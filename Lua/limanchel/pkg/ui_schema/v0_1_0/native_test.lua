local busted = require("busted")
local assert = require("luassert")
local native = require("limanchel.pkg.ui_schema.v0_1_0.native")
local describe, it = busted.describe, busted.it

describe("Нативный доступ", function()
   it(
      "восстанавливает регистрацию списка после локального доступа к окнам",
      function()
         local registered = false
         local removed
         local managed = {
            Remove = function(object)
               removed = object
            end,
         }
         local api = { LuaUserData = {}, GUI = { MessageBox = {} } }
         function api.LuaUserData.IsRegistered()
            return registered
         end
         function api.LuaUserData.RegisterType()
            registered = true
         end
         function api.LuaUserData.UnregisterType()
            registered = false
         end
         setmetatable(api.GUI.MessageBox, {
            __index = function(_, field)
               if field == "MessageBoxes" then
                  assert.is_true(registered)
                  return managed
               end
            end,
         })
         local object = {}
         native.new(api):remove_message_box(object)
         assert.is_false(registered)
         assert.is_true(rawequal(object, removed))
      end
   )
   it("не обращается к GUI при создании backend", function()
      assert.is_not_nil(native.new())
   end)

   it("пишет вложенный struct обратно владельцу", function()
      local point = { X = 1, Y = 2 }
      function point:GetType()
         return { IsValueType = true }
      end
      local assigned
      local owner = setmetatable({}, {
         __index = function(_, key)
            if key == "Offset" then
               local copy = { X = point.X, Y = point.Y, GetType = point.GetType }
               return copy
            end
         end,
         __newindex = function(_, key, value)
            if key == "Offset" then
               assigned = value
            end
         end,
      })
      native.new():write_member(owner, "Offset.X", 9)
      assert.are.equal(9, assigned.X)
      assert.are.equal(2, assigned.Y)
   end)

   it("выбирает целочисленную перегрузку Color", function()
      local api = {}
      function api.Int32(value)
         return { integer = value }
      end
      function api.Color(...)
         return { ... }
      end
      local color = native.new(api):new_value("Color", { 1, 2, 3, 255 })
      assert.are.equal(1, color[1].integer)
      assert.are.equal(255, color[4].integer)
   end)
end)
