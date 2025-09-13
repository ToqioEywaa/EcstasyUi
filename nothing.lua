--[[
  Ecstays UI Library – 2025 ultra-clean rebuild
  - Transparent, klein & clean (default 640x420)
  - Titlebar-Drag (eigene DragArea) -> stabil, ohne Teleport + Inertia
  - Zoom Open/Close
  - Kein Overlap: linke Label-Fläche, rechter Control-Slot je Zeile
  - ScrollFrame passt sich automatisch an (CanvasSize)
  - Nur Minimize & Close (rechts oben)
  - Controls: Tabs, Section, Button, Input, Toggle, Keybind, Dropdown, Slider, Paragraph, Notify
  - Theming & Settings
  - Keine externen Assets
]]

if not game:IsLoaded() then game.Loaded:Wait() end

-- Services
local Players = game:GetService("Players")
local Tween   = game:GetService("TweenService")
local UIS     = game:GetService("UserInputService")
local Run     = game:GetService("RunService")
local LP      = Players.LocalPlayer

-- Utils
local function safeParent(gui)
  local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
  if not ok then gui.Parent = LP:WaitForChild("PlayerGui") end
end
local function tplay(o,t,p,s,d) return Tween:Create(o, TweenInfo.new(t, s or Enum.EasingStyle.Sine, d or Enum.EasingDirection.Out), p):Play() end
local function tint(c,by,mode) local r,g,b=c.R*255,c.G*255,c.B*255; if mode=="down" then return Color3.fromRGB(math.max(0,r-by),math.max(0,g-by),math.max(0,b-by)) end; return Color3.fromRGB(math.min(255,r+by),math.min(255,g+by),math.min(255,b+by)) end
local function round(p,r) local u=Instance.new("UICorner") u.CornerRadius=UDim.new(0,r or 10) u.Parent=p return u end
local function stroke(p,thk,col,tr) local s=Instance.new("UIStroke") s.Thickness=thk or 1 s.Color=col or Color3.fromRGB(90,72,112) s.Transparency=tr or .6 s.Parent=p return s end
local function clamp01(x) return x<0 and 0 or (x>1 and 1 or x) end
local function clampToViewport(guiObj)
  local cam=workspace.CurrentCamera if not cam then return end
  local vp=cam.ViewportSize local abs=guiObj.AbsoluteSize
  local x=math.clamp(guiObj.Position.X.Offset,0,math.max(0,vp.X-abs.X))
  local y=math.clamp(guiObj.Position.Y.Offset,0,math.max(0,vp.Y-abs.Y))
  guiObj.Position=UDim2.fromOffset(x,y)
end

-- Theme
local DEFAULT_THEME = {
  Primary    = Color3.fromRGB(20,18,24),  -- Titlebar
  Secondary  = Color3.fromRGB(26,24,32),  -- Window
  Tertiary   = Color3.fromRGB(32,29,38),  -- Panels/Rows
  Interact   = Color3.fromRGB(40,36,48),  -- Inputs/Hover

  Title      = Color3.fromRGB(246,242,252),
  Text       = Color3.fromRGB(220,216,228),
  Muted      = Color3.fromRGB(190,186,198),

  Stroke     = Color3.fromRGB(96,78,122),
  Icon       = Color3.fromRGB(236,226,248),

  Accent     = Color3.fromRGB(206,99,255),   -- pink-lilac
  AccentSoft = Color3.fromRGB(168,88,232),

  Danger     = Color3.fromRGB(255,92,128),
  Success    = Color3.fromRGB(120,230,170),
}

-- Library
local Ecstays = {}
Ecstays._VERSION = "4.0"

function Ecstays:CreateWindow(opts)
  opts = opts or {}
  local Theme   = opts.ThemeTable or DEFAULT_THEME
  local Title   = opts.Title or "Ecstays"
  local WSize   = opts.Size or Vector2.new(640, 420)        -- kleiner
  local BaseT   = math.clamp(tonumber(opts.Transparency) or 0.26, 0, .95) -- transparenter
  local Key     = opts.MinimizeKeybind or Enum.KeyCode.LeftControl

  -- ScreenGui
  local SG = Instance.new("ScreenGui")
  SG.Name = "EcstaysUI"
  SG.IgnoreGuiInset = true
  SG.ResetOnSpawn = false
  safeParent(SG)

  -- Root (CanvasGroup, damit GroupTransparency wirkt)
  local Root = Instance.new("CanvasGroup")
  Root.Name = "Window"
  Root.Size = UDim2.fromOffset(WSize.X, WSize.Y)
  Root.Position = UDim2.fromOffset(120, 120)
  Root.BackgroundColor3 = Theme.Secondary
  Root.GroupTransparency = BaseT
  Root.Active = true
  Root.Visible = false
  Root.Parent = SG
  round(Root, 12) stroke(Root, 1, Theme.Stroke, .55)

  -- Titlebar
  local Bar = Instance.new("Frame")
  Bar.Name = "Titlebar"
  Bar.BackgroundColor3 = Theme.Primary
  Bar.Size = UDim2.new(1, 0, 0, 40)
  Bar.Parent = Root
  round(Bar, 12)

  local TitleLbl = Instance.new("TextLabel")
  TitleLbl.BackgroundTransparency = 1
  TitleLbl.Position = UDim2.fromOffset(14, 0)
  TitleLbl.Size = UDim2.new(1, -120, 1, 0)
  TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
  TitleLbl.Font = Enum.Font.GothamSemibold
  TitleLbl.TextSize = 15
  TitleLbl.TextColor3 = Theme.Title
  TitleLbl.Text = Title .. " • Ecstays"
  TitleLbl.Parent = Bar

  -- Buttons (rechts)
  local Btns = Instance.new("Frame")
  Btns.BackgroundTransparency = 1
  Btns.Size = UDim2.fromOffset(110, 40)
  Btns.Position = UDim2.new(1, -110, 0, 0)
  Btns.Parent = Bar
  local bll = Instance.new("UIListLayout", Btns)
  bll.FillDirection = Enum.FillDirection.Horizontal
  bll.HorizontalAlignment = Enum.HorizontalAlignment.Right
  bll.VerticalAlignment = Enum.VerticalAlignment.Center
  bll.Padding = UDim.new(0, 8)

  local function makeTopBtn(name, txt, col)
    local B = Instance.new("TextButton")
    B.Name = name
    B.AutoButtonColor = false
    B.Size = UDim2.fromOffset(38, 26)
    B.BackgroundColor3 = tint(Theme.Secondary, 6, "down")
    B.Text = txt
    B.TextColor3 = col or Theme.Text
    B.Font = Enum.Font.GothamBold
    B.TextSize = 15
    B.Parent = Btns
    round(B, 8)
    local s = stroke(B, 1, Theme.Stroke, .65)
    B.MouseEnter:Connect(function()
      tplay(B, .10, {BackgroundColor3 = Theme.Interact})
      tplay(s, .10, {Transparency = .42, Color = Theme.Accent})
    end)
    B.MouseLeave:Connect(function()
      tplay(B, .12, {BackgroundColor3 = tint(Theme.Secondary, 6, "down")})
      tplay(s, .12, {Transparency = .65, Color = Theme.Stroke})
    end)
    return B
  end

  local BtnMin   = makeTopBtn("Minimize", "–", Theme.Text)
  local BtnClose = makeTopBtn("Close",    "×", Theme.Danger)

  -- Separate DragArea (verhindert Button-Klick -> Drag-Start)
  local DragArea = Instance.new("Frame")
  DragArea.BackgroundTransparency = 1
  DragArea.Size = UDim2.new(1, -120, 1, 0) -- Titelbereich ohne Button-Zone
  DragArea.Position = UDim2.fromOffset(0, 0)
  DragArea.Parent = Bar
  DragArea.Active = true

  -- Body
  local Body = Instance.new("Frame")
  Body.BackgroundTransparency = 1
  Body.Size = UDim2.new(1, -16, 1, -56)
  Body.Position = UDim2.fromOffset(8, 48)
  Body.Parent = Root

  -- Sidebar
  local Sidebar = Instance.new("Frame")
  Sidebar.Size = UDim2.new(0, 196, 1, 0)
  Sidebar.BackgroundColor3 = Theme.Tertiary
  Sidebar.Parent = Body
  round(Sidebar, 10) stroke(Sidebar, 1, Theme.Stroke, .6)

  local SideHeader = Instance.new("TextLabel")
  SideHeader.BackgroundTransparency = 1
  SideHeader.Size = UDim2.new(1, -14, 0, 30)
  SideHeader.Position = UDim2.fromOffset(7, 4)
  SideHeader.Font = Enum.Font.GothamSemibold
  SideHeader.TextXAlignment = Enum.TextXAlignment.Left
  SideHeader.Text = "Navigation"
  SideHeader.TextSize = 13
  SideHeader.TextColor3 = Theme.Title
  SideHeader.Parent = Sidebar

  local TabList = Instance.new("Frame")
  TabList.BackgroundTransparency = 1
  TabList.Position = UDim2.fromOffset(6, 34)
  TabList.Size = UDim2.new(1, -12, 1, -40)
  TabList.Parent = Sidebar
  local tll = Instance.new("UIListLayout", TabList)
  tll.SortOrder = Enum.SortOrder.LayoutOrder
  tll.Padding = UDim.new(0, 6)

  -- Main area
  local Main = Instance.new("Frame")
  Main.Name = "Main"
  Main.BackgroundColor3 = Theme.Tertiary
  Main.Size = UDim2.new(1, -204, 1, 0)
  Main.Position = UDim2.fromOffset(204, 0)
  Main.Parent = Body
  round(Main, 10) stroke(Main, 1, Theme.Stroke, .6)

  local TabPages = Instance.new("Folder")
  TabPages.Name = "TabPages"
  TabPages.Parent = Main

  -- Zoom open/close
  local function open()
    Root.Visible = true
    Root.GroupTransparency = 1
    Root.Size = UDim2.fromOffset(WSize.X * 0.93, WSize.Y * 0.93)
    tplay(Root, .18, {Size = UDim2.fromOffset(WSize.X, WSize.Y)}, Enum.EasingStyle.Quad)
    tplay(Root, .18, {GroupTransparency = BaseT}, Enum.EasingStyle.Sine)
  end
  local function close()
    tplay(Root, .14, {GroupTransparency = 1}, Enum.EasingStyle.Sine)
    tplay(Root, .14, {Size = UDim2.fromOffset(WSize.X * 0.93, WSize.Y * 0.93)}, Enum.EasingStyle.Quad)
    task.wait(.14)
    Root.Visible = false
    Root.Size = UDim2.fromOffset(WSize.X, WSize.Y)
    Root.GroupTransparency = BaseT
  end

  -- Stable Drag mit Inertia
  do
    local dragging = false
    local dragOffset = Vector2.new()
    local lastMouse = Vector2.new()
    local vel = Vector2.new()
    local lastT = 0
    local friction = 0.90
    local minSpeed = 18

    local function mouse()
      local m = UIS:GetMouseLocation()
      return Vector2.new(m.X, m.Y)
    end
    local function setDragT(on)
      if on then tplay(Root, .08, {GroupTransparency = math.clamp(BaseT + 0.14, 0, .95)})
      else tplay(Root, .10, {GroupTransparency = BaseT}) end
    end

    DragArea.InputBegan:Connect(function(inp)
      if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
      if UIS:GetFocusedTextBox() then return end
      dragging = true
      local m = mouse()
      dragOffset = Vector2.new(m.X - Root.Position.X.Offset, m.Y - Root.Position.Y.Offset)
      lastMouse = m; lastT = tick(); vel = Vector2.new()
      setDragT(true)
    end)

    UIS.InputChanged:Connect(function(inp)
      if not dragging then return end
      if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
      local m = mouse()
      local newPos = m - dragOffset
      Root.Position = UDim2.fromOffset(newPos.X, newPos.Y)
      local now = tick() local dt = now - lastT
      if dt > 0 then
        local diff = m - lastMouse
        vel = vel * friction + (diff / dt) * (1 - friction)
        lastMouse = m; lastT = now
      end
    end)

    UIS.InputEnded:Connect(function(inp)
      if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
      if not dragging then return end
      dragging = false
      setDragT(false)
      -- inertia
      local step; step = Run.RenderStepped:Connect(function(dt)
        vel = vel * 0.90
        if vel.Magnitude < minSpeed then step:Disconnect(); clampToViewport(Root); return end
        local p = Vector2.new(Root.Position.X.Offset, Root.Position.Y.Offset) + vel * dt
        Root.Position = UDim2.fromOffset(p.X, p.Y)
      end)
    end)
  end

  -- Tabs/Pages
  local Tabs, CurrentTab = {}, nil
  local Sections = {} -- name -> order

  local function makeTabButton(name, order)
    local Btn = Instance.new("TextButton")
    Btn.Name = name
    Btn.AutoButtonColor = false
    Btn.BackgroundColor3 = Theme.Interact
    Btn.Size = UDim2.new(1, 0, 0, 30)
    Btn.Text = ""
    Btn.LayoutOrder = order or (#TabList:GetChildren() + 1)
    Btn.Parent = TabList
    round(Btn, 8)
    local s = stroke(Btn, 1, Theme.Stroke, .65)

    local TL = Instance.new("TextLabel")
    TL.BackgroundTransparency = 1
    TL.Font = Enum.Font.Gotham
    TL.TextXAlignment = Enum.TextXAlignment.Left
    TL.TextSize = 13
    TL.TextColor3 = Theme.Text
    TL.Text = name
    TL.Size = UDim2.new(1, -16, 1, 0)
    TL.Position = UDim2.fromOffset(8, 0)
    TL.Parent = Btn

    Btn.MouseEnter:Connect(function()
      tplay(Btn, .10, {BackgroundColor3 = tint(Theme.Interact, 4, "up")})
      tplay(s, .10, {Transparency = .45, Color = Theme.Accent})
    end)
    Btn.MouseLeave:Connect(function()
      tplay(Btn, .12, {BackgroundColor3 = Theme.Interact})
      tplay(s, .12, {Transparency = .65, Color = Theme.Stroke})
    end)
    return Btn
  end

  local function makeTabPage(name)
    local Page = Instance.new("CanvasGroup")
    Page.Name = name
    Page.Size = UDim2.new(1, -16, 1, -16)
    Page.Position = UDim2.fromOffset(8, 8)
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
    Scroll.Size = UDim2.new(1, 0, 1, 0)
    Scroll.Parent = Page

    local List = Instance.new("UIListLayout")
    List.Parent = Scroll
    List.SortOrder = Enum.SortOrder.LayoutOrder
    List.Padding = UDim.new(0, 8)

    local Pad = Instance.new("UIPadding")
    Pad.Parent = Scroll
    Pad.PaddingTop = UDim.new(0, 8)
    Pad.PaddingLeft = UDim.new(0, 8)
    Pad.PaddingRight = UDim.new(0, 8)
    Pad.PaddingBottom = UDim.new(0, 8)

    -- Auto-CanvasSize (gegen Überlappungen/Abschneiden)
    local function resizeCanvas()
      local h = List.AbsoluteContentSize.Y + 16
      Scroll.CanvasSize = UDim2.new(0, 0, 0, h)
    end
    List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeCanvas)
    resizeCanvas()

    return Page, Scroll, List
  end

  local function setTab(name)
    for tabName, info in pairs(Tabs) do
      local btn, page = info.Button, info.Page
      if tabName == name then
        if not page.Visible then page.Visible = true tplay(page, .14, {GroupTransparency = 0}) end
        tplay(btn, .10, {BackgroundColor3 = tint(Theme.Interact, 6, "up")})
      else
        if page.Visible then tplay(page, .10, {GroupTransparency = 1}) task.delay(.10, function() page.Visible = false end) end
        tplay(btn, .10, {BackgroundColor3 = Theme.Interact})
      end
    end
    CurrentTab = name
  end

  -- Shared row helpers (verhindert Overlap: Label-Breite vs. RightSlot)
  local function makeRow(parent, height)
    local Row = Instance.new("Frame")
    Row.BackgroundColor3 = Theme.Tertiary
    Row.Size = UDim2.new(1, 0, 0, height)
    Row.Parent = parent
    round(Row, 8) stroke(Row, 1, Theme.Stroke, .6)
    return Row
  end
  local function addLabelArea(row, title, desc, rightWidth)
    rightWidth = rightWidth or 0
    local L = Instance.new("Frame")
    L.BackgroundTransparency = 1
    L.Position = UDim2.fromOffset(10, 6)
    L.Size = UDim2.new(1, - (rightWidth + 24), 1, -12) -- Platz für RightSlot
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
    D.TextColor3 = Theme.Muted
    D.TextWrapped = true
    D.Text = desc or ""
    D.Position = UDim2.fromOffset(0, 20)
    D.Size = UDim2.new(1, 0, 1, -20)
    D.Parent = L

    return T, D
  end
  local function rightSlot(row, w, h)
    local S = Instance.new("Frame")
    S.BackgroundTransparency = 1
    S.Size = UDim2.fromOffset(w, h)
    S.AnchorPoint = Vector2.new(1, .5)
    S.Position = UDim2.new(1, -10, .5, 0)
    S.Parent = row
    return S
  end

  -- Components
  local Components = {}

  function Components.Section(target, cfg)
    local S = makeRow(target, 28)
    local T = Instance.new("TextLabel")
    T.BackgroundTransparency = 1
    T.Font = Enum.Font.GothamSemibold
    T.TextSize = 13
    T.TextXAlignment = Enum.TextXAlignment.Left
    T.TextColor3 = Theme.Title
    T.Text = cfg.Name or "Section"
    T.Size = UDim2.new(1, -10, 1, 0)
    T.Position = UDim2.fromOffset(10, 0)
    T.Parent = S
    return S
  end

  function Components.Button(target, cfg)
    local rightW = 118
    local Row = makeRow(target, 54)
    addLabelArea(Row, cfg.Title, cfg.Description, rightW)
    local R = rightSlot(Row, rightW, 28)
    local B = Instance.new("TextButton")
    B.AutoButtonColor = false
    B.Size = UDim2.fromScale(1, 1)
    B.BackgroundColor3 = Theme.Interact
    B.Text = "Execute"
    B.TextColor3 = Theme.Title
    B.Font = Enum.Font.GothamBold
    B.TextSize = 13
    B.Parent = R
    round(B, 8) local s = stroke(B, 1, Theme.Stroke, .6)
    B.MouseEnter:Connect(function() tplay(B, .10, {BackgroundColor3 = tint(Theme.Interact, 6, "up")}) tplay(s, .10, {Transparency = .42, Color = Theme.Accent}) end)
    B.MouseLeave:Connect(function() tplay(B, .12, {BackgroundColor3 = Theme.Interact}) tplay(s, .12, {Transparency = .6, Color = Theme.Stroke}) end)
    B.MouseButton1Click:Connect(function() if cfg.Callback then pcall(cfg.Callback) end end)
    return Row
  end

  function Components.Input(target, cfg)
    local rightW = 220
    local Row = makeRow(target, 60)
    addLabelArea(Row, cfg.Title, cfg.Description, rightW)
    local R = rightSlot(Row, rightW, 28)
    local Box = Instance.new("TextBox")
    Box.ClearTextOnFocus = false
    Box.Size = UDim2.fromScale(1, 1)
    Box.BackgroundColor3 = Theme.Interact
    Box.PlaceholderText = cfg.Placeholder or "type here…"
    Box.TextColor3 = Theme.Title
    Box.PlaceholderColor3 = tint(Theme.Muted, 18, "down")
    Box.Font = Enum.Font.Gotham
    Box.TextSize = 13
    Box.Text = ""
    Box.Parent = R
    round(Box, 8) local s = stroke(Box, 1, Theme.Stroke, .6)
    Box.Focused:Connect(function() tplay(s, .08, {Transparency = .35, Color = Theme.Accent}) end)
    Box.FocusLost:Connect(function(enter) tplay(s, .10, {Transparency = .6, Color = Theme.Stroke}); if enter and cfg.Callback then pcall(function() cfg.Callback(Box.Text) end) end end)
    return Row
  end

  function Components.Toggle(target, cfg)
    local rightW = 62
    local Row = makeRow(target, 54)
    addLabelArea(Row, cfg.Title, cfg.Description, rightW)
    local R = rightSlot(Row, rightW, 26)
    local Back = Instance.new("Frame")
    Back.Size = UDim2.fromScale(1, 1)
    Back.BackgroundColor3 = Theme.Interact
    Back.Parent = R
    round(Back, 13) stroke(Back, 1, Theme.Stroke, .6)
    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.fromOffset(22, 22)
    Dot.Position = UDim2.fromOffset(2, 2)
    Dot.BackgroundColor3 = Theme.Secondary
    Dot.Parent = Back
    round(Dot, 11)

    local state = cfg.Default == true
    local function set(v)
      state = v and true or false
      if state then
        tplay(Back, .10, {BackgroundColor3 = Theme.Accent})
        tplay(Dot, .10, {Position = UDim2.fromOffset(62-2-22, 2), BackgroundColor3 = Color3.fromRGB(255,255,255)})
      else
        tplay(Back, .10, {BackgroundColor3 = Theme.Interact})
        tplay(Dot, .10, {Position = UDim2.fromOffset(2, 2), BackgroundColor3 = Theme.Secondary})
      end
    end
    set(state)
    Row.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then set(not state) if cfg.Callback then pcall(function() cfg.Callback(state) end) end end end)
    return Row
  end

  function Components.Keybind(target, cfg)
    local rightW = 132
    local Row = makeRow(target, 54)
    addLabelArea(Row, cfg.Title, cfg.Description, rightW)
    local R = rightSlot(Row, rightW, 28)
    local Btn = Instance.new("TextButton")
    Btn.AutoButtonColor = false
    Btn.Size = UDim2.fromScale(1,1)
    Btn.BackgroundColor3 = Theme.Interact
    Btn.Text = "Set Key"
    Btn.TextColor3 = Theme.Title
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.Parent = R
    round(Btn, 8) local s = stroke(Btn, 1, Theme.Stroke, .6)

    local capturing = false
    Btn.MouseButton1Click:Connect(function()
      if capturing then return end
      capturing = true
      Btn.Text = "..."
      local con; con = UIS.InputBegan:Connect(function(input,gp)
        if gp then return end
        capturing = false
        local label = input.UserInputType == Enum.UserInputType.Keyboard and tostring(input.KeyCode):gsub("Enum.KeyCode.","") or tostring(input.UserInputType):gsub("Enum.UserInputType.","")
        Btn.Text = label
        if cfg.Callback then pcall(function() cfg.Callback(input) end) end
        if con then con:Disconnect() end
      end)
    end)

    Btn.MouseEnter:Connect(function() tplay(Btn,.10,{BackgroundColor3=tint(Theme.Interact,6,"up")}) tplay(s,.10,{Transparency=.42,Color=Theme.Accent}) end)
    Btn.MouseLeave:Connect(function() tplay(Btn,.12,{BackgroundColor3=Theme.Interact}) tplay(s,.12,{Transparency=.6,Color=Theme.Stroke}) end)
    return Row
  end

  function Components.Dropdown(target, cfg)
    local rightW = 220
    local Row = makeRow(target, 60)
    addLabelArea(Row, cfg.Title, cfg.Description, rightW)
    local R = rightSlot(Row, rightW, 28)
    local Btn = Instance.new("TextButton")
    Btn.AutoButtonColor = false
    Btn.Size = UDim2.fromScale(1,1)
    Btn.BackgroundColor3 = Theme.Interact
    Btn.Text = ""
    Btn.Parent = R
    round(Btn, 8) local s = stroke(Btn, 1, Theme.Stroke, .6)

    local TL = Instance.new("TextLabel")
    TL.BackgroundTransparency = 1
    TL.Font = Enum.Font.Gotham
    TL.TextXAlignment = Enum.TextXAlignment.Left
    TL.TextSize = 13
    TL.TextColor3 = Theme.Title
    TL.Text = cfg.Placeholder or "Select…"
    TL.Size = UDim2.new(1, -22, 1, 0)
    TL.Position = UDim2.fromOffset(8, 0)
    TL.Parent = Btn

    local Arrow = Instance.new("TextLabel")
    Arrow.BackgroundTransparency = 1
    Arrow.Font = Enum.Font.GothamBold
    Arrow.TextSize = 14
    Arrow.TextColor3 = Theme.Muted
    Arrow.Text = "▼"
    Arrow.Size = UDim2.fromOffset(18, 18)
    Arrow.Position = UDim2.new(1, -20, 0, 5)
    Arrow.Parent = Btn

    local Open, Popup = false, nil
    local function closePopup()
      if not Popup then return end
      tplay(Popup, .10, {GroupTransparency = 1})
      task.delay(.10, function() if Popup then Popup:Destroy() Popup = nil end end)
      Open = false
    end
    local function openPopup()
      if Open then closePopup() return end
      Open = true
      Popup = Instance.new("CanvasGroup")
      Popup.GroupTransparency = 1
      Popup.BackgroundColor3 = Theme.Secondary
      Popup.Size = UDim2.fromOffset(220, 196)
      Popup.Position = UDim2.new(0, Btn.AbsolutePosition.X - Root.AbsolutePosition.X, 0, Btn.AbsolutePosition.Y - Root.AbsolutePosition.Y + 30)
      Popup.Parent = Root
      round(Popup, 10) stroke(Popup, 1, Theme.Stroke, .55)
      local Scroll = Instance.new("ScrollingFrame")
      Scroll.Active = true; Scroll.BorderSizePixel = 0; Scroll.BackgroundTransparency = 1
      Scroll.ScrollBarThickness = 4; Scroll.ScrollBarImageTransparency = .1; Scroll.ScrollBarImageColor3 = Theme.Interact
      Scroll.Size = UDim2.new(1, -10, 1, -10); Scroll.Position = UDim2.fromOffset(5,5); Scroll.Parent = Popup
      local L = Instance.new("UIListLayout", Scroll) L.Padding = UDim.new(0,6) L.SortOrder = Enum.SortOrder.LayoutOrder
      for k,v in pairs(cfg.Options or {}) do
        local Opt = Instance.new("TextButton")
        Opt.AutoButtonColor = false; Opt.Size = UDim2.new(1, 0, 0, 26)
        Opt.BackgroundColor3 = Theme.Tertiary; Opt.Text = ""; Opt.Parent = Scroll
        round(Opt, 8) local os = stroke(Opt, 1, Theme.Stroke, .6)
        local OTL = Instance.new("TextLabel")
        OTL.BackgroundTransparency = 1; OTL.Size = UDim2.new(1, -10, 1, 0); OTL.Position = UDim2.fromOffset(6, 0)
        OTL.Font = Enum.Font.Gotham; OTL.TextXAlignment = Enum.TextXAlignment.Left; OTL.TextSize = 12; OTL.TextColor3 = Theme.Text; OTL.Text = tostring(k); OTL.Parent = Opt
        Opt.MouseEnter:Connect(function() tplay(Opt, .08, {BackgroundColor3 = tint(Theme.Tertiary, 6, "up")}) tplay(os, .08, {Transparency = .45, Color = Theme.Accent}) end)
        Opt.MouseLeave:Connect(function() tplay(Opt, .10, {BackgroundColor3 = Theme.Tertiary}) tplay(os, .10, {Transparency = .6, Color = Theme.Stroke}) end)
        Opt.MouseButton1Click:Connect(function() TL.Text = tostring(k) closePopup() if cfg.Callback then pcall(function() cfg.Callback(v) end) end end)
      end
      tplay(Popup, .12, {GroupTransparency = 0})
    end
    Btn.MouseButton1Click:Connect(openPopup)
    UIS.InputBegan:Connect(function(inp,gp)
      if gp or not Open or not Popup then return end
      if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = UIS:GetMouseLocation()
        local x,y = Popup.AbsolutePosition.X, Popup.AbsolutePosition.Y
        local x2,y2 = x + Popup.AbsoluteSize.X, y + Popup.AbsoluteSize.Y
        if not (pos.X>=x and pos.X<=x2 and pos.Y>=y and pos.Y<=y2) then closePopup() end
      end
    end)
    return Row
  end

  function Components.Slider(target, cfg)
    local rightW = 110  -- Box rechts
    local Row = makeRow(target, 70)
    local T, D = addLabelArea(Row, cfg.Title, cfg.Description, rightW)
    local R = rightSlot(Row, rightW, 26)

    local max      = tonumber(cfg.MaxValue) or 100
    local allowDec = cfg.AllowDecimals == true
    local decimals = tonumber(cfg.DecimalAmount) or 2

    -- Track (unter dem Labelblock, volle Breite bis vor RightSlot)
    local Track = Instance.new("Frame")
    Track.BackgroundColor3 = Theme.Interact
    Track.Size = UDim2.new(1, - (rightW + 28), 0, 6)
    Track.Position = UDim2.new(0, 10, 1, -14) -- unten im Row
    Track.Parent = Row
    round(Track, 3)

    local Fill = Instance.new("Frame")
    Fill.BackgroundColor3 = Theme.Accent
    Fill.Size = UDim2.fromScale(0, 1)
    Fill.Parent = Track
    round(Fill, 3)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(14, 14)
    Knob.AnchorPoint = Vector2.new(.5,.5)
    Knob.Position = UDim2.new(0, 0, .5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Knob.Parent = Track
    round(Knob, 7) stroke(Knob, 1, Theme.Stroke, .4)

    local Box = Instance.new("TextBox")
    Box.Size = UDim2.fromScale(1,1)
    Box.BackgroundColor3 = Theme.Interact
    Box.Text = "0"
    Box.TextColor3 = Theme.Title
    Box.PlaceholderText = "0"
    Box.Font = Enum.Font.Gotham
    Box.TextSize = 13
    Box.Parent = R
    round(Box, 8) local sb = stroke(Box, 1, Theme.Stroke, .6)

    local value = 0
    local function fmt(n)
      if allowDec then local p=10^decimals n=math.floor(n*p+0.5)/p return tostring(n) end
      return tostring(math.floor(n + 0.5))
    end
    local function setVal(n)
      n = math.clamp(n, 0, max)
      value = n
      local sc = (max == 0) and 0 or (n / max)
      Fill.Size = UDim2.fromScale(sc, 1)
      Knob.Position = UDim2.new(sc, 0, .5, 0)
      Box.Text = fmt(n)
      if cfg.Callback then pcall(function() cfg.Callback(n) end) end
    end

    local dragging = false
    local function mouseToValue()
      local m = UIS:GetMouseLocation()
      local x0 = Track.AbsolutePosition.X
      local w  = Track.AbsoluteSize.X
      local s  = clamp01((m.X - x0) / w)
      return s * max
    end
    Track.InputBegan:Connect(function(inp)
      if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true setVal(mouseToValue()) end
    end)
    UIS.InputChanged:Connect(function(inp)
      if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then setVal(mouseToValue()) end
    end)
    UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    Box.Focused:Connect(function() tplay(sb, .08, {Transparency = .35, Color = Theme.Accent}) end)
    Box.FocusLost:Connect(function(enter) tplay(sb, .10, {Transparency = .6, Color = Theme.Stroke}); if enter then setVal(tonumber(Box.Text) or 0) end end)

    setVal(tonumber(cfg.Default) or 0)
    return Row
  end

  function Components.Paragraph(target, cfg)
    local Row = makeRow(target, 110)
    local T, D = addLabelArea(Row, cfg.Title, cfg.Description, 0)
    D.TextWrapped = true
    return Row
  end

  -- Notifications
  local NotiRoot = Instance.new("Frame")
  NotiRoot.BackgroundTransparency = 1
  NotiRoot.Size = UDim2.new(1, -12, 1, -12)
  NotiRoot.Position = UDim2.fromOffset(6, 6)
  NotiRoot.ZIndex = 9999
  NotiRoot.Parent = Root
  local nll = Instance.new("UIListLayout", NotiRoot)
  nll.Padding = UDim.new(0, 6)
  nll.SortOrder = Enum.SortOrder.LayoutOrder
  nll.VerticalAlignment = Enum.VerticalAlignment.Bottom
  nll.HorizontalAlignment = Enum.HorizontalAlignment.Right
  local function notify(cfg)
    local N = Instance.new("CanvasGroup")
    N.GroupTransparency = 1
    N.BackgroundColor3 = Theme.Secondary
    N.Size = UDim2.fromOffset(300, 68)
    N.AnchorPoint = Vector2.new(1,1)
    N.Position = UDim2.new(1, 0, 1, 0)
    N.Parent = NotiRoot
    round(N, 10) stroke(N, 1, Theme.Stroke, .55)

    local Bar = Instance.new("Frame")
    Bar.BackgroundColor3 = Theme.Accent
    Bar.Size = UDim2.new(0, 0, 0, 3)
    Bar.Position = UDim2.new(0, 0, 1, -3)
    Bar.Parent = N

    local L = Instance.new("Frame")
    L.BackgroundTransparency = 1
    L.Size = UDim2.new(1, -14, 1, -14)
    L.Position = UDim2.fromOffset(7,7)
    L.Parent = N

    local T = Instance.new("TextLabel")
    T.BackgroundTransparency = 1
    T.Font = Enum.Font.GothamSemibold
    T.TextSize = 13
    T.TextXAlignment = Enum.TextXAlignment.Left
    T.TextColor3 = Theme.Title
    T.Text = cfg.Title or "Notification"
    T.Size = UDim2.new(1, 0, 0, 18)
    T.Parent = L

    local D = Instance.new("TextLabel")
    D.BackgroundTransparency = 1
    D.Font = Enum.Font.Gotham
    D.TextSize = 12
    D.TextXAlignment = Enum.TextXAlignment.Left
    D.TextWrapped = true
    D.TextColor3 = Theme.Text
    D.Text = cfg.Description or ""
    D.Position = UDim2.fromOffset(0, 20)
    D.Size = UDim2.new(1, 0, 1, -20)
    D.Parent = L

    tplay(N, .12, {GroupTransparency = BaseT})
    local dur = tonumber(cfg.Duration) or 2
    tplay(Bar, dur, {Size = UDim2.new(1, 0, 0, 3)})
    task.delay(dur, function() tplay(N, .10, {GroupTransparency = 1}) task.delay(.10, function() N:Destroy() end) end)
  end

  -- Public API
  local API = {}

  -- window
  function API:Show() open() end
  function API:Hide() Root.Visible = false end
  function API:Destroy() SG:Destroy() end
  function API:SetTitle(t) TitleLbl.Text = tostring(t or "Ecstays") .. " • Ecstays" end
  function API:SetSize(v2) WSize = Vector2.new(v2.X, v2.Y) Root.Size = UDim2.fromOffset(WSize.X, WSize.Y) clampToViewport(Root) end
  function API:SetTransparency(v) BaseT = math.clamp(v or BaseT, 0, .95) Root.GroupTransparency = BaseT end
  function API:SetTheme(tbl)
    Theme = tbl or Theme
    Root.BackgroundColor3 = Theme.Secondary
    Bar.BackgroundColor3 = Theme.Primary
    Sidebar.BackgroundColor3 = Theme.Tertiary
    Main.BackgroundColor3 = Theme.Tertiary
    TitleLbl.TextColor3 = Theme.Title
  end

  -- controls
  BtnMin.MouseButton1Click:Connect(function() Root.Visible = false end)
  BtnClose.MouseButton1Click:Connect(function() close() end)
  UIS.InputBegan:Connect(function(inp,gp) if gp then return end if inp.KeyCode == Key then if not Root.Visible then open() else Root.Visible = false end end end)

  -- tabs
  function API:AddTabSection(cfg) Sections[cfg.Name] = cfg.Order or (#Sections + 1) end
  function API:AddTab(cfg)
    local title = cfg.Title or "Tab"
    local order = Sections[cfg.Section] or 999
    local btn = makeTabButton(title, order)
    local page, scroll = makeTabPage(title)
    Tabs[title] = { Button = btn, Page = page, Scroll = scroll }
    btn.MouseButton1Click:Connect(function() setTab(title) end)
    if not CurrentTab then setTab(title) end
    return scroll
  end
  function API:SetTab(name) if Tabs[name] then setTab(name) end end

  -- components
  function API:AddSection(cfg)   return Components.Section(cfg.Tab, cfg) end
  function API:AddButton(cfg)    return Components.Button(cfg.Tab, cfg) end
  function API:AddInput(cfg)     return Components.Input(cfg.Tab, cfg) end
  function API:AddToggle(cfg)    return Components.Toggle(cfg.Tab, cfg) end
  function API:AddKeybind(cfg)   return Components.Keybind(cfg.Tab, cfg) end
  function API:AddDropdown(cfg)  return Components.Dropdown(cfg.Tab, cfg) end
  function API:AddSlider(cfg)    return Components.Slider(cfg.Tab, cfg) end
  function API:AddParagraph(cfg) return Components.Paragraph(cfg.Tab, cfg) end
  function API:Notify(cfg)       return notify(cfg) end

  -- show initially
  open()
  return API
end

return Ecstays
