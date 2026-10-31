---@type storage.LoadArgs
local load_args = ...

if load_args == nil then
    error("storage load args are required", 0)
end

if load_args.module_path == nil then
    error("storage load arg module_path is required", 0)
end

---@type storage.Lib
local storage = {
    deps = {},
    ERROR = {
        options_required = "storage options are required",
        logger_required = "storage logger is required",
        cs_storage_required = "storage C# storage is required",
        csharp_call_failed = "storage C# call failed",
        empty_path = "empty_path",
        absolute_path_not_allowed = "absolute_path_not_allowed",
        invalid_path = "invalid_path",
        read_failed = "read_failed",
        null_content = "null_content",
        write_failed = "write_failed",
        delete_failed = "delete_failed",
        path_must_be_directory = "path_must_be_directory",
        empty_extension = "empty_extension",
        invalid_extension = "invalid_extension",
        delete_recursive_extension_failed = "delete_recursive_extension_failed",
        storage_root_invalid = "storage_root_invalid",
        save_folder_unavailable = "save_folder_unavailable",
    },
}

local Service = assert(loadfile(load_args.module_path .. "/service.lua"))()

---Returns the initialized errors library or fails on a composition-root wiring error.
---@private
---@return errors.Lib
local function get_errors()
    if storage.deps.errors == nil then
        error("storage.init must be called before storage is used", 0)
    end

    return storage.deps.errors
end

---Initializes runtime dependencies for the storage library.
---@param dependencies storage.Dependencies
---@return storage.Lib
function storage.init(dependencies)
    if dependencies == nil then
        error("storage dependencies are required", 0)
    end

    if dependencies.errors == nil then
        error("storage dependency errors is required", 0)
    end

    storage.deps.errors = dependencies.errors

    Service.init({
        errors = dependencies.errors,
        ERROR = storage.ERROR,
    })

    return storage
end

---Creates a storage service bound to one C# Storage helper.
---@param options storage.Options
---@return storage.Service
---@throws errors.Error
function storage.new(options)
    local errors = get_errors()

    if options == nil then
        error(errors.wrap("create storage service", errors.new(storage.ERROR.options_required)), 0)
    end

    if options.logger == nil then
        error(errors.wrap("create storage service", errors.new(storage.ERROR.logger_required)), 0)
    end

    if options.cs_storage == nil then
        error(errors.wrap("create storage service", errors.new(storage.ERROR.cs_storage_required)), 0)
    end

    local log = options.logger:with_prefix("C# bridge")
    log:trace("creating storage service")

    return Service.new({
        cs_storage = options.cs_storage,
        log = log,
    })
end

return storage
