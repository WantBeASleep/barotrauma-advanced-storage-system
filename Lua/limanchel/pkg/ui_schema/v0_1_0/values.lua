local values = {}
local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")
local json_decoder = require("limanchel.pkg.ui_schema.v0_1_0.json_decoder")

local fields = {
   ["$type"] = { ["$type"] = true, value = true },
   ["$enum"] = { ["$enum"] = true, value = true },
   ["$resource"] = { ["$resource"] = true },
   ["$ref"] = { ["$ref"] = true, member = true },
   ["$nil"] = { ["$nil"] = true },
}

local function failure(message)
   return nil, goerrors.new(message)
end

local function special(spec, marker, context)
   local allowed = fields[marker]
   if not allowed then
      return failure("неизвестный маркер " .. marker)
   end
   for key in pairs(spec) do
      if not allowed[key] then
         return failure("недопустимое поле " .. tostring(key))
      end
   end
   if marker == "$nil" then
      if spec[marker] ~= true then
         return failure("$nil должен быть true")
      end
      return nil
   end
   local name = spec[marker]
   if type(name) ~= "string" or name == "" then
      return failure("нужно непустое имя " .. marker)
   end
   if marker == "$resource" then
      if context.resources[name] == nil then
         return failure("ресурс не найден: " .. name)
      end
      return context.resources[name]
   end
   if marker == "$ref" then
      local object = context.by_id[name]
      if object == nil then
         return failure("объект не найден: " .. name)
      end
      if spec.member ~= nil then
         if type(spec.member) ~= "string" or spec.member == "" then
            return failure("member должен быть непустой строкой")
         end
         local result = context.backend:read_member(object, spec.member)
         if result == nil then
            return failure("член не найден: " .. spec.member)
         end
         return result
      end
      return object
   end
   if marker == "$enum" then
      if type(spec.value) ~= "string" or spec.value == "" then
         return failure("нужно имя варианта перечисления")
      end
      local options = context.registry:get_enum(name)
      if not options or options[spec.value] == nil then
         return failure("неизвестный вариант " .. name .. "." .. spec.value)
      end
      return options[spec.value]
   end
   local converter = context.registry:get_value_type(name)
   if not converter then
      return failure("неизвестный тип значения " .. name)
   end
   if spec.value == nil then
      return failure("отсутствует value")
   end
   return converter(spec.value, context)
end

local function resolve_inner(spec, context, path)
   if type(spec) ~= "table" then
      if type(spec) == "number" and (spec ~= spec or spec == math.huge or spec == -math.huge) then
         return failure("число должно быть конечным")
      end
      return spec
   end
   if json_decoder.kind(spec) == "null" then
      return failure("null запрещён")
   end
   for key in pairs(spec) do
      if type(key) == "string" and key:sub(1, 1) == "$" then
         return special(spec, key, context)
      end
   end
   local copy = {}
   for key, entry in pairs(spec) do
      local resolved, err = values.resolve(entry, context, path .. "." .. tostring(key))
      if err then
         return nil, err
      end
      copy[key] = resolved
   end
   return setmetatable(copy, getmetatable(spec))
end

function values.resolve(spec, context, path)
   local ok, result, err = pcall(resolve_inner, spec, context, path)
   if not ok then
      return failure(path .. ": " .. tostring(result))
   end
   if err then
      return nil, goerrors.wrap(path, err)
   end
   return result
end

local function vector_converter(name, count, integers, backend)
   return function(input)
      if type(input) ~= "table" or #input ~= count then
         return failure("для " .. name .. " нужно координат: " .. count)
      end
      local args = {}
      local entries = 0
      for key, value in pairs(input) do
         entries = entries + 1
         if type(key) ~= "number" or key < 1 or key > count or key % 1 ~= 0 then
            return failure("неверный массив " .. name)
         end
         if
            type(value) ~= "number"
            or value ~= value
            or value == math.huge
            or value == -math.huge
            or (integers and value % 1 ~= 0)
         then
            return failure("неверная координата " .. name)
         end
         args[key] = value
      end
      if entries ~= count then
         return failure("неполный массив " .. name)
      end
      return backend:new_value(name, args)
   end
end

function values.register_defaults(reg, backend)
   for _, item in ipairs({
      { "Point", 2, true },
      { "Vector2", 2 },
      { "Vector3", 3 },
      { "Vector4", 4 },
      { "Rectangle", 4, true },
   }) do
      reg:register_value_type(item[1], vector_converter(item[1], item[2], item[3], backend))
   end
   reg:register_value_type("Color", function(input)
      if type(input) ~= "table" or (#input ~= 3 and #input ~= 4) then
         return failure("Color принимает RGB или RGBA")
      end
      local args = {}
      for key, value in pairs(input) do
         if
            type(key) ~= "number"
            or key % 1 ~= 0
            or key < 1
            or key > #input
            or type(value) ~= "number"
            or value % 1 ~= 0
            or value < 0
            or value > 255
         then
            return failure("компонента Color должна быть целой от 0 до 255")
         end
         args[key] = value
      end
      if args[4] == nil then
         args[4] = 255
      end
      return backend:new_value("Color", args)
   end)
   reg:register_value_type("Identifier", function(input)
      if type(input) ~= "string" then
         return failure("Identifier принимает строку")
      end
      return backend:new_value("Identifier", { input })
   end)
end

return values
