-- Builds a character Model from plain Parts only (no meshes, no image
-- assets, no borrowed art). Each character is a chunky little figure:
-- body, head, eyes, feet, and one signature accessory per character.

local CharacterFactory = {}

local function part(name: string, size: Vector3, color: Color3, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function weldAll(model: Model)
	local root = model.PrimaryPart
	if not root then
		return
	end
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") and desc ~= root then
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = desc
			w.Parent = root
		end
	end
end

-- def: one entry of Characters.LIST. mutation: one entry of MUTATIONS.
function CharacterFactory.build(def, mutation): Model
	local model = Instance.new("Model")
	model.Name = def.name

	local bodyColor = def.bodyColor
	if mutation and mutation.color then
		bodyColor = mutation.color
	end

	local body = part("Body", Vector3.new(2.4, 2.2, 1.8), bodyColor)
	body.Position = Vector3.new(0, 2.1, 0)
	body.Parent = model
	model.PrimaryPart = body

	local head = part("Head", Vector3.new(1.8, 1.6, 1.6), def.accentColor)
	head.Position = Vector3.new(0, 4.0, 0)
	head.Parent = model

	local eyeL = part("EyeL", Vector3.new(0.35, 0.5, 0.2), Color3.fromRGB(255, 255, 255))
	eyeL.Position = Vector3.new(-0.45, 4.1, 0.85)
	eyeL.Parent = model
	local eyeR = part("EyeR", Vector3.new(0.35, 0.5, 0.2), Color3.fromRGB(255, 255, 255))
	eyeR.Position = Vector3.new(0.45, 4.1, 0.85)
	eyeR.Parent = model

	local footL = part("FootL", Vector3.new(0.8, 0.5, 1.2), def.accentColor)
	footL.Position = Vector3.new(-0.6, 0.25, 0)
	footL.Parent = model
	local footR = part("FootR", Vector3.new(0.8, 0.5, 1.2), def.accentColor)
	footR.Position = Vector3.new(0.6, 0.25, 0)
	footR.Parent = model

	-- One signature accessory per character, all plain Parts.
	if def.id == "sir_croissant" then
		local hat = part("Plume", Vector3.new(0.5, 1.0, 0.5), Color3.fromRGB(220, 60, 60))
		hat.Position = Vector3.new(0, 5.2, 0)
		hat.Parent = model
	elseif def.id == "dj_pickle" then
		local disc = part("Disc", Vector3.new(2.2, 0.25, 2.2), Color3.fromRGB(30, 30, 30))
		disc.CFrame = CFrame.new(0, 5.0, 0) * CFrame.Angles(0, 0, 0)
		disc.Position = Vector3.new(0, 5.0, 0)
		disc.Parent = model
	elseif def.id == "captain_noodle" then
		local hat = part("SailorHat", Vector3.new(2.0, 0.4, 2.0), Color3.fromRGB(255, 255, 255))
		hat.Position = Vector3.new(0, 5.0, 0)
		hat.Parent = model
	elseif def.id == "professor_waffle" then
		local book = part("Book", Vector3.new(1.2, 0.2, 1.6), Color3.fromRGB(90, 60, 160))
		book.Position = Vector3.new(1.4, 2.4, 0)
		book.Parent = model
	elseif def.id == "turbo_taco_cat" then
		local earL = part("EarL", Vector3.new(0.5, 0.9, 0.4), def.accentColor)
		earL.Position = Vector3.new(-0.6, 5.1, 0)
		earL.Parent = model
		local earR = part("EarR", Vector3.new(0.5, 0.9, 0.4), def.accentColor)
		earR.Position = Vector3.new(0.6, 5.1, 0)
		earR.Parent = model
	elseif def.id == "queen_boba" then
		local crown = part("Crown", Vector3.new(1.6, 0.6, 1.6), Color3.fromRGB(255, 210, 60))
		crown.Position = Vector3.new(0, 5.0, 0)
		crown.Parent = model
	elseif def.id == "lord_dumpling" then
		local fan = part("Fan", Vector3.new(1.6, 1.0, 0.2), Color3.fromRGB(200, 60, 60))
		fan.Position = Vector3.new(1.5, 3.0, 0)
		fan.Parent = model
	elseif def.id == "cosmic_ramen_dragon" then
		local wingL = part("WingL", Vector3.new(2.0, 0.3, 1.2), Color3.fromRGB(255, 220, 80))
		wingL.Position = Vector3.new(-1.8, 3.4, 0)
		wingL.Parent = model
		local wingR = part("WingR", Vector3.new(2.0, 0.3, 1.2), Color3.fromRGB(255, 220, 80))
		wingR.Position = Vector3.new(1.8, 3.4, 0)
		wingR.Parent = model
	end

	-- Name tag above the head (BillboardGui, created in code).
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.fromOffset(140, 36)
	tag.StudsOffset = Vector3.new(0, 2.2, 0)
	tag.AlwaysOnTop = true
	tag.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.4
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 15
	label.Font = Enum.Font.SourceSansBold
	label.Text = def.name
	label.Parent = tag

	weldAll(model)
	return model
end

return CharacterFactory
