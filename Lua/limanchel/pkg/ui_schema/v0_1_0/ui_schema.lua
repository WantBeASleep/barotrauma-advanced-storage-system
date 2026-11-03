local ui_schema = {}
local document = require("limanchel.pkg.ui_schema.v0_1_0.document")
local registry = require("limanchel.pkg.ui_schema.v0_1_0.registry")
local values = require("limanchel.pkg.ui_schema.v0_1_0.values")
local build = require("limanchel.pkg.ui_schema.v0_1_0.build")
local native = require("limanchel.pkg.ui_schema.v0_1_0.native")
local types_basic = require("limanchel.pkg.ui_schema.v0_1_0.types_basic")

local Builder = {}
local Builder_mt = { __index = Builder }

function ui_schema.new()
   local reg, backend = registry.new(), native.new()
   values.register_defaults(reg, backend)
   for _, name in ipairs({
      "Anchor",
      "Pivot",
      "Alignment",
      "ScaleBasis",
      "NumberType",
      "ButtonVisibility",
      "ScalingMode",
      "MessageBoxType",
      "SoundType",
      "CursorState",
   }) do
      reg:register_enum(
         name,
         setmetatable({}, {
            __index = function(_, member)
               return backend:get_enum(name)[member]
            end,
         })
      )
   end
   types_basic.register(reg, backend)
   return setmetatable({ registry = reg, backend = backend }, Builder_mt)
end

function Builder:parse(text)
   return document.parse(text)
end
function Builder:build(doc, name, parent, context)
   return build.run(doc, name, parent, context, self.registry, self.backend)
end
function Builder:register_type(name, descriptor)
   self.registry:register_type(name, descriptor)
end
function Builder:register_value_type(name, converter)
   self.registry:register_value_type(name, converter)
end
function Builder:register_enum(name, options)
   self.registry:register_enum(name, options)
end

return ui_schema
