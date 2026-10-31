# Структура проекта и пути

Устройство исходного шаблона и правила размещения файлов. Все пути указаны относительно корня репозитория.

## Пути и вспомогательные файлы

Не привязывайте код к абсолютным путям конкретного компьютера. Вычисляйте пути
относительно скрипта, проекта или каталога игры. Необходимые вспомогательные файлы
храните в проекте или внутри каталога установки Barotrauma.

## Структура проекта

Ниже приведена структура исходного шаблона. Папки `assets/` и `source/`
создаются по необходимости. После переименования проекта используйте его
фактические пути вместо `your_namespace/your_project`.

```text
.
+-- .codex/                       # Локальные skills и правила для AI-агентов
+-- .vscode/                      # VS Code workspace с Lua annotations
+-- assets/                       # Runtime assets, загружаемые игрой
+-- bin/                          # Локальные бинарники инструментов
+-- docs/                         # Техническая документация
|   +-- development/              # Разработка и проверки
|   +-- template/                 # Подготовка нового мода
+-- CSharp/                       # Опциональные LuaCs C# source scripts
+-- Lua/                          # Runtime Lua-код, загружаемый LuaCs
|   +-- Autorun/                   # LuaCs autorun entrypoints
|   +-- your_namespace/
|       +-- pkg/                   # Версионированные общие Lua-пакеты
|       |   +-- package_name/
|       |       +-- v1_0_0/
|       +-- your_project/
|           +-- feature/           # Код конкретного мода
+-- preview/                      # Workshop preview/logo images
+-- source/                       # Исходники ассетов, references, fonts
+-- tools/                        # Проектные утилиты
|   +-- luafmt/                    # Запуск StyLua
|   +-- lualint/                   # Запуск Selene
+-- .stylua.toml                  # Конфигурация StyLua
+-- .styluaignore                 # Исключения для StyLua
+-- AGENTS.md                     # Инструкции для coding agents
+-- filelist.xml                  # Barotrauma content package definition
+-- ModConfig.xml                 # Lua/C# файлы, компилируемые/загружаемые LuaCs
+-- selene.toml                   # Конфигурация Selene
+-- selene_std_luacs_client.yml   # Generated client LuaCs std
+-- selene_std_luacs_server.yml   # Generated server LuaCs std
```

Общие пакеты размещай и версионируй по [соглашению pkg](packages.md).
Существующие библиотеки в `lib` переносятся отдельной задачей; схема выше задаёт целевое размещение.

[К оглавлению разработки](README.md).

