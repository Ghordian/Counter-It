-- Author      : Manel
-- Create Date : 15/06/2025 17:52:26

-- autotrigger.lua
local CounterIt = LibStub("AceAddon-3.0"):GetAddon("CounterIt")

-- Mapa de reglas: [EVENTO] = { [valor_evento] = taskID o templateID }
CounterIt.AutoTrigger = {
    Rules = {
        QUEST_ACCEPTED = {
          -- https://www.wowhead.com/quest=86915/side-with-a-cartel
          [86915] = "side-with-a-cartel",
          -- https://www.wowhead.com/quest=86917/ship-right
          [86917] = "ship-right",
          -- https://www.wowhead.com/quest=86918/reclaimed-scrap
          [86918] = "reclaimed-scrap",
          -- https://www.wowhead.com/quest=86919/side-gig
          [86919] = "side-gig",
          -- https://www.wowhead.com/quest=86920/war-mode-violence
          [86920] = "war-mode-violence",
          -- https://www.wowhead.com/quest=86923/go-fish
          [86923] = "go-fish",
          -- https://www.wowhead.com/quest=86924/gotta-catch-at-least-a-few
          [86924] = "gotta-catch-at-least-a-few",
          -- https://www.wowhead.com/quest=87302/rare-rivals
          [87302] = "rare-rivals",
          -- https://www.wowhead.com/quest=87303/clean-the-sidestreets
          [87303] = "clean-the-sidestreets",
          -- https://www.wowhead.com/quest=87304/time-to-vacate
          [87304] = "time-to-vacate",
          -- https://www.wowhead.com/quest=87305/desire-to-d-r-i-v-e
          [87305] = "desire-to-d-r-i-v-e",
          -- https://www.wowhead.com/quest=87306/kaja-cruising
          [87306] = "kaja-cruising",
          -- https://www.wowhead.com/quest=87307/garbage-day
          [87307] = "garbage-day",
        },
        ITEM_RECEIVED = {
            [235053] = { 
              "garbage-day",
              "kaja-cruising",
              "desire-to-d-r-i-v-e",
              "time-to-vacate",
              "clean-the-sidestreets",
              "rare-rivals",
              "gotta-catch-at-least-a-few",
              "go-fish",
              "war-mode-violence",
              "side-gig",
              "reclaimed-scrap",
              "ship-right",
              "side-with-a-cartel"
            },
        },
    },

    -- API: devolver ID asociado al evento y valor
    GetTaskFromEvent = function (self, event, value)
      local eventMap = self.Rules[event]
      if not eventMap then return nil end
      local result = eventMap[value]
      if not result then return nil end
      if type(result) == "table" then
        return result -- lista de plantillas
      else
        return { result } -- normaliza a lista
      end
    end,

    Register = function(self, event, key, target)
      self.Rules[event] = self.Rules[event] or {}
      self.Rules[event][key] = target
    end,
}

-----------------------------------------------------
-- COMANDO: /cittriggers para listar reglas automáticas
-----------------------------------------------------

SLASH_CITTRIGGERS1 = "/cittriggers"
SlashCmdList["CITTRIGGERS"] = function()
  print("=== Counter-It: Reglas Automaticas ===")

  local foundAny = false

  for event, table in pairs(CounterIt.AutoTrigger.Rules or {}) do
    print("Evento: " .. event)
    for key, id in pairs(table) do
      foundAny = true
      local exists = CounterIt:IsTemplate(id) and "Plantilla"
                or (CounterIt:TaskExists(id) and "Tarea")
                or "! No existe"
      print(string.format("   [%s] ! %s (%s)", tostring(key), tostring(id), exists))
    end
  end

  if not foundAny then
    print("No se han definido triggers automaticos.")
  end
end
