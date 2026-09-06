---
doc_id: stcop.runtime-integration
title: "Runtime STCOP: книги, награды, телохранители и заказы"
kind: reference
status: verified-static
updated: 2026-09-06
topics: [runtime, IXR, registry, service, skill_books, rewards, bodyguards, trader_orders, callbacks]
sources: [../scripts/sgm_stcop_skill_books.script, ../scripts/sgm_stcop_skill_book_rewards.script, ../scripts/sgm_stcop_bodyguards.script, ../scripts/sgm_stcop_trader_orders.script, ../../ixray-sgm/scripts/sgm_g.script, ../../ixray-sgm/scripts/sgm_bodyguards.script]
---

# Runtime STCOP: книги, награды, телохранители и заказы

STCOP использует четыре Lua-скрипта. Код отдельного пакета хранит его weapon/book IDs; базовый SGM предоставляет расширяемые API. Это сохраняет работу SGM при отключённом STCOP. Ни один описанный registry-сервис не является постоянным save storage.

Перед анализом/правкой Lua полностью прочитать [script-performance.md](../../ixray-sgm/.ai/script-performance.md) и правила [AGENTS.md](../AGENTS.md). Справочник функций со ссылками на source — [source-catalog.md](reference/source-catalog.md). Код искать с `repo: "ixray-sgm-stcop"`, эту страницу — с `repo: "ixray-sgm-stcop-docs"`, базовые реализации — с `repo: "ixray-sgm"`.

## Точки входа

| Скрипт | Вход | Роль |
|---|---|---|
| [sgm_stcop_skill_books](../scripts/sgm_stcop_skill_books.script) | `on_game_start()`, публичная `register_skill_books()` | Registry marker STCOP и регистрация карты книг |
| [sgm_stcop_skill_book_rewards](../scripts/sgm_stcop_skill_book_rewards.script) | `on_game_start()` → framework callbacks | Fixed quest/treasure rewards |
| [sgm_stcop_bodyguards](../scripts/sgm_stcop_bodyguards.script) | `on_game_start(data)` | Оружейный catalogue extension для телохранителей |
| [sgm_stcop_trader_orders](../scripts/sgm_stcop_trader_orders.script) | XML `action` → `select_*` | Адаптер выбора заказного оружия |

[mod_script_stcop_skill_books.ltx](../configs/mod_script_stcop_skill_books.ltx) также добавляет `sgm_stcop_skill_books` в `[common] script`. Это не устанавливает гарантированный порядок `on_game_start`. Обычные start-функции подхватывает IXR autoloader; hard dependency решается registry queue + immediate apply. После добавления script/start функции нужен полный перезапуск процесса из-за кэша автозагрузчика.

## Контракт сервиса книг SGM

Константы объявлены в [sgm_g.script](../../ixray-sgm/scripts/sgm_g.script):

| Константа | Значение |
|---|---|
| `SGM_SKILL_BOOK_REGISTRY_KEY` | `sgm_skill_books` |
| `SGM_SERVICE_KEY` | `service` |
| `SGM_EXTENSIONS_KEY` | `extensions` |
| `SGM_SKILL_BOOKS_READY_EVENT` | `sgm_skill_books_on_ready` |

`initialize_skill_books_framework()` публикует таблицу version 1 в `GetRegistryValue("sgm_skill_books", "service")`. API:

| Поле | Контракт |
|---|---|
| `version` | 1 |
| `set_skill_books(level_name, books)` | Принимает имя уровня и строку/массив книг; нормализует `skill_book_`, отбирает существующие секции и устраняет повторы |
| `register_map(books_by_level)` | Принимает карту level → books; добавляет через общий setter |
| `give_skill_book(section, news, is_general)` | Сохраняет legacy global API; явный section выдаётся один раз, nil выбирает из пулов |

Setter возвращает число добавлений либо false с описанием ошибки. `register_map` возвращает число добавлений либо false для некорректного типа карты. `give_skill_book` не следует использовать как boolean result API: публичная функция не возвращает результат внутренней once-выдачи. Для fixed reward проверяется `*_given` info portion.

База после публикации читает queued maps из `extensions`, применяет их и посылает ready event. Intercept `sgm_skill_books_on_ready` с аргументом `service_table` зарегистрирован в [__ixr_override_signals_intercepts.script](../../ixray-sgm/scripts/__ixr_override_signals_intercepts.script).

## Почему карта STCOP намеренно пустая

В `sgm_stcop_skill_books` таблица `books_by_level = {}` — текущий дизайн, а не пропущенное содержимое. Книги STCOP являются фиксированными квестовыми/тайниковыми наградами. Добавление их в random location pools позволило бы раннему случайному выпадению поглотить позднюю награду.

`register_skill_books()`:

1. Проверяет наличие API `IsModuleLoaded` и модуля `ixr_registry`; при отсутствии возвращает false.
2. Получает `extensions`, восстанавливает table при несовместимом значении.
3. Записывает `extensions.stcop = books_by_level`.
4. Если service уже существует и имеет `register_map`, применяет карту немедленно.
5. После успешного immediate apply посылает ready event.
6. Возвращает true после успешной постановки в очередь, даже если service ещё не опубликован.

Условие `register_map` проверяет именно результат false: ноль добавленных книг является успешной регистрацией пустой карты. Маркер `extensions.stcop` нужен fixed-reward consumer для обнаружения активного расширения.

Оба порядка поддерживаются конструкцией: extension-first оставляет queue для базы; service-first применяет карту сразу. Повторный вызов записывает тот же ключ и не добавляет дубликаты книг; ready event может прийти повторно, поэтому downstream handlers должны быть идемпотентны.

## Fixed rewards: источник истины и жизненный цикл

`sgm_stcop_skill_book_rewards` содержит локальную таблицу `rewards`: каждый элемент задаёт `info` и массив `books`. Точный полный перечень находится в [исходнике](../scripts/sgm_stcop_skill_book_rewards.script). Representative mappings:

| Сюжетный флаг | Книги |
|---|---|
| `esc_lull_before_borax_complete` | `skill_book_aps`, `skill_book_tt33` |
| `esc_blockpost_protection_complete` | `skill_book_kedr`, `skill_book_kiparis` |
| `jup_beat_from_monsters_complete` | `skill_book_saiga`, `skill_book_vepr` |
| `mil_defence_b7_monsters_is_dead` | `skill_book_m16`, `skill_book_m4` |
| `pri_b35_reward_given` | `skill_book_m24`, `skill_book_sv98` |
| `stcop_zat_unique_treasure_1_opened` | `skill_book_scar`, `skill_book_m98b` |
| `stcop_zat_unique_treasure_2_opened` | `skill_book_ak12`, `skill_book_mk14` |
| `stcop_jup_unique_treasure_1_opened` | `skill_book_dvl10`, `skill_book_l96` |
| `stcop_jup_unique_treasure_2_opened` | `skill_book_ace52`, `skill_book_fal` |
| `pri_zone_cleaning_complete` | `skill_book_pkp` |

Два выбора флага особенно существенны. `mil_defence_b7_complete` встречается и при провале: reward использует флаг уничтожения всех monster squads. `pri_b35_task_end` возможен при бегстве цели: reward использует успешный `pri_b35_reward_given`. Замена их общими «завершено» флагами меняет условия награды.

`get_skill_book_service()` требует загруженный registry, table `extensions.stcop` и service с функцией `give_skill_book`. `process_rewards()` завершается без обработки до наличия `db.actor` и service. `processing_rewards` защищает от вложенного повторного прохода, когда выдача info portion сама вызывает info callback.

Для неразрешённого reward проверяется quest flag. Каждая ещё не выданная книга передаётся в `service.give_skill_book(section, true)`; завершённость определяется `reward_is_resolved()`, то есть наличием всех `section .. "_given"`. Module-local `reward.resolved` — runtime ускорение, а постоянное доказательство выдачи — info portions.

## Колбэки наград

`on_game_start()` регистрирует стабильные именованные функции:

| Событие | Handler | Что разрешает |
|---|---|---|
| `sgm_skill_books_on_ready` | `on_skill_books_ready` | Отложенную готовность сервиса |
| `on_game_load` | `on_game_load` | Выполненные флаги после загрузки |
| `actor_on_info_callback` | `on_actor_info` | Новое сюжетное условие |
| `actor_on_item_take_from_box` | `on_take_item_from_box(box)` | Fallback открытия кодового тайника |

После регистрации сразу вызывается `process_rewards()`. Отдельного `actor_on_update` polling нет. Повторный callback безопасен за счёт once-info checks и защиты от вложенной обработки. Не заменять обработчики новыми анонимными closures при каждом start: framework set дедуплицирует стабильные ссылки, а не эквивалентный текст функций.

## Предмет книги, skill binding и кодовый тайник

[mod_system_stcop_skill_books.ltx](../configs/mod_system_stcop_skill_books.ltx) объявляет `[skill_book_*]:skill_book`, локализованные `inv_name`/`description`, `skill_target = wpn_*` и дополняет `[keep_items]`. Weapon `increasing_skill_info` и `weapon_type` находятся у владельца оружия, а не в этом item-file.

Тексты принадлежат [st_sgm_stcop_skill_books.xml](../configs/text/rus/st_sgm_stcop_skill_books.xml). [mod_extended_portations_stcop.xml](../configs/gameplay/mod_extended_portations_stcop.xml) добавляет свои info IDs, в том числе четыре `stcop_*_unique_treasure_*_opened`. При добавлении новой книги проверить доступность всех потребляемых/выданных info IDs во всём активном стеке; наличие item section само по себе этого не доказывает.

Четыре `configs/scripts/SGM/{zaton,jupiter}/unique_treasures/mod_*_stcop.ltx` меняют `[ph_universal] treasure_object_code_action` на выдачу соответствующего open-info. Fallback handler получает story ID контейнера через `get_object_story_id(box:id())`; первый взятый предмет из одного из четырёх известных контейнеров записывает open-info, если его ещё нет. Это поддерживает saves, где другой аддон заменил custom_data тайника. Handler не считает любой открытый контейнер STCOP-тайником.

## Телохранители: оборудование через registry

[sgm_stcop_bodyguards.script](../scripts/sgm_stcop_bodyguards.script) хранит явный set `ROOTS` weapon families. `build_catalogue()` обходит эффективный `system_ini()`; вариант определяется по `parent_section`, а при отсутствии — по собственной секции.

Фильтры:

- root должен быть разрешён в `ROOTS`;
- исключается `pri_a17_gauss_rifle`;
- исключается `quest_item = true`;
- нужны `class` и `slot`, class начинается с `WP_`;
- slot 1 даёт `kind = "pistol"`, slot 2 — `kind = "rifle"`.

Публикация: `GetRegistryValue("sgm_bodyguards", SGM_EXTENSIONS_KEY, {})` → `maps.stcop = entries` → `SetRegistryValue`. Если service уже есть и `version == 1`, вызывается `service.register_equipment("stcop", entries)`. Module-local `registered` предотвращает повторную регистрацию этим startup.

Базовый [sgm_bodyguards.register_equipment(extension_id, entries)](../../ixray-sgm/scripts/sgm_bodyguards.script) принимает карту section → `{kind=...}`. До готовности gameplay INI он откладывает записи; после готовности разрешает metadata и пересобирает каталог. Сервис принимает `pistol`, `rifle`, `medkit`; STCOP передаёт только оружейные виды. Порядок extension IDs при сборке каталога сортируется в базе.

Нельзя напрямую менять local catalogue базы, выводить варианты из имени файла или добавлять quest weapons обходом фильтра. Новый root требует проверки effective parent_section всех desired variants. Registry-каталог не сохраняется в .ixr; собственный механизм persistent storage STCOP здесь не создаёт.

## Заказное оружие: публичные XML action wrappers

`sgm_stcop_trader_orders` не регистрирует новый сервис или callback. Локальная `order_specs` задаёт item, cost, rank, а `select_order(key)` вызывает существующие `sgm_dialogs.custom_order(spec.cost)` и `sgm_dialogs.choose_item(spec.item, spec.rank)`.

Публичные функции сохраняют XML-сигнатуру `(first_speaker, second_speaker)`:

`select_kriss_vector`, `select_vihr`, `select_p90`, `select_protecta`, `select_m3super90`, `select_fn2000`, `select_vsk94`, `select_sr25`, `select_pkp`, `select_vssk`.

Потребители — [mod_extended_dialogs_stcop_tier5_orders.xml](../configs/gameplay/mod_extended_dialogs_stcop_tier5_orders.xml), [mod_dialogs_escape_stcop_tier5_orders.xml](../configs/gameplay/mod_dialogs_escape_stcop_tier5_orders.xml), [mod_dialogs_marsh_stcop_tier5_orders.xml](../configs/gameplay/mod_dialogs_marsh_stcop_tier5_orders.xml). Флаги заказов объявлены в [mod_extended_portations_stcop_tier5_orders.xml](../configs/gameplay/mod_extended_portations_stcop_tier5_orders.xml).

Например XML `<action>sgm_stcop_trader_orders.select_fn2000</action>` выбирает spec для `wpn_fn2000`; далее диалог использует штатные cost/money/delivery действия SGM. Число `cost` этого spec нельзя автоматически считать полной магазинной ценой оружия: его семантика определяется `custom_order`. При изменении стоимости проверить все дальнейшие действия заказа.

## Обязательная матрица регрессии

| Сценарий | Ожидаемый инвариант |
|---|---|
| Только SGM | Нет STCOP maps/items/rewards/dialog actions в активном стеке |
| Extension до service | Queue принята после публикации |
| Service до extension | Immediate API call применяет те же данные |
| Повторный start/регистрация | Нет дублей books/catalogue/callback effects |
| Ready/info до actor | Обработка безопасно отложена |
| Условие уже выполнено при load | Невыданная награда разрешается после готовности |
| Книга уже в инвентаре/прочитана | once-info фиксируется без второго предмета |
| Провал Military или бегство цели B35 | Награда успеха не выдаётся |
| Кодовый тайник и fallback first take | Один и тот же open-info, отсутствие двойной выдачи |
| Scoped weapon у телохранителя | Включение по effective parent_section, исключение quest item |
| XML заказ | Корректный item, ранг, проверка денег, оплата и дальнейшая выдача |

LuaJIT `loadfile` проверяет синтаксис; stub-тесты проверяют API/порядок, но не движковые userdata или сохранение. Полный перезапуск, новая игра для новых upgrade trees, save/load и игровой сценарий выполняются человеком. Состояние `verified-static` не заявляет, что эти gameplay-сценарии уже пройдены.

