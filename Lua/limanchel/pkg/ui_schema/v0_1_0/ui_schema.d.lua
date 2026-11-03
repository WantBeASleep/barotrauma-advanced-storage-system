---@meta limanchel.pkg.ui_schema.v0_1_0.ui_schema
---@class ui_schema.Context
---@field resources? table<string, any> Заимствованные игровые объекты и функции; пакет их не освобождает.
---@class ui_schema.Builder
---@field parse fun(self: ui_schema.Builder, json_text: string): ui_schema.Document?, goerrors.Error? Разбор строки без создания GUI.
---@field build fun(self: ui_schema.Builder, document: ui_schema.Document, component_name: string, parent: any, context?: ui_schema.Context): ui_schema.View?, goerrors.Error? Создание именованной заготовки.
---@field register_type fun(self: ui_schema.Builder, name: string, descriptor: ui_schema.Descriptor) Добавление независимого описания типа.
---@field register_value_type fun(self: ui_schema.Builder, name: string, converter: function)
---@field register_enum fun(self: ui_schema.Builder, name: string, values: table)
---@class ui_schema.Lib
---@field new fun(): ui_schema.Builder Без создания GUI и обращения к клиентскому API.
local ui_schema = {}
return ui_schema
