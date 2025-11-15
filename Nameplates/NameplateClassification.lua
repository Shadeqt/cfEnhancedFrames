-- Nameplate classification module
local addon = cfFrames

-- Update nameplate classification icon
function addon.UpdateNameplateClassification(frame, unit)
    local classification = UnitClassification(unit)
    local isElite = classification == addon.CLASSIFICATIONS.ELITE or classification == addon.CLASSIFICATIONS.WORLDBOSS
    local isRare = classification == addon.CLASSIFICATIONS.RARE or classification == addon.CLASSIFICATIONS.RAREELITE

    if not (isElite or isRare) then
        if frame.cfClassification then frame.cfClassification:Hide() end
        return
    end

    -- Create texture if needed
    if not frame.cfClassification then
        frame.cfClassification = frame.healthBar:CreateTexture(nil, "OVERLAY")
        frame.cfClassification:SetSize(64, 32)
        frame.cfClassification:SetPoint("LEFT", frame.healthBar, "RIGHT", -5, -3)
    end

    -- Set appropriate texture: gold for elite, silver for rare
    frame.cfClassification:SetTexture(isElite
        and "Interface\\Tooltips\\EliteNameplateIcon"
        or "Interface\\Tooltips\\RareEliteNameplateIcon"
    )
    frame.cfClassification:Show()
end
