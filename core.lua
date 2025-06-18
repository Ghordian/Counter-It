local CounterIt = LibStub("AceAddon-3.0"):NewAddon("CounterIt", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt")

-- Variables compartidas entre archivos
local globalTasks     -- nivel cuenta
local charCounters    -- nivel personaje

-- Inicialización
function CounterIt:OnInitialize()
  -- DB global (por cuenta)
  self.db = LibStub("AceDB-3.0"):New("CounterItGlobalData", {
    global = {
      tasks = {},
      taskManagerFrame = { x = 0, y = 0, width = 400, height = 500 },
      activeMonitorFrame = { x = 0, y = 0, width = 400, height = 500 },
      minimap = { hide = false },
    },
  })

  -- DB por personaje
  self.charDb = LibStub("AceDB-3.0"):New("CounterItCharData", {
    char = {
      counters = {},
    },
  })

  globalTasks = self.db.global.tasks
  charCounters = self.charDb.char.counters

  -- Comandos de consola
  self:RegisterChatCommand("counterit", "OpenTaskManager")
  self:RegisterChatCommand("ci", "OpenTaskManager")
  self:RegisterChatCommand("cit", "OpenActiveTasksMonitor")

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

function CounterIt:HandleAutoTrigger(id)
    if self:IsTemplate(id) then
        local task = self:CreateTaskFromTemplate(id)
        if task then
          self:ActivateTask(task.id)
        else
          --print("HandleAutoTrigger: Tarea duplicada con ID: " .. tostring(id))
        end
    elseif self:TaskExists(id) then
        self:ActivateTask(id)
    else
        print("HandleAutoTrigger: No se encontró tarea o plantilla con ID: " .. tostring(id))
    end
end

-- Exponer referencias para otros módulos
CounterIt.globalTasks = function() return globalTasks end
CounterIt.charCounters = function() return charCounters end
