---@meta limanchel.pkg.goerrors.v0_1_0.goerrors

---Структурный контракт ошибки, не обязательный базовый класс.
---@class goerrors.Error
---@field error fun(self: goerrors.Error): string Описание для человека.
---@field unwrap? fun(self: goerrors.Error): goerrors.Error[] Плотный массив непосредственных причин; пустой массив обозначает лист.

---Создание объектов ожидаемых ошибок. Неверные аргументы вызывают строковую ошибку Lua.
---@class goerrors.Lib
---@field new fun(message: string): goerrors.Error Новый объект с указанным сообщением.
---@field wrap fun(message: string, err: goerrors.Error, ...: goerrors.Error): goerrors.Error Контекст с одной или несколькими причинами по ссылке; nil недопустим.
---@field is fun(err: goerrors.Error?, target: goerrors.Error?): boolean Поиск того же объекта в глубину без __eq; nil совпадает только с nil.
---@field as fun(err: goerrors.Error?, error_class: table): goerrors.Error? Первый исходный объект указанного класса, без наследования; nil при отсутствии совпадения.
local goerrors = {}

return goerrors
