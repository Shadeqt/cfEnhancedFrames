local addon = cfFrames

-- State
local tickFrame
local spark
local previousMana = 0
local manaTickTime = 0
local gainingMana = false
local fiveSecRuleEnd = 0

local TICK_INTERVAL = 2
local FIVE_SEC_RULE = 5

-- Create the tick indicator overlay
local function SetupTickBar()
    tickFrame = CreateFrame("StatusBar", nil, PlayerFrameManaBar)
    tickFrame:SetAllPoints(PlayerFrameManaBar)
    tickFrame:SetMinMaxValues(0, TICK_INTERVAL)
    tickFrame:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    tickFrame:SetStatusBarColor(0, 0, 0, 0)

    spark = tickFrame:CreateTexture(nil, "OVERLAY")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetWidth(16)
    spark:SetBlendMode("ADD")
    spark:SetVertexColor(1, 1, 1)

    tickFrame:Hide()
end

-- Update spark position
local function UpdateSparkPosition(self, elapsed)
    local now = GetTime()

    if now >= manaTickTime then
        manaTickTime = now + TICK_INTERVAL
    end

    local remaining = manaTickTime - now
    local progress = 1 - (remaining / TICK_INTERVAL)
    local sparkPos = PlayerFrameManaBar:GetWidth() * progress

    spark:ClearAllPoints()
    spark:SetPoint("CENTER", tickFrame, "LEFT", sparkPos, 0)
    spark:SetHeight(PlayerFrameManaBar:GetHeight() * 2)
end

-- Handle mana changes
local function OnPowerUpdate(self, event, unit, powerType)
    if unit ~= "player" or powerType ~= "MANA" then return end

    local now = GetTime()
    local currentMana = UnitPower("player", 0)

    print("ResourceTicker: Power update - current:", currentMana, "previous:", previousMana)

    -- Mana decreased = spell cast, start 5SR
    if currentMana < previousMana then
        print("ResourceTicker: Mana spent, starting 5SR")
        gainingMana = false
        fiveSecRuleEnd = now + FIVE_SEC_RULE
        tickFrame:Hide()
        tickFrame:SetScript("OnUpdate", nil)

    -- Check if 5SR ended
    elseif not gainingMana and now >= fiveSecRuleEnd then
        print("ResourceTicker: 5SR ended, starting tick tracking")
        gainingMana = true
        manaTickTime = now + TICK_INTERVAL
    end

    -- Mana increased while gaining = tick detected
    if gainingMana and currentMana > previousMana then
        print("ResourceTicker: Tick detected! Showing spark")
        manaTickTime = now + TICK_INTERVAL
        tickFrame:Show()
        tickFrame:SetScript("OnUpdate", UpdateSparkPosition)
    end

    previousMana = currentMana
end

-- Module initialization
addon:RegisterModuleInit(function()
    print("ResourceTicker: Init called")

    if not cfFramesDB[addon.MODULES.RESOURCE_TICKER] then
        print("ResourceTicker: Module disabled in config")
        return
    end

    print("ResourceTicker: Setting up tick bar")
    SetupTickBar()

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:SetScript("OnEvent", OnPowerUpdate)

    previousMana = UnitPower("player", 0)
    print("ResourceTicker: Initialized, initial mana:", previousMana)
end)
