# Команды проверок Lua-кода

## Тесты

Тесты запускай через Busted в WSL под Lua 5.2. В дистрибутиве WSL должны быть доступны команды `busted` и `lua5.2`.

Из PowerShell в корне репозитория:

```powershell
wsl --exec busted --lua=lua5.2 --pattern='_test%.lua$' --lpath='./Lua/?.lua;./Lua/?/init.lua' Lua
```

Команда рекурсивно ищет `*_test.lua` в `Lua` согласно [правилу размещения](structure.md#тесты-lua). Параметр `--pattern` заменяет стандартный шаблон Busted `_spec`, а `--lpath` задаёт пути поиска модулей. Параметры описаны в [документации Busted](https://lunarmodules.github.io/busted/#usage).

## Форматирование и линт

Форматирование:

```powershell
python tools/luafmt/luafmt.py
```

Проверка форматирования без изменения файлов:

```powershell
python tools/luafmt/luafmt.py --check
```

Линт:

```powershell
python tools/lualint/lualint.py
```

Параметры запуска и требования — в README [luafmt](../../tools/luafmt/README.md) и [lualint](../../tools/lualint/README.md).
