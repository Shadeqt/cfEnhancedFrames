local addon = cfFrames

-- State
local tickFrame
local spark
local previousMana = 0
local timerEndTime = 0
local isInFSR = false  -- true = FSR countdown, false = tick tracking

local TICK_INTERVAL = 2
local FIVE_SEC_RULE = 5

-- Create the tick indicator overlay
local function SetupTickBar()
    tickFrame = CreateFrame("StatusBar", nil, PlayerFrameManaBar)
    tickFrame:SetPoint("TOPLEFT", PlayerFrameManaBar, "TOPLEFT", 2, 0)
    tickFrame:SetPoint("BOTTOMRIGHT", PlayerFrameManaBar, "BOTTOMRIGHT", 2, 0)
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
    local currentMana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)

    -- Hide if at full mana
    if currentMana >= maxMana then
        tickFrame:Hide()
        tickFrame:SetScript("OnUpdate", nil)
        return
    end

    if timerEndTime == 0 then return end

    -- Check for timer expiration
    if now >= timerEndTime then
        isInFSR = false
        timerEndTime = now + TICK_INTERVAL
    end

    -- Unified progress calculation
    local remaining = timerEndTime - now
    local progress = isInFSR
        and (remaining / FIVE_SEC_RULE)  -- Reverse for FSR
        or (1 - remaining / TICK_INTERVAL)  -- Forward for tick

    local sparkPos = PlayerFrameManaBar:GetWidth() * progress

    spark:ClearAllPoints()
    spark:SetPoint("CENTER", tickFrame, "LEFT", sparkPos, 0)
    spark:SetHeight(PlayerFrameManaBar:GetHeight() * 3)
end

-- Handle mana changes
local function OnPowerUpdate(self, event, unit, powerType)
    if unit ~= "player" or powerType ~= "MANA" then return end

    local now = GetTime()
    local currentMana = UnitPower("player", 0)
    local manaDelta = currentMana - previousMana

    -- Mana decreased = spell cast, start FSR
    if manaDelta < 0 then
        isInFSR = true
        timerEndTime = now + FIVE_SEC_RULE
        tickFrame:Show()
        tickFrame:SetScript("OnUpdate", UpdateSparkPosition)

    -- Mana increased during tick mode = tick detected, reset timer
    elseif not isInFSR and manaDelta > 0 then
        timerEndTime = now + TICK_INTERVAL
    end

    previousMana = currentMana
end

-- Module initialization
addon:RegisterModuleInit(function()
    if not cfFramesDB[addon.MODULES.RESOURCE_TICKER] then return end

    SetupTickBar()
    tickFrame:RegisterEvent("UNIT_POWER_UPDATE")
    tickFrame:SetScript("OnEvent", OnPowerUpdate)

    previousMana = UnitPower("player", 0)
end)
