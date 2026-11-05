-- COLLATZ: FALL OF THE PRIMES | ServerScriptService/CollatzGame (Script)
-- Builds a playable Episode 1, manages quests, fragments, drones, and combat.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local existing = workspace:FindFirstChild("CollatzWorld")
if existing then existing:Destroy() end
local world = Instance.new("Folder")
world.Name = "CollatzWorld"
world.Parent = workspace

local events = ReplicatedStorage:FindFirstChild("CollatzEvents") or Instance.new("Folder")
events.Name = "CollatzEvents"
events.Parent = ReplicatedStorage
local notify = events:FindFirstChild("Notify") or Instance.new("RemoteEvent")
notify.Name = "Notify"
notify.Parent = events
local attack = events:FindFirstChild("Attack") or Instance.new("RemoteEvent")
attack.Name = "Attack"
attack.Parent = events

local function part(name, size, pos, color, material, parent)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Position = name, size, pos
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.Parent = parent or world
    return p
end
local function label(adornee, text, offset, width)
    local bb = Instance.new("BillboardGui")
    bb.Name = "Title"
    bb.Adornee = adornee
    bb.Size = UDim2.fromOffset(width or 240, 60)
    bb.StudsOffset = Vector3.new(0, offset or 4, 0)
    bb.AlwaysOnTop = true
    bb.Parent = adornee
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.fromScale(1,1)
    t.Text = text
    t.TextScaled = true
    t.TextWrapped = true
    t.Font = Enum.Font.GothamBold
    t.TextColor3 = Color3.fromRGB(220,240,255)
    t.TextStrokeTransparency = .4
    t.Parent = bb
end
local function message(player, speaker, words, objective)
    notify:FireClient(player, speaker, words, objective or "")
end

-- Map: a fractured archive plaza on Planet Primehold.
part("Primehold Ground", Vector3.new(210,4,210), Vector3.new(0,-3,0), Color3.fromRGB(29,39,63), Enum.Material.Slate)
for i = -4,4 do
    part("Archive Walkway", Vector3.new(6,.35,125), Vector3.new(i*10,-.8,0), Color3.fromRGB(42,59,86), Enum.Material.Metal)
end
for i = 1,12 do
    local a = i * math.pi/6
    local radius = 65
    local h = (i%4+2)*5
    part("Fallen Pillar", Vector3.new(6,h,6),Vector3.new(math.cos(a)*radius,h/2-1,math.sin(a)*radius),Color3.fromRGB(62,77,97),Enum.Material.Concrete)
end
local sp = Instance.new("SpawnLocation")
sp.Name = "Zeta Prime Spawn"
sp.Size = Vector3.new(9,1,9)
sp.Position = Vector3.new(0,0,77)
sp.Anchored = true
sp.Neutral = true
sp.Color = Color3.fromRGB(29,195,217)
sp.Material = Enum.Material.Neon
sp.Parent = world
label(sp,"PLANET PRIMEHOLD\nCOMPOSITE GUARD OUTPOST",7,330)

-- Archivist Sigma: friendly NPC.
local sigma = part("Archivist Sigma", Vector3.new(4,7,3), Vector3.new(0,3,-38),Color3.fromRGB(80,170,244),Enum.Material.Metal)
label(sigma,"ARCHIVIST SIGMA",6,270)
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Talk"
prompt.ObjectText = "Archivist Sigma"
prompt.MaxActivationDistance = 13
prompt.RequiresLineOfSight = false
prompt.Parent = sigma

-- Escape gateway: initially inactive.
local gateBase = part("Portal Frame", Vector3.new(16,16,2), Vector3.new(0,7,-81), Color3.fromRGB(82,100,133), Enum.Material.Metal)
local portal = part("Residua Portal", Vector3.new(11,12,1), Vector3.new(0,7,-79.8), Color3.fromRGB(53,69,82), Enum.Material.Glass)
portal.Transparency = .45
portal.CanCollide = false
label(gateBase,"GATE TO RESIDUA (LOCKED)",11,300)

local playersData = {}
local drones = {}
local fragments = {}
local function getData(player)
    return playersData[player]
end
local function objective(data)
    if data.episodeDone then return "Episode 1 complete" end
    if not data.started then return "Find Archivist Sigma" end
    if data.kills < 3 then return ("Disable Collatz drones (%d/3)"):format(data.kills) end
    if data.collected < 3 then return ("Recover Proof Fragments (%d/3)"):format(data.collected) end
    if not data.portalReady then return "Return to Archivist Sigma" end
    return "Enter the portal to Residua"
end

local dronePositions = {
    Vector3.new(-28,2,14), Vector3.new(29,2,12), Vector3.new(0,2,-5)
}
for i,pos in ipairs(dronePositions) do
    local body = part("Collatz Drone "..i, Vector3.new(5,4,5),pos,Color3.fromRGB(183,61,80),Enum.Material.Neon)
    body.Shape = Enum.PartType.Ball
    label(body,"COLLATZ DRONE",5,220)
    drones[i] = {body=body, health=100, alive=true, spawn=pos}
end
local fragmentPositions = {
    Vector3.new(-42,2,-22), Vector3.new(45,2,-24), Vector3.new(-4,2,29)
}
for i,pos in ipairs(fragmentPositions) do
    local crystal = part("Proof Fragment "..i, Vector3.new(3,3,3),pos,Color3.fromRGB(254,218,101),Enum.Material.Neon)
    crystal.Shape = Enum.PartType.Ball
    label(crystal,"PROOF FRAGMENT",4,200)
    local p = Instance.new("ProximityPrompt")
    p.ActionText = "Collect"
    p.ObjectText = "Proof Fragment"
    p.MaxActivationDistance = 10
    p.RequiresLineOfSight = false
    p.Parent = crystal
    fragments[i] = crystal
    p.Triggered:Connect(function(player)
        local data = getData(player)
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not data or not root or (root.Position-crystal.Position).Magnitude > 12 then return end
        if not data.started or data.kills < 3 then
            message(player,"Zeta Prime","The archive seals are still active. Disable the three drones first.",objective(data))
            return
        end
        if data.fragments[i] then return end
        data.fragments[i] = true
        data.collected += 1
        message(player,"Archive System","Proof Fragment "..i.." recovered. The Conjecture's location is partially decoded.",objective(data))
        -- Client-specific collection: keep part visible for other players.
    end)
end

prompt.Triggered:Connect(function(player)
    local data = getData(player)
    if not data then return end
    if not data.started then
        data.started = true
        message(player,"Archivist Sigma","Zeta Prime... Collatz seized twenty galaxies searching for the Conjecture. He attacked our archives, but one proof escaped. Find the fragments. First, disable his three drones.", objective(data))
    elseif data.kills < 3 then
        message(player,"Archivist Sigma","His drones still occupy the plaza. Use your Pulse Blade to disable all three.",objective(data))
    elseif data.collected < 3 then
        message(player,"Archivist Sigma","The drones are down. Recover all three golden Proof Fragments.",objective(data))
    elseif not data.portalReady then
        data.portalReady = true
        message(player,"Archivist Sigma","The Conjecture is not a weapon. It is a pattern that could reshape every galaxy. Collatz is heading for Residua. The gate is open—go!",objective(data))
    else
        message(player,"Archivist Sigma","Go through the portal, Zeta. Don't let Collatz reach Residua's observatory.",objective(data))
    end
end)

local cooldown = {}
attack.OnServerEvent:Connect(function(player)
    local data = getData(player)
    if not data or not data.started or data.kills >= 3 then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local tool = char and char:FindFirstChild("Pulse Blade")
    if not root or not humanoid or humanoid.Health <= 0 or not tool then return end
    local t = os.clock()
    if cooldown[player] and t - cooldown[player] < .55 then return end
    cooldown[player] = t
    local target, best = nil, 13
    for _, drone in ipairs(drones) do
        if drone.alive then
            local dist = (drone.body.Position-root.Position).Magnitude
            if dist < best then target,best = drone,dist end
        end
    end
    if not target then return end
    target.health -= 35
    target.body.Color = Color3.fromRGB(255,166,164)
    task.delay(.15, function()
        if target.alive then target.body.Color = Color3.fromRGB(183,61,80) end
    end)
    if target.health <= 0 then
        target.alive = false
        target.body.Transparency = .8
        target.body.CanCollide = false
        target.body:FindFirstChildOfClass("BillboardGui").Enabled = false
        data.kills += 1
        message(player,"Zeta Prime","Drone disabled. The archive plaza is one step closer to freedom.",objective(data))
    end
end)

portal.Touched:Connect(function(hit)
    local character = hit:FindFirstAncestorOfClass("Model")
    local player = character and Players:GetPlayerFromCharacter(character)
    local data = player and getData(player)
    if not data or not data.portalReady or data.episodeDone then return end
    data.episodeDone = true
    message(player,"EPISODE 1 COMPLETE","You escaped Primehold. Across the stars, Collatz watches Residua. NEXT: The Observatory of Remainders.","Episode 1 complete")
end)

local function giveBlade(player)
    local backpack = player:WaitForChild("Backpack")
    if backpack:FindFirstChild("Pulse Blade") or (player.Character and player.Character:FindFirstChild("Pulse Blade")) then return end
    local tool = Instance.new("Tool")
    tool.Name = "Pulse Blade"
    tool.RequiresHandle = false
    tool.CanBeDropped = false
    tool.ToolTip = "Click near a drone to disable it"
    tool.Parent = backpack
end
Players.PlayerAdded:Connect(function(player)
    playersData[player] = {started=false, kills=0, collected=0,fragments={}, portalReady=false, episodeDone=false}
    player.CharacterAdded:Connect(function()
        task.defer(function() giveBlade(player) end)
        task.delay(2, function()
            if player.Parent then
                local data = getData(player)
                if data then
                    message(player,"NARRATOR","Planet Primehold has fallen. Collatz seeks the Conjecture. You are Zeta Prime, a Composite Guard warrior. Find Archivist Sigma.",objective(data))
                end
            end
        end)
    end)
end)
Players.PlayerRemoving:Connect(function(player)
    playersData[player] = nil
    cooldown[player] = nil
end)
