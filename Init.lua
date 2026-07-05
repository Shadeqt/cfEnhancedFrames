local addonName, addon = ...

-- Re-entrancy marker, passed as the trailing arg to SetVertexColor. ActionBarAlphaFix and the
-- standalone cfDarkMode addon both hook SetVertexColor on the SAME ActionButton textures; each skips
-- writes carrying this flag so they recognize their own (and each other's) writes and don't loop.
-- The literal "cff" is a SHARED CONTRACT with cfDarkMode (its Init.lua sets the identical value):
-- changing one without the other reintroduces the ping-pong. This creates no presence dependency --
-- each addon works alone; the shared string only governs how they coexist.
addon.SENTINEL = "cff"

-- Shared layout helpers (used by BiggerUnitFrames and the PetManaBarOverlap fix). Promoted here from
-- the per-feature file so both can reach them. Raise a region's Y by dy, self-correcting against
-- Blizzard's repeated layout resets: re-baseline from the current default Y whenever it moves, so the
-- offset never compounds and never sticks to a stale base. Re-reads the anchor each call in case
-- Blizzard re-anchors to a new point.
local isReapplying = false  -- re-entrancy guard for the SetPoint hooks below
function addon.ApplyOffset(region, dy)
	if not region then return end
	local point, relativeTo, relativePoint, x, y = region:GetPoint()
	if not y then return end
	if not region.cfAppliedY or math.abs(region.cfAppliedY - y) > 0.5 then
		region.cfBaselineY = y  -- Blizzard's current default; re-baseline off it
	end
	region:ClearAllPoints()
	region:SetPoint(point, relativeTo, relativePoint, x, region.cfBaselineY + dy)
	region.cfAppliedY = region.cfBaselineY + dy
end

-- Apply addon.ApplyOffset and keep it applied past Blizzard's deferred layout by hooking the region's
-- own SetPoint and re-asserting -- making our write the last one. The guard skips the SetPoint we issue
-- ourselves; ApplyOffset is self-correcting, so re-asserting lands on default+dy without compounding.
function addon.KeepOffset(region, dy)
	if not region then return end
	addon.ApplyOffset(region, dy)
	if region.cfOffsetHookInstalled then return end
	region.cfOffsetHookInstalled = true
	hooksecurefunc(region, "SetPoint", function()
		if isReapplying then return end
		isReapplying = true
		addon.ApplyOffset(region, dy)
		isReapplying = false
	end)
end

-- Shared status-text helpers (used by the folded StatusText + DruidBar features). Two concerns kept in
-- one place: HOW the LeftText/TextString/RightText trio is created, and WHAT it shows per
-- statusTextDisplay.

-- Build the standard status-text trio on `bar`, font strings parented to `parent`, positioned via
-- anchors = { left = {relTo, x, y}, center = {relTo, x, y}, right = {relTo, x, y} }. The font-string
-- parent and the SetPoint anchor target are kept separate (the druid bar parents its text to its border
-- but anchors to the bar; the target parents + anchors to the same texture frame).
function addon.CreateBarText(bar, parent, anchors)
	bar.LeftText   = parent:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	bar.TextString = parent:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	bar.RightText  = parent:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	bar.LeftText:SetPoint("LEFT",     anchors.left[1],   anchors.left[2],   anchors.left[3])
	bar.TextString:SetPoint("CENTER", anchors.center[1], anchors.center[2], anchors.center[3])
	bar.RightText:SetPoint("RIGHT",   anchors.right[1],  anchors.right[2],  anchors.right[3])
end

-- The single source of truth for "what a managed bar's text shows per statusTextDisplay." Runs as a post
-- hook on TextStatusBar_UpdateTextString (installed below) for every bar flagged bar.cfManaged. The
-- caller sets lockShow=1 so Blizzard renders in all modes; this hides the text on NONE unless moused
-- over, and otherwise forces showPercentage=false so the render is the value (NUMERIC), splitting to
-- Left/Right in BOTH.
function addon.ApplyBarStatusText(bar)
	if GetCVar("statusTextDisplay") == "NONE" and not bar:IsMouseOver() then
		bar.TextString:Hide(); bar.LeftText:Hide(); bar.RightText:Hide()
	elseif bar.showPercentage then
		bar.showPercentage = false
		TextStatusBar_UpdateTextString(bar)
	end
end

-- One global hook serving both features: every cfManaged bar runs through the shared gate after Blizzard
-- renders it. Installed here (not in SetupStatusText) so it's decoupled from the StatusText feature
-- toggle -- the druid bar's gating works even with target status text turned off.
hooksecurefunc("TextStatusBar_UpdateTextString", function(bar)
	if bar.cfManaged then addon.ApplyBarStatusText(bar) end
end)

-- DB schema (the single source of truth for cfFramesDB keys).
-- All module bools default true; StatusBarTexture is the one stored value.
-- Cut keys (frame-move/scale, the old DarkMode sub-toggles/colors, and the DarkMode master toggle now
-- that dark mode is the standalone cfDarkMode addon) are absent here, and InitDB() prunes them from any
-- existing saved DB.
addon.defaults = {
	-- General
	BiggerHealthbar           = true,
	-- Status text + bars (folded from cfStatusText / cfDruidBar)
	StatusText                = true,
	WatchedBar                = true,
	DruidBar                  = true,
	-- Class Colors (absorbed from cfClassColors): two coloring toggles under one GUI header.
	ClassColors               = true,   -- health-bar tint (Healthbars.lua)
	ClassColorText            = true,   -- social-text coloring: chat / class words / level numbers / menus
	ShamanColorFix            = true,   -- Era Shaman pink -> blue, local: Core.lua resolver + chat rewrite + native raid frames (ShamanColor.lua)
	-- Pet (absorbed from cfPet): pet-frame additions, class-gated per feature.
	PetLevelBadge             = true,   -- Hunter pet level badge (Pet/Level.lua)
	PetXpBar                  = true,   -- Hunter pet XP bar (Pet/XpBar.lua)
	PetDebuffs                = true,   -- Hunter/Warlock pet debuff grid (Pet/Debuffs.lua)
	-- Hide (one bool per native element; was the single HideNative master, now split)
	HidePortraitGlow          = true,
	HidePlayerAttackGlow      = true,
	HidePetCombatFlash        = true,
	HideGroupIndicator        = true,
	HideHitIndicators         = true,
	-- Fixes
	ActionBarAlphaFix         = true,
	ToTPortraitFix            = true,
	ToTBackgroundFix          = true,
	TargetNameWidthFix        = true,
	NameplateLevelPositionFix = true,
	ActionBarIconPositionFix  = true,
	PetActionBarCheckedFix    = true,
	UnitFrameResetFix         = true,
	PetManaBarOverlapFix      = true,
	-- Stored value: chosen status-bar texture (StatusBar on/off is encoded here;
	-- the GUI's "Blizzard Default" dropdown entry = feature off).
	StatusBarTexture = "Interface\\AddOns\\cfFrames\\Media\\StatusBar\\smooth",
}

function addon.InitDB()
	cfFramesDB = cfFramesDB or {}
	-- Merge newly-added defaults.
	for key, value in pairs(addon.defaults) do
		if cfFramesDB[key] == nil then
			cfFramesDB[key] = value
		end
	end
	-- Prune keys no longer in the schema (e.g. cut frame-move / DarkMode-color keys).
	for key in pairs(cfFramesDB) do
		if addon.defaults[key] == nil then
			cfFramesDB[key] = nil
		end
	end
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
	addon.InitDB()
	addon.SetupSettings()   -- register the GUI now that the DB is populated (explicit order, B1)
	-- Defer feature setup to PLAYER_ENTERING_WORLD (nameplates / compact-raid exist there).
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:SetScript("OnEvent", function(self)
		self:UnregisterAllEvents()
		-- Setup* calls are appended here, one per feature step (explicit order, B1).
		addon.SetupStatusBar()
		addon.SetupBiggerHealthbar()
		-- Status text after BiggerHealthbar: it mirrors the player text's CURRENT position, so the
		-- player text must already be raised when SetupStatusText runs.
		addon.SetupStatusText()
		addon.SetupWatchedBar()
		addon.SetupDruidBar()
		addon.SetupHideNative()
		-- Class colors: health-bar tint + the four social-text coloring features (absorbed from
		-- cfClassColors). SetupShamanColor corrects Blizzard's OWN raid frames to blue; the resolver in
		-- ClassColors/Core.lua plus the chat rewrite cover cfFrames' own surfaces.
		addon.SetupClassColorHealthbars()
		addon.SetupShamanColor()
		addon.SetupChatColors()
		addon.SetupClassNameColors()
		addon.SetupNameMenuColors()
		addon.SetupLevelColors()
		-- Pet frame additions (absorbed from cfPet). After SetupStatusBar so the pet XP bar's initial
		-- texture read sees an already-painted PetFrameHealthBar (the hook self-heals regardless).
		addon.SetupPetLevel()
		addon.SetupPetXpBar()
		addon.SetupPetDebuffs()

		-- Fixes
		addon.SetupActionBarAlphaFix()
		addon.SetupToTPortraitFix()
		addon.SetupToTBackgroundFix()
		addon.SetupTargetNameWidthFix()
		addon.SetupNameplateLevelPositionFix()
		addon.SetupActionBarIconPositionFix()
		addon.SetupPetActionBarCheckedFix()
		addon.SetupUnitFrameResetFix()
		addon.SetupPetManaBarOverlapFix()
	end)
end)
