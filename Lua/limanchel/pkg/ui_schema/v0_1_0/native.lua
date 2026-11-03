local native = {}
local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")
local Backend = {}
local Backend_mt = { __index = Backend }

local enum_names = {
   Anchor = "Barotrauma.Anchor",
   Pivot = "Barotrauma.Pivot",
   Alignment = "Barotrauma.Alignment",
   ScaleBasis = "Barotrauma.ScaleBasis",
   NumberType = "Barotrauma.NumberType",
   ButtonVisibility = "Barotrauma.GUINumberInput+ButtonVisibility",
   ScalingMode = "Barotrauma.GUIImage+ScalingMode",
   MessageBoxType = "Barotrauma.GUIMessageBox+Type",
   SoundType = "Barotrauma.GUISoundType",
   CursorState = "Barotrauma.CursorState",
}

local function optional(object, name)
   local ok, value = pcall(function()
      return object[name]
   end)
   if ok then
      return value
   end
end

local function game_environment()
   return {
      CLIENT = CLIENT,
      GUI = GUI,
      LuaUserData = LuaUserData,
      Point = Point,
      Vector2 = Vector2,
      Vector3 = Vector3,
      Vector4 = Vector4,
      Rectangle = Rectangle,
      Color = Color,
      Identifier = Identifier,
      Int32 = Int32,
   }
end

local function environment(self)
   return self.environment or game_environment()
end

local function is_struct(self, value)
   return optional(value, "GetType") ~= nil and environment(self).LuaUserData.IsTargetType(value, "System.ValueType")
end

function native.new(api)
   assert(api == nil or type(api) == "table", "окружение API должно быть таблицей")
   return setmetatable({ enums = {}, environment = api }, Backend_mt)
end
function Backend:is_client()
   return environment(self).CLIENT == true
end

function Backend:get_type(name)
   local gui = environment(self).GUI
   assert(gui ~= nil and gui[name] ~= nil, "GUI-тип недоступен: " .. name)
   return gui[name]
end

function Backend:get_enum(name)
   if not self.enums[name] then
      local api = environment(self).LuaUserData
      assert(api ~= nil, "LuaUserData недоступен")
      self.enums[name] = api.CreateEnumTable(enum_names[name] or name)
   end
   return self.enums[name]
end

function Backend:new_array(type_name, entries)
   local api = environment(self).LuaUserData
   local array_name = type_name .. "[]"
   local existed = api.IsRegistered(array_name)
   local descriptor = api.RegisterType(array_name)
   local ok, result = pcall(function()
      return api.CreateUserDataFromDescriptor(entries, descriptor)
   end)
   if not existed then
      api.UnregisterType(array_name)
   end
   if not ok then
      error(tostring(result), 0)
   end
   return result
end

function Backend:remove_message_box(object)
   local env = environment(self)
   local api = env.LuaUserData
   local type_name = "System.Collections.Generic.List`1[[Barotrauma.GUIComponent, Barotrauma]]"
   local existed = api.IsRegistered(type_name)
   if not existed then
      api.RegisterType(type_name)
   end
   local ok, list = pcall(function()
      return env.GUI.MessageBox.MessageBoxes
   end)
   if not existed then
      api.UnregisterType(type_name)
   end
   if not ok then
      error(list, 0)
   end
   list.Remove(object)
end

function Backend:clear_context_menu(object)
   local menu = self:get_type("ContextMenu")
   if menu.CurrentContextMenu == object then
      menu.CurrentContextMenu = nil
   end
end

function Backend:new_value(name, args)
   local constructor = environment(self)[name]
   assert(constructor ~= nil, "тип значения недоступен: " .. name)
   if name == "Color" then
      local int32 = environment(self).Int32
      assert(int32 ~= nil, "Int32 недоступен для Color")
      return constructor(int32(args[1]), int32(args[2]), int32(args[3]), int32(args[4]))
   end
   return constructor(table.unpack(args, 1, #args))
end

function Backend:new_rect(spec, parent)
   local size = spec.size
   assert(size ~= nil, "rect.size обязателен")
   local kind = environment(self).LuaUserData.TypeOf(size)
   kind = kind:match("[^%.]+$")
   assert(kind == "Point" or kind == "Vector2", "rect.size должен быть Point или Vector2")
   local anchor = spec.anchor
   if anchor == nil then
      anchor = self:get_enum("Anchor").TopLeft
   end
   local basis = spec.scale_basis
   if basis == nil then
      basis = self:get_enum("ScaleBasis").Normal
   end
   local constructor = self:get_type("RectTransform")
   if kind == "Point" then
      return constructor(size, parent, anchor, spec.pivot, basis)
   end
   return constructor(size, parent, anchor, spec.pivot, nil, nil, basis)
end

function Backend:read_member(object, path)
   assert(type(path) == "string" and path ~= "", "нужен путь члена")
   local current = object
   for name in path:gmatch("[^%.]+") do
      assert(current ~= nil, "нет промежуточного объекта: " .. path)
      current = current[name]
   end
   return current
end

function Backend:write_member(object, path, value)
   local parts = {}
   for name in path:gmatch("[^%.]+") do
      parts[#parts + 1] = name
   end
   assert(#parts > 0, "нужен путь свойства")
   local owners = { object }
   for i = 1, #parts - 1 do
      owners[i + 1] = owners[i][parts[i]]
      assert(owners[i + 1] ~= nil, "нет промежуточного объекта: " .. path)
   end
   owners[#parts][parts[#parts]] = value
   for i = #parts - 1, 1, -1 do
      if is_struct(self, owners[i + 1]) then
         owners[i][parts[i]] = owners[i + 1]
      end
   end
end

-- Снимок делается до входа в конструктор, который сам прикрепляет корень.
function Backend:creation_cleanup(name, parent, destroy)
   if name ~= "SerializableEntityEditor" then
      parent = environment(self).GUI.Canvas.Instance
   end
   local before = {}
   for _, child in ipairs(parent.Children) do
      before[#before + 1] = child
   end
   local expected = "Barotrauma." .. (name == "SerializableEntityEditor" and name or "GUI" .. name)
   return function()
      local created = {}
      for _, child in ipairs(parent.Children) do
         local existed = false
         for _, original in ipairs(before) do
            if child == original then
               existed = true
               break
            end
         end
         local object = child.GUIComponent
         if not existed and object and environment(self).LuaUserData.TypeOf(object) == expected then
            created[#created + 1] = object
         end
      end
      local errors = {}
      for _, object in ipairs(created) do
         local ok, result, err = pcall(destroy, object)
         if not ok or err then
            errors[#errors + 1] = goerrors.new(tostring(ok and err or result))
            local detached, detail, detach_err = pcall(self.detach, self, object)
            if not detached or detach_err then
               errors[#errors + 1] = goerrors.new(tostring(detached and detach_err or detail))
            end
         end
      end
      if #errors > 0 then
         return nil, goerrors.wrap("Откат частичного " .. name, table.unpack(errors))
      end
      return true
   end
end

function Backend:detach(object)
   local rect = optional(object, "RectTransform")
   local component = object
   if not rect and optional(object, "Children") ~= nil then
      rect = object
      component = optional(rect, "GUIComponent")
   end
   if not rect then
      return true
   end
   if component then
      local remove = optional(component, "RemoveFromGUIUpdateList")
      if remove then
         remove(true)
      end
      component.Visible = false
   end
   local gui = environment(self).GUI
   local dispatcher = gui and gui.KeyboardDispatcher
   local subscriber = dispatcher and dispatcher.Subscriber
   local current = subscriber and optional(subscriber, "RectTransform")
   while current do
      if current == rect then
         dispatcher.Subscriber = nil
         break
      end
      current = current.Parent
   end
   rect.Parent = nil
   return true
end

return native
