# Команды проверок Lua-кода

## Команды

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
