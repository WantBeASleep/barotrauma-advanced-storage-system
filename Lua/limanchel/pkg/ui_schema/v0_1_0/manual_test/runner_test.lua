local busted = require("busted")
local assert = require("luassert")
local runner = require("limanchel.pkg.ui_schema.v0_1_0.manual_test.runner")
local test_support = require("limanchel.pkg.ui_schema.v0_1_0.test_support")
local describe, it = busted.describe, busted.it

local function setup()
   local builder, backend = test_support.new_builder()
   local host = test_support.new_host(backend)
   local reports = {}
   local function read_text(path)
      local file = assert(io.open(path, "r"))
      local text = file:read("*a")
      file:close()
      return text
   end
   local session = assert(runner.start({
      builder = builder,
      host = host,
      schema_path = "Lua/limanchel/pkg/ui_schema/v0_1_0/manual_test",
      read_text = read_text,
      write_report = function(report)
         reports[#reports + 1] = report
      end,
   }))
   return session, host, reports
end

describe("Готовность к визуальной проверке", function()
   it(
      "ждёт два завершённых кадра и сбрасывает шаг после действия",
      function()
         local session, host = setup()
         assert(session:open("controls"))
         for _ = 1, 3 do
            host:fire("update")
         end
         assert.is_false(session:report().ready)
         host:fire("draw_complete")
         assert.is_false(session:report().ready)
         host:fire("update")
         host:fire("draw_complete")
         local before = session:report()
         assert.is_true(before.ready)
         assert(session:step("change_message"))
         local after = session:report()
         assert.is_false(after.ready)
         assert.are.equal(before.step_id + 1, after.step_id)
         assert.are.equal(before.run_id, after.run_id)
         session:stop()
         assert.is_nil(next(host.commands))
         assert.is_nil(next(host.callbacks))
      end
   )

   it("не выдаёт ready после таймаута", function()
      local session, host = setup()
      assert(session:open("layout"))
      host.clock = 6
      host:fire("update")
      host:fire("draw_complete")
      local report = session:report()
      assert.is_false(report.ready)
      assert.matches("ожидания", report.error, 1, true)
      session:stop()
   end)

   it("повторно запускается без накопления регистраций", function()
      local first, first_host = setup()
      first:stop()
      local second, second_host = setup()
      assert.is_nil(next(first_host.commands))
      assert.is_not_nil(second_host.commands.ui_schema_test)
      second:stop()
      second:stop()
   end)
end)
