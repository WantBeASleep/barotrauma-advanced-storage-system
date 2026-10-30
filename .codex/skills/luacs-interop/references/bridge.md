# Устройство моста

## Три уровня

| Уровень | Что обеспечивает | Что не следует из его наличия |
| --- | --- | --- |
| Форк MoonSharp | `DynValue`, `UserData`, descriptors, конвертеры, binder перегрузок, вызовы `Closure` | Наличие игрового API и его регистрация |
| LuaCs | Загрузка сборок/скриптов, поиск типов, `LuaUserData`, регистрация игры, специальные конвертеры, хуки, безопасный вызов Lua | Корректность конкретного игрового действия и сетевой синхронизации |
| Barotrauma / код мода | Конструкторы, свойства, игровые правила, DTO и обработчики | Автоматический экспорт любого типа и одинаковое API клиента/сервера |

**S:** [P1–P5](sources.md#p1), [M1](sources.md#m1), [M6–M8](sources.md#m6). Код игры исследован в точной ревизии LuaCs; для вывода об оригинальной игре сравни upstream отдельно.

## Lua → C#

1. `PackageManagementService.ExecuteLoadedPackages` сначала загружает и активирует C#-сборки, затем выполняет Lua. `PluginManagementService.GetType` ищет в системных/игровых и загруженных модовых сборках. При выключенном C# используется ограниченный `SafeLuaUserDataService`; свой namespace не входит в его обычный whitelist. **S:** [P2](sources.md#p2), [P6](sources.md#p6), [P7](sources.md#p7).
2. `LuaUserData.RegisterType(full_name)` вызывает `UserData.RegisterType(Type)` и сохраняет descriptor. Descriptor описывает доступные члены; это не экземпляр DTO и не Lua-таблица его данных. `CreateStatic` возвращает static userdata с descriptor типа и `Object == null`. `CreateStatic` не заменяет регистрацию. **S/E:** [P1](sources.md#p1), [M17](sources.md#m17), [проверки](validation.md).
3. `StandardUserDataDescriptor.FillMemberList` добавляет публичные совместимые методы, свойства, поля, события, конструкторы под `__new`; учитывает атрибуты видимости и скрытия. Для struct есть descriptor конструктора по умолчанию. Закрытые члены могут быть добавлены LuaCs через `MakeFieldAccessible`, `MakeMethodAccessible`, `MakePropertyAccessible`. `AddMethod`/`AddField` меняют descriptor, а не CLR-определение типа. **S:** [M1](sources.md#m1), [P1](sources.md#p1).
4. VM `ExecIndex/ExecIndexSet` обращается к `descriptor.Index/SetIndex`; descriptor различает члены и индексатор. Для методов создаётся bound callback с целевым объектом. Статические вызовы оформляй `Api.Process(request)`, экземплярные — `object:Method(arg)`; вариант bound-dot также встречается в модах. Не добавляй `self` вручную к bound-dot. **S/E:** [M2](sources.md#m2), [M5](sources.md#m5), [M15](sources.md#m15).
5. `Type(...)` в этом форке перехватывается `Processor.GetMetamethod("__call")`, находит `__new` и вызывает его без неявного первого аргумента. `Type.__new(...)` вызывает тот же constructor descriptor напрямую. Никакого поиска `init` или `new` здесь нет. **S/E:** [M16](sources.md#m16); `BridgeDemo.Line` вообще не имеет этих методов.
6. `OverloadedMethodMemberDescriptor` сортирует и оценивает кандидатов по весам преобразований, optional/ref/params и количеству аргументов; результат кешируется по Lua-типам и userdata descriptors. При равных весах это не диагностика неоднозначности компилятора C#: побеждает первый лучший кандидат после сортировки. Один кандидат вызывается сразу. **S:** [M4](sources.md#m4). Не проектируй контракт на случайном выигрыше `int` против `long` или `object` против DTO.
7. `BuildArgumentList` преобразует аргументы через `ScriptToClrConversions`, подставляет default, собирает params, фиксирует ref/out; `MethodMemberDescriptor.Execute` вызывает compiled delegate либо reflection. `BuildReturnValue` преобразует обычный результат; при ref/out создаёт Lua tuple: результат, затем изменённые параметры. **S/E:** [M3](sources.md#m3), [M5](sources.md#m5), [M6](sources.md#m6).
8. `ClrToScriptConversions` сначала проверяет null/DynValue/пользовательские конвертеры/простые типы; затем userdata, незарегистрированный enum, delegates, коллекции и перечисления. Зарегистрированная коллекция перехватывается userdata-веткой раньше превращения в Lua table. **S/E:** [M7](sources.md#m7), [M8](sources.md#m8).

## C# → Lua

Передача Lua-функции в `Closure` сохраняет настоящий объект замыкания с `OwnerScript`. `Closure.Call` → `Script.Call` → преобразование C# аргументов в DynValue → VM → результат DynValue → явный `ToObject<T>()` при необходимости. `ScriptFunctionDelegate` также поддержан runtime. Для произвольного CLR delegate универсальной автоматической конверсии нет. **S/E:** [M6](sources.md#m6), [M19](sources.md#m19).

LuaCs добавляет конвертеры конкретных `Action`, `Func`, игровых GUI delegates, `LuaCsAction`, `LuaCsFunc`, patch и networking callback. Часть вызывает `CallFunctionSafe`, часть — напрямую `Closure.Call`; только некоторые проверяют `OwnerScript`. Поэтому одинаковое слово «callback» не гарантирует одинаковую обработку исключений и reload. **S:** [P5](sources.md#p5). События имеют отдельный механизм `EventFacade.add/remove`: [жизненный цикл](lifecycle.md).

В `Script.Call` C# аргументы проходят `DynValue.FromObject`; перед VM-вызовом проверяется принадлежность функции/значений Script. [M21](sources.md#m21). Это объясняет, почему сохранённая Lua-функция не становится автоматически функцией нового окружения после reload.

Для имён используй точное написание C#-члена. Descriptor может применять `FuzzySymbolMatching` (первая заглавная буква/camel/pascal), но наличие альтернативного написания зависит от глобальных флагов и может скрывать опечатку. **S:** [M2](sources.md#m2). Глобальные `Int32`, `Vector2` и подобные создаются отдельной LuaCs-надстройкой: [W2](sources.md#w2).

## Ошибки

Ошибка поиска типа возникает в LuaCs; ошибка доступа — в descriptor/VM; ошибка аргумента — при конвертации либо binder; исключение бизнес-логики — уже внутри C#. VM разворачивает `TargetInvocationException`, добавляет контекст и передаёт обработчику ошибки. **S:** [P1](sources.md#p1), [M15](sources.md#m15).

В LuaCs `ShouldPCallCatchException` включён для CLR exceptions. **Пример:** `local ok, err = pcall(function() return Api.Process(request) end)`; в проверенном сценарии `err` — строка, а не DTO исключения. Регистрация класса исключения не превращает ошибку `pcall` в этот класс. **S/E:** [P3](sources.md#p3), [M18](sources.md#m18), [validation](validation.md).

`CallFunctionSafe` проверяет `IsRunning`, синхронизирует доступ через `lock(_script)`, ловит и логирует исключения, возвращает null при ошибке. Успешный Lua `nil` — DynValue.Nil; для вызывающего C# это другой случай. В GUI-конвертере `?.CastToBool() ?? default` ошибка может выглядеть как `false`. **S:** [P3](sources.md#p3), [P5](sources.md#p5).
