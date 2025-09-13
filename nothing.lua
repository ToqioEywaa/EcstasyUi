--[[
    Ecstays UI Library – 2025 clean rebuild (closer to original, but fixed & modern)
    - Clean dark + pink–lilac accent
    - More transparent by default (and extra while dragging)
    - Stable drag (no teleport): absolute-offset drag, inertial glide on release
    - Zoom open/close
    - Only Minimize & Close (top-right, large, clean)
    - Full controls: Tabs, Section, Button, Input, Toggle, Keybind, Dropdown, Slider, Paragraph, Notify
    - Theming & Settings
    - No external assets
]]

if not game:IsLoaded() then game.Loaded:Wait() end

--== Services ==--
local Players = game:GetService("Players")
local Tween   = game:GetService("TweenService")
local UIS     = game:GetService("UserInputService")
local Run     = game:GetService("RunService")
local LP      = Players.LocalPlayer

--== Utils ==--
local function safeParent(gui)
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok then gui.Parent = LP:WaitForChild("PlayerGui") end
end
local function tplay(inst, t, props, style, dir)
    return Tween:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.Out), props):Play()
end
local function tint(c, by, mode)
    local r,g,b = c.R*255, c.G*255, c.B*255
    if mode == "down" then return Color3.fromRGB(math.max(0,r-by), math.max(0,g-by), math.max(0,b-by)) end
    return Color3.fromRGB(math.min(255,r+by), math.min(255,g+by), math.min(255,b+by))
end
local function newRound(p, r) local u=Instance.new("UICorner");u.CornerRadius=UDim.new(0,r or 10);u.Parent=p;return u end
local function newStroke(p, thk, col, tr) local s=Instance.new("UIStroke");s.Thickness=thk or 1;s.Color=col or Color3.fromRGB(70,60,92);s.Transparency=tr or .6;s.Parent=p;return s end
local function px(n) return UDim.new(0,n) end
local function clamp01(x) return x<0 and 0 or (x>1 and 1 or x) end
local function clampToViewport(guiObj)
    local cam=workspace.CurrentCamera;if not cam then return end
    local vp=cam.ViewportSize; local abs=guiObj.AbsoluteSize
    local x=math.clamp(guiObj.Position.X.Offset,0,math.max(0,vp.X-abs.X))
    local y=math.clamp(guiObj.Position.Y.Offset,0,math.max(0,vp.Y-abs.Y))
    guiObj.Position=UDim2.fromOffset(x,y)
end

--== Theme (closer to original, but refined) ==--
local DEFAULT_THEME = {
    Primary       = Color3.fromRGB(22, 20, 26),  -- titlebar
    Secondary     = Color3.fromRGB(28, 26, 34),  -- window
    Tertiary      = Color3.fromRGB(34, 31, 40),  -- components / panels
    Interact      = Color3.fromRGB(42, 38, 50),  -- hoverable/inputs

    Title         = Color3.fromRGB(244, 240, 250),
    Text          = Color3.fromRGB(218, 214, 226),
    Muted         = Color3.fromRGB(188, 184, 198),

    Stroke        = Color3.fromRGB(90, 72, 112), -- lavender-ish
    Icon          = Color3.fromRGB(234, 222, 246),

    Accent        = Color3.fromRGB(206, 99, 255),
    AccentSoft    = Color3.fromRGB(164, 88, 230),

    Danger        = Color3.fromRGB(255, 92, 128),
    Success       = Color3.fromRGB(120, 230, 170),
}

--== Library ==--
local Ecstays = {}
Ecstays._VERSION = "3.2"

function Ecstays:CreateWindow(opts)
    opts = opts or {}
    local Theme   = opts.ThemeTable or DEFAULT_THEME
    local Title   = opts.Title or "Ecstays"
    local WSize   = opts.Size or Vector2.new(760, 500)
    -- mehr Transparenz by default:
    local BaseT   = math.clamp(tonumber(opts.Transparency) or 0.18, 0, .95)
    local Key     = opts.MinimizeKeybind or Enum.KeyCode.LeftControl

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
    Root.Position = UDim2.fromOffset(120, 120)
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
    BarMask.Size = UDim2.new(1,0,0,14)
    BarMask.Parent = Bar

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Position = UDim2.fromOffset(16,0)
    TitleLbl.Size = UDim2.new(1,-140,1,0)
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Font = Enum.Font.GothamSemibold
    TitleLbl.TextSize = 16
    TitleLbl.TextColor3 = Theme.Title
    TitleLbl.Text = Title .. " • Ecstays"
    TitleLbl.Parent = Bar

    -- Top-right Buttons
    local Btns = Instance.new("Frame")
    Btns.BackgroundTransparency = 1
    Btns.Size = UDim2.fromOffset(120,44)
    Btns.Position = UDim2.new(1,-120,0,0)
    Btns.Parent = Bar
    local btnLayout = Instance.new("UIListLayout", Btns)
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    btnLayout.Padding = UDim.new(0,10)

    local function makeTopBtn(name, text, color)
        local B=Instance.new("TextButton")
        B.Name=name; B.AutoButtonColor=false
        B.Size=UDim2.fromOffset(40,28)
        B.BackgroundColor3=tint(Theme.Secondary,6,"down")
        B.Font=Enum.Font.GothamBold; B.TextSize=16
        B.TextColor3=color or Theme.Text; B.Text=text
        B.Parent=Btns; newRound(B,8)
        local s=newStroke(B,1,Theme.Stroke,.65)
        B.MouseEnter:Connect(function()
            tplay(B,.10,{BackgroundColor3=Theme.Interact})
            tplay(s,.10,{Transparency=.42,Color=Theme.Accent})
        end)
        B.MouseLeave:Connect(function()
            tplay(B,.12,{BackgroundColor3=tint(Theme.Secondary,6,"down")})
            tplay(s,.12,{Transparency=.65,Color=Theme.Stroke})
        end)
        -- wichtig: Buttons „schlucken“ Titlebar-Klicks (verhindert Drag-Teleport)
        B.InputBegan:Connect(function() end)
        return B
    end

    local BtnMin   = makeTopBtn("Minimize","–",Theme.Text)
    local BtnClose = makeTopBtn("Close","×",Theme.Danger)

    -- Body (Sidebar + Main) – näher am Original
    local Body = Instance.new("Frame")
    Body.BackgroundTransparency=1
    Body.Size=UDim2.new(1,-20,1,-64)
    Body.Position=UDim2.fromOffset(10,54)
    Body.Parent=Root

    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0,204,1,0)
    Sidebar.BackgroundColor3 = Theme.Tertiary
    Sidebar.Parent = Body
    newRound(Sidebar,12); newStroke(Sidebar,1,Theme.Stroke,.6)

    local SideHeader = Instance.new("TextLabel")
    SideHeader.BackgroundTransparency=1
    SideHeader.Size=UDim2.new(1,-16,0,36)
    SideHeader.Position=UDim2.fromOffset(8,6)
    SideHeader.Font=Enum.Font.GothamSemibold
    SideHeader.TextXAlignment=Enum.TextXAlignment.Left
    SideHeader.Text="Navigation"
    SideHeader.TextSize=14
    SideHeader.TextColor3=Theme.Title
    SideHeader.Parent=Sidebar

    local TabList = Instance.new("Frame")
    TabList.BackgroundTransparency=1
    TabList.Position=UDim2.fromOffset(6,44)
    TabList.Size=UDim2.new(1,-12,1,-50)
    TabList.Parent=Sidebar
    local TL=Instance.new("UIListLayout",TabList)
    TL.SortOrder=Enum.SortOrder.LayoutOrder
    TL.Padding=UDim.new(0,6)

    local Main = Instance.new("Frame")
    Main.Name="Main"
    Main.BackgroundColor3=Theme.Tertiary
    Main.Size=UDim2.new(1,-214,1,0)
    Main.Position=UDim2.fromOffset(214,0)
    Main.Parent=Body
    newRound(Main,12); newStroke(Main,1,Theme.Stroke,.6)

    local TabPages = Instance.new("Folder")
    TabPages.Name="TabPages"
    TabPages.Parent=Main

    --== Open/Close (Zoom) ==--
    local function open()
        Root.Visible=true
        Root.GroupTransparency=1
        Root.Size=UDim2.fromOffset(WSize.X*0.93,WSize.Y*0.93)
        tplay(Root,.20,{Size=UDim2.fromOffset(WSize.X,WSize.Y)},Enum.EasingStyle.Quad)
        tplay(Root,.20,{GroupTransparency=BaseT},Enum.EasingStyle.Sine)
    end
    local function close()
        tplay(Root,.16,{GroupTransparency=1},Enum.EasingStyle.Sine)
        tplay(Root,.16,{Size=UDim2.fromOffset(WSize.X*0.93,WSize.Y*0.93)},Enum.EasingStyle.Quad)
        task.wait(.16)
        Root.Visible=false
        Root.Size=UDim2.fromOffset(WSize.X,WSize.Y)
        Root.GroupTransparency=BaseT
    end

    --== Stable „Icy Drag“ (kein Teleport) ==--
    do
        local dragging=false
        local dragOffset=Vector2.new()
        local vel=Vector2.new()
        local lastMouse=Vector2.new()
        local lastT=0
        local draggingConn, moveConn, upConn
        local friction=0.88
        local minSpeed=18

        local function mousePos()
            local m=UIS:GetMouseLocation()
            return Vector2.new(m.X,m.Y)
        end
        local function rootAbsPos()
            return Vector2.new(Root.AbsolutePosition.X, Root.AbsolutePosition.Y)
        end
        local function setDragTransparency(on)
            if on then
                tplay(Root,.08,{GroupTransparency=math.clamp(BaseT+0.14,0,.95)})
            else
                tplay(Root,.10,{GroupTransparency=BaseT})
            end
        end

        -- nur Titlebar startet Drag, Buttons blocken (sind separate targets)
        Bar.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            -- wenn in Buttons geklickt, kein Drag
            local target = input.Target or nil
            if UIS:GetFocusedTextBox() then return end
            dragging=true
            local m=mousePos()
            local abs=rootAbsPos()
            dragOffset=m - abs
            lastMouse=m; lastT=tick(); vel=Vector2.new()
            setDragTransparency(true)

            moveConn = UIS.InputChanged:Connect(function(inp)
                if not dragging then return end
                if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
                    local mp=mousePos()
                    local newPos = mp - dragOffset
                    Root.Position = UDim2.fromOffset(newPos.X, newPos.Y)
                    local now=tick(); local dt=now-lastT
                    if dt>0 then
                        local diff=mp-lastMouse
                        vel = vel*friction + (diff/dt)*(1-friction)
                        lastMouse=mp; lastT=now
                    end
                end
            end)
            upConn = UIS.InputEnded:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragging=false
                    setDragTransparency(false)
                    if moveConn then moveConn:Disconnect(); moveConn=nil end
                    if upConn then upConn:Disconnect(); upConn=nil end
                    -- inertia: RenderStepped easing
                    local t0=tick()
                    local stepConn; stepConn=Run.RenderStepped:Connect(function(dt)
                        vel = vel*0.90
                        if vel.Magnitude < minSpeed then stepConn:Disconnect(); clampToViewport(Root); return end
                        local p = Vector2.new(Root.Position.X.Offset, Root.Position.Y.Offset) + vel*dt
                        Root.Position = UDim2.fromOffset(p.X, p.Y)
                    end)
                end
            end)
        end)
    end

    --== Tabs/Pages (closer to original visuals) ==--
    local Tabs, CurrentTab = {}, nil
    local Sections = {} -- name -> order

    local function makeTabButton(tabName, order)
        local Btn=Instance.new("TextButton")
        Btn.Name=tabName; Btn.AutoButtonColor=false
        Btn.BackgroundColor3=Theme.Interact
        Btn.Size=UDim2.new(1,0,0,32); Btn.Text=""
        Btn.LayoutOrder = order or (#TabList:GetChildren()+1)
        Btn.Parent=TabList; newRound(Btn,8)
        local s=newStroke(Btn,1,Theme.Stroke,.65)

        local Labels=Instance.new("Frame")
        Labels.BackgroundTransparency=1
        Labels.Size=UDim2.new(1,-18,1,0)
        Labels.Position=UDim2.fromOffset(9,0)
        Labels.Parent=Btn

        local T=Instance.new("TextLabel")
        T.BackgroundTransparency=1
        T.Font=Enum.Font.Gotham
        T.TextXAlignment=Enum.TextXAlignment.Left
        T.TextSize=14; T.TextColor3=Theme.Text
        T.Text=tabName; T.Size=UDim2.new(1,0,1,0)
        T.Parent=Labels

        Btn.MouseEnter:Connect(function()
            tplay(Btn,.10,{BackgroundColor3=tint(Theme.Interact,5,"up")})
            tplay(s,.10,{Transparency=.45,Color=Theme.Accent})
        end)
        Btn.MouseLeave:Connect(function()
            tplay(Btn,.12,{BackgroundColor3=Theme.Interact})
            tplay(s,.12,{Transparency=.65,Color=Theme.Stroke})
        end)
        return Btn
    end

    local function makeTabPage(tabName)
        local Page=Instance.new("CanvasGroup")
        Page.Name=tabName
        Page.Size=UDim2.new(1,-20,1,-20)
        Page.Position=UDim2.fromOffset(10,10)
        Page.BackgroundTransparency=1
        Page.GroupTransparency=0
        Page.Visible=false
        Page.Parent=TabPages

        local Scroll=Instance.new("ScrollingFrame")
        Scroll.Active=true; Scroll.BorderSizePixel=0
        Scroll.BackgroundTransparency=1
        Scroll.ScrollBarThickness=4
        Scroll.ScrollBarImageTransparency=.15
        Scroll.ScrollBarImageColor3=Theme.Interact
        Scroll.Size=UDim2.new(1,-12,1,-12)
        Scroll.Position=UDim2.fromOffset(6,6)
        Scroll.Parent=Page

        local List=Instance.new("UIListLayout",Scroll)
        List.SortOrder=Enum.SortOrder.LayoutOrder
        List.Padding=UDim.new(0,8)
        local Pad=Instance.new("UIPadding",Scroll)
        Pad.PaddingTop=px(8); Pad.PaddingLeft=px(8); Pad.PaddingRight=px(8); Pad.PaddingBottom=px(8)
        return Page, Scroll
    end

    local function setTab(name)
        for tabName,info in pairs(Tabs) do
            local btn, page = info.Button, info.Page
            if tabName==name then
                if not page.Visible then page.Visible=true; tplay(page,.16,{GroupTransparency=0}) end
                tplay(btn,.12,{BackgroundColor3=tint(Theme.Interact,6,"up")})
            else
                if page.Visible then tplay(page,.10,{GroupTransparency=1}); task.delay(.10,function() page.Visible=false end) end
                tplay(btn,.12,{BackgroundColor3=Theme.Interact})
            end
        end
        CurrentTab=name
    end

    --== Component factories ==--
    local function section(parent, title)
        local F=Instance.new("TextLabel")
        F.BackgroundColor3=Theme.Tertiary
        F.TextXAlignment=Enum.TextXAlignment.Left
        F.Font=Enum.Font.GothamSemibold
        F.TextSize=14; F.TextColor3=Theme.Title
        F.Text=title or "Section"
        F.Size=UDim2.new(1,0,0,32); F.Parent=parent
        newRound(F,8); newStroke(F,1,Theme.Stroke,.6)
        return F
    end
    local function rowBase(parent, h)
        local B=Instance.new("TextButton")
        B.AutoButtonColor=false; B.Text=""
        B.BackgroundColor3=Theme.Tertiary
        B.Size=UDim2.new(1,0,0,h or 58); B.Parent=parent
        newRound(B,10); local s=newStroke(B,1,Theme.Stroke,.6)
        B.MouseEnter:Connect(function()
            tplay(B,.10,{BackgroundColor3=tint(Theme.Tertiary,5,"up")})
            tplay(s,.10,{Transparency=.46,Color=Theme.Accent})
        end)
        B.MouseLeave:Connect(function()
            tplay(B,.12,{BackgroundColor3=Theme.Tertiary})
            tplay(s,.12,{Transparency=.6,Color=Theme.Stroke})
        end)
        return B
    end
    local function labels(parent, title, desc)
        local L=Instance.new("Frame"); L.BackgroundTransparency=1
        L.Size=UDim2.new(1,-14,1,-14); L.Position=UDim2.fromOffset(10,7); L.Parent=parent
        local T=Instance.new("TextLabel"); T.BackgroundTransparency=1
        T.Font=Enum.Font.GothamSemibold; T.TextXAlignment=Enum.TextXAlignment.Left
        T.TextSize=14; T.TextColor3=Theme.Title; T.Text=title or "Title"
        T.Size=UDim2.new(1,0,0,20); T.Parent=L
        local D=Instance.new("TextLabel"); D.BackgroundTransparency=1
        D.Font=Enum.Font.Gotham; D.TextXAlignment=Enum.TextXAlignment.Left
        D.TextSize=13; D.TextColor3=Theme.Muted; D.TextWrapped=true
        D.Text=desc or ""; D.Position=UDim2.fromOffset(0,22); D.Size=UDim2.new(1,-4,1,-22); D.Parent=L
        return T,D
    end
    local function rightSlot(parent,w,h)
        local S=Instance.new("Frame"); S.BackgroundTransparency=1
        S.Size=UDim2.fromOffset(w,h); S.AnchorPoint=Vector2.new(1,.5)
        S.Position=UDim2.new(1,-10,.5,0); S.Parent=parent; return S
    end

    local Components = {}

    function Components.Button(target, cfg)
        local Row=rowBase(target,64); labels(Row,cfg.Title,cfg.Description)
        local R=rightSlot(Row,120,32)
        local B=Instance.new("TextButton"); B.AutoButtonColor=false
        B.Size=UDim2.fromScale(1,1); B.BackgroundColor3=Theme.Interact
        B.Text="Execute"; B.TextColor3=Theme.Title
        B.Font=Enum.Font.GothamBold; B.TextSize=14; B.Parent=R
        newRound(B,8); local s=newStroke(B,1,Theme.Stroke,.6)
        B.MouseEnter:Connect(function() tplay(B,.10,{BackgroundColor3=tint(Theme.Interact,6,"up")}); tplay(s,.10,{Transparency=.42,Color=Theme.Accent}) end)
        B.MouseLeave:Connect(function() tplay(B,.12,{BackgroundColor3=Theme.Interact}); tplay(s,.12,{Transparency=.6,Color=Theme.Stroke}) end)
        B.MouseButton1Click:Connect(function() if cfg.Callback then pcall(cfg.Callback) end end)
        return Row
    end

    function Components.Input(target, cfg)
        local Row=rowBase(target,70); labels(Row,cfg.Title,cfg.Description)
        local R=rightSlot(Row,220,32)
        local Box=Instance.new("TextBox"); Box.ClearTextOnFocus=false
        Box.Size=UDim2.fromScale(1,1); Box.BackgroundColor3=Theme.Interact
        Box.PlaceholderText=cfg.Placeholder or "type here…"
        Box.TextColor3=Theme.Title; Box.PlaceholderColor3=tint(Theme.Muted,18,"down")
        Box.Font=Enum.Font.Gotham; Box.TextSize=14; Box.Text=""
        Box.Parent=R; newRound(Box,8); local s=newStroke(Box,1,Theme.Stroke,.6)
        Box.Focused:Connect(function() tplay(s,.08,{Transparency=.35,Color=Theme.Accent}) end)
        Box.FocusLost:Connect(function(enter) tplay(s,.10,{Transparency=.6,Color=Theme.Stroke}); if enter and cfg.Callback then pcall(function() cfg.Callback(Box.Text) end) end end)
        return Row
    end

    function Components.Toggle(target, cfg)
        local Row=rowBase(target,64); labels(Row,cfg.Title,cfg.Description)
        local R=rightSlot(Row,64,28)
        local Back=Instance.new("Frame"); Back.Size=UDim2.fromScale(1,1)
        Back.BackgroundColor3=Theme.Interact; Back.Parent=R; newRound(Back,14); newStroke(Back,1,Theme.Stroke,.6)
        local Dot=Instance.new("Frame"); Dot.Size=UDim2.fromOffset(24,24); Dot.Position=UDim2.fromOffset(3,2)
        Dot.BackgroundColor3=Theme.Secondary; Dot.Parent=Back; newRound(Dot,12)
        local state = cfg.Default==true
        local function set(v)
            state = v and true or false
            if state then tplay(Back,.12,{BackgroundColor3=Theme.Accent}); tplay(Dot,.12,{Position=UDim2.fromOffset(64-3-24,2), BackgroundColor3=Color3.fromRGB(255,255,255)}) 
            else tplay(Back,.12,{BackgroundColor3=Theme.Interact}); tplay(Dot,.12,{Position=UDim2.fromOffset(3,2), BackgroundColor3=Theme.Secondary}) end
        end
        set(state)
        Row.MouseButton1Click:Connect(function() set(not state); if cfg.Callback then pcall(function() cfg.Callback(state) end) end end)
        return Row
    end

    function Components.Keybind(target, cfg)
        local Row=rowBase(target,64); labels(Row,cfg.Title,cfg.Description)
        local R=rightSlot(Row,140,32)
        local Btn=Instance.new("TextButton"); Btn.AutoButtonColor=false
        Btn.Size=UDim2.fromScale(1,1); Btn.BackgroundColor3=Theme.Interact
        Btn.Text="Set Key"; Btn.TextColor3=Theme.Title
        Btn.Font=Enum.Font.GothamBold; Btn.TextSize=14; Btn.Parent=R
        newRound(Btn,8); local s=newStroke(Btn,1,Theme.Stroke,.6)
        local capturing=false
        Btn.MouseButton1Click:Connect(function()
            if capturing then return end; capturing=true; Btn.Text="..."
            local con; con=UIS.InputBegan:Connect(function(input,gp)
                if gp then return end; capturing=false
                local txt = (input.UserInputType==Enum.UserInputType.Keyboard) and tostring(input.KeyCode):gsub("Enum.KeyCode.","") or tostring(input.UserInputType):gsub("Enum.UserInputType.","")
                Btn.Text=txt; if cfg.Callback then pcall(function() cfg.Callback(input) end) end
                if con then con:Disconnect() end
            end)
        end)
        Btn.MouseEnter:Connect(function() tplay(Btn,.10,{BackgroundColor3=tint(Theme.Interact,6,"up")}); tplay(s,.10,{Transparency=.42,Color=Theme.Accent}) end)
        Btn.MouseLeave:Connect(function() tplay(Btn,.12,{BackgroundColor3=Theme.Interact}); tplay(s,.12,{Transparency=.6,Color=Theme.Stroke}) end)
        return Row
    end

    function Components.Dropdown(target, cfg)
        local Row=rowBase(target,70); labels(Row,cfg.Title,cfg.Description)
        local R=rightSlot(Row,220,32)
        local Btn=Instance.new("TextButton"); Btn.AutoButtonColor=false
        Btn.BackgroundColor3=Theme.Interact; Btn.Size=UDim2.fromScale(1,1); Btn.Text=""; Btn.Parent=R
        newRound(Btn,8); local s=newStroke(Btn,1,Theme.Stroke,.6)
        local TL=Instance.new("TextLabel"); TL.BackgroundTransparency=1
        TL.Font=Enum.Font.Gotham; TL.TextXAlignment=Enum.TextXAlignment.Left
        TL.TextSize=14; TL.TextColor3=Theme.Title; TL.Text=cfg.Placeholder or "Select…"
        TL.Size=UDim2.new(1,-28,1,0); TL.Position=UDim2.fromOffset(10,0); TL.Parent=Btn
        local Arrow=Instance.new("TextLabel"); Arrow.BackgroundTransparency=1
        Arrow.Font=Enum.Font.GothamBold; Arrow.TextSize=16; Arrow.TextColor3=Theme.Muted
        Arrow.Text="▼"; Arrow.Size=UDim2.fromOffset(24,24); Arrow.Position=UDim2.new(1,-28,0,4); Arrow.Parent=Btn

        local Open, Popup=false, nil
        local function closePopup()
            if not Popup then return end
            tplay(Popup,.10,{GroupTransparency=1}); task.delay(.10,function() if Popup then Popup:Destroy() Popup=nil end end)
            Open=false
        end
        local function openPopup()
            if Open then closePopup(); return end; Open=true
            Popup=Instance.new("CanvasGroup"); Popup.GroupTransparency=1
            Popup.BackgroundColor3=Theme.Secondary; Popup.Size=UDim2.fromOffset(220,200)
            Popup.Position=UDim2.new(0, Btn.AbsolutePosition.X-Root.AbsolutePosition.X, 0, Btn.AbsolutePosition.Y-Root.AbsolutePosition.Y+36)
            Popup.Parent=Root; newRound(Popup,10); newStroke(Popup,1,Theme.Stroke,.55)
            local Scroll=Instance.new("ScrollingFrame"); Scroll.Active=true; Scroll.BorderSizePixel=0; Scroll.BackgroundTransparency=1
            Scroll.ScrollBarThickness=4; Scroll.ScrollBarImageTransparency=.1; Scroll.ScrollBarImageColor3=Theme.Interact
            Scroll.Size=UDim2.new(1,-12,1,-12); Scroll.Position=UDim2.fromOffset(6,6); Scroll.Parent=Popup
            local L=Instance.new("UIListLayout",Scroll); L.Padding=UDim.new(0,6); L.SortOrder=Enum.SortOrder.LayoutOrder
            for k,v in pairs(cfg.Options or {}) do
                local Opt=Instance.new("TextButton"); Opt.AutoButtonColor=false
                Opt.Size=UDim2.new(1,0,0,28); Opt.BackgroundColor3=Theme.Tertiary; Opt.Text=""; Opt.Parent=Scroll
                newRound(Opt,8); local os=newStroke(Opt,1,Theme.Stroke,.6)
                local OTL=Instance.new("TextLabel"); OTL.BackgroundTransparency=1; OTL.Size=UDim2.new(1,-12,1,0); OTL.Position=UDim2.fromOffset(8,0)
                OTL.Font=Enum.Font.Gotham; OTL.TextXAlignment=Enum.TextXAlignment.Left; OTL.TextSize=13; OTL.TextColor3=Theme.Text; OTL.Text=tostring(k); OTL.Parent=Opt
                Opt.MouseEnter:Connect(function() tplay(Opt,.08,{BackgroundColor3=tint(Theme.Tertiary,6,"up")}); tplay(os,.08,{Transparency=.45,Color=Theme.Accent}) end)
                Opt.MouseLeave:Connect(function() tplay(Opt,.10,{BackgroundColor3=Theme.Tertiary}); tplay(os,.10,{Transparency=.6,Color=Theme.Stroke}) end)
                Opt.MouseButton1Click:Connect(function() TL.Text=tostring(k); closePopup(); if cfg.Callback then pcall(function() cfg.Callback(v) end) end end)
            end
            tplay(Popup,.12,{GroupTransparency=0})
        end
        Btn.MouseButton1Click:Connect(openPopup)
        UIS.InputBegan:Connect(function(inp,gp)
            if gp or not Open or not Popup then return end
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then
                local pos=UIS:GetMouseLocation()
                local x,y=Popup.AbsolutePosition.X, Popup.AbsolutePosition.Y
                local x2,y2=x+Popup.AbsoluteSize.X, y+Popup.AbsoluteSize.Y
                if not (pos.X>=x and pos.X<=x2 and pos.Y>=y and pos.Y<=y2) then closePopup() end
            end
        end)
        return Row
    end

    function Components.Slider(target, cfg)
        local max=tonumber(cfg.MaxValue) or 100
        local allowDec=cfg.AllowDecimals==true
        local decimals=tonumber(cfg.DecimalAmount) or 2
        local Row=rowBase(target,82); labels(Row,cfg.Title,cfg.Description)

        local Track=Instance.new("Frame"); Track.BackgroundColor3=Theme.Interact
        Track.Size=UDim2.new(1,-20,0,6); Track.Position=UDim2.fromOffset(10,54); Track.Parent=Row; newRound(Track,3)
        local Fill=Instance.new("Frame"); Fill.BackgroundColor3=Theme.Accent; Fill.Size=UDim2.fromScale(0,1); Fill.Parent=Track; newRound(Fill,3)
        local Knob=Instance.new("Frame"); Knob.Size=UDim2.fromOffset(16,16); Knob.AnchorPoint=Vector2.new(.5,.5)
        Knob.Position=UDim2.new(0,0,.5,0); Knob.BackgroundColor3=Color3.fromRGB(255,255,255); Knob.Parent=Track; newRound(Knob,8); newStroke(Knob,1,Theme.Stroke,.4)

        local Box=Instance.new("TextBox"); Box.Size=UDim2.fromOffset(80,28); Box.AnchorPoint=Vector2.new(1,.5)
        Box.Position=UDim2.new(1,-10,.5,0); Box.Text="0"; Box.TextColor3=Theme.Title; Box.BackgroundColor3=Theme.Interact
        Box.PlaceholderText="0"; Box.Font=Enum.Font.Gotham; Box.TextSize=14; Box.Parent=Row; newRound(Box,8); local s=newStroke(Box,1,Theme.Stroke,.6)

        local value=0
        local function fmt(n) if allowDec then local p=10^decimals; n=math.floor(n*p+0.5)/p; return tostring(n) else return tostring(math.floor(n+0.5)) end end
        local function setVal(n)
            n=math.clamp(n,0,max); value=n
            local sc = (max==0 and 0) or (n/max)
            Fill.Size=UDim2.fromScale(sc,1); Knob.Position=UDim2.new(sc,0,.5,0); Box.Text=fmt(n)
            if cfg.Callback then pcall(function() cfg.Callback(n) end) end
        end

        local dragging=false
        local function mouseToValue()
            local m=UIS:GetMouseLocation(); local x0=Track.AbsolutePosition.X; local w=Track.AbsoluteSize.X
            local s=clamp01((m.X-x0)/w); return s*max
        end
        Track.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; setVal(mouseToValue()) end end)
        UIS.InputChanged:Connect(function(inp) if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then setVal(mouseToValue()) end end)
        UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

        Box.Focused:Connect(function() tplay(s,.08,{Transparency=.35,Color=Theme.Accent}) end)
        Box.FocusLost:Connect(function(enter) tplay(s,.10,{Transparency=.6,Color=Theme.Stroke}); if enter then setVal(tonumber(Box.Text) or 0) end end)

        setVal(tonumber(cfg.Default) or 0)
        return Row
    end

    function Components.Paragraph(target, cfg)
        local Row=rowBase(target,118)
        local _,D=labels(Row,cfg.Title,cfg.Description); D.TextWrapped=true
        return Row
    end

    --== Notifications ==--
    local NotiRoot=Instance.new("Frame"); NotiRoot.BackgroundTransparency=1
    NotiRoot.Size=UDim2.new(1,-20,1,-20); NotiRoot.Position=UDim2.fromOffset(10,10)
    NotiRoot.ZIndex=9999; NotiRoot.Parent=Root
    local NL=Instance.new("UIListLayout",NotiRoot)
    NL.Padding=UDim.new(0,8); NL.SortOrder=Enum.SortOrder.LayoutOrder
    NL.VerticalAlignment=Enum.VerticalAlignment.Bottom
    NL.HorizontalAlignment=Enum.HorizontalAlignment.Right
    local function notify(cfg)
        local N=Instance.new("CanvasGroup"); N.GroupTransparency=1
        N.BackgroundColor3=Theme.Secondary; N.Size=UDim2.fromOffset(320,74)
        N.AnchorPoint=Vector2.new(1,1); N.Position=UDim2.new(1,0,1,0)
        N.Parent=NotiRoot; newRound(N,10); newStroke(N,1,Theme.Stroke,.55)
        local Bar=Instance.new("Frame"); Bar.BackgroundColor3=Theme.Accent; Bar.Size=UDim2.new(0,0,0,3)
        Bar.Position=UDim2.new(0,0,1,-3); Bar.Parent=N
        local L=Instance.new("Frame"); L.BackgroundTransparency=1; L.Size=UDim2.new(1,-16,1,-16); L.Position=UDim2.fromOffset(8,8); L.Parent=N
        local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.GothamSemibold; T.TextSize=14; T.TextXAlignment=Enum.TextXAlignment.Left
        T.TextColor3=Theme.Title; T.Text=cfg.Title or "Notification"; T.Size=UDim2.new(1,0,0,20); T.Parent=L
        local D=Instance.new("TextLabel"); D.BackgroundTransparency=1; D.Font=Enum.Font.Gotham; D.TextSize=13; D.TextXAlignment=Enum.TextXAlignment.Left
        D.TextColor3=Theme.Text; D.TextWrapped=true; D.Text=cfg.Description or ""; D.Position=UDim2.fromOffset(0,22); D.Size=UDim2.new(1,0,1,-22); D.Parent=L
        tplay(N,.14,{GroupTransparency=BaseT}); local dur=tonumber(cfg.Duration) or 2
        tplay(Bar,dur,{Size=UDim2.new(1,0,0,3)}); task.delay(dur,function() tplay(N,.10,{GroupTransparency=1}); task.delay(.10,function() N:Destroy() end) end)
    end

    --== Public API ==--
    local API = {}

    -- core
    function API:Show() open() end
    function API:Hide() Root.Visible=false end
    function API:Destroy() SG:Destroy() end

    function API:SetTitle(t) TitleLbl.Text = tostring(t or "Ecstays") .. " • Ecstays" end
    function API:SetSize(v2) WSize=Vector2.new(v2.X,v2.Y); Root.Size=UDim2.fromOffset(WSize.X,WSize.Y); clampToViewport(Root) end
    function API:SetTransparency(v) BaseT=math.clamp(v or BaseT,0,.95); Root.GroupTransparency=BaseT end
    function API:SetTheme(tbl)
        Theme = tbl or Theme
        Bar.BackgroundColor3=Theme.Primary
        Root.BackgroundColor3=Theme.Secondary
        Sidebar.BackgroundColor3=Theme.Tertiary
        Main.BackgroundColor3=Theme.Tertiary
        TitleLbl.TextColor3=Theme.Title
        RootStroke.Color=Theme.Stroke
    end

    -- buttons
    BtnMin.MouseButton1Click:Connect(function() Root.Visible=false end)
    BtnClose.MouseButton1Click:Connect(function() close() end)
    UIS.InputBegan:Connect(function(inp,gp) if gp then return end; if inp.KeyCode==Key then if not Root.Visible then open() else Root.Visible=false end end end)

    -- tab sections
    function API:AddTabSection(cfg) Sections[cfg.Name]=cfg.Order or (#Sections+1) end
    function API:AddTab(cfg)
        local title=cfg.Title or "Tab"
        local order=Sections[cfg.Section] or 999
        local btn=makeTabButton(title,order)
        local page,scroll=makeTabPage(title)
        Tabs[title]={Button=btn,Page=page,Scroll=scroll}
        btn.MouseButton1Click:Connect(function() setTab(title) end)
        if not CurrentTab then setTab(title) end
        return scroll
    end
    function API:SetTab(name) if Tabs[name] then setTab(name) end end

    -- components
    function API:AddSection(cfg)   return section(cfg.Tab,cfg.Name) end
    function API:AddButton(cfg)    return Components.Button(cfg.Tab,cfg) end
    function API:AddInput(cfg)     return Components.Input(cfg.Tab,cfg) end
    function API:AddToggle(cfg)    return Components.Toggle(cfg.Tab,cfg) end
    function API:AddKeybind(cfg)   return Components.Keybind(cfg.Tab,cfg) end
    function API:AddDropdown(cfg)  return Components.Dropdown(cfg.Tab,cfg) end
    function API:AddSlider(cfg)    return Components.Slider(cfg.Tab,cfg) end
    function API:AddParagraph(cfg) return Components.Paragraph(cfg.Tab,cfg) end
    function API:Notify(cfg)       notify(cfg) end

    -- auto-open
    open()
    return API
end

return Ecstays
