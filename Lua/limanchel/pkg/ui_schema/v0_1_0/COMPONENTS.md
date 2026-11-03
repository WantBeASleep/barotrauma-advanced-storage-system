# Карта игровых типов UI

Целевая ревизия: `c6e8829143c98162ed376aee33eb9799602365ac`, Barotrauma `1.13.5.0`. Сигнатуры ниже прочитаны в исходниках (S). В клиенте LuaCs 1.0.117 выполнено создание и очистка 22 типов ниже, кроме CreditsPlayer; проверен основной вариант каждого типа, а не все перегрузки. ContextMenuOption проверен как значение.

Режим `new` создаёт описанный `rect`, `parent` передаёт существующего родителя, `none` использует собственный способ размещения типа. Для обычного компонента очистка означает снятие его дерева с обновления и отсоединение; дополнительные действия указаны отдельно.

| Имя | Режим и область детей | Дополнительная очистка |
| --- | --- | --- |
| [Frame](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIFrame.cs) | `new`, `RectTransform` | Обычная очистка |
| [LayoutGroup](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUILayoutGroup.cs) | `new`, `RectTransform` | Обычная очистка |
| [TextBlock](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUITextBlock.cs) | `new`, `RectTransform` | Обычная очистка |
| [Button](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIButton.cs) | `new`, `RectTransform` | Обычная очистка |
| [TextBox](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUITextBox.cs) | `new`, `RectTransform` | Обычная очистка |
| [NumberInput](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUINumberInput.cs) | `new`, `RectTransform` | Обычная очистка |
| [TickBox](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUITickBox.cs) | `new`, `RectTransform` | Обычная очистка |
| [Image](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIImage.cs) | `new`, `RectTransform` | Обычная очистка |
| [ListBox](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIListBox.cs) | `new`, `Content.RectTransform` | Обычная очистка |
| [DropDown](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIDropDown.cs) | `new`, `ListBox.Content.RectTransform`; дополнительные области по имени | Обычная очистка |
| [ScrollBar](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIScrollBar.cs) | `new`, `RectTransform` | Обычная очистка |
| [ProgressBar](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIProgressBar.cs) | `new`, `RectTransform` | Обычная очистка |
| [ColorPicker](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIColorPicker.cs) | `new`, `RectTransform` | `Dispose()` освобождает собственные текстуры |
| [CustomComponent](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUICustomComponent.cs) | `new`, `RectTransform` | Обычная очистка |
| [ScissorComponent](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIScissorComponent.cs) | `new`, `RectTransform` | Обычная очистка |
| [DragHandle](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIDragHandle.cs) | `new`, `RectTransform` | Обычная очистка |
| [MessageBox](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIMessageBox.cs) | `none`, `Content.RectTransform`; `inner` — `InnerFrame.RectTransform` | Удалить только свой объект из `GUI.MessageBox.MessageBoxes`, без ожидания анимации `Close` |
| [ContextMenu](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/GUIContextMenu.cs) | `none`, `RectTransform` | Обнулить `CurrentContextMenu` только если он равен этому объекту; не активировать конструктором чужое меню |
| [VideoPlayer](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/VideoPlayer.cs) | `none`, Нет | `Remove()` останавливает собственное видео |
| [Graph](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/GUI/Graph.cs) | `none`, Нет | Только управляемая память; не панель |
| [SerializableEntityEditor](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/Serialization/SerializableEntityEditor.cs) | `parent`, `RectTransform` | Обычная очистка |
| [SlideshowPlayer](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/Screens/SlideshowPlayer.cs) | `new`, `RectTransform` | Обычная очистка |
| [CreditsPlayer](https://github.com/evilfactory/LuaCsForBarotrauma/blob/c6e8829143c98162ed376aee33eb9799602365ac/Barotrauma/BarotraumaClient/ClientSource/Screens/CreditsPlayer.cs) | Исключён из текущей версии | По решению пользователя создание пока не поддерживается; C#-помощник не добавляется |

## Варианты создания

### Frame

- `public GUIFrame(RectTransform rectT, string style = "", Color? color = null)`.

### LayoutGroup

- `public GUILayoutGroup(RectTransform rectT, bool isHorizontal = false, Anchor childAnchor = Anchor.TopLeft)`.

### TextBlock

- `public GUITextBlock(RectTransform rectT, RichString text, Color? textColor = null, GUIFont font = null, Alignment textAlignment = Alignment.Left, bool wrap = false, string style = "", Color? color = null)`.

### Button

- `public GUIButton(RectTransform rectT, Alignment textAlignment = Alignment.Center, string style = "", Color? color = null)`.
- `public GUIButton(RectTransform rectT, LocalizedString text, Alignment textAlignment = Alignment.Center, string style = "", Color? color = null)`.

### TextBox

- `public GUITextBox(RectTransform rectT, string text = "", Color? textColor = null, GUIFont font = null, Alignment textAlignment = Alignment.Left, bool wrap = false, string style = "", Color? color = null, bool createClearButton = false, bool createPenIcon = true)`.

### NumberInput

- `public GUINumberInput( RectTransform rectT, NumberType inputType, string style = "", Alignment textAlignment = Alignment.Center, float? relativeButtonAreaWidth = null, ButtonVisibility buttonVisibility = ButtonVisibility.Automatic, (GUIButton PlusButton, GUIButton MinusButton)? customPlusMinusButtons = null)`.

### TickBox

- `public GUITickBox(RectTransform rectT, LocalizedString label, GUIFont font = null, string style = "")`.

### Image

- `public GUIImage(RectTransform rectT, string style, bool scaleToFit)`.
- `public GUIImage(RectTransform rectT, string style, ScalingMode scaleToFit = ScalingMode.None)`.
- `public GUIImage(RectTransform rectT, Sprite sprite, bool scaleToFit, Rectangle? sourceRect = null)`.
- `public GUIImage(RectTransform rectT, Sprite sprite, Rectangle? sourceRect = null, ScalingMode scaleToFit = ScalingMode.None)`.

### ListBox

- `public GUIListBox(RectTransform rectT, bool isHorizontal = false, Color? color = null, string style = "", bool isScrollBarOnDefaultSide = true, bool useMouseDownToSelect = false)`.

### DropDown

- `public GUIDropDown(RectTransform rectT, LocalizedString text = null, int elementCount = 4, string style = "", bool selectMultiple = false, bool dropAbove = false, Alignment textAlignment = Alignment.CenterLeft, float listBoxScale = 1)`.

### ScrollBar

- `public GUIScrollBar(RectTransform rectT, float barSize = 1, Color? color = null, string style = "", bool? isHorizontal = null)`.

### ProgressBar

- `public GUIProgressBar(RectTransform rectT, float barSize, Color? color = null, string style = "", bool showFrame = true)`.

### ColorPicker

- `public GUIColorPicker(RectTransform rectT, string? style = null)`.

### CustomComponent

- `public GUICustomComponent(RectTransform rectT, Action<SpriteBatch, GUICustomComponent> onDraw = null, Action<float, GUICustomComponent> onUpdate = null)`.

### ScissorComponent

- `public GUIScissorComponent(RectTransform rectT)`.

### DragHandle

- `public GUIDragHandle(RectTransform rectT, RectTransform elementToMove, string style = "GUIDragIndicator")`.

### MessageBox

- `public GUIMessageBox(LocalizedString headerText, LocalizedString text, Vector2? relativeSize = null, Point? minSize = null, Type type = Type.Default)`.
- `public GUIMessageBox(RichString headerText, RichString text, LocalizedString[] buttons, Vector2? relativeSize = null, Point? minSize = null, Alignment textAlignment = Alignment.TopLeft, Type type = Type.Default, string tag = "", Sprite icon = null, string iconStyle = "", Sprite backgroundIcon = null, Func<bool> autoCloseCondition = null, bool hideCloseButton = false)`.
- `public GUIMessageBox(Identifier hintIdentifier, LocalizedString text, Sprite icon)`.

### ContextMenu

- `public GUIContextMenu(Vector2? position, LocalizedString header, string style, params ContextMenuOption[] options)`.

### VideoPlayer

- `public VideoPlayer()`.

### Graph

- `public Graph(int arraySize = 100)`.

### SerializableEntityEditor

- `public SerializableEntityEditor(RectTransform parent, ISerializableEntity entity, bool inGame, bool showName, string style = "", int elementHeight = 24, GUIFont titleFont = null, bool dimOutDefaultValues = true)`.
- `public SerializableEntityEditor(RectTransform parent, ISerializableEntity entity, IEnumerable<SerializableProperty> properties, bool showName, string style = "", int elementHeight = 24, GUIFont titleFont = null, bool dimOutDefaultValues = true)`.

### SlideshowPlayer

- `public SlideshowPlayer(RectTransform rectT, SlideshowPrefab prefab)`.

### CreditsPlayer

Создание пока исключено по согласованию с пользователем. Сигнатура приведена справочно:

- `public CreditsPlayer(RectTransform rectT, string configFile)`.

## Вспомогательные и служебные имена

- `ContextMenuOption`: значение для контекстного меню, варианты label/isEnabled/onSelected и label/isEnabled/subOptions; не принимает UI-детей.
- `GUI.Canvas.Instance`: существующий singleton, используется как родитель/ресурс; пакет не создаёт и не удаляет его.
- `GUI`, `Style`, `GUIStyle`, `Component`, `Screen`: фасады, базовые/служебные классы; не являются схемами создаваемых панелей.
- `RectTransform`: объект размещения, создаётся через поле `rect`.
- `Anchor`, `Alignment`, `Pivot`, `SoundType`, `CursorState`: именованные игровые варианты; передаются через `$enum`. `ScaleBasis` и вложенные enum получают точное CLR-имя.

Для ColorPicker, MessageBox, ContextMenu и VideoPlayer тесты обязаны проверить очистку не только прямоугольника. Для всех типов итоговый README отмечает реально выполненный игровой прогон.

Для `DropDown` в цепочке родителей необходим настоящий GUIComponent, например Frame. Один RectTransform без GUIComponent не удовлетворяет требованиям штатного раскрывающегося списка.
