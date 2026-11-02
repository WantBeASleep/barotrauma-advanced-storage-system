---@type goerrors.Lib
local goerrors = {}

---@class goerrors.BuiltinError: goerrors.Error
---@field private message string
---@field private causes goerrors.Error[]
local Error = {}
local Error_mt = {
   __index = Error,
   __tostring = function(self)
      return self:error()
   end,
}

---Проверяет наличие обязательного метода ошибки без вычисления описания.
---@param err any
---@return nil
local function validate_error(err)
   assert(type(err) == "table", "Ожидается объект ошибки")
   assert(type(err.error) == "function", "Ошибка должна иметь метод error()")
end

---Возвращает собственное описание с контекстом непосредственных причин.
---@return string
function Error:error()
   if #self.causes == 0 then
      return self.message
   end

   local descriptions = {}
   for i, cause in ipairs(self.causes) do
      validate_error(cause)
      local description = cause:error()
      assert(type(description) == "string", "Метод error() должен возвращать строку")
      descriptions[i] = description
   end

   if #descriptions == 1 then
      return self.message .. ": " .. descriptions[1]
   end
   return self.message .. ": [" .. table.concat(descriptions, "; ") .. "]"
end

---Возвращает независимый список ссылок на непосредственные причины.
---@return goerrors.Error[]
function Error:unwrap()
   local causes = {}
   for i, cause in ipairs(self.causes) do
      causes[i] = cause
   end
   return causes
end

function goerrors.new(message)
   assert(type(message) == "string", "Сообщение ошибки должно быть строкой")
   return setmetatable({ message = message, causes = {} }, Error_mt)
end

function goerrors.wrap(message, ...)
   assert(type(message) == "string", "Контекст ошибки должен быть строкой")
   local count = select("#", ...)
   assert(count > 0, "Для обёртки требуется хотя бы одна причина")

   local causes = {}
   for i = 1, count do
      local cause = select(i, ...)
      validate_error(cause)
      causes[i] = cause
   end
   return setmetatable({ message = message, causes = causes }, Error_mt)
end

return goerrors
