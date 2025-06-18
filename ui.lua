local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")

local AceGUI = LibStub("AceGUI-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt")

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

-- Panel principal de tareas pausadas
-- Constantes para el gestor de tareas
local TASKMANAGER_MIN_WIDTH = 400
local TASKMANAGER_MIN_HEIGHT = 500
local TASKMANAGER_DEFAULT_WIDTH = 400
local TASKMANAGER_DEFAULT_HEIGHT = 500
local TASKMANAGER_SCROLL_OFFSET = 220
local TASKMANAGER_SCROLL_MIN = 100
local BUTTON_WIDTH = 100

-- Reestructurado con diseño Fill y separación en top/bottom
function CounterIt:OpenTaskManager()
  if self.taskManagerFrame then
    self.taskManagerFrame:Release()
  end

  local pos = self.db.global.taskManagerFrame or {}
  local frame = AceGUI:Create("Frame")
  frame:SetTitle(L["TITLE_TASK_MANAGER"])
  frame:SetStatusText(L["STATUSTEXT_TASK_MANAGER"])
  frame:SetLayout("Fill")
--frame:SetWidth(pos.width or TASKMANAGER_DEFAULT_WIDTH)
--frame:SetHeight(pos.height or TASKMANAGER_DEFAULT_HEIGHT)
  frame.frame:SetWidth(pos.width or TASKMANAGER_DEFAULT_WIDTH)
  frame.frame:SetHeight(pos.height or TASKMANAGER_DEFAULT_HEIGHT)

  frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x or 100, pos.y or 100)
  self.taskManagerFrame = frame
--frame.frame:SetMinResize(TASKMANAGER_MIN_WIDTH, TASKMANAGER_MIN_HEIGHT)
--frame:SetMinWidth(TASKMANAGER_MIN_WIDTH) 
--frame:SetMinHeight(TASKMANAGER_MIN_HEIGHT)

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

  self:RenderPausedTasks()

  -- Contenedor inferior fijo
  local bottomGroup = AceGUI:Create("SimpleGroup")
  bottomGroup:SetLayout("Flow")
  bottomGroup:SetFullWidth(true)
  bottomGroup:SetHeight(80)

  local activateButton = AceGUI:Create("Button")
  activateButton:SetText(L["ACTIVATE"])
  activateButton:SetWidth(BUTTON_WIDTH)
  activateButton:SetCallback("OnClick", function()
    if self.selectedPausedTask then
      local tasks = self.globalTasks()
      tasks[self.selectedPausedTask].active = true
      self.selectedPausedTask = nil
      self:RenderPausedTasks()
      if self.activeMonitorFrame then self:RenderActiveTasks() end
    end
  end)
  bottomGroup:AddChild(activateButton)

  local editButton = AceGUI:Create("Button")
  editButton:SetText(L["EDIT"])
  editButton:SetWidth(BUTTON_WIDTH)
  editButton:SetCallback("OnClick", function()
    if self.selectedPausedTask then
      self:OpenTaskEditor(self.selectedPausedTask)
    end
  end)
  bottomGroup:AddChild(editButton)

  local deleteButton = AceGUI:Create("Button")
  deleteButton:SetText(L["DELETE"])
  deleteButton:SetWidth(BUTTON_WIDTH)
  deleteButton:SetCallback("OnClick", function()
    if self.selectedPausedTask then
      local taskName = self.selectedPausedTask
      StaticPopupDialogs["COUNTERIT_CONFIRM_DELETE"] = {
        text = L["CONFIRM_DELETE_TASK"],
        button1 = L["YES"],
        button2 = L["CANCEL"],
        OnAccept = function()
          local tasks = self.globalTasks()
          local counters = self.charCounters()
          tasks[taskName] = nil
          counters[taskName] = nil
          self.selectedPausedTask = nil
          self:RenderPausedTasks()
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

-- Renderizar lista de tareas pausadas
function CounterIt:RenderPausedTasks()
  if not self.pausedTasksScrollFrame then return end

  local group = self.pausedTasksScrollFrame
  group:ReleaseChildren()

  for name, task in pairs(self.globalTasks()) do
    if not task.active then
      local row = AceGUI:Create("SimpleGroup")
      row:SetLayout("Flow")
      row:SetFullWidth(true)
      row:SetHeight(30)

      if task.icon then
        local icon = AceGUI:Create("Label")
        icon:SetImage(task.icon, 24, 24)
        icon:SetWidth(30)
        row:AddChild(icon)
      end

      local label = AceGUI:Create("InteractiveLabel")
      label:SetText( format( L["TASK_OBJECTIVE"], tostring(task.description), tonumber(task.goal) ) )
      label:SetFontObject(GameFontNormal)
      label:SetWidth(260)
      label:SetHeight(30)
      label:SetColor(self.selectedPausedTask == name and 1 or 1, self.selectedPausedTask == name and 1 or 1, self.selectedPausedTask == name and 0 or 1)

      label:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
        GameTooltip:SetText(format(L["TASK_TOOLTIP_OBJECTIVE"], task.description, task.goal))
        GameTooltip:Show()
      end)
      label:SetCallback("OnLeave", GameTooltip_Hide)
      label:SetCallback("OnClick", function()
        self.selectedPausedTask = name
        self:RenderPausedTasks()
      end)

      row:AddChild(label)
      group:AddChild(row)
    end
  end

  -- Espaciador inferior
  local spacer = AceGUI:Create("Label")
  spacer:SetFullWidth(true)
  spacer:SetText(" ")
  group:AddChild(spacer)
end

-- Botonera superior del gestor de tareas
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

-- Botón de compartir tareas
function CounterIt:AddExportImportButton(parentFrame)
  local shareButton = AceGUI:Create("Button")
  shareButton:SetText(L["EXPORT_IMPORT"])
  shareButton:SetFullWidth(true)
  shareButton:SetCallback("OnClick", function()
    self:OpenExportImportWindow()
  end)
  parentFrame:AddChild(shareButton)
end

-- Mostrar ventana flotante con tareas activas
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

-- Mostrar lista de tareas activas con botones de interacción
function CounterIt:RenderActiveTasks()
  if self.activeTasksFrame then
    self.activeTasksFrame:Hide()
    self.activeTasksFrame:SetParent(nil)
    self.activeTasksFrame = nil
  end

  if not self.activeMonitorFrame or not self.activeMonitorFrame.scrollContent then
    -- No hay contenedor visible, no renderizamos nada
    --debug:print("[Counter-It] RenderActiveTasks(): no se encontró un contenedor visible. Abortando.")
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
  local counters = self.charCounters()

  local lastRow
  for name, task in pairs(tasks) do
    if task.active then
      local row = CreateFrame("Frame", nil, container)
      row:SetSize(container:GetWidth(), 28)
      row:SetPoint("TOPLEFT", lastRow or container, lastRow and "BOTTOMLEFT" or "TOPLEFT", 0, lastRow and -4 or 0)

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
        counters[name] = math.max(0, (counters[name] or 0) - 1)
        self:UpdateTaskProgress(name, task)
        self:RenderActiveTasks()
      end)

      local btnInc = createButton("+", 32, function()
        if (counters[name] or 0) < task.goal then
          counters[name] = (counters[name] or 0) + 1
          self:UpdateTaskProgress(name, task)
          self:RenderActiveTasks()
        end
      end)

      local btnReset = createButton("R", 60, function()
        counters[name] = 0
        task.completed = false
        self:UpdateTaskProgress(name, task, true)
          self:Print("Reset on", name)
        self:RenderActiveTasks()
      end)

      local btnPause = createButton("P", 88, function()
        task.active = false
        self:RenderActiveTasks()
        if self.taskManagerFrame then
          self:RenderPausedTasks()
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
      label:SetText((counters[name] or 0) .. " / " .. task.goal)
      label:SetTextColor(task.completed and 0 or 1, task.completed and 1 or 1, 0)
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

-- Editor de tareas personalizadas
function CounterIt:OpenTaskEditor(existingTaskName)
  if self.taskEditor then
    self.taskEditor:ReleaseChildren()
    self.taskEditor:Show()
  else
    self.taskEditor = AceGUI:Create("Frame")
    self.taskEditor:SetTitle(existingTaskName and L["EDIT_TASK"] or L["NEW_TASK"])
    self.taskEditor:SetStatusText(L["DEFINE_TASK_DETAILS"])
    self.taskEditor:SetLayout("List")
    self.taskEditor:SetWidth(450)
    self.taskEditor:SetHeight(500)
    self.taskEditor:SetCallback("OnClose", function(widget)
      AceGUI:Release(widget)
      self.taskEditor = nil
    end)
  end

  local description = AceGUI:Create("EditBox")
  description:SetLabel("Descripción")
  description:SetFullWidth(true)
  self.taskEditor:AddChild(description)

  local objective = AceGUI:Create("EditBox")
  objective:SetLabel("Objetivo")
  objective:SetFullWidth(true)
  objective:SetCallback("OnTextChanged", function(_, _, val)
    if not tonumber(val) then
      objective:SetText("")
    end
  end)
  self.taskEditor:AddChild(objective)

  local icon = AceGUI:Create("EditBox")
  icon:SetLabel("Icono (opcional)")
  icon:SetFullWidth(true)
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

  local task = {}
  if existingTaskName and self.globalTasks()[existingTaskName] then
    task = self.globalTasks()[existingTaskName]
    if not task.rules then task.rules = {} end
    description:SetText(task.description)
    objective:SetText(task.goal)
    icon:SetText(task.icon or "")
  end

  -- Reglas
  local rulesHeader = AceGUI:Create("Label")
  rulesHeader:SetText(L["RULES"])
  self.taskEditor:AddChild(rulesHeader)

  local rulesGroup = AceGUI:Create("InlineGroup")
  rulesGroup:SetLayout("List")
  rulesGroup:SetFullWidth(true)
  rulesGroup:SetFullHeight(true)
  self.taskEditor:AddChild(rulesGroup)

  for i, rule in ipairs(task.rules or {}) do
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
        task.rules[i] = updatedRule
        self:OpenTaskEditor(existingTaskName)
      end)
    end)
    ruleContainer:AddChild(editBtn)

    local delBtn = AceGUI:Create("Button")
    delBtn:SetText(L["DELETE"])
    delBtn:SetWidth(80)
    delBtn:SetCallback("OnClick", function()
      table.remove(task.rules, i)
      self:OpenTaskEditor(existingTaskName)
    end)
    ruleContainer:AddChild(delBtn)

    rulesGroup:AddChild(ruleContainer)
  end

  local addRuleButton = AceGUI:Create("Button")
  addRuleButton:SetText(L["NEW_RULE"])
  addRuleButton:SetCallback("OnClick", function()
    if task.rules == nil then task.rules = {} end
    self:OpenRuleEditor(task, nil, function(newRule)
      table.insert(task.rules, newRule)
      self:OpenTaskEditor(existingTaskName)
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

    local tasks = self.globalTasks()
    tasks[desc] = {
      description = desc,
      goal = goal,
      icon = iconPath ~= "" and iconPath or nil,
      active = task.active or false,
      completed = task.completed or false,
      rules = task.rules or {},
    }

    self:Print(format(L["TASK_SAVED"], desc))
    self.taskEditor:Hide()
    self:RenderActiveTasks()
    self:RenderPausedTasks()
  end)
  self.taskEditor:AddChild(saveButton)
end

-- Editor de reglas
function CounterIt:OpenRuleEditor(task, existingRule, callback)
  local editor = AceGUI:Create("Frame")
  editor:SetTitle(existingRule and L["EDIT_RULE"] or L["NEW_RULE"])
  editor:SetStatusText(L["STATUSTEXT_NEW_RULE"])
  editor:SetLayout("List")
  editor:SetWidth(300)
  editor:SetHeight(200)
  editor:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)

  local typeDropdown = AceGUI:Create("Dropdown")
  typeDropdown:SetLabel("Tipo de regla")
  typeDropdown:SetList({
    manual = "Contador manual",
    quest = "Completar misión (questID)",
    item = "Obtener objeto (itemID)",
    spell = "Lanzar hechizo (spellID)",
    petcapture = "Capturar mascotas de duelo",
  })
  typeDropdown:SetValue(existingRule and existingRule.type or "manual")
  typeDropdown:SetFullWidth(true)
  editor:AddChild(typeDropdown)

  local idBox = AceGUI:Create("EditBox")
  idBox:SetLabel("ID (opcional para manual)")
  idBox:SetFullWidth(true)
  if existingRule then
    idBox:SetText(existingRule.questID or existingRule.itemID or existingRule.spellID or "")
  end
  editor:AddChild(idBox)

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
    end

    callback(rule)
    editor:Hide()
  end)
  editor:AddChild(saveBtn)

  local cancelBtn = AceGUI:Create("Button")
  cancelBtn:SetText(L["CANCEL"])
  cancelBtn:SetFullWidth(true)
  cancelBtn:SetCallback("OnClick", function() editor:Hide() end)
  editor:AddChild(cancelBtn)
end

--[[ v0 Panel principal de tareas pausadas
function CounterIt:v0_OpenTaskManager()
  if self.taskManagerFrame then
    self.taskManagerFrame:Release()
  end

  local pos = self.db.global.taskManagerFrame or {}
  local frame = AceGUI:Create("Frame")
  frame:SetTitle(L["TITLE_TASK_MANAGER"])
  frame:SetStatusText(L["STATUSTEXT_TASK_MANAGER"])
  frame:SetLayout("List")
  frame:SetWidth(pos.width or TASKMANAGER_DEFAULT_WIDTH)
  frame:SetHeight(pos.height or TASKMANAGER_DEFAULT_HEIGHT)
  frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x or 100, pos.y or 100)
  self.taskManagerFrame = frame

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

  -- Botones superiores
  self:AddTopButtons(frame)

  -- Etiqueta
  local pausedLabel = AceGUI:Create("Label")
  pausedLabel:SetText(L["TASK_PAUSED"])
  pausedLabel:SetFullWidth(true)
  frame:AddChild(pausedLabel)

  frame:SetCallback("OnClose", function(widget)
    local point, relativeTo, relativePoint, x, y = frame.frame:GetPoint()
    self.db.global.taskManagerFrame = {
      point = point,
      relativePoint = relativePoint,
      x = x,
      y = y,
      width = frame.frame:GetWidth(),
      height = frame.frame:GetHeight(),
    }
    AceGUI:Release(widget)
    self.taskManagerFrame = nil
  end)

 -- ScrollFrame dentro de un grupo con altura fija
  local scrollGroup = AceGUI:Create("SimpleGroup")
  scrollGroup:SetLayout("Fill")
  scrollGroup:SetFullWidth(true)
  scrollGroup:SetHeight(math.max(TASKMANAGER_SCROLL_MIN, frame.frame:GetHeight() - TASKMANAGER_SCROLL_OFFSET))
  frame:AddChild(scrollGroup)

  local scrollFrame = AceGUI:Create("ScrollFrame")
  scrollFrame:SetLayout("List")
  scrollGroup:AddChild(scrollFrame)
  self.pausedTasksScrollFrame = scrollFrame

  -- Ajustar altura dinámica al redimensionar
  frame:SetCallback("OnSizeChanged", function(widget, width, height)
    local minW, minH = TASKMANAGER_MIN_WIDTH, TASKMANAGER_MIN_HEIGHT
    if width < minW or height < minH then
      widget:SetWidth(math.max(width, minW))
      widget:SetHeight(math.max(height, minH))
    end
    scrollGroup:SetHeight(math.max(TASKMANAGER_SCROLL_MIN, widget.frame:GetHeight() - TASKMANAGER_SCROLL_OFFSET))
  end)

  self:RenderPausedTasks()

  -- Botones inferiores
  local actionsGroup = AceGUI:Create("SimpleGroup")
  actionsGroup:SetLayout("Flow")
  actionsGroup:SetFullWidth(true)

  local activateButton = AceGUI:Create("Button")
  activateButton:SetText(L["ACTIVATE"])
  activateButton:SetWidth(BUTTON_WIDTH)
  activateButton:SetCallback("OnClick", function()
    if self.selectedPausedTask then
      local tasks = self.globalTasks()
      tasks[self.selectedPausedTask].active = true
      self.selectedPausedTask = nil
      self:RenderPausedTasks()
      if self.activeMonitorFrame then self:RenderActiveTasks() end
    end
  end)
  actionsGroup:AddChild(activateButton)

  local editButton = AceGUI:Create("Button")
  editButton:SetText(L["EDIT"])
  editButton:SetWidth(BUTTON_WIDTH)
  editButton:SetCallback("OnClick", function()
    if self.selectedPausedTask then
      self:OpenTaskEditor(self.selectedPausedTask)
    end
  end)
  actionsGroup:AddChild(editButton)

  local deleteButton = AceGUI:Create("Button")
  deleteButton:SetText(L["DELETE"])
  deleteButton:SetWidth(BUTTON_WIDTH)
  deleteButton:SetCallback("OnClick", function()
    if self.selectedPausedTask then
      local taskName = self.selectedPausedTask
      StaticPopupDialogs["COUNTERIT_CONFIRM_DELETE"] = {
        text = L["CONFIRM_DELETE_TASK"],
        button1 = L["YES"],
        button2 = L["CANCEL"],
        OnAccept = function()
          local tasks = self.globalTasks()
          local counters = self.charCounters()
          tasks[taskName] = nil
          counters[taskName] = nil
          self.selectedPausedTask = nil
          self:RenderPausedTasks()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show("COUNTERIT_CONFIRM_DELETE", taskName)
    end
  end)
  actionsGroup:AddChild(deleteButton)

  frame:AddChild(actionsGroup)

  -- Botón de exportar/importar
  self:AddExportImportButton(frame)
end
]]--

--[[ basic Panel principal de tareas pausadas
function CounterIt:basic_OpenTaskManager()
  if self.taskManagerFrame then
    self.taskManagerFrame:Release()
  end

  local pos = self.db.global.taskManagerFrame or {}
  local frame = AceGUI:Create("Frame")
  frame:SetTitle(L["TITLE_TASK_MANAGER"])
  frame:SetStatusText(L["STATUSTEXT_TASK_MANAGER"])
  frame:SetLayout("List")
  frame:SetWidth(pos.width or 400)
  frame:SetHeight(pos.height or 500)
  frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x or 100, pos.y or 100)
  self.taskManagerFrame = frame

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

  -- Botones superiores
  self:AddTopButtons(frame)

  -- Etiqueta
  local pausedLabel = AceGUI:Create("Label")
  pausedLabel:SetText(L["TASK_PAUSED"])
  pausedLabel:SetFullWidth(true)
  frame:AddChild(pausedLabel)

  frame:SetCallback("OnClose", function(widget)
    local point, relativeTo, relativePoint, x, y = frame.frame:GetPoint()
    self.db.global.taskManagerFrame = {
      point = point,
      relativePoint = relativePoint,
      x = x,
      y = y,
      width = frame.frame:GetWidth(),
      height = frame.frame:GetHeight(),
    }
    AceGUI:Release(widget)
    self.taskManagerFrame = nil
  end)

 -- ScrollFrame dentro de un grupo con altura fija
  local scrollGroup = AceGUI:Create("SimpleGroup")
  scrollGroup:SetLayout("Fill")
  scrollGroup:SetFullWidth(true)
  scrollGroup:SetHeight(math.max(100, frame.frame:GetHeight() - 220))
  frame:AddChild(scrollGroup)

  local scrollFrame = AceGUI:Create("ScrollFrame")
  scrollFrame:SetLayout("List")
  scrollGroup:AddChild(scrollFrame)
  self.pausedTasksScrollFrame = scrollFrame

  -- Ajustar altura dinámica al redimensionar
  frame:SetCallback("OnSizeChanged", function(widget, width, height)
    local minW, minH = 350, 300
    if width < minW or height < minH then
      widget:SetWidth(math.max(width, minW))
      widget:SetHeight(math.max(height, minH))
    end
    scrollGroup:SetHeight(math.max(100, widget.frame:GetHeight() - 220))
  end)

  self:RenderPausedTasks()

  -- Botones inferiores
  local actionsGroup = AceGUI:Create("SimpleGroup")
  actionsGroup:SetLayout("Flow")
  actionsGroup:SetFullWidth(true)

  local activateButton = AceGUI:Create("Button")
  activateButton:SetText(L["ACTIVATE"])
  activateButton:SetWidth(100)
  activateButton:SetCallback("OnClick", function()
    if self.selectedPausedTask then
      local tasks = self.globalTasks()
      tasks[self.selectedPausedTask].active = true
      self.selectedPausedTask = nil
      self:RenderPausedTasks()
      if self.activeMonitorFrame then self:RenderActiveTasks() end
    end
  end)
  actionsGroup:AddChild(activateButton)

  local editButton = AceGUI:Create("Button")
  editButton:SetText(L["EDIT"])
  editButton:SetWidth(100)
  editButton:SetCallback("OnClick", function()
    if self.selectedPausedTask then
      self:OpenTaskEditor(self.selectedPausedTask)
    end
  end)
  actionsGroup:AddChild(editButton)

  local deleteButton = AceGUI:Create("Button")
  deleteButton:SetText(L["DELETE"])
  deleteButton:SetWidth(100)
  deleteButton:SetCallback("OnClick", function()
    if self.selectedPausedTask then
      local taskName = self.selectedPausedTask
      StaticPopupDialogs["COUNTERIT_CONFIRM_DELETE"] = {
        text = "¿Eliminar la tarea '%s' permanentemente?",
        button1 = "Sí",
        button2 = "Cancelar",
        OnAccept = function()
          local tasks = self.globalTasks()
          local counters = self.charCounters()
          tasks[taskName] = nil
          counters[taskName] = nil
          self.selectedPausedTask = nil
          self:RenderPausedTasks()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show("COUNTERIT_CONFIRM_DELETE", taskName)
    end
  end)
  actionsGroup:AddChild(deleteButton)

  frame:AddChild(actionsGroup)

  -- Botón de exportar/importar
  self:AddExportImportButton(frame)
end
]]--

-- fin del archivo ui.lua
