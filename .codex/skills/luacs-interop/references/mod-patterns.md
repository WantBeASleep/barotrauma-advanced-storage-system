# Практики установленных модов

**W** означает наблюдение в исходниках мода, не успешное исполнение. Корень всех путей ниже: `D:/SteamLibrary/steamapps/workshop/content/602960/`. Снимок версий и SHA256: [инвентаризация](../../../../docs/features/luacs-interop/workshop-inventory.md), [файлы](../../../../docs/features/luacs-interop/workshop-files.json). Полный файловый охват — 42 каталога, 111 Lua и 54 C# файлов; вручную разобраны следующие цепочки разных механизмов. Статус отдельных модов в игре не проверялся.

## 1. Собственные вложенные DTO и фабрики

**QoL - Medical icons, 3748775860.**

- Lua: `Lua/limanchel/medical_icons/csharp/overlay_calculator/csharp_bridge.lua:65`, `csharp_bridge.init`: регистрация calculator/coords/request, а также returned-only rect/result; `CreateStatic`.
- Lua: `.../overlay_calculator/init.lua:67`, `create_csharp_request`: создаёт три coords через `.init`, затем request; `calculate:89` вызывает `Calculate` внутри pcall.
- C#: `CSharp/Client/OverlayCalculator/OverlayCalculator.cs:23–113`, классы `OverlayCalculatorCoords`, `OverlayCalculatorRequest`, `OverlayCalculatorResult`; `Calculate:162` валидирует, считает оси, возвращает вложенные result DTO.

**Пример:** связанные сокращённые фрагменты:

```lua
local container_size = descriptors.csharp_coords.init(request.ContainerSize.X, request.ContainerSize.Y)
-- Созданы также content_size и desired_position.
return descriptors.csharp_request_dto.init(container_size, content_size, desired_position)
-- Затем descriptors.csharp_calculator.Calculate(csharp_request).
```

```csharp
public static OverlayCalculatorCoords init(int x, int y)
{
    return new OverlayCalculatorCoords(x, y);
}
// Calculate(OverlayCalculatorRequest request) возвращает
// new OverlayCalculatorResult(new OverlayCalculatorRect(...), new OverlayCalculatorCoords(...)).
```

Задача: перенести расчёт геометрии в C#, оставив Lua понятный контракт. Механизм: registered userdata и обычные static factories/methods ([P1](sources.md#p1), [M3](sources.md#m3), [M7](sources.md#m7)). Достоинство — типизированная граница и регистрация результатов; цена — поддержка Lua-адаптера и аннотаций. `init` явно определён модом; требование платформы из этого не следует. Применимость зависит от включённого клиентского C# и точных имён типов; `Plugin.cs` использует новый `Barotrauma.LuaCs.IAssemblyPlugin`.

## 2. Вложенные массивы DTO с явным CLR-типом

**Тот же Medical Icons, 3748775860**, другой сценарий той же кодовой базы, не независимое подтверждение популярности.

- Lua: `.../atlas_composer/csharp_bridge.lua:99–179`: регистрирует System.Type, берёт `descriptor.Type`, создаёт static wrappers.
- Lua: `.../atlas_composer/dto_factory.lua:29–31`: `create_csharp_array`; `create_overlay_apply:45`, `create_overlay_pack_operation:88`, `create_overlay_pack_operations:115` последовательно создают элементы и обёртки двух уровней.
- Lua: `.../atlas_composer/init.lua:68–75`: передаёт готовые operations в C#.
- C#: `CSharp/Client/AtlasComposer/AtlasComposer.cs:29–117`: `AtlasOverlayPackOperation.Overlays : AtlasOverlayApply[]`, собственные фабрики `init`; `Compose:126` принимает `AtlasOverlayPackOperation[]`, далее `ComposeInner` проверяет операции.

**Пример:** ключевая граница:

```lua
return LuaUserData.CreateUserDataFromType(values, element_type:MakeArrayType())
-- После сборки:
-- descriptors.csharp_composer.Compose(input_atlas_path, output_storage_path, csharp_operations)
```

```csharp
public static int Compose(string inputAtlasPath, string outputStoragePath,
    AtlasOverlayPackOperation[] operations)
```

Механизм: `ToObject(Type)` + userdata с descriptor ([P1](sources.md#p1), [M8](sources.md#m8)). Плюс — тип сохранён до binder; ограничение — копирование контейнеров и доступность System.Type. Для этой конкретной non-params typed signature плотная table из DTO также поддерживается runtime; использование обёртки в моде не доказывает её обязательность. Для object/params это различие существенно. Сам рендеринг атласа здесь не выполнялся.

## 3. Делегат игрового GUI и обход IEnumerable

**Real Sonar, 2936760984**: `Lua/easysettings.lua:11–32`, `GetChildren`, patch `GUI.TogglePauseMenu`, создание `GUI.Button`, присваивание `button.OnClicked`.

**Enhanced Immersion, 2968896556**: `Lua/EnhancedImmersion/Utils/gui.lua:23–31`, `gui.Button`; `SliderLabel:34`, `TickBox:50` присваивают другие GUI delegates.

**Пример:**

```lua
for value in comp.GetAllChildren() do table.insert(tbl, value) end
button.OnClicked = function() value.OnOpen(frame) end
```

Связанный C# находится **в платформе/игре**, не в этих Lua-only модах: `GUIButton.cs:15–16` определяет `delegate bool OnClickedHandler(GUIButton button, object obj)` и поле; строка 299 вызывает его. `LuaConverters.RegisterLuaConverters` регистрирует точный handler и возвращает `Call(f,a1,a2)?.CastToBool() ?? default`. [G1](sources.md#g1), [P5](sources.md#p5), [M7](sources.md#m7).

Плюс — естественный callback без собственной C# сборки. Ограничения — client-only, конкретный converter, bool-контракт и удержание closure полем GUI. Отсутствие return в примере не является рекомендацией: проектируя свой обработчик, задай осмысленный bool.

**Происхождение:** оба файла прямо указывают, что адаптированы из EvilFactory LuaAudioOverhaul (workshop 2868921484, отсутствует в установленном наборе). Это семейство производных GUI helpers, а не два независимых изобретения. Полных совпадений SHA256 среди всех 165 исходников не найдено; это не исключает адаптированных копий.

## 4. Открытие закрытых полей и CLR-индексация

**Press-R-to-Reload, 3413495302**: `Lua/Autorun/ReloadLua.lua:3–7` регистрирует nested `ItemContainer+SlotRestrictions`, закрытый generic ImmutableArray и открывает `slotRestrictions`/`slots`; строка 323 читает `itemContainer.slotRestrictions[i-1]`. Hook `Character.ControlLocalPlayer:475–496` запускает логику после игрового метода.

**Пример:**

```lua
LuaUserData.MakeFieldAccessible(Descriptors['Barotrauma.Items.Components.ItemContainer'], 'slotRestrictions')
local handInvSlotRestriction = itemContainer.slotRestrictions[i-1]
```

Связанный C#: `ItemContainer.cs:266`, `private readonly ImmutableArray<SlotRestrictions> slotRestrictions`. [G3](sources.md#g3). LuaCs добавляет `FieldMemberDescriptor` закрытого поля; registry закрытого типа даёт доступ к CLR indexer. readonly запрещает замену поля, а не чтение элементов. Плюс — доступ к недостающей информации; риски — частный контракт игры, 0-based индексы, assembly-qualified generic name с `Barotrauma`, отличия серверной сборки.

**Press R to Reload GE Compatible Patch, 3457759775**: `Lua/Autorun/reloadPatch.lua:1–31` повторяет открытие тех же полей, читает `handInv.slots`, перебирает restrictions, вызывает `TryPutItem(...,index-1,...)`. Это связанный compatibility patch той же механики; не считать независимой библиотекой. Актуальность поведения перезарядки и индексов не проверялась игровым запуском.

## 5. Закрытый static method с optional-параметром

**Enhanced Reactors, 3045796581**: `Lua/Autorun/init.lua:5` открывает `Explosion.GetObstacleDamageMultiplier`; `Lua/enhancedreactors.lua:83` вызывает с тремя аргументами.

**Пример:**

```lua
LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Explosion"], "GetObstacleDamageMultiplier")
-- Далее: Explosion.GetObstacleDamageMultiplier(sim_position, world_position, target_sim_position)
```

Связанный C#: `Explosion.cs:777`, `private static float GetObstacleDamageMultiplier(Vector2 explosionSimPos, Vector2 explosionWorldPos, Vector2 targetSimPos, IEnumerable<Structure> ignoredCover = null)`. [G2](sources.md#g2). LuaCs добавляет method descriptor; runtime подставляет null для отсутствующего четвёртого параметра. Плюс — повторное использование игровой физики; ограничения — частное имя/перегрузки/единицы координат. При появлении перегрузок передай точный список типов в `MakeMethodAccessible`; это выбирает reflection method для добавления, а не универсальный синтаксис выбора любой перегрузки из Lua.

## 6. Extension method, скрытый за экземплярным вызовом

**Lua Linker, 2852315967**: `Lua/Autorun/lualinker.lua:5–15`, `LinkAdd/LinkRemove`; hook `luaLinker.onUse:33` получает item и вызывает логику связывания.

**Пример:**

```lua
target.AddLinked(otherTarget)
otherTarget.AddLinked(target)
```

В C# это не найденный по имени метод Item: `BarotraumaExtensions.cs:12`, `MapEntityExtensions.AddLinked(this MapEntity entity, MapEntity other)` делает `entity.linkedTo.Add(other)`. `DefaultLuaRegistrar.cs:186` регистрирует extension type, binder подставляет target первым аргументом. [P4](sources.md#p4), [M4](sources.md#m4), [M5](sources.md#m5); [постоянный исходник extension](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/BarotraumaExtensions.cs#L12).

Плюс — удобный API над игровым объектом; зависимость — extension registration LuaCs, а не только версия vanilla класса. Двусторонняя запись связей и multiplayer-ограничения — решения мода; одно наличие extension не доказывает сетевую репликацию.

## 7. Файл настроек между Lua и C#

**Tactical Sonar [beta], 3755729681.** `Lua/Autorun/enhanced_sonar_settings_menu.lua:24–60`: `Menu.ConfigFileName`, `getConfigPath`, `saveConfig` пишет JSON. `CSharp/Client/EnhancedSonar.PerformanceSettings.cs:18–50`: то же имя файла; `GetPerformancePreset` раз в 3 секунды читает файл, `ExtractPerformanceModeValue` разбирает настройку; `GetPerformanceConfigPath` находит путь.

**Пример:**

```lua
File.Write(getConfigPath(), json.serialize(Menu.Config))
```

```csharp
string text = File.ReadAllText(path);
string mode = ExtractPerformanceModeValue(text);
```

Здесь связь доказана общим файлом и полем PerformanceMode, а не наличием двух языков. Это сериализация/опрос диска, **не** userdata bridge. Плюсы — независимость от регистрации DTO и сохранение между запусками; ограничения — задержка, поиск пути, неполная/конкурирующая запись, собственный parser. Зависит от файлового доступа и GUI LuaCs, но не от конвертера `Table → custom DTO`.

В `enhanced_sonar_real_sonar_compat.lua:1177–1189` также есть `Networking.Receive` с Lua callbacks. Поиск одинаковых имён сообщений в C# не выявил соответствующего отправителя; это не записано как доказанный C# → Lua сетевой протокол. Название «bridge» в коде не доказывает механизм.

## Отрицательные результаты и границы

BetterHealthUI (3231293294), ConditionBarsForInteractionLabels (3471496395), More Orders (3574799606) содержат C# plugins, но исходников Lua в них нет. `GUIComponent.UserData` в их C# — произвольное поле игры, не доказательство MoonSharp userdata. Они не включены в каталог собственных межъязыковых DTO.

В просмотренном наборе не найден отдельный независимый модовый custom converter или C# event/Closure API для Lua, пригодный как второй источник собственных DTO/callback практик. Это ограничение выборки; возможности подтверждены платформой и нашими E-примерами. DLL-only реализации не исследованы массовой декомпиляцией. Статический просмотр не доказывает отсутствие динамически создаваемых взаимодействий.
