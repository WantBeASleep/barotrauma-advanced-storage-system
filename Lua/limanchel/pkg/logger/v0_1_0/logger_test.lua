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
