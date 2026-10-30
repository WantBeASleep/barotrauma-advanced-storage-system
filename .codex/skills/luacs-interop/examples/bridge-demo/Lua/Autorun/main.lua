-- Пример: самостоятельный autorun, не переиспользуемый Lua-пакет.
assert(CSActive, "BridgeDemo requires C# execution enabled on this side")

for _, type_name in ipairs({
   "BridgeDemo.Address", "BridgeDemo.Line", "BridgeDemo.Request",
   "BridgeDemo.Result", "BridgeDemo.Api", "BridgeDemo.Publisher", "BridgeDemo.Line[]",
}) do
   LuaUserData.RegisterType(type_name)
end

local Address = LuaUserData.CreateStatic("BridgeDemo.Address")
local Line = LuaUserData.CreateStatic("BridgeDemo.Line")
local Request = LuaUserData.CreateStatic("BridgeDemo.Request")
local Api = LuaUserData.CreateStatic("BridgeDemo.Api")
local Publisher = LuaUserData.CreateStatic("BridgeDemo.Publisher")

local destination = Address()
destination.Label = "cargo"
local first = Line("steel", 2)
local second = Line.__new()
second.Name = "copper"
second.Quantity = 3
local request = Request()
request.Destination = destination
request.Lines = { first, second }
request.Limit = nil
local result = Api.Process(request)
assert(result.Label == "cargo" and result.Total == 5)

-- Массив зарегистрирован как userdata; IEnumerable даёт итератор значений.
local count = 0
for line in result.Lines do
   count = count + 1
   assert(line.Quantity > 0)
end
assert(count == 2)

---@param value any BridgeDemo.Result
---@return integer
local function on_result(value)
   return value.Total + 1
end
assert(Api.ProcessAndNotify(request, on_result) == 6)
assert(Api.CreateLine("factory", 4).Quantity == 4)
assert(Api.LineFromTable({ name = "adapter", quantity = 7 }).Quantity == 7)

local publisher = Publisher()
local received = 0
---@param value any BridgeDemo.Result
local function on_completed(value)
   received = received + value.Total
end
publisher.Completed.add(on_completed)
publisher:Publish(result)
publisher.Completed.remove(on_completed)
publisher:Publish(result)
publisher:Dispose()
assert(received == 5)
print("BridgeDemo PASS: total=5, callback=6, event=5")
