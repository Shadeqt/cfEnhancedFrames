-- Nameplate core hook - central point for all nameplate updates
local db = cfFramesDB
local addon = cfFrames

-- Don't load if no nameplate modules are enabled
if not db[addon.MODULES.NAMEPLATE_HEALTH]
    and not db[addon.MODULES.NAMEPLATE_CLASSIFICATION]
    and not db[addon.MODULES.NAMEPLATE_THREAT_GLOW] then
    return
end

-- Single hook for all nameplate updates
hooksecurefunc("CompactUnitFrame_UpdateHealth", function(frame)
    if not frame then return end
    if not frame.displayedUnit then return end
    if not frame.healthBar then return end

    local unit = frame.displayedUnit

    -- Filter out players
    if UnitIsPlayer(unit) then
        -- Hide all module elements for players
        if frame.cfHealthText then frame.cfHealthText:Hide() end
        if frame.cfClassification then frame.cfClassification:Hide() end
        if frame.cfThreatGlow then frame.cfThreatGlow:Hide() end
        return
    end

    if db[addon.MODULES.NAMEPLATE_CLASSIFICATION] and addon.UpdateNameplateClassification then
        addon.UpdateNameplateClassification(frame, unit)
    end

    local reaction = UnitReaction(unit, "player")
    -- Only show for enemy nameplates (1-3)
    if not reaction or reaction > 4 then
        if frame.cfThreatGlow then frame.cfThreatGlow:Hide() end
        return
    end

        -- Call enabled module functions (each gets data it needs)
    if db[addon.MODULES.NAMEPLATE_HEALTH] and addon.UpdateNameplateHealth then
        addon.UpdateNameplateHealth(frame, unit)
    end

    if db[addon.MODULES.NAMEPLATE_THREAT_GLOW] and addon.UpdateNameplateThreatGlow then
        addon.UpdateNameplateThreatGlow(frame, unit)
    end
end)
