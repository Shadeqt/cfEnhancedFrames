-- Nameplate health numbers module
local addon = cfFrames

-- Update nameplate health text
local function UpdateHealth(frame, unit)
    -- Create text frame if it doesn't exist
    if not frame.cfHealthText then
        frame.cfHealthText = frame.healthBar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
        frame.cfHealthText:SetFont("Fonts\\FRIZQT__.TTF", 9, "THICKOUTLINE")
        frame.cfHealthText:SetPoint("TOP", frame.healthBar, "TOP", 0, -1)
        frame.cfHealthText:SetJustifyH("CENTER")
    end

    -- Update HP
    local health = UnitHealth(unit)
    frame.cfHealthText:SetText(health)
    frame.cfHealthText:Show()
end

-- Initialize module (called after SavedVariables load)
local function Initialize()
    -- Don't load if module is disabled
    if not cfFramesDB[addon.MODULES.NAMEPLATE_HEALTH] then return end

    -- Hook health updates
    hooksecurefunc("CompactUnitFrame_UpdateHealth", function(frame)
        local unit = frame.displayedUnit
        -- Filter out players
        if UnitIsPlayer(unit) then
            if frame.cfHealthText then frame.cfHealthText:Hide() end
            return
        end

        -- Filter out non-hostile units
        local reaction = UnitReaction(unit, "player")
        if not reaction or reaction > addon.UNIT_REACTION.NEUTRAL_HOSTILE then
            if frame.cfHealthText then frame.cfHealthText:Hide() end
            return
        end

        UpdateHealth(frame, unit)
    end)
end

-- Register initialization callback
addon:RegisterModuleInit(Initialize)
