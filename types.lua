-- types.lua

---@class TaskData
---@field taskID string                 -- Identificar único de la tarea
---@field description string            -- Descripción de la tarea
---@field goal number                   -- Número objetivo para completarla
---@field icon number|string            -- ID del icono (usualmente un número o ruta)
---@field rules RuleData[]              -- Lista de reglas asociadas
---@field active boolean                -- Si está activa
---@field completed boolean             -- Si está completada
---@field step? number                  -- Paso dentro de una cadena de tareas (opcional)
---@field url? string                   -- URL informativa (opcional)
---@field notes? string                 -- Notas adicionales (opcional)

---@class RuleData
---@field type string                  -- Tipo de regla: "manual", "quest", "spell", etc.
---@field count? number                -- Cantidad requerida (manual, item, etc.)
---@field progress? number             -- Progreso actual
---@field completed boolean            -- Si está completada
---@field role? string                 -- Rol de la regla: "completion", "activation", "auto-count"
---@field questID? number              -- Para tipo quest
---@field spellID? number              -- Para tipo spell
---@field spellInfo table              -- Para tipo spell
---@field itemID? number               -- Para tipo item
---@field object? number               -- Para tipo object (como fishing nodes)
---@field event? string                -- Para tipo event

---@class TasksList; tabla de tareas global definidas

---@class CounterList: tabla de contador de progreso de tareas por personaje

-- types.lua - fin del archivo
