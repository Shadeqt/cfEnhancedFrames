local addon = cfFrames

-- State
local tickFrame
local spark
local previousMana = 0
local timerEndTime = 0
local isInFSR = false  -- true = FSR countdown, false = tick tracking
local currentInterval = 2
local manaBarWidth
local manaBarHeight

local TICK_INTERVAL = 2
local FIVE_SEC_RULE = 5

local function SetMode(inFSR, now)
    isInFSR = inFSR
    currentInterval = inFSR and FIVE_SEC_RULE or TICK_INTERVAL
    timerEndTime = now + currentInterval
end

-- Create the tick indicator overlay
local function SetupTickBar()
    tickFrame = CreateFrame("Frame", nil, PlayerFrameManaBar)
    tickFrame:SetAllPoints(PlayerFrameManaBar)

    spark = tickFrame:CreateTexture(nil, "OVERLAY")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetWidth(16)
    spark:SetBlendMode("ADD")
    spark:SetVertexColor(1, 1, 1)

    tickFrame:Hide()

    -- Cache dimensions
    manaBarWidth = PlayerFrameManaBar:GetWidth()
    manaBarHeight = PlayerFrameManaBar:GetHeight()
end

-- Update spark position
local function UpdateSparkPosition(self, elapsed)
    local now = GetTime()
    local currentMana = UnitPower("player", 0)
    local maxMana = UnitPowerMax("player", 0)

    -- Hide if at full mana
    if currentMana >= maxMana then
        self:Hide()
        self:SetScript("OnUpdate", nil)
        return
    end

    if timerEndTime == 0 then return end

    -- Check for timer expiration
    if now >= timerEndTime then
        SetMode(false, now)
    end

    -- Unified progress calculation
    local remaining = timerEndTime - now
    local progress = isInFSR
        and (remaining / currentInterval)  -- FSR: counts down
        or (1 - remaining / currentInterval)  -- Tick: counts up

    local sparkPos = manaBarWidth * progress

    spark:ClearAllPoints()
    spark:SetPoint("CENTER", self, "LEFT", sparkPos, 0)
    spark:SetHeight(manaBarHeight * 3)
end

-- Handle mana changes
local function OnPowerUpdate(self, event, unit, powerType)
    if unit ~= "player" then return end
    if powerType ~= "MANA" then return end

    local now = GetTime()
    local currentMana = UnitPower("player", 0)
    local manaDelta = currentMana - previousMana

    -- Mana decreased = spell cast, start FSR
    if manaDelta < 0 then
        SetMode(true, now)
        self:Show()
        self:SetScript("OnUpdate", UpdateSparkPosition)

    -- Mana increased during tick mode = tick detected, reset timer
    elseif not isInFSR and manaDelta > 0 then
        SetMode(false, now)
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
