# csharp/storage

Lua wrapper for a C# storage helper exposed through LuaCs.

The library wraps an already-created C# storage helper and turns C# storage
exceptions into `lib/errors` values. It does not register LuaCs types, choose a
mod namespace, or hard-code a C# type name; the composition root owns C# bridge
registration and passes the ready helper explicitly.

```lua
LuaUserData.RegisterType("YourMod.StorageException")
LuaUserData.RegisterType("YourMod.Storage")

local cs_storage = LuaUserData.CreateStatic("YourMod.Storage")

local storage_lib = assert(loadfile(LUA_PATH .. "/lib/csharp/storage/storage.lua"))({
    module_path = LUA_PATH .. "/lib/csharp/storage",
})

local storage = storage_lib.init({
    errors = errors,
}).new({
    logger = log,
    cs_storage = cs_storage,
})

storage:save_string("my-mod/settings.json", "{}")
local content = storage:load_string("my-mod/settings.json")
```

The example type names are placeholders. Each mod should register its own C#
storage helper and pass that static wrapper as `cs_storage`.

Public operations mirror the Lua-facing C# API:

- `exists(path)`
- `load_string(path)`
- `save_string(path, content)`
- `delete(path)`
- `delete_recursive_extension(path, extension)`
- `get_full_path(path)`

Missing files return `nil` from `load_string`, matching the C# contract.
Operation failures are raised with `error(errors.Error, 0)`. Stable root causes
are exposed on `storage.ERROR` for `errors.is(...)` checks.

The C# helper owns path validation and the actual storage root. Lua callers pass
storage-relative paths such as `my-mod/settings.json`.
