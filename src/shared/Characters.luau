-- Shared character catalogue for Snack Sprint: Brainrot Meadow.
-- ALL characters are original inventions for this game. None are copied
-- from Steal a Brainrot or any other game: no borrowed names, art or assets.
-- Each character is built at runtime from plain Roblox Parts (see
-- src/server/CharacterFactory.luau), so the game needs no mesh/image assets.

local Characters = {}

Characters.RARITIES = {
	Common = { order = 1, color = Color3.fromRGB(180, 180, 180), multiplier = 1 },
	Rare = { order = 2, color = Color3.fromRGB(80, 160, 255), multiplier = 1 },
	Epic = { order = 3, color = Color3.fromRGB(170, 90, 255), multiplier = 1 },
	Legendary = { order = 4, color = Color3.fromRGB(255, 190, 40), multiplier = 1 },
	Mythic = { order = 5, color = Color3.fromRGB(255, 80, 160), multiplier = 1 },
}

-- weight = how often it spawns on the conveyor (higher = more common).
Characters.LIST = {
	{
		id = "sir_croissant",
		name = "Sir Croissant",
		blurb = "A polite pastry knight. Salutes everyone, earns while he bows.",
		rarity = "Common",
		cost = 120,
		incomePerSecond = 2,
		weight = 30,
		bodyColor = Color3.fromRGB(232, 178, 90),
		accentColor = Color3.fromRGB(120, 70, 20),
	},
	{
		id = "dj_pickle",
		name = "DJ Pickle",
		blurb = "Spins sour beats on the conveyor. The crowd pays to stay briny.",
		rarity = "Common",
		cost = 200,
		incomePerSecond = 3,
		weight = 26,
		bodyColor = Color3.fromRGB(110, 190, 70),
		accentColor = Color3.fromRGB(30, 30, 30),
	},
	{
		id = "captain_noodle",
		name = "Captain Noodle",
		blurb = "Sails a bowl of broth. Never tangles, always delivers.",
		rarity = "Rare",
		cost = 450,
		incomePerSecond = 7,
		weight = 18,
		bodyColor = Color3.fromRGB(245, 215, 130),
		accentColor = Color3.fromRGB(40, 90, 160),
	},
	{
		id = "professor_waffle",
		name = "Professor Waffle",
		blurb = "Lectures in syrup. His grid is flawless and his grants are huge.",
		rarity = "Rare",
		cost = 800,
		incomePerSecond = 12,
		weight = 12,
		bodyColor = Color3.fromRGB(205, 145, 70),
		accentColor = Color3.fromRGB(255, 240, 200),
	},
	{
		id = "turbo_taco_cat",
		name = "Turbo Taco Cat",
		blurb = "Half taco, half cat, all speed. Leaves crumbs at 200 km/h.",
		rarity = "Epic",
		cost = 1800,
		incomePerSecond = 28,
		weight = 7,
		bodyColor = Color3.fromRGB(240, 190, 60),
		accentColor = Color3.fromRGB(220, 90, 60),
	},
	{
		id = "queen_boba",
		name = "Queen Boba",
		blurb = "Rules the tea kingdom from a pearl throne. Sips, earns, repeats.",
		rarity = "Epic",
		cost = 3500,
		incomePerSecond = 55,
		weight = 4,
		bodyColor = Color3.fromRGB(210, 160, 120),
		accentColor = Color3.fromRGB(60, 40, 40),
	},
	{
		id = "lord_dumpling",
		name = "Lord Dumpling",
		blurb = "A steamed noble with a folding-fan fortune. Bows only to money.",
		rarity = "Legendary",
		cost = 8000,
		incomePerSecond = 130,
		weight = 2,
		bodyColor = Color3.fromRGB(250, 235, 200),
		accentColor = Color3.fromRGB(200, 60, 60),
	},
	{
		id = "cosmic_ramen_dragon",
		name = "Cosmic Ramen Dragon",
		blurb = "Slurps stars, breathes broth. The rarest catch in the Meadow.",
		rarity = "Mythic",
		cost = 20000,
		incomePerSecond = 350,
		weight = 1,
		bodyColor = Color3.fromRGB(140, 90, 220),
		accentColor = Color3.fromRGB(255, 220, 80),
	},
}

Characters.MUTATIONS = {
	{ id = "none", name = "", multiplier = 1, weight = 70, color = nil },
	{ id = "golden", name = "Golden", multiplier = 2, weight = 18, color = Color3.fromRGB(255, 210, 60) },
	{ id = "frozen", name = "Frozen", multiplier = 3, weight = 7, color = Color3.fromRGB(140, 210, 255) },
	{ id = "spicy", name = "Spicy", multiplier = 4, weight = 4, color = Color3.fromRGB(255, 90, 40) },
	{ id = "rainbow", name = "Rainbow", multiplier = 5, weight = 1, color = Color3.fromRGB(255, 120, 200) },
}

function Characters.byId(id: string)
	for _, c in ipairs(Characters.LIST) do
		if c.id == id then
			return c
		end
	end
	return nil
end

local function pickWeighted(entries)
	local total = 0
	for _, e in ipairs(entries) do
		total += e.weight
	end
	local roll = math.random(1, total)
	for _, e in ipairs(entries) do
		roll -= e.weight
		if roll <= 0 then
			return e
		end
	end
	return entries[1]
end

function Characters.rollCharacter()
	return pickWeighted(Characters.LIST)
end

function Characters.rollMutation()
	return pickWeighted(Characters.MUTATIONS)
end

return Characters
