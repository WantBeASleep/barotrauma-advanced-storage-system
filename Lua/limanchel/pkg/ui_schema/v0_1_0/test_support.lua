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
   return { TopLeft = 0, Center = 5, Left = 1, CenterLeft = 3, Int = 0, Automatic = 0, None = 0, Default = 0 }
end

function Backend:get_type(name)
   return function(...)
      local args = table.pack(...)
      local object = self:new_object(name, args[1])
      object.args = args
      object.Content = { RectTransform = { Children = {} } }
      object.InnerFrame = { RectTransform = { Children = {} } }
      object.ListBox = { Content = object.Content, RectTransform = { Children = {} } }
      object.TextBlock = {}
      function object.Dispose()
         object.disposed = true
      end
      function object.Remove()
         object.removed = true
      end
      return object
   end
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
