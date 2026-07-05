local _, addon = ...

local CHAT_TYPES = {
	"SAY", "EMOTE", "YELL",
	"GUILD", "OFFICER",
	"WHISPER",
	"PARTY", "PARTY_LEADER",
	"RAID", "RAID_LEADER", "RAID_WARNING",
	"INSTANCE_CHAT", "INSTANCE_CHAT_LEADER",
	"VOICE_TEXT",
}

local function Apply()
	-- The one CVar write (the documented feature-CVar exception): Blizzard's own class-color
	-- override must be off for SetChatColorNameByClass to take effect.
	SetCVar("chatClassColorOverride", "0")
	for _, chatType in ipairs(CHAT_TYPES) do
		SetChatColorNameByClass(chatType, true)
	end
	for i = 1, 50 do
		SetChatColorNameByClass("CHANNEL" .. i, true)
	end
end

-- Shaman-blue in chat, class-accurately (NOT by scanning for a color). Verified against Classic
-- ChatFrame.lua: GetColoredName resolves the sender's class from the message GUID (arg12) via
-- GetPlayerInfoByGUID and wraps the name in RAID_CLASS_COLORS[class]. We replace it: run the original, and
-- ONLY when that same GUID resolves to a SHAMAN recolor the name blue. The class comes from the GUID -- the
-- exact way Blizzard decides -- so Paladins (who share Shaman's Era pink) are never touched, on any faction.
-- Chat isn't protected, so replacing this display helper cannot taint a protected call.
local shamanChatInstalled = false
local function InstallShamanChatColor()
	if shamanChatInstalled or type(GetColoredName) ~= "function" then return end
	shamanChatInstalled = true
	local blue = "|c" .. addon.SHAMAN_BLUE.colorStr  -- "|cff0070de"
	local orig = GetColoredName
	GetColoredName = function(event, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, ...)
		local name = orig(event, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, ...)
		if type(name) == "string" and a12 and a12 ~= "" then
			local _, class = GetPlayerInfoByGUID(a12)
			if class == "SHAMAN" then
				-- This name is confirmed a Shaman; swap only its (leading) class-color escape to blue.
				name = name:gsub("|cff%x%x%x%x%x%x", blue, 1)
			end
		end
		return name
	end
end

function addon.SetupChatColors()
	if not cfFramesDB.ClassColorText then return end

	Apply()

	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("CHANNEL_UI_UPDATE")
	frame:SetScript("OnEvent", Apply)

	hooksecurefunc("FCF_OpenNewWindow", Apply)

	-- Correct pink Shaman names to blue, class-accurately (default on; opt out via the Shaman Color toggle).
	-- No faction gate: the GUID class lookup makes it Shaman-only, so Alliance Paladins keep their pink.
	if cfFramesDB.ShamanColorFix ~= false then
		InstallShamanChatColor()
	end
end
