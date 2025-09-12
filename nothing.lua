--[[
    Ecstays UI Library (2025 rebuild)
    - Clean core with icy drag (inertia + live transparency)
    - Zoom open/close
    - Only Minimize & Close (top-right, large, clean)
    - Pink–Lilac accent
    - Full set of controls: Tabs, Sections, Button, Input, Toggle, Keybind, Dropdown, Slider, Paragraph, Notify
    - No external assets, no loadstring
]]

--========================================================
-- Guards & Services
--========================================================
if not game:IsLoaded() then game.Loaded:Wait() end

local Players   = game:GetService("Players")
local Tween     = game:GetService("TweenService")
local UIS       = game:GetService("UserInputService")
local Run       = game:GetService("RunService")
local Http      = game:GetService("HttpService")

local LP        = Players.LocalPlayer

--========================================================
-- Helpers
--========================================================
local function safeParent(gui)
    -- Prefer CoreGui if allowed, fallback to PlayerGui
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok then
        gui.Parent = LP:WaitForChild("PlayerGui")
    end
end

local function tplay(inst, time, props, style, dir)
    return Tween:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.Out), props):Play()
end

local function clamp01(x) return (x<0 and 0) or (x>1 and 1) or x end

local function clampToViewport(guiObj)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local abs = guiObj.AbsoluteSize
    local x = math.clamp(guiObj.Position.X.Offset, 0, math.max(0, vp.X - abs.X))
    local y = math.clamp(guiObj.Position.Y.Offset, 0, math.max(0, vp.Y - abs.Y))
    guiObj.Position = UDim2.fromOffset(x, y)
end

local function newRound(parent, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = parent; return c end
local function newStroke(parent, thk, col, tr)
    local s = Instance.new("UIStroke"); s.Thickness = thk or 1; s.Color = col or Color3.fromRGB(60,60,65); s.Transparency = tr or .6; s.Parent = parent; return s
end

local function px(n) return UDim.new(0, n) end

--========================================================
-- Theme
--========================================================
local DEFAULT_THEME = {
    -- Surfaces
    Primary       = Color3.fromRGB(18, 16, 22),  -- titlebar
    Secondary     = Color3.fromRGB(24, 22, 30),  -- window/content
    Tertiary      = Color3.fromRGB(30, 27, 38),  -- components
    Interact      = Color3.fromRGB(38, 34, 48),  -- hovers/inputs

    -- Text
    Title         = Color3.fromRGB(242, 238, 248),
    Text          = Color3.fromRGB(212, 208, 220),
    Muted         = Color3.fromRGB(182, 178, 190),

    -- Lines / Icon
    Stroke        = Color3.fromRGB(72, 58, 92),
    Icon          = Color3.fromRGB(235, 220, 245),

    -- Accent
    Accent        = Color3.fromRGB(206, 99, 255),
    AccentSoft    = Color3.fromRGB(166, 82, 232),

    -- States
    Danger        = Color3.fromRGB(255, 92, 128),
    Success       = Color3.fromRGB(120, 230, 170),
}

-- Slight color lift/darken (mode= "up"|"down")
local function tint(col, by, mode)
    local r,g,b = col.R*255, col.G*255, col.B*255
    if mode == "down" then
        return Color3.fromRGB(math.clamp(r - by, 0, 255), math.clamp(g - by,0,255), math.clamp(b - by,0,255))
    else
        return Color3.fromRGB(math.clamp(r + by, 0, 255), math.clamp(g + by,0,255), math.clamp(b + by,0,255))
    end
end

--========================================================
-- Library
--========================================================
local Ecstays = {}
Ecstays._VERSION = "3.0-clean"

--========================================================
-- Core Window
--========================================================
function Ecstays:CreateWindow(opts)
    opts = opts or {}
    local Theme   = opts.ThemeTable or DEFAULT_THEME
    local Title   = opts.Title or "Ecstays"
    local WSize   = opts.Size or Vector2.new(760, 500)
    local Key     = opts.MinimizeKeybind or Enum.KeyCode.LeftControl
    local BaseT   = math.clamp(tonumber(opts.Transparency) or 0.06, 0, .95)

    -- ScreenGui
    local SG = Instance.new("ScreenGui")
    SG.Name = "EcstaysUI"
    SG.IgnoreGuiInset = true
    SG.ResetOnSpawn = false
    safeParent(SG)

    -- Root Window
    local Root = Instance.new("CanvasGroup")
    Root.Name = "Window"
    Root.Size = UDim2.fromOffset(WSize.X, WSize.Y)
    Root.Position = UDim2.fromOffset(110, 110)
    Root.BackgroundColor3 = Theme.Secondary
    Root.GroupTransparency = BaseT
    Root.Active = true
    Root.Visible = false
    Root.Parent = SG
    newRound(Root, 14)
    local RootStroke = newStroke(Root, 1, Theme.Stroke, .55)

    -- Titlebar
    local Bar = Instance.new("Frame")
    Bar.Name = "Titlebar"
    Bar.BackgroundColor3 = Theme.Primary
    Bar.Size = UDim2.new(1, 0, 0, 44)
    Bar.Parent = Root
    newRound(Bar, 14)
    local BarMask = Instance.new("Frame")
    BarMask.BackgroundTransparency = 1
    BarMask.Size = UDim2.new(1, 0, 0, 14)
    BarMask.Parent = Bar

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Position = UDim2.fromOffset(16, 0)
    TitleLbl.Size = UDim2.new(1, -140, 1, 0)
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Font = Enum.Font.GothamSemibold
    TitleLbl.TextSize = 16
    TitleLbl.TextColor3 = Theme.Title
    TitleLbl.Text = Title .. " • Ecstays"
    TitleLbl.Parent = Bar

    -- Buttons (right)
    local Btns = Instance.new("Frame")
    Btns.Name = "Buttons"
    Btns.BackgroundTransparency = 1
    Btns.Size = UDim2.fromOffset(120, 44)
    Btns.Position = UDim2.new(1, -120, 0, 0)
    Btns.Parent = Bar

    local BtnLayout = Instance.new("UIListLayout", Btns)
    BtnLayout.FillDirection = Enum.FillDirection.Horizontal
    BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    BtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    BtnLayout.Padding = UDim.new(0, 10)

    local function mkBtn(name, txt, txtColor)
        local B = Instance.new("TextButton")
        B.Name = name
        B.AutoButtonColor = false
        B.Size = UDim2.fromOffset(40, 28)
        B.BackgroundColor3 = tint(Theme.Secondary, 6, "down")
        B.Font = Enum.Font.GothamBold
        B.TextSize = 16
        B.TextColor3 = txtColor or Theme.Text
        B.Text = txt
        B.Parent = Btns
        newRound(B, 8)
        local s = newStroke(B, 1, Theme.Stroke, .65)

        -- Hover accents
        B.MouseEnter:Connect(function()
            tplay(B, .12, {BackgroundColor3 = Theme.Interact})
            tplay(s, .12, {Transparency = .42, Color = Theme.Accent})
        end)
        B.MouseLeave:Connect(function()
            tplay(B, .14, {BackgroundColor3 = tint(Theme.Secondary, 6, "down")})
            tplay(s, .14, {Transparency = .65, Color = Theme.Stroke})
        end)

        return B
    end

    local BtnMin   = mkBtn("Minimize", "–", Theme.Text)
    local BtnClose = mkBtn("Close",    "×", Theme.Danger)

    -- Body layout: Sidebar + Main
    local Body = Instance.new("Frame")
    Body.Name = "Body"
    Body.BackgroundTransparency = 1
    Body.Size = UDim2.new(1, -20, 1, -64)
    Body.Position = UDim2.fromOffset(10, 54)
    Body.Parent = Root

    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 204, 1, 0)
    Sidebar.BackgroundColor3 = Theme.Tertiary
    Sidebar.Parent = Body
    newRound(Sidebar, 12)
    newStroke(Sidebar, 1, Theme.Stroke, .6)

    local SideHeader = Instance.new("TextLabel")
    SideHeader.BackgroundTransparency = 1
    SideHeader.Size = UDim2.new(1, -16, 0, 36)
    SideHeader.Position = UDim2.fromOffset(8, 6)
    SideHeader.Font = Enum.Font.GothamSemibold
    SideHeader.TextXAlignment = Enum.TextXAlignment.Left
    SideHeader.Text = "Navigation"
    SideHeader.TextSize = 14
    SideHeader.TextColor3 = Theme.Title
    SideHeader.Parent = Sidebar

    local TabList = Instance.new("Frame")
    TabList.Name = "TabList"
    TabList.BackgroundTransparency = 1
    TabList.Position = UDim2.fromOffset(6, 44)
    TabList.Size = UDim2.new(1, -12, 1, -50)
    TabList.Parent = Sidebar

    local TLLayout = Instance.new("UIListLayout", TabList)
    TLLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TLLayout.Padding = UDim.new(0, 6)

    -- Main
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.BackgroundColor3 = Theme.Tertiary
    Main.Size = UDim2.new(1, -214, 1, 0)
    Main.Position = UDim2.fromOffset(214, 0)
    Main.Parent = Body
    newRound(Main, 12)
    newStroke(Main, 1, Theme.Stroke, .6)

    -- Canvas for Tabs
    local TabPages = Instance.new("Folder")
    TabPages.Name = "TabPages"
    TabPages.Parent = Main

    --====================================================
    -- Open / Close (Zoom)
    --====================================================
    local function open()
        Root.Visible = true
        Root.GroupTransparency = 1
        Root.Size = UDim2.fromOffset(WSize.X * 0.94, WSize.Y * 0.94)
        tplay(Root, .18, {Size = UDim2.fromOffset(WSize.X, WSize.Y)}, Enum.EasingStyle.Quad)
        tplay(Root, .18, {GroupTransparency = BaseT}, Enum.EasingStyle.Sine)
    end

    local function close()
        tplay(Root, .15, {GroupTransparency = 1}, Enum.EasingStyle.Sine)
        tplay(Root, .15, {Size = UDim2.fromOffset(WSize.X * 0.94, WSize.Y * 0.94)}, Enum.EasingStyle.Quad)
        task.wait(.15)
        Root.Visible = false
        Root.Size = UDim2.fromOffset(WSize.X, WSize.Y)
        Root.GroupTransparency = BaseT
    end

    --====================================================
    -- Icy Drag with inertia + live transparency
    --====================================================
    do
        local dragging = false
        local dragStart
        local startPos
        local lastPos
        local velocity = Vector2.new(0,0)
        local lastTick = 0
        local friction = 0.88
        local boost = 12

        local function setDragTransparency(active)
            if active then
                tplay(Root, .08, {GroupTransparency = math.clamp(BaseT + 0.10, 0, .95)})
            else
                tplay(Root, .10, {GroupTransparency = BaseT})
            end
        end

        Bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Root.Position
                lastPos = input.Position
                lastTick = tick()
                setDragTransparency(true)

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        setDragTransparency(false)
                        -- inertia tween
                        local target = Vector2.new(
                            Root.Position.X.Offset + velocity.X * boost,
                            Root.Position.Y.Offset + velocity.Y * boost
                        )
                        local tw = Tween:Create(Root, TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(target.X, target.Y)})
                        tw:Play()
                        tw.Completed:Wait()
                        clampToViewport(Root)
                    end
                end)
            end
        end)

        UIS.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                Root.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)

                local now = tick()
                local dt = now - lastTick
                if dt > 0 then
                    local diff = input.Position - lastPos
                    local vx = diff.X / dt
                    local vy = diff.Y / dt
                    velocity = Vector2.new(
                        velocity.X * friction + vx * (1 - friction),
                        velocity.Y * friction + vy * (1 - friction)
                    )
                    lastPos = input.Position
                    lastTick = now
                end
            end
        end)
    end

    --====================================================
    -- Tabs + Pages
    --====================================================
    local Tabs = {}
    local CurrentTab = nil

    local function makeTabButton(tabName, order)
        local Btn = Instance.new("TextButton")
        Btn.Name = tabName
        Btn.AutoButtonColor = false
        Btn.BackgroundColor3 = Theme.Interact
        Btn.Size = UDim2.new(1, 0, 0, 34)
        Btn.Text = ""
        Btn.LayoutOrder = order or (#TabList:GetChildren()+1)
        Btn.Parent = TabList
        newRound(Btn, 8)
        local s = newStroke(Btn, 1, Theme.Stroke, .65)

        local Labels = Instance.new("Frame")
        Labels.BackgroundTransparency = 1
        Labels.Size = UDim2.new(1, -20, 1, 0)
        Labels.Position = UDim2.fromOffset(10,0)
        Labels.Parent = Btn

        local T = Instance.new("TextLabel")
        T.BackgroundTransparency = 1
        T.Font = Enum.Font.Gotham
        T.TextXAlignment = Enum.TextXAlignment.Left
        T.TextSize = 14
        T.TextColor3 = Theme.Text
        T.Text = tabName
        T.Size = UDim2.new(1, 0, 1, 0)
        T.Parent = Labels

        -- Hover
        Btn.MouseEnter:Connect(function()
            tplay(Btn, .12, {BackgroundColor3 = tint(Theme.Interact, 4, "up")})
            tplay(s, .12, {Transparency = .45, Color = Theme.Accent})
        end)
        Btn.MouseLeave:Connect(function()
            tplay(Btn, .14, {BackgroundColor3 = Theme.Interact})
            tplay(s, .14, {Transparency = .65, Color = Theme.Stroke})
        end)

        return Btn
    end

    local function makeTabPage(tabName)
        local Page = Instance.new("CanvasGroup")
        Page.Name = tabName
        Page.Size = UDim2.new(1, -20, 1, -20)
        Page.Position = UDim2.fromOffset(10,10)
        Page.BackgroundTransparency = 1
        Page.GroupTransparency = 0
        Page.Visible = false
        Page.Parent = TabPages

        local Scroll = Instance.new("ScrollingFrame")
        Scroll.Active = true
        Scroll.BorderSizePixel = 0
        Scroll.BackgroundTransparency = 1
        Scroll.ScrollBarThickness = 4
        Scroll.ScrollBarImageTransparency = .15
        Scroll.ScrollBarImageColor3 = Theme.Interact
        Scroll.Size = UDim2.new(1, -12, 1, -12)
        Scroll.Position = UDim2.fromOffset(6, 6)
        Scroll.Parent = Page

        local List = Instance.new("UIListLayout", Scroll)
        List.SortOrder = Enum.SortOrder.LayoutOrder
        List.Padding = UDim.new(0, 8)

        local Pad = Instance.new("UIPadding", Scroll)
        Pad.PaddingTop = px(8)
        Pad.PaddingLeft = px(8)
        Pad.PaddingRight = px(8)
        Pad.PaddingBottom = px(8)

        return Page, Scroll
    end

    local function setTab(name)
        for tabName, info in pairs(Tabs) do
            local btn = info.Button
            local page = info.Page
            if tabName == name then
                if not page.Visible then
                    page.Visible = true
                    tplay(page, .18, {GroupTransparency = 0})
                end
                tplay(btn, .14, {BackgroundColor3 = tint(Theme.Interact, 6, "up")})
            else
                if page.Visible then
                    tplay(page, .12, {GroupTransparency = 1})
                    task.delay(.12, function() page.Visible = false end)
                end
                tplay(btn, .14, {BackgroundColor3 = Theme.Interact})
            end
        end
        CurrentTab = name
    end

    --====================================================
    -- Components (Factory)
    --====================================================
    local Components = {}

    local function section(parent, title)
        local F = Instance.new("TextLabel")
        F.BackgroundColor3 = Theme.Tertiary
        F.TextXAlignment = Enum.TextXAlignment.Left
        F.Font = Enum.Font.GothamSemibold
        F.TextSize = 14
        F.TextColor3 = Theme.Title
        F.Text = title or "Section"
        F.Size = UDim2.new(1, 0, 0, 32)
        F.Parent = parent
        newRound(F, 8)
        newStroke(F, 1, Theme.Stroke, .6)
        return F
    end

    local function rowBase(parent, height)
        local B = Instance.new("TextButton")
        B.AutoButtonColor = false
        B.BackgroundColor3 = Theme.Tertiary
        B.Text = ""
        B.Size = UDim2.new(1, 0, 0, height or 58)
        B.Parent = parent
        newRound(B, 10)
        local s = newStroke(B, 1, Theme.Stroke, .6)
        -- hover subtle
        B.MouseEnter:Connect(function()
            tplay(B, .12, {BackgroundColor3 = tint(Theme.Tertiary, 4, "up")})
            tplay(s, .12, {Transparency = .46, Color = Theme.Accent})
        end)
        B.MouseLeave:Connect(function()
            tplay(B, .14, {BackgroundColor3 = Theme.Tertiary})
            tplay(s, .14, {Transparency = .6, Color = Theme.Stroke})
        end)
        return B
    end

    local function labels(parent, title, desc)
        local L = Instance.new("Frame")
        L.BackgroundTransparency = 1
        L.Size = UDim2.new(1, -14, 1, -14)
        L.Position = UDim2.fromOffset(10,7)
        L.Parent = parent

        local T = Instance.new("TextLabel")
        T.BackgroundTransparency = 1
        T.Font = Enum.Font.GothamSemibold
        T.TextXAlignment = Enum.TextXAlignment.Left
        T.TextSize = 14
        T.TextColor3 = Theme.Title
        T.Text = title or "Title"
        T.Size = UDim2.new(1, 0, 0, 20)
        T.Parent = L

        local D = Instance.new("TextLabel")
        D.BackgroundTransparency = 1
        D.Font = Enum.Font.Gotham
        D.TextXAlignment = Enum.TextXAlignment.Left
        D.TextSize = 13
        D.TextColor3 = Theme.Muted
        D.Text = desc or ""
        D.Position = UDim2.fromOffset(0, 22)
        D.Size = UDim2.new(1, -4, 1, -22)
        D.TextWrapped = true
        D.RichText = true
        D.Parent = L

        return T, D
    end

    local function rightSlot(parent, w, h)
        local S = Instance.new("Frame")
        S.BackgroundTransparency = 1
        S.Size = UDim2.fromOffset(w, h)
        S.AnchorPoint = Vector2.new(1, .5)
        S.Position = UDim2.new(1, -10, .5, 0)
        S.Parent = parent
        return S
    end

    -- Button
    function Components.Button(target, cfg)
        local Row = rowBase(target, 64)
        local T,D = labels(Row, cfg.Title, cfg.Description)

        local R = rightSlot(Row, 120, 32)
        local B = Instance.new("TextButton")
        B.AutoButtonColor = false
        B.Size = UDim2.fromScale(1,1)
        B.BackgroundColor3 = Theme.Interact
        B.Text = "Execute"
        B.TextColor3 = Theme.Title
        B.Font = Enum.Font.GothamBold
        B.TextSize = 14
        B.Parent = R
        newRound(B, 8)
        local s = newStroke(B, 1, Theme.Stroke, .6)

        B.MouseEnter:Connect(function()
            tplay(B, .12, {BackgroundColor3 = tint(Theme.Interact, 6, "up")})
            tplay(s, .12, {Transparency = .42, Color = Theme.Accent})
        end)
        B.MouseLeave:Connect(function()
            tplay(B, .14, {BackgroundColor3 = Theme.Interact})
            tplay(s, .14, {Transparency = .6, Color = Theme.Stroke})
        end)
        B.MouseButton1Click:Connect(function()
            pcall(function() cfg.Callback() end)
        end)

        return Row
    end

    -- Input
    function Components.Input(target, cfg)
        local Row = rowBase(target, 70)
        local T,D = labels(Row, cfg.Title, cfg.Description)
        local R = rightSlot(Row, 220, 32)

        local Box = Instance.new("TextBox")
        Box.ClearTextOnFocus = false
        Box.Size = UDim2.fromScale(1,1)
        Box.BackgroundColor3 = Theme.Interact
        Box.PlaceholderText = cfg.Placeholder or "type here…"
        Box.TextColor3 = Theme.Title
        Box.PlaceholderColor3 = tint(Theme.Muted, 20, "down")
        Box.Font = Enum.Font.Gotham
        Box.TextSize = 14
        Box.Text = ""
        Box.Parent = R
        newRound(Box, 8)
        local s = newStroke(Box, 1, Theme.Stroke, .6)

        Box.Focused:Connect(function() tplay(s, .10, {Transparency = .35, Color = Theme.Accent}) end)
        Box.FocusLost:Connect(function(enter)
            tplay(s, .12, {Transparency = .6, Color = Theme.Stroke})
            if enter then pcall(function() cfg.Callback(Box.Text) end) end
        end)

        return Row
    end

    -- Toggle
    function Components.Toggle(target, cfg)
        local Row = rowBase(target, 64)
        local T,D = labels(Row, cfg.Title, cfg.Description)

        local R = rightSlot(Row, 64, 28)
        local Back = Instance.new("Frame")
        Back.Size = UDim2.fromScale(1,1)
        Back.BackgroundColor3 = Theme.Interact
        Back.Parent = R
        newRound(Back, 14)
        local s = newStroke(Back, 1, Theme.Stroke, .6)

        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.fromOffset(24, 24)
        Dot.Position = UDim2.fromOffset(3,2)
        Dot.BackgroundColor3 = Theme.Secondary
        Dot.Parent = Back
        newRound(Dot, 12)

        local state = cfg.Default == true
        local function set(v)
            state = v and true or false
            if state then
                tplay(Back, .12, {BackgroundColor3 = Theme.Accent})
                tplay(Dot, .12, {Position = UDim2.fromOffset(64-3-24, 2), BackgroundColor3 = Color3.fromRGB(255,255,255)})
            else
                tplay(Back, .12, {BackgroundColor3 = Theme.Interact})
                tplay(Dot, .12, {Position = UDim2.fromOffset(3, 2), BackgroundColor3 = Theme.Secondary})
            end
        end
        set(state)

        Row.MouseButton1Click:Connect(function()
            set(not state)
            pcall(function() cfg.Callback(state) end)
        end)

        return Row
    end

    -- Keybind
    function Components.Keybind(target, cfg)
        local Row = rowBase(target, 64)
        local T,D = labels(Row, cfg.Title, cfg.Description)
        local R = rightSlot(Row, 140, 32)

        local Btn = Instance.new("TextButton")
        Btn.AutoButtonColor = false
        Btn.Size = UDim2.fromScale(1,1)
        Btn.BackgroundColor3 = Theme.Interact
        Btn.TextColor3 = Theme.Title
        Btn.Font = Enum.Font.GothamBold
        Btn.TextSize = 14
        Btn.Text = "Set Key"
        Btn.Parent = R
        newRound(Btn, 8)
        local s = newStroke(Btn, 1, Theme.Stroke, .6)

        local capturing = false
        Btn.MouseButton1Click:Connect(function()
            if capturing then return end
            capturing = true
            Btn.Text = "..."
            local con; con = UIS.InputBegan:Connect(function(input, gp)
                if gp then return end
                capturing = false
                local txt
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    txt = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                else
                    txt = tostring(input.UserInputType):gsub("Enum.UserInputType.", "")
                end
                Btn.Text = txt
                if cfg.Callback then pcall(function() cfg.Callback(input) end) end
                if con then con:Disconnect() end
            end)
        end)

        Btn.MouseEnter:Connect(function()
            tplay(Btn, .12, {BackgroundColor3 = tint(Theme.Interact, 6, "up")})
            tplay(s, .12, {Transparency = .42, Color = Theme.Accent})
        end)
        Btn.MouseLeave:Connect(function()
            tplay(Btn, .14, {BackgroundColor3 = Theme.Interact})
            tplay(s, .14, {Transparency = .6, Color = Theme.Stroke})
        end)

        return Row
    end

    -- Dropdown (single select)
    function Components.Dropdown(target, cfg)
        local Row = rowBase(target, 70)
        local T,D = labels(Row, cfg.Title, cfg.Description)
        local R = rightSlot(Row, 220, 32)

        local Btn = Instance.new("TextButton")
        Btn.AutoButtonColor = false
        Btn.BackgroundColor3 = Theme.Interact
        Btn.Size = UDim2.fromScale(1,1)
        Btn.Text = ""
        Btn.Parent = R
        newRound(Btn, 8)
        local s = newStroke(Btn, 1, Theme.Stroke, .6)

        local TL = Instance.new("TextLabel")
        TL.BackgroundTransparency = 1
        TL.Font = Enum.Font.Gotham
        TL.TextXAlignment = Enum.TextXAlignment.Left
        TL.TextSize = 14
        TL.TextColor3 = Theme.Title
        TL.Text = cfg.Placeholder or "Select…"
        TL.Size = UDim2.new(1, -28, 1, 0)
        TL.Position = UDim2.fromOffset(10,0)
        TL.Parent = Btn

        local Arrow = Instance.new("TextLabel")
        Arrow.BackgroundTransparency = 1
        Arrow.Font = Enum.Font.GothamBold
        Arrow.TextSize = 16
        Arrow.TextColor3 = Theme.Muted
        Arrow.Text = "▼"
        Arrow.Size = UDim2.fromOffset(24, 24)
        Arrow.Position = UDim2.new(1, -28, 0, 4)
        Arrow.Parent = Btn

        local Open = false
        local Popup
        local function closePopup()
            if not Popup then return end
            tplay(Popup, .12, {GroupTransparency = 1})
            task.delay(.12, function() if Popup then Popup:Destroy() Popup=nil end end)
            Open = false
        end

        local function openPopup()
            if Open then closePopup() return end
            Open = true

            Popup = Instance.new("CanvasGroup")
            Popup.GroupTransparency = 1
            Popup.BackgroundColor3 = Theme.Secondary
            Popup.Size = UDim2.fromOffset(220, 200)
            Popup.Position = UDim2.new(0, Btn.AbsolutePosition.X - Root.AbsolutePosition.X, 0, Btn.AbsolutePosition.Y - Root.AbsolutePosition.Y + 36)
            Popup.Parent = Root
            newRound(Popup, 10)
            newStroke(Popup, 1, Theme.Stroke, .55)

            local Scroll = Instance.new("ScrollingFrame")
            Scroll.Active = true
            Scroll.BorderSizePixel = 0
            Scroll.BackgroundTransparency = 1
            Scroll.ScrollBarThickness = 4
            Scroll.ScrollBarImageTransparency = .1
            Scroll.ScrollBarImageColor3 = Theme.Interact
            Scroll.Size = UDim2.new(1, -12, 1, -12)
            Scroll.Position = UDim2.fromOffset(6,6)
            Scroll.Parent = Popup

            local L = Instance.new("UIListLayout", Scroll)
            L.Padding = UDim.new(0,6)
            L.SortOrder = Enum.SortOrder.LayoutOrder

            for k,v in pairs(cfg.Options or {}) do
                local optName, optVal = k, v
                local Opt = Instance.new("TextButton")
                Opt.AutoButtonColor = false
                Opt.Size = UDim2.new(1, 0, 0, 28)
                Opt.BackgroundColor3 = Theme.Tertiary
                Opt.Text = ""
                Opt.Parent = Scroll
                newRound(Opt, 8)
                local os = newStroke(Opt, 1, Theme.Stroke, .6)

                local OTL = Instance.new("TextLabel")
                OTL.BackgroundTransparency = 1
                OTL.Size = UDim2.new(1, -12, 1, 0)
                OTL.Position = UDim2.fromOffset(8,0)
                OTL.Font = Enum.Font.Gotham
                OTL.TextXAlignment = Enum.TextXAlignment.Left
                OTL.TextSize = 13
                OTL.TextColor3 = Theme.Text
                OTL.Text = tostring(optName)
                OTL.Parent = Opt

                Opt.MouseEnter:Connect(function()
                    tplay(Opt, .10, {BackgroundColor3 = tint(Theme.Tertiary, 6, "up")})
                    tplay(os, .10, {Transparency = .45, Color = Theme.Accent})
                end)
                Opt.MouseLeave:Connect(function()
                    tplay(Opt, .12, {BackgroundColor3 = Theme.Tertiary})
                    tplay(os, .12, {Transparency = .6, Color = Theme.Stroke})
                end)
                Opt.MouseButton1Click:Connect(function()
                    TL.Text = tostring(optName)
                    closePopup()
                    if cfg.Callback then pcall(function() cfg.Callback(optVal) end) end
                end)
            end

            tplay(Popup, .14, {GroupTransparency = 0})
        end

        Btn.MouseButton1Click:Connect(openPopup)
        -- close on click elsewhere
        UIS.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if Open and inp.UserInputType == Enum.UserInputType.MouseButton1 then
                local pos = UIS:GetMouseLocation()
                local gx, gy = Popup.AbsolutePosition.X, Popup.AbsolutePosition.Y
                local gx2, gy2 = gx+Popup.AbsoluteSize.X, gy+Popup.AbsoluteSize.Y
                if not (pos.X >= gx and pos.X <= gx2 and pos.Y >= gy and pos.Y <= gy2) then
                    closePopup()
                end
            end
        end)

        return Row
    end

    -- Slider (0..Max)
    function Components.Slider(target, cfg)
        local max = tonumber(cfg.MaxValue) or 100
        local allowDec = cfg.AllowDecimals == true
        local decimals = tonumber(cfg.DecimalAmount) or 2

        local Row = rowBase(target, 82)
        local T,D = labels(Row, cfg.Title, cfg.Description)

        local Track = Instance.new("Frame")
        Track.BackgroundColor3 = Theme.Interact
        Track.Size = UDim2.new(1, -20, 0, 6)
        Track.Position = UDim2.fromOffset(10, 54)
        Track.Parent = Row
        newRound(Track, 3)

        local Fill = Instance.new("Frame")
        Fill.BackgroundColor3 = Theme.Accent
        Fill.Size = UDim2.fromScale(0,1)
        Fill.Parent = Track
        newRound(Fill, 3)

        local Circle = Instance.new("Frame")
        Circle.Size = UDim2.fromOffset(16,16)
        Circle.AnchorPoint = Vector2.new(.5,.5)
        Circle.Position = UDim2.new(0, 0, .5, 0)
        Circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
        Circle.Parent = Track
        newRound(Circle, 8)
        newStroke(Circle, 1, Theme.Stroke, .4)

        local Box = Instance.new("TextBox")
        Box.Size = UDim2.fromOffset(80, 28)
        Box.AnchorPoint = Vector2.new(1, .5)
        Box.Position = UDim2.new(1, -10, .5, 0)
        Box.Text = "0"
        Box.TextColor3 = Theme.Title
        Box.BackgroundColor3 = Theme.Interact
        Box.PlaceholderText = "0"
        Box.Font = Enum.Font.Gotham
        Box.TextSize = 14
        Box.Parent = Row
        newRound(Box, 8)
        local s = newStroke(Box, 1, Theme.Stroke, .6)

        local value = 0

        local function fmt(n)
            if allowDec then
                local p = 10 ^ decimals
                n = math.floor(n * p + 0.5) / p
                return tostring(n)
            else
                return tostring(math.floor(n + 0.5))
            end
        end

        local function setVal(n)
            n = math.clamp(n, 0, max)
            value = n
            local scale = n / max
            Fill.Size = UDim2.fromScale(scale, 1)
            Circle.Position = UDim2.new(scale, 0, .5, 0)
            Box.Text = fmt(n)
            if cfg.Callback then pcall(function() cfg.Callback(n) end) end
        end

        local dragging = false
        local function fromMouse()
            local m = UIS:GetMouseLocation()
            local x0 = Track.AbsolutePosition.X
            local w  = Track.AbsoluteSize.X
            local s  = clamp01((m.X - x0) / w)
            return s * max
        end

        Track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                setVal(fromMouse())
            end
        end)
        UIS.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                setVal(fromMouse())
            end
        end)

        Box.Focused:Connect(function() tplay(s, .08, {Transparency = .35, Color = Theme.Accent}) end)
        Box.FocusLost:Connect(function(enter)
            tplay(s, .10, {Transparency = .6, Color = Theme.Stroke})
            if enter then
                local n = tonumber(Box.Text) or 0
                setVal(n)
            end
        end)

        setVal(tonumber(cfg.Default) or 0)
        return Row
    end

    -- Paragraph
    function Components.Paragraph(target, cfg)
        local Row = rowBase(target, 120)
        local T,D = labels(Row, cfg.Title, cfg.Description)
        D.TextWrapped = true
        return Row
    end

    -- Notification (floating)
    local NotiRoot = Instance.new("Frame")
    NotiRoot.BackgroundTransparency = 1
    NotiRoot.Size = UDim2.new(1, -20, 1, -20)
    NotiRoot.Position = UDim2.fromOffset(10,10)
    NotiRoot.ZIndex = 9999
    NotiRoot.Parent = Root

    local NotiList = Instance.new("UIListLayout", NotiRoot)
    NotiList.Padding = UDim.new(0, 8)
    NotiList.SortOrder = Enum.SortOrder.LayoutOrder
    NotiList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotiList.HorizontalAlignment = Enum.HorizontalAlignment.Right

    local function notify(cfg)
        local N = Instance.new("CanvasGroup")
        N.GroupTransparency = 1
        N.BackgroundColor3 = Theme.Secondary
        N.Size = UDim2.fromOffset(320, 74)
        N.AnchorPoint = Vector2.new(1,1)
        N.Position = UDim2.new(1, 0, 1, 0)
        N.Parent = NotiRoot
        newRound(N, 10)
        local s = newStroke(N, 1, Theme.Stroke, .55)

        local Bar = Instance.new("Frame")
        Bar.BackgroundColor3 = Theme.Accent
        Bar.Size = UDim2.new(0, 0, 0, 3)
        Bar.Position = UDim2.new(0, 0, 1, -3)
        Bar.Parent = N

        local L = Instance.new("Frame")
        L.BackgroundTransparency = 1
        L.Size = UDim2.new(1, -16, 1, -16)
        L.Position = UDim2.fromOffset(8,8)
        L.Parent = N

        local T = Instance.new("TextLabel")
        T.BackgroundTransparency = 1
        T.Font = Enum.Font.GothamSemibold
        T.TextSize = 14
        T.TextXAlignment = Enum.TextXAlignment.Left
        T.TextColor3 = Theme.Title
        T.Text = cfg.Title or "Notification"
        T.Size = UDim2.new(1, 0, 0, 20)
        T.Parent = L

        local D = Instance.new("TextLabel")
        D.BackgroundTransparency = 1
        D.Font = Enum.Font.Gotham
        D.TextSize = 13
        D.TextXAlignment = Enum.TextXAlignment.Left
        D.TextColor3 = Theme.Text
        D.TextWrapped = true
        D.Text = cfg.Description or ""
        D.Position = UDim2.fromOffset(0, 22)
        D.Size = UDim2.new(1, 0, 1, -22)
        D.Parent = L

        tplay(N, .16, {GroupTransparency = BaseT})
        local dur = tonumber(cfg.Duration) or 2
        tplay(Bar, dur, {Size = UDim2.new(1, 0, 0, 3)})
        task.delay(dur, function()
            tplay(N, .12, {GroupTransparency = 1})
            task.delay(.12, function() N:Destroy() end)
        end)
    end

    --====================================================
    -- Public API (Window)
    --====================================================
    local API = {}

    -- core
    function API:Show() open() end
    function API:Hide() Root.Visible = false end
    function API:Destroy() SG:Destroy() end

    function API:SetTitle(t) TitleLbl.Text = tostring(t or "Ecstays") .. " • Ecstays" end
    function API:SetSize(v2)
        WSize = Vector2.new(v2.X, v2.Y)
        Root.Size = UDim2.fromOffset(WSize.X, WSize.Y)
        clampToViewport(Root)
    end
    function API:SetTransparency(v)
        BaseT = math.clamp(v or BaseT, 0, .95)
        Root.GroupTransparency = BaseT
    end
    function API:SetTheme(tbl)
        -- lightweight live theming: update top-level colors
        Theme = tbl or Theme
        Bar.BackgroundColor3 = Theme.Primary
        Root.BackgroundColor3 = Theme.Secondary
        Sidebar.BackgroundColor3 = Theme.Tertiary
        Main.BackgroundColor3 = Theme.Tertiary
        TitleLbl.TextColor3 = Theme.Title
        RootStroke.Color = Theme.Stroke
    end

    -- window controls
    BtnMin.MouseButton1Click:Connect(function() Root.Visible = false end)
    BtnClose.MouseButton1Click:Connect(function() close() end)

    UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == Key then
            if not Root.Visible then open() else Root.Visible = false end
        end
    end)

    -- tabs
    function API:AddTabSection(cfg)
        -- kept for API compatibility; sections define ordering in sidebar
        -- here we just store order; rendering is handled by AddTab
        self.__sections = self.__sections or {}
        self.__sections[cfg.Name] = cfg.Order or (table.getn(self.__sections)+1)
    end

    function API:AddTab(cfg)
        local title = cfg.Title or "Tab"
        local order = (self.__sections and self.__sections[cfg.Section]) or 999
        local btn = makeTabButton(title, order)
        local page, scroll = makeTabPage(title)

        Tabs[title] = { Button = btn, Page = page, Scroll = scroll }

        btn.MouseButton1Click:Connect(function() setTab(title) end)
        if not CurrentTab then setTab(title) end

        return scroll
    end

    function API:SetTab(name) if Tabs[name] then setTab(name) end end

    -- components
    function API:AddSection(cfg) return section(cfg.Tab, cfg.Name) end
    function API:AddButton(cfg)  return Components.Button(cfg.Tab, cfg) end
    function API:AddInput(cfg)   return Components.Input(cfg.Tab, cfg) end
    function API:AddToggle(cfg)  return Components.Toggle(cfg.Tab, cfg) end
    function API:AddKeybind(cfg) return Components.Keybind(cfg.Tab, cfg) end
    function API:AddDropdown(cfg) return Components.Dropdown(cfg.Tab, cfg) end
    function API:AddSlider(cfg)  return Components.Slider(cfg.Tab, cfg) end
    function API:AddParagraph(cfg) return Components.Paragraph(cfg.Tab, cfg) end
    function API:Notify(cfg) notify(cfg) end

    -- finalize: open on create
    open()

    return API
end

--========================================================
-- QUICK DEMO (comment out if used as module)
--========================================================
--[[
local UI = Ecstays:CreateWindow({
    Title = "Ecstays",
    Size = Vector2.new(760, 500),
    Transparency = 0.06,
    MinimizeKeybind = Enum.KeyCode.LeftControl,
})

UI:AddTabSection({ Name = "General",  Order = 1 })
UI:AddTabSection({ Name = "Gameplay", Order = 2 })

local home = UI:AddTab({ Title = "Home", Section = "General" })
local ctrl = UI:AddTab({ Title = "Controls", Section = "Gameplay" })
UI:SetTab("Home")

UI:AddSection({ Name = "Welcome", Tab = home })
UI:AddParagraph({
    Title = "Ecstays UI",
    Description = "Clean dark theme mit pink-lilac Accent. LeftCtrl minimiert/öffnet.",
    Tab = home
})

UI:AddButton({
    Title = "Show Notification",
    Description = "Kurze Demo-Notification",
    Tab = home,
    Callback = function()
        UI:Notify({ Title = "Ecstays", Description = "Hello ✨", Duration = 2.2 })
    end
})

UI:AddInput({
    Title = "Your Name",
    Description = "Enter drücken um zu bestätigen",
    Tab = home,
    Callback = function(text)
        UI:Notify({ Title = "Hi!", Description = text == "" and "Anonymous" or text, Duration = 1.6 })
    end
})

UI:AddSection({ Name = "Gameplay", Tab = ctrl })
UI:AddToggle({
    Title = "Auto Sprint",
    Description = "Demo Toggle",
    Default = true,
    Tab = ctrl,
    Callback = function(on) print("Auto Sprint:", on) end
})

UI:AddKeybind({
    Title = "Quick Action",
    Description = "Taste/Maus setzen",
    Tab = ctrl,
    Callback = function(input) print("Keybind:", input.KeyCode or input.UserInputType) end
})

UI:AddDropdown({
    Title = "Difficulty",
    Description = "Select one",
    Options = { ["Casual"]="casual", ["Normal"]="normal", ["Hard"]="hard" },
    Tab = ctrl,
    Callback = function(choice) print("Difficulty:", choice) end
})

UI:AddSlider({
    Title = "WalkSpeed",
    Description = "0–100",
    MaxValue = 100,
    AllowDecimals = false,
    Tab = ctrl,
    Callback = function(v) print("WalkSpeed:", v) end
})
--]]

return Ecstays
