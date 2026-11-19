-- Snack Sprint: Brainrot Meadow — server.
-- Loop: original characters walk the centre conveyor; a player buys one
-- (near the conveyor, enough money, a free slot on their base), it then
-- earns money every second on their base. Other players can steal a
-- character off a base and must carry it home; the owner can slap the
-- thief to make them drop it. Rebirth resets money for +25% income each.
-- A Pickle Storm every 3 minutes speeds the conveyor up and spawns faster.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Characters = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Characters"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local CharacterFactory = require(script.Parent:WaitForChild("CharacterFactory"))

local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local buyEvent = remotes:WaitForChild("BuyCharacter")
local stealEvent = remotes:WaitForChild("StealCharacter")
local slapEvent = remotes:WaitForChild("Slap")
local rebirthEvent = remotes:WaitForChild("Rebirth")
local stateEvent = remotes:WaitForChild("GameState")

local basesFolder = Workspace:WaitForChild("Bases")

local BASE_COLORS = {
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(120, 180, 255),
	Color3.fromRGB(120, 255, 140),
	Color3.fromRGB(255, 210, 90),
	Color3.fromRGB(190, 120, 255),
	Color3.fromRGB(255, 140, 200),
	Color3.fromRGB(90, 220, 220),
	Color3.fromRGB(255, 160, 70),
}

local BASE_POSITIONS = {
	Vector3.new(-28, 0.5, -60),
	Vector3.new(28, 0.5, -60),
	Vector3.new(-28, 0.5, -20),
	Vector3.new(28, 0.5, -20),
	Vector3.new(-28, 0.5, 20),
	Vector3.new(28, 0.5, 20),
	Vector3.new(-28, 0.5, 60),
	Vector3.new(28, 0.5, 60),
}

-- playerData[userId] = { money, rebirths, baseIndex, owned = {uid -> entry},
--   carrying = entry | nil, lastSlapAt, stunnedUntil }
local playerData = {}
local freeBases = {}
for i = 1, Config.MAX_BASES do
	freeBases[i] = true
end

-- conveyorModels[uid] = { model, def, mutation, speed }
local conveyorModels = {}
local nextUid = 1

local stormActive = false
local stormEndsAt = 0
local nextStormAt = os.clock() + Config.STORM_EVERY

local function newUid(): string
	nextUid += 1
	return "c" .. tostring(nextUid)
end

local function slotPosition(basePos: Vector3, slotIndex: number): Vector3
	-- 8 slots: 2 rows x 4 columns on the base pad.
	local col = (slotIndex - 1) % 4
	local row = math.floor((slotIndex - 1) / 4)
	return basePos + Vector3.new(-6 + col * 4, 1.5, -3.5 + row * 7)
end

local function createBase(index: number, pos: Vector3, color: Color3): Model
	local base = Instance.new("Model")
	base.Name = "Base" .. tostring(index)
	local pad = Instance.new("Part")
	pad.Name = "Pad"
	pad.Size = Vector3.new(20, 1, 16)
	pad.Position = pos
	pad.Color = color
	pad.Material = Enum.Material.SmoothPlastic
	pad.Anchored = true
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.Parent = base
	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(6, 3, 0.5)
	sign.Position = pos + Vector3.new(0, 4, -7.5)
	sign.Color = Color3.fromRGB(255, 255, 255)
	sign.Anchored = true
	sign.Parent = base
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(30, 30, 30)
	label.TextSize = 22
	label.Font = Enum.Font.SourceSansBold
	label.Text = "BASE " .. tostring(index)
	label.Parent = gui
	base.Parent = basesFolder
	return base
end

for i, pos in ipairs(BASE_POSITIONS) do
	createBase(i, pos, BASE_COLORS[i])
end

local function incomeOf(entry): number
	local def = Characters.byId(entry.defId)
	if not def then
		return 0
	end
	local mult = 1
	for _, m in ipairs(Characters.MUTATIONS) do
		if m.id == entry.mutationId then
			mult = m.multiplier
			break
		end
	end
	return def.incomePerSecond * mult
end

local function totalIncome(data): number
	local sum = 0
	for _, entry in pairs(data.owned) do
		sum += incomeOf(entry)
	end
	return math.floor(sum * (1 + Config.REBIRTH_BONUS * data.rebirths))
end

local function freeSlot(data): number?
	for i = 1, Config.BASE_SLOTS do
		local taken = false
		for _, entry in pairs(data.owned) do
			if entry.slot == i then
				taken = true
				break
			end
		end
		if not taken then
			return i
		end
	end
	return nil
end

local function placeOnBase(entry, data)
	local basePos = BASE_POSITIONS[data.baseIndex]
	local target = slotPosition(basePos, entry.slot)
	entry.model:SetPrimaryPartCFrame(CFrame.new(target))
	entry.model.Parent = Workspace
end

local function spawnConveyorCharacter()
	local def = Characters.rollCharacter()
	local mutation = Characters.rollMutation()
	local model = CharacterFactory.build(def, mutation)
	local uid = newUid()
	model:SetAttribute("Uid", uid)
	model:SetAttribute("DefId", def.id)
	model:SetAttribute("MutationId", mutation.id)
	model:SetAttribute("Cost", def.cost)
	model:SetPrimaryPartCFrame(CFrame.new(0, 1, -75))
	model.Parent = Workspace
	conveyorModels[uid] = { model = model, def = def, mutation = mutation }
end

-- Move conveyor characters; despawn at the far end.
RunService.Heartbeat:Connect(function(dt: number)
	local speed = Config.CONVEYOR_SPEED
	if stormActive then
		speed = Config.CONVEYOR_STORM_SPEED
	end
	for uid, item in pairs(conveyorModels) do
		local model = item.model
		if model.Parent == nil then
			conveyorModels[uid] = nil
		else
			local cf = model:GetPrimaryPartCFrame()
			local nextPos = cf.Position + Vector3.new(0, 0, speed * dt)
			model:SetPrimaryPartCFrame(CFrame.new(nextPos))
			if nextPos.Z > 82 then
				model:Destroy()
				conveyorModels[uid] = nil
			end
		end
	end
	-- Carry: keep a stolen character floating above its carrier's head.
	for _, data in pairs(playerData) do
		local carrying = data.carrying
		if carrying and carrying.model.Parent ~= nil then
			local player = Players:GetPlayerByUserId(data.userId)
			local char = player and player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root then
				carrying.model:SetPrimaryPartCFrame(
					CFrame.new(root.Position + Vector3.new(0, 4.5, 0))
				)
			end
		end
	end
end)

-- Spawner + storm clock.
task.spawn(function()
	while true do
		local now = os.clock()
		if not stormActive and now >= nextStormAt then
			stormActive = true
			stormEndsAt = now + Config.STORM_LENGTH
			stateEvent:FireAllClients({ type = "storm_start", seconds = Config.STORM_LENGTH })
		elseif stormActive and now >= stormEndsAt then
			stormActive = false
			nextStormAt = now + Config.STORM_EVERY
			stateEvent:FireAllClients({ type = "storm_end" })
		end
		spawnConveyorCharacter()
		local waitTime = Config.SPAWN_INTERVAL
		if stormActive then
			waitTime = Config.SPAWN_INTERVAL_STORM
		end
		task.wait(waitTime)
	end
end)

-- Income tick.
task.spawn(function()
	while true do
		task.wait(Config.INCOME_TICK)
		for userId, data in pairs(playerData) do
			local gain = totalIncome(data)
			if gain > 0 then
				data.money += gain
				local player = Players:GetPlayerByUserId(userId)
				if player then
					local ls = player:FindFirstChild("leaderstats")
					if ls then
						local m = ls:FindFirstChild("Money")
						if m then
							m.Value = data.money
						end
						local inc = ls:FindFirstChild("Income")
						if inc then
							inc.Value = gain
						end
					end
				end
			end
		end
	end
end)

-- Per-player state push (HUD).
task.spawn(function()
	while true do
		task.wait(1)
		for userId, data in pairs(playerData) do
			local player = Players:GetPlayerByUserId(userId)
			if player then
				stateEvent:FireClient(player, {
					type = "state",
					money = data.money,
					income = totalIncome(data),
					rebirths = data.rebirths,
					ownedCount = (function()
						local n = 0
						for _ in pairs(data.owned) do
							n += 1
						end
						return n
					end)(),
					stormActive = stormActive,
					stormIn = math.max(0, math.floor(nextStormAt - os.clock())),
					rebirthCost = Config.REBIRTH_BASE_COST * (data.rebirths + 1),
				})
			end
		end
	end
end)

local function characterNearPlayer(player: Player, model: Model, maxDist: number): boolean
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local primary = model.PrimaryPart
	if not root or not primary then
		return false
	end
	return (root.Position - primary.Position).Magnitude <= maxDist
end

buyEvent.OnServerEvent:Connect(function(player: Player, uid: string)
	local data = playerData[player.UserId]
	if not data then
		return
	end
	local item = conveyorModels[uid]
	if not item then
		return
	end
	local def = item.def
	if data.money < def.cost then
		return
	end
	if not characterNearPlayer(player, item.model, 14) then
		return
	end
	local slot = freeSlot(data)
	if not slot then
		return
	end
	data.money -= def.cost
	local entry = {
		uid = uid,
		defId = def.id,
		mutationId = item.mutation.id,
		slot = slot,
		model = item.model,
		ownerId = player.UserId,
		lastStealAt = 0,
	}
	conveyorModels[uid] = nil
	data.owned[uid] = entry
	placeOnBase(entry, data)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local m = ls:FindFirstChild("Money")
		if m then
			m.Value = data.money
		end
	end
end)

stealEvent.OnServerEvent:Connect(function(player: Player, uid: string)
	local data = playerData[player.UserId]
	if not data or data.carrying then
		return
	end
	-- Find the character on somebody else's base.
	local targetEntry = nil
	local targetData = nil
	for _, other in pairs(playerData) do
		if other.userId ~= player.UserId and other.owned[uid] then
			targetEntry = other.owned[uid]
			targetData = other
			break
		end
	end
	if not targetEntry or not targetData then
		return
	end
	if os.clock() - targetEntry.lastStealAt < Config.STEAL_COOLDOWN then
		return
	end
	if not characterNearPlayer(player, targetEntry.model, 12) then
		return
	end
	targetData.owned[uid] = nil
	targetEntry.lastStealAt = os.clock()
	data.carrying = targetEntry
	stateEvent:FireClient(player, { type = "stolen", name = Characters.byId(targetEntry.defId).name })
end)

-- Reaching your own base while carrying delivers the stolen character.
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, data in pairs(playerData) do
			local carrying = data.carrying
			if carrying then
				local player = Players:GetPlayerByUserId(data.userId)
				local char = player and player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					local basePos = BASE_POSITIONS[data.baseIndex]
					if (root.Position - basePos).Magnitude < 12 then
						local slot = freeSlot(data)
						if slot then
							carrying.slot = slot
							carrying.ownerId = data.userId
							data.owned[carrying.uid] = carrying
							data.carrying = nil
							placeOnBase(carrying, data)
						end
					end
				end
			end
		end
	end
end)

slapEvent.OnServerEvent:Connect(function(player: Player, targetUserId: number)
	local data = playerData[player.UserId]
	local target = Players:GetPlayerByUserId(targetUserId)
	local targetData = target and playerData[targetUserId]
	if not data or not target or not targetData then
		return
	end
	if os.clock() - data.lastSlapAt < Config.SLAP_COOLDOWN then
		return
	end
	local pChar = player.Character
	local tChar = target.Character
	local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
	local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
	if not pRoot or not tRoot then
		return
	end
	if (pRoot.Position - tRoot.Position).Magnitude > 9 then
		return
	end
	data.lastSlapAt = os.clock()
	local carrying = targetData.carrying
	-- Only a slap that rescues your own character drops the catch.
	if carrying and carrying.ownerId == player.UserId then
		targetData.carrying = nil
		local ownerData = playerData[carrying.ownerId]
		if ownerData then
			local slot = freeSlot(ownerData)
			if slot then
				carrying.slot = slot
				ownerData.owned[carrying.uid] = carrying
				placeOnBase(carrying, ownerData)
			end
		end
	end
	local humanoid = tChar:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		task.delay(Config.SLAP_STUN, function()
			if humanoid.Parent ~= nil then
				humanoid.WalkSpeed = 16
			end
		end)
	end
end)

rebirthEvent.OnServerEvent:Connect(function(player: Player)
	local data = playerData[player.UserId]
	if not data then
		return
	end
	local cost = Config.REBIRTH_BASE_COST * (data.rebirths + 1)
	if data.money < cost then
		return
	end
	for _, entry in pairs(data.owned) do
		if entry.model.Parent ~= nil then
			entry.model:Destroy()
		end
	end
	data.owned = {}
	data.carrying = nil
	data.money = Config.START_MONEY
	data.rebirths += 1
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local m = ls:FindFirstChild("Money")
		if m then
			m.Value = data.money
		end
		local r = ls:FindFirstChild("Rebirths")
		if r then
			r.Value = data.rebirths
		end
	end
end)

local function onPlayerAdded(player: Player)
	local baseIndex = nil
	for i = 1, Config.MAX_BASES do
		if freeBases[i] then
			baseIndex = i
			freeBases[i] = false
			break
		end
	end
	if not baseIndex then
		baseIndex = 1
	end
	local data = {
		userId = player.UserId,
		money = Config.START_MONEY,
		rebirths = 0,
		baseIndex = baseIndex,
		owned = {},
		carrying = nil,
		lastSlapAt = 0,
	}
	playerData[player.UserId] = data

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = data.money
	money.Parent = leaderstats
	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	player.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			local basePos = BASE_POSITIONS[baseIndex]
			char:SetPrimaryPartCFrame(CFrame.new(basePos + Vector3.new(0, 3, 12)))
		end
	end)
end

local function onPlayerRemoving(player: Player)
	local data = playerData[player.UserId]
	if data then
		for _, entry in pairs(data.owned) do
			if entry.model.Parent ~= nil then
				entry.model:Destroy()
			end
		end
		if data.carrying and data.carrying.model.Parent ~= nil then
			data.carrying.model:Destroy()
		end
		freeBases[data.baseIndex] = true
		playerData[player.UserId] = nil
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("Snack Sprint: Brainrot Meadow server ready.")
