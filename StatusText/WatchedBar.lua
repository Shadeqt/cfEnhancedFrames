-- cfStatusText WatchedBar (folded into cfFrames): persistent text + custom formatting on the XP and
-- reputation watch bars, following statusTextDisplay. Reload-gated on cfFramesDB.WatchedBar; run from
-- addon.SetupWatchedBar in Init's PLAYER_ENTERING_WORLD pass (cfStatusText ran this inline at file load;
-- the watch bars exist by PEW, so the registrations land the same).

local _, addon = ...

local function Percent(current, max)
    return math.floor((current / max) * 100 + 0.5)
end

-- XP text uses Blizzard's native render in every mode -- we don't reformat it. ApplyVisibility just
-- toggles xpBarText so the native text is persistent (not hover-only) whenever the mode isn't NONE.

-- Rep's native text is hardcoded "name value/max" for every mode. Override BOTH and PERCENT;
-- NUMERIC keeps the native; NONE is hidden by ApplyVisibility.
local function OverrideRep()
    if not ReputationWatchBar:IsShown() then return end
    local display = GetCVar("statusTextDisplay")
    if display ~= "BOTH" and display ~= "PERCENT" then return end
    local name, _, minBar, maxBar, value = GetWatchedFactionInfo()
    if not name then return end
    local current, max = value - minBar, maxBar - minBar
    if max == 0 then return end
    local pct = Percent(current, max)
    if display == "BOTH" then
        -- Match the XP bar's ordering: percent before numeric (XP renders "(15%) 128 / 900").
        ReputationWatchBar.OverlayFrame.Text:SetText(string.format("%s (%d%%) %d / %d", name, pct, current, max))
    else
        ReputationWatchBar.OverlayFrame.Text:SetText(string.format("%s %d%%", name, pct))
    end
end

-- xpBarText gates Blizzard's XP text; ShowWatchBarText locks the rep text on (default is
-- hover-only). HideWatchBarText(_, true) clears the lock.
local function ApplyVisibility()
    local on = GetCVar("statusTextDisplay") ~= "NONE"
    SetCVar("xpBarText", on and "1" or "0")
    if on then ShowWatchBarText(ReputationWatchBar)
    else HideWatchBarText(ReputationWatchBar, true) end
end

function addon.SetupWatchedBar()
    if not cfFramesDB.WatchedBar then return end

    ApplyVisibility()

    -- The XP and reputation text parents (MainMenuBarOverlayFrame,
    -- ReputationWatchBar.OverlayFrame) render at DIALOG strata by Blizzard default -- a
    -- strata above the windowed WorldMapFrame (MEDIUM), so the text we force persistently on
    -- bled through the open map. Drop them to the bar's own MEDIUM strata: the map's
    -- high-frame-level content then occludes the text where they overlap, while it still
    -- draws above the bar art (a lower level within MEDIUM) everywhere else.
    MainMenuBarOverlayFrame:SetFrameStrata("MEDIUM")
    ReputationWatchBar.OverlayFrame:SetFrameStrata("MEDIUM")

    -- Blizzard doesn't re-render rep on statusTextDisplay changes -- trigger it ourselves;
    -- the hook below picks up the rest.
    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(_, _, arg1)
        if arg1 == "statusTextDisplay" then MainMenuBar_UpdateExperienceBars() end
    end)
    frame:RegisterEvent("CVAR_UPDATE")

    hooksecurefunc("MainMenuBar_UpdateExperienceBars", function()
        ApplyVisibility()
        OverrideRep()
    end)
end
