---@meta

---@class url_opener.LoadArgs
---@field module_path string
---@field errors errors.Lib

---@class url_opener.Options
---@field logger logger.logger
---@field cs_url_opener url_opener.CSharpUrlOpener

---@class url_opener.Error
---@field options_required string
---@field logger_required string
---@field cs_url_opener_required string
---@field csharp_call_failed string

---@class url_opener.Lib
---@field ERROR url_opener.Error
---@field new fun(options: url_opener.Options): url_opener.Service

---@class url_opener.CSharpUrlOpener
---@field Open fun(url: string): nil

---@class url_opener.ServiceDependencies
---@field errors errors.Lib
---@field ERROR url_opener.Error

---@class url_opener.ServiceOptions
---@field cs_url_opener url_opener.CSharpUrlOpener
---@field log logger.logger

---@class url_opener.Service
---@field private cs_url_opener url_opener.CSharpUrlOpener
---@field private log logger.logger
---@field open fun(self: url_opener.Service, url: string): nil
