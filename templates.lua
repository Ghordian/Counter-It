-- templates.lua
local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt")

-- Tabla de plantillas predefinidas
CounterIt.taskTemplates = {
  ["Rebuscar en la basura"] = {
    description = "Rebuscar en la basura",
    goal = 25,
    icon = "Interface\\Icons\\inv_10_engineering_purchasedparts_color2",
    rules = {
      { type = "spell", spellID = 470986 },
      { type = "spell", spellID = 6247 },
      { type = "manual", count = 25 },
      { type = "quest", questID = 86918 },
    },
  },
  ["side-with-a-cartel"] = {
    description = "Have chosen which Cartel you will align with for that week.",
    url = "https://www.wowhead.com/quest=86915",
    goal = 1,
    icon = 134400,
    rules = {
      { type = "quest", questID = 86915 },
    },
  },
  ["ship-right"] = {
    description = "Realizar 10 trabajos.",
    url = "https://www.wowhead.com/quest=86917",
    goal = 10,
    icon = 134400,
    rules = {
      { type = "quest", questID = 86917 },
    },
  },
  ["reclaimed-scrap"] = {
    description = "Gathered 100 empty Kaja' Cola cans from S.C.R.A.P piles.",
    url = "https://www.wowhead.com/quest=86918",
    goal = 100,
    icon = 134400,
    rules = {
      { type = "quest", questID = 86918 },
    },
  },
  ["side-gig"] = {
    description = "Have completed a Side Gig. Side Gigs are available in the main Transportation Hub.",
    url = "https://www.wowhead.com/quest=86919",
    goal = 1,
    icon = 134400,
    rules = {
      { type = "quest", questID = 86919 },
    },
  },
  ["war-mode-violence"] = {
    description = "Defeat five enemy players in War Mode in Undermine.",
    url = "https://www.wowhead.com/quest=86920",
    goal = 5,
    icon = 134400,
    rules = {
      { type = "quest", questID = 86920 },
    },
  },
  ["go-fish"] = {
    description = "Plantilla dummy generada automáticamente.",
    url = "https://www.wowhead.com/quest=86923",
    goal = 50,
    icon = 134400,
    rules = {
      -- https://www.wowhead.com/item=227673/gold-fish
      { type = "item", itemID = 227673, count = 50 },
      { type = "quest", questID = 86923 },
    },
  },
  ["gotta-catch-at-least-a-few"] = {
    description = "Captura 5 mascotas salvajes",
    url = "https://www.wowhead.com/quest=86924",
    goal = 5,
    icon = "Interface\\Icons\\Ability_Hunter_BeastTaming",
    rules = {
      { type = "petcapture", count = 5 },
      { type = "quest", questID = 86924 },
    },
  },
  ["rare-rivals"] = {
    description = "Derrota a 3 NPCs raros de Minahonda.",
    url = "https://www.wowhead.com/quest=87302",
    goal = 3,
    icon = 134400,
    rules = {
      { type = "quest", questID = 87302 },
    },
  },
  ["clean-the-sidestreets"] = {
    description = "complete the Sidestreet Sluice Delve.",
    url = "https://www.wowhead.com/quest=87303",
    goal = 1,
    icon = 134400,
    rules = {
      { type = "quest", questID = 87303 },
    },
  },
  ["time-to-vacate"] = {
    description = "Excavation Site 9 Delve completed.",
    url = "https://www.wowhead.com/quest=87304",
    goal = 1,
    icon = 134400,
    rules = {
      { type = "quest", questID = 87304 },
    },
  },
  ["desire-to-d-r-i-v-e"] = {
    description = "Complete two races in Undermine.",
    url = "https://www.wowhead.com/quest=87305",
    goal = 2,
    icon = 134400,
    rules = {
      { type = "quest", quesID = 87305 },
    },
  },
  ["kaja-cruising"] = {
    description = "Collecting cans while driving the G-99 Breakneck (D.R.I.V.E. mount).",
    url = "https://www.wowhead.com/quest=87306",
    goal = 50,
    icon = 134400,
    rules = {
      { type = "quest", quesID = 87306 },
    },
  },
  ["garbage-day"] = {
    description = "Rebuscar en la basura",
    url = "https://www.wowhead.com/quest=86918",
    goal = 25,
    icon = "Interface\\Icons\\inv_10_engineering_purchasedparts_color2",
    iconID = 134400,
    rules = {
      { type = "spell", spellID = 470986 },
      { type = "spell", spellID = 6247 },
      { type = "manual", count = 25 },
      { type = "quest", questID = 86918 },
    },
  },
  ["template_lixo"] = {
    description = "Plantilla dummy generada automáticamente.",
    goal = 1,
    icon = 134400,
    rules = {},
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
    print(format("TAREA", name, "ya existe"))
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
          rule.progress = rule.goal or 1
          self:EvaluateTaskCompletion(name, task)
        end
      end
    end
  end
  self:RenderActiveTasks()
end
