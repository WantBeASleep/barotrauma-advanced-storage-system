# errors

Small tree-shaped error library for LuaCs mods.

An error has a `context` string and optional `cause` array. When `cause` is
`nil`, the error is a root cause and `context` is the cause searched by `is`.

```lua
local errors = assert(loadfile(LUA_PATH .. "/lib/errors/errors.lua"))()

local invalid_path = errors.new("invalid path")
local save_failed = errors.wrap("save settings", invalid_path)

print(save_failed:error())
print(errors.is(save_failed, "invalid path"))
```
