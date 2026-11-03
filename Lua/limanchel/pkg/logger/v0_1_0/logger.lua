---@type logger.Lib
local logger = {}

local levels = { trace = 1, debug = 2, info = 3, warning = 4, error = 5 }
local option_names = { level = true, prefixes = true, write = true }

---@class logger.Instance: logger.Logger
---@field private threshold integer
---@field private prefixes string[]
---@field private write fun(line: string)
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

---Отправляет разрешённое сообщение в функцию вывода экземпляра.
---@private
---@param level logger.Level
---@param message string
---@return nil
function Logger:write_message(level, message)
   if levels[level] < self.threshold then
      return
   end
   assert(type(message) == "string", "Сообщение должно быть строкой")
   local prefixes = ""
   if #self.prefixes > 0 then
      prefixes = "[" .. table.concat(self.prefixes, "][") .. "]"
   end
   self.write(prefixes .. "[" .. string.upper(level) .. "] " .. message)
end

function Logger:trace(message)
   self:write_message("trace", message)
end

function Logger:debug(message)
   self:write_message("debug", message)
end

function Logger:info(message)
   self:write_message("info", message)
end

function Logger:warning(message)
   self:write_message("warning", message)
end

function Logger:error(message)
   self:write_message("error", message)
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
