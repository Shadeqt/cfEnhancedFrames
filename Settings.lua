local _, addon = ...

-- The producer's settings page: one flat vertical-layout category under three section headers
-- (General / Class Colors / Fixes). No runtime lifecycle — checkboxes write a cfFramesDB bool
-- applied at the next reload (the Setup* reads it at load); the only live control is the
-- texture dropdown.

local TEXTURE_FOLDER = "Interface\\AddOns\\cfFrames\\Media\\StatusBar\\"

-- Build the settings page. Called explicitly from Init's ADDON_LOADED handler, after InitDB(),
-- so cfFramesDB is fully populated before any RegisterAddOnSetting reads cfFramesDB[key]. A
-- freshly-created character has no saved DB yet, and registering a setting against a nil backing
-- value hands back an unusable setting object (the GetVariableType crash seen on new characters).
function addon.SetupSettings()
	local category = Settings.RegisterVerticalLayoutCategory("cfFrames")
	local layout = SettingsPanel:GetLayout(category)

	-- Boolean setting bound to cfFramesDB[key]; reload-gated (no value-changed callback).
	local function Checkbox(key, label, tooltip)
		local setting = Settings.RegisterAddOnSetting(category, "cfFrames_" .. key, key, cfFramesDB,
			Settings.VarType.Boolean, label, addon.defaults[key])
		Settings.CreateCheckbox(category, setting, tooltip)
	end

	local function Header(name)
		layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(name))
	end

	Header("Some changes apply after /reload.")

	-- General
	Header("General")
	local function TextureOptions()
		local container = Settings.CreateControlTextContainer()
		container:Add(addon.BLIZZARD_DEFAULT,                     "Blizzard Default")
		container:Add(TEXTURE_FOLDER .. "smooth",                 "Smooth")
		container:Add(TEXTURE_FOLDER .. "BlizzardRetailBarCrop2", "Blizzard Retail")
		container:Add(TEXTURE_FOLDER .. "DragonflightTexture",    "Dragonflight")
		container:Add(TEXTURE_FOLDER .. "DragonflightTextureHD",  "Dragonflight HD")
		container:Add(TEXTURE_FOLDER .. "ShatteredDF",           "Shattered DF")
		return container:GetData()
	end
	local textureSetting = Settings.RegisterAddOnSetting(category, "cfFrames_StatusBarTexture",
		"StatusBarTexture", cfFramesDB, Settings.VarType.String, "Status Bar Texture",
		addon.defaults.StatusBarTexture)
	Settings.CreateDropdown(category, textureSetting, TextureOptions,
		"Choose the status bar texture. Blizzard Default turns the feature off.")
	Settings.SetOnValueChangedCallback("cfFrames_StatusBarTexture", function() addon.SetupStatusBar() end)

	Checkbox("BiggerHealthbar", "Bigger Health Bars", "Enlarge player and target health bars")

	-- Status Text
	Header("Status Text")
	Checkbox("StatusText", "Target Status Text", "Show health/mana text on the target frame, mirroring the player frame's text")
	Checkbox("WatchedBar", "XP / Reputation Text", "Keep XP and reputation bar text visible (not hover-only) and format it to match the status-text display mode")
	Checkbox("DruidBar", "Druid Mana Bar", "Show a secondary mana bar for druids while shapeshifted, so the hidden mana pool stays visible")

	-- Class Colors
	Header("Class Colors")
	Checkbox("ClassColors", "Health Bar Colors", "Color unit-frame health bars by class (nameplate class colors live in the cfPlates addon)")
	Checkbox("ClassColorText", "Chat, Names & Levels", "Class-color player names, class words, and level numbers across chat, friends/guild/who lists, right-click menus, and tooltips")
	Checkbox("ShamanColorFix", "Shaman Color", "Recolor Era's pink Shaman class color to blue across cfFrames' coloring, chat names, and Blizzard's own raid frames")

	-- Pet
	Header("Pet")
	Checkbox("PetLevelBadge", "Pet Level Badge", "Show the Hunter pet's level as a badge below the pet frame, but only when it differs from your own")
	Checkbox("PetXpBar", "Pet XP Bar", "Show an XP bar below the pet frame while leveling a Hunter pet")
	Checkbox("PetDebuffs", "Pet Debuffs", "Show a custom color-coded debuff grid below the pet frame's buff row (Hunter/Warlock)")

	-- Hide
	Header("Hide")
	Checkbox("HidePortraitGlow", "Player Portrait Glow", "Hide the pulsing combat/rested glow on the player portrait")
	Checkbox("HidePlayerAttackGlow", "Player Attack Glow", "Hide the red attack/combat glow behind the player frame")
	Checkbox("HidePetCombatFlash", "Pet Combat Flash", "Hide the pet portrait combat flash and attack-mode texture")
	Checkbox("HideGroupIndicator", "Player Group Indicator", "Hide the group/role badge above the player frame in a party")
	Checkbox("HideHitIndicators", "Player/Pet Hit Numbers", "Hide the floating damage/healing numbers over the player and pet portraits")

	-- Fixes
	Header("Fixes")
	Checkbox("ActionBarAlphaFix", "Action Bar Alpha Fix", "Reduce action bar button texture alpha to 50%")
	Checkbox("ToTPortraitFix", "ToT Portrait Fix", "Adjust the Target-of-Target portrait position")
	Checkbox("ToTBackgroundFix", "ToT Background Fix", "Align the Target-of-Target background with its bars")
	Checkbox("TargetNameWidthFix", "Target Name Width Fix", "Widen the target name to reduce truncation")
	Checkbox("NameplateLevelPositionFix", "Nameplate Level Position Fix", "Re-center level text on nameplates")
	Checkbox("ActionBarIconPositionFix", "Action Bar Icon Position Fix", "Center action bar icons within their border")
	Checkbox("PetActionBarCheckedFix", "Pet Action Bar Checked Fix", "Align pet button checked textures with their icon")
	Checkbox("UnitFrameResetFix", "Unit Frame Reset Fix", "Persist reset-to-default frame positions across reload")
	Checkbox("PetManaBarOverlapFix", "Pet Mana Bar Overlap Fix", "Drop the pet mana bar 1px so it no longer overlaps the pet health bar")

	Settings.RegisterAddOnCategory(category)

	-- Raise the panel above high-strata world UI. Classic Era renders the native XP-bar text
	-- (MainMenuExpBar.TextString, lit by cfStatusText's xpBarText) over the settings page;
	-- FULLSCREEN_DIALOG sits above it while staying below tooltips.
	SettingsPanel:SetFrameStrata("FULLSCREEN_DIALOG")

	-- Make the panel draggable by its empty areas (child controls still take their own clicks).
	SettingsPanel:SetMovable(true)
	SettingsPanel:EnableMouse(true)
	SettingsPanel:RegisterForDrag("LeftButton")
	SettingsPanel:SetScript("OnDragStart", SettingsPanel.StartMoving)
	SettingsPanel:SetScript("OnDragStop", SettingsPanel.StopMovingOrSizing)

	SLASH_CFF1 = "/cff"
	SlashCmdList.CFF = function() Settings.OpenToCategory(category:GetID()) end
end
