-- events.lua
local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")
local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt")

-- Almacén interno de lanzamientos de hechizos 
local spellCasts = {}
local pendingSpellName
local lastInventory = {}
local hasScannedInventory = false
local processedItems = {}

-----------------------------------------------------
-- REGISTRO DE EVENTOS USANDO ACEEVENT
-----------------------------------------------------

function CounterIt:RegisterRelevantEvents()
  self:RegisterEvent("PET_BATTLE_CAPTURED")

  self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
  self:RegisterEvent("UNIT_SPELLCAST_SENT")
  self:RegisterEvent("UNIT_SPELLCAST_STOP")

  self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
  self:RegisterEvent("QUEST_WATCH_UPDATE")
  self:RegisterEvent("QUEST_LOG_UPDATE")
  self:RegisterEvent("QUEST_ACCEPTED")

  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

  self:RegisterEvent("UNIT_INVENTORY_CHANGED")
  self:RegisterEvent("BAG_UPDATE_DELAYED")

  self:RegisterEvent("ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED")
end

function CounterIt:OnEnable()
  if self._eventsRegistered then
    self:Debug("CounterIt:OnEnable")
    return
  end

  self._eventsRegistered = true

  if self.db.profile.enableTriggers then
    self:RegisterRelevantEvents()
  end

  self:RegisterEvent("PLAYER_ENTERING_WORLD")

--  self:CheckTriggersFromActiveQuests()

  self:InitConfig()
end

function CounterIt:UnregisterRelevantEvents()
  self:UnregisterEvent("PET_BATTLE_CAPTURED")

  self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
  self:UnregisterEvent("UNIT_SPELLCAST_SENT")
  self:UnregisterEvent("UNIT_SPELLCAST_STOP")

  self:UnregisterEvent("UNIT_QUEST_LOG_CHANGED")
  self:UnregisterEvent("QUEST_WATCH_UPDATE")
  self:UnregisterEvent("QUEST_LOG_UPDATE")
  self:UnregisterEvent("QUEST_ACCEPTED")

  self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

  self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
  self:UnregisterEvent("BAG_UPDATE_DELAYED")

  self:UnregisterEvent("ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED")
end

function CounterIt:OnDisable()
  if self._eventsRegistered then
    self:UnregisterRelevantEvents()

    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
  end

  self._eventsRegistered = false
end

-----------------------------------------------------
-- HANDLERS
-----------------------------------------------------

function CounterIt:PET_BATTLE_CAPTURED()
  self:HandlePetBattleCaptured()
end

--[[
  https://warcraft.wiki.gg/wiki/UNIT_SPELLCAST_SENT
  Payload
	event
		string : UNIT_SPELLCAST_SENT
	unit
		string : UnitId - Only fires for "player"
	target
		string : UnitId
	castGUID
		string : GUID - e.g. for  [Flare] (Spell ID 1543) "Cast-3-3783-1-7-1543-000197DD84"
	spellID
		number
  ]]--
function CounterIt:UNIT_SPELLCAST_SENT(event, unit, target, castGUID, spellID)
  self:Debug("UNIT_SPELLCAST_SENT; u;", unit, "t;", target, "c;", castGUID, "s;", spellID)
  if unit == "player" then
    self:CheckSpellCast(spellID, target)
  end
end

--[[
  https://warcraft.wiki.gg/wiki/UNIT_SPELLCAST_SUCCEEDED
  Payload
    unitTarget
        string : UnitId
    castGUID
        string
    spellID
        number
  ]]--
function CounterIt:UNIT_SPELLCAST_SUCCEEDED(unitTarget, castGUID, spellID)
  if unitTarget == "player" then
    spellCasts[spellID] = (spellCasts[spellID] or 0) + 1
    self:CheckSpellCast(spellID, "")
  end
end

--[[
  https://warcraft.wiki.gg/wiki/UNIT_SPELLCAST_STOP
  Payload
    unitTarget
        string : UnitId
    castGUID
        string
    spellID
        number
  ]]--
function CounterIt:UNIT_SPELLCAST_STOP(unitTarget, castGUID, spellID)
  if unitTarget == "player" then
    self:CheckSpellCast(spellID, "")
  end
end

--[[
  https://warcraft.wiki.gg/wiki/PLAYER_ENTERING_WORLD
  Payload
    isInitialLogin
        boolean - True whenever the character logs in. This includes logging out to character select and then logging in again.
    isReloadingUi
        boolean
  ]]--
function CounterIt:PLAYER_ENTERING_WORLD(isLogin, isReload)
  if self._enteredWorldTime and (GetTime() - self._enteredWorldTime < 5) then
    --self:Debug("Ignorando llamada duplicada de PLAYER_ENTERING_WORLD")
    return
  end
  self._enteredWorldTime = GetTime()
  
  if isLogin or isReload then
    self:Debug("PLAYER_ENTERING_WORLD")
    --self:Debug("loaded the UI")
    self:CheckAutoTriggersOnLogin()
    if not hasScannedInventory then
      self:ScanInventoryForAutoTriggers()
      hasScannedInventory = true
    end
    self:CheckQuestRulesForActiveTasks()
  else
  --self:Debug("zoned between map instances")
  end
end

--[[
  https://warcraft.wiki.gg/wiki/UNIT_QUEST_LOG_CHANGED
  Payload
    unitTarget
        string : UnitId
  ]]--
function CounterIt:UNIT_QUEST_LOG_CHANGED(unitTarget)
  self:Debug("UNIT_QUEST_LOG_CHANGED")
  self:CheckQuestRulesForActiveTasks()
end

--[[
  https://warcraft.wiki.gg/wiki/QUEST_WATCH_UPDATE
  Payload
    questID
        number
  ]]--
function CounterIt:QUEST_WATCH_UPDATE(questID)
  self:Debug("QUEST_WATCH_UPDATE")
  self:CheckQuestRulesForActiveTasks()
  self:EvaluateQuestRules(questID)
end

--[[
  https://warcraft.wiki.gg/wiki/QUEST_LOG_UPDATE
  ]]--
function CounterIt:QUEST_LOG_UPDATE()
  self:Debug("QUEST_LOG_UPDATE")
  self:CheckQuestRulesForActiveTasks()
end

--[[
  https://warcraft.wiki.gg/wiki/QUEST_ACCEPTED
  QUEST_ACCEPTED: [questLogIndex,] questId
  Payload
	questLogIndex
		number - WoW Icon update.png Classic only. Index of the quest in the quest log. You may pass this to GetQuestLogTitle() for information about the accepted quest.
	questID
		number - QuestID of the accepted quest.
  ]]--
function CounterIt:QUEST_ACCEPTED(questID)
  local taskOrTemplate = self.AutoTrigger and self.AutoTrigger:GetTaskFromEvent("QUEST_ACCEPTED", questID)
  if taskOrTemplate then
    self:HandleAutoTrigger(taskOrTemplate)
  end
  self:EvaluateQuestRules(questID)
end

--[[
  https://warcraft.wiki.gg/wiki/BAG_UPDATE_DELAYED
  ]]--
function CounterIt:BAG_UPDATE_DELAYED()
  self.processedItemTriggers = self.processedItemTriggers or {}

  for itemID, _ in pairs(self.processedItemTriggers) do
    if not self:HasItem(itemID) then
      self:Debug("ItemID", itemID, "ya no están las bolsas. Trigger reiniciado.")
      self.processedItemTriggers[itemID] = nil
    end
  end

  -- Lógica de auto-pausado
  local bRefresh = self:AutoPauseTasksByInventory()
  if bRefresh then
    self:RenderActiveTasks()
  end
end

--[[
  https://warcraft.wiki.gg/wiki/COMBAT_LOG_EVENT_UNFILTERED
    timestamp
        number - Unix Time in seconds with milliseconds precision, for example 1555749627.861. Similar to time() and can be passed as the second argument of date().
    subevent
        string - The combat log event, for example SPELL_DAMAGE.
    hideCaster
        boolean - Returns true if the source unit is hidden (an empty string).[1]
    guid
        string - Globally unique identifier for units (NPCs, players, pets, etc), for example "Creature-0-3113-0-47-94-00003AD5D7".
    name
        string - Name of the unit.
    flags
        number - Contains the flag bits for a unit's type, controller, reaction and affiliation. For example 68168 (0x10A48): Unit is the current target, is an NPC, the controller is an NPC, reaction is hostile and affiliation is outsider.
    raidFlags
        number - Contains the raid flag bits for a unit's raid target icon. For example 64 (0x40): Unit is marked with cross.
  
  ]]--
function CounterIt:COMBAT_LOG_EVENT_UNFILTERED()
  local _, subevent, _, _, _, _, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
  if subevent == "SPELL_CAST_SUCCESS" then
    self:EvaluateSpellRules(spellID, spellName)
  end
end

--[[
  https://warcraft.wiki.gg/wiki/UNIT_INVENTORY_CHANGED
  
  Payload
	unitTarget
		string : UnitId
  ]]--
function CounterIt:UNIT_INVENTORY_CHANGED(unitTarget)
  self:Debug("UNIT_INVENTORY_CHANGED")
  if unitTarget and unitTarget ~= "player" then return end
  if unitTarget == "player" then
    self:ScanInventoryForNewItems()
  end
end

--[[
  https://warcraft.wiki.gg/wiki/ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED
  ]]--
function CounterIt:ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED()
  self:Debug("ACCOUNT_CHARACTER_CURRENCY_DATA_RECEIVED")
  self:CheckQuestRulesForActiveTasks()
end

-----------------------------------------------------
-- FUNCIONES DE EVALUACIÓN DE REGLAS
-----------------------------------------------------


function CounterIt:CheckSpellCast(spellID, target)
  if spellID then
    self:Debug(format(L["SPELLCAST_ID"], tostring(spellID or "n/a")))
  end
  if target then
    self:Debug(format(L["SPELLCAST_NAME"], tostring(target or "n/a")))
  end
  local needRefresh = false
  local counters = self.charCounters()
  for taskID, task in pairs(self.globalTasks()) do
    if task.active and not task.completed and task.rules then
      for _, rule in ipairs(task.rules) do
        if rule.type == "spell" then
          local match = false
          if tonumber(rule.spellID) and tonumber(spellID) and tonumber(rule.spellID) == tonumber(spellID) then
            match = true
          end

          if match then
            rule.progress = (rule.progress or 0) + 1
            counters[taskID] = (counters[taskID] or 0) + 1
            self:CheckRuleCompletion(rule, task)
            self:EvaluateTaskCompletion(taskID, task)
            self:Debug( format(L["SPELLCAST_MATCH"], tostring(spellID)), tonumber(counters[taskID]))
            needRefresh = true
          end
        end
      end
    end
  end
  if needRefresh then
    self:RenderActiveTasks()
  end
end

function CounterIt:EvaluateSpellRules(spellID, target)
  self:CheckSpellCast(spellID, target)
end

function CounterIt:EvaluateQuestRules(questID)
  local counters = self.charCounters()
  for taskID, task in pairs(self.globalTasks()) do
    if task.active and not task.completed and task.rules then
      for _, rule in ipairs(task.rules) do
        if rule.type == "quest" then
          if tonumber(rule.questID) and tonumber(questID) and tonumber(rule.questID) == tonumber(questID) then
            rule.progress = (rule.progress or 0) + 1
            counters[taskID] = (counters[taskID] or 0) + 1
            self:EvaluateTaskCompletion(taskID, task)
            self:Debug(format(L["QUEST_MATCH"], tostring(questID)))
          end
        end
      end
    end
  end
  self:RenderActiveTasks()  
end

function CounterIt:HandlePetBattleCaptured()
  if not self:IsTrackingEnabled() then return end

  local counters = self.charCounters()
  for taskID, task in pairs(self.globalTasks()) do
    if task.active and task.rules then
      for _, rule in ipairs(task.rules) do
        if rule.type == "petcapture" and not rule.completed then
          counters[taskID] = (counters[taskID] or 0) + 1
          self:EvaluateRule(taskID, task, rule)
        end
      end
      self:UpdateTaskProgress(taskID, task)
    end
  end
  self:RenderActiveTasks()
end

function CounterIt:ScanInventoryForNewItems()
  Print("ScanInventoryForNewItems");
  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local itemID = GetContainerItemID(bag, slot)
      local key = bag..":"..slot
      if itemID and lastInventory[key] ~= itemID then
        self:OnItemReceived(itemID, 1)
      end
      lastInventory[key] = itemID
    end
  end
end

function CounterIt:OnItemReceived(itemID, count)
  Print("OnItemReceived", itemID, count)
  -- Regla global primero (activación automática)
  local templates = self.AutoTrigger and self.AutoTrigger:GetTaskFromEvent("ITEM_RECEIVED", itemID)
  if templates then
    for _, templateID in ipairs(templates) do    
      self:HandleAutoTrigger(templateID)
    end
  end

  -- Evaluación de tareas activas con regla "item"
  for taskID, task in pairs(self.globalTasks()) do
    if task.active and not task.completed and task.rules then
      for _, rule in ipairs(task.rules) do
        if rule.type == "item" and tonumber(rule.itemID) == itemID then
          rule.progress = (rule.progress or 0) + count
          self:EvaluateTaskCompletion(taskID, task)
          self:Print(format("Item %d recibido para tarea: %s", itemID, taskID))
        end
      end
    end
  end
  self:RenderActiveTasks()
end

function CounterIt:CheckAutoTriggersOnLogin()
  if not self.AutoTrigger or not self.AutoTrigger.Rules then return end
  local questCount = 0
  local rules = self.AutoTrigger.Rules.QUEST_ACCEPTED or {}
  for questID, templateID in pairs(rules) do
    if C_QuestLog.IsOnQuest(questID) 
      or C_QuestLog.ReadyForTurnIn(questID) 
      or C_QuestLog.IsQuestFlaggedCompleted(questID) then
        questCount = questCount + 1
        self:HandleAutoTrigger(templateID)
    end
  end
  if questCount > 0 then
    self:Debug('CheckAutoTriggersOnLogin', questCount)
  end
end

function CounterIt:CheckTriggersFromActiveQuests()
  if not self.AutoTrigger or not self.AutoTrigger.Rules.QUEST_ACCEPTED then return end

  local questCount = 0
  for i = 1, C_QuestLog.GetNumQuestLogEntries() do
    local info = C_QuestLog.GetInfo(i)
    if info and not info.isHeader then
      questCount = questCount + 1
      local questID = info.questID
      local templateID = self.AutoTrigger.Rules.QUEST_ACCEPTED[questID]
      if templateID then
        if type(templateID) == "table" then
          for _, id in ipairs(templateID) do
            self:HandleAutoTrigger(id)
          end
        else
          self:HandleAutoTrigger(templateID)
        end
      end
    end
  end
  if questCount > 0 then
    self:Debug('CheckTriggersFromActiveQuests', questCount)
  end
end

function CounterIt:CheckQuestRulesForActiveTasks()
  if not self:IsTrackingEnabled() then return end

  local tasks = self.globalTasks()
  local questCount = 0
  for taskID, task in pairs(tasks) do
    if task.active and task.rules then
      for _, rule in ipairs(task.rules) do
        if rule.type == "quest" and rule.questID then
          if C_QuestLog.ReadyForTurnIn(rule.questID) or C_QuestLog.IsQuestFlaggedCompleted(rule.questID) then
            questCount = questCount + 1
            rule.progress = rule.count or 1
            self:EvaluateRule(taskID, task, rule)
          end
        end
      end
      self:EvaluateTaskCompletion(taskID, task)
    end
  end
  if questCount > 0 then
    self:Debug('CheckQuestRulesForActiveTasks', questCount)
  end
end

-- Escanear inventario al entrar en el mundo y activar tareas por plantillas si hay ítems presentes
function CounterIt:ScanInventoryForAutoTriggers()
  if not self:IsTrackingEnabled() then return end

  if not self.AutoTrigger or not self.AutoTrigger.Rules["ITEM_RECEIVED"] then return end
  self:Debug("ScanInventoryForAutoTriggers")

  self.processedItemTriggers = self.processedItemTriggers or {}

  for itemID, _ in pairs(self.AutoTrigger.Rules["ITEM_RECEIVED"]) do
    self:Debug("ITEM_RECEIVED", itemID)
    if self:HasItem(itemID) and not self.processedItemTriggers[itemID] then
      local templates = self.AutoTrigger:GetTaskFromEvent("ITEM_RECEIVED", itemID)
      if templates then
        for _, templateID in ipairs(templates) do
          self:HandleAutoTrigger(templateID)
        end
        
        self.processedItemTriggers[itemID] = true
      end
    end
  end
end

function CounterIt:UpdateTasks()
  local tasks = self.globalTasks()
  local taskCount = 0
  for taskID, task in pairs(tasks) do
    local bCompleted = self:UpdateTaskProgress(taskID, task, false)
    if bCompleted then
      taskCount = taskCount + 1
    end
  end
  if taskCount > 0 then
    self:Debug('UpdateTasks', taskCount)
  end
end

--- Pausa automáticamente las tareas activas si pierdes el objeto requerido.
---
---@return boolean  -- true si alguna tarea ha sido pausada y es necesario refrescar la UI, false si no hubo cambios
function CounterIt:AutoPauseTasksByInventory()
  local bDone = false
  for taskID, task in pairs(self.globalTasks()) do
    if task.active and not task.completed and task.rules then
      for _, rule in ipairs(task.rules) do
        if rule.type == "item" and rule.itemID then
          if not self:HasItem(rule.itemID) then
            task.active = false
            self:Debug("Tarea '"..taskID.."' pausada automáticamente: objeto "..rule.itemID.." no están el inventario.")
            -- Solo pausar la tarea una vez y salir del bucle de reglas
            bDone = true 
            break
          end
        end
      end
    end
  end
  return bDone
end

-----------------------------------------------------
-- SLASH COMMANDS DE DEPURACIÓN
-----------------------------------------------------

SLASH_CITSIMULATE1 = "/citsim"
SlashCmdList["CITSIMULATE"] = function()
  CounterIt:HandlePetBattleCaptured()
  print(L["SIMULATE_PET"])
end

SLASH_CITUPDATE1 = "/citupdate"
SlashCmdList["CITSIMULATE"] = function()
  CounterIt:UpdateTasks()
  print("SLASH_CITUPDATE1")
end

-- Obtener cantidad de veces que se lanzó un hechizo
function CounterIt:GetSpellCastCount(spellID)
  return spellCasts[spellID] or 0
end

-----------------------------------------------------
-- COMANDO PARA SIMULAR CAPTURA DE MASCOTA
-----------------------------------------------------

SLASH_CITSIMULATE1 = "/citsim"
SlashCmdList["CITSIMULATE"] = function()
  CounterIt:HandlePetBattleCaptured()
  print(L["SIMULATE_PET"])
end

-- events.lua -- fin del archivo

--[[

Kaja'Cruising

PLAYER_ENTERING_WORLD, 
UNIT_QUEST_LOG_CHANGED, 
QUEST_WATCH_UPDATE, 
QUEST_LOG_UPDATE, 
QUEST_ACCEPTED

function(t)
    return t[3] and (t[1] or t[2]) and not t[4] 
end

function t1()
    if aura_env.config.turbo and C_QuestLog.IsOnQuest(87306) == true then
        return true
    end
end

function t2()
    if aura_env.config.turbo and (C_QuestLog.ReadyForTurnIn(87306) or C_QuestLog.IsQuestFlaggedCompleted(87306)) == true then
        return true
    end
end

function t3()
   -- id:235053
   -- contar los objetos > 0 
end

function t4()
    local questIDs = {
        86923, -- Go Fish
        86920, -- War Mode Violence
        86924, -- Gotta Catch at Least a Few
        87304, -- Time to Vacate
        87303, -- Clean the Sidestreets
        86917, -- Ship Right
        87302, -- Rare Rival
        86918, -- Reclaimed Scrap
        86919, -- Side Gig
        87305, -- Desire to D.R.I.V.E.
        87306, -- Kaja Cruising
        87307, -- Garbage Day
        86915, -- Side with Cartel
    }
    
    local completedCount = 0
    for _, questID in ipairs(questIDs) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
            completedCount = completedCount + 1
        end
    end
    
    return completedCount >= 4
end

]]--
