---@meta limanchel.pkg.ui_schema.v0_1_0.values
---@class ui_schema.Values
---@field resolve fun(spec: any, context: table, path: string): any, goerrors.Error? Успешное значение может быть nil или false.
---@field register_defaults fun(reg: ui_schema.Registry, backend: table) Внутренние преобразователи, без создания GUI.
local values = {}
return values
