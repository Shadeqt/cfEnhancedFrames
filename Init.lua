-- Create addon namespace
cfFrames = {}

-- Localize for performance and consistency
local db = cfFramesDB
local addon = cfFrames

-- Module definitions
addon.MODULES = {
    -- Target Frame modules
    TARGET_HEALTH = "TargetHealth",
    RARE_ELITE = "RareElite",
    THREAT_GLOW = "ThreatGlow",
    THREAT_NUMERIC = "ThreatNumeric",
    -- Nameplate modules
    NAMEPLATE_HEALTH = "NameplateHealth",
    NAMEPLATE_CLASSIFICATION = "NameplateClassification",
    NAMEPLATE_THREAT_GLOW = "NameplateThreatGlow",
}

-- Threat color definitions (used by ThreatIndicators and NameplateThreatGlow)
addon.THREAT_COLORS = {
    [0] = {0.69, 0.69, 0.69},   -- Gray: no threat
    [1] = {1, 1, 0.47},         -- Yellow: low threat
    [2] = {1, 0.6, 0},          -- Orange: gaining threat
    [3] = {1, 0, 0}             -- Red: high threat/tanking
}

-- Threat status constants (return values from UnitThreatSituation)
addon.THREAT_STATUS = {
    NONE = 0,       -- No threat / Not on threat table
    LOW = 1,        -- Low threat
    GAINING = 2,    -- Gaining threat / Close to tanking
    TANKING = 3     -- High threat / Tanking
}

-- Unit reaction constants (return values from UnitReaction)
addon.UNIT_REACTION = {
    HATED = 1,              -- Extremely hostile
    HOSTILE = 2,            -- Hostile
    UNFRIENDLY = 3,         -- Unfriendly
    NEUTRAL_HOSTILE = 4,    -- Neutral (attackable, e.g. yellow mobs/bosses)
    NEUTRAL = 5,            -- Neutral (non-hostile, e.g. critters)
    FRIENDLY = 6,           -- Friendly
    HONORED = 7,            -- Honored
    EXALTED = 8             -- Exalted
}

-- Classification type constants (used by NameplateClassification and RareElite)
addon.CLASSIFICATIONS = {
    NORMAL = "normal",
    RARE = "rare",
    ELITE = "elite",
    RAREELITE = "rareelite",
    WORLDBOSS = "worldboss",
    MINUS = "minus"
}

local dbDefaults = {
    [addon.MODULES.TARGET_HEALTH] = true,
    [addon.MODULES.RARE_ELITE] = true,
    [addon.MODULES.THREAT_GLOW] = true,
    [addon.MODULES.THREAT_NUMERIC] = true,
    [addon.MODULES.NAMEPLATE_HEALTH] = true,
    [addon.MODULES.NAMEPLATE_CLASSIFICATION] = true,
    [addon.MODULES.NAMEPLATE_THREAT_GLOW] = true,
}

-- Database initialization
if not db then
    db = {}
    cfFramesDB = db
end

-- Apply defaults for any missing keys
for key, value in pairs(dbDefaults) do
    if db[key] == nil then
        db[key] = value
    end
end

-- Remove keys from DB that aren't in defaults
for key in pairs(db) do
    if dbDefaults[key] == nil then
        db[key] = nil
    end
end

-- Module initialization callbacks
local initCallbacks = {}

-- Register a module initialization callback
function addon:RegisterModuleInit(callback)
    table.insert(initCallbacks, callback)
end

-- Initialize modules after ADDON_LOADED (when SavedVariables are available)
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "cfFrames" then return end
    self:UnregisterEvent("ADDON_LOADED")

    -- At this point, SavedVariables have overwritten cfFramesDB
    -- Now it's safe to initialize modules
    for _, callback in ipairs(initCallbacks) do
        callback()
    end
end)

