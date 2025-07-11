local CounterIt = LibStub("AceAddon-3.0"):NewAddon("CounterIt", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt")

--*-- DB_VERSION = 1 -- hasta v0.1.3
--*-- DB_VERSION = 2 -- desde v0.1.4 (cambia estructura de tasks)
--*-- DB_VERSION = 3 -- desde v0.1.5 (IDs únicos para tasks)
--*-- DB_VERSION = 4 -- desde v0.1.6
--*-- DB_VERSION = 5 -- desde v0.1.7
local DB_VERSION = 6 -- desde v0.1.9

-- Variables compartidas entre archivos
local globalTasks     -- nivel cuenta
--local charCounters    -- nivel personaje

-- Define tus constantes de roles aquí
CounterIt.RuleRoles = {
    COMPLETION = "completion",
    AUTO_COUNT = "auto-count",
    ACTIVATION = "activation",
}

function CounterIt:Debug(...)
  if self:IsDebugMode() then
    print("|cffffcc00[CounterIt DEBUG]|r", ...)
  end
end

function CounterIt:ToggleDebugMode()
  if self:IsDebugMode() then
    print("|cffffcc00[CounterIt DEBUG]|r", "ON")
  else
    print("|cffffcc00[CounterIt DEBUG]|r", "OFF")
  end
end

---Devuelve true si el seguimiento de tareas está habilitado por configuración.
---@return boolean
function CounterIt:IsTrackingEnabled()
  return self.db and self.db.profile and self.db.profile.enableTracking == true
end

function CounterIt:IsDebugMode()
  return self.db and self.db.profile and self.db.profile.debugMode == true
end

--- Migra todas las tareas existentes en la base de datos al nuevo sistema basado en IDs únicos.
--- - Asigna `task.id` a cada tarea.
--- - Usa como clave interna el ID único (plantilla o generado para tareas personalizadas).
--- - Elimina duplicados y claves antiguas basadas en descripción.
--- - Deja la base de datos limpia y lista para el sistema de IDs.
---@return nil
function CounterIt:MigrateTasksToIDs()
  local tasks = self.db and self.db.global and self.db.global.tasks
  if not tasks then return end

  local templates = self.taskTemplates or {}
  local newTasks = {}
  local changed = 0
  local customCount = 0
  local existingIDs = {}

  for oldKey, task in pairs(tasks) do
    -- 1. Si es tarea de plantilla, usa su id único
    local id = nil
    for tid, tpl in pairs(templates) do
      if tpl.description == task.description or (task.templateID and task.templateID == tid) then
        id = tpl.id or tid
        break
      end
    end
    -- 2. Si es tarea personalizada, genera un id único si no existe
    if not id then
      if task.id then
        id = task.id
      else
        id = "custom-"..tostring(time()).."-"..tostring(customCount)
        customCount = customCount + 1
      end
    end

    -- Evita duplicados
    if not existingIDs[id] then
      task.id = id
      newTasks[id] = task
      existingIDs[id] = true
      if oldKey ~= id then changed = changed + 1 end
    end
  end

  self.db.global.tasks = newTasks
  Debug(string.format("[CounterIt] Migración a sistema de IDs: %d tareas actualizadas", changed))
end

function CounterIt:MigrateSpellRulesToAutoCountRole()
  local tasks = self.db and self.db.global and self.db.global.tasks
  if not tasks then return end
  -- Migración: Asegura que todas las reglas tipo "spell" tengan role = "auto-count"
  for _, task in pairs(tasks) do
    for _, rule in ipairs(task.rules or {}) do
      if rule.type == "spell" and not rule.role then
        rule.role = "auto-count"
      end
    end
  end
end

--- Limpia los campos de progreso y estado de las tareas globales.
function CounterIt:CleanupGlobalTaskStates()
  local tasks = self.db.global.tasks
  if not tasks then return end

  local anyCleared = false
  for _, task in pairs(tasks) do
    if task.active or task.completed then 
      anyCleared = true
    end
    -- Borra estado de tarea global
    task.active = nil
    task.completed = nil
    -- Borra estado de reglas globales
    if task.rules then
      for _, rule in ipairs(task.rules) do
        if rule.progress or rule.completed then 
          anyCleared = true
        end
        rule.progress = nil
        rule.completed = nil
      end
    end
  end
  return anyCleared
end

--- Migra el progreso manual desde charCounters a la nueva estructura de estado por tarea/personaje.
function CounterIt:MigrateCharCountersToTaskState()
  local charDb = self.charDb.char
  if not charDb then return end

  -- Inicializar tasks si no existe
  if not charDb.tasks then
    charDb.tasks = {}
  end

  local counters = charDb.counters or {}
  local charTasks = charDb.tasks

  for taskID, progress in pairs(counters) do
    if not charTasks[taskID] then
      charTasks[taskID] = {
        taskID = taskID,
        active = false,
        completed = false,
        progressManual = progress or 0,
        rulesProgress = {},
      }
    else
      charTasks[taskID].progressManual = progress or 0
    end
  end

  -- Borra la antigua tabla counters tras migrar
  charDb.counters = nil
end

--- Establece el valor por defecto de isFavorite de todas las tareas ya definidas
function MigrateFavoriteTesk()
  local tasks = self.db.global.tasks
  if not tasks then return end

  local anyCleared = false
  for _, task in pairs(tasks) do
    if task.isFavorite == nil then 
      anyCleared = true
      task.isFavorite = false
    end
  end
  return anyCleared
end

function CounterIt:MigrateDatabase()
  local db = self.db.global
  if not db.dbVersion then db.dbVersion = 1 end

  if db.dbVersion < 2 then
    self:ReapplyTemplatesToTasks()
    db.dbVersion = 2
  end

  if db.dbVersion < 3 then
    self:MigrateTasksToIDs()
    db.dbVersion = 3
  end

  if db.dbVersion < 4 then
    self:MigrateSpellRulesToAutoCountRole()
    db.dbVersion = 4
  end

  if db.dbVersion < 5 then
    local anyCleared = self:CleanupGlobalTaskStates()
    if anyCleared then
      self:Print("|cffffcc00[Counter-It]|r ", L["MIGRATION_CLEANED_GLOBAL_PROGRESS"])
    end
    self:MigrateCharCountersToTaskState()
    db.dbVersion = 5
  end

  if db.dbVersion < 6 then
    local anyCleared = self:CleanupGlobalTaskStates()
    if anyCleared then
      self:Print("|cffffcc00[Counter-It]|r ", L["MIGRATION_CLEANED_GLOBAL_PROGRESS"])
    end
    self:MigrateFavoriteTesk()
    db.dbVersion = 6
  end

  db.dbVersion = DB_VERSION
end

-- Inicialización
function CounterIt:OnInitialize()
  -- DB global (por cuenta)
  self.db = LibStub("AceDB-3.0"):New("CounterItGlobalData", {
    global = {
      dbVersion = DB_VERSION,
      tasks = {},
      taskManagerFrame = { x = 0, y = 0, width = 400, height = 500 },
      activeMonitorFrame = { x = 0, y = 0, width = 400, height = 500 },
      minimap = { hide = false },
    },
  })

  self:MigrateDatabase()

  self:ValidateManualRules()

  globalTasks = self.db.global.tasks

  -- DB por personaje
  self.charDb = LibStub("AceDB-3.0"):New("CounterItCharData", {
    char = {
    --counters = {},--rejected db < 5
      tasks = {},
      enableTracking = true,
      enableTriggers = true,
      debugMode = false,
    },
  })

--charCounters = self.charDb.char.counters-- rejected

  self:MigrateDatabase() -- v0.1.5

  -- Inicializar la tabla para monitorear los ítems
  self.itemsToMonitorForActivation = {}
  self.itemCountsBeforeBagUpdate = {} -- Para guardar el conteo anterior de ítems

  -- Llama a una función para poblar itemsToMonitorForActivation al inicio
  self:BuildActivationItemMonitorList()

  -- Comandos de consola
  self:RegisterChatCommand("counterit", "OpenTaskManager")
  self:RegisterChatCommand("ci", "OpenTaskManager")
  self:RegisterChatCommand("cit", "OpenActiveTasksMonitor")
  self:RegisterChatCommand("citreset", "ResetActiveTasks")
  self:RegisterChatCommand("citdbg", "ToggleDebugMode")

  -- Minimapa y DataBroker
  local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("CounterIt", {
    type = "data source",
    text = "Counter-It",
    icon = "Interface\\AddOns\\Counter-It\\Media\\icon",
    OnClick = function(_, button)
      if button == "LeftButton" then
        CounterIt:OpenTaskManager()
      elseif button == "RightButton" then
        CounterIt:OpenActiveTasksMonitor()
      end
    end,
    OnTooltipShow = function(tooltip)
      tooltip:AddLine("Counter-It")
      tooltip:AddLine(L["MINIMAP_LEFT"])
      tooltip:AddLine(L["MINIMAP_RIGHT"])
    end,
  })

  LibStub("LibDBIcon-1.0"):Register("CounterIt", LDB, self.db.global.minimap or {})

  self:Print(L["LOADED_MSG"])
end

-- Nueva función para construir la lista de ítems a monitorear
function CounterIt:BuildActivationItemMonitorList()
    wipe(self.itemsToMonitorForActivation) -- Limpiar antes de poblar

    -- Recorre todas tus tareas (globales y plantillas si quieres)
    -- global.tasks es para las tareas que ya tiene el personaje
    for taskID, taskData in pairs(self.db.global.tasks) do
        for _, rule in ipairs(taskData.rules) do
            if rule.type == "item" and rule.role == self.RuleRoles.ACTIVATION and rule.itemID then
                self.itemsToMonitorForActivation[rule.itemID] = true -- Solo necesitamos saber que existe
            end
        end
    end

    -- Si también quieres que las plantillas se activen automáticamente al obtener un ítem:
    for templateID, templateData in pairs(self.taskTemplates) do
         for _, rule in ipairs(templateData.rules) do
            if rule.type == "item" and rule.role == self.RuleRoles.ACTIVATION and rule.itemID then
                self.itemsToMonitorForActivation[rule.itemID] = true
            end
        end
    end

    -- Almacenar los conteos actuales de estos ítems para la próxima BAG_UPDATE
    self:UpdateStoredItemCounts()
end

-- Función para guardar los conteos actuales de los ítems monitoreados
function CounterIt:UpdateStoredItemCounts()
    for itemID, _ in pairs(self.itemsToMonitorForActivation) do
        self.itemCountsBeforeBagUpdate[itemID] = GetItemCount(itemID)
    end
end

function CounterIt:ResetActiveTasks()
  -- Cerrar el panel de seguimiento de tareas activas
  if self.activeMonitorFrame and self.activeMonitorFrame:IsShown() then
    self.activeMonitorFrame:Hide()
  end

  -- Cerrar el panel de tareas en pausa
  if self.taskManagerFrame and self.taskManagerFrame:IsShown() then
    self.taskManagerFrame:Hide()
  end

  if CounterIt.db then
    CounterIt.db.tasks = {}
    print("CounterIt: Todas las tareas han sido eliminadas.")
  else
    print("CounterIt: No se pudo acceder a los datos.")
  end
end

--- @param id string           -- ID de la tarea o template
function CounterIt:HandleAutoTrigger(id)
  self:Debug('HandleAutoTrigger', id)
  if self:IsTemplate(id) then
    local task = self:CreateTaskFromTemplate(id)
    if task and task.id then
      self:Debug('ActivateTask(task.id)', task.id)
      self:ActivateTask(task.id)
    else
      self:Debug("HandleAutoTrigger: Tarea duplicada con ID: " .. tostring(id))
    end
  elseif self:TaskExists(id) then
    self:ActivateTask(id)
  else
    self:Debug("HandleAutoTrigger: No se encontró tarea o plantilla con ID: " .. tostring(id))
  end
end

-- Exponer referencias para otros módulos
CounterIt.globalTasks = function() return globalTasks end

--[[
-- CounterIt.charCounters = function() return charCounters end -- To-Be-Deleted

creo que es mucho cambio cuando aún no sabemos/podemos activar una tarea por personaje! 
De momento lo anoto como pendiente, y regresaremos a ello en un cuarto paso, 
sigamos pues con el tercer paso, ok?

local charTasks = self.charDb.char.tasks
if not charTasks[taskID] then
  charTasks[taskID] = { ... inicializar ... }
end
charTasks[taskID].progressManual = ...

local progress = charTasks[taskID] and charTasks[taskID].progressManual or 0

]]--

-- core.lua -- fin del archivo
