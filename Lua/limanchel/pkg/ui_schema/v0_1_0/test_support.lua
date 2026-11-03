local test_support = {}
local assert = require("luassert")
local Backend = {}
local Backend_mt = { __index = Backend }

function test_support.new_backend()
   return setmetatable({ created = {}, writes = {}, destroyed = {}, client = true }, Backend_mt)
end

function Backend:is_client()
   return self.client
end
function Backend:new_value(name, args)
   return { type = name, args = args }
end

function Backend:new_rect(spec, parent)
   local rect = { Parent = parent, Children = {}, spec = spec }
   if parent then
      parent.Children = parent.Children or {}
      parent.Children[#parent.Children + 1] = rect
   end
   return rect
end

function Backend:new_object(name, rect)
   local object = { type = name, RectTransform = rect }
   self.created[#self.created + 1] = object
   return object
end

function Backend:get_enum()
   return {
      TopLeft = 0,
      TopCenter = 1,
      TopRight = 2,
      Center = 4,
      CenterLeft = 3,
      CenterRight = 5,
      BottomLeft = 6,
      BottomCenter = 7,
      BottomRight = 8,
      Left = 1,
      Int = 0,
      Automatic = 0,
      None = 0,
      Default = 0,
      Normal = 0,
   }
end

function Backend:get_type(name)
   return function(...)
      local args = table.pack(...)
      local rect = args[1]
      if name == "MessageBox" or name == "ContextMenu" then
         rect = { Children = {} }
      end
      if name == "Graph" or name == "VideoPlayer" or name == "ContextMenuOption" then
         rect = nil
      end
      local object = self:new_object(name, rect)
      object.args = args
      object.Content = { RectTransform = { Children = {} } }
      object.InnerFrame = { RectTransform = { Children = {} } }
      object.ListBox = { Content = object.Content, RectTransform = { Children = {} } }
      object.TextBlock = {}
      object.Text = type(args[2]) == "string" and args[2] or ""
      object.BarSize = type(args[2]) == "number" and args[2] or 0
      object.BarScroll = 0
      object.Selected = false
      object.IntValue = 1
      object.items = {}
      function object.AddItem(text, data)
         object.items[#object.items + 1] = { text = text, data = data }
      end
      function object.Dispose()
         object.disposed = true
      end
      function object.Remove()
         object.removed = true
      end
      return object
   end
end

function test_support.new_builder()
   local registry = require("limanchel.pkg.ui_schema.v0_1_0.registry")
   local values = require("limanchel.pkg.ui_schema.v0_1_0.values")
   local types_basic = require("limanchel.pkg.ui_schema.v0_1_0.types_basic")
   local types_controls = require("limanchel.pkg.ui_schema.v0_1_0.types_controls")
   local document = require("limanchel.pkg.ui_schema.v0_1_0.document")
   local build = require("limanchel.pkg.ui_schema.v0_1_0.build")
   local reg, backend = registry.new(), test_support.new_backend()
   values.register_defaults(reg, backend)
   for _, name in ipairs({ "Anchor", "Pivot", "Alignment", "ScaleBasis", "NumberType", "ScalingMode" }) do
      reg:register_enum(name, backend:get_enum(name))
   end
   types_basic.register(reg, backend)
   types_controls.register(reg, backend)
   local builder = {}
   function builder:parse(text)
      return document.parse(text)
   end
   function builder:build(doc, name, parent, context)
      return build.run(doc, name, parent, context, reg, backend)
   end
   function builder:register_type(name, descriptor)
      reg:register_type(name, descriptor)
   end
   return builder, backend
end

function test_support.new_host(backend)
   local host = {
      parent = { Children = {} },
      clock = 0,
      callbacks = {},
      commands = {},
      resources = { item_sprite = {}, draw = function() end },
   }
   function host:add_command(name, _, callback)
      assert(self.commands[name] == nil)
      self.commands[name] = callback
   end
   function host:remove_command(name)
      self.commands[name] = nil
   end
   function host:subscribe(event, callback)
      local token = { event = event, callback = callback }
      self.callbacks[token] = true
      return token
   end
   function host:unsubscribe(token)
      self.callbacks[token] = nil
   end
   function host:now()
      return self.clock
   end
   function host:fire(event)
      for token in pairs(self.callbacks) do
         if token.event == event then
            token.callback()
         end
      end
   end
   function host:create_badge(_, rect)
      return backend:new_object("DemoBadge", rect)
   end
   function host:detach(object)
      return backend:detach(object)
   end
   return host
end

function Backend:read_member(object, path)
   local current = object
   for part in path:gmatch("[^%.]+") do
      if current == nil then
         error("нет промежуточного объекта: " .. path)
      end
      current = current[part]
   end
   return current
end

function Backend:write_member(object, path, value)
   if self.fail_write == path then
      error("отказ свойства " .. path)
   end
   local prefix, member = path:match("^(.*)%.([^%.]+)$")
   local target = prefix and self:read_member(object, prefix) or object
   target[member or path] = value
   self.writes[#self.writes + 1] = { object = object, member = path, value = value }
end

function Backend:detach(object)
   local rect = object.RectTransform or object
   if rect.Parent and rect.Parent.Children then
      for i, child in ipairs(rect.Parent.Children) do
         if rawequal(child, rect) then
            table.remove(rect.Parent.Children, i)
            break
         end
      end
   end
   rect.Parent = nil
   self.destroyed[#self.destroyed + 1] = object
end

function test_support.assert_error_path(err, path)
   assert.is_not_nil(err)
   assert.matches(path, err:error(), 1, true)
end

function test_support.descriptor(backend)
   local descriptor = { rect_mode = "new" }
   function descriptor.validate()
      return true
   end
   function descriptor.create(params, rect)
      local object = backend:new_object("Panel", rect)
      object.params = params
      return object
   end
   function descriptor.child_parent(object, slot)
      if slot ~= nil and slot ~= "content" then
         error("неизвестная область " .. slot)
      end
      return object.RectTransform
   end
   function descriptor.destroy(object)
      backend:detach(object)
      return true
   end
   return descriptor
end

return test_support
