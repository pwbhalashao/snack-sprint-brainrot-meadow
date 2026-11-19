-- Snack Sprint: Brainrot Meadow — client HUD.
-- ScreenGui over the 3D world: money, income/second, rebirths, storm
-- timer, rebirth button, and a context prompt when near a conveyor
-- character (buy) or near another player's character (steal / slap).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local buyEvent = remotes:WaitForChild("BuyCharacter")
local stealEvent = remotes:WaitForChild("StealCharacter")
local slapEvent = remotes:WaitForChild("Slap")
local rebirthEvent = remotes:WaitForChild("Rebirth")
local stateEvent = remotes:WaitForChild("GameState")

local gui = Instance.new("ScreenGui")
gui.Name = "SnackSprintHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function label(name: string, pos: UDim2, size: UDim2, text: string, textSize: number)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = pos
	l.Size = size
	l.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	l.BackgroundTransparency = 0.25
	l.TextColor3 = Color3.fromRGB(255, 255, 255)
	l.Text = text
	l.TextSize = textSize
	l.Font = Enum.Font.SourceSansBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = gui
	return l
end

-- Top-right panel (kept clear of Roblox's top-left menu buttons).
local moneyLabel = label("Money", UDim2.new(1, -260, 0, 12), UDim2.fromOffset(248, 36), "$250", 24)
local incomeLabel = label("Income", UDim2.new(1, -260, 0, 54), UDim2.fromOffset(248, 28), "+$0 / sec", 18)
local rebirthLabel = label("Rebirths", UDim2.new(1, -260, 0, 88), UDim2.fromOffset(248, 28), "Rebirths: 0", 18)
local stormLabel = label("Storm", UDim2.new(1, -260, 0, 122), UDim2.fromOffset(248, 28), "Pickle Storm in 180s", 18)

local titleLabel = label("Title", UDim2.new(0.5, -220, 0, 12), UDim2.fromOffset(440, 36), "SNACK SPRINT: BRAINROT MEADOW", 22)
titleLabel.TextXAlignment = Enum.TextXAlignment.Center

local promptLabel = label("Prompt", UDim2.new(0.5, -220, 1, -120), UDim2.fromOffset(440, 36), "", 20)
promptLabel.TextXAlignment = Enum.TextXAlignment.Center
promptLabel.Visible = false

local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.Position = UDim2.new(1, -260, 0, 162)
rebirthButton.Size = UDim2.fromOffset(248, 40)
rebirthButton.BackgroundColor3 = Color3.fromRGB(255, 190, 40)
rebirthButton.TextColor3 = Color3.fromRGB(30, 30, 30)
rebirthButton.Text = "Rebirth ($5,000)"
rebirthButton.TextSize = 20
rebirthButton.Font = Enum.Font.SourceSansBold
rebirthButton.Parent = gui
rebirthButton.MouseButton1Click:Connect(function()
	rebirthEvent:FireServer()
end)

local toastLabel = label("Toast", UDim2.new(0.5, -220, 0, 60), UDim2.fromOffset(440, 32), "", 18)
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.Visible = false

local function toast(text: string)
	toastLabel.Text = text
	toastLabel.Visible = true
	task.delay(3, function()
		toastLabel.Visible = false
	end)
end

stateEvent.OnClientEvent:Connect(function(state)
	if state.type == "state" then
		moneyLabel.Text = "$" .. tostring(state.money)
		incomeLabel.Text = "+$" .. tostring(state.income) .. " / sec"
		rebirthLabel.Text = "Rebirths: " .. tostring(state.rebirths)
		rebirthButton.Text = "Rebirth ($" .. tostring(state.rebirthCost) .. ")"
		if state.stormActive then
			stormLabel.Text = "PICKLE STORM! Conveyor is fast!"
			stormLabel.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
		else
			stormLabel.Text = "Pickle Storm in " .. tostring(state.stormIn) .. "s"
			stormLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		end
	elseif state.type == "storm_start" then
		toast("PICKLE STORM! Run home with your catch!")
	elseif state.type == "storm_end" then
		toast("The storm has passed.")
	elseif state.type == "stolen" then
		toast("You stole " .. tostring(state.name) .. "! Get it to your base!")
	end
end)

-- Proximity prompt: nearest conveyor character, or nearest other player's
-- character / player (for steal / slap). E buys, F steals, Q slaps.
local UserInputService = game:GetService("UserInputService")
local nearestUid: string? = nil
local nearestKind: string? = nil -- "buy" | "steal"
local nearestPlayer: Player? = nil

local function refreshPrompt()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		promptLabel.Visible = false
		nearestUid = nil
		nearestKind = nil
		nearestPlayer = nil
		return
	end
	local bestDist = 14
	nearestUid = nil
	nearestKind = nil
	-- Conveyor characters (no owner yet): buy.
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("Uid") then
			local primary = model.PrimaryPart
			if primary then
				local d = (root.Position - primary.Position).Magnitude
				if d < bestDist then
					bestDist = d
					nearestUid = model:GetAttribute("Uid")
					nearestKind = "buy"
				end
			end
		end
	end
	-- Other players close by: slap (Q). Steal is via their base characters,
	-- which are Models with a Uid but owned — handled by the server check;
	-- the prompt here only offers Buy for conveyor models.
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			local oRoot = other.Character:FindFirstChild("HumanoidRootPart")
			if oRoot and (root.Position - oRoot.Position).Magnitude < 9 then
				nearestPlayer = other
			end
		end
	end
	if nearestUid and nearestKind == "buy" then
		promptLabel.Text = "Press E to buy this character"
		promptLabel.Visible = true
	elseif nearestPlayer then
		promptLabel.Text = "Press Q to slap " .. nearestPlayer.DisplayName
		promptLabel.Visible = true
	else
		promptLabel.Visible = false
	end
end

RunService.RenderStepped:Connect(function()
	refreshPrompt()
end)

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E and nearestUid then
		buyEvent:FireServer(nearestUid)
	elseif input.KeyCode == Enum.KeyCode.Q and nearestPlayer then
		slapEvent:FireServer(nearestPlayer.UserId)
	elseif input.KeyCode == Enum.KeyCode.F and nearestUid then
		-- F on a base character: the server only accepts steals of
		-- characters owned by someone else, so this is safe to send.
		stealEvent:FireServer(nearestUid)
	end
end)
