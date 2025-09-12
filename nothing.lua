-- Ecstays UI Library
-- Cleaned and redesigned with a pink-purple aesthetic

-- Services
local GetService = game.GetService
local Players = GetService(game, "Players")
local TweenService = GetService(game, "TweenService")
local UserInputService = GetService(game, "UserInputService")
local RunService = GetService(game, "RunService")
local InsertService = GetService(game, "InsertService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Mouse = LocalPlayer:GetMouse()

-- Configuration
local Setup = {
	Keybind = Enum.KeyCode.LeftControl,
	Transparency = 0.1,
	ThemeMode = "Dark",
	Size = UDim2.new(0, 500, 0, 350)
}

-- Pink-Purple Theme
local Theme = {
	Primary = Color3.fromRGB(40, 30, 50),      -- Deep purple background
	Secondary = Color3.fromRGB(50, 40, 60),    -- Slightly lighter purple
	Component = Color3.fromRGB(70, 50, 80),    -- Component background
	Interactables = Color3.fromRGB(200, 100, 150), -- Pink accent
	Text = Color3.fromRGB(240, 200, 220),      -- Light pink text
	Title = Color3.fromRGB(255, 180, 200),     -- Brighter pink for titles
	Shadow = Color3.fromRGB(20, 10, 30),       -- Dark purple shadow
	Outline = Color3.fromRGB(90, 60, 100),     -- Purple outline
	Icon = Color3.fromRGB(220, 180, 200)       -- Soft pink icons
}

-- Utility Functions
local function Tween(Object, Speed, Properties, Style, Direction)
	Style = Style or Enum.EasingStyle.Sine
	Direction = Direction or Enum.EasingDirection.Out
	local tween = TweenService:Create(Object, TweenInfo.new(Speed, Style, Direction), Properties)
	tween:Play()
	return tween
end

local function SetProperty(Object, Properties)
	for Key, Value in pairs(Properties) do
		Object[Key] = Value
	end
	return Object
end

local function Drag(Canvas)
	local dragging, dragInput, startPos, startMouse

	local function update(input)
		local delta = input.Position - startMouse
		Canvas.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	Canvas.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startMouse = input.Position
			startPos = Canvas.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	Canvas.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- Initialize UI
local Screen
if identifyexecutor then
	Screen = InsertService:LoadLocalAsset("rbxassetid://18490507748")
else
	Screen = script.Parent
end

Screen.Main.Visible = false
Screen.Parent = game.CoreGui or PlayerGui

local Components = Screen:FindFirstChild("Components")
local Library = {}
local StoredInfo = { Sections = {}, Tabs = {} }

-- Animations
local Animations = {}

function Animations:Open(Window, Transparency)
	local originalSize = Setup.Size
	local scaledSize = UDim2.new(
		originalSize.X.Scale * 1.05,
		originalSize.X.Offset,
		originalSize.Y.Scale * 1.05,
		originalSize.Y.Offset
	)

	SetProperty(Window, { Size = scaledSize, GroupTransparency = 1, Visible = true })
	Tween(Window.UIStroke, 0.3, { Transparency = 0.3 })
	Tween(Window, 0.3, { Size = originalSize, GroupTransparency = Transparency or 0 })
end

function Animations:Close(Window)
	local originalSize = Window.Size
	local scaledSize = UDim2.new(
		originalSize.X.Scale * 1.05,
		originalSize.X.Offset,
		originalSize.Y.Scale * 1.05,
		originalSize.Y.Offset
	)

	Tween(Window.UIStroke, 0.3, { Transparency = 1 })
	Tween(Window, 0.3, { Size = scaledSize, GroupTransparency = 1 })
	task.wait(0.3)
	Window.Size = originalSize
	Window.Visible = false
end

function Animations:Component(Component)
	Component.InputBegan:Connect(function()
		Tween(Component, 0.2, { BackgroundColor3 = Theme.Interactables })
	end)
	Component.InputEnded:Connect(function()
		Tween(Component, 0.2, { BackgroundColor3 = Theme.Component })
	end)
end

-- Library Functions
function Library:CreateWindow(Settings)
	local Window = Screen.Main:Clone()
	local Sidebar = Window.Sidebar
	local Holder = Window.Main
	local BG = Window.BackgroundShadow
	local Tab = Sidebar.Tab

	local Options = {}
	local Examples = {}
	local opened = true
	local maximized = false

	-- Collect example components
	for _, descendant in pairs(Window:GetDescendants()) do
		if descendant.Name:find("Example") then
			Examples[descendant.Name] = descendant
		end
	end

	-- Setup
	Drag(Window)
	Setup.Transparency = Settings.Transparency or Setup.Transparency
	Setup.Size = Settings.Size or Setup.Size
	Setup.Keybind = Settings.MinimizeKeybind or Setup.Keybind

	-- Window Controls
	local function toggleWindow()
		if opened then
			opened = false
			Animations:Close(Window)
		else
			opened = true
			Animations:Open(Window, Setup.Transparency)
		end
	end

	for _, button in pairs(Sidebar.Top.Buttons:GetChildren()) do
		if button:IsA("TextButton") then
			Animations:Component(button)
			button.MouseButton1Click:Connect(function()
				if button.Name == "Close" then
					toggleWindow()
				elseif button.Name == "Maximize" then
					maximized = not maximized
					Tween(Window, 0.2, {
						Size = maximized and UDim2.fromScale(1, 1) or Setup.Size,
						Position = maximized and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0.5, 0.5)
					})
				elseif button.Name == "Minimize" then
					opened = false
					Window.Visible = false
				end
			end)
		end
	end

	UserInputService.InputBegan:Connect(function(input, focused)
		if input.KeyCode == Setup.Keybind and not focused then
			toggleWindow()
		end
	end)

	-- Tab Management
	function Options:SetTab(name)
		for _, button in pairs(Tab:GetChildren()) do
			if button:IsA("TextButton") then
				local isSelected = button.Name == name
				local padding = button:FindFirstChildOfClass("UIPadding")
				Tween(padding, 0.2, { PaddingLeft = UDim.new(0, isSelected and 25 or 15) })
				Tween(button, 0.2, { BackgroundTransparency = isSelected and 0.8 or 1, Size = UDim2.new(1, isSelected and -15 or -30, 0, 30) })
				button.Value.Value = isSelected
			end
		end

		for _, main in pairs(Holder:GetChildren()) do
			if main:IsA("CanvasGroup") then
				local isSelected = main.Name == name
				local scroll = main.ScrollingFrame
				if isSelected then
					main.Visible = true
					Tween(main, 0.3, { GroupTransparency = 0 })
					Tween(scroll.UIPadding, 0.3, { PaddingTop = UDim.new(0, 5) })
				else
					Tween(main, 0.2, { GroupTransparency = 1 })
					Tween(scroll.UIPadding, 0.2, { PaddingTop = UDim.new(0, 10) })
					task.delay(0.2, function() main.Visible = false end)
				end
				main.Value.Value = isSelected
			end
		end
	end

	function Options:AddTabSection(Settings)
		local Section = Examples.SectionExample:Clone()
		SetProperty(Section, {
			Parent = Tab,
			Text = Settings.Name,
			Name = Settings.Name,
			LayoutOrder = Settings.Order or 0,
			Visible = true
		})
		StoredInfo.Sections[Settings.Name] = Settings.Order or 0
	end

	function Options:AddTab(Settings)
		if StoredInfo.Tabs[Settings.Title] then
			error("[Ecstays]: Tab with name '" .. Settings.Title .. "' already exists")
		end

		local TabButton = Examples.TabButtonExample:Clone()
		local Main = Examples.MainExample:Clone()

		if Settings.Icon then
			TabButton.ICO.Image = Settings.Icon
		else
			TabButton.ICO:Destroy()
		end

		SetProperty(TabButton.TextLabel, { Text = Settings.Title })
		SetProperty(Main, { Parent = Holder, Name = Settings.Title })
		SetProperty(TabButton, {
			Parent = Tab,
			LayoutOrder = StoredInfo.Sections[Settings.Section] or #StoredInfo.Sections + 1,
			Name = Settings.Title,
			Visible = true
		})

		TabButton.MouseButton1Click:Connect(function()
			Options:SetTab(Settings.Title)
		end)

		StoredInfo.Tabs[Settings.Title] = { TabButton }
		return Main.ScrollingFrame
	end

	function Options:Notify(Settings)
		local Notification = Components.Notification:Clone()
		local Title, Description = Notification.Labels.Title, Notification.Labels.Description
		local Timer = Notification.Timer

		SetProperty(Title, { Text = Settings.Title })
		SetProperty(Description, { Text = Settings.Description })
		SetProperty(Notification, { Parent = Screen.Frame })

		task.spawn(function()
			Animations:Open(Notification, Setup.Transparency, true)
			Tween(Timer, Settings.Duration or 2, { Size = UDim2.new(0, 0, 0, 4) })
			task.wait(Settings.Duration or 2)
			Animations:Close(Notification)
			task.wait(0.3)
			Notification:Destroy()
		end)
	end

	function Options:AddSection(Settings)
		local Section = Components.Section:Clone()
		SetProperty(Section, { Text = Settings.Name, Parent = Settings.Tab, Visible = true })
	end

	function Options:AddButton(Settings)
		local Button = Components.Button:Clone()
		local Title, Description = Button.Labels.Title, Button.Labels.Description

		Animations:Component(Button)
		Button.MouseButton1Click:Connect(Settings.Callback)
		SetProperty(Title, { Text = Settings.Title })
		SetProperty(Description, { Text = Settings.Description })
		SetProperty(Button, { Name = Settings.Title, Parent = Settings.Tab, Visible = true })
	end

	function Options:AddToggle(Settings)
		local Toggle = Components.Toggle:Clone()
		local Title, Description = Toggle.Labels.Title, Toggle.Labels.Description
		local Main = Toggle.Main
		local Circle = Main.Circle
		local Value = Toggle.Value

		local function setState(state)
			Tween(Main, 0.2, { BackgroundColor3 = state and Theme.Interactables or Theme.Component })
			Tween(Circle, 0.2, { BackgroundColor3 = state and Theme.Text or Theme.Primary, Position = UDim2.new(state and 1 or 0, state and -16 or 3, 0.5, 0) })
			Value.Value = state
		end

		Toggle.MouseButton1Click:Connect(function()
			setState(not Value.Value)
			Settings.Callback(Value.Value)
		end)

		Animations:Component(Toggle)
		setState(Settings.Default or false)
		SetProperty(Title, { Text = Settings.Title })
		SetProperty(Description, { Text = Settings.Description })
		SetProperty(Toggle, { Name = Settings.Title, Parent = Settings.Tab, Visible = true })
	end

	function Options:SetTheme(newTheme)
		Theme = newTheme or Theme
		Window.BackgroundColor3 = Theme.Primary
		Holder.BackgroundColor3 = Theme.Secondary
		Window.UIStroke.Color = Theme.Shadow

		for _, descendant in pairs(Screen:GetDescendants()) do
			if descendant:IsA("TextLabel") then
				descendant.TextColor3 = Theme.Text
			elseif descendant:IsA("TextButton") and descendant:FindFirstChild("Labels") then
				descendant.BackgroundColor3 = Theme.Component
			elseif descendant:IsA("UIStroke") then
				descendant.Color = Theme.Outline
			end
		end
	end

	-- Initialize Window
	SetProperty(Window, { Size = Settings.Size or Setup.Size, Visible = true, Parent = Screen })
	Animations:Open(Window, Settings.Transparency or Setup.Transparency)
	Options:SetTheme()

	return Options
end

return Library
