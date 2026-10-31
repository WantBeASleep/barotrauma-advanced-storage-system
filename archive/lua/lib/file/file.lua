---@type file.Lib
local file = {
    deps = {},
    ERROR = {
        path_required = "file path is required",
        open_failed = "file open failed",
        read_failed = "file read failed",
        close_failed = "file close failed",
    },
}

local READ_MODE = "r"
local READ_ALL = "*a"

---Returns the initialized error library dependency.
---@private
---@return errors.Lib
local function get_errors()
    if file.deps.errors == nil then
        error("file.init must be called before file is used", 0)
    end

    return file.deps.errors
end

---Initializes the file helper dependencies.
---@param dependencies file.Dependencies
---@return file.Lib
function file.init(dependencies)
    if dependencies == nil then
        error("file dependencies are required", 0)
    end

    if dependencies.errors == nil then
        error("file dependency errors is required", 0)
    end

    file.deps.errors = dependencies.errors

    return file
end

---Checks that a path was intentionally provided by the caller.
---@private
---@param path string
---@return nil
local function validate_path(path)
    if type(path) ~= "string" or path == "" then
        local errors = get_errors()
        error(errors.wrap("read file", errors.new(file.ERROR.path_required)), 0)
    end
end

---Raises an I/O error with a stable root cause and dynamic operation context.
---@private
---@param root_cause string
---@param operation string
---@param path string
---@param reason any
local function raise_read_error(root_cause, operation, path, reason)
    local errors = get_errors()
    local context
    if reason == nil or reason == "" then
        context = string.format("%s: %s", operation, path)
    else
        context = string.format("%s: %s: %s", operation, path, tostring(reason))
    end

    error(errors.wrap(context, errors.new(root_cause)), 0)
end

---Reads a required file as text.
---@param path string
---@return string content
---@throws errors.Error
function file.read_all(path)
    validate_path(path)

    local handle, open_err = io.open(path, READ_MODE)
    if handle == nil then
        raise_read_error(file.ERROR.open_failed, "open file", path, open_err)
    end

    ---@diagnostic disable-next-line: need-check-nil
    local content, read_err = handle:read(READ_ALL)
    ---@diagnostic disable-next-line: need-check-nil
    local close_ok, close_err = handle:close()

    if content == nil then
        raise_read_error(file.ERROR.read_failed, "read file", path, read_err)
    end

    if close_ok == nil or close_ok == false then
        raise_read_error(file.ERROR.close_failed, "close file", path, close_err)
    end

    return content
end

return file
