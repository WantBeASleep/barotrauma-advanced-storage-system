local busted = require("busted")
local assert = require("luassert")
local build = require("limanchel.pkg.ui_schema.v0_1_0.build")
local document = require("limanchel.pkg.ui_schema.v0_1_0.document")
local registry = require("limanchel.pkg.ui_schema.v0_1_0.registry")
local values = require("limanchel.pkg.ui_schema.v0_1_0.values")
local basic = require("limanchel.pkg.ui_schema.v0_1_0.types_basic")
local controls = require("limanchel.pkg.ui_schema.v0_1_0.types_controls")
local special = require("limanchel.pkg.ui_schema.v0_1_0.types_special")
local native = require("limanchel.pkg.ui_schema.v0_1_0.native")
local support = require("limanchel.pkg.ui_schema.v0_1_0.test_support")
local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")
local describe, it = busted.describe, busted.it
local function doc(node)
   return assert(document.parse("{\"schema_version\":1,\"components\":{\"test\":" .. node .. "}}"))
end

describe("Регрессии итогового ревью", function()
   it("сохраняет перегрузку Image с enum и sourceRect", function()
      local backend, reg = support.new_backend(), registry.new()
      controls.register(reg, backend)
      local descriptor = reg:get_type("Image")
      local sprite, crop = {}, {}
      local object = descriptor.create({
         values = { sprite = sprite, sourceRect = crop, scaleToFit = 0 },
         present = { sprite = true, sourceRect = true, scaleToFit = true },
         variant = "default",
      }, {}, { defer_cleanup = function() end })
      assert.is_true(rawequal(crop, object.args[3]))
      assert.are.equal(0, object.args[4])
   end)

   it("разрешает раннюю ссылку внутри ContextMenuOption", function()
      local backend, reg = support.new_backend(), registry.new()
      function backend:new_array(_, entries)
         return entries
      end
      values.register_defaults(reg, backend)
      basic.register(reg, backend)
      special.register(reg, backend)
      local source = doc(
         [[{"type":"Frame","rect":{"size":{"$type":"Point","value":[300,200]}},"children":[{"type":"TextBlock","id":"title","rect":{"size":{"$type":"Point","value":[100,20]}},"constructor":{"text":"Пункт"}},{"type":"ContextMenu","id":"menu","constructor":{"header":"Меню","options":[{"$type":"ContextMenuOption","value":{"label":{"$ref":"title","member":"Text"},"onSelected":{"$resource":"click"}}}]}}]}]]
      )
      local view, err = build.run(source, "test", {}, { resources = { click = function() end } }, reg, backend)
      assert.is_nil(err)
      assert.are.equal("Пункт", view:get("menu").args[4][1].args[1])
      view:dispose()
   end)

   it("сохраняет возвращённую ошибку временной очистки", function()
      local backend, reg = support.new_backend(), registry.new()
      reg:register_type("Broken", {
         rect_mode = "none",
         validate = function()
            return true
         end,
         create = function(_, _, context)
            context.defer_cleanup(function()
               return nil, goerrors.new("cleanup-failed")
            end)
            error("factory-failed", 0)
         end,
         destroy = function() end,
         child_parent = function() end,
      })
      local view, err = build.run(doc("{\"type\":\"Broken\"}"), "test", {}, nil, reg, backend)
      assert.is_nil(view)
      assert.matches("factory-failed", err:error(), 1, true)
      assert.matches("cleanup-failed", err:error(), 1, true)
   end)

   for _, name in ipairs({ "ContextMenu", "MessageBox", "SerializableEntityEditor" }) do
      it(
         "откатывает частичный конструктор "
            .. name
            .. " и сохраняет чужое дерево",
         function()
            local foreign = { GUIComponent = { kind = "чужой" } }
            local parent = { Children = { foreign } }
            local api = { CLIENT = true, GUI = { Canvas = { Instance = parent } }, LuaUserData = {} }
            local backend = native.new(api)
            function api.LuaUserData.TypeOf(object)
               return object.kind
            end
            local native_name = name == "SerializableEntityEditor" and name or "GUI" .. name
            api.GUI[name] = setmetatable({}, {
               __call = function()
                  local rect = { Parent = parent, Children = {} }
                  rect.GUIComponent = { kind = "Barotrauma." .. native_name, RectTransform = rect }
                  parent.Children[#parent.Children + 1] = rect
                  error("native-failed", 0)
               end,
            })
            function backend:new_array(_, entries)
               return entries
            end
            function backend:remove_message_box() end
            function backend:clear_context_menu() end
            function backend:detach(object)
               local rect = object.RectTransform or object
               for i, child in ipairs(parent.Children) do
                  if child == rect then
                     table.remove(parent.Children, i)
                     break
                  end
               end
               rect.Parent = nil
               return true
            end
            local reg = registry.new()
            special.register(reg, backend)
            local args = name == "ContextMenu" and "\"header\":\"Тест\",\"options\":[]"
               or name == "MessageBox" and "\"headerText\":\"Тест\",\"text\":\"Текст\",\"type\":0"
               or "\"entity\":{\"$resource\":\"entity\"},\"inGame\":true,\"showName\":true"
            local view, err = build.run(
               doc("{\"type\":\"" .. name .. "\",\"constructor\":{" .. args .. "}}"),
               "test",
               parent,
               { resources = { entity = {} } },
               reg,
               backend
            )
            assert.is_nil(view)
            assert.matches("native-failed", err:error(), 1, true)
            assert.are.equal(1, #parent.Children)
            assert.is_true(rawequal(foreign, parent.Children[1]))
         end
      )
   end
end)
