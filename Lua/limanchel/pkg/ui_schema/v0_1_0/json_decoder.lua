local json_decoder = {}

local lunajson_decoder = require("limanchel.pkg.ui_schema.v0_1_0.vendor.lunajson_decoder")
local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")

local null_value = {}
local array_mt = { __ui_schema_kind = "array" }
local object_mt = { __ui_schema_kind = "object" }

local function normalize(value)
   if type(value) ~= "table" or rawequal(value, null_value) then
      return value
   end
   local is_array = value[0] ~= nil
   value[0] = nil
   setmetatable(value, is_array and array_mt or object_mt)
   for key, child in pairs(value) do
      value[key] = normalize(child)
   end
   return value
end

function json_decoder.decode(text)
   assert(type(text) == "string", "JSON должен быть строкой")
   local decode = lunajson_decoder()
   local ok, value = pcall(decode, text, nil, null_value, true)
   if not ok then
      return nil, goerrors.new("Ошибка JSON: " .. tostring(value))
   end
   return normalize(value)
end

function json_decoder.kind(value)
   if rawequal(value, null_value) then
      return "null"
   end
   if type(value) == "table" then
      local mt = getmetatable(value)
      return mt and mt.__ui_schema_kind or "table"
   end
   return type(value)
end

return json_decoder
