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
local VIM               = game:GetService("VirtualInputManager")

local LP              = Players.LocalPlayer
local placeId         = game.PlaceId
local jobId           = game.JobId
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
-- PORTAL / MOB LIST
-- ══════════════════════════════════════════════════════
local PORTALS = {
    { Portal = "Starter",      MobName = "Thief",          FarmTime = 1 },
    { Portal = "Starter",      MobName = "ThiefBoss",      FarmTime = 1,IsBossEntry = true},
    { Portal = "Jungle",       MobName = "Monkey",         FarmTime = 1 },
    { Portal = "Jungle",       MobName = "MonkeyBoss",     FarmTime = 1,  IsBossEntry = true },
    { Portal = "Desert",       MobName = "Desert",         FarmTime = 1 },
    { Portal = "Desert",       MobName = "DesertBoss",     FarmTime = 1,  IsBossEntry = true },
    {Portal =  "Snow",         MobName = "FrostRogue",     FarmTime = 1,},
    { Portal = "Snow",         MobName = "SnowBoss",       FarmTime = 1,  IsBossEntry = true},
    { Portal = "HollowIsland", MobName = "Hollow",         FarmTime = 0 },
    { Portal = "Shibuya",      MobName = "Sorcerer",       FarmTime = 0 },
    { Portal = "Shinjuku",     MobName = "Curse",          FarmTime = 0 },
    { Portal = "Shinjuku",     MobName = "StrongSorcerer", FarmTime = 0 },
    { Portal = "Slime",        MobName = "Slime",          FarmTime = 0 },
    { Portal = "Academy",      MobName = "AcademyTeacher", FarmTime = 0 },
    { Portal = "Judgement",    MobName = "Swordsman",      FarmTime = 0 },
    { Portal = "SoulDominion", MobName = "Quincy",         FarmTime = 2.3 },
    { Portal = "Ninja",        MobName = "Ninja",          FarmTime = 1 },
    { Portal = "Lawless",      MobName = "ArenaFighter",   FarmTime = 1 },

}

local DEFAULT_FARM_TIME  = 0
local BOSS_SKIP_TIMEOUT  = 0

local portalIndex   = 1
local zoneStartTime = tick()

local CFG = {
    Portal          = PORTALS[portalIndex].Portal,
    MobName         = PORTALS[portalIndex].MobName,
    FloatY          = 3,
    AutoRotate      = true,
    SkillX          = true,
    SkillCoolX      = 0.01,
    AntiAFK         = true,
    AntiAFKInterval = 60,
    TPMinDelay      = 0,
    TPRandExtra     = 0,
    AutoRejoin      = true,
    HitDelay        = 0,

    -- Toggle flags (ควบคุมผ่าน UI เท่านั้น)
    AutoFarm        = false,
    SpawnBoss       = false,
    HakiEnabled     = true,
    BusoOn          = false,
}

-- ══════════════════════════════════════════════════════
-- FPS BOOST
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
-- AUTO REJOIN
-- ══════════════════════════════════════════════════════
local SCRIPT_URL  = "https://raw.githubusercontent.com/IMPACTlazy/NEW-FARM/refs/heads/main/sailor_lawless.lua"
local HttpService = game:GetService("HttpService")
local VIP_SAVE    = "SailorHub/VIPServer.json"

if queue_on_teleport then
    queue_on_teleport(string.format([[loadstring(game:HttpGet("%s"))()]], SCRIPT_URL))
end

pcall(function()
    if not isfolder("SailorHub") then makefolder("SailorHub") end
    if privateServerId ~= "" then
        writefile(VIP_SAVE, HttpService:JSONEncode({
            placeId         = placeId,
            jobId           = jobId,
            privateServerId = privateServerId,
        }))
    end
end)

local isRejoining    = false
local rejoinCooldown = 0
local isTeleporting  = false

local function DoRejoin()
    if isRejoining then return end
    if not CFG.AutoRejoin then return end
    if tick() - rejoinCooldown < 15 then return end
    isRejoining    = false
    rejoinCooldown = 0
    task.spawn(DoRejoin)

    local waitCount = 0
    while isTeleporting and waitCount < 30 do
        task.wait(1)
        waitCount += 1
    end
    isTeleporting = false

    local ok, data = pcall(function()
        if isfile and isfile(VIP_SAVE) then
            return HttpService:JSONDecode(readfile(VIP_SAVE))
        end
    end)

    local savedJobId = (ok and data and data.jobId)   or jobId
    local savedPlace = (ok and data and data.placeId) or placeId

    for attempt = 1, 5 do
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(savedPlace, savedJobId, LP)
        end)
        if success then
            isTeleporting = true
            return
        end
        local errStr = tostring(err):lower()
        if errStr:find("teleporting") or errStr:find("previous") or errStr:find("pending") then
            isTeleporting = false
            task.wait(20)
        else
            task.wait(10)
        end
    end

    isRejoining    = false
    rejoinCooldown = 0
    isTeleporting  = false
end

task.spawn(function()
    while true do
        task.wait(0.1)
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
                        if txt:find("267") or txt:find("disconnect") or txt:find("kicked")
                            or txt:find("เชื่อมต่อ") or txt:find("ยกเลิก")
                        then
                            pcall(function() sg.MouseButton1Click:Fire() end)
                            task.wait(2)
                            isRejoining    = true
                            rejoinCooldown = 0
                            task.spawn(DoRejoin)
                            return
                        end
                    end
                end
            end
        end)
    end
end)

GuiService.ErrorMessageChanged:Connect(function(msg)
    if not CFG.AutoRejoin or msg == "" then return end
    local lo = msg:lower()
    if lo:find("teleport") or lo:find("connecting") then return end
    task.wait(2)
    isRejoining    = false
    rejoinCooldown = 0
    task.spawn(DoRejoin)
end)

LP.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        isTeleporting  = false
        task.wait(15)
        isRejoining    = false
        rejoinCooldown = 0
        task.spawn(DoRejoin)
    elseif state == Enum.TeleportState.InProgress
        or state == Enum.TeleportState.RequestedFromServer
    then
        isTeleporting = true
    end
end)

-- ══════════════════════════════════════════════════════
-- REMOTES
-- ══════════════════════════════════════════════════════
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local CheckPortalUnlock = Remotes:WaitForChild("CheckPortalUnlock")
local PortalRmt         = Remotes:WaitForChild("TeleportToPortal")
local CombatRmt         = ReplicatedStorage
    :WaitForChild("CombatSystem")
    :WaitForChild("Remotes")
    :WaitForChild("RequestHit")

local AbilityRmt = nil
pcall(function()
    AbilityRmt = ReplicatedStorage.AbilitySystem.Remotes.RequestAbility
end)

local SummonBossRmt = nil
pcall(function()
    SummonBossRmt = ReplicatedStorage.Remotes:WaitForChild("RequestSummonBoss", 5)
end)

-- ══════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════
local BossKW = { "Boss", "Elite", "Guard", "Captain", "Lord", "King" }
local function IsBoss(name)
    local lo = name:lower()
    for _, kw in ipairs(BossKW) do
        if lo:find(kw:lower(), 1, true) then return true end
    end
    return false
end

local function FindNearestMob()
    if not HRP then return nil end
    local best, bestDist = nil, math.huge
    local npcs       = workspace:FindFirstChild("NPCs") or workspace
    local mobLow     = CFG.MobName:lower()
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

local function GetMobCentroid()
    if not HRP then return nil end
    local npcs       = workspace:FindFirstChild("NPCs") or workspace
    local mobLow     = CFG.MobName:lower()
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
    local dest = CFrame.new(targetPos + Vector3.new(0, CFG.FloatY, 0)) * CFrame.Angles(math.rad(90), math.rad(90), 0)
    HRP.AssemblyLinearVelocity  = Vector3.zero
    HRP.AssemblyAngularVelocity = Vector3.zero
    HRP.CFrame = dest
    frozenCF    = dest
    freezeUntil = tick() + 0
    lastCFrame  = dest
    DisableCollision()
end

-- ══════════════════════════════════════════════════════
-- FLOAT LOCK
-- ══════════════════════════════════════════════════════
RunService.Stepped:Connect(function()
    if not CFG.AutoFarm then return end
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
        bv          = Instance.new("BodyVelocity")
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
    if HRP and CFG.AutoFarm then
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
    print(("[RemoveMap] ลบ %d objects"):format(removed))
end

-- ══════════════════════════════════════════════════════
-- ISLAND CHECK + TELEPORT
-- ══════════════════════════════════════════════════════
local tping          = false
local lastTP         = -999
local TP_GRACE       = 0
local TP_COOLDOWN    = 0
local tpingStartTime = 0
local lastMobFound   = tick()

local function OnIsland()
    local isBossMode = PORTALS[portalIndex].IsBossEntry
    local grace = isBossMode and BOSS_SKIP_TIMEOUT or TP_GRACE
    if tick() - lastTP < grace then return true end
    if not HRP then return false end
    local npcs   = workspace:FindFirstChild("NPCs") or workspace
    local mobLow = CFG.MobName:lower()
    for _, m in ipairs(npcs:GetDescendants()) do
        if m:IsA("Model") and m.Name:lower():find(mobLow, 1, true) then
            local root = m:FindFirstChild("HumanoidRootPart")
            local hum  = m:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0
                and (HRP.Position - root.Position).Magnitude < 600
            then
                return true
            end
        end
    end
    return false
end

local function DoTeleport()
    if tping then return end
    tping          = true
    tpingStartTime = tick()
    lastTP         = tick()
    print(("[Farm] TP → %s (%s)"):format(CFG.Portal, CFG.MobName))
    pcall(function() PortalRmt:FireServer(CFG.Portal) end)
    task.wait(0)
    RefreshChar()
    tping = false
end

task.spawn(function()
    while true do
        task.wait(0)
        if tping and tick() - tpingStartTime > 20 then
            tping  = false
            lastTP = -999
        end
    end
end)

-- ══════════════════════════════════════════════════════
-- AUTO SPAWN BOSS
-- ══════════════════════════════════════════════════════
local function TrySpawnBoss(bossName, difficulty)
    if not SummonBossRmt then return end
    pcall(function() SummonBossRmt:FireServer(bossName, difficulty) end)
    print(("[Boss] Summon %s [%s]"):format(bossName, difficulty))
end

-- ══════════════════════════════════════════════════════
-- PORTAL SWITCH
-- ══════════════════════════════════════════════════════
local curTarget = nil

local function SwitchPortal(idx)
    idx           = ((idx - 1) % #PORTALS) + 1
    local p       = PORTALS[idx]
    portalIndex   = idx
    CFG.Portal    = p.Portal
    CFG.MobName   = p.MobName
    zoneStartTime = tick()
    mapRemoved    = false
    curTarget     = nil
    lastTP        = -999
    tping         = false
    print(("[Portal] → [%d/%d] %s | %s%s")
        :format(idx, #PORTALS, p.Portal, p.MobName,
            p.IsBossEntry and " 👹" or ""))
    task.spawn(DoTeleport)
    if p.IsBossEntry then
        task.delay(2, function()
            TrySpawnBoss(p.MobName, p.Difficulty or "Normal")
        end)
    end
end

local function PressKey(keyCode)
    pcall(function() VIM:SendKeyEvent(true,  keyCode, false, game) end)
    task.delay(0.1, function()
        pcall(function() VIM:SendKeyEvent(false, keyCode, false, game) end)
    end)
end

local function ActivateHaki()
    if not CFG.HakiEnabled then return end
    task.wait(2)
    if not CFG.BusoOn then return end
    if Hum then pcall(function() Hum.PlatformStand = false end) end
    task.wait(0.2)
    PressKey(Enum.KeyCode.G)
    print("[Haki] Armament ON ✅")
end

LP.CharacterAdded:Connect(function()
    task.wait(2.5)
    RefreshChar()
    DisableCollision()
    task.spawn(ActivateHaki)
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
                if cam then cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(0.1), 0) end
            end)
        end
    end
end)

LP.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- ══════════════════════════════════════════════════════
-- HOTKEYS
-- ══════════════════════════════════════════════════════
UserInputSvc.InputBegan:Connect(function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.LeftBracket then
        SwitchPortal(portalIndex - 1)
    elseif i.KeyCode == Enum.KeyCode.RightBracket then
        SwitchPortal(portalIndex + 1)
    end
end)

-- ══════════════════════════════════════════════════════
-- MAIN LOOPS (ทำงานเฉพาะเมื่อ Toggle เปิดผ่าน UI)
-- ══════════════════════════════════════════════════════
local lastSkillX  = 0
local lastHitTime = 0

-- Auto Farm Loop
task.spawn(function()
    while true do
        task.wait()
        if not CFG.AutoFarm then continue end

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

        if not mapRemoved then task.spawn(RemoveMap) end

        pcall(function() Hum.PlatformStand = true end)
        GetCurrentTool()

        local alive = curTarget
            and curTarget.Parent
            and (curTarget:FindFirstChildOfClass("Humanoid") or { Health = 0 }).Health > 0
        if not alive then curTarget = FindNearestMob() end

        if not curTarget then
            if tick() - lastMobFound > 20 and not tping then
                lastTP = -999
                task.spawn(DoTeleport)
            end
            continue
        end

        lastMobFound = tick()

        local tRoot = curTarget:FindFirstChild("HumanoidRootPart")
        if not tRoot then curTarget = nil; continue end

        Hum.AutoRotate = false
        TPToTarget(tRoot)

        local npcs       = workspace:FindFirstChild("NPCs") or workspace
        local mobLow     = CFG.MobName:lower()
        local isBossMode = PORTALS[portalIndex].IsBossEntry
        local nowHit     = tick()

        if nowHit - lastHitTime >= CFG.HitDelay then
            lastHitTime = nowHit
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
        end

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

-- Haki Loop
local hakiActive = false

LP.CharacterAdded:Connect(function()
    hakiActive = false -- ตายแล้ว reset
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if not CFG.HakiEnabled then
            hakiActive = false
            continue
        end
        if hakiActive then continue end -- เปิดอยู่แล้ว ไม่ต้องกดซ้ำ
        ActivateHaki()
        hakiActive = true
    end
end)

-- ══════════════════════════════════════════════════════
-- Auto Rotate / Portal Switch Loop  ← แก้ไขตรงนี้
-- ══════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(1)
        if not CFG.AutoFarm or not CFG.AutoRotate then continue end

        local p = PORTALS[portalIndex]

        if p.IsBossEntry then
            local bossAlive = false
            local npcs      = workspace:FindFirstChild("NPCs") or workspace
            local mobLow    = p.MobName:lower()
            for _, m in ipairs(npcs:GetDescendants()) do
                if m:IsA("Model") and m.Name:lower():find(mobLow, 1, true) then
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then bossAlive = true; break end
                end
            end
            -- ถ้าเปิด SpawnBoss และบอสตายแล้ว ให้ summon ใหม่
            if CFG.SpawnBoss and not bossAlive then
                TrySpawnBoss(p.MobName, p.Difficulty or "Normal")
            end
            -- switch เมืองเมื่อบอสตายแล้ว
            if not bossAlive and tick() - zoneStartTime >= BOSS_SKIP_TIMEOUT then
                SwitchPortal(portalIndex + 1)
            end
        else
            local farmTime = p.FarmTime > 0 and p.FarmTime or DEFAULT_FARM_TIME
            if farmTime == 0 or tick() - zoneStartTime >= farmTime then
                SwitchPortal(portalIndex + 1)
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════
-- UI (Fluent)
-- ══════════════════════════════════════════════════════
local Fluent           = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager      = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title       = "[🌙Moon Update⚔️] Sailor's Piece by impact",
    SubTitle    = "by impact",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(580, 460),
    Acrylic     = true,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main     = Window:AddTab({ Title = "Main",     Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local PortalConfig = require(ReplicatedStorage:WaitForChild("PortalConfig")).Portals
local Portals = {}
for Name, _ in PortalConfig do
    table.insert(Portals, Name)
end

-- ── Main Tab ──
Tabs.Main:AddSection("Farm")

Tabs.Main:AddToggle("Auto Farm only mob", {
    Title   = "All mob bypass TP",
    Default = false,
    Callback = function(val)
        CFG.AutoFarm = val
        print("[Farm] Auto Farm: " .. tostring(val))
        if val then
            task.spawn(DoTeleport)
        end
    end
})

Tabs.Main:AddToggle("Spawn Boss", {
    Title   = "Auto Spawn Boss",
    Default = false,
    Callback = function(val)
        CFG.SpawnBoss = val
        print("[Boss] Auto Spawn: " .. tostring(val))
        if val and PORTALS[portalIndex].IsBossEntry then
            TrySpawnBoss(PORTALS[portalIndex].MobName, PORTALS[portalIndex].Difficulty or "Normal")
        end
    end
})

Tabs.Main:AddToggle("BusoOn", {
    Title   = "Auto Enable Haki (Buso)",
    Default = true,
    Callback = function(val)
        CFG.BusoOn = val
        CFG.HakiEnabled = val
        print("[Haki] Buso Haki: " .. tostring(val))
        if val then
            task.spawn(ActivateHaki)
        end
    end
})

Tabs.Main:AddSection("Portal")

Tabs.Main:AddDropdown("Select Portal", {
    Title   = "Select Portal",
    Values  = Portals,
    Multi   = false,
    Default = 1,
})

Tabs.Main:AddButton({
    Title       = "Teleport",
    Description = "Teleport to selected gate",
    Callback    = function()
        local Options = Fluent.Options
        local Select  = Options["Select Portal"].Value
        if CheckPortalUnlock:InvokeServer(Select) then
            PortalRmt:FireServer(Select)
        end
    end
})

-- ── Settings Tab ──
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title    = "[🌙Moon Update⚔️] Sailor's Piece by impact",
    Content  = "Script loaded — เปิด Toggle ใน UI เพื่อเริ่มทำงาน",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()

-- ══════════════════════════════════════════════════════
-- LOG
-- ══════════════════════════════════════════════════════
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("[Farm] Loaded ✅  (เปิด UI เพื่อเริ่ม)")
print("[Farm] [ = Prev Portal | ] = Next Portal")
for i, v in ipairs(PORTALS) do
    local ft = v.IsBossEntry
        and ("boss/" .. BOSS_SKIP_TIMEOUT .. "s")
        or (v.FarmTime > 0 and v.FarmTime .. "s" or DEFAULT_FARM_TIME .. "s")
    print(("  [%02d] %-14s | %-18s | %s"):format(i, v.Portal, v.MobName, ft))
end
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
