---@type filestore.Lib
local filestore = {}

local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")

local temporary_suffix = ".filestore-tmp"
local device_names = { CON = true, PRN = true, AUX = true, NUL = true }
for _, prefix in ipairs({ "COM", "LPT" }) do
   for i = 1, 9 do
      device_names[prefix .. i] = true
   end
   for _, digit in ipairs({ "¹", "²", "³" }) do
      device_names[prefix .. digit] = true
   end
end

filestore.errors = {
   not_found = goerrors.new("Файл не найден"),
   read_failed = goerrors.new("Не удалось прочитать файл"),
   write_failed = goerrors.new("Не удалось сохранить файл"),
}

---Проверяет переносимый относительный ключ до обращения к платформе.
---@param key string
local function validate_key(key)
   assert(type(key) == "string" and key ~= "", "Ключ должен быть непустой строкой")
   assert(not key:find("[\\%z\1-\31\127<>:\"|?*]"), "Ключ содержит запрещённый символ")
   for segment in (key .. "/"):gmatch("(.-)/") do
      assert(segment ~= "", "Ключ содержит пустой сегмент")
      assert(
         segment ~= "." and segment ~= "..",
         "Ключ содержит переход между каталогами"
      )
      assert(
         not segment:find("[. ]$"),
         "Сегмент ключа заканчивается точкой или пробелом"
      )
      assert(
         segment:lower():sub(-#temporary_suffix) ~= temporary_suffix,
         "Суффикс .filestore-tmp зарезервирован"
      )
      local base_name = segment:match("^[^.]*"):upper()
      assert(
         not device_names[base_name],
         "Ключ содержит зарезервированное имя устройства"
      )
   end
end

---Получает путь из текущего каталога сохранений игры.
---@param key string Проверенный ключ.
---@return string
local function get_path(key)
   local root = Game.SaveFolder
   assert(type(root) == "string" and root ~= "", "Недоступен каталог сохранений игры")
   root = root:gsub("\\", "/"):gsub("/+$", "")
   return root .. "/ModFiles/" .. key
end

---Добавляет к платформенному сбою стадию, ключ и стабильную причину.
---@param cause goerrors.Error
---@param stage string
---@param key string
---@param reason any
---@return goerrors.Error
local function operation_error(cause, stage, key, reason)
   return goerrors.wrap(string.format("%s [%s]", stage, key), cause, goerrors.new(tostring(reason)))
end

function filestore.load(key)
   validate_key(key)
   local stage = "Определение каталога"
   local found = false
   local ok, result = pcall(function()
      local path = get_path(key)
      stage = "Проверка наличия файла"
      found = File.Exists(path)
      if not found then
         return nil
      end
      stage = "Чтение файла"
      return File.Read(path)
   end)
   if not ok then
      return nil, operation_error(filestore.errors.read_failed, stage, key, result)
   end
   if not found then
      return nil, goerrors.wrap(string.format("Загрузка [%s]", key), filestore.errors.not_found)
   end
   return result
end

return filestore
