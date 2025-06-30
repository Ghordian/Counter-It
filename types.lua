-- types.lua

---@class TaskData
---@field taskID string                 -- Identificar único de la tarea
---@field description string            -- Descripción de la tarea
---@field hint? string                  -- Texto adicional (opcional)
---@field goal number                   -- Número objetivo para completarla
---@field icon number|string            -- ID del icono (usualmente un número o ruta)
---@field rules RuleData[]              -- Lista de reglas asociadas
---@field active boolean                -- Si está activa
---@field completed boolean             -- Si está completada
---@field step? number                  -- Paso dentro de una cadena de tareas (opcional)
---@field url? string                   -- URL informativa (opcional)
---@field notes? string                 -- Notas adicionales (opcional)
---@field templateID? string            -- (opcional) ID de plantilla de origen si fue creada desde plantilla

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

---@alias TasksList table<string, TaskData>  -- Diccionario: clave = taskID, valor = TaskData

---@alias CounterList table<string, number>  -- Diccionario: clave = taskID, valor = progreso numérico

-- types.lua - fin del archivo
