local types_basic = {}
local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")

function types_basic.enum_default(backend, name, member)
   return function()
      return backend:get_enum(name)[member]
   end
end

function types_basic.describe(backend, name, recipe)
   local function select_variant(constructor)
      local variant = constructor.variant or "default"
      if variant == "default" and recipe.choose then
         variant = recipe.choose(constructor)
      end
      return recipe.variants[variant]
   end
   local descriptor = { rect_mode = recipe.rect_mode or "new", slots = recipe.slots or { default = "RectTransform" } }
   function descriptor.validate(constructor, path)
      local variant = select_variant(constructor)
      if not variant then
         return nil, goerrors.new(path .. ".variant: неизвестный вариант создания " .. name)
      end
      local known = { variant = true }
      for _, field in ipairs(variant.parameters) do
         known[field] = true
      end
      for field in pairs(constructor) do
         if not known[field] then
            return nil, goerrors.new(path .. "." .. field .. ": неизвестный параметр " .. name)
         end
      end
      for _, field in ipairs(variant.required or {}) do
         if constructor[field] == nil then
            return nil, goerrors.new(path .. "." .. field .. ": обязательный параметр")
         end
      end
      return true
   end
   function descriptor.create(params, rect, context)
      local selector = { variant = params.variant }
      for field in pairs(params.present) do
         selector[field] = true
      end
      local variant = select_variant(selector)
      local args, offset = {}, 0
      if recipe.pass_rect ~= false then
         args[1] = rect
         offset = 1
      end
      for i, field in ipairs(variant.parameters) do
         if params.present[field] then
            args[i + offset] = params.values[field]
         else
            local value = (variant.defaults or {})[field]
            if type(value) == "function" then
               value = value()
            end
            args[i + offset] = value
         end
      end
      local constructor = backend:get_type(name)
      local object = constructor(table.unpack(args, 1, #variant.parameters + offset))
      context.defer_cleanup(function()
         descriptor.destroy(object)
      end)
      if recipe.after_create then
         recipe.after_create(object, context)
      end
      return object
   end
   function descriptor.child_parent(object, slot)
      local path = descriptor.slots[slot or "default"]
      if not path then
         return nil, goerrors.new("неизвестная область " .. tostring(slot))
      end
      return backend:read_member(object, path)
   end
   function descriptor.destroy(object)
      if recipe.destroy then
         recipe.destroy(object)
      end
      return backend:detach(object)
   end
   return descriptor
end

function types_basic.register(reg, backend)
   local center = types_basic.enum_default(backend, "Alignment", "Center")
   local left = types_basic.enum_default(backend, "Alignment", "Left")
   local recipes = {
      Frame = { variants = { default = { parameters = { "style", "color" }, defaults = { style = "" } } } },
      LayoutGroup = {
         variants = {
            default = {
               parameters = { "isHorizontal", "childAnchor" },
               defaults = { isHorizontal = false, childAnchor = types_basic.enum_default(backend, "Anchor", "TopLeft") },
            },
         },
      },
      TextBlock = {
         variants = {
            default = {
               parameters = { "text", "textColor", "font", "textAlignment", "wrap", "style", "color" },
               required = { "text" },
               defaults = { textAlignment = left, wrap = false, style = "" },
            },
         },
      },
      Button = {
         choose = function(constructor)
            return constructor.text ~= nil and "text" or "empty"
         end,
         variants = {
            text = {
               parameters = { "text", "textAlignment", "style", "color" },
               required = { "text" },
               defaults = { textAlignment = center, style = "" },
            },
            empty = {
               parameters = { "textAlignment", "style", "color" },
               defaults = { textAlignment = center, style = "" },
            },
         },
      },
   }
   for name, recipe in pairs(recipes) do
      reg:register_type(name, types_basic.describe(backend, name, recipe))
   end
end

return types_basic
