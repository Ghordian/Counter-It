local CounterIt = LibStub("AceAddon-3.0"):NewAddon("CounterIt", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt")

--*-- DB_VERSION = 1 -- hasta v0.1.3
--*-- DB_VERSION = 2 -- desde v0.1.4 (cambia estructura de tasks)
--*-- DB_VERSION = 3 -- desde v0.1.5 (IDs únicos para tasks)
local DB_VERSION = 4 -- desde v0.1.6

-- Variables compartidas entre archivos
local globalTasks     -- nivel cuenta
local charCounters    -- nivel personaje

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

  -- DB por personaje
  self.charDb = LibStub("AceDB-3.0"):New("CounterItCharData", {
    char = {
      counters = {},
      enableTracking = true,
      enableTriggers = true,
      debugMode = false,
    },
  })

  globalTasks = self.db.global.tasks
  charCounters = self.charDb.char.counters

  self:MigrateDatabase() -- v0.1.5

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
CounterIt.charCounters = function() return charCounters end

-- core.lua -- fin del archivo
