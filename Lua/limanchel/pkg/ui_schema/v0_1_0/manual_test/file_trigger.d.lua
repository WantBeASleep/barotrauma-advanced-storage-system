---@meta limanchel.pkg.ui_schema.v0_1_0.manual_test.file_trigger
---@class ui_schema.ManualTrigger
---@field accept fun(self: ui_schema.ManualTrigger, text: string): boolean? Принимает только команды примеров с новым номером.
---@class ui_schema.ManualTriggerLib
---@field new fun(callback: fun(args: string[])): ui_schema.ManualTrigger
local file_trigger = {}
return file_trigger
