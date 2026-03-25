local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputSvc   = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui        = game:GetService("CoreGui")

local LP  = Players.LocalPlayer
local Char, HRP, Hum

local function RefreshChar()
    Char = LP.Character
    if not Char then return end
    HRP  = Char:FindFirstChild("HumanoidRootPart")
    Hum  = Char:FindFirstChildOfClass("Humanoid")
end
RefreshChar()
LP.CharacterAdded:Connect(function() task.wait(1) RefreshChar() end)


local PORTALS = {
    { Portal = "SoulDominion",    MobName = "Quincy",        FarmTime = 2  }, -- ตี 2 วิ
    { Portal = "Judgement", MobName = "Swordsman",  FarmTime = 2  }, -- ตี 2 วิ
    { Portal = "Ninja",   MobName = "Ninja",        FarmTime = 2  }, -- ตี 2 วิ
    { Portal = "Lawless", MobName = "ArenaFighter",  FarmTime = 2  }, -- ตี 2 วิ
    { Portal = "Acedamy", MobName = "Acedamy",  FarmTime = 2  }, -- ตี 2 วิ
    { Portal = "Slime", MobName = "Slime",  FarmTime = 2  }, -- ตี 2 วิ



}

local CFG = {
    Enabled    = true,
    floatheight = 15,
    FloatY     = 10,
    frozenCFrame= nil,
    SkillX     = true,
    SkillCoolX = 0.5,

    Portal     = PORTALS[1].Portal,
    MobName    = PORTALS[1].MobName,
}

local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local PortalRmt  = Remotes:WaitForChild("TeleportToPortal")
local CombatRmt  = ReplicatedStorage
    :WaitForChild("CombatSystem")
    :WaitForChild("Remotes")
    :WaitForChild("RequestHit")

if CoreGui:FindFirstChild("LF_UI") then CoreGui.LF_UI:Destroy() end
local SG = Instance.new("ScreenGui")
SG.Name = "LF_UI"; SG.Parent = CoreGui
SG.ZIndexBehavior = Enum.ZIndexBehavior.Global
SG.IgnoreGuiInset = true
SG.ResetOnSpawn  = false

local BG = Instance.new("Frame", SG)
BG.Size = UDim2.new(0,240,0,250)
BG.Position = UDim2.new(0,16,0.28,0)
BG.BackgroundColor3 = Color3.fromRGB(8,8,8)
BG.BorderSizePixel = 0
Instance.new("UICorner",BG).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke",BG).Color = Color3.fromRGB(38,38,38)

local Hdr = Instance.new("Frame",BG)
Hdr.Size = UDim2.new(1,0,0,34)
Hdr.BackgroundColor3 = Color3.fromRGB(13,13,13)
Hdr.BorderSizePixel = 0
Instance.new("UICorner",Hdr).CornerRadius = UDim.new(0,8)

local HdrLbl = Instance.new("TextLabel",Hdr)
HdrLbl.Size = UDim2.new(1,0,1,0)
HdrLbl.BackgroundTransparency = 1
HdrLbl.Text = "⚔  | IMPACT AUTO FARM  |"
HdrLbl.TextColor3 = Color3.fromRGB(85,255,127)
HdrLbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json",Enum.FontWeight.Bold)
HdrLbl.TextSize = 11

local function Div(y)
    local d = Instance.new("Frame",BG)
    d.Size = UDim2.new(1,-20,0,1)
    d.Position = UDim2.new(0,10,0,y)
    d.BackgroundColor3 = Color3.fromRGB(28,28,28)
    d.BorderSizePixel = 0
end

local function Row(ic,lb,y)
    local f = Instance.new("Frame",BG)
    f.Size = UDim2.new(1,-20,0,20)
    f.Position = UDim2.new(0,10,0,y)
    f.BackgroundTransparency = 1
    local function T(txt,col,xalign,szx,px)
        local t = Instance.new("TextLabel",f)
        t.BackgroundTransparency = 1
        t.Size = UDim2.new(0,szx,1,0)
        t.Position = UDim2.new(0,px,0,0)
        t.Text = txt; t.TextColor3 = col
        t.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json",Enum.FontWeight.Medium)
        t.TextSize = 10; t.TextXAlignment = xalign
        return t
    end
    T(ic, Color3.fromRGB(120,120,120), Enum.TextXAlignment.Left, 18, 0)
    T(lb, Color3.fromRGB(70,70,70),   Enum.TextXAlignment.Left, 80, 20)
    local v = T("—", Color3.fromRGB(200,200,200), Enum.TextXAlignment.Right, 110, 110)
    return v
end

Div(36)
local vStatus = Row("⚡","Status",  42)
local vPhase  = Row("🗺","Zone",    64)
local vTimer  = Row("⏱","Time",    86)
local vTarget = Row("🎯","Target", 108)
local vWeapon = Row("🥊","Weapon", 130)
Div(154)

local Btn = Instance.new("TextButton",BG)
Btn.Size = UDim2.new(1,-20,0,26)
Btn.Position = UDim2.new(0,10,1,-34)
Btn.BackgroundColor3 = Color3.fromRGB(18,18,18)
Btn.BorderSizePixel = 0
Btn.Text = "[ F ]  START FARM"
Btn.TextColor3 = Color3.fromRGB(85,255,127)
Btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json",Enum.FontWeight.Bold)
Btn.TextSize = 10
Instance.new("UICorner",Btn).CornerRadius = UDim.new(0,4)
local BS = Instance.new("UIStroke",Btn); BS.Color = Color3.fromRGB(85,255,127)

local drag,di,ds,sp
Hdr.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true;ds=i.Position;sp=BG.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false end end)
    end
end)
Hdr.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement then di=i end end)
UserInputSvc.InputChanged:Connect(function(i)
    if i==di and drag then
        local d=i.Position-ds
        BG.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
    end
end)

local function SetOn(on)
    CFG.Enabled = on
    if on then
        vStatus.Text="RUNNING"; vStatus.TextColor3=Color3.fromRGB(85,255,127)
        Btn.Text="[ F ]  STOP FARM"; Btn.TextColor3=Color3.fromRGB(255,90,90); BS.Color=Color3.fromRGB(255,90,90)
    else
        vStatus.Text="OFF"; vStatus.TextColor3=Color3.fromRGB(255,90,90)
        vPhase.Text="—"; vTarget.Text="—"; vTimer.Text="—"
        Btn.Text="[ F ]  START FARM"; Btn.TextColor3=Color3.fromRGB(85,255,127); BS.Color=Color3.fromRGB(85,255,127)
        if Hum then Hum.AutoRotate=true end
    end
end

Btn.MouseButton1Click:Connect(function() SetOn(not CFG.Enabled) end)
UserInputSvc.InputBegan:Connect(function(i,p)
    if p then return end
    if i.KeyCode==Enum.KeyCode.F then SetOn(not CFG.Enabled) end
end)

local function GetCurrentTool()
    if not Char then return nil end
    for _,v in ipairs(Char:GetChildren()) do
        if v:IsA("Tool") then return v end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _,v in ipairs(bp:GetChildren()) do
            if v:IsA("Tool") then
                if Hum then
                    pcall(function() Hum:EquipTool(v) end)
                    task.wait(0.15)
                    for _,c in ipairs(Char:GetChildren()) do
                        if c:IsA("Tool") then return c end
                    end
                end
            end
        end
    end
    return nil
end

local BossKW = {"Boss","Elite","Guard","Captain","Lord","King"}
local function IsBoss(name)
    local lo = name:lower()
    for _,kw in ipairs(BossKW) do
        if lo:find(kw:lower(),1,true) then return true end
    end
    return false
end

local function FindNearestMob()
    RefreshChar()
    if not HRP then return nil end
    local best, bestDist = nil, math.huge
    local npcs = workspace:FindFirstChild("NPCs") or workspace
    for _,m in ipairs(npcs:GetDescendants()) do
        if m:IsA("Model") and m ~= Char then
            local hum  = m:FindFirstChildOfClass("Humanoid")
            local root = m:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                local lo = m.Name:lower()
                if lo:find(CFG.MobName:lower(),1,true) and not IsBoss(m.Name) then
                    local d = (HRP.Position - root.Position).Magnitude
                    if d < bestDist then bestDist=d; best=m end
                end
            end
        end
    end
    return best
end

local frozenCFrame = nil
local freezeUntil  = 0

local function TPToTarget(root)
    RefreshChar()
    if not HRP or not root then return end
    local dest = CFrame.new(root.Position + Vector3.new(0, CFG.FloatY, 0))
        * CFrame.Angles(math.rad(90), 0, 0)
    HRP.AssemblyLinearVelocity  = Vector3.zero
    HRP.AssemblyAngularVelocity = Vector3.zero
    HRP.CFrame = dest
    frozenCFrame = dest
    freezeUntil  = tick() + 0.3
    pcall(function()
        for _,p in ipairs(Char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

RunService.Heartbeat:Connect(function()
    if frozenCFrame and tick() < freezeUntil then
        if HRP then
            HRP.AssemblyLinearVelocity  = Vector3.zero
            HRP.AssemblyAngularVelocity = Vector3.zero
            HRP.CFrame = frozenCFrame
        end
    else
        frozenCFrame = nil
    end
end)

local tping       = false
local lastTP      = -999
local TP_GRACE    = 12
local TP_COOLDOWN = 20  
local function OnIslandReal()
    RefreshChar()
    if not HRP then return false end
    local npcs = workspace:FindFirstChild("NPCs") or workspace
    for _,m in ipairs(npcs:GetDescendants()) do
        if m:IsA("Model") then
            local lo = m.Name:lower()
            if lo:find(CFG.MobName:lower(),1,true) then
                local root = m:FindFirstChild("HumanoidRootPart")
                if root and (HRP.Position - root.Position).Magnitude < 600 then
                    return true
                end
            end
        end
    end
    return false
end

local function OnIsland()
    if tick() - lastTP < TP_GRACE then return true end
    return OnIslandReal()
end

local function DoTeleport()
    if tping then return end
    tping  = true
    lastTP = tick()
    vPhase.Text = "→ " .. CFG.Portal
    vPhase.TextColor3 = Color3.fromRGB(255,200,0)
    pcall(function() PortalRmt:FireServer(CFG.Portal) end)
    task.wait(3)
    RefreshChar()
    vPhase.TextColor3 = Color3.fromRGB(85,255,127)
    tping = false
end

local portalIndex   = 1
local zoneStartTime = tick()

local function SwitchToNextPortal()
    portalIndex = (portalIndex % #PORTALS) + 1
    local p = PORTALS[portalIndex]
    CFG.Portal  = p.Portal
    CFG.MobName = p.MobName
    zoneStartTime = tick(0.5)
    return p
end

task.spawn(function()
    while true do
        task.wait(1)
        if not CFG.Enabled then continue end
        local p = PORTALS[portalIndex]
        local elapsed = tick() - zoneStartTime
        local remain  = math.max(0, p.FarmTime - elapsed)
        vTimer.Text   = string.format("%ds / %ds", math.floor(elapsed), p.FarmTime)

        if elapsed >= p.FarmTime then
            local next = SwitchToNextPortal()
            print(string.format("[Rotation] → %s (%s)", next.Portal, next.MobName))
            lastTP = -999
            tping  = false
            task.spawn(DoTeleport)
        end
    end
end)

local curTarget = nil

RunService.Heartbeat:Connect(function()
    if not CFG.Enabled then return end
    RefreshChar()
    if not HRP or not Hum or Hum.Health <= 0 then return end

    if not OnIsland() then
        vPhase.Text = "Not on island"
        vPhase.TextColor3 = Color3.fromRGB(255,80,80)
        if not tping and tick() - lastTP > TP_COOLDOWN then
            task.spawn(DoTeleport)
        end
        return
    end

    vPhase.Text = CFG.Portal
    vPhase.TextColor3 = Color3.fromRGB(85,255,127)

    local tool = GetCurrentTool()
    if tool then
        vWeapon.Text = tool.Name .. " ✓"
        vWeapon.TextColor3 = Color3.fromRGB(85,255,127)
    else
        vWeapon.Text = "No tool!"
        vWeapon.TextColor3 = Color3.fromRGB(255,80,80)
    end

    local alive = curTarget
        and curTarget.Parent
        and curTarget:FindFirstChildOfClass("Humanoid")
        and curTarget:FindFirstChildOfClass("Humanoid").Health > 0

    if not alive then curTarget = FindNearestMob() end

    if not curTarget then
        vTarget.Text = "Searching..."
        vTarget.TextColor3 = Color3.fromRGB(255,200,0)
        return
    end

    local tRoot = curTarget:FindFirstChild("HumanoidRootPart")
    if not tRoot then curTarget = nil; return end

    vTarget.Text = curTarget.Name
    vTarget.TextColor3 = Color3.fromRGB(200,200,200)

    Hum.AutoRotate = false
    TPToTarget(tRoot)

    pcall(function()
        firetouchinterest(HRP, tRoot, 0)
        firetouchinterest(HRP, tRoot, 1)
    end)

    pcall(function() CombatRmt:FireServer(tRoot.Position) end)

    if tool then
        pcall(function()
            local act = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent")
            if act then act:FireServer() end
        end)
    end
end)

local AbilityRmt = nil
pcall(function()
    AbilityRmt = ReplicatedStorage.AbilitySystem.Remotes.RequestAbility
end)

local lastSkillX = 0

task.spawn(function()
    while true do
        task.wait(0.05)
        if not CFG.Enabled then continue end
        RefreshChar()
        if not Hum or Hum.Health <= 0 then continue end
        local now = tick()
        if CFG.SkillX and AbilityRmt and now - lastSkillX >= CFG.SkillCoolX then
            lastSkillX = now
            pcall(function() AbilityRmt:FireServer(2) end)
        end
    end
end)

task.spawn(DoTeleport)

print("[AutoFarm v7] Loaded — F = Toggle")
print("[AutoFarm v7] Rotation: Ninja(60s) → Soul(60s) → Lawless(60s)")

-- [[ นำระบบที่ให้มาใหม่มาใส่ด้านล่างนี้ ]]

local lp = LP
_G.MasterToggle = CFG.Enabled

RunService.Stepped:Connect(function()
    _G.MasterToggle = CFG.Enabled -- เชื่อม Toggle ของระบบใหม่เข้ากับ CFG.Enabled ของระบบเก่า
    if _G.MasterToggle and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = lp.Character.HumanoidRootPart
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")

        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.RotVelocity = Vector3.new(0, 0, 0)

        for _, v in ipairs(lp.Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end

        if hrp.Position.Y < -50 then 
            if lastCFrame then
                hrp.CFrame = lastCFrame
            else
                hrp.CFrame = CFrame.new(0, 100, 0) 
            end
        end

        local bv = hrp:FindFirstChild("FarmFloat")
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.Name = "FarmFloat"
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = hrp
        end
        
        hum.PlatformStand = true 
    end
end)
