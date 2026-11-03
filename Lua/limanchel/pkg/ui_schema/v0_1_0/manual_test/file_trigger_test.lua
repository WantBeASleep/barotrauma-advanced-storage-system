local busted = require("busted")
local assert = require("luassert")
local file_trigger = require("limanchel.pkg.ui_schema.v0_1_0.manual_test.file_trigger")

busted.describe("Файловый триггер проверочных меню", function()
   busted.it("исполняет запрос один раз и принимает новый номер", function()
      local calls = {}
      local trigger = file_trigger.new(function(args)
         calls[#calls + 1] = args
      end)
      trigger:accept("1 open layout")
      trigger:accept("1 open layout")
      trigger:accept("2 step change_message")
      assert.are.same({ { "open", "layout" }, { "step", "change_message" } }, calls)
   end)

   busted.it("не исполняет произвольные команды игры или Lua", function()
      local calls = 0
      local trigger = file_trigger.new(function()
         calls = calls + 1
      end)
      assert.is_nil(trigger:accept("1 lua print(1)"))
      assert.is_nil(trigger:accept("2 open layout extra"))
      assert.are.equal(0, calls)
   end)
end)
