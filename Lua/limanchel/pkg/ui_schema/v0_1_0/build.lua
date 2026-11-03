local build = {}
local document = require("limanchel.pkg.ui_schema.v0_1_0.document")
local values = require("limanchel.pkg.ui_schema.v0_1_0.values")
local json_decoder = require("limanchel.pkg.ui_schema.v0_1_0.json_decoder")
local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")

local View = {}
local View_mt = { __index = View }

local function as_error(value)
   if type(value) == "table" and type(value.error) == "function" then
      return value
   end
   return goerrors.new(tostring(value))
end

local function abort(path, message)
   error(path .. ": " .. message, 0)
end

local function checked(path, callback, ...)
   local ok, result, err = pcall(callback, ...)
   if not ok then
      error(goerrors.wrap(path, as_error(result)):error(), 0)
   end
   if err then
      error(goerrors.wrap(path, as_error(err)):error(), 0)
   end
   return result
end

local function assignments(props, path)
   local result = {}
   if not props then
      return result
   end
   if json_decoder.kind(props) == "array" then
      for i, entry in ipairs(props) do
         result[#result + 1] = { member = entry.member, value = entry.value, path = path .. "[" .. i .. "].value" }
      end
   else
      local keys = {}
      for name in pairs(props) do
         keys[#keys + 1] = name
      end
      table.sort(keys)
      for _, name in ipairs(keys) do
         result[#result + 1] = { member = name, value = props[name], path = path .. "." .. name }
      end
   end
   return result
end

local function apply_props(target, props, path, context)
   for _, entry in ipairs(assignments(props, path)) do
      local value = checked(entry.path, values.resolve, entry.value, context, entry.path)
      checked(entry.path, context.backend.write_member, context.backend, target, entry.member, value)
   end
end

local function cleanup(records)
   local errors = {}
   for i = #records, 1, -1 do
      local entry = records[i]
      if entry.active then
         local ok, err = pcall(entry.clean)
         if ok then
            entry.active = false
         else
            errors[#errors + 1] = as_error(err)
         end
      end
   end
   if #errors > 0 then
      return nil, goerrors.wrap("Ошибка очистки UI", table.unpack(errors))
   end
   return true
end

function View:get(id)
   assert(not self.disposed, "экземпляр UI освобождён")
   assert(type(id) == "string" and self.by_id[id] ~= nil, "объект UI не найден: " .. tostring(id))
   return self.by_id[id]
end

function View:dispose()
   local ok, err = cleanup(self.records)
   local remaining = {}
   for _, record in ipairs(self.records) do
      if record.active then
         remaining[#remaining + 1] = record
      end
   end
   self.records = remaining
   self.root = nil
   for id in pairs(self.by_id) do
      self.by_id[id] = nil
   end
   self.disposed = true
   return ok, err
end

local function collect(node, path, parent_entry, entries, ids, reg)
   local descriptor = reg:get_type(node.type)
   if not descriptor then
      abort(path .. ".type", "неизвестный тип " .. node.type)
   end
   if descriptor.rect_mode == "new" and not node.rect then
      abort(path .. ".rect", "требуется размер и положение")
   end
   if descriptor.rect_mode ~= "new" and node.rect then
      abort(path .. ".rect", "этот тип сам управляет размещением")
   end
   local entry = { node = node, descriptor = descriptor, parent = parent_entry, path = path, index = #entries + 1 }
   entries[#entries + 1] = entry
   if node.id then
      if ids[node.id] then
         abort(path .. ".id", "повторный id " .. node.id)
      end
      ids[node.id] = entry
   end
   if node.attach_to and not parent_entry then
      abort(path .. ".attach_to", "корню уже передан родитель")
   end
   if parent_entry and parent_entry.descriptor.slots then
      local slot = node.attach_to or "default"
      if not parent_entry.descriptor.slots[slot] then
         abort(path .. ".attach_to", "недоступная область " .. slot)
      end
   end
   checked(path .. ".constructor", descriptor.validate, node.constructor or {}, path .. ".constructor")
   for i, child in ipairs(node.children or {}) do
      collect(child, path .. ".children[" .. i .. "]", entry, entries, ids, reg)
   end
end

local function check_refs(spec, path, entry, ids, context, early)
   if type(spec) ~= "table" then
      checked(path, values.resolve, spec, context, path)
      return
   end
   if spec["$ref"] ~= nil then
      for key in pairs(spec) do
         if key ~= "$ref" and key ~= "member" then
            abort(path, "лишнее поле ссылки " .. tostring(key))
         end
      end
      local name = spec["$ref"]
      if type(name) ~= "string" or not ids[name] then
         abort(path, "объект ссылки не найден: " .. tostring(name))
      end
      if early and ids[name].index >= entry.index then
         abort(path, "ссылка требует уже созданный объект: " .. name)
      end
      if spec.member ~= nil and (type(spec.member) ~= "string" or spec.member == "") then
         abort(path, "member должен быть строкой")
      end
      return
   end
   for key in pairs(spec) do
      if type(key) == "string" and key:sub(1, 1) == "$" then
         checked(path, values.resolve, spec, context, path)
         return
      end
   end
   for key, child in pairs(spec) do
      check_refs(child, path .. "." .. tostring(key), entry, ids, context, early)
   end
end

local function preflight(node, path, context, reg)
   local entries, ids = {}, {}
   collect(node, path, nil, entries, ids, reg)
   for _, entry in ipairs(entries) do
      check_refs(entry.node.constructor or {}, entry.path .. ".constructor", entry, ids, context, true)
      check_refs(entry.node.rect or {}, entry.path .. ".rect", entry, ids, context, true)
      for _, assignment in ipairs(assignments(entry.node.props, entry.path .. ".props")) do
         check_refs(assignment.value, assignment.path, entry, ids, context, false)
      end
   end
   return entries
end

local function resolve_rect(spec, context, path)
   local result = {}
   for _, name in ipairs({ "size", "anchor", "pivot", "scale_basis" }) do
      if spec[name] ~= nil then
         result[name] = checked(path .. "." .. name, values.resolve, spec[name], context, path .. "." .. name)
      end
   end
   return result
end

local function make_entry(entry, external_parent, context, view)
   local parent = external_parent
   if entry.parent then
      parent = checked(
         entry.path .. ".attach_to",
         entry.parent.descriptor.child_parent,
         entry.parent.object,
         entry.node.attach_to
      )
      if parent == nil then
         abort(entry.path .. ".attach_to", "родитель не принимает детей")
      end
   end
   local rect = parent
   local pending = {}
   local tracking = true
   context.defer_cleanup = function(callback)
      assert(
         tracking and type(callback) == "function",
         "defer_cleanup допустим только при создании"
      )
      pending[#pending + 1] = callback
   end
   local record = { active = true }
   record.clean = function()
      local errors = {}
      for i = #pending, 1, -1 do
         local ok, err = pcall(pending[i])
         if not ok then
            errors[#errors + 1] = as_error(err)
         end
      end
      if entry.descriptor.rect_mode == "new" and rect ~= parent then
         local ok, err = pcall(context.backend.detach, context.backend, rect)
         if not ok then
            errors[#errors + 1] = as_error(err)
         end
      end
      if #errors > 0 then
         error(goerrors.wrap(entry.path, table.unpack(errors)):error(), 0)
      end
   end
   view.records[#view.records + 1] = record
   if entry.descriptor.rect_mode == "new" then
      local spec = resolve_rect(entry.node.rect, context, entry.path .. ".rect")
      rect = checked(entry.path .. ".rect", context.backend.new_rect, context.backend, spec, parent)
      apply_props(rect, entry.node.rect.props, entry.path .. ".rect.props", context)
   elseif entry.descriptor.rect_mode == "none" then
      rect = nil
   end
   local params = { values = {}, present = {}, variant = "default" }
   for name, value in pairs(entry.node.constructor or {}) do
      if name == "variant" then
         params.variant = value
      else
         params.present[name] = true
         params.values[name] = checked(
            entry.path .. ".constructor." .. name,
            values.resolve,
            value,
            context,
            entry.path .. ".constructor." .. name
         )
      end
   end
   local object = checked(
      entry.path .. " (" .. entry.node.type .. (entry.node.id and " id=" .. entry.node.id or "") .. ")",
      entry.descriptor.create,
      params,
      rect,
      context
   )
   if object == nil then
      abort(entry.path, "создание не вернуло объект")
   end
   tracking = false
   pending = {}
   entry.object = object
   record.clean = function()
      local ok, err = pcall(checked, entry.path, entry.descriptor.destroy, object)
      if not ok then
         local detached, detach_err = pcall(context.backend.detach, context.backend, object)
         if not detached then
            error(goerrors.wrap(entry.path, as_error(err), as_error(detach_err)):error(), 0)
         end
         error(err, 0)
      end
   end
   if entry.node.id then
      view.by_id[entry.node.id] = object
   end
   if not entry.parent then
      view.root = object
   end
end

function build.run(doc, name, parent, options, reg, backend)
   assert(options == nil or type(options) == "table", "контекст должен быть таблицей")
   local resources = options and options.resources or {}
   assert(type(resources) == "table", "resources должен быть таблицей")
   if not backend:is_client() then
      return nil, goerrors.new("Создание UI доступно только на клиенте")
   end
   local node, err = document.get_schema(doc, name)
   if err then
      return nil, err
   end
   local view = setmetatable({ by_id = {}, records = {}, disposed = false }, View_mt)
   local context = { resources = resources, by_id = view.by_id, registry = reg, backend = backend }
   local ok, result = pcall(function()
      local entries = preflight(node, "components." .. name, context, reg)
      for _, entry in ipairs(entries) do
         make_entry(entry, parent, context, view)
      end
      for _, entry in ipairs(entries) do
         apply_props(entry.object, entry.node.props, entry.path .. ".props", context)
      end
      return view
   end)
   if not ok then
      local _, cleanup_err = view:dispose()
      if cleanup_err then
         return nil, goerrors.wrap("Построение UI", as_error(result), cleanup_err)
      end
      return nil, as_error(result)
   end
   return result
end

return build
