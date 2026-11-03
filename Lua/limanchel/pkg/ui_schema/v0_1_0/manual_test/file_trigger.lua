local file_trigger = {}
local Trigger = {}
local Trigger_mt = { __index = Trigger }

function file_trigger.new(callback)
   assert(type(callback) == "function", "нужен обработчик команды")
   return setmetatable({ callback = callback }, Trigger_mt)
end

function Trigger:accept(text)
   local id, operation, argument = text:match("^%s*(%d+)%s+(%a+)%s*([%w_]*)%s*$")
   if not id or id == self.last_id then
      return nil
   end
   if operation == "open" or operation == "step" then
      if argument == "" then
         return nil
      end
   elseif operation == "report" or operation == "close" or operation == "stop" then
      if argument ~= "" then
         return nil
      end
   else
      return nil
   end
   self.last_id = id
   self.callback({ operation, argument ~= "" and argument or nil })
   return true
end

return file_trigger
