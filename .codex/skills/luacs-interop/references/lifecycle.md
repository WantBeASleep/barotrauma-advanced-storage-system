# Callback, загрузка и время жизни

## Способы вызова C# → Lua

| Способ | Конверсия / результат | Ошибки и удержание |
| --- | --- | --- |
| Параметр `Closure` | Lua function преобразуется автоматически; `callback.Call(result)` возвращает DynValue; `ToObject<int>()` задаёт контракт результата | Прямой синхронный вызов пробрасывает ошибку. Closure удерживает OwnerScript. E/S M6, M19 |
| `ScriptFunctionDelegate` | Runtime предоставляет `Closure.GetDelegate()` | Ссылка также удерживает closure; не обещает интеграции с выгрузкой LuaCs. S M6 |
| Игровой delegate, например `GUIButton.OnClickedHandler` | LuaCs регистрирует конкретный converter; GUI вызывает `(button, userData)`, результат приводится к bool | Converter идёт через CallFunctionSafe, логирует ошибку и может вернуть false. Поле OnClicked удерживает delegate/closure. S P5, G1; W Real Sonar |
| Произвольный `Func<int,int>` | Нужен собственный converter либо фасад с Closure | В тесте прямое присвоение функции не поддержано. Не обобщай доступность `Action<float>` на все Action/Func. E/S M6, P5 |
| `event Action<Result>` | EventFacade принимает `.add(lua_function)` и `.remove(the_same_function)` | Отдельный механизм, не универсальный delegate converter; descriptor хранит callbacks и subscribers. E/S M12 |
| `Hook.Add(name,id,fn)` | EventService/LuaCs hook dispatch; смысл параметров и возвращаемого значения задаёт конкретный hook | Снимай через соответствующий Remove; нельзя переносить контракт одного hook на другой. S P10 |
| `Hook.Patch` | LuaPatcher вызывает callback вокруг C# метода; доступ к параметрам зависит от patch API | Это перехват вызова, а не DTO mapper. Очистка патча и уникальный ID обязательны для управляемого владельцем срока жизни. S P11; W Enhanced Reactors / Real Sonar |

Источники: [M6](sources.md#m6), [M12](sources.md#m12), [M19](sources.md#m19), [P5](sources.md#p5), [P10](sources.md#p10), [P11](sources.md#p11), [G1](sources.md#g1).

### Ограничения события

`EventMemberDescriptor.CheckEventIsCompatible`: владелец не value type; есть add/remove; handler возвращает void; не более 16 параметров; параметры не value type и не by-ref. Поэтому `Action<Result>` как **event** работает, а `event Action<int>` стандартным EventFacade не экспортируется. Это не то же самое, что свойство `Action<Result>`: для свойства потребуется converter. **S/E:** M12, probes.

Храни исходную Lua-функцию для отписки. Новый `function(...) ... end` с тем же текстом — другое замыкание. `EventMemberDescriptor.DispatchEvent` вызывает `Closure.Call` напрямую; safe-dispatch LuaCs и проверка актуальности Script здесь не добавляются. **S:** M12.

## Загрузка

В исследованной версии `ModConfig.xml` явно задаёт `<Assembly File="..." IsScript="true" Target="Client|Server|Any"/>` и `<Lua ... IsAutorun="true"/>`. При отсутствии ModConfig есть legacy-discovery каталогов. Не смешивай маршруты загрузки вслепую. Отдельный `CSharp/RunConfig.xml` не требуется для явного примера: в текущем пути ModConfig ресурсами управляют Target и глобальная настройка C#. Наличие старого RunConfig в workshop-моде не доказывает, что именно он управляет новой загрузкой. **S:** [P8](sources.md#p8), [P9](sources.md#p9), [P7](sources.md#p7).

C# сборки загружаются/активируются перед Lua autorun. Для plugin: `PreInitPatching` → `Initialize` → `OnLoadCompleted`; загрузка всех типов не равна выполнению бизнес-инициализации. Не вызывай Lua из Initialize, предполагая, что пользовательский autorun уже создал globals. **S:** [P2](sources.md#p2), [P7](sources.md#p7).

Для client/server в одном исходнике используй общий API или явные `#if CLIENT`/`#if SERVER`. Раздельные процессы имеют разные экземпляры DTO, Script и registrations. Пример Target=Any исполняется на каждой включённой стороне отдельно. GUI-only API на сервере недоступен независимо от правильности Lua-синтаксиса.

## Очистка и reload

В обычном выходе из Running платформа вызывает `EventService.Call("stop")`, затем останавливает пакеты. `StopRunningPackages` выгружает Lua scripts и managed assemblies; `OnAssemblyUnloading` удаляет регистрацию типов с `deleteHistory: true`. `LuaUserDataService.Reset` очищает локальный словарь descriptors, а не является универсальным способом очистки всех внешних подписок. **S:** [P12](sources.md#p12), [P7](sources.md#p7), [P3](sources.md#p3), [P1](sources.md#p1).

Для длительной подписки владелец должен:

1. Хранить callback и токен/источник подписки; определить явную операцию завершения.
2. До потери Script снять event handler, hook, timer, patch, сбросить delegate fields и собственные ссылки на Closure/Table.
3. В `Dispose` C# прекратить генерацию событий, отменить ожидающую работу и освободить ссылки. Операция должна выдерживать повторное завершение.
4. После reload заново получить типы, экземпляры и wrappers. Оставшаяся userdata не делает выгруженную сборку пригодной к дальнейшей работе.

**Пример:** в [main.lua](../examples/bridge-demo/Lua/Autorun/main.lua) события снимаются сразу, затем Publisher.Dispose запрещает новые вызовы. Это намеренно короткий жизненный цикл, который проверен E. Реальная игра/reload/аварийная выгрузка — U; не выдавай этот пример за проверку остановки игрового мода.

## Потоки

LuaCs отключает `CheckThreadAccess`, но `CallFunctionSafe` использует lock. Это не разрешение менять GUI/Entity с worker thread. Прямой `Closure.Call` и EventFacade не используют этот service lock. Для background-работы вычисляй независимые данные, доставляй завершение на допустимый игровой поток и проверяй, что операция ещё принадлежит текущему запуску. Конкретный dispatcher выбирай по API целевой версии; универсальный непроверенный `RunOnMainThread` здесь не предлагается. **S:** [P3](sources.md#p3), [M12](sources.md#m12).

## Сеть и сериализация

Ссылка userdata действует внутри процесса. `Networking.Start/Send/Receive` передаёт сериализованные поля сообщения, а JSON-файл — сохранённые данные. Нужны формат, проверка входа, версия и обработка отсутствующих объектов. Tactical Sonar обменивается Lua/C# настройками через файл; это не доказательство автоматического общего DTO. См. [каталог](mod-patterns.md).
