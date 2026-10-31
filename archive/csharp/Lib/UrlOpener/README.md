# UrlOpener

Small C# helper for opening external URLs through Barotrauma's shell-opening API.

## Lua-facing type

Register and create the static helper with:

```lua
LuaUserData.RegisterType("YourProject.UrlOpener")
local url_opener = LuaUserData.CreateStatic("YourProject.UrlOpener")
```

## Contract

- `Open(url)` requires a non-empty URL string.
- Invalid empty input throws `ArgumentException`.
- The helper delegates to `Barotrauma.ToolBox.OpenFileWithShell`.
