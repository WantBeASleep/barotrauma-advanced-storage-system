# csharp/url_opener

Lua wrapper for a C# URL-opening helper exposed through LuaCs.

The library wraps an already-created C# static helper and turns LuaCs/C#
exceptions into `lib/errors` values. It does not register LuaCs types, choose a
mod namespace, or hard-code a C# type name; the composition root owns C# bridge
registration and passes the ready helper explicitly.

```lua
LuaUserData.RegisterType("YourProject.UrlOpener")

local cs_url_opener = LuaUserData.CreateStatic("YourProject.UrlOpener")

local url_opener = assert(loadfile(LUA_PATH .. "/lib/csharp/url_opener/url_opener.lua"))({
    module_path = LUA_PATH .. "/lib/csharp/url_opener",
    errors = errors,
}).new({
    logger = log,
    cs_url_opener = cs_url_opener,
})

url_opener:open("https://example.com")
```

The example type name is a placeholder. Each mod should register its own URL
opener helper and pass that static wrapper as `cs_url_opener`.

Public operations:

- `open(url)`

The C# helper owns URL validation and the actual shell-opening behavior.
Operation failures are raised with `error(errors.Error, 0)`. Stable root causes
are exposed on `url_opener.ERROR` for `errors.is(...)` checks.
