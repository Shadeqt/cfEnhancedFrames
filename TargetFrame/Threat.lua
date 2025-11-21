local addon = cfFrames

-- Module-level state
local glow
local numeric
local numericText
local numericBackground

-- Hide all threat indicators
local function HideAll()
    glow:Hide()
    numeric:Hide()
end

-- Update numeric display
local function UpdateNumeric(r, g, b, isTanking, rawThreatPercent)
    -- If tanking, show percentage ahead of second-highest threat
    if isTanking then
        rawThreatPercent = UnitThreatPercentageOfLead("player", "target")
    end

    if not rawThreatPercent or rawThreatPercent <= 0 then
        numeric:Hide()
        return
    end

    numericText:SetFormattedText("%.0f%%", rawThreatPercent)
    numericBackground:SetVertexColor(r, g, b)
    numeric:Show()
end

-- Update threat indicators
local function UpdateThreat()
    if not UnitExists("target") then
        HideAll()
        return
    end

    -- Only show threat when in group/raid or have a pet (threat is meaningless when solo without pet)
    if not (IsInGroup() or IsInRaid() or UnitExists("pet")) then
        HideAll()
        return
    end

    local isTanking, threatStatus, _threatPercent, rawThreatPercent = UnitDetailedThreatSituation("player", "target")

    if not threatStatus or threatStatus == addon.THREAT_STATUS.NONE then
        HideAll()
        return
    end

    local r, g, b = unpack(addon.THREAT_COLORS[threatStatus])

    if cfFramesDB[addon.MODULES.THREAT_GLOW] then
        glow:SetVertexColor(r, g, b)
        glow:Show()
    end

    if cfFramesDB[addon.MODULES.THREAT_NUMERIC] then
        UpdateNumeric(r, g, b, isTanking, rawThreatPercent)
    end
end

-- Create UI elements
local function SetupThreatUI()
    -- Create glow texture
    glow = TargetFrame:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash")
    glow:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", -24, 0)
    glow:SetSize(242, 93)
    glow:SetTexCoord(0, 0.9453125, 0, 0.181640625)
    glow:Hide()

    -- Create numeric threat frame
    numeric = CreateFrame("Frame", nil, TargetFrame)
    numeric:SetSize(49, 18)
    numeric:SetPoint("BOTTOM", TargetFrame, "TOP", -50, -22)
    numeric:Hide()

    numericBackground = numeric:CreateTexture(nil, "BACKGROUND")
    numericBackground:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    numericBackground:SetSize(37, 14)
    numericBackground:SetPoint("TOP", numeric, "TOP", 0, -3)

    local border = numeric:CreateTexture(nil, "ARTWORK")
    border:SetTexture("Interface\\TargetingFrame\\NumericThreatBorder")
    border:SetTexCoord(0, 0.765625, 0, 0.5625)
    border:SetAllPoints(numeric)

    numericText = numeric:CreateFontString(nil, "BACKGROUND", "TextStatusBarText")
    numericText:SetDrawLayer("BACKGROUND", 1)
    numericText:SetPoint("TOP", numeric, "TOP", 0, -4)
end

-- Module initialization
addon:RegisterModuleInit(function()
    if not cfFramesDB[addon.MODULES.THREAT_GLOW] and not cfFramesDB[addon.MODULES.THREAT_NUMERIC] then return end

    SetupThreatUI()
    
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
    frame:SetScript("OnEvent", UpdateThreat)
end)
