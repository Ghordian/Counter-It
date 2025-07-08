-- rules.lua
-- Lógica de validación de reglas de tareas

local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")

local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt") 

-- Obtener acceso a las variables compartidas
local function getTasks() return CounterIt.globalTasks() end

--- Evalúa una regla individual y marca si está completada en el estado personal.
--- @param taskID string           -- ID de la tarea
--- @param task TaskData           -- Definición global de la tarea
--- @param idx number              -- Índice de la regla
function CounterIt:EvaluateRule(taskID, task, idx)
  local charTasks = self.charDb.char.tasks
  if not charTasks or not charTasks[taskID] then 
    return false 
  end

  if self.traceMode == true then
    self:Debug("EvaluateRule;", taskID, "rule;", idx)
  end

  local st = charTasks[taskID]
  local rule = task.rules and task.rules[idx]
  if not rule then return false end

  if not st.rulesProgress[idx] then
    st.rulesProgress[idx] = { progress = 0, completed = false }
  end
  local rp = st.rulesProgress[idx]
  local required = rule.count or task.goal or 1

  if rule.type == "manual" or rule.type == "petcapture" then
    rp.progress = st.progressManual or 0
    rp.completed = (rp.progress >= required)
  elseif rule.type == "quest" and rule.questID then
    rp.completed = C_QuestLog.IsQuestFlaggedCompleted(rule.questID) or C_QuestLog.ReadyForTurnIn(rule.questID)
  elseif rule.type == "item" and rule.itemID then
    rp.completed = self:HasItem(rule.itemID)
  elseif rule.type == "spell" and rule.role == "auto-count" then
    -- Aquí puedes añadir lógica para spells con progreso real si lo implementas
    -- rp.progress = ...
  end

  return rp.completed
end

--[[
--- Evalúa una regla individual y marca si está completada.
--- @param taskID string           -- ID de la tarea
--- @param task TaskData           -- Estructura de la tarea
--- @param rule RuleData           -- Estructura de la regla a evaluar
--- @return boolean                -- true si la regla está completada, false si no
function CounterIt:NoUsr_EvaluateRule(taskID, task, rule)
  if rule.type == "manual" or rule.type == "petcapture" then
    local count = getCounters()[taskID] or 0
    rule.progress = count
    rule.completed = (count >= rule.count or 1)
  elseif rule.type == "quest" and rule.questID and type(rule.questID) == "number" then
    rule.completed = C_QuestLog.IsQuestFlaggedCompleted(rule.questID) or C_QuestLog.ReadyForTurnIn(tonumber(rule.questID))
  elseif rule.type == "item" and rule.itemID then
    rule.completed = self:HasItem(rule.itemID)
  elseif rule.type == "spell" and rule.role == "auto-count" then -- and rule.spellID 
    local count = getCounters()[taskID] or 0
    rule.progress = count
  end
  return rule.completed
end
]]--

--- Comprueba si una regla está completada en el estado personal.
--- @param taskID string           -- ID de la tarea
--- @param task TaskData           -- Definición global de la tarea
--- @param idx number              -- Índice de la regla
function CounterIt:CheckRuleCompletion(taskID, task, idx)
  local charTasks = self.charDb.char.tasks
  if not charTasks or not charTasks[taskID] then return false end

  local st = charTasks[taskID]
  local rule = task.rules and task.rules[idx]
  if not rule then return false end
  local rp = st.rulesProgress[idx]
  local required = rule.count or task.goal or 1

  if rule.type == "spell" or rule.type == "manual" then
    if (rp.progress or 0) >= required then
      rp.completed = true
    end
  elseif rule.type == "quest" and rule.questID then
    if C_QuestLog.IsQuestFlaggedCompleted(rule.questID) or C_QuestLog.ReadyForTurnIn(rule.questID) then
      rp.completed = true
    end
  end
  return rp.completed
end

--[[
--- Comprueba si una regla está completada y actualiza su campo 'completed'.
--- @param rule RuleData           -- Regla a comprobar
--- @param task TaskData           -- Tarea asociada
function CounterIt:NoUsar_CheckRuleCompletion(rule, task)
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
]]--

--- Evalúa si una tarea debe considerarse completada en base a las reglas personales.
--- INTERNA: Solo debe llamarse desde UpdateTaskProgress.
--- @param st CharacterTaskState    -- Estado personal de la tarea
--- @param task TaskData            -- Definición global de la tarea
local function EvaluateTaskCompletion(st, task)
  if not task.rules then
    st.completed = false
    st.rulesProgress = nil
    return
  end

  if CounterIt.traceMode == true then
    CounterIt:Debug("EvaluateTaskCompletion;", task.id)
  end

  local hasCompletionRules = false
  local allCompletionPassed = true

  -- Reglas de "completion"
  for idx, rule in ipairs(task.rules) do
    if rule.role == "completion" then
      hasCompletionRules = true
      if not st.rulesProgress[idx] or not st.rulesProgress[idx].completed then
        allCompletionPassed = false
      end
    end
  end

  if hasCompletionRules then
    st.completed = allCompletionPassed
  else
    -- Si no hay reglas de 'completion', todas deben estar completas
    local allRulesComplete = true
    for idx, _ in ipairs(task.rules) do
      if not st.rulesProgress[idx] or not st.rulesProgress[idx].completed then
        allRulesComplete = false
        break
      end
    end
    st.completed = allRulesComplete
  end
end

--[[
--- Evalúa si una tarea debe considerarse completada en base a sus reglas.
--- @param taskID string           -- ID de la tarea
--- @param task TaskData           -- Estructura de la tarea
function CounterIt:NoUsar_EvaluateTaskCompletion(taskID, task)
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
        self:Debug("EvaluateTaskCompletion; fail", taskID, rule.type)
        break
      end
    end
    task.completed = allRulesComplete
  end
end
]]--

--- Actualiza el progreso y el estado de una tarea para el personaje actual.
--- 
--- Esta función centraliza toda la lógica de evaluación de reglas y comprobación
--- de completado de tareas. Internamente:
---   - Evalúa y actualiza el progreso de cada regla según el modelo por personaje.
---   - Llama a `EvaluateTaskCompletion` para actualizar el estado 'completed' de la tarea,
---     usando solo el estado personal (nunca la estructura global).
---
--- NOTA: No es necesario llamar manualmente a `EvaluateTaskCompletion` ni a las funciones
--- de evaluación de reglas desde otros módulos (UI, eventos, etc); basta con usar esta función.
---
--- @param taskID string               -- ID de la tarea
--- @param task TaskData               -- Definición global de la tarea
--- @param reset boolean|nil           -- Si es true, reinicia el estado personal de la tarea
--- @return boolean                    -- true si la tarea está completada tras actualizar, false si no
function CounterIt:UpdateTaskProgress(taskID, task, reset)
  local charTasks = self.charDb.char.tasks
  if not charTasks or not charTasks[taskID] then 
    return false 
  end

  if self.traceMode == true then
    self:Debug("UpdateTaskProgress;", taskID, "reset;", reset)
  end

  local st = charTasks[taskID]
  if reset then
    st.completed = false
    st.progressManual = 0
    for _, rp in pairs(st.rulesProgress or {}) do
      rp.progress = 0
      rp.completed = false
    end
  end

  -- Evalúa cada regla según el estado PERSONAL
  if task.rules then
    for idx, rule in ipairs(task.rules) do
      -- Inicializa el estado personal de la regla si no existe
      if not st.rulesProgress[idx] then
        st.rulesProgress[idx] = { progress = 0, completed = false }
      end
      local rp = st.rulesProgress[idx]
      local required = rule.count or task.goal or 1

      -- Evaluación según tipo de regla
      if rule.type == "manual" or rule.type == "petcapture" then
        rp.progress = st.progressManual or 0
        rp.completed = (rp.progress >= required)
      elseif rule.type == "quest" and rule.questID then
        rp.completed = C_QuestLog.IsQuestFlaggedCompleted(rule.questID) or C_QuestLog.ReadyForTurnIn(rule.questID)
      elseif rule.type == "item" and rule.itemID then
        rp.completed = self:HasItem(rule.itemID)
      elseif rule.type == "spell" and rule.role == "auto-count" then
        -- Si tienes progreso de spells por personaje, guárdalo aquí
        -- rp.progress = ... (si implementas progreso real)
      end
    end
  end

  EvaluateTaskCompletion(st, task)
  return st.completed
end

--[[
--- Actualiza el progreso de una tarea, evaluando reglas y estado.
--- @param taskID string           -- ID de la tarea
--- @param task TaskData           -- Tarea a actualizar
--- @param reset boolean|nil       -- Si es true, reinicia el estado de la tarea
--- @return boolean                -- true si la tarea está completada tras actualizar, false si no
function CounterIt:nousar_UpdateTaskProgress(taskID, task, reset)
--if not self:IsTrackingEnabled() then return end
  local debug = (taskID == "garbage-day") and reset
  if reset then
    task.completed = false
  end
  if task.rules then
    for _, rule in ipairs(task.rules) do
      if debug then
        self:Debug("EvaluateRule", rule)
      end
      self:EvaluateRule(taskID, task, rule)
    end
  end
  self:EvaluateTaskCompletion(taskID, task)
  return task.completed
end
]]--

--- Agrega una regla de tipo misión (quest) a una tarea.
--- @param task TaskData           -- Tarea a modificar
--- @param questID number          -- ID de la misión
function CounterIt:AddQuestRuleToTask(task, questID)
  if not task.rules then task.rules = {} end
  table.insert(task.rules, {
    type = "quest",
    questID = questID,
    completed = false
  })
end

--- Agrega una regla de tipo objeto (item) a una tarea.
--- @param task TaskData           -- Tarea a modificar
--- @param itemID number           -- ID del objeto
--- @param count number|nil        -- Cantidad necesaria (opcional)
function CounterIt:AddItemRuleToTask(task, itemID, count)
  if not task.rules then task.rules = {} end
  table.insert(task.rules, {
    type = "item",
    itemID = itemID,
    count = count or 1,
    completed = false
  })
end

--- Agrega una regla de tipo captura de mascotas a una tarea.
--- @param task TaskData           -- Tarea a modificar
function CounterIt:AddPetCaptureRuleToTask(task)
  if not task.rules then task.rules = {} end
  table.insert(task.rules, {
    type = "petcapture",
    count = 5,
    completed = false
  })
end

--- Obtiene el progreso actual de una regla concreta para el personaje.
--- @param taskID string           -- ID de la tarea
--- @param task TaskData           -- Definición global de la tarea
--- @param idx number              -- Índice de la regla
--- @return number                 -- Progreso numérico actual
function CounterIt:GetRuleProgress(taskID, task, idx)
  local charTasks = self.charDb.char.tasks
  if not charTasks or not charTasks[taskID] then return 0 end

  local st = charTasks[taskID]
  local rule = task.rules and task.rules[idx]
  if not rule then return 0 end
  local rp = st.rulesProgress[idx] or {}

  if rule.type == "manual" or rule.type == "petcapture" then
    return rp.progress or 0
  elseif rule.type == "quest" then
    return (C_QuestLog.ReadyForTurnIn(rule.questID) or C_QuestLog.IsQuestFlaggedCompleted(rule.questID)) and (rule.count or task.goal or 1) or 0
  elseif rule.type == "item" then
    return self:HasItem(rule.itemID) and (rule.count or task.goal or 1) or 0
  elseif rule.type == "spell" and (rule.role == "auto-count" or not rule.role) then
    return rp.progress or 0
  end
  return 0
end

--[[
--- Obtiene el progreso actual de una regla concreta.
--- @param task TaskData           -- Tarea asociada
--- @param rule RuleData           -- Regla de la que obtener progreso
--- @return number                 -- Progreso numérico actual
function CounterIt:NoUsar_GetRuleProgress(task, rule)
  if not task then return -1 end

  local taskID = task.id
  local count = getCounters()[taskID] or 0

  if rule.type == "manual" or rule.type == "petcapture" then
    return count
  elseif rule.type == "quest" then
    return (C_QuestLog.ReadyForTurnIn(rule.questID) or C_QuestLog.IsQuestFlaggedCompleted(rule.questID)) and task.goal or 0
  elseif rule.type == "item" then
    return self:HasItem(rule.itemID) and task.goal or 0
  elseif rule.type == "spell" and (rule.role == "auto-count" or not rule.role) then
    return count
  end
  return 0
end
]]--

--- Obtiene el progreso de la tarea para el personaje actual.
--- @param taskID string           -- ID de la tarea
--- @param task TaskData           -- Definición global de la tarea
--- @return number                 -- Progreso relevante de la tarea
function CounterIt:GetTaskProgress(taskID, task)
  if not task or not task.rules then return -1 end

  local charTasks = self.charDb.char.tasks
  if not charTasks or not charTasks[taskID] then return 0 end
  local st = charTasks[taskID]

  local relevantRules = {}
  for idx, rule in ipairs(task.rules) do
    if rule.role == "completion" then
      table.insert(relevantRules, idx)
    end
  end

  if #relevantRules > 0 then
    -- Si hay reglas de "completion", usar el mínimo de sus progresos personales
    local minProgress = math.huge
    for _, idx in ipairs(relevantRules) do
      local p = self:GetRuleProgress(taskID, task, idx)
      if p < minProgress then minProgress = p end
    end
    return (minProgress ~= math.huge) and minProgress or 0
  else
    -- Si no hay reglas de 'completion', usa el máximo entre todas
    local maxProgress = 0
    for idx, _ in ipairs(task.rules) do
      local p = self:GetRuleProgress(taskID, task, idx)
      if p > maxProgress then maxProgress = p end
    end
    return maxProgress
  end
end

--- Obtiene el progreso máximo entre todas las reglas de una tarea.
--- @param task TaskData           -- Tarea a consultar
--- @return number                 -- Máximo progreso entre todas las reglas
--[[
  Resumen técnico
    Usar el máximo para tareas multi-regla y multi-rol puede dar falsos completados.

    Mejor usar el mínimo entre reglas de tipo "completion", o bien mostrar explícitamente 
    el desglose de progreso de cada regla (lo ideal para tareas avanzadas).
]]--
--[[
function CounterIt:NoUsar_GetTaskProgress(task)
  if not task then return -1 end

  local relevantRules = {}
  for _, rule in ipairs(task.rules or {}) do
    if rule.role == "completion" then
      table.insert(relevantRules, rule)
    end
  end

  local function getProgress(rule)
    return self:GetRuleProgress(task, rule)
  end

  if #relevantRules > 0 then
    -- Si hay reglas de "completion", usar el mínimo de sus progresos
    local minProgress = math.huge
    for _, rule in ipairs(relevantRules) do
      local p = getProgress(rule)
      if p < minProgress then minProgress = p end
    end
    -- Si no hay progreso, vuelve a 0
    return (minProgress ~= math.huge) and minProgress or 0
  else
    -- Si no hay reglas de "completion", usa el máximo entre todas
    local maxProgress = 0
    for _, rule in ipairs(task.rules or {}) do
      local p = getProgress(rule)
      if p > maxProgress then maxProgress = p end
    end
    return maxProgress
  end
end
]]--

--- Comprueba si un ID corresponde a una plantilla de tarea.
--- @param id string               -- ID de plantilla
--- @return boolean                -- true si es plantilla, false si no
function CounterIt:IsTemplate(id)
  return self.taskTemplates and self.taskTemplates[id] ~= nil
end

--- Comprueba si una tarea existe en la base de datos.
--- @param taskID string           -- ID de tarea
--- @return boolean                -- true si existe, false si no
function CounterIt:TaskExists(taskID)
  return self.tasks and self.tasks[taskID] ~= nil
end

-- Valida que todas las reglas "manual" tengan un parámetro "count" válido (>0)
-- Si no, lo corrige y muestra aviso en modo debug.
local DEFAULT_MANUAL_COUNT = 1

function CounterIt:ValidateManualRules()
  local db = self.db and self.db.global
  if not db or not db.tasks then return end

  local erroresDetectados = false
  local ruleCount = 0

  for taskID, task in pairs(db.tasks) do
    if task.rules and type(task.rules) == "table" then
      for i, rule in ipairs(task.rules) do
        if rule.type == "manual" then
          ruleCount = ruleCount + 1
          if type(rule.count) ~= "number" or rule.count < 1 then
            -- Usar el goal de la tarea si es válido
            local goal = tonumber(task.goal)
            if goal and goal > 0 then
              rule.count = goal
            else
              rule.count = DEFAULT_MANUAL_COUNT
            end
            erroresDetectados = true
            self:Debug(string.format(L["ManualRuleFixedDebug"], taskID, i, rule.count, tostring(task.goal)))
          end
        end
      end
    end
  end

  if erroresDetectados or (ruleCount > 0) then
    self:Print("|cffff0000[CounterIt]|r " .. L["ManualRulesFixed"], ruleCount)
  end
end

-- Migrar tareas existentes según la plantilla actual (sin perder progreso del usuario)
function CounterIt:ReapplyTemplatesToTasks()
  local tasks = self.db and self.db.global and self.db.global.tasks
  if not tasks or not self.taskTemplates then return end

  local totalUpdated = 0

  for taskID, task in pairs(tasks) do
    local template = self.taskTemplates[taskID]
    if template then
      -- Conserva progreso y flags personalizados:
      local active     = task.active
      local completed  = task.completed
      local counters   = task.counters
      local userFields = {} -- Si tienes otros campos personalizados a conservar

      -- Copia todo lo de la plantilla (description, hint, rules, goal, etc):
      for k, v in pairs(template) do
        task[k] = v
      end

      -- Restaura los campos que quieres conservar:
      task.active     = active
      task.completed  = completed
      if counters then task.counters = counters end
      -- task.[otros campos] = userFields.[otros campos] (si necesitas más)

      totalUpdated = totalUpdated + 1
    end
  end

  self:Print(format("[CounterIt] " .. L["TemplatesReapplied"], totalUpdated))
end

--- Comprueba si una tarea admite control manual (botones [-][+]).
--- Devuelve true si existe alguna regla de tipo "manual" o "petcapture".
--- @param task TaskData           -- La tarea a comprobar
--- @return boolean                -- true si se puede avanzar manualmente, false si no
function CounterIt:TaskAllowsManualControl(task)
  if not task or not task.rules then return false end
  for _, rule in ipairs(task.rules) do
    if rule.type == "manual" or rule.type == "petcapture" then
      return true
    end
  end
  return false
end

-- final del archivo -- rules.lua
