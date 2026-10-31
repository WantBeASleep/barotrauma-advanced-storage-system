# Logger

`logger` is a small shared Barotrauma LuaCs logging library.

The library has one public entry point:

```lua
local logger = assert(loadfile(LUA_PATH .. "/lib/logger/logger.lua"))()
```

Create a logger by passing all runtime dependencies through `logger.new`.

In a normal Barotrauma client mod, the sink is usually a small wrapper around
`Barotrauma.DebugConsole`. Create the console in the composition root and pass a
sink object into the logger:

```lua
local console = LuaUserData.CreateStatic("Barotrauma.DebugConsole")

local sink = {}

function sink:write(text, color)
    console.NewMessage(text, color, false)
end

local log = logger.new({
    prefix = "My Mod",
    min_level = logger.levels.trace,
    sink = sink,
})
```

The constructor requires `prefix`, `min_level`, and `sink`. Missing values are wiring errors and fail immediately.

The sink owns the output behavior. The logger does not create `DebugConsole`, catch sink errors, or fall back to `print`; the composition root decides which sink to provide and how failures should be handled.

Use `log:with_prefix("Section")` to create a child logger that shares the same sink and minimum level.
