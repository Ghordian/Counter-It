-- ui_native.lua

local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")
local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt")

-- Constantes
local PANEL_WIDTH, PANEL_HEIGHT = 500, 600
local BUTTON_WIDTH, BUTTON_HEIGHT = 120, 24
local MARGIN = 10
local LIST_ITEM_HEIGHT = 32

-- Guardar posición del panel
function CounterIt:SaveTaskManagerFrameState()
  if not self.taskManagerFrame then return end
  local f = self.taskManagerFrame
  local point, _, relativePoint, xOfs, yOfs = f:GetPoint()
  self.db.global.taskManagerFrame = {
    point = point,
    relativePoint = relativePoint,
    x = xOfs,
    y = yOfs,
    width = f:GetWidth(),
    height = f:GetHeight(),
  }
end

-- Panel de gestión de tareas (versión nativa)
function CounterIt:OpenTaskManager()
  if self.taskManagerFrame then
    self.taskManagerFrame:Hide()
    self.taskManagerFrame:SetParent(nil)
    self.taskManagerFrame = nil
  end

  local pos = self.db.global.taskManagerFrame or {}
  local frame = CreateFrame("Frame", "CounterItTaskManager", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(pos.width or PANEL_WIDTH, pos.height or PANEL_HEIGHT)
  if pos.point then
    frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
  else
    frame:SetPoint("CENTER")
  end

  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    CounterIt:SaveTaskManagerFrameState()
  end)
  frame:SetResizable(true)
  --frame:SetMinResize(400, 300) -- No disponible en versiones antiguas de WoW
  frame:SetScript("OnSizeChanged", function(self)
    CounterIt:SaveTaskManagerFrameState()
  end)

  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  frame.title:SetPoint("TOP", 0, -10)
  frame.title:SetText(L["TASK_MANAGER_TITLE"] or "Gestor de Tareas")

  local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", -5, -5)

  -- ScrollFrame para las tareas pausadas
  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 16, -40)
  scrollFrame:SetPoint("BOTTOMRIGHT", -36, 80)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(1, 1)
  scrollFrame:SetScrollChild(content)
  self.pausedTasksScrollFrame = content

  self.taskManagerFrame = frame
  self:RenderPausedTasks_Native()
  self:AddTopButtons_Native()
  self:AddBottomButtons_Native()
  frame:Show()
end

function CounterIt:RenderPausedTasks_Native()
  local parent = self.pausedTasksScrollFrame
  if not parent then return end

  -- Eliminar hijos anteriores
  for i = 1, select("#", parent:GetChildren()) do
    select(i, parent:GetChildren()):Hide()
  end

  local tasks = self.globalTasks()
  local paused = {}
  for id, task in pairs(tasks) do
    if task.active == false and task.completed ~= true then
      table.insert(paused, { id = id, data = task })
    end
  end

  local last
  for i, entry in ipairs(paused) do
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(PANEL_WIDTH - 60, LIST_ITEM_HEIGHT)
    btn:SetText(entry.data.description)
    btn:SetPoint("TOPLEFT", 0, -((i - 1) * (LIST_ITEM_HEIGHT + 4)))
    btn:SetScript("OnClick", function()
      self.selectedPausedTask = entry.id
      self:RenderPausedTasks_Native()
    end)

    if self.selectedPausedTask == entry.id then
      btn:GetFontString():SetTextColor(1, 1, 0)
    else
      btn:GetFontString():SetTextColor(1, 1, 1)
    end

    last = btn
  end

  local totalHeight = (#paused * (LIST_ITEM_HEIGHT + 4)) + 8
  parent:SetHeight(totalHeight)
end

function CounterIt:AddTopButtons_Native()
  local f = self.taskManagerFrame
  if not f then return end

  local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  addBtn:SetText(L["ADD_TASK"] or "Añadir tarea")
  addBtn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
  addBtn:SetPoint("TOPLEFT", 16, -10)
  addBtn:SetScript("OnClick", function() self:OpenTaskEditor(nil) end)

  local tplBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  tplBtn:SetText(L["FROM_TEMPLATE"] or "Desde plantilla")
  tplBtn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
  tplBtn:SetPoint("LEFT", addBtn, "RIGHT", 8, 0)
  tplBtn:SetScript("OnClick", function() self:OpenTemplateSelector() end)

  local monBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  monBtn:SetText(L["OPEN_MONITOR"] or "Monitor")
  monBtn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
  monBtn:SetPoint("LEFT", tplBtn, "RIGHT", 8, 0)
  monBtn:SetScript("OnClick", function() self:OpenActiveTasksMonitor() end)
end

function CounterIt:AddBottomButtons_Native()
  local f = self.taskManagerFrame
  if not f then return end

  local activateBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  activateBtn:SetText(L["ACTIVATE"] or "Activar")
  activateBtn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
  activateBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 16)
  activateBtn:SetScript("OnClick", function()
    if self.selectedPausedTask then
      local tasks = self.globalTasks()
      tasks[self.selectedPausedTask].active = true
      self.selectedPausedTask = nil
      self:RenderPausedTasks_Native()
      if self.activeMonitorFrame then self:RenderActiveTasks() end
    end
  end)

  local editBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  editBtn:SetText(L["EDIT"] or "Editar")
  editBtn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
  editBtn:SetPoint("LEFT", activateBtn, "RIGHT", 8, 0)
  editBtn:SetScript("OnClick", function()
    if self.selectedPausedTask then
      self:OpenTaskEditor(self.selectedPausedTask)
    end
  end)

  local deleteBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  deleteBtn:SetText(L["DELETE"] or "Eliminar")
  deleteBtn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
  deleteBtn:SetPoint("LEFT", editBtn, "RIGHT", 8, 0)
  deleteBtn:SetScript("OnClick", function()
    if self.selectedPausedTask then
      local name = self.selectedPausedTask
      StaticPopupDialogs["COUNTERIT_CONFIRM_DELETE"] = {
        text = L["CONFIRM_DELETE_TASK"] or "¿Eliminar tarea?",
        button1 = L["YES"] or "Sí",
        button2 = L["CANCEL"] or "Cancelar",
        OnAccept = function()
          local tasks = self.globalTasks()
          local counters = self.charCounters()
          tasks[name] = nil
          counters[name] = nil
          self.selectedPausedTask = nil
          self:RenderPausedTasks_Native()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show("COUNTERIT_CONFIRM_DELETE", name)
    end
  end)

  local exportBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  exportBtn:SetText(L["EXPORT_IMPORT"] or "Importar/Exportar")
  exportBtn:SetSize(BUTTON_WIDTH + 60, BUTTON_HEIGHT)
  exportBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
  exportBtn:SetScript("OnClick", function()
    self:OpenExportImportWindow()
  end)
end
