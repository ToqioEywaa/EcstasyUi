--[[
    Ecstays UI • Full Rebuild v7
    - Blue-dark Theme, rounded corners
    - Login Gate (blur background only, no darkening)
    - Discord button: blue gradient (no icons), strong hover
    - Notifications: bottom-right, above blur
    - Window: zoom open/close + smooth draggable with inertia
    - Components: Tabs/Sections, Button, Input, Toggle, Keybind, Dropdown, Slider, Paragraph
    - Only Minimize + Close buttons (top-right)
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local TweenS   = game:GetService("TweenService")
local RunS     = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LP       = Players.LocalPlayer

-- ============== helpers ==============
local function safeParent(gui)
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok then gui.Parent = LP:WaitForChild("PlayerGui") end
end

local function tw(o, t, props, style, dir)
    return TweenS:Create(
        o,
        TweenInfo.new(t, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function rc(p, r)
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, r or 14)
    u.Parent = p
    return u
end

local function st(p, th, col, tr)
    local s = Instance.new("UIStroke")
    s.Thickness = th or 1
    s.Color = col or Color3.fromRGB(70, 95, 140)
    s.Transparency = tr or .45
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function clamp01(x) return x < 0 and 0 or (x > 1 and 1 or x) end

local function roundAll(root, r)
    for _,v in ipairs(root:GetDescendants()) do
        if (v:IsA("Frame") or v:IsA("TextButton") or v:IsA("ImageLabel") or v:IsA("CanvasGroup"))
           and not v:FindFirstChildOfClass("UICorner") then
            rc(v, r or 14)
        end
    end
end

-- ============== theme ==============
local Theme = {
    Primary    = Color3.fromRGB(18, 20, 26),
    Secondary  = Color3.fromRGB(22, 25, 32),
    Panel      = Color3.fromRGB(28, 32, 40),
    Interact   = Color3.fromRGB(36, 41, 50),

    Title      = Color3.fromRGB(236, 241, 255),
    Text       = Color3.fromRGB(210, 222, 244),
    Muted      = Color3.fromRGB(164, 178, 206),

    Accent     = Color3.fromRGB(88, 165, 255),
    Accent2    = Color3.fromRGB(40, 98, 255),
    Danger     = Color3.fromRGB(255, 100, 120),
    Outline    = Color3.fromRGB(70, 95, 140),
}

-- ============== library ==============
local Ecstays = {}
Ecstays._VERSION = "7.0"

function Ecstays:CreateWindow(opt)
    opt = opt or {}
    local Size  = opt.Size or UDim2.fromOffset(660, 430)
    local Trans = math.clamp(opt.Transparency or 0.24, 0, .95)
    local Key   = opt.MinimizeKeybind or Enum.KeyCode.LeftControl

    local LOGIN = opt.LoginGate or {
        Enabled     = true,
        Title       = "Reedem Script Key",
        DiscordURL  = nil,
        PurchaseURL = nil,
        OnSubmit    = function(key, proceed, fail) proceed() end
    }

    -- ScreenGuis
    local SG = Instance.new("ScreenGui")
    SG.Name = "EcstaysUI"
    SG.IgnoreGuiInset = true
    SG.ResetOnSpawn = false
    SG.DisplayOrder = 50
    safeParent(SG)

    local SG_Notify = Instance.new("ScreenGui")
    SG_Notify.Name = "EcstaysNotify"
    SG_Notify.IgnoreGuiInset = true
    SG_Notify.ResetOnSpawn = false
    SG_Notify.DisplayOrder = 100 -- above blur & window
    safeParent(SG_Notify)

    -- ========== Notifications ==========
    local NotiRoot = Instance.new("Frame")
    NotiRoot.BackgroundTransparency = 1
    NotiRoot.AnchorPoint = Vector2.new(1,1)
    NotiRoot.Position = UDim2.new(1,-12,1,-12)
    NotiRoot.Size = UDim2.fromOffset(360, 660)
    NotiRoot.ZIndex = 100
    NotiRoot.Parent = SG_Notify

    local NL = Instance.new("UIListLayout", NotiRoot)
    NL.SortOrder = Enum.SortOrder.LayoutOrder
    NL.Padding = UDim.new(0,8)
    NL.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NL.HorizontalAlignment = Enum.HorizontalAlignment.Right

    local function Notify(cfg)
        cfg = cfg or {}
        local N = Instance.new("CanvasGroup")
        N.GroupTransparency = 1
        N.BackgroundColor3 = Theme.Secondary
        N.Size = UDim2.fromOffset(330, 74)
        N.ZIndex = 100
        N.ClipsDescendants = true
        N.Parent = NotiRoot
        rc(N,12); st(N,1,Theme.Outline,.45)

        local Bar = Instance.new("Frame")
        Bar.BackgroundColor3 = Theme.Accent
        Bar.Size = UDim2.new(0,0,0,3)
        Bar.Position = UDim2.new(0,0,1,-3)
        Bar.ZIndex = 101
        Bar.Parent = N

        local P = Instance.new("Frame")
        P.BackgroundTransparency = 1
        P.ZIndex = 101
        P.Size = UDim2.new(1,-16,1,-16)
        P.Position = UDim2.fromOffset(8,8)
        P.Parent = N

        local T = Instance.new("TextLabel")
        T.BackgroundTransparency = 1
        T.Font = Enum.Font.GothamSemibold
        T.TextXAlignment = Enum.TextXAlignment.Left
        T.TextSize = 13
        T.TextColor3 = Theme.Title
        T.ZIndex = 101
        T.Size = UDim2.new(1,0,0,18)
        T.Text = cfg.Title or "Notification"
        T.Parent = P

        local D = Instance.new("TextLabel")
        D.BackgroundTransparency = 1
        D.Font = Enum.Font.Gotham
        D.TextXAlignment = Enum.TextXAlignment.Left
        D.TextWrapped = true
        D.TextSize = 12
        D.TextColor3 = Theme.Text
        D.ZIndex = 101
        D.Position = UDim2.fromOffset(0,20)
        D.Size = UDim2.new(1,0,1,-20)
        D.Text = cfg.Description or ""
        D.Parent = P

        local dur = tonumber(cfg.Duration) or 2
        tw(N,.12,{GroupTransparency=Trans})
        tw(Bar,dur,{Size=UDim2.new(1,0,0,3)})
        task.delay(dur,function()
            tw(N,.10,{GroupTransparency=1})
            task.delay(.1,function() N:Destroy() end)
        end)
    end

    -- ========== Window ==========
    local Root = Instance.new("CanvasGroup")
    Root.Name = "Window"
    Root.ClipsDescendants = true
    Root.AnchorPoint = Vector2.new(.5,.5)
    Root.Position = UDim2.fromScale(.5,.5)
    Root.Size = Size
    Root.BackgroundColor3 = Theme.Secondary
    Root.GroupTransparency = Trans
    Root.Visible = false
    Root.Parent = SG
    rc(Root,14); local RootStroke = st(Root,1,Theme.Outline,.45)

    local Bar = Instance.new("Frame")
    Bar.ClipsDescendants = true
    Bar.BackgroundColor3 = Theme.Primary
    Bar.Size = UDim2.new(1,0,0,44)
    Bar.Parent = Root
    rc(Bar,14)

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Text = (opt.Title or "Ecstays").." • Ecstays"
    Title.Font = Enum.Font.GothamSemibold
    Title.TextSize = 15
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextColor3 = Theme.Title
    Title.Position = UDim2.fromOffset(14,0)
    Title.Size = UDim2.new(1,-140,1,0)
    Title.Parent = Bar

    local Btns = Instance.new("Frame")
    Btns.BackgroundTransparency = 1
    Btns.Size = UDim2.fromOffset(112,44)
    Btns.Position = UDim2.new(1,-112,0,0)
    Btns.Parent = Bar
    local BL = Instance.new("UIListLayout", Btns)
    BL.FillDirection = Enum.FillDirection.Horizontal
    BL.HorizontalAlignment = Enum.HorizontalAlignment.Right
    BL.VerticalAlignment = Enum.VerticalAlignment.Center
    BL.Padding = UDim.new(0,8)

    local function topBtn(name,txt,txtCol,bg)
        local B = Instance.new("TextButton")
        B.Name=name; B.AutoButtonColor=false
        B.Size=UDim2.fromOffset(44,28)
        B.BackgroundColor3=bg or Theme.Panel
        B.Text=txt; B.TextColor3=txtCol or Theme.Text
        B.Font=Enum.Font.GothamBold; B.TextSize=16
        B.Parent=Btns
        rc(B,8); local s=st(B,1,Theme.Outline,.55)
        B.MouseEnter:Connect(function()
            tw(B,.08,{BackgroundColor3=Theme.Interact})
            tw(s,.08,{Transparency=.35, Color=Theme.Accent})
        end)
        B.MouseLeave:Connect(function()
            tw(B,.10,{BackgroundColor3=bg or Theme.Panel})
            tw(s,.10,{Transparency=.55, Color=Theme.Outline})
        end)
        return B
    end

    local BtnMin   = topBtn("Minimize","–",Theme.Text)
    local BtnClose = topBtn("Close","×",Color3.fromRGB(255,130,145))

    -- Body
    local Body = Instance.new("Frame")
    Body.ClipsDescendants = true
    Body.BackgroundTransparency = 1
    Body.Size = UDim2.new(1,-16,1,-64)
    Body.Position = UDim2.fromOffset(8,52)
    Body.Parent = Root

    local Sidebar = Instance.new("Frame")
    Sidebar.ClipsDescendants = true
    Sidebar.Size = UDim2.new(0,200,1,0)
    Sidebar.BackgroundColor3 = Theme.Panel
    Sidebar.Parent = Body
    rc(Sidebar,12); st(Sidebar,1,Theme.Outline,.5)

    local Main = Instance.new("Frame")
    Main.ClipsDescendants = true
    Main.BackgroundColor3 = Theme.Panel
    Main.Size = UDim2.new(1,-208,1,0)
    Main.Position = UDim2.fromOffset(208,0)
    Main.Parent = Body
    rc(Main,12); st(Main,1,Theme.Outline,.5)

    local SideHead = Instance.new("TextLabel")
    SideHead.BackgroundTransparency = 1
    SideHead.Text = "Navigation"
    SideHead.TextColor3 = Theme.Title
    SideHead.TextXAlignment = Enum.TextXAlignment.Left
    SideHead.Font = Enum.Font.GothamSemibold
    SideHead.TextSize = 13
    SideHead.Size = UDim2.new(1,-14,0,30)
    SideHead.Position = UDim2.fromOffset(7,4)
    SideHead.Parent = Sidebar

    local TabList = Instance.new("Frame")
    TabList.BackgroundTransparency = 1
    TabList.Size = UDim2.new(1,-12,1,-40)
    TabList.Position = UDim2.fromOffset(6,34)
    TabList.Parent = Sidebar
    local TL = Instance.new("UIListLayout", TabList)
    TL.Padding = UDim.new(0,6)
    TL.SortOrder = Enum.SortOrder.LayoutOrder

    local Pages = Instance.new("Folder")
    Pages.Name = "Pages"
    Pages.Parent = Main

    -- Open / Close (zoom)
    local function open()
        Root.Visible = true
        Root.GroupTransparency = 1
        local sz = Root.Size
        Root.Size = UDim2.new(sz.X, UDim.new(0, math.floor(sz.Y.Offset*0.93)))
        tw(Root,.18,{Size=sz},Enum.EasingStyle.Quad)
        tw(Root,.18,{GroupTransparency=Trans},Enum.EasingStyle.Sine)
    end
    local function close()
        local sz = Root.Size
        tw(Root,.14,{GroupTransparency=1},Enum.EasingStyle.Sine)
        tw(Root,.14,{Size=UDim2.new(sz.X, UDim.new(0, math.floor(sz.Y.Offset*0.93)))},Enum.EasingStyle.Quad)
        task.wait(.14)
        Root.Visible=false; Root.Size=sz; Root.GroupTransparency=Trans
    end

    -- Drag with inertia
    do
        local DragHandle = Instance.new("Frame")
        DragHandle.BackgroundTransparency = 1
        DragHandle.Size = UDim2.new(1,-120,1,0)
        DragHandle.Parent = Bar
        DragHandle.Active = true

        local dragging=false; local startOff=Vector2.new(); local vel=Vector2.new(); local last=Vector2.new(); local lastT=0
        local minSpeed=18

        local function mpos()
            local m=UIS:GetMouseLocation()
            return Vector2.new(m.X,m.Y)
        end

        DragHandle.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            if UIS:GetFocusedTextBox() then return end
            dragging=true
            local m=mpos()
            startOff = m - Vector2.new(Root.AbsolutePosition.X, Root.AbsolutePosition.Y)
            last = m; lastT = tick(); vel = Vector2.new()
            tw(Root,.08,{GroupTransparency=math.clamp(Trans+0.12,0,.95)})
        end)

        UIS.InputChanged:Connect(function(i)
            if not dragging or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            local m=mpos()
            local newPos = m - startOff
            Root.Position = UDim2.fromOffset(newPos.X, newPos.Y)
            local now=tick(); local dt=now-lastT
            if dt>0 then vel = vel*0.90 + (m-last)/dt*0.10 end
            last=m; lastT=now
        end)

        UIS.InputEnded:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 or not dragging then return end
            dragging=false; tw(Root,.10,{GroupTransparency=Trans})
            local step; step = RunS.RenderStepped:Connect(function(dt)
                vel = vel * 0.90
                if vel.Magnitude < minSpeed then step:Disconnect(); return end
                local p = Vector2.new(Root.Position.X.Offset, Root.Position.Y.Offset) + vel * dt
                Root.Position = UDim2.fromOffset(p.X, p.Y)
            end)
        end)
    end

    BtnMin.MouseButton1Click:Connect(function() Root.Visible=false end)
    BtnClose.MouseButton1Click:Connect(close)
    UIS.InputBegan:Connect(function(i,gp)
        if gp then return end
        if i.KeyCode == Key then
            if Root.Visible then Root.Visible=false else open() end
        end
    end)

    -- Tabs
    local Stored, Current = { Sections = {}, Tabs = {} }, nil

    local function makeTabBtn(name, order)
        local B=Instance.new("TextButton")
        B.AutoButtonColor=false; B.Name=name; B.Text=""; B.LayoutOrder=order or 999
        B.Size=UDim2.new(1,0,0,30); B.BackgroundColor3=Theme.Interact; B.Parent=TabList
        rc(B,10); local s=st(B,1,Theme.Outline,.5)
        local T=Instance.new("TextLabel")
        T.BackgroundTransparency=1; T.Font=Enum.Font.Gotham
        T.TextXAlignment=Enum.TextXAlignment.Left; T.TextSize=13
        T.TextColor3=Theme.Text; T.Text=name; T.Size=UDim2.new(1,-16,1,0)
        T.Position=UDim2.fromOffset(8,0); T.Parent=B
        B.MouseEnter:Connect(function() tw(B,.08,{BackgroundColor3=Theme.Panel}); tw(s,.08,{Transparency=.35, Color=Theme.Accent}) end)
        B.MouseLeave:Connect(function() tw(B,.10,{BackgroundColor3=Theme.Interact}); tw(s,.10,{Transparency=.5, Color=Theme.Outline}) end)
        return B
    end

    local function makePage(name)
        local P=Instance.new("CanvasGroup")
        P.Name=name; P.BackgroundTransparency=1; P.GroupTransparency=0; P.Visible=false
        P.ClipsDescendants=true
        P.Size=UDim2.new(1,-16,1,-16)
        P.Position=UDim2.fromOffset(8,8)
        P.Parent=Pages
        local S=Instance.new("ScrollingFrame")
        S.Active=true; S.BackgroundTransparency=1; S.BorderSizePixel=0
        S.ScrollBarThickness=4; S.ScrollBarImageTransparency=.15; S.ScrollBarImageColor3=Theme.Interact
        S.Size=UDim2.new(1,0,1,0); S.Parent=P
        local L=Instance.new("UIListLayout",S); L.Padding=UDim.new(0,8)
        local Pad=Instance.new("UIPadding",S); Pad.PaddingTop=UDim.new(0,8); Pad.PaddingLeft=UDim.new(0,8); Pad.PaddingRight=UDim.new(0,8); Pad.PaddingBottom=UDim.new(0,8)
        L:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            S.CanvasSize = UDim2.new(0,0,0,L.AbsoluteContentSize.Y+16)
        end)
        return P,S
    end

    local function setTab(name)
        for k,v in pairs(Stored.Tabs) do
            if k == name then
                if not v.Page.Visible then v.Page.Visible=true; tw(v.Page,.14,{GroupTransparency=0}) end
                tw(v.Button,.08,{BackgroundColor3=Theme.Panel})
            else
                if v.Page.Visible then tw(v.Page,.10,{GroupTransparency=1}); task.delay(.10,function() v.Page.Visible=false end) end
                tw(v.Button,.10,{BackgroundColor3=Theme.Interact})
            end
        end
        Current = name
    end

    local API = {}

    function API:AddTabSection(s) Stored.Sections[s.Name]=s.Order or (#Stored.Sections+1) end
    function API:AddTab(s)
        if Stored.Tabs[s.Title] then error("[Ecstays] Tab exists: "..s.Title) end
        local btn = makeTabBtn(s.Title, Stored.Sections[s.Section] or 999)
        local page,scroll = makePage(s.Title)
        Stored.Tabs[s.Title] = { Button=btn, Page=page, Scroll=scroll }
        btn.MouseButton1Click:Connect(function() setTab(s.Title) end)
        if not Current then setTab(s.Title) end
        return scroll
    end
    function API:SetTab(n) if Stored.Tabs[n] then setTab(n) end end

    -- component helpers
    local function row(parent,h) local R=Instance.new("Frame"); R.ClipsDescendants=true; R.BackgroundColor3=Theme.Panel; R.Size=UDim2.new(1,0,0,h); R.Parent=parent; rc(R,10); st(R,1,Theme.Outline,.5); return R end
    local function labels(r,title,desc,rw)
        local L=Instance.new("Frame"); L.BackgroundTransparency=1; L.Position=UDim2.fromOffset(10,8); L.Size=UDim2.new(1,-((rw or 0)+28),1,-16); L.Parent=r
        local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.GothamSemibold; T.TextXAlignment=Enum.TextXAlignment.Left; T.TextSize=13; T.TextColor3=Theme.Title; T.Text=title or "Title"; T.Size=UDim2.new(1,0,0,18); T.Parent=L
        local D=Instance.new("TextLabel"); D.BackgroundTransparency=1; D.Font=Enum.Font.Gotham; D.TextXAlignment=Enum.TextXAlignment.Left; D.TextWrapped=true; D.TextSize=12; D.TextColor3=Theme.Muted; D.Text=desc or ""; D.Position=UDim2.fromOffset(0,20); D.Size=UDim2.new(1,0,1,-20); D.Parent=L
        return T,D
    end
    local function right(r,w,h) local S=Instance.new("Frame"); S.BackgroundTransparency=1; S.Size=UDim2.fromOffset(w,h); S.AnchorPoint=Vector2.new(1,.5); S.Position=UDim2.new(1,-10,.5,0); S.Parent=r; return S end

    function API:AddSection(s)
        local R=row(s.Tab,28)
        local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.GothamSemibold; T.TextSize=13; T.TextXAlignment=Enum.TextXAlignment.Left; T.TextColor3=Theme.Title; T.Text=s.Name or "Section"; T.Size=UDim2.new(1,-10,1,0); T.Position=UDim2.fromOffset(10,0); T.Parent=R
        return R
    end

    function API:AddButton(s)
        local RW=124; local R=row(s.Tab,56); labels(R,s.Title,s.Description,RW); local slot=right(R,RW,30)
        local B=Instance.new("TextButton"); B.AutoButtonColor=false; B.BackgroundColor3=Theme.Interact; B.Text="Execute"; B.TextColor3=Theme.Title; B.Font=Enum.Font.GothamBold; B.TextSize=13; B.Size=UDim2.fromScale(1,1); B.Parent=slot; rc(B,10); st(B,1,Theme.Outline,.5)
        B.MouseEnter:Connect(function() tw(B,.08,{BackgroundColor3=Theme.Panel}) end)
        B.MouseLeave:Connect(function() tw(B,.10,{BackgroundColor3=Theme.Interact}) end)
        B.MouseButton1Click:Connect(function() if s.Callback then pcall(s.Callback) end end)
        return R
    end

    function API:AddInput(s)
        local RW=230; local R=row(s.Tab,62); labels(R,s.Title,s.Description,RW); local slot=right(R,RW,30)
        local Box=Instance.new("TextBox"); Box.ClearTextOnFocus=false; Box.BackgroundColor3=Theme.Interact; Box.TextColor3=Theme.Title; Box.PlaceholderText=s.Placeholder or "type here…"; Box.Font=Enum.Font.Gotham; Box.TextSize=13; Box.Size=UDim2.fromScale(1,1); Box.Parent=slot; rc(Box,10); st(Box,1,Theme.Outline,.5)
        Box.Focused:Connect(function() tw(Box,.08,{BackgroundColor3=Theme.Panel}) end)
        Box.FocusLost:Connect(function(enter) tw(Box,.10,{BackgroundColor3=Theme.Interact}); if enter and s.Callback then pcall(function() s.Callback(Box.Text) end) end end)
        return R
    end

    function API:AddToggle(s)
        local RW=66; local R=row(s.Tab,56); labels(R,s.Title,s.Description,RW); local slot=right(R,RW,28)
        local Back=Instance.new("Frame"); Back.Size=UDim2.fromScale(1,1); Back.BackgroundColor3=Theme.Interact; Back.Parent=slot; rc(Back,14); st(Back,1,Theme.Outline,.5)
        local Dot=Instance.new("Frame"); Dot.Size=UDim2.fromOffset(24,24); Dot.Position=UDim2.fromOffset(2,2); Dot.BackgroundColor3=Theme.Secondary; Dot.Parent=Back; rc(Dot,12)
        local state = s.Default == true
        local function set(v)
            state = v and true or false
            if state then tw(Back,.10,{BackgroundColor3=Theme.Accent2}); tw(Dot,.10,{Position=UDim2.fromOffset(RW-2-24,2), BackgroundColor3=Color3.fromRGB(255,255,255)})
            else tw(Back,.10,{BackgroundColor3=Theme.Interact}); tw(Dot,.10,{Position=UDim2.fromOffset(2,2), BackgroundColor3=Theme.Secondary}) end
        end
        set(state)
        R.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then set(not state); if s.Callback then pcall(function() s.Callback(state) end) end
            end
        end)
        return R
    end

    function API:AddKeybind(s)
        local RW=138; local R=row(s.Tab,56); labels(R,s.Title,s.Description,RW); local slot=right(R,RW,30)
        local Btn=Instance.new("TextButton"); Btn.AutoButtonColor=false; Btn.BackgroundColor3=Theme.Interact; Btn.Text="Set Key"; Btn.TextColor3=Theme.Title; Btn.Font=Enum.Font.GothamBold; Btn.TextSize=13; Btn.Size=UDim2.fromScale(1,1); Btn.Parent=slot; rc(Btn,10); st(Btn,1,Theme.Outline,.5)
        local cap=false
        Btn.MouseButton1Click:Connect(function()
            if cap then return end; cap=true; Btn.Text="..."
            local con; con = UIS.InputBegan:Connect(function(input,gp)
                if gp then return end; cap=false
                local label = input.UserInputType==Enum.UserInputType.Keyboard
                    and tostring(input.KeyCode):gsub("Enum.KeyCode.","")
                    or tostring(input.UserInputType):gsub("Enum.UserInputType.","")
                Btn.Text=label; if s.Callback then pcall(function() s.Callback(input) end) end
                if con then con:Disconnect() end
            end)
        end)
        return R
    end

    function API:AddDropdown(s)
        local RW=230; local R=row(s.Tab,64); labels(R,s.Title,s.Description,RW); local slot=right(R,RW,30)
        local Btn=Instance.new("TextButton"); Btn.AutoButtonColor=false; Btn.BackgroundColor3=Theme.Interact; Btn.Text=""; Btn.Size=UDim2.fromScale(1,1); Btn.Parent=slot; rc(Btn,10); st(Btn,1,Theme.Outline,.5)
        local TL=Instance.new("TextLabel"); TL.BackgroundTransparency=1; TL.Font=Enum.Font.Gotham; TL.TextXAlignment=Enum.TextXAlignment.Left; TL.TextSize=13; TL.TextColor3=Theme.Title; TL.Text=s.Placeholder or "Select…"; TL.Size=UDim2.new(1,-22,1,0); TL.Position=UDim2.fromOffset(8,0); TL.Parent=Btn
        local Arrow=Instance.new("TextLabel"); Arrow.BackgroundTransparency=1; Arrow.Font=Enum.Font.GothamBold; Arrow.TextSize=14; Arrow.TextColor3=Theme.Muted; Arrow.Text="▼"; Arrow.Size=UDim2.fromOffset(18,18); Arrow.Position=UDim2.new(1,-20,0,6); Arrow.Parent=Btn
        local Open,Pop=false,nil
        local function closeP() if not Pop then return end; tw(Pop,.10,{GroupTransparency=1}); task.delay(.1,function() if Pop then Pop:Destroy(); Pop=nil end end); Open=false end
        local function openP()
            if Open then closeP() return end; Open=true
            Pop=Instance.new("CanvasGroup"); Pop.GroupTransparency=1; Pop.BackgroundColor3=Theme.Secondary; Pop.ClipsDescendants=true; Pop.Size=UDim2.fromOffset(240,210)
            Pop.Position=UDim2.new(0, Btn.AbsolutePosition.X-Root.AbsolutePosition.X, 0, Btn.AbsolutePosition.Y-Root.AbsolutePosition.Y+34); Pop.Parent=Root; rc(Pop,12); st(Pop,1,Theme.Outline,.45)
            local S=Instance.new("ScrollingFrame"); S.Active=true; S.BorderSizePixel=0; S.BackgroundTransparency=1; S.ScrollBarThickness=4; S.ScrollBarImageTransparency=.1; S.ScrollBarImageColor3=Theme.Interact; S.Size=UDim2.new(1,-10,1,-10); S.Position=UDim2.fromOffset(5,5); S.Parent=Pop
            local L=Instance.new("UIListLayout",S); L.Padding=UDim.new(0,6)
            for k,v in pairs(s.Options or {}) do
                local O=Instance.new("TextButton"); O.AutoButtonColor=false; O.Size=UDim2.new(1,0,0,28); O.Text=""; O.BackgroundColor3=Theme.Panel; O.Parent=S; rc(O,10); st(O,1,Theme.Outline,.45)
                local OTL=Instance.new("TextLabel"); OTL.BackgroundTransparency=1; OTL.Font=Enum.Font.Gotham; OTL.TextXAlignment=Enum.TextXAlignment.Left; OTL.TextSize=12; OTL.TextColor3=Theme.Text; OTL.Text=tostring(k); OTL.Size=UDim2.new(1,-10,1,0); OTL.Position=UDim2.fromOffset(6,0); OTL.Parent=O
                O.MouseButton1Click:Connect(function() TL.Text=tostring(k); closeP(); if s.Callback then pcall(function() s.Callback(v) end) end end)
            end
            tw(Pop,.12,{GroupTransparency=0})
        end
        Btn.MouseButton1Click:Connect(openP)
        UIS.InputBegan:Connect(function(i,gp)
            if gp or not Open or not Pop then return end
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                local p=UIS:GetMouseLocation(); local x,y=Pop.AbsolutePosition.X,Pop.AbsolutePosition.Y; local x2,y2=x+Pop.AbsoluteSize.X, y+Pop.AbsoluteSize.Y
                if not (p.X>=x and p.X<=x2 and p.Y>=y and p.Y<=y2) then closeP() end
            end
        end)
        return R
    end

    function API:AddSlider(s)
        local RW=116; local R=row(s.Tab,74); labels(R,s.Title,s.Description,RW)
        local Track=Instance.new("Frame"); Track.BackgroundColor3=Theme.Interact; Track.Size=UDim2.new(1,-(RW+32),0,8); Track.Position=UDim2.new(0,10,1,-18); Track.Parent=R; rc(Track,4)
        local Fill=Instance.new("Frame"); Fill.BackgroundColor3=Theme.Accent2; Fill.Size=UDim2.fromScale(0,1); Fill.Parent=Track; rc(Fill,4)
        local Knob=Instance.new("Frame"); Knob.Size=UDim2.fromOffset(16,16); Knob.AnchorPoint=Vector2.new(.5,.5); Knob.Position=UDim2.new(0,0,.5,0); Knob.BackgroundColor3=Color3.fromRGB(255,255,255); Knob.Parent=Track; rc(Knob,8); st(Knob,1,Theme.Outline,.4)
        local slot=right(R,RW,30); local Box=Instance.new("TextBox"); Box.Size=UDim2.fromScale(1,1); Box.BackgroundColor3=Theme.Interact; Box.TextColor3=Theme.Title; Box.PlaceholderText="0"; Box.Text="0"; Box.Font=Enum.Font.Gotham; Box.TextSize=13; Box.Parent=slot; rc(Box,10); st(Box,1,Theme.Outline,.5)
        local max=tonumber(s.MaxValue) or 100; local dec=s.AllowDecimals==true; local prec=tonumber(s.DecimalAmount) or 2
        local function fmt(n) if dec then local p=10^prec n=math.floor(n*p+0.5)/p return tostring(n) else return tostring(math.floor(n+0.5)) end end
        local function setv(n) n=math.clamp(n,0,max); local sc=(max==0) and 0 or (n/max); Fill.Size=UDim2.fromScale(sc,1); Knob.Position=UDim2.new(sc,0,.5,0); Box.Text=fmt(n); if s.Callback then pcall(function() s.Callback(n) end) end end
        local dragging=false
        local function mval() local m=UIS:GetMouseLocation(); local x0=Track.AbsolutePosition.X; local w=Track.AbsoluteSize.X; return clamp01((m.X-x0)/w)*max end
        Track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; setv(mval()) end end)
        UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then setv(mval()) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
        Box.FocusLost:Connect(function(enter) if enter then setv(tonumber(Box.Text) or 0) end end)
        setv(tonumber(s.Default) or 0); return R
    end

    function API:AddParagraph(s)
        local R=row(s.Tab,116); local _,D=labels(R,s.Title,s.Description,0); D.TextWrapped=true; return R
    end

    function API:Notify(c) Notify(c) end
    function API:SetTheme(tbl)
        for k,v in pairs(tbl or {}) do Theme[k]=v end
        Root.BackgroundColor3=Theme.Secondary; Bar.BackgroundColor3=Theme.Primary
        Sidebar.BackgroundColor3=Theme.Panel; Main.BackgroundColor3=Theme.Panel
        RootStroke.Color=Theme.Outline; Title.TextColor3=Theme.Title
    end
    function API:SetSetting(k,v)
        if k=="Transparency" then Trans=math.clamp(v or Trans,0,.95); Root.GroupTransparency=Trans
        elseif k=="Size" then Size=v; Root.Size=v
        elseif k=="Theme" and typeof(v)=="table" then API:SetTheme(v)
        elseif k=="Keybind" then Key=v end
    end
    function API:Show() open() end
    function API:Hide() Root.Visible=false end
    function API:Destroy() SG:Destroy(); SG_Notify:Destroy() end

    -- ========== Login Gate (Blur, blue Discord button, rounded) ==========
    local function showGate()
        if not LOGIN.Enabled then open(); return end

        -- Blur only (brightness unchanged)
        local Blur = Instance.new("BlurEffect")
        Blur.Size = 0
        Blur.Parent = Lighting
        tw(Blur,.14,{Size=12})

        local Modal = Instance.new("CanvasGroup")
        Modal.AnchorPoint = Vector2.new(.5,.5)
        Modal.Position = UDim2.fromScale(.5,.5)
        Modal.Size = UDim2.fromOffset(840, 370)
        Modal.GroupTransparency = 1
        Modal.Parent = SG

        local Card = Instance.new("Frame")
        Card.Size = UDim2.fromScale(1,1)
        Card.BackgroundColor3 = Theme.Secondary
        Card.ClipsDescendants = true
        Card.Parent = Modal
        rc(Card,18); st(Card,1,Theme.Outline,.4)

        local BGF = Instance.new("Frame")
        BGF.Size = UDim2.fromScale(1,1)
        BGF.BackgroundColor3 = Theme.Secondary
        BGF.Parent = Card
        local Grad = Instance.new("UIGradient", BGF)
        Grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(14,18,28)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(20,28,44)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(10,14,22)),
        })

        local CloseX = Instance.new("TextButton")
        CloseX.AutoButtonColor=false
        CloseX.Text="×"; CloseX.TextSize=20; CloseX.Font=Enum.Font.GothamBold
        CloseX.TextColor3=Theme.Text
        CloseX.BackgroundTransparency=1
        CloseX.Size=UDim2.fromOffset(28,28)
        CloseX.Position=UDim2.new(1,-36,0,8)
        CloseX.Parent=Card
        CloseX.MouseButton1Click:Connect(function()
            tw(Modal,.12,{GroupTransparency=1}); tw(Blur,.12,{Size=0})
            task.delay(.12,function() Modal:Destroy(); Blur:Destroy() end)
        end)

        local H1 = Instance.new("TextLabel")
        H1.BackgroundTransparency=1
        H1.Font=Enum.Font.GothamBlack
        H1.TextSize=28
        H1.TextXAlignment=Enum.TextXAlignment.Left
        H1.TextColor3=Theme.Title
        H1.Text = LOGIN.Title or "Reedem Script Key"
        H1.Position=UDim2.fromOffset(26,18)
        H1.Size=UDim2.new(1,-44,0,32)
        H1.Parent=Card

        local Links = Instance.new("TextLabel")
        Links.BackgroundTransparency=1
        Links.Font=Enum.Font.Gotham
        Links.RichText = true
        Links.TextSize=13
        Links.TextXAlignment=Enum.TextXAlignment.Left
        Links.TextColor3=Theme.Muted
        Links.Text = 'The Key link has been copied if not <font color="#4BA3FF"><u>click here</u></font> to copy  '..
                     'Want to purchase subscription instead? <font color="#4BA3FF"><u>Click to purchase</u></font>'
        Links.Position=UDim2.fromOffset(26,58)
        Links.Size=UDim2.new(1,-52,0,40)
        Links.Parent=Card

        local LinkCopy = Instance.new("TextButton")
        LinkCopy.BackgroundTransparency=1; LinkCopy.Text=""; LinkCopy.AutoButtonColor=false
        LinkCopy.Size=UDim2.fromOffset(130,18); LinkCopy.Position=UDim2.fromOffset(375,58); LinkCopy.Parent=Card
        local LinkBuy = Instance.new("TextButton")
        LinkBuy.BackgroundTransparency=1; LinkBuy.Text=""; LinkBuy.AutoButtonColor=false
        LinkBuy.Size=UDim2.fromOffset(150,18); LinkBuy.Position=UDim2.fromOffset(640,58); LinkBuy.Parent=Card

        local Row = Instance.new("Frame")
        Row.BackgroundTransparency=1
        Row.Size=UDim2.new(1,-52,0,66)
        Row.Position=UDim2.fromOffset(26,108)
        Row.Parent=Card

        local Field = Instance.new("Frame")
        Field.BackgroundColor3 = Theme.Interact
        Field.Size = UDim2.new(1,0,1,0)
        Field.ClipsDescendants = true
        Field.Parent = Row
        rc(Field,16); st(Field,1,Theme.Outline,.45)

        -- Eye removed – simple show/hide button on the right of text
        local Box = Instance.new("TextBox")
        Box.ClearTextOnFocus=false
        Box.BackgroundTransparency=1
        Box.TextColor3=Theme.Title
        Box.PlaceholderText="Elternative Library Key"
        Box.PlaceholderColor3=Theme.Muted
        Box.Font=Enum.Font.Gotham
        Box.TextSize=16
        Box.TextXAlignment=Enum.TextXAlignment.Left
        Box.Text=""
        Box.Position=UDim2.fromOffset(16,0)
        Box.Size=UDim2.new(1,-140,1,0)
        Box.Parent=Field

        local ToggleMask = Instance.new("TextButton")
        ToggleMask.AutoButtonColor=false
        ToggleMask.Text = "• • •"
        ToggleMask.TextSize = 16
        ToggleMask.Font = Enum.Font.GothamBold
        ToggleMask.TextColor3 = Theme.Text
        ToggleMask.BackgroundTransparency=1
        ToggleMask.Size=UDim2.fromOffset(46,44)
        ToggleMask.Position=UDim2.new(1,-102,.5,-22)
        ToggleMask.Parent=Field

        local Submit = Instance.new("TextButton")
        Submit.AutoButtonColor=false
        Submit.Text="✓"; Submit.TextSize=18; Submit.Font=Enum.Font.GothamBold
        Submit.TextColor3=Color3.fromRGB(255,255,255)
        Submit.BackgroundColor3=Theme.Accent2
        Submit.Size=UDim2.fromOffset(54,48)
        Submit.Position=UDim2.new(1,-54-12,.5,-24)
        Submit.Parent=Field
        rc(Submit,12)

        local Hidden, Real = false, ""
        local function sync()
            if Hidden then
                Real = Box.Text
                Box.Text = string.rep("•", utf8.len(Real) or #Real)
            else
                Box.Text = Real ~= "" and Real or Box.Text
            end
        end
        ToggleMask.MouseButton1Click:Connect(function() Hidden = not Hidden; sync() end)
        Box:GetPropertyChangedSignal("Text"):Connect(function()
            if Hidden then
                Real = Real .. "" -- keep
            else
                Real = Box.Text
            end
        end)

        local Error = Instance.new("TextLabel")
        Error.BackgroundTransparency=1
        Error.Font=Enum.Font.Gotham
        Error.TextSize=12
        Error.TextColor3=Theme.Danger
        Error.TextXAlignment=Enum.TextXAlignment.Left
        Error.Text = ""
        Error.Position = UDim2.fromOffset(28, 268)
        Error.Size = UDim2.new(1,-56,0,18)
        Error.Parent = Card

        -- Discord Button (blue, rounded, strong hover)
        local Discord = Instance.new("TextButton")
        Discord.AutoButtonColor=false
        Discord.BackgroundTransparency = 1
        Discord.Size = UDim2.new(1,-52,0,66)
        Discord.Position = UDim2.fromOffset(26, 192)
        Discord.Text = ""
        Discord.Parent = Card

        local BG = Instance.new("Frame")
        BG.Size = UDim2.fromScale(1,1)
        BG.BackgroundColor3 = Theme.Accent2
        BG.Parent = Discord
        rc(BG,16)

        local g = Instance.new("UIGradient", BG)
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(54,122,255)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(46,110,255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(36, 95,240)),
        })

        local wrap = Instance.new("Frame")
        wrap.BackgroundTransparency=1
        wrap.Size=UDim2.fromScale(1,1)
        wrap.Parent=Discord
        rc(wrap,16)
        local stroke = st(wrap,1,Color3.fromRGB(255,255,255),.82)

        local T1 = Instance.new("TextLabel")
        T1.BackgroundTransparency=1
        T1.Font=Enum.Font.GothamBlack
        T1.TextSize=20
        T1.TextXAlignment=Enum.TextXAlignment.Left
        T1.TextColor3=Color3.fromRGB(255,255,255)
        T1.Text = "Discord"
        T1.Position=UDim2.fromOffset(18,10)
        T1.Size=UDim2.new(1,-36,0,22)
        T1.Parent=Discord

        local T2 = Instance.new("TextLabel")
        T2.BackgroundTransparency=1
        T2.Font=Enum.Font.Gotham
        T2.TextSize=13
        T2.TextXAlignment=Enum.TextXAlignment.Left
        T2.TextColor3=Color3.fromRGB(230,240,255)
        T2.Text = "Tap to join our server for updates and news"
        T2.Position=UDim2.fromOffset(18,34)
        T2.Size=UDim2.new(1,-36,0,20)
        T2.Parent=Discord

        local Scale = Instance.new("UIScale", Discord); Scale.Scale = 1
        Discord.MouseEnter:Connect(function()
            tw(Scale,.10,{Scale=1.02}); tw(g,.10,{Rotation=8}); tw(stroke,.10,{Transparency=.65})
        end)
        Discord.MouseLeave:Connect(function()
            tw(Scale,.10,{Scale=1}); tw(g,.10,{Rotation=0}); tw(stroke,.10,{Transparency=.82})
        end)
        Discord.MouseButton1Down:Connect(function() tw(g,.06,{Rotation=12}) end)
        Discord.MouseButton1Up:Connect(function() tw(g,.12,{Rotation=8}) end)
        Discord.MouseButton1Click:Connect(function()
            if LOGIN.DiscordURL and setclipboard then
                setclipboard(LOGIN.DiscordURL)
                Notify({ Title="Discord", Description="Invite copied. Paste in browser.", Duration=2 })
            else
                Notify({ Title="Discord", Description="No invite configured.", Duration=2 })
            end
        end)

        LinkCopy.MouseButton1Click:Connect(function()
            if setclipboard then
                local txt = Hidden and Real or Box.Text
                setclipboard(txt)
            end
            Notify({Title="Key", Description="Key copied.", Duration=1.6})
        end)
        LinkBuy.MouseButton1Click:Connect(function()
            if LOGIN.PurchaseURL and setclipboard then setclipboard(LOGIN.PurchaseURL) end
            Notify({Title="Purchase", Description="Purchase link copied.", Duration=1.6})
        end)

        local function proceed()
            tw(Modal,.12,{GroupTransparency=1}); tw(Blur,.12,{Size=0})
            task.delay(.12,function() Modal:Destroy(); Blur:Destroy(); open() end)
        end
        local function fail(msg) Error.Text = msg or "Invalid key."; tw(Error,.08,{TextTransparency=0}) end
        local function doSubmit()
            local key = Hidden and Real or Box.Text
            if LOGIN.OnSubmit then
                local ok = pcall(function() LOGIN.OnSubmit(key, proceed, fail) end)
                if not ok then fail("Validation error") end
            else proceed() end
        end
        Submit.MouseButton1Click:Connect(doSubmit)
        Box.FocusLost:Connect(function(enter) if enter then doSubmit() end end)

        tw(Modal,.14,{GroupTransparency=Trans})
        roundAll(Card, 18)
    end

    -- init:
    roundAll(Root, 14)
    showGate()

    return API
end

return Ecstays
