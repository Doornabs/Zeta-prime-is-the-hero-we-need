-- COLLATZ: FALL OF THE PRIMES | StarterPlayerScripts/CollatzClient (LocalScript)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local events = ReplicatedStorage:WaitForChild("CollatzEvents")
local notify = events:WaitForChild("Notify")
local attack = events:WaitForChild("Attack")

local gui = Instance.new("ScreenGui")
gui.Name = "CollatzHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local function makeText(name, size, pos, color, textSize)
    local t = Instance.new("TextLabel")
    t.Name = name
    t.Size = size
    t.Position = pos
    t.BackgroundColor3 = Color3.fromRGB(11,19,38)
    t.BackgroundTransparency = .16
    t.TextColor3 = color
    t.TextSize = textSize
    t.TextWrapped = true
    t.Font = Enum.Font.GothamBold
    t.BorderSizePixel = 0
    t.Parent = gui
    return t
end
local title = makeText("Title", UDim2.new(.40,0,0,40), UDim2.new(.30,0,0,12),Color3.fromRGB(250,221,141),22)
title.Text = "COLLATZ: FALL OF THE PRIMES"
local objective = makeText("Objective", UDim2.new(.5,0,0,44), UDim2.new(.25,0,0,60),Color3.fromRGB(220,244,255),18)
objective.Text = "OBJECTIVE: Find Archivist Sigma"
local dialogue = makeText("Dialogue", UDim2.new(.75,0,0,120), UDim2.new(.125,0,1,-150),Color3.fromRGB(244,246,255),20)
dialogue.Visible = false
local timer = 0
notify.OnClientEvent:Connect(function(speaker, words, nextObjective)
    timer += 1
    local token = timer
    dialogue.Text = string.upper(speaker).."\n"..words
    dialogue.Visible = true
    if nextObjective and nextObjective ~= "" then objective.Text = "OBJECTIVE: "..nextObjective end
    task.delay(10,function()
        if token == timer then dialogue.Visible = false end
    end)
end)

local function connectTool(tool)
    if not tool:IsA("Tool") or tool.Name ~= "Pulse Blade" then return end
    tool.Activated:Connect(function() attack:FireServer() end)
end
local backpack = player:WaitForChild("Backpack")
backpack.ChildAdded:Connect(connectTool)
for _,item in ipairs(backpack:GetChildren()) do connectTool(item) end
local function onCharacter(character)
    character.ChildAdded:Connect(connectTool)
    for _,item in ipairs(character:GetChildren()) do connectTool(item) end
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then onCharacter(player.Character) end
