# Версии и результаты проверок

Дата исследования: **2026-10-30**. Все статусы относятся к этому снимку; tag `latest` изменяемый, поэтому исходники цитируются по commit.

## Установленные и актуальные сборки

| Источник | Версия / commit | Что установлено |
| --- | --- | --- |
| Workshop `2559634234/filelist.xml` | modversion 1.0.117, gameversion 1.13.5.0 | Метаданные установленного пакета |
| Workshop `Binary/Barotrauma.dll`, `DedicatedServer.dll` | `1.13.5.0+c6e8829143c98162ed376aee33eb9799602365ac` | ProductVersion обеих сборок совпадает с исследованными исходниками |
| Workshop `Binary/MoonSharp.Interpreter.dll` | `2.0.0+b556e550eb20b950a7db3ef69006104af3f654da` | Точный commit форка совпадает с submodule платформы |
| Официальный master и tag latest | `c6e8829143c98162ed376aee33eb9799602365ac` | `git ls-remote`; release published 2026-10-27T11:15:01Z. Workshop совпадает по commit с актуальным на дату проверки |
| Папка игры: Barotrauma.dll, DedicatedServer.dll | `1.13.5.0+0a9af9a7f0efeef46d63a4fe80103b4446a21dee` | Другая сборка. В клиентской DLL через reflection не найден новый `Barotrauma.LuaCs.LuaUserDataService`; точная исходная ревизия не получена |
| Папка игры: MoonSharp.Interpreter.dll | `2.0.0+b556e550eb20b950a7db3ef69006104af3f654da` | Commit тот же, но SHA256 отличается от workshop: нельзя считать бинарники тождественными |

Полные абсолютные пути, версии и SHA256: [binaries.json](../../../../docs/features/luacs-interop/binaries.json). Папка игры не изменялась; успешное исполнение примеров относится к **workshop DLL**, а не к фактически запущенному игровому клиенту. Версия `2.0.0` сама по себе не отличает форк от upstream MoonSharp.

Официальные источники: [LuaCs commit](https://github.com/evilfactory/LuaCsForBarotrauma/commit/c6e8829143c98162ed376aee33eb9799602365ac), [MoonSharp commit](https://github.com/evilfactory/moonsharp/commit/b556e550eb20b950a7db3ef69006104af3f654da), [release](https://github.com/evilfactory/LuaCsForBarotrauma/releases/tag/latest). Локальный checkout вне мода: `C:/Users/limanchel/.cache/luacs-bridge-research/platform`.

## Исполнено — E

Host: Windows, PowerShell 7.6.5 / .NET 10, C# компилируется Roslyn Add-Type; библиотеки игры целятся в .NET 8. При компиляции подавлено только предупреждение CS1701 о runtime version unification. Успех в таком host не доказывает работу всей игры на .NET 10.

Используются настоящие workshop `MoonSharp.Interpreter.dll`, `Barotrauma.dll`, `BarotraumaCore.dll`, `FluentResults.dll`. `LuaUserDataService` настоящий, не переписанный stub. Через DispatchProxy заменён только поиск типа в IPluginManagementService: локально скомпилированная сборка не загружалась игровым package loader. C# plugin компилируется против настоящего IAssemblyPlugin, но методы жизненного цикла loader не запускает. Host не включает все default registrations и LuaCs custom converters.

Связанный demo: собственные конструкторы и свойства; вложенный Address; table → Line[]; обработка Request и возврат Result; синхронный C# → Lua → C# callback с числовым результатом; event add/publish/remove и Dispose. Результат: **`BridgeDemo PASS: total=5, callback=6, event=5`**.

Дополнительные 20 проверок в [probes.lua](../examples/probes/probes.lua):

1. Оба способа вызова конструктора, поля, static, наследование, interface-аргумент; отсутствие автоматических `init/new`.
2. Запрет записи readonly field, get-only property, private setter.
3. struct-копия при getter и передаче by-value; явная запись обратно.
4. optional/nil/Nullable и ошибка обязательного int=nil.
5. int/double overload, округление 2.5/3.5, отсутствие общего string → int.
6. params, ref/out tuple; отказ от автоматического разворачивания table в params.
7. table → List/Dictionary; table → object остаётся Table; отсутствие автоматического DTO mapping.
8. Незарегистрированный List → table snapshot; изменение таблицы не меняет тот же C# List.
9. Регистрация List → userdata, 0-based index, Add, Count, IEnumerable-перебор.
10. Реальный `CreateUserDataFromType` для массива и передача его в params.
11. Незарегистрированный/зарегистрированный enum.
12. Generic method с явным Type и проверкой constraints.
13. Автоматический Closure против неподдержанного без converter произвольного Func<int,int>.
14. Синхронное распространение Lua callback error.
15. Ограничение EventFacade для Action<int>.
16. Настоящие MakeFieldAccessible/MakeMethodAccessible/MakePropertyAccessible, чтение/запись закрытых членов.
17. C# exception → строка ошибки pcall.
18. Сохранение ссылки class-элемента при копировании table-контейнера в массив.
19. Ошибка generic Echo<int>(Lua number): отсутствует повторная конверсия double → int после закрытия метода.
20. Явный Table-адаптер отвергает дробное количество до integer-конверсии.

Команда и требования: [examples/README.md](../examples/README.md). Необработанный успешный вывод: [runtime-output.txt](../../../../docs/features/luacs-interop/runtime-output.txt). Проверки запускались в новых процессах; registry не переносился между запусками.

## Статически проверено — S

Загрузка/активация plugin перед Lua autorun; Target и ModConfig; safe/full LuaUserData; enum и коллекционные ветки; generic descriptors; binder и cache; специфические LuaCs converters (включая ulong, Option, GUI); hook/patch dispatch; stop/reload/unregister; способ удержания callbacks. [Реестр файлов и символов](sources.md).

## Не исполнялось — U

- Установка demo в LocalMods, игровой client/server startup, разрешение C#, package discovery/compile в игре, GUI callbacks.
- Смена раунда, остановка/перезагрузка LuaCs, unload AssemblyLoadContext, многопоточность, гонки и длительные подписки.
- Сетевой обмен и сериализация чужих модов; отрисовка Medical Icons; игровое поведение перезарядки/реакторов.
- Все комбинации generic instance/extension/optional/params/ref/out, composite interfaces, AOT и другие версии платформы.
- Производительность и потребление памяти. Проверены результаты, не benchmark.

Отсутствие игрового прогона не скрыто под формулировкой «проверено runtime»: фактически исполнены чистые DTO и изолированный сервис моста.

## Проверка skill

Штатный `skill-creator/scripts/quick_validate.py` завершился **`Skill is valid!`**. Для него PyYAML 6.0.3 установлен только в исследовательский кеш `C:/Users/limanchel/.cache/luacs-bridge-research/python-libs`; глобальная Python-среда проекта не менялась. Валидатор проверяет структуру/frontmatter, а не корректность API; для последней служат S/E материалы выше.
