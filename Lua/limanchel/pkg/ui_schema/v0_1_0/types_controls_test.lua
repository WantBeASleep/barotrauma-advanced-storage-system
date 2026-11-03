local busted = require("busted")
local assert = require("luassert")
local types_controls = require("limanchel.pkg.ui_schema.v0_1_0.types_controls")
local registry = require("limanchel.pkg.ui_schema.v0_1_0.registry")
local test_support = require("limanchel.pkg.ui_schema.v0_1_0.test_support")
local describe, it = busted.describe, busted.it

describe("Основные элементы управления", function()
   local cases = {
      { "TextBox", {} },
      { "NumberInput", { inputType = 0 } },
      { "TickBox", { label = "Да" } },
      { "Image", { sprite = {} } },
      { "ListBox", {} },
      { "DropDown", {} },
      { "ScrollBar", {} },
      { "ProgressBar", { barSize = 0.5 } },
      { "ColorPicker", {} },
      { "CustomComponent", { onDraw = function() end } },
      { "ScissorComponent", {} },
      { "DragHandle", { elementToMove = {} } },
   }
   for _, case in ipairs(cases) do
      it("создаёт и удаляет исходный объект " .. case[1], function()
         local backend, reg = test_support.new_backend(), registry.new()
         types_controls.register(reg, backend)
         local descriptor = reg:get_type(case[1])
         assert(descriptor.validate(case[2], "constructor"))
         local params = { values = case[2], present = {}, variant = "default" }
         for field in pairs(case[2]) do
            params.present[field] = true
         end
         local rect = { Children = {} }
         local object = assert(descriptor.create(params, rect, { defer_cleanup = function() end }))
         assert.is_true(rawequal(rect, object.args[1]))
         descriptor.destroy(object)
         assert.is_true(rawequal(object, backend.destroyed[1]))
         if case[1] == "ColorPicker" then
            assert.is_true(object.disposed)
         end
         if case[1] == "Image" then
            assert.is_true(rawequal(case[2].sprite, object.args[2]))
         end
         if case[1] == "CustomComponent" then
            assert.is_true(rawequal(case[2].onDraw, object.args[2]))
         end
      end)
   end

   it("вставляет строки именно во внутреннюю область списка", function()
      local backend, reg = test_support.new_backend(), registry.new()
      types_controls.register(reg, backend)
      local descriptor = reg:get_type("ListBox")
      local list = { Content = { RectTransform = {} } }
      assert.is_true(rawequal(list.Content.RectTransform, descriptor.child_parent(list)))
      assert.is_true(rawequal(list.Content.RectTransform, descriptor.child_parent(list, "content")))
      local parent, err = descriptor.child_parent(list, "unknown")
      assert.is_nil(parent)
      assert.is_not_nil(err)
   end)

   it("отклоняет обязательные параметры и чужие варианты Image", function()
      local backend, reg = test_support.new_backend(), registry.new()
      types_controls.register(reg, backend)
      assert.is_nil(reg:get_type("ProgressBar").validate({}, "constructor"))
      assert.is_nil(reg:get_type("Image").validate({ variant = "sprite", style = "wrong" }, "constructor"))
   end)
end)
