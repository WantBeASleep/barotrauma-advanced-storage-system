local cases = {}
local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")
local Cases = {}
local Cases_mt = { __index = Cases }
local Example = {}
local Example_mt = { __index = Example }

local function action(example, name, callback)
   local function run(...)
      if example.busy then
         return true
      end
      example.busy = true
      local ok, err = pcall(callback, ...)
      example.busy = false
      if not ok then
         error(err, 0)
      end
      example.last_action = name
      if example.on_action then
         example.on_action(name)
      end
      return true
   end
   example.actions[name] = run
   return run
end

local function message(example, text)
   example.expected_message = text
   example.view:get("message").Text = text
end

local function close_view(view, errors)
   local ok, err = view:dispose()
   if not ok then
      errors[#errors + 1] = err
   end
end

function Example:close()
   local errors = {}
   for i = #self.rows, 1, -1 do
      close_view(self.rows[i], errors)
   end
   self.rows = {}
   close_view(self.view, errors)
   if #errors > 0 then
      return nil, goerrors.wrap("Закрытие примера", table.unpack(errors))
   end
   return true
end

function Example:report()
   local actual = tostring(self.view:get("message").Text)
   local checks = {
      {
         name = "Текст надписи",
         expected = self.expected_message,
         actual = actual,
         passed = actual == self.expected_message,
      },
   }
   if self.name == "rows" then
      checks[#checks + 1] = {
         name = "Число строк",
         expected = self.expected_rows,
         actual = #self.rows,
         passed = self.expected_rows == #self.rows,
      }
   end
   if self.name == "controls" then
      local bar = self.view:get("progress").BarSize
      checks[#checks + 1] = {
         name = "Индикатор",
         expected = self.expected_progress,
         actual = bar,
         passed = math.abs(bar - self.expected_progress) < 0.001,
      }
   end
   return checks
end

local function bind_controls(example)
   local view = example.view
   view:get("entry").OnTextChanged = function(_, text)
      return action(example, "text", function()
         message(example, "Ввод: " .. tostring(text))
      end)()
   end
   view:get("number").OnValueChanged = function(input)
      action(example, "number", function()
         message(example, "Число: " .. tostring(input.IntValue))
      end)()
   end
   view:get("toggle").OnSelected = function(toggle)
      return action(example, "toggle", function()
         message(example, toggle.Selected and "Флажок включён" or "Флажок выключен")
      end)()
   end
   local slide = action(example, "slider", function(value)
      local progress = value
      if progress == nil then
         progress = 0.5
      end
      example.expected_progress = progress
      view:get("progress").BarSize = progress
      message(example, "Индикатор: " .. tostring(math.floor(progress * 100)) .. "%")
   end)
   view:get("slider").OnMoved = function(_, value)
      return slide(value)
   end
   local choices = view:get("choices")
   choices.AddItem("Первый", "Первый")
   choices.AddItem("Второй", "Второй")
   choices.OnSelected = function(_, data)
      return action(example, "choice", function()
         message(example, "Выбрано: " .. tostring(data))
      end)()
   end
end

local function bind_rows(example, owner)
   local add = action(example, "add_row", function()
      example.serial = example.serial + 1
      local list = example.view:get("rows")
      local row, err = owner.builder:build(owner.documents.rows, "item_row", list.Content.RectTransform)
      if err then
         error(err, 0)
      end
      row:get("name").Text = "Строка " .. example.serial
      example.rows[#example.rows + 1] = row
      example.expected_rows = example.expected_rows + 1
      local remove_name = "remove_row_" .. example.serial
      row:get("remove").OnClicked = action(example, remove_name, function()
         for i, current in ipairs(example.rows) do
            if rawequal(current, row) then
               local ok, remove_err = row:dispose()
               if not ok then
                  error(remove_err, 0)
               end
               table.remove(example.rows, i)
               example.expected_rows = example.expected_rows - 1
               example.actions[remove_name] = nil
               break
            end
         end
         message(example, "Строк: " .. #example.rows)
      end)
      message(example, "Строк: " .. #example.rows)
   end)
   example.view:get("add_row").OnClicked = add
end

function cases.create(builder, documents, host)
   if host.create_badge then
      local descriptor = { rect_mode = "new", slots = { default = true } }
      function descriptor.validate()
         return true
      end
      function descriptor.create(params, rect)
         return host:create_badge(params, rect)
      end
      function descriptor.child_parent(object)
         return object.RectTransform
      end
      function descriptor.destroy(object)
         return host:detach(object)
      end
      builder:register_type("DemoBadge", descriptor)
   end
   return setmetatable({ builder = builder, documents = documents, host = host }, Cases_mt)
end

function Cases:open(name)
   local doc = self.documents[name]
   if not doc then
      return nil, goerrors.new("Неизвестный пример: " .. tostring(name))
   end
   local view, err = self.builder:build(doc, "menu", self.host.parent, { resources = self.host.resources or {} })
   if err then
      return nil, err
   end
   local example = setmetatable({
      name = name,
      view = view,
      rows = {},
      actions = {},
      expected_message = "Готово",
      expected_progress = 0,
      expected_rows = 0,
      serial = 0,
   }, Example_mt)
   local ok, bind_err = pcall(function()
      if name ~= "rows" and name ~= "lifecycle" then
         view:get("change_message").OnClicked = action(example, "change_message", function()
            message(example, "Кнопка нажата")
         end)
      end
      if name == "controls" then
         bind_controls(example)
      end
      if name == "rows" then
         bind_rows(example, self)
      end
      if name == "lifecycle" then
         view:get("fail").OnClicked = action(example, "fail", function()
            local invalid, expected_err = self.builder:build(doc, "broken", self.host.parent)
            if invalid then
               invalid:dispose()
               error("Ошибочная схема неожиданно построена")
            end
            assert(expected_err ~= nil, "Ожидалась ошибка схемы")
            example.last_error = expected_err:error()
            message(example, "Ошибка обработана")
         end)
      end
   end)
   if not ok then
      local _, close_err = example:close()
      if close_err then
         return nil, goerrors.wrap("Подключение примера", goerrors.new(tostring(bind_err)), close_err)
      end
      return nil, goerrors.new(tostring(bind_err))
   end
   return example
end

return cases
