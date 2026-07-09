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

#### `NebulaUI:DestroyAll()`
Destruye **todas** las ventanas de NebulaUI activas en el `PlayerGui` (de esta ejecución y de ejecuciones anteriores que hayan quedado colgadas). Se llama típicamente una sola vez, al principio del script, antes de crear la ventana propia — así evitás interfaces duplicadas si el usuario re-ejecuta el script sin reiniciar el juego.

---

## 🛠️ Referencia de la API

### Ventana Principal

#### `NebulaUI.CreateWindow(options)`
Crea e inicializa la ventana de la interfaz. Retorna el objeto `Window`.

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

##### Propiedades públicas del objeto `Window`

Además de los métodos documentados abajo, el objeto `Window` expone estas propiedades por si necesitás construir contenido custom directamente sobre la GUI (fuera de los componentes estándar `AddX`):

| Propiedad | Tipo | Descripción |
|---|---|---|
| `Window.ScreenGui` | `ScreenGui` | El `ScreenGui` raíz de esta ventana. |
| `Window.MainFrame` | `Frame` | El panel principal. Contiene un hijo fijo llamado `"Header"` (50px de alto, con Avatar/Title/Subtitle/Minimize ya construidos) donde podés parentear elementos propios (badges, íconos, etc.) sin tocar `library.lua`. |
| `Window.Sidebar` | `ScrollingFrame` | La barra lateral con los botones de las pestañas. |
| `Window.Container` | `Frame` | El contenedor donde viven los `ContentFrame` de cada `Tab`. |
| `Window.IsMobile` | `boolean` | `true` si la ventana se dimensionó para pantalla táctil/chica. Usalo para ajustar tamaños de elementos custom con el patrón `isMobile and X or Y`. |
| `Window.Flags` | `table` | Diccionario `Flag -> valor` de todos los componentes con `Flag` asignado. Ver sección de Persistencia. |
| `Window.Tabs` | `table` | Array de los objetos `Tab` creados, en orden. |

---

### Pestañas

#### `Window:AddTab(title)`
Añade una pestaña al menú lateral. Retorna el objeto `Tab` donde se insertarán los componentes.

```lua
local Tab = Window:AddTab("Combate")
```

##### Propiedades públicas del objeto `Tab`

| Propiedad | Tipo | Descripción |
|---|---|---|
| `Tab.ContentFrame` | `ScrollingFrame` | El contenedor scrolleable de esta pestaña. Parenteá acá cualquier `Instance` propia si querés construir UI custom que no cubran los componentes estándar (ver ejemplo abajo). |
| `Tab.Button` | `TextButton` | El botón de esta pestaña en el Sidebar. |
| `Tab.Active` | `boolean` | `true` si esta es la pestaña actualmente visible. |
| `Tab.LayoutOrderCounter` | `number` | Contador interno que usan los `AddX` para ordenar elementos verticalmente. Si construís Instances propias directo en `ContentFrame`, incrementalo vos mismo (`Tab.LayoutOrderCounter = (Tab.LayoutOrderCounter or 0) + 1`) y asignalo a `LayoutOrder` de tu Frame para que se intercale bien con el resto de los componentes. |

```lua
-- Ejemplo: construir un elemento propio dentro de una pestaña,
-- respetando el orden y el ancho estándar del resto de los componentes
Tab.LayoutOrderCounter = (Tab.LayoutOrderCounter or 0) + 1
local miFrame = Instance.new("Frame")
miFrame.Size = UDim2.new(0.95, 0, 0, 60)
miFrame.LayoutOrder = Tab.LayoutOrderCounter
miFrame.Parent = Tab.ContentFrame
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

#### 🃏 Card (Tarjeta con ícono, descripción y click opcional)
Componente más rico que `AddLabel`/`AddParagraph`: soporta ícono (emoji, texto corto, o imagen vía `rbxassetid://` o ID numérico), color de fondo custom, modo "glass" (glasmorfismo translúcido) y un click opcional. Crece en alto automáticamente para no truncar el texto.

```lua
local card = Tab:AddCard("Auto Farm", {
    Description = "Recolecta recursos automáticamente en el área actual.",
    Icon = "⚡", -- también acepta "rbxassetid://123..." o solo el ID numérico
    Color = Color3.fromRGB(40, 60, 90), -- Opcional: color de fondo custom (si se omite, usa Theme.CardBackground)
    Glass = false, -- Opcional: efecto glasmorfismo translúcido
    Callback = function()
        print("Card clickeada")
    end
})

-- Métodos adicionales:
card.SetTitle("Nuevo título")
card.SetDescription("Nueva descripción")
```

| Parámetro | Tipo | Default | Descripción |
|---|---|---|---|
| `Description` | `string` | `""` | Texto secundario, debajo del título. Si se omite, la card queda más compacta. |
| `Icon` | `string` | `""` | Emoji/texto corto, o `"rbxassetid://..."`/ID numérico para usar una imagen. |
| `Color` | `Color3` | `Theme.CardBackground` | Color de fondo custom. La barra de acento lateral se oscurece automáticamente en base a este color. |
| `Glass` | `boolean` | `false` | Activa un fondo semitransparente con brillo degradado (glasmorfismo). |
| `Callback` | `function` | — | Si se define, toda la card se vuelve clickeable. |

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
local toggle = Tab:AddToggle("Auto Farm", {
    Default = false,
    Flag = "AutoFarmToggle",
    Callback = function(state)
        print("Estado:", state) -- true o false
    end
})

-- Métodos adicionales:
toggle.SetValue(true) -- Cambia el estado del toggle (true/false). NOTA: también dispara el Callback.
local estado = toggle.GetValue() -- Retorna el estado actual (boolean)
```

> ⚠️ **Importante:** `SetValue` en Toggle, Slider, Dropdown y ColorPicker dispara internamente el mismo `Callback` que se ejecuta al interactuar manualmente. Si vas a llamar `SetValue` *desde dentro* de un `Callback` de otro componente (por ejemplo, para sincronizar dos controles), agregá una guarda (flag booleano) para evitar recursión infinita.

---

#### ✏️ TextBox (Entrada de texto)
```lua
local textbox = Tab:AddTextBox("Nombre del Objetivo", {
    Placeholder = "Escribe un nombre...",
    ClearOnFocus = false,
    Flag = "TargetName",
    Callback = function(text)
        print("Objetivo fijado en:", text)
    end
})

-- Métodos adicionales:
textbox.SetValue("Nuevo texto") -- Cambia el valor del texto
local texto = textbox.GetValue() -- Retorna el texto actual (string)
```

---

#### 📊 Slider (Barra deslizadora numérica)
```lua
local slider = Tab:AddSlider("Velocidad de Caminado", {
	Min = 16,
	Max = 150,
	Default = 16,
	Rounding = 0, -- Decimales a mostrar (0 = enteros)
	Flag = "WalkSpeedSlider",
	Callback = function(value)
		game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
	end
})

-- Métodos adicionales:
slider.SetValue(50) -- Cambia el valor actual
local valor = slider.GetValue() -- Retorna el valor actual (number)
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
dd.SetValue("Zona VIP") -- Cambia el valor actual
local valor = dd.GetValue() -- Retorna el valor seleccionado actualmente (string)
dd.Refresh({"Spawn", "Tienda", "Zona VIP", "Nuevo Mapa"}) -- Reemplaza los elementos de la lista
```

---

#### ⌨️ KeyBind (Asignación de tecla)
```lua
local kb = Tab:AddKeyBind("Alternar Menú", {
    Default = Enum.KeyCode.RightShift,
    Flag = "ToggleMenuKey",
    Callback = function()
        print("Tecla presionada!")
    end
})

-- Métodos adicionales:
kb.SetValue(Enum.KeyCode.F) -- Cambia la tecla asignada
local tecla = kb.GetValue() -- Retorna la tecla asignada actualmente (Enum.KeyCode)
```

---

#### 🎨 ColorPicker (Selector de color)
Picker completo con canvas de Saturación/Valor + slider de Tono (Hue) + hex label. Se expande/colapsa inline al hacer click en la cabecera (no es un popup flotante).

```lua
local cp = Tab:AddColorPicker("Color del ESP", {
    Default = Color3.fromRGB(155, 93, 229),
    Flag = "EspColorPicker",
    Callback = function(color)
        print("Color seleccionado:", color) -- Retorna un Color3
    end
})

-- Métodos adicionales:
cp.SetValue(Color3.fromRGB(255, 0, 0)) -- Cambia el color seleccionado
local color = cp.GetValue() -- Retorna el color actual (Color3)
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

#### `Window:SaveConfig()`
Guarda `Window.Flags` al archivo JSON configurado en `ConfigSaving`. Se llama automáticamente cada vez que un componente con `Flag` cambia de valor (por interacción del usuario o por `SetValue`), pero también podés llamarlo manualmente en cualquier momento.

#### `Window:LoadConfig()`
Carga el archivo JSON guardado hacia `Window.Flags`. Se llama automáticamente una sola vez, dentro de `CreateWindow`, antes de construir cualquier pestaña — por eso los componentes ya nacen con el valor guardado si existe (`Flag` + `Default`). No hace falta llamarlo manualmente en el uso normal.

---

## 🎨 Temas y Personalización en Tiempo Real

### Accent color

Podés cambiar el color de acento de toda la interfaz dinámicamente en tiempo real (por ejemplo, mediante un `ColorPicker` para que el usuario elija su color preferido):

```lua
Tab:AddColorPicker("Color de la Interfaz", {
    Default = NebulaUI.Theme.Accent,
    Callback = function(color)
        Window:UpdateTheme(color) -- Actualiza el tema visual instantáneamente
    end
})
```

`Window:UpdateTheme(color)` recolorea automáticamente sliders, toggles, dropdowns, botones, la barra de acento del tab activo, el subtítulo del header y el ícono del botón flotante. **No** recolorea Instances construidas a mano fuera de los componentes `AddX` (por ejemplo, si armaste tus propios labels directo en `Tab.ContentFrame`) — esas las tenés que recolorear vos mismo dentro de tu propio callback.

### Presets de superficie

Además del accent color, NebulaUI trae 4 presets de **superficie** (fondos, bordes, tracks) predefinidos en `NebulaUI.Presets`:

```lua
print(NebulaUI.Presets.Nebula.Accent)   --> Color3.fromRGB(155, 93, 229)
print(NebulaUI.Presets.Midnight.Accent) --> Color3.fromRGB(88, 148, 255)
print(NebulaUI.Presets.Carbon.Accent)   --> Color3.fromRGB(0, 198, 255)
print(NebulaUI.Presets.Abyss.Accent)    --> Color3.fromRGB(0, 226, 178)
```

Cada preset define: `Accent`, `Background`, `SidebarBackground`, `HeaderBackground`, `CardBackground`, `CardBorder`, `ElementBackground`, `InputBackground`, `SliderTrack`, `ToggleOff`.

#### `Window:ApplyPreset(preset)`
Aplica un preset de superficie. Acepta el **nombre** del preset (`string`, busca en `NebulaUI.Presets`) o una **tabla propia** con la misma forma (no hace falta definir las 9 claves, solo las que quieras sobreescribir).

```lua
Window:ApplyPreset("Midnight") -- por nombre

Window:ApplyPreset({           -- o con una tabla custom
    Background = Color3.fromRGB(10, 10, 15),
    CardBackground = Color3.fromRGB(20, 20, 28)
})
```

> ℹ️ `ApplyPreset` **no** toca el accent color — solo superficies. Si querés que cambiar de preset también sugiera un accent recomendado (como hace el tema del panel en Touchline Reach), llamá `Window:UpdateTheme(NebulaUI.Presets[nombre].Accent)` por separado.

### Botón flotante (Toggle)

#### `Window:SetToggleLocked(locked)`
Fija (`true`) o libera (`false`) el botón flotante circular que abre/cierra la ventana. Fijado, no se puede arrastrar por la pantalla, pero el click para abrir/cerrar sigue funcionando igual.

```lua
Window:SetToggleLocked(true)
```

#### `Window:GetToggleLocked()`
Retorna el estado actual (`boolean`) de si el botón flotante está fijado o no.

```lua
local fijado = Window:GetToggleLocked()
```

### Cerrar la ventana

#### `Window:Destroy()`
Destruye esta ventana específica (su `ScreenGui` y todo lo que contiene). A diferencia de `NebulaUI:DestroyAll()`, que borra *todas* las ventanas activas, `Window:Destroy()` solo afecta a esta instancia — útil si tu script maneja múltiples ventanas o necesita reconstruir la UI (por ejemplo, al cambiar de idioma) sin afectar otras.

```lua
Window:Destroy()
```
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
local toggle = Tab:AddToggle("Auto Farm", {
    Default = false,
    Flag = "AutoFarmToggle",
    Callback = function(state)
        print("Estado:", state) -- true o false
    end
})

-- Métodos adicionales:
toggle:SetValue(true) -- Cambia el estado del toggle (true/false)
local estado = toggle:GetValue() -- Retorna el estado actual (boolean)
```

---

#### ✏️ TextBox (Entrada de texto)
```lua
local textbox = Tab:AddTextBox("Nombre del Objetivo", {
    Placeholder = "Escribe un nombre...",
    ClearOnFocus = false,
    Flag = "TargetName",
    Callback = function(text)
        print("Objetivo fijado en:", text)
    end
})

-- Métodos adicionales:
textbox:SetValue("Nuevo texto") -- Cambia el valor del texto
local texto = textbox:GetValue() -- Retorna el texto actual (string)
```

---

#### 📊 Slider (Barra deslizadora numérica)
```lua
local slider = Tab:AddSlider("Velocidad de Caminado", {
	Min = 16,
	Max = 150,
	Default = 16,
	Rounding = 0, -- Decimales a mostrar (0 = enteros)
	Flag = "WalkSpeedSlider",
	Callback = function(value)
		game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
	end
})

-- Métodos adicionales:
slider:SetValue(50) -- Cambia el valor actual
local valor = slider:GetValue() -- Retorna el valor actual (number)
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
local valor = dd:GetValue() -- Retorna el valor seleccionado actualmente (string)
dd:Refresh({"Spawn", "Tienda", "Zona VIP", "Nuevo Mapa"}) -- Reemplaza los elementos de la lista
```

---

#### ⌨️ KeyBind (Asignación de tecla)
```lua
local kb = Tab:AddKeyBind("Alternar Menú", {
    Default = Enum.KeyCode.RightShift,
    Flag = "ToggleMenuKey",
    Callback = function()
        print("Tecla presionada!")
    end
})

-- Métodos adicionales:
kb:SetValue(Enum.KeyCode.F) -- Cambia la tecla asignada
local tecla = kb:GetValue() -- Retorna la tecla asignada actualmente (Enum.KeyCode)
```

---

#### 🎨 ColorPicker (Selector de color)
```lua
local cp = Tab:AddColorPicker("Color del ESP", {
    Default = Color3.fromRGB(155, 93, 229),
    Flag = "EspColorPicker",
    Callback = function(color)
        print("Color seleccionado:", color) -- Retorna un Color3
    end
})

-- Métodos adicionales:
cp:SetValue(Color3.fromRGB(255, 0, 0)) -- Cambia el color seleccionado
local color = cp:GetValue() -- Retorna el color actual (Color3)
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
