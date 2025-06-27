-- templates.lua
local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt")

-- Tabla de plantillas predefinidas
CounterIt.taskTemplates = {
--[[
  ["Rebuscar en la basura"] = {
    description = "Rebuscar en la basura",
    goal = 25,
    icon = 134391,
    rules = {
      { type = "spell", spellID = 470986 },
      { type = "spell", spellID = 6247 },
      { type = "manual", count = 25 },
      { type = "quest", questID = 86918 },
    },
  },
  ["dummyTask"] = {
    description = "Tarea de ejemplo completa",
    goal = 10,
    icon = 134400,
    rules = {
        --* Se usa para activar/desactivar automáticamente la tarea
        { type = "quest", questID = 12345, role = "activation" },

        --* Regla manual, necesaria para considerar la tarea completada
        { type = "manual", count = 10, role = "completion" },

        --* Se usa como mecanismo de auto-contaje, no evalúa finalización
        { type = "event", event = "PLAYER_KILL", count = 10, role = "auto-count" },

        --* Alternativamente, si esta quest está completada, se considera terminada la tarea
        { type = "quest", questID = 12346, role = "completion" },
    },
  },
  ]]--

  ["side-with-a-cartel"] = {
    description = L["side-with-a-cartel"],
    url = "https://www.wowhead.com/quest=86915",
    goal = 1,
    icon = 134391,
    step = 1,
    rules = {
      { type = "quest", questID = 86915, role = "completion" },
    },
  },
  ["ship-right"] = {
    description = L["ship-right"],
    url = "https://www.wowhead.com/quest=86917",
    goal = 10,
    icon = 134391,
    step = 2,
    rules = {
      { type = "quest", questID = 86917, role = "completion" },
    },
  },
  ["reclaimed-scrap"] = {
    description = L["reclaimed-scrap"],
    url = "https://www.wowhead.com/quest=86918",
    goal = 100,
    icon = 134391,
    step = 3,
    rules = {
      { type = "quest", questID = 86918, role = "completion" },
    },
  },
  ["side-gig"] = {
    description =  L["side-gig"],
    url = "https://www.wowhead.com/quest=86919",
    goal = 1,
    icon = 134391,
    step = 4,
    rules = {
      { type = "quest", questID = 86919, role = "completion" },
    },
  },
  ["war-mode-violence"] = {
    description = L["war-mode-violence"],
    url = "https://www.wowhead.com/quest=86920",
    goal = 5,
    icon = 134391,
    step = 5,
    rules = {
      { type = "quest", questID = 86920, role = "completion" },
    },
  },
  ["go-fish"] = {
    description = L["go-fish"],
    notes = "50 Fishing Pools",
    url = "https://www.wowhead.com/quest=86923",
    goal = 50,
    icon = 134391,
    step = 6,
    rules = {
      -- https://www.wowhead.com/item=227673/gold-fish
      -- https://www.wowhead.com/es/object=457157/escorrent%C3%ADa-bonvapor
      { type = "item", itemID = 227673, count = 50, role = "auto-count" },
      { type = "object", object = 457157, role = "auto-count" },
      { type = "quest", questID = 86923, role = "completion" },
    },
  },
  ["gotta-catch-at-least-a-few"] = {
    description = L["gotta-catch-at-least-a-few"],
    url = "https://www.wowhead.com/quest=86924",
    goal = 5,
    icon = 134391,
    step = 7,
    rules = {
      { type = "petcapture", count = 5, role = "auto-count" },
      { type = "quest", questID = 86924, role = "completion" },
    },
  },
  ["rare-rivals"] = {
    description = L["rare-rivals"],
    url = "https://www.wowhead.com/quest=87302",
    goal = 3,
    icon = 134391,
    step = 8,
    rules = {
      { type = "quest", questID = 87302, role = "completion" },
    },
  },
  ["clean-the-sidestreets"] = {
    description = L["clean-the-sidestreets"],
    url = "https://www.wowhead.com/quest=87303",
    goal = 1,
    icon = 134391,
    step = 9,
    rules = {
      { type = "quest", questID = 87303, role = "completion" },
    },
  },
  ["time-to-vacate"] = {
    description = L["time-to-vacate"],
    url = "https://www.wowhead.com/quest=87304",
    goal = 1,
    icon = 134391,
    step = 10,
    rules = {
      { type = "quest", questID = 87304, role = "completion" },
    },
  },
  ["desire-to-d-r-i-v-e"] = {
    description = L["desire-to-d-r-i-v-e"],
    url = "https://www.wowhead.com/quest=87305",
    goal = 2,
    icon = 134391,
    step = 11,
    rules = {
      { type = "quest", questID = 87305, role = "completion" },
    },
  },
  ["kaja-cruising"] = {
    description = L["kaja-cruising"],
    url = "https://www.wowhead.com/quest=87306",
    goal = 50,
    icon = 134391,
    step = 12,
    rules = {
      { type = "quest", questID = 87306, role = "completion" },
    },
  },
  ["garbage-day"] = {
    description = L["garbage-day"],
    url = "https://www.wowhead.com/quest=86918",
    goal = 25,
    icon = "Interface\\Icons\\inv_10_engineering_purchasedparts_color2",
    icon = 134391,
    step = 13,
    rules = {
      { type = "spell", spellID = 470986, role = "auto-count" },
      { type = "spell", spellID = 6247, role = "auto-count" },
      { type = "manual", count = 25 },
      { type = "quest", questID = 86918, role = "completion" },
    },
  },
}

-- Selector visual de plantillas
function CounterIt:OpenTemplateSelector()
  local frame = AceGUI:Create("Frame")
  frame:SetTitle(L["TITLE_SELECT_TEMPLATE"])
  frame:SetStatusText(L["STATUSTEXT_SELECT_TEMPLATE"])
  frame:SetLayout("Flow")
  frame:SetWidth(350)
  frame:SetHeight(400)

  for name, template in pairs(self.taskTemplates) do
    local button = AceGUI:Create("Button")
    button:SetText(name)
    button:SetFullWidth(true)
    button:SetCallback("OnClick", function()
      self:CreateTaskFromTemplate(name)
      frame:Release()
    end)
    frame:AddChild(button)
  end
end

-- Crear una tarea basada en una plantilla
function CounterIt:CreateTaskFromTemplate(name)
  local template = self.taskTemplates[name]
  if not template then
    print(format(L["TEMPLATE_NOT_FOUND"], name))
    return
  end

  if self.globalTasks()[name] then 
    --self:DEBUG(format("TAREA", name, "ya existe"))
    return -- evitar duplicados
  end

  local newTask = {
    description = template.description,
    goal = template.goal,
    icon = template.icon,
    rules = CopyTable(template.rules),
    active = true,
    completed = false,
  }

  self.globalTasks()[name] = newTask
  print(format(L["TASK_TEMPLATE_CREATED"], name))

  if self.taskManagerFrame then
    self:RenderPausedTasks()
  end
end

-- Verificar tareas basadas en misiones ya completadas
function CounterIt:CheckCompletedQuestsAgainstTasks()
  local completed = C_QuestLog.GetAllCompletedQuestIDs()
  if not completed then return end

  local taskList = self.globalTasks()
  for name, task in pairs(taskList) do
    if task.active and not task.completed and task.rules then
      for _, rule in ipairs(task.rules) do
        if rule.type == "quest" and tContains(completed, rule.questID) then
          rule.progress = rule.count or 1
          self:EvaluateTaskCompletion(name, task)
        end
      end
    end
  end
  self:RenderActiveTasks()
end
