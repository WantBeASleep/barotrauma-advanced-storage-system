local busted = require("busted")
local assert = require("luassert")
local document = require("limanchel.pkg.ui_schema.v0_1_0.document")

local describe, it = busted.describe, busted.it

describe("Документы схем UI", function()
   it("хранит несколько именованных схем", function()
      local doc, err = document.parse(
         "{\"schema_version\":1,\"components\":{\"menu\":{\"type\":\"Frame\"},\"row\":{\"type\":\"Frame\"}}}"
      )
      assert.is_nil(err)
      assert.are.equal("Frame", document.get_schema(doc, "menu").type)
      assert.are.equal("Frame", document.get_schema(doc, "row").type)
      local missing, missing_err = document.get_schema(doc, "absent")
      assert.is_nil(missing)
      assert.matches("absent", missing_err:error(), 1, true)
   end)

   local invalid = {
      { "{\"schema_version\":2,\"components\":{}}", "schema_version" },
      { "{\"schema_version\":1,\"components\":[]}", "components" },
      { "{\"schema_version\":1,\"components\":{\"x\":{\"type\":\"Frame\",\"children\":{}}}}", "children" },
      { "{\"schema_version\":1,\"components\":{\"x\":{\"type\":\"Frame\",\"extra\":true}}}", "extra" },
      { "{\"schema_version\":1,\"components\":{\"x\":{\"type\":\"Frame\",\"props\":{\"Text\":null}}}}", "Text" },
      { "{\"schema_version\":1,\"components\":{\"x\":{\"type\":\"Frame\",\"id\":\"\"}}}", "id" },
      { "{\"schema_version\":1,\"components\":{\"x\":{\"type\":\"Frame\",\"rect\":{\"wrong\":1}}}}", "wrong" },
      { "{\"schema_version\":1,\"components\":{\"x\":{\"type\":\"Frame\",\"props\":{\"Parent\":1}}}}", "Parent" },
      { "{\"schema_version\":1,\"components\":{\"x\":{\"type\":\"Frame\",\"props\":[{\"member\":\"Text\"}]}}}", "value" },
   }
   for _, case in ipairs(invalid) do
      it("объясняет неверное поле " .. case[2], function()
         local doc, err = document.parse(case[1])
         assert.is_nil(doc)
         assert.matches(case[2], err:error(), 1, true)
      end)
   end

   it("сохраняет порядок присваиваний и явный nil", function()
      local doc = assert(
         document.parse(
            "{\"schema_version\":1,\"components\":{\"x\":{\"type\":\"Frame\",\"props\":[{\"member\":\"Text\",\"value\":{\"$nil\":true}},{\"member\":\"Text\",\"value\":\"новый\"}]}}}"
         )
      )
      local node = document.get_schema(doc, "x")
      assert.are.equal("Text", node.props[1].member)
      assert.is_true(node.props[1].value["$nil"])
      assert.are.equal("новый", node.props[2].value)
   end)

   it("проверяет аргументы API", function()
      assert.has_error(function()
         document.parse(false)
      end)
      assert.has_error(function()
         document.get_schema({}, "x")
      end)
   end)
end)
