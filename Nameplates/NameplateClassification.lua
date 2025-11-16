-- Nameplate classification module
local addon = cfFrames

-- Don't load if module is disabled
if not cfFramesDB[addon.MODULES.NAMEPLATE_CLASSIFICATION] then return end

-- Update nameplate classification icon
local function UpdateClassification(frame, unit)
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

-- Register nameplate creation event
local classFrame = CreateFrame("Frame")
classFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
classFrame:SetScript("OnEvent", function(self, event, unitID)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitID)
    UpdateClassification(nameplate.UnitFrame, unitID)
end)
