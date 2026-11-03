local types_controls = {}
local types_basic = require("limanchel.pkg.ui_schema.v0_1_0.types_basic")

function types_controls.register(reg, backend)
   local left = types_basic.enum_default(backend, "Alignment", "Left")
   local center = types_basic.enum_default(backend, "Alignment", "Center")
   local no_scaling = types_basic.enum_default(backend, "ScalingMode", "None")
   local recipes = {
      TextBox = {
         variants = {
            default = {
               parameters = {
                  "text",
                  "textColor",
                  "font",
                  "textAlignment",
                  "wrap",
                  "style",
                  "color",
                  "createClearButton",
                  "createPenIcon",
               },
               defaults = {
                  text = "",
                  textAlignment = left,
                  wrap = false,
                  style = "",
                  createClearButton = false,
                  createPenIcon = true,
               },
            },
         },
      },
      NumberInput = {
         variants = {
            default = {
               parameters = {
                  "inputType",
                  "style",
                  "textAlignment",
                  "relativeButtonAreaWidth",
                  "buttonVisibility",
                  "customPlusMinusButtons",
               },
               required = { "inputType" },
               defaults = {
                  style = "",
                  textAlignment = center,
                  buttonVisibility = types_basic.enum_default(backend, "ButtonVisibility", "Automatic"),
               },
            },
         },
      },
      TickBox = {
         variants = {
            default = { parameters = { "label", "font", "style" }, required = { "label" }, defaults = { style = "" } },
         },
      },
      Image = {
         choose = function(constructor)
            local variant = constructor.sprite ~= nil and "sprite" or "style"
            if type(constructor.scaleToFit) == "boolean" then
               variant = variant .. "_bool"
            end
            return variant
         end,
         variants = {
            sprite = {
               parameters = { "sprite", "sourceRect", "scaleToFit" },
               required = { "sprite" },
               defaults = { scaleToFit = no_scaling },
            },
            style = { parameters = { "style", "scaleToFit" }, defaults = { style = "", scaleToFit = no_scaling } },
            sprite_bool = {
               parameters = { "sprite", "scaleToFit", "sourceRect" },
               required = { "sprite", "scaleToFit" },
            },
            style_bool = {
               parameters = { "style", "scaleToFit" },
               required = { "scaleToFit" },
               defaults = { style = "" },
            },
         },
      },
      ListBox = {
         slots = {
            default = "Content.RectTransform",
            content = "Content.RectTransform",
            background = "ContentBackground.RectTransform",
            scrollbar = "ScrollBar.RectTransform",
         },
         variants = {
            default = {
               parameters = { "isHorizontal", "color", "style", "isScrollBarOnDefaultSide", "useMouseDownToSelect" },
               defaults = {
                  isHorizontal = false,
                  style = "",
                  isScrollBarOnDefaultSide = true,
                  useMouseDownToSelect = false,
               },
            },
         },
      },
      DropDown = {
         slots = {
            default = "ListBox.Content.RectTransform",
            content = "ListBox.Content.RectTransform",
            list = "ListBox.RectTransform",
         },
         variants = {
            default = {
               parameters = {
                  "text",
                  "elementCount",
                  "style",
                  "selectMultiple",
                  "dropAbove",
                  "textAlignment",
                  "listBoxScale",
               },
               defaults = {
                  elementCount = 4,
                  style = "",
                  selectMultiple = false,
                  dropAbove = false,
                  textAlignment = types_basic.enum_default(backend, "Alignment", "CenterLeft"),
                  listBoxScale = 1,
               },
            },
         },
         destroy = function(object)
            object.Dropped = false
         end,
      },
      ScrollBar = {
         variants = {
            default = {
               parameters = { "barSize", "color", "style", "isHorizontal" },
               defaults = { barSize = 1, style = "" },
            },
         },
      },
      ProgressBar = {
         variants = {
            default = {
               parameters = { "barSize", "color", "style", "showFrame" },
               required = { "barSize" },
               defaults = { style = "", showFrame = true },
            },
         },
      },
      ColorPicker = {
         variants = { default = { parameters = { "style" } } },
         destroy = function(object)
            object.Dispose()
         end,
      },
      CustomComponent = { variants = { default = { parameters = { "onDraw", "onUpdate" } } } },
      ScissorComponent = { variants = { default = { parameters = {} } } },
      DragHandle = {
         variants = {
            default = {
               parameters = { "elementToMove", "style" },
               required = { "elementToMove" },
               defaults = { style = "GUIDragIndicator" },
            },
         },
      },
   }
   for name, recipe in pairs(recipes) do
      reg:register_type(name, types_basic.describe(backend, name, recipe))
   end
end

return types_controls
