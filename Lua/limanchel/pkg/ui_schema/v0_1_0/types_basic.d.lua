---@meta limanchel.pkg.ui_schema.v0_1_0.types_basic
---@class ui_schema.BasicTypes
---@field register fun(reg: ui_schema.Registry, backend: ui_schema.Native)
---@field describe fun(backend: ui_schema.Native, name: string, recipe: table): ui_schema.Descriptor Внутреннее описание нативных перегрузок.
---@field enum_default fun(backend: ui_schema.Native, name: string, member: string): function Ленивое значение по умолчанию.
local types_basic = {}
return types_basic
