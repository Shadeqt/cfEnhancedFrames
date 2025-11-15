-- Nameplate threat glow module
local addon = cfFrames

-- Update nameplate threat glow
function addon.UpdateNameplateThreatGlow(frame, unit)
    -- Only show threat when in group/raid or have a pet (threat is meaningless when solo without pet)
    if not (IsInGroup() or IsInRaid() or UnitExists("pet")) then
        if frame.cfThreatGlow then frame.cfThreatGlow:Hide() end
        return
    end

    local threatStatus = UnitThreatSituation("player", unit)
    -- Hide if no threat
    if not threatStatus or threatStatus == 0 then
        if frame.cfThreatGlow then frame.cfThreatGlow:Hide() end
        return
    end

    -- Create glow texture if needed
    if not frame.cfThreatGlow then
        local parent = frame.healthBar.border or frame.healthBar
        frame.cfThreatGlow = parent:CreateTexture(nil, "BACKGROUND")
        frame.cfThreatGlow:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Flash")
        frame.cfThreatGlow:SetPoint("CENTER", parent, "CENTER", 0, 1)
        frame.cfThreatGlow:SetSize(144, 28)
        frame.cfThreatGlow:SetTexCoord(0, 144/256, 270/512, 302/512)
    end

    -- Update color and show
    local r, g, b = unpack(addon.THREAT_COLORS[threatStatus])
    frame.cfThreatGlow:SetVertexColor(r, g, b)
    frame.cfThreatGlow:Show()
end

-- Register events for real-time threat updates
local frame = CreateFrame("Frame")
frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
frame:SetScript("OnEvent", function(self, event, unitID)
    if not unitID or not string.match(unitID, "nameplate%d") then return end

    local nameplate = C_NamePlate.GetNamePlateForUnit(unitID)
    if nameplate and nameplate.UnitFrame then
        addon.UpdateNameplateThreatGlow(nameplate.UnitFrame, unitID)
    end
end)
