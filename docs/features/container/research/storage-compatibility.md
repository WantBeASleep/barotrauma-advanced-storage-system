# Хранение предметов: исследование совместимости

Статус: исследование выполняется по [плану](../../../superpowers/plans/2026-11-04-storage-compatibility-research.md). Механизм хранения и окончательный контракт содержимого ещё не выбраны.

## Среда и источники

Дата: 4 ноября 2026 года. Установленный клиент: Barotrauma `1.13.5.0+c6e8829143c98162ed376aee33eb9799602365ac`; checkout LuaCs имеет тот же HEAD. Основные выводы относятся к этой ревизии, а не к vanilla upstream или произвольной версии LuaCs.

Установленный `DedicatedServer.dll`: `1.13.5.0+0a9af9a7f0efeef46d63a4fe80103b4446a21dee`. Серверный код изучается в основном checkout; без отдельного сопоставления это не подтверждает поведение установленного серверного бинарника.

Основание — [утверждённая архитектура](../../../superpowers/specs/2026-11-04-storage-architecture-design.md). Игровые эксперименты и замеры не проводятся. Для выводов используются статусы «подтверждено исходниками», «вывод из исходников» и «не проверено»; статус «проверено в игре» в этом отчёте не используется.

Постоянная база источников: [LuaCs c6e8829](https://github.com/evilfactory/LuaCsForBarotrauma/tree/c6e8829143c98162ed376aee33eb9799602365ac). Исходники исследуются вне репозитория мода. Онлайн-руководства [Networking](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/networking/) и [Hooks](https://evilfactory.github.io/LuaCsForBarotrauma/lua-docs/manual/how-to-use-hooks/) — справочный контекст; конкретное поведение сверяется с checkout.

## Варианты хранения

| Вариант | Что существует в игре | Что требуется сравнить |
| --- | --- | --- |
| Реальные `Item` | Каждый предмет остаётся игровым экземпляром в настоящем инвентаре | Штатные потребители, индивидуальное состояние, цена CPU/памяти/сети, возможность скрыть слотовое меню |
| Записи с пересозданием | Предмет удаляется при помещении; вместо него сохраняются данные; выдача создаёт новый `Item` | Достаточность сериализации, ссылки на прежний экземпляр, интеграция потребителей, корректная выдача и сетевой жизненный цикл |
| Сочетание подходов | Часть предметов или стадий операции использует настоящие `Item`, часть — записи | Чёткая граница допустимых предметов, отсутствие дублирования и потери, измеримая польза относительно первого варианта |

Сравнение охватывает совместимость, сохранность состояния, вложенность, сохранение/идентичность, сетевую доставку и стоимость интеграции. Уменьшение числа `Item` само по себе не доказывает выигрыш производительности в сценарии игрока.

## Конструктор

**Подтверждено исходниками:** `Fabricator` хранит ингредиенты как `Dictionary<Identifier, List<Item>>`, а не количества типов. Основная цепочка находится в [Shared Fabricator.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Items/Components/Machines/Fabricator.cs#L880).

1. `RefreshAvailableIngredients` берёт `AllItems` входного инвентаря и связанных через `item.linkedTo` предметов с `ItemContainer`. Для связанного деконструктора используется выходной контейнер; проверяются необходимые для доступа предметы персонажа.
2. Растущий список обходится до конца: у найденного `ItemContainer` добавляются его реальные предметы, затем их вложенность. В этой цепочке используется первый `GetComponent<ItemContainer>()`, поэтому несколько компонентов хранения у одного предмета не означают автоматическое чтение всех инвентарей.
3. Добавляются предусмотренные игрой инвентари персонажей; ссылки группируются по prefab identifier и сортируются с приоритетом входного инвентаря, затем инвентаря персонажа, затем прочих источников, с дополнительным учётом цены, состояния и слота.
4. `CanBeFabricated` проверяет конкретные экземпляры и их состояние; `HashSet<Item>` не позволяет засчитать один предмет в несколько требований рецепта — [код](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Items/Components/Machines/Fabricator.cs#L750).
5. `StartFabricating` на сервере/в одиночной игре вызывает `MoveIngredientsToInputContainer`: нужные реальные экземпляры перемещаются штатным `TryPutItem`; затем доступный запас обновляется — [старт](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Items/Components/Machines/Fabricator.cs#L206), [перенос](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Items/Components/Machines/Fabricator.cs#L995).
6. Перед `Fabricate` запас и возможность изготовления проверяются заново. Ингредиент может расходоваться снижением `Condition`, а не удалением. Для расходуемого предмета обрабатывается вложенное содержимое, вызываются таланты с `List<Item>`, затем экземпляры ставятся в очередь удаления — [потребление](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Items/Components/Machines/Fabricator.cs#L367).

Клиент самостоятельно обновляет ингредиенты и использует `CanBeFabricated` для доступности кнопки и списка — [Client Fabricator.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/Items/Components/Machines/Fabricator.cs#L1324). Подсветка отдельно читает реальные слоты и вложенные инвентари; её обход не следует считать тождественным сбору ингредиентов. Сервер получает рецепт и количество, проверяет доступ к машине и запускает изготовление — [Server Fabricator.cs](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaServer/ServerSource/Items/Components/Machines/Fabricator.cs#L10).

| Размещение | Что видит штатный конструктор | Статус |
| --- | --- | --- |
| Реальный ингредиент в связанном шкафу | Читает из его `ItemContainer.Inventory` | Подтверждено исходниками, при выполнении проверок доступа и рецепта |
| Реальный ингредиент во вложенном обычном кейсе | Добавляет при рекурсивном расширении списка | Подтверждено исходниками для используемого компонента хранения |
| Реальный ингредиент в контейнере с невидимыми слотами | Сам сбор ингредиентов не зависит от `DrawInventory` | Подтверждено исходниками; полное взаимодействие требует игрового теста |
| Запись мода без созданного ингредиента | Не попадает в `List<Item>` штатного обхода | Вывод из исходников; нужна отдельная интеграция |

**Вывод из исходников:** научить конструктор работать с записями возможно как отдельную интеграцию, но простая подмена количества не подходит. Нужно согласовать клиентскую доступность рецептов, серверный выбор/резервирование, материализацию до штатного потребления, частичный расход состояния, отмену/повтор и таланты. Вариант с материализацией только выбранных ингредиентов оставляет реальные `Item` на стадии исполнения, даже если в покое хранятся записи. Вариант вообще без таких `Item` требует замены соответствующей логики потребителя и его взаимодействий. Ни один вариант здесь не реализован и не проверен в игре.

## Потребители содержимого

Таблица описывает проверенные пути, а не обещает исчерпывающую совместимость всей игры и сторонних модов. Ссылки ведут на места чтения и последующего использования экземпляров.

| Система | Чтение и изменение | Последствие отсутствия Item | Возможная интеграция и ограничения |
| --- | --- | --- | --- |
| Конструктор | Сбор `List<Item>`, перенос, состояние, таланты и удаление | Штатный запас не виден | Интеграция нескольких стадий на клиенте и сервере; см. выше |
| Поиск и получение ботами | `Submarine.GetItems` строится из `Item.ItemList`; цель хранится как `Item`, учитываются `ParentInventory`, доступ и реальные слоты — [AIObjectiveGetItem](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Characters/AI/Objectives/AIObjectiveGetItem.cs#L456), [получение](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Characters/AI/Objectives/AIObjectiveGetItem.cs#L299) | Запись не обнаруживается обычным поиском; удалённая цель не превращается в новую автоматически | Адаптация поиска/резервирования/получения; одного изменения меню игрока недостаточно |
| Деконструктор | Читает входные `Item`, применяет эффекты, обрабатывает содержимое всех `ItemContainer` цели и удаляет её — [Deconstructor](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Items/Components/Machines/Deconstructor.cs#L117), [вложенность](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Items/Components/Machines/Deconstructor.cs#L340) | Скрытые записи внутри уничтожаемого контейнера не проходят этот штатный обход | Передать содержимое через специальную обработку до уничтожения контейнера; отдельно определить исследование генматериалов |
| Эффекты хранения и оборудование | `ItemContainer.Update` применяет эффекты к `activeContainedItems`; `ShouldApplyEffects` читает `Condition`, `AllPropertyObjects`, персонажа-владельца — [ItemContainer](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Items/Components/ItemContainer.cs#L703) | Эффекты над отсутствующим предметом не исполняются штатно | Материализовать предметы либо отдельно согласовать семантику времени/эффектов; считать запись «тем же поведением» нельзя |
| Длительные цели и ссылки | AI хранит `targetItem`, эффекты проверяют `Removed` и удерживают цели; подлодка ищет реальные сущности — [цель AI](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Characters/AI/Objectives/AIObjectiveGetItem.cs#L238), [StatusEffect](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/StatusEffects/StatusEffect.cs#L1646), [Submarine.GetItems](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Map/Submarine.cs#L1510) | Новый объект не восстанавливает автоматически ссылки на старый | Нужна собственная идентичность записей и явно поддержанные переходы у потребителей |
| Меню и подсветка мода | Требования к конкретным экземплярам, состоянию, встроенным слотам и месту хранения | Текущий контракт представления не описывает записи | Пересмотреть [содержимое](../../menu/content.md) и [подсветку](../../menu/highlighting.md) после выбора хранения, не теряя различимость экземпляров |

### Точки интеграции LuaCs

**Подтверждено исходниками:** [DefaultLuaRegistrar](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/DefaultLuaRegistrar.cs#L77) регистрирует разрешённые типы сборок; [SafeLuaUserDataService](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/SafeLuaUserDataService.cs#L74) допускает рассматриваемые игровые типы. Доступ к закрытым членам требует явного открытия; [LuaPatcherService](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/_Lua/LuaPatcherService.cs#L295) разрешает поиск непубличных методов, prefix/postfix и замену результата. Рассмотренные `Fabricator` и `Inventory` не входят в запрет патчей окружения LuaCs.

Это подтверждает наличие механизма для исследования Lua-интеграции; не подтверждает готовность патча конкретной цепочки. Работа с generic-коллекциями, перегрузками и частотой вызовов требует отдельной проверки, прежде чем выбирать небольшой C#-исполнитель ради недоступности или производительности. Необходимость переносить в C# логику хранилища не установлена.

Существуют события `item.deconstructed`, `item.removed` и `inventoryPutItem`. Последний — prefix к низкоуровневому `Inventory.PutItem`, где возврат `true` пропускает оригинал — [HarmonyEventPatchesService](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/LuaCs/_Services/HarmonyEventPatchesService.cs#L349). Сам по себе этот void-hook не гарантирует корректный результат внешнего `TryPutItem`, сохранность источника и покрытие всех путей; окончательная интеграция фильтров оставлена отдельной работе.

### Невидимые слоты и физическое хранение

**Подтверждено исходниками:** `DrawInventory=false` предназначен для скрытия инвентаря при выборе предмета и не запрещает drag-and-drop — [свойство](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaShared/SharedSource/Items/Components/ItemContainer.cs#L114). Клиент проверяет его в HUD, открытии вложенного инвентаря и обработке наведения — [HUD](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/Items/Components/ItemContainer.cs#L617), [Inventory](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/Items/Inventory.cs#L744).

**Вывод из исходников:** отсутствие слотового меню не требует удаления `Item`. Вариант с невидимым настоящим инвентарём пригоден как база совместимости для сравнения. Он сохраняет внутренние ограничения слотов/стаков; иной учёт вместимости не появляется от одного флага. Произвольная вместимость без штатных ограничений этим не доказана.
