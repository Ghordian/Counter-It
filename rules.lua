-- Lógica de validación de reglas de tareas

local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")

-- Obtener acceso a las variables compartidas
local function getTasks() return CounterIt.globalTasks() end
local function getCounters() return CounterIt.charCounters() end

-- Evaluar una regla individual
function CounterIt:EvaluateRule(name, task, rule)
  if rule.type == "manual" or rule.type == "petcapture" then
    local count = getCounters()[name] or 0
    rule.completed = (count >= rule.count)
  elseif rule.type == "quest" and rule.questID then
    rule.completed = C_QuestLog.ReadyForTurnIn(rule.questID) or C_QuestLog.IsQuestFlaggedCompleted(rule.questID)
  elseif rule.type == "item" and rule.itemID then
    rule.completed = self:HasItem(rule.itemID)
  elseif rule.type == "spell" and rule.spellID then
    local casted = self:GetSpellCastCount(rule.spellID)
    rule.completed = casted >= (rule.count or 1)
  end
end

-- Evaluar si toda la tarea está completa
function CounterIt:EvaluateTaskCompletion(name, task)
  if not task.rules then
    task.completed = false
    return
  end

  local allCompleted = true
  for _, rule in ipairs(task.rules) do
    if not rule.completed then
      allCompleted = false
      break
    end
  end
  task.completed = allCompleted
end

-- Actualizar el progreso de una tarea (contadores, reglas, estado)
function CounterIt:UpdateTaskProgress(name, task, reset)
  if reset then
    task.completed = false
  end
  if task.rules then
    for _, rule in ipairs(task.rules) do
      self:EvaluateRule(name, task, rule)
      if reset then
          rule.completed = false
      end
    end
  end
  self:EvaluateTaskCompletion(name, task)
end

-- Agregar regla de tipo misión
function CounterIt:AddQuestRuleToTask(task, questID)
  if not task.rules then task.rules = {} end
  table.insert(task.rules, {
    type = "quest",
    questID = questID,
    completed = false
  })
end

-- Agregar regla de tipo objeto
function CounterIt:AddItemRuleToTask(task, itemID, count)
  if not task.rules then task.rules = {} end
  table.insert(task.rules, {
    type = "item",
    itemID = itemID,
    count = count or 1,
    completed = false
  })
end

-- Agregar regla de captura de mascotas
function CounterIt:AddPetCaptureRuleToTask(task)
  if not task.rules then task.rules = {} end
  table.insert(task.rules, {
    type = "petcapture",
    count = 5,
    completed = false
  })
end

-- Obtener progreso de una regla
function CounterIt:GetRuleProgress(task, rule)
  local name = task.description
  local count = getCounters()[name] or 0

  if rule.type == "manual" or rule.type == "petcapture" then
    return count
  elseif rule.type == "quest" then
    return C_QuestLog.ReadyForTurnIn(rule.questID) or C_QuestLog.IsQuestFlaggedCompleted(rule.questID) and task.goal or 0
  elseif rule.type == "item" then
    return self:HasItem(rule.itemID) and task.goal or 0
  elseif rule.type == "spell" then
    return self:GetSpellCastCount(rule.spellID) or 0
  end
  return 0
end

-- Obtener el mayor progreso entre todas las reglas
function CounterIt:GetTaskProgress(task)
  local maxProgress = 0
  for _, rule in ipairs(task.rules or {}) do
    local current = self:GetRuleProgress(task, rule)
    if current > maxProgress then
      maxProgress = current
    end
  end
  return maxProgress
end

function CounterIt:IsTemplate(id)
  return self.taskTemplates and self.taskTemplates[id] ~= nil
end

function CounterIt:TaskExists(id)
  return self.tasks and self.tasks[id] ~= nil
end

