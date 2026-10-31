# Инструменты и проверки

Настройка редактора и проверка Lua-кода. Все пути указаны относительно корня репозитория; команды запускайте из корня, а не из папки этого документа.

## VS Code и Lua annotations

Workspace [`.vscode/advance-storage-system.code-workspace`](../../.vscode/advance-storage-system.code-workspace) настроен под
[Lua Language Server](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)
и type definitions из
[Barotrauma-Lua-Annotations](https://github.com/zhu-rengong/Barotrauma-Lua-Annotations).

По умолчанию workspace ожидает annotations рядом с проектом:

```text
../Barotrauma-Lua-Annotations/Library/Client
```

Для server-side Lua можно переключить библиотеку на:

```text
../Barotrauma-Lua-Annotations/Library/Server
```

## Когда запускать проверки

- После изменения игрового Lua-кода запускайте форматирование и линт.
- После изменения настроек или инструментов форматирования запускайте форматирование.
- После изменения настроек линтера, сгенерированных std-файлов или инструментов
  линтинга запускайте линт.
- Исключайте сгенерированный Lua-код через `.styluaignore`, если форматирование
  может его повредить.
- Для изменений только документации форматирование и линт Lua не требуются.

Эти проверки выполняются, если пользователь не попросил иначе и инструменты доступны.
Команды приведены в следующих разделах.

## Форматирование Lua

Проект использует [StyLua](https://github.com/JohnnyMorganz/StyLua) с
`syntax = "Lua52"` в `.stylua.toml`.

Отформатировать Lua-файлы:

```powershell
python tools/luafmt/luafmt.py
```

Проверить форматирование без изменений:

```powershell
python tools/luafmt/luafmt.py --check
```

Раннер вычисляет пути от своего расположения и запускает локальный
`bin/stylua.exe` для папки `Lua/`.

## Линт Lua

Проект использует [Selene](https://github.com/Kampfkarren/selene) с Lua 5.2 и
сгенерированными LuaCs std-файлами.

Запустить lint для всех runtime Lua-файлов:

```powershell
python tools/lualint/lualint.py
```

Проверить конкретный файл или папку:

```powershell
python tools/lualint/lualint.py Lua/Autorun
```

Дополнительные аргументы Selene передаются повторяемым `--selene-arg`:

```powershell
python tools/lualint/lualint.py --selene-arg=--display-style --selene-arg=rich
```

## Генерация Selene std

В репозитории есть `selene_std_luacs_client.yml` и `selene_std_luacs_server.yml`,
но генератор `tools/generate/selene_std/generate_selene_luacs_std.py` отсутствует.
Повторная генерация из `Barotrauma-Lua-Annotations` пока недоступна;
восстановление генератора — отдельная задача. Для линта используются существующие std-файлы.

[К оглавлению разработки](README.md).
