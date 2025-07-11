-- Author      : Manel
-- Create Date : 15/06/2025 13:10:15
--Translator ZamestoTV
local L = LibStub("AceLocale-3.0"):NewLocale("CounterIt", "ruRU")

if not L then return end

L["TITLE"] = "Счётчик"
L["TASK_MANAGER_TITLE"] = "Менеджер задач"
L["ACTIVE_MONITOR_TITLE"] = "Активные задачи"
L["ADD_TASK"] = "Добавить задачу"
L["FROM_TEMPLATE"] = "Из шаблона"
L["OPEN_MONITOR"] = "Открыть монитор"
L["EXPORT_IMPORT"] = "Экспорт / Импорт"
L["ACTIVATE"] = "Активировать"
L["EDIT"] = "Редактировать"
L["DELETE"] = "Удалить"
L["TASK_DESCRIPTION"] = "Описание"
L["TASK_GOAL"] = "Цель"
L["TASK_ICON"] = "Иконка"
L["SAVE"] = "Сохранить"
L["CANCEL"] = "Отмена"
L["CLOSE"] = "Закрыть"
L["RULES"] = "Правила"
L["NEW_RULE"] = "Новое правило"
L["TYPE"] = "Тип"
L["ID"] = "ID"
L["MINIMAP_LEFT"] = "ЛКМ: Открыть менеджер приостановленных задач"
L["MINIMAP_RIGHT"] = "ПКМ: Открыть монитор активных задач"
L["LOADED_MSG"] = "Счётчик загружен. Используйте /counterit для управления задачами или /cit для мониторинга."

L["MIGRATION_CLEANED_GLOBAL_PROGRESS"] = "Global task progress has been cleared to enable per-character tracking."

-- util
L["IMPORT_INVALID"] = "Недопустимый текст."
L["IMPORT_DECOMPRESS_FAIL"] = "Не удалось распаковать текст."
L["IMPORT_DESERIALIZE_FAIL"] = "Не удалось интерпретировать данные."
L["IMPORT_SUCCESS"] = "Задачи успешно импортированы."
L["EXPORT_IMPORT_TASKS"] = "Экспорт / Импорт задач"
L["COPY_PASTE_TASKS_DATA"] = "Копировать или вставить данные задач"
L["TASKS_TEXT"] = "Текст задач"
L["EXPORT"] = "Экспорт"
L["IMPORT"] = "Импорт"

-- ui
L["TITLE_TASK_MANAGER"] = "Счётчик: Менеджер задач"
L["STATUSTEXT_TASK_MANAGER"] = "Управляйте своими задачами"

L["TASKS_DEFINED"] = "TASKS DEFINED" -- TODO

L["EDIT_TASK"] = "Редактировать задачу"
L["NEW_TASK"] = "Новая задача"
L["DEFINE_TASK_DETAILS"] = "Определите детали задачи"

L["CONFIRM_DELETE_TASK"] = "Удалить задачу '%s' навсегда?"
L["YES"] = "Да"
L["CANCEL"] = "Отмена"

L["ADD_TO_FAVORITES"] = "Add to Favorites" -- TODO
L["REMOVE_FROM_FAVORITES"] = "Remove from Favorites" -- TODO
L["SHOW_ONLY_FAVORITES"] = "Show Only Favorites" -- TODO

L["TASK_SAVE_MISSING"] = "Отсутствуют обязательные поля."
L["TASK_SAVED"] = "Задача сохранена: %s"
L["TASK_PAUSED"] = "Приостановленные задачи"
L["TASK_OBJECTIVE"] = "%s (Цель: %d)"
L["TASK_TOOLTIP_OBJECTIVE"] = "Задача: %s \nЦель: %d"
L["SELECT_ICON"] = "Выбрать иконку"
L["EDIT_RULE"] = "Редактировать правило"
L["STATUSTEXT_NEW_RULE"] = "Определите детали правила"

L["TASK_OBJECTIVE_LABEL"] = "Цель"
L["TASK_ICON_LABEL"] = "Иконка (необязательно)"
L["RULE_TYPE_LABEL"] = "Тип правила"
L["RULE_ID_LABEL"] = "ID (необязательно для ручного)"

L["RULE_MANUAL"] = "Ручной счётчик"
L["RULE_QUEST"] = "Выполнить задание (questID)"
L["RULE_ITEM"] = "Получить предмет (itemID)"
L["RULE_SPELL"] = "Применить заклинание (spellID)"
L["RULE_PETCAPTURE"] = "Поймать боевых питомцев"

L["RULE_SPELL_NOT_FOUND"] = "|cffff0000Заклинание не найдено|r"
L["RULE_SPELLID_NOT_VALID"] = "|cffff0000ID недействителен|r"

L["RULE_ROLE_LABEL"] = "Роль" --TODO
L["ROLE_COMPLETION"] = "выполнение задания" --TODO
L["ROLE_AUTO_COUNT"] = "автоподсчет" --TODO
L["ROLE_ACTIVATION"] = "активация" --TODO
L["NO_ROLE"] = "без роли" --TODO

L["SCROLLFRAME_DEBUG"] = "scrollFrame = %s"

-- events
L["SIMULATE_PET"] = "Симулировано событие поимки питомца."
L["SPELLCAST_ID"] = "CheckSpellCast; %s"
L["SPELLCAST_NAME"] = "CheckSpellCast; %s"
L["SPELLCAST_MATCH"] = "CheckSpellCast; совпадение; %s"

-- template
L["TASK_TEMPLATE_CREATED"] = "Задача создана из шаблона: %s"
L["TEMPLATE_NOT_FOUND"] = "Шаблон не найден: %s"
L["TITLE_SELECT_TEMPLATE"] = "Выбрать шаблон"
L["STATUSTEXT_SELECT_TEMPLATE"] = "Выберите шаблон для создания задачи"

L["side-with-a-cartel"] = "Выбрали, с каким картелем вы будете сотрудничать на этой неделе"
L["ship-right"] = "Выполнить 10 работ."
L["reclaimed-scrap"] = "Собрано 100 пустых банок из-под Каджа'Колы из Гор ХЛАМа"
L["side-gig"] = "Выполнена побочная работа. Побочные работы доступны в главном транспортном узле"
L["war-mode-violence"] = "Победить пять игроков в режиме войны в Нижней Шахте"
L["go-fish"] = "Рыбалка в Нижней Шахте"
L["gotta-catch-at-least-a-few"] = "Поймать 5 диких питомцев"
L["rare-rivals"] = "Победить 3 редких НПС в Нижней Шахте"
L["clean-the-sidestreets"] = "Завершить вылазку Переулочного Шлюза"
L["time-to-vacate"] = "Завершено вылазку в месте раскопок 9"
L["desire-to-d-r-i-v-e"] = "Завершить две гонки в Нижней Шахте"
L["kaja-cruising"] = "Сбор банок во время вождения Стремглава G-99 (транспорт Р.А.З.Г.О.Н.)"
L["garbage-day"] = "Сбор мусора"

-- config
L["GENERAL_OPTIONS"] = "Общие настройки"
L["ENABLE_TRIGGERS"] = "Включить автоматические триггеры"
L["ENABLE_TRIGGERS_DESC"] = "Разрешить Счётчику автоматически активировать задачи на основе игровых условий."
L["ENABLE_TRACKING"] = "Включить отслеживание задач"
L["ENABLE_TRACKING_DESC"] = "Разрешить отображение и обновление активных задач в панели отслеживания."
L["DEBUG_MODE"] = "Режим отладки"
L["DEBUG_MODE_DESC"] = "Включает/выключает режим отладки для Счётчика."

-- rules
L["ManualRulesFixed"] = "Ручные правила без параметра 'count' исправлены."
L["TemplatesReapplied"] = "Шаблоны переприменены к %d существующим задачам."
L["ManualRuleFixedDebug"] = "Задача '%s': ручное правило %d не имело действительного 'count', установлено в %d (цель=%s)"
