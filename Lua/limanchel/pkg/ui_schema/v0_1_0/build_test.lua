local busted = require("busted")
local assert = require("luassert")
local build = require("limanchel.pkg.ui_schema.v0_1_0.build")
local document = require("limanchel.pkg.ui_schema.v0_1_0.document")
local registry = require("limanchel.pkg.ui_schema.v0_1_0.registry")
local values = require("limanchel.pkg.ui_schema.v0_1_0.values")
local test_support = require("limanchel.pkg.ui_schema.v0_1_0.test_support")
local describe, it = busted.describe, busted.it

local rect = "\"rect\":{\"size\":{\"$type\":\"Point\",\"value\":[100,40]}}"
local function panel(extra)
   return "{\"type\":\"Panel\"," .. rect .. (extra and "," .. extra or "") .. "}"
end
local function doc(node)
   return assert(document.parse("{\"schema_version\":1,\"components\":{\"row\":" .. node .. "}}"))
end
local function setup()
   local backend = test_support.new_backend()
   local reg = registry.new()
   values.register_defaults(reg, backend)
   reg:register_type("Panel", test_support.descriptor(backend))
   return backend, reg, { Children = {} }
end

describe("Построение и владение UI", function()
   it("сохраняет причину отказа при строковом error MoonSharp", function()
      local env = {
         require = require,
         assert = assert,
         type = type,
         tostring = tostring,
         pairs = pairs,
         ipairs = ipairs,
         table = table,
         setmetatable = setmetatable,
         pcall = pcall,
         error = function(message, level)
            if type(message) ~= "string" then
               error("MoonSharp принимает только строковые исключения")
            end
            error(message, level)
         end,
      }
      local source = assert(io.open("Lua/limanchel/pkg/ui_schema/v0_1_0/build.lua", "r"))
      local text = source:read("*a")
      source:close()
      -- В Busted используется Lua 5.2 с четырьмя аргументами load; игровой std описывает только один.
      -- selene: allow(incorrect_standard_library_use)
      local isolated = assert(load(text, "build", "t", env))()
      local backend, reg, parent = setup()
      local view, err = isolated.run(doc("{\"type\":\"Unknown\"}"), "row", parent, nil, reg, backend)
      assert.is_nil(view)
      assert.matches("неизвестный тип Unknown", err:error(), 1, true)
   end)
   it(
      "не удерживает освобождённые объекты через результат построения",
      function()
         local backend, reg, parent = setup()
         local view = assert(build.run(doc(panel()), "row", parent, nil, reg, backend))
         local weak = setmetatable({ view.root }, { __mode = "v" })
         view:dispose()
         backend.created = {}
         backend.destroyed = {}
         backend.writes = {}
         collectgarbage("collect")
         assert.is_nil(weak[1])
         assert.is_nil(view.root)
      end
   )
   it("создаёт независимые строки и исходные ссылки", function()
      local backend, reg, parent = setup()
      local source = doc(panel("\"id\":\"label\",\"props\":{\"Text\":\"текст\"}"))
      local first = assert(build.run(source, "row", parent, nil, reg, backend))
      local second = assert(build.run(source, "row", parent, nil, reg, backend))
      assert.is_true(rawequal(first:get("label"), first.by_id.label))
      assert.is_false(rawequal(first:get("label"), second:get("label")))
      assert.are.equal("текст", document.get_schema(source, "row").props.Text)
      first:dispose()
      first:dispose()
      assert.is_nil(first.root)
      assert.is_nil(first.by_id.label)
      assert.is_not_nil(second.root)
      assert.are.equal(1, #parent.Children)
      assert.has_error(function()
         first:get("label")
      end)
      assert.has_error(function()
         second:get("absent")
      end)
   end)

   it("сохраняет порядок детей и ссылки вперёд в свойствах", function()
      local backend, reg, parent = setup()
      local source = doc(
         panel(
            "\"id\":\"root\",\"props\":{\"Other\":{\"$ref\":\"last\"}},\"children\":["
               .. panel("\"id\":\"first\"")
               .. ","
               .. panel("\"id\":\"last\"")
               .. "]"
         )
      )
      local view = assert(build.run(source, "row", parent, nil, reg, backend))
      assert.is_true(rawequal(view.root.Other, view:get("last")))
      assert.is_true(rawequal(view:get("first").RectTransform.Parent, view.root.RectTransform))
      assert.is_true(rawequal(backend.created[2], view:get("first")))
      assert.is_true(rawequal(backend.created[3], view:get("last")))
   end)

   it("отклоняет дубликаты и ссылки конструктора до создания", function()
      local backend, reg, parent = setup()
      for _, node in ipairs({
         panel("\"id\":\"same\",\"children\":[" .. panel("\"id\":\"same\"") .. "]"),
         panel("\"constructor\":{\"target\":{\"$ref\":\"later\"}},\"children\":[" .. panel("\"id\":\"later\"") .. "]"),
      }) do
         local view, err = build.run(doc(node), "row", parent, nil, reg, backend)
         assert.is_nil(view)
         test_support.assert_error_path(err, "components.row")
      end
      assert.are.equal(0, #backend.created)
      assert.are.equal(0, #parent.Children)
   end)

   it("сохраняет присутствие явного nil", function()
      local backend, reg, parent = setup()
      local view = assert(
         build.run(
            doc(panel("\"constructor\":{\"style\":{\"$nil\":true},\"color\":false}")),
            "row",
            parent,
            nil,
            reg,
            backend
         )
      )
      assert.is_true(view.root.params.present.style)
      assert.is_nil(view.root.params.values.style)
      assert.is_false(view.root.params.values.color)
   end)

   it(
      "применяет словарь по именам, массив по заданному порядку",
      function()
         local backend, reg, parent = setup()
         assert(build.run(doc(panel("\"props\":{\"Z\":1,\"A\":2}")), "row", parent, nil, reg, backend))
         assert.are.equal("A", backend.writes[1].member)
         assert.are.equal("Z", backend.writes[2].member)
         backend.writes = {}
         local view = assert(
            build.run(
               doc(panel("\"props\":[{\"member\":\"Z\",\"value\":1},{\"member\":\"Z\",\"value\":2}]")),
               "row",
               parent,
               nil,
               reg,
               backend
            )
         )
         assert.are.equal(2, view.root.Z)
         assert.are.equal(2, #backend.writes)
      end
   )

   it(
      "убирает частичный конструктор и существующее дерево при отказе",
      function()
         local backend, reg, parent = setup()
         local cleaned = false
         local failing = test_support.descriptor(backend)
         function failing.create(_, _, context)
            context.defer_cleanup(function()
               cleaned = true
            end)
            error("сбой конструктора")
         end
         reg:register_type("Broken", failing)
         local source = doc(panel("\"children\":[{\"type\":\"Broken\"," .. rect .. "}]"))
         local view, err = build.run(source, "row", parent, nil, reg, backend)
         assert.is_nil(view)
         assert.is_true(cleaned)
         assert.are.equal(0, #parent.Children)
         assert.matches("сбой конструктора", err:error(), 1, true)
      end
   )

   it(
      "откатывает свойства в обратном порядке и сохраняет ресурсы и соседей",
      function()
         local backend, reg, parent = setup()
         local sibling = backend:new_rect({}, parent)
         local sprite = {}
         backend.fail_write = "Z"
         local source = doc(
            panel(
               "\"id\":\"root\",\"children\":["
                  .. panel("\"id\":\"child\",\"props\":{\"A\":{\"$resource\":\"sprite\"},\"Z\":1}")
                  .. "]"
            )
         )
         local view, err = build.run(source, "row", parent, { resources = { sprite = sprite } }, reg, backend)
         assert.is_nil(view)
         test_support.assert_error_path(err, ".props.Z")
         assert.is_true(rawequal(backend.destroyed[1], backend.created[2]))
         assert.is_true(rawequal(backend.destroyed[2], backend.created[1]))
         assert.are.same({ sibling }, parent.Children)
         assert.is_nil(sprite.disposed)
      end
   )

   it("сохраняет причину отказа очистки", function()
      local backend, reg, parent = setup()
      local broken = test_support.descriptor(backend)
      function broken.destroy()
         error("сбой очистки")
      end
      reg:register_type("Unclean", broken)
      backend.fail_write = "Z"
      local view, err =
         build.run(doc("{\"type\":\"Unclean\"," .. rect .. ",\"props\":{\"Z\":1}}"), "row", parent, nil, reg, backend)
      assert.is_nil(view)
      assert.matches("отказ свойства", err:error(), 1, true)
      assert.matches("сбой очистки", err:error(), 1, true)
      assert.are.equal(0, #parent.Children)
   end)

   it("удаляет перенесённый созданный объект", function()
      local backend, reg, parent = setup()
      local view = assert(
         build.run(doc(panel("\"children\":[" .. panel("\"id\":\"child\"") .. "]")), "row", parent, nil, reg, backend)
      )
      local other = { Children = {} }
      backend:detach(view:get("child"))
      view:get("child").RectTransform.Parent = other
      other.Children[1] = view:get("child").RectTransform
      view:dispose()
      assert.are.equal(0, #other.Children)
   end)

   it("не создаёт GUI на сервере и при неизвестных ресурсах", function()
      local backend, reg, parent = setup()
      backend.client = false
      local view, err = build.run(doc(panel()), "row", parent, nil, reg, backend)
      assert.is_nil(view)
      assert.is_not_nil(err)
      backend.client = true
      view, err =
         build.run(doc(panel("\"props\":{\"Text\":{\"$resource\":\"absent\"}}")), "row", parent, nil, reg, backend)
      assert.is_nil(view)
      assert.is_not_nil(err)
      assert.are.equal(0, #backend.created)
   end)
end)
