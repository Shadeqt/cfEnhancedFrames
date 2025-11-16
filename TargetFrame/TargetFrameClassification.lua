local addon = cfFrames

-- Hook handler: apply rare-elite texture when classification matches
local function OnCheckClassification(self, lock)
    if self ~= TargetFrame then return end
    if lock then return end
    if UnitClassification(self.unit) ~= addon.CLASSIFICATIONS.RAREELITE then return end

    self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite")
end

-- Module initialization
addon:RegisterModuleInit(function()
    if not cfFramesDB[addon.MODULES.RARE_ELITE] then return end

    hooksecurefunc("TargetFrame_CheckClassification", OnCheckClassification)
end)
