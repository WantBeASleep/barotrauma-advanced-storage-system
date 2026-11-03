---@meta limanchel.pkg.ui_schema.v0_1_0.document
---@class ui_schema.Document Подготовленные данные; внутренние поля не являются API.
---@class ui_schema.DocumentLib
---@field parse fun(text: string): ui_schema.Document?, goerrors.Error? Проверка JSON и структуры.
---@field get_schema fun(doc: ui_schema.Document, name: string): table?, goerrors.Error? Внутренний доступ к узлу.
local document = {}
return document
