---@meta limanchel.pkg.ui_schema.v0_1_0.test_support
---@class ui_schema.TestSupport
---@field new_backend fun(): table Управляемая подмена игрового API только для тестов.
---@field new_builder fun(): table, table Настоящий разбор и построение с подменёнными игровыми конструкторами.
---@field new_host fun(backend: table): table Управляемые часы, команды и события проверки.
---@field descriptor fun(backend: table): ui_schema.Descriptor Описание тестового компонента.
---@field assert_error_path fun(err: goerrors.Error?, path: string) Проверка диагностического пути.
local test_support = {}
return test_support
