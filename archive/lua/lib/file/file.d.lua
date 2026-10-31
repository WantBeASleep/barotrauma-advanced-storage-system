---@meta

---@class file.Dependencies
---@field errors errors.Lib

---@class file.DependencyState
---@field errors errors.Lib|nil

---@class file.Error
---@field path_required string
---@field open_failed string
---@field read_failed string
---@field close_failed string

---@class file.Lib
---@field deps file.DependencyState
---@field ERROR file.Error
---@field init fun(dependencies: file.Dependencies): file.Lib
---@field read_all fun(path: string): string
