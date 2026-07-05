local NebulaUI = {
	Windows = {},
	Theme = {
		Background = Color3.fromRGB(8, 9, 13),
		SidebarBackground = Color3.fromRGB(12, 13, 18),
		HeaderBackground = Color3.fromRGB(16, 17, 24),
		HeaderGradientStart = Color3.fromRGB(28, 18, 48),
		HeaderGradientEnd = Color3.fromRGB(12, 13, 18),
		
		Accent = Color3.fromRGB(155, 93, 229), -- Violeta principal
		SecondaryAccent = Color3.fromRGB(0, 245, 212), -- Cyan neón secundario
		Text = Color3.fromRGB(245, 245, 245),
		MutedText = Color3.fromRGB(150, 150, 150),
		DarkAccent = Color3.fromRGB(30, 22, 45), -- Tinte morado suave para pestaña activa
		
		CardBackground = Color3.fromRGB(18, 19, 24),
		CardBorder = Color3.fromRGB(30, 31, 38),
		CardBorderHover = Color3.fromRGB(155, 93, 229),
		
		ToggleOn = Color3.fromRGB(155, 93, 229),
		ToggleOff = Color3.fromRGB(53, 54, 74)
	}
}
NebulaUI.__index = NebulaUI

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local NebulaTask = task or {}
if not NebulaTask.wait then
	NebulaTask.wait = function(duration)
		if wait then return wait(duration) end
	end
end
if not NebulaTask.spawn then
	NebulaTask.spawn = function(callback)
		if spawn then
			return spawn(callback)
		end
		local co = coroutine.create(callback)
		return coroutine.resume(co)
	end
end
if not NebulaTask.delay then
	NebulaTask.delay = function(duration, callback)
		if delay then return delay(duration, callback) end
		return NebulaTask.spawn(function()
			NebulaTask.wait(duration)
			callback()
		end)
	end
end

local function tableClear(list)
	if table.clear then
		table.clear(list)
		return
	end
	for key in pairs(list) do
		list[key] = nil
	end
end

local function tableFind(list, value)
	if table.find then
		return table.find(list, value)
	end
	for index, item in ipairs(list) do
		if item == value then
			return index
		end
	end
	return nil
end

local function mathClamp(value, minValue, maxValue)
	if math.clamp then
		return math.clamp(value, minValue, maxValue)
	end
	if value < minValue then return minValue end
	if value > maxValue then return maxValue end
	return value
end

local function mathRound(value)
	if math.round then
		return math.round(value)
	end
	return math.floor(value + 0.5)
end

local function udim2FromOffset(x, y)
	if UDim2.fromOffset then
		return UDim2.fromOffset(x, y)
	end
	return UDim2.new(0, x, 0, y)
end

local function nebulaTypeof(value)
	if typeof then
		return typeof(value)
	end
	return type(value)
end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Destruye todas las ventanas creadas por la librería
function NebulaUI:DestroyAll()
	for _, win in ipairs(NebulaUI.Windows) do
		pcall(function()
			win:Destroy()
		end)
	end
	tableClear(NebulaUI.Windows)
end

-- Obtener tamaño dinámico según el dispositivo para soporte responsive
local function getWindowSize()
	local camera = workspace.CurrentCamera
	local viewportSize = camera and camera.ViewportSize or Vector2.new(1000, 800)
	local isMobile = UserInputService.TouchEnabled and (viewportSize.X < 800 or viewportSize.Y < 600)
	
	local width = isMobile and 360 or 450
	local height = isMobile and 225 or 285
	local sidebarWidth = isMobile and 95 or 120
	
	return width, height, sidebarWidth, isMobile
end

-- Helper para crear los marcos base de los componentes de forma estándar y con hover
local function createBase(tab, name, height)
	tab.LayoutOrderCounter = (tab.LayoutOrderCounter or 0) + 1
	local frame = Instance.new("Frame")
	frame.Name = name .. "_Container"
	frame.Size = UDim2.new(0.95, 0, 0, height)
	frame.LayoutOrder = tab.LayoutOrderCounter
	frame.BackgroundColor3 = NebulaUI.Theme.CardBackground
	frame.BorderSizePixel = 0
	frame.Parent = tab.ContentFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = NebulaUI.Theme.CardBorder
	stroke.Thickness = 1
	stroke.Parent = frame
	
	-- Efectos de hover suaves
	frame.MouseEnter:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Color = NebulaUI.Theme.CardBorderHover
		}):Play()
	end)
	frame.MouseLeave:Connect(function()
		TweenService:Create(stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Color = NebulaUI.Theme.CardBorder
		}):Play()
	end)
	
	return frame
end

-- Actualizar tamaño del canvas al agregar componentes
function Tab:_UpdateCanvas()
	local layoutEl = self.ContentFrame:FindFirstChildOfClass("UIListLayout")
	if layoutEl then
		self.ContentFrame.CanvasSize = UDim2.new(0, 0, 0, layoutEl.AbsoluteContentSize.Y + 25)
	end
end

-- Crear la ventana principal de la interfaz
function NebulaUI.CreateWindow(options)
	options = options or {}
	local titleText = options.Title or "NebulaUI"
	local subTitleText = options.SubTitle or "by Antigravity"
	
	local self = setmetatable({}, Window)
	self.Tabs = {}
	self.ActiveTab = nil
	self.ConfigSaving = options.ConfigSaving or { Enabled = false }
	self.Flags = {}
	
	pcall(function()
		self:LoadConfig()
	end)
	
	local width, height, sidebarWidth, isMobile = getWindowSize()
	self.IsMobile = isMobile
	
	-- 1. Contenedor principal de la GUI (ScreenGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NebulaUI_" .. math.random(1000, 9999)
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.Parent = PlayerGui
	self.ScreenGui = screenGui
	
	-- Intentar cargar icono de nebulosa personalizado (PNG)
	local nebulaIcon = "rbxassetid://6034287525" -- Fallback: icono de nebulosa/galaxia
	local pngHex = "89504e470d0a1a0a0000000d494844520000005a0000003e0806000000abcd0c4e000000097048597300000b1300000b1301009a9c18000000017352474200aece1ce90000000467414d410000b18f0bfc61050000000e74455874536f667477617265004669676d619eb196630000057b494441547801ed9c8195db360c86e1be0ee00da24e507782aa13d41b449d20dec0dae092097c9de0d209980ddc0de84ee0eb047fc992ae5d9d08821425d989bef7f8fc72362910a240008442b4b0f035b1a26f0c006bf35199b6bef9f3ab6dabd5ea440bc3314afe60da193cf67b65da93698d69152dc8f14acbe568da6e51ba00a3a41794e190a3f0efe80130135b9b5663d88afa9bcad098a68d2c7bfa5af0cab52bf1dc5951eb8cb186988e101a8f6a4efceaddfb4984682903db0f3329fb6edc3bb855fac1b41dfddff5eae3645cb11f28ef3a1539f7ee96b56ff6ef3ffacf0dc93999f6cb5dbb8776e270e62085238d8c97cb9a1b259449d13d0267220ec8e3234d8857fab340ae1ddd0bb8dae058e010422163332c247b1391fb4cf78040d0e004e036b25a781d7b33ed2aaca83066cc0df8396c692efca415d2519ce07ed23662b3e1b28dde34c237ca7e7f4081b0da5f33c481e600ce4ce428b8ee196bed15d5f5ad73386080c299eb4f6b3ee056f111691cfa260f17b8288c43568467fa7d64c69c660f812c4b768b326dd31963e8a69942f2e30e3ed27c47638274974da1632230ad826f79a204e09eb210358d059ca9d0906195b8ebf49f4bc1b7d409f34d5ad1df5301bc802f140f9d2d9f4dfbcd84abaf9dfef6f1ad289f93695fc865e95efdbf89aea7293f533cacdefb312454cc77a53285578c92de43865da9db4e5fbb8a9f908782f7ad21dc7c208bf0a463a940fff25e07e4ae9b42c79b409aa9f96f1270caad6800e03d8646d0bf62fa97cd7940aee41da54ff68df028b8c14414d508fa3743faa708ba479c33a71cc8fc62851176f088a2a38921f04f624525102a59c72e087e456b8ce82299b1b7ccb5b791bedc6a2e633622025eb0d1607443815b557dae5c8b91232bf007b51be265d64cdf8686c228e696e71425e1ea05683ff994538d2ce012512174a4ef21b7af54b835e21ec273a0af55a675e1140626724a80ccb348c40f771b1a0ae261f531d0afef29d0982f715f47e65105fac59ee6e1476b88df491d521cc2d9bb966600bcd968037d24fe7e4543105c4423bc0ab81bf4996600ce049e03f358077e1f4bf5b63414c44d06b7436ba6dfa487ab1db9361dd974681ec83499a90255918bb44c5fce166a4cb021c2ad46abd43af05d0d264f225072997960802b8381b98402b25b059e7394e26f82429ce1ae28e2abb98af43fe6dca0027273070fd1a80df2e3b732f51b1878ca8bb02b34ca2608f9a1c13b660c6936b1a55280bfab95a0fff84252d6a94cc81ebf178ed15229c09b0dd18a64847ea1026428d8a20263490f1e5a2a09f8c451231c837b22b2ec1b9c72ad495348c7ca5375c693da634b4ba541817a05c493fa0a4cc510ae255df637972aa45cda9ef1a5e510f6370d8d01c22944b1730e3ed4ed9b8ceeb41228bc5dc51bc89f088d31b3898c2049496da41d5595c4aefeba234bea21f01b53531c9453b4244f5012859ed311a4574d4d931e40d87424071bc8abbf4b45a13fccb6f65d278cc39e7116072314efa1fc4b3a0ace03e9cbb83548f74c14a6ce91834f6fb69409ae5e44ce0ad7b8d63687d2997be4d589343401ab3ea1cd47a8dac6965afd34f4ed23b88d66e35b5f58fc17b9922edbfebc2d1feb8c539b8f5fc9bd6499ba223f99d686c69e04f08f9ec6fce77eb9810b3052ad4816889fade9a91eb91ed95e90879e4b6616c82b89b6341190d59574f9b75e8fee15a41521dadf1dbc22468ba690e6bd684c508c23857d45d92bcd062a39c29ee85aa3fceadb659cdfcd26949c9b867bf463f9f02fa67dca197f56f0f630b314c9593c840b79ac79b0fe7f4d8f0cf26a996364156ce35a4666fd718540e0f2d0c0d93c8d728cfbf6d223e357d4ae80c2efe3bde94700cedfbe3cc6a9b4f40d51ec3f4681b39397b0ba22175a5f6c67e53f2f6f4bfd61bc82675a58585858e0f8072e0541017cd7563e0000000049454e44ae426082"
	
	local function hex2bin(hex)
		return (hex:gsub('..', function (cc)
			return string.char(tonumber(cc, 16))
		end))
	end

	pcall(function()
		if writefile and getcustomasset then
			if makefolder then
				pcall(function() makefolder("nebula-ui") end)
				pcall(function() makefolder("nebula-ui/assets") end)
			end
			writefile("nebula-ui/assets/Group.png", hex2bin(pngHex))
			nebulaIcon = getcustomasset("nebula-ui/assets/Group.png")
		elseif readfile and isfile and getcustomasset then
			if isfile("nebula-ui/assets/Group.png") then
				nebulaIcon = getcustomasset("nebula-ui/assets/Group.png")
			end
		end
	end)

	-- 2. Botón de Toggle Flotante (Diseño Circular Premium)
	local toggleBtn = Instance.new("ImageButton")
	toggleBtn.Name = "Toggle"
	toggleBtn.Size = udim2FromOffset(46, 46)
	
	-- Posicionamiento inteligente para evitar colisiones si ya hay ventanas activas
	-- (el módulo evita que el offset crezca sin límite si se abren/cierran muchas ventanas)
	local offsetMultiplier = #NebulaUI.Windows % 6
	toggleBtn.Position = UDim2.new(0, 15 + (offsetMultiplier * 15), 0.5, 40 + (offsetMultiplier * 10))
	toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
	toggleBtn.Parent = screenGui
	
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggleBtn
	
	local toggleStroke = Instance.new("UIStroke")
	toggleStroke.Color = NebulaUI.Theme.CardBorder -- Gris por defecto, no rojo
	toggleStroke.Thickness = 1.5
	toggleStroke.Parent = toggleBtn
	
	-- Icono interno (para evitar recortes por UICorner)
	local toggleIcon = Instance.new("ImageLabel")
	toggleIcon.Name = "Icon"
	toggleIcon.Size = UDim2.new(1, 0, 1, 0)
	toggleIcon.BackgroundTransparency = 1
	toggleIcon.Image = nebulaIcon
	toggleIcon.ImageColor3 = NebulaUI.Theme.Accent -- Violeta
	toggleIcon.ScaleType = Enum.ScaleType.Fit
	toggleIcon.Parent = toggleBtn
	
	local btnPadding = Instance.new("UIPadding")
	btnPadding.PaddingTop = UDim.new(0, 8) -- 8px para ajustar el tamaño del PNG dentro del círculo
	btnPadding.PaddingBottom = UDim.new(0, 8)
	btnPadding.PaddingLeft = UDim.new(0, 8)
	btnPadding.PaddingRight = UDim.new(0, 8)
	btnPadding.Parent = toggleBtn
	
	-- 3. Marco Principal del Menú
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = udim2FromOffset(width, height)
	-- Desplazamiento de ventanas para soporte multi-ventana limpio
	mainFrame.Position = UDim2.new(0.5, -(width/2) + (offsetMultiplier * 20), 0.5, -(height/2) + (offsetMultiplier * 20))
	mainFrame.BackgroundColor3 = NebulaUI.Theme.Background
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = true
	mainFrame.Parent = screenGui
	self.MainFrame = mainFrame
	
	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame
	
	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = NebulaUI.Theme.CardBorder
	mainStroke.Thickness = 1.5
	mainStroke.Parent = mainFrame
	
	-- Sistema para arrastrar la ventana
	local dragging = false
	local dragInput, dragStart, startPos
	
	local function update(input)
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, 
			startPos.X.Offset + delta.X, 
			startPos.Y.Scale, 
			startPos.Y.Offset + delta.Y
		)
	end
	
	mainFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	mainFrame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	local draggingToggle = false
	local dragToggleStart, startTogglePos
	local hasDraggedToggle = false
	
	local function updateTogglePos(input)
		local delta = input.Position - dragToggleStart
		toggleBtn.Position = UDim2.new(
			startTogglePos.X.Scale, 
			startTogglePos.X.Offset + delta.X, 
			startTogglePos.Y.Scale, 
			startTogglePos.Y.Offset + delta.Y
		)
	end
	
	toggleBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingToggle = true
			hasDraggedToggle = false
			dragToggleStart = input.Position
			startTogglePos = toggleBtn.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					draggingToggle = false
				end
			end)
		end
	end)
	
	toggleBtn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput then
			if dragging then
				update(input)
			elseif draggingToggle then
				local delta = input.Position - dragToggleStart
				if delta.Magnitude > 5 then
					hasDraggedToggle = true
				end
				updateTogglePos(input)
			end
		end
	end)
	
	-- Comportamiento del botón de toggle flotante
	local isOpen = true
	toggleBtn.MouseButton1Click:Connect(function()
		if hasDraggedToggle then
			hasDraggedToggle = false
			return
		end
		isOpen = not isOpen
		
		local clickTween = TweenService:Create(toggleBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = udim2FromOffset(40, 40)
		})
		clickTween:Play()
		clickTween.Completed:Connect(function()
			TweenService:Create(toggleBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = udim2FromOffset(46, 46)
			}):Play()
		end)
		
		mainFrame.Visible = isOpen
		
		if isOpen then
			toggleIcon.Image = nebulaIcon
			toggleIcon.ImageColor3 = NebulaUI.Theme.Accent
			toggleStroke.Color = NebulaUI.Theme.CardBorder
		else
			toggleIcon.Image = nebulaIcon
			toggleIcon.ImageColor3 = NebulaUI.Theme.MutedText
			toggleStroke.Color = NebulaUI.Theme.CardBorder
		end
	end)
	
	-- Hover en el botón flotante
	toggleBtn.MouseEnter:Connect(function()
		TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(30, 31, 38)
		}):Play()
	end)
	toggleBtn.MouseLeave:Connect(function()
		TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(20, 21, 26)
		}):Play()
	end)
	
	-- 4. Cabecera (Header Bar) con Gradiente
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = NebulaUI.Theme.HeaderBackground
	header.BorderSizePixel = 0
	header.Parent = mainFrame
	

	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header
	
	local headerHide = Instance.new("Frame")
	headerHide.Name = "HeaderHide"
	headerHide.Size = UDim2.new(1, 0, 0, 10)
	headerHide.Position = UDim2.new(0, 0, 1, -10)
	headerHide.BackgroundColor3 = NebulaUI.Theme.Background
	headerHide.BorderSizePixel = 0
	headerHide.Parent = header
	
	local separator = Instance.new("Frame")
	separator.Name = "Separator"
	separator.Size = UDim2.new(1, 0, 0, 1)
	separator.Position = UDim2.new(0, 0, 1, 0)
	separator.BackgroundColor3 = NebulaUI.Theme.CardBorder
	separator.BorderSizePixel = 0
	separator.Parent = header
	
	-- Avatar del jugador (visible por defecto; se puede desactivar con options.ShowAvatar = false)
	local showAvatar = options.ShowAvatar
	if showAvatar == nil then
		showAvatar = true
	end
	local avatarSize = isMobile and 28 or 32
	local textLeftOffset = 15

	if showAvatar then
		local avatarImage = Instance.new("ImageLabel")
		avatarImage.Name = "Avatar"
		avatarImage.Size = udim2FromOffset(avatarSize, avatarSize)
		avatarImage.Position = UDim2.new(0, 12, 0.5, -avatarSize / 2)
		avatarImage.BackgroundColor3 = NebulaUI.Theme.CardBackground
		avatarImage.Image = ""
		avatarImage.Parent = header

		local avatarCorner = Instance.new("UICorner")
		avatarCorner.CornerRadius = UDim.new(1, 0)
		avatarCorner.Parent = avatarImage

		local avatarStroke = Instance.new("UIStroke")
		avatarStroke.Color = NebulaUI.Theme.CardBorder
		avatarStroke.Thickness = 1
		avatarStroke.Parent = avatarImage

		self.AvatarImage = avatarImage
		textLeftOffset = 12 + avatarSize + 10

		NebulaTask.spawn(function()
			local ok, content = pcall(function()
				return Players:GetUserThumbnailAsync(
					LocalPlayer.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size100x100
				)
			end)
			if ok then
				avatarImage.Image = content
			end
		end)
	end

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.5, -textLeftOffset + 15, 0.5, 0)
	title.Position = UDim2.new(0, textLeftOffset, 0, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = titleText
	title.TextColor3 = NebulaUI.Theme.Text
	title.TextSize = isMobile and 14 or 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(0.5, -textLeftOffset + 15, 0.5, 0)
	subtitle.Position = UDim2.new(0, textLeftOffset, 0.5, 2)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.GothamSemibold
	subtitle.Text = subTitleText
	subtitle.TextColor3 = NebulaUI.Theme.Accent
	subtitle.TextSize = isMobile and 9 or 10
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = header
	
	-- Botón de minimizar en la cabecera
	local minBtn = Instance.new("TextButton")
	minBtn.Name = "Minimize"
	minBtn.Size = udim2FromOffset(30, 30)
	minBtn.Position = UDim2.new(1, -40, 0.5, -15)
	minBtn.BackgroundTransparency = 1
	minBtn.TextColor3 = NebulaUI.Theme.MutedText
	minBtn.Font = Enum.Font.GothamBold
	minBtn.Text = "_"
	minBtn.TextSize = 18
	minBtn.Parent = header
	
	minBtn.MouseButton1Click:Connect(function()
		isOpen = false
		mainFrame.Visible = false
		toggleIcon.Image = nebulaIcon
		toggleIcon.ImageColor3 = NebulaUI.Theme.MutedText
		toggleStroke.Color = NebulaUI.Theme.CardBorder
	end)
	
	minBtn.MouseEnter:Connect(function()
		TweenService:Create(minBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(245, 80, 80)}):Play()
	end)
	minBtn.MouseLeave:Connect(function()
		TweenService:Create(minBtn, TweenInfo.new(0.2), {TextColor3 = NebulaUI.Theme.MutedText}):Play()
	end)

	-- 5. Barra Lateral (Sidebar) para Pestañas
	local sidebar = Instance.new("ScrollingFrame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, sidebarWidth, 1, -51)
	sidebar.Position = UDim2.new(0, 0, 0, 51)
	sidebar.BackgroundColor3 = NebulaUI.Theme.SidebarBackground
	sidebar.BorderSizePixel = 0
	sidebar.ScrollBarThickness = 0
	sidebar.Parent = mainFrame
	
	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.Padding = UDim.new(0, 4)
	sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sidebarLayout.Parent = sidebar
	
	local sidebarPadding = Instance.new("UIPadding")
	sidebarPadding.PaddingTop = UDim.new(0, 8)
	sidebarPadding.Parent = sidebar
	
	local verticalSeparator = Instance.new("Frame")
	verticalSeparator.Name = "VerticalSeparator"
	verticalSeparator.Size = UDim2.new(0, 1, 1, -51)
	verticalSeparator.Position = UDim2.new(0, sidebarWidth, 0, 51)
	verticalSeparator.BackgroundColor3 = NebulaUI.Theme.CardBorder
	verticalSeparator.BorderSizePixel = 0
	verticalSeparator.Parent = mainFrame
	
	-- Contenedor de contenido de las pestañas
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, -sidebarWidth - 1, 1, -51)
	container.Position = UDim2.new(0, sidebarWidth + 1, 0, 51)
	container.BackgroundTransparency = 1
	container.Parent = mainFrame
	
	self.Sidebar = sidebar
	self.Container = container
	
	table.insert(NebulaUI.Windows, self)
	
	return self
end

-- Eliminar esta ventana de la GUI
function Window:Destroy()
	pcall(function()
		self.ScreenGui:Destroy()
	end)
	for i, win in ipairs(NebulaUI.Windows) do
		if win == self then
			table.remove(NebulaUI.Windows, i)
			break
		end
	end
end

-- Guardar configuración en la carpeta del executor
function Window:SaveConfig()
	if not self.ConfigSaving or not self.ConfigSaving.Enabled then return end
	local folder = self.ConfigSaving.Folder or "NebulaUI"
	local file = self.ConfigSaving.FileName or "config"
	
	pcall(function()
		if writefile then
			if makefolder then
				pcall(function() makefolder(folder) end)
			end
			local data = {}
			for k, v in pairs(self.Flags) do
				if nebulaTypeof(v) == "Color3" then
					data[k] = {__type = "Color3", r = v.R, g = v.G, b = v.B}
				elseif nebulaTypeof(v) == "EnumItem" then
					data[k] = {__type = "EnumItem", name = v.Name, value = v.Value}
				else
					data[k] = v
				end
			end
			writefile(folder .. "/" .. file .. ".json", HttpService:JSONEncode(data))
		end
	end)
end

-- Cargar configuración guardada
function Window:LoadConfig()
	if not self.ConfigSaving or not self.ConfigSaving.Enabled then return end
	local folder = self.ConfigSaving.Folder or "NebulaUI"
	local file = self.ConfigSaving.FileName or "config"
	
	pcall(function()
		if isfile and readfile then
			local filepath = folder .. "/" .. file .. ".json"
			if isfile(filepath) then
				local content = readfile(filepath)
				local decoded = HttpService:JSONDecode(content)
				for k, v in pairs(decoded) do
					if type(v) == "table" and v.__type then
						if v.__type == "Color3" then
							self.Flags[k] = Color3.new(v.r, v.g, v.b)
						elseif v.__type == "EnumItem" then
							pcall(function()
								self.Flags[k] = Enum.KeyCode[v.name]
							end)
						end
					else
						self.Flags[k] = v
					end
				end
			end
		end
	end)
end

-- Actualizar dinámicamente el color del tema en toda la interfaz en tiempo real
function Window:UpdateTheme(accentColor)
	if not accentColor or nebulaTypeof(accentColor) ~= "Color3" then return end
	if not self.ScreenGui then return end
	
	NebulaUI.Theme.Accent = accentColor
	NebulaUI.Theme.CardBorderHover = accentColor
	NebulaUI.Theme.ToggleOn = accentColor
	
	local h, s, v = Color3.toHSV(accentColor)
	local darkAccent = Color3.fromHSV(h, s, mathClamp(v * 0.25, 0.1, 0.3))
	local selectionAccent = Color3.fromHSV(h, s, mathClamp(v * 0.18, 0.08, 0.22))
	
	-- Actualizar botón flotante (Toggle) y subtítulo del Header
	pcall(function()
		local toggle = self.ScreenGui:FindFirstChild("Toggle")
		if toggle then
			local toggleIcon = toggle:FindFirstChild("Icon")
			if toggleIcon then
				toggleIcon.ImageColor3 = accentColor
			end
		end
		local mainFrame = self.ScreenGui:FindFirstChild("MainFrame")
		if mainFrame then
			local header = mainFrame:FindFirstChild("Header")
			if header then
				local subtitle = header:FindFirstChild("Subtitle")
				if subtitle then
					subtitle.TextColor3 = accentColor
				end
			end
		end
	end)
	
	-- Recorrer todos los descendientes de forma segura y optimizada sin pcalls anidados
	for _, obj in ipairs(self.ScreenGui:GetDescendants()) do
		local name = obj.Name
		
		-- Sliders
		if name == "Fill" then
			local parent = obj.Parent
			if parent and parent.Name == "Track" then
				obj.BackgroundColor3 = accentColor
			end
		elseif name == "Value" then
			local parent = obj.Parent
			if parent and (parent.Name:find("Slider") or parent.Name:find("_Container")) then
				obj.TextColor3 = accentColor
			end
		elseif name == "Knob" then
			local parent = obj.Parent
			if parent and parent.Name == "Track" then
				local stroke = obj:FindFirstChildOfClass("UIStroke")
				if stroke then stroke.Color = accentColor end
			end
		
		-- Toggles
		elseif name == "Switch" then
			if obj.BackgroundColor3 ~= NebulaUI.Theme.ToggleOff then
				obj.BackgroundColor3 = accentColor
			end
			
		-- Dropdowns
		elseif name == "Display" then
			local parent = obj.Parent
			if parent and parent.Name == "Trigger" then
				obj.TextColor3 = accentColor
			end
		elseif obj:IsA("TextButton") and obj.Parent and obj.Parent.Name == "ListFrame" then
			if obj.TextColor3 ~= NebulaUI.Theme.MutedText then
				obj.TextColor3 = accentColor
				obj.BackgroundColor3 = selectionAccent
			end
			
		-- Keybinds
		elseif name == "BindBtn" then
			if obj.TextColor3 ~= NebulaUI.Theme.SecondaryAccent then
				obj.TextColor3 = accentColor
			end
			
		-- Botones estándar
		elseif name == "Button" and obj:IsA("TextButton") then
			obj.BackgroundColor3 = accentColor
			
		-- Pestañas en el Sidebar
		elseif obj:IsA("TextButton") and obj.Parent and obj.Parent.Name == "Sidebar" then
			if obj.TextColor3 ~= NebulaUI.Theme.MutedText then
				obj.TextColor3 = accentColor
			end
			
		-- ScrollingFrames
		elseif obj:IsA("ScrollingFrame") then
			obj.ScrollBarImageColor3 = accentColor
			
		-- Separadores / Títulos
		elseif name == "TextLabel" then
			local parent = obj.Parent
			if parent and parent.Name:find("Separator_") then
				obj.TextColor3 = accentColor
			end
		end
	end
end

-- Agregar una pestaña (Tab) al menú
function Window:AddTab(title)
	local tabObj = setmetatable({}, Tab)
	tabObj.Window = self
	tabObj.Active = false
	
	local isMobile = self.IsMobile
	
	-- Botón de pestaña en el Sidebar
	local btn = Instance.new("TextButton")
	btn.Name = title
	btn.Size = UDim2.new(0.9, 0, 0, isMobile and 28 or 32)
	btn.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamMedium
	btn.Text = title
	btn.TextColor3 = NebulaUI.Theme.MutedText
	btn.TextSize = isMobile and 11 or 12
	btn.Parent = self.Sidebar
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn
	
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = NebulaUI.Theme.CardBorder
	btnStroke.Thickness = 1
	btnStroke.Parent = btn
	
	-- Contenedor deslizable de la pestaña
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = title .. "_Content"
	contentFrame.Size = UDim2.new(1, 0, 1, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 3
	contentFrame.ScrollBarImageColor3 = NebulaUI.Theme.Accent
	contentFrame.Visible = false
	contentFrame.Parent = self.Container
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = contentFrame
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = contentFrame
	
	tabObj.Button = btn
	tabObj.ContentFrame = contentFrame
	
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabObj:_UpdateCanvas()
	end)
	
	-- Función para activar la pestaña de forma segura
	local function selectTab()
		for _, otherTab in ipairs(self.Tabs) do
			otherTab.Active = false
			otherTab.ContentFrame.Visible = false
			otherTab.Button.TextColor3 = NebulaUI.Theme.MutedText
			otherTab.Button.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
			local stroke = otherTab.Button:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = NebulaUI.Theme.CardBorder
			end
		end
		
		tabObj.Active = true
		contentFrame.Visible = true
		btn.TextColor3 = NebulaUI.Theme.Accent
		btn.BackgroundColor3 = Color3.fromRGB(20, 21, 26)
		local stroke = btn:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = NebulaUI.Theme.CardBorder
		end
	end
	
	btn.MouseButton1Click:Connect(selectTab)
	
	table.insert(self.Tabs, tabObj)
	
	-- Seleccionar la primera pestaña por defecto
	if #self.Tabs == 1 then
		selectTab()
	end
	
	return tabObj
end

-- Agregar un Slider a la pestaña
function Tab:AddSlider(name, options)
	options = options or {}
	local min = options.Min or 0
	local max = options.Max or 100
	local default = options.Default or min
	local callback = options.Callback or function() end
	local rounding = options.Rounding or 1
	local flag = options.Flag
	
	if flag and self.Window.Flags[flag] ~= nil then
		default = self.Window.Flags[flag]
	elseif flag then
		self.Window.Flags[flag] = default
	end
	
	local currentValue = default
	local isMobile = self.Window.IsMobile
	
	local sliderHeight = isMobile and 48 or 56
	local sliderFrame = createBase(self, name, sliderHeight)
	
	-- Texto del título del Slider
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0.7, 0, 0, isMobile and 16 or 20)
	titleLabel.Position = UDim2.new(0, 10, 0, isMobile and 4 or 6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamMedium
	titleLabel.Text = name
	titleLabel.TextColor3 = NebulaUI.Theme.Text
	titleLabel.TextSize = isMobile and 11 or 12
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = sliderFrame
	
	-- Texto que muestra el valor actual
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(0.25, 0, 0, isMobile and 16 or 20)
	valueLabel.Position = UDim2.new(0.7, -10, 0, isMobile and 4 or 6)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.Text = tostring(currentValue)
	valueLabel.TextColor3 = NebulaUI.Theme.Accent
	valueLabel.TextSize = isMobile and 11 or 12
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = sliderFrame
	
	-- Pista de fondo del Slider
	local sliderTrack = Instance.new("Frame")
	sliderTrack.Name = "Track"
	sliderTrack.Size = UDim2.new(1, -20, 0, isMobile and 5 or 6)
	sliderTrack.Position = UDim2.new(0, 10, 0, isMobile and 30 or 36)
	sliderTrack.BackgroundColor3 = Color3.fromRGB(35, 36, 45)
	sliderTrack.BorderSizePixel = 0
	sliderTrack.Parent = sliderFrame
	
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = sliderTrack
	
	-- Relleno activo del Slider (Color Sólido)
	local sliderFill = Instance.new("Frame")
	sliderFill.Name = "Fill"
	sliderFill.Size = UDim2.new(0, 0, 1, 0)
	sliderFill.BackgroundColor3 = NebulaUI.Theme.Accent
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderTrack
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = sliderFill
	
	-- Botón deslizable (Knob)
	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = udim2FromOffset(14, 14)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	knob.BorderSizePixel = 0
	knob.Parent = sliderTrack
	
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob
	
	local knobStroke = Instance.new("UIStroke")
	knobStroke.Color = NebulaUI.Theme.Accent
	knobStroke.Thickness = 1
	knobStroke.Parent = knob
	
	local isDragging = false
	
	-- Actualizar el valor
	local function updateValue(inputX)
		local trackWidth = sliderTrack.AbsoluteSize.X
		if trackWidth <= 0 then return end
		
		local trackPos = sliderTrack.AbsolutePosition.X
		local alpha = mathClamp((inputX - trackPos) / trackWidth, 0, 1)
		
		local rawValue = min + (max - min) * alpha
		local factor = 10 ^ (rounding or 0)
		currentValue = math.floor(rawValue * factor + 0.5) / factor
		currentValue = mathClamp(currentValue, min, max)
		
		if flag then
			self.Window.Flags[flag] = currentValue
			self.Window:SaveConfig()
		end
		
		local displayAlpha = (currentValue - min) / (max - min)
		sliderFill.Size = UDim2.new(displayAlpha, 0, 1, 0)
		knob.Position = UDim2.new(displayAlpha, 0, 0.5, 0)
		valueLabel.Text = tostring(currentValue)
		
		pcall(callback, currentValue)
	end
	
	-- Inicializar
	local initialAlpha = (currentValue - min) / (max - min)
	sliderFill.Size = UDim2.new(initialAlpha, 0, 1, 0)
	knob.Position = UDim2.new(initialAlpha, 0, 0.5, 0)
	
	sliderTrack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
			updateValue(input.Position.X)
		end
	end)
	
	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateValue(input.Position.X)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDragging = false
		end
	end)
	
	knob.MouseEnter:Connect(function()
		TweenService:Create(knob, TweenInfo.new(0.15), {
			BackgroundColor3 = NebulaUI.Theme.Accent
		}):Play()
	end)
	knob.MouseLeave:Connect(function()
		TweenService:Create(knob, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(245, 245, 245)
		}):Play()
	end)
	
	NebulaTask.spawn(function() self:_UpdateCanvas() end)
	
	return {
		SetValue = function(val)
			currentValue = mathClamp(val, min, max)
			if flag then
				self.Window.Flags[flag] = currentValue
				self.Window:SaveConfig()
			end
			local targetAlpha = (currentValue - min) / (max - min)
			sliderFill.Size = UDim2.new(targetAlpha, 0, 1, 0)
			knob.Position = UDim2.new(targetAlpha, 0, 0.5, 0)
			valueLabel.Text = tostring(currentValue)
			pcall(callback, currentValue)
		end,
		GetValue = function()
			return currentValue
		end
	}
end

-- Agregar un Toggle (Switch) a la pestaña
function Tab:AddToggle(name, options)
	options = options or {}
	local default = options.Default or false
	local callback = options.Callback or function() end
	local flag = options.Flag
	
	if flag and self.Window.Flags[flag] ~= nil then
		default = self.Window.Flags[flag]
	elseif flag then
		self.Window.Flags[flag] = default
	end
	
	local state = default
	local isMobile = self.Window.IsMobile
	local height = isMobile and 38 or 44
	local frame = createBase(self, name, height)
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = name
	label.TextColor3 = NebulaUI.Theme.Text
	label.TextSize = isMobile and 11 or 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	
	-- Contenedor del Switch (Pill)
	local switch = Instance.new("TextButton")
	switch.Name = "Switch"
	switch.Size = udim2FromOffset(36, 20)
	switch.Position = UDim2.new(1, -48, 0.5, -10)
	switch.BackgroundColor3 = state and NebulaUI.Theme.ToggleOn or NebulaUI.Theme.ToggleOff
	switch.Text = ""
	switch.Parent = frame
	
	local switchCorner = Instance.new("UICorner")
	switchCorner.CornerRadius = UDim.new(1, 0)
	switchCorner.Parent = switch
	
	local switchStroke = Instance.new("UIStroke")
	switchStroke.Color = NebulaUI.Theme.CardBorder
	switchStroke.Thickness = 1
	switchStroke.Parent = switch
	
	-- Knob circular
	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = udim2FromOffset(14, 14)
	knob.Position = UDim2.new(state and 1 or 0, state and -17 or 3, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	knob.BorderSizePixel = 0
	knob.Parent = switch
	
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob
	
	local function updateToggle(newState)
		state = newState
		if flag then
			self.Window.Flags[flag] = state
			self.Window:SaveConfig()
		end
		local targetColor = state and NebulaUI.Theme.ToggleOn or NebulaUI.Theme.ToggleOff
		local targetPos = UDim2.new(state and 1 or 0, state and -17 or 3, 0.5, -7)
		
		TweenService:Create(switch, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = targetColor
		}):Play()
		
		TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = targetPos
		}):Play()
		
		pcall(callback, state)
	end
	
	switch.MouseButton1Click:Connect(function()
		updateToggle(not state)
	end)
	
	NebulaTask.spawn(function() self:_UpdateCanvas() end)
	
	return {
		SetValue = function(val)
			updateToggle(val)
		end,
		GetValue = function()
			return state
		end
	}
end

-- Agregar un botón simple a la pestaña
function Tab:AddButton(name, options)
	options = options or {}
	local callback = options.Callback or function() end
	local description = options.Description or ""
	
	local isMobile = self.Window.IsMobile
	local hasDesc = description ~= ""
	local height = hasDesc and (isMobile and 46 or 52) or (isMobile and 38 or 44)
	
	local frame = createBase(self, name, height)
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.65, -12, hasDesc and 0.5 or 1, 0)
	label.Position = UDim2.new(0, 12, 0, hasDesc and 4 or 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = name
	label.TextColor3 = NebulaUI.Theme.Text
	label.TextSize = isMobile and 11 or 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = frame
	
	if hasDesc then
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "Description"
		descLabel.Size = UDim2.new(0.65, -12, 0.5, 0)
		descLabel.Position = UDim2.new(0, 12, 0.5, -2)
		descLabel.BackgroundTransparency = 1
		descLabel.Font = Enum.Font.Gotham
		descLabel.Text = description
		descLabel.TextColor3 = NebulaUI.Theme.MutedText
		descLabel.TextSize = isMobile and 9 or 10
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.Parent = frame
	end
	
	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Size = UDim2.new(0.3, 0, 0, isMobile and 24 or 28)
	button.Position = UDim2.new(0.7, -12, 0.5, isMobile and -12 or -14)
	button.BackgroundColor3 = NebulaUI.Theme.Accent
	button.Font = Enum.Font.GothamBold
	button.Text = "Click"
	button.TextColor3 = NebulaUI.Theme.Text
	button.TextSize = isMobile and 10 or 11
	button.Parent = frame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = button
	
	-- Animaciones al hacer click (Efecto Ripple / Presionado)
	button.MouseButton1Click:Connect(function()
		local pressTween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.28, 0, 0, isMobile and 22 or 26),
			Position = UDim2.new(0.71, -12, 0.5, isMobile and -11 or -13)
		})
		pressTween:Play()
		pressTween.Completed:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0.3, 0, 0, isMobile and 24 or 28),
				Position = UDim2.new(0.7, -12, 0.5, isMobile and -12 or -14)
			}):Play()
		end)
		
		pcall(callback)
	end)
	
	NebulaTask.spawn(function() self:_UpdateCanvas() end)
	
	return {
		Fire = function()
			pcall(callback)
		end
	}
end

-- Agregar un TextBox (input de texto) a la pestaña
function Tab:AddTextBox(name, options)
	options = options or {}
	local default = options.Default or ""
	local placeholder = options.Placeholder or "Escribe..."
	local clearOnFocus = options.ClearOnFocus or false
	local callback = options.Callback or function() end
	local flag = options.Flag
	
	if flag and self.Window.Flags[flag] ~= nil then
		default = self.Window.Flags[flag]
	elseif flag then
		self.Window.Flags[flag] = default
	end
	
	local isMobile = self.Window.IsMobile
	local height = isMobile and 38 or 44
	local frame = createBase(self, name, height)
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = name
	label.TextColor3 = NebulaUI.Theme.Text
	label.TextSize = isMobile and 11 or 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	
	local inputFrame = Instance.new("Frame")
	inputFrame.Name = "InputFrame"
	inputFrame.Size = UDim2.new(0.4, 0, 0, isMobile and 24 or 28)
	inputFrame.Position = UDim2.new(0.6, -12, 0.5, isMobile and -12 or -14)
	inputFrame.BackgroundColor3 = Color3.fromRGB(24, 25, 32)
	inputFrame.BorderSizePixel = 0
	inputFrame.Parent = frame
	
	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 6)
	inputCorner.Parent = inputFrame
	
	local inputStroke = Instance.new("UIStroke")
	inputStroke.Color = NebulaUI.Theme.CardBorder
	inputStroke.Thickness = 1
	inputStroke.Parent = inputFrame
	
	local textbox = Instance.new("TextBox")
	textbox.Name = "TextBox"
	textbox.Size = UDim2.new(1, -8, 1, 0)
	textbox.Position = UDim2.new(0, 4, 0, 0)
	textbox.BackgroundTransparency = 1
	textbox.Font = Enum.Font.Gotham
	textbox.Text = default
	textbox.PlaceholderText = placeholder
	textbox.PlaceholderColor3 = NebulaUI.Theme.MutedText
	textbox.TextColor3 = NebulaUI.Theme.Text
	textbox.TextSize = isMobile and 10 or 11
	textbox.ClearTextOnFocus = clearOnFocus
	textbox.ClipsDescendants = true
	textbox.Parent = inputFrame
	
	textbox.Focused:Connect(function()
		TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color = NebulaUI.Theme.Accent}):Play()
	end)
	
	textbox.FocusLost:Connect(function(enterPressed)
		TweenService:Create(inputStroke, TweenInfo.new(0.2), {Color = NebulaUI.Theme.CardBorder}):Play()
		if flag then
			self.Window.Flags[flag] = textbox.Text
			self.Window:SaveConfig()
		end
		pcall(callback, textbox.Text)
	end)
	
	NebulaTask.spawn(function() self:_UpdateCanvas() end)
	
	return {
		SetValue = function(val)
			textbox.Text = val
			if flag then
				self.Window.Flags[flag] = val
				self.Window:SaveConfig()
			end
			pcall(callback, val)
		end,
		GetValue = function()
			return textbox.Text
		end
	}
end

-- Agregar un Dropdown a la pestaña
function Tab:AddDropdown(name, options)
	options = options or {}
	local items = options.Items or {}
	local default = options.Default or ""
	local callback = options.Callback or function() end
	local flag = options.Flag
	
	if flag and self.Window.Flags[flag] ~= nil then
		default = self.Window.Flags[flag]
	elseif flag then
		self.Window.Flags[flag] = default
	end
	
	local isMobile = self.Window.IsMobile
	local collapsedHeight = isMobile and 38 or 44
	local selectedValue = default
	local isOpened = false
	
	-- Contenedor del dropdown (con ClipsDescendants para colapsar/abrir)
	local frame = Instance.new("Frame")
	frame.Name = name .. "_Dropdown"
	frame.Size = UDim2.new(0.95, 0, 0, collapsedHeight)
	frame.BackgroundColor3 = NebulaUI.Theme.CardBackground
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = self.ContentFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = NebulaUI.Theme.CardBorder
	stroke.Thickness = 1
	stroke.Parent = frame
	
	-- Hover visual
	frame.MouseEnter:Connect(function()
		if not isOpened then
			TweenService:Create(stroke, TweenInfo.new(0.2), {Color = NebulaUI.Theme.CardBorderHover}):Play()
		end
	end)
	frame.MouseLeave:Connect(function()
		if not isOpened then
			TweenService:Create(stroke, TweenInfo.new(0.2), {Color = NebulaUI.Theme.CardBorder}):Play()
		end
	end)
	
	-- Elemento interactivo principal de cabecera
	local trigger = Instance.new("TextButton")
	trigger.Name = "Trigger"
	trigger.Size = UDim2.new(1, 0, 0, collapsedHeight)
	trigger.BackgroundTransparency = 1
	trigger.Text = ""
	trigger.Parent = frame
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = name
	label.TextColor3 = NebulaUI.Theme.Text
	label.TextSize = isMobile and 11 or 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = trigger
	
	-- Texto seleccionado actual
	local display = Instance.new("TextLabel")
	display.Name = "Display"
	display.Size = UDim2.new(0.35, 0, 1, 0)
	display.Position = UDim2.new(0.65, -30, 0, 0)
	display.BackgroundTransparency = 1
	display.Font = Enum.Font.GothamSemibold
	display.Text = selectedValue == "" and "Seleccionar..." or selectedValue
	display.TextColor3 = NebulaUI.Theme.Accent
	display.TextSize = isMobile and 10 or 11
	display.TextXAlignment = Enum.TextXAlignment.Right
	display.Parent = trigger
	
	-- Flechita de despliegue
	local arrow = Instance.new("ImageLabel")
	arrow.Name = "Arrow"
	arrow.Size = udim2FromOffset(12, 12)
	arrow.Position = UDim2.new(1, -24, 0.5, -6)
	arrow.BackgroundTransparency = 1
	arrow.Image = "rbxassetid://6034818372" -- Flecha abajo
	arrow.ImageColor3 = NebulaUI.Theme.MutedText
	arrow.Parent = trigger
	
	-- Contenedor del listado (dentro de un scrolling frame interno)
	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "ListFrame"
	listFrame.Size = UDim2.new(1, -20, 1, -collapsedHeight - 8)
	listFrame.Position = UDim2.new(0, 10, 0, collapsedHeight + 4)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 2
	listFrame.ScrollBarImageColor3 = NebulaUI.Theme.Accent
	listFrame.Parent = frame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listFrame
	
	local optionButtons = {}
	
	-- Limpiar y recrear las opciones
	local function populateItems()
		for _, child in ipairs(listFrame:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		tableClear(optionButtons)
		
		for idx, item in ipairs(items) do
			local opt = Instance.new("TextButton")
			opt.Name = item
			opt.Size = UDim2.new(1, 0, 0, isMobile and 24 or 28)
			opt.BackgroundColor3 = (item == selectedValue) and Color3.fromRGB(35, 22, 45) or Color3.fromRGB(24, 25, 32)
			opt.BorderSizePixel = 0
			opt.Font = Enum.Font.GothamMedium
			opt.Text = "  " .. item
			opt.TextColor3 = (item == selectedValue) and NebulaUI.Theme.Accent or NebulaUI.Theme.MutedText
			opt.TextSize = isMobile and 10 or 11
			opt.TextXAlignment = Enum.TextXAlignment.Left
			opt.LayoutOrder = idx
			opt.Parent = listFrame
			
			local optCorner = Instance.new("UICorner")
			optCorner.CornerRadius = UDim.new(0, 4)
			optCorner.Parent = opt
			
			opt.MouseButton1Click:Connect(function()
				selectedValue = item
				display.Text = item
				
				if flag then
					self.Window.Flags[flag] = selectedValue
					self.Window:SaveConfig()
				end
				
				-- Actualizar colores de las opciones
				for _, otherOpt in ipairs(listFrame:GetChildren()) do
					if otherOpt:IsA("TextButton") then
						local isSelected = (otherOpt.Name == selectedValue)
						otherOpt.BackgroundColor3 = isSelected and Color3.fromRGB(35, 22, 45) or Color3.fromRGB(24, 25, 32)
						otherOpt.TextColor3 = isSelected and NebulaUI.Theme.Accent or NebulaUI.Theme.MutedText
					end
				end
				
				-- Colapsar dropdown
				isOpened = false
				TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(0.95, 0, 0, collapsedHeight)
				}):Play()
				TweenService:Create(arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Rotation = 0
				}):Play()
				
				pcall(callback, item)
				
				NebulaTask.delay(0.26, function()
					self:_UpdateCanvas()
				end)
			end)
		end
		
		local contentSize = listLayout.AbsoluteContentSize.Y
		listFrame.CanvasSize = UDim2.new(0, 0, 0, contentSize)
	end
	
	populateItems()
	
	-- Handler de apertura/cierre
	trigger.MouseButton1Click:Connect(function()
		isOpened = not isOpened
		local targetHeight = collapsedHeight
		local targetRotation = 0
		
		if isOpened then
			local numItems = #items
			local listHeight = mathClamp(numItems * (isMobile and 28 or 32), 60, 120)
			targetHeight = collapsedHeight + listHeight + 12
			targetRotation = 180
			stroke.Color = NebulaUI.Theme.Accent
		else
			stroke.Color = NebulaUI.Theme.CardBorder
		end
		
		TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.95, 0, 0, targetHeight)
		}):Play()
		
		TweenService:Create(arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Rotation = targetRotation
		}):Play()
		
		-- Loop para animar el canvas mientras se expande
		local start = os.clock()
		while os.clock() - start < 0.26 do
			self:_UpdateCanvas()
			NebulaTask.wait()
		end
		self:_UpdateCanvas()
	end)
	
	NebulaTask.spawn(function() self:_UpdateCanvas() end)
	
	return {
		SetValue = function(item)
			selectedValue = item
			display.Text = item
			if flag then
				self.Window.Flags[flag] = selectedValue
				self.Window:SaveConfig()
			end
			pcall(callback, item)
			populateItems()
		end,
		GetValue = function()
			return selectedValue
		end,
		Refresh = function(newItems)
			items = newItems or {}
			if not tableFind(items, selectedValue) then
				selectedValue = ""
				display.Text = "Seleccionar..."
			end
			populateItems()
		end
	}
end

-- Agregar un Label (Texto descriptivo) a la pestaña
function Tab:AddLabel(text, options)
	options = options or {}
	local color = options.Color or NebulaUI.Theme.Text
	
	local isMobile = self.Window.IsMobile
	local frame = createBase(self, "Label", isMobile and 30 or 34)
	
	local label = Instance.new("TextLabel")
	label.Name = "TextLabel"
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.TextColor3 = color
	label.TextSize = isMobile and 11 or 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = frame
	
	NebulaTask.spawn(function() self:_UpdateCanvas() end)
	
	return {
		Set = function(newText)
			label.Text = newText
		end
	}
end

-- Agregar un Paragraph (Párrafo largo con título) a la pestaña
function Tab:AddParagraph(titleText, contentText)
	local isMobile = self.Window.IsMobile
	local TextService = game:GetService("TextService")
	
	local sidebarWidth = isMobile and 95 or 120
	local mainWidth = isMobile and 360 or 450
	local contentWidth = (mainWidth - sidebarWidth - 1) * 0.95 - 20
	
	local titleFont = Enum.Font.GothamBold
	local titleSize = isMobile and 11 or 12
	local contentFont = Enum.Font.Gotham
	local contentSize = isMobile and 9 or 10
	
	local titleBounds = TextService:GetTextSize(titleText, titleSize, titleFont, Vector2.new(contentWidth, 1000))
	local contentBounds = TextService:GetTextSize(contentText, contentSize, contentFont, Vector2.new(contentWidth, 1000))
	
	local height = titleBounds.Y + contentBounds.Y + 22
	local frame = createBase(self, "Paragraph", height)
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -20, 0, titleBounds.Y)
	titleLabel.Position = UDim2.new(0, 10, 0, 6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = titleFont
	titleLabel.Text = titleText
	titleLabel.TextColor3 = NebulaUI.Theme.Text
	titleLabel.TextSize = titleSize
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextWrapped = true
	titleLabel.Parent = frame
	
	local contentLabel = Instance.new("TextLabel")
	contentLabel.Name = "Content"
	contentLabel.Size = UDim2.new(1, -20, 0, contentBounds.Y)
	contentLabel.Position = UDim2.new(0, 10, 0, 6 + titleBounds.Y + 4)
	contentLabel.BackgroundTransparency = 1
	contentLabel.Font = contentFont
	contentLabel.Text = contentText
	contentLabel.TextColor3 = NebulaUI.Theme.MutedText
	contentLabel.TextSize = contentSize
	contentLabel.TextXAlignment = Enum.TextXAlignment.Left
	contentLabel.TextWrapped = true
	contentLabel.Parent = frame
	
	NebulaTask.spawn(function() self:_UpdateCanvas() end)
	
	return {
		Set = function(newTitle, newContent)
			titleLabel.Text = newTitle
			contentLabel.Text = newContent
			
			local newTitleBounds = TextService:GetTextSize(newTitle, titleSize, titleFont, Vector2.new(contentWidth, 1000))
			local newContentBounds = TextService:GetTextSize(newContent, contentSize, contentFont, Vector2.new(contentWidth, 1000))
			
			titleLabel.Size = UDim2.new(1, -20, 0, newTitleBounds.Y)
			contentLabel.Size = UDim2.new(1, -20, 0, newContentBounds.Y)
			contentLabel.Position = UDim2.new(0, 10, 0, 6 + newTitleBounds.Y + 4)
			
			frame.Size = UDim2.new(0.95, 0, 0, newTitleBounds.Y + newContentBounds.Y + 22)
			self:_UpdateCanvas()
		end
	}
end

-- Agregar un Separador visual
function Tab:AddSeparator(name)
	self.LayoutOrderCounter = (self.LayoutOrderCounter or 0) + 1
	local isMobile = self.Window.IsMobile
	local frame = Instance.new("Frame")
	frame.Name = "Separator_" .. name
	frame.Size = UDim2.new(0.95, 0, 0, 20)
	frame.LayoutOrder = self.LayoutOrderCounter
	frame.BackgroundTransparency = 1
	frame.Parent = self.ContentFrame
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "TextLabel"
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = string.upper(name)
	textLabel.TextColor3 = NebulaUI.Theme.Accent
	textLabel.TextSize = isMobile and 10 or 11
	textLabel.TextXAlignment = Enum.TextXAlignment.Center
	textLabel.Parent = frame
	
	NebulaTask.spawn(function() self:_UpdateCanvas() end)
end

-- Agregar un KeyBind a la pestaña
function Tab:AddKeyBind(name, options)
	options = options or {}
	local default = options.Default or Enum.KeyCode.RightShift
	local callback = options.Callback or function() end
	local flag = options.Flag
	
	if flag and self.Window.Flags[flag] ~= nil then
		default = self.Window.Flags[flag]
	elseif flag then
		self.Window.Flags[flag] = default
	end
	
	local currentKey = default
	local listening = false
	local isMobile = self.Window.IsMobile
	local height = isMobile and 38 or 44
	local frame = createBase(self, name, height)
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = name
	label.TextColor3 = NebulaUI.Theme.Text
	label.TextSize = isMobile and 11 or 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	
	local bindBtn = Instance.new("TextButton")
	bindBtn.Name = "BindBtn"
	bindBtn.Size = UDim2.new(0.3, 0, 0, isMobile and 24 or 28)
	bindBtn.Position = UDim2.new(0.7, -12, 0.5, isMobile and -12 or -14)
	bindBtn.BackgroundColor3 = Color3.fromRGB(24, 25, 32)
	bindBtn.Font = Enum.Font.GothamBold
	bindBtn.Text = currentKey.Name
	bindBtn.TextColor3 = NebulaUI.Theme.Accent
	bindBtn.TextSize = isMobile and 10 or 11
	bindBtn.Parent = frame
	
	local bindCorner = Instance.new("UICorner")
	bindCorner.CornerRadius = UDim.new(0, 6)
	bindCorner.Parent = bindBtn
	
	local bindStroke = Instance.new("UIStroke")
	bindStroke.Color = NebulaUI.Theme.CardBorder
	bindStroke.Thickness = 1
	bindStroke.Parent = bindBtn
	
	local function startListening()
		listening = true
		bindBtn.Text = "..."
		bindBtn.TextColor3 = NebulaUI.Theme.SecondaryAccent
		bindStroke.Color = NebulaUI.Theme.SecondaryAccent
	end
	
	local function assignKey(key)
		listening = false
		currentKey = key
		bindBtn.Text = key.Name
		bindBtn.TextColor3 = NebulaUI.Theme.Accent
		bindStroke.Color = NebulaUI.Theme.CardBorder
		if flag then
			self.Window.Flags[flag] = currentKey
			self.Window:SaveConfig()
		end
	end
	
	bindBtn.MouseButton1Click:Connect(function()
		if not listening then
			startListening()
		end
	end)
	
	-- Capturar input de teclado
	UserInputService.InputBegan:Connect(function(input, processed)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			assignKey(input.KeyCode)
		elseif not processed and input.KeyCode == currentKey then
			pcall(callback)
		end
	end)
	
	NebulaTask.spawn(function() self:_UpdateCanvas() end)
	
	return {
		SetValue = function(key)
			assignKey(key)
		end,
		GetValue = function()
			return currentKey
		end
	}
end

-- Agregar un ColorPicker a la pestaña
function Tab:AddColorPicker(name, options)
	options = options or {}
	local default = options.Default or Color3.fromRGB(255, 0, 0)
	local callback = options.Callback or function() end
	local flag = options.Flag
	
	if flag and self.Window.Flags[flag] ~= nil then
		default = self.Window.Flags[flag]
	elseif flag then
		self.Window.Flags[flag] = default
	end
	
	local isMobile = self.Window.IsMobile
	local collapsedHeight = isMobile and 38 or 44
	local colorValue = default
	local h, s, v = Color3.toHSV(colorValue)
	local isOpened = false
	
	local function toHex(color)
		local r = mathRound(color.R * 255)
		local g = mathRound(color.G * 255)
		local b = mathRound(color.B * 255)
		return string.format("#%02X%02X%02X", r, g, b)
	end
	
	local frame = Instance.new("Frame")
	frame.Name = name .. "_ColorPicker"
	frame.Size = UDim2.new(0.95, 0, 0, collapsedHeight)
	frame.BackgroundColor3 = NebulaUI.Theme.CardBackground
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = self.ContentFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = NebulaUI.Theme.CardBorder
	stroke.Thickness = 1
	stroke.Parent = frame
	
	-- Cabecera
	local trigger = Instance.new("TextButton")
	trigger.Name = "Trigger"
	trigger.Size = UDim2.new(1, 0, 0, collapsedHeight)
	trigger.BackgroundTransparency = 1
	trigger.Text = ""
	trigger.Parent = frame
	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = name
	label.TextColor3 = NebulaUI.Theme.Text
	label.TextSize = isMobile and 11 or 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = trigger
	
	-- Texto con valor hexadecimal del color
	local hexLabel = Instance.new("TextLabel")
	hexLabel.Name = "HexLabel"
	hexLabel.Size = UDim2.new(0, 60, 1, 0)
	hexLabel.Position = UDim2.new(1, -114, 0, 0)
	hexLabel.BackgroundTransparency = 1
	hexLabel.Font = Enum.Font.GothamSemibold
	hexLabel.Text = toHex(colorValue)
	hexLabel.TextColor3 = NebulaUI.Theme.MutedText
	hexLabel.TextSize = isMobile and 9 or 10
	hexLabel.TextXAlignment = Enum.TextXAlignment.Right
	hexLabel.Parent = trigger
	
	-- Cuadro visualizador de color actual
	local preview = Instance.new("Frame")
	preview.Name = "Preview"
	preview.Size = udim2FromOffset(36, 16)
	preview.Position = UDim2.new(1, -48, 0.5, -8)
	preview.BackgroundColor3 = colorValue
	preview.Parent = trigger
	
	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 4)
	previewCorner.Parent = preview
	
	local previewStroke = Instance.new("UIStroke")
	previewStroke.Color = Color3.fromRGB(245, 245, 245)
	previewStroke.Thickness = 1
	previewStroke.Parent = preview
	
	-- Área de selección expandida
	local pickerArea = Instance.new("Frame")
	pickerArea.Name = "PickerArea"
	pickerArea.Size = UDim2.new(1, -20, 0, 80)
	pickerArea.Position = UDim2.new(0, 10, 0, collapsedHeight + 4)
	pickerArea.BackgroundTransparency = 1
	pickerArea.Parent = frame
	
	-- Canvas de Sat/Val (2D en base a color de fondo dinámico)
	local satValCanvas = Instance.new("Frame")
	satValCanvas.Name = "SatValCanvas"
	satValCanvas.Size = UDim2.new(0.7, -10, 1, 0)
	satValCanvas.Position = UDim2.new(0, 0, 0, 0)
	satValCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
	satValCanvas.BorderSizePixel = 0
	satValCanvas.Parent = pickerArea
	
	local canvasCorner = Instance.new("UICorner")
	canvasCorner.CornerRadius = UDim.new(0, 6)
	canvasCorner.Parent = satValCanvas
	
	-- Capa de saturación horizontal (Blanco a transparente)
	local satGradFrame = Instance.new("Frame")
	satGradFrame.Name = "SaturationGradient"
	satGradFrame.Size = UDim2.new(1, 0, 1, 0)
	satGradFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	satGradFrame.BorderSizePixel = 0
	satGradFrame.ZIndex = 1
	satGradFrame.Parent = satValCanvas
	
	local satGradCorner = Instance.new("UICorner")
	satGradCorner.CornerRadius = UDim.new(0, 6)
	satGradCorner.Parent = satGradFrame
	
	local satGradient = Instance.new("UIGradient")
	satGradient.Rotation = 0
	satGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	satGradient.Parent = satGradFrame
	
	-- Capa de valor/brillo vertical (Transparente a negro)
	local valGradFrame = Instance.new("Frame")
	valGradFrame.Name = "ValueGradient"
	valGradFrame.Size = UDim2.new(1, 0, 1, 0)
	valGradFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	valGradFrame.BorderSizePixel = 0
	valGradFrame.ZIndex = 2
	valGradFrame.Parent = satValCanvas
	
	local valGradCorner = Instance.new("UICorner")
	valGradCorner.CornerRadius = UDim.new(0, 6)
	valGradCorner.Parent = valGradFrame
	
	local valGradient = Instance.new("UIGradient")
	valGradient.Rotation = 90
	valGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	valGradient.Parent = valGradFrame
	
	-- Cursor en el canvas
	local canvasCursor = Instance.new("Frame")
	canvasCursor.Name = "Cursor"
	canvasCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	canvasCursor.Size = udim2FromOffset(8, 8)
	canvasCursor.Position = UDim2.new(s, 0, 1 - v, 0)
	canvasCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	canvasCursor.ZIndex = 3
	canvasCursor.Parent = satValCanvas
	
	local cursorCorner = Instance.new("UICorner")
	cursorCorner.CornerRadius = UDim.new(1, 0)
	cursorCorner.Parent = canvasCursor
	
	local cursorStroke = Instance.new("UIStroke")
	cursorStroke.Color = Color3.fromRGB(0, 0, 0)
	cursorStroke.Thickness = 1
	cursorStroke.Parent = canvasCursor
	
	-- Slider de Tono (Hue en base a gradiente arcoíris local)
	local hueSlider = Instance.new("Frame")
	hueSlider.Name = "HueSlider"
	hueSlider.Size = UDim2.new(0.3, 0, 1, 0)
	hueSlider.Position = UDim2.new(0.7, 0, 0, 0)
	hueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hueSlider.BorderSizePixel = 0
	hueSlider.Parent = pickerArea
	
	local hueCorner = Instance.new("UICorner")
	hueCorner.CornerRadius = UDim.new(0, 6)
	hueCorner.Parent = hueSlider
	
	local hueGradient = Instance.new("UIGradient")
	hueGradient.Rotation = 90
	hueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
	})
	hueGradient.Parent = hueSlider
	
	-- Barra/Cursor en el slider de tono
	local hueCursor = Instance.new("Frame")
	hueCursor.Name = "HueCursor"
	hueCursor.Size = UDim2.new(1, 4, 0, 4)
	hueCursor.Position = UDim2.new(0, -2, h, -2)
	hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hueCursor.BorderSizePixel = 0
	hueCursor.ZIndex = 3
	hueCursor.Parent = hueSlider
	
	local function updateColor()
		colorValue = Color3.fromHSV(h, s, v)
		preview.BackgroundColor3 = colorValue
		satValCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		hexLabel.Text = toHex(colorValue)
		if isOpened then
			stroke.Color = colorValue
		end
		if flag then
			self.Window.Flags[flag] = colorValue
			self.Window:SaveConfig()
		end
		pcall(callback, colorValue)
	end
	
	-- Inputs en Sat/Val Canvas
	local draggingCanvas = false
	local function updateSatVal(inputX, inputY)
		local sizeX = satValCanvas.AbsoluteSize.X
		local sizeY = satValCanvas.AbsoluteSize.Y
		if sizeX <= 0 or sizeY <= 0 then return end
		
		local posX = satValCanvas.AbsolutePosition.X
		local posY = satValCanvas.AbsolutePosition.Y
		
		s = mathClamp((inputX - posX) / sizeX, 0, 1)
		v = 1 - mathClamp((inputY - posY) / sizeY, 0, 1)
		
		canvasCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		updateColor()
	end
	
	satValCanvas.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingCanvas = true
			updateSatVal(input.Position.X, input.Position.Y)
		end
	end)
	
	-- Inputs en Hue Slider
	local draggingHue = false
	local function updateHue(inputY)
		local sizeY = hueSlider.AbsoluteSize.Y
		if sizeY <= 0 then return end
		
		local posY = hueSlider.AbsolutePosition.Y
		h = mathClamp((inputY - posY) / sizeY, 0, 1)
		
		hueCursor.Position = UDim2.new(0, -2, h, -2)
		updateColor()
	end
	
	hueSlider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingHue = true
			updateHue(input.Position.Y)
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if draggingCanvas then
				updateSatVal(input.Position.X, input.Position.Y)
			elseif draggingHue then
				updateHue(input.Position.Y)
			end
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingCanvas = false
			draggingHue = false
		end
	end)
	
	-- Desplegar y colapsar
	trigger.MouseButton1Click:Connect(function()
		isOpened = not isOpened
		local targetHeight = collapsedHeight
		
		if isOpened then
			targetHeight = collapsedHeight + 96
			stroke.Color = colorValue
		else
			stroke.Color = NebulaUI.Theme.CardBorder
		end
		
		TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.95, 0, 0, targetHeight)
		}):Play()
		
		local start = os.clock()
		while os.clock() - start < 0.26 do
			self:_UpdateCanvas()
			NebulaTask.wait()
		end
		self:_UpdateCanvas()
	end)
	
	NebulaTask.spawn(function() self:_UpdateCanvas() end)
	pcall(callback, colorValue)
	return {
		SetValue = function(color)
			colorValue = color
			h, s, v = Color3.toHSV(colorValue)
			canvasCursor.Position = UDim2.new(s, 0, 1 - v, 0)
			hueCursor.Position = UDim2.new(0, -2, h, -2)
			updateColor()
		end,
		GetValue = function()
			return colorValue
		end
	}
end

return NebulaUI
