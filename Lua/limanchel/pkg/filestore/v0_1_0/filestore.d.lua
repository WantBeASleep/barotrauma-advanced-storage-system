---@meta limanchel.pkg.filestore.v0_1_0.filestore

---Стабильные причины для поиска через goerrors.is; объекты не изменять.
---@class filestore.Errors
---@field not_found goerrors.Error File.Exists не обнаружил файл.
---@field read_failed goerrors.Error Сбой определения пути, проверки наличия или чтения.
---@field write_failed goerrors.Error Сбой сохранения.

---Локальное текстовое хранилище в Game.SaveFolder/ModFiles. Неверные аргументы вызывают строковую ошибку Lua.
---@class filestore.Lib
---@field errors filestore.Errors Стабильные причины ожидаемых сбоев.
---@field load fun(key: string): string?, goerrors.Error? Читает файл без кеша; пустая строка допустима. При сбое возвращает nil, err.
local filestore = {}

return filestore
