-- Nameplate threat glow module
local addon = cfFrames

-- Don't load if module is disabled
if not cfFramesDB[addon.MODULES.NAMEPLATE_THREAT_GLOW] then return end

-- Calculate glow dimensions based on healthBar size (hybrid: fixed + proportional scaling)
local function CalculateGlowSize(healthBar)
    local hpWidth, hpHeight = healthBar:GetSize()
    local glowWidth = hpWidth + 25 + (hpWidth * 0.15)
    local glowHeight = hpHeight + 20 + (hpHeight * 0.15)
    return glowWidth, glowHeight
end

-- Update nameplate threat glow
local function UpdateThreatGlow(unitID)
    -- Filter out players
    if UnitIsPlayer(unitID) then return end

    -- Filter out non-hostile units
    local reaction = UnitReaction(unitID, "player")
    if reaction and reaction > addon.UNIT_REACTION.NEUTRAL_HOSTILE then return end

    -- Get nameplate frame
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitID)
    if not nameplate or not nameplate.UnitFrame then return end

    local frame = nameplate.UnitFrame

    -- Only show threat when in group/raid or have a pet (threat is meaningless when solo without pet)
    if not (IsInGroup() or IsInRaid() or UnitExists("pet")) then
        if frame.cfThreatGlow then frame.cfThreatGlow:Hide() end
        return
    end

    local threatStatus = UnitThreatSituation("player", unitID)
    -- Hide if no threat
    if not threatStatus or threatStatus == addon.THREAT_STATUS.NONE then
        if frame.cfThreatGlow then frame.cfThreatGlow:Hide() end
        return
    end

    local parent = frame.healthBar
    -- Create glow texture if needed
    if not frame.cfThreatGlow then
        frame.cfThreatGlow = parent:CreateTexture(nil, "BACKGROUND")
        frame.cfThreatGlow:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash")
        frame.cfThreatGlow:SetPoint("CENTER", parent, "CENTER", 9, 1)
        frame.cfThreatGlow:SetTexCoord(0, 144/256, 270/512, 302/512)
    end

    -- Dynamically size the glow based on healthBar dimensions
    local glowWidth, glowHeight = CalculateGlowSize(parent)
    frame.cfThreatGlow:SetSize(glowWidth, glowHeight)

    -- Update color and show
    local r, g, b = unpack(addon.THREAT_COLORS[threatStatus])
    frame.cfThreatGlow:SetVertexColor(r, g, b)
    frame.cfThreatGlow:Show()
end

-- Register threat update events
local threatFrame = CreateFrame("Frame")
threatFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
threatFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
threatFrame:SetScript("OnEvent", function(self, event, unitID)
    -- Only validate nameplate pattern for UNIT_THREAT_LIST_UPDATE
    if event == "UNIT_THREAT_LIST_UPDATE" then
        if not unitID or not string.find(unitID, "nameplate%d") then return end
    end

    UpdateThreatGlow(unitID)
end)
