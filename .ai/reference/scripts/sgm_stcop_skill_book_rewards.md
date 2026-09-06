---
doc_id: "ixray-sgm-stcop.script.sgm_stcop_skill_book_rewards"
title: "sgm_stcop_skill_book_rewards: Lua declarations and literal API references"
kind: "generated-reference"
status: "extracted-static"
updated: "2026-09-06"
topics: ["sgm_stcop_skill_book_rewards","Lua","script","symbols","callbacks"]
sources: ["../../../scripts/sgm_stcop_skill_book_rewards.script"]
source_sha256: "5a2540bd1fc3c3d67d3bb9d8e18612fa8b7415b04bef668c3f3dc17e497fa1e1"
---

# sgm_stcop_skill_book_rewards: объявления Lua и ссылки API

Репозиторий: `ixray-sgm-stcop`. Виртуальный путь: `scripts/sgm_stcop_skill_book_rewards.script`. Источник: [scripts/sgm_stcop_skill_book_rewards.script](../../../scripts/sgm_stcop_skill_book_rewards.script). Кодировка чтения: UTF-8. SHA-256: `5a2540bd1fc3c3d67d3bb9d8e18612fa8b7415b04bef668c3f3dc17e497fa1e1`.

Это автоматически извлечённая карта навигации. Объявление без `local` не доказывает публичность API: вложенность и области видимости не разрешаются. Строковые обращения не доказывают достижимость. Полное поведение описано в [навигации документации](../../README.md).

## sgm_stcop_skill_book_rewards: объявления функций

| Символ | Аргументы | Строка исходника (1-based) | Явный local |
|---|---|---:|---|
| `get_skill_book_service` | `` | 69 | да |
| `reward_is_resolved` | `reward` | 86 | да |
| `give_reward` | `service, reward` | 95 | да |
| `process_rewards` | `` | 107 | да |
| `on_actor_info` | `` | 131 | нет |
| `on_skill_books_ready` | `` | 135 | нет |
| `on_game_load` | `` | 139 | нет |
| `on_take_item_from_box` | `box` | 143 | нет |
| `on_game_start` | `` | 160 | нет |

## sgm_stcop_skill_book_rewards: буквальные имена callbacks, modules и registry

| Операция | Имя | Строка |
|---|---|---:|
| `IsModuleLoaded` | `ixr_registry` | 70 |
| `RegisterScriptCallback` | `on_game_load` | 162 |
| `RegisterScriptCallback` | `actor_on_info_callback` | 163 |
| `RegisterScriptCallback` | `actor_on_item_take_from_box` | 164 |
