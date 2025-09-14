-- Ecstays UI Library – center window, neutral/blue theme, login gate first
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TweenS  = game:GetService("TweenService")

local LP = Players.LocalPlayer

local function safeParent(gui)
    local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not ok then gui.Parent = LP:WaitForChild("PlayerGui") end
end
local function tplay(o,t,props,style,dir)
    return TweenS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.Out), props):Play()
end
local function rc(p,r) local u=Instance.new("UICorner");u.CornerRadius=UDim.new(0,r or 10);u.Parent=p return u end
local function st(p,th,co,tr) local s=Instance.new("UIStroke");s.Thickness=th or 1;s.Color=co or Color3.fromRGB(80,96,122);s.Transparency=tr or .55;s.Parent=p return s end
local function clamp01(x) return x<0 and 0 or (x>1 and 1 or x) end

-- Neutral + blue accent
local Theme = {
  Primary    = Color3.fromRGB(18,20,24), -- Titlebar
  Secondary  = Color3.fromRGB(22,24,28), -- Window
  Component  = Color3.fromRGB(28,31,36), -- Rows
  Interact   = Color3.fromRGB(36,40,46), -- Inputs

  Title      = Color3.fromRGB(235,240,250),
  Text       = Color3.fromRGB(210,220,235),
  Muted      = Color3.fromRGB(170,182,198),

  Outline    = Color3.fromRGB(80,96,122),
  Accent     = Color3.fromRGB(68,140,255),  -- blau
  Danger     = Color3.fromRGB(255,95,115),
  Success    = Color3.fromRGB(120,230,170),
}

local Ecstays = {}
Ecstays._VERSION = "4.1"

function Ecstays:CreateWindow(opts)
  opts = opts or {}

  local Size  = opts.Size or UDim2.fromOffset(640,420)
  local Trans = math.clamp(tonumber(opts.Transparency) or 0.26, 0, .95)
  local Key   = opts.MinimizeKeybind or Enum.KeyCode.LeftControl

  -- Login Gate options
  local Gate = opts.LoginGate or {
    Enabled = true,
    Title = "Redeem Library Key",
    DiscordURL = nil,              -- string | nil
    OnSubmit = function(key, proceed, fail) proceed() end, -- default: passthrough
  }

  -- Screen
  local SG = Instance.new("ScreenGui")
  SG.Name = "EcstaysUI"
  SG.IgnoreGuiInset = true
  SG.ResetOnSpawn = false
  safeParent(SG)

  -- Notifications (bottom-left)
  local NotiRoot = Instance.new("Frame")
  NotiRoot.BackgroundTransparency = 1
  NotiRoot.AnchorPoint = Vector2.new(0,1)
  NotiRoot.Position = UDim2.new(0,12,1,-12)
  NotiRoot.Size = UDim2.fromOffset(340, 600)
  NotiRoot.Parent = SG
  local NL = Instance.new("UIListLayout", NotiRoot)
  NL.SortOrder = Enum.SortOrder.LayoutOrder
  NL.Padding = UDim.new(0,8)
  NL.VerticalAlignment = Enum.VerticalAlignment.Bottom
  NL.HorizontalAlignment = Enum.HorizontalAlignment.Left

  -- Window (centered)
  local Root = Instance.new("CanvasGroup")
  Root.Name = "Window"
  Root.Size = Size
  Root.AnchorPoint = Vector2.new(.5,.5)
  Root.Position = UDim2.fromScale(.5,.5)
  Root.BackgroundColor3 = Theme.Secondary
  Root.GroupTransparency = Trans
  Root.Visible = false
  Root.Parent = SG
  rc(Root,12) local RootStroke = st(Root,1,Theme.Outline,.55)

  -- Titlebar
  local Bar = Instance.new("Frame")
  Bar.BackgroundColor3 = Theme.Primary
  Bar.Size = UDim2.new(1,0,0,40)
  Bar.Parent = Root
  rc(Bar,12)

  local Title = Instance.new("TextLabel")
  Title.BackgroundTransparency = 1
  Title.Text = (opts.Title or "Ecstays").." • Ecstays"
  Title.Font = Enum.Font.GothamSemibold
  Title.TextSize = 15
  Title.TextXAlignment = Enum.TextXAlignment.Left
  Title.TextColor3 = Theme.Title
  Title.Position = UDim2.fromOffset(14,0)
  Title.Size = UDim2.new(1,-130,1,0)
  Title.Parent = Bar

  -- Top-right buttons
  local Btns = Instance.new("Frame")
  Btns.BackgroundTransparency=1
  Btns.Size = UDim2.fromOffset(110,40)
  Btns.Position = UDim2.new(1,-110,0,0)
  Btns.Parent = Bar
  local BL = Instance.new("UIListLayout", Btns)
  BL.FillDirection = Enum.FillDirection.Horizontal
  BL.HorizontalAlignment = Enum.HorizontalAlignment.Right
  BL.VerticalAlignment = Enum.VerticalAlignment.Center
  BL.Padding = UDim.new(0,8)

  local function topBtn(name, txt, col)
    local B = Instance.new("TextButton")
    B.Name=name; B.AutoButtonColor=false
    B.Size=UDim2.fromOffset(38,26)
    B.BackgroundColor3=Theme.Component
    B.Text=txt; B.TextColor3=col or Theme.Text
    B.Font=Enum.Font.GothamBold; B.TextSize=15; B.Parent=Btns
    rc(B,8); local s=st(B,1,Theme.Outline,.65)
    B.MouseEnter:Connect(function()
      tplay(B,.10,{BackgroundColor3=Theme.Interact})
      tplay(s,.10,{Transparency=.42,Color=Theme.Accent})
    end)
    B.MouseLeave:Connect(function()
      tplay(B,.12,{BackgroundColor3=Theme.Component})
      tplay(s,.12,{Transparency=.65,Color=Theme.Outline})
    end)
    return B
  end
  local BtnMin   = topBtn("Minimize","–",Theme.Text)
  local BtnClose = topBtn("Close","×",Theme.Danger)

  -- Drag only on titlebar (with slight transparency while dragging)
  local DragHandle = Instance.new("Frame")
  DragHandle.BackgroundTransparency = 1
  DragHandle.Size = UDim2.new(1,-110,1,0)
  DragHandle.Parent = Bar
  DragHandle.Active = true
  do
    local dragging=false; local off=Vector2.new()
    local function mp() local m=UIS:GetMouseLocation(); return Vector2.new(m.X,m.Y) end
    DragHandle.InputBegan:Connect(function(i)
      if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
      if UIS:GetFocusedTextBox() then return end
      dragging=true
      local m=mp()
      off = Vector2.new(m.X - Root.AbsolutePosition.X, m.Y - Root.AbsolutePosition.Y)
      tplay(Root,.08,{GroupTransparency=math.clamp(Trans+0.12,0,.95)})
    end)
    UIS.InputChanged:Connect(function(i)
      if not dragging then return end
      if i.UserInputType~=Enum.UserInputType.MouseMovement then return end
      local m=mp()
      Root.Position = UDim2.fromOffset(m.X - off.X + Root.Size.X.Offset*0, m.Y - off.Y + Root.Size.Y.Offset*0)
    end)
    UIS.InputEnded:Connect(function(i)
      if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
      if not dragging then return end
      dragging=false
      tplay(Root,.1,{GroupTransparency=Trans})
    end)
  end

  -- Body
  local Body = Instance.new("Frame")
  Body.BackgroundTransparency=1
  Body.Size = UDim2.new(1,-16,1,-56)
  Body.Position = UDim2.fromOffset(8,48)
  Body.Parent = Root

  -- Sidebar
  local Sidebar = Instance.new("Frame")
  Sidebar.Size = UDim2.new(0,196,1,0)
  Sidebar.BackgroundColor3 = Theme.Component
  Sidebar.Parent = Body
  rc(Sidebar,10) st(Sidebar,1,Theme.Outline,.6)

  local SideHead = Instance.new("TextLabel")
  SideHead.BackgroundTransparency=1
  SideHead.Text="Navigation"
  SideHead.TextColor3=Theme.Title
  SideHead.TextXAlignment=Enum.TextXAlignment.Left
  SideHead.Font=Enum.Font.GothamSemibold
  SideHead.TextSize=13
  SideHead.Size=UDim2.new(1,-14,0,30)
  SideHead.Position=UDim2.fromOffset(7,4)
  SideHead.Parent=Sidebar

  local TabList = Instance.new("Frame")
  TabList.BackgroundTransparency=1
  TabList.Size=UDim2.new(1,-12,1,-40)
  TabList.Position=UDim2.fromOffset(6,34)
  TabList.Parent=Sidebar
  local TL=Instance.new("UIListLayout",TabList); TL.Padding=UDim.new(0,6); TL.SortOrder=Enum.SortOrder.LayoutOrder

  -- Main
  local Main = Instance.new("Frame")
  Main.BackgroundColor3=Theme.Component
  Main.Size=UDim2.new(1,-204,1,0)
  Main.Position=UDim2.fromOffset(204,0)
  Main.Parent=Body
  rc(Main,10) st(Main,1,Theme.Outline,.6)

  local Pages = Instance.new("Folder")
  Pages.Name="Pages"; Pages.Parent=Main

  -- Open/Close (zoom)
  local function open()
    Root.Visible=true
    Root.GroupTransparency=1
    Root.Size = UDim2.new(Size.X, UDim.new(0, math.floor(Size.Y.Offset*0.93)))
    tplay(Root,.18,{Size=Size},Enum.EasingStyle.Quad)
    tplay(Root,.18,{GroupTransparency=Trans},Enum.EasingStyle.Sine)
  end
  local function close()
    tplay(Root,.14,{GroupTransparency=1},Enum.EasingStyle.Sine)
    tplay(Root,.14,{Size=UDim2.new(Size.X, UDim.new(0, math.floor(Size.Y.Offset*0.93)))},Enum.EasingStyle.Quad)
    task.wait(.14)
    Root.Visible=false
    Root.Size=Size
    Root.GroupTransparency=Trans
  end

  -- Buttons + toggle key
  BtnMin.MouseButton1Click:Connect(function() Root.Visible=false end)
  BtnClose.MouseButton1Click:Connect(function() close() end)
  UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Key then
      if not Root.Visible then open() else Root.Visible=false end
    end
  end)

  -- Tabs/Sections
  local Stored = { Sections = {}, Tabs = {} }
  local Current

  local function mkTabBtn(name, order)
    local B=Instance.new("TextButton")
    B.Name=name; B.AutoButtonColor=false
    B.BackgroundColor3=Theme.Interact
    B.Size=UDim2.new(1,0,0,30); B.Text=""
    B.LayoutOrder=order or 999; B.Parent=TabList
    rc(B,8); local s=st(B,1,Theme.Outline,.65)
    local T=Instance.new("TextLabel")
    T.BackgroundTransparency=1; T.Font=Enum.Font.Gotham
    T.TextXAlignment=Enum.TextXAlignment.Left; T.TextSize=13
    T.TextColor3=Theme.Text; T.Text=name
    T.Size=UDim2.new(1,-16,1,0); T.Position=UDim2.fromOffset(8,0); T.Parent=B
    B.MouseEnter:Connect(function() tplay(B,.10,{BackgroundColor3=Theme.Component}); tplay(s,.10,{Transparency=.45,Color=Theme.Accent}) end)
    B.MouseLeave:Connect(function() tplay(B,.12,{BackgroundColor3=Theme.Interact}); tplay(s,.12,{Transparency=.65,Color=Theme.Outline}) end)
    return B
  end
  local function mkPage(name)
    local P=Instance.new("CanvasGroup")
    P.Name=name; P.BackgroundTransparency=1; P.GroupTransparency=0; P.Visible=false
    P.Size=UDim2.new(1,-16,1,-16); P.Position=UDim2.fromOffset(8,8); P.Parent=Pages
    local S=Instance.new("ScrollingFrame")
    S.Active=true; S.BackgroundTransparency=1; S.BorderSizePixel=0
    S.ScrollBarThickness=4; S.ScrollBarImageTransparency=.15; S.ScrollBarImageColor3=Theme.Interact
    S.Size=UDim2.new(1,0,1,0); S.Parent=P
    local L=Instance.new("UIListLayout",S); L.Padding=UDim.new(0,8)
    local Pad=Instance.new("UIPadding",S); Pad.PaddingTop=UDim.new(0,8); Pad.PaddingLeft=UDim.new(0,8); Pad.PaddingRight=UDim.new(0,8); Pad.PaddingBottom=UDim.new(0,8)
    L:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
      S.CanvasSize=UDim2.new(0,0,0,L.AbsoluteContentSize.Y+16)
    end)
    return P,S
  end
  local function setTab(n)
    for k,v in pairs(Stored.Tabs) do
      if k==n then
        if not v.Page.Visible then v.Page.Visible=true; tplay(v.Page,.14,{GroupTransparency=0}) end
        tplay(v.Button,.10,{BackgroundColor3=Theme.Component})
      else
        if v.Page.Visible then tplay(v.Page,.10,{GroupTransparency=1}); task.delay(.10,function() v.Page.Visible=false end) end
        tplay(v.Button,.10,{BackgroundColor3=Theme.Interact})
      end
    end
    Current=n
  end

  local function makeRow(parent,h)
    local R=Instance.new("Frame")
    R.BackgroundColor3=Theme.Component
    R.Size=UDim2.new(1,0,0,h); R.Parent=parent
    rc(R,8); st(R,1,Theme.Outline,.6)
    return R
  end
  local function labelBlock(row,title,desc,rightW)
    local L=Instance.new("Frame"); L.BackgroundTransparency=1; L.Position=UDim2.fromOffset(10,6)
    L.Size=UDim2.new(1,-((rightW or 0)+24),1,-12); L.Parent=row
    local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.GothamSemibold
    T.TextXAlignment=Enum.TextXAlignment.Left; T.TextSize=13; T.TextColor3=Theme.Title; T.Text=title or "Title"; T.Size=UDim2.new(1,0,0,18); T.Parent=L
    local D=Instance.new("TextLabel"); D.BackgroundTransparency=1; D.Font=Enum.Font.Gotham; D.TextXAlignment=Enum.TextXAlignment.Left
    D.TextSize=12; D.TextColor3=Theme.Muted; D.TextWrapped=true; D.Text=desc or ""; D.Position=UDim2.fromOffset(0,20); D.Size=UDim2.new(1,0,1,-20); D.Parent=L
    return T,D
  end
  local function rightSlot(row,w,h)
    local S=Instance.new("Frame"); S.BackgroundTransparency=1; S.Size=UDim2.fromOffset(w,h); S.AnchorPoint=Vector2.new(1,.5); S.Position=UDim2.new(1,-10,.5,0); S.Parent=row; return S
  end

  local API = {}

  -- Tabs API
  function API:AddTabSection(s) Stored.Sections[s.Name]=s.Order or (#Stored.Sections+1) end
  function API:AddTab(s)
    if Stored.Tabs[s.Title] then error("[Ecstays] Tab exists: "..s.Title) end
    local btn=mkTabBtn(s.Title, Stored.Sections[s.Section] or 999)
    local page,scroll=mkPage(s.Title)
    Stored.Tabs[s.Title]={Button=btn, Page=page, Scroll=scroll}
    btn.MouseButton1Click:Connect(function() setTab(s.Title) end)
    if not Current then setTab(s.Title) end
    return scroll
  end
  function API:SetTab(n) if Stored.Tabs[n] then setTab(n) end end

  -- Components
  function API:AddSection(s)
    local row=makeRow(s.Tab,28)
    local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamSemibold; t.TextSize=13; t.TextXAlignment=Enum.TextXAlignment.Left
    t.TextColor3=Theme.Title; t.Text=s.Name or "Section"; t.Size=UDim2.new(1,-10,1,0); t.Position=UDim2.fromOffset(10,0); t.Parent=row
    return row
  end
  function API:AddButton(s)
    local RW=118; local row=makeRow(s.Tab,54); labelBlock(row,s.Title,s.Description,RW)
    local R=rightSlot(row,RW,28)
    local B=Instance.new("TextButton"); B.AutoButtonColor=false; B.BackgroundColor3=Theme.Interact; B.Text="Execute"; B.TextColor3=Theme.Title
    B.Font=Enum.Font.GothamBold; B.TextSize=13; B.Size=UDim2.fromScale(1,1); B.Parent=R; rc(B,8); local x=st(B,1,Theme.Outline,.6)
    B.MouseEnter:Connect(function() tplay(B,.10,{BackgroundColor3=Theme.Component}); tplay(x,.10,{Transparency=.42,Color=Theme.Accent}) end)
    B.MouseLeave:Connect(function() tplay(B,.12,{BackgroundColor3=Theme.Interact}); tplay(x,.12,{Transparency=.6,Color=Theme.Outline}) end)
    B.MouseButton1Click:Connect(function() if s.Callback then pcall(s.Callback) end end)
    return row
  end
  function API:AddInput(s)
    local RW=220; local row=makeRow(s.Tab,60); labelBlock(row,s.Title,s.Description,RW)
    local R=rightSlot(row,RW,28)
    local Box=Instance.new("TextBox"); Box.ClearTextOnFocus=false; Box.BackgroundColor3=Theme.Interact; Box.TextColor3=Theme.Title
    Box.PlaceholderText=s.Placeholder or "type here…"; Box.Font=Enum.Font.Gotham; Box.TextSize=13; Box.Size=UDim2.fromScale(1,1); Box.Parent=R
    rc(Box,8); local x=st(Box,1,Theme.Outline,.6)
    Box.Focused:Connect(function() tplay(x,.08,{Transparency=.35,Color=Theme.Accent}) end)
    Box.FocusLost:Connect(function(enter) tplay(x,.10,{Transparency=.6,Color=Theme.Outline}); if enter and s.Callback then pcall(function() s.Callback(Box.Text) end) end end)
    return row
  end
  function API:AddToggle(s)
    local RW=62; local row=makeRow(s.Tab,54); labelBlock(row,s.Title,s.Description,RW)
    local R=rightSlot(row,RW,26)
    local Back=Instance.new("Frame"); Back.Size=UDim2.fromScale(1,1); Back.BackgroundColor3=Theme.Interact; Back.Parent=R; rc(Back,13); st(Back,1,Theme.Outline,.6)
    local Dot=Instance.new("Frame"); Dot.Size=UDim2.fromOffset(22,22); Dot.Position=UDim2.fromOffset(2,2); Dot.BackgroundColor3=Theme.Secondary; Dot.Parent=Back; rc(Dot,11)
    local state = s.Default==true
    local function set(v)
      state=v and true or false
      if state then tplay(Back,.10,{BackgroundColor3=Theme.Accent}); tplay(Dot,.10,{Position=UDim2.fromOffset(RW-2-22,2), BackgroundColor3=Color3.fromRGB(255,255,255)})
      else tplay(Back,.10,{BackgroundColor3=Theme.Interact}); tplay(Dot,.10,{Position=UDim2.fromOffset(2,2), BackgroundColor3=Theme.Secondary}) end
    end; set(state)
    row.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then set(not state); if s.Callback then pcall(function() s.Callback(state) end) end end end)
    return row
  end
  function API:AddKeybind(s)
    local RW=132; local row=makeRow(s.Tab,54); labelBlock(row,s.Title,s.Description,RW)
    local R=rightSlot(row,RW,28)
    local Btn=Instance.new("TextButton"); Btn.AutoButtonColor=false; Btn.BackgroundColor3=Theme.Interact; Btn.Text="Set Key"; Btn.TextColor3=Theme.Title
    Btn.Font=Enum.Font.GothamBold; Btn.TextSize=13; Btn.Size=UDim2.fromScale(1,1); Btn.Parent=R; rc(Btn,8); local x=st(Btn,1,Theme.Outline,.6)
    local cap=false
    Btn.MouseButton1Click:Connect(function()
      if cap then return end; cap=true; Btn.Text="..."
      local con; con=UIS.InputBegan:Connect(function(input,gp)
        if gp then return end; cap=false
        local label = input.UserInputType==Enum.UserInputType.Keyboard and tostring(input.KeyCode):gsub("Enum.KeyCode.","") or tostring(input.UserInputType):gsub("Enum.UserInputType.","")
        Btn.Text=label; if s.Callback then pcall(function() s.Callback(input) end) end
        if con then con:Disconnect() end
      end)
    end)
    Btn.MouseEnter:Connect(function() tplay(Btn,.10,{BackgroundColor3=Theme.Component}); tplay(x,.10,{Transparency=.42,Color=Theme.Accent}) end)
    Btn.MouseLeave:Connect(function() tplay(Btn,.12,{BackgroundColor3=Theme.Interact}); tplay(x,.12,{Transparency=.6,Color=Theme.Outline}) end)
    return row
  end
  function API:AddDropdown(s)
    local RW=220; local row=makeRow(s.Tab,60); labelBlock(row,s.Title,s.Description,RW)
    local R=rightSlot(row,RW,28)
    local Btn=Instance.new("TextButton"); Btn.AutoButtonColor=false; Btn.BackgroundColor3=Theme.Interact; Btn.Text=""; Btn.Size=UDim2.fromScale(1,1); Btn.Parent=R
    rc(Btn,8); local x=st(Btn,1,Theme.Outline,.6)
    local TL=Instance.new("TextLabel"); TL.BackgroundTransparency=1; TL.Font=Enum.Font.Gotham; TL.TextXAlignment=Enum.TextXAlignment.Left; TL.TextSize=13; TL.TextColor3=Theme.Title
    TL.Text=s.Placeholder or "Select…"; TL.Size=UDim2.new(1,-22,1,0); TL.Position=UDim2.fromOffset(8,0); TL.Parent=Btn
    local Arrow=Instance.new("TextLabel"); Arrow.BackgroundTransparency=1; Arrow.Font=Enum.Font.GothamBold; Arrow.TextSize=14; Arrow.TextColor3=Theme.Muted
    Arrow.Text="▼"; Arrow.Size=UDim2.fromOffset(18,18); Arrow.Position=UDim2.new(1,-20,0,5); Arrow.Parent=Btn
    local Open,Popup=false,nil
    local function closeP() if not Popup then return end; tplay(Popup,.1,{GroupTransparency=1}); task.delay(.1,function() if Popup then Popup:Destroy(); Popup=nil end end); Open=false end
    local function openP()
      if Open then closeP() return end; Open=true
      Popup=Instance.new("CanvasGroup"); Popup.GroupTransparency=1; Popup.BackgroundColor3=Theme.Secondary
      Popup.Size=UDim2.fromOffset(220,196)
      Popup.Position=UDim2.new(0, Btn.AbsolutePosition.X-Root.AbsolutePosition.X, 0, Btn.AbsolutePosition.Y-Root.AbsolutePosition.Y+30)
      Popup.Parent=Root; rc(Popup,10); st(Popup,1,Theme.Outline,.55)
      local S=Instance.new("ScrollingFrame"); S.Active=true; S.BorderSizePixel=0; S.BackgroundTransparency=1
      S.ScrollBarThickness=4; S.ScrollBarImageTransparency=.1; S.ScrollBarImageColor3=Theme.Interact
      S.Size=UDim2.new(1,-10,1,-10); S.Position=UDim2.fromOffset(5,5); S.Parent=Popup
      local L=Instance.new("UIListLayout",S); L.Padding=UDim.new(0,6)
      for k,v in pairs(s.Options or {}) do
        local O=Instance.new("TextButton"); O.AutoButtonColor=false; O.Size=UDim2.new(1,0,0,26); O.Text=""; O.BackgroundColor3=Theme.Component; O.Parent=S
        rc(O,8); local os=st(O,1,Theme.Outline,.6)
        local OTL=Instance.new("TextLabel"); OTL.BackgroundTransparency=1; OTL.Font=Enum.Font.Gotham; OTL.TextXAlignment=Enum.TextXAlignment.Left; OTL.TextSize=12; OTL.TextColor3=Theme.Text
        OTL.Text=tostring(k); OTL.Size=UDim2.new(1,-10,1,0); OTL.Position=UDim2.fromOffset(6,0); OTL.Parent=O
        O.MouseEnter:Connect(function() tplay(O,.08,{BackgroundColor3=Theme.Interact}); tplay(os,.08,{Transparency=.45,Color=Theme.Accent}) end)
        O.MouseLeave:Connect(function() tplay(O,.10,{BackgroundColor3=Theme.Component}); tplay(os,.10,{Transparency=.6,Color=Theme.Outline}) end)
        O.MouseButton1Click:Connect(function() TL.Text=tostring(k); closeP(); if s.Callback then pcall(function() s.Callback(v) end) end end)
      end
      tplay(Popup,.12,{GroupTransparency=0})
    end
    Btn.MouseButton1Click:Connect(openP)
    UIS.InputBegan:Connect(function(i,gp)
      if gp or not Open or not Popup then return end
      if i.UserInputType==Enum.UserInputType.MouseButton1 then
        local p=UIS:GetMouseLocation(); local x,y=Popup.AbsolutePosition.X, Popup.AbsolutePosition.Y
        local x2,y2=x+Popup.AbsoluteSize.X, y+Popup.AbsoluteSize.Y
        if not(p.X>=x and p.X<=x2 and p.Y>=y and p.Y<=y2) then closeP() end
      end
    end)
    return row
  end
  function API:AddSlider(s)
    local RW=110; local row=makeRow(s.Tab,70); labelBlock(row,s.Title,s.Description,RW)
    local Track=Instance.new("Frame"); Track.BackgroundColor3=Theme.Interact; Track.Size=UDim2.new(1,-(RW+28),0,6); Track.Position=UDim2.new(0,10,1,-14); Track.Parent=row; rc(Track,3)
    local Fill=Instance.new("Frame"); Fill.BackgroundColor3=Theme.Accent; Fill.Size=UDim2.fromScale(0,1); Fill.Parent=Track; rc(Fill,3)
    local Knob=Instance.new("Frame"); Knob.Size=UDim2.fromOffset(14,14); Knob.AnchorPoint=Vector2.new(.5,.5); Knob.Position=UDim2.new(0,0,.5,0); Knob.BackgroundColor3=Color3.fromRGB(255,255,255); Knob.Parent=Track; rc(Knob,7); st(Knob,1,Theme.Outline,.4)
    local R=rightSlot(row,RW,26); local Box=Instance.new("TextBox"); Box.Size=UDim2.fromScale(1,1); Box.BackgroundColor3=Theme.Interact; Box.TextColor3=Theme.Title; Box.PlaceholderText="0"; Box.Text="0"; Box.Font=Enum.Font.Gotham; Box.TextSize=13; Box.Parent=R; rc(Box,8); local sb=st(Box,1,Theme.Outline,.6)
    local max=tonumber(s.MaxValue) or 100; local aD=s.AllowDecimals==true; local dec=tonumber(s.DecimalAmount) or 2; local val=0
    local function fmt(n) if aD then local p=10^dec n=math.floor(n*p+0.5)/p return tostring(n) else return tostring(math.floor(n+0.5)) end end
    local function setv(n) n=math.clamp(n,0,max); val=n; local sc=(max==0) and 0 or (n/max); Fill.Size=UDim2.fromScale(sc,1); Knob.Position=UDim2.new(sc,0,.5,0); Box.Text=fmt(n); if s.Callback then pcall(function() s.Callback(n) end) end end
    local dragging=false
    local function mouseVal() local m=UIS:GetMouseLocation(); local x0=Track.AbsolutePosition.X; local w=Track.AbsoluteSize.X; local sc=clamp01((m.X-x0)/w); return sc*max end
    Track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; setv(mouseVal()) end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then setv(mouseVal()) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    Box.Focused:Connect(function() tplay(sb,.08,{Transparency=.35,Color=Theme.Accent}) end)
    Box.FocusLost:Connect(function(enter) tplay(sb,.10,{Transparency=.6,Color=Theme.Outline}); if enter then setv(tonumber(Box.Text) or 0) end end)
    setv(tonumber(s.Default) or 0); return row
  end
  function API:AddParagraph(s)
    local row=makeRow(s.Tab,110); local _,D=labelBlock(row,s.Title,s.Description,0); D.TextWrapped=true; return row
  end

  -- Notifications
  local function notify(cfg)
    local N=Instance.new("CanvasGroup"); N.GroupTransparency=1; N.BackgroundColor3=Theme.Secondary; N.Size=UDim2.fromOffset(320,70); N.Parent=NotiRoot
    rc(N,10); st(N,1,Theme.Outline,.55)
    local Bar=Instance.new("Frame"); Bar.BackgroundColor3=Theme.Accent; Bar.Size=UDim2.new(0,0,0,3); Bar.Position=UDim2.new(0,0,1,-3); Bar.Parent=N
    local L=Instance.new("Frame"); L.BackgroundTransparency=1; L.Size=UDim2.new(1,-14,1,-14); L.Position=UDim2.fromOffset(7,7); L.Parent=N
    local T=Instance.new("TextLabel"); T.BackgroundTransparency=1; T.Font=Enum.Font.GothamSemibold; T.TextXAlignment=Enum.TextXAlignment.Left; T.TextSize=13; T.TextColor3=Theme.Title; T.Text=cfg.Title or "Notification"; T.Size=UDim2.new(1,0,0,18); T.Parent=L
    local D=Instance.new("TextLabel"); D.BackgroundTransparency=1; D.Font=Enum.Font.Gotham; D.TextXAlignment=Enum.TextXAlignment.Left; D.TextWrapped=true; D.TextSize=12; D.TextColor3=Theme.Text; D.Text=cfg.Description or ""; D.Position=UDim2.fromOffset(0,20); D.Size=UDim2.new(1,0,1,-20); D.Parent=L
    local dur=tonumber(cfg.Duration) or 2
    tplay(N,.12,{GroupTransparency=Trans}); tplay(Bar,dur,{Size=UDim2.new(1,0,0,3)}); task.delay(dur,function() tplay(N,.10,{GroupTransparency=1}); task.delay(.10,function() N:Destroy() end) end)
  end
  function API:Notify(c) notify(c) end

  -- Theme / Settings
  function API:SetTheme(tbl)
    for k,v in pairs(tbl or {}) do Theme[k]=v end
    Root.BackgroundColor3=Theme.Secondary; Bar.BackgroundColor3=Theme.Primary
    Sidebar.BackgroundColor3=Theme.Component; Main.BackgroundColor3=Theme.Component
    RootStroke.Color=Theme.Outline; Title.TextColor3=Theme.Title
  end
  function API:SetSetting(s,v)
    if s=="Transparency" then Trans = math.clamp(v or Trans,0,.95); Root.GroupTransparency=Trans
    elseif s=="Size" then Size=v; Root.Size=v
    elseif s=="Theme" and typeof(v)=="table" then API:SetTheme(v)
    elseif s=="Keybind" then Key=v
    end
  end

  --= LOGIN GATE =--
  local function showGate()
    if not Gate.Enabled then open(); return end

    local Shade = Instance.new("CanvasGroup")
    Shade.Size = UDim2.fromScale(1,1); Shade.BackgroundColor3 = Color3.fromRGB(0,0,0)
    Shade.GroupTransparency = 1; Shade.Parent = SG
    tplay(Shade,.12,{GroupTransparency=.25})

    local Modal = Instance.new("CanvasGroup")
    Modal.GroupTransparency=1
    Modal.AnchorPoint=Vector2.new(.5,.5)
    Modal.Position=UDim2.fromScale(.5,.5)
    Modal.Size=UDim2.fromOffset(520, 320)
    Modal.BackgroundColor3=Theme.Secondary
    Modal.Parent=SG
    rc(Modal,14); st(Modal,1,Theme.Outline,.5)

    local TitleM = Instance.new("TextLabel")
    TitleM.BackgroundTransparency=1
    TitleM.Font=Enum.Font.GothamBlack; TitleM.TextSize=24
    TitleM.TextColor3=Theme.Title
    TitleM.Text = Gate.Title or "Redeem Library Key"
    TitleM.Position=UDim2.fromOffset(20,16)
    TitleM.Size=UDim2.new(1,-40,0,30)
    TitleM.Parent=Modal

    local Sub = Instance.new("TextLabel")
    Sub.BackgroundTransparency=1
    Sub.Font=Enum.Font.Gotham; Sub.TextSize=13
    Sub.TextColor3=Theme.Text
    Sub.Text = "Enter your key or join our Discord for updates."
    Sub.Position=UDim2.fromOffset(20,50)
    Sub.Size=UDim2.new(1,-40,0,20)
    Sub.Parent=Modal

    -- Key Input Row
    local Row = Instance.new("Frame")
    Row.BackgroundColor3=Theme.Component
    Row.Size=UDim2.new(1,-40,0,56)
    Row.Position=UDim2.fromOffset(20,90)
    Row.Parent=Modal
    rc(Row,10); st(Row,1,Theme.Outline,.55)

    local Box = Instance.new("TextBox")
    Box.ClearTextOnFocus=false
    Box.BackgroundColor3=Theme.Interact
    Box.TextColor3=Theme.Title
    Box.PlaceholderText="Library Key"
    Box.Font=Enum.Font.Gotham; Box.TextSize=14
    Box.Text=""
    Box.Size=UDim2.new(1,-110,1,-20)
    Box.Position=UDim2.fromOffset(10,10)
    Box.Parent=Row
    rc(Box,8); st(Box,1,Theme.Outline,.5)

    local Eye = Instance.new("TextButton")
    Eye.AutoButtonColor=false; Eye.Text="👁"; Eye.TextSize=18; Eye.Font=Enum.Font.Gotham
    Eye.BackgroundColor3=Theme.Interact
    Eye.TextColor3=Theme.Text
    Eye.Size=UDim2.fromOffset(40,36)
    Eye.Position=UDim2.new(1,-96,0,10)
    Eye.Parent=Row
    rc(Eye,8); st(Eye,1,Theme.Outline,.5)

    local Submit = Instance.new("TextButton")
    Submit.AutoButtonColor=false; Submit.Text="✓"; Submit.TextSize=18; Submit.Font=Enum.Font.GothamBold
    Submit.BackgroundColor3=Theme.Accent; Submit.TextColor3=Color3.fromRGB(255,255,255)
    Submit.Size=UDim2.fromOffset(40,36)
    Submit.Position=UDim2.new(1,-50,0,10)
    Submit.Parent=Row
    rc(Submit,8)

    local Error = Instance.new("TextLabel")
    Error.BackgroundTransparency=1; Error.Font=Enum.Font.Gotham; Error.TextSize=12
    Error.TextColor3=Theme.Danger; Error.Text=""; Error.Position=UDim2.fromOffset(22,150); Error.Size=UDim2.new(1,-44,0,18); Error.Parent=Modal

    -- Buttons: Discord + (optional) purchase removed
    local Disc = Instance.new("TextButton")
    Disc.AutoButtonColor=false
    Disc.BackgroundColor3=Theme.Accent
    Disc.TextColor3=Color3.fromRGB(255,255,255)
    Disc.Font=Enum.Font.GothamBold; Disc.TextSize=14
    Disc.Text="Join Discord"
    Disc.Size=UDim2.new(0,180,0,40)
    Disc.Position=UDim2.fromOffset(20, 190)
    Disc.Parent=Modal
    rc(Disc,10)

    local Info = Instance.new("TextLabel")
    Info.BackgroundTransparency=1; Info.Font=Enum.Font.Gotham; Info.TextSize=12; Info.TextColor3=Theme.Muted
    Info.Text = "By continuing, you agree to our Terms & Privacy."
    Info.Position=UDim2.fromOffset(20, 240); Info.Size=UDim2.new(1,-40,0,18); Info.Parent=Modal

    -- Interactions
    local masked=true
    Eye.MouseButton1Click:Connect(function()
      masked = not masked
      -- Roblox TextBox hat kein echtes Password-Mode, daher nur kleine UX: wir zeigen Punkte/echten Text
      if masked then
        Box.Text = string.rep("•", #Box.Text)
      else
        -- keine sichere Umkehr – nur visuell; echte Maskierung/Unmaskierung braucht Puffer
        Error.Text = "Tip: Key wird nicht wirklich maskiert (Roblox-Limit)."
      end
    end)

    local function proceed()
      tplay(Modal,.12,{GroupTransparency=1}); tplay(Shade,.10,{GroupTransparency=1})
      task.delay(.12,function() Modal:Destroy(); Shade:Destroy(); open() end)
    end
    local function fail(msg)
      Error.Text = msg or "Invalid key."
      tplay(Error,.08,{TextTransparency=0})
    end

    local function submit()
      local raw = Box.Text:gsub("•","") -- falls wir Punkte drin haben
      if Gate and typeof(Gate.OnSubmit)=="function" then
        local ok, err = pcall(function() Gate.OnSubmit(raw, proceed, fail) end)
        if not ok then fail("Validation error") end
      else
        proceed()
      end
    end
    Submit.MouseButton1Click:Connect(submit)
    Box.FocusLost:Connect(function(enter) if enter then submit() end end)

    Disc.MouseButton1Click:Connect(function()
      if Gate and Gate.DiscordURL and setclipboard then
        setclipboard(Gate.DiscordURL)
        -- kleine Info
        local N = { Title="Discord", Description="Link kopiert! Füge ihn in deinen Browser ein.", Duration=2 }
        notify(N)
      else
        notify({ Title="Discord", Description="Kein Link konfiguriert.", Duration=2 })
      end
    end)

    -- show modal
    tplay(Modal,.14,{GroupTransparency=Trans})
  end

  -- public notify for gate
  local function _notify(c) notify(c) end

  -- expose window-level API
  function API:Show() open() end
  function API:Hide() Root.Visible=false end
  function API:Destroy() SG:Destroy() end
  function API:Notify(c) _notify(c) end
  function API:SetTheme(t) Ecstays.SetTheme = nil; -- (keine globale)
    for k,v in pairs(t or {}) do Theme[k]=v end
    Root.BackgroundColor3=Theme.Secondary; Bar.BackgroundColor3=Theme.Primary; Sidebar.BackgroundColor3=Theme.Component; Main.BackgroundColor3=Theme.Component
    Title.TextColor3=Theme.Title; RootStroke.Color=Theme.Outline
  end
  function API:SetSetting(s,v)
    if s=="Transparency" then Trans=math.clamp(v or Trans,0,.95); Root.GroupTransparency=Trans
    elseif s=="Size" then Size=v; Root.Size=v
    elseif s=="Theme" and typeof(v)=="table" then API:SetTheme(v)
    elseif s=="Keybind" then Key=v
    end
  end

  -- gate first
  showGate()

  -- return component API
  return API
end

return Ecstays
