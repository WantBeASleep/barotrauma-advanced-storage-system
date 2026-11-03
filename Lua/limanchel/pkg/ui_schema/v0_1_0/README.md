# ui_schema 0.1.0

Создание штатного UI Barotrauma из строки JSON. Библиотека находится в разработке. В Barotrauma 1.13.5.0 / LuaCs 1.0.117 проверены пять тестовых меню и создание/очистка 22 встроенных типов; подробности и оставшиеся проверки — в `manual_test/README.md`. Источник исходников — этот репозиторий, `Lua/limanchel/pkg/ui_schema/v0_1_0/`.

Зависимости: Lua 5.2 через LuaCs/MoonSharp, клиентский GUI для построения, `limanchel.pkg.goerrors.v0_1_0.goerrors`. Разбор JSON не требует игры. Файлы читает вызывающий код.

Внутренний декодер — Lunajson 1.2.3, ревизия `250afac121df831f449d6370ddf406673f6f9c2b`, оригинальный `src/lunajson/decoder.lua`. Поставляется без изменения, SHA-256 `5257c567492e7c0203ae1a463313fce6b8d082db093a4aa841ccec8dec164546`, лицензия — `vendor/LICENSE`. SAX-парсер, кодировщик и файловый API не поставляются.

Карта игровых типов и состояние проверок — [COMPONENTS.md](COMPONENTS.md).

Создание `CreditsPlayer` пока исключено по согласованию с пользователем: у штатного проигрывателя титров нет публичного способа снять скрытую подписку на смену разрешения. C#-помощник в пакет не входит.


## Минимальный пример

**Пример:** вызывающий код читает файл, библиотека разбирает JSON и создаёт меню. Родитель — существующий `RectTransform` интерфейса клиента.

```json
{
  "schema_version": 1,
  "components": {
    "menu": {
      "type": "Frame",
      "rect": {"size": {"$type": "Point", "value": [400, 180]}},
      "children": [
        {
          "type": "LayoutGroup",
          "rect": {"size": {"$type": "Vector2", "value": [1, 1]}},
          "children": [
            {
              "type": "TextBlock", "id": "status",
              "rect": {"size": {"$type": "Point", "value": [380, 40]}},
              "constructor": {"text": "Готово"}
            },
            {
              "type": "Button", "id": "apply",
              "rect": {"size": {"$type": "Point", "value": [380, 40]}},
              "constructor": {"text": "Нажать"}
            }
          ]
        }
      ]
    }
  }
}
```

```lua
local ui_schema = require("limanchel.pkg.ui_schema.v0_1_0.ui_schema")
local builder = ui_schema.new()
local document, err = builder:parse(File.Read(mod_path .. "/menu.json"))
if err then
   error(err:error())
end
local view, build_err = builder:build(document, "menu", parent)
if build_err then
   error(build_err:error())
end
view:get("apply").OnClicked = function()
   view:get("status").Text = "Кнопка нажата"
   return true
end
-- При закрытии вызывающий код проверяет результат очистки.
local ok, dispose_err = view:dispose()
if not ok then
   error(dispose_err:error())
end
```

Обновление и рисование родителя обеспечивает вызывающий код обычным способом Barotrauma. Пакет не подключает обработчики игры и не открывает окна при `require` или `new`.

## Формат схемы

Один документ содержит несколько независимых заготовок в `components`. Внутри заготовки — дерево: элемент и его `children`. Меню и динамическая строка списка могут жить в одном файле как две заготовки. `schema_version` обязателен и равен `1`.

| Поле элемента | Назначение |
| --- | --- |
| `type` | Имя зарегистрированного типа, например `Frame` или `Button` |
| `id` | Необязательное имя для доступа через `view:get`; уникально внутри одного построения |
| `rect` | Размер, положение и параметры штатного `RectTransform` |
| `constructor` | Именованные аргументы создания; регистр имён совпадает с картой типов |
| `props` | Свойства и обработчики готового объекта |
| `children` | Массив дочерних элементов в порядке создания |
| `attach_to` | Область родительского компонента, куда вставить этот элемент; обычно не нужна |

`rect.size` задаётся как `Point` (пиксели) или `Vector2` (доли родителя). Дополнительно доступны `anchor`, `pivot`, `scale_basis` и `props`. Первые три — штатные перечисления `Anchor`, `Pivot`, `ScaleBasis`. Нативная вёрстка остаётся нативной: расположение детей группы регулируют свойства `LayoutGroup`, прокрутку — `ListBox`.

`props` бывает объектом или массивом. У объекта свойства назначаются по алфавиту. Массив вида `[{"member":"Text","value":"Готово"}]` задаёт точный порядок. Путь `TextBlock.TextColor` обращается к вложенному члену. Значимые структуры записываются обратно владельцу. Нельзя менять `Parent` или заменять `RectTransform`: это нарушило бы владение деревом.

У обычного элемента дети попадают в его `RectTransform`; у `ListBox` — в `Content`, у `DropDown` — в содержимое выпадающего списка. Дополнительные области и особые способы создания перечислены в [карте](COMPONENTS.md). Тип с режимом `none` не принимает `rect`; режим `parent` передаёт родителя конструктору, который сам создаёт свой прямоугольник.

## Значения в JSON

Числа, строки, логические значения, объекты и массивы передаются как Lua-значения. `false` сохраняется. JSON `null` запрещён; явный `nil` записывается специальным маркером. `{}` и `[]` различаются при проверке схемы.

| Запись | Что получит игровой объект |
| --- | --- |
| `{"$type":"Point","value":[400,180]}` | Игровой размер в пикселях |
| `{"$type":"Vector2","value":[1,0.5]}` | Игровой вектор |
| `{"$type":"Color","value":[255,80,0,255]}` | Цвет в каналах 0–255; альфа необязательна и равна 255 |
| `{"$enum":"Anchor","value":"Center"}` | Значение штатного перечисления |
| `{"$resource":"icon"}` | Готовый объект `context.resources.icon` |
| `{"$ref":"title"}` | Объект с `id = title` из этого построения |
| `{"$ref":"title","member":"RectTransform"}` | Член указанного объекта |
| `{"$nil":true}` | Явный Lua `nil` |

Встроенные значения: `Point`, `Vector2`, `Vector3`, `Vector4`, `Rectangle`, `Color`, `Identifier`; для `Identifier` значение — строка, для остальных — массив координат/каналов. Перечисления: `Anchor`, `Pivot`, `Alignment`, `ScaleBasis`, `NumberType`, `ButtonVisibility`, `ScalingMode`, `MessageBoxType`, `SoundType`, `CursorState`.

Ресурсы — заимствованные объекты и функции. Например, `Sprite`, шрифт или обработчик передаются из Lua через четвёртый аргумент `build`: `{ resources = { icon = sprite, click = callback } }`. Пакет не загружает и не освобождает эти ресурсы. Функции не записываются строками в JSON и не исполняются как код.

Ссылки в `constructor` могут вести лишь к уже созданным элементам. Ссылки в `props` могут вести вперёд: свойства назначаются после создания всего дерева. `rect.props` назначаются до построения детей; им также нужны уже созданные объекты.

## API и время жизни

- `ui_schema.new()` создаёт независимый builder с собственным реестром типов.
- `builder:parse(json_text)` возвращает документ или `nil, err`. Документ предназначен только для передачи в `build`; не изменяйте его внутренности.
- `builder:build(document, name, parent, context?)` возвращает новое представление или `nil, err`. Нужен клиент игры. Одну заготовку можно строить многократно.
- `view.root` — корневой игровой объект; `view.by_id` — индекс игровых объектов; `view:get(id)` — доступ с проверкой имени.
- `view:dispose()` возвращает `true` либо `nil, err`; повторный вызов допустим. Неудавшуюся очистку можно повторить. После начала очистки представление больше не предоставляет GUI через `root`/`by_id`/`get`.
- `builder:register_type(name, descriptor)`, `register_value_type(name, converter)`, `register_enum(name, values)` расширяют только этот builder. Занятое имя повторно не регистрируется.

Ошибки схемы, преобразования или игрового создания возвращаются как `goerrors.Error`; текст доступен через `err:error()`. Некорректный вызов API (например, вместо строки передана таблица) вызывает Lua-ошибку. При неудачном построении уже созданные объекты очищаются в обратном порядке; ошибки очистки входят в итоговую ошибку.

Представление владеет созданными им объектами. Не переставляйте их к другим родителям в обход библиотеки. Отдельно построенная строка имеет отдельное представление и собственный набор `id`; закройте её до закрытия меню-контейнера.

**Пример:** заготовка `item_row` описывается рядом с `menu`, но создаётся по мере появления данных.

```lua
local row, err = builder:build(document, "item_row", menu:get("items").Content.RectTransform)
if err then
   error(err:error())
end
row:get("name").Text = "Гаечный ключ"
-- Удаление строки:
local ok, dispose_err = row:dispose()
if not ok then
   error(dispose_err:error())
end
```

## Дополнительные типы

Описание типа определяет проверку конструктора, создание, область детей и очистку. Оно получает исходные игровые объекты. Сложные аргументы и новые классы могут передаваться ресурсами или регистрироваться собственным описанием; универсальность не требует хранить игровые функции внутри JSON.

**Пример:** дополнительный тип обычной панели. Он использует публичный контракт описания, не внутренние модули пакета.

```lua
local descriptor = { rect_mode = "new", slots = { default = true } }
function descriptor.validate(constructor, path)
   return true
end
function descriptor.destroy(object)
   object.RemoveFromGUIUpdateList(true)
   object.Visible = false
   object.RectTransform.Parent = nil
   return true
end
function descriptor.create(params, rect, context)
   local object = GUI.Frame(rect)
   context.defer_cleanup(function()
      return descriptor.destroy(object)
   end)
   return object
end
function descriptor.child_parent(object, slot)
   return object.RectTransform
end
builder:register_type("DemoPanel", descriptor)
```

`params.values` содержит преобразованные аргументы `constructor`, `params.present` — признаки их присутствия, `params.variant` — выбранный вариант. Это позволяет отличить отсутствие аргумента от явного `$nil`. `context.defer_cleanup(callback)` регистрирует откат ещё до завершения фабрики; после успеха его заменяет вызов `destroy`.

`rect_mode` равен `new`, `parent` или `none`. `slots` перечисляет допустимые области детей; `child_parent` возвращает `RectTransform` выбранной области. `validate`, `create`, `child_parent`, `destroy` могут вернуть `nil, err`. Фабрика отвечает за освобождение собственных побочных эффектов, включая подписки и глобальные регистрации.

`register_value_type(name, converter)` добавляет обработчик `$type`; его аргументы — исходное `value` и контекст преобразования. Результат — преобразованное значение или `nil, err`. `register_enum(name, values)` добавляет таблицу значений для `$enum`. Подробный исполняемый пример дополнительного GUI-типа и ресурсов — [manual_test](manual_test/README.md).

## Проверки и изменения версии

Начальная версия содержит JSON-документы, сборку деревьев, доступ по `id`, преобразование значений, расширение типов, откат и очистку. Старый `archive/ui_runtime` не является зависимостью и не задаёт контракт. В игровую точку входа основного мода пакет не подключён.

Автоматические тесты выполняются общим Busted-набором проекта. [Пять проверочных меню](manual_test/README.md) предназначены для проверки в клиенте: кнопка, основные поля ввода, динамические строки, ресурсы и откат ошибки. Успех unit-тестов не подтверждает визуальный прогон или поддержку непроверенной версии игры.
