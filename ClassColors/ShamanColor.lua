local _, addon = ...

-- Shaman-blue on Blizzard's OWN raid frames. The resolver in Core.lua (addon.ClassColor) only covers
-- cfFrames' own coloring, and chat is handled in ChatColors.lua; this file covers the two native raid UIs
-- (the new compact raid frames and the old Blizzard_RaidUI group list).
--
-- We must NOT write RAID_CLASS_COLORS -- that taint is the whole bug (an insecure write to the shared
-- global poisons the value, and Blizzard's secure raid code reading it during combat gets its protected
-- ClearAllPoints/Hide blocked). Instead we let Blizzard class-color normally (pink) and correct it
-- afterward with display-only setters (SetStatusBarColor / SetTextColor), which are not protected and do
-- not taint the layout path -- the same category Healthbars.lua already calls on protected party/target
-- frames without ever blocking.
--
-- Shamans are identified by their real class TOKEN (from the unit / roster API), NEVER by reading a
-- bar/text color: Era's SHAMAN and PALADIN share the identical pink, so any color-based match is broken by
-- construction. For each surface we mirror Blizzard's own condition for "is this member being class-colored
-- right now?" and, only for an actual SHAMAN, override to blue.
--
-- Gated by cfFramesDB.ShamanColorFix ALONE (independent of the ClassColors/ClassColorText toggles): this
-- corrects Blizzard's coloring, not cfFrames' own. Reload-gated like every module. Taint-safe: SetStatusBarColor
-- / SetTextColor are not protected methods, so recoloring these frames from a post-hook never blocks a later
-- secure layout call (verified against the WoW taint model + shipping class-color addons).

-- Compact raid/party frames. Blizzard's CompactUnitFrame_UpdateHealthColor (Classic CompactUnitFrame.lua)
-- shows RAID_CLASS_COLORS[class] on frame.healthBar exactly when the unit is a connected player and
-- optionTable.useClassColors is on. Mirror that condition; override to blue for a SHAMAN.
local function CorrectCompact(frame)
	if not frame then return end
	local hb = frame.healthBar
	if not hb or hb:IsForbidden() then return end
	local unit = frame.unit
	if not unit or not UnitIsPlayer(unit) or not UnitIsConnected(unit) then return end
	if not (frame.optionTable and frame.optionTable.useClassColors) then return end
	local _, class = UnitClass(unit)
	if class == "SHAMAN" then
		hb:SetStatusBarColor(addon.SHAMAN_BLUE:GetRGB())
	end
end

-- Old raid UI (Blizzard_RaidUI). RaidGroupFrame_Update and RaidGroupFrame_UpdateHealth(id) class-color a
-- member's Name / Class.text / Level fontstrings when online and alive (red if dead, gray if offline). Read
-- the member's real class from GetRaidRosterInfo(i) -- the button index maps 1:1 to roster member i -- and
-- override to blue only for a live SHAMAN. Verified fontstring names; no color inspection anywhere.
local function CorrectRaidButton(i)
	if not i then return end
	local button = _G["RaidGroupButton" .. i]
	if not button or button:IsForbidden() then return end
	local _, _, _, _, _, fileName, _, online, isDead = GetRaidRosterInfo(i)
	if fileName ~= "SHAMAN" or not online or isDead then return end
	local r, g, b = addon.SHAMAN_BLUE:GetRGB()
	local name = _G["RaidGroupButton" .. i .. "Name"]
	if name then name:SetTextColor(r, g, b) end
	local classFrame = _G["RaidGroupButton" .. i .. "Class"]
	if classFrame and classFrame.text then classFrame.text:SetTextColor(r, g, b) end
	local level = _G["RaidGroupButton" .. i .. "Level"]
	if level then level:SetTextColor(r, g, b) end
end

local function CorrectRaidRoster()
	for i = 1, MAX_RAID_MEMBERS do CorrectRaidButton(i) end
end

function addon.SetupShamanColor()
	if cfFramesDB.ShamanColorFix == false then return end

	if type(CompactUnitFrame_UpdateHealthColor) == "function" then
		hooksecurefunc("CompactUnitFrame_UpdateHealthColor", CorrectCompact)
	end

	-- Blizzard_RaidUI may be load-on-demand; hook now if present, else when it loads. Hook BOTH the roster
	-- update and the per-member health update -- the latter re-colors the name on every UNIT_HEALTH and would
	-- otherwise revert our blue when a Shaman takes damage.
	local function HookOldRaidUI()
		if type(RaidGroupFrame_Update) == "function" then
			hooksecurefunc("RaidGroupFrame_Update", CorrectRaidRoster)
		end
		if type(RaidGroupFrame_UpdateHealth) == "function" then
			hooksecurefunc("RaidGroupFrame_UpdateHealth", CorrectRaidButton)  -- called as (id); id == button index
		end
	end
	if type(RaidGroupFrame_Update) == "function" then
		HookOldRaidUI()
	else
		EventUtil.ContinueOnAddOnLoaded("Blizzard_RaidUI", HookOldRaidUI)
	end
end
