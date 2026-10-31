# Lua-код и C#-библиотеки

Организация игрового кода и доступные библиотеки. Пути указаны относительно корня репозитория.

Размещение и версии общих пакетов регулирует [соглашение pkg](packages.md).
Упоминания `lib` ниже описывают прежнее размещение библиотек до их переноса.

## Lua-код

Runtime Lua-код рассчитан на Lua 5.2 через LuaCsForBarotrauma/MoonSharp.
Разделяйте клиентский, серверный и общий код; используйте API только на той стороне,
для которой он предназначен.
Держите проектный код под namespace, чтобы не конфликтовать с другими модами:

```text
Lua/
+-- Autorun/
|   +-- main.lua
+-- your_namespace/
    +-- your_project/
        +-- lib/
        +-- feature/
            +-- module.lua
```

В шаблоне уже есть Lua-библиотеки под
`Lua/your_namespace/your_project/lib`:

- [logger](../../Lua/your_namespace/your_project/lib/logger/README.md) - dependency-injected логирование с настраиваемым sink и уровнями.
- [errors](../../Lua/your_namespace/your_project/lib/errors/README.md) - древовидные error-значения для wrapping и классификации ошибок.
- [file](../../Lua/your_namespace/your_project/lib/file/README.md) - строгие чтения text files с ошибками через `lib/errors`.
- [ui_runtime](../../Lua/your_namespace/your_project/lib/ui_runtime/README.md) - строгий JSON-to-Barotrauma-GUI renderer и node adapters.
- `utils` - небольшие pure Lua helpers.
- [csharp/storage](../../Lua/your_namespace/your_project/lib/csharp/storage/README.md) - Lua wrapper над C# storage helper.
- [csharp/url_opener](../../Lua/your_namespace/your_project/lib/csharp/url_opener/README.md) - Lua wrapper над C# URL opener helper.

Перед изменением библиотеки прочитайте её README. Правила работы с контрактами
и зависимостями описаны в [lua-style](../../.codex/skills/lua-style/SKILL.md).

Документация:

- [LuaCsForBarotrauma docs](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/index.html)
- [LuaCsForBarotrauma repository](https://github.com/evilfactory/LuaCsForBarotrauma)
- [Barotrauma modding docs](https://regalis11.github.io/BaroModDoc/)

## Библиотека ошибок

Для ошибок Lua-модулей выбрана [lib/errors](../../Lua/your_namespace/your_project/lib/errors/README.md), передаваемая как зависимость `errors`. Это проектное соглашение; оно не означает, что все библиотеки уже связаны загрузчиком.

- Общий тип ошибки — `errors.Error`.
- Первопричину создавай из публичной таблицы модуля: `errors.new(module.ERROR.cause)`; для классификации используй `errors.is(err, module.ERROR.cause)`.
- Динамический контекст добавляй через `errors.wrap(context, err)`.

## Опциональные C# helpers

`CSharp/` содержит опциональные LuaCs C# source scripts.
Подробности находятся в [документации C#](../../CSharp/README.md):

```text
CSharp/
+-- Client/Plugin.cs              # Client IAssemblyPlugin entrypoint
+-- Server/Plugin.cs              # Server IAssemblyPlugin entrypoint
+-- Lib/Storage/Storage.cs        # Side-neutral storage helper
+-- Lib/UrlOpener/UrlOpener.cs    # Client-oriented URL opener helper
+-- RunConfig.xml                 # Client/server C# loading switch
```

`CSharp/RunConfig.xml` управляет тем, на каких сторонах загружается C#.
По умолчанию client C# включен, server C# выключен. `ModConfig.xml` управляет
тем, какие C# source files компилируются для каждой стороны и какой Lua autorun
файл загружается.

Перед использованием C# helpers в реальном моде замените namespace
`YourProject` и синхронизируйте строки
`LuaUserData.RegisterType(...)` / `CreateStatic(...)` в Lua.

[К оглавлению разработки](README.md).
