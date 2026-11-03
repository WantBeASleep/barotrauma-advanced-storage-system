# ui_schema 0.1.0

Создание штатного UI Barotrauma из строки JSON. Библиотека находится в разработке; игровые прогоны пока не выполнены. Источник исходников — этот репозиторий, `Lua/limanchel/pkg/ui_schema/v0_1_0/`.

Зависимости: Lua 5.2 через LuaCs/MoonSharp, клиентский GUI для построения, `limanchel.pkg.goerrors.v0_1_0.goerrors`. Разбор JSON не требует игры. Файлы читает вызывающий код.

Внутренний декодер — Lunajson 1.2.3, ревизия `250afac121df831f449d6370ddf406673f6f9c2b`, оригинальный `src/lunajson/decoder.lua`. Поставляется без изменения, SHA-256 `5257c567492e7c0203ae1a463313fce6b8d082db093a4aa841ccec8dec164546`, лицензия — `vendor/LICENSE`. SAX-парсер, кодировщик и файловый API не поставляются.

Карта игровых типов и состояние проверок — [COMPONENTS.md](COMPONENTS.md).
