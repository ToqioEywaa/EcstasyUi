-- Ecstays UI Library (Standalone Loadstring Version)
-- Pink-Purple themed, clean, and fully self-contained UI library

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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
local Screen = Instance.new("ScreenGui")
Screen.Name = "Ecstays"
Screen.IgnoreGuiInset = true
Screen.Parent = game.CoreGui or PlayerGui

local Components = Instance.new("Folder", Screen)
Components.Name = "Components"

local Library = {}
local StoredInfo = { Sections = {}, Tabs = {} }

-- Create Base UI Structure
local function CreateBaseUI()
	local Main = Instance.new("CanvasGroup", Screen)
	Main.Name = "Main"
	SetProperty(Main, {
		Size = Setup.Size,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Primary,
		GroupTransparency = Setup.Transparency,
		Visible = false
	})

	local UIStroke = Instance.new("UIStroke", Main)
	SetProperty(UIStroke, {
		Color = Theme.Shadow,
		Thickness = 2,
		Transparency = 0.3
	})

	local Sidebar = Instance.new("Frame", Main)
	Sidebar.Name = "Sidebar"
	SetProperty(Sidebar, {
		Size = UDim2.new(0, 150, 1, 0),
		BackgroundColor3 = Theme.Secondary,
		BorderSizePixel = 0
	})

	local Top = Instance.new("Frame", Sidebar)
	Top.Name = "Top"
	SetProperty(Top, {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Theme.Primary,
		BorderSizePixel = 0
	})

	local Buttons = Instance.new("Frame", Top)
	Buttons.Name = "Buttons"
	SetProperty(Buttons, {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1
	})

	local ButtonLayout = Instance.new("UIListLayout", Buttons)
	SetProperty(ButtonLayout, {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 5)
	})

	local function CreateButton(name)
		local Button = Instance.new("TextButton", Buttons)
		SetProperty(Button, {
			Name = name,
			Size = UDim2.new(0, 30, 0, 30),
			BackgroundColor3 = Theme.Component,
			Text = name == "Close" and "X" or name == "Maximize" and "□" or "−",
			TextColor3 = Theme.Text,
			Font = Enum.Font.Gotham,
			TextSize = 14
		})
		local Corner = Instance.new("UICorner", Button)
		Corner.CornerRadius = UDim.new(0, 4)
		return Button
	end

	CreateButton("Close")
	CreateButton("Maximize")
	CreateButton("Minimize")

	local Tab = Instance.new("Frame", Sidebar)
	Tab.Name = "Tab"
	SetProperty(Tab, {
		Position = UDim2.new(0, 0, 0, 50),
		Size = UDim2.new(1, 0, 1, -50),
		BackgroundTransparency = 1
	})

	local TabLayout = Instance.new("UIListLayout", Tab)
	SetProperty(TabLayout, {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5)
	})

	local Holder = Instance.new("Frame", Main)
	Holder.Name = "Main"
	SetProperty(Holder, {
		Position = UDim2.new(0, 150, 0, 0),
		Size = UDim2.new(1, -150, 1, 0),
		BackgroundColor3 = Theme.Secondary,
		BorderSizePixel = 0
	})

	local BG = Instance.new("Frame", Main)
	BG.Name = "BackgroundShadow"
	SetProperty(BG, {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1
	})

	return Main, Sidebar, Holder, Tab, BG
end

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

-- Component Templates
local function CreateComponentTemplates()
	local Button = Instance.new("TextButton", Components)
	Button.Name = "Button"
	SetProperty(Button, {
		Size = UDim2.new(1, -10, 0, 50),
		BackgroundColor3 = Theme.Component,
		Text = "",
		Visible = false
	})
	local ButtonCorner = Instance.new("UICorner", Button)
	ButtonCorner.CornerRadius = UDim.new(0, 6)
	local Labels = Instance.new("Frame", Button)
	Labels.Name = "Labels"
	SetProperty(Labels, {
		Size = UDim2.new(1, -10, 1, -10),
		Position = UDim2.new(0, 5, 0, 5),
		BackgroundTransparency = 1
	})
	local Title = Instance.new("TextLabel", Labels)
	Title.Name = "Title"
	SetProperty(Title, {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		TextColor3 = Theme.Title,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	local Description = Instance.new("TextLabel", Labels)
	Description.Name = "Description"
	SetProperty(Description, {
		Position = UDim2.new(0, 0, 0, 20),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	local Toggle = Button:Clone()
	Toggle.Name = "Toggle"
	local Main = Instance.new("Frame", Toggle)
	Main.Name = "Main"
	SetProperty(Main, {
		Size = UDim2.new(0, 40, 0, 20),
		Position = UDim2.new(1, -50, 0.5, -10),
		BackgroundColor3 = Theme.Component,
		AnchorPoint = Vector2.new(1, 0.5)
	})
	local MainCorner = Instance.new("UICorner", Main)
	MainCorner.CornerRadius = UDim.new(0, 10)
	local Circle = Instance.new("Frame", Main)
	Circle.Name = "Circle"
	SetProperty(Circle, {
		Size = UDim2.new(0, 14, 0, 14),
		Position = UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Primary
	})
	local CircleCorner = Instance.new("UICorner", Circle)
	CircleCorner.CornerRadius = UDim.new(0, 7)
	local Value = Instance.new("BoolValue", Toggle)
	Value.Name = "Value"

	local Slider = Button:Clone()
	Slider.Name = "Slider"
	local SliderMain = Instance.new("Frame", Slider)
	SliderMain.Name = "Slider"
	SetProperty(SliderMain, {
		Size = UDim2.new(1, -10, 0, 20),
		Position = UDim2.new(0, 5, 1, -25),
		BackgroundTransparency = 1
	})
	local Slide = Instance.new("Frame", SliderMain)
	Slide.Name = "Slide"
	SetProperty(Slide, {
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = Theme.Component
	})
	local SlideCorner = Instance.new("UICorner", Slide)
	SlideCorner.CornerRadius = UDim.new(0, 2)
	local Highlight = Instance.new("Frame", Slide)
	Highlight.Name = "Highlight"
	SetProperty(Highlight, {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.Interactables
	})
	local HighlightCorner = Instance.new("UICorner", Highlight)
	HighlightCorner.CornerRadius = UDim.new(0, 2)
	local Circle = Instance.new("Frame", Highlight)
	Circle.Name = "Circle"
	SetProperty(Circle, {
		Size = UDim2.new(0, 10, 0, 10),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Theme.Text
	})
	local CircleCorner = Instance.new("UICorner", Circle)
	CircleCorner.CornerRadius = UDim.new(0, 5)
	local Fire = Instance.new("TextButton", Slide)
	Fire.Name = "Fire"
	SetProperty(Fire, {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = ""
	})
	local Input = Instance.new("TextBox", SliderMain)
	Input.Name = "Input"
	SetProperty(Input, {
		Size = UDim2.new(0, 50, 0, 20),
		Position = UDim2.new(1, -60, 0, -20),
		BackgroundColor3 = Theme.Component,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		Text = "0"
	})
	local InputCorner = Instance.new("UICorner", Input)
	InputCorner.CornerRadius = UDim.new(0, 4)

	local Notification = Instance.new("CanvasGroup", Components)
	Notification.Name = "Notification"
	SetProperty(Notification, {
		Size = UDim2.new(0, 300, 0, 100),
		Position = UDim2.new(1, -310, 1, -110),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = Theme.Primary,
		GroupTransparency = 1,
		Visible = false
	})
	local NotifStroke = Instance.new("UIStroke", Notification)
	NotifStroke.Color = Theme.Outline
	local NotifLabels = Instance.new("Frame", Notification)
	NotifLabels.Name = "Labels"
	SetProperty(NotifLabels, {
		Size = UDim2.new(1, -10, 1, -14),
		Position = UDim2.new(0, 5, 0, 5),
		BackgroundTransparency = 1
	})
	local NotifTitle = Instance.new("TextLabel", NotifLabels)
	NotifTitle.Name = "Title"
	SetProperty(NotifTitle, {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		TextColor3 = Theme.Title,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	local NotifDesc = Instance.new("TextLabel", NotifLabels)
	NotifDesc.Name = "Description"
	SetProperty(NotifDesc, {
		Position = UDim2.new(0, 0, 0, 20),
		Size = UDim2.new(1, 0, 1, -20),
		BackgroundTransparency = 1,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top
	})
	local Timer = Instance.new("Frame", Notification)
	Timer.Name = "Timer"
	SetProperty(Timer, {
		Size = UDim2.new(1, 0, 0, 4),
		Position = UDim2.new(0, 0, 1, -4),
		BackgroundColor3 = Theme.Interactables
	})

	local Section = Instance.new("TextLabel", Components)
	Section.Name = "Section"
	SetProperty(Section, {
		Size = UDim2.new(1, -10, 0, 30),
		BackgroundTransparency = 1,
		TextColor3 = Theme.Title,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = false
	})

	local TabButtonExample = Instance.new("TextButton", Components)
	TabButtonExample.Name = "TabButtonExample"
	SetProperty(TabButtonExample, {
		Size = UDim2.new(1, -10, 0, 30),
		BackgroundColor3 = Theme.Component,
		Text = "",
		Visible = false
	})
	local TabButtonCorner = Instance.new("UICorner", TabButtonExample)
	TabButtonCorner.CornerRadius = UDim.new(0, 4)
	local TabText = Instance.new("TextLabel", TabButtonExample)
	TabText.Name = "TextLabel"
	SetProperty(TabText, {
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 40, 0, 0),
		BackgroundTransparency = 1,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	local ICO = Instance.new("ImageLabel", TabButtonExample)
	ICO.Name = "ICO"
	SetProperty(ICO, {
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		ImageColor3 = Theme.Icon
	})
	local TabPadding = Instance.new("UIPadding", TabButtonExample)
	TabPadding.PaddingLeft = UDim.new(0, 15)
	local TabValue = Instance.new("BoolValue", TabButtonExample)
	TabValue.Name = "Value"

	local MainExample = Instance.new("CanvasGroup", Components)
	MainExample.Name = "MainExample"
	SetProperty(MainExample, {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.Secondary,
		Visible = false
	})
	local ScrollingFrame = Instance.new("ScrollingFrame", MainExample)
	ScrollingFrame.Name = "ScrollingFrame"
	SetProperty(ScrollingFrame, {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Component,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y
	})
	local ScrollLayout = Instance.new("UIListLayout", ScrollingFrame)
	ScrollLayout.Padding = UDim.new(0, 5)
	local ScrollPadding = Instance.new("UIPadding", ScrollingFrame)
	ScrollPadding.PaddingTop = UDim.new(0, 5)
	local MainValue = Instance.new("BoolValue", MainExample)
	MainValue.Name = "Value"
end

CreateComponentTemplates()

-- Library Functions
function Library:CreateWindow(Settings)
	local Window, Sidebar, Holder, Tab, BG = CreateBaseUI()
	local Options = {}
	local Examples = {
		SectionExample = Components.Section,
		TabButtonExample = Components.TabButtonExample,
		MainExample = Components.MainExample
	}
	local opened = true
	local maximized = false

	Drag(Window)
	Setup.Transparency = Settings.Transparency or Setup.Transparency
	Setup.Size = Settings.Size or Setup.Size
	Setup.Keybind = Settings.MinimizeKeybind or Setup.Keybind

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
		local Section = Components.Section:Clone()
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

		local TabButton = Components.TabButtonExample:Clone()
		local Main = Components.MainExample:Clone()

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
		SetProperty(Notification, { Parent = Screen })

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

	function Options:AddSlider(Settings)
		local Slider = Components.Slider:Clone()
		local Title, Description = Slider.Labels.Title, Slider.Labels.Description
		local Main = Slider.Slider
		local Amount = Main.Input
		local Slide = Main.Slide
		local Fire = Slide.Fire
		local Fill = Slide.Highlight
		local Circle = Fill.Circle

		local Active = false
		local Value = 0

		local function SetNumber(Number)
			if Settings.AllowDecimals then
				local Power = 10 ^ (Settings.DecimalAmount or 2)
				Number = math.floor(Number * Power + 0.5) / Power
			else
				Number = math.round(Number)
			end
			return Number
		end

		local function Update(Number)
			local Scale = (Mouse.X - Slide.AbsolutePosition.X) / Slide.AbsoluteSize.X
			Scale = math.clamp(Scale, 0, 1)

			if Number then
				Number = math.clamp(Number, 0, Settings.MaxValue)
			end

			Value = SetNumber(Number or (Scale * Settings.MaxValue))
			Amount.Text = tostring(Value)
			Fill.Size = UDim2.fromScale((Number and Number / Settings.MaxValue) or Scale, 1)
			Settings.Callback(Value)
		end

		local function Activate()
			Active = true
			while Active do
				Update()
				task.wait()
			end
		end

		Amount.FocusLost:Connect(function()
			Update(tonumber(Amount.Text) or 0)
		end)

		Fire.MouseButton1Down:Connect(Activate)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				Active = false
			end
		end)

		Fill.Size = UDim2.fromScale(Value, 1)
		Animations:Component(Slider)
		SetProperty(Title, { Text = Settings.Title })
		SetProperty(Description, { Text = Settings.Description })
		SetProperty(Slider, { Name = Settings.Title, Parent = Settings.Tab, Visible = true })
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
			elseif descendant:IsA("ImageLabel") then
				descendant.ImageColor3 = Theme.Icon
			end
		end
	end

	SetProperty(Window, { Size = Settings.Size or Setup.Size, Visible = true, Parent = Screen })
	Animations:Open(Window, Settings.Transparency or Setup.Transparency)
	Options:SetTheme()

	return Options
end

return Library
