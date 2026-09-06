---
doc_id: stcop.arsenal-loadouts
title: "Арсенал STCOP, профили оружия и доступность в мире"
kind: reference
status: verified-static
updated: 2026-09-06
topics: [arsenal, weapons, profiles, parent_section, loadout, spawn_supplies, trade, ammo, HUD]
sources: [../configs/weapons/stcop_content.ltx, ../configs/weapons/stcop_patches.ltx, ../configs/weapons/AR/w_ak12.ltx, ../configs/mod_engine_external_stcop_loadout.ltx, ../configs/gameplay/mod_character_desc_general_stcop_loadouts.xml, ../configs/gameplay/loadouts/stalker/tier_1.ltx]
---

# Арсенал STCOP, профили оружия и доступность в мире

Арсенал состоит из собственных weapon definitions и изменений оружия SGM. Расположение файла в `AR` или `P` не доказывает, что все его секции — независимые предметы: там могут быть HUD, scoped-варианты, sound/profile parents. Исчерпывающий активный список определяется include closure [stcop_content.ltx](../configs/weapons/stcop_content.ltx) и [stcop_patches.ltx](../configs/weapons/stcop_patches.ltx).

## Файлы и section IDs

| Семейство | Каталог | Характерные соответствия |
|---|---|---|
| Автоматы/винтовки | [weapons/AR](../configs/weapons/AR) | `w_ak12.ltx → wpn_ak12`; `w_lr300ml.ltx` не означает weapon ID `wpn_lr300ml` |
| Пистолеты | [weapons/P](../configs/weapons/P) | `w_fiveseven.ltx → wpn_fn57`; `w_tt33.ltx → wpn_tt33` |
| Дробовики | [weapons/SHTG](../configs/weapons/SHTG) | `wpn_saiga`, `wpn_vepr`, `wpn_fort500` |
| Пистолеты-пулемёты | [weapons/SMG](../configs/weapons/SMG) | `wpn_kriss_vector`, `wpn_kedr`, `wpn_p90` |
| Снайперские винтовки | [weapons/SR](../configs/weapons/SR) | `w_l96a1.ltx → wpn_l96`; `wpn_sr25`, `wpn_vssk` |
| Пулемёты | [weapons/LMG](../configs/weapons/LMG) | `w_hk21e.ltx → wpn_hk21`; `wpn_pkp`, `wpn_m60` |
| Уникальные варианты | [stcop/unique_content.ltx](../configs/weapons/stcop/unique_content.ltx), [unique_patches.ltx](../configs/weapons/stcop/unique_patches.ltx) | Definitions и изменения загружаются последними в своих списках |
| Общие parents | [stcop/common](../configs/weapons/stcop/common) | Defaults, sounds, projectiles |
| Обвесы | [stcop/addons](../configs/weapons/stcop/addons) | Scopes, silencers, launchers |
| Патроны | [stcop/ammo](../configs/weapons/stcop/ammo) | Только собственные definitions |
| Изменения SGM | [stcop/patches](../configs/weapons/stcop/patches) | Common, ammo, weapons, upgrades |

Поиск новой модели всегда проверяет literal section header. Нельзя вычислять `skill_book`, `parent_section`, upgrade IDs или loot key заменой префикса физического имени файла.

## Разбор `wpn_ak12`

В [w_ak12.ltx](../configs/weapons/AR/w_ak12.ltx) оружие наследует:

`weapon_probability, stcop_default_weapon_params, wpn_ak12_sounds, mod_stcop_ak12, mod_stcop_ak12_damage, cost_stcop_ak12`.

Отдельные профили задают стоимость, skill book (`increasing_skill_info = skill_book_ak12`), weapon type и damage. В weapon section находятся engine class `WP_AK74`, `parent_section = wpn_ak12`, доступ к mechanic через `sgm_upgrade_mechanic = wpn_ak74`, собственные группы `stcop_ak12_*`, HUD и модель.

`ammo_class` использует SGM `ammo_5.45x39_fmj` и `ammo_5.45x39_ap`; это общие секции SGM, а не отдельная копия STCOP. Иконки ссылаются на `ui/ui_icon_equipment_stcopwp` и `ui/ui_actor_weapons_stcopwp`. Этот пример показывает взаимосвязи; актуальные числовые параметры читать из рабочего файла и effective parents.

[stcop_default_weapon_params](../configs/weapons/stcop/common/defaults.ltx) наследует `default_weapon_params`, задаёт общие STCOP значения, включая `ammo_in_chamber` и `block_firemode_glm`. Tracers и suppressor smoke наследуются из SGM. Не копировать эти поля в модели без обоснованной разницы.

## Новые патроны и общие калибры

STCOP content явно включает дополнительные ammo files для 12.7×55, .338 Lapua, .357, 5.7×28, .50 AE, .50 BMG, 7.62×25, 7.62×39, 7.62×51, 7.62×54, 7.92×57, 9×39 и VOG-25. Наличие файла калибра не означает, что весь калибр переопределяет SGM: проверять конкретные section IDs.

Common SGM calibre balance остаётся у SGM. В [stcop_patches.ltx](../configs/weapons/stcop_patches.ltx) сохранены только подключённые непустые intentional ammo deltas: `p_12x76`, `p_7_62x54`, `p_base`, `p_gauss`, `p_og_7b`, `p_vog_25`, `p_sgm_extensions`. Новое отличие требует самостоятельного обоснования.

[patches/ammo/p_sgm_extensions.ltx](../configs/weapons/stcop/patches/ammo/p_sgm_extensions.ltx) расширяет Lua ammo membership. Дополнительные loot-интеграции отделены: [mod_death_items_count_50_stcop_ammo.ltx](../configs/misc/mod_death_items_count_50_stcop_ammo.ltx) и [mod_ph_box_items_by_levels_50_stcop_ammo.ltx](../configs/misc/mod_ph_box_items_by_levels_50_stcop_ammo.ltx). Расширение одного списка не заменяет эти механизмы.

## Как NPC получает оружие

[mod_engine_external_stcop_loadout.ltx](../configs/mod_engine_external_stcop_loadout.ltx) меняет `[spawn_supplies]`:

~~~ini
EnableLoadoutsSupplies = true
EnableSpawnFullRandomLoadout = false
EnableSpawnOnceRandomItemPerEachLoadouts = true
EnableSpawnOnceRandomitemByRandomLoadout = false
~~~

В данных используются группы `[spawn_loadout]`, `[spawn_loadout2]` и другие, встроенные в XML supplies. Литералы `\n` в LTX-фрагментах являются частью текста для XML/INI supplies; их нельзя механически заменить обычными переводами строк.

Пример [loadouts/stalker/tier_1.ltx](../configs/gameplay/loadouts/stalker/tier_1.ltx) разделяет основное оружие и пистолеты на две группы. Он не является одной общей таблицей вероятностей всего NPC. Точное поведение выбора определяется включёнными engine flags и их реализацией; значения `= 1` нельзя без проверки reader интерпретировать как полный шанс конкретного предмета.

[mod_character_desc_general_stcop_loadouts.xml](../configs/gameplay/mod_character_desc_general_stcop_loadouts.xml) заменяет supplies обычных simulation profiles, например `sim_default_duty_0_default_0`. Вместе с weapon-loadout он сохраняет подключения обычных предметов, еды, лекарств и при необходимости гранат. Actor и именованные квестовые NPC намеренно исключены этим override.

## Обычные и расширенные loadout datasets

| Путь | Потребитель/разделение |
|---|---|
| `gameplay/loadouts/<community>/tier_*.ltx` | Generic simulation profiles |
| `gameplay/loadouts/military/sniper.ltx`, `monolith/sniper.ltx` | Специализированные наборы |
| `gameplay/loadouts/escape_*.ltx`, `marsh_*.ltx`, `military_ak.ltx` | Конкретные ранние/локационные профили |
| `gameplay/loadouts_extended/respawn/<community>/tier_*.ltx` | SGM respawn profiles |
| `gameplay/loadouts_extended/freeplay_zombied/tier_*.ltx` | Freeplay zombied |
| `gameplay/loadouts_extended/alfa_force/<role>/tier_*.ltx` | Alfa commander, shotgunner, sniper, specnaz |

В стандартных путях используется `duty`, а в respawn — `dolg`; это реальные имена каталогов, не опечатка для массового переименования. Часть consumers лежит в SGM: например [character_desc_extended.xml](../../ixray-sgm/configs/gameplay/character_desc_extended.xml) включает extended freeplay loadouts. Один и тот же virtual path STCOP может заменять базовый dataset без изменения XML consumer.

Нельзя добавлять всё оружие сразу во все tiers ради «полной интеграции». Tier и роль — часть баланса доступности. После изменения проверить конкретный consumer, наличие каждой weapon section и отсутствие загрязнения набора без STCOP.

## Торговля, заказы и rewards

[configs/misc/trade](../configs/misc/trade) содержит полные trade resources и DLTX patches. [order_traders](../configs/misc/trade/order_traders) расширяет таблицы SGM. Патчи `*_stcop_tier5_order_only.ltx` удаляют отдельные сильные модели из обычных supplies; dialogue XML и `sgm_stcop_trader_orders` связывают их с заказом.

Таким образом weapon definition, продажа, NPC loadout, труп/ящик, заказ и skill-book reward — независимые каналы. Для нового предмета явно выбрать нужные каналы и проверить их владельцев. [Runtime-интеграция](runtime-integration.md) описывает точные script API и флаги.

## HUD и улучшения

[mod_engine_external_stwpbase.ltx](../configs/mod_engine_external_stwpbase.ltx) включает `EnableWeaponInertion`, `EnableWeaponCollision`, `EnableDelayedWeaponActions`. HUD definitions находятся в [mod_defines_50_stcop_weapon_hud.ltx](../configs/mod_defines_50_stcop_weapon_hud.ltx); позднее исключение ограничено двумя forward position fields в [mod_system_stcop_hud.ltx](../configs/mod_system_stcop_hud.ltx).

Собственные upgrade trees расположены в [stcop/upgrades/families](../configs/weapons/stcop/upgrades/families), shared includes — в `stcop_upgrades.ltx`. Требования mechanic читаются через SGM aliases. Полный контракт и четыре сочетания проверок — в [SGM upgrades](../../ixray-sgm/.ai/configuration/upgrades.md).

## Проверка арсенала

Для каждого изменённого weapon ID статически проверить: владелец, родители, effective fields, ammo, HUD/resources, localized strings, upgrade closure, variants и каждый затронутый канал выдачи. Для общего калибра проверить прохождение SGM base change в STCOP без второй правки.

Человек проверяет representative pistol/SMG/rifle/shotgun/sniper/LMG, scoped-вариант, глушитель/подствольник, chamber/reload, collision/inertion, работу механика и конкретный изменённый loadout/trader. Отсутствие ошибок parser не доказывает исправность motion или экономического сценария.

RAG namespaces: `ixray-sgm-stcop` для source; `ixray-sgm-stcop-docs` для этой страницы. Искомые якоря: `parent_section`, `stcop_content`, `spawn_loadout`, `EnableSpawnOnceRandomItemPerEachLoadouts`, `sgm_ammo_extensions`.

