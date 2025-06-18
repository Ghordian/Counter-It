-- events.lua
local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")
local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt")

-- Almacén interno de lanzamientos de hechizos
local spellCasts = {}
local pendingSpellName
local lastInventory = {}

-----------------------------------------------------
-- REGISTRO DE EVENTOS USANDO ACEEVENT
-----------------------------------------------------
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
function CounterIt:OnEnable()
  self:RegisterEvent("PET_BATTLE_CAPTURED")
  self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
  self:RegisterEvent("UNIT_SPELLCAST_SENT")
  self:RegisterEvent("UNIT_SPELLCAST_STOP")
  self:RegisterEvent("QUEST_ACCEPTED")
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  self:RegisterEvent("UNIT_INVENTORY_CHANGED") -- NUEVO

  self:CheckTriggersFromActiveQuests()

  self:CheckQuestRulesForActiveTasks()

  self:CheckAutoTriggersOnLogin()

end

-----------------------------------------------------
-- HANDLERS
-----------------------------------------------------

function CounterIt:PET_BATTLE_CAPTURED()
  self:HandlePetBattleCaptured()
end

function CounterIt:UNIT_SPELLCAST_SENT(unit, _, spellID, spellName)
  if unit == "player" then
    pendingSpellName = spellName
  end
end

function CounterIt:UNIT_SPELLCAST_SUCCEEDED(unit, _, spellID, spellName)
  if unit == "player" then
    spellCasts[spellID] = (spellCasts[spellID] or 0) + 1
    self:CheckSpellCast(spellID, spellName)
  end
end

function CounterIt:UNIT_SPELLCAST_STOP(unit)
  if unit == "player" then
    self:CheckSpellCast(nil, pendingSpellName)
    pendingSpellName = nil
  end
end

function CounterIt:QUEST_ACCEPTED(questID)
  local taskOrTemplate = self.AutoTrigger and self.AutoTrigger:GetTaskFromEvent("QUEST_ACCEPTED", questID)
  if taskOrTemplate then
    self:HandleAutoTrigger(taskOrTemplate)
  end
end

function CounterIt:COMBAT_LOG_EVENT_UNFILTERED()
  local _, subevent, _, _, _, _, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
  if subevent == "SPELL_CAST_SUCCESS" then
    self:EvaluateSpellRules(spellID, spellName)
  end
end

function CounterIt:UNIT_INVENTORY_CHANGED(unit)
  if unit == "player" then
    self:ScanInventoryForNewItems()
  end
end

-----------------------------------------------------
-- FUNCIONES DE EVALUACIÓN DE REGLAS
-----------------------------------------------------

function CounterIt:CheckSpellCast(spellID, spellName)
  if spellID then
  --  print(format(L["SPELLCAST_ID"], tostring(spellID or "n/a")))
  end
  if spellName then
  --  print(format(L["SPELLCAST_NAME"], tostring(spellName or "n/a")))
  end
--print("[DEBUG] Ejecutando CheckSpellCast con spellID:", spellID, "spellName:", spellName)
  if spellID then
  --  print(format(L["SPELLCAST_ID"], tostring(spellID or "n/a")))
  end
  if spellName then
  --  print(format(L["SPELLCAST_NAME"], tostring(spellName or "n/a")))
  end
  for name, task in pairs(self.globalTasks()) do
    if task.active and not task.completed and task.rules then
      for _, rule in ipairs(task.rules) do
        if rule.type == "spell" then
          local match = false
          if tonumber(rule.spellID) and tonumber(spellID) and tonumber(rule.spellID) == tonumber(spellID) then
            match = true
          elseif rule.spellName and spellName and rule.spellName == spellName then
            match = true
          end

          if match then
            rule.progress = (rule.progress or 0) + 1
            self:EvaluateTaskCompletion(name, task)
            print(format(L["SPELLCAST_MATCH"], tostring(name)))
          end
        end
      end
    end
  end
  self:RenderActiveTasks()
end

function CounterIt:EvaluateSpellRules(spellID, spellName)
  self:CheckSpellCast(spellID, spellName)
end

function CounterIt:HandlePetBattleCaptured()
  local counters = self.charCounters()
  for name, task in pairs(self.globalTasks()) do
    if task.active and task.rules then
      for _, rule in ipairs(task.rules) do
        if rule.type == "petcapture" and not rule.completed then
          counters[name] = (counters[name] or 0) + 1
          self:EvaluateRule(name, task, rule)
        end
      end
      self:UpdateTaskProgress(name, task)
    end
  end
  self:RenderActiveTasks()
end

function CounterIt:ScanInventoryForNewItems()
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
  -- Regla global primero (activación automática)
  local taskOrTemplate = self.AutoTrigger and self.AutoTrigger:GetTaskFromEvent("ITEM_RECEIVED", itemID)
  if taskOrTemplate then
    self:HandleAutoTrigger(taskOrTemplate)
  end

  -- Evaluación de tareas activas con regla "item"
  for name, task in pairs(self.globalTasks()) do
    if task.active and not task.completed and task.rules then
      for _, rule in ipairs(task.rules) do
        if rule.type == "item" and tonumber(rule.itemID) == itemID then
          rule.progress = (rule.progress or 0) + count
          self:EvaluateTaskCompletion(name, task)
          print(format("Item %d recibido para tarea: %s", itemID, name))
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
        if C_QuestLog.IsOnQuest(questID) or C_QuestLog.ReadyForTurnIn(questID) or C_QuestLog.IsQuestFlaggedCompleted(questID) then
            questCount = questCount + 1
            self:HandleAutoTrigger(templateID)
        end
    end
  if questCount > 0 then
    self:Print('CheckAutoTriggersOnLogin', questCount)
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
    self:Print('CheckTriggersFromActiveQuests', questCount)
  end
end

function CounterIt:CheckQuestRulesForActiveTasks()
  local tasks = self.globalTasks()
  local questCount = 0
  for name, task in pairs(tasks) do
    if task.active and task.rules then
      for _, rule in ipairs(task.rules) do
        if rule.type == "quest" and rule.questID and C_QuestLog.IsQuestFlaggedCompleted(rule.questID) then
          questCount = questCount + 1
          rule.progress = rule.count or 1
        end
      end
      self:EvaluateTaskCompletion(name, task)
    end
  end
  if questCount > 0 then
    self:Print('CheckQuestRulesForActiveTasks', questCount)
  end
end

-----------------------------------------------------
-- SLASH COMMANDS DE DEPURACIÓN
-----------------------------------------------------

SLASH_CITSIMULATE1 = "/citsim"
SlashCmdList["CITSIMULATE"] = function()
  CounterIt:HandlePetBattleCaptured()
  print(L["SIMULATE_PET"])
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
