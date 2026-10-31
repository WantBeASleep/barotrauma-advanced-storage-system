# Область просмотра workshop

Снимок 2026-10-30. Перечислены все каталоги и все `.lua`/`.cs`, включая скрытые и игнорируемые. Бинарники, XML и ресурсы не декомпилировались массово. Счётчики включают `.d.lua`; наличие C# и Lua не означает взаимодействие. Хеши каждого файла и группы точных копий: [workshop-files.json](workshop-files.json).

| ID | Мод | modversion | Lua | C# |
| --- | --- | --- | ---: | ---: |
| 2095211492 | Shipwrecks Extended | 1.0.17 | 0 | 0 |
| 2518816103 | Barotraumatic | 1.0.276 | 0 | 0 |
| 2532991202 | DynamicEuropa | 2.0.265 | 0 | 0 |
| 2559634234 | LuaCsForBarotrauma | 1.0.117 | 10 | 0 |
| 2687736741 | 32x Stack - Lite | 1.0.16 | 0 | 0 |
| 2767049553 | Wreck Locator | 1.0.3 | 0 | 0 |
| 2783973083 | R-278 «Dugong» | 1.0.21 | 0 | 0 |
| 2809175631 | [EA-HI]木卫二萌化计划 | 2.2.4 | 0 | 0 |
| 2852315967 | Lua Linker | 1.2.1 | 3 | 0 |
| 2936760984 | Real Sonar | 2.1.0 | 17 | 0 |
| 2954998725 | Hungry Europans | 2.0.49 | 0 | 0 |
| 2968896556 | Enhanced Immersion | 1.0.27 | 10 | 0 |
| 2986079116 | Total Russian Translation (TRT) | 1.81.1 | 3 | 0 |
| 3045796581 | Enhanced Reactors | 1.0.36 | 3 | 0 |
| 3114087512 | Immersive Repairs | 1.0.37 | 0 | 0 |
| 3136460675 | oClockRadar ⁄ Sonar [Alt] for BT v1.2.8 | 1.0.3 | 0 | 0 |
| 3153737715 | Soundproof Walls 2.0 | 2.2.2 | 0 | 0 |
| 3218219821 | Artifacts and Ruins Enhanced | 1.0.19 | 0 | 0 |
| 3231293294 | BetterHealthUI (Rework) | 2.2.2.0 | 0 | 8 |
| 3239152683 | Immersive Repairs - Vanilla Oxygen Patch | 1.0.1 | 0 | 0 |
| 3239164008 | Immersive Crates | 1.0.6 | 0 | 0 |
| 3241571278 | Project Humanize Character Overhaul | b1.26 | 0 | 0 |
| 3279470465 | Baroverhaul | 1.4.27 | 0 | 0 |
| 3282179907 | Baroverhaul Immersive Repairs Patch | 1.0.3 | 0 | 0 |
| 3321850228 | Immersive Handcuffs | 1.0.12 | 0 | 0 |
| 3337851889 | Immersive Crates - Mod Crates Compatibility Patch | 1.0.1 | 0 | 0 |
| 3354732876 | Enhanced Reactors - Reactor Management (Add-On) | 1.0.6 | 0 | 0 |
| 3371925534 | Guns Enhanced | 0.0.73 | 0 | 0 |
| 3413495302 | Press-R-to-Reload | 1.0.25 | 1 | 0 |
| 3429028131 | More Clown Outfits | 1.0.0 | 0 | 0 |
| 3442900520 | Baroverhaul Enhanced Reactors Patch | 1.0.3 | 0 | 0 |
| 3448276676 | Baroverhaul - Dynamic Europa Patch | 1.0.5 | 0 | 0 |
| 3457759775 | Press R to Reload GE Compatible Patch | 1.0.4 | 1 | 0 |
| 3471496395 | ConditionBarsForInteractionLabels | 1.1 | 0 | 1 |
| 3483512226 | Various Cultist Robes (VCR) | 1.0.28 | 0 | 0 |
| 3504630278 | Fishes and Underwater Creatures Kollection | 7.2 | 0 | 0 |
| 3574799606 | More Orders | 1.2.1 | 0 | 14 |
| 3696204435 | More Content for Europa | 1.0.94 | 0 | 0 |
| 3748775860 | QoL - Medical icons | 2.0.0 | 61 | 5 |
| 3755729681 | Tactical Sonar [beta] | 1.4.0 | 2 | 26 |
| 3777143995 | Get out | 0.5 | 0 | 0 |
| 3817473233 | More Content for Europa - Enhanced Reactors Compatibility Patch | 1.0.0 | 0 | 0 |

Всего: 42 каталогов, 111 Lua-файлов, 54 C#-файлов.

По всем исходникам выполнен поиск `LuaUserData`, `UserData.Register`, `MoonSharp`, `Closure`, `DynValue`, `LuaCs`, `Hook`, GUI-делегатов, файлового и сетевого обмена. Цепочки вручную прослежены для подходов в [каталоге практик](../../../.codex/skills/luacs-interop/references/mod-patterns.md). Это полный файловый охват доступных исходников, но не построчный аудит всего кода и не проверка поведения всех модов.
