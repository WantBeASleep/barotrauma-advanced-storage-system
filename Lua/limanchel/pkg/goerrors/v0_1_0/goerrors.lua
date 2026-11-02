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

---Проверяет плотность списка, не посещая объекты причин заранее.
---@param causes any
---@return integer
local function count_causes(causes)
   assert(type(causes) == "table", "Метод unwrap() должен возвращать массив ошибок")
   local count = 0
   local maximum = 0
   for index in next, causes do
      assert(
         type(index) == "number",
         "Причины должны иметь целочисленные индексы"
      )
      assert(index >= 1 and index % 1 == 0, "Индексы причин должны начинаться с 1")
      count = count + 1
      if index > maximum then
         maximum = index
      end
   end
   assert(maximum == count, "Массив причин не должен содержать пропуски")
   return count
end

---Обходит узлы в глубину и запрашивает причины лишь после проверки узла.
---@param err goerrors.Error
---@param matches fun(candidate: goerrors.Error): boolean
---@return goerrors.Error?
local function find_error(err, matches)
   local stack = { { causes = { err }, index = 1, count = 1 } }
   while #stack > 0 do
      local frame = stack[#stack]
      if frame.index > frame.count then
         stack[#stack] = nil
      else
         local candidate = frame.causes[frame.index]
         frame.index = frame.index + 1
         validate_error(candidate)
         if matches(candidate) then
            return candidate
         end

         local unwrap = candidate.unwrap
         if unwrap ~= nil then
            assert(type(unwrap) == "function", "Поле unwrap должно быть методом")
            local causes = unwrap(candidate)
            local count = count_causes(causes)
            if count > 0 then
               stack[#stack + 1] = { causes = causes, index = 1, count = count }
            end
         end
      end
   end
   return nil
end

function goerrors.is(err, target)
   if target == nil then
      if err ~= nil then
         validate_error(err)
      end
      return err == nil
   end
   validate_error(target)
   if err == nil then
      return false
   end
   return find_error(err, function(candidate)
      return rawequal(candidate, target)
   end) ~= nil
end

function goerrors.as(err, error_class)
   assert(type(error_class) == "table", "Класс ошибки должен быть таблицей")
   if err == nil then
      return nil
   end
   return find_error(err, function(candidate)
      local mt = getmetatable(candidate)
      return type(mt) == "table" and (rawequal(mt, error_class) or rawequal(rawget(mt, "__index"), error_class))
   end)
end

return goerrors
