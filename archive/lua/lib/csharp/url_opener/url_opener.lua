---@type url_opener.LoadArgs
local load_args = ...

if load_args == nil then
    error("url_opener load args are required", 0)
end

if load_args.module_path == nil then
    error("url_opener load arg module_path is required", 0)
end

if load_args.errors == nil then
    error("url_opener load arg errors is required", 0)
end

local errors = load_args.errors

---@type url_opener.Lib
local url_opener = {
    ERROR = {
        options_required = "url_opener options are required",
        logger_required = "url_opener logger is required",
        cs_url_opener_required = "url_opener C# URL opener is required",
        csharp_call_failed = "url_opener C# call failed",
    },
}

local Service = assert(loadfile(load_args.module_path .. "/service.lua"))({
    errors = errors,
    ERROR = url_opener.ERROR,
})

---Creates a URL opener service bound to one C# UrlOpener helper.
---@param options url_opener.Options
---@return url_opener.Service
---@throws errors.Error
function url_opener.new(options)
    if options == nil then
        error(errors.wrap("create URL opener service", errors.new(url_opener.ERROR.options_required)), 0)
    end

    if options.logger == nil then
        error(errors.wrap("create URL opener service", errors.new(url_opener.ERROR.logger_required)), 0)
    end

    if options.cs_url_opener == nil then
        error(errors.wrap("create URL opener service", errors.new(url_opener.ERROR.cs_url_opener_required)), 0)
    end

    local log = options.logger:with_prefix("C# bridge")
    log:trace("creating URL opener service")

    return Service.new({
        cs_url_opener = options.cs_url_opener,
        log = log,
    })
end

return url_opener
