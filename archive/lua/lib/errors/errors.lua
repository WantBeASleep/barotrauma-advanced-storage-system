---@type errors.Lib
local errors = {}

---@class errors.Error
local error_model = {}
error_model.__index = error_model

---Checks that context can be used as a readable error message.
---@param context string
---@return nil
local function validate_context(context)
    if context == nil or context == "" then
        error("error context is required")
    end
end

---Checks that a wrapped error value was created by this library.
---@param err any
---@return nil
local function validate_error(err)
    if getmetatable(err) ~= error_model then
        error("error value is required")
    end
end

---Checks that cause is a non-empty array of errors.
---@param cause errors.Error[]
---@return nil
local function validate_cause(cause)
    if type(cause) ~= "table" then
        error("error cause must be an array")
    end

    if #cause == 0 then
        error("error cause must not be empty")
    end

    for index = 1, #cause do
        if cause[index] == nil then
            error(string.format("error cause at index %s is required", index))
        end

        validate_error(cause[index])
    end
end

---Creates one error object.
---@param context string
---@param cause errors.Error[]|nil
---@return errors.Error
local function create_error(context, cause)
    validate_context(context)

    if cause ~= nil then
        validate_cause(cause)
    end

    return setmetatable({
        context = context,
        cause = cause,
    }, error_model)
end

---Returns true when this error is a root cause.
---@return boolean
function error_model:is_root()
    return self.cause == nil
end

---Checks this error tree for a root cause with the target context.
---@param target string
---@return boolean
function error_model:is(target)
    validate_context(target)

    if self:is_root() then
        return self.context == target
    end

    for _, cause in ipairs(self.cause) do
        if cause:is(target) then
            return true
        end
    end

    return false
end

---Returns a readable top-level-to-root error tree.
---@return string
function error_model:error()
    if self:is_root() then
        return self.context
    end

    if #self.cause == 1 then
        return string.format("%s: %s", self.context, self.cause[1]:error())
    end

    local cause_messages = {}
    for index, cause in ipairs(self.cause) do
        cause_messages[index] = cause:error()
    end

    return string.format("%s: [%s]", self.context, table.concat(cause_messages, "; "))
end

---@return string
function error_model:__tostring()
    return self:error()
end

---Creates a root cause error.
---@param context string
---@return errors.Error
function errors.new(context)
    return create_error(context, nil)
end

---Wraps one error with higher-level context.
---@param context string
---@param err errors.Error
---@return errors.Error
function errors.wrap(context, err)
    validate_error(err)

    return create_error(context, { err })
end

---Wraps several errors with one higher-level context.
---@param context string
---@param cause errors.Error[]
---@return errors.Error
function errors.join(context, cause)
    validate_cause(cause)

    local copied_cause = {}
    for _, err in ipairs(cause) do
        table.insert(copied_cause, err)
    end

    return create_error(context, copied_cause)
end

---Checks an error tree for a root cause with the target context.
---@param err errors.Error
---@param target string
---@return boolean
function errors.is(err, target)
    validate_error(err)

    return err:is(target)
end

return errors
