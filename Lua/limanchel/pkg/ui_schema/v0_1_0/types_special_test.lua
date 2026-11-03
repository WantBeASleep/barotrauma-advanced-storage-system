local busted = require("busted")
local assert = require("luassert")
local types_special = require("limanchel.pkg.ui_schema.v0_1_0.types_special")
local registry = require("limanchel.pkg.ui_schema.v0_1_0.registry")
local test_support = require("limanchel.pkg.ui_schema.v0_1_0.test_support")
local describe, it = busted.describe, busted.it

local function setup()
   local backend, reg = test_support.new_backend(), registry.new()
   function backend:remove_message_box(object)
      self.closed = object
   end
   function backend:clear_context_menu(object)
      if self.current_menu == object then
         self.current_menu = nil
      end
   end
   function backend:new_array(name, entries)
      return { array_type = name, entries = entries }
   end
   types_special.register(reg, backend)
   return backend, reg
end

describe("Специальные объекты", function()
   local cases = {
      { "MessageBox", { headerText = "Заголовок", text = "Текст" }, "none" },
      { "ContextMenu", { header = "Меню", options = {} }, "none" },
      { "VideoPlayer", {}, "none" },
      { "Graph", {}, "none" },
      { "SerializableEntityEditor", { entity = {}, inGame = true, showName = true }, "parent" },
      { "SlideshowPlayer", { prefab = {} }, "new" },
   }
   for _, case in ipairs(cases) do
      it("создаёт и очищает " .. case[1], function()
         local backend, reg = setup()
         local descriptor = reg:get_type(case[1])
         assert.are.equal(case[3], descriptor.rect_mode)
         assert(descriptor.validate(case[2], "constructor"))
         local params = { values = case[2], present = {}, variant = "default" }
         for field in pairs(case[2]) do
            params.present[field] = true
         end
         local object = assert(descriptor.create(params, {}, { defer_cleanup = function() end }))
         descriptor.destroy(object)
         if case[1] == "VideoPlayer" then
            assert.is_true(object.removed)
         end
         if case[1] == "MessageBox" then
            assert.is_true(rawequal(object, backend.closed))
         end
         if case[1] == "ContextMenu" then
            assert.are.equal("Barotrauma.ContextMenuOption", object.args[4].array_type)
         end
      end)
   end

   it("не закрывает чужое активное контекстное меню", function()
      local backend, reg = setup()
      local other = {}
      backend.current_menu = other
      reg:get_type("ContextMenu").destroy({})
      assert.is_true(rawequal(other, backend.current_menu))
   end)

   it("возвращает внутренние области MessageBox", function()
      local _, reg = setup()
      local object = { Content = { RectTransform = {} }, InnerFrame = { RectTransform = {} } }
      assert.is_true(rawequal(object.Content.RectTransform, reg:get_type("MessageBox").child_parent(object)))
      assert.is_true(
         rawequal(object.InnerFrame.RectTransform, reg:get_type("MessageBox").child_parent(object, "inner"))
      )
   end)
end)
