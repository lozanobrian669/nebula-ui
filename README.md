# 🌌 NebulaUI

**Librería de interfaz de usuario premium para Roblox** — Diseño oscuro futurista, totalmente responsiva en dispositivos móviles y PC, con soporte para temas dinámicos en tiempo real y guardado de configuración automático.

---

## 🚀 Instalación y Carga

Para utilizar NebulaUI en tu script, podés cargarla de forma remota utilizando el siguiente enlace:

```lua
local NebulaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/lozanobrian669/nebula-ui/refs/heads/main/library.lua"))()
```

---

## ⚡ Estructura Base (Boilerplate)

Plantilla mínima para iniciar un script utilizando NebulaUI:

```lua
local NebulaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/lozanobrian669/nebula-ui/refs/heads/main/library.lua"))()
NebulaUI:DestroyAll() -- Evita interfaces duplicadas al re-ejecutar

local Window = NebulaUI.CreateWindow({
    Title = "Mi Script",
    SubTitle = "v1.0"
})

local Tab = Window:AddTab("Principal")

Tab:AddButton("Ejecutar", {
    Callback = function()
        print("¡Ejecutado!")
    end
})
```

---

## 🛠️ Referencia de la API

### Ventana Principal

#### `NebulaUI.CreateWindow(options)`
Crea e inicializa la ventana de la interfaz.

| Parámetro | Tipo | Default | Descripción |
|---|---|---|---|
| `Title` | `string` | `"NebulaUI"` | Título principal en la cabecera. |
| `SubTitle` | `string` | `"by Antigravity"` | Subtítulo decorativo en la cabecera. |
| `ShowAvatar` | `boolean` | `true` | Determina si se muestra la foto de perfil (avatar) del jugador de forma asíncrona en el encabezado. |
| `ConfigSaving` | `table` | `{ Enabled = false }` | Opciones de guardado automático (ver sección de Config). |

```lua
local Window = NebulaUI.CreateWindow({
    Title = "Control Panel",
    SubTitle = "Premium Edition",
    ShowAvatar = true -- Opcional: mostrar avatar en el header (true por defecto)
})
```

---

### Pestañas

#### `Window:AddTab(title)`
Añade una pestaña al menú lateral. Retorna el objeto `Tab` donde se insertarán los componentes.

```lua
local Tab = Window:AddTab("Combate")
```

---

### Componentes de la Interfaz

Todos los componentes interactivos tienen soporte opcional para:
* `Flag`: Un identificador único (string) usado para persistir el valor en la configuración.
* `Callback`: Función que se ejecuta automáticamente cuando el usuario interactúa con el componente.

---

#### 📄 Paragraph (Párrafo informativo)
```lua
local p = Tab:AddParagraph("Título", "Descripción o información detallada.")
p:Set("Nuevo Título", "Nueva descripción.") -- Actualiza el texto en tiempo real
```

---

#### 🏷️ Label (Etiqueta de texto)
```lua
local label = Tab:AddLabel("Información del script", {
    Color = Color3.fromRGB(0, 245, 212) -- Color personalizado (opcional)
})
label:Set("Nueva información") -- Actualiza el texto en tiempo real
```

---

#### ➖ Separator (Divisor visual)
```lua
Tab:AddSeparator("Sección de Combate") -- Dibuja una línea decorativa con texto centrado
```

---

#### 🔘 Button (Botón de acción)
```lua
Tab:AddButton("Ejecutar Acción", {
    Description = "Descripción opcional de la acción a realizar.", -- Opcional
    Callback = function()
        print("Acción ejecutada")
    end
})
```

---

#### 🔄 Toggle (Interruptor ON/OFF)
```lua
Tab:AddToggle("Auto Farm", {
    Default = false,
    Flag = "AutoFarmToggle",
    Callback = function(state)
        print("Estado:", state) -- true o false
    end
})
```

---

#### ✏️ TextBox (Entrada de texto)
```lua
Tab:AddTextBox("Nombre del Objetivo", {
    Placeholder = "Escribe un nombre...",
    ClearOnFocus = false,
    Flag = "TargetName",
    Callback = function(text)
        print("Objetivo fijado en:", text)
    end
})
```

---

#### 📊 Slider (Barra deslizadora numérica)
```lua
Tab:AddSlider("Velocidad de Caminado", {
	Min = 16,
	Max = 150,
	Default = 16,
	Rounding = 0, -- Decimales a mostrar (0 = enteros)
	Flag = "WalkSpeedSlider",
	Callback = function(value)
		game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
	end
})
```

---

#### 📋 Dropdown (Lista desplegable)
```lua
local dd = Tab:AddDropdown("Seleccionar Teleport", {
    Items = {"Spawn", "Tienda", "Zona VIP"},
    Default = "Spawn",
    Flag = "TpDropdown",
    Callback = function(selected)
        print("Destino:", selected)
    end
})

-- Métodos adicionales:
dd:SetValue("Zona VIP") -- Cambia el valor actual
dd:Refresh({"Spawn", "Tienda", "Zona VIP", "Nuevo Mapa"}) -- Reemplaza los elementos de la lista
```

---

#### ⌨️ KeyBind (Asignación de tecla)
```lua
Tab:AddKeyBind("Alternar Menú", {
    Default = Enum.KeyCode.RightShift,
    Flag = "ToggleMenuKey",
    Callback = function()
        print("Tecla presionada!")
    end
})
```

---

#### 🎨 ColorPicker (Selector de color)
```lua
Tab:AddColorPicker("Color del ESP", {
    Default = Color3.fromRGB(155, 93, 229),
    Flag = "EspColorPicker",
    Callback = function(color)
        print("Color seleccionado:", color) -- Retorna un Color3
    end
})
```

---

## 💾 Persistencia de Configuración (Config Saving)

Para activar el guardado y carga automática de la configuración en la carpeta del ejecutor, inicializá la ventana de la siguiente manera:

```lua
local Window = NebulaUI.CreateWindow({
    Title = "Mi Script",
    ConfigSaving = {
        Enabled = true,
        Folder = "MiCarpetaConfigs", -- Nombre de la carpeta en 'workspace'
        FileName = "configuracion"    -- Nombre del archivo JSON (sin extensión)
    }
})
```

### Acceso a los valores en código:
Podés leer o escribir los valores de los componentes con `Flag` directamente usando `Window.Flags`:

```lua
-- Leer un valor actual:
local autoFarmActive = Window.Flags["AutoFarmToggle"]

-- Guardar manualmente (los componentes guardan automáticamente al interactuar):
Window.Flags["WalkSpeedSlider"] = 50
Window:SaveConfig()
```

---

## 🎨 Temas y Personalización en Tiempo Real

Podés cambiar el color de acento de toda la interfaz dinámicamente en tiempo real (por ejemplo, mediante un `ColorPicker` para que el usuario elija su color preferido):

```lua
Tab:AddColorPicker("Color de la Interfaz", {
    Default = NebulaUI.Theme.Accent,
    Callback = function(color)
        Window:UpdateTheme(color) -- Actualiza el tema visual instantáneamente
    end
})
```
