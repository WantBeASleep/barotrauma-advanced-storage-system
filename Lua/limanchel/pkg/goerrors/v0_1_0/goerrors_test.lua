local busted = require("busted")
local assert = require("luassert")
local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")

local describe = busted.describe
local it = busted.it

local function assert_contract_error(callback)
   local ok, message = pcall(callback)
   assert.is_false(ok)
   assert.are.equal("string", type(message))
end

describe("Объекты и обёртки goerrors", function()
   it("сохраняет пустое сообщение", function()
      assert.are.equal("", goerrors.new(""):error())
   end)

   it("создаёт независимые объекты при одинаковом сообщении", function()
      local first = goerrors.new("сбой")
      local second = goerrors.new("сбой")
      assert.is_false(rawequal(first, second))
      assert.are.equal("сбой", first:error())
   end)

   it("добавляет контекст одной причине", function()
      local disk = goerrors.new("диск")
      assert.are.equal("сохранение: диск", goerrors.wrap("сохранение", disk):error())
   end)

   it("сохраняет порядок нескольких причин", function()
      local disk = goerrors.new("диск")
      local network = goerrors.new("сеть")
      assert.are.equal(
         "сохранение: [диск; сеть]",
         goerrors.wrap("сохранение", disk, network):error()
      )
   end)

   it("формирует описание вложенных обёрток", function()
      local disk = goerrors.new("диск")
      local err = goerrors.wrap("операция", goerrors.wrap("сохранение", disk))
      assert.are.equal("операция: сохранение: диск", err:error())
   end)

   it("сохраняет разделитель при пустом контексте", function()
      assert.are.equal(": диск", goerrors.wrap("", goerrors.new("диск")):error())
   end)

   it("поддерживает tostring встроенных ошибок", function()
      assert.are.equal("диск", tostring(goerrors.new("диск")))
      assert.are.equal(
         "сохранение: диск",
         tostring(goerrors.wrap("сохранение", goerrors.new("диск")))
      )
   end)

   it("сохраняет ссылку и поля пользовательской ошибки", function()
      local custom = {
         storage_id = 42,
         error = function(self)
            return string.format("хранилище %s", self.storage_id)
         end,
      }
      local wrapped = goerrors.wrap("загрузка", custom)
      assert.is_true(rawequal(custom, wrapped:unwrap()[1]))
      assert.are.equal(42, custom.storage_id)
      assert.are.equal("загрузка: хранилище 42", wrapped:error())
      custom.storage_id = 43
      assert.are.equal("загрузка: хранилище 43", wrapped:error())
   end)

   it(
      "защищает состав обёртки от изменения полученного массива",
      function()
         local disk = goerrors.new("диск")
         local wrapped = goerrors.wrap("сохранение", disk)
         local causes = wrapped:unwrap()
         causes[1] = goerrors.new("сеть")
         causes[2] = disk
         assert.is_true(rawequal(disk, wrapped:unwrap()[1]))
         assert.are.equal(1, #wrapped:unwrap())
         assert.are.equal("сохранение: диск", wrapped:error())
      end
   )

   it("возвращает пустой список причин для встроенного листа", function()
      assert.are.same({}, goerrors.new("диск"):unwrap())
   end)

   it("отклоняет нестроковые сообщения", function()
      assert_contract_error(function()
         goerrors.new(nil)
      end)
      assert_contract_error(function()
         goerrors.wrap(false, goerrors.new("диск"))
      end)
   end)

   it("требует хотя бы одну причину", function()
      assert_contract_error(function()
         goerrors.wrap("сохранение")
      end)
   end)

   it("отклоняет nil в конце и середине списка причин", function()
      local disk = goerrors.new("диск")
      assert_contract_error(function()
         goerrors.wrap("сохранение", disk, nil)
      end)
      assert_contract_error(function()
         goerrors.wrap("сохранение", nil, disk)
      end)
   end)

   it("отклоняет значения без метода описания", function()
      assert_contract_error(function()
         goerrors.wrap("сохранение", {})
      end)
      assert_contract_error(function()
         goerrors.wrap("сохранение", "диск")
      end)
   end)

   it("отклоняет нестроковое пользовательское описание", function()
      local custom = {
         error = function()
            return 42
         end,
      }
      assert_contract_error(function()
         goerrors.wrap("сохранение", custom):error()
      end)
   end)

   it("не маскирует сбой пользовательского описания", function()
      local custom = {
         error = function()
            error("ошибка пользовательского метода", 0)
         end,
      }
      assert.has_error(function()
         goerrors.wrap("сохранение", custom):error()
      end, "ошибка пользовательского метода")
   end)
end)

local function custom_leaf()
   return {
      error = function()
         return "причина"
      end,
   }
end

local function custom_wrapper(causes)
   local err = custom_leaf()
   function err:unwrap()
      return causes
   end
   return err
end

local function error_class()
   local CustomError = {}
   function CustomError:error()
      return "пользовательская ошибка"
   end
   return CustomError
end

describe("Поиск в деревьях goerrors", function()
   it("находит сам объект и отличает одинаковые сообщения", function()
      local leaf = goerrors.new("причина")
      assert.is_true(goerrors.is(leaf, leaf))
      assert.is_false(goerrors.is(leaf, goerrors.new("причина")))
   end)

   it("находит глубокие причины и последующие ветви", function()
      local leaf = goerrors.new("причина")
      local other = goerrors.new("другая причина")
      local root = goerrors.wrap("верх", goerrors.wrap("ветвь", leaf), other)
      assert.is_true(goerrors.is(root, leaf))
      assert.is_true(goerrors.is(root, other))
      assert.is_false(goerrors.is(root, goerrors.new("отсутствует")))
   end)

   it(
      "обходит глубокое дерево без рекурсивного вызова поиска",
      function()
         local leaf = goerrors.new("причина")
         local root = leaf
         for _ = 1, 12000 do
            root = custom_wrapper({ root })
         end
         assert.is_true(goerrors.is(root, leaf))
      end
   )

   it("находит класс с отдельной метатаблицей", function()
      local CustomError = error_class()
      local original = setmetatable({ storage_id = 42 }, { __index = CustomError })
      local root = goerrors.wrap("контекст", original)
      local found = goerrors.as(root, CustomError)
      assert.is_true(rawequal(original, found))
      assert.are.equal(42, found.storage_id)
   end)

   it("находит класс непосредственно в метатаблице", function()
      local CustomError = error_class()
      CustomError.__index = CustomError
      local original = setmetatable({}, CustomError)
      assert.is_true(rawequal(original, goerrors.as(original, CustomError)))
   end)

   it("выбирает первое совпадение в глубину", function()
      local CustomError = error_class()
      local mt = { __index = CustomError }
      local first = setmetatable({}, mt)
      local second = setmetatable({}, mt)
      local root = goerrors.wrap("верх", goerrors.wrap("ветвь", first), second)
      assert.is_true(rawequal(first, goerrors.as(root, CustomError)))
   end)

   it("предпочитает подходящий корень его причинам", function()
      local CustomError = error_class()
      local child = setmetatable({}, { __index = CustomError })
      local root = setmetatable(custom_wrapper({ child }), { __index = CustomError })
      assert.is_true(rawequal(root, goerrors.as(root, CustomError)))
   end)

   it("не использует __eq для совпадения ошибок", function()
      local mt = {
         __eq = function()
            return true
         end,
      }
      local first = setmetatable(custom_leaf(), mt)
      local second = setmetatable(custom_leaf(), mt)
      assert.is_false(goerrors.is(first, second))
      assert.is_false(goerrors.is(goerrors.wrap("контекст", first), second))
   end)

   it("не использует __eq для совпадения классов", function()
      local mt = {
         __eq = function()
            return true
         end,
      }
      local FirstError = setmetatable(error_class(), mt)
      local SecondError = setmetatable(error_class(), mt)
      local original = setmetatable(custom_leaf(), FirstError)
      assert.is_nil(goerrors.as(original, SecondError))
      local separate = setmetatable(custom_leaf(), { __index = FirstError })
      assert.is_nil(goerrors.as(separate, SecondError))
   end)

   it("не находит экземпляр по базовому классу", function()
      local BaseError = error_class()
      local DerivedError = setmetatable({}, { __index = BaseError })
      DerivedError.__index = DerivedError
      local original = setmetatable({}, DerivedError)
      assert.is_nil(goerrors.as(original, BaseError))
      assert.is_true(rawequal(original, goerrors.as(original, DerivedError)))
   end)

   it("не находит класс у объекта без метатаблицы", function()
      assert.is_nil(goerrors.as(custom_leaf(), error_class()))
   end)

   it("не вызывает функцию __index при распознавании класса", function()
      local calls = 0
      local mt = {
         __index = function()
            calls = calls + 1
         end,
      }
      local root = setmetatable(custom_wrapper({}), mt)
      assert.is_nil(goerrors.as(root, error_class()))
      assert.is_true(rawequal(root, goerrors.as(root, mt)))
      assert.are.equal(0, calls)
   end)

   it("не использует унаследованное поле __index метатаблицы", function()
      local CustomError = error_class()
      local mt = setmetatable({}, { __index = { __index = CustomError } })
      local original = setmetatable(custom_wrapper({}), mt)
      assert.is_nil(goerrors.as(original, CustomError))
   end)

   it(
      "поддерживает пользовательские обёртки и оба варианта листа",
      function()
         local first = custom_leaf()
         local second = custom_wrapper({})
         local root = custom_wrapper({ custom_wrapper({ first }), second })
         assert.is_true(goerrors.is(root, first))
         assert.is_true(goerrors.is(root, second))
         assert.is_false(goerrors.is(root, custom_leaf()))
      end
   )

   it("допускает общий лист в нескольких ветвях", function()
      local shared = custom_leaf()
      local root = custom_wrapper({ custom_wrapper({ shared }), shared })
      assert.is_true(goerrors.is(root, shared))
      assert.is_false(goerrors.is(root, custom_leaf()))
   end)

   it("определяет отсутствие ошибки через nil", function()
      local leaf = custom_leaf()
      assert.is_true(goerrors.is(nil, nil))
      assert.is_false(goerrors.is(nil, leaf))
      assert.is_false(goerrors.is(leaf, nil))
      assert.is_nil(goerrors.as(nil, error_class()))
   end)

   it("отклоняет неверные типы аргументов поиска", function()
      assert_contract_error(function()
         goerrors.is("ошибка", custom_leaf())
      end)
      assert_contract_error(function()
         goerrors.is(custom_leaf(), {})
      end)
      assert_contract_error(function()
         goerrors.as(custom_leaf(), "класс")
      end)
      assert_contract_error(function()
         goerrors.as(false, {})
      end)
   end)

   local invalid_causes = {
      { name = "nil", value = nil },
      { name = "строка", value = "причина" },
      { name = "разрыв", value = { [1] = custom_leaf(), [3] = custom_leaf() } },
      { name = "не-ошибка", value = { false } },
      { name = "поле вместо индекса", value = { cause = custom_leaf() } },
   }
   for _, case in ipairs(invalid_causes) do
      it("отклоняет некорректный массив причин: " .. case.name, function()
         assert_contract_error(function()
            goerrors.is(custom_wrapper(case.value), custom_leaf())
         end)
      end)
   end

   it("отклоняет присутствующее поле unwrap без функции", function()
      local root = custom_leaf()
      root.unwrap = false
      assert_contract_error(function()
         goerrors.is(root, custom_leaf())
      end)
   end)

   it("не запрашивает причины при совпадении корня", function()
      local CustomError = error_class()
      local root = setmetatable(custom_leaf(), { __index = CustomError })
      function root:unwrap()
         error("не должен вызываться", 0)
      end
      assert.is_true(goerrors.is(root, root))
      assert.is_true(rawequal(root, goerrors.as(root, CustomError)))
   end)

   it("не посещает следующие ветви после совпадения", function()
      local CustomError = error_class()
      local first = setmetatable(custom_leaf(), { __index = CustomError })
      local trap = custom_leaf()
      function trap:unwrap()
         error("не должен вызываться", 0)
      end
      local root = custom_wrapper({ first, trap })
      assert.is_true(goerrors.is(root, first))
      assert.is_true(rawequal(first, goerrors.as(root, CustomError)))
   end)

   it("не проверяет чужие непосещённые причины заранее", function()
      local first = custom_leaf()
      assert.is_true(goerrors.is(custom_wrapper({ first, false }), first))
   end)

   it("не вычисляет описание при поиске", function()
      local leaf = {
         error = function()
            error("описание не должно вычисляться", 0)
         end,
      }
      local root = goerrors.wrap("контекст", leaf)
      assert.is_true(goerrors.is(root, leaf))
      assert.is_nil(goerrors.as(root, error_class()))
   end)

   it("не маскирует сбой вызванного unwrap", function()
      local root = custom_leaf()
      function root:unwrap()
         error("ошибка пользовательского unwrap", 0)
      end
      assert.has_error(function()
         goerrors.is(root, custom_leaf())
      end, "ошибка пользовательского unwrap")
   end)
end)
