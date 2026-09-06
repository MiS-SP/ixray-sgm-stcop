---
doc_id: stcop.overview
title: "STCOP для SGM: карта проекта и навигация"
kind: reference
status: verified-static
updated: 2026-09-06
topics: [STCOP, SGM, overview, addon, architecture, RAG, GitNexus]
sources: [../addon.init, ../AGENTS.md, ../configs/weapons/stcop_content.ltx, ../configs/weapons/stcop_patches.ltx, ../scripts]
---

# STCOP для SGM: карта проекта и навигация

Этот репозиторий — необязательный оружейный и интеграционный пакет для базового SGM на IX-Ray CoP. Текущий физический каталог: `ixr_addons/ixray-sgm-stcop`. [addon.init](../addon.init) задаёт `name: stcop`, `platform: cop`, зависимость от `sgm`. Отдельный базовый пакет находится в `ixr_addons/ixray-sgm`; ID зависимости и имя физического каталога различаются.

Документация описывает исходники и конфигурацию рабочего дерева на 2026-09-06. Статус `verified-static` означает сверку со source, а не запуск игры. Материалы с историческими префиксами каталогов не следует использовать для вычисления текущих путей.

## Куда идти по задаче

| Задача | Документ |
|---|---|
| Оружие, ammo, HUD, классы, loadout, торговля | [Арсенал и доступность](arsenal-and-loadouts.md) |
| Книги, fixed rewards, registry, телохранители, заказы | [Runtime интеграция](runtime-integration.md) |
| Точные исходные файлы и карта для поиска | [Source catalog](reference/source-catalog.md) |
| Владение секциями и порядок DLTX | [SGM loading-and-dltx](../../ixray-sgm/.ai/configuration/loading-and-dltx.md) |
| Патроны и Lua membership | [SGM weapons-and-ammunition](../../ixray-sgm/.ai/configuration/weapons-and-ammunition.md) |
| Деревья и два INI-контекста | [SGM upgrades](../../ixray-sgm/.ai/configuration/upgrades.md) |
| Детали текущего пересчёта улучшений | [weapon-upgrade-balance.md](../docs/weapon-upgrade-balance.md) |
| UI/атласы/локализация/модели | [SGM resources-and-localization](../../ixray-sgm/.ai/configuration/resources-and-localization.md) |
| Мир, тайники, LTX и all.spawn | [SGM world-and-spawn](../../ixray-sgm/.ai/configuration/world-and-spawn.md) |
| Обязательные правила | [AGENTS.md](../AGENTS.md), [SGM weapon-dltx-layers](../../ixray-sgm/docs/weapon-dltx-layers.md) |

## Границы пакета

| Каталог | Роль |
|---|---|
| `configs/weapons/{AR,P,SHTG,SR,LMG,SMG,...}` | Оружейные определения и локальные варианты |
| `configs/weapons/stcop` | Общие STCOP defaults/sounds/addons/ammo/upgrades и настоящие DLTX изменения SGM |
| `configs/gameplay` | Loadout datasets, XMLOverride персонажей/диалогов/инфопорций |
| `configs/misc` | Торговля, ammunition loot и дополнительные предметные данные |
| `configs/scripts/SGM` | Точечные патчи логики четырёх кодовых тайников |
| `configs/text`, `configs/ui` | Локализация, прицелы и atlas descriptors |
| `scripts` | Четыре модульных интеграционных скрипта |
| `meshes`, `textures`, `sounds`, `anims` | Бинарные ресурсы |
| `tools` | Вспомогательные инструменты разработки |
| `.ai` | Документация и retrieval artifacts |

STCOP добавляет own sections и изменяет SGM, но не должен помещать свои обязательные ID в базовые таблицы SGM. При отключении STCOP его книги, награды, оружие и runtime-регистрации должны исчезать вместе с пакетом. Это проверяется отдельным стеком SGM; наличие `depends: sgm` не доказывает обратную независимость.

## Основные точки сборки

[stcop_content.ltx](../configs/weapons/stcop_content.ltx) содержит точный список собственных definitions. [stcop_patches.ltx](../configs/weapons/stcop_patches.ltx) содержит конкретные изменения SGM. Оба подключены через `mod_weapons_10_stcop_load.ltx` и `mod_weapons_50_stcop_patches.ltx`.

Апгрейды дополнительно включены через `mod_item_upgrades_10_stcop_load.ltx` и `mod_item_upgrades_50_stcop_patches.ltx`: глобальный INI и отдельный Lua INI должны видеть одинаковые определения/patches.

Скрипты `sgm_stcop_skill_books`, `sgm_stcop_skill_book_rewards`, `sgm_stcop_bodyguards` используют IXR Framework lifecycle; `sgm_stcop_trader_orders` вызывается из XML action. Файл script-набора не равен manifest-модулю Framework; все контракты разобраны в [runtime-integration.md](runtime-integration.md).

## Поиск GitNexus и RAG

Использовать явные пространства поиска:

- `repo: "ixray-sgm-stcop"` — исходный STCOP репозиторий.
- `repo: "ixray-sgm"` — сервисы и обязательная база SGM.
- `repo: "ixray-sgm-stcop-docs"` — отдельный индекс этой `.ai`.
- `repo: "ixray-sgm-docs"` — общая документация SGM.

Раздельный docs index нужен потому, что установленный scanner GitNexus не включает скрытую `.ai` при обычном source scan. Markdown находится в `.ai`; копии документации среди runtime-файлов не нужны.

Рабочие запросы: `stcop skill_book rewards registry`, `parent_section bodyguards register_equipment`, `stcop_content ammo_class`, `sgm_upgrade_mechanic item_upgrades`. После retrieval перейти по ссылке в конкретный source. Имя файла может не совпадать с section ID: например `w_fiveseven.ltx` и `wpn_fn57`.

GitNexus в этом проекте может возвращать File definitions без Lua symbols и execution flows. При первом исследовании этой версии `context(register_skill_books)` не нашёл символ, хотя функция есть в script. Это ограничение графа, не доказательство отсутствия функции. Проверять свежесть индекса и подтверждать строковые XML/LTX links через исходники.

## Проверка изменения

Для конфигов: SGM и SGM + STCOP, effective values и include closure; для upgrades — оба INI в каждом стеке. Для Lua: LuaJIT loadfile, все вызовы публичных функций, extension до/после service, повторная регистрация, отсутствие STCOP. Для ресурсов: виртуальные пути, XML/string/atlas IDs, кодировки и нужные варианты UI.

Новые деревья STCOP рассчитаны на новую игру; миграции старых installed upgrade IDs не заявлено. Игровая проверка человеком после полного перезапуска остаётся отдельной от статической проверки.

