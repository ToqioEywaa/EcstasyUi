-- === DROP-IN: ersetzt deine showGate() komplett ===
local function showGate()
    if not LOGIN.Enabled then open(); return end

    -- Dim
    local Shade = Instance.new("CanvasGroup")
    Shade.Size = UDim2.fromScale(1,1)
    Shade.BackgroundColor3 = Color3.fromRGB(0,0,0)
    Shade.GroupTransparency = 1
    Shade.Parent = SG
    tplay(Shade,.12,{GroupTransparency=.25})

    -- Modal
    local Modal = Instance.new("CanvasGroup")
    Modal.AnchorPoint = Vector2.new(.5,.5)
    Modal.Position = UDim2.fromScale(.5,.5)
    Modal.Size = UDim2.fromOffset(620, 360)
    Modal.GroupTransparency = 1
    Modal.Parent = SG

    -- Card (fix: clippt Ecken -> keine weißen Kanten)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.fromScale(1,1)
    Card.BackgroundColor3 = Theme.Secondary
    Card.ClipsDescendants = true
    Card.Parent = Modal
    rc(Card,14)
    st(Card,1,Theme.Outline,.42)

    -- weicher Verlaufs-Hintergrund (dunkelblau)
    local BG = Instance.new("Frame")
    BG.Size = UDim2.fromScale(1,1)
    BG.BackgroundColor3 = Theme.Secondary
    BG.Parent = Card
    local Grad = Instance.new("UIGradient")
    Grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(14,18,28)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(20,28,44)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(10,14,22)),
    })
    Grad.Parent = BG

    -- Close (X)
    local CloseX = Instance.new("TextButton")
    CloseX.AutoButtonColor=false
    CloseX.Text="×"; CloseX.TextSize=20; CloseX.Font=Enum.Font.GothamBold
    CloseX.TextColor3=Theme.Text
    CloseX.BackgroundTransparency=1
    CloseX.Size=UDim2.fromOffset(28,28)
    CloseX.Position=UDim2.new(1,-36,0,8)
    CloseX.Parent=Card
    CloseX.MouseButton1Click:Connect(function()
        tplay(Modal,.12,{GroupTransparency=1}); tplay(Shade,.10,{GroupTransparency=1})
        task.delay(.12,function() Modal:Destroy(); Shade:Destroy() end)
    end)

    -- Titel (gewünscht: Reedem Script Key)
    local H1 = Instance.new("TextLabel")
    H1.BackgroundTransparency=1
    H1.Font=Enum.Font.GothamBlack
    H1.TextSize=28
    H1.TextXAlignment=Enum.TextXAlignment.Left
    H1.TextColor3=Theme.Title
    H1.Text = "Reedem Script Key"
    H1.Position=UDim2.fromOffset(22,18)
    H1.Size=UDim2.new(1,-44,0,32)
    H1.Parent=Card

    -- Link-Zeilen
    local Links = Instance.new("TextLabel")
    Links.BackgroundTransparency=1
    Links.Font=Enum.Font.Gotham
    Links.RichText = true
    Links.TextSize=13
    Links.TextXAlignment=Enum.TextXAlignment.Left
    Links.TextColor3=Theme.Muted
    Links.Text = 'The Key link has been copied if not <font color="#4BA3FF"><u>click here</u></font> to copy\n'..
                 'Want to purchase subscription instead? <font color="#4BA3FF"><u>Click to purchase</u></font>'
    Links.Position=UDim2.fromOffset(22,58)
    Links.Size=UDim2.new(1,-44,0,42)
    Links.Parent=Card
    -- klickbare Hotspots (einfach kopieren in Zwischenablage)
    local LinkCopy = Instance.new("TextButton")
    LinkCopy.BackgroundTransparency=1; LinkCopy.Text=""; LinkCopy.AutoButtonColor=false
    LinkCopy.Size=UDim2.fromOffset(130,18); LinkCopy.Position=UDim2.fromOffset(260,58); LinkCopy.Parent=Card
    LinkCopy.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard((Box and (Box.Text:gsub("•",""))) or "") end
        Notify({Title="Key", Description="Key copied to clipboard.", Duration=1.6})
    end)
    local LinkBuy = Instance.new("TextButton")
    LinkBuy.BackgroundTransparency=1; LinkBuy.Text=""; LinkBuy.AutoButtonColor=false
    LinkBuy.Size=UDim2.fromOffset(150,18); LinkBuy.Position=UDim2.fromOffset(310,82); LinkBuy.Parent=Card
    LinkBuy.MouseButton1Click:Connect(function()
        if LOGIN.PurchaseURL and setclipboard then setclipboard(LOGIN.PurchaseURL) end
        Notify({Title="Purchase", Description="Purchase link copied.", Duration=1.6})
    end)

    -- KEY-ROW mit Eye-Icon (Asset statt Emoji) + ✓
    local Row = Instance.new("Frame")
    Row.BackgroundTransparency=1
    Row.Size=UDim2.new(1,-44,0,64)
    Row.Position=UDim2.fromOffset(22,110)
    Row.Parent=Card

    local Field = Instance.new("Frame")
    Field.BackgroundColor3 = Theme.Interact
    Field.Size = UDim2.new(1,0,1,0)
    Field.Parent = Row
    rc(Field,12)
    st(Field,1,Theme.Outline,.45)

    -- Eye icon (requested asset)
    local Eye = Instance.new("ImageButton")
    Eye.AutoButtonColor=false
    Eye.Image = "rbxassetid://6523858422"
    Eye.ImageColor3 = Color3.fromRGB(180, 205, 240)
    Eye.BackgroundTransparency=1
    Eye.Size=UDim2.fromOffset(34,34)
    Eye.Position=UDim2.fromOffset(12,15)
    Eye.Parent=Field

    -- Input
    Box = Instance.new("TextBox")
    Box.ClearTextOnFocus=false
    Box.BackgroundTransparency=1
    Box.TextColor3=Theme.Title
    Box.PlaceholderText="Elternative Library Key"
    Box.PlaceholderColor3=Theme.Muted
    Box.Font=Enum.Font.Gotham
    Box.TextSize=16
    Box.TextXAlignment=Enum.TextXAlignment.Left
    Box.Text=""
    Box.Position=UDim2.fromOffset(52,0)
    Box.Size=UDim2.new(1,-110,1,0)
    Box.Parent=Field

    -- Submit ✓
    local Submit = Instance.new("TextButton")
    Submit.AutoButtonColor=false
    Submit.Text="✓"; Submit.TextSize=18; Submit.Font=Enum.Font.GothamBold
    Submit.TextColor3=Color3.fromRGB(255,255,255)
    Submit.BackgroundColor3=Theme.Accent
    Submit.Size=UDim2.fromOffset(42,42)
    Submit.Position=UDim2.new(1,-52,.5,-21)
    Submit.Parent=Field
    rc(Submit,10)

    -- Fehlerausgabe
    local Error = Instance.new("TextLabel")
    Error.BackgroundTransparency=1
    Error.Font=Enum.Font.Gotham
    Error.TextSize=12
    Error.TextColor3=Theme.Danger
    Error.TextXAlignment=Enum.TextXAlignment.Left
    Error.Text = ""
    Error.Position = UDim2.fromOffset(24, 255)
    Error.Size = UDim2.new(1,-48,0,18)
    Error.Parent = Card

    -- DISCORD-BUTTON mit Gradient-Image + Icon links + Hover/Click
    local Discord = Instance.new("TextButton")
    Discord.AutoButtonColor=false
    Discord.BackgroundTransparency = 1
    Discord.Size = UDim2.new(1,-44,0,60)
    Discord.Position = UDim2.fromOffset(22, 190)
    Discord.Text = ""
    Discord.Parent = Card

    -- Hintergrund per Image (dein Gradient-Asset)
    local DiscBG = Instance.new("ImageLabel")
    DiscBG.BackgroundTransparency=1
    DiscBG.ScaleType = Enum.ScaleType.Stretch
    DiscBG.Image = "rbxassetid://424418391"
    DiscBG.ImageTransparency = 0
    DiscBG.Size = UDim2.fromScale(1,1)
    DiscBG.Parent = Discord
    rc(DiscBG,12)

    -- leichte Outline oben drauf
    local DiscStrokeHolder = Instance.new("Frame")
    DiscStrokeHolder.BackgroundTransparency=1
    DiscStrokeHolder.Size = UDim2.fromScale(1,1)
    DiscStrokeHolder.Parent = Discord
    rc(DiscStrokeHolder,12)
    st(DiscStrokeHolder,1,Color3.fromRGB(255,255,255),.85)

    -- Icon links (dein Asset)
    local DiscIcon = Instance.new("ImageLabel")
    DiscIcon.BackgroundTransparency=1
    DiscIcon.Image = "rbxassetid://124135407373085"
    DiscIcon.Size = UDim2.fromOffset(28,28)
    DiscIcon.Position = UDim2.fromOffset(18,16)
    DiscIcon.Parent = Discord

    local DiscTitle = Instance.new("TextLabel")
    DiscTitle.BackgroundTransparency=1
    DiscTitle.Font=Enum.Font.GothamBlack
    DiscTitle.TextSize=20
    DiscTitle.TextXAlignment=Enum.TextXAlignment.Left
    DiscTitle.TextColor3=Color3.fromRGB(255,255,255)
    DiscTitle.Text = "Discord"
    DiscTitle.Position=UDim2.fromOffset(54,7)
    DiscTitle.Size=UDim2.new(1,-70,0,22)
    DiscTitle.Parent=Discord

    local DiscSub = Instance.new("TextLabel")
    DiscSub.BackgroundTransparency=1
    DiscSub.Font=Enum.Font.Gotham
    DiscSub.TextSize=13
    DiscSub.TextXAlignment=Enum.TextXAlignment.Left
    DiscSub.TextColor3=Color3.fromRGB(230,240,255)
    DiscSub.Text = "Tap to Join Elternative Library discord server For updates and news"
    DiscSub.Position=UDim2.fromOffset(54,30)
    DiscSub.Size=UDim2.new(1,-70,0,20)
    DiscSub.Parent=Discord

    -- Hover / Press Effekt
    local hoverConn, outConn
    Discord.MouseEnter:Connect(function()
        tplay(Discord,.08,{Size=UDim2.new(1,-44,0,62)},Enum.EasingStyle.Sine)
        tplay(DiscBG,.08,{ImageTransparency = 0.03})
    end)
    Discord.MouseLeave:Connect(function()
        tplay(Discord,.10,{Size=UDim2.new(1,-44,0,60)},Enum.EasingStyle.Sine)
        tplay(DiscBG,.10,{ImageTransparency = 0})
    end)
    Discord.MouseButton1Down:Connect(function()
        tplay(DiscBG,.06,{ImageTransparency = 0.08})
    end)
    Discord.MouseButton1Up:Connect(function()
        tplay(DiscBG,.10,{ImageTransparency = 0.03})
    end)

    Discord.MouseButton1Click:Connect(function()
        if LOGIN.DiscordURL and setclipboard then
            setclipboard(LOGIN.DiscordURL)
            Notify({ Title="Discord", Description="Invite link copied. Paste in browser.", Duration=2 })
        else
            Notify({ Title="Discord", Description="No invite configured.", Duration=2 })
        end
    end)

    -- Eye-Masking (einfaches Visual-Masking)
    local masked, buffer = true, ""
    Eye.MouseButton1Click:Connect(function()
        masked = not masked
        if masked then
            Box.Text = string.rep("•", #buffer)
        else
            Box.Text = buffer
        end
    end)
    Box:GetPropertyChangedSignal("Text"):Connect(function()
        if masked then
            local n = utf8.len(Box.Text) or #Box.Text
            if n < #buffer then buffer = string.sub(buffer,1,n) end
            Box.Text = string.rep("•", #buffer)
        else
            buffer = Box.Text
        end
    end)

    -- Submit-Flow
    local function proceed()
        tplay(Modal,.12,{GroupTransparency=1}); tplay(Shade,.10,{GroupTransparency=1})
        task.delay(.12,function() Modal:Destroy(); Shade:Destroy(); open() end)
    end
    local function fail(msg)
        Error.Text = msg or "Invalid key."
        tplay(Error,.08,{TextTransparency=0})
    end
    local function doSubmit()
        local key = masked and buffer or Box.Text
        if LOGIN.OnSubmit then
            local ok = pcall(function() LOGIN.OnSubmit(key, proceed, fail) end)
            if not ok then fail("Validation error") end
        else
            proceed()
        end
    end
    Submit.MouseButton1Click:Connect(doSubmit)
    Box.FocusLost:Connect(function(enter) if enter then doSubmit() end end)

    -- Show modal
    tplay(Modal,.14,{GroupTransparency=Trans})
end
-- === Ende DROP-IN ===
