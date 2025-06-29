-- config.lua
local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")
local L = LibStub("AceLocale-3.0"):GetLocale("CounterIt")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

local options = {
  type = "group",
  name = "Counter-It",
  args = {
    general = {
      type = "group",
      name = L["GENERAL_OPTIONS"],
      order = 1,
      args = {
        enableTriggers = {
          type = "toggle",
          name = L["ENABLE_TRIGGERS"],
          desc = L["ENABLE_TRIGGERS_DESC"],
          get = function() return CounterIt.db.profile.enableTriggers end,
          set = function(_, val)
            CounterIt.db.profile.enableTriggers = val 
            if val then
              if CounterIt.RegisterRelevantEvents then
                CounterIt:RegisterRelevantEvents()
              end
            else
              if CounterIt.UnregisterRelevantEvents then
                CounterIt:UnregisterRelevantEvents()
              end
            end
          end,
        },
        enableTracking = {
          type = "toggle",
          name = L["ENABLE_TRACKING"],
          desc = L["ENABLE_TRACKING_DESC"],
          get = function() return CounterIt.db.profile.enableTracking end,
          set = function(_, val) CounterIt.db.profile.enableTracking = val end,
        },
      },
    },
  },
}

function CounterIt:InitConfig()
  AceConfig:RegisterOptionsTable("CounterIt", options)
  AceConfigDialog:AddToBlizOptions("CounterIt", "Counter-It")

  local profiles = AceDBOptions:GetOptionsTable(self.db)
  AceConfig:RegisterOptionsTable("CounterIt_Profiles", profiles)
  AceConfigDialog:AddToBlizOptions("CounterIt_Profiles", "Profiles", "Counter-It")
end
