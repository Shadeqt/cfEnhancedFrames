-- Localize for performance and consistency
local db = cfFramesDB
local addon = cfFrames

-- Module-level state
local pendingState = nil
local allCheckboxes = {}

-- Initialization code
local panel = CreateFrame("Frame", "cfFramesPanel")
panel.name = "cfFrames"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("cfFrames Settings")

-- Helper function to create a checkbox
local function createCheckbox(parent, anchorTo, xOffset, yOffset, moduleName, labelText)
    local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    check:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", xOffset, yOffset)
    check.Text:SetText(labelText)
    check.moduleName = moduleName
    return check
end

-- UI Element Creation
-- Target Frame header
local targetHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
targetHeader:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
targetHeader:SetText("|cffFFD700Target Frame:|r")

allCheckboxes.targetHealth = createCheckbox(panel, targetHeader, 0, -8, addon.MODULES.TARGET_HEALTH, "Health/Mana Numbers")
allCheckboxes.rareElite = createCheckbox(panel, allCheckboxes.targetHealth, 0, -8, addon.MODULES.RARE_ELITE, "Rare-Elite Border Texture")
allCheckboxes.threatGlow = createCheckbox(panel, allCheckboxes.rareElite, 0, -8, addon.MODULES.THREAT_GLOW, "Threat Glow (colored border)")
allCheckboxes.threatNumeric = createCheckbox(panel, allCheckboxes.threatGlow, 0, -8, addon.MODULES.THREAT_NUMERIC, "Threat Numeric (percentage display)")

-- Nameplates header
local nameplateHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
nameplateHeader:SetPoint("TOPLEFT", allCheckboxes.threatNumeric, "BOTTOMLEFT", 0, -16)
nameplateHeader:SetText("|cffFFD700Nameplates:|r")

allCheckboxes.nameplateHealth = createCheckbox(panel, nameplateHeader, 0, -8, addon.MODULES.NAMEPLATE_HEALTH, "Health/Power Text")
allCheckboxes.nameplateClassification = createCheckbox(panel, allCheckboxes.nameplateHealth, 0, -8, addon.MODULES.NAMEPLATE_CLASSIFICATION, "Rare-Elite Texture")
allCheckboxes.nameplateThreatGlow = createCheckbox(panel, allCheckboxes.nameplateClassification, 0, -8, addon.MODULES.NAMEPLATE_THREAT_GLOW, "Threat Glow")

-- Reload UI button and warning text
local reloadBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
reloadBtn:SetPoint("TOPLEFT", allCheckboxes.nameplateThreatGlow, "BOTTOMLEFT", 0, -16)
reloadBtn:SetSize(120, 25)
reloadBtn:SetText("Reload UI")
reloadBtn:SetScript("OnClick", function()
    -- Commit pending changes to database
    for key, value in pairs(pendingState) do
        cfFramesDB[key] = value
    end
    ReloadUI()
end)

local warning = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
warning:SetPoint("LEFT", reloadBtn, "RIGHT", 8, 0)
warning:SetText("|cffFF6600Click 'Reload UI' to apply changes|r")

local info = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
info:SetPoint("TOPLEFT", reloadBtn, "BOTTOMLEFT", 4, -8)
info:SetText("Type |cffFFFF00/cfef|r to open this panel")

-- Function to initialize checkboxes from database
local function initializeCheckboxes()
    -- Copy database to pending state
    pendingState = {
        [addon.MODULES.TARGET_HEALTH] = cfFramesDB[addon.MODULES.TARGET_HEALTH],
        [addon.MODULES.RARE_ELITE] = cfFramesDB[addon.MODULES.RARE_ELITE],
        [addon.MODULES.THREAT_GLOW] = cfFramesDB[addon.MODULES.THREAT_GLOW],
        [addon.MODULES.THREAT_NUMERIC] = cfFramesDB[addon.MODULES.THREAT_NUMERIC],
        [addon.MODULES.NAMEPLATE_HEALTH] = cfFramesDB[addon.MODULES.NAMEPLATE_HEALTH],
        [addon.MODULES.NAMEPLATE_CLASSIFICATION] = cfFramesDB[addon.MODULES.NAMEPLATE_CLASSIFICATION],
        [addon.MODULES.NAMEPLATE_THREAT_GLOW] = cfFramesDB[addon.MODULES.NAMEPLATE_THREAT_GLOW],
    }

    -- Configure each checkbox
    for _, check in pairs(allCheckboxes) do
        check:SetChecked(pendingState[check.moduleName])
        check:Enable()

        -- Set OnClick handler
        check:SetScript("OnClick", function(self)
            pendingState[self.moduleName] = self:GetChecked()
        end)
    end
end

-- Register interface initialization
addon:RegisterModuleInit(function()
    -- Initialize checkboxes when panel is shown (lazy initialization)
    panel:SetScript("OnShow", initializeCheckboxes)

    -- Register panel with WoW settings API
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        category.ID = panel.name
        Settings.RegisterAddOnCategory(category)
    end
end)

-- Slash command: /cff
SLASH_CFFRAMES1 = "/cff"
SlashCmdList["CFFRAMES"] = function()
    Settings.OpenToCategory(panel.name)
end
