local busted = require("busted")
local assert = require("luassert")
local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")

local module_name = "limanchel.pkg.filestore.v0_1_0.filestore"
local invalid_keys = {
   { name = "пустая строка", value = "" },
   { name = "абсолютный путь", value = "/a" },
   { name = "буква диска", value = "C:/a" },
   { name = "путь относительно диска", value = "C:a" },
   { name = "обратный слеш", value = "a\\b" },
   { name = "сетевой путь", value = "//server/file" },
   { name = "пустой сегмент", value = "a//b" },
   { name = "завершающий слеш", value = "a/" },
   { name = "текущий каталог", value = "./a" },
   { name = "родительский каталог", value = "a/../b" },
   { name = "точка", value = "." },
   { name = "две точки", value = ".." },
   { name = "нулевой байт", value = "a\0b" },
   { name = "перенос строки", value = "a\nb" },
   { name = "управляющий символ", value = "a" .. string.char(31) .. "b" },
   { name = "DEL", value = "a\127b" },
   { name = "меньше", value = "a<b" },
   { name = "больше", value = "a>b" },
   { name = "двоеточие", value = "a:b" },
   { name = "кавычка", value = "a\"b" },
   { name = "вертикальная черта", value = "a|b" },
   { name = "вопросительный знак", value = "a?b" },
   { name = "звёздочка", value = "a*b" },
   { name = "завершающий пробел", value = "a " },
   { name = "завершающая точка", value = "a." },
   { name = "точка с пробелом", value = "a. " },
   { name = "неверный каталог", value = "a./file" },
   { name = "служебный файл", value = "a.filestore-tmp" },
   {
      name = "служебный каталог без учёта регистра",
      value = "x.FILESTORE-TMP/file.txt",
   },
   { name = "nil" },
   { name = "число", value = 42 },
   { name = "таблица", value = {} },
}

local device_names = { "CON", "PRN", "AUX", "NUL" }
for _, prefix in ipairs({ "COM", "LPT" }) do
   for i = 1, 9 do
      device_names[#device_names + 1] = prefix .. i
   end
   for _, digit in ipairs({ "¹", "²", "³" }) do
      device_names[#device_names + 1] = prefix .. digit
   end
end
for _, name in ipairs(device_names) do
   invalid_keys[#invalid_keys + 1] = { name = "устройство " .. name, value = name }
   invalid_keys[#invalid_keys + 1] = {
      name = "устройство с расширением " .. name,
      value = "folder/" .. name:lower() .. ".tar.gz",
   }
end

-- Подменяются только глобальные границы LuaCs; исходные значения восстанавливаются после теста.
-- selene: allow(global_usage)
busted.describe("filestore", function()
   local filestore, files, directories, calls, failures
   local previous_file, previous_game, previous_module

   busted.before_each(function()
      previous_file = rawget(_G, "File")
      previous_game = rawget(_G, "Game")
      previous_module = package.loaded[module_name]
      package.loaded[module_name] = nil
      files, directories, calls, failures = {}, {}, {}, {}
      _G.Game = { SaveFolder = "saves" }
      _G.File = {
         Exists = function(path)
            calls[#calls + 1] = { "Exists", path }
            if failures.Exists then
               error(failures.Exists, 0)
            end
            return files[path] ~= nil
         end,
         Read = function(path)
            calls[#calls + 1] = { "Read", path }
            if failures.Read then
               error(failures.Read, 0)
            end
            if files[path] == nil or directories[path] then
               error("файл недоступен", 0)
            end
            return files[path]
         end,
      }
   end)

   busted.after_each(function()
      _G.File = previous_file
      _G.Game = previous_game
      package.loaded[module_name] = previous_module
   end)

   busted.describe("загрузка", function()
      busted.before_each(function()
         filestore = require(module_name)
      end)

      busted.it("читает вложенный файл по относительному ключу", function()
         files["saves/ModFiles/ass/storagecfgs/cfg1.json"] = "{\"key\":\"значение\"}"
         local text, err = filestore.load("ass/storagecfgs/cfg1.json")
         assert.are.equal("{\"key\":\"значение\"}", text)
         assert.is_nil(err)
         assert.are.same({
            { "Exists", "saves/ModFiles/ass/storagecfgs/cfg1.json" },
            { "Read", "saves/ModFiles/ass/storagecfgs/cfg1.json" },
         }, calls)
      end)

      busted.it("отличает отсутствующий файл от пустого", function()
         local text, err = filestore.load("missing.txt")
         assert.is_nil(text)
         assert.is_true(goerrors.is(err, filestore.errors.not_found))
         assert.is_truthy(err:error():find("missing.txt", 1, true))
         files["saves/ModFiles/empty.txt"] = ""
         assert.are.equal("", filestore.load("empty.txt"))
      end)

      busted.it("видит ручные изменения при следующем чтении", function()
         files["saves/ModFiles/settings.txt"] = "раньше"
         assert.are.equal("раньше", filestore.load("settings.txt"))
         files["saves/ModFiles/settings.txt"] = "после правки"
         assert.are.equal("после правки", filestore.load("settings.txt"))
      end)

      busted.it(
         "берёт актуальный каталог сохранений при каждом вызове",
         function()
            files["saves/ModFiles/a"] = "первый"
            files["other/ModFiles/a"] = "второй"
            assert.are.equal("первый", filestore.load("a"))
            _G.Game.SaveFolder = "other"
            assert.are.equal("второй", filestore.load("a"))
         end
      )

      for _, root in ipairs({ "saves/", "saves//", "saves\\" }) do
         busted.it("принимает завершающий разделитель корня " .. root, function()
            _G.Game.SaveFolder = root
            files["saves/ModFiles/a"] = "текст"
            assert.are.equal("текст", filestore.load("a"))
         end)
      end

      busted.it("сохраняет диск и вложенность Windows-корня", function()
         _G.Game.SaveFolder = "C:\\Data\\Saves\\"
         files["C:/Data/Saves/ModFiles/a"] = "текст"
         assert.are.equal("текст", filestore.load("a"))
      end)

      busted.it("сохраняет абсолютный Unix-корень", function()
         _G.Game.SaveFolder = "/"
         files["/ModFiles/a"] = "текст"
         assert.are.equal("текст", filestore.load("a"))
      end)

      busted.it("сохраняет регистр, кириллицу и допустимые имена", function()
         files["saves/ModFiles/Мод/.hidden/COM10.Auxiliary.txt"] = "данные"
         assert.are.equal("данные", filestore.load("Мод/.hidden/COM10.Auxiliary.txt"))
      end)

      busted.it(
         "не подменяет отсутствующий целевой файл временным",
         function()
            files["saves/ModFiles/a.filestore-tmp"] = "незавершённое"
            local text, err = filestore.load("a")
            assert.is_nil(text)
            assert.is_true(goerrors.is(err, filestore.errors.not_found))
            assert.are.same({ { "Exists", "saves/ModFiles/a" } }, calls)
         end
      )

      for _, operation in ipairs({ "Exists", "Read" }) do
         busted.it("возвращает ошибку при отказе " .. operation, function()
            files["saves/ModFiles/a"] = "текст"
            failures[operation] = "диск недоступен"
            local text, err = filestore.load("a")
            assert.is_nil(text)
            assert.is_true(goerrors.is(err, filestore.errors.read_failed))
            assert.is_truthy(err:error():find("a", 1, true))
            assert.is_truthy(err:error():find("диск недоступен", 1, true))
         end)
      end

      busted.it(
         "возвращает ошибку для файла, исчезнувшего перед чтением",
         function()
            _G.File.Exists = function()
               return true
            end
            local text, err = filestore.load("a")
            assert.is_nil(text)
            assert.is_true(goerrors.is(err, filestore.errors.read_failed))
         end
      )

      busted.it(
         "следует проверке File.Exists для каталога вместо файла",
         function()
            directories["saves/ModFiles/a"] = true
            local text, err = filestore.load("a")
            assert.is_nil(text)
            assert.is_true(goerrors.is(err, filestore.errors.not_found))
         end
      )

      for _, case in ipairs(invalid_keys) do
         busted.it("отклоняет ключ до обращения к диску: " .. case.name, function()
            local ok, err = pcall(filestore.load, case.value)
            assert.is_false(ok)
            assert.are.equal("string", type(err))
            assert.are.same({}, calls)
         end)
      end
   end)

   busted.it("загружает модуль без Game, File и файловых обращений", function()
      _G.Game, _G.File = nil, nil
      local loaded = require(module_name)
      assert.are.equal("function", type(loaded.load))
      assert.are.same({}, calls)
   end)
end)
