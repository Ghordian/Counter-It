-- types.lua

---@class TaskData
---@field taskID string                 -- Identificar único de la tarea
---@field description string            -- Descripción de la tarea
---@field hint? string                  -- Texto adicional (opcional)
---@field goal number                   -- Número objetivo para completarla
---@field icon number|string            -- ID del icono (usualmente un número o ruta)
---@field rules RuleData[]              -- Lista de reglas asociadas
---@field step? number                  -- Paso dentro de una cadena de tareas (opcional)
---@field url? string                   -- URL informativa (opcional)
---@field notes? string                 -- Notas adicionales (opcional)
---@field templateID? string            -- (opcional) ID de plantilla de origen si fue creada desde plantilla

---@class RuleData
---@field type string                  -- Tipo de regla: "manual", "quest", "spell", etc.
---@field count? number                -- Cantidad requerida (manual, item, etc.)
---@field role? string                 -- Rol de la regla: "completion", "activation", "auto-count"
---@field questID? number              -- Para tipo quest
---@field spellID? number              -- Para tipo spell
---@field spellInfo table              -- Para tipo spell
---@field itemID? number               -- Para tipo item
---@field currencyID? number           -- Para tipo currency (currency=2815/cristales-de-resonancia)
---@field event? string                -- Para tipo event

---@alias TasksList table<string, TaskData>  -- Diccionario: clave = taskID, valor = TaskData

-- NUEVO: Estado personal de una tarea para un personaje
---@class CharacterTaskState
---@field taskID string                                  -- ID de la tarea
---@field active boolean                                 -- Si está activa para este personaje
---@field completed boolean                              -- Si está completada por este personaje
---@field progressManual number                          -- para el progreso principal manual
---@field rulesProgress table<number, RuleProgress>      -- Progreso de cada regla, indexado por índice en TaskData.rules

---@class RuleProgress
---@field progress number                                -- Progreso actual de la regla para este personaje
---@field completed boolean                              -- Si está completada esta regla para este personaje

---@alias CharTasksStateList table<string, CharacterTaskState> -- taskID -> estado personal de tarea

---@class CharDBData
---@field tasks CharTasksStateList            -- Estado personal de todas las tareas
---@field enableTracking boolean              -- Si está activo el seguimiento para este personaje
---@field enableTriggers boolean              -- Si están activos los triggers automáticos
---@field debugMode boolean                   -- Si está en modo debug

-- types.lua - fin del archivo
