-- Author      : Manel
-- Create Date : 15/06/2025 13:10:15

local L = LibStub("AceLocale-3.0"):NewLocale("CounterIt", "esES")

if not L then return end

L["TITLE"] = "Counter-It"
L["TASK_MANAGER_TITLE"] = "Gestor de Tareas"
L["ACTIVE_MONITOR_TITLE"] = "Tareas Activas"
L["ADD_TASK"] = "Nueva Tarea"
L["FROM_TEMPLATE"] = "Nueva Desde Plantilla"
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

L["MIGRATION_CLEANED_GLOBAL_PROGRESS"] = "Se ha eliminado el progreso global de tareas para habilitar la gestión por personaje."

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

L["TASKS_DEFINED"] = "Tareas DEFINIDAS"

L["EDIT_TASK"] = "Editar tarea"
L["NEW_TASK"] = "Nueva tarea"
L["DEFINE_TASK_DETAILS"] = "Define los detalles de la tarea"

L["CONFIRM_DELETE_TASK"] = "¿Eliminar la tarea '%s' permanentemente?"
L["YES"] = "Sí"
L["CANCEL"] = "Cancelar"

L["ADD_TO_FAVORITES"] = "Añadir a Favoritos"
L["REMOVE_FROM_FAVORITES"] = "Quitar de Favoritos"
L["SHOW_ONLY_FAVORITES"] = "Mostrar solo Favoritas"

L["TASK_SAVE_MISSING"] = "Faltan campos obligatorios."
L["TASK_SAVED"] = "Tarea guardada: %s"
L["TASK_PAUSED"] = "Tareas pausadas"
L["TASK_OBJECTIVE"] = "%s (Objetivo: %d)"
L["TASK_TOOLTIP_OBJECTIVE"] = "Tarea: %s \nObjetivo: %d"
L["SELECT_ICON"] = "Elegir Icono"
L["EDIT_RULE"] = "Editar Regla"
L["STATUSTEXT_NEW_RULE"] = "Define los detalles de la regla"

L["TASK_OBJECTIVE_LABEL"] = "Objetivo"
L["TASK_ICON_LABEL"] = "Icono (opcional)"
L["RULE_TYPE_LABEL"] = "Tipo de regla"
L["RULE_ID_LABEL"] = "ID (opcional para manual)"

L["RULE_MANUAL"] = "Contador manual"
L["RULE_QUEST"] = "Completar misión (questID)"
L["RULE_ITEM"] = "Obtener objeto (itemID)"
L["RULE_SPELL"] = "Lanzar hechizo (spellID)"
L["RULE_PETCAPTURE"] = "Capturar mascotas de duelo"

L["RULE_SPELL_NOT_FOUND"] = "|cffff0000Hechizo no encontrado|r"
L["RULE_SPELLID_NOT_VALID"] = "|cffff0000ID de hechizo no válido|r"

L["RULE_ROLE_LABEL"] = "Role"
L["ROLE_COMPLETION"] = "Completar tarea"
L["ROLE_AUTO_COUNT"] = "Conteo automático"
L["ROLE_ACTIVATION"] = "Activación"
L["NO_ROLE"] = "Sin role"

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

L["side-with-a-cartel-hint"] = "Haber elegido un Cartel para aliarte con él para esta semana"
L["ship-right-hint"] = "Completa 10 trabajos para Envíos y Portes"
L["reclaimed-scrap-hint"] = "Recoger 100 latas de Kaja'Cola vacías de un Montón de C.H.A.T.A.R.R.A"
L["side-gig-hint"] = "Haber completado un trabajo extra. Hay trabajos extra disponibles en el Centro de Transporte principal."
L["war-mode-violence-hint"] = "Derrota a cinco jugadores enemigos en modo guerra en Minahonda"
L["go-fish-hint"] = "A pescar por Minahonda"
L["gotta-catch-at-least-a-few-hint"] = "Captura 5 mascotas salvajes"
L["rare-rivals-hint"] = "Derrota a 3 NPCs raros de Minahonda"
L["clean-the-sidestreets-hint"] = "Finaliza la profundidad Canal Callejero"
L["time-to-vacate-hint"] = "Finaliza la profundidad Excavación 9"
L["desire-to-d-r-i-v-e-hint"] = "Finaliza dos carreras en Minahonda"
L["kaja-cruising-hint"] = "Recolecta turbo-latas mientras conduces tu Partecuellos G-99 (Montura C.A.C.H.A.R.R.O)"
L["garbage-day-hint"] = "Rebuscar en la basura"

L["side-with-a-cartel"] = "Asociarse con un cártel"
L["ship-right"] = "Envío en condiciones"
L["reclaimed-scrap"] = "A tirar la basura"
L["side-gig"] = "Haber completado un trabajo extra"
L["war-mode-violence"] = "Derrota a cinco jugadores"
L["go-fish"] = "A pescar por Minahonda"
L["gotta-catch-at-least-a-few"] = "Hay que pescar unos cuantos"
L["rare-rivals"] = "Rivales poco comunes"
L["clean-the-sidestreets"] = "Despejar los callejones"
L["time-to-vacate"] = "Finaliza la profundidad Excavación 9"
L["desire-to-d-r-i-v-e"] = "Con C.A.R.R.O. y a lo loco"
L["kaja-cruising"] = "Recolecta turbo-latas"
L["garbage-day"] = "Rebuscar en la basura"

-- config
L["GENERAL_OPTIONS"] = "Opciones generales"
L["ENABLE_TRIGGERS"] = "Activar desencadenantes automáticos"
L["ENABLE_TRIGGERS_DESC"] = "Permite que Counter-It active tareas automáticamente según condiciones del juego."
L["ENABLE_TRACKING"] = "Activar seguimiento de tareas"
L["ENABLE_TRACKING_DESC"] = "Permite que las tareas activas se muestren y actualicen en el panel de seguimiento."
L["DEBUG_MODE"] = "Depuración (debugMode)"
L["DEBUG_MODE_DESC"] = "Activa/desactiva el modo depuración para Counter-It."

-- rules
L["ManualRulesFixed"] = "Se han corregido reglas 'manual' sin parámetro 'count'."
L["TemplatesReapplied"] = "Plantillas reaplicadas a %d tareas existentes."
L["ManualRuleFixedDebug"] = "Tarea '%s': regla manual %d no tenía 'count' válido, se ha puesto a %d (goal=%s)"
