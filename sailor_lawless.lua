repeat task.wait(.1) until game:IsLoaded()

-- ══════════════════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputSvc      = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local GuiService        = game:GetService("GuiService")
local VirtualUser       = game:GetService("VirtualUser")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")
local VIM               = game:GetService("VirtualInputManager")  -- ✅ เพิ่มสำหรับ Auto Haki

local LP            = Players.LocalPlayer
local placeId       = game.PlaceId
local jobId         = game.JobId
local privateServerId = game.PrivateServerId
local Char, HRP, Hum

local function RefreshChar()
    Char = LP.Character
    if not Char then return end
    HRP  = Char:FindFirstChild("HumanoidRootPart")
    Hum  = Char:FindFirstChildOfClass("Humanoid")
end
RefreshChar()
LP.CharacterAdded:Connect(function() task.wait(1) RefreshChar() end)

-- ══════════════════════════════════════════════════════
-- PORTAL LIST
-- ══════════════════════════════════════════════════════
local PORTALS = {
    { Portal = "HollowIsland", MobName = "Hollow",         FarmTime = 1 },
    { Portal = "HollowIsland",     MobName = "AizenBoss",       FarmTime = 0, IsBossEntry = true },
    { Portal = "Starter",      MobName = "Thief",  "ThiefBoss",           FarmTime = 1 , IsBossEntry = true},
    { Portal = "Jungle",       MobName = "Monkey", "MonkeyBoss",           FarmTime = 1 , IsBossEntry = true },
    { Portal = "Desert",       MobName = "Desert", "DesertBoss",           FarmTime = 1 , IsBossEntry = true },
    { Portal = "Snow",         MobName = "Frostrogue", "SnowBoss",           FarmTime = 1 , IsBossEntry = true },
    { Portal = "Shinjuku",     MobName = "Curse",          FarmTime = 1 },
    { Portal = "Shinjuku",     MobName = "StrongSorcerer", FarmTime = 1 },
    { Portal = "Sailor",     MobName = "JinwooBoss",       FarmTime = 0, IsBossEntry = true },
    { Portal = "Slime",        MobName = "Slime",          FarmTime = 1 },
    { Portal = "Sailor",     MobName = "AlucardBoss",       FarmTime = 0, IsBossEntry = true },
    { Portal = "Shibuya",      MobName = "Sorcerer",     FarmTime = 1},
    { Portal = "Shibuya",     MobName = "GojoBoss",       FarmTime = 0, IsBossEntry = true },
    { Portal = "Academy",      MobName = "AcademyTeacher", FarmTime = 1 },
    { Portal = "Judgement",    MobName = "Swordsman",      FarmTime = 2 },
    { Portal = "Shibuya",     MobName = "SukunaBoss",       FarmTime = 0, IsBossEntry = true },
    { Portal = "SoulDominion", MobName = "Quincy",         FarmTime = 4 },
    { Portal = "Ninja",        MobName = "Ninja",          FarmTime = 3 },
    { Portal = "Shibuya",     MobName = "YujiBoss",       FarmTime = 0, IsBossEntry = true },
    { Portal = "Lawless",      MobName = "ArenaFighter",   FarmTime = 2 },
}

local portalIndex   = 19
local zoneStartTime = tick()

local CFG = {
    Enabled     = true,
    Portal      = PORTALS[portalIndex].Portal,
    MobName     = PORTALS[portalIndex].MobName,
    FloatY      = 3,
    AutoRotate  = true,
    SkillX      = true,
    SkillCoolX  = 0.1,
    AntiAFK         = true,
    AntiAFKInterval = 60,
    TPMinDelay  = 0.5,
    TPRandExtra = 0.5,
    AutoRejoin  = true,
    BusoOn      = true,   -- ✅ Armament Haki (G)
    ObsOn       = true,   -- ✅ Observation Haki (H)
}

-- ══════════════════════════════════════════════════════
-- FPS BOOST (รันทันที)
-- ══════════════════════════════════════════════════════
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") or v:IsA("Sky")
        or v:IsA("BloomEffect") or v:IsA("BlurEffect")
        or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect")
        or v:IsA("DepthOfFieldEffect") then
            pcall(function() v:Destroy() end)
        end
    end
end)

-- ══════════════════════════════════════════════════════
-- BYPASS GAMEPLAY PAUSED
-- ══════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(function()
            for _, sg in ipairs(CoreGui:GetChildren()) do
                if sg:IsA("ScreenGui") then
                    local lo = sg.Name:lower()
                    if lo:find("pause") or lo:find("paused") or lo:find("gameplay") then
                        sg.Enabled = false
                    end
                end
            end
        end)
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam and cam.CameraType ~= Enum.CameraType.Custom then
                cam.CameraType = Enum.CameraType.Custom
            end
        end)
    end
end)

-- ══════════════════════════════════════════════════════
-- AUTO REJOIN — รองรับ error 773
-- ══════════════════════════════════════════════════════
local SCRIPT_URL = "https://raw.githubusercontent.com/IMPACTlazy/NEW-FARM/refs/heads/main/sailor_lawless.lua"

if queue_on_teleport then
    queue_on_teleport(string.format([[loadstring(game:HttpGet("%s"))()]], SCRIPT_URL))
    print("[AutoExec] queue_on_teleport ✅")
end

pcall(function()
    if not isfolder("SailorHub") then makefolder("SailorHub") end
    if privateServerId ~= "" then
        writefile("SailorHub/last_server.json",
            game:GetService("HttpService"):JSONEncode({
                placeId = placeId, jobId = jobId, privateId = privateServerId
            })
        )
    end
end)

local isRejoining = true
local function DoRejoin()
    if isRejoining then return end
    isRejoining = true
    print("[Rejoin] กำลัง rejoin...")
    task.wait(1)
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, LP)
    end)
    if not ok then
        task.wait(1)
        ok = pcall(function() TeleportService:Teleport(placeId, LP) end)
    end
    if not ok then
        print("[Rejoin] ❌ retry ใน 5s")
        task.wait(5)
        isRejoining = false
        task.spawn(DoRejoin)
    end
end

GuiService.ErrorMessageChanged:Connect(function(msg)
    if not CFG.AutoRejoin or msg == "" then return end
    local lo = msg:lower()
    if lo:find("teleport") or lo:find("connecting") then return end
    print("[Rejoin] " .. msg)
    task.spawn(DoRejoin)
end)

task.spawn(function()
    while true do
        task.wait(0.3)
        if not CFG.AutoRejoin then continue end
        pcall(function()
            for _, sg in ipairs(CoreGui:GetDescendants()) do
                if not sg:IsA("TextButton") then continue end
                local t = sg.Text:lower()
                if not (t == "ออก" or t == "ok" or t == "okay" or t == "leave") then continue end
                if not sg.Visible then continue end
                local frame = sg.Parent
                if not frame then continue end
                for _, child in ipairs(frame:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        local txt = child.Text:lower()
                        if txt:find("773") or txt:find("disconnect")
                            or txt:find("kicked") or txt:find("เชื่อมต่อ")
                            or txt:find("ยกเลิก") or txt:find("สำเร็จ")
                        then
                            print("[Rejoin] พบ popup 773 → กด OK")
                            pcall(function() sg.MouseButton1Click:Fire() end)
                            task.wait(0.5)
                            task.spawn(DoRejoin)
                            return
                        end
                    end
                end
            end
        end)
    end
end)

LP.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        print("[Rejoin] TeleportState.Failed → retry")
        isRejoining = false
        task.wait(3)
        task.spawn(DoRejoin)
    end
end)

-- ══════════════════════════════════════════════════════
-- REMOTES
-- ══════════════════════════════════════════════════════
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local PortalRmt = Remotes:WaitForChild("TeleportToPortal")
local CombatRmt = ReplicatedStorage
    :WaitForChild("CombatSystem")
    :WaitForChild("Remotes")
    :WaitForChild("RequestHit")

local AbilityRmt = nil
pcall(function()
    AbilityRmt = ReplicatedStorage.AbilitySystem.Remotes.RequestAbility
end)

-- ══════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════
local BossKW = {"Boss","Elite","Guard","Captain","Lord","King"}
local function IsBoss(name)
    local lo = name:lower()
    for _, kw in ipairs(BossKW) do
        if lo:find(kw:lower(), 1, true) then return true end
    end
    return false
end

-- ✅ FIX 1: FindNearestMob — เช็ค IsBossEntry ก่อนกรอง boss
local function FindNearestMob()
    if not HRP then return nil end
    local best, bestDist = nil, math.huge
    local npcs   = workspace:FindFirstChild("NPCs") or workspace
    local mobLow = CFG.MobName:lower()
    local isBossMode = PORTALS[portalIndex].IsBossEntry
    for _, m in ipairs(npcs:GetDescendants()) do
        if m:IsA("Model") and m ~= Char then
            local hum  = m:FindFirstChildOfClass("Humanoid")
            local root = m:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root
                and m.Name:lower():find(mobLow, 1, true)
                and (isBossMode or not IsBoss(m.Name))
            then
                local d = (HRP.Position - root.Position).Magnitude
                if d < bestDist then bestDist = d; best = m end
            end
        end
    end
    return best
end

local function GetCurrentTool()
    if not Char then return nil end
    for _, v in ipairs(Char:GetChildren()) do
        if v:IsA("Tool") then return v end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, v in ipairs(bp:GetChildren()) do
            if v:IsA("Tool") then
                task.spawn(function()
                    if Hum then pcall(function() Hum:EquipTool(v) end) end
                end)
                break
            end
        end
    end
    return nil
end

local function DisableCollision()
    if not Char then return end
    for _, v in ipairs(Char:GetDescendants()) do
        if v:IsA("BasePart") then
            pcall(function() v.CanCollide = false end)
        end
    end
end
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    RefreshChar()
    DisableCollision()
end)

-- ══════════════════════════════════════════════════════
-- CENTROID
-- ══════════════════════════════════════════════════════
local MOB_GATHER_RADIUS = 600

-- ✅ FIX 2: GetMobCentroid — เช็ค IsBossEntry ก่อนกรอง boss
local function GetMobCentroid()
    if not HRP then return nil end
    local npcs   = workspace:FindFirstChild("NPCs") or workspace
    local mobLow = CFG.MobName:lower()
    local isBossMode = PORTALS[portalIndex].IsBossEntry
    local sum, count = Vector3.zero, 0
    for _, m in ipairs(npcs:GetDescendants()) do
        if m:IsA("Model") and m ~= Char then
            local hum  = m:FindFirstChildOfClass("Humanoid")
            local root = m:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root
                and m.Name:lower():find(mobLow, 1, true)
                and (isBossMode or not IsBoss(m.Name))
                and (HRP.Position - root.Position).Magnitude <= MOB_GATHER_RADIUS
            then
                sum   = sum + root.Position
                count = count + 1
            end
        end
    end
    if count == 0 then return nil end
    return sum / count
end

-- ══════════════════════════════════════════════════════
-- TP TO MOB
-- ══════════════════════════════════════════════════════
local lastTPTime             = 1
local frozenCF, freezeUntil = nil, 0
local lastCFrame             = nil

local function TPToTarget(root)
    if not HRP or not root then return end

    local now   = tick()
    local delay = CFG.TPMinDelay + math.random() * CFG.TPRandExtra
    if now - lastTPTime < delay then return end
    lastTPTime = tick()

    local targetPos = GetMobCentroid() or root.Position

    HRP.AssemblyLinearVelocity  = Vector3.zero
    HRP.AssemblyAngularVelocity = Vector3.zero
    HRP.CFrame = CFrame.new(targetPos + Vector3.new(0, CFG.FloatY + 12, 0))
    task.wait(0.03)

    local dest = CFrame.new(targetPos + Vector3.new(0, CFG.FloatY, 0))
    HRP.AssemblyLinearVelocity  = Vector3.zero
    HRP.AssemblyAngularVelocity = Vector3.zero
    HRP.CFrame = dest

    frozenCF    = dest
    freezeUntil = tick() + 0.3
    lastCFrame  = dest

    DisableCollision()
end

-- ══════════════════════════════════════════════════════
-- FLOAT LOCK
-- ══════════════════════════════════════════════════════
RunService.Stepped:Connect(function()
    if not CFG.Enabled then return end
    if not Char or not HRP or not Hum then return end

    HRP.Velocity    = Vector3.zero
    HRP.RotVelocity = Vector3.zero

    for _, v in ipairs(Char:GetDescendants()) do
        if v:IsA("BasePart") then
            pcall(function() v.CanCollide = false end)
        end
    end

    if HRP.Position.Y < -50 then
        HRP.CFrame = lastCFrame or CFrame.new(0, 100, 0)
    end

    local bv = HRP:FindFirstChild("FarmFloat")
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name     = "FarmFloat"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        bv.Parent   = HRP
    end
    bv.Velocity = Vector3.zero

    pcall(function() Hum.PlatformStand = true end)
end)

RunService.Heartbeat:Connect(function()
    if frozenCF and tick() < freezeUntil and HRP then
        HRP.AssemblyLinearVelocity  = Vector3.zero
        HRP.AssemblyAngularVelocity = Vector3.zero
        HRP.CFrame = frozenCF
    else
        frozenCF = nil
    end
    if HRP and CFG.Enabled then
        lastCFrame = HRP.CFrame
    end
end)

-- ══════════════════════════════════════════════════════
-- REMOVE MAP
-- ══════════════════════════════════════════════════════
local mapRemoved = false

local function RemoveMap()
    if mapRemoved then return end
    mapRemoved = true

    local removed  = 0
    local keepName = { NPCs = true, Terrain = true, Camera = true }

    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Terrain") or obj:IsA("Camera") then continue end
        if keepName[obj.Name] then continue end
        if obj == Char then continue end
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then continue end
        pcall(function() obj:Destroy() removed += 1 end)
    end

    print(("[RemoveMap] ลบ %d objects — เหลือแค่ NPCs"):format(removed))
end

-- ══════════════════════════════════════════════════════
-- ISLAND CHECK + TELEPORT
-- ══════════════════════════════════════════════════════
local tping       = false
local lastTP      = -999
local TP_GRACE    = 0
local TP_COOLDOWN = 0

local function OnIsland()
    if tick() - lastTP < TP_GRACE then return true end
    if not HRP then return false end
    local npcs   = workspace:FindFirstChild("NPCs") or workspace
    local mobLow = CFG.MobName:lower()
    for _, m in ipairs(npcs:GetDescendants()) do
        if m:IsA("Model") and m.Name:lower():find(mobLow, 1, true) then
            local root = m:FindFirstChild("HumanoidRootPart")
            if root and (HRP.Position - root.Position).Magnitude < 600 then
                return true
            end
        end
    end
    return false
end

local function DoTeleport()
    if tping then return end
    tping  = true
    lastTP = tick()
    print(("[Farm] TP → %s (%s)"):format(CFG.Portal, CFG.MobName))
    pcall(function() PortalRmt:FireServer(CFG.Portal) end)
    task.wait(1)
    RefreshChar()
    tping = false
end

-- ══════════════════════════════════════════════════════
-- PORTAL SWITCH
-- ══════════════════════════════════════════════════════
local curTarget = nil

local function SwitchPortal(idx)
    idx         = ((idx - 1) % #PORTALS) + 1
    local p     = PORTALS[idx]
    portalIndex   = idx
    CFG.Portal    = p.Portal
    CFG.MobName   = p.MobName
    zoneStartTime = tick()
    mapRemoved    = false
    curTarget     = nil
    lastTP        = -999
    tping         = false
    print(("[Portal] → [%d/%d] %s | %s | %ds")
        :format(idx, #PORTALS, p.Portal, p.MobName, p.FarmTime))
    task.spawn(DoTeleport)
end

-- ══════════════════════════════════════════════════════
-- PORTAL ROTATION LOOP
-- ✅ FIX 3: บอสไม่เกิดใน 30 วิ → ข้ามไปก่อน แล้ววนกลับมาเอง
-- ══════════════════════════════════════════════════════
local BOSS_SKIP_TIMEOUT = 0

task.spawn(function()
    while true do
        task.wait(1)
        if not CFG.Enabled or not CFG.AutoRotate then continue end
        local p = PORTALS[portalIndex]

        if p.IsBossEntry then
            local bossFound = false
            local npcs = workspace:FindFirstChild("NPCs") or workspace
            local mobLow = p.MobName:lower()
            for _, m in ipairs(npcs:GetDescendants()) do
                if m:IsA("Model") and m.Name:lower():find(mobLow, 1, true) then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        bossFound = true; break
                    end
                end
            end
            if not bossFound and tick() - zoneStartTime >= BOSS_SKIP_TIMEOUT then
                print(("[Portal] บอสไม่เกิดใน %ds → ข้าม"):format(BOSS_SKIP_TIMEOUT))
                SwitchPortal(portalIndex + 1)
            end
        else
            if tick() - zoneStartTime >= p.FarmTime then
                SwitchPortal(portalIndex + 1)
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════
-- ✅ AUTO HAKI — กด G/H ตอนโหลด + ตาย respawn ใหม่อัตโนมัติ
-- ══════════════════════════════════════════════════════
local function PressKey(keyCode)
    pcall(function() VIM:SendKeyEvent(true,  keyCode, false, game) end)
    task.delay(0.1, function()
        pcall(function() VIM:SendKeyEvent(false, keyCode, false, game) end)
    end)
end

local function ActivateHaki()
    task.wait(0.5)
    if CFG.BusoOn then
        PressKey(Enum.KeyCode.G)
        print("[Haki] Armament (Buso) ON ✅")
    end
    task.wait(0.3)
    if CFG.ObsOn then
        PressKey(Enum.KeyCode.H)
        print("[Haki] Observation (Obs) ON ✅")
    end
end

ActivateHaki()

LP.CharacterAdded:Connect(function()
    task.wait(2.5)
    RefreshChar()
    DisableCollision()
    ActivateHaki()  -- ✅ กด Haki ใหม่ทุกครั้งที่ respawn
end)

-- ══════════════════════════════════════════════════════
-- ANTI-AFK
-- ══════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(CFG.AntiAFKInterval)
        if CFG.AntiAFK then
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam then
                    cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(0.1), 0)
                end
            end)
        end
    end
end)

LP.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- ══════════════════════════════════════════════════════
-- MAIN FARM LOOP
-- ══════════════════════════════════════════════════════
local lastSkillX = 0

task.spawn(DoTeleport)

task.spawn(function()
    while true do
        task.wait(0.05)
        if not CFG.Enabled then continue end
        RefreshChar()
        if not HRP or not Hum or Hum.Health <= 0 then continue end

        if HRP.Position.Y < -100 then
            HRP.CFrame = frozenCF or CFrame.new(0, 100, 0)
        end

        if not OnIsland() then
            if not tping and tick() - lastTP > TP_COOLDOWN then
                task.spawn(DoTeleport)
            end
            continue
        end

        if not mapRemoved then
            task.spawn(RemoveMap)
        end

        pcall(function() Hum.PlatformStand = true end)
        GetCurrentTool()

        local alive = curTarget
            and curTarget.Parent
            and (curTarget:FindFirstChildOfClass("Humanoid") or {Health=0}).Health > 0
        if not alive then curTarget = FindNearestMob() end
        if not curTarget then continue end

        local tRoot = curTarget:FindFirstChild("HumanoidRootPart")
        if not tRoot then curTarget = nil; continue end

        Hum.AutoRotate = false
        TPToTarget(tRoot)

        local npcs   = workspace:FindFirstChild("NPCs") or workspace
        local mobLow = CFG.MobName:lower()
        -- ✅ FIX 3 (ใน loop ตี): เช็ค IsBossEntry ก่อนกรอง boss
        local isBossMode = PORTALS[portalIndex].IsBossEntry
        for _, m in ipairs(npcs:GetDescendants()) do
            if m:IsA("Model") and m ~= Char then
                local hum   = m:FindFirstChildOfClass("Humanoid")
                local mRoot = m:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and mRoot
                    and m.Name:lower():find(mobLow, 1, true)
                    and (isBossMode or not IsBoss(m.Name))
                    and (HRP.Position - mRoot.Position).Magnitude <= MOB_GATHER_RADIUS
                then
                    pcall(function()
                        firetouchinterest(HRP, mRoot, 0)
                        firetouchinterest(HRP, mRoot, 1)
                        CombatRmt:FireServer(mRoot.Position)
                    end)
                end
            end
        end

        -- ✅ เหลือแค่ SkillX (ลบ SkillZ ออกแล้ว)
        if AbilityRmt then
            local now = tick()
            if CFG.SkillX and now - lastSkillX >= CFG.SkillCoolX then
                lastSkillX = now
                pcall(function() AbilityRmt:FireServer(2) end)
            end
        end

        local tool = GetCurrentTool()
        if tool then
            pcall(function()
                local act = tool:FindFirstChildOfClass("RemoteEvent")
                if act then act:FireServer() end
            end)
        end
    end
end)

-- ══════════════════════════════════════════════════════
-- HOTKEYS
-- ══════════════════════════════════════════════════════
UserInputSvc.InputBegan:Connect(function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.F then
        CFG.Enabled = not CFG.Enabled
        print("[Farm] " .. (CFG.Enabled and "STARTED ✅" or "STOPPED ❌"))
        if CFG.Enabled then lastTP = -999; task.spawn(DoTeleport) end

    elseif i.KeyCode == Enum.KeyCode.R then
        CFG.AutoRotate = not CFG.AutoRotate
        print("[Rotation] " .. (CFG.AutoRotate and "ON 🔄" or "OFF ⏹"))
        if CFG.AutoRotate then zoneStartTime = tick() end

    elseif i.KeyCode == Enum.KeyCode.LeftBracket then
        SwitchPortal(portalIndex - 1)

    elseif i.KeyCode == Enum.KeyCode.RightBracket then
        SwitchPortal(portalIndex + 1)
    end
end)

-- ══════════════════════════════════════════════════════
-- STARTUP LOG
-- ══════════════════════════════════════════════════════
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("[Farm] Loaded ✅  No UI  |  AutoRotate=" .. tostring(CFG.AutoRotate))
print("[Farm] F=Toggle | R=Rotation | [=Prev | ]=Next")
for i, v in ipairs(PORTALS) do
    print(("  [%02d] %-14s | %-18s | %ds%s")
        :format(i, v.Portal, v.MobName, v.FarmTime,
            i == portalIndex and "  ◀ START" or ""))
end
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
