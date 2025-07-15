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
  elseif rule.type == "zone" and rule.zoneIDs then -- NUEVO: Evaluación para reglas de zona
    local currentMapID = C_Map.GetBestMapForUnit("player")
    local inZone = false
    if currentMapID then
        for _, zoneID in ipairs(rule.zoneIDs) do
            if zoneID == currentMapID then
                inZone = true
                break
            end
        end
    end
    rp.completed = inZone
  end

  return rp.completed
end

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
  elseif rule.type == "zone" and rule.zoneIDs then -- NUEVO: Comprobación de reglas de zona
    local currentMapID = C_Map.GetBestMapForUnit("player")
    local inZone = false
    if currentMapID then
        for _, zoneID in ipairs(rule.zoneIDs) do
            if zoneID == currentMapID then
                inZone = true
                break
            end
        end
    end
    if inZone then
        rp.completed = true
    end
  end
  return rp.completed
end

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

  if (self.traceMode == true) or reset then
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
      elseif rule.type == "zone" and rule.zoneIDs then -- NUEVO: Evaluación para reglas de zona
        local currentMapID = C_Map.GetBestMapForUnit("player")
        local inZone = false
        if currentMapID then
            for _, zoneID in ipairs(rule.zoneIDs) do
                if zoneID == currentMapID then
                    inZone = true
                    break
                end
            end
        end
        rp.completed = inZone
      end
    end
  end

  EvaluateTaskCompletion(st, task)
  return st.completed or reset
end

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
  elseif rule.type == "zone" then -- NUEVO: Progreso para reglas de zona
    local currentMapID = C_Map.GetBestMapForUnit("player")
    local inZone = false
    if currentMapID then
        for _, zoneID in ipairs(rule.zoneIDs) do
            if zoneID == currentMapID then
                inZone = true
                break
            end
        end
    end
    return inZone and (rule.count or task.goal or 1) or 0 -- Considera "completado" si está en la zona
  end
  return 0
end

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

--- NUEVO: Marca reglas de tipo "quest" como completadas si el jugador ya completó la quest.
--- Esta función es ideal para ser llamada al cargar el addon o después de ciertos eventos de misiones.
---@return nil
function CounterIt:CheckCompletedQuestsAgainstTasks()
  local completedQuestIDs = C_QuestLog.GetAllCompletedQuestIDs()
  if not completedQuestIDs then return end

  local needRefresh = false
  local tasks = self.globalTasks()
  local charTasks = self.charDb.char.tasks
  for taskID, task in pairs(tasks) do
    local st = charTasks[taskID]
    -- Solo procesar tareas activas y no completadas para evitar trabajo innecesario
    if st and st.active and not st.completed and task.rules then
      local needsUpdate = false
      for idx, rule in ipairs(task.rules) do
        if rule.type == "quest" and tContains(completedQuestIDs, rule.questID) then
          -- Si la regla de quest está completada, marcamos que se necesita una actualización
          needsUpdate = true
          -- No es necesario evaluar la regla individualmente aquí, UpdateTaskProgress lo hará
          -- st.rulesProgress[idx].completed = true -- Esto lo hará UpdateTaskProgress
        end
      end
      if needsUpdate then
        self:UpdateTaskProgress(taskID, task)
        needRefresh = true
      end
    end
  end
  if needRefresh then
  --self:RenderActiveTasks()
    self:SendMessage("CounterIt_UpdateTasksMonitor")
  --self:RenderAllTasks()
    self:SendMessage("CounterIt_UpdateAllTasks")
  end
end

-- final del archivo -- rules.lua
