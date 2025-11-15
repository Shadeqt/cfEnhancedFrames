-- Nameplate health numbers module
local addon = cfEnhancedFrames

-- Update nameplate health text
function addon.UpdateNameplateHealth(frame, unit)
    -- Create text frame if it doesn't exist
    if not frame.cfHealthText then
        frame.cfHealthText = frame.healthBar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
        frame.cfHealthText:SetPoint("TOP", frame.healthBar, "TOP", 0, 2)
        frame.cfHealthText:SetJustifyH("CENTER")
    end

    -- Update HP
    local health = UnitHealth(unit)
    frame.cfHealthText:SetText(health)
    frame.cfHealthText:Show()
end
