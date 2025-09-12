--[[
	Ecstays UI Library
	Clean glassy dark theme with pink–lilac accent
	Made by Late • Restyled by Ecstays
]]

--// Connections
local GetService = game.GetService
local Connect = game.Loaded.Connect
local Wait = game.Loaded.Wait
local Clone = game.Clone
local Destroy = game.Destroy

if (not game:IsLoaded()) then
	local Loaded = game.Loaded
	Loaded.Wait(Loaded);
end

--// Important
local Setup = {
	Keybind = Enum.KeyCode.LeftControl,
	Transparency = 0.08,  -- etwas klarer / cleaner
	ThemeMode = "Dark",
	Size = nil,
}

--// Ecstays Theme (Dark)
--  Primärflächen sind etwas dunkler und neutraler,
--  Akzent ist pink-lila (magenta-lavender) und wird für aktive/hover Zustände genutzt.
local Theme = {
	-- Frames
	Primary       = Color3.fromRGB(18, 16, 22),   -- Fensterhintergrund
	Secondary     = Color3.fromRGB(24, 22, 30),   -- Hauptbereich
	Component     = Color3.fromRGB(30, 27, 38),   -- Karten/Controls
	Interactables = Color3.fromRGB(38, 34, 48),   -- Buttons/Inputs

	-- Text
	Tab         = Color3.fromRGB(210, 206, 218),
	Title       = Color3.fromRGB(242, 238, 248),
	Description = Color3.fromRGB(190, 186, 198),

	-- Outlines/Shadows
	Shadow  = Color3.fromRGB(0, 0, 0),
	Outline = Color3.fromRGB(72, 58, 92),         -- dezentes Lavender-Outline

	-- Icons & Accent
	Icon   = Color3.fromRGB(235, 220, 245),
	Accent = Color3.fromRGB(206, 99, 255),        -- Ecstays Akzent (pink-lila)
}

--// Services & Functions
local Type, Blur = nil
local LocalPlayer = GetService(game, "Players").LocalPlayer;
local Services = {
	Insert = GetService(game, "InsertService");
	Tween  = GetService(game, "TweenService");
	Run    = GetService(game, "RunService");
	Input  = GetService(game, "UserInputService");
}

local Player = {
	Mouse = LocalPlayer:GetMouse();
	GUI   = LocalPlayer.PlayerGui;
}

local Tween = function(Object : Instance, Speed : number, Properties : {}, Info : { EasingStyle: Enum?, EasingDirection: Enum? })
	local Style, Direction
	if Info then
		Style, Direction = Info["EasingStyle"], Info["EasingDirection"]
	else
		Style, Direction = Enum.EasingStyle.Sine, Enum.EasingDirection.Out
	end
	return Services.Tween:Create(Object, TweenInfo.new(Speed, Style, Direction), Properties):Play()
end

local SetProperty = function(Object: Instance, Properties: {})
	for Index, Property in next, Properties do
		Object[Index] = (Property);
	end
	return Object
end

local Multiply = function(Value, Amount)
	local New = {
		Value.X.Scale * Amount;
		Value.X.Offset * Amount;
		Value.Y.Scale * Amount;
		Value.Y.Offset * Amount;
	}
	return UDim2.new(unpack(New))
end

local Color = function(Color3Value, Factor, Mode)
	Mode = Mode or Setup.ThemeMode
	local r,g,b = Color3Value.R * 255, Color3Value.G * 255, Color3Value.B * 255
	if Mode == "Light" then
		return Color3.fromRGB(math.clamp(r - Factor,0,255), math.clamp(g - Factor,0,255), math.clamp(b - Factor,0,255))
	else
		return Color3.fromRGB(math.clamp(r + Factor,0,255), math.clamp(g + Factor,0,255), math.clamp(b + Factor,0,255))
	end
end

local Drag = function(Canvas)
	if Canvas then
		local Dragging; local DragInput; local Start; local StartPosition;
		local function Update(input)
			local delta = input.Position - Start
			Canvas.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + delta.Y)
		end
		Connect(Canvas.InputBegan, function(Input)
			if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and not Type then
				Dragging = true
				Start = Input.Position
				StartPosition = Canvas.Position
				Connect(Input.Changed, function()
					if Input.UserInputState == Enum.UserInputState.End then
						Dragging = false
					end
				end)
			end
		end)
		Connect(Canvas.InputChanged, function(Input)
			if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) and not Type then
				DragInput = Input
			end
		end)
		Connect(Services.Input.InputChanged, function(Input)
			if Input == DragInput and Dragging and not Type then
				Update(Input)
			end
		end)
	end
end

Resizing = {
	TopLeft     = { X = Vector2.new(-1, 0), Y = Vector2.new(0, -1)};
	TopRight    = { X = Vector2.new( 1, 0), Y = Vector2.new(0, -1)};
	BottomLeft  = { X = Vector2.new(-1, 0), Y = Vector2.new(0,  1)};
	BottomRight = { X = Vector2.new( 1, 0), Y = Vector2.new(0,  1)};
}

Resizeable = function(Tab, Minimum, Maximum)
	task.spawn(function()
		local MousePos, Size, UIPos = nil, nil, nil
		if Tab and Tab:FindFirstChild("Resize") then
			local Positions = Tab:FindFirstChild("Resize")
			for _, Types in next, Positions:GetChildren() do
				Connect(Types.InputBegan, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Type = Types
						MousePos = Vector2.new(Player.Mouse.X, Player.Mouse.Y)
						Size = Tab.AbsoluteSize
						UIPos = Tab.Position
					end
				end)
				Connect(Types.InputEnded, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Type = nil
					end
				end)
			end
		end
		local Resize = function(Delta)
			if Type and MousePos and Size and UIPos and Tab:FindFirstChild("Resize")[Type.Name] == Type then
				local Mode = Resizing[Type.Name]
				local NewSize = Vector2.new(Size.X + Delta.X * Mode.X.X, Size.Y + Delta.Y * Mode.Y.Y)
				NewSize = Vector2.new(math.clamp(NewSize.X, Minimum.X, Maximum.X), math.clamp(NewSize.Y, Minimum.Y, Maximum.Y))
				local AnchorOffset = Vector2.new(Tab.AnchorPoint.X * Size.X, Tab.AnchorPoint.Y * Size.Y)
				local NewAnchorOffset = Vector2.new(Tab.AnchorPoint.X * NewSize.X, Tab.AnchorPoint.Y * NewSize.Y)
				local DeltaAnchorOffset = NewAnchorOffset - AnchorOffset
				Tab.Size = UDim2.new(0, NewSize.X, 0, NewSize.Y)
				local NewPosition = UDim2.new(
					UIPos.X.Scale,
					UIPos.X.Offset + DeltaAnchorOffset.X * Mode.X.X,
					UIPos.Y.Scale,
					UIPos.Y.Offset + DeltaAnchorOffset.Y * Mode.Y.Y
				)
				Tab.Position = NewPosition
			end
		end
		Connect(Player.Mouse.Move, function()
			if Type then
				Resize(Vector2.new(Player.Mouse.X, Player.Mouse.Y) - MousePos)
			end
		end)
	end)
end

--// Setup [UI]
if (identifyexecutor) then
	Screen = Services.Insert:LoadLocalAsset("rbxassetid://18490507748");
	Blur   = loadstring(game:HttpGet("https://raw.githubusercontent.com/lxte/lates-lib/main/Assets/Blur.lua"))();
else
	Screen = (script.Parent);
	Blur   = require(script.Blur)
end

Screen.Main.Visible = false

xpcall(function()
	Screen.Parent = game.CoreGui
end, function()
	Screen.Parent = Player.GUI
end)

--// Tables for Data
local Animations = {}
local Blurs = {}
local Components = (Screen:FindFirstChild("Components"));
local Library = {};
local StoredInfo = {
	["Sections"] = {};
	["Tabs"] = {}
};

--// Animations [Window]
function Animations:Open(Window: CanvasGroup, Transparency: number, UseCurrentSize: boolean)
	local Original = (UseCurrentSize and Window.Size) or Setup.Size
	local Multiplied = Multiply(Original, 1.06) -- etwas subtiler
	local Shadow = Window:FindFirstChildOfClass("UIStroke")

	SetProperty(Shadow, { Transparency = 1, Color = Theme.Outline, Thickness = 1 })
	SetProperty(Window, {
		Size = Multiplied,
		GroupTransparency = 1,
		Visible = true,
	})

	Tween(Shadow, .22, { Transparency = 0.4 })
	Tween(Window, .22, {
		Size = Original,
		GroupTransparency = Transparency or 0,
	})
end

function Animations:Close(Window: CanvasGroup)
	local Original = Window.Size
	local Multiplied = Multiply(Original, 1.06)
	local Shadow = Window:FindFirstChildOfClass("UIStroke")

	SetProperty(Window, { Size = Original })
	Tween(Shadow, .18, { Transparency = 1 })
	Tween(Window, .18, {
		Size = Multiplied,
		GroupTransparency = 1,
	})
	task.wait(.18)
	Window.Size = Original
	Window.Visible = false
end

function Animations:Component(Component: any, Custom: boolean)
	Connect(Component.InputBegan, function()
		if Custom then
			Tween(Component, .16, { Transparency = .88 });
		else
			-- Hover bekommt Akzent-Tint
			Tween(Component, .16, { BackgroundColor3 = Color(Theme.Component, 4, Setup.ThemeMode) });
			if Component:FindFirstChild("UIStroke") then
				Tween(Component.UIStroke, .16, { Color = Theme.Accent, Transparency = 0.4 })
			end
		end
	end)
	Connect(Component.InputEnded, function()
		if Custom then
			Tween(Component, .16, { Transparency = 1 });
		else
			Tween(Component, .16, { BackgroundColor3 = Theme.Component });
			if Component:FindFirstChild("UIStroke") then
				Tween(Component.UIStroke, .16, { Color = Theme.Outline, Transparency = 0.6 })
			end
		end
	end)
end

--// Library [Window]
function Library:CreateWindow(Settings: { Title: string, Size: UDim2, Transparency: number, MinimizeKeybind: Enum.KeyCode?, Blurring: boolean, Theme: string })
	local Window  = Clone(Screen:WaitForChild("Main"));
	local Sidebar = Window:FindFirstChild("Sidebar");
	local Holder  = Window:FindFirstChild("Main");
	local BG      = Window:FindFirstChild("BackgroundShadow");
	local Tab     = Sidebar:FindFirstChild("Tab");

	local Options = {};
	local Examples = {};
	local Opened = true;
	local Maximized = false;
	local BlurEnabled = false

	for _, Example in next, Window:GetDescendants() do
		if Example.Name:find("Example") and not Examples[Example.Name] then
			Examples[Example.Name] = Example
		end
	end

	-- UI Blur & More
	Drag(Window);
	Resizeable(Window, Vector2.new(411, 271), Vector2.new(9e9, 9e9));
	Setup.Transparency = Settings.Transparency or 0
	Setup.Size = Settings.Size
	Setup.ThemeMode = Settings.Theme or "Dark"

	if Settings.Blurring then
		Blurs[Settings.Title] = Blur.new(Window, 6)
		BlurEnabled = true
	end

	if Settings.MinimizeKeybind then
		Setup.Keybind = Settings.MinimizeKeybind
	end

	-- Branding: Ecstays Titel rechts oben (falls vorhanden)
	if Sidebar:FindFirstChild("Top") and Sidebar.Top:FindFirstChild("Title") then
		Sidebar.Top.Title.Text = (Settings.Title and (Settings.Title .. " • Ecstays")) or "Ecstays"
	end

	-- Animate
	local Close = function()
		if Opened then
			if BlurEnabled then
				Blurs[Settings.Title].root.Parent = nil
			end
			Opened = false
			Animations:Close(Window)
			Window.Visible = false
		else
			Animations:Open(Window, Setup.Transparency)
			Opened = true
			if BlurEnabled then
				Blurs[Settings.Title].root.Parent = workspace.CurrentCamera
			end
		end
	end

	for _, Button in next, Sidebar.Top.Buttons:GetChildren() do
		if Button:IsA("TextButton") then
			local Name = Button.Name
			Animations:Component(Button, true)
			Connect(Button.MouseButton1Click, function()
				if Name == "Close" then
					Close()
				elseif Name == "Maximize" then
					if Maximized then
						Maximized = false
						Tween(Window, .15, { Size = Setup.Size, Position = UDim2.fromScale(.5, .5) });
					else
						Maximized = true
						Tween(Window, .15, { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(.5, .5) });
					end
				elseif Name == "Minimize" then
					Opened = false
					Window.Visible = false
					if BlurEnabled and Blurs[Settings.Title] then
						Blurs[Settings.Title].root.Parent = nil
					end
				end
			end)
		end
	end

	Services.Input.InputBegan:Connect(function(Input, Focused)
		if (Input == Setup.Keybind or Input.KeyCode == Setup.Keybind) and not Focused then
			Close()
		end
	end)

	-- Tabs
	function Options:SetTab(Name: string)
		for _, Button in next, Tab:GetChildren() do
			if Button:IsA("TextButton") then
				local Opened, SameName = Button.Value, (Button.Name == Name);
				local Padding = Button:FindFirstChildOfClass("UIPadding");
				if SameName and not Opened.Value then
					Tween(Padding, .18, { PaddingLeft = UDim.new(0, 26) });
					Tween(Button, .18, { BackgroundTransparency = 0.85, Size = UDim2.new(1, -15, 0, 30) });
					if Button:FindFirstChild("UIStroke") then
						Tween(Button.UIStroke, .18, { Color = Theme.Accent, Transparency = 0.35 })
					end
					SetProperty(Opened, { Value = true });
				elseif not SameName and Opened.Value then
					Tween(Padding, .18, { PaddingLeft = UDim.new(0, 20) });
					Tween(Button, .18, { BackgroundTransparency = 1, Size = UDim2.new(1, -44, 0, 30) });
					if Button:FindFirstChild("UIStroke") then
						Tween(Button.UIStroke, .18, { Color = Theme.Outline, Transparency = 0.65 })
					end
					SetProperty(Opened, { Value = false });
				end
			end
		end
		for _, Main in next, Holder:GetChildren() do
			if Main:IsA("CanvasGroup") then
				local Opened, SameName = Main.Value, (Main.Name == Name);
				local Scroll = Main:FindFirstChild("ScrollingFrame");
				if SameName and not Opened.Value then
					Opened.Value = true
					Main.Visible = true
					Tween(Main, .22, { GroupTransparency = 0 });
					Tween(Scroll["UIPadding"], .22, { PaddingTop = UDim.new(0, 5) });
				elseif not SameName and Opened.Value then
					Opened.Value = false
					Tween(Main, .14, { GroupTransparency = 1 });
					Tween(Scroll["UIPadding"], .14, { PaddingTop = UDim.new(0, 15) });
					task.delay(.15, function() Main.Visible = false end)
				end
			end
		end
	end

	function Options:AddTabSection(Settings: { Name: string, Order: number })
		local Example = Examples["SectionExample"];
		local Section = Clone(Example);
		StoredInfo["Sections"][Settings.Name] = (Settings.Order);
		SetProperty(Section, {
			Parent = Example.Parent,
			Text = Settings.Name,
			Name = Settings.Name,
			LayoutOrder = Settings.Order,
			Visible = true
		});
	end

	function Options:AddTab(Settings: { Title: string, Icon: string, Section: string? })
		if StoredInfo["Tabs"][Settings.Title] then
			error("[Ecstays UI]: A tab with the same name has already been created")
		end
		local Example, MainExample = Examples["TabButtonExample"], Examples["MainExample"];
		local Section = StoredInfo["Sections"][Settings.Section];
		local Main = Clone(MainExample);
		local TabBtn = Clone(Example);

		if not Settings.Icon then
			if TabBtn:FindFirstChild("ICO") then Destroy(TabBtn["ICO"]); end
		else
			if TabBtn:FindFirstChild("ICO") then SetProperty(TabBtn["ICO"], { Image = Settings.Icon }); end
		end

		StoredInfo["Tabs"][Settings.Title] = { TabBtn }
		SetProperty(TabBtn["TextLabel"], { Text = Settings.Title });

		SetProperty(Main, {
			Parent = MainExample.Parent,
			Name = Settings.Title;
		})

		SetProperty(TabBtn, {
			Parent = Example.Parent,
			LayoutOrder = Section or #StoredInfo["Sections"] + 1,
			Name = Settings.Title;
			Visible = true;
		})

		-- dünne Accent Linie links bei Hover/Aktiv (falls vorhanden)
		if TabBtn:FindFirstChild("Underline") then
			TabBtn.Underline.BackgroundColor3 = Theme.Accent
		end

		TabBtn.MouseButton1Click:Connect(function()
			Options:SetTab(TabBtn.Name);
		end)

		return Main.ScrollingFrame
	end

	-- Notifications
	function Options:Notify(Settings: { Title: string, Description: string, Duration: number })
		local Notification = Clone(Components["Notification"]);
		local Title, Description = Options:GetLabels(Notification);
		local Timer = Notification["Timer"];

		SetProperty(Title, { Text = Settings.Title });
		SetProperty(Description, { Text = Settings.Description });
		SetProperty(Notification, {
			Parent = Screen["Frame"],
		})

		-- Accent Leiste
		if Timer then
			Timer.BackgroundColor3 = Theme.Accent
		end

		task.spawn(function()
			local Duration = Settings.Duration or 2
			local Wait = task.wait;
			Animations:Open(Notification, Setup.Transparency, true);
			Tween(Timer, Duration, { Size = UDim2.new(0, 0, 0, 4) });
			Wait(Duration);
			Animations:Close(Notification);
			Wait(0.8);
			Notification:Destroy();
		end)
	end

	-- Components
	function Options:GetLabels(Component)
		local Labels = Component:FindFirstChild("Labels")
		return Labels.Title, Labels.Description
	end

	function Options:AddSection(Settings: { Name: string, Tab: Instance })
		local Section = Clone(Components["Section"]);
		SetProperty(Section, {
			Text = Settings.Name,
			Parent = Settings.Tab,
			Visible = true,
		})
	end

	function Options:AddButton(Settings: { Title: string, Description: string, Tab: Instance, Callback: any })
		local Button = Clone(Components["Button"]);
		local Title, Description = Options:GetLabels(Button);
		Connect(Button.MouseButton1Click, Settings.Callback)
		Animations:Component(Button)
		SetProperty(Title, { Text = Settings.Title });
		SetProperty(Description, { Text = Settings.Description });
		SetProperty(Button, {
			Name = Settings.Title,
			Parent = Settings.Tab,
			Visible = true,
		})
	end

	function Options:AddInput(Settings: { Title: string, Description: string, Tab: Instance, Callback: any })
		local Input = Clone(Components["Input"]);
		local Title, Description = Options:GetLabels(Input);
		local TextBox = Input["Main"]["Input"];
		Connect(Input.MouseButton1Click, function() TextBox:CaptureFocus() end)
		Connect(TextBox.FocusLost, function() Settings.Callback(TextBox.Text) end)
		Animations:Component(Input)
		SetProperty(Title, { Text = Settings.Title });
		SetProperty(Description, { Text = Settings.Description });
		SetProperty(Input, {
			Name = Settings.Title,
			Parent = Settings.Tab,
			Visible = true,
		})
	end

	function Options:AddToggle(Settings: { Title: string, Description: string, Default: boolean, Tab: Instance, Callback: any })
		local Toggle = Clone(Components["Toggle"]);
		local Title, Description = Options:GetLabels(Toggle);
		local On = Toggle["Value"];
		local Main = Toggle["Main"];
		local Circle = Main["Circle"];

		-- Ecstays Toggle: ON nutzt Accent, OFF neutrales Dark
		local Set = function(Value)
			if Value then
				Tween(Main,   .16, { BackgroundColor3 = Theme.Accent });
				Tween(Circle, .16, { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.new(1, -16, 0.5, 0) });
			else
				Tween(Main,   .16, { BackgroundColor3 = Theme.Interactables });
				Tween(Circle, .16, { BackgroundColor3 = Theme.Primary, Position = UDim2.new(0, 3, 0.5, 0) });
			end
			On.Value = Value
		end

		Connect(Toggle.MouseButton1Click, function()
			local Value = not On.Value
			Set(Value)
			Settings.Callback(Value)
		end)

		Animations:Component(Toggle);
		Set(Settings.Default);
		SetProperty(Title, { Text = Settings.Title });
		SetProperty(Description, { Text = Settings.Description });
		SetProperty(Toggle, {
			Name = Settings.Title,
			Parent = Settings.Tab,
			Visible = true,
		})
	end

	function Options:AddKeybind(Settings: { Title: string, Description: string, Tab: Instance, Callback: any })
		local Dropdown = Clone(Components["Keybind"]);
		local Title, Description = Options:GetLabels(Dropdown);
		local Bind = Dropdown["Main"].Options;

		local Mouse = { Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3 };
		local Types = { ["Mouse"] = "Enum.UserInputType.MouseButton", ["Key"] = "Enum.KeyCode." }

		Connect(Dropdown.MouseButton1Click, function()
			local Detect, Finished
			SetProperty(Bind, { Text = "..." });
			Detect = Connect(game.UserInputService.InputBegan, function(Key, Focused)
				local InputType = (Key.UserInputType);
				if not Finished and not Focused then
					Finished = true
					if table.find(Mouse, InputType) then
						Settings.Callback(Key);
						SetProperty(Bind, { Text = tostring(InputType):gsub(Types.Mouse, "MB") })
					elseif InputType == Enum.UserInputType.Keyboard then
						Settings.Callback(Key);
						SetProperty(Bind, { Text = tostring(Key.KeyCode):gsub(Types.Key, "") })
					end
				end
			end)
		end)

		Animations:Component(Dropdown);
		SetProperty(Title, { Text = Settings.Title });
		SetProperty(Description, { Text = Settings.Description });
		SetProperty(Dropdown, {
			Name = Settings.Title,
			Parent = Settings.Tab,
			Visible = true,
		})
	end

	function Options:AddDropdown(Settings: { Title: string, Description: string, Options: {}, Tab: Instance, Callback: any })
		local Dropdown = Clone(Components["Dropdown"]);
		local Title, Description = Options:GetLabels(Dropdown);
		local Text = Dropdown["Main"].Options;

		Connect(Dropdown.MouseButton1Click, function()
			local Example = Clone(Examples["DropdownExample"]);
			local Buttons = Example["Top"]["Buttons"];
			Tween(BG, .18, { BackgroundTransparency = 0.55 });
			SetProperty(Example, { Parent = Window });
			Animations:Open(Example, 0, true)

			for _, Button in next, Buttons:GetChildren() do
				if Button:IsA("TextButton") then
					Animations:Component(Button, true)
					Connect(Button.MouseButton1Click, function()
						Tween(BG, .18, { BackgroundTransparency = 1 });
						Animations:Close(Example);
						task.wait(0.6)
						Destroy(Example);
					end)
				end
			end

			for Index, Option in next, Settings.Options do
				local Button = Clone(Examples["DropdownButtonExample"]);
				local LTitle, LDesc = Options:GetLabels(Button);
				local Selected = Button["Value"];
				Animations:Component(Button);
				SetProperty(LTitle, { Text = Index });
				SetProperty(Button, { Parent = Example.ScrollingFrame, Visible = true });
				Destroy(LDesc)

				Connect(Button.MouseButton1Click, function()
					local NewValue = not Selected.Value
					if NewValue then
						Tween(Button, .16, { BackgroundColor3 = Theme.Interactables });
						Settings.Callback(Option)
						Text.Text = Index
						for _, Others in next, Example:GetChildren() do
							if Others:IsA("TextButton") and Others ~= Button then
								Others.BackgroundColor3 = Theme.Component
							end
						end
					else
						Tween(Button, .16, { BackgroundColor3 = Theme.Component });
					end
					Selected.Value = NewValue
					Tween(BG, .18, { BackgroundTransparency = 1 });
					Animations:Close(Example);
					task.wait(0.6)
					Destroy(Example);
				end)
			end
		end)

		Animations:Component(Dropdown);
		SetProperty(Title, { Text = Settings.Title });
		SetProperty(Description, { Text = Settings.Description });
		SetProperty(Dropdown, {
			Name = Settings.Title,
			Parent = Settings.Tab,
			Visible = true,
		})
	end

	function Options:AddSlider(Settings: { Title: string, Description: string, MaxValue: number, AllowDecimals: boolean, DecimalAmount: number, Tab: Instance, Callback: any })
		local Slider = Clone(Components["Slider"]);
		local Title, Description = Options:GetLabels(Slider);

		local Main = Slider["Slider"];
		local Amount = Main["Main"].Input;
		local Slide = Main["Slide"];
		local Fire = Slide["Fire"];
		local Fill = Slide["Highlight"];
		local Circle = Fill["Circle"];

		local Active = false
		local Value = 0

		-- Ecstays: Fill & Circle nutzen Accent
		if Fill then Fill.BackgroundColor3 = Theme.Accent end
		if Circle then Circle.UIStroke.Color = Theme.Outline end

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
			local Scale = (Player.Mouse.X - Slide.AbsolutePosition.X) / Slide.AbsoluteSize.X
			Scale = (Scale > 1 and 1) or (Scale < 0 and 0) or Scale
			if Number then
				Number = (Number > Settings.MaxValue and Settings.MaxValue) or (Number < 0 and 0) or Number
			end
			Value = SetNumber(Number or (Scale * Settings.MaxValue))
			Amount.Text = Value
			Fill.Size = UDim2.fromScale((Number and Number / Settings.MaxValue) or Scale, 1)
			Settings.Callback(Value)
		end

		local function Activate()
			Active = true
			repeat task.wait()
				Update()
			until not Active
		end

		Connect(Amount.FocusLost, function() Update(tonumber(Amount.Text) or 0) end)
		Connect(Fire.MouseButton1Down, Activate)
		Connect(Services.Input.InputEnded, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Active = false
			end
		end)

		Fill.Size = UDim2.fromScale(Value, 1);
		Animations:Component(Slider);
		SetProperty(Title, { Text = Settings.Title });
		SetProperty(Description, { Text = Settings.Description });
		SetProperty(Slider, {
			Name = Settings.Title,
			Parent = Settings.Tab,
			Visible = true,
		})
	end

	function Options:AddParagraph(Settings: { Title: string, Description: string, Tab: Instance })
		local Paragraph = Clone(Components["Paragraph"]);
		local Title, Description = Options:GetLabels(Paragraph);
		SetProperty(Title, { Text = Settings.Title });
		SetProperty(Description, { Text = Settings.Description });
		SetProperty(Paragraph, {
			Parent = Settings.Tab,
			Visible = true,
		})
	end

	-- Theming rules
	local Themes = {
		Names = {
			["Paragraph"] = function(Label)
				if Label:IsA("TextButton") then
					Label.BackgroundColor3 = Color(Theme.Component, 4, "Dark");
					if Label:FindFirstChild("UIStroke") then
						Label.UIStroke.Color = Theme.Outline
						Label.UIStroke.Transparency = 0.6
					end
				end
			end,

			["Title"] = function(Label)
				if Label:IsA("TextLabel") then Label.TextColor3 = Theme.Title end
			end,

			["Description"] = function(Label)
				if Label:IsA("TextLabel") then Label.TextColor3 = Theme.Description end
			end,

			["Section"] = function(Label)
				if Label:IsA("TextLabel") then Label.TextColor3 = Theme.Title end
			end,

			["Options"] = function(Label)
				if Label:IsA("TextLabel") and Label.Parent.Name == "Main" then
					Label.TextColor3 = Theme.Title
				end
			end,

			["Notification"] = function(Label)
				if Label:IsA("CanvasGroup") then
					Label.BackgroundColor3 = Theme.Primary
					Label.UIStroke.Color = Theme.Outline
					Label.UIStroke.Transparency = 0.6
				end
			end,

			["TextLabel"] = function(Label)
				if Label:IsA("TextLabel") and Label.Parent:FindFirstChild("List") then
					Label.TextColor3 = Theme.Tab
				end
			end,

			["Main"] = function(Label)
				if Label:IsA("Frame") then
					if Label.Parent == Window then
						Label.BackgroundColor3 = Theme.Secondary
					elseif Label.Parent:FindFirstChild("Value") then
						local Toggle = Label.Parent.Value
						if not Toggle.Value then
							Label.BackgroundColor3 = Theme.Interactables
							if Label:FindFirstChild("Circle") then
								Label.Circle.BackgroundColor3 = Theme.Primary
							end
						end
					else
						Label.BackgroundColor3 = Theme.Interactables
					end
					if Label:FindFirstChild("UIStroke") then
						Label.UIStroke.Color = Theme.Outline
						Label.UIStroke.Transparency = 0.6
					end
				elseif Label:FindFirstChild("Padding") then
					Label.TextColor3 = Theme.Title
				end
			end,

			["Amount"] = function(Label)
				if Label:IsA("Frame") then Label.BackgroundColor3 = Theme.Interactables end
			end,

			["Slide"] = function(Label)
				if Label:IsA("Frame") then Label.BackgroundColor3 = Theme.Interactables end
			end,

			["Input"] = function(Label)
				if Label:IsA("TextLabel") then
					Label.TextColor3 = Theme.Title
				elseif Label:FindFirstChild("Labels") then
					Label.BackgroundColor3 = Theme.Component
				elseif Label:IsA("TextBox") and Label.Parent.Name == "Main" then
					Label.TextColor3 = Theme.Title
				end
			end,

			["Outline"] = function(Stroke)
				if Stroke:IsA("UIStroke") then
					Stroke.Color = Theme.Outline
					Stroke.Transparency = 0.6
				end
			end,

			["DropdownExample"] = function(Label)
				Label.BackgroundColor3 = Theme.Secondary
				if Label:FindFirstChild("UIStroke") then
					Label.UIStroke.Color = Theme.Outline
					Label.UIStroke.Transparency = 0.6
				end
			end,

			["Underline"] = function(Label)
				if Label:IsA("Frame") then
					Label.BackgroundColor3 = Theme.Accent
				end
			end,

			["Highlight"] = function(Label)
				if Label:IsA("Frame") then
					Label.BackgroundColor3 = Theme.Accent
				end
			end,
		},

		Classes = {
			["ImageLabel"] = function(Label)
				if Label.Image ~= "rbxassetid://6644618143" then
					Label.ImageColor3 = Theme.Icon
				end
			end,

			["TextLabel"] = function(Label)
				if Label:FindFirstChild("Padding") then
					Label.TextColor3 = Theme.Title
				end
			end,

			["TextButton"] = function(Label)
				if Label:FindFirstChild("Labels") then
					Label.BackgroundColor3 = Theme.Component
					if Label:FindFirstChild("UIStroke") then
						Label.UIStroke.Color = Theme.Outline
						Label.UIStroke.Transparency = 0.6
					end
				end
			end,

			["ScrollingFrame"] = function(Label)
				Label.ScrollBarImageColor3 = Theme.Component
			end,
		},
	}

	function Options:SetTheme(Info)
		Theme = Info or Theme
		Window.BackgroundColor3 = Theme.Primary
		Holder.BackgroundColor3  = Theme.Secondary
		Window.UIStroke.Color    = Theme.Shadow

		for _, Descendant in next, Screen:GetDescendants() do
			local NameFn, ClassFn = Themes.Names[Descendant.Name], Themes.Classes[Descendant.ClassName]
			if NameFn then NameFn(Descendant) elseif ClassFn then ClassFn(Descendant) end
		end
	end

	-- Settings API
	function Options:SetSetting(Setting, Value) -- Size, Transparency, Blur, Theme, Keybind
		if Setting == "Size" then
			Window.Size = Value
			Setup.Size = Value
		elseif Setting == "Transparency" then
			Window.GroupTransparency = Value
			Setup.Transparency = Value
			for _, Notification in next, Screen:GetDescendants() do
				if Notification:IsA("CanvasGroup") and Notification.Name == "Notification" then
					Notification.GroupTransparency = Value
				end
			end
		elseif Setting == "Blur" then
			local AlreadyBlurred, Root = Blurs[Settings.Title], nil
			if AlreadyBlurred then Root = Blurs[Settings.Title]["root"] end
			if Value then
				BlurEnabled = true
				if not AlreadyBlurred or not Root then
					Blurs[Settings.Title] = Blur.new(Window, 6)
				elseif Root and not Root.Parent then
					Root.Parent = workspace.CurrentCamera
				end
			elseif not Value and (AlreadyBlurred and Root and Root.Parent) then
				Root.Parent = nil
				BlurEnabled = false
			end
		elseif Setting == "Theme" and typeof(Value) == "table" then
			Options:SetTheme(Value)
		elseif Setting == "Keybind" then
			Setup.Keybind = Value
		else
			warn("[Ecstays UI] Tried to change a non-existent or locked setting.")
		end
	end

	SetProperty(Window, { Size = Settings.Size, Visible = true, Parent = Screen });
	Animations:Open(Window, Settings.Transparency or 0)

	-- sofort Ecstays Theme anwenden
	Options:SetTheme(Theme)

	return Options
end

return Library
