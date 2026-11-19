-- Shared tuning for Snack Sprint: Brainrot Meadow.

local Config = {}

Config.START_MONEY = 250
Config.BASE_SLOTS = 8
Config.MAX_BASES = 8
Config.CONVEYOR_LENGTH = 160
Config.CONVEYOR_SPEED = 10 -- studs per second (normal)
Config.CONVEYOR_STORM_SPEED = 18 -- studs per second during a Pickle Storm
Config.SPAWN_INTERVAL = 4 -- seconds between conveyor spawns (normal)
Config.SPAWN_INTERVAL_STORM = 2.5
Config.INCOME_TICK = 1 -- seconds between income payouts
Config.STEAL_COOLDOWN = 20 -- seconds before the same character can be stolen again
Config.SLAP_COOLDOWN = 10 -- seconds between slaps
Config.SLAP_STUN = 3 -- seconds a slapped thief is stunned (drops the catch)
Config.REBIRTH_BASE_COST = 5000 -- x (rebirths + 1)
Config.REBIRTH_BONUS = 0.25 -- +25% income per rebirth
Config.STORM_EVERY = 180 -- seconds between Pickle Storms
Config.STORM_LENGTH = 20 -- seconds a storm lasts
Config.SELL_REFUND = 0.5 -- selling a character refunds half its cost

return Config
