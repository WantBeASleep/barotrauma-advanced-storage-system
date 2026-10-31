---@meta

---@class errors.Error
---@field context string
---@field cause errors.Error[]|nil
---@field is_root fun(self: errors.Error): boolean
---@field is fun(self: errors.Error, target: string): boolean
---@field error fun(self: errors.Error): string

---@class errors.Lib
---@field new fun(context: string): errors.Error
---@field wrap fun(context: string, err: errors.Error): errors.Error
---@field join fun(context: string, cause: errors.Error[]): errors.Error
---@field is fun(err: errors.Error, target: string): boolean
