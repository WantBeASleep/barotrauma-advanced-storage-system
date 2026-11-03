---@meta limanchel.pkg.ui_schema.v0_1_0.registry
---@class ui_schema.Registry
---@field register_type fun(self: ui_schema.Registry, name: string, descriptor: ui_schema.Descriptor)
---@field register_value_type fun(self: ui_schema.Registry, name: string, converter: function)
---@field register_enum fun(self: ui_schema.Registry, name: string, options: table)
---@field get_type fun(self: ui_schema.Registry, name: string): ui_schema.Descriptor?
---@field get_value_type fun(self: ui_schema.Registry, name: string): function?
---@field get_enum fun(self: ui_schema.Registry, name: string): table?
---@class ui_schema.Descriptor
---@field rect_mode "new"|"parent"|"none"
---@field validate fun(constructor: table, path: string): boolean?, goerrors.Error?
---@field create fun(params: table, rect_or_parent: any, context: table): any, goerrors.Error?
---@field child_parent fun(object: any, slot: string?): any, goerrors.Error?
---@field destroy fun(object: any): boolean?, goerrors.Error?
---@class ui_schema.RegistryLib
---@field new fun(): ui_schema.Registry
local registry = {}
return registry
