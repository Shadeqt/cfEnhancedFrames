-- Check if module is enabled
local db = cfFramesDB
local addon = cfFrames

if not db[addon.MODULES.TARGET_HEALTH] then return end

-- Create text objects for health and mana bars
local TextObjects = {
    [TargetFrameHealthBar] = {
        TextString = TargetFrameTextureFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText"),
        LeftText = TargetFrameTextureFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText"),
        RightText = TargetFrameTextureFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
    },
    [TargetFrameManaBar] = {
        TextString = TargetFrameTextureFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText"),
        LeftText = TargetFrameTextureFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText"),
        RightText = TargetFrameTextureFrame:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
    }
}

-- Set anchors (relative to TargetFrameTextureFrame, matching ModernTargetFrame positioning)
TextObjects[TargetFrameHealthBar].TextString:SetPoint("CENTER", TargetFrameTextureFrame, "CENTER", -50, 3)
TextObjects[TargetFrameHealthBar].LeftText:SetPoint("LEFT", TargetFrameTextureFrame, "LEFT", 8, 3)
TextObjects[TargetFrameHealthBar].RightText:SetPoint("RIGHT", TargetFrameTextureFrame, "RIGHT", -110, 3)

TextObjects[TargetFrameManaBar].TextString:SetPoint("CENTER", TargetFrameTextureFrame, "CENTER", -50, -8)
TextObjects[TargetFrameManaBar].LeftText:SetPoint("LEFT", TargetFrameTextureFrame, "LEFT", 8, -8)
TextObjects[TargetFrameManaBar].RightText:SetPoint("RIGHT", TargetFrameTextureFrame, "RIGHT", -110, -8)

-- Assign text objects to bars and initialize
for bar, texts in pairs(TextObjects) do
    for key, obj in pairs(texts) do
        bar[key] = obj
    end
    TextStatusBar_UpdateTextString(bar)
end

-- Hook UnitFrameHealthBar_Update to disable showPercentage (like ModernTargetFrame's HealthVisibilityPatch)
hooksecurefunc("UnitFrameHealthBar_Update", function(statusbar, unit)
    if TextObjects[statusbar] and statusbar.showPercentage then
        statusbar.showPercentage = false
        TextStatusBar_UpdateTextString(statusbar)
    end
end)
