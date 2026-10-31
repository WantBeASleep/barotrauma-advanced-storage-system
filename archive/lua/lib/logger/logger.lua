---@type logger.module
local logger = {}

---@type logger.levels
logger.levels = {
    trace = 0,
    debug = 5,
    info = 10,
    warning = 15,
    error = 20,
}

---@type table<logger.level, string>
local LEVEL_LABEL = {
    [logger.levels.trace] = "TRACE",
    [logger.levels.debug] = "DEBUG",
    [logger.levels.info] = "INFO",
    [logger.levels.warning] = "WARN",
    [logger.levels.error] = "ERROR",
}

---@type table<logger.level, Microsoft.Xna.Framework.Color>
local LEVEL_COLOR = {
    [logger.levels.trace] = Color.Gray,
    [logger.levels.debug] = Color.Green,
    [logger.levels.info] = Color.Cyan,
    [logger.levels.warning] = Color.Yellow,
    [logger.levels.error] = Color.Red,
}

---@class logger.instance
local logger_instance = {}

---Formats every logger prefix segment as a console label.
---@private
---@param prefix string[]
---@return string
local function format_prefix(prefix)
    local parts = {}

    for _, value in ipairs(prefix) do
        table.insert(parts, string.format("[%s]", value))
    end

    return table.concat(parts)
end

---Creates a copy of prefix segments for a child logger.
---@private
---@param prefix string[]
---@return string[]
local function copy_prefix(prefix)
    local result = {}

    for index, value in ipairs(prefix) do
        result[index] = value
    end

    return result
end

---Builds one logger instance after the composition root provides its dependencies.
---@param options logger.options
---@return logger.logger
function logger.new(options)
    if options == nil then
        error("logger.new requires options", 0)
    end

    if options.prefix == nil then
        error("logger.new requires options.prefix", 0)
    end

    if options.min_level == nil then
        error("logger.new requires options.min_level", 0)
    end

    if options.sink == nil then
        error("logger.new requires options.sink", 0)
    end

    ---@type logger.instance
    local instance = {
        prefix = { options.prefix },
        min_level = options.min_level,
        sink = options.sink,
        levels = logger.levels,
    }

    return setmetatable(instance, { __index = logger_instance })
end

---Writes a message when the current minimum level allows it.
---@private
---@param message string
---@param message_level logger.level
---@return nil
function logger_instance:_write(message, message_level)
    if self.min_level > message_level then
        return
    end

    local label = LEVEL_LABEL[message_level]
    local color = LEVEL_COLOR[message_level]

    if label == nil or color == nil then
        error("logger received an unknown message level", 0)
    end

    self.sink:write(string.format("[%s]%s %s", label, format_prefix(self.prefix), message), color)
end

---Writes a trace message.
---@param message string
---@return nil
function logger_instance:trace(message)
    self:_write(message, logger.levels.trace)
end

---Writes a debug message.
---@param message string
---@return nil
function logger_instance:debug(message)
    self:_write(message, logger.levels.debug)
end

---Writes an informational message.
---@param message string
---@return nil
function logger_instance:info(message)
    self:_write(message, logger.levels.info)
end

---Writes a warning message.
---@param message string
---@return nil
function logger_instance:warn(message)
    self:_write(message, logger.levels.warning)
end

---Writes an error message.
---@param message string
---@return nil
function logger_instance:error(message)
    self:_write(message, logger.levels.error)
end

---Creates a child logger that writes to the same sink with an extra prefix segment.
---@param prefix string
---@return logger.logger
function logger_instance:with_prefix(prefix)
    if prefix == nil then
        error("logger:with_prefix requires prefix", 0)
    end

    local child_prefix = copy_prefix(self.prefix)
    table.insert(child_prefix, prefix)

    ---@type logger.instance
    local child = {
        prefix = child_prefix,
        min_level = self.min_level,
        sink = self.sink,
        levels = self.levels,
    }

    return setmetatable(child, { __index = logger_instance })
end

return logger
