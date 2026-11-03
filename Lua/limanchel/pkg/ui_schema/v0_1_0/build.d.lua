---@meta limanchel.pkg.ui_schema.v0_1_0.build
---@class ui_schema.View
---@field root? any Корневой игровой объект, отсутствует после очистки.
---@field by_id table<string, any> Индекс исходных объектов; не изменяется потребителем.
---@field get fun(self: ui_schema.View, id: string): any Ошибка при отсутствии имени или после очистки.
---@field dispose fun(self: ui_schema.View): boolean?, goerrors.Error? Очистка; повторный вызов разрешён.
---@class ui_schema.Build
---@field run fun(doc: ui_schema.Document, name: string, parent: any, options: table?, reg: ui_schema.Registry, backend: table): ui_schema.View?, goerrors.Error?
local build = {}
return build
