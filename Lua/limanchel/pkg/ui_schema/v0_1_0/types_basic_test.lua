local busted = require("busted")
local assert = require("luassert")
local types_basic = require("limanchel.pkg.ui_schema.v0_1_0.types_basic")
local registry = require("limanchel.pkg.ui_schema.v0_1_0.registry")
local test_support = require("limanchel.pkg.ui_schema.v0_1_0.test_support")
local describe, it = busted.describe, busted.it

describe("Базовые игровые компоненты", function()
   it("сохраняет nil посреди аргументов Frame", function()
      local backend = test_support.new_backend()
      local args
      function backend:get_type()
         return function(...)
            args = table.pack(...)
            return {}
         end
      end
      function backend:get_enum()
         return { Center = 5, TopLeft = 0, Left = 0 }
      end
      local reg = registry.new()
      types_basic.register(reg, backend)
      local descriptor = reg:get_type("Frame")
      local rect, color = {}, {}
      descriptor.create(
         { values = { color = color }, present = { style = true, color = true }, variant = "default" },
         rect,
         { defer_cleanup = function() end }
      )
      assert.are.equal(3, args.n)
      assert.is_true(rawequal(rect, args[1]))
      assert.is_nil(args[2])
      assert.is_true(rawequal(color, args[3]))
   end)

   it("проверяет варианты и параметры до вызова конструктора", function()
      local backend, reg = test_support.new_backend(), registry.new()
      types_basic.register(reg, backend)
      local valid, err = reg:get_type("Button").validate({ variant = "missing" }, "constructor")
      assert.is_nil(valid)
      assert.is_not_nil(err)
      valid, err = reg:get_type("Frame").validate({ unknown = 1 }, "constructor")
      assert.is_nil(valid)
      assert.is_not_nil(err)
   end)
end)
