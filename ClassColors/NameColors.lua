local _, addon = ...
local classNameToToken = addon.classNameToToken

local function ClassForPlayer(name, guid, unit)
	if unit and UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		if class then return class end
	end
	if guid then
		local _, class = GetPlayerInfoByGUID(guid)
		if class then return class end
	end
	if not name then return end
	for i = 1, C_FriendList.GetNumWhoResults() do
		local info = C_FriendList.GetWhoInfo(i)
		if info and info.fullName == name then
			local class = classNameToToken[info.classStr]
			if class then return class end
		end
	end
	local friendInfo = C_FriendList.GetFriendInfo(name)
	if friendInfo and friendInfo.className then
		local class = classNameToToken[friendInfo.className]
		if class then return class end
	end
	if IsInGuild() then
		for i = 1, GetNumGuildMembers() do
			local gName, _, _, _, _, _, _, _, _, _, gClass = GetGuildRosterInfo(i)
			if gName and (gName == name or gName:match("^(.-)%-") == name) then
				return gClass
			end
		end
	end
	if C_LFGList then
		local _, resultIDs = C_LFGList.GetSearchResults()
		for _, resultID in pairs(resultIDs or {}) do
			local leaderInfo = C_LFGList.GetSearchResultLeaderInfo(resultID)
			if leaderInfo and leaderInfo.name == name and leaderInfo.classFilename then
				return leaderInfo.classFilename
			end
		end
	end
end

local function ColorMenuTitle(name, class)
	local color = class and addon.ClassColor(class)
	if not color then return end
	local menu = Menu.GetManager():GetOpenMenu()
	if not menu then return end
	local children = menu:GetLayoutChildren()
	local title = children and children[1]
	if not title or not title:IsShown() then return end
	for _, region in pairs({ title:GetRegions() }) do
		if region:IsObjectType("FontString") then
			region:SetText(color:WrapTextInColorCode(name))
			break
		end
	end
end

function addon.SetupNameMenuColors()
	if not cfFramesDB.ClassColorText then return end

	-- UnitPopupManager: unit right-click menus (friends, guild, who, party, etc.)
	hooksecurefunc(UnitPopupManager, "OpenMenu", function(_, which, contextData)
		local class = ClassForPlayer(contextData.name, contextData.guid, contextData.unit)
		ColorMenuTitle(contextData.name, class)
	end)

	-- CreateContextMenu: other right-click menus (LFG, etc.)
	hooksecurefunc(MenuUtil, "CreateContextMenu", function()
		local menu = Menu.GetManager():GetOpenMenu()
		if not menu then return end
		local children = menu:GetLayoutChildren()
		local title = children and children[1]
		if not title or not title:IsShown() then return end
		for _, region in pairs({ title:GetRegions() }) do
			if region:IsObjectType("FontString") then
				local name = region:GetText()
				if name then
					local class = ClassForPlayer(name)
					ColorMenuTitle(name, class)
				end
				break
			end
		end
	end)
end
