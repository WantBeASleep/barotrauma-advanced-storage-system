local ERROR_CAUSE_CODE_FIELD = "Code"
local ERROR_CAUSE_MESSAGE_FIELD = "Message"

local Service = {}
Service.__index = Service
Service.deps = {}
Service.storage_error_codes = {}

---Returns initialized service dependencies or fails on a composition-root wiring error.
---@private
---@return errors.Lib
---@return storage.Error
local function get_dependencies()
    if Service.deps.errors == nil or Service.deps.ERROR == nil then
        error("storage service init must be called before storage service is used", 0)
    end

    return Service.deps.errors, Service.deps.ERROR
end

---Reads one field from a LuaCs/C# exception object without masking the original failure.
---@private
---@param cause any
---@param field_name string
---@return string|nil
local function read_cause_field(cause, field_name)
    if cause == nil then
        return nil
    end

    local ok, result = pcall(function()
        return cause[field_name]
    end)

    if not ok or result == nil then
        return nil
    end

    return tostring(result)
end

---Returns the stable root cause for a failed C# storage call.
---@private
---@param cause any
---@return string
local function get_root_cause(cause)
    local _, ERROR = get_dependencies()
    local code = read_cause_field(cause, ERROR_CAUSE_CODE_FIELD)
    if code ~= nil and Service.storage_error_codes[code] == true then
        return code
    end

    return ERROR.csharp_call_failed
end

---Returns dynamic context for a failed C# storage call.
---@private
---@param operation string
---@param cause any
---@return string
local function get_error_context(operation, cause)
    local code = read_cause_field(cause, ERROR_CAUSE_CODE_FIELD)
    local message = read_cause_field(cause, ERROR_CAUSE_MESSAGE_FIELD)

    if code ~= nil and message ~= nil then
        return string.format("%s: %s: %s", operation, code, message)
    end

    if code ~= nil then
        return string.format("%s: %s", operation, code)
    end

    if message ~= nil then
        return string.format("%s: %s", operation, message)
    end

    return string.format("%s: %s", operation, tostring(cause))
end

---Raises one shared error for a failed C# storage operation.
---@private
---@param operation string
---@param cause any
local function raise_csharp_error(operation, cause)
    local errors = get_dependencies()

    error(errors.wrap(get_error_context(operation, cause), errors.new(get_root_cause(cause))), 0)
end

---Initializes runtime dependencies for storage service instances.
---@param dependencies storage.ServiceDependencies
---@return storage.ServiceClass
function Service.init(dependencies)
    if dependencies == nil then
        error("storage service dependencies are required", 0)
    end

    if dependencies.errors == nil then
        error("storage service dependency errors is required", 0)
    end

    if dependencies.ERROR == nil then
        error("storage service dependency ERROR is required", 0)
    end

    Service.deps.errors = dependencies.errors
    Service.deps.ERROR = dependencies.ERROR
    Service.storage_error_codes = {
        [dependencies.ERROR.empty_path] = true,
        [dependencies.ERROR.absolute_path_not_allowed] = true,
        [dependencies.ERROR.invalid_path] = true,
        [dependencies.ERROR.read_failed] = true,
        [dependencies.ERROR.null_content] = true,
        [dependencies.ERROR.write_failed] = true,
        [dependencies.ERROR.delete_failed] = true,
        [dependencies.ERROR.path_must_be_directory] = true,
        [dependencies.ERROR.empty_extension] = true,
        [dependencies.ERROR.invalid_extension] = true,
        [dependencies.ERROR.delete_recursive_extension_failed] = true,
        [dependencies.ERROR.storage_root_invalid] = true,
        [dependencies.ERROR.save_folder_unavailable] = true,
    }

    return Service
end

---Creates a storage service.
---@param options storage.ServiceOptions
---@return storage.Service
function Service.new(options)
    local errors, ERROR = get_dependencies()

    if options == nil then
        error(errors.wrap("create storage service", errors.new(ERROR.options_required)), 0)
    end

    if options.cs_storage == nil then
        error(errors.wrap("create storage service", errors.new(ERROR.cs_storage_required)), 0)
    end

    if options.log == nil then
        error(errors.wrap("create storage service", errors.new(ERROR.logger_required)), 0)
    end

    return setmetatable({
        cs_storage = options.cs_storage,
        log = options.log,
    }, Service)
end

---Checks whether a storage file exists.
---@param path string
---@return boolean
---@throws errors.Error
function Service:exists(path)
    self.log:trace("storage exists: " .. tostring(path))

    local ok, result = pcall(function()
        return self.cs_storage.Exists(path)
    end)

    if not ok then
        raise_csharp_error("storage exists", result)
    end

    self.log:trace("storage exists completed: " .. tostring(path))
    return result
end

---Reads a text file from storage. Missing files return nil.
---@param path string
---@return string|nil
---@throws errors.Error
function Service:load_string(path)
    self.log:trace("storage load string: " .. tostring(path))

    local ok, result = pcall(function()
        return self.cs_storage.LoadString(path)
    end)

    if not ok then
        raise_csharp_error("storage load string", result)
    end

    self.log:trace("storage load string completed: " .. tostring(path))
    return result
end

---Writes a text file to storage.
---@param path string
---@param content string
---@throws errors.Error
function Service:save_string(path, content)
    self.log:trace("storage save string: " .. tostring(path))

    local ok, result = pcall(function()
        return self.cs_storage.SaveString(path, content)
    end)

    if not ok then
        raise_csharp_error("storage save string", result)
    end

    self.log:trace("storage save string completed: " .. tostring(path))
end

---Deletes a file from storage.
---@param path string
---@return boolean deleted
---@throws errors.Error
function Service:delete(path)
    self.log:trace("storage delete: " .. tostring(path))

    local ok, result = pcall(function()
        return self.cs_storage.Delete(path)
    end)

    if not ok then
        raise_csharp_error("storage delete", result)
    end

    self.log:trace("storage delete completed: " .. tostring(path))
    return result
end

---Deletes files with one extension under a storage directory.
---@param path string
---@param extension string
---@return integer deleted_count
---@throws errors.Error
function Service:delete_recursive_extension(path, extension)
    self.log:trace("storage delete recursive extension: " .. tostring(path) .. " " .. tostring(extension))

    local ok, result = pcall(function()
        return self.cs_storage.DeleteRecursiveExtension(path, extension)
    end)

    if not ok then
        raise_csharp_error("storage delete recursive extension", result)
    end

    self.log:trace("storage delete recursive extension completed: " .. tostring(path) .. " " .. tostring(extension))
    return result
end

---Returns the real absolute path for a storage-relative path.
---@param path string
---@return string
---@throws errors.Error
function Service:get_full_path(path)
    self.log:trace("storage get full path: " .. tostring(path))

    local ok, result = pcall(function()
        return self.cs_storage.GetFullPath(path)
    end)

    if not ok then
        raise_csharp_error("storage get full path", result)
    end

    self.log:trace("storage get full path completed: " .. tostring(path))
    return result
end

return Service
