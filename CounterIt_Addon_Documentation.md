# 📘 Counter-It Addon para World of Warcraft (Retail 11.1.5)

## 🎯 Propósito del addon

`Counter-It` permite a los jugadores crear y gestionar **tareas personalizadas** con condiciones de progreso manual o automático. Es útil para objetivos personales, farmeo, rutinas repetitivas, etc.

---

## 🗂️ Estructura de una tarea

Cada **tarea** contiene:

- `description`: texto libre para identificarla.
- `goal`: valor numérico como meta de progreso.
- `rules`: lista de condiciones (ver más abajo).
- `icon`: ruta a ícono (estándar o personalizado).
- `active`: si está activa (visible en el monitor).
- `completed`: calculado automáticamente.

---

## ⚙️ Dependencias

Este addon utiliza [Ace3](https://www.wowace.com/projects/ace3) y otras librerías:

- **AceAddon-3.0**: estructura del addon, eventos.
- **AceConsole-3.0**: registro de comandos.
- **AceGUI-3.0**: construcción de la interfaz.
- **AceDB-3.0**: almacenamiento de configuración.
- **LibDataBroker + LibDBIcon**: ícono en minimapa.
- **AceSerializer + LibDeflate**: exportación/importación.

---

## 📐 Interfaz de Usuario

### 1. 🧭 Gestor de Tareas Pausadas

Abierto con `/counterit` o `/ci`:

- Movible y redimensionable, recuerda su posición.
- Botones:
  - [Nueva Tarea]
  - [Desde Plantilla]
  - [Abrir Monitor]
  - [Exportar/Importar]
- Lista de tareas pausadas con acciones:
  - [Activar] [Editar] [Eliminar]

### 2. 📊 Monitor de Tareas Activas

Abierto con `/cit`:

- Marco flotante y redimensionable.
- Muestra:
  ```
  [−][+][R][P] [🧱] 4 / 10  |  Recolectar hongos
  ```
- Botones:
  - `−` y `+`: ajustar manualmente el contador.
  - `R`: reinicia progreso.
  - `P`: pausa la tarea.

### 3. 🧪 Editor de Reglas

- Selección del tipo: `manual`, `quest`, `spell`, etc.
- Campo para `ID` (opcional según tipo).
- [Guardar] / [Cancelar]

### 4. 🖼️ Selector de Iconos *(en desarrollo)*

- Basado en `IconSelectorPopupFrameTemplate`.
- Permitirá elegir íconos de la interfaz estándar.
- Actualmente muestra ícono predeterminado.

---

## 🧭 Icono del Minimapa

Implementado mediante `LibDataBroker` y `LibDBIcon`:

```lua
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("CounterIt", {
  type = "data source",
  text = "Counter-It",
  icon = "Interface\AddOns\Counter-It\Media\icon",
  OnClick = function(_, button)
    if button == "LeftButton" then CounterIt:OpenTaskManager()
    elseif button == "RightButton" then CounterIt:OpenActiveTasksMonitor()
    end
  end,
  OnTooltipShow = function(tooltip)
    tooltip:AddLine("Counter-It")
    tooltip:AddLine("Izquierdo: Gestor de tareas")
    tooltip:AddLine("Derecho: Monitor activo")
  end,
})
```

---

## 📈 Tipos de reglas soportadas

| Tipo        | Campo requerido  | Descripción                                           |
|-------------|------------------|-------------------------------------------------------|
| `manual`    | ninguno          | Contador manejado manualmente por el jugador         |
| `quest`     | `questID`        | Detecta misión completada via `C_QuestLog`           |
| `item`      | `itemID`         | Verifica si el objeto está en las bolsas             |
| `spell`     | `spellID` o `spellName` | Detecta lanzamientos de hechizos              |
| `petcapture`| ninguno          | Incrementa con captura de mascota (`PET_BATTLE_CAPTURED`) |

---

## 📦 Exportar e Importar Tareas

- Exporta tareas como texto comprimido y codificado.
- Puede compartirse por chat o copiarse/pegarse.
- Compatible con múltiples reglas y estado activo.

---

## 💾 Persistencia de Datos

```lua
CounterIt.db = {
  global = {
    taskManagerFrame = { x, y, width, height },
    activeMonitorFrame = { x, y, width, height },
    minimap = { hide = false },
    tasks = { [nombreTarea] = { description, rules, icon, ... } }
  },
  char = {
    counters = { [nombreTarea] = progreso }
  }
}
```

---

## 📁 Estructura de Archivos (modular)

```
Counter-It/
├── core.lua           -- Registro del addon y base de datos
├── rules.lua          -- Evaluación de reglas y progreso
├── events.lua         -- Eventos de juego (hechizos, mascotas)
├── templates.lua      -- Plantillas de tareas predefinidas
├── util.lua           -- Exportar/Importar, funciones auxiliares
├── ui.lua             -- Interfaces: gestor, monitor, editores
├── iconselector.lua   -- Selector de iconos (en desarrollo)
└── counter-it.toc     -- Archivo TOC
```

---

## ✅ Comandos disponibles

| Comando             | Acción                                |
|---------------------|----------------------------------------|
| `/counterit` o `/ci`| Abre el gestor de tareas pausadas     |
| `/cit`              | Abre el monitor de tareas activas     |
| `/cshare`           | Abre la ventana de exportar/importar  |
| `/citsim`           | Simula una captura de mascota         |

---

## 💡 Ideas Futuras

- Intercambio de tareas entre jugadores en tiempo real.
- Soporte para logros, muertes, y temporizadores.
- Mejor selector visual de iconos con previsualización.
- Reglas encadenadas, múltiples condiciones lógicas.
- Integración con la UI de seguimiento de misiones.
