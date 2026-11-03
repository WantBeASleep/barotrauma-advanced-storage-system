local mod_path = ...
if not CLIENT then
   return
end

local loaded, startup_error = pcall(function()
   local runner = require("limanchel.pkg.ui_schema.v0_1_0.manual_test.runner")
   local native = require("limanchel.pkg.ui_schema.v0_1_0.native")
   local backend = native.new()
   local file_trigger = require("limanchel.pkg.ui_schema.v0_1_0.manual_test.file_trigger")
   local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1), GUI.Canvas.Instance), nil)
   frame.CanBeFocused = false

   local host = { parent = frame.RectTransform, serial = 0, resources = {} }
   local session
   local trigger = file_trigger.new(function(args)
      session:command(args)
   end)
   local next_poll = 0
   local stop_id = "limanchel.ui_schema.manual.stop"

   function host:add_command(name, help, callback)
      Game.AddCommand(name, help, callback)
   end
   function host:remove_command(name)
      Game.RemoveCommand(name)
   end
   function host:now()
      return Timer.GetTime()
   end

   function host:subscribe(event, callback)
      self.serial = self.serial + 1
      local token = { id = "limanchel.ui_schema.manual." .. self.serial }
      if event == "update" then
         token.class = "Barotrauma.GUI"
         token.method = "Update"
         token.parameters = { "System.Single" }
         token.kind = Hook.HookMethodType.Before
         Hook.Patch(token.id, token.class, token.method, token.parameters, function()
            frame.AddToGUIUpdateList()
            callback()
            if session and Timer.GetTime() >= next_poll then
               next_poll = Timer.GetTime() + 0.25
               local request_path = mod_path .. "/manual_request.txt"
               if File.Exists(request_path) then
                  trigger:accept(File.Read(request_path))
               end
            end
         end, token.kind)
      else
         assert(event == "draw_complete", "неизвестное тестовое событие")
         token.class = "Barotrauma.GameMain"
         token.method = "Draw"
         token.parameters = { "Microsoft.Xna.Framework.GameTime" }
         token.kind = Hook.HookMethodType.After
         Hook.Patch(token.id, token.class, token.method, token.parameters, callback, token.kind)
      end
      return token
   end

   function host:unsubscribe(token)
      Hook.RemovePatch(token.id, token.class, token.method, token.parameters, token.kind)
   end
   function host:create_badge(_, rect)
      return GUI.Frame(rect)
   end
   function host:detach(object)
      return backend:detach(object)
   end
   function host:shutdown()
      backend:detach(frame)
      Hook.Remove("stop", stop_id)
   end

   function host:describe(view)
      local rects = {}
      for id, object in pairs(view.by_id) do
         local rect = object.Rect
         if rect then
            rects[id] = { x = rect.X, y = rect.Y, width = rect.Width, height = rect.Height }
         end
      end
      local content = File.Read("Content/ContentPackages/Vanilla.xml")
      local config = File.Read("config_player.xml")
      local platform_path = config:match("path=\"([^\"]-2559634234[^\"]-)\"")
      local platform_content = platform_path and File.Read(platform_path) or ""
      return {
         game_version = content:match("gameversion=\"([^\"]+)\"") or "не определена",
         game_version_source = "Vanilla.xml",
         platform = "LuaCs",
         platform_version = platform_content:match("modversion=\"([^\"]+)\"") or "не определена",
         width = GUI.Canvas.Instance.Rect.Width,
         height = GUI.Canvas.Instance.Rect.Height,
         scale = GUI.Scale,
         rects = rects,
      }
   end

   host.resources.draw = function(sprite_batch, component)
      GUI.DrawRectangle(sprite_batch, component.Rect, Color.LimeGreen, false, 2)
   end

   local prefab = ItemPrefab.Prefabs[Identifier("wrench")]
   if prefab then
      host.resources.item_sprite = prefab.InventoryIcon
   end

   local function write_report(report)
      local line = json.serialize(report)
      print("[ui_schema] " .. line)
      File.Write(mod_path .. "/manual_report.json", line)
   end

   local result, err = runner.start({
      schema_path = mod_path .. "/Lua/limanchel/pkg/ui_schema/v0_1_0/manual_test",
      read_text = File.Read,
      write_report = write_report,
      host = host,
   })
   if not result then
      host:shutdown()
      error(err:error())
   end
   session = result
   Hook.Add("stop", stop_id, function()
      session:stop()
   end)
   print("[ui_schema] Готово. Команда: ui_schema_test open controls")

end)
if not loaded then
   File.Write(mod_path .. "/manual_startup_error.txt", tostring(startup_error))
   error(startup_error, 0)
end
