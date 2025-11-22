local addon = cfFrames

-- Constants: WoW server tick rate and Five Second Rule duration
local TICK_INTERVAL = 2
local FSR_DURATION = 5

-- State: track power changes and timer endpoints
local previousPower = 0
local fsrEndTime = 0
local tickEndTime = 0
local powerType = 0
local powerToken = "MANA"

-- Create spark overlay frame for the mana/energy bar
local function SetupTickBar()
    local frame = CreateFrame("Frame", nil, PlayerFrameManaBar)
    frame:SetAllPoints(PlayerFrameManaBar)

    local spark = frame:CreateTexture(nil, "OVERLAY")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetWidth(16)
    spark:SetBlendMode("ADD")

    frame.spark = spark
    frame.manaBarWidth = PlayerFrameManaBar:GetWidth()
    frame.sparkHeight = PlayerFrameManaBar:GetHeight() * 3
    frame:Hide()
    return frame
end

-- Calculate tick progress with automatic timer reset fallback
local function CalculateTickProgress(currentTime)
    if tickEndTime <= currentTime then
        tickEndTime = currentTime + TICK_INTERVAL
        return 0
    end
    return 1 - ((tickEndTime - currentTime) / TICK_INTERVAL)
end

-- Update spark position every frame based on current timers
local function OnUpdate(self, elapsed)
    local currentTime = GetTime()
    local currentPower = UnitPower("player", powerType)
    local maxPower = UnitPowerMax("player", powerType)

    local sparkProgress = 0

    -- Energy users: always show tick progress (even at full energy)
    if powerToken == "ENERGY" then
        sparkProgress = CalculateTickProgress(currentTime)
    -- Mana users: handle FSR countdown and tick tracking
    elseif powerToken == "MANA" then
        -- During FSR: show countdown from 5 to 0 seconds
        if fsrEndTime > currentTime then
            sparkProgress = (fsrEndTime - currentTime) / FSR_DURATION
        -- After FSR: show tick progress until mana is full
        elseif currentPower < maxPower and tickEndTime > 0 then
            sparkProgress = CalculateTickProgress(currentTime)
        -- Mana is full: hide ticker
        else
            self:Hide()
            return
        end
    end

    local sparkPosition = self.manaBarWidth * sparkProgress
    self.spark:ClearAllPoints()
    self.spark:SetPoint("CENTER", self, "LEFT", sparkPosition, 0)
    self.spark:SetHeight(self.sparkHeight)
end

-- Update power type and initialize ticker for energy users
local function UpdatePowerType(frame)
    powerType, powerToken = UnitPowerType("player")
    if powerToken ~= "MANA" and powerToken ~= "ENERGY" then return end

    previousPower = UnitPower("player", powerType)

    if powerToken ~= "ENERGY" then return end
    tickEndTime = GetTime() + TICK_INTERVAL
    frame:Show()
end

-- Handle power changes: detect mana spending (FSR) and power gains (ticks)
local function OnPowerUpdate(self, event, eventPowerToken)
    if eventPowerToken ~= powerToken then return end

    local currentTime = GetTime()
    local currentPower = UnitPower("player", powerType)
    local powerDelta = currentPower - previousPower

    -- Mana spent: start Five Second Rule countdown
    if powerToken == "MANA" and powerDelta < 0 then
        fsrEndTime = currentTime + FSR_DURATION
        tickEndTime = 0
        self:Show()
    end

    -- Power gained: synchronize tick timer with actual server tick
    if powerDelta > 0 then
        tickEndTime = currentTime + TICK_INTERVAL
        -- Only show if not during FSR (mana users only)
        if fsrEndTime <= currentTime then
            self:Show()
        end
    end

    previousPower = currentPower
end

-- Handle power type changes (druid shapeshifting)
local function OnDisplayPowerChanged(self, event)
    UpdatePowerType(self)
end

addon:RegisterModuleInit(function()
    if not cfFramesDB[addon.MODULES.POWER_TICKER] then return end

    local frame = SetupTickBar()
    frame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
    frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_POWER_UPDATE" then
            local unit, eventPowerToken = ...
            OnPowerUpdate(self, event, eventPowerToken)
        elseif event == "UNIT_DISPLAYPOWER" then
            OnDisplayPowerChanged(self, event, ...)
        end
    end)
    frame:SetScript("OnUpdate", OnUpdate)

    UpdatePowerType(frame)
end)
