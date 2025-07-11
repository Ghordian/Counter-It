-- templates.lua
local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt")

-- Tabla de plantillas predefinidas con campo id único (clave = id)
CounterIt.taskTemplates = {
  ["side-with-a-cartel"] = {
    id = "side-with-a-cartel",
    description = L["side-with-a-cartel"],
    hint = L["side-with-a-cartel-hint"],
    url = "https://www.wowhead.com/quest=86915",
    goal = 1,
    icon = 134391,
    step = 1,
    rules = {
      { type = "quest", questID = 86915, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
  ["ship-right"] = {
    id = "ship-right",
    description = L["ship-right"],
    hint = L["ship-right-hint"],
    url = "https://www.wowhead.com/quest=86917",
    goal = 10,
    icon = 134391,
    step = 2,
    rules = {
      { type = "manual", count = 10 },
      { type = "quest", questID = 86917, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
  ["reclaimed-scrap"] = {
    id = "reclaimed-scrap",
    description = L["reclaimed-scrap"],
    hint = L["reclaimed-scrap-hint"],
    url = "https://www.wowhead.com/quest=86918",
    goal = 100,
    icon = 134391,
    step = 3,
    rules = {
      { type = "currency", itemID = 3218, count = 100, role = "auto-count", url = "https://www.wowhead.com/currency=3218/empty-kajacola-can" },
      { type = "quest", questID = 86918, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
  ["side-gig"] = {
    id = "side-gig",
    description =  L["side-gig"],
    hint = L["side-gig-hint"],
    url = "https://www.wowhead.com/quest=86919",
    goal = 1,
    icon = 134391,
    step = 4,
    rules = {
      { type = "quest", questID = 86919, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
  ["war-mode-violence"] = {
    id = "war-mode-violence",
    description = L["war-mode-violence"],
    hint = L["war-mode-violence-hint"],
    url = "https://www.wowhead.com/quest=86920",
    goal = 5,
    icon = 134391,
    step = 5,
    rules = {
      { type = "manual", count = 5 },
      { type = "quest", questID = 86920, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
  ["go-fish"] = {
    id = "go-fish",
    description = L["go-fish"],
    hint = L["go-fish-hint"],
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
      { type = "manual", count = 50 },
      { type = "quest", questID = 86923, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
  ["gotta-catch-at-least-a-few"] = {
    id = "gotta-catch-at-least-a-few",
    description = L["gotta-catch-at-least-a-few"],
    hint = L["gotta-catch-at-least-a-few-hint"],
    url = "https://www.wowhead.com/quest=86924",
    goal = 5,
    icon = 134391,
    step = 7,
    rules = {
      { type = "petcapture", count = 5, role = "auto-count" },
      { type = "quest", questID = 86924, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
  ["rare-rivals"] = {
    id = "rare-rivals",
    description = L["rare-rivals"],
    hint = L["rare-rivals-hint"],
    url = "https://www.wowhead.com/quest=87302",
    goal = 3,
    icon = 134391,
    step = 8,
    rules = {
      { type = "manual", count = 3 },
      { type = "quest", questID = 87302, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
  ["clean-the-sidestreets"] = { --  Sidestreet Sluice Delve.
    id = "clean-the-sidestreets",
    description = L["clean-the-sidestreets"],
    hint = L["clean-the-sidestreets-hint"],
    url = "https://www.wowhead.com/quest=87303",
    goal = 1,
    icon = 134391,
    step = 9,
    rules = {
      { type = "quest", questID = 87303, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
  ["time-to-vacate"] = { -- Excavation Site 9 Delve.
    id = "time-to-vacate",
    description = L["time-to-vacate"],
    hint = L["time-to-vacate-hint"],
    url = "https://www.wowhead.com/quest=87304",
    goal = 1,
    icon = 134391,
    step = 10,
    rules = {
      { type = "quest", questID = 87304, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
  ["desire-to-d-r-i-v-e"] = {
    id = "desire-to-d-r-i-v-e",
    description = L["desire-to-d-r-i-v-e"],
    hint = L["desire-to-d-r-i-v-e-hint"],
    url = "https://www.wowhead.com/quest=87305",
    goal = 2,
    icon = 134391,
    step = 11,
    rules = {
      { type = "manual", count = 2 },
      { type = "quest", questID = 87305, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
  ["kaja-cruising"] = {
    id = "kaja-cruising",
    description = L["kaja-cruising"],
    hint = L["kaja-cruising-hint"],
    url = "https://www.wowhead.com/quest=87306",
    goal = 50,
    icon = 134391,
    step = 12,
    rules = {
      { type = "manual", count = 50 },
      { type = "quest", questID = 87306, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
  ["garbage-day"] = {
    id = "garbage-day",
    description = L["garbage-day"],
    hint = L["garbage-day-hint"],
    url = "https://www.wowhead.com/quest=87307",
    goal = 25,
    icon = "Interface\\Icons\\inv_10_engineering_purchasedparts_color2",
    icon = 134391,
    step = 13,
    rules = {
      { type = "spell", spellID = 470986, role = "auto-count" },
      { type = "spell", spellID = 6247, role = "auto-count" },
      { type = "manual", count = 25 },
      { type = "quest", questID = 87307, role = "completion" },
      { type = "item", itemID = 235053, count = 1, role = "completion" },
    },
  },
}

--- Abre el selector visual para elegir una plantilla de tarea predefinida.
function CounterIt:OpenTemplateSelector()
  local frame = AceGUI:Create("Frame")
  frame:SetTitle(L["TITLE_SELECT_TEMPLATE"])
  frame:SetStatusText(L["STATUSTEXT_SELECT_TEMPLATE"])
  frame:SetLayout("Flow")
  frame:SetWidth(350)
  frame:SetHeight(400)

  for name, template in pairs(self.taskTemplates) do
    local button = AceGUI:Create("Button")
    local desc = template.description or name
    button:SetText(desc)
    button:SetFullWidth(true)
    button:SetCallback("OnClick", function()
      self:CreateTaskFromTemplate(name)
      frame:Release()
    end)
    frame:AddChild(button)
  end
end

--- Crea una nueva tarea en base a una plantilla predefinida.
---@param name string         -- ID de la plantilla.
---@return TaskData?          -- Tarea creada (o nil si falla).
function CounterIt:CreateTaskFromTemplate(name)
  local template = self.taskTemplates[name]
  if not template then
    print(format(L["TEMPLATE_NOT_FOUND"], name))
    return
  end

  local taskID = template.id or name -- taskID

  if self.globalTasks()[taskID] then -- taskID
    --self:DEBUG(format("TAREA", name, "ya existe"))
    return -- evitar duplicados
  end

  ---@type TaskData
  local newTask = {
    id = taskID,
    description = template.description,
    hint = template.hint,
    goal = template.goal,
    icon = template.icon,
    rules = CopyTable(template.rules),
    active = true,
    completed = false,
    templateID = taskID,
    url = template.url,
    step = template.step,
    isFavorite = false,
  }

  self.globalTasks()[taskID] = newTask -- taskID
  print(format(L["TASK_TEMPLATE_CREATED"], name, taskID))

  if self.taskManagerFrame then
    self:RenderAllTasks()
  end

  return newTask
end

--- Marca reglas de tipo "quest" como completadas si el jugador ya completó la quest.
---@return nil
function CounterIt:CheckCompletedQuestsAgainstTasks()
  local completedQuestIDs = C_QuestLog.GetAllCompletedQuestIDs()
  if not completedQuestIDs then return end

  local needRefresh = false
  local tasks = self.globalTasks()
  local charTasks = self.charDb.char.tasks
  for taskID, task in pairs(tasks) do
    local st = charTasks[taskID]
    if st.active and not st.completed and task.rules then
      local needsUpdate = false
      for idx, rule in ipairs(task.rules) do
        if rule.type == "quest" and tContains(completedQuestIDs, rule.questID) then
        --rule.progress = rule.count or 1
        --self:EvaluateTaskCompletion(taskID, task)
          needsUpdate = true
        end
      end
      if needsUpdate then
        self:UpdateTaskProgress(taskID, task)
        needRefresh = true
      end
    end
  end
  if needRefresh then
    self:RenderActiveTasks()
  end
end

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
