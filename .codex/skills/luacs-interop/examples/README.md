# Связанные примеры

**Пример:** [bridge-demo](bridge-demo) — отдельный образец мода, не подключённый к рабочему проекту. C# типы и бизнес-обработка: [Contracts.cs](bridge-demo/CSharp/Contracts.cs); plugin: [Plugin.cs](bridge-demo/CSharp/Plugin.cs); Lua: [main.lua](bridge-demo/Lua/Autorun/main.lua). Это autorun-сценарий, не общий Lua-пакет; соглашение о версиях пакетов к нему не применяется.

## В игре

1. Используй LuaCs версии из [протокола](../references/validation.md) с установленной клиентской/серверной частью и включённым C#. На исследованном компьютере workshop и папка игры отличаются; файлы автоматически не заменялись.
2. Скопируй **только** каталог `bridge-demo` целиком в новый `LocalMods/luacs-bridge-demo`, сохранив filelist.xml, ModConfig.xml, CSharp и Lua. Не смешивай его с рабочим модом. Это инструкция для ручного игрового прогона; исследование не выполняло эту установку.
3. Включи LuaCs и пример в списке модов, примени изменения/перезагрузи LuaCs. ModConfig явно включает оба C# файла и Lua autorun; Target=Any допускает обе стороны, при включённом на них C#.
4. Ожидай `BridgeDemo PASS: total=5, callback=6, event=5`. При ошибке сначала смотри compilation/load log, затем Lua assertion.

`PreInitPatching`, `Initialize`, `OnLoadCompleted`, `Dispose` реализуют IAssemblyPlugin. Регистрация DTO происходит в Lua после загрузки C#. Отдельные C#-фабрики показаны как вариант, а основной пример использует реальные конструкторы и setters. Вложенные `Line` сохраняются по ссылке, контейнер table → array создаётся заново. Result намеренно разделяет Lines с Request.

Callback `ProcessAndNotify` одноразовый и синхронный: Lua function → Closure → C# вызывает Lua с Result → Lua возвращает 6 → C# преобразует его в int. Publisher показывает отдельный механизм событий и отписку тем же экземпляром функции. Долгоживущие игровые callbacks потребуют очистки по [правилам жизненного цикла](../references/lifecycle.md).

## В изолированном host

Проверено исполнением вне игры. Новый процесс PowerShell 7.6, .NET 10, Roslyn Add-Type; .NET 8 workshop assemblies загружаются как библиотеки. Нужен полный каталог Binary, не только MoonSharp.dll.

**Пример:** из корня проекта:

```powershell
pwsh -NoProfile -File .codex/skills/luacs-interop/examples/probes/run.ps1 `
  -BinaryRoot 'D:/SteamLibrary/steamapps/workshop/content/602960/2559634234/Binary'
```

[run.ps1](probes/run.ps1) компилирует Contracts, Plugin, [ProbeTypes.cs](probes/ProbeTypes.cs), [Host.cs](probes/Host.cs) в память. Host использует настоящий `LuaUserDataService` из workshop Barotrauma.dll. Только `IPluginManagementService.GetType` заменён поиском по уже загруженным сборкам через DispatchProxy. Host задаёт CSActive и минимальные registrations, включает такую же обработку CLR exceptions в pcall, но не запускает `DefaultLuaRegistrar`, все `LuaConverters`, LuaSetup, game loader, сеть и GUI.

Затем выполняются неизменённый demo autorun и [probes.lua](probes/probes.lua). Ожидаются demo PASS, 20 строк PASS и `Bridge probes PASS: 20`. DLL и моды не изменяются. Host — проверка runtime/service конвертации, не имитация успешной установки платформы и не полный integration test. [Точный протокол](../references/validation.md).
