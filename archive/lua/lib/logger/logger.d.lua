---@alias logger.level integer

---@class logger.levels
---@field trace logger.level
---@field debug logger.level
---@field info logger.level
---@field warning logger.level
---@field error logger.level

---@class logger.sink
---@field write fun(self: logger.sink, text: string, color: Microsoft.Xna.Framework.Color): nil

---@class logger.options
---@field prefix string
---@field min_level logger.level
---@field sink logger.sink

---@class logger.logger
---@field levels logger.levels
---@field trace fun(self: logger.logger, message: string): nil
---@field debug fun(self: logger.logger, message: string): nil
---@field info fun(self: logger.logger, message: string): nil
---@field warn fun(self: logger.logger, message: string): nil
---@field error fun(self: logger.logger, message: string): nil
---@field with_prefix fun(self: logger.logger, prefix: string): logger.logger

---@class logger.instance: logger.logger
---@field private prefix string[]
---@field private min_level logger.level
---@field private sink logger.sink

---@class logger.module
---@field levels logger.levels
---@field new fun(options: logger.options): logger.logger
