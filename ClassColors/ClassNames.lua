local _, addon = ...
local classNameToToken = addon.classNameToToken

local PINK_SHAMAN = "|cfff48cba"
local localShaman = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE["SHAMAN"] or "Shaman"

local function StripPinkShaman(text)
	if text:find(PINK_SHAMAN .. localShaman, 1, true) then
		return text:gsub(PINK_SHAMAN .. localShaman .. "|r", localShaman)
	end
	return text
end

local function ColorClassInText(fontString)
	local text = fontString and fontString:GetText()
	if not text then return end
	text = StripPinkShaman(text)
	for className, token in pairs(classNameToToken) do
		if text:find(className, 1, true) then
			local color = addon.ClassColor(token)
			if color then
				local colored = color:WrapTextInColorCode(className)
				if text:find(colored, 1, true) then return true end  -- already colored; idempotent (no re-wrap)
				fontString:SetText((text:gsub(className, colored)))
				return true
			end
		end
	end
end

local function ColorByClass(fontString, class)
	local c = addon.ClassColor(class)
	if c then fontString:SetTextColor(c.r, c.g, c.b) end
end

-- Battle.net friends carry no class *word* in their row/tooltip text, so ColorClassInText finds
-- nothing to color. We resolve the friend's class directly and color the character-name substring,
-- append the level (difficulty-colored, like LevelColors does for server friends), and -- in the
-- tooltip -- add race+class and zone lines.

-- Resolve (gameInfo, classColor, characterName) for a BNet friend, or nil unless they're online in a
-- WoW client with a known class.
local function ResolveBNetClass(friendIndex)
	local accountInfo = C_BattleNet.GetFriendAccountInfo(friendIndex)
	local gameInfo = accountInfo and accountInfo.gameAccountInfo
	if not gameInfo or not gameInfo.isOnline or gameInfo.clientProgram ~= BNET_CLIENT_WOW then return end
	local charName = gameInfo.characterName
	local token = charName and classNameToToken[gameInfo.className or ""]
	local color = token and addon.ClassColor(token)
	if not color then return end
	return gameInfo, color, charName
end

-- Class-color the character-name substring of `fontString`. When appendLevel is set, also append ", XX"
-- (number in quest-difficulty color; the "Level" word is deliberately omitted). Same-region friends pass
-- appendLevel=false because Blizzard already prints the level on that line. Idempotent: bails once the
-- wrapped name is already present.
local function ApplyNameAndLevel(fontString, gameInfo, color, charName, appendLevel)
	local text = fontString:GetText()
	if not text then return end
	local wrapped = color:WrapTextInColorCode(charName)
	if text:find(wrapped, 1, true) then return end -- already decorated
	if not text:find(charName, 1, true) then return end
	local replacement = wrapped
	local level = appendLevel and gameInfo.characterLevel
	if level and level > 0 then
		local d = GetQuestDifficultyColor(level)
		replacement = wrapped
			.. GRAY_FONT_COLOR:WrapTextInColorCode(", ")  -- grey ", " separator (no "Level" word)
			.. CreateColor(d.r, d.g, d.b):WrapTextInColorCode(tostring(level)) -- difficulty-colored number
	end
	fontString:SetText((text:gsub(charName, replacement, 1)))
end

-- Friend-row entry point (button.name = "Account (Character)").
local function ColorBNetName(fontString, friendIndex)
	local gameInfo, color, charName = ResolveBNetClass(friendIndex)
	if gameInfo then ApplyNameAndLevel(fontString, gameInfo, color, charName, true) end
end

-- Tooltip entry point: class-color the character name on the name line (the caller colors the class
-- word). For CROSS-region friends -- whose name line is the bare character name -- also append the level
-- and add "Race Class" + zone lines above the rich-presence/realm line. SAME-region friends already get
-- "CharName, <level> Race Class" from Blizzard, so we color the name only (no level append, no extra
-- lines: those would duplicate Blizzard's and overflow the tooltip). The class word already on the line
-- is the same-region tell; a cross-region line is the bare character name. Runs every frame the tooltip
-- is shown so it survives the per-frame rebuild Blizzard does for friends with a broadcast; idempotent.
local function DecorateBNetTooltip()
	if not FriendsTooltip:IsShown() then return end
	local button = FriendsTooltip.button
	if not (button and button.buttonType == FRIENDS_BUTTON_TYPE_BNET) then return end
	local gameInfo, color, charName = ResolveBNetClass(button.id)
	if not gameInfo then return end

	local nameFS = FriendsTooltipGameAccount1Name
	local nameText = nameFS:GetText()
	if not (nameText and nameText:find(charName, 1, true)) then return end

	local sameRegion = gameInfo.className and gameInfo.className ~= "" and nameText:find(gameInfo.className, 1, true)

	-- Color the name in both cases; append the level only when Blizzard isn't already printing it.
	ApplyNameAndLevel(nameFS, gameInfo, color, charName, not sameRegion)

	if sameRegion then return end  -- Blizzard already shows race/class/zone; don't duplicate or overflow

	local extra = {}
	local raceClass = (gameInfo.raceName and (gameInfo.raceName .. " ") or "") .. (gameInfo.className or "")
	if (raceClass:gsub("%s+", "")) ~= "" then extra[#extra + 1] = raceClass end
	if gameInfo.areaName and gameInfo.areaName ~= "" then extra[#extra + 1] = gameInfo.areaName end
	if #extra == 0 then return end

	local infoFS = FriendsTooltipGameAccount1Info
	local keep = gameInfo.richPresence
	local target = table.concat(extra, "|n")
	if keep and keep ~= "" then target = target .. "|n" .. keep end
	if infoFS:GetText() == target then return end -- already extended (idempotent; no repeated grow)
	local before = infoFS:GetStringHeight()
	infoFS:SetText(target)
	local delta = infoFS:GetStringHeight() - before
	if delta > 0 then FriendsTooltip:SetHeight(FriendsTooltip:GetHeight() + delta) end
end

function addon.SetupClassNameColors()
	if not cfFramesDB.ClassColorText then return end

	-- Character frame
	hooksecurefunc("PaperDollFrame_SetLevel", function()
		ColorClassInText(CharacterLevelText)
	end)

	-- Inspect frame (LoD)
	EventUtil.ContinueOnAddOnLoaded("Blizzard_InspectUI", function()
		hooksecurefunc("InspectPaperDollFrame_SetLevel", function()
			ColorClassInText(InspectLevelText)
		end)
	end)

	-- Guild member detail (guard against our own SetText re-triggering the hook)
	local updating = false
	hooksecurefunc(GuildMemberDetailLevel, "SetText", function(self)
		if updating then return end
		updating = true
		ColorClassInText(self)
		updating = false
	end)

	-- Guild list
	hooksecurefunc("GuildStatus_Update", function()
		local offset = FauxScrollFrame_GetOffset(GuildListScrollFrame)
		for i = 1, GUILDMEMBERS_TO_DISPLAY do
			local _, _, _, _, _, _, _, _, online, _, class = GetGuildRosterInfo(offset + i)
			if online then
				ColorByClass(_G["GuildFrameButton" .. i .. "Class"], class)
			end
		end
	end)

	-- Friends list
	hooksecurefunc("FriendsFrame_UpdateFriendButton", function(button)
		if button.buttonType == FRIENDS_BUTTON_TYPE_WOW then
			local info = C_FriendList.GetFriendInfoByIndex(button.id)
			if not info or not info.className or not info.connected then return end
			ColorClassInText(button.name)
		elseif button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
			ColorBNetName(button.name, button.id)
		end
	end)

	-- Friends tooltip: class-color the BNet name line (class word + character name) plus the cross-region
	-- decoration. Both run on OnShow AND every OnUpdate frame, because Blizzard rebuilds the tooltip each
	-- frame for friends with a broadcast (its OnUpdate calls button:OnEnter while hasBroadcast) -- so the
	-- coloring would otherwise reset every frame. Running each frame also picks up class data that arrives
	-- a beat after a friend logs in. Both ColorClassInText and DecorateBNetTooltip are idempotent, so the
	-- per-frame calls are no-ops once nothing changes (no string growth on non-broadcast friends).
	local function UpdateFriendsTooltip()
		ColorClassInText(FriendsTooltipGameAccount1Name)  -- class word ("Shaman")
		DecorateBNetTooltip()                             -- character name (+ cross-region level/extras)
	end
	FriendsTooltip:HookScript("OnShow", UpdateFriendsTooltip)
	FriendsTooltip:HookScript("OnUpdate", UpdateFriendsTooltip)

	-- GameTooltip
	GameTooltip:HookScript("OnTooltipSetUnit", function(self)
		local _, unit = self:GetUnit()
		if not unit or not UnitIsPlayer(unit) then return end
		for i = 2, self:NumLines() do
			if ColorClassInText(_G["GameTooltipTextLeft" .. i]) then break end
		end
	end)

	-- Chat config legend (LoD)
	EventUtil.ContinueOnAddOnLoaded("Blizzard_ChatFrameBase", function()
		if not ChatConfigFrame then return end
		ChatConfigFrame:HookScript("OnShow", function()
			local legends = { ChatConfigChatSettingsClassColorLegend, ChatConfigChannelSettingsClassColorLegend }
			for _, frame in pairs(legends) do
				if frame then
					for _, region in pairs({ frame:GetRegions() }) do
						if region.GetText then
							ColorClassInText(region)
						end
					end
				end
			end
		end)
	end)
end
