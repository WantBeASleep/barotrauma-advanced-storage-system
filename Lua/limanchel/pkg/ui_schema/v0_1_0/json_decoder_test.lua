local busted = require("busted")
local assert = require("luassert")
local json_decoder = require("limanchel.pkg.ui_schema.v0_1_0.json_decoder")

local describe, it = busted.describe, busted.it

describe("Разбор JSON без игры", function()
   it("различает формы и сохраняет ложь и ноль", function()
      local value, err = json_decoder.decode("{\"a\":[],\"b\":{},\"c\":null,\"d\":false,\"n\":0}")
      assert.is_nil(err)
      assert.are.equal("array", json_decoder.kind(value.a))
      assert.are.equal("object", json_decoder.kind(value.b))
      assert.are.equal("null", json_decoder.kind(value.c))
      assert.is_false(value.d)
      assert.are.equal(0, value.n)
      assert.is_nil(value.a[0])
   end)

   it("читает Unicode и пары суррогатов", function()
      local value = assert(json_decoder.decode("\"Привет \\uD83D\\uDE00\""))
      assert.are.equal("Привет 😀", value)
   end)

   for _, text in ipairs({ "{\"x\":1,}", "[1,]", "//comment\n{}", "{} {}", "{\"x\":", "01" }) do
      it("отклоняет некорректный JSON: " .. text, function()
         local value, err = json_decoder.decode(text)
         assert.is_nil(value)
         assert.matches("JSON", err:error(), 1, true)
         assert.matches("%d", err:error())
      end)
   end

   it("проверяет тип аргумента", function()
      assert.has_error(function()
         json_decoder.decode({})
      end)
   end)
end)
