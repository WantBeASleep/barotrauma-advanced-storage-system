local busted = require("busted")
local assert = require("luassert")
local ui_schema = require("limanchel.pkg.ui_schema.v0_1_0.ui_schema")
local describe, it = busted.describe, busted.it

describe("Публичный пакет", function()
   it("загружается и разбирает документ без GUI", function()
      local builder = ui_schema.new()
      local doc, err = builder:parse(
         "{\"schema_version\":1,\"components\":{\"x\":{\"type\":\"Frame\",\"rect\":{\"size\":{\"$type\":\"Point\",\"value\":[100,40]}}}}}"
      )
      assert.is_nil(err)
      assert.is_not_nil(doc)
      local view, build_err = builder:build(doc, "x", nil)
      assert.is_nil(view)
      assert.matches("клиент", build_err:error(), 1, true)
   end)
end)
