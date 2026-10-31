---@type url_opener.ServiceDependencies
local dependencies = ...

if dependencies == nil then
    error("url_opener service dependencies are required", 0)
end

if dependencies.errors == nil then
    error("url_opener service dependency errors is required", 0)
end

if dependencies.ERROR == nil then
    error("url_opener service dependency ERROR is required", 0)
end

local errors = dependencies.errors
local ERROR = dependencies.ERROR

local Service = {}
Service.__index = Service

---Raises one shared error for a failed C# URL opener operation.
---@private
---@param operation string
---@param cause any
local function raise_csharp_error(operation, cause)
    error(errors.wrap(operation .. ": " .. tostring(cause), errors.new(ERROR.csharp_call_failed)), 0)
end

---Creates a URL opener service.
---@param options url_opener.ServiceOptions
---@return url_opener.Service
---@throws errors.Error
function Service.new(options)
    if options == nil then
        error(errors.wrap("create URL opener service", errors.new(ERROR.options_required)), 0)
    end

    if options.cs_url_opener == nil then
        error(errors.wrap("create URL opener service", errors.new(ERROR.cs_url_opener_required)), 0)
    end

    if options.log == nil then
        error(errors.wrap("create URL opener service", errors.new(ERROR.logger_required)), 0)
    end

    return setmetatable({
        cs_url_opener = options.cs_url_opener,
        log = options.log,
    }, Service)
end

---Opens a URL through the configured C# helper.
---@param url string
---@throws errors.Error
function Service:open(url)
    self.log:trace("URL opener open: " .. tostring(url))

    local ok, result = pcall(function()
        return self.cs_url_opener.Open(url)
    end)

    if not ok then
        raise_csharp_error("URL opener open", result)
    end

    self.log:trace("URL opener open completed: " .. tostring(url))
end

return Service
