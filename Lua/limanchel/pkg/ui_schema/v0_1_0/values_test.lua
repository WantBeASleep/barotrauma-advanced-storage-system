local busted = require("busted")
local assert = require("luassert")
local values = require("limanchel.pkg.ui_schema.v0_1_0.values")
local registry = require("limanchel.pkg.ui_schema.v0_1_0.registry")

local describe, it = busted.describe, busted.it

local function context()
   local reg = registry.new()
   local backend = {}
   function backend:new_value(name, args)
      return { type = name, args = args }
   end
   function backend:read_member(object, member)
      return object[member]
   end
   values.register_defaults(reg, backend)
   reg:register_enum("Anchor", { Center = 5 })
   return {
      registry = reg,
      backend = backend,
      resources = { flag = false },
      by_id = { window = { RectTransform = {} } },
   }
end

describe("Значения схем", function()
   it("сохраняет false и явный nil", function()
      local ctx = context()
      local value, err = values.resolve({ ["$resource"] = "flag" }, ctx, "props.Enabled")
      assert.is_nil(err)
      assert.is_false(value)
      local absent, nil_err = values.resolve({ ["$nil"] = true }, ctx, "constructor.style")
      assert.is_nil(absent)
      assert.is_nil(nil_err)
   end)

   it("готовит тип и перечисление", function()
      local ctx = context()
      local point = assert(values.resolve({ ["$type"] = "Point", value = { 400, 240 } }, ctx, "size"))
      assert.are.same({ type = "Point", args = { 400, 240 } }, point)
      assert.are.equal(5, values.resolve({ ["$enum"] = "Anchor", value = "Center" }, ctx, "anchor"))
      local color = assert(values.resolve({ ["$type"] = "Color", value = { 1, 2, 3 } }, ctx, "color"))
      assert.are.equal(255, color.args[4])
   end)

   it("возвращает исходную ссылку и её член", function()
      local ctx = context()
      assert.is_true(rawequal(ctx.by_id.window, values.resolve({ ["$ref"] = "window" }, ctx, "ref")))
      assert.is_true(
         rawequal(
            ctx.by_id.window.RectTransform,
            values.resolve({ ["$ref"] = "window", member = "RectTransform" }, ctx, "ref")
         )
      )
   end)

   it("не изменяет исходный массив и вложенные значения", function()
      local source = { false, 0, { text = "да" } }
      local result = assert(values.resolve(source, context(), "items"))
      assert.are.same(source, result)
      assert.is_false(rawequal(source, result))
   end)

   local invalid = {
      { ["$resource"] = "missing" },
      { ["$ref"] = "missing" },
      { ["$enum"] = "Anchor", value = "Wrong" },
      { ["$enum"] = "Unknown", value = "x" },
      { ["$type"] = "Unknown", value = {} },
      { ["$nil"] = false },
      { ["$nil"] = true, extra = 1 },
      { ["$resource"] = "flag", ["$nil"] = true },
      { ["$type"] = "Point", value = { 1.5, 2 } },
      { ["$type"] = "Vector2", value = { 1 } },
      { ["$type"] = "Color", value = { 256, 0, 0 } },
      { ["$type"] = "Vector2", value = { math.huge, 1 } },
   }
   for i, spec in ipairs(invalid) do
      it("сообщает путь неверного значения " .. i, function()
         local value, err = values.resolve(spec, context(), "test.path")
         assert.is_nil(value)
         assert.matches("test.path", err:error(), 1, true)
      end)
   end
end)
