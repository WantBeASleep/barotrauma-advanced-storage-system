---@meta limanchel.pkg.ui_schema.v0_1_0.native
---@class ui_schema.Native
---@field is_client fun(self: ui_schema.Native): boolean
---@field get_type fun(self: ui_schema.Native, name: string): any
---@field get_enum fun(self: ui_schema.Native, name: string): table
---@field new_value fun(self: ui_schema.Native, name: string, args: any[]): any
---@field new_rect fun(self: ui_schema.Native, spec: table, parent: any): any
---@field read_member fun(self: ui_schema.Native, object: any, path: string): any
---@field write_member fun(self: ui_schema.Native, object: any, path: string, value: any)
---@field detach fun(self: ui_schema.Native, object: any): boolean
---@class ui_schema.NativeLib
---@field new fun(api?: table): ui_schema.Native Ленивый доступ к игре без побочных эффектов загрузки.
local native = {}
return native
