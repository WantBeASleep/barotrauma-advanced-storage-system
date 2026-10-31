# CSharp Template

This folder contains optional LuaCs C# source scripts.

Replace the `YourProject` namespace in C# files with a valid C# namespace for
your mod, then use the same type names from Lua:

```lua
LuaUserData.RegisterType("YourProject.Storage")
local storage = LuaUserData.CreateStatic("YourProject.Storage")
```

## Side Switches

`CSharp/RunConfig.xml` controls whether LuaCs loads C# on each side:

- `Client` is `Standard` by default.
- `Server` is `None` by default.

`ModConfig.xml` controls which C# files are compiled for each side through
`<Assembly ... Target="Client" />` and `<Assembly ... Target="Server" />`.

Enable server C# by changing both places:

1. Set `<Server>Standard</Server>` in `CSharp/RunConfig.xml`.
2. Uncomment the server `Assembly` entries in `ModConfig.xml`.

## Layout

```text
CSharp/
├─ Client/
│  └─ Plugin.cs          # client IAssemblyPlugin entrypoint
├─ Server/
│  └─ Plugin.cs          # server IAssemblyPlugin entrypoint
├─ Lib/
│  ├─ Storage/           # side-neutral text file storage helper
│  └─ UrlOpener/         # client-oriented URL opener helper
└─ RunConfig.xml         # client/server C# loading switch
```

Keep side-specific Barotrauma API calls under `Client/` or `Server/`.
Keep side-neutral DTOs and helpers under `Lib/`.
