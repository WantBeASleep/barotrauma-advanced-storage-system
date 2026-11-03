---@meta limanchel.pkg.ui_schema.v0_1_0.json_decoder
---@class ui_schema.JsonDecoder
---@field decode fun(text: string): any, goerrors.Error? Разбор JSON с сохранением формы коллекций.
---@field kind fun(value: any): string Вид JSON-значения или тип Lua.
local json_decoder = {}
return json_decoder
