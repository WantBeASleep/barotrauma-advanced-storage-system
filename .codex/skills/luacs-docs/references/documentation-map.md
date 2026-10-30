# Карта документации LuaCsForBarotrauma

Ссылки проверены 29 октября 2026 года. Карта охватывает ветки документации платформы; перечень тем и сущностей не исчерпывающий. Для любой другой темы используй индексы и общий поиск из SKILL.md. Доступность страницы не подтверждает её соответствие установленной версии.

## Выбор ветки

| Вопрос | Начало маршрута |
| --- | --- |
| Где искать документацию платформы | [Общий вход](https://evilfactory.github.io/LuaCsForBarotrauma/): ссылки на Lua и C#; при пустом текстовом представлении открывай ветки напрямую |
| Lua-скрипты, доступный из Lua API, хуки | [Lua Manual и Code](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/) |
| C#-мод, компиляция, сборка, плагины, Harmony | [C# Introduction и Development](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/html/index.html) |
| Класс или механизм клиента | [Client API](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-client/html/classes.html) |
| Класс или механизм сервера | [Server API](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-server/html/classes.html) |
| Общий код, различия сторон | Сопоставь тип и нужный член в обоих C#-индексах; флаги Lua разбирай по руководству Networking |
| Lua ↔ C# | LuaUserData и FAQ Lua, затем C#-тип нужной стороны; при пробеле — код регистрации и преобразования в платформе |
| Установка, включение C#, зависимости, версия | Руководство установки, C# Introduction, RunConfig; [релизы](https://github.com/evilfactory/LuaCsForBarotrauma/releases) и [теги](https://github.com/evilfactory/LuaCsForBarotrauma/tags) для соответствующей версии |
| Ошибка, неизвестная настройка или тема без отдельного руководства | Точное имя/текст ошибки → индексы обеих веток → документация и исходники [репозитория](https://github.com/evilfactory/LuaCsForBarotrauma) |

## Руководства Lua и установка

| Задача | Страница | Что выяснить |
| --- | --- | --- |
| Запуск скриптов и окружение Lua | [Getting started](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/getting-started/) | Порядок запуска, Autorun, передаваемые пути, загрузка файлов и доступ к C# |
| События и перехват методов | [How to use hooks](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/how-to-use-hooks/) | Различие событий и патчей, регистрация обработчиков; затем точный контракт в Hook |
| Стороны выполнения и обмен данными | [Networking](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/networking/) | CLIENT/SERVER, одиночная игра, синхронизация свойств и собственные сообщения |
| Ошибки доступа к userdata и обход коллекций | [Common Questions](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/common-questions/) | Статические и экземплярные члены, отсутствующие поля, перечислители |
| Пример использования механизма | [Lua Examples](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/lua-examples/) | Контекст применения; сигнатуры дополнительно сверять со справочником |
| Установка платформы | [Installing LuaCs manually](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/installing-lua-for-barotrauma-manually/) | Читать при настройке или диагностике установки |

## C#: подключение, загрузка и конфигурация

| Задача | Страница | Что выяснить |
| --- | --- | --- |
| Включить поддержку C# | [Introduction / Enabling](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/html/index.html) | Настройки платформы, включение C# и контекст сессии. Имена настроек сверять с целевой версией |
| Подключить C#-исходники | [In-memory CSharp Mod](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/html/md_manual_inmemorymod.html) | Компиляция исходников, Client/Server/Shared, точка входа и жизненный цикл плагина |
| Подключить готовую сборку, настроить сборку/отладку | [Assembly CSharp Mod](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/html/md_manual_assemblymod.html) | DLL, reference assemblies, проекты по сторонам/ОС, размещение результата, debug-сборка платформы. SDK из примера сверять с целевой версией |
| Изменить поведение C#-метода патчем | [Using Harmony](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/html/md_manual_harmony.html) | Переход к официальной документации Harmony из руководства платформы; затем сигнатура целевого метода нужной стороны |
| Настроить запуск C# по сторонам и зависимости | [RunConfig](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-client/html/class_run_config.html) | Client, Server, Dependencies, настройки сборки; форматы и допустимые значения уточнять по исходнику RunConfig и загрузчику |
| Разобрать этапы плагина | [IAssemblyPlugin](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-client/html/interface_i_assembly_plugin.html) | Инициализация, завершение загрузки, патчи до запуска контента; сверить интерфейс и пример для используемой версии |
| Разобрать загрузку, выгрузку и разрешение сборок | [AssemblyManager](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-client/html/class_assembly_manager.html) | Контексты загрузки, зависимости, события, ошибки и освобождение сборок |
| Настройки и инициализация платформы | [LuaCsSetupConfig](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-client/html/class_barotrauma_1_1_lua_cs_setup_config.html), [LuaCsSetup](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-client/html/class_barotrauma_1_1_lua_cs_setup.html) | Где читается настройка, как она влияет на запуск, какие условия относятся к стороне выполнения |

Прямые ссылки на классы в этой таблице ведут в клиентский справочник. Для серверного поведения найди тот же тип в серверном индексе и прочитай его реализацию; одинаковое имя не доказывает одинаковую доступность членов.

При вопросе о конкретном конфигурационном файле ищи и имя файла, и его ключи. Если в проекте встречаются `ModConfig.xml`, `Assembly`, `Target` или другая схема, не приписывай ей поведение из похожего руководства: найди её описание либо фактический разбор в исходниках соответствующей версии. README проекта — свидетельство локальной настройки, а не доказательство контракта платформы.

## Индексы C# для произвольной сущности

| Что известно | Клиент | Сервер | Как продолжить |
| --- | --- | --- | --- |
| Имя типа | [Class Index](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-client/html/classes.html) | [Class Index](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-server/html/classes.html) | Выбери тип с нужным полным именем, затем член и перегрузку |
| Пространство имён | [Packages](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-client/html/namespaces.html) | [Packages](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-server/html/namespaces.html) | Открой namespace, его типы, функции и перечисления |
| Имя метода, поля, свойства или события | [Class Members](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-client/html/functions.html) | [Class Members](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-server/html/functions.html) | Следуй буквенным страницам и фильтрам Functions/Variables/Properties/Events/Enumerations; первая страница не содержит весь алфавит |
| Базовый тип или семейство компонентов | [Hierarchy](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-client/html/hierarchy.html) | [Hierarchy](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/baro-server/html/hierarchy.html) | Найди наследника и унаследованные члены; проверь List of all members на странице типа |

Для C# доступны страницы исходников: переходи по `Definition at line ... of file ...` со страницы типа/члена. Не угадывай закодированное Doxygen-имя файла или якорь. Если меню не отобразилось, прочитай ссылки из HTML и подключённой навигации. [Навигация C#-руководства](https://evilfactory.github.io/LuaCsForBarotrauma/cs-docs/html/navtreedata.js) также указывает на Generated Documentation обеих сторон; это данные для извлечения ссылок, запускать JavaScript не требуется.

## Основные игровые сущности и API Lua

| Область | Сущности и ссылки | Как различать и что искать |
| --- | --- | --- |
| Предметы | [Item](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/item/), [ItemPrefab](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/itemprefab/) | Item — конкретный предмет; ItemPrefab — определение его типа. Ищи состояние экземпляра отдельно от данных prefab |
| Инвентари | [Inventory](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/inventory/) | Владелец, слоты, содержимое и операции размещения. От Item переходи к OwnInventory/ParentInventory и нужной перегрузке метода |
| Компоненты предмета | Начни с [Item](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/item/) | ItemComponent и конкретные компоненты, например ItemContainer, определяют отдельные возможности предмета. Ищи способ получения компонента и его точный тип; если Lua-страницы нет, найди тип в C#-индексе нужной стороны, затем проверь его доступность из Lua |
| Персонаж и здоровье | [Character](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/character/), [CharacterHealth](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/characterhealth/) | Персонаж, его инвентарь и управление; здоровье и применение состояний — связанная, но отдельная область |
| Состояния персонажа | [Affliction](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/affliction/), [AfflictionPrefab](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/afflictionprefab/) | Конкретное состояние и определение его типа; проверяй силу, цели применения и связанные типы |
| Мир | [Entity](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/entity/), [Submarine](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/submarine/), [Hull](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/hull/), [Level](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/level/) | Объект мира, подлодка, отсек и уровень; проверяй принадлежность, координаты и время жизни |
| Хуки | [Hook](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/hook/) | Методы регистрации/снятия/патчей и каталог событий, включая roundStart, roundEnd, item.created. Для каждого события свой контракт |
| Отложенные вызовы | [Timer](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/timer/) | Единицы времени, момент выполнения обработчика и доступность захваченного объекта к этому моменту |
| Сеть | [Networking](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/networking/), [IReadMessage](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/ireadmessage/), [IWriteMessage](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/iwritemessage/) | Создание, отправка и приём сообщения; типы и порядок чтения/записи, получатель и сторона вызова |
| Контекст игры и подключения | [Game](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/game/), [Client](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/client/) | Режим игры и состояние сессии; Client как объект подключения не путать с флагом CLIENT |
| Интерфейс | [GUI](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/gui/), [GUI.Component](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/gui.component/), [GUI.RectTransform](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/gui.recttransform/) | UI-компоненты и размещение; конкретные элементы ищи в индексе GUI.*, проверяй клиентскую доступность |
| Lua и CLR | [LuaUserData](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/code/luauserdata/) | Регистрация типов, статические ссылки, доступ к членам. Для преобразования значения ищи точный метод и поддерживаемый тип |

Перечисления ищи по точному имени типа из параметра метода в [общем индексе](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/). Не подбирай числовые значения enum по памяти.

## Поиск конкретного контракта

1. Найди тему в руководстве, тип в соответствующем индексе или имя члена через поиск. Начни с `site:evilfactory.github.io/LuaCsForBarotrauma/ <тема>`; сузь область до `lua-docs/`, `cs-docs/html/`, `cs-docs/baro-client/` или `cs-docs/baro-server/`, когда ветка понятна.
2. Открой найденную страницу, а не ограничивайся поисковым сниппетом. Lua-страницы содержат большое общее оглавление: ищи заголовок сущности в основном тексте, затем нужный член в Functions/Fields. Для C# пользуйся таблицами членов, наследованием и детальным описанием.
3. Прочитай параметры, результат, замечания и подходящие перегрузки. Посмотри определения неизвестных типов аргументов и результата.
4. Если описание повторяет только имя метода, перейди по `Barotrauma source code` в Lua-справочнике или `Definition ... of file` в C#-справочнике. Проверь версию исходников и объявление/реализацию метода.
5. Если остаётся вопрос о доступности из Lua, ищи регистрацию и экспорт в [репозитории LuaCsForBarotrauma](https://github.com/evilfactory/LuaCsForBarotrauma), а не только C#-объявление.

Для локального поиска сначала найди файлы: `rg --files <каталог-исходников>`, затем символы: `rg -n 'TryPutItem|inventoryPutItem' <каталог-исходников>`. Для событий ищи и место вызова хука: оно помогает установить момент срабатывания и использование возвращаемого значения. Для доступности типов ищи имя типа, `LuaSetup`, `RegisterType` и `CreateStatic` в установленной или соответствующей версии платформы.

Для загрузки и конфигурации ищи `RunConfig`, `IAssemblyPlugin`, `AssemblyManager`, `LuaCsSetup` и конкретные XML-ключи. Для неизвестной темы ищи по всему репозиторию: в README, каталогах документации и changelog, затем в реализации. Не ограничивай поиск только перечисленными здесь классами. Если руководство ведёт к внешней документации зависимости, например Harmony, переходи к ней для соответствующего вопроса.

Lua-аннотации выбранной стороны используй для навигации и типов; путь к ним бери из настроек рабочего проекта. Существующие моды помогают найти пример, но не заменяют документацию и исходники платформы.

## Примеры маршрутов

**Пример:** «подключить C# на клиенте и сервере» → C# Introduction → In-memory CSharp Mod либо Assembly CSharp Mod по способу поставки → RunConfig → IAssemblyPlugin → индексы API обеих сторон. Сопоставь включение C#, отбор файлов для сторон и жизненный цикл. При расхождении с конфигурацией проекта проверь загрузчик нужной версии до изменения файлов.

**Пример:** «найти настройку, которой нет в этой карте» → имя файла/ключа → поиск по всей документации → конфигурационный тип и его исходник → чтение ключа загрузчиком. Если описание отсутствует, сообщи найденное поведение по реализации и её версии.

**Пример:** для перемещения предмета найди Inventory.TryPutItem, различи перегрузки, выясни смысл результата и сетевых параметров. Затем проверь, как получается нужный Inventory и нужен ли связанный inventoryPutItem-хук. Не копируй вызов с набором булевых аргументов, пока их смысл не установлен.

**Пример:** для обработчика события сначала прочитай руководство по хукам, затем запись конкретного события на странице Hook. Сверь имя события, аргументы и влияние return; не переноси имя и сигнатуру обработчика из примера другого события.
