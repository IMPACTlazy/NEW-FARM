repeat task.wait(.1) until game:IsLoaded()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputSvc      = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Char, HRP, Hum

local function RefreshChar()
    Char = LP.Character
    if not Char then return end
    HRP = Char:FindFirstChild("HumanoidRootPart")
    Hum = Char:FindFirstChildOfClass("Humanoid")
end
RefreshChar()
LP.CharacterAdded:Connect(function() task.wait(1); RefreshChar() end)

-- ══════════════════════════════════════════════════════
-- PORTALS
-- ══════════════════════════════════════════════════════
local PORTALS = {
    { Portal = "Starter",      MobName = "Thief",                FarmTime = 1.5, IsBossEntry = true},
    { Portal = "Jungle",       MobName = "Monkey",               FarmTime = 1.5, IsBossEntry = true},
    { Portal = "Desert",       MobName = "Desert",               FarmTime = 1.5, IsBossEntry = true},
    { Portal = "Snow",         MobName = "FrostRogue",           FarmTime = 2,   IsBossEntry = true},
    { Portal = "Shibuya",      MobName = "Sorcerer",             FarmTime = 2,   IsBossEntry = true},
    { Portal = "Hollow",       MobName = "Hollow",               FarmTime = 2,   },
    { Portal = "Shinjuku",     MobName = "Curse",                FarmTime = 2,   },
    { Portal = "Shinjuku",     MobName = "Strong",               FarmTime = 2,   },
    { Portal = "Slime",        MobName = "Slime",                FarmTime = 1,   },
    { Portal = "Academy",      MobName = "AcademyTeacher",       FarmTime = 2 },
    { Portal = "Judgement",    MobName = "Swordsman",            FarmTime = 2   },
    { Portal = "SoulDominion", MobName = "Quincy",               FarmTime = 3.5 },
    { Portal = "Ninja",        MobName = "Ninja",                FarmTime = 2   },
    { Portal = "Lawless",      MobName = "ArenaFighter",         FarmTime = 2   },
    { Portal = "Hollow",       MobName = "AizenBoss",            FarmTime = 1, IsBossEntry = true },
    { Portal = "Sailor",       MobName = "JinwooBoss",           FarmTime = 1, IsBossEntry = true },
    { Portal = "Sailor",       MobName = "AlucardBoss",          FarmTime = 1, IsBossEntry = true },
    { Portal = "Shibuya",      MobName = "YujiBoss",             FarmTime = 1, IsBossEntry = true },
    { Portal = "Shibuya",      MobName = "SukunaBoss",           FarmTime = 1, IsBossEntry = true },
    { Portal = "Shibuya",      MobName = "GojoBoss",             FarmTime = 1, IsBossEntry = true },
    { Portal = "Ninja",        MobName = "StrongestShinobiBoss", FarmTime = 1, IsBossEntry = true },
}

-- ── Blacklist: NPC/Object ที่ไม่ใช่ mob จริง ห้ามตี ──
local BLACKLIST = {
    "true manipulator",
    "summoner",
    "merchant",
    "shopkeeper",
    "trainer",
    "questgiver",
    "open",
}
local function IsBlacklisted(name)
    local lo = name:lower()
    -- กรองทุกตัวที่ลงท้ายด้วย "npc" เช่น QuestNPC, MerchantNPC ฯลฯ
    if lo:sub(-3) == "npc" then return true end
    for _, kw in ipairs(BLACKLIST) do
        if lo:find(kw, 1, true) then return true end
    end
    return false
end

local CFG = {
    Enabled         = false,
    FloatY          = 8,
    SkillX          = true,
    SkillCoolX      = 0.5,
    Portal          = PORTALS[1].Portal,
    MobName         = PORTALS[1].MobName,
    AntiAFK         = true,
    AntiAFKInterval = 60,
    BusoOn          = false,
    ObsOn           = false,
    AutoRespawn     = true,
    RespawnInterval = 300,
}

-- ══════════════════════════════════════════════════════
-- STARTUP FPS BOOST
-- ══════════════════════════════════════════════════════
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
pcall(function()
    Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("BloomEffect")
        or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect")
        or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
            pcall(function() v:Destroy() end)
        end
    end
end)

-- ══════════════════════════════════════════════════════
-- BYPASS GAMEPLAY PAUSED
-- ══════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            for _, sg in ipairs(CoreGui:GetChildren()) do
                if sg:IsA("ScreenGui") then
                    local lo = sg.Name:lower()
                    if lo:find("pause") or lo:find("paused") or lo:find("gameplay") then
                        sg.Enabled = false
                    end
                end
            end
            local cam = workspace.CurrentCamera
            if cam and cam.CameraType ~= Enum.CameraType.Custom then
                cam.CameraType = Enum.CameraType.Custom
            end
        end)
    end
end)

-- ══════════════════════════════════════════════════════
-- FPS BOOST
-- ══════════════════════════════════════════════════════
local function BoostFPS()
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function()
        Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9
        for _, v in ipairs(Lighting:GetChildren()) do pcall(function() v:Destroy() end) end
    end)
    local removed = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        local parent = obj.Parent; if not parent then continue end
        if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then continue end
        if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SpecialMesh")
        or obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            pcall(function() obj:Destroy() end); removed += 1
        elseif obj:IsA("Sound") then
            pcall(function()
                if not obj.Parent:FindFirstChildOfClass("Humanoid") then obj.Volume = 0 end
            end)
        elseif obj:IsA("BasePart") then
            pcall(function()
                obj.CastShadow = false
                if obj.Material ~= Enum.Material.SmoothPlastic then obj.Material = Enum.Material.SmoothPlastic end
            end)
        end
    end
    print(("[FPS Boost] ลบไป %d object"):format(removed))
end

-- ══════════════════════════════════════════════════════
-- REMOTES
-- ══════════════════════════════════════════════════════
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local PortalRmt  = Remotes:WaitForChild("TeleportToPortal")
local CombatRmt  = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")
local AbilityRmt = nil
pcall(function() AbilityRmt = ReplicatedStorage.AbilitySystem.Remotes.RequestAbility end)

-- ══════════════════════════════════════════════════════
-- FLUENT UI
-- ══════════════════════════════════════════════════════
local Fluent           = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager      = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Win = Fluent:CreateWindow({
    Title="[🗡️Massive Update🔥] Sailor Piece BY IMPACT]", SubTitle="By IMPACT",
    TabWidth=160, Size=UDim2.fromOffset(580,460), Acrylic=true, Theme="Dark",
    MinimizeKey=Enum.KeyCode.LeftControl,
})
local Tabs = {
    Main     = Win:AddTab({ Title="AutoFarm", Icon="sword"    }),
    Haki     = Win:AddTab({ Title="Haki",     Icon="flame"    }),
    Misc     = Win:AddTab({ Title="Misc",     Icon="gauge"    }),
    Settings = Win:AddTab({ Title="Settings", Icon="settings" }),
}
local Options = Fluent.Options

local portalIndex=1; local zoneStartTime=tick()
local tping=false; local lastTP=-999; local TP_GRACE=12; local TP_COOLDOWN=20
local frozenCF=nil; local freezeUntil=0
local farmFloat=nil; local scriptReady=false

local BossKW={"Boss","Elite","Guard","Captain","Lord","King"}
local function NameLooksBoss(name)
    local lo=name:lower()
    for _,kw in ipairs(BossKW) do if lo:find(kw:lower(),1,true) then return true end end
    return false
end
local function CurrentEntryIsBoss()
    local e=PORTALS[portalIndex]; return e and e.IsBossEntry==true
end

local function DoTeleport()
    if tping then return end
    if not scriptReady then return end
    tping=true; lastTP=tick()
    if CurrentEntryIsBoss() then
        RefreshChar()
        if HRP then
            local BOSS_MAP={Sailor="SailorIsland",Shibuya="ShibuyaIsland",Hollow="HollowIsland",Ninja="NinjaIsland"}
            local folderName=BOSS_MAP[CFG.Portal] or (CFG.Portal.."Island")
            local folder=workspace:FindFirstChild(folderName)
            if not folder then
                for _,v in ipairs(workspace:GetChildren()) do
                    if v.Name:lower():find(CFG.Portal:lower(),1,true) then folder=v; break end
                end
            end
            if folder then
                local sp=nil
                for _,v in ipairs(folder:GetDescendants()) do
                    if v.Name:lower():find("spawn") and v:IsA("BasePart") then sp=v; break end
                end
                if not sp then
                    for _,v in ipairs(folder:GetDescendants()) do
                        if v:IsA("SpawnLocation") then sp=v; break end
                    end
                end
                if sp then HRP.CFrame=CFrame.new(sp.Position+Vector3.new(0,5,0)); tping=false; return end
            end
            local mobLow=CFG.MobName:lower()
            for _,m in ipairs(workspace:GetDescendants()) do
                if m:IsA("Model") and m~=Char then
                    local h=m:FindFirstChildOfClass("Humanoid"); local r=m:FindFirstChild("HumanoidRootPart")
                    if h and h.Health>0 and r and m.Name:lower():find(mobLow,1,true) then
                        HRP.CFrame=CFrame.new(r.Position+Vector3.new(0,5,3)); tping=false; return
                    end
                end
            end
        end
        pcall(function() PortalRmt:FireServer(CFG.Portal) end)
        task.wait(3); RefreshChar(); tping=false; return
    end
    pcall(function() PortalRmt:FireServer(CFG.Portal) end)
    task.wait(3); RefreshChar(); tping=false
end

-- ── Main Tab ──────────────────────────────────────────────
Tabs.Main:AddParagraph({ Title="AutoFarm", Content="Hotkey: F  |  กด Toggle เพื่อเริ่ม/หยุด" })

Tabs.Main:AddToggle("FarmEnabled", { Title="Enable AutoFarm", Default=false })
Options.FarmEnabled:OnChanged(function()
    CFG.Enabled=Options.FarmEnabled.Value
    if CFG.Enabled then
        Fluent:Notify({ Title="AutoFarm", Content="RUNNING ✅", Duration=3 })
        if Hum then Hum.AutoRotate=false end
        zoneStartTime=tick(); lastTP=-999
        task.spawn(DoTeleport)
    else
        Fluent:Notify({ Title="AutoFarm", Content="STOPPED ❌", Duration=3 })
        frozenCF=nil; freezeUntil=0; RefreshChar()
        if HRP then
            local bv=HRP:FindFirstChild("FarmFloat"); if bv then bv:Destroy() end
            farmFloat=nil
            HRP.AssemblyLinearVelocity=Vector3.zero
            HRP.AssemblyAngularVelocity=Vector3.zero
        end
        if Hum then Hum.AutoRotate=true; Hum.PlatformStand=false end
    end
end)

UserInputSvc.InputBegan:Connect(function(i,p)
    if p then return end
    if i.KeyCode==Enum.KeyCode.F then Options.FarmEnabled:SetValue(not Options.FarmEnabled.Value) end
end)

local portalNames={}
for _,v in ipairs(PORTALS) do table.insert(portalNames, v.Portal.." - "..v.MobName) end
Tabs.Main:AddDropdown("PortalSelect", { Title="Select Portal / Mob", Values=portalNames, Multi=false, Default=1 })
Options.PortalSelect:OnChanged(function(val)
    for i,v in ipairs(PORTALS) do
        if (v.Portal.." - "..v.MobName)==val then
            CFG.Portal=v.Portal; CFG.MobName=v.MobName; portalIndex=i; zoneStartTime=tick()
            Fluent:Notify({ Title="Portal", Content="→ "..v.Portal.." ("..v.MobName..")", Duration=3 })
            break
        end
    end
end)

Tabs.Main:AddToggle("SkillX", { Title="Auto Skill X", Default=true })
Options.SkillX:OnChanged(function() CFG.SkillX=Options.SkillX.Value end)
Tabs.Main:AddSlider("SkillCool", { Title="Skill Cooldown (s)", Default=0.5, Min=0.1, Max=3, Rounding=1, Callback=function(v) CFG.SkillCoolX=v end })
Tabs.Main:AddSlider("FloatY", { Title="Float Height", Default=8, Min=0, Max=30, Rounding=0, Callback=function(v) CFG.FloatY=v end })
Tabs.Main:AddToggle("AutoRespawn", { Title="Auto Respawn", Description="รี spawn ทุก N วิ", Default=true })
Options.AutoRespawn:OnChanged(function() CFG.AutoRespawn=Options.AutoRespawn.Value end)
Tabs.Main:AddSlider("RespawnInterval", { Title="Respawn ทุกกี่วิ", Default=300, Min=60, Max=600, Rounding=0, Callback=function(v) CFG.RespawnInterval=v end })
local StatusPara=Tabs.Main:AddParagraph({ Title="Live Status", Content="Status: OFF" })

-- ── Haki Tab ──────────────────────────────────────────────
Tabs.Haki:AddParagraph({ Title="Auto Haki", Content="กดครั้งเดียวตอนเปิด\nพอตายจะกดเปิดใหม่อัตโนมัติ" })
Tabs.Haki:AddToggle("BusoOn", { Title="Armament Haki (Buso)", Description="กด G ครั้งเดียว", Default=false })
Tabs.Haki:AddToggle("ObsOn",  { Title="Observation Haki (Obs)", Description="กด H ครั้งเดียว", Default=false })

-- ── Misc Tab ──────────────────────────────────────────────
Tabs.Misc:AddParagraph({ Title="Remove Map", Content="ลบ part/effect ทั้งหมด\nNPC Boss ตัวละคร จะไม่ถูกลบ" })

Tabs.Misc:AddButton({
    Title="🗑️ REMOVE MAP", Description="ลบ Island/Part ออก เหลือแค่ฟ้า + mob + ตัวละคร",
    Callback=function()
        local removed=0
        pcall(function()
            Lighting.GlobalShadows=false; Lighting.FogEnd=9e9
            for _,v in ipairs(Lighting:GetChildren()) do pcall(function() v:Destroy() end) end
        end)

        -- เก็บชื่อ character ทุกคน
        local keepChar={}
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Character then keepChar[p.Character.Name]=true end
        end

        for _,obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Terrain") then continue end
            if obj:IsA("Camera") then continue end
            if keepChar[obj.Name] then continue end
            if obj:IsA("Model") then
                -- ข้าม Model ทุกอันที่มี Humanoid (mob/npc/boss/player)
                local hasHum=obj:FindFirstChildOfClass("Humanoid")~=nil
                if not hasHum then
                    for _,v in ipairs(obj:GetDescendants()) do
                        if v:IsA("Humanoid") then hasHum=true; break end
                    end
                end
                if hasHum then continue end
            end
            -- ข้าม Folder ที่น่าจะเก็บ mob/npc
            if obj:IsA("Folder") then
                local lo=obj.Name:lower()
                if lo:find("npc") or lo:find("mob") or lo:find("boss")
                or lo:find("spawn") or lo:find("enemy") then continue end
            end
            pcall(function() obj:Destroy() end)
            removed+=1
        end

        pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
        pcall(function()
            for _,v in ipairs(game:GetService("SoundService"):GetDescendants()) do
                if v:IsA("Sound") then v.Volume=0 end
            end
        end)
        Fluent:Notify({ Title="Remove Map ✅", Content="ลบไป "..removed.." objects 🚀", Duration=4 })
        print("[Remove Map] ลบไป "..removed.." objects")
    end,
})

Tabs.Misc:AddButton({
    Title="🚀 FPS Boost", Description="ลบ Decal/Particle/Shadow เท่านั้น",
    Callback=function() BoostFPS(); Fluent:Notify({ Title="FPS Boost", Content="เสร็จแล้ว!", Duration=3 }) end,
})
Tabs.Misc:AddToggle("AntiAFK", { Title="Anti-AFK", Default=true })
Options.AntiAFK:OnChanged(function() CFG.AntiAFK=Options.AntiAFK.Value end)

-- ── Settings Tab ──────────────────────────────────────────
SaveManager:SetLibrary(Fluent); InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("SailorPieceHub"); SaveManager:SetFolder("SailorPieceHub/autofarm")
InterfaceManager:BuildInterfaceSection(Tabs.Settings); SaveManager:BuildConfigSection(Tabs.Settings)
Win:SelectTab(1)
SaveManager:LoadAutoloadConfig()

task.defer(function()
    Options.FarmEnabled:SetValue(false); CFG.Enabled=false
    CFG.SkillX      = Options.SkillX      and Options.SkillX.Value      or true
    CFG.AutoRespawn = Options.AutoRespawn  and Options.AutoRespawn.Value  or true
    CFG.AntiAFK     = Options.AntiAFK      and Options.AntiAFK.Value      or true
    CFG.BusoOn      = Options.BusoOn       and Options.BusoOn.Value       or false
    CFG.ObsOn       = Options.ObsOn        and Options.ObsOn.Value        or false
    if Options.PortalSelect and Options.PortalSelect.Value then
        local val=Options.PortalSelect.Value
        for i,v in ipairs(PORTALS) do
            if (v.Portal.." - "..v.MobName)==val then
                CFG.Portal=v.Portal; CFG.MobName=v.MobName; portalIndex=i; break
            end
        end
    end
    scriptReady=true
    print("[Config] โหลดเสร็จ — กด Toggle เพื่อเริ่ม")
end)

Fluent:Notify({ Title="Loaded ✅", Content="กด F = Toggle Farm\nLeftCtrl = ซ่อน UI", Duration=5 })

-- ══════════════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════════════
local function FindMobCenter()
    if not HRP then return nil end
    local mobLow = CFG.MobName:lower()
    local wantBoss = CurrentEntryIsBoss()
    local positions = {}
    local nearestMob = nil
    local nearestDist = math.huge

    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m ~= Char then
            local hum  = m:FindFirstChildOfClass("Humanoid")
            local root = m:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                local nm = m.Name:lower():find(mobLow, 1, true)
                local pf = wantBoss or not NameLooksBoss(m.Name)
                local notBL = not IsBlacklisted(m.Name)
                if nm and pf and notBL then
                    table.insert(positions, root.Position)
                    local d = (HRP.Position - root.Position).Magnitude
                    if d < nearestDist then
                        nearestDist = d
                        nearestMob = m
                    end
                end
            end
        end
    end

    if #positions == 0 then return nil, nil end

    -- คำนวณจุดกึ่งกลางของ mob ทั้งหมด
    local sum = Vector3.zero
    for _, pos in ipairs(positions) do sum = sum + pos end
    local center = sum / #positions

    return center, nearestMob
end

local function GetCurrentTool()
    if not Char then return nil end
    for _,v in ipairs(Char:GetChildren()) do if v:IsA("Tool") then return v end end
    local bp=LP:FindFirstChild("Backpack")
    if bp then
        for _,v in ipairs(bp:GetChildren()) do
            if v:IsA("Tool") then
                task.spawn(function() if Hum then pcall(function() Hum:EquipTool(v) end) end end)
                return nil
            end
        end
    end
    return nil
end

-- ══════════════════════════════════════════════════════
-- TPToTarget
-- ══════════════════════════════════════════════════════
local lastTPPos=Vector3.zero; local lastTPTime=0; local stuckCount=0

local function TPToTarget(root)
    if not HRP or not root then return end
    local now=tick()
    local moved=(HRP.Position-lastTPPos).Magnitude
    if moved<0.5 and now-lastTPTime>1.5 then stuckCount+=1 else stuckCount=0 end
    lastTPPos=HRP.Position; lastTPTime=now

    local offsetY=2; local offsetX=0; local offsetZ=3
    if stuckCount>=3 then
        offsetY=math.random(1,4); offsetX=math.random(-3,3); offsetZ=math.random(3,6)
        stuckCount=0
    end

    local dest=CFrame.new(root.Position+Vector3.new(offsetX,offsetY,offsetZ))*CFrame.new(0,0,3)
    HRP.AssemblyLinearVelocity=Vector3.zero; HRP.AssemblyAngularVelocity=Vector3.zero
    HRP.CFrame=dest; frozenCF=dest; freezeUntil=tick()+0.35

    task.delay(0.15, function()
        if not HRP or not root then return end
        pcall(function() CombatRmt:FireServer(root.Position) end)
    end)
end

RunService.Heartbeat:Connect(function()
    if frozenCF and tick()<freezeUntil then
        if HRP then
            HRP.AssemblyLinearVelocity=Vector3.zero
            HRP.AssemblyAngularVelocity=Vector3.zero
            HRP.CFrame=frozenCF
        end
    else frozenCF=nil end
end)

local function OnIslandReal()
    if not HRP then return false end
    local mobLow=CFG.MobName:lower()
    for _,m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m~=Char then
            local hum=m:FindFirstChildOfClass("Humanoid"); local root=m:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health>0 and root
            and m.Name:lower():find(mobLow,1,true)
            and (HRP.Position-root.Position).Magnitude<800 then
                return true
            end
        end
    end
    return false
end
local function OnIsland()
    if tick()-lastTP<TP_GRACE then return true end
    return OnIslandReal()
end
local function SwitchToNextPortal()
    portalIndex=(portalIndex%#PORTALS)+1
    local p=PORTALS[portalIndex]
    CFG.Portal=p.Portal; CFG.MobName=p.MobName; zoneStartTime=tick(); return p
end

task.spawn(function()
    while true do
        task.wait(1)
        if not CFG.Enabled then continue end
        local p=PORTALS[portalIndex]; local elapsed=tick()-zoneStartTime
        pcall(function()
            StatusPara:SetTitle("Live Status")
            StatusPara:SetContent("Zone: "..CFG.Portal.."  |  Target: "..CFG.MobName..
                "  |  Time: "..math.floor(elapsed).."s / "..p.FarmTime.."s")
        end)
        if elapsed>=p.FarmTime then
            local nxt=SwitchToNextPortal(); lastTP=-999; tping=false; task.spawn(DoTeleport)
        end
    end
end)

-- ══════════════════════════════════════════════════════
-- MAIN FARM LOOP
-- ══════════════════════════════════════════════════════
local curTarget=nil; local lastSkillX=0
local function EnsureFarmFloat()
    if not HRP then return end
    if farmFloat and farmFloat.Parent==HRP then return end
    farmFloat=HRP:FindFirstChild("FarmFloat")
    if not farmFloat then
        farmFloat=Instance.new("BodyVelocity")
        farmFloat.Name="FarmFloat"; farmFloat.MaxForce=Vector3.new(9e9,9e9,9e9)
        farmFloat.Velocity=Vector3.zero; farmFloat.Parent=HRP
    end
end

LP.CharacterAdded:Connect(function()
    task.wait(1.5); RefreshChar()
    if Char then
        for _,v in ipairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then pcall(function() v.CanCollide=false end) end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.3+math.random()*0.2)
        if not CFG.Enabled then continue end
        RefreshChar()
        if not HRP or not Hum or Hum.Health<=0 then continue end
        if HRP.Position.Y<-50 then HRP.CFrame=frozenCF or CFrame.new(0,100,0) end
        EnsureFarmFloat()
        pcall(function() Hum.PlatformStand=true end)
        if not OnIsland() then
            if not tping and tick()-lastTP>TP_COOLDOWN then task.spawn(DoTeleport) end
            continue
        end
        local alive = curTarget and curTarget.Parent
            and (curTarget:FindFirstChildOfClass("Humanoid") or {Health=0}).Health>0
        if not alive then
            local center, mob = FindMobCenter()
            curTarget = mob
            -- วาปไปตรงกลาง mob ทั้งหมด
            if center and HRP then
                local dest = CFrame.new(center + Vector3.new(0, CFG.FloatY, 0))
                HRP.AssemblyLinearVelocity  = Vector3.zero
                HRP.AssemblyAngularVelocity = Vector3.zero
                HRP.CFrame  = dest
                frozenCF    = dest
                freezeUntil = tick() + 0.35
            end
        end
        if not curTarget then continue end
        local tRoot = curTarget:FindFirstChild("HumanoidRootPart")
        if not tRoot then curTarget=nil; continue end
        Hum.AutoRotate=false

        -- TP ไปตรงกลาง mob group ทุก tick
        local center2, _ = FindMobCenter()
        if center2 then
            local dest2 = CFrame.new(center2 + Vector3.new(0, CFG.FloatY, 0))
            HRP.AssemblyLinearVelocity  = Vector3.zero
            HRP.AssemblyAngularVelocity = Vector3.zero
            HRP.CFrame  = dest2
            frozenCF    = dest2
            freezeUntil = tick() + 0.35
            task.delay(0.15, function()
                if not HRP then return end
                pcall(function() CombatRmt:FireServer(center2) end)
            end)
        else
            TPToTarget(tRoot)
        end
        pcall(function() firetouchinterest(HRP,tRoot,0) end)
        task.wait(0.05+math.random()*0.05)
        pcall(function() firetouchinterest(HRP,tRoot,1) end)
        local now=tick()
        if CFG.SkillX and AbilityRmt and now-lastSkillX>=CFG.SkillCoolX then
            lastSkillX=now
            task.wait(0.05+math.random()*0.05)
            pcall(function() AbilityRmt:FireServer(2) end)
        end
        local tool=GetCurrentTool()
        if tool then
            pcall(function()
                local act=tool:FindFirstChildOfClass("RemoteEvent")
                if act then act:FireServer() end
            end)
        end
    end
end)

-- ══════════════════════════════════════════════════════
-- AUTO RESPAWN
-- ══════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(CFG.RespawnInterval)
        if not CFG.AutoRespawn or not CFG.Enabled then continue end
        Fluent:Notify({ Title="Auto Respawn", Content="รี spawn 🔄", Duration=3 })
        frozenCF=nil; freezeUntil=0; RefreshChar()
        if HRP then local bv=HRP:FindFirstChild("FarmFloat"); if bv then bv:Destroy() end; farmFloat=nil end
        if Hum then pcall(function() Hum.PlatformStand=false end); pcall(function() Hum.Health=0 end) end
        task.wait(4); RefreshChar()
        lastTP=-999; tping=false; curTarget=nil
        task.spawn(DoTeleport)
    end
end)

-- ══════════════════════════════════════════════════════
-- AUTO HAKI
-- ══════════════════════════════════════════════════════
local VIM=game:GetService("VirtualInputManager")
local function PressKey(keyCode)
    pcall(function() VIM:SendKeyEvent(true, keyCode, false, game) end)
    task.delay(0.1, function()
        pcall(function() VIM:SendKeyEvent(false, keyCode, false, game) end)
    end)
end

Options.BusoOn:OnChanged(function()
    CFG.BusoOn=Options.BusoOn.Value
    if CFG.BusoOn then PressKey(Enum.KeyCode.G) end
end)
Options.ObsOn:OnChanged(function()
    CFG.ObsOn=Options.ObsOn.Value
    if CFG.ObsOn then PressKey(Enum.KeyCode.H) end
end)

LP.CharacterAdded:Connect(function()
    task.wait(2.5); RefreshChar()
    if CFG.BusoOn then PressKey(Enum.KeyCode.G) end
    if CFG.ObsOn  then PressKey(Enum.KeyCode.H) end
end)

-- ══════════════════════════════════════════════════════
-- ANTI-AFK
-- ══════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(CFG.AntiAFKInterval)
        if CFG.AntiAFK then
            pcall(function()
                local cam=workspace.CurrentCamera
                if cam then cam.CFrame=cam.CFrame*CFrame.Angles(0,math.rad(0.1),0) end
            end)
        end
    end
end)
local VU=game:GetService("VirtualUser")
LP.Idled:Connect(function()
    VU:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    task.wait(1)
    VU:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

print("[🗡️Massive Update🔥] Sailor Piece By IMPACT]")
