local _, addon = ...

-- Class-color feature family, absorbed from the former standalone cfClassColors addon: chat, class-word,
-- name, and level coloring across the social UI. The health-bar tint (Healthbars.lua) is the sibling
-- visual half. The Shaman pink->blue correction lives here too, as addon.ClassColor (below): a local
-- read-time substitution, NOT a write to the shared RAID_CLASS_COLORS global. Writing that global (the
-- old Fixes/ShamanColorFix.lua) tainted Blizzard's protected raid frames and blocked their layout in
-- combat whenever a Shaman was present; resolving the color locally leaves the global untouched.
-- Default-on; an explicit cfFramesDB.ShamanColorFix == false opts back to Era pink. The `not cfFramesDB`
-- guard covers the pre-InitDB window (every real caller runs after InitDB, but stay defensive). The blue
-- object matches RAID_CLASS_COLORS' shape (r/g/b + colorStr + ColorMixin methods) so it drops in at every
-- call site. addon.SHAMAN_BLUE is reused by the chat rewrite and the native-raid-frame recolor.
addon.SHAMAN_BLUE = CreateColor(0, 0.44, 0.87)
addon.SHAMAN_BLUE.colorStr = "ff0070de"
function addon.ClassColor(token)
	if token == "SHAMAN" and (not cfFramesDB or cfFramesDB.ShamanColorFix ~= false) then
		return addon.SHAMAN_BLUE
	end
	return RAID_CLASS_COLORS[token]
end

-- This file also builds the one shared piece: a reverse lookup from localized class name -> class token, used
-- by ClassNames + NameColors. Built at file scope (the LOCALIZED_CLASS_NAMES globals exist at load), so
-- it's ready before the PLAYER_ENTERING_WORLD Setup* calls run. MUST load before its consumers (.toc
-- order): ClassNames/NameColors capture addon.classNameToToken as a file-scope local.
addon.classNameToToken = {}
for token, name in pairs(LOCALIZED_CLASS_NAMES_MALE or {}) do
	addon.classNameToToken[name] = token
end
for token, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE or {}) do
	addon.classNameToToken[name] = token
end
