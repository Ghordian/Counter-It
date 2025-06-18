-- Author      : Manel
-- Create Date : 15/06/2025 13:10:15

local L = LibStub("AceLocale-3.0"):NewLocale("CounterIt", "esES")

if not L then return end

L["TITLE"] = "Counter-It"
L["TASK_MANAGER_TITLE"] = "Gestor de Tareas"
L["ACTIVE_MONITOR_TITLE"] = "Tareas Activas"
L["ADD_TASK"] = "Nueva Tarea"
L["FROM_TEMPLATE"] = "Desde Plantilla"
L["OPEN_MONITOR"] = "Abrir Monitor"
L["EXPORT_IMPORT"] = "Exportar / Importar"
L["ACTIVATE"] = "Activar"
L["EDIT"] = "Editar"
L["DELETE"] = "Eliminar"
L["TASK_DESCRIPTION"] = "Descripción"
L["TASK_GOAL"] = "Objetivo"
L["TASK_ICON"] = "Icono"
L["SAVE"] = "Guardar"
L["CANCEL"] = "Cancelar"
L["CLOSE"] = "Cerrar"
L["RULES"] = "Reglas"
L["NEW_RULE"] = "Añadir Nueva Regla"
L["TYPE"] = "Tipo"
L["ID"] = "ID"
L["MINIMAP_LEFT"] = "Clic izquierdo: abrir gestor de tareas pausadas"
L["MINIMAP_RIGHT"] = "Clic derecho: abrir monitor de tareas activas"
L["LOADED_MSG"] = "Counter-It cargado. Usa /counterit para gestionar tareas o /cit para seguimiento."

-- util
L["IMPORT_INVALID"] = "Texto no válido."
L["IMPORT_DECOMPRESS_FAIL"] = "No se pudo descomprimir el texto."
L["IMPORT_DESERIALIZE_FAIL"] = "Error al interpretar los datos."
L["IMPORT_SUCCESS"] = "Tareas importadas con éxito."
L["EXPORT_IMPORT_TASKS"] = "Exportar / Importar tareas"
L["COPY_PASTE_TASKS_DATA"] = "Copiar o pegar datos de tareas"
L["TASKS_TEXT"] = "Texto de tareas"
L["EXPORT"] = "Exportar"
L["IMPORT"] = "Importar"

-- ui
L["TITLE_TASK_MANAGER"] = "Counter-It: Gestor de Tareas"
L["STATUSTEXT_TASK_MANAGER"] = "Gestiona tus tareas personalizadas"
L["EDIT_TASK"] = "Editar tarea"
L["NEW_TASK"] = "Nueva tarea"
L["DEFINE_TASK_DETAILS"] = "Define los detalles de la tarea"

L["CONFIRM_DELETE_TASK"] = "¿Eliminar la tarea '%s' permanentemente?"
L["YES"] = "Sí"
L["CANCEL"] = "Cancelar"

L["TASK_SAVE_MISSING"] = "Faltan campos obligatorios."
L["TASK_SAVED"] = "Tarea guardada: %s"
L["TASK_PAUSED"] = "Tareas pausadas"
L["TASK_OBJECTIVE"] = "%s (Objetivo: %d)"
L["TASK_TOOLTIP_OBJECTIVE"] = "Tarea: %s \nObjetivo: %d"
L["SELECT_ICON"] = "Elegir Icono"
L["EDIT_RULE"] = "Editar Regla"
L["STATUSTEXT_NEW_RULE"] = "Define los detalles de la regla"

L["SCROLLFRAME_DEBUG"] = "scrollFrame = %s"

-- events
L["SIMULATE_PET"] = "Simulación de captura de mascota ejecutada."
L["SPELLCAST_ID"] = "CheckSpellCast; %s"
L["SPELLCAST_NAME"] = "CheckSpellCast; %s"
L["SPELLCAST_MATCH"] = "CheckSpellCast; match; %s"

-- template
L["TASK_TEMPLATE_CREATED"] = "Tarea creada desde plantilla: %s"
L["TEMPLATE_NOT_FOUND"] = "Plantilla no encontrada: %s"
L["TITLE_SELECT_TEMPLATE"] = "Seleccionar Plantilla"
L["STATUSTEXT_SELECT_TEMPLATE"] = "Elige una plantilla para crear una tarea"
