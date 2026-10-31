# file

Small text file helper library for LuaCs mods.

The library reads required files and raises I/O failures with `lib/errors`
values through `error(err, 0)`. It does not log, choose fallbacks, or hide
missing files because the caller owns the operation context.

Known root causes are exposed through `file.ERROR`. These strings are stable
classification values for `errors.is`; dynamic details stay in wrapped context.

```lua
local errors = assert(loadfile(LUA_PATH .. "/lib/errors/errors.lua"))()
local file = assert(loadfile(LUA_PATH .. "/lib/file/file.lua"))()
file.init({
    errors = errors,
})

local ok, result = pcall(function()
    return file.read_all(MOD_PATH .. "/assets/index.json")
end)

if not ok and errors.is(result, file.ERROR.open_failed) then
    print("asset index file could not be opened")
end

if not ok then
    error(errors.wrap("load asset index", result), 0)
end
```
