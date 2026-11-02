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
