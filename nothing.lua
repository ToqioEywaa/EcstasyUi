--[[
    Ecstays UI Library – oriented to "Late" style, cleaner & fixed
    - Transparent, compact, pink-lilac accent
    - Titlebar-only drag (no teleport), smooth open/close zoom
    - Only Minimize & Close (top-right)
    - Notifications bottom-left of screen (outside window)
    - API aligned with original Late-style functions
]]

if not game:IsLoaded() then game.Loaded:Wait() end

--// Services
local GetService = game.GetService
local Players = GetService(game, "Players")
local UIS     = GetService(game, "UserInputService")
local TweenS  = GetService(game, "TweenService")
local RunS    = GetService(game, "RunService")

local LP      = Players.LocalPlayer

--// Utils
local function safeParent(gui)
    local ok = pcall(function() gui.Parent = GetService(game, "CoreGui") end)
    if not ok then gui.Parent = LP:WaitForChild("PlayerGui") end
end

local function Tween(o, t, props, style, dir)
    return TweenS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.Out), props):Play()
end

local function UICornerOf(p, r)
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, r or 10)
    u.Parent = p
    return u
end

local function StrokeOf(p, thk, col, tr)
    local s = Instance.new("UIStroke")
    s.Thickness = thk or 1
    s.Color = col or Color3.fromRGB(96,78,122)
    s.Transparency = tr or .55
    s.Parent = p
    return s
end

local function clamp01(x) return x<0 and 0 or (x>1 and 1 or x) end

--// Theme (Dark + pink-lilac)
local Theme = {
    Primary       = Color3.fromRGB(20,18,24),
    Secondary     = Color3.fromRGB(26,24,32),
    Component     = Color3.fromRGB(32,29,38),
    Interactables = Color3.fromRGB(40,36,48),

    Tab           = Color3.fromRGB(210,210,220),
    Title         = Color3.fromRGB(246,242,252),
    Description   = Color3.fromRGB(192,188,200),

    Shadow        = Color3.fromRGB(0,0,0),
    Outline       = Color3.fromRGB(96,78,122),

    Icon          = Color3.fromRGB(236,226,248),

    Accent        = Color3.fromRGB(206,99,255),
    AccentSoft    = Color3.fromRGB(168,88,232),
    Danger        = Color3.fromRGB(255,92,128),
}

--// Library
local Library = {}
local Setup = {
    Keybind = Enum.KeyCode.LeftControl,
    Transparency = 0.26,
    ThemeMode = "Dark",
    Size = nil,
}

--========================
-- Window Constructor
--========================
function Library:CreateWindow(Settings)
    Settings = Settings or {}
    Setup.Size = Settings.Size or UDim2.fromOffset(640, 420)
    Setup.Transparency = (typeof(Settings.Transparency) == "number" and Settings.Transparency) or 0.26
    if Settings.MinimizeKeybind then Setup.Keybind = Settings.MinimizeKeybind end

    -- ScreenGui
    local SG = Instance.new("ScreenGui")
    SG.Name = "EcstaysUI"
    SG.IgnoreGuiInset = true
    SG.ResetOnSpawn = false
    safeParent(SG)

    -- Notification root (BOTTOM-LEFT OF SCREEN)
    local NotiRoot = Instance.new("Frame")
    NotiRoot.BackgroundTransparency = 1
    NotiRoot.AnchorPoint = Vector2.new(0,1)
    NotiRoot.Position = UDim2.new(0, 12, 1, -12)
    NotiRoot.Size = UDim2.fromOffset(320, 600)
    NotiRoot.ZIndex = 9999
    NotiRoot.Parent = SG
    local NotiList = Instance.new("UIListLayout", NotiRoot)
    NotiList.SortOrder = Enum.SortOrder.LayoutOrder
    NotiList.Padding = UDim.new(0, 8)
    NotiList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    NotiList.VerticalAlignment = Enum.VerticalAlignment.Bottom

    -- Window
    local Window = Instance.new("CanvasGroup")
    Window.Name = "Window"
    Window.Size = Settings.Size or UDim2.fromOffset(640, 420)
    Window.Position = UDim2.fromOffset(120, 120)
    Window.BackgroundColor3 = Theme.Secondary
    Window.GroupTransparency = Setup.Transparency
    Window.Visible = false
    Window.Active = true
    Window.Parent = SG
    UICornerOf(Window, 12)
    local WStroke = StrokeOf(Window, 1, Theme.Outline, .55)

    -- Titlebar
    local Titlebar = Instance.new("Frame")
    Titlebar.Name = "Titlebar"
    Titlebar.BackgroundColor3 = Theme.Primary
    Titlebar.Size = UDim2.new(1, 0, 0, 40)
    Titlebar.Parent = Window
    UICornerOf(Titlebar, 12)

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Font = Enum.Font.GothamSemibold
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.TextSize = 15
    TitleLbl.TextColor3 = Theme.Title
    TitleLbl.Text = (Settings.Title or "Ecstays") .. " • Ecstays"
    TitleLbl.Position = UDim2.fromOffset(14, 0)
    TitleLbl.Size = UDim2.new(1, -130, 1, 0)
    TitleLbl.Parent = Titlebar

    -- Buttons (Minimize, Close)
    local Btns = Instance.new("Frame")
    Btns.BackgroundTransparency = 1
    Btns.Size = UDim2.fromOffset(110, 40)
    Btns.Position = UDim2.new(1, -110, 0, 0)
    Btns.Parent = Titlebar
    local BL = Instance.new("UIListLayout", Btns)
    BL.FillDirection = Enum.FillDirection.Horizontal
    BL.HorizontalAlignment = Enum.HorizontalAlignment.Right
    BL.VerticalAlignment = Enum.VerticalAlignment.Center
    BL.Padding = UDim.new(0, 8)

    local function TopBtn(name, label, col)
        local B = Instance.new("TextButton")
        B.Name = name
        B.AutoButtonColor = false
        B.Size = UDim2.fromOffset(38, 26)
        B.BackgroundColor3 = Theme.Component
        B.Text = label
        B.TextColor3 = col or Theme.Tab
        B.Font = Enum.Font.GothamBold
        B.TextSize = 15
        B.Parent = Btns
        UICornerOf(B, 8)
        local S = StrokeOf(B, 1, Theme.Outline, .65)
        B.MouseEnter:Connect(function()
            Tween(B, .10, {BackgroundColor3 = Theme.Interactables})
            Tween(S, .10, {Transparency = .42, Color = Theme.Accent})
        end)
        B.MouseLeave:Connect(function()
            Tween(B, .12, {BackgroundColor3 = Theme.Component})
            Tween(S, .12, {Transparency = .65, Color = Theme.Outline})
        end)
        return B
    end

    local BtnMin   = TopBtn("Minimize", "–", Theme.Tab)
    local BtnClose = TopBtn("Close",    "×", Theme.Danger)

    -- Drag area (titlebar only)
    local DragHandle = Instance.new("Frame")
    DragHandle.BackgroundTransparency = 1
    DragHandle.Size = UDim2.new(1, -110, 1, 0) -- exclude buttons area
    DragHandle.Position = UDim2.fromOffset(0, 0)
    DragHandle.Parent = Titlebar
    DragHandle.Active = true

    -- Body: Sidebar + Main
    local Body = Instance.new("Frame")
    Body.BackgroundTransparency = 1
    Body.Size = UDim2.new(1, -16, 1, -56)
    Body.Position = UDim2.fromOffset(8, 48)
    Body.Parent = Window

    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 196, 1, 0)
    Sidebar.BackgroundColor3 = Theme.Component
    Sidebar.Parent = Body
    UICornerOf(Sidebar, 10)
    StrokeOf(Sidebar, 1, Theme.Outline, .6)

    local SideHeader = Instance.new("TextLabel")
    SideHeader.BackgroundTransparency = 1
    SideHeader.Text = "Navigation"
    SideHeader.TextColor3 = Theme.Title
    SideHeader.TextXAlignment = Enum.TextXAlignment.Left
    SideHeader.Font = Enum.Font.GothamSemibold
    SideHeader.TextSize = 13
    SideHeader.Size = UDim2.new(1, -14, 0, 30)
    SideHeader.Position = UDim2.fromOffset(7, 4)
    SideHeader.Parent = Sidebar

    local TabList = Instance.new("Frame")
    TabList.BackgroundTransparency = 1
    TabList.Size = UDim2.new(1, -12, 1, -40)
    TabList.Position = UDim2.fromOffset(6, 34)
    TabList.Parent = Sidebar
    local TL = Instance.new("UIListLayout", TabList)
    TL.SortOrder = Enum.SortOrder.LayoutOrder
    TL.Padding = UDim.new(0, 6)

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.BackgroundColor3 = Theme.Component
    Main.Size = UDim2.new(1, -204, 1, 0)
    Main.Position = UDim2.fromOffset(204, 0)
    Main.Parent = Body
    UICornerOf(Main, 10)
    StrokeOf(Main, 1, Theme.Outline, .6)

    local Pages = Instance.new("Folder")
    Pages.Name = "Pages"; Pages.Parent = Main

    -- Animations: open/close zoom
    local function Open()
        Window.Visible = true
        Window.GroupTransparency = 1
        local size0 = Window.Size
        Window.Size = UDim2.new(size0.X, UDim.new(0, math.floor(size0.Y.Offset*0.93)))
        Tween(Window, .18, {Size = size0}, Enum.EasingStyle.Quad)
        Tween(Window, .18, {GroupTransparency = Setup.Transparency}, Enum.EasingStyle.Sine)
    end
    local function Close()
        local size0 = Window.Size
        Tween(Window, .14, {GroupTransparency = 1}, Enum.EasingStyle.Sine)
        Tween(Window, .14, {Size = UDim2.new(size0.X, UDim.new(0, math.floor(size0.Y.Offset*0.93)))}, Enum.EasingStyle.Quad)
        task.wait(.14)
        Window.Visible = false
        Window.Size = size0
        Window.GroupTransparency = Setup.Transparency
    end

    -- Drag: stable, title-only
    do
        local dragging = false
        local offset = Vector2.new()
        local function mousePos()
            local m = UIS:GetMouseLocation()
            return Vector2.new(m.X, m.Y)
        end
        DragHandle.InputBegan:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if UIS:GetFocusedTextBox() then return end
            dragging = true
            local m = mousePos()
            offset = Vector2.new(m.X - Window.Position.X.Offset, m.Y - Window.Position.Y.Offset)
            Tween(Window, .08, {GroupTransparency = math.clamp(Setup.Transparency + 0.12, 0, .95)})
        end)
        UIS.InputChanged:Connect(function(inp)
            if not dragging then return end
            if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
            local m = mousePos()
            Window.Position = UDim2.fromOffset(m.X - offset.X, m.Y - offset.Y)
        end)
        UIS.InputEnded:Connect(function(inp)
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if not dragging then return end
            dragging = false
            Tween(Window, .10, {GroupTransparency = Setup.Transparency})
        end)
    end

    -- Top buttons behaviour
    BtnMin.MouseButton1Click:Connect(function() Window.Visible = false end)
    BtnClose.MouseButton1Click:Connect(function() Close() end)
    UIS.InputBegan:Connect(function(inp,gp)
        if gp then return end
        if inp.KeyCode == Setup.Keybind then
            if not Window.Visible then Open() else Window.Visible = false end
        end
    end)

    -- Tabs & Sections
    local StoredInfo = { Sections = {}, Tabs = {} }
    local CurrentTab

    local function MakeTabButton(name, order)
        local Btn = Instance.new("TextButton")
        Btn.Name = name
        Btn.AutoButtonColor = false
        Btn.BackgroundColor3 = Theme.Interactables
        Btn.Size = UDim2.new(1, 0, 0, 30)
        Btn.Text = ""
        Btn.LayoutOrder = order or (#TabList:GetChildren()+1)
        Btn.Parent = TabList
        UICornerOf(Btn, 8); local s = StrokeOf(Btn, 1, Theme.Outline, .65)

        local TLbl = Instance.new("TextLabel")
        TLbl.BackgroundTransparency = 1
        TLbl.Font = Enum.Font.Gotham
        TLbl.TextXAlignment = Enum.TextXAlignment.Left
        TLbl.TextSize = 13
        TLbl.TextColor3 = Theme.Tab
        TLbl.Text = name
        TLbl.Size = UDim2.new(1, -16, 1, 0)
        TLbl.Position = UDim2.fromOffset(8, 0)
        TLbl.Parent = Btn

        Btn.MouseEnter:Connect(function()
            Tween(Btn, .10, {BackgroundColor3 = Theme.Component})
            Tween(s, .10, {Transparency = .45, Color = Theme.Accent})
        end)
        Btn.MouseLeave:Connect(function()
            Tween(Btn, .12, {BackgroundColor3 = Theme.Interactables})
            Tween(s, .12, {Transparency = .65, Color = Theme.Outline})
        end)
        return Btn
    end

    local function MakePage(name)
        local Page = Instance.new("CanvasGroup")
        Page.Name = name
        Page.BackgroundTransparency = 1
        Page.GroupTransparency = 0
        Page.Visible = false
        Page.Size = UDim2.new(1, -16, 1, -16)
        Page.Position = UDim2.fromOffset(8, 8)
        Page.Parent = Pages

        local Scroll = Instance.new("ScrollingFrame")
        Scroll.Active = true
        Scroll.BackgroundTransparency = 1
        Scroll.BorderSizePixel = 0
        Scroll.ScrollBarThickness = 4
        Scroll.ScrollBarImageTransparency = .15
        Scroll.ScrollBarImageColor3 = Theme.Interactables
        Scroll.Size = UDim2.new(1, 0, 1, 0)
        Scroll.Parent = Page

        local List = Instance.new("UIListLayout", Scroll)
        List.SortOrder = Enum.SortOrder.LayoutOrder
        List.Padding = UDim.new(0, 8)

        local Pad = Instance.new("UIPadding", Scroll)
        Pad.PaddingTop = UDim.new(0, 8)
        Pad.PaddingLeft = UDim.new(0, 8)
        Pad.PaddingRight = UDim.new(0, 8)
        Pad.PaddingBottom = UDim.new(0, 8)

        local function resize()
            Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 16)
        end
        List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize); resize()

        return Page, Scroll
    end

    local function SetTab(name)
        for tabName, data in pairs(StoredInfo.Tabs) do
            local btn, page = data.Button, data.Page
            if tabName == name then
                if not page.Visible then page.Visible = true Tween(page, .14, {GroupTransparency = 0}) end
                Tween(btn, .10, {BackgroundColor3 = Theme.Component})
            else
                if page.Visible then Tween(page, .10, {GroupTransparency = 1}) task.delay(.10, function() page.Visible = false end) end
                Tween(btn, .10, {BackgroundColor3 = Theme.Interactables})
            end
        end
        CurrentTab = name
    end

    -- Row helpers (keine Überlappungen)
    local function MakeRow(parent, h)
        local R = Instance.new("Frame")
        R.BackgroundColor3 = Theme.Component
        R.Size = UDim2.new(1, 0, 0, h)
        R.Parent = parent
        UICornerOf(R, 8); StrokeOf(R, 1, Theme.Outline, .6)
        return R
    end
    local function LabelBlock(row, title, desc, rightW)
        local L = Instance.new("Frame")
        L.BackgroundTransparency = 1
        L.Position = UDim2.fromOffset(10, 6)
        L.Size = UDim2.new(1, -((rightW or 0) + 24), 1, -12)
        L.Parent = row

        local T = Instance.new("TextLabel")
        T.BackgroundTransparency = 1
        T.Font = Enum.Font.GothamSemibold
        T.TextXAlignment = Enum.TextXAlignment.Left
        T.TextSize = 13
        T.TextColor3 = Theme.Title
        T.Text = title or "Title"
        T.Size = UDim2.new(1, 0, 0, 18)
        T.Parent = L

        local D = Instance.new("TextLabel")
        D.BackgroundTransparency = 1
        D.Font = Enum.Font.Gotham
        D.TextXAlignment = Enum.TextXAlignment.Left
        D.TextSize = 12
        D.TextColor3 = Theme.Description
        D.TextWrapped = true
        D.Text = desc or ""
        D.Position = UDim2.fromOffset(0, 20)
        D.Size = UDim2.new(1, 0, 1, -20)
        D.Parent = L
        return T, D
    end
    local function RightSlot(row, w, h)
        local S = Instance.new("Frame")
        S.BackgroundTransparency = 1
        S.Size = UDim2.fromOffset(w, h)
        S.AnchorPoint = Vector2.new(1, .5)
        S.Position = UDim2.new(1, -10, .5, 0)
        S.Parent = row
        return S
    end

    -- Components (Late-like API)
    local Options = {}

    function Options:SetTab(name) SetTab(name) end

    function Options:AddTabSection(Settings2)
        StoredInfo.Sections[Settings2.Name] = Settings2.Order or (#StoredInfo.Sections + 1)
    end

    function Options:AddTab(Settings2)
        if StoredInfo.Tabs[Settings2.Title] then error("[Ecstays] Tab exists: "..Settings2.Title) end
        local order = StoredInfo.Sections[Settings2.Section] or 999
        local btn = MakeTabButton(Settings2.Title, order)
        local page, scroll = MakePage(Settings2.Title)
        StoredInfo.Tabs[Settings2.Title] = { Button = btn, Page = page, Scroll = scroll }
        btn.MouseButton1Click:Connect(function() SetTab(Settings2.Title) end)
        if not CurrentTab then SetTab(Settings2.Title) end
        return scroll
    end

    -- Section
    function Options:AddSection(Settings2)
        local row = MakeRow(Settings2.Tab, 28)
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.GothamSemibold
        t.TextSize = 13
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextColor3 = Theme.Title
        t.Text = Settings2.Name or "Section"
        t.Size = UDim2.new(1, -10, 1, 0)
        t.Position = UDim2.fromOffset(10, 0)
        t.Parent = row
        return row
    end

    -- Button
    function Options:AddButton(Settings2)
        local RW = 118
        local row = MakeRow(Settings2.Tab, 54)
        LabelBlock(row, Settings2.Title, Settings2.Description, RW)
        local R = RightSlot(row, RW, 28)
        local B = Instance.new("TextButton")
        B.AutoButtonColor = false
        B.BackgroundColor3 = Theme.Interactables
        B.Text = "Execute"
        B.TextColor3 = Theme.Title
        B.Font = Enum.Font.GothamBold
        B.TextSize = 13
        B.Size = UDim2.fromScale(1,1)
        B.Parent = R
        UICornerOf(B, 8) local s = StrokeOf(B,1,Theme.Outline,.6)
        B.MouseEnter:Connect(function() Tween(B,.10,{BackgroundColor3=Theme.Component}) Tween(s,.10,{Transparency=.42,Color=Theme.Accent}) end)
        B.MouseLeave:Connect(function() Tween(B,.12,{BackgroundColor3=Theme.Interactables}) Tween(s,.12,{Transparency=.6,Color=Theme.Outline}) end)
        B.MouseButton1Click:Connect(function() if Settings2.Callback then pcall(Settings2.Callback) end end)
        return row
    end

    -- Input
    function Options:AddInput(Settings2)
        local RW = 220
        local row = MakeRow(Settings2.Tab, 60)
        LabelBlock(row, Settings2.Title, Settings2.Description, RW)
        local R = RightSlot(row, RW, 28)
        local Box = Instance.new("TextBox")
        Box.ClearTextOnFocus = false
        Box.BackgroundColor3 = Theme.Interactables
        Box.TextColor3 = Theme.Title
        Box.PlaceholderText = Settings2.Placeholder or "type here…"
        Box.Font = Enum.Font.Gotham
        Box.TextSize = 13
        Box.Size = UDim2.fromScale(1,1)
        Box.Parent = R
        UICornerOf(Box, 8) local s = StrokeOf(Box,1,Theme.Outline,.6)
        Box.Focused:Connect(function() Tween(s,.08,{Transparency=.35,Color=Theme.Accent}) end)
        Box.FocusLost:Connect(function(enter) Tween(s,.10,{Transparency=.6,Color=Theme.Outline}); if enter and Settings2.Callback then pcall(function() Settings2.Callback(Box.Text) end) end end)
        return row
    end

    -- Toggle
    function Options:AddToggle(Settings2)
        local RW = 62
        local row = MakeRow(Settings2.Tab, 54)
        LabelBlock(row, Settings2.Title, Settings2.Description, RW)
        local R = RightSlot(row, RW, 26)
        local Back = Instance.new("Frame"); Back.Size=UDim2.fromScale(1,1); Back.BackgroundColor3=Theme.Interactables; Back.Parent=R
        UICornerOf(Back, 13); StrokeOf(Back,1,Theme.Outline,.6)
        local Dot = Instance.new("Frame"); Dot.Size=UDim2.fromOffset(22,22); Dot.Position=UDim2.fromOffset(2,2); Dot.BackgroundColor3=Theme.Secondary; Dot.Parent=Back; UICornerOf(Dot,11)

        local state = Settings2.Default == true
        local function set(v)
            state = v and true or false
            if state then
                Tween(Back,.10,{BackgroundColor3=Theme.Accent})
                Tween(Dot,.10,{Position=UDim2.fromOffset(RW-2-22,2), BackgroundColor3=Color3.fromRGB(255,255,255)})
            else
                Tween(Back,.10,{BackgroundColor3=Theme.Interactables})
                Tween(Dot,.10,{Position=UDim2.fromOffset(2,2), BackgroundColor3=Theme.Secondary})
            end
        end
        set(state)
        row.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then set(not state) if Settings2.Callback then pcall(function() Settings2.Callback(state) end) end end end)
        return row
    end

    -- Keybind
    function Options:AddKeybind(Settings2)
        local RW = 132
        local row = MakeRow(Settings2.Tab, 54)
        LabelBlock(row, Settings2.Title, Settings2.Description, RW)
        local R = RightSlot(row, RW, 28)
        local Btn = Instance.new("TextButton"); Btn.AutoButtonColor=false; Btn.BackgroundColor3=Theme.Interactables
        Btn.Text="Set Key"; Btn.TextColor3=Theme.Title; Btn.Font=Enum.Font.GothamBold; Btn.TextSize=13; Btn.Size=UDim2.fromScale(1,1); Btn.Parent=R
        UICornerOf(Btn,8); local s=StrokeOf(Btn,1,Theme.Outline,.6)
        local cap=false
        Btn.MouseButton1Click:Connect(function()
            if cap then return end; cap=true; Btn.Text="..."
            local con; con = UIS.InputBegan:Connect(function(input,gp)
                if gp then return end; cap=false
                local label = input.UserInputType==Enum.UserInputType.Keyboard and tostring(input.KeyCode):gsub("Enum.KeyCode.","") or tostring(input.UserInputType):gsub("Enum.UserInputType.","")
                Btn.Text = label
                if Settings2.Callback then pcall(function() Settings2.Callback(input) end) end
                if con then con:Disconnect() end
            end)
        end)
        Btn.MouseEnter:Connect(function() Tween(Btn,.10,{BackgroundColor3=Theme.Component}) Tween(s,.10,{Transparency=.42,Color=Theme.Accent}) end)
        Btn.MouseLeave:Connect(function() Tween(Btn,.12,{BackgroundColor3=Theme.Interactables}) Tween(s,.12,{Transparency=.6,Color=Theme.Outline}) end)
        return row
    end

    -- Dropdown
    function Options:AddDropdown(Settings2)
        local RW = 220
        local row = MakeRow(Settings2.Tab, 60)
        LabelBlock(row, Settings2.Title, Settings2.Description, RW)
        local R = RightSlot(row, RW, 28)
        local Btn = Instance.new("TextButton"); Btn.AutoButtonColor=false; Btn.BackgroundColor3=Theme.Interactables; Btn.Text=""; Btn.Size=UDim2.fromScale(1,1); Btn.Parent=R
        UICornerOf(Btn,8); local s = StrokeOf(Btn,1,Theme.Outline,.6)

        local TL = Instance.new("TextLabel"); TL.BackgroundTransparency=1; TL.Font=Enum.Font.Gotham; TL.TextXAlignment=Enum.TextXAlignment.Left
        TL.TextSize=13; TL.TextColor3=Theme.Title; TL.Text=Settings2.Placeholder or "Select…"; TL.Size=UDim2.new(1,-22,1,0); TL.Position=UDim2.fromOffset(8,0); TL.Parent=Btn
        local Arrow = Instance.new("TextLabel"); Arrow.BackgroundTransparency=1; Arrow.Font=Enum.Font.GothamBold; Arrow.TextSize=14; Arrow.TextColor3=Theme.Description
        Arrow.Text="▼"; Arrow.Size=UDim2.fromOffset(18,18); Arrow.Position=UDim2.new(1,-20,0,5); Arrow.Parent=Btn

        local Open, Popup = false, nil
        local function closePop()
            if not Popup then return end
            Tween(Popup,.10,{GroupTransparency=1}); task.delay(.10,function() if Popup then Popup:Destroy() Popup=nil end end); Open=false
        end
        local function openPop()
            if Open then closePop() return end; Open=true
            Popup = Instance.new("CanvasGroup")
            Popup.GroupTransparency = 1
            Popup.BackgroundColor3 = Theme.Secondary
            Popup.Size = UDim2.fromOffset(220, 196)
            Popup.Position = UDim2.new(0, Btn.AbsolutePosition.X - Window.AbsolutePosition.X, 0, Btn.AbsolutePosition.Y - Window.AbsolutePosition.Y + 30)
            Popup.Parent = Window
            UICornerOf(Popup,10); StrokeOf(Popup,1,Theme.Outline,.55)

            local Scroll = Instance.new("ScrollingFrame")
            Scroll.Active=true; Scroll.BorderSizePixel=0; Scroll.BackgroundTransparency=1
            Scroll.ScrollBarThickness=4; Scroll.ScrollBarImageTransparency=.1; Scroll.ScrollBarImageColor3=Theme.Interactables
            Scroll.Size=UDim2.new(1,-10,1,-10); Scroll.Position=UDim2.fromOffset(5,5); Scroll.Parent=Popup
            local L = Instance.new("UIListLayout", Scroll); L.Padding=UDim.new(0,6)

            for k,v in pairs(Settings2.Options or {}) do
                local Opt = Instance.new("TextButton"); Opt.AutoButtonColor=false; Opt.Size=UDim2.new(1,0,0,26); Opt.Text=""
                Opt.BackgroundColor3=Theme.Component; Opt.Parent=Scroll
                UICornerOf(Opt,8); local os=StrokeOf(Opt,1,Theme.Outline,.6)
                local OTL=Instance.new("TextLabel"); OTL.BackgroundTransparency=1; OTL.Font=Enum.Font.Gotham; OTL.TextXAlignment=Enum.TextXAlignment.Left
                OTL.TextSize=12; OTL.TextColor3=Theme.Tab; OTL.Text=tostring(k); OTL.Size=UDim2.new(1,-10,1,0); OTL.Position=UDim2.fromOffset(6,0); OTL.Parent=Opt
                Opt.MouseEnter:Connect(function() Tween(Opt,.08,{BackgroundColor3=Theme.Interactables}) Tween(os,.08,{Transparency=.45,Color=Theme.Accent}) end)
                Opt.MouseLeave:Connect(function() Tween(Opt,.10,{BackgroundColor3=Theme.Component}) Tween(os,.10,{Transparency=.6,Color=Theme.Outline}) end)
                Opt.MouseButton1Click:Connect(function() TL.Text=tostring(k); closePop(); if Settings2.Callback then pcall(function() Settings2.Callback(v) end) end end)
            end
            Tween(Popup,.12,{GroupTransparency=0})
        end
        Btn.MouseButton1Click:Connect(openPop)
        UIS.InputBegan:Connect(function(inp,gp)
            if gp or not Open or not Popup then return end
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then
                local p = UIS:GetMouseLocation()
                local x,y = Popup.AbsolutePosition.X, Popup.AbsolutePosition.Y
                local x2,y2= x + Popup.AbsoluteSize.X, y + Popup.AbsoluteSize.Y
                if not (p.X>=x and p.X<=x2 and p.Y>=y and p.Y<=y2) then closePop() end
            end
        end)
        return row
    end

    -- Slider
    function Options:AddSlider(Settings2)
        local RW = 110
        local row = MakeRow(Settings2.Tab, 70)
        LabelBlock(row, Settings2.Title, Settings2.Description, RW)

        local Track = Instance.new("Frame")
        Track.BackgroundColor3 = Theme.Interactables
        Track.Size = UDim2.new(1, -(RW + 28), 0, 6)
        Track.Position = UDim2.new(0, 10, 1, -14)
        Track.Parent = row
        UICornerOf(Track, 3)

        local Fill = Instance.new("Frame")
        Fill.BackgroundColor3 = Theme.Accent
        Fill.Size = UDim2.fromScale(0,1)
        Fill.Parent = Track
        UICornerOf(Fill, 3)

        local Knob = Instance.new("Frame")
        Knob.Size = UDim2.fromOffset(14,14)
        Knob.AnchorPoint = Vector2.new(.5,.5)
        Knob.Position = UDim2.new(0,0,.5,0)
        Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        Knob.Parent = Track
        UICornerOf(Knob,7); StrokeOf(Knob,1,Theme.Outline,.4)

        local R = RightSlot(row, RW, 26)
        local Box = Instance.new("TextBox"); Box.Size=UDim2.fromScale(1,1)
        Box.BackgroundColor3=Theme.Interactables; Box.TextColor3=Theme.Title
        Box.PlaceholderText="0"; Box.Text="0"; Box.Font=Enum.Font.Gotham; Box.TextSize=13; Box.Parent=R
        UICornerOf(Box,8); local sb=StrokeOf(Box,1,Theme.Outline,.6)

        local max = tonumber(Settings2.MaxValue) or 100
        local allowDec = Settings2.AllowDecimals == true
        local decimals = tonumber(Settings2.DecimalAmount) or 2
        local value = 0
        local function fmt(n) if allowDec then local p=10^decimals n=math.floor(n*p+0.5)/p return tostring(n) else return tostring(math.floor(n+0.5)) end end
        local function setVal(n)
            n = math.clamp(n, 0, max); value = n
            local s = (max==0) and 0 or (n/max)
            Fill.Size = UDim2.fromScale(s,1)
            Knob.Position = UDim2.new(s,0,.5,0)
            Box.Text = fmt(n)
            if Settings2.Callback then pcall(function() Settings2.Callback(n) end) end
        end
        local dragging=false
        local function mouseToValue()
            local m = UIS:GetMouseLocation()
            local x0 = Track.AbsolutePosition.X; local w = Track.AbsoluteSize.X
            local s = clamp01((m.X - x0) / w)
            return s * max
        end
        Track.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true setVal(mouseToValue()) end end)
        UIS.InputChanged:Connect(function(inp) if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then setVal(mouseToValue()) end end)
        UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

        Box.Focused:Connect(function() Tween(sb,.08,{Transparency=.35,Color=Theme.Accent}) end)
        Box.FocusLost:Connect(function(enter) Tween(sb,.10,{Transparency=.6,Color=Theme.Outline}); if enter then setVal(tonumber(Box.Text) or 0) end end)

        setVal(tonumber(Settings2.Default) or 0)
        return row
    end

    -- Paragraph
    function Options:AddParagraph(Settings2)
        local row = MakeRow(Settings2.Tab, 110)
        local _,D = LabelBlock(row, Settings2.Title, Settings2.Description, 0)
        D.TextWrapped = true
        return row
    end

    -- Notifications (bottom-left)
    function Options:Notify(Settings2)
        local N = Instance.new("CanvasGroup")
        N.GroupTransparency = 1
        N.BackgroundColor3 = Theme.Secondary
        N.Size = UDim2.fromOffset(300, 68)
        N.Parent = NotiRoot
        UICornerOf(N, 10); StrokeOf(N,1,Theme.Outline,.55)

        local Bar = Instance.new("Frame")
        Bar.BackgroundColor3 = Theme.Accent
        Bar.Size = UDim2.new(0,0,0,3)
        Bar.Position = UDim2.new(0,0,1,-3)
        Bar.Parent = N

        local L = Instance.new("Frame")
        L.BackgroundTransparency = 1
        L.Size = UDim2.new(1,-14,1,-14)
        L.Position = UDim2.fromOffset(7,7)
        L.Parent = N

        local T = Instance.new("TextLabel")
        T.BackgroundTransparency = 1
        T.Font = Enum.Font.GothamSemibold
        T.TextXAlignment = Enum.TextXAlignment.Left
        T.TextSize = 13
        T.TextColor3 = Theme.Title
        T.Text = Settings2.Title or "Notification"
        T.Size = UDim2.new(1,0,0,18)
        T.Parent = L

        local D = Instance.new("TextLabel")
        D.BackgroundTransparency = 1
        D.Font = Enum.Font.Gotham
        D.TextXAlignment = Enum.TextXAlignment.Left
        D.TextSize = 12
        D.TextWrapped = true
        D.TextColor3 = Theme.Tab
        D.Text = Settings2.Description or ""
        D.Position = UDim2.fromOffset(0,20)
        D.Size = UDim2.new(1,0,1,-20)
        D.Parent = L

        local dur = tonumber(Settings2.Duration) or 2
        Tween(N,.12,{GroupTransparency=Setup.Transparency})
        Tween(Bar,dur,{Size=UDim2.new(1,0,0,3)})
        task.delay(dur,function() Tween(N,.10,{GroupTransparency=1}); task.delay(.10,function() N:Destroy() end) end)
    end

    -- Theme & Settings
    function Options:SetTheme(tbl)
        if typeof(tbl) ~= "table" then return end
        for k,v in pairs(tbl) do Theme[k] = v end
        Window.BackgroundColor3 = Theme.Secondary
        Titlebar.BackgroundColor3 = Theme.Primary
        Main.BackgroundColor3 = Theme.Component
        Sidebar.BackgroundColor3 = Theme.Component
        TitleLbl.TextColor3 = Theme.Title
        WStroke.Color = Theme.Outline
    end

    function Options:SetSetting(Setting, Value)
        if Setting == "Size" then
            Window.Size = Value; Setup.Size = Value
        elseif Setting == "Transparency" then
            Window.GroupTransparency = Value; Setup.Transparency = Value
        elseif Setting == "Theme" and typeof(Value) == "table" then
            Options:SetTheme(Value)
        elseif Setting == "Keybind" then
            Setup.Keybind = Value
        else
            warn("[Ecstays] Unknown setting:", Setting)
        end
    end

    -- initial open
    Window.Size = Setup.Size
    Window.Visible = true
    Open()

    return Options
end

return Library
