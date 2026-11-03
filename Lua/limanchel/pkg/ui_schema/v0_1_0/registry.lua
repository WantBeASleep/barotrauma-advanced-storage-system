local registry = {}
local Registry = {}
local Registry_mt = { __index = Registry }

local function add(target, name, value)
   assert(type(name) == "string" and name ~= "", "нужно непустое имя регистрации")
   assert(target[name] == nil, "имя уже зарегистрировано: " .. name)
   target[name] = value
end

function registry.new()
   return setmetatable({ types = {}, value_types = {}, enums = {} }, Registry_mt)
end

function Registry:register_type(name, descriptor)
   assert(type(descriptor) == "table", "описание типа должно быть таблицей")
   assert(
      descriptor.rect_mode == "new" or descriptor.rect_mode == "parent" or descriptor.rect_mode == "none",
      "неверный rect_mode"
   )
   for _, field in ipairs({ "validate", "create", "child_parent", "destroy" }) do
      assert(type(descriptor[field]) == "function", "отсутствует функция " .. field)
   end
   local copy = {}
   for key, value in pairs(descriptor) do
      copy[key] = value
   end
   add(self.types, name, copy)
end

function Registry:register_value_type(name, converter)
   assert(type(converter) == "function", "преобразователь должен быть функцией")
   add(self.value_types, name, converter)
end

function Registry:register_enum(name, options)
   assert(type(options) == "table", "варианты перечисления должны быть таблицей")
   local copy = {}
   for key, value in pairs(options) do
      copy[key] = value
   end
   setmetatable(copy, getmetatable(options))
   add(self.enums, name, copy)
end

function Registry:get_type(name)
   return self.types[name]
end
function Registry:get_value_type(name)
   return self.value_types[name]
end
function Registry:get_enum(name)
   return self.enums[name]
end

return registry
