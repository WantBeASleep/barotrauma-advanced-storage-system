local busted = require("busted")
local assert = require("luassert")
local cases = require("limanchel.pkg.ui_schema.v0_1_0.manual_test.cases")
local test_support = require("limanchel.pkg.ui_schema.v0_1_0.test_support")
local describe, it = busted.describe, busted.it

local function prepare()
   local builder, backend = test_support.new_builder()
   local host = test_support.new_host(backend)
   local documents = {}
   for _, name in ipairs({ "layout", "controls", "rows", "resources", "lifecycle" }) do
      local file = assert(io.open("Lua/limanchel/pkg/ui_schema/v0_1_0/manual_test/" .. name .. ".json", "r"))
      local text = file:read("*a")
      file:close()
      documents[name] = assert(builder:parse(text))
   end
   return cases.create(builder, documents, host), host
end

describe("Поведение игровых примеров", function()
   it("кнопка меняет настоящую надпись созданной схемы", function()
      local examples = prepare()
      local case = assert(examples:open("controls"))
      case.actions.change_message()
      assert.are.equal("Кнопка нажата", case.view:get("message").Text)
      case:close()
   end)

   it("добавляет независимые строки и удаляет только нужную", function()
      local examples = prepare()
      local case = assert(examples:open("rows"))
      case.actions.add_row()
      case.actions.add_row()
      assert.are.equal(2, #case.rows)
      local first, second = case.rows[1], case.rows[2]
      assert.is_false(rawequal(first:get("name"), second:get("name")))
      first:get("remove").OnClicked()
      assert.are.equal(1, #case.rows)
      assert.is_true(rawequal(second, case.rows[1]))
      assert.is_nil(first.root)
      assert.is_nil(case.actions.remove_row_1)
      case:close()
      assert.is_nil(second.root)
   end)
end)
