-- Check if either threat module is enabled
local db = cfFramesDB
local addon = cfFrames

if not db[addon.MODULES.THREAT_GLOW] and not db[addon.MODULES.THREAT_NUMERIC] then return end

-- Create glow texture
local glow = TargetFrame:CreateTexture(nil, "BACKGROUND")
glow:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash")
glow:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", -24, 0)
glow:SetSize(242, 93)
glow:SetTexCoord(0, 0.9453125, 0, 0.181640625)
glow:Hide()

-- Create numeric threat frame
local numeric = CreateFrame("Frame", nil, TargetFrame)
numeric:SetSize(49, 18)
numeric:SetPoint("BOTTOM", TargetFrame, "TOP", -50, -22)
numeric:Hide()

local background = numeric:CreateTexture(nil, "BACKGROUND")
background:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
background:SetSize(37, 14)
background:SetPoint("TOP", numeric, "TOP", 0, -3)

local border = numeric:CreateTexture(nil, "ARTWORK")
border:SetTexture("Interface\\TargetingFrame\\NumericThreatBorder")
border:SetTexCoord(0, 0.765625, 0, 0.5625)
border:SetAllPoints(numeric)

local text = numeric:CreateFontString(nil, "BACKGROUND", "TextStatusBarText")
text:SetDrawLayer("BACKGROUND", 1)
text:SetPoint("TOP", numeric, "TOP", 0, -4)

local function HideAll()
    glow:Hide()
    numeric:Hide()
end

-- Update glow display
local function UpdateGlow(r, g, b)
    glow:SetVertexColor(r, g, b)
    glow:Show()
end

-- Update numeric display
local function UpdateNumeric(r, g, b, tanking, percent)
    if tanking then
        percent = UnitThreatPercentageOfLead("player", "target")
    end

    if not percent or percent <= 0 then
        numeric:Hide()
        return
    end

    text:SetFormattedText("%.0f%%", percent)
    background:SetVertexColor(r, g, b)
    numeric:Show()
end

-- Update function
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

    local tanking, status, _, percent = UnitDetailedThreatSituation("player", "target")

    if not status or status == 0 then
        HideAll()
        return
    end

    local r, g, b = unpack(addon.THREAT_COLORS[status])

    if db[addon.MODULES.THREAT_GLOW] then
        UpdateGlow(r, g, b)
    end

    if db[addon.MODULES.THREAT_NUMERIC] then
        UpdateNumeric(r, g, b, tanking, percent)
    end
end

-- Register events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
frame:SetScript("OnEvent", UpdateThreat)
