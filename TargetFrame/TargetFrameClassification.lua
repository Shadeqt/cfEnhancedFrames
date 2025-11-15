-- Check if module is enabled
local db = cfFramesDB
local addon = cfFrames

if not db[addon.MODULES.RARE_ELITE] then return end

-- Hook TargetFrame_CheckClassification to apply rare-elite texture
hooksecurefunc("TargetFrame_CheckClassification", function(self, lock)
    if self ~= TargetFrame then return end
    if lock then return end
    if UnitClassification(self.unit) ~= addon.CLASSIFICATIONS.RAREELITE then return end

    self.borderTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite")
end)
