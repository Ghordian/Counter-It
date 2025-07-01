-- ui.lua

local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")

local AceGUI = LibStub("AceGUI-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt") 

--- Guarda el estado (posición y tamaño) del panel de gestión de tareas.
function CounterIt:SaveTaskManagerFrameState()
  if not self.taskManagerFrame or not self.taskManagerFrame.frame then return end
  local f = self.taskManagerFrame.frame
  local x, y = f:GetCenter()
  self.db.global.taskManagerFrame = {
    x = x - UIParent:GetLeft(),
    y = y - UIParent:GetBottom(),
    width = f:GetWidth(),
    height = f:GetHeight(),
  }
end

-- Constantes para el gestor de tareas
local TASKMANAGER_MIN_WIDTH = 400
local TASKMANAGER_MIN_HEIGHT = 500
local TASKMANAGER_DEFAULT_WIDTH = 400
local TASKMANAGER_DEFAULT_HEIGHT = 500
local TASKMANAGER_SCROLL_OFFSET = 220
local TASKMANAGER_SCROLL_MIN = 100
local BUTTON_WIDTH = 100

--- Abre el panel de gestión de tareas ("Task Manager") y construye la UI con AceGUI.
function CounterIt:OpenTaskManager()
  if self.taskManagerFrame then
    self.taskManagerFrame:Release()
  end

  local pos = self.db.global.taskManagerFrame or {}
  local frame = AceGUI:Create("Frame")
  frame:SetTitle(L["TITLE_TASK_MANAGER"])
  frame:SetStatusText(L["STATUSTEXT_TASK_MANAGER"])
  frame:SetLayout("Fill")
  frame.frame:SetWidth(pos.width or TASKMANAGER_DEFAULT_WIDTH)
  frame.frame:SetHeight(pos.height or TASKMANAGER_DEFAULT_HEIGHT)
  frame.frame:SetFrameStrata("MEDIUM")

  frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x or 100, pos.y or 100)
  self.taskManagerFrame = frame

  frame.frame:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
      CounterIt:SaveTaskManagerFrameState()
  end)

  frame.frame:SetScript("OnSizeChanged", function(self)
      CounterIt:SaveTaskManagerFrameState()
  end)

  frame:SetCallback("OnClose", function(widget)
    local x, y = frame.frame:GetCenter()
    self.db.global.taskManagerFrame = {
      x = x - UIParent:GetLeft(),
      y = y - UIParent:GetBottom(),
      width = frame.frame:GetWidth(),
      height = frame.frame:GetHeight(),
    }
    AceGUI:Release(widget)
    self.taskManagerFrame = nil
  end)

  frame:SetCallback("OnSizeChanged", function(widget, width, height)
    if width < TASKMANAGER_MIN_WIDTH or height < TASKMANAGER_MIN_HEIGHT then
      width = math.max(width, TASKMANAGER_MIN_WIDTH)
      --widget:SetWidth(width)
      height = math.max(height, TASKMANAGER_MIN_HEIGHT)
      --widget:SetHeight(height)
    end
  end)

  -- Contenedor principal interno
  local mainGroup = AceGUI:Create("SimpleGroup")
  mainGroup:SetLayout("Fill")
  mainGroup:SetFullWidth(true)
  mainGroup:SetFullHeight(true)
  frame:AddChild(mainGroup)

  -- Agrupador interno para top + bottom con layout vertical
  local containerGroup = AceGUI:Create("SimpleGroup")
  containerGroup:SetLayout("List")
  containerGroup:SetFullWidth(true)
  containerGroup:SetFullHeight(true)
  mainGroup:AddChild(containerGroup)

  -- Contenedor superior (scroll y etiquetas)
  local topGroup = AceGUI:Create("SimpleGroup")
  topGroup:SetLayout("List")
  --topGroup:SetFullHeight(true)
  topGroup:SetHeight(math.max(100, frame.frame:GetHeight() - TASKMANAGER_SCROLL_OFFSET))
  topGroup:SetFullWidth(true)

  self:AddTopButtons(topGroup)

  local pausedLabel = AceGUI:Create("Label")
  pausedLabel:SetText(L["TASK_PAUSED"])
  pausedLabel:SetFullWidth(true)
  topGroup:AddChild(pausedLabel)

  local scrollGroup = AceGUI:Create("SimpleGroup")
  scrollGroup:SetLayout("Fill")
  scrollGroup:SetFullWidth(true)
  scrollGroup:SetHeight(math.max(TASKMANAGER_SCROLL_MIN, frame.frame:GetHeight() - TASKMANAGER_SCROLL_OFFSET))
  topGroup:AddChild(scrollGroup)

  local scrollFrame = AceGUI:Create("ScrollFrame")
  scrollFrame:SetLayout("List")
  scrollGroup:AddChild(scrollFrame)
  self.pausedTasksScrollFrame = scrollFrame

  containerGroup:AddChild(topGroup)

  self:RenderAllTasks()

  -- Contenedor inferior fijo
  local bottomGroup = AceGUI:Create("SimpleGroup")
  bottomGroup:SetLayout("Flow")
  bottomGroup:SetFullWidth(true)
  bottomGroup:SetHeight(80)

  local activateButton = AceGUI:Create("Button")
  activateButton:SetText(L["ACTIVATE"])
  activateButton:SetWidth(BUTTON_WIDTH)
  activateButton:SetCallback("OnClick", function()
    if self.selectedTaskID then
    --local tasks = self.globalTasks()
    --tasks[self.selectedTaskID].active = true -- taskID

      local charTasks = self.charDb.char.tasks
      if not charTasks[self.selectedTaskID] then
        charTasks[self.selectedTaskID] = {
          taskID = self.selectedTaskID,
          active = true,
          completed = false,
          progressManual = 0,
          rulesProgress = {},
        }
      else
        charTasks[self.selectedTaskID].active = true
      end

      self.selectedTaskID = nil
      self:RenderAllTasks()
      if self.activeMonitorFrame then self:RenderActiveTasks() end
    end
  end)
  bottomGroup:AddChild(activateButton)

  local editButton = AceGUI:Create("Button")
  editButton:SetText(L["EDIT"])
  editButton:SetWidth(BUTTON_WIDTH)
  editButton:SetCallback("OnClick", function()
    if self.selectedTaskID then
      self:OpenTaskEditor(self.selectedTaskID) -- todo taskID
    end
  end)
  bottomGroup:AddChild(editButton)

  local deleteButton = AceGUI:Create("Button")
  deleteButton:SetText(L["DELETE"])
  deleteButton:SetWidth(BUTTON_WIDTH)
  deleteButton:SetCallback("OnClick", function()
    if self.selectedTaskID then
      local tasks = self.globalTasks()
      local charTasks = self.charDb.char.tasks
      local taskID = self.selectedTaskID -- taskID
      local taskName = tasks[taskID] and tasks[taskID].description or ""
      StaticPopupDialogs["COUNTERIT_CONFIRM_DELETE"] = {
        text = L["CONFIRM_DELETE_TASK"],
        button1 = L["YES"],
        button2 = L["CANCEL"],
        OnAccept = function()
        --local tasks = self.globalTasks()
          tasks[taskID] = nil -- taskID
        --local counters = self.charCounters()
        --counters[taskID] = nil -- taskID
          charTasks[taskID] = nil
          self.selectedTaskID = nil
          self:RenderAllTasks()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show("COUNTERIT_CONFIRM_DELETE", taskName)
    end
  end)
  bottomGroup:AddChild(deleteButton)

  containerGroup:AddChild(bottomGroup)

  -- Botón de exportar/importar
  self:AddExportImportButton(bottomGroup)
end

--- Renderiza la lista completa de tareas en el panel de gestión de tareas.
function CounterIt:RenderAllTasks()
  if not self.pausedTasksScrollFrame then return end

  local group = self.pausedTasksScrollFrame
  group:ReleaseChildren()

  local tasks = self.globalTasks()
  local charTasks = self.charDb.char.tasks or {}

  for taskID, task in pairs(tasks) do
    local row = AceGUI:Create("SimpleGroup")
    row:SetLayout("Flow")
    row:SetFullWidth(true)
    row:SetHeight(30)

    local st = charTasks[taskID]

    -- Check de activación
    local check = AceGUI:Create("CheckBox")
    check:SetValue(st and st.active or false) -- task.active
    check:SetWidth(24)
    check:SetCallback("OnValueChanged", function(widget, event, value)
    --task.active = value
      if not charTasks[taskID] then
        charTasks[taskID] = {
          taskID = taskID,
          active = value,
          completed = false,
          progressManual = 0,
          rulesProgress = {},
        }
      else
        charTasks[taskID].active = value
      end
      self:UpdateTaskProgress(taskID, task) -- name
      if self.activeMonitorFrame then 
        self:RenderActiveTasks()
      end
    end)
    row:AddChild(check)

    -- Icono
    if task.icon then
      local icon = AceGUI:Create("Label")
      icon:SetImage(task.icon, 24, 24)
      icon:SetWidth(30)
      row:AddChild(icon)
    end

    -- Texto de la tarea
    local label = AceGUI:Create("InteractiveLabel")
    label:SetText(format(L["TASK_OBJECTIVE"], tostring(task.description), tonumber(task.goal)))
    label:SetFontObject(GameFontNormal)
    label:SetWidth(260)
    label:SetHeight(30)
    label:SetColor(self.selectedTaskID == taskID and 1 or 1, self.selectedTaskID == taskID and 1 or 1, self.selectedTaskID == taskID and 0 or 1)

    label:SetCallback("OnEnter", function(widget)
      GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
      GameTooltip:SetText(format(L["TASK_TOOLTIP_OBJECTIVE"], task.description, task.goal))
      if task.hint then
        GameTooltip:AddLine(task.hint, 1, 0.9, 0)
      end
      GameTooltip:Show()
    end)
    label:SetCallback("OnLeave", GameTooltip_Hide)
    label:SetCallback("OnClick", function()
      self.selectedTaskID = taskID -- name
      self:RenderAllTasks()
    end)

    row:AddChild(label)
    group:AddChild(row)
  end

  -- Espaciador inferior
  local spacer = AceGUI:Create("Label")
  spacer:SetFullWidth(true)
  spacer:SetText(" ")
  group:AddChild(spacer)
end

--- Añade la botonera superior (crear, plantilla, monitor) al gestor de tareas.
---@param parentFrame table -- Widget AceGUI SimpleGroup destino.
function CounterIt:AddTopButtons(parentFrame)
  local row = AceGUI:Create("SimpleGroup")
  row:SetFullWidth(true)
  row:SetLayout("Flow")

  local addButton = AceGUI:Create("Button")
  addButton:SetText(L["ADD_TASK"])
  addButton:SetWidth(130)
  addButton:SetCallback("OnClick", function() self:OpenTaskEditor(nil) end)
  row:AddChild(addButton)

  local templateButton = AceGUI:Create("Button")
  templateButton:SetText(L["FROM_TEMPLATE"])
  templateButton:SetWidth(130)
  templateButton:SetCallback("OnClick", function() self:OpenTemplateSelector() end)
  row:AddChild(templateButton)

  local monitorButton = AceGUI:Create("Button")
  monitorButton:SetText(L["OPEN_MONITOR"])
  monitorButton:SetWidth(120)
  monitorButton:SetCallback("OnClick", function() self:OpenActiveTasksMonitor() end)
  row:AddChild(monitorButton)

  parentFrame:AddChild(row)
end

--- Añade el botón de exportar/importar tareas al gestor de tareas.
---@param parentFrame table -- Widget AceGUI SimpleGroup destino.
function CounterIt:AddExportImportButton(parentFrame)
  local shareButton = AceGUI:Create("Button")
  shareButton:SetText(L["EXPORT_IMPORT"])
  shareButton:SetFullWidth(true)
  shareButton:SetCallback("OnClick", function()
    self:OpenExportImportWindow()
  end)
  parentFrame:AddChild(shareButton)
end

--- Abre la ventana flotante de monitor de tareas activas.
function CounterIt:OpenActiveTasksMonitor()
  if self.activeMonitorFrame then
    self.activeMonitorFrame:Show()
    return
  end

  local pos = self.db.global.activeMonitorFrame or {}
  local frame = CreateFrame("Frame", "CounterItMonitorFrame", UIParent, "BackdropTemplate")
  frame:SetSize(pos.width or 400, pos.height or 400)
  if pos.point and pos.x and pos.y then
    frame:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x, pos.y)
  else
    frame:SetPoint("CENTER")
  end

  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self)
    frame:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    CounterIt.db.global.activeMonitorFrame = {
      point = point,
      relativePoint = relativePoint,
      x = xOfs,
      y = yOfs,
      width = self:GetWidth(),
      height = self:GetHeight(),
    }
  end)
  frame:SetResizable(true)
  frame:SetScript("OnSizeChanged", function(self, width, height)
    local minW, minH = 300, 200
    if width < minW or height < minH then
      self:SetSize(math.max(width, minW), math.max(height, minH))
    end
  end)
  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  frame:SetBackdropColor(0, 0, 0, 0.7)

  -- Título
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  title:SetText(L["ACTIVE_MONITOR_TITLE"])
  title:SetPoint("TOP", 0, -10)

  -- Botones
  local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  closeBtn:SetText(L["CLOSE"])
  closeBtn:SetSize(80, 22)
  closeBtn:SetPoint("BOTTOMRIGHT", -10, 10)
  closeBtn:SetScript("OnClick", function() frame:Hide() end)

  local pausedBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  pausedBtn:SetText(L["TASK_MANAGER_TITLE"])
  pausedBtn:SetSize(120, 22)
  pausedBtn:SetPoint("BOTTOMLEFT", 10, 10)
  pausedBtn:SetScript("OnClick", function() self:OpenTaskManager() end)

  -- Scroll
  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 10, -30)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(1, 1)
  scrollFrame:SetScrollChild(content)

  frame.scrollContent = content

  self.activeMonitorFrame = frame

  -- Añadir grip para redimensionar
  local resize = CreateFrame("Frame", nil, frame)
  resize:SetSize(16, 16)
  resize:SetPoint("BOTTOMRIGHT")
  resize:EnableMouse(true)
  resize:SetScript("OnMouseDown", function()
    frame:StartSizing("BOTTOMRIGHT")
  end)
  resize:SetScript("OnMouseUp", function()
    frame:StopMovingOrSizing()
  end)

  resize.texture = resize:CreateTexture(nil, "BACKGROUND")
  resize.texture:SetAllPoints(true)
  resize.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  resize:SetFrameStrata("HIGH")
  resize:SetAlpha(0.7)

  self:RenderActiveTasks()
end

--- Renderiza la lista de tareas activas y sus controles de interacción.
function CounterIt:RenderActiveTasks()
  if self.activeTasksFrame then
    self.activeTasksFrame:Hide()
    self.activeTasksFrame:SetParent(nil)
    self.activeTasksFrame = nil
  end

  if not self.activeMonitorFrame or not self.activeMonitorFrame.scrollContent then
    -- No hay contenedor visible, no renderizamos nada
    --self:Debug("[Counter-It] RenderActiveTasks(): no se encontró un contenedor visible. Abortando.")
    return
  end

  local parent = self.activeMonitorFrame.scrollContent

  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(parent:GetWidth(), 1)
  container:SetPoint("TOPLEFT", 0, 0)
  container:SetPoint("TOPRIGHT", 0, 0)
  container:SetHeight(100)
  self.activeTasksFrame = container

  local tasks = self.globalTasks()
--local counters = self.charCounters()
  local charTasks = self.charDb.char.tasks or {}

  local lastRow
  for taskID, task in pairs(tasks) do
  --if task.active then
    local st = charTasks[taskID]
    if st and st.active then
      local row = CreateFrame("Frame", nil, container)
      row:SetSize(container:GetWidth(), 28)
      row:SetPoint("TOPLEFT", lastRow or container, lastRow and "BOTTOMLEFT" or "TOPLEFT", 0, lastRow and -4 or 0)

      local hasManualRule = self:TaskAllowsManualControl(task)
      local progress = st.progressManual or 0

      -- Botones: -, +, R, P
      local function createButton(label, xOffset, onClick)
        local b = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        b:SetSize(24, 24)
        b:SetText(label)
        b:SetPoint("LEFT", row, "LEFT", xOffset, 0)
        b:SetScript("OnClick", onClick)
        return b
      end

      local btnDec = createButton("-", 4, function()
      --counters[taskID] = math.max(0, (counters[taskID] or 0) - 1)
        st.progressManual = math.max(0, (st.progressManual or 0) - 1)
        self:UpdateTaskProgress(taskID, task)
        self:RenderActiveTasks()
      end)
      btnDec:SetEnabled(hasManualRule)

      local btnInc = createButton("+", 32, function()
      --if (counters[taskID] or 0) < task.goal then
        if st.progressManual < (task.goal or 1) then
        --counters[taskID] = (counters[taskID] or 0) + 1
          st.progressManual = (st.progressmanual or 0) + 1
          self:UpdateTaskProgress(taskID, task)
          self:RenderActiveTasks()
        end
      end)
      btnInc:SetEnabled(hasManualRule)

      local btnReset = createButton("R", 60, function()
        st.progressManual = 0
        st.completed = false
      --counters[taskID] = 0
      --task.completed = false
        local bRefresh = self:UpdateTaskProgress(taskID, task, true)
        if bRefresh then
          self:Print("Reset on", taskID)
          self:RenderActiveTasks()
        end
      end)

      local btnPause = createButton("P", 88, function()
      --task.active = false
        st.active = false
        self:RenderActiveTasks()
        if self.taskManagerFrame then
          self:RenderAllTasks()
        end
      end)

      -- Icono
      local icon = CreateFrame("Frame", nil, row)
      icon:SetSize(24, 24)
      icon.texture = icon:CreateTexture(nil, "BACKGROUND")
      icon.texture:SetAllPoints(true)
      icon.texture:SetTexture(task.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
      icon:SetPoint("LEFT", btnPause, "RIGHT", 8, 0)

      -- Contador
      local textCount = CreateFrame("Frame", nil, row)
      textCount:SetSize(50, 24)
      local label = textCount:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      local progress = (st.progressManual or 0)
      --progress = self:GetTaskProgress(task, progress)--REJECTED--TODO
      label:SetText(progress .. " / " .. task.goal or 1)
      label:SetTextColor(st.completed and 0 or 1, st.completed and 1 or 1, 0)
      label:SetAllPoints(true)
      textCount:SetPoint("LEFT", icon, "RIGHT", 8, 0)

      -- Descripción
      local desc = CreateFrame("Frame", nil, row)
      desc:SetSize(140, 24)
      local descLabel = desc:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      descLabel:SetJustifyH("LEFT")
      descLabel:SetJustifyV("MIDDLE")
      descLabel:SetText(task.description or "")
      descLabel:SetAllPoints(true)
      desc:SetPoint("LEFT", textCount, "RIGHT", 8, 0)

      lastRow = row
    end
  end

  local totalHeight = (lastRow and lastRow:GetBottom() and math.abs(lastRow:GetBottom() - container:GetTop()) + 32) or 100
  container:SetHeight(totalHeight)
end

--- Renderiza la lista de reglas asociadas a una tarea.
---@param rulesGroup table    -- Widget AceGUI destino.
---@param task TaskData       -- Tarea a la que pertenecen las reglas.
---@param taskID string       -- ID de la tarea.
function CounterIt:RenderRules(rulesGroup, task, taskID) -- existingTaskName
  rulesGroup:ReleaseChildren()

  for idx, rule in ipairs(task.rules or {}) do
    local ruleContainer = AceGUI:Create("SimpleGroup")
    ruleContainer:SetLayout("Flow")
    ruleContainer:SetFullWidth(true)

    local ruleLabel = AceGUI:Create("Label")
    ruleLabel:SetText(rule.type .. (rule.questID and ": " .. rule.questID or "") .. (rule.itemID and ": " .. rule.itemID or "") .. (rule.spellID and ": " .. rule.spellID or ""))
    ruleLabel:SetWidth(200)
    ruleContainer:AddChild(ruleLabel)

    local editBtn = AceGUI:Create("Button")
    editBtn:SetText(L["EDIT"])
    editBtn:SetWidth(80)
    editBtn:SetCallback("OnClick", function()
      self:OpenRuleEditor(task, rule, function(updatedRule)
        task.rules[idx] = updatedRule
        self:RenderRules(rulesGroup, task, taskID) -- existingTaskName
      end)
    end)
    ruleContainer:AddChild(editBtn)

    local delBtn = AceGUI:Create("Button")
    delBtn:SetText(L["DELETE"])
    delBtn:SetWidth(80)
    delBtn:SetCallback("OnClick", function()
      table.remove(task.rules, i)
      self:RenderRules(rulesGroup, task, taskID) -- existingTaskName
    end)
    ruleContainer:AddChild(delBtn)

    rulesGroup:AddChild(ruleContainer)
  end
end

--- Abre el editor de tareas personalizadas (nueva o existente).
---@param taskID string?      -- ID de la tarea a editar (opcional).
function CounterIt:OpenTaskEditor(taskID)
  local existingTaskName = (taskID and self.globalTasks()[taskID])
  if self.taskEditor then
    self.taskEditor:ReleaseChildren()
    self.taskEditor:Show()
  else
    self.taskEditor = AceGUI:Create("Frame")
    self.taskEditor:SetTitle( existingTaskName and L["EDIT_TASK"] or L["NEW_TASK"] )
    self.taskEditor:SetStatusText(L["DEFINE_TASK_DETAILS"])
    self.taskEditor:SetLayout("List")
    self.taskEditor:SetWidth(450)
    self.taskEditor:SetHeight(500)
    self.taskEditor:SetCallback("OnClose", function(widget)
      AceGUI:Release(widget)
      self.taskEditor = nil
    end)
  end

  local tasks = self.globalTasks()
  local task = (taskID and tasks[taskID]) or {}

  local description = AceGUI:Create("EditBox")
  description:SetLabel(L["TASK_DESCRIPTION"])
  description:SetFullWidth(true)
  description:SetText(task.description or "")
  self.taskEditor:AddChild(description)

  local objective = AceGUI:Create("EditBox")
  objective:SetLabel(L["TASK_GOAL"])
  objective:SetFullWidth(true)
  objective:SetText(task.goal or "")
  objective:SetCallback("OnTextChanged", function(_, _, val)
    if not tonumber(val) then
      objective:SetText("")
    end
  end)
  self.taskEditor:AddChild(objective)

  local icon = AceGUI:Create("EditBox")
  icon:SetLabel(L["TASK_ICON_LABEL"])
  icon:SetFullWidth(true)
  icon:SetText(task.icon or "")
  self.taskEditor:AddChild(icon)

  local iconSelectBtn = AceGUI:Create("Button")
  iconSelectBtn:SetText(L["SELECT_ICON"])
  iconSelectBtn:SetWidth(120)
  iconSelectBtn:SetCallback("OnClick", function()
    self:OpenIconSelector(function(selectedIcon)
      icon:SetText(selectedIcon)
    end)
  end)
  self.taskEditor:AddChild(iconSelectBtn)

  -- Reglas
  local rulesHeader = AceGUI:Create("Label")
  rulesHeader:SetText(L["RULES"])
  self.taskEditor:AddChild(rulesHeader)

  local rulesGroup = AceGUI:Create("InlineGroup")
  rulesGroup:SetLayout("List")
  rulesGroup:SetFullWidth(true)
  rulesGroup:SetFullHeight(true)
  self.taskEditor:AddChild(rulesGroup)

  self:RenderRules(rulesGroup, task, taskID) -- existingTaskName

  local addRuleButton = AceGUI:Create("Button")
  addRuleButton:SetText(L["NEW_RULE"])
  addRuleButton:SetCallback("OnClick", function()
    if task.rules == nil then task.rules = {} end
    self:OpenRuleEditor(task, nil, function(newRule)
      table.insert(task.rules, newRule)

      self:RenderRules(rulesGroup, task, taskID) -- existingTaskName

    end)
  end)

  local addRuleContainer = AceGUI:Create("SimpleGroup")
  addRuleContainer:SetFullWidth(true)
  addRuleContainer:SetLayout("Flow")
  addRuleContainer:AddChild(addRuleButton)
  self.taskEditor:AddChild(addRuleContainer)

  local saveButton = AceGUI:Create("Button")
  saveButton:SetText(L["SAVE"])
  saveButton:SetFullWidth(true)
  saveButton:SetCallback("OnClick", function()
    local desc = description:GetText()
    local goal = tonumber(objective:GetText())
    local iconPath = icon:GetText()

    if desc == "" or not goal then
      self:Print(L["TASK_SAVE_MISSING"])
      return
    end

    local id = taskID or task.id or "custom-"..date("%Y%m%d-%H%M%S").."-"..math.random(10000,99999) 
    tasks[id] = {
      id = id,
      description = desc,
      goal = goal,
      icon = iconPath ~= "" and iconPath or nil,
      active = task.active or false,
      completed = task.completed or false,
      rules = task.rules or {},
      hint = task.hint,
      templateID = task.templateID,
      url = task.url,
      step = task.step,
    }

    self:Print(format(L["TASK_SAVED"], desc))
    self.taskEditor:Hide()
    self:RenderActiveTasks()
    self:RenderAllTasks()
  end)
  self.taskEditor:AddChild(saveButton)
end

--- Abre el editor para una regla de una tarea.
---@param task TaskData                        -- Tarea a la que pertenece la regla.
---@param existingRule? RuleData               -- Regla existente (opcional).
---@param callback fun(rule: RuleData)         -- Función callback a ejecutar tras guardar.
function CounterIt:OpenRuleEditor(task, existingRule, callback)
  local editor = AceGUI:Create("Frame")
  editor:SetTitle(existingRule and L["EDIT_RULE"] or L["NEW_RULE"])
  editor:SetStatusText(L["STATUSTEXT_NEW_RULE"])
  editor:SetLayout("List")
  editor:SetWidth(350)
  editor:SetHeight(250)
  editor:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)

  local typeDropdown = AceGUI:Create("Dropdown")
  typeDropdown:SetLabel(L["RULE_TYPE_LABEL"])
  typeDropdown:SetList({
    manual = L["RULE_MANUAL"],
    quest = L["RULE_QUEST"],
    item = L["RULE_ITEM"],
    spell = L["RULE_SPELL"],
    petcapture = L["RULE_PETCAPTURE"],
  })
  typeDropdown:SetValue(existingRule and existingRule.type or "manual")
  typeDropdown:SetFullWidth(true)
  editor:AddChild(typeDropdown)

  local idBox = AceGUI:Create("EditBox")
  idBox:SetLabel(L["RULE_ID_LABEL"])
  idBox:SetFullWidth(true)
  if existingRule then
    idBox:SetText(existingRule.questID or existingRule.itemID or existingRule.spellID or "")
  end
  editor:AddChild(idBox)

  local rule_spellInfo = existingRule and existingRule.spellInfo or {}
  local spellInfoLabel = AceGUI:Create("Label")
  spellInfoLabel:SetFullWidth(true)
  editor:AddChild(spellInfoLabel)

  idBox:SetCallback("OnTextChanged", function(widget, event, text)
    -- Solo buscar para reglas tipo 'spell'
    if typeDropdown:GetValue() == "spell" then
      local spellID = tonumber(text)
      if spellID then
        local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
        if spellInfo and spellInfo.name then
          spellInfoLabel:SetText("|T" .. (spellInfo.iconFileID or "Interface\\Icons\\INV_Misc_QuestionMark") .. ":18:18:0:0|t " .. spellInfo.name)
          rule_spellInfo = spellInfo
        else
          spellInfoLabel:SetText("|cffff0000Hechizo no encontrado|r")
        end
      else
        spellInfoLabel:SetText("|cffff0000ID no válido|r")
      end
    else
      spellInfoLabel:SetText("")
    end
  end)

  typeDropdown:SetCallback("OnValueChanged", function()
    local text = idBox:GetText()
    if typeDropdown:GetValue() == "spell" then
      local spellID = tonumber(text)
      if spellID then
        local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
        if spellInfo and spellInfo.name then
          spellInfoLabel:SetText("|T" .. (spellInfo.iconFileID or "Interface\\Icons\\INV_Misc_QuestionMark") .. ":18:18:0:0|t " .. spellInfo.name)
        else
          spellInfoLabel:SetText(L["RULE_SPELL_NOT_FOUND"])
        end
      else
        spellInfoLabel:SetText(l["RULE_SPELLID_NOT_VALID"])
      end
    else
      spellInfoLabel:SetText("")
    end
  end)

  local saveBtn = AceGUI:Create("Button")
  saveBtn:SetText(L["SAVE"])
  saveBtn:SetFullWidth(true)
  saveBtn:SetCallback("OnClick", function()
    local ruleType = typeDropdown:GetValue()
    local id = tonumber(idBox:GetText())
    local rule = { type = ruleType }

    if ruleType == "quest" then
      rule.questID = id
    elseif ruleType == "item" then
      rule.itemID = id
    elseif ruleType == "spell" then
      rule.spellID = id
      rule.spellInfo = rule_spellInfo
      rule.role = id
    elseif ruleType == "manual" then
      rule.count = id
      if not rule.count or rule.count <= 0 then
        rule.count = task.goal or 1
      end
    end

    callback(rule)
    editor:Hide()
  end)
  editor:AddChild(saveBtn)

end

-- ui.lua - fin del archivo 
