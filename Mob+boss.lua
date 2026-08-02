repeat task.wait() until game:IsLoaded()

local _ENV = (getgenv or getrenv or getfenv)()

local Importer, Inserter = ...

local HIDDEN_SETTINGS: { [ string ]: any } = {
    ROLL_COOLDOWN = 0.4
}

local Owner = "vita8it"
local Respoitory = "Xynapse"

if type(Importer) ~= 'function' then
    Importer = function(Path)
        local Github = 'https://raw.githubusercontent.com/%s'
        local Direct = `{Owner}/{Respoitory}/main/{Path}.lua`

        local Formater = Github:format(Direct)
        local Result = game:HttpGet(Formater)

        return loadstring(Result)
    end 
end

local Module, Cache = {}, {}
local Packages, Settings = Importer('Utils/Packages')(Importer)

local UserInputService = game:GetService('UserInputService')
local TeleportService = game:GetService('TeleportService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService('RunService')
local Lighting = game:GetService('Lighting')
local Players = game:GetService('Players')

local Configurators = Packages.Configurators
local Connectors = Packages.Connectors
local Queueable =  Packages.Queueable
local Plugins = Packages.Plugins

local Options = Queueable.new()
local Connect = Connectors.Connect

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local MAP = workspace:WaitForChild('MAP')

local Plots = MAP:WaitForChild('Plots')

local CardSlotRE = ReplicatedStorage:WaitForChild('CardSlotRE')
local Modules = ReplicatedStorage:WaitForChild('Modules')
local Remotes = ReplicatedStorage:WaitForChild('Remotes')

local GiftRE = Remotes:WaitForChild('GiftRE')
local ConveyorRE = Remotes:WaitForChild('ConveyorRE')

local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped
local Player = Players.LocalPlayer

local PlayerGui = Player.PlayerGui

function NewModule(Name, Function)
    do Module[Name] = Function(Module)
        return Module[Name]
    end
end

NewModule("PlotManagers", function()
    local PlotManagers = {}

    local PlotNumber = Player:WaitForChild('PlotNumber')
    local Plots = Plots[ tostring(PlotNumber.Value) ]

    local Conveyor = Plots:FindFirstChild('LocalConveyorModels', true)
    local ClickDetector = Plots:FindFirstChild('ClickDetector', true)
    local SellPart = Plots:FindFirstChild('SellPart', true)
    local ProxiBox = Plots:FindFirstChild('ProxiBox', true)
    local Prompt = Plots:FindFirstChild('Prompt', true)

    Cache.PlotNumber = PlotNumber
    Cache.Conveyor = Conveyor
    Cache.SellPart = SellPart
    Cache.Plots = Plots

    PlotManagers.Rolls = setmetatable({ LastRoll = -math.huge }, {
        __call = function(self)
            local Now = tick()

            if Now - self.LastRoll >= HIDDEN_SETTINGS.ROLL_COOLDOWN then
                self.LastRoll = Now
                pcall(fireclickdetector, ClickDetector)
            end
        end,
    })

    PlotManagers.Buys = function(Card)
        if Player.Character then
            local ProximityPrompt = Card:FindFirstChild('ProximityPrompt', true)
            if not ProximityPrompt then return end

            Player.Character:PivotTo(Prompt.CFrame) 
            pcall(fireproximityprompt, ProximityPrompt)
        end
    end

    PlotManagers.Sells = function()
        if SellPart.ProximityPrompt and Player.Character then
            Player.Character:PivotTo(SellPart.CFrame) 
            task.wait(1)
            pcall(fireproximityprompt, SellPart.ProximityPrompt)
        end
    end

    PlotManagers.Boxs = function()
        if ProxiBox.ProximityPrompt and Player.Character then
            Player.Character:PivotTo(ProxiBox.CFrame) 
            task.wait(1)
            pcall(fireproximityprompt, ProxiBox.ProximityPrompt)
        end
    end

    PlotManagers.GetSlots = function()
        local Slots = {}

        for _, Slot in Plots.Plot_N0:GetChildren() do
            if Slot.Name:find('CardSlot') then
                table.insert(Slots, Slot)
            end
        end

        return Slots
    end

    PlotManagers.GetSlotsByAction = function(Action)
        local Slots = PlotManagers.GetSlots()

        for _, Slot in Slots do
            local PromptHolder = Slot:FindFirstChild('PromptHolder')
            if not PromptHolder then continue end

            local ProximityPrompt = PromptHolder.ProximityPrompt
            if ProximityPrompt and ProximityPrompt.ActionText == Action then
                return Slot, ProximityPrompt
            end
        end
    end

    PlotManagers.GetCards = function(Backpack)
        for _, Card in Backpack:GetChildren() do
            if Card.Name:find('Pack') then
                return Card
            end
        end
    end

    return PlotManagers
end)

NewModule("CardsModule", function()
    local CardsModule = {} do
        Cache.LastRandomResult = nil
    end

    local ConveyorPacks = require(Modules.ConveyorPacks)
    local CardsConfig = require(Modules.CardsConfig)

    CardsModule.Events = {
        ["SpawnAndMoveToB"] = function(Data)
            Cache.Price = Data.Price
        end,
        ["BoughtAndRemove"] = function(Data)
            Cache.Price = nil
        end,
    }

    CardsModule.Packs = {} do
        for Pack, _ in CardsConfig.PackCards do
            table.insert(CardsModule.Packs, Pack)
        end 
    end

    CardsModule.Mutations = {} do
        for _, Mutation in ConveyorPacks.Mutations do
            table.insert(CardsModule.Mutations, Mutation.Name)
        end
    end

    Connect(ConveyorRE.OnClientEvent, function(Action, ...)
        if CardsModule.Events[Action] then
            CardsModule.Events[Action]( ... )
        end
    end)

    return CardsModule
end)

local PlotManagers = Module.PlotManagers
local CardsModule = Module.CardsModule

NewModule("Sequencer Managers", function()
    Cache.LastSelled = 0

    Options:NewOption("Open Card Packs", function()
        local Character = Player.Character
        if not Character then return end

        local Backpack = Player:FindFirstChildOfClass('Backpack')
        if not Backpack then return end

        local Humanoid = Character:FindFirstChildOfClass('Humanoid')
        if not Humanoid then return end

        local NeedOpen, PromptOpen = PlotManagers.GetSlotsByAction("Open")

        if NeedOpen and PromptOpen then
            Character:PivotTo(NeedOpen:GetPivot())
            pcall(fireproximityprompt, PromptOpen)
            return true
        end

        local NeedRemove, PromptRemove = PlotManagers.GetSlotsByAction("Remove")

        if NeedRemove and PromptRemove then
            Character:PivotTo(NeedRemove:GetPivot())
            pcall(fireproximityprompt, PromptRemove)
            return true
        end

        local NeedPlace, PromptPlace = PlotManagers.GetSlotsByAction("Place")

        if NeedPlace and PromptPlace then
            local Equipped = Character:FindFirstChildOfClass('Tool')

            if Equipped and Equipped.Name:find('Pack') then
                Character:PivotTo(NeedPlace:GetPivot())
                pcall(fireproximityprompt, PromptPlace)
            else
                local Card = PlotManagers.GetCards(Backpack)
                if not Card then return end

                Humanoid:EquipTool(Card)
            end

            return true
        end
    end)

    Options:NewOption("Roll Cards", function()
        local Card = Cache.Conveyor:FindFirstChildOfClass("Model")
        if not Card or not Cache.Price then return PlotManagers.Rolls() end

        local Gui = Card:FindFirstChild("BillboardGuiInfo", true)
        if not Gui then return end

        local Name = Card.Name
        local Mutation = Gui.Mutation.Text

        local ShouldBuy =
            table.find(Settings["Select Packs"], Name) and
            table.find(Settings["Select Mutations"], Mutation)

        if not ShouldBuy then return PlotManagers.Rolls() end
        if not Settings["Buy Cards"] then return end

        if Settings["Skip Cards"] and Player.CashValue.Value < Cache.Price then
            return PlotManagers.Rolls()
        end

        PlotManagers.Buys(Card)

        return true
    end)

    Options:NewOption("Selling Cards", function()
        local Character = Player.Character
        if not Character then return end

        local Backpack = Player:FindFirstChildOfClass('Backpack')
        if not Backpack then return end

        local Humanoid = Character:FindFirstChildOfClass('Humanoid')
        if not Humanoid then return end

        local Now = tick()
        local Cooldown = Settings["Selling Interval"]

        if Now - Cache.LastSelled < Cooldown then
            return false
        end

        local Equipped = Character:FindFirstChildOfClass('Tool')

        if Equipped and Equipped.Name == 'Box' then
            Cache.LastSelled = Now
            PlotManagers.Sells()
        else
            local Box = Backpack:FindFirstChild('Box')

            if not Box then
                PlotManagers.Boxs()
                return
            end

            Humanoid:EquipTool(Box)
        end

        return true
    end)
end)

NewModule("Window Managers", function()
    local Folder = gethui and gethui()

    local Title = "Xynapse"
    local Footer = "Copy right 2026 Xynapse, All right reserved."

    for _, Object in Folder:GetChildren() do
        if Object.Name:find('Xyn') then
            Object:Destroy()
        end
    end

    local Window = Plugins:Window({ Title, Footer, 124715602753920 }, Options) do
        Plugins:Community() 
    end

    local Rolls = Plugins:Page(117686260778540) do
        Rolls.Rollers = "Working" do
            Packages:Default("Select Packs", {
                CardsModule.Packs[1]
            })

            Packages:Default("Select Mutations", {
                CardsModule.Mutations[1]
            })

            Plugins:Dropdown(Rolls.Rollers, "Select Packs", CardsModule.Packs, 'Select Packs')

            Plugins:Dropdown(Rolls.Rollers, "Select Mutations", CardsModule.Mutations, 'Select Mutations')

            Plugins:Toggle(Rolls.Rollers, {
                "Skip Cards",
                "Skip cards if you don't have enough money."
            }, "Skip Cards")

            Plugins:Toggle(Rolls.Rollers, {
                "Buy Cards",
                "Buy if founds select cards."
            }, "Buy Cards")

            Plugins:Toggle(Rolls.Rollers, {
                "Roll Cards",
                "Rolls cards until the selected cards are found."
            }, "Roll Cards")
        end

        Rolls.Sellers = "Working" do
            Packages:Default("Selling Interval", 10)

            Plugins:Toggle(Rolls.Sellers, {
                "Selling Cards",
                "Sell all card boxs."
            }, 'Selling Cards')

            Plugins:Slider(Rolls.Sellers, {
                "Selling Interval",
                "The time period between sales cycles."
            }, { 1, 30, 0 }, "Selling Interval")
        end

        Rolls.Cards = "Working" do
            Plugins:Toggle(Rolls.Cards, {
                "Open Card Packs",
                "Place all card packs and open."
            }, 'Open Card Packs')
        end
    end

    Plugins:Managers()
    Options:RunQueue()
    
    Connect(Player.Idled, function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)
