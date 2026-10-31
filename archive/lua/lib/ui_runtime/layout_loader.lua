---@type ui_runtime.LayoutLoader
local loader = {
    deps = {},
}

local READ_MODE = "r"
local READ_ALL = "*a"

---Returns initialized dependencies or fails on a composition-root wiring error.
---@private
---@return errors.Lib
---@return logger.logger
---@return ui_runtime.Error
local function get_dependencies()
    if loader.deps.errors == nil or loader.deps.log == nil or loader.deps.ERROR == nil then
        error("ui_runtime layout_loader.init must be called before layout_loader is used", 0)
    end

    return loader.deps.errors, loader.deps.log, loader.deps.ERROR
end

---Raises one layout loading error with path-specific context.
---@private
---@param root_cause string
---@param operation string
---@param path string
---@param reason any
local function raise_layout_error(root_cause, operation, path, reason)
    local errors = get_dependencies()
    local context
    if reason == nil or reason == "" then
        context = string.format("%s: %s", operation, path)
    else
        context = string.format("%s: %s: %s", operation, path, tostring(reason))
    end

    error(errors.wrap(context, errors.new(root_cause)), 0)
end

---Initializes layout loader dependencies.
---@param dependencies ui_runtime.InternalDependencies
---@return ui_runtime.LayoutLoader
function loader.init(dependencies)
    if dependencies == nil then
        error("ui_runtime layout_loader dependencies are required", 0)
    end

    if dependencies.errors == nil then
        error("ui_runtime layout_loader dependency errors is required", 0)
    end

    if dependencies.log == nil then
        error("ui_runtime layout_loader dependency log is required", 0)
    end

    if dependencies.ERROR == nil then
        error("ui_runtime layout_loader dependency ERROR is required", 0)
    end

    loader.deps.errors = dependencies.errors
    loader.deps.log = dependencies.log
    loader.deps.ERROR = dependencies.ERROR

    return loader
end

---Reads one required layout file.
---@private
---@param path string
---@return string
---@throws errors.Error
local function read_all(path)
    local _, log, ERROR = get_dependencies()
    if type(path) ~= "string" or path == "" then
        raise_layout_error(ERROR.path_required, "read UI layout", tostring(path), nil)
    end

    log:trace("opening UI layout: " .. path)
    local handle, open_err = io.open(path, READ_MODE)
    if handle == nil then
        raise_layout_error(ERROR.open_failed, "open UI layout", path, open_err)
    end

    ---@diagnostic disable-next-line: need-check-nil
    local content, read_err = handle:read(READ_ALL)
    ---@diagnostic disable-next-line: need-check-nil
    local close_ok, close_err = handle:close()

    if content == nil then
        raise_layout_error(ERROR.read_failed, "read UI layout", path, read_err)
    end

    if close_ok == nil or close_ok == false then
        raise_layout_error(ERROR.close_failed, "close UI layout", path, close_err)
    end

    if content == "" then
        raise_layout_error(ERROR.empty_file, "read UI layout", path, nil)
    end

    return content
end

---Loads and parses one JSON layout file.
---@param path string
---@return table
---@throws errors.Error
function loader.load(path)
    local _, log, ERROR = get_dependencies()
    local content = read_all(path)

    log:trace("parsing UI layout JSON: " .. path)
    local ok, parsed = pcall(function()
        return json.parse(content)
    end)
    if not ok then
        raise_layout_error(ERROR.json_parse_failed, "parse UI layout JSON", path, parsed)
    end
    if type(parsed) ~= "table" then
        raise_layout_error(ERROR.parsed_layout_required, "parse UI layout JSON", path, type(parsed))
    end

    return parsed
end

return loader
