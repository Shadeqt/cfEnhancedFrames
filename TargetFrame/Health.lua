local addon = cfFrames

-- Module-level state
local TextObjects

-- Create and configure text objects for health and mana bars
local function SetupTextObjects()
    TextObjects = {
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

    -- Set anchors (relative to TargetFrameTextureFrame)
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
end

-- Hook handler: disable showPercentage to prevent default percentage display
local function OnHealthBarUpdate(statusbar, unit)
    if TextObjects[statusbar] and statusbar.showPercentage then
        statusbar.showPercentage = false
        TextStatusBar_UpdateTextString(statusbar)
    end
end

-- Module initialization
addon:RegisterModuleInit(function()
    if not cfFramesDB[addon.MODULES.TARGET_HEALTH] then return end

    SetupTextObjects()
    
    hooksecurefunc("UnitFrameHealthBar_Update", OnHealthBarUpdate)
end)
