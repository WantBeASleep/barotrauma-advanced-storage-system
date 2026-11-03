---@meta limanchel.pkg.ui_schema.v0_1_0.manual_test.runner
---@class ui_schema.ManualSession
---@field command fun(self: ui_schema.ManualSession, args: string[]) Исполнение команды примера без игровой консоли.
---@field open fun(self: ui_schema.ManualSession, name: string): boolean?, goerrors.Error?
---@field step fun(self: ui_schema.ManualSession, name: string): boolean?, goerrors.Error?
---@field report fun(self: ui_schema.ManualSession): table
---@field close fun(self: ui_schema.ManualSession): boolean?, goerrors.Error?
---@field stop fun(self: ui_schema.ManualSession): boolean?, goerrors.Error?
---@class ui_schema.ManualRunner
---@field start fun(options: table): ui_schema.ManualSession?, goerrors.Error? Явное подключение примеров, не вызывается загрузкой библиотеки.
local runner = {}
return runner
