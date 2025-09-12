local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

local Library = {
	Elements = {},
	ThemeObjects = {},
	Connections = {},
	Flags = {},
	Themes = {
		Default = {
			Main = Color3.fromRGB(20, 20, 22),
			Second = Color3.fromRGB(30, 30, 32),
			Stroke = Color3.fromRGB(60, 60, 65),
			Divider = Color3.fromRGB(40, 40, 45),
			Text = Color3.fromRGB(240, 240, 245),
			TextDark = Color3.fromRGB(160, 160, 165),
			Accent = Color3.fromRGB(12, 144, 164)
		}
	},
	SelectedTheme = "Default",
	Folder = nil,
	SaveCfg = false,
	Font = Enum.Font.Gotham,
	UITransparency = false
}

function Library:CleanupInstance()
    for _, con in pairs(self.Connections) do
        if typeof(con) == "RBXScriptConnection" then
            con:Disconnect()
        end
    end
    table.clear(self.Connections)
    local cg = game:GetService("CoreGui")
    for _, obj in pairs(cg:GetChildren()) do
        if obj:IsA("ScreenGui") and obj.Name:match("^[A-Z]%d%d%d$") then
            obj:Destroy()
        end
    end
end

local function Create(Name, Parent, Properties, Children)
    local Object = Instance.new(Name)
    for prop, value in pairs(Properties or {}) do
        Object[prop] = value
    end
    for _, child in pairs(Children or {}) do
        child.Parent = Object
    end
    Object.Parent = Parent
    return Object
end

local function AddConnection(Signal, Function)
	if not Library:IsRunning() then return end
	local Connection = Signal:Connect(Function)
	table.insert(Library.Connections, Connection)
	return Connection
end

local function MakeDraggable(DragPoint, Main)
	local Dragging, DragInput, MousePos, FramePos
	AddConnection(DragPoint.InputBegan, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			MousePos = Input.Position
			FramePos = Main.Position
			AddConnection(Input.Changed, function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)
	AddConnection(DragPoint.InputChanged, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
			DragInput = Input
		end
	end)
	AddConnection(UserInputService.InputChanged, function(Input)
		if Input == DragInput and Dragging then
			local Delta = Input.Position - MousePos
			TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
				Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
			}):Play()
		end
	end)
end

local function CreateElement(ElementName, ElementFunction)
	Library.Elements[ElementName] = ElementFunction
end

local function MakeElement(ElementName, ...)
	return Library.Elements[ElementName](...)
end

local function Round(Number, Factor)
	local Result = math.floor(Number / Factor + 0.5) * Factor
	return Result < 0 and Result + Factor or Result
end

local function ReturnProperty(Object)
	if Object:IsA("Frame") or Object:IsA("TextButton") then return "BackgroundColor3" end
	if Object:IsA("ScrollingFrame") then return "ScrollBarImageColor3" end
	if Object:IsA("UIStroke") then return "Color" end
	if Object:IsA("TextLabel") or Object:IsA("TextBox") then return "TextColor3" end
	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then return "ImageColor3" end
end

local function AddThemeObject(Object, Type)
	Library.ThemeObjects[Type] = Library.ThemeObjects[Type] or {}
	table.insert(Library.ThemeObjects[Type], Object)
	Object[ReturnProperty(Object)] = Library.Themes[Library.SelectedTheme][Type]
	return Object
end

local function SetTheme()
	for Type, Objects in pairs(Library.ThemeObjects) do
		for _, Object in pairs(Objects) do
			Object[ReturnProperty(Object)] = Library.Themes[Library.SelectedTheme][Type]
		end
	end
end

Library:CleanupInstance()

local Container = Create("ScreenGui", game:GetService("CoreGui"), {
	Name = string.char(math.random(65, 90)) .. tostring(math.random(100, 999)),
	DisplayOrder = 2147483647
})

function Library:IsRunning()
	return Container.Parent == game:GetService("CoreGui")
end

task.spawn(function()
	while Library:IsRunning() do
		task.wait()
	end
	for _, Connection in pairs(Library.Connections) do
		Connection:Disconnect()
	end
end)

function Library:SetUITransparency(enabled)
	Library.UITransparency = enabled
	local transparency = enabled and 0.1 or 0
	local blurSize = enabled and 24 or 0

	for _, obj in pairs(Container:GetDescendants()) do
		if (obj:IsA("Frame") or obj:IsA("TextButton")) and obj.BackgroundTransparency < 1 then
			TweenService:Create(obj, TweenInfo.new(0.3), {BackgroundTransparency = transparency}):Play()
		end
	end

	local blur = game.Lighting:FindFirstChild("BlurEffect")
	if enabled and not blur then
		Create("BlurEffect", game.Lighting, {Name = "BlurEffect", Size = blurSize})
	elseif not enabled and blur then
		blur:Destroy()
	end
end

local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadCfg(Config)
	local Data = HttpService:JSONDecode(Config)
	for flag, value in pairs(Data) do
		if Library.Flags[flag] then
			task.spawn(function()
				if Library.Flags[flag].Type == "Colorpicker" then
					Library.Flags[flag]:Set(UnpackColor(value))
				else
					Library.Flags[flag]:Set(value)
				end
			end)
		else
			warn("Config Loader: Flag not found -", flag, value)
		end
	end
end

local function SaveCfg(Name)
	local Data = {}
	for flag, obj in pairs(Library.Flags) do
		if obj.Save then
			Data[flag] = obj.Type == "Colorpicker" and PackColor(obj.Value) or obj.Value
		end
	end
	if Library.Folder and Library.SaveCfg then
		writefile(Library.Folder .. "/" .. Name .. ".txt", HttpService:JSONEncode(Data))
	end
end

CreateElement("Corner", function(Scale, Offset)
	return Create("UICorner", nil, {CornerRadius = UDim.new(Scale or 0, Offset or 6)})
end)

CreateElement("Stroke", function(Color, Thickness)
	return Create("UIStroke", nil, {Color = Color or Library.Themes.Default.Stroke, Thickness = Thickness or 1})
end)

CreateElement("List", function(Scale, Offset)
	return Create("UIListLayout", nil, {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(Scale or 0, Offset or 4)})
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
	return Create("UIPadding", nil, {
		PaddingBottom = UDim.new(0, Bottom or 4),
		PaddingLeft = UDim.new(0, Left or 4),
		PaddingRight = UDim.new(0, Right or 4),
		PaddingTop = UDim.new(0, Top or 4)
	})
end)

CreateElement("Frame", function(Color)
	return Create("Frame", nil, {BackgroundColor3 = Color or Library.Themes.Default.Main, BorderSizePixel = 0})
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
	return Create("Frame", nil, {
		BackgroundColor3 = Color or Library.Themes.Default.Main,
		BorderSizePixel = 0
	}, {MakeElement("Corner", Scale, Offset)})
end)

CreateElement("Button", function()
	return Create("TextButton", nil, {Text = "", AutoButtonColor = false, BackgroundTransparency = 0.8, BorderSizePixel = 0})
end)

CreateElement("ScrollFrame", function(Color, Width)
	return Create("ScrollingFrame", nil, {
		BackgroundTransparency = 1,
		ScrollBarImageColor3 = Color or Library.Themes.Default.Divider,
		BorderSizePixel = 0,
		ScrollBarThickness = Width or 4,
		CanvasSize = UDim2.new(0, 0, 0, 0)
	})
end)

CreateElement("Label", function(Text, TextSize, Transparency)
	return Create("TextLabel", nil, {
		Text = Text or "",
		TextColor3 = Library.Themes.Default.Text,
		TextTransparency = Transparency or 0,
		TextSize = TextSize or 15,
		Font = Library.Font,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left
	})
end)

local NotificationHolder = Create("Frame", Container, {
	Position = UDim2.new(1, -25, 1, -25),
	Size = UDim2.new(0, 300, 1, -25),
	AnchorPoint = Vector2.new(1, 1),
	BackgroundTransparency = 1
}, {
	MakeElement("List", 0, 5),
	MakeElement("Padding", 10, 10, 10, 10)
})

function Library:MakeNotification(Config)
	task.spawn(function()
		Config = Config or {}
		Config.Name = Config.Name or "Notification"
		Config.Content = Config.Content or "Content"
		Config.Time = Config.Time or 5

		local NotificationParent = Create("Frame", NotificationHolder, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1
		})

		local NotificationFrame = Create("Frame", NotificationParent, {
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, -55, 0, 0),
			BackgroundColor3 = Library.Themes.Default.Main,
			AutomaticSize = Enum.AutomaticSize.Y
		}, {
			MakeElement("Corner", 0, 8),
			MakeElement("Stroke"),
			MakeElement("Padding", 12, 12, 12, 12),
			Create("ImageLabel", {
				Size = UDim2.new(0, 20, 0, 20),
				Image = "rbxassetid://4384403532",
				ImageColor3 = Library.Themes.Default.Text,
				BackgroundTransparency = 1,
				Name = "Icon"
			}),
			Create("TextLabel", {
				Text = Config.Name,
				Size = UDim2.new(1, -30, 0, 20),
				Position = UDim2.new(0, 30, 0, 0),
				Font = Library.Font,
				TextSize = 15,
				TextColor3 = Library.Themes.Default.Text,
				BackgroundTransparency = 1,
				Name = "Title"
			}),
			Create("TextLabel", {
				Text = Config.Content,
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 25),
				Font = Library.Font,
				TextSize = 14,
				TextColor3 = Library.Themes.Default.TextDark,
				AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true,
				BackgroundTransparency = 1,
				Name = "Content"
			})
		})

		TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()
		task.wait(Config.Time - 0.8)
		TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
		TweenService:Create(NotificationFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
		TweenService:Create(NotificationFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
		TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
		task.wait(0.05)
		TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {Position = UDim2.new(1, 20, 0, 0)}):Play()
		task.wait(1)
		NotificationFrame:Destroy()
	end)
end

function Library:MakeWindow(WindowConfig)
	WindowConfig = WindowConfig or {}
	WindowConfig.Name = WindowConfig.Name or "UI Library"
	WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
	WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
	WindowConfig.Icon = WindowConfig.Icon or "rbxassetid://18898147855"
	WindowConfig.ShowIcon = WindowConfig.ShowIcon or true
	Library.Folder = WindowConfig.ConfigFolder
	Library.SaveCfg = WindowConfig.SaveConfig

	if WindowConfig.SaveConfig and not isfolder(WindowConfig.ConfigFolder) then
		makefolder(WindowConfig.ConfigFolder)
	end

	local Minimized, UIHidden = false, false
	local MainWindow = Create("Frame", Container, {
		Position = UDim2.new(0.5, -307, 0.5, -172),
		Size = UDim2.new(0, 615, 0, 344),
		BackgroundColor3 = Library.Themes.Default.Main,
		ClipsDescendants = true
	}, {MakeElement("Corner", 0, 10)})

	local DragPoint = Create("Frame", MainWindow, {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		Name = "TopBar"
	})

	local WindowName = AddThemeObject(Create("TextLabel", DragPoint, {
		Text = WindowConfig.Name,
		Size = UDim2.new(1, -30, 0, 50),
		Position = UDim2.new(0, WindowConfig.ShowIcon and 50 or 25, 0, 0),
		Font = Enum.Font.GothamBlack,
		TextSize = 20,
		TextColor3 = Library.Themes.Default.Text,
		BackgroundTransparency = 1
	}), "Text")

	if WindowConfig.ShowIcon then
		Create("ImageLabel", DragPoint, {
			Image = WindowConfig.Icon,
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, 25, 0, 15),
			BackgroundTransparency = 1
		})
	end

	local CloseBtn = Create("TextButton", DragPoint, {
		Text = "",
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -40, 0, 10),
		BackgroundColor3 = Library.Themes.Default.Second,
		BackgroundTransparency = 0.7,
		AutoButtonColor = false
	}, {
		AddThemeObject(Create("ImageLabel", {
			Image = "rbxassetid://7072725342",
			Size = UDim2.new(0, 18, 0, 18),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1
		}), "Text"),
		MakeElement("Corner", 0, 7),
		MakeElement("Stroke")
	})

	local MinimizeBtn = Create("TextButton", DragPoint, {
		Text = "",
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -80, 0, 10),
		BackgroundColor3 = Library.Themes.Default.Second,
		BackgroundTransparency = 0.7,
		AutoButtonColor = false
	}, {
		AddThemeObject(Create("ImageLabel", {
			Image = "rbxassetid://7072719338",
			Size = UDim2.new(0, 18, 0, 18),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Name = "Ico"
		}), "Text"),
		MakeElement("Corner", 0, 7),
		MakeElement("Stroke")
	})

	local TabHolder = AddThemeObject(Create("ScrollingFrame", MainWindow, {
		Size = UDim2.new(0, 150, 1, -50),
		Position = UDim2.new(0, 0, 0, 50),
		BackgroundColor3 = Library.Themes.Default.Second,
		ScrollBarImageColor3 = Library.Themes.Default.Divider,
		ScrollBarThickness = 4,
		CanvasSize = UDim2.new(0, 0, 0, 0)
	}, {
		MakeElement("List", 0, 8),
		MakeElement("Padding", 8, 8, 8, 8)
	}), "Divider")

	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
	end)

	MakeDraggable(DragPoint, MainWindow)

	local MobileReopenButton = Create("TextButton", Container, {
		Size = UDim2.new(0, 40, 0, 40),
		Position = UDim2.new(0.5, -20, 0, 20),
		BackgroundColor3 = Library.Themes.Default.Main,
		Visible = false
	}, {
		Create("ImageLabel", {
			Image = WindowConfig.Icon,
			Size = UDim2.new(0.7, 0, 0.7, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 1
		}),
		MakeElement("Corner", 1)
	})

	AddConnection(CloseBtn.MouseButton1Click, function()
		MainWindow.Visible = false
		if UserInputService.TouchEnabled then
			MobileReopenButton.Visible = true
		end
		UIHidden = true
		Library:MakeNotification({
			Name = "Interface Hidden",
			Content = UserInputService.TouchEnabled and "Tap the button or press Insert to reopen" or "Press Insert to reopen",
			Time = 5
		})
	end)

	AddConnection(UserInputService.InputBegan, function(Input)
		if Input.KeyCode == Enum.KeyCode.Insert then
			MainWindow.Visible = not MainWindow.Visible
			MobileReopenButton.Visible = not MainWindow.Visible
			UIHidden = not MainWindow.Visible
		end
	end)

	AddConnection(MobileReopenButton.Activated, function()
		MainWindow.Visible = true
		MobileReopenButton.Visible = false
		UIHidden = false
	end)

	AddConnection(MinimizeBtn.MouseButton1Click, function()
		Minimized = not Minimized
		if Minimized then
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50)}):Play()
			MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
			MainWindow.ClipsDescendants = true
			TabHolder.Visible = false
		else
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 615, 0, 344)}):Play()
			MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
			task.wait(0.02)
			MainWindow.ClipsDescendants = false
			TabHolder.Visible = true
		end
	end)

	local TabFunction = {}

	function TabFunction:MakeTab(TabConfig)
		TabConfig = TabConfig or {}
		TabConfig.Name = TabConfig.Name or "Tab"
		TabConfig.Icon = TabConfig.Icon or ""
		TabConfig.PremiumOnly = TabConfig.PremiumOnly or false

		local TabFrame = Create("TextButton", TabHolder, {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			AutoButtonColor = false
		}, {
			AddThemeObject(Create("ImageLabel", {
				Image = TabConfig.Icon,
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(0, 10, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				ImageTransparency = FirstTab and 0 or 0.4,
				BackgroundTransparency = 1,
				Name = "Ico"
			}), "Text"),
			AddThemeObject(Create("TextLabel", {
				Text = TabConfig.Name,
				Size = UDim2.new(1, -35, 1, 0),
				Position = UDim2.new(0, 35, 0, 0),
				Font = FirstTab and Enum.Font.GothamBlack or Library.Font,
				TextTransparency = FirstTab and 0 or 0.4,
				TextColor3 = Library.Themes.Default.Text,
				BackgroundTransparency = 1,
				Name = "Title"
			}), "Text")
		})

		local Container = AddThemeObject(Create("ScrollingFrame", MainWindow, {
			Size = UDim2.new(1, -150, 1, -50),
			Position = UDim2.new(0, 150, 0, 50),
			BackgroundTransparency = 1,
			ScrollBarImageColor3 = Library.Themes.Default.Divider,
			ScrollBarThickness = 5,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Visible = FirstTab,
			Name = "ItemContainer"
		}, {
			MakeElement("List", 0, 6),
			MakeElement("Padding", 15, 10, 10, 15)
		}), "Divider")

		AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
		end)

		if FirstTab then
			FirstTab = false
		end

		AddConnection(TabFrame.MouseButton1Click, function()
			for _, Tab in pairs(TabHolder:GetChildren()) do
				if Tab:IsA("TextButton") then
					TweenService:Create(Tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0.4, ImageColor3 = Library.Themes.Default.Text}):Play()
					TweenService:Create(Tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 0.4, TextColor3 = Library.Themes.Default.Text}):Play()
					Tab.Title.Font = Library.Font
				end
			end
			for _, ItemContainer in pairs(MainWindow:GetChildren()) do
				if ItemContainer.Name == "ItemContainer" then
					ItemContainer.Visible = false
				end
			end
			TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {ImageTransparency = 0, ImageColor3 = Library.Themes.Default.Accent}):Play()
			TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {TextTransparency = 0, TextColor3 = Library.Themes.Default.Accent}):Play()
			TabFrame.Title.Font = Enum.Font.GothamBlack
			Container.Visible = true
		end)

		local ElementFunction = {}

		function ElementFunction:AddLabel(Text)
			local LabelFrame = AddThemeObject(Create("Frame", Container, {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = Library.Themes.Default.Second,
				BackgroundTransparency = 0.7
			}, {
				AddThemeObject(Create("TextLabel", {
					Text = Text or "",
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Library.Font,
					TextSize = 15,
					TextColor3 = Library.Themes.Default.Text,
					BackgroundTransparency = 1,
					Name = "Content"
				}), "Text"),
				MakeElement("Stroke"),
				MakeElement("Corner", 0, 5)
			}), "Second")

			local Label = {}
			function Label:Set(NewText)
				LabelFrame.Content.Text = NewText
			end
			return Label
		end

		function ElementFunction:AddButton(ButtonConfig)
			ButtonConfig = ButtonConfig or {}
			ButtonConfig.Name = ButtonConfig.Name or "Button"
			ButtonConfig.Callback = ButtonConfig.Callback or function() end
			ButtonConfig.Icon = ButtonConfig.Icon or "rbxassetid://3944703587"

			local ButtonFrame = AddThemeObject(Create("Frame", Container, {
				Size = UDim2.new(1, 0, 0, 33),
				BackgroundColor3 = Library.Themes.Default.Second,
				BackgroundTransparency = 0.7
			}, {
				AddThemeObject(Create("TextLabel", {
					Text = ButtonConfig.Name,
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Library.Font,
					TextSize = 15,
					TextColor3 = Library.Themes.Default.Text,
					BackgroundTransparency = 1,
					Name = "Content"
				}), "Text"),
				AddThemeObject(Create("ImageLabel", {
					Image = ButtonConfig.Icon,
					Size = UDim2.new(0, 20, 0, 20),
					Position = UDim2.new(1, -30, 0, 7),
					BackgroundTransparency = 1
				}), "TextDark"),
				MakeElement("Stroke"),
				MakeElement("Corner", 0, 5),
				Create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""})
			}), "Second")

			local Click = ButtonFrame.TextButton
			AddConnection(Click.MouseEnter, function()
				TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(Library.Themes.Default.Second.R * 255 + 3, Library.Themes.Default.Second.G * 255 + 3, Library.Themes.Default.Second.B * 255 + 3)}):Play()
			end)
			AddConnection(Click.MouseLeave, function()
				TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = Library.Themes.Default.Second}):Play()
			end)
			AddConnection(Click.MouseButton1Down, function()
				TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(Library.Themes.Default.Second.R * 255 + 6, Library.Themes.Default.Second.G * 255 + 6, Library.Themes.Default.Second.B * 255 + 6)}):Play()
			end)
			AddConnection(Click.MouseButton1Up, function()
				TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = Library.Themes.Default.Second}):Play()
				task.spawn(ButtonConfig.Callback)
			end)

			local Button = {}
			function Button:Set(NewText)
				ButtonFrame.Content.Text = NewText
			end
			return Button
		end

		function ElementFunction:AddToggle(ToggleConfig)
			ToggleConfig = ToggleConfig or {}
			ToggleConfig.Name = ToggleConfig.Name or "Toggle"
			ToggleConfig.Default = ToggleConfig.Default or false
			ToggleConfig.Callback = ToggleConfig.Callback or function() end
			ToggleConfig.Color = ToggleConfig.Color or Library.Themes.Default.Accent
			ToggleConfig.Flag = ToggleConfig.Flag or nil
			ToggleConfig.Save = ToggleConfig.Save or false

			local Toggle = {Value = ToggleConfig.Default, Save = ToggleConfig.Save}
			local ToggleBox = Create("Frame", nil, {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(1, -24, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = ToggleConfig.Default and ToggleConfig.Color or Library.Themes.Default.Divider
			}, {
				Create("UIStroke", {Color = ToggleConfig.Default and ToggleConfig.Color or Library.Themes.Default.Stroke, Transparency = 0.5, Name = "Stroke"}),
				Create("ImageLabel", {
					Image = "rbxassetid://3944680095",
					Size = ToggleConfig.Default and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					BackgroundTransparency = 1,
					ImageTransparency = ToggleConfig.Default and 0 or 1,
					Name = "Ico"
				}),
				MakeElement("Corner", 0, 4)
			})

			local ToggleFrame = AddThemeObject(Create("Frame", Container, {
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundColor3 = Library.Themes.Default.Second,
				BackgroundTransparency = 0.7
			}, {
				AddThemeObject(Create("TextLabel", {
					Text = ToggleConfig.Name,
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Library.Font,
					TextSize = 15,
					TextColor3 = Library.Themes.Default.Text,
					BackgroundTransparency = 1,
					Name = "Content"
				}), "Text"),
				MakeElement("Stroke"),
				MakeElement("Corner", 0, 5),
				ToggleBox,
				Create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""})
			}), "Second")

			local Click = ToggleFrame.TextButton
			function Toggle:Set(Value)
				Toggle.Value = Value
				TweenService:Create(ToggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundColor3 = Value and ToggleConfig.Color or Library.Themes.Default.Divider}):Play()
				TweenService:Create(ToggleBox.Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Color = Value and ToggleConfig.Color or Library.Themes.Default.Stroke}):Play()
				TweenService:Create(ToggleBox.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {ImageTransparency = Value and 0 or 1, Size = Value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8)}):Play()
				ToggleConfig.Callback(Value)
				if ToggleConfig.Save then
					SaveCfg(game.GameId)
				end
			end

			AddConnection(Click.MouseEnter, function()
				TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(Library.Themes.Default.Second.R * 255 + 3, Library.Themes.Default.Second.G * 255 + 3, Library.Themes.Default.Second.B * 255 + 3)}):Play()
			end)
			AddConnection(Click.MouseLeave, function()
				TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = Library.Themes.Default.Second}):Play()
			end)
			AddConnection(Click.MouseButton1Down, function()
				TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(Library.Themes.Default.Second.R * 255 + 6, Library.Themes.Default.Second.G * 255 + 6, Library.Themes.Default.Second.B * 255 + 6)}):Play()
			end)
			AddConnection(Click.MouseButton1Up, function()
				TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = Library.Themes.Default.Second}):Play()
				Toggle:Set(not Toggle.Value)
			end)

			Toggle:Set(ToggleConfig.Default)
			if ToggleConfig.Flag then
				Library.Flags[ToggleConfig.Flag] = Toggle
			end
			return Toggle
		end

		function ElementFunction:AddSlider(SliderConfig)
			SliderConfig = SliderConfig or {}
			SliderConfig.Name = SliderConfig.Name or "Slider"
			SliderConfig.Min = SliderConfig.Min or 0
			SliderConfig.Max = SliderConfig.Max or 100
			SliderConfig.Increment = SliderConfig.Increment or 1
			SliderConfig.Default = SliderConfig.Default or 50
			SliderConfig.Callback = SliderConfig.Callback or function() end
			SliderConfig.ValueName = SliderConfig.ValueName or ""
			SliderConfig.Color = SliderConfig.Color or Library.Themes.Default.Accent
			SliderConfig.Flag = SliderConfig.Flag or nil
			SliderConfig.Save = SliderConfig.Save or false

			local Slider = {Value = SliderConfig.Default, Save = SliderConfig.Save}
			local Dragging = false

			local SliderDrag = Create("Frame", nil, {
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundColor3 = SliderConfig.Color,
				BackgroundTransparency = 0.3,
				ClipsDescendants = true
			}, {
				AddThemeObject(Create("TextLabel", {
					Text = tostring(SliderConfig.Default) .. " " .. SliderConfig.ValueName,
					Size = UDim2.new(1, -12, 0, 14),
					Position = UDim2.new(0, 12, 0, 6),
					Font = Library.Font,
					TextSize = 13,
					TextColor3 = Library.Themes.Default.Text,
					BackgroundTransparency = 1,
					Name = "Value"
				}), "Text"),
				MakeElement("Corner", 0, 5)
			})

			local SliderBar = Create("Frame", nil, {
				Size = UDim2.new(1, -24, 0, 26),
				Position = UDim2.new(0, 12, 0, 30),
				BackgroundColor3 = SliderConfig.Color,
				BackgroundTransparency = 0.9
			}, {
				MakeElement("Stroke", SliderConfig.Color),
				AddThemeObject(Create("TextLabel", {
					Text = tostring(SliderConfig.Default) .. " " .. SliderConfig.ValueName,
					Size = UDim2.new(1, -12, 0, 14),
					Position = UDim2.new(0, 12, 0, 6),
					Font = Library.Font,
					TextSize = 13,
					TextColor3 = Library.Themes.Default.Text,
					TextTransparency = 0.8,
					BackgroundTransparency = 1,
					Name = "Value"
				}), "Text"),
				SliderDrag,
				MakeElement("Corner", 0, 5)
			})

			local SliderFrame = AddThemeObject(Create("Frame", Container, {
				Size = UDim2.new(1, 0, 0, 65),
				BackgroundColor3 = Library.Themes.Default.Second,
				BackgroundTransparency = 0.7
			}, {
				AddThemeObject(Create("TextLabel", {
					Text = SliderConfig.Name,
					Size = UDim2.new(1, -12, 0, 14),
					Position = UDim2.new(0, 12, 0, 10),
					Font = Library.Font,
					TextSize = 15,
					TextColor3 = Library.Themes.Default.Text,
					BackgroundTransparency = 1,
					Name = "Content"
				}), "Text"),
				MakeElement("Stroke"),
				MakeElement("Corner", 0, 4),
				SliderBar
			}), "Second")

			AddConnection(SliderBar.InputBegan, function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					Dragging = true
				end
			end)
			AddConnection(SliderBar.InputEnded, function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					Dragging = false
				end
			end)
			AddConnection(UserInputService.InputChanged, function(Input)
				if Dragging then
					local SizeScale = math.clamp((Mouse.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
					Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale))
				end
			end)

			function Slider:Set(Value)
				self.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
				TweenService:Create(SliderDrag, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = UDim2.fromScale((self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1)}):Play()
				SliderBar.Value.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
				SliderDrag.Value.Text = tostring(self.Value) .. " " .. SliderConfig.ValueName
				SliderConfig.Callback(self.Value)
				if SliderConfig.Save then
					SaveCfg(game.GameId)
				end
			end

			Slider:Set(SliderConfig.Default)
			if SliderConfig.Flag then
				Library.Flags[SliderConfig.Flag] = Slider
			end
			return Slider
		end

		function ElementFunction:AddDropdown(DropdownConfig)
			DropdownConfig = DropdownConfig or {}
			DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
			DropdownConfig.Options = DropdownConfig.Options or {}
			DropdownConfig.Default = DropdownConfig.Default or ""
			DropdownConfig.Callback = DropdownConfig.Callback or function() end
			DropdownConfig.Flag = DropdownConfig.Flag or nil
			DropdownConfig.Save = DropdownConfig.Save or false

			local Dropdown = {Value = DropdownConfig.Default, Options = DropdownConfig.Options, Buttons = {}, Toggled = false, Type = "Dropdown", Save = DropdownConfig.Save}
			local MaxElements = 5

			local DropdownList = MakeElement("List")
			local DropdownContainer = AddThemeObject(Create("ScrollingFrame", Container, {
				Size = UDim2.new(1, 0, 1, -38),
				Position = UDim2.new(0, 0, 0, 38),
				BackgroundColor3 = Library.Themes.Default.Divider,
				ScrollBarImageColor3 = Library.Themes.Default.Stroke,
				ScrollBarThickness = 4,
				ClipsDescendants = true
			}, {DropdownList}), "Divider")

			local DropdownFrame = AddThemeObject(Create("Frame", Container, {
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundColor3 = Library.Themes.Default.Second,
				BackgroundTransparency = 0.7,
				ClipsDescendants = true
			}, {
				DropdownContainer,
				Create("Frame", {
					Size = UDim2.new(1, 0, 0, 38),
					ClipsDescendants = true,
					Name = "F"
				}, {
					AddThemeObject(Create("TextLabel", {
						Text = DropdownConfig.Name,
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Library.Font,
						TextSize = 15,
						TextColor3 = Library.Themes.Default.Text,
						BackgroundTransparency = 1,
						Name = "Content"
					}), "Text"),
					AddThemeObject(Create("TextLabel", {
						Text = DropdownConfig.Default,
						Size = UDim2.new(1, -40, 1, 0),
						Font = Library.Font,
						TextSize = 13,
						TextColor3 = Library.Themes.Default.TextDark,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Right,
						Name = "Selected"
					}), "TextDark"),
					AddThemeObject(Create("ImageLabel", {
						Image = "rbxassetid://7072706796",
						Size = UDim2.new(0, 20, 0, 20),
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(1, -30, 0.5, 0),
						BackgroundTransparency = 1,
						Name = "Ico"
					}), "TextDark"),
					Create("Frame", {
						Size = UDim2.new(1, 0, 0, 1),
						Position = UDim2.new(0, 0, 1, -1),
						BackgroundColor3 = Library.Themes.Default.Stroke,
						Name = "Line",
						Visible = false
					}),
					Create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""})
				}),
				MakeElement("Stroke"),
				MakeElement("Corner", 0, 5)
			}), "Second")

			AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y)
			end)

			local Click = DropdownFrame.F.TextButton
			function Dropdown:Refresh(Options, Delete)
				if Delete then
					for _, v in pairs(Dropdown.Buttons) do
						v:Destroy()
					end
					table.clear(Dropdown.Options)
					table.clear(Dropdown.Buttons)
				end
				Dropdown.Options = Options
				for _, Option in pairs(Options) do
					local OptionBtn = AddThemeObject(Create("TextButton", DropdownContainer, {
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundColor3 = Library.Themes.Default.Divider,
						BackgroundTransparency = 1,
						AutoButtonColor = false
					}, {
						AddThemeObject(Create("TextLabel", {
							Text = Option,
							Position = UDim2.new(0, 8, 0, 0),
							Size = UDim2.new(1, -8, 1, 0),
							Font = Library.Font,
							TextSize = 13,
							TextColor3 = Library.Themes.Default.Text,
							TextTransparency = 0.4,
							BackgroundTransparency = 1,
							Name = "Title"
						}), "Text"),
						MakeElement("Corner", 0, 6)
					}), "Divider")

					AddConnection(OptionBtn.MouseButton1Click, function()
						Dropdown:Set(Option)
					end)
					Dropdown.Buttons[Option] = OptionBtn
				end
			end

			function Dropdown:Set(Value)
				if not table.find(Dropdown.Options, Value) then
					Dropdown.Value = "..."
					DropdownFrame.F.Selected.Text = Dropdown.Value
					for _, v in pairs(Dropdown.Buttons) do
						TweenService:Create(v, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
						TweenService:Create(v.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0.4}):Play()
					end
					return
				end

				Dropdown.Value = Value
				DropdownFrame.F.Selected.Text = Value
				for _, v in pairs(Dropdown.Buttons) do
					TweenService:Create(v, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
					TweenService:Create(v.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0.4}):Play()
				end
				TweenService:Create(Dropdown.Buttons[Value], TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
				TweenService:Create(Dropdown.Buttons[Value].Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
				DropdownConfig.Callback(Value)
				if DropdownConfig.Save then
					SaveCfg(game.GameId)
				end
			end

			AddConnection(Click.MouseButton1Click, function()
				Dropdown.Toggled = not Dropdown.Toggled
				DropdownFrame.F.Line.Visible = Dropdown.Toggled
				TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Rotation = Dropdown.Toggled and 180 or 0}):Play()
				local newSize = Dropdown.Toggled and (#Dropdown.Options > MaxElements and UDim2.new(1, 0, 0, 38 + MaxElements * 28) or UDim2.new(1, 0, 0, DropdownList.AbsoluteContentSize.Y + 38)) or UDim2.new(1, 0, 0, 38)
				TweenService:Create(DropdownFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = newSize}):Play()
			end)

			Dropdown:Refresh(DropdownConfig.Options, false)
			Dropdown:Set(DropdownConfig.Default)
			if DropdownConfig.Flag then
				Library.Flags[DropdownConfig.Flag] = Dropdown
			end
			return Dropdown
		end

		function ElementFunction:AddBind(BindConfig)
			BindConfig = BindConfig or {}
			BindConfig.Name = BindConfig.Name or "Bind"
			BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
			BindConfig.Hold = BindConfig.Hold or false
			BindConfig.Callback = BindConfig.Callback or function() end
			BindConfig.Flag = BindConfig.Flag or nil
			BindConfig.Save = BindConfig.Save or false

			local Bind = {Value = BindConfig.Default, Binding = false, Type = "Bind", Save = BindConfig.Save}
			local Holding = false

			local BindBox = AddThemeObject(Create("Frame", nil, {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(1, -12, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Library.Themes.Default.Main
			}, {
				AddThemeObject(Create("TextLabel", {
					Text = BindConfig.Default.Name or BindConfig.Default,
					Size = UDim2.new(1, 0, 1, 0),
					Font = Library.Font,
					TextSize = 14,
					TextColor3 = Library.Themes.Default.Text,
					TextXAlignment = Enum.TextXAlignment.Center,
					BackgroundTransparency = 1,
					Name = "Value"
				}), "Text"),
				MakeElement("Stroke"),
				MakeElement("Corner", 0, 4)
			}), "Main")

			local BindFrame = AddThemeObject(Create("Frame", Container, {
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundColor3 = Library.Themes.Default.Second,
				BackgroundTransparency = 0.7
			}, {
				AddThemeObject(Create("TextLabel", {
					Text = BindConfig.Name,
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Library.Font,
					TextSize = 15,
					TextColor3 = Library.Themes.Default.Text,
					BackgroundTransparency = 1,
					Name = "Content"
				}), "Text"),
				MakeElement("Stroke"),
				MakeElement("Corner", 0, 5),
				BindBox,
				Create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""})
			}), "Second")

			local Click = BindFrame.TextButton
			AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
				TweenService:Create(BindBox, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(0, BindBox.Value.TextBounds.X + 16, 0, 24)}):Play()
			end)

			AddConnection(Click.InputEnded, function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					if not Bind.Binding then
						Bind.Binding = true
						BindBox.Value.Text = "..."
					end
				end
			end)

			AddConnection(UserInputService.InputBegan, function(Input)
				if UserInputService:GetFocusedTextBox() then return end
				if Bind.Binding then
					local Key
					if not table.find({Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right, Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape}, Input.KeyCode) then
						Key = Input.KeyCode
					elseif table.find({Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3, Enum.UserInputType.Touch}, Input.UserInputType) then
						Key = Input.UserInputType
					end
					Bind:Set(Key or Bind.Value)
				elseif (Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value) then
					if BindConfig.Hold then
						Holding = true
						BindConfig.Callback(Holding)
					else
						BindConfig.Callback()
					end
				end
			end)

			AddConnection(UserInputService.InputEnded, function(Input)
				if Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value then
					if BindConfig.Hold and Holding then
						Holding = false
						BindConfig.Callback(Holding)
					end
				end
			end)

			function Bind:Set(Key)
				Bind.Binding = false
				Bind.Value = Key or Bind.Value
				BindBox.Value.Text = Bind.Value.Name or Bind.Value
				if BindConfig.Save then
					SaveCfg(game.GameId)
				end
			end

			Bind:Set(BindConfig.Default)
			if BindConfig.Flag then
				Library.Flags[BindConfig.Flag] = Bind
			end
			return Bind
		end

		function ElementFunction:AddTextbox(TextboxConfig)
			TextboxConfig = TextboxConfig or {}
			TextboxConfig.Name = TextboxConfig.Name or "Textbox"
			TextboxConfig.Default = TextboxConfig.Default or ""
			TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
			TextboxConfig.Callback = TextboxConfig.Callback or function() end

			local TextboxActual = AddThemeObject(Create("TextBox", nil, {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				TextColor3 = Library.Themes.Default.Text,
				PlaceholderColor3 = Library.Themes.Default.TextDark,
				PlaceholderText = "Input",
				Font = Library.Font,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Center,
				ClearTextOnFocus = false
			}), "Text")

			local TextContainer = AddThemeObject(Create("Frame", nil, {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(1, -12, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Library.Themes.Default.Main
			}, {
				MakeElement("Stroke"),
				MakeElement("Corner", 0, 4),
				TextboxActual
			}), "Main")

			local TextboxFrame = AddThemeObject(Create("Frame", Container, {
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundColor3 = Library.Themes.Default.Second,
				BackgroundTransparency = 0.7
			}, {
				AddThemeObject(Create("TextLabel", {
					Text = TextboxConfig.Name,
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Library.Font,
					TextSize = 15,
					TextColor3 = Library.Themes.Default.Text,
					BackgroundTransparency = 1,
					Name = "Content"
				}), "Text"),
				MakeElement("Stroke"),
				MakeElement("Corner", 0, 5),
				TextContainer,
				Create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""})
			}), "Second")

			AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), function()
				TweenService:Create(TextContainer, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {Size = UDim2.new(0, TextboxActual.TextBounds.X + 16, 0, 24)}):Play()
			end)

			AddConnection(TextboxActual.FocusLost, function()
				TextboxConfig.Callback(TextboxActual.Text)
				if TextboxConfig.TextDisappear then
					TextboxActual.Text = ""
				end
			end)

			TextboxActual.Text = TextboxConfig.Default
			local Click = TextboxFrame.TextButton
			AddConnection(Click.MouseEnter, function()
				TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = Color3.fromRGB(Library.Themes.Default.Second.R * 255 + 3, Library.Themes.Default.Second.G * 255 + 3, Library.Themes.Default.Second.B * 255 + 3)}):Play()
			end)
			AddConnection(Click.MouseLeave, function()
				TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = Library.Themes.Default.Second}):Play()
			end)
			AddConnection(Click.MouseButton1Up, function()
				TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = Library.Themes.Default.Second}):Play()
				TextboxActual:CaptureFocus()
			end)

			return TextboxActual
		end

		function ElementFunction:AddColorpicker(ColorpickerConfig)
			ColorpickerConfig = ColorpickerConfig or {}
			ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
			ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255, 255, 255)
			ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
			ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil
			ColorpickerConfig.Save = ColorpickerConfig.Save or false

			local ColorH, ColorS, ColorV = Color3.toHSV(ColorpickerConfig.Default)
			local Colorpicker = {Value = ColorpickerConfig.Default, Toggled = false, Type = "Colorpicker", Save = ColorpickerConfig.Save}

			local Color = Create("ImageLabel", nil, {
				Size = UDim2.new(1, -25, 1, 0),
				Visible = false,
				Image = "rbxassetid://4155801252",
				BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
				Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(ColorS, 0, 1 - ColorV, 0),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})
			})

			local Hue = Create("Frame", nil, {
				Size = UDim2.new(0, 20, 1, 0),
				Position = UDim2.new(1, -20, 0, 0),
				Visible = false
			}, {
				Create("UIGradient", {
					Rotation = 270,
					Color = ColorSequence.new{
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 4)),
						ColorSequenceKeypoint.new(0.2, Color3.fromRGB(234, 255, 0)),
						ColorSequenceKeypoint.new(0.4, Color3.fromRGB(21, 255, 0)),
						ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 255)),
						ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 17, 255)),
						ColorSequenceKeypoint.new(0.9, Color3.fromRGB(255, 0, 251)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 4))
					}
				}),
				Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
				Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0.5, 0, 1 - ColorH, 0),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})
			})

			local ColorpickerContainer = Create("Frame", nil, {
				Position = UDim2.new(0, 0, 0, 32),
				Size = UDim2.new(1, 0, 1, -32),
				BackgroundTransparency = 1,
				ClipsDescendants = true
			}, {
				Hue,
				Color,
				Create("UIPadding", {
					PaddingLeft = UDim.new(0, 35),
					PaddingRight = UDim.new(0, 35),
					PaddingBottom = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 17)
				})
			})

			local ColorpickerBox = AddThemeObject(Create("Frame", nil, {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(1, -12, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = ColorpickerConfig.Default
			}, {
				MakeElement("Stroke"),
				MakeElement("Corner", 0, 4)
			}), "Main")

			local ColorpickerFrame = AddThemeObject(Create("Frame", Container, {
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundColor3 = Library.Themes.Default.Second,
				BackgroundTransparency = 0.7
			}, {
				Create("Frame", {
					Size = UDim2.new(1, 0, 0, 38),
					ClipsDescendants = true,
					Name = "F"
				}, {
					AddThemeObject(Create("TextLabel", {
						Text = ColorpickerConfig.Name,
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Library.Font,
						TextSize = 15,
						TextColor3 = Library.Themes.Default.Text,
						BackgroundTransparency = 1,
						Name = "Content"
					}), "Text"),
					ColorpickerBox,
					Create("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""}),
					Create("Frame", {
						Size = UDim2.new(1, 0, 0, 1),
						Position = UDim2.new(0, 0, 1, -1),
						BackgroundColor3 = Library.Themes.Default.Stroke,
						Name = "Line",
						Visible = false
					})
				}),
				ColorpickerContainer,
				MakeElement("Stroke"),
				MakeElement("Corner", 0, 5)
			}), "Second")

			local Click = ColorpickerFrame.F.TextButton
			AddConnection(Click.MouseButton1Click, function()
				Colorpicker.Toggled = not Colorpicker.Toggled
				TweenService:Create(ColorpickerFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = Colorpicker.Toggled and UDim2.new(1, 0, 0, 148) or UDim2.new(1, 0, 0, 38)}):Play()
				Color.Visible = Colorpicker.Toggled
				Hue.Visible = Colorpicker.Toggled
				ColorpickerFrame.F.Line.Visible = Colorpicker.Toggled
			end)

			local ColorInput, HueInput
			local function UpdateColorPicker()
				ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
				Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
				Colorpicker:Set(ColorpickerBox.BackgroundColor3)
				if ColorpickerConfig.Save then
					SaveCfg(game.GameId)
				end
			end

			AddConnection(Color.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if ColorInput then ColorInput:Disconnect() end
					ColorInput = AddConnection(RunService.RenderStepped, function()
						local ColorX = math.clamp((Mouse.X - Color.AbsolutePosition.X) / Color.AbsoluteSize.X, 0, 1)
						local ColorY = math.clamp((Mouse.Y - Color.AbsolutePosition.Y) / Color.AbsoluteSize.Y, 0, 1)
						Color.Children[2].Position = UDim2.new(ColorX, 0, ColorY, 0)
						ColorS = ColorX
						ColorV = 1 - ColorY
						UpdateColorPicker()
					end)
				end
			end)

			AddConnection(Color.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch and ColorInput then
					ColorInput:Disconnect()
				end
			end)

			AddConnection(Hue.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if HueInput then HueInput:Disconnect() end
					HueInput = AddConnection(RunService.RenderStepped, function()
						local HueY = math.clamp((Mouse.Y - Hue.AbsolutePosition.Y) / Hue.AbsoluteSize.Y, 0, 1)
						Hue.Children[3].Position = UDim2.new(0.5, 0, HueY, 0)
						ColorH = 1 - HueY
						UpdateColorPicker()
					end)
				end
			end)

			AddConnection(Hue.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch and HueInput then
					HueInput:Disconnect()
				end
			end)

			function Colorpicker:Set(Value)
				Colorpicker.Value = Value
				ColorpickerBox.BackgroundColor3 = Value
				ColorpickerConfig.Callback(Value)
			end

			Colorpicker:Set(ColorpickerConfig.Default)
			if ColorpickerConfig.Flag then
				Library.Flags[ColorpickerConfig.Flag] = Colorpicker
			end
			return Colorpicker
		end

		return ElementFunction
	end

	local FirstTab = true
	local LibraryTab = TabFunction:MakeTab({
		Name = "Library",
		Icon = "rbxassetid://18898147855",
		PremiumOnly = false
	})

	LibraryTab:AddToggle({
		Name = "Enable Transparency",
		Default = false,
		Color = Library.Themes.Default.Accent,
		Callback = function(value)
			Library:SetUITransparency(value)
		end
	})

	return TabFunction
end

function Library:Init()
	if Library.SaveCfg then
		pcall(function()
			if isfile(Library.Folder .. "/" .. game.GameId .. ".txt") then
				LoadCfg(readfile(Library.Folder .. "/" .. game.GameId .. ".txt"))
				Library:MakeNotification({
					Name = "Configuration",
					Content = "Loaded configuration for game " .. game.GameId,
					Time = 5
				})
			end
		end)
	end
end

function Library:Destroy()
	Container:Destroy()
end

return Library
