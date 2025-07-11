# 📘 Counter-It Addon para World of Warcraft (Retail 11.1.7)

## 🎯 Propósito del addon

`Counter-It` permite a los jugadores crear y gestionar **tareas personalizadas** con condiciones de progreso manual o automático. Es útil para objetivos personales, farmeo, rutinas repetitivas, etc.

---

## 🗂️ Estructura de una tarea

Cada **tarea** contiene:

- `taskID`: identificador único de la tarea.
- `description`: texto libre para identificarla.
- `hint`: texto libre que explica cómo completarla (opcional).
- `goal`: valor numérico como meta de progreso.
- `rules`: lista de condiciones (ver más abajo).
- `icon`: ruta a ícono (estándar o personalizado).
- `step`: paso dentro de una cadena de tareas (opcional).
- `url`: URL informativa (opcional).
- `notes`: notas adicionales (opcional).
- `templateID`: ID de plantilla de origen si fue creada desde plantilla (opcional).
- `isFavorite`: si la tarea está marcada como favorita (opcional).

Además, cada tarea tiene un estado personal por personaje (`CharacterTaskState`) que incluye:
- `taskID`: ID de la tarea.
- `active`: si está activa para este personaje.
- `completed`: si está completada por este personaje.
- `progressManual`: para el progreso principal manual.
- `rulesProgress`: progreso de cada regla asociada, indexado por su posición en `TaskData.rules`.

---

## ⚙️ Dependencias

Este addon utiliza [Ace3](https://www.wowace.com/projects/ace3) y otras librerías:

- **AceAddon-3.0**: estructura del addon, eventos.
- **AceConsole-3.0**: registro de comandos.
- **AceGUI-3.0**: construcción de la interfaz.
- **AceDB-3.0**: almacenamiento de configuración.
- **LibDataBroker + LibDBIcon**: ícono en minimapa.
- **AceSerializer + LibDeflate**: exportación/importación.
- **AceConfig-3.0**: para el panel de configuración.
- **AceConfigDialog-3.0**: para el panel de configuración.
- **AceDBOptions-3.0**: para la gestión de perfiles en el panel de configuración.

---

## 📐 Interfaz de Usuario

### 1. 🧭 Gestor de Tareas

Abierto con `/counterit` o `/ci`:

- Movible y redimensionable, recuerda su posición.
- Ahora se muestran **todas las tareas**, no solo las pausadas.
- Cada tarea incluye un **check-box** para activarla o pausarla directamente.
- El estado de completado se recalcula automáticamente al activar una tarea (por ejemplo, si está basada en una misión ya completada, se marcará como terminada inmediatamente).
- Botones:
  - [Nueva Tarea]
  - [Nueva Desde Plantilla]
  - [Abrir Monitor]
  - [Exportar/Importar]
- Lista de tareas con acciones:
  - [Activar/Pausar] [Editar] [Eliminar]

### 2. 📊 Monitor de Tareas Activas

Abierto con `/cit`:

- Marco flotante y redimensionable.
- Muestra:
```

[−][+][R][P] [🧱] 4 / 10  |  Recolectar hongos

````
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
````

-----

## 📈 Tipos de reglas soportadas

Cada regla (`RuleData`) puede tener los siguientes campos:

  - `type`: Tipo de regla (ej. "manual", "quest", "spell", etc.).
  - `count`: Cantidad requerida (para tipos como `manual`, `item`).
  - `role`: Rol de la regla ("completion", "activation", "auto-count").
  - `questID`: Para reglas de tipo `quest`.
  - `spellID`: Para reglas de tipo `spell`.
  - `spellInfo`: Información adicional del hechizo para reglas de tipo `spell`.
  - `itemID`: Para reglas de tipo `item`.
  - `currencyID`: Para reglas de tipo `currency` (ej. `currency=2815/cristales-de-resonancia`).
  - `event`: Para reglas de tipo `event`.

| Tipo        | Campo requerido           | Descripción                                           |
|-------------|---------------------------|-------------------------------------------------------|
| `manual`    | `count` (opcional)        | Contador manejado manualmente por el jugador         |
| `quest`     | `questID`                 | Detecta misión completada vía `C_QuestLog`           |
| `item`      | `itemID`                  | Verifica si el objeto está en las bolsas             |
| `spell`     | `spellID` o `spellInfo`   | Detecta lanzamientos de hechizos                      |
| `petcapture`| ninguno                   | Incrementa con captura de mascota (`PET_BATTLE_CAPTURED`) |
| `currency`  | `currencyID`              | Rastrea una divisa específica                        |
| `event`     | `event`                   | Se activa mediante un evento de juego personalizado  |

-----

## 📦 Exportar e Importar Tareas

  - Exporta tareas como texto comprimido y codificado.
  - Puede compartirse por chat o copiarse/pegarse.
  - Compatible con múltiples reglas y estado activo.

-----

## 💾 Persistencia de Datos

```lua
CounterIt.db = {
  global = {
    taskManagerFrame = { x, y, width, height },
    activeMonitorFrame = { x, y, width, height },
    minimap = { hide = false },
    tasks = { [taskID] = { description, rules, icon, ... } } -- 'tasks' ahora usa taskID como clave.
  },
  char = {
    tasks = { [taskID] = { active, completed, progressManual, rulesProgress } }, -- Estado personal de tareas por personaje
    enableTracking = boolean,           -- Si está activo el seguimiento para este personaje
    enableTriggers = boolean,           -- Si están activos los triggers automáticos
    debugMode = boolean,                -- Si está en modo debug
  }
}
```

-----

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
├── config.lua         -- Panel de configuración
└── counter-it.toc     -- Archivo TOC
```

-----

## ✅ Comandos disponibles

| Comando             | Acción                                |
|---------------------|----------------------------------------|
| `/counterit` o `/ci`| Abre el gestor de tareas              |
| `/cit`              | Abre el monitor de tareas activas     |
| `/cshare`           | Abre la ventana de exportar/importar  |
| `/citsim`           | Simula una captura de mascota         |

-----

## 💡 Ideas Futuras

  - Intercambio de tareas entre jugadores en tiempo real.
  - Soporte para logros, muertes, y temporizadores.
  - Mejor selector visual de iconos con previsualización.
  - Reglas encadenadas, múltiples condiciones lógicas.
  - Integración con la UI de seguimiento de misiones.

## 🛠️ Panel de Configuración

Desde ahora, Counter-It incluye un panel de configuración accesible desde el menú de interfaz del juego (AddOns), basado en **AceConfig**.

### Opciones disponibles:

  * **Activar/desactivar triggers automáticos**: Permite que el addon active tareas automáticamente según condiciones del juego.
  * **Activar/desactivar seguimiento de tareas**: Controla si las tareas activas se muestran en el panel de seguimiento.
  * **Gestión de perfiles**: Cambiar entre configuraciones por personaje o globales (Usa AceDBOptions).

### Implementación:

  * Se define en `config.lua`.
  * Se inicializa en `CounterIt:OnInitialize()`.
  * Utiliza:
      * `AceConfig-3.0`
      * `AceConfigDialog-3.0`
      * `AceDBOptions-3.0`

### Traducción (localización):

