--[[
	Ecstasy UI Library
	Premium Glass UI Library for Roblox
	Made for modern script execution
]]

--// Services & Setup
local GetService = game.GetService
local Connect = game.Loaded.Connect or function(signal, func) return signal:Connect(func) end
local Wait = game.Loaded.Wait or function(signal) return signal:Wait() end
local Clone = game.Clone or function(obj) return obj:Clone() end
local Destroy = game.Destroy or function(obj) return obj:Destroy() end

if not game:IsLoaded() then
	game.Loaded:Wait()
end

--// Configuration
local Config = {
	Title = "Ecstasy UI",
	Version = "2.0.1",
	Build = "Release",
	Username = "User",
	UserId = "12345678",
	Avatar = "https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?w=100&h=100&fit=crop&crop=face",
	Ping = "42ms",
	Premium = false,
	Executor = "Synapse X",
	ExecutorStatus = "Verified as Supported",
	DiscordServer = "https://discord.gg/ecstasyui",
	MainScript = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/ecstasy/ui/main.lua"))()',
	Keybind = Enum.KeyCode.LeftControl,
	Theme = "Dark"
}

--// Theme System
local Theme = {
	-- Glass Colors
	Primary = Color3.fromRGB(15, 15, 25),
	Secondary = Color3.fromRGB(20, 20, 35),
	Accent = Color3.fromRGB(100, 80, 255),
	AccentHover = Color3.fromRGB(120, 100, 255),
	
	-- Text Colors
	TextPrimary = Color3.fromRGB(255, 255, 255),
	TextSecondary = Color3.fromRGB(180, 180, 200),
	TextMuted = Color3.fromRGB(120, 120, 140),
	
	-- Status Colors
	Success = Color3.fromRGB(50, 200, 100),
	Warning = Color3.fromRGB(255, 200, 50),
	Error = Color3.fromRGB(255, 100, 100),
	
	-- Glass Effects
	GlassBackground = Color3.fromRGB(255, 255, 255),
	GlassTransparency = 0.95,
	BorderColor = Color3.fromRGB(255, 255, 255),
	BorderTransparency = 0.8,
	
	-- Gradients
	PrimaryGradient = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 80, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255))
	},
	SecondaryGradient = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 200, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 220, 150))
	}
}

--// Services
local Players = GetService(game, "Players")
local TweenService = GetService(game, "TweenService")
local UserInputService = GetService(game, "UserInputService")
local RunService = GetService(game, "RunService")
local CoreGui = GetService(game, "CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// Utility Functions
local function Tween(object, duration, properties, easingStyle, easingDirection)
	local info = TweenInfo.new(
		duration or 0.3,
		easingStyle or Enum.EasingStyle.Quart,
		easingDirection or Enum.EasingDirection.Out
	)
	return TweenService:Create(object, info, properties):Play()
end

local function CreateGlassEffect(frame)
	-- Background with transparency
	frame.BackgroundColor3 = Theme.GlassBackground
	frame.BackgroundTransparency = Theme.GlassTransparency
	
	-- Border
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.BorderColor
	stroke.Transparency = Theme.BorderTransparency
	stroke.Thickness = 1
	stroke.Parent = frame
	
	-- Corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	
	return frame
end

local function CreateGradient(frame, colorSequence, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = colorSequence
	gradient.Rotation = rotation or 0
	gradient.Parent = frame
	return gradient
end

local function CreateHoverEffect(button, hoverColor, normalColor)
	local isHovering = false
	
	button.MouseEnter:Connect(function()
		if not isHovering then
			isHovering = true
			Tween(button, 0.2, {BackgroundColor3 = hoverColor})
		end
	end)
	
	button.MouseLeave:Connect(function()
		if isHovering then
			isHovering = false
			Tween(button, 0.2, {BackgroundColor3 = normalColor})
		end
	end)
end

local function MakeDraggable(frame)
	local dragging = false
	local dragInput, mousePos, framePos
	
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			mousePos = input.Position
			framePos = frame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			frame.Position = UDim2.new(
				framePos.X.Scale,
				framePos.X.Offset + delta.X,
				framePos.Y.Scale,
				framePos.Y.Offset + delta.Y
			)
		end
	end)
end

--// Main Library
local EcstasyUI = {}
local CurrentWindow = nil

function EcstasyUI:CreateWindow(settings)
	settings = settings or {}
	
	-- Update config with user settings
	for key, value in pairs(settings) do
		if Config[key] ~= nil then
			Config[key] = value
		end
	end
	
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EcstasyUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Try to parent to CoreGui, fallback to PlayerGui
	local success = pcall(function()
		screenGui.Parent = CoreGui
	end)
	if not success then
		screenGui.Parent = LocalPlayer.PlayerGui
	end
	
	-- Create Home Starter
	local homeStarter = EcstasyUI:CreateHomeStarter(screenGui)
	
	-- Window object
	local Window = {
		ScreenGui = screenGui,
		HomeStarter = homeStarter,
		MainUI = nil,
		Tabs = {},
		CurrentTab = nil
	}
	
	CurrentWindow = Window
	return Window
end

function EcstasyUI:CreateHomeStarter(parent)
	-- Main Frame
	local homeFrame = Instance.new("Frame")
	homeFrame.Name = "HomeStarter"
	homeFrame.Size = UDim2.new(0, 800, 0, 600)
	homeFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
	homeFrame.BackgroundColor3 = Theme.Primary
	homeFrame.BackgroundTransparency = 0.1
	homeFrame.BorderSizePixel = 0
	homeFrame.Parent = parent
	
	CreateGlassEffect(homeFrame)
	MakeDraggable(homeFrame)
	
	-- Background Gradient
	CreateGradient(homeFrame, ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 30, 60))
	}, 45)
	
	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 80)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundTransparency = 1
	header.Parent = homeFrame
	
	-- Home Icon and Title
	local homeIcon = Instance.new("ImageLabel")
	homeIcon.Name = "HomeIcon"
	homeIcon.Size = UDim2.new(0, 32, 0, 32)
	homeIcon.Position = UDim2.new(0, 30, 0, 24)
	homeIcon.BackgroundTransparency = 1
	homeIcon.Image = "rbxassetid://6031075938" -- Home icon
	homeIcon.ImageColor3 = Theme.TextSecondary
	homeIcon.Parent = header
	
	local homeTitle = Instance.new("TextLabel")
	homeTitle.Name = "HomeTitle"
	homeTitle.Size = UDim2.new(0, 100, 0, 32)
	homeTitle.Position = UDim2.new(0, 70, 0, 24)
	homeTitle.BackgroundTransparency = 1
	homeTitle.Text = "Home"
	homeTitle.TextColor3 = Theme.TextSecondary
	homeTitle.TextSize = 18
	homeTitle.TextXAlignment = Enum.TextXAlignment.Left
	homeTitle.Font = Enum.Font.GothamMedium
	homeTitle.Parent = header
	
	-- Time Display
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(0, 150, 0, 32)
	timeLabel.Position = UDim2.new(1, -180, 0, 24)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = os.date("%I:%M %p")
	timeLabel.TextColor3 = Theme.TextMuted
	timeLabel.TextSize = 16
	timeLabel.TextXAlignment = Enum.TextXAlignment.Right
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.Parent = header
	
	-- Update time every second
	spawn(function()
		while homeFrame.Parent do
			timeLabel.Text = os.date("%I:%M %p")
			wait(1)
		end
	end)
	
	-- Main Content Area
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.Size = UDim2.new(1, -60, 1, -140)
	contentFrame.Position = UDim2.new(0, 30, 0, 100)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = homeFrame
	
	-- Brand Card (Top)
	local brandCard = Instance.new("Frame")
	brandCard.Name = "BrandCard"
	brandCard.Size = UDim2.new(1, 0, 0, 120)
	brandCard.Position = UDim2.new(0, 0, 0, 0)
	brandCard.BackgroundColor3 = Theme.GlassBackground
	brandCard.BackgroundTransparency = Theme.GlassTransparency
	brandCard.BorderSizePixel = 0
	brandCard.Parent = contentFrame
	
	CreateGlassEffect(brandCard)
	
	-- Brand Title
	local brandTitle = Instance.new("TextLabel")
	brandTitle.Name = "BrandTitle"
	brandTitle.Size = UDim2.new(0, 300, 0, 40)
	brandTitle.Position = UDim2.new(0, 20, 0, 20)
	brandTitle.BackgroundTransparency = 1
	brandTitle.Text = Config.Title
	brandTitle.TextColor3 = Theme.TextPrimary
	brandTitle.TextSize = 28
	brandTitle.TextXAlignment = Enum.TextXAlignment.Left
	brandTitle.Font = Enum.Font.GothamBold
	brandTitle.Parent = brandCard
	
	-- Create gradient text effect
	CreateGradient(brandTitle, Theme.PrimaryGradient, 0)
	
	-- Star Icon
	local starIcon = Instance.new("ImageLabel")
	starIcon.Name = "StarIcon"
	starIcon.Size = UDim2.new(0, 24, 0, 24)
	starIcon.Position = UDim2.new(0, 320, 0, 28)
	starIcon.BackgroundTransparency = 1
	starIcon.Image = "rbxassetid://6031068421" -- Star icon
	starIcon.ImageColor3 = Color3.fromRGB(255, 215, 0)
	starIcon.Parent = brandCard
	
	-- Version Info
	local versionLabel = Instance.new("TextLabel")
	versionLabel.Name = "VersionLabel"
	versionLabel.Size = UDim2.new(0, 150, 0, 20)
	versionLabel.Position = UDim2.new(1, -170, 0, 20)
	versionLabel.BackgroundTransparency = 1
	versionLabel.Text = "Ver: " .. Config.Version
	versionLabel.TextColor3 = Theme.TextSecondary
	versionLabel.TextSize = 14
	versionLabel.TextXAlignment = Enum.TextXAlignment.Right
	versionLabel.Font = Enum.Font.Gotham
	versionLabel.Parent = brandCard
	
	local buildLabel = Instance.new("TextLabel")
	buildLabel.Name = "BuildLabel"
	buildLabel.Size = UDim2.new(0, 150, 0, 20)
	buildLabel.Position = UDim2.new(1, -170, 0, 40)
	buildLabel.BackgroundTransparency = 1
	buildLabel.Text = "Build: " .. Config.Build
	buildLabel.TextColor3 = Theme.TextSecondary
	buildLabel.TextSize = 14
	buildLabel.TextXAlignment = Enum.TextXAlignment.Right
	buildLabel.Font = Enum.Font.Gotham
	buildLabel.Parent = brandCard
	
	-- Stats Container
	local statsContainer = Instance.new("Frame")
	statsContainer.Name = "StatsContainer"
	statsContainer.Size = UDim2.new(1, -40, 0, 40)
	statsContainer.Position = UDim2.new(0, 20, 0, 70)
	statsContainer.BackgroundTransparency = 1
	statsContainer.Parent = brandCard
	
	-- Ping Stat
	local pingCard = Instance.new("Frame")
	pingCard.Name = "PingCard"
	pingCard.Size = UDim2.new(0.5, -10, 1, 0)
	pingCard.Position = UDim2.new(0, 0, 0, 0)
	pingCard.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	pingCard.BackgroundTransparency = 0.7
	pingCard.BorderSizePixel = 0
	pingCard.Parent = statsContainer
	
	CreateGlassEffect(pingCard)
	
	local pingLabel = Instance.new("TextLabel")
	pingLabel.Name = "PingLabel"
	pingLabel.Size = UDim2.new(1, 0, 0.5, 0)
	pingLabel.Position = UDim2.new(0, 0, 0, 0)
	pingLabel.BackgroundTransparency = 1
	pingLabel.Text = "Ping"
	pingLabel.TextColor3 = Theme.TextMuted
	pingLabel.TextSize = 12
	pingLabel.Font = Enum.Font.Gotham
	pingLabel.Parent = pingCard
	
	local pingValue = Instance.new("TextLabel")
	pingValue.Name = "PingValue"
	pingValue.Size = UDim2.new(1, 0, 0.5, 0)
	pingValue.Position = UDim2.new(0, 0, 0.5, 0)
	pingValue.BackgroundTransparency = 1
	pingValue.Text = Config.Ping
	pingValue.TextColor3 = Theme.TextPrimary
	pingValue.TextSize = 14
	pingValue.Font = Enum.Font.GothamMedium
	pingValue.Parent = pingCard
	
	-- Premium Stat (removed as requested)
	-- User Profile Card
	local userCard = Instance.new("Frame")
	userCard.Name = "UserCard"
	userCard.Size = UDim2.new(0.48, 0, 0, 160)
	userCard.Position = UDim2.new(0, 0, 0, 140)
	userCard.BackgroundColor3 = Theme.GlassBackground
	userCard.BackgroundTransparency = Theme.GlassTransparency
	userCard.BorderSizePixel = 0
	userCard.Parent = contentFrame
	
	CreateGlassEffect(userCard)
	
	-- User Avatar
	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(0, 60, 0, 60)
	avatar.Position = UDim2.new(0, 20, 0, 20)
	avatar.BackgroundTransparency = 1
	avatar.Image = Config.Avatar
	avatar.Parent = userCard
	
	-- Avatar corner
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0.5, 0)
	avatarCorner.Parent = avatar
	
	-- Avatar border
	local avatarStroke = Instance.new("UIStroke")
	avatarStroke.Color = Theme.Accent
	avatarStroke.Thickness = 2
	avatarStroke.Transparency = 0.5
	avatarStroke.Parent = avatar
	
	-- Online indicator
	local onlineIndicator = Instance.new("Frame")
	onlineIndicator.Name = "OnlineIndicator"
	onlineIndicator.Size = UDim2.new(0, 16, 0, 16)
	onlineIndicator.Position = UDim2.new(1, -8, 1, -8)
	onlineIndicator.BackgroundColor3 = Theme.Success
	onlineIndicator.BorderSizePixel = 0
	onlineIndicator.Parent = avatar
	
	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(0.5, 0)
	indicatorCorner.Parent = onlineIndicator
	
	-- Username
	local username = Instance.new("TextLabel")
	username.Name = "Username"
	username.Size = UDim2.new(1, -100, 0, 25)
	username.Position = UDim2.new(0, 90, 0, 20)
	username.BackgroundTransparency = 1
	username.Text = Config.Username
	username.TextColor3 = Theme.TextPrimary
	username.TextSize = 16
	username.TextXAlignment = Enum.TextXAlignment.Left
	username.Font = Enum.Font.GothamMedium
	username.Parent = userCard
	
	local usernameSubtext = Instance.new("TextLabel")
	usernameSubtext.Name = "UsernameSubtext"
	usernameSubtext.Size = UDim2.new(1, -100, 0, 20)
	usernameSubtext.Position = UDim2.new(0, 90, 0, 45)
	usernameSubtext.BackgroundTransparency = 1
	usernameSubtext.Text = "UserName"
	usernameSubtext.TextColor3 = Theme.TextMuted
	usernameSubtext.TextSize = 12
	usernameSubtext.Font = Enum.Font.Gotham
	usernameSubtext.Parent = userCard
	
	-- User ID Card
	local idCard = Instance.new("Frame")
	idCard.Name = "IDCard"
	idCard.Size = UDim2.new(1, -40, 0, 50)
	idCard.Position = UDim2.new(0, 20, 0, 90)
	idCard.BackgroundColor3 = Color3.fromRGB(0, 150, 150)
	idCard.BackgroundTransparency = 0.8
	idCard.BorderSizePixel = 0
	idCard.Parent = userCard
	
	CreateGlassEffect(idCard)
	
	local idLabel = Instance.new("TextLabel")
	idLabel.Name = "IDLabel"
	idLabel.Size = UDim2.new(1, 0, 0.4, 0)
	idLabel.Position = UDim2.new(0, 0, 0, 5)
	idLabel.BackgroundTransparency = 1
	idLabel.Text = "ID"
	idLabel.TextColor3 = Theme.TextMuted
	idLabel.TextSize = 10
	idLabel.Font = Enum.Font.Gotham
	idLabel.Parent = idCard
	
	local idValue = Instance.new("TextLabel")
	idValue.Name = "IDValue"
	idValue.Size = UDim2.new(1, 0, 0.6, 0)
	idValue.Position = UDim2.new(0, 0, 0.4, 0)
	idValue.BackgroundTransparency = 1
	idValue.Text = Config.UserId
	idValue.TextColor3 = Theme.TextPrimary
	idValue.TextSize = 12
	idValue.Font = Enum.Font.GothamMedium
	idValue.Parent = idCard
	
	-- Services Container
	local servicesContainer = Instance.new("Frame")
	servicesContainer.Name = "ServicesContainer"
	servicesContainer.Size = UDim2.new(0.48, 0, 0, 160)
	servicesContainer.Position = UDim2.new(0.52, 0, 0, 140)
	servicesContainer.BackgroundTransparency = 1
	servicesContainer.Parent = contentFrame
	
	-- Executor Card
	local executorCard = Instance.new("Frame")
	executorCard.Name = "ExecutorCard"
	executorCard.Size = UDim2.new(1, 0, 0, 70)
	executorCard.Position = UDim2.new(0, 0, 0, 0)
	executorCard.BackgroundColor3 = Theme.Success
	executorCard.BackgroundTransparency = 0.8
	executorCard.BorderSizePixel = 0
	executorCard.Parent = servicesContainer
	
	CreateGlassEffect(executorCard)
	CreateGradient(executorCard, Theme.SecondaryGradient, 45)
	
	local executorName = Instance.new("TextLabel")
	executorName.Name = "ExecutorName"
	executorName.Size = UDim2.new(1, -50, 0, 25)
	executorName.Position = UDim2.new(0, 20, 0, 15)
	executorName.BackgroundTransparency = 1
	executorName.Text = Config.Executor
	executorName.TextColor3 = Theme.TextPrimary
	executorName.TextSize = 16
	executorName.TextXAlignment = Enum.TextXAlignment.Left
	executorName.Font = Enum.Font.GothamMedium
	executorName.Parent = executorCard
	
	local executorStatus = Instance.new("TextLabel")
	executorStatus.Name = "ExecutorStatus"
	executorStatus.Size = UDim2.new(1, -50, 0, 20)
	executorStatus.Position = UDim2.new(0, 20, 0, 40)
	executorStatus.BackgroundTransparency = 1
	executorStatus.Text = Config.ExecutorStatus
	executorStatus.TextColor3 = Color3.fromRGB(200, 255, 200)
	executorStatus.TextSize = 12
	executorStatus.TextXAlignment = Enum.TextXAlignment.Left
	executorStatus.Font = Enum.Font.Gotham
	executorStatus.Parent = executorCard
	
	-- Shield Icon
	local shieldIcon = Instance.new("ImageLabel")
	shieldIcon.Name = "ShieldIcon"
	shieldIcon.Size = UDim2.new(0, 24, 0, 24)
	shieldIcon.Position = UDim2.new(1, -40, 0, 23)
	shieldIcon.BackgroundTransparency = 1
	shieldIcon.Image = "rbxassetid://6031068421" -- Shield icon
	shieldIcon.ImageColor3 = Color3.fromRGB(200, 255, 200)
	shieldIcon.Parent = executorCard
	
	-- Discord Card
	local discordCard = Instance.new("TextButton")
	discordCard.Name = "DiscordCard"
	discordCard.Size = UDim2.new(1, 0, 0, 70)
	discordCard.Position = UDim2.new(0, 0, 0, 80)
	discordCard.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	discordCard.BackgroundTransparency = 0.8
	discordCard.BorderSizePixel = 0
	discordCard.Text = ""
	discordCard.Parent = servicesContainer
	
	CreateGlassEffect(discordCard)
	CreateHoverEffect(discordCard, Color3.fromRGB(108, 121, 255), Color3.fromRGB(88, 101, 242))
	
	local discordTitle = Instance.new("TextLabel")
	discordTitle.Name = "DiscordTitle"
	discordTitle.Size = UDim2.new(1, -50, 0, 25)
	discordTitle.Position = UDim2.new(0, 20, 0, 15)
	discordTitle.BackgroundTransparency = 1
	discordTitle.Text = "Discord"
	discordTitle.TextColor3 = Theme.TextPrimary
	discordTitle.TextSize = 16
	discordTitle.TextXAlignment = Enum.TextXAlignment.Left
	discordTitle.Font = Enum.Font.GothamMedium
	discordTitle.Parent = discordCard
	
	local discordSubtext = Instance.new("TextLabel")
	discordSubtext.Name = "DiscordSubtext"
	discordSubtext.Size = UDim2.new(1, -50, 0, 20)
	discordSubtext.Position = UDim2.new(0, 20, 0, 40)
	discordSubtext.BackgroundTransparency = 1
	discordSubtext.Text = "Click To Copy Link"
	discordSubtext.TextColor3 = Color3.fromRGB(150, 180, 255)
	discordSubtext.TextSize = 12
	discordSubtext.TextXAlignment = Enum.TextXAlignment.Left
	discordSubtext.Font = Enum.Font.Gotham
	discordSubtext.Parent = discordCard
	
	-- Copy Icon
	local copyIcon = Instance.new("ImageLabel")
	copyIcon.Name = "CopyIcon"
	copyIcon.Size = UDim2.new(0, 20, 0, 20)
	copyIcon.Position = UDim2.new(1, -35, 0, 25)
	copyIcon.BackgroundTransparency = 1
	copyIcon.Image = "rbxassetid://6031068421" -- Copy icon
	copyIcon.ImageColor3 = Color3.fromRGB(150, 180, 255)
	copyIcon.Parent = discordCard
	
	-- Discord click handler
	discordCard.MouseButton1Click:Connect(function()
		-- Copy to clipboard (if supported)
		if setclipboard then
			setclipboard(Config.DiscordServer)
			discordSubtext.Text = "Copied!"
			wait(2)
			discordSubtext.Text = "Click To Copy Link"
		end
	end)
	
	-- Action Buttons
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(1, 0, 0, 60)
	buttonContainer.Position = UDim2.new(0, 0, 1, -80)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = contentFrame
	
	-- Copy Script Button
	local copyScriptBtn = Instance.new("TextButton")
	copyScriptBtn.Name = "CopyScriptButton"
	copyScriptBtn.Size = UDim2.new(0.48, 0, 1, 0)
	copyScriptBtn.Position = UDim2.new(0, 0, 0, 0)
	copyScriptBtn.BackgroundColor3 = Theme.Accent
	copyScriptBtn.BackgroundTransparency = 0.2
	copyScriptBtn.BorderSizePixel = 0
	copyScriptBtn.Text = "Copy Script"
	copyScriptBtn.TextColor3 = Theme.TextPrimary
	copyScriptBtn.TextSize = 16
	copyScriptBtn.Font = Enum.Font.GothamMedium
	copyScriptBtn.Parent = buttonContainer
	
	CreateGlassEffect(copyScriptBtn)
	CreateGradient(copyScriptBtn, Theme.PrimaryGradient, 45)
	CreateHoverEffect(copyScriptBtn, Theme.AccentHover, Theme.Accent)
	
	-- Load Script Button
	local loadScriptBtn = Instance.new("TextButton")
	loadScriptBtn.Name = "LoadScriptButton"
	loadScriptBtn.Size = UDim2.new(0.48, 0, 1, 0)
	loadScriptBtn.Position = UDim2.new(0.52, 0, 0, 0)
	loadScriptBtn.BackgroundColor3 = Theme.Success
	loadScriptBtn.BackgroundTransparency = 0.2
	loadScriptBtn.BorderSizePixel = 0
	loadScriptBtn.Text = "Load Script"
	loadScriptBtn.TextColor3 = Theme.TextPrimary
	loadScriptBtn.TextSize = 16
	loadScriptBtn.Font = Enum.Font.GothamMedium
	loadScriptBtn.Parent = buttonContainer
	
	CreateGlassEffect(loadScriptBtn)
	CreateGradient(loadScriptBtn, Theme.SecondaryGradient, 45)
	CreateHoverEffect(loadScriptBtn, Color3.fromRGB(70, 220, 120), Theme.Success)
	
	-- Button click handlers
	copyScriptBtn.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(Config.MainScript)
			copyScriptBtn.Text = "Copied!"
			wait(2)
			copyScriptBtn.Text = "Copy Script"
		end
	end)
	
	loadScriptBtn.MouseButton1Click:Connect(function()
		-- Hide home starter and show main UI
		homeFrame.Visible = false
		if CurrentWindow then
			CurrentWindow.MainUI = EcstasyUI:CreateMainUI(parent)
		end
	end)
	
	-- Settings button (top right)
	local settingsBtn = Instance.new("TextButton")
	settingsBtn.Name = "SettingsButton"
	settingsBtn.Size = UDim2.new(0, 40, 0, 40)
	settingsBtn.Position = UDim2.new(1, -50, 0, 20)
	settingsBtn.BackgroundColor3 = Theme.GlassBackground
	settingsBtn.BackgroundTransparency = Theme.GlassTransparency
	settingsBtn.BorderSizePixel = 0
	settingsBtn.Text = "⚙️"
	settingsBtn.TextColor3 = Theme.TextSecondary
	settingsBtn.TextSize = 20
	settingsBtn.Font = Enum.Font.Gotham
	settingsBtn.Parent = header
	
	CreateGlassEffect(settingsBtn)
	CreateHoverEffect(settingsBtn, Color3.fromRGB(255, 255, 255), Theme.GlassBackground)
	
	-- Settings click handler
	settingsBtn.MouseButton1Click:Connect(function()
		EcstasyUI:ShowConfigModal(parent)
	end)
	
	-- Entrance animation
	homeFrame.Size = UDim2.new(0, 0, 0, 0)
	homeFrame.BackgroundTransparency = 1
	
	Tween(homeFrame, 0.5, {
		Size = UDim2.new(0, 800, 0, 600),
		BackgroundTransparency = 0.1
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	
	return homeFrame
end

function EcstasyUI:CreateMainUI(parent)
	-- Main UI Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainUI"
	mainFrame.Size = UDim2.new(0, 900, 0, 650)
	mainFrame.Position = UDim2.new(0.5, -450, 0.5, -325)
	mainFrame.BackgroundColor3 = Theme.Primary
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = parent
	
	CreateGlassEffect(mainFrame)
	MakeDraggable(mainFrame)
	
	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = Theme.Secondary
	header.BackgroundTransparency = 0.2
	header.BorderSizePixel = 0
	header.Parent = mainFrame
	
	CreateGlassEffect(header)
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0, 200, 1, 0)
	title.Position = UDim2.new(0, 20, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = Config.Title
	title.TextColor3 = Theme.TextPrimary
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.Parent = header
	
	CreateGradient(title, Theme.PrimaryGradient, 0)
	
	-- Version
	local version = Instance.new("TextLabel")
	version.Name = "Version"
	version.Size = UDim2.new(0, 100, 1, 0)
	version.Position = UDim2.new(0, 220, 0, 0)
	version.BackgroundTransparency = 1
	version.Text = "v" .. Config.Version
	version.TextColor3 = Theme.TextMuted
	version.TextSize = 14
	version.TextXAlignment = Enum.TextXAlignment.Left
	version.Font = Enum.Font.Gotham
	version.Parent = header
	
	-- Close Button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -50, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	closeBtn.BackgroundTransparency = 0.3
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Theme.TextPrimary
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = header
	
	CreateGlassEffect(closeBtn)
	CreateHoverEffect(closeBtn, Color3.fromRGB(255, 120, 120), Color3.fromRGB(255, 100, 100))
	
	closeBtn.MouseButton1Click:Connect(function()
		mainFrame:Destroy()
		if CurrentWindow and CurrentWindow.HomeStarter then
			CurrentWindow.HomeStarter.Visible = true
		end
	end)
	
	-- Sidebar
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 200, 1, -60)
	sidebar.Position = UDim2.new(0, 0, 0, 60)
	sidebar.BackgroundColor3 = Theme.Secondary
	sidebar.BackgroundTransparency = 0.3
	sidebar.BorderSizePixel = 0
	sidebar.Parent = mainFrame
	
	CreateGlassEffect(sidebar)
	
	-- Content Area
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -200, 1, -60)
	content.Position = UDim2.new(0, 200, 0, 60)
	content.BackgroundColor3 = Theme.Primary
	content.BackgroundTransparency = 0.5
	content.BorderSizePixel = 0
	content.Parent = mainFrame
	
	CreateGlassEffect(content)
	
	-- Entrance animation
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.BackgroundTransparency = 1
	
	Tween(mainFrame, 0.5, {
		Size = UDim2.new(0, 900, 0, 650),
		BackgroundTransparency = 0.1
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	
	return {
		Frame = mainFrame,
		Sidebar = sidebar,
		Content = content,
		Tabs = {}
	}
end

function EcstasyUI:ShowConfigModal(parent)
	-- Modal Background
	local modal = Instance.new("Frame")
	modal.Name = "ConfigModal"
	modal.Size = UDim2.new(1, 0, 1, 0)
	modal.Position = UDim2.new(0, 0, 0, 0)
	modal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	modal.BackgroundTransparency = 0.5
	modal.BorderSizePixel = 0
	modal.Parent = parent
	
	-- Modal Content
	local modalContent = Instance.new("Frame")
	modalContent.Name = "ModalContent"
	modalContent.Size = UDim2.new(0, 600, 0, 500)
	modalContent.Position = UDim2.new(0.5, -300, 0.5, -250)
	modalContent.BackgroundColor3 = Theme.Primary
	modalContent.BackgroundTransparency = 0.1
	modalContent.BorderSizePixel = 0
	modalContent.Parent = modal
	
	CreateGlassEffect(modalContent)
	
	-- Modal Title
	local modalTitle = Instance.new("TextLabel")
	modalTitle.Name = "ModalTitle"
	modalTitle.Size = UDim2.new(1, -100, 0, 50)
	modalTitle.Position = UDim2.new(0, 20, 0, 20)
	modalTitle.BackgroundTransparency = 1
	modalTitle.Text = "Configuration"
	modalTitle.TextColor3 = Theme.TextPrimary
	modalTitle.TextSize = 24
	modalTitle.TextXAlignment = Enum.TextXAlignment.Left
	modalTitle.Font = Enum.Font.GothamBold
	modalTitle.Parent = modalContent
	
	-- Close Modal Button
	local closeModalBtn = Instance.new("TextButton")
	closeModalBtn.Name = "CloseModalButton"
	closeModalBtn.Size = UDim2.new(0, 40, 0, 40)
	closeModalBtn.Position = UDim2.new(1, -60, 0, 15)
	closeModalBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	closeModalBtn.BackgroundTransparency = 0.3
	closeModalBtn.BorderSizePixel = 0
	closeModalBtn.Text = "✕"
	closeModalBtn.TextColor3 = Theme.TextPrimary
	closeModalBtn.TextSize = 16
	closeModalBtn.Font = Enum.Font.GothamBold
	closeModalBtn.Parent = modalContent
	
	CreateGlassEffect(closeModalBtn)
	CreateHoverEffect(closeModalBtn, Color3.fromRGB(255, 120, 120), Color3.fromRGB(255, 100, 100))
	
	closeModalBtn.MouseButton1Click:Connect(function()
		modal:Destroy()
	end)
	
	-- Configuration options would go here
	-- This is a placeholder for the full configuration system
	
	-- Entrance animation
	modalContent.Size = UDim2.new(0, 0, 0, 0)
	modalContent.BackgroundTransparency = 1
	
	Tween(modalContent, 0.3, {
		Size = UDim2.new(0, 600, 0, 500),
		BackgroundTransparency = 0.1
	}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- Toggle visibility with keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Config.Keybind then
		if CurrentWindow then
			local homeStarter = CurrentWindow.HomeStarter
			local mainUI = CurrentWindow.MainUI
			
			if homeStarter and homeStarter.Visible then
				homeStarter.Visible = false
			elseif mainUI and mainUI.Frame.Visible then
				mainUI.Frame.Visible = false
			elseif homeStarter then
				homeStarter.Visible = true
			end
		end
	end
end)

return EcstasyUI
