local busted = require("busted")
local assert = require("luassert")
local logger = require("limanchel.pkg.logger.v0_1_0.logger")

local describe = busted.describe
local it = busted.it
local after_each = busted.after_each
local restore_globals

after_each(function()
   if restore_globals then
      restore_globals()
      restore_globals = nil
   end
end)

local function collect_lines(lines)
   return function(...)
      assert.are.equal(1, select("#", ...))
      local line = ...
      assert.are.equal("string", type(line))
      lines[#lines + 1] = line
   end
end

local function new_log(level, prefixes)
   local lines = {}
   return logger.new({ level = level, prefixes = prefixes, write = collect_lines(lines) }), lines
end

local function assert_contract_error(callback)
   local ok, message = pcall(callback)
   assert.is_false(ok)
   assert.are.equal("string", type(message))
end

describe("Создание logger", function()
   it("требует таблицу настроек", function()
      assert_contract_error(function()
         logger.new()
      end)
      for _, value in ipairs({ false, 42, "info" }) do
         assert_contract_error(function()
            logger.new(value)
         end)
      end
   end)

   for _, name in ipairs({ "level", "prefixes", "write" }) do
      it("требует явно передать " .. name, function()
         local options = { level = "info", prefixes = {}, write = print }
         options[name] = nil
         assert_contract_error(function()
            logger.new(options)
         end)
      end)
   end

   local invalid_options = {
      { name = "неизвестную настройку", field = "typo", value = true },
      { name = "неизвестный уровень", field = "level", value = "warn" },
      { name = "верхний регистр уровня", field = "level", value = "INFO" },
      { name = "число вместо уровня", field = "level", value = 1 },
      { name = "false вместо уровня", field = "level", value = false },
      { name = "строку вместо массива", field = "prefixes", value = "ASS" },
      { name = "false вместо массива", field = "prefixes", value = false },
      { name = "нефункциональный write", field = "write", value = true },
      { name = "пустой префикс", field = "prefixes", value = { "" } },
      { name = "нестроковой префикс", field = "prefixes", value = { 42 } },
      { name = "false в префиксах", field = "prefixes", value = { false } },
      { name = "разрыв в массиве", field = "prefixes", value = { [1] = "a", [3] = "b" } },
      { name = "начало массива с нуля", field = "prefixes", value = { [0] = "a" } },
      { name = "дробный индекс", field = "prefixes", value = { [1.5] = "a" } },
      { name = "лишний ключ массива", field = "prefixes", value = { [1] = "a", extra = "b" } },
   }
   for _, case in ipairs(invalid_options) do
      it("отклоняет " .. case.name, function()
         local options = { level = "info", prefixes = {}, write = print }
         options[case.field] = case.value
         assert_contract_error(function()
            logger.new(options)
         end)
      end)
   end

   -- Подмена глобальной функции нужна для обнаружения неявного вывода модуля.
   -- selene: allow(global_usage)
   it("не выводит сообщения при загрузке и создании", function()
      local original_print = _G.print
      local module_name = "limanchel.pkg.logger.v0_1_0.logger"
      local original_module = package.loaded[module_name]
      local lines = {}
      restore_globals = function()
         _G.print = original_print
         package.loaded[module_name] = original_module
      end
      _G.print = collect_lines(lines)
      package.loaded[module_name] = nil
      local loaded = require("limanchel.pkg.logger.v0_1_0.logger")
      loaded.new({ level = "info", prefixes = {}, write = _G.print })
      assert.are.same({}, lines)
   end)

   it("копирует префиксы и сохраняет порог с функцией вывода", function()
      local lines = {}
      local prefixes = { "ASS" }
      local write = collect_lines(lines)
      local options = { level = "warning", prefixes = prefixes, write = write }
      local log = logger.new(options)
      assert.are.equal("ASS", prefixes[1])
      assert.are.equal(1, #prefixes)
      assert.are.equal("warning", options.level)
      assert.is_true(rawequal(prefixes, options.prefixes))
      assert.is_true(rawequal(write, options.write))

      prefixes[1] = "changed"
      prefixes[2] = "extra"
      options.prefixes = { "other" }
      options.level = "trace"
      options.write = function()
         error("Функция вывода была заменена")
      end
      assert.is_nil(log:info("скрыто"))
      assert.is_nil(log:warning("текст"))
      assert.are.same({ "[ASS][WARNING] текст" }, lines)
   end)
end)

describe("Уровни logger", function()
   local levels = { "trace", "debug", "info", "warning", "error" }
   local expected_lines = {
      "[TRACE] текст",
      "[DEBUG] текст",
      "[INFO] текст",
      "[WARNING] текст",
      "[ERROR] текст",
   }
   local allowed = {
      { true, true, true, true, true },
      { false, true, true, true, true },
      { false, false, true, true, true },
      { false, false, false, true, true },
      { false, false, false, false, true },
   }
   for threshold_index, threshold in ipairs(levels) do
      for level_index, level in ipairs(levels) do
         it("обрабатывает " .. level .. " при пороге " .. threshold, function()
            local log, lines = new_log(threshold, {})
            assert.is_nil(log[level](log, "текст"))
            if allowed[threshold_index][level_index] then
               assert.are.same({ expected_lines[level_index] }, lines)
            else
               assert.are.same({}, lines)
            end
         end)
      end
   end

   it("не обращается к аргументам подавленного сообщения", function()
      local log, lines = new_log("error", {})
      local touched = 0
      local object = setmetatable({}, {
         __tostring = function()
            touched = touched + 1
            error("Преобразование запрещено")
         end,
      })
      local fields = setmetatable({ object = object }, {
         __pairs = function()
            touched = touched + 1
            error("Обход запрещён")
         end,
      })
      assert.is_nil(log:debug(false, fields))
      assert.is_nil(log:debug(nil, false))
      assert.are.equal(0, touched)
      assert.are.same({}, lines)
   end)
end)

describe("Сообщения logger", function()
   it("выводит цепочку префиксов перед уровнем", function()
      local log, lines = new_log("info", { "ASS", "storage" })
      assert.is_nil(log:info("текст"))
      assert.are.same({ "[ASS][storage][INFO] текст" }, lines)
   end)

   it("сохраняет пустое сообщение", function()
      local log, lines = new_log("info", {})
      assert.is_nil(log:info(""))
      assert.are.same({ "[INFO] " }, lines)
   end)

   it("отклоняет неверный тип разрешённого сообщения", function()
      local log = new_log("info", {})
      assert_contract_error(function()
         log:info()
      end)
      for _, value in ipairs({ false, 42, {} }) do
         assert_contract_error(function()
            log:info(value)
         end)
      end
   end)
end)

describe("Именованные поля logger", function()
   it("сохраняет маскированное значение из __pairs", function()
      local log, lines = new_log("info", {})
      local fields = setmetatable({ token = "исходное значение" }, {
         __pairs = function()
            return next, { token = "[скрыто]" }, nil
         end,
      })
      log:info("текст", fields)
      assert.are.same({ "[INFO] текст {token = [скрыто]}" }, lines)
      assert.are.equal("исходное значение", fields.token)
   end)

   it("сохраняет виртуальное поле false из __pairs", function()
      local log, lines = new_log("info", {})
      local fields = setmetatable({}, {
         __pairs = function()
            return next, { enabled = false }, nil
         end,
      })
      log:info("текст", fields)
      assert.are.same({ "[INFO] текст {enabled = false}" }, lines)
      assert.is_nil(rawget(fields, "enabled"))
   end)

   it("сортирует именованные поля", function()
      local log, lines = new_log("info", { "ASS", "storage", "filters" })
      log:info("Предмет отклонён", { reason = "blacklist", item_id = 42 })
      assert.are.same({
         "[ASS][storage][filters][INFO] Предмет отклонён {item_id = 42; reason = blacklist}",
      }, lines)
   end)

   for _, level in ipairs({ "trace", "debug", "info", "warning", "error" }) do
      it("выводит поля на уровне " .. level, function()
         local log, lines = new_log("trace", {})
         assert.is_nil(log[level](log, "текст", { count = 42 }))
         assert.are.same({ "[" .. string.upper(level) .. "] текст {count = 42}" }, lines)
      end)
   end

   it("сохраняет false, ноль и пустые строки", function()
      local log, lines = new_log("info", {})
      log:info("", { [""] = false, count = 0, text = "" })
      assert.are.same({ "[INFO]  { = false; count = 0; text = }" }, lines)
   end)

   it("не выводит блок для отсутствующих или пустых полей", function()
      local log, lines = new_log("info", {})
      log:info("текст")
      log:info("текст", nil)
      log:info("текст", {})
      log:info("текст", { absent = nil })
      assert.are.same({ "[INFO] текст", "[INFO] текст", "[INFO] текст", "[INFO] текст" }, lines)
   end)

   it("отклоняет неверные типы полей и ключей", function()
      local log, lines = new_log("info", {})
      for _, fields in ipairs({
         false,
         42,
         "текст",
         { [1] = "значение" },
         { [false] = "значение" },
      }) do
         assert_contract_error(function()
            log:info("текст", fields)
         end)
      end
      assert.are.same({}, lines)
   end)

   it(
      "вызывает __tostring по одному разу на поле и не меняет объекты",
      function()
         local log, lines = new_log("info", {})
         local calls = 0
         local object = setmetatable({ tag = "предмет" }, {
            __tostring = function(self)
               calls = calls + 1
               return self.tag
            end,
         })
         local fields = { second = object, first = object }
         log:info("текст", fields)
         assert.are.same({ "[INFO] текст {first = предмет; second = предмет}" }, lines)
         assert.are.equal(2, calls)
         assert.are.same({ tag = "предмет" }, object)
         assert.is_true(rawequal(object, fields.first))
         assert.is_true(rawequal(object, fields.second))
         local count = 0
         for _ in pairs(fields) do
            count = count + 1
         end
         assert.are.equal(2, count)
      end
   )

   it(
      "использует стандартное представление таблицы, функции и цикла",
      function()
         local log, lines = new_log("info", {})
         local plain = {}
         local callback = function() end
         local cyclic = {}
         cyclic.self = cyclic
         local expected = "[INFO] текст {callback = "
            .. tostring(callback)
            .. "; cyclic = "
            .. tostring(cyclic)
            .. "; plain = "
            .. tostring(plain)
            .. "}"
         log:info("текст", { plain = plain, callback = callback, cyclic = cyclic })
         assert.are.same({ expected }, lines)
         assert.is_true(rawequal(cyclic, cyclic.self))
      end
   )

   it("не вызывает обычное поле tostring у значения", function()
      local log, lines = new_log("info", {})
      local object = {
         tostring = function()
            error("Метод вызываться не должен")
         end,
      }
      local expected = "[INFO] текст {object = " .. tostring(object) .. "}"
      log:info("текст", { object = object })
      assert.are.same({ expected }, lines)
   end)

   it("передаёт сбой __tostring без частичного вывода", function()
      local log, lines = new_log("info", {})
      local broken = setmetatable({}, {
         __tostring = function()
            error("Сбой преобразования", 0)
         end,
      })
      local ok, message = pcall(function()
         log:info("текст", { a = "готово", b = broken })
      end)
      assert.is_false(ok)
      assert.are.equal("Сбой преобразования", message)
      assert.are.same({}, lines)
   end)

   it("передаёт сбой write без повторного вызова", function()
      local calls = 0
      local log = logger.new({
         level = "info",
         prefixes = {},
         write = function(line)
            calls = calls + 1
            assert.are.equal("[INFO] текст {count = 42}", line)
            error("Сбой вывода", 0)
         end,
      })
      local ok, message = pcall(function()
         log:info("текст", { count = 42 })
      end)
      assert.is_false(ok)
      assert.are.equal("Сбой вывода", message)
      assert.are.equal(1, calls)
   end)

   it("не возвращает результат функции вывода", function()
      local log = logger.new({
         level = "info",
         prefixes = {},
         write = function()
            return 42, "результат"
         end,
      })
      assert.is_nil(log:info("текст", { count = 1 }))
   end)

   it("экранирует CR и LF во всех текстовых компонентах", function()
      local log, lines = new_log("info", { "a\r\nb" })
      local object = setmetatable({}, {
         __tostring = function()
            return "a\r\nb"
         end,
      })
      log:info("a\r\nb", { ["a\r\nb"] = object })
      assert.are.same({ "[a\\r\\nb][INFO] a\\r\\nb {a\\r\\nb = a\\r\\nb}" }, lines)
   end)

   it(
      "сохраняет прочие разделители без завершающего перевода строки",
      function()
         local text = "[]{};=\\"
         local log, lines = new_log("info", { text })
         log:info(text, { [text] = text })
         assert.are.same({ "[[]{};=\\][INFO] []{};=\\ {[]{};=\\ = []{};=\\}" }, lines)
      end
   )
end)

describe("Производные логгеры", function()
   it(
      "добавляет несколько префиксов без изменения родителя и соседей",
      function()
         local log, lines = new_log("warning", { "ASS" })
         local child = log:with_prefix("storage", "filters")
         local sibling = log:with_prefix("menu")
         local grandchild = child:with_prefix("filters")
         child:warning("текст")
         sibling:warning("текст")
         grandchild:warning("текст")
         log:warning("текст")
         assert.are.same({
            "[ASS][storage][filters][WARNING] текст",
            "[ASS][menu][WARNING] текст",
            "[ASS][storage][filters][filters][WARNING] текст",
            "[ASS][WARNING] текст",
         }, lines)
         assert.is_false(rawequal(log, child))
         assert.is_false(rawequal(child, sibling))
         assert.is_false(rawequal(child, grandchild))
      end
   )

   it("наследует порог и функцию вывода", function()
      local log, lines = new_log("warning", {})
      local child = log:with_prefix("storage")
      local sibling = log:with_prefix("menu")
      local grandchild = child:with_prefix("filters")
      for _, instance in ipairs({ log, child, sibling, grandchild }) do
         assert.is_nil(instance:info("скрыто"))
         assert.is_nil(instance:error("текст", { count = 42 }))
      end
      assert.are.same({
         "[ERROR] текст {count = 42}",
         "[storage][ERROR] текст {count = 42}",
         "[menu][ERROR] текст {count = 42}",
         "[storage][filters][ERROR] текст {count = 42}",
      }, lines)
   end)

   it("создаёт независимые экземпляры при повторном new", function()
      local first, first_lines = new_log("info", { "ASS" })
      local second, second_lines = new_log("error", { "other" })
      assert.is_false(rawequal(first, second))
      first:with_prefix("storage"):info("текст")
      second:info("скрыто")
      second:error("сбой")
      assert.are.same({ "[ASS][storage][INFO] текст" }, first_lines)
      assert.are.same({ "[other][ERROR] сбой" }, second_lines)
   end)

   local invalid_prefixes = {
      {
         name = "отсутствие аргументов",
         call = function(log)
            log:with_prefix()
         end,
      },
      {
         name = "пустую строку",
         call = function(log)
            log:with_prefix("")
         end,
      },
      {
         name = "число",
         call = function(log)
            log:with_prefix(42)
         end,
      },
      {
         name = "начальный nil",
         call = function(log)
            log:with_prefix(nil, "x")
         end,
      },
      {
         name = "промежуточный nil",
         call = function(log)
            log:with_prefix("x", nil, "y")
         end,
      },
      {
         name = "замыкающий nil",
         call = function(log)
            log:with_prefix("x", nil)
         end,
      },
   }
   for _, case in ipairs(invalid_prefixes) do
      it("отклоняет " .. case.name .. " без изменения родителя", function()
         local log, lines = new_log("info", { "ASS" })
         assert_contract_error(function()
            case.call(log)
         end)
         log:info("текст")
         assert.are.same({ "[ASS][INFO] текст" }, lines)
      end)
   end

   -- Подмена глобальной функции проверяет захват явно переданного print.
   -- selene: allow(global_usage)
   it("сохраняет явно переданный print у всей семьи", function()
      local original_print = _G.print
      local lines = {}
      local replacement_lines = {}
      restore_globals = function()
         _G.print = original_print
      end
      _G.print = collect_lines(lines)
      local log = logger.new({ level = "info", prefixes = {}, write = _G.print })
      _G.print = collect_lines(replacement_lines)
      local child = log:with_prefix("storage")
      log:info("текст")
      child:info("текст")
      assert.are.same({ "[INFO] текст", "[storage][INFO] текст" }, lines)
      assert.are.same({}, replacement_lines)
   end)
end)
