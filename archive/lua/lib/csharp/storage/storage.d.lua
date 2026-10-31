---@meta

---@class storage.LoadArgs
---@field module_path string

---@class storage.Dependencies
---@field errors errors.Lib

---@class storage.DependencyState
---@field errors errors.Lib|nil

---@class storage.Options
---@field logger logger.logger
---@field cs_storage storage.CSharpStorage

---@class storage.Error
---@field options_required string
---@field logger_required string
---@field cs_storage_required string
---@field csharp_call_failed string
---@field empty_path string
---@field absolute_path_not_allowed string
---@field invalid_path string
---@field read_failed string
---@field null_content string
---@field write_failed string
---@field delete_failed string
---@field path_must_be_directory string
---@field empty_extension string
---@field invalid_extension string
---@field delete_recursive_extension_failed string
---@field storage_root_invalid string
---@field save_folder_unavailable string

---@class storage.Lib
---@field deps storage.DependencyState
---@field ERROR storage.Error
---@field init fun(dependencies: storage.Dependencies): storage.Lib
---@field new fun(options: storage.Options): storage.Service

---@class storage.CSharpStorage
---@field Exists fun(path: string): boolean
---@field LoadString fun(path: string): string|nil
---@field SaveString fun(path: string, content: string): nil
---@field Delete fun(path: string): boolean
---@field DeleteRecursiveExtension fun(path: string, extension: string): integer
---@field GetFullPath fun(path: string): string

---@class storage.ServiceDependencies
---@field errors errors.Lib
---@field ERROR storage.Error

---@class storage.ServiceDependencyState
---@field errors errors.Lib|nil
---@field ERROR storage.Error|nil

---@class storage.ServiceClass
---@field deps storage.ServiceDependencyState
---@field storage_error_codes table<string, boolean>
---@field init fun(dependencies: storage.ServiceDependencies): storage.ServiceClass
---@field new fun(options: storage.ServiceOptions): storage.Service

---@class storage.ServiceOptions
---@field cs_storage storage.CSharpStorage
---@field log logger.logger

---@class storage.Service
---@field private cs_storage storage.CSharpStorage
---@field private log logger.logger
---@field exists fun(self: storage.Service, path: string): boolean
---@field load_string fun(self: storage.Service, path: string): string|nil
---@field save_string fun(self: storage.Service, path: string, content: string): nil
---@field delete fun(self: storage.Service, path: string): boolean
---@field delete_recursive_extension fun(self: storage.Service, path: string, extension: string): integer
---@field get_full_path fun(self: storage.Service, path: string): string
