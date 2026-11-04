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
   { name = "управляющий U+0085", value = "a" .. string.char(194, 133) .. "b" },
   { name = "управляющий U+009F", value = "a" .. string.char(194, 159) .. "b" },
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
   { name = "короткий псевдоним NTFS", value = "SETTIN~1.FI~" },
   { name = "короткий псевдоним в каталоге", value = "folder~2/file.txt" },
   { name = "число", value = 42 },
   { name = "таблица", value = {} },
}

local device_names = { "CON", "PRN", "AUX", "NUL", "CONIN$", "CONOUT$" }
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
         CreateDirectory = function(path)
            calls[#calls + 1] = { "CreateDirectory", path }
            if failures.CreateDirectory == false then
               return false
            end
            if failures.CreateDirectory then
               error(failures.CreateDirectory, 0)
            end
            for file_path in pairs(files) do
               if path == file_path or path:sub(1, #file_path + 1) == file_path .. "/" then
                  error("родитель является файлом", 0)
               end
            end
            directories[path] = true
            return true
         end,
         Write = function(path, text)
            calls[#calls + 1] = { "Write", path, text }
            if not directories[path:match("^(.*)/")] then
               error("родительский каталог отсутствует", 0)
            end
            if failures.Write then
               files[path] = text:sub(1, 2)
               error(failures.Write, 0)
            end
            files[path] = text
         end,
         Move = function(path, target)
            calls[#calls + 1] = { "Move", path, target }
            if failures.Move then
               error(failures.Move, 0)
            end
            if files[path] == nil or directories[target] then
               error("замена недоступна", 0)
            end
            files[target], files[path] = files[path], nil
         end,
         Delete = function(path)
            calls[#calls + 1] = { "Delete", path }
            if failures.Delete then
               error(failures.Delete, 0)
            end
            files[path] = nil
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

      for _, case in ipairs({
         { root = "saves/", path = "saves/ModFiles/a" },
         { root = "saves//", path = "saves//ModFiles/a" },
         { root = "saves\\", path = "saves\\/ModFiles/a" },
      }) do
         busted.it(
            "принимает завершающий разделитель корня " .. case.root,
            function()
               _G.Game.SaveFolder = case.root
               files[case.path] = "текст"
               assert.are.equal("текст", filestore.load("a"))
            end
         )
      end

      busted.it("сохраняет диск и вложенность Windows-корня", function()
         _G.Game.SaveFolder = "C:\\Data\\Saves\\"
         files["C:\\Data\\Saves\\/ModFiles/a"] = "текст"
         assert.are.equal("текст", filestore.load("a"))
      end)

      busted.it("не меняет обратный слеш в имени Linux-каталога", function()
         _G.Game.SaveFolder = "/srv/saves\\blue"
         files["/srv/saves\\blue/ModFiles/a"] = "верный каталог"
         files["/srv/saves/blue/ModFiles/a"] = "другой каталог"
         assert.are.equal("верный каталог", filestore.load("a"))
      end)

      busted.it("сохраняет абсолютный Unix-корень", function()
         _G.Game.SaveFolder = "/"
         files["/ModFiles/a"] = "текст"
         assert.are.equal("текст", filestore.load("a"))
      end)

      busted.it("сохраняет регистр, кириллицу и допустимые имена", function()
         files["saves/ModFiles/Мод ©/.hidden/COM10.Auxiliary~draft.txt"] = "данные"
         assert.are.equal("данные", filestore.load("Мод ©/.hidden/COM10.Auxiliary~draft.txt"))
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

   busted.describe("сохранение", function()
      busted.before_each(function()
         filestore = require(module_name)
         assert.are.equal("function", type(filestore.save))
      end)

      busted.it("сохраняет текст с созданием вложенных каталогов", function()
         local ok, err = filestore.save("ass/storagecfgs/cfg1.json", "Привет\r\nмир\n")
         assert.is_true(ok)
         assert.is_nil(err)
         assert.are.equal("Привет\r\nмир\n", files["saves/ModFiles/ass/storagecfgs/cfg1.json"])
         assert.is_true(directories["saves/ModFiles/ass/storagecfgs"])
         assert.is_nil(files["saves/ModFiles/ass/storagecfgs/cfg1.json.filestore-tmp"])
         assert.are.same({
            { "CreateDirectory", "saves/ModFiles/ass/storagecfgs" },
            { "Write", "saves/ModFiles/ass/storagecfgs/cfg1.json.filestore-tmp", "Привет\r\nмир\n" },
            {
               "Move",
               "saves/ModFiles/ass/storagecfgs/cfg1.json.filestore-tmp",
               "saves/ModFiles/ass/storagecfgs/cfg1.json",
            },
         }, calls)
         assert.are.equal("Привет\r\nмир\n", filestore.load("ass/storagecfgs/cfg1.json"))
      end)

      busted.it("полностью заменяет прежний файл пустой строкой", function()
         files["saves/ModFiles/a"] = "старое содержимое"
         assert.is_true(filestore.save("a", ""))
         assert.are.equal("", filestore.load("a"))
      end)

      busted.it("не усекает длинный текст", function()
         local text = ("длинная строка\n"):rep(10000)
         assert.is_true(filestore.save("long.txt", text))
         assert.are.equal(text, filestore.load("long.txt"))
      end)

      busted.it("учитывает смену корня между сохранениями", function()
         assert.is_true(filestore.save("a", "первый"))
         _G.Game.SaveFolder = "other"
         assert.is_true(filestore.save("a", "второй"))
         assert.are.equal("первый", files["saves/ModFiles/a"])
         assert.are.equal("второй", files["other/ModFiles/a"])
      end)

      busted.it("сохраняет в Linux-корень с обратным слешем в имени", function()
         _G.Game.SaveFolder = "/srv/saves\\blue"
         assert.is_true(filestore.save("a", "новое"))
         assert.are.equal("новое", files["/srv/saves\\blue/ModFiles/a"])
         assert.is_nil(files["/srv/saves/blue/ModFiles/a"])
      end)

      busted.it(
         "перезаписывает аварийный остаток только своего ключа",
         function()
            files["saves/ModFiles/a"] = "старое"
            files["saves/ModFiles/a.filestore-tmp"] = "аварийный остаток"
            files["saves/ModFiles/b"] = "соседний файл"
            files["saves/ModFiles/b.filestore-tmp"] = "чужой временный"
            assert.are.equal("старое", filestore.load("a"))
            assert.is_true(filestore.save("a", "новое"))
            assert.are.equal("новое", filestore.load("a"))
            assert.is_nil(files["saves/ModFiles/a.filestore-tmp"])
            assert.are.equal("соседний файл", files["saves/ModFiles/b"])
            assert.are.equal("чужой временный", files["saves/ModFiles/b.filestore-tmp"])
         end
      )

      for _, operation in ipairs({ "CreateDirectory", "Write", "Move" }) do
         busted.it("сохраняет прежний файл при отказе " .. operation, function()
            files["saves/ModFiles/settings.json"] = "старое"
            failures[operation] = "отказ " .. operation
            local ok, err = filestore.save("settings.json", "новое")
            assert.is_nil(ok)
            assert.is_true(goerrors.is(err, filestore.errors.write_failed))
            assert.is_truthy(err:error():find("settings.json", 1, true))
            assert.is_truthy(err:error():find("отказ " .. operation, 1, true))
            assert.are.equal("старое", files["saves/ModFiles/settings.json"])
            assert.is_nil(files["saves/ModFiles/settings.json.filestore-tmp"])
            for _, call in ipairs(calls) do
               assert.is_false(call[1] == "Delete" and call[2] == "saves/ModFiles/settings.json")
            end
         end)
      end

      busted.it("обрабатывает false от создания каталога как отказ", function()
         failures.CreateDirectory = false
         local ok, err = filestore.save("a", "новое")
         assert.is_nil(ok)
         assert.is_true(goerrors.is(err, filestore.errors.write_failed))
         assert.is_nil(files["saves/ModFiles/a"])
      end)

      busted.it(
         "возвращает ошибку, если родительский путь занят файлом",
         function()
            files["saves/ModFiles/folder"] = "обычный файл"
            local ok, err = filestore.save("folder/child/a", "новое")
            assert.is_nil(ok)
            assert.is_true(goerrors.is(err, filestore.errors.write_failed))
            assert.are.equal("обычный файл", files["saves/ModFiles/folder"])
         end
      )

      busted.it("возвращает ошибку замены каталога файлом", function()
         directories["saves/ModFiles/a"] = true
         local ok, err = filestore.save("a", "новое")
         assert.is_nil(ok)
         assert.is_true(goerrors.is(err, filestore.errors.write_failed))
         assert.is_true(directories["saves/ModFiles/a"])
         assert.is_nil(files["saves/ModFiles/a.filestore-tmp"])
      end)

      for _, operation in ipairs({ "Write", "Move" }) do
         busted.it(
            "сохраняет обе причины при сбое очистки после " .. operation,
            function()
               files["saves/ModFiles/a"] = "старое"
               failures[operation] = "основной отказ"
               failures.Delete = "отказ очистки"
               local ok, err = filestore.save("a", "новое")
               assert.is_nil(ok)
               assert.is_true(goerrors.is(err, filestore.errors.write_failed))
               assert.is_truthy(err:error():find("основной отказ", 1, true))
               assert.is_truthy(err:error():find("отказ очистки", 1, true))
               assert.are.equal("старое", files["saves/ModFiles/a"])
               assert.is_not_nil(files["saves/ModFiles/a.filestore-tmp"])
               local causes = err:unwrap()
               assert.is_true(goerrors.is(causes[1], filestore.errors.write_failed))
               assert.is_truthy(causes[2]:error():find("отказ очистки", 1, true))
            end
         )
      end

      for _, case in ipairs(invalid_keys) do
         busted.it("отклоняет ключ до записи: " .. case.name, function()
            local ok, err = pcall(filestore.save, case.value, "текст")
            assert.is_false(ok)
            assert.are.equal("string", type(err))
            assert.are.same({}, calls)
         end)
      end

      for _, case in ipairs({
         { name = "nil" },
         { name = "число", value = 42 },
         { name = "таблица", value = {} },
         { name = "boolean", value = false },
      }) do
         busted.it("не преобразует в текст: " .. case.name, function()
            local ok, err = pcall(filestore.save, "a", case.value)
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
