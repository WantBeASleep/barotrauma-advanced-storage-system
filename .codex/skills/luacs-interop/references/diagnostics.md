# Диагностика по этапам

Сначала зафиксируй сторону, DLL/ProductVersion, `CSActive`, точный вызов и полный текст ошибки. Уменьши запрос до одного DTO/элемента/вызова; после изменения регистрации повтори в свежем Script, поскольку registry и converter state общие. Источники причин: [P1–P7](sources.md#p1), [M1–M18](sources.md#m1).

| Симптом | Проверка | Причина / исправление |
| --- | --- | --- |
| Тип не существует | Файл включён в ModConfig? Target совпадает? C# включён? Есть ошибка compilation? Полное имя с namespace и `+` для nested? | `RegisterType` сначала вызывает lookup загруженных сборок. Исправь загрузку/имя, затем регистрацию; `CreateStatic` не скомпилирует отсутствующий тип |
| Тип есть, член отсутствует | Public/hidden? static/instance? Descriptor конкретного типа или базового? Член совместим с runtime? | Проверь отражённую сигнатуру; для собственной библиотеки открой публичный фасад, для нужного закрытого игрового API используй соответствующий Make*Accessible |
| `HasMember` true, вызов/запись падает | Проверь actual `pcall(function() ... end)`, setter, readonly и receiver | HasMember имеет reflection fallback и не является проверкой прав доступа/успешной конверсии |
| Не найден constructor | Создан static userdata зарегистрированного типа? Конструктор public? Тип abstract/open generic? | Используй `Type(...)`/`Type.__new(...)`; не придумывай обязательный init. Убери неоднозначность параметров |
| Не найдена перегрузка | Сравни число аргументов, Lua-типы, userdata type, nil/default/params | Lua number — double; table-scoring приблизителен. Явный typed array либо метод-фасад с одним контрактом |
| Аргумент не конвертируется | Параметр `object`, `T[]`, `params T[]`, DTO, Table или delegate? | Для DTO создай userdata; для массива передай плотную последовательность DTO; для params оберни массив; для callback проверь конкретный converter |
| nil неожиданно меняет default | Сравни пропуск и явный nil на точной сигнатуре | Reference optional получает null при nil; optional non-nullable value type получает default; обязательный value type не принимает nil |
| Неудобно читать коллекцию | `type(value)`, `LuaUserData.TypeOf(value)` только для ненулевого userdata; Count/Length, индекс 0/1 | Table может быть копией, userdata — живой CLR-коллекцией, IEnumerable — iterator. Выбери регистрацию/обёртку или C# метод преобразования |
| Изменение не сохраняется | Повторно прочти через исходного владельца, а не локальную переменную | Getter вернул struct-копию или коллекция превратилась в table. Нужен writeback/метод владельца; clone-контракт тоже может быть намеренным |
| Callback не вызывается | Точная сигнатура, converter, event совместимость, IsRunning, актуальный OwnerScript | Ошибка может быть залогирована внутри CallFunctionSafe, а вызывающий увидит false/null. Проверяй журнал и прямой минимальный callback |
| Callback остаётся после reload | Кто удерживает Closure: статическое поле, event descriptor, timer, внешняя подписка? Отписка тем же экземпляром функции? | Сними подписку и останови источник до выгрузки; не рассчитывай на GC/UnregisterType как на замену очистки |

**Пример:** минимальная проверка доступности собственного API после успешной C#-загрузки:

```lua
assert(CSActive, "C# disabled")
local descriptor = LuaUserData.RegisterType("BridgeDemo.Line")
local Line = LuaUserData.CreateStatic("BridgeDemo.Line")
assert(Line ~= nil)
local ok, line_or_error = pcall(function() return Line("steel", 2) end)
assert(ok, tostring(line_or_error))
assert(line_or_error.Quantity == 2)
```

Для Method/Field/Property проверяй каждый уровень отдельно. Если доступ закрыт политикой `SafeLuaUserDataService`, изменение имени члена не поможет. Если вызов дошёл до пользовательского C# exception, регистрация уже пройдена — исправляй контракт/данные, а не loader.

При диагностике ошибок не разбирай текст `pcall` как стабильный протокол кодов. Для машинной обработки спроектируй `Result { Success, ErrorCode, ... }`. Не подавляй ошибку «пустым DTO по умолчанию»: это скрывает этап сбоя.
