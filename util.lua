local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt")

-- Exportar todas las tareas como texto comprimido
function CounterIt:ExportTasks()
  local exportData = {}
  for name, task in pairs(self.globalTasks()) do
    exportData[name] = {
      description = task.description,
      goal = task.goal,
      icon = task.icon,
      active = task.active,
      completed = task.completed,
      rules = task.rules,
    }
  end

  local serializer = LibStub("AceSerializer-3.0")
  local deflate = LibStub("LibDeflate")
  local serialized = serializer:Serialize(exportData)
  local compressed = deflate:CompressDeflate(serialized)
  local encoded = deflate:EncodeForPrint(compressed)

  return encoded
end

-- Importar tareas desde texto comprimido
function CounterIt:ImportTasks(encoded)
  local deflate = LibStub("LibDeflate")
  local serializer = LibStub("AceSerializer-3.0")
  local decoded = deflate:DecodeForPrint(encoded)
  if not decoded then
    self:Print(L["IMPORT_INVALID"])
    return
  end

  local decompressed = deflate:DecompressDeflate(decoded)
  if not decompressed then
    self:Print(L["IMPORT_DECOMPRESS_FAIL"])
    return
  end

  local success, data = serializer:Deserialize(decompressed)
  if not success then
    self:Print(L["IMPORT_DESERIALIZE_FAIL"])
    return
  end

  for name, task in pairs(data) do
    self.globalTasks()[name] = task
  end

  self:Print(L["IMPORT_SUCCESS"])
  self:RenderPausedTasks()
  self:RenderActiveTasks()
end

-- Ventana gráfica para exportar/importar texto
function CounterIt:OpenExportImportWindow()
  local frame = AceGUI:Create("Frame")
  frame:SetTitle(L["EXPORT_IMPORT_TASKS"])
  frame:SetStatusText(L["COPY_PASTE_TASKS_DATA"])
  frame:SetLayout("Flow")
  frame:SetWidth(400)
  frame:SetHeight(300)

  local editbox = AceGUI:Create("MultiLineEditBox")
  editbox:SetLabel(L["TASKS_TEXT"])
  editbox:SetFullWidth(true)
  editbox:SetNumLines(10)
  frame:AddChild(editbox)

  local exportButton = AceGUI:Create("Button")
  exportButton:SetText(L["EXPORT"])
  exportButton:SetFullWidth(true)
  exportButton:SetCallback("OnClick", function()
    local data = self:ExportTasks()
    editbox:SetText(data)
  end)
  frame:AddChild(exportButton)

  local importButton = AceGUI:Create("Button")
  importButton:SetText(L["IMPORT"])
  importButton:SetFullWidth(true)
  importButton:SetCallback("OnClick", function()
    local text = editbox:GetText()
    self:ImportTasks(text)
  end)
  frame:AddChild(importButton)
end

-- Comprobar si el jugador tiene un objeto en sus bolsas
function CounterIt:HasItem(itemID)
  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local id = GetContainerItemID(bag, slot)
      if id == itemID then
        return true
      end
    end
  end
  return false
end
