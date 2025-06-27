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
  elseif rule.type == "quest" and rule.questID and type(rule.questID) == "number" then
    rule.completed = C_QuestLog.IsQuestFlaggedCompleted(rule.questID) or C_QuestLog.ReadyForTurnIn(tonumber(rule.questID))
  elseif rule.type == "item" and rule.itemID then
    rule.completed = self:HasItem(rule.itemID)
  elseif rule.type == "spell" and rule.spellID then
    local casted = self:GetSpellCastCount(rule.spellID)
    rule.completed = casted >= (rule.count or 1)
  end
  return rule.completed
end

--[[ Evaluar si toda la tarea está completa
function CounterIt:EvaluateTaskCompletion(name, task)
  if not task.rules then
    task.completed = false
    return
  end

  local allCompleted = true
  for _, rule in ipairs(task.rules) do
    if not rule.completed then
      allCompleted = false
      if task.completed then
          self:Debug("EvaluateTaskCompletion; fail", name, task.type)
      end
      break
    end
  end
  task.completed = allCompleted
end
]]--

function CounterIt:CheckRuleCompletion(rule, task)
  local progress = rule.progress or 0
  local required = rule.count or task.goal

  if rule.type == "spell" or rule.type == "manual" then
    if progress >= required then
      rule.completed = true
    end
  elseif rule.type == "quest" and rule.questID then
    if C_QuestLog.IsQuestFlaggedCompleted(rule.questID) or C_QuestLog.ReadyForTurnIn(rule.questID) then
      rule.completed = true
    end
  end
end

-- Evalúa si una tarea debe considerarse completada
function CounterIt:EvaluateTaskCompletion(name, task)
  if not task.rules then
    task.completed = false
    return
  end

  local hasCompletionRules = false      -- ¿Hay reglas marcadas como 'completion'?
  local allCompletionPassed = true      -- ¿Están todas esas reglas completadas?

  -- Recorremos las reglas buscando solo aquellas con role = "completion"
  for _, rule in ipairs(task.rules) do
    if rule.role == "completion" then
      hasCompletionRules = true
      if not rule.completed then
        allCompletionPassed = false     -- Una no completada => no se puede marcar la tarea como terminada
      end
    end
  end

  if hasCompletionRules then
    -- Si hay reglas específicas de finalización, usamos solo esas para decidir
    task.completed = allCompletionPassed
  else
    -- Si no hay reglas de 'completion', aplicamos la lógica anterior (todas deben estar completas)
    local allRulesComplete = true
    for _, rule in ipairs(task.rules) do
      if not rule.completed then
        allRulesComplete = false
        self:Debug("EvaluateTaskCompletion; fail", name, rule.type)
        break
      end
    end
    task.completed = allRulesComplete
  end
end

-- Actualizar el progreso de una tarea (contadores, reglas, estado)
function CounterIt:UpdateTaskProgress(name, task, reset)
  if reset then
    task.completed = false
  end
  if task.rules then
    for _, rule in ipairs(task.rules) do
      self:EvaluateRule(name, task, rule)
    end
  end
  self:EvaluateTaskCompletion(name, task)
  return task.completed
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
  if not task then return -1 end

  local name = task.description
  local count = getCounters()[name] or 0

  if rule.type == "manual" or rule.type == "petcapture" then
    return count
  elseif rule.type == "quest" then
    return (C_QuestLog.ReadyForTurnIn(rule.questID) or C_QuestLog.IsQuestFlaggedCompleted(rule.questID)) and task.goal or 0
  elseif rule.type == "item" then
    return self:HasItem(rule.itemID) and task.goal or 0
  elseif rule.type == "spell" then
    return self:GetSpellCastCount(rule.spellID) or 0
  end
  return 0
end

-- Obtener el mayor progreso entre todas las reglas
function CounterIt:GetTaskProgress(task)
  if not task then return -1 end

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

