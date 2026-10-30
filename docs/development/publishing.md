# Публикация в Steam Workshop

Для публикации лучше собирать отдельную Workshop-версию, в которой есть только
runtime-файлы:

- `filelist.xml`
- `ModConfig.xml` и файлы `CSharp/`, если мод использует C# helpers
- `Lua/`
- runtime assets из `assets/`
- preview-файлы, нужные для публикации

Не публикуйте исходники, `docs/`, agent skills, `.vscode`, локальные бинарники
инструментов и временные development files, если они не нужны в Workshop package.
