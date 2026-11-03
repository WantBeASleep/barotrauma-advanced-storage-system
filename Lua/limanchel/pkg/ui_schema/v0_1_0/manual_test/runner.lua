local runner = {}
local ui_schema = require("limanchel.pkg.ui_schema.v0_1_0.ui_schema")
local cases = require("limanchel.pkg.ui_schema.v0_1_0.manual_test.cases")
local goerrors = require("limanchel.pkg.goerrors.v0_1_0.goerrors")
local Session = {}
local Session_mt = { __index = Session }

local function reset(session, action)
   session.action = action
   session.ready = false
   session.error = nil
   session.frames = 0
   session.last_draw_update = session.updates
   session.started = session.host:now()
end

function Session:report()
   local checks = self.example and self.example:report() or {}
   local passed = self.example ~= nil
   for _, check in ipairs(checks) do
      if not check.passed then
         passed = false
      end
   end
   local report = {
      run_id = self.run_id,
      step_id = self.step_id,
      case = self.case_name,
      action = self.action,
      ready = self.ready and passed and self.error == nil,
      error = self.error,
      checks = checks,
   }
   if self.host.describe and self.example then
      report.environment = self.host:describe(self.example.view)
   end
   if self.example then
      report.expected_error = self.example.last_error
   end
   return report
end

function Session:close()
   local example = self.example
   self.example = nil
   self.ready = false
   if example then
      return example:close()
   end
   return true
end

function Session:open(name)
   assert(not self.stopped, "тестовая сессия остановлена")
   local ok, err = self:close()
   if not ok then
      return nil, err
   end
   local example
   example, err = self.cases:open(name)
   if err then
      return nil, err
   end
   self.example = example
   self.case_name = name
   self.run_id = self.run_id + 1
   self.step_id = 0
   reset(self, "open")
   example.on_action = function(action)
      self.step_id = self.step_id + 1
      reset(self, action)
   end
   self.write_report(self:report())
   return true
end

function Session:step(name)
   assert(not self.stopped, "тестовая сессия остановлена")
   if not self.example or not self.example.actions[name] then
      return nil, goerrors.new("Действие недоступно: " .. tostring(name))
   end
   local ok, err = pcall(self.example.actions[name])
   if not ok then
      self.ready = false
      self.error = tostring(err)
      return nil, goerrors.new(self.error)
   end
   return true
end

function Session:stop()
   if self.stopped then
      return true
   end
   self.stopped = true
   local ok, err = self:close()
   for _, token in ipairs(self.tokens) do
      self.host:unsubscribe(token)
   end
   self.host:remove_command("ui_schema_test")
   if self.host.shutdown then
      self.host:shutdown()
   end
   return ok, err
end

local function update(session)
   session.updates = session.updates + 1
   if session.example and not session.ready and not session.error and session.host:now() - session.started > 5 then
      session.error = "Истёк таймаут ожидания кадров"
      session.write_report(session:report())
   end
end

local function draw_complete(session)
   if not session.example or session.error or session.ready or session.updates <= session.last_draw_update then
      return
   end
   session.last_draw_update = session.updates
   session.frames = session.frames + 1
   if session.frames >= 2 then
      session.ready = true
      local report = session:report()
      if not report.ready then
         session.ready = false
         session.error = "Проверки состояния не пройдены"
         report = session:report()
      end
      session.write_report(report)
   end
end

function Session:command(args)
   local session = self
   local operation = args[1]
   local ok, err
   if operation == "open" then
      ok, err = session:open(args[2])
   elseif operation == "step" then
      ok, err = session:step(args[2])
   elseif operation == "close" then
      ok, err = session:close()
   elseif operation == "stop" then
      ok, err = session:stop()
   elseif operation == "report" then
      session.write_report(session:report())
      return
   else
      err = goerrors.new("Команды: open <пример>, step <действие>, report, close, stop")
   end
   if not ok and err then
      session.write_report({ ready = false, error = err:error(), run_id = session.run_id, step_id = session.step_id })
   end
end

function runner.start(options)
   assert(
      type(options) == "table" and type(options.read_text) == "function" and type(options.write_report) == "function",
      "нужны options.read_text и write_report"
   )
   assert(type(options.schema_path) == "string" and type(options.host) == "table", "нужны schema_path и host")
   local builder = options.builder or ui_schema.new()
   local documents = {}
   local ok, result = pcall(function()
      for _, name in ipairs({ "layout", "controls", "rows", "resources", "lifecycle" }) do
         local text = options.read_text(options.schema_path .. "/" .. name .. ".json")
         local doc, err = builder:parse(text)
         if err then
            error(tostring(err), 0)
         end
         documents[name] = doc
      end
      return cases.create(builder, documents, options.host)
   end)
   if not ok then
      return nil, goerrors.new("Подготовка примеров: " .. tostring(result))
   end
   local session = setmetatable({
      host = options.host,
      cases = result,
      write_report = options.write_report,
      tokens = {},
      run_id = 0,
      step_id = 0,
      updates = 0,
      ready = false,
   }, Session_mt)
   local connected, connection_err = pcall(function()
      session.tokens[#session.tokens + 1] = session.host:subscribe("update", function()
         update(session)
      end)
      session.tokens[#session.tokens + 1] = session.host:subscribe("draw_complete", function()
         draw_complete(session)
      end)
      session.host:add_command("ui_schema_test", "Примеры UI: open, step, report, close, stop", function(args)
         session:command(args)
      end)
   end)
   if not connected then
      for _, token in ipairs(session.tokens) do
         session.host:unsubscribe(token)
      end
      return nil, goerrors.new("Подключение примеров: " .. tostring(connection_err))
   end
   return session
end

return runner
