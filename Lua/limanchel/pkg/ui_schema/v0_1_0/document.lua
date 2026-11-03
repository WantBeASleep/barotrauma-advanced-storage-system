local document = {}

local json_decoder = require("limanchel.pkg.ui_schema.v0_1_0.json_decoder")
local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")

local Document_mt = {}
local node_fields =
   { type = true, id = true, rect = true, constructor = true, props = true, children = true, attach_to = true }
local rect_fields = { size = true, anchor = true, pivot = true, scale_basis = true, props = true }

local function fail(path, message)
   return nil, goerrors.new(path .. ": " .. message)
end

local function check_fields(value, fields, path)
   if json_decoder.kind(value) ~= "object" then
      return fail(path, "ожидается объект JSON")
   end
   for key in pairs(value) do
      if not fields[key] then
         return fail(path .. "." .. key, "неизвестное поле")
      end
   end
   return true
end

local function check_value(value, path)
   local kind = json_decoder.kind(value)
   if kind == "null" then
      return fail(path, "null запрещён; используйте $nil")
   end
   if kind == "number" and (value ~= value or value == math.huge or value == -math.huge) then
      return fail(path, "число должно быть конечным")
   end
   if kind == "object" or kind == "array" then
      for key, child in pairs(value) do
         local ok, err = check_value(child, path .. "." .. tostring(key))
         if not ok then
            return nil, err
         end
      end
   end
   return true
end

local function check_member(member, path)
   if
      type(member) ~= "string"
      or member == ""
      or member:find("[^%w_%.]")
      or member:find("%.%.")
      or member:sub(1, 1) == "."
      or member:sub(-1) == "."
   then
      return fail(path, "неверный путь свойства")
   end
   for part in member:gmatch("[^%.]+") do
      if part == "Parent" then
         return fail(path, "изменение Parent запрещено")
      end
   end
   if member == "RectTransform" or member:match("%.RectTransform$") then
      return fail(path, "подмена RectTransform запрещена")
   end
   return true
end

local function check_props(props, path)
   if props == nil then
      return true
   end
   local kind = json_decoder.kind(props)
   if kind ~= "array" and kind ~= "object" then
      return fail(path, "ожидается объект или массив присваиваний")
   end
   for key, entry in pairs(props) do
      local member = key
      local entry_path = path .. "." .. tostring(key)
      if kind == "array" then
         local ok, err = check_fields(entry, { member = true, value = true }, entry_path)
         if not ok then
            return nil, err
         end
         if entry.value == nil then
            return fail(entry_path .. ".value", "обязательное значение отсутствует")
         end
         member = entry.member
      end
      local ok, err = check_member(member, entry_path)
      if not ok then
         return nil, err
      end
   end
   return true
end

local function check_node(node, path)
   local ok, err = check_fields(node, node_fields, path)
   if not ok then
      return nil, err
   end
   for _, field in ipairs({ "type", "id", "attach_to" }) do
      if node[field] ~= nil and (type(node[field]) ~= "string" or node[field] == "") then
         return fail(path .. "." .. field, "ожидается непустая строка")
      end
   end
   if node.type == nil then
      return fail(path .. ".type", "обязательное поле отсутствует")
   end
   if node.constructor ~= nil and json_decoder.kind(node.constructor) ~= "object" then
      return fail(path .. ".constructor", "ожидается объект параметров")
   end
   ok, err = check_props(node.props, path .. ".props")
   if not ok then
      return nil, err
   end
   if node.rect ~= nil then
      ok, err = check_fields(node.rect, rect_fields, path .. ".rect")
      if not ok then
         return nil, err
      end
      if node.rect.size == nil then
         return fail(path .. ".rect.size", "обязательное поле отсутствует")
      end
      ok, err = check_props(node.rect.props, path .. ".rect.props")
      if not ok then
         return nil, err
      end
   end
   if node.children ~= nil then
      if json_decoder.kind(node.children) ~= "array" then
         return fail(path .. ".children", "ожидается массив")
      end
      for i, child in ipairs(node.children) do
         ok, err = check_node(child, path .. ".children[" .. i .. "]")
         if not ok then
            return nil, err
         end
      end
   end
   return true
end

function document.parse(text)
   assert(type(text) == "string", "документ должен быть строкой JSON")
   local value, err = json_decoder.decode(text)
   if err then
      return nil, err
   end
   local ok
   ok, err = check_fields(value, { schema_version = true, components = true }, "document")
   if not ok then
      return nil, err
   end
   if value.schema_version ~= 1 then
      return fail("schema_version", "поддерживается версия 1")
   end
   if json_decoder.kind(value.components) ~= "object" then
      return fail("components", "ожидается объект именованных схем")
   end
   ok, err = check_value(value, "document")
   if not ok then
      return nil, err
   end
   for name, node in pairs(value.components) do
      if name == "" then
         return fail("components", "пустое имя схемы")
      end
      ok, err = check_node(node, "components." .. name)
      if not ok then
         return nil, err
      end
   end
   return setmetatable({ schemas = value.components }, Document_mt)
end

function document.get_schema(doc, name)
   assert(type(doc) == "table" and getmetatable(doc) == Document_mt, "нужен документ из parse")
   assert(type(name) == "string" and name ~= "", "нужно непустое имя схемы")
   if not doc.schemas[name] then
      return fail("components." .. name, "схема не найдена")
   end
   return doc.schemas[name]
end

return document
