local types_special = {}
local types_basic = require("limanchel.pkg.ui_schema.v0_1_0.types_basic")
local values = require("limanchel.pkg.ui_schema.v0_1_0.values")
local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")

local function context_options(reg, backend)
   reg:register_value_type("ContextMenuOption", function(input, context)
      if type(input) ~= "table" then
         return nil, goerrors.new("ContextMenuOption требует объект")
      end
      for key in pairs(input) do
         if key ~= "label" and key ~= "isEnabled" and key ~= "onSelected" and key ~= "subOptions" then
            return nil, goerrors.new("неизвестное поле ContextMenuOption: " .. tostring(key))
         end
      end
      if
         input.label == nil
         or (input.onSelected == nil and input.subOptions == nil)
         or (input.onSelected ~= nil and input.subOptions ~= nil)
      then
         return nil,
            goerrors.new("ContextMenuOption требует label и ровно одно из onSelected/subOptions")
      end
      local converted, err = values.resolve(input, context, "ContextMenuOption")
      if err then
         return nil, err
      end
      local enabled = converted.isEnabled
      if enabled == nil then
         enabled = true
      end
      local action = converted.onSelected
      if converted.subOptions then
         action = backend:new_array("Barotrauma.ContextMenuOption", converted.subOptions)
      end
      return backend:get_type("ContextMenuOption")(converted.label, enabled, action)
   end)
end

function types_special.register(reg, backend)
   local default_box = types_basic.enum_default(backend, "MessageBoxType", "Default")
   local top_left = types_basic.enum_default(backend, "Alignment", "TopLeft")
   local recipes = {
      MessageBox = {
         track_creation = true,
         rect_mode = "none",
         pass_rect = false,
         slots = {
            default = "Content.RectTransform",
            content = "Content.RectTransform",
            inner = "InnerFrame.RectTransform",
         },
         choose = function(constructor)
            if constructor.hintIdentifier ~= nil then
               return "hint"
            end
            if constructor.buttons ~= nil then
               return "buttons"
            end
            return "simple"
         end,
         variants = {
            simple = {
               parameters = { "headerText", "text", "relativeSize", "minSize", "type" },
               required = { "headerText", "text" },
               defaults = { type = default_box },
            },
            hint = {
               parameters = { "hintIdentifier", "text", "icon" },
               required = { "hintIdentifier", "text", "icon" },
            },
            buttons = {
               parameters = {
                  "headerText",
                  "text",
                  "buttons",
                  "relativeSize",
                  "minSize",
                  "textAlignment",
                  "type",
                  "tag",
                  "icon",
                  "iconStyle",
                  "backgroundIcon",
                  "autoCloseCondition",
                  "hideCloseButton",
               },
               required = { "headerText", "text", "buttons" },
               defaults = {
                  textAlignment = top_left,
                  type = default_box,
                  tag = "",
                  iconStyle = "",
                  hideCloseButton = false,
               },
            },
         },
         destroy = function(object)
            backend:remove_message_box(object)
         end,
      },
      ContextMenu = {
         track_creation = true,
         rect_mode = "none",
         pass_rect = false,
         variants = {
            default = {
               parameters = { "position", "header", "style", "options" },
               required = { "header", "options" },
               defaults = { style = "GUIToolTip" },
            },
         },
         destroy = function(object)
            backend:clear_context_menu(object)
         end,
      },
      VideoPlayer = {
         rect_mode = "none",
         pass_rect = false,
         slots = {},
         variants = { default = { parameters = {} } },
         destroy = function(object)
            object.Remove()
         end,
      },
      Graph = {
         rect_mode = "none",
         pass_rect = false,
         slots = {},
         variants = { default = { parameters = { "arraySize" }, defaults = { arraySize = 100 } } },
      },
      SerializableEntityEditor = {
         track_creation = true,
         rect_mode = "parent",
         choose = function(constructor)
            return constructor.properties ~= nil and "properties" or "in_game"
         end,
         variants = {
            in_game = {
               parameters = {
                  "entity",
                  "inGame",
                  "showName",
                  "style",
                  "elementHeight",
                  "titleFont",
                  "dimOutDefaultValues",
               },
               required = { "entity", "inGame", "showName" },
               defaults = { style = "", elementHeight = 24, dimOutDefaultValues = true },
            },
            properties = {
               parameters = {
                  "entity",
                  "properties",
                  "showName",
                  "style",
                  "elementHeight",
                  "titleFont",
                  "dimOutDefaultValues",
               },
               required = { "entity", "properties", "showName" },
               defaults = { style = "", elementHeight = 24, dimOutDefaultValues = true },
            },
         },
      },
      SlideshowPlayer = { variants = { default = { parameters = { "prefab" }, required = { "prefab" } } } },
   }
   for name, recipe in pairs(recipes) do
      local descriptor = types_basic.describe(backend, name, recipe)
      if name == "ContextMenu" then
         local create = descriptor.create
         descriptor.create = function(params, rect, context)
            local args = {}
            for key, value in pairs(params.values) do
               args[key] = value
            end
            args.options = backend:new_array("Barotrauma.ContextMenuOption", args.options)
            return create({ values = args, present = params.present, variant = params.variant }, rect, context)
         end
      end
      reg:register_type(name, descriptor)
   end
   context_options(reg, backend)
end

return types_special
