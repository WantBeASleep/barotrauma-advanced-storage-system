---@type logger.Lib
local logger = {}

local levels = { trace = 1, debug = 2, info = 3, warning = 4, error = 5 }
local option_names = { level = true, prefixes = true, write = true }

---@type table<logger.Level, Microsoft.Xna.Framework.Color>
local colors = {
   trace = Color.Beige,
   debug = Color.LimeGreen,
   info = Color.SkyBlue,
   warning = Color.Orange,
   error = Color.Red,
}

---@class logger.Instance: logger.Logger
---@field private threshold integer
---@field private prefixes string[]
---@field private write fun(line: string, color: Microsoft.Xna.Framework.Color)
local Logger = {}
local Logger_mt = { __index = Logger }

---Проверяет плотный массив непустых префиксов и возвращает его копию.
---@param prefixes string[]
---@return string[]
local function copy_prefixes(prefixes)
   assert(type(prefixes) == "table", "prefixes должен быть массивом строк")
   local count = 0
   local copied = {}
   for key, prefix in pairs(prefixes) do
      assert(
         type(key) == "number" and key >= 1 and key % 1 == 0,
         "prefixes должен быть плотным массивом с индекса 1"
      )
      assert(
         type(prefix) == "string" and prefix ~= "",
         "Префикс должен быть непустой строкой"
      )
      count = count + 1
      copied[key] = prefix
   end
   for i = 1, count do
      assert(copied[i] ~= nil, "prefixes должен быть плотным массивом с индекса 1")
   end
   return copied
end

---Заменяет физические переносы строк видимыми последовательностями.
---@param text string
---@return string
local function escape_text(text)
   return (text:gsub("\r", "\\r"):gsub("\n", "\\n"))
end

---Формирует отсортированный блок полей без изменения исходной таблицы.
---@param fields table<string, any>?
---@return string
local function format_fields(fields)
   if fields == nil then
      return ""
   end
   assert(type(fields) == "table", "Поля сообщения должны быть таблицей")
   local keys = {}
   local values = {}
   for key, value in pairs(fields) do
      assert(type(key) == "string", "Ключ поля должен быть строкой")
      keys[#keys + 1] = key
      values[key] = value
   end
   if #keys == 0 then
      return ""
   end
   table.sort(keys)
   local parts = {}
   for i, key in ipairs(keys) do
      parts[i] = escape_text(key) .. " = " .. escape_text(tostring(values[key]))
   end
   return " {" .. table.concat(parts, "; ") .. "}"
end

---Отправляет разрешённое сообщение в функцию вывода экземпляра.
---@private
---@param level logger.Level
---@param message string
---@param fields table<string, any>?
---@return nil
function Logger:write_message(level, message, fields)
   if levels[level] < self.threshold then
      return
   end
   assert(type(message) == "string", "Сообщение должно быть строкой")
   local parts = {}
   for i, prefix in ipairs(self.prefixes) do
      parts[i] = "[" .. escape_text(prefix) .. "]"
   end
   parts[#parts + 1] = "[" .. string.upper(level) .. "] " .. escape_text(message) .. format_fields(fields)
   self.write(table.concat(parts), colors[level])
end

function Logger:trace(message, fields)
   self:write_message("trace", message, fields)
end

function Logger:debug(message, fields)
   self:write_message("debug", message, fields)
end

function Logger:info(message, fields)
   self:write_message("info", message, fields)
end

function Logger:warning(message, fields)
   self:write_message("warning", message, fields)
end

function Logger:error(message, fields)
   self:write_message("error", message, fields)
end

function Logger:with_prefix(prefix, ...)
   assert(
      type(prefix) == "string" and prefix ~= "",
      "Префикс должен быть непустой строкой"
   )
   local prefixes = copy_prefixes(self.prefixes)
   prefixes[#prefixes + 1] = prefix
   for i = 1, select("#", ...) do
      local extra_prefix = select(i, ...)
      assert(
         type(extra_prefix) == "string" and extra_prefix ~= "",
         "Префикс должен быть непустой строкой"
      )
      prefixes[#prefixes + 1] = extra_prefix
   end
   return setmetatable({ threshold = self.threshold, prefixes = prefixes, write = self.write }, Logger_mt)
end

function logger.new(options)
   assert(type(options) == "table", "Настройки логгера должны быть таблицей")
   for name in pairs(options) do
      assert(option_names[name], "Неизвестная настройка логгера")
   end
   assert(
      type(options.level) == "string" and levels[options.level],
      "Неизвестный уровень логгера"
   )
   assert(type(options.write) == "function", "write должен быть функцией")
   local prefixes = copy_prefixes(options.prefixes)
   return setmetatable({ threshold = levels[options.level], prefixes = prefixes, write = options.write }, Logger_mt)
end

return logger
