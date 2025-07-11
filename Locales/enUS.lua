-- Author      : Manel
-- Create Date : 15/06/2025 13:09:58

local L = LibStub("AceLocale-3.0"):NewLocale("CounterIt", "enUS", true)

if not L then return end

L["TITLE"] = "Counter-It"
L["TASK_MANAGER_TITLE"] = "Task Manager"
L["ACTIVE_MONITOR_TITLE"] = "Active Tasks"
L["ADD_TASK"] = "Add Task"
L["FROM_TEMPLATE"] = "Add From Template"  -- fostot
L["OPEN_MONITOR"] = "Open Monitor"
L["EXPORT_IMPORT"] = "Export / Import"
L["ACTIVATE"] = "Activate"
L["EDIT"] = "Edit"
L["DELETE"] = "Delete"
L["TASK_DESCRIPTION"] = "Description"
L["TASK_GOAL"] = "Goal"
L["TASK_ICON"] = "Icon"
L["SAVE"] = "Save"
L["CANCEL"] = "Cancel"
L["CLOSE"] = "Close"
L["RULES"] = "Rules"
L["NEW_RULE"] = "New Rule"
L["TYPE"] = "Type"
L["ID"] = "ID"
L["MINIMAP_LEFT"] = "Left Click: Open paused tasks manager"
L["MINIMAP_RIGHT"] = "Right Click: Open active tasks monitor"
L["LOADED_MSG"] = "Counter-It loaded. Use /counterit to manage tasks or /cit to monitor."

L["MIGRATION_CLEANED_GLOBAL_PROGRESS"] = "Global task progress has been cleared to enable per-character tracking."

-- util
L["IMPORT_INVALID"] = "Invalid text."
L["IMPORT_DECOMPRESS_FAIL"] = "Could not decompress the text."
L["IMPORT_DESERIALIZE_FAIL"] = "Failed to interpret the data."
L["IMPORT_SUCCESS"] = "Tasks imported successfully."
L["EXPORT_IMPORT_TASKS"] = "Export / Import tasks"
L["COPY_PASTE_TASKS_DATA"] = "Copy or paste task data"
L["TASKS_TEXT"] = "Tasks text"
L["EXPORT"] = "Export"
L["IMPORT"] = "Import"

-- ui
L["TITLE_TASK_MANAGER"] = "Counter-It: Task Manager"
L["STATUSTEXT_TASK_MANAGER"] = "Manage your custom tasks"

L["TASKS_DEFINED"] = "DEFINED TASKS"

L["EDIT_TASK"] = "Edit Task"
L["NEW_TASK"] = "New Task"
L["DEFINE_TASK_DETAILS"] = "Define the task details"

L["CONFIRM_DELETE_TASK"] = "Permanently delete the task '%s'?"
L["YES"] = "Yes"
L["CANCEL"] = "Cancel"

L["ADD_TO_FAVORITES"] = "Add to Favorites"
L["REMOVE_FROM_FAVORITES"] = "Remove from Favorites"
L["SHOW_ONLY_FAVORITES"] = "Show Only Favorites"

L["TASK_SAVE_MISSING"] = "Missing required fields."
L["TASK_SAVED"] = "Task saved: %s"
L["TASK_PAUSED"] = "Paused Tasks"
L["TASK_OBJECTIVE"] = "%s (Objective: %d)"
L["TASK_TOOLTIP_OBJECTIVE"] = "Task: %s \nObjective: %d"
L["SELECT_ICON"] = "Select Icon" 
L["EDIT_RULE"] = "Edit Rule"
L["STATUSTEXT_NEW_RULE"] = "Define the rule details"

L["TASK_OBJECTIVE_LABEL"] = "Objective"
L["TASK_ICON_LABEL"] = "Icon (optional)"
L["RULE_TYPE_LABEL"] = "Rule type"
L["RULE_ID_LABEL"] = "ID (optional for manual)"

L["RULE_MANUAL"] = "Manual counter"
L["RULE_QUEST"] = "Complete quest (questID)"
L["RULE_ITEM"] = "Obtain item (itemID)"
L["RULE_SPELL"] = "Cast spell (spellID)"
L["RULE_PETCAPTURE"] = "Capture battle pets"

L["RULE_SPELL_NOT_FOUND"] = "|cffff0000Spell not found|r"
L["RULE_SPELLID_NOT_VALID"] = "|cffff0000ID not valid|r"

L["RULE_ROLE_LABEL"] = "Role"
L["ROLE_COMPLETION"] = "Task Completion"
L["ROLE_AUTO_COUNT"] = "Auto-Counting"
L["ROLE_ACTIVATION"] = "Activation"
L["NO_ROLE"] = "No Role"

L["SCROLLFRAME_DEBUG"] = "scrollFrame = %s"

-- events
L["SIMULATE_PET"] = "Simulated pet capture event."
L["SPELLCAST_ID"] = "CheckSpellCast; %s"
L["SPELLCAST_NAME"] = "CheckSpellCast; %s"
L["SPELLCAST_MATCH"] = "CheckSpellCast; match; %s"

-- template
L["TASK_TEMPLATE_CREATED"] = "Task created from template: %s"
L["TEMPLATE_NOT_FOUND"] = "Template not found: %s"
L["TITLE_SELECT_TEMPLATE"] = "Select Template"
L["STATUSTEXT_SELECT_TEMPLATE"] = "Choose a template to create a task"

L["side-with-a-cartel"] = "Have chosen which Cartel you will align with for that week"
L["ship-right"] = "Perform 10 ship jobs"
L["reclaimed-scrap"] = "Gathered 100 empty Kaja' Cola cans from S.C.R.A.P piles"
L["side-gig"] = "Have completed a Side Gig. Side Gigs are available in the main Transportation Hub"
L["war-mode-violence"] = "Defeat five enemy players in War Mode in Undermine"
L["go-fish"] = "Go fish in Undermine"
L["gotta-catch-at-least-a-few"] = "Captura 5 mascotas salvajes"
L["rare-rivals"] = "Derrota a 3 NPCs raros de Minahonda"
L["clean-the-sidestreets"] = "complete the Sidestreet Sluice Delve"
L["time-to-vacate"] = "Excavation Site 9 Delve completed"
L["desire-to-d-r-i-v-e"] = "Complete two races in Undermine"
L["kaja-cruising"] = "Collecting cans while driving the G-99 Breakneck (D.R.I.V.E. mount)"
L["garbage-day"] = "Reclaimed Scrap"

-- config
L["GENERAL_OPTIONS"] = "General Options"
L["ENABLE_TRIGGERS"] = "Enable automatic triggers"
L["ENABLE_TRIGGERS_DESC"] = "Allow Counter-It to activate tasks automatically based on in-game conditions."
L["ENABLE_TRACKING"] = "Enable task tracking"
L["ENABLE_TRACKING_DESC"] = "Allow active tasks to be displayed and updated in the tracking panel."
L["DEBUG_MODE"] = "Debugging (debugMode)"
L["DEBUG_MODE_DESC"] = "Toggle debug mode for Counter-It."

-- rules
L["ManualRulesFixed"] = "Manual rules without 'count' parameter have been fixed."
L["TemplatesReapplied"] = "Templates reapplied to %d existing tasks."
L["ManualRuleFixedDebug"] = "Task '%s': manual rule %d had no valid 'count', set to %d (goal=%s)"

