local addonName, ns = ...

---------------------------------------------------------------------------
-- M+ DUNGEON TELEPORT MODULE
-- Click dungeon icons in the Challenges frame to teleport.
-- Spell is gated by the player completing the dungeon at +10 or higher.
-- Uses dungeon data from prey_dungeon_data.lua.
---------------------------------------------------------------------------

local MIN_KEY_LEVEL = 10   -- key level required to earn the teleport spell

---------------------------------------------------------------------------
-- SETTINGS
---------------------------------------------------------------------------

local function IsEnabled()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
    return settings and settings.mplusTeleportEnabled ~= false
end

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------

-- Returns the best key level this season for a given challenge map ID, or 0.
local function GetSeasonBest(mapID)
    if not (C_MythicPlus and C_MythicPlus.GetSeasonBestForMap) then return 0 end
    local best = C_MythicPlus.GetSeasonBestForMap(mapID)
    if not best then return 0 end
    -- Handle both table and multi-return API forms across WoW versions.
    if type(best) == "table" then
        return best.level or 0
    end
    return tonumber(best) or 0
end

-- True if the player has the teleport spell in their spellbook.
local function KnowsSpell(spellID)
    if C_Spell and C_Spell.IsSpellKnown then
        return C_Spell.IsSpellKnown(spellID)
    end
    return IsSpellKnown and IsSpellKnown(spellID) or false
end

-- Colored text helper (r/g/b in 0-1 range).
local function ColorText(r, g, b, text)
    return string.format("|cff%02x%02x%02x%s|r",
        math.floor(r * 255), math.floor(g * 255), math.floor(b * 255), text)
end

---------------------------------------------------------------------------
-- TOOLTIP
---------------------------------------------------------------------------

local function ShowTeleportTooltip(anchor, mapID, spellID)
    local dungeonName = C_ChallengeMode.GetMapUIInfo(mapID) or "Unknown Dungeon"
    local bestLevel   = GetSeasonBest(mapID)
    local hasSpell    = spellID and KnowsSpell(spellID)

    GameTooltip:SetOwner(anchor, "ANCHOR_BOTTOM", 0, -4)
    GameTooltip:ClearLines()

    -- Title
    GameTooltip:AddLine(dungeonName, 1, 1, 1)

    -- Season best
    if bestLevel > 0 then
        local r, g, b = 1, 1, 1
        if ns.DungeonData and ns.DungeonData.GetKeyColor then
            r, g, b = ns.DungeonData.GetKeyColor(bestLevel)
        end
        GameTooltip:AddLine("Season best: " .. ColorText(r, g, b, "+" .. bestLevel), 1, 1, 1)
    else
        GameTooltip:AddLine("Season best: " .. ColorText(0.6, 0.6, 0.6, "None"), 1, 1, 1)
    end

    -- Spacer
    GameTooltip:AddLine(" ")

    -- Teleport status
    if not spellID then
        GameTooltip:AddLine(ColorText(0.6, 0.6, 0.6, "No teleport available for this dungeon."))
    elseif hasSpell then
        GameTooltip:AddLine(ColorText(0.2, 1, 0.4, "Click to teleport!"))
        GameTooltip:AddLine(ColorText(0.7, 0.7, 0.7, "Left-click to cast teleport spell."))
    else
        GameTooltip:AddLine(ColorText(1, 0.6, 0.1, "Teleport locked."))
        GameTooltip:AddLine(
            ColorText(0.7, 0.7, 0.7,
                string.format("Complete this dungeon at +%d or higher", MIN_KEY_LEVEL) ..
                " to unlock the teleport spell."
            )
        )
    end

    GameTooltip:Show()
end

---------------------------------------------------------------------------
-- OVERLAY CREATION
---------------------------------------------------------------------------

local function CreateTeleportOverlay(dungeonIcon, mapID, spellID)
    if dungeonIcon.preyTeleportOverlay then return end
    if InCombatLockdown() then return end

    local hasSpell = spellID and KnowsSpell(spellID)

    -- Build the overlay.  Always use a secure button so Blizzard's protected
    -- spell-cast path is used; it just won't do anything useful when not known.
    local overlay = CreateFrame("Button", nil, dungeonIcon, "SecureActionButtonTemplate")
    overlay:SetAllPoints(dungeonIcon)
    overlay:SetFrameLevel(dungeonIcon:GetFrameLevel() + 10)
    overlay:RegisterForClicks("AnyUp", "AnyDown")

    if hasSpell and spellID then
        overlay:SetAttribute("type", "spell")
        overlay:SetAttribute("spell", spellID)
    else
        -- Not yet unlocked — make it a display-only button (no action).
        overlay:SetAttribute("type", "macro")
        overlay:SetAttribute("macrotext", "")
    end

    -- Highlight texture indicating availability.
    local highlight = overlay:CreateTexture(nil, "OVERLAY")
    highlight:SetAllPoints()
    if hasSpell then
        highlight:SetColorTexture(0.15, 0.9, 0.35, 0.25)   -- green: can teleport
    else
        highlight:SetColorTexture(0.9, 0.5, 0.05, 0.18)    -- amber: locked
    end
    highlight:Hide()
    overlay.highlight = highlight

    overlay:SetScript("OnEnter", function(self)
        highlight:Show()
        ShowTeleportTooltip(self, mapID, spellID)
    end)

    overlay:SetScript("OnLeave", function(self)
        highlight:Hide()
        GameTooltip:Hide()
    end)

    dungeonIcon.preyTeleportOverlay = overlay
    return overlay
end

-- Refresh a previously-created overlay (e.g. after the player learns the spell).
local function RefreshOverlay(dungeonIcon, mapID, spellID)
    if not dungeonIcon.preyTeleportOverlay then return end
    if InCombatLockdown() then return end

    local overlay = dungeonIcon.preyTeleportOverlay
    local hasSpell = spellID and KnowsSpell(spellID)

    if hasSpell and spellID then
        overlay:SetAttribute("type", "spell")
        overlay:SetAttribute("spell", spellID)
        overlay.highlight:SetColorTexture(0.15, 0.9, 0.35, 0.25)
    else
        overlay:SetAttribute("type", "macro")
        overlay:SetAttribute("macrotext", "")
        overlay.highlight:SetColorTexture(0.9, 0.5, 0.05, 0.18)
    end
end

---------------------------------------------------------------------------
-- CHALLENGE FRAME HOOK
---------------------------------------------------------------------------

local function HookDungeonIcons()
    if not ChallengesFrame or not ChallengesFrame.DungeonIcons then return end

    for _, dungeonIcon in ipairs(ChallengesFrame.DungeonIcons) do
        local mapID = dungeonIcon.mapID
        if mapID then
            local spellID = _G.PREY_DungeonData and _G.PREY_DungeonData.GetTeleportSpellID(mapID)
            -- Only create an overlay when we have a known spell for this dungeon.
            if spellID then
                if dungeonIcon.preyTeleportOverlay then
                    RefreshOverlay(dungeonIcon, mapID, spellID)
                else
                    CreateTeleportOverlay(dungeonIcon, mapID, spellID)
                end
            end
        end
    end
end

local function OnChallengesFrameUpdate()
    if not IsEnabled() then return end
    C_Timer.After(0.15, HookDungeonIcons)
end

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

local teleportFrame = CreateFrame("Frame")
local hooked = false

teleportFrame:RegisterEvent("ADDON_LOADED")
teleportFrame:RegisterEvent("SPELLS_CHANGED")          -- fires when spells are learned/removed
teleportFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

teleportFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_ChallengesUI" then
            if not hooked and ChallengesFrame then
                hooksecurefunc(ChallengesFrame, "Update", OnChallengesFrameUpdate)
                hooked = true
            end
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        -- Refresh overlays whenever the spellbook changes (e.g. player just
        -- earned a +10 teleport) or on world entry after a reload.
        if hooked then
            C_Timer.After(0.5, HookDungeonIcons)
        end
    end
end)

-- Handle case where Blizzard_ChallengesUI is already loaded before we register.
if C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") and ChallengesFrame then
    hooksecurefunc(ChallengesFrame, "Update", OnChallengesFrameUpdate)
    hooked = true
end
