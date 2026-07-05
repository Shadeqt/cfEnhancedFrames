local _, addon = ...

-- BiggerUnitFrames (cfFramesTest's newest implementation, UnitFramesImproved variant): enlarge the
-- player + target health bars and swap in the UnitFramesImproved frame art, and extend the same
-- bigger-bar treatment (resize/move only) to the party member frames and the pet frame. Reload-gated
-- on cfFramesDB.BiggerHealthbar (the DB key is kept from the old single-file BiggerHealthbar feature so
-- saved settings + the GUI checkbox carry over). Layout offsetting uses addon.ApplyOffset/KeepOffset
-- (promoted to Init.lua).
--
-- Player/target get NEW art (UnitFramesImproved) with a taller bar window, so their bars enlarge
-- freely. Party/pet keep Blizzard's DEFAULT frame art (there is no UnitFramesImproved party/pet
-- border), so their bars can only grow as far as the default art's bar well allows before spilling
-- past the border -- keep the party/pet height constants modest and tune them against the live frames.
--
-- Everything but the addon.SetupBiggerHealthbar entry point is file-local: the paths share only the
-- sizing constants in their own sections, so no state is published on the addon table.

local DIR           = "Interface\\AddOns\\cfFrames\\Media\\UnitFramesImproved\\"
local GREEK_DIR     = "Interface\\AddOns\\cfFrames\\Media\\GreekCrafted\\"  -- party/pet art (no UnitFramesImproved variant ever shipped)
local NORMAL_BORDER = DIR .. "UI-TargetingFrame"
local PLAYER_STATUS = DIR .. "UI-Player-Status"

-- Health-bar sizing for the taller bar window in the UnitFramesImproved art (player + target share it).
-- The bar grows downward from its top anchor, so the offset slides the enlarged bar back up into the
-- window; the name rides up by the same amount. The bar's status text + the Dead/Corpse overlay follow
-- the bar with the text offset.
local HEALTH_BAR_HEIGHT      = 28
local VERTICAL_OFFSET        = 18
local HEALTH_BAR_TEXT_OFFSET = 10

-- Player: swap in the UnitFramesImproved frame art and enlarge the player health bar. This art lines up
-- with Blizzard's default level/glow/icon positions, so it needs no alignment nudges -- just textures +
-- bar enlarge + the name/text raise the taller bar window requires. KeepOffset re-asserts past Blizzard's
-- deferred layout passes (the player frame isn't re-applied on an event, unlike the target).
local function SetupPlayer()
	if PlayerFrameTexture then PlayerFrameTexture:SetTexture(NORMAL_BORDER) end
	if PlayerStatusTexture then PlayerStatusTexture:SetTexture(PLAYER_STATUS) end
	addon.KeepOffset(PlayerName, VERTICAL_OFFSET)
	if PlayerFrameHealthBar then
		PlayerFrameHealthBar:SetHeight(HEALTH_BAR_HEIGHT)
		addon.KeepOffset(PlayerFrameHealthBar, VERTICAL_OFFSET)
		-- Raise the bar's native text to stay centered in the enlarged bar.
		addon.KeepOffset(PlayerFrameHealthBar.TextString, HEALTH_BAR_TEXT_OFFSET)
		addon.KeepOffset(PlayerFrameHealthBar.LeftText,   HEALTH_BAR_TEXT_OFFSET)
		addon.KeepOffset(PlayerFrameHealthBar.RightText,  HEALTH_BAR_TEXT_OFFSET)
	end
end

-- Target border art per unit classification; anything not listed falls back to NORMAL_BORDER.
local BORDER_TEXTURE_BY_CLASSIFICATION = {
	worldboss = DIR .. "UI-TargetingFrame-Elite",
	elite     = DIR .. "UI-TargetingFrame-Elite",
	rareelite = DIR .. "UI-TargetingFrame-Rare-Elite",
	rare      = DIR .. "UI-TargetingFrame-Rare",
}

-- Target: enlarge the target health bar and swap in the UnitFramesImproved classification border art,
-- raising the name and "Dead" overlay onto the bigger bar. Re-applied inside TargetFrame_CheckClassification
-- (Blizzard fires it per target change and resets the texture there), so ApplyOffset (self-correcting,
-- re-applied each change) is used rather than the persistent KeepOffset hook.
-- The elite/rare dragon is baked into TargetFrameTextureFrameTexture (in TargetFrameTextureFrame), and
-- the ToT frame (TargetFrameToT, holding TargetFrameToTPortrait) sits at the SAME frame strata + level
-- as that texture frame. With the tie, WoW's draw-order tiebreaker lets the dragon's tail paint over the
-- ToT portrait (intermittently, since the tie is resolved by undefined child order). Break the tie by
-- lifting the whole ToT frame one level above the texture frame so the portrait always wins the overlap.
-- Only matters once the custom elite/rare art (with its longer tail) is in place, so it's owned here.
--
-- TargetFrameToT is a PROTECTED frame, so SetFrameLevel on it is blocked during combat lockdown -- and
-- TargetFrame_CheckClassification (our caller) fires on every in-combat target change. The level
-- persists once set, so this is safe to make lazy: skip when it's already correct (idempotent, so no
-- redundant protected calls), and if we're locked down before it's ever been set, defer the single
-- application to PLAYER_REGEN_ENABLED rather than touching the frame in combat.
local totRegenFrame
local function RaiseToTAboveDragon()
	if not (TargetFrameToT and TargetFrameTextureFrame) then return end
	local desired = TargetFrameTextureFrame:GetFrameLevel() + 1
	if TargetFrameToT:GetFrameLevel() == desired then return end
	if InCombatLockdown() then
		if not totRegenFrame then
			totRegenFrame = CreateFrame("Frame")
			totRegenFrame:SetScript("OnEvent", function(self)
				self:UnregisterAllEvents()
				RaiseToTAboveDragon()
			end)
		end
		totRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	TargetFrameToT:SetFrameLevel(desired)
end

local function ApplyTargetArt()
	if TargetFrameTextureFrameTexture then
		local classification = UnitClassification("target")
		TargetFrameTextureFrameTexture:SetTexture(
			BORDER_TEXTURE_BY_CLASSIFICATION[classification] or NORMAL_BORDER)
	end
	RaiseToTAboveDragon()
	addon.ApplyOffset(TargetFrameTextureFrameName, VERTICAL_OFFSET)
	if TargetFrameHealthBar then
		TargetFrameHealthBar:SetHeight(HEALTH_BAR_HEIGHT)
		addon.ApplyOffset(TargetFrameHealthBar, VERTICAL_OFFSET)
	end
	addon.ApplyOffset(TargetFrameTextureFrameDeadText, HEALTH_BAR_TEXT_OFFSET)

	-- Target dark backing: TargetFrameNameBackground is the target's only backing region. Trim its
	-- default 19px to 18px so its bottom edge clears the raised bar, and set the translucent black that
	-- HealthbarColor also writes (they agree, and HealthbarColor's SetVertexColor hook guards against a
	-- write loop). The trim is owned here (it only matters once this feature raised the bar).
	if TargetFrameNameBackground then
		TargetFrameNameBackground:SetHeight(18)
		TargetFrameNameBackground:SetVertexColor(0, 0, 0, 0.5)
	end
end

local function SetupTarget()
	hooksecurefunc("TargetFrame_CheckClassification", ApplyTargetArt)
	if UnitExists("target") then ApplyTargetArt() end  -- catch a target already present (e.g. after /reload)
end

-- =====================================================================================================
-- Party: swap in the GreekCrafted party border art and extend the bigger-bar treatment to the regular
-- PartyMemberFrames. Layout is parametric off the HEALTH bar: mana sits directly below it and the native
-- Background wraps both, so fitting is just tuning the PARTY_* constants (the rest tracks). The
-- GreekCrafted art has a taller bar window than Blizzard's default (health 70x8 @ 47,-12; mana below;
-- Background 72x20) -- hence the doubled health height. The compact raid-style frames
-- (useCompactPartyFrames) use a different art system and aren't covered. Ported from cfFramesTest's
-- GreekCrafted Party.
-- =====================================================================================================

-- Party border art (the GreekCrafted party texture; lives under Media\GreekCrafted\). The fit constants
-- below are tuned to THIS art's window, not default art.
local PARTY_BORDER = GREEK_DIR .. "party"
local PARTY_HP_W, PARTY_HP_H = 70, 16   -- health bar (doubled from the default 8 to fill the art's well)
local PARTY_HP_X, PARTY_HP_Y = 47, -12  -- TOPLEFT anchor on the frame (Blizzard's default position)
local PARTY_MANA_H    = 8               -- mana bar height (kept slim; mana follows below health)
local PARTY_MANA_GAP  = 1               -- px between the health bar's bottom and the mana bar's top
local PARTY_BG_INSET  = 1               -- px the dark Background extends beyond the bars on each side
local PARTY_DEBUFF_DROP = 6             -- px to push the debuff row down so it clears the frame art

local function FitPartyMember(i)
	local frame = _G["PartyMemberFrame" .. i]
	if not frame then return end
	local tex  = _G["PartyMemberFrame" .. i .. "Texture"]
	local hp   = _G["PartyMemberFrame" .. i .. "HealthBar"]
	local mana = _G["PartyMemberFrame" .. i .. "ManaBar"]
	local bg   = _G["PartyMemberFrame" .. i .. "Background"]

	if tex then tex:SetTexture(PARTY_BORDER) end

	if hp then
		hp:SetSize(PARTY_HP_W, PARTY_HP_H)
		hp:ClearAllPoints()
		hp:SetPoint("TOPLEFT", frame, "TOPLEFT", PARTY_HP_X, PARTY_HP_Y)
	end

	-- Mana follows directly below health, same width, its own (slimmer) height.
	if mana and hp then
		mana:SetSize(PARTY_HP_W, PARTY_MANA_H)
		mana:ClearAllPoints()
		mana:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, -PARTY_MANA_GAP)
	end

	-- Dark Background wrapping both bars. The native art doesn't stretch cleanly when re-anchored, so
	-- repurpose it as a solid black 0.5 fill (matching the pet/player backing) spanning health -> mana.
	if bg and hp and mana then
		bg:SetColorTexture(0, 0, 0, 0.5)
		bg:ClearAllPoints()
		bg:SetPoint("TOPLEFT", hp, "TOPLEFT", -PARTY_BG_INSET, PARTY_BG_INSET)
		bg:SetPoint("BOTTOMRIGHT", mana, "BOTTOMRIGHT", PARTY_BG_INSET, -PARTY_BG_INSET)
	end

	-- Drop the debuff row so it clears the frame art. Debuff2+ chain off Debuff1, so nudging only the
	-- first moves the whole row. Offset off a captured baseline y so re-applies don't compound.
	local d1 = _G["PartyMemberFrame" .. i .. "Debuff1"]
	if d1 then
		local point, relTo, relPoint, x, y = d1:GetPoint(1)
		if point then
			if d1.cfBaseY == nil then d1.cfBaseY = y or 0 end
			d1:ClearAllPoints()
			d1:SetPoint(point, relTo, relPoint, x, d1.cfBaseY - PARTY_DEBUFF_DROP)
		end
	end
end

local function SetupParty()
	for i = 1, MAX_PARTY_MEMBERS do FitPartyMember(i) end
	-- Reassert after Blizzard re-lays-out a member (it resets bar anchors/size in UpdateMember, which
	-- also runs on roster changes -- so this one hook covers joins/leaves too).
	if type(PartyMemberFrame_UpdateMember) == "function" then
		hooksecurefunc("PartyMemberFrame_UpdateMember", function(self)
			if self and self.GetID then FitPartyMember(self:GetID()) end
		end)
	end
end

-- =====================================================================================================
-- Pet: swap in the GreekCrafted pet border art, grow the pet health bar a couple px upward (top rises,
-- bottom holds via KeepOffset so it doesn't collide with the mana bar below), add the dark backing the
-- pet frame natively lacks, center the name over the bar, and lift the health text to stay centered.
-- PetManaBarOverlapFix independently lowers the mana bar 1px -- a different region, so no conflict.
-- Ported from cfFramesTest's GreekCrafted Pet (the art designed around Blizzard's default bar layout,
-- hence the small +2px fit rather than a full re-anchor).
-- =====================================================================================================

-- Pet border art. This is the GreekCrafted pet texture (the UnitFramesImproved set never shipped a pet
-- variant); it lives under Media\GreekCrafted\.
local PET_BORDER   = GREEK_DIR .. "pet"
local PET_HP_RAISE = 2  -- grow the health bar this many px upward

-- Swap the pet frame's border art. Reasserted via ApplyPet since Blizzard re-points PetFrameTexture on
-- pet updates.
local function ApplyPetArt()
	if PetFrameTexture then PetFrameTexture:SetTexture(PET_BORDER) end
end

-- The pet frame has no native dark backing (unlike the player's PlayerFrameBackground). Create one to
-- match: a black 0.5 texture on PetFrame's BACKGROUND layer spanning the health+mana bar area. Once.
local petBacking
local function EnsurePetBacking()
	if petBacking or not (PetFrame and PetFrameHealthBar and PetFrameManaBar) then return end
	petBacking = PetFrame:CreateTexture(nil, "BACKGROUND")
	petBacking:SetColorTexture(0, 0, 0, 0.5)
	petBacking:SetPoint("TOPLEFT", PetFrameHealthBar, "TOPLEFT", 0, 0)
	petBacking:SetPoint("BOTTOMRIGHT", PetFrameManaBar, "BOTTOMRIGHT", 0, 0)
end

-- Grow the pet health bar PET_HP_RAISE px upward (top edge rises, bottom stays put). The default height
-- is captured once so repeated re-applies don't compound it; KeepOffset lifts the top by the height we
-- added so the bottom holds.
local function ApplyPetBar()
	local bar = PetFrameHealthBar
	if not bar then return end
	if not bar.cfPetBaseHeight then bar.cfPetBaseHeight = bar:GetHeight() end
	bar:SetHeight(bar.cfPetBaseHeight + PET_HP_RAISE)
	addon.KeepOffset(bar, PET_HP_RAISE)
end

-- Center the pet name above the health bar, replacing Blizzard's default (left-ish) placement.
local function ApplyPetName()
	if not (PetName and PetFrameHealthBar) then return end
	PetName:ClearAllPoints()
	PetName:SetPoint("BOTTOM", PetFrameHealthBar, "TOP", 0, 3)
end

-- Raise the pet HEALTH-bar text 2px (Blizzard parks it ~1px below the bar's center). Horizontal anchor
-- kept exactly; only y shifts up. Each string's default y is captured once so the repeated re-applies
-- (on every PetFrame_Update) don't compound. Mana text left alone.
local function RaisePetHealthText()
	local bar = PetFrameHealthBar
	if not bar then return end
	local function raise(str)
		if not str then return end
		local point, relativeTo, relativePoint, x, y = str:GetPoint(1)
		if not point then return end
		if str.cfBaseY == nil then str.cfBaseY = y or 0 end
		str:ClearAllPoints()
		str:SetPoint(point, relativeTo, relativePoint, x, str.cfBaseY + 2)
	end
	raise(bar.TextString)
	raise(bar.LeftText)
	raise(bar.RightText)
end

local function ApplyPet()
	ApplyPetArt()
	EnsurePetBacking()
	ApplyPetBar()
	ApplyPetName()
	RaisePetHealthText()
end

local function SetupPet()
	-- PetFrame_Update is Blizzard's pet-frame handler -- it fires on entering world, pet summon/change
	-- (UNIT_PET), and every health/power update, re-pointing the bar each time. Hooking it reasserts our
	-- changes on every one of those.
	if type(PetFrame_Update) == "function" then
		hooksecurefunc("PetFrame_Update", ApplyPet)
	end
	if UnitExists("pet") then ApplyPet() end  -- catch a pet already present (e.g. after /reload)
end

-- Reload-gated; called once from Init's PLAYER_ENTERING_WORLD pass.
function addon.SetupBiggerHealthbar()
	if not cfFramesDB.BiggerHealthbar then return end
	SetupPlayer()
	SetupTarget()
	SetupParty()
	SetupPet()
end
