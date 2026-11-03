---@meta limanchel.pkg.logger.v0_1_0.logger

---@alias logger.Level "trace" | "debug" | "info" | "warning" | "error"

---Все настройки обязательны; неверные значения вызывают строковую ошибку Lua.
---@class logger.Options
---@field level logger.Level Минимальный выводимый уровень.
---@field prefixes string[] Плотный массив непустых строк; пустой массив допускается.
---@field write fun(line: string) Получает готовую строку без завершающего перевода строки.

---Настроенный экземпляр. Подавленные сообщения не проверяют аргументы.
---Разрешённый вызов требует строку и таблицу со строковыми ключами или nil;
---неверные типы вызывают строковую ошибку Lua. Сбои __tostring/write распространяются вызывающему коду.
---@class logger.Logger
---@field trace fun(self: logger.Logger, message: string, fields?: table<string, any>): nil Вывод с уровнем TRACE.
---@field debug fun(self: logger.Logger, message: string, fields?: table<string, any>): nil Вывод с уровнем DEBUG.
---@field info fun(self: logger.Logger, message: string, fields?: table<string, any>): nil Вывод с уровнем INFO.
---@field warning fun(self: logger.Logger, message: string, fields?: table<string, any>): nil Вывод с уровнем WARNING.
---@field error fun(self: logger.Logger, message: string, fields?: table<string, any>): nil Вывод с уровнем ERROR, без исключения по уровню.
---@field with_prefix fun(self: logger.Logger, prefix: string, ...: string): logger.Logger Новый экземпляр с добавленными непустыми префиксами; наследует порог и write, не меняет родителя. Отсутствие аргументов, nil и неверные типы вызывают строковую ошибку Lua.

---@class logger.Lib
---@field new fun(options: logger.Options): logger.Logger Новый независимый экземпляр; копирует префиксы, сохраняет write по ссылке.
local logger = {}

return logger
