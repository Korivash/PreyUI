local addonName, ns = ...

---------------------------------------------------------------------------
-- SHARED DUNGEON DATA
-- Central source of truth for dungeon short names and teleport spells.
-- Used by: prey_datatexts.lua, prey_dungeon_teleport.lua, prey_mplus_timer.lua
--
-- NAME_TO_SHORT  — dungeon display name → abbreviation (expansion-agnostic;
--                  names come from C_ChallengeMode.GetMapUIInfo so they stay
--                  accurate even when Blizzard remaps mapIDs between seasons)
--
-- MAPID_TO_SPELL — challenge-mode mapID → teleport spellID.
--                  Only dungeons with a confirmed spell ID appear here.
--                  Dungeons without an entry simply won't receive an overlay.
--
-- TO ADD A NEW DUNGEON:
--   1. Find the mapID with: /script for _,id in ipairs(C_ChallengeMode.GetMapTable()) do print(id, C_ChallengeMode.GetMapUIInfo(id)) end
--   2. Find the spell ID by hovering the spell in your spellbook and running:
--      /script print(GetMouseFocus():GetParent().spellID)
--   3. Add entries to both tables.
---------------------------------------------------------------------------

local factionGroup   = UnitFactionGroup("player")
local SIEGE_SPELL    = factionGroup == "Horde" and 464256  or 445418
local MOTHERLODE_SPELL = factionGroup == "Horde" and 467555 or 467553

---------------------------------------------------------------------------
-- NAME → SHORT ABBREVIATION
---------------------------------------------------------------------------

local NAME_TO_SHORT = {
    -- Classic: Wrath of the Lich King
    ["Pit of Saron"]                        = "PIT",

    -- MoP
    ["Temple of the Jade Serpent"]          = "TJS",
    ["Stormstout Brewery"]                  = "SSB",
    ["Shado-Pan Monastery"]                 = "SPM",
    ["Siege of Niuzao Temple"]              = "SNT",
    ["Gate of the Setting Sun"]             = "GOSS",
    ["Mogu'shan Palace"]                    = "MSP",
    ["Scholomance"]                         = "SCHOLO",
    ["Scarlet Halls"]                       = "SH",
    ["Scarlet Monastery"]                   = "SM",

    -- Warlords of Draenor
    ["Bloodmaul Slag Mines"]                = "BSM",
    ["Auchindoun"]                          = "AUCH",
    ["Skyreach"]                            = "SKY",
    ["Shadowmoon Burial Grounds"]           = "SBG",
    ["Grimrail Depot"]                      = "GD",
    ["Upper Blackrock Spire"]               = "UBRS",
    ["The Everbloom"]                       = "EB",
    ["Iron Docks"]                          = "ID",

    -- Legion
    ["Eye of Azshara"]                      = "EOA",
    ["Darkheart Thicket"]                   = "DHT",
    ["Black Rook Hold"]                     = "BRH",
    ["Halls of Valor"]                      = "HOV",
    ["Neltharion's Lair"]                   = "NL",
    ["Vault of the Wardens"]                = "VAULT",
    ["Maw of Souls"]                        = "MOS",
    ["The Arcway"]                          = "ARC",
    ["Court of Stars"]                      = "COS",
    ["Return to Karazhan: Lower"]           = "LKARA",
    ["Return to Karazhan: Upper"]           = "UKARA",
    ["Seat of the Triumvirate"]             = "SEAT",

    -- Battle for Azeroth
    ["Atal'Dazar"]                          = "AD",
    ["Freehold"]                            = "FH",
    ["The MOTHERLODE!!"]                    = "ML",
    ["Waycrest Manor"]                      = "WM",
    ["Kings' Rest"]                         = "KR",
    ["Temple of Sethraliss"]                = "SETH",
    ["The Underrot"]                        = "UNDR",
    ["Shrine of the Storm"]                 = "SHRINE",
    ["Siege of Boralus"]                    = "SIEGE",
    ["Operation: Mechagon - Junkyard"]      = "YARD",
    ["Operation: Mechagon - Workshop"]      = "WORK",

    -- Shadowlands
    ["Mists of Tirna Scithe"]               = "MISTS",
    ["The Necrotic Wake"]                   = "NW",
    ["De Other Side"]                       = "DOS",
    ["Halls of Atonement"]                  = "HOA",
    ["Plaguefall"]                          = "PF",
    ["Sanguine Depths"]                     = "SD",
    ["Spires of Ascension"]                 = "SOA",
    ["Theater of Pain"]                     = "TOP",
    ["Tazavesh: Streets of Wonder"]         = "STRT",
    ["Tazavesh: So'leah's Gambit"]          = "GMBT",

    -- Dragonflight
    ["Ruby Life Pools"]                     = "RLP",
    ["The Nokhud Offensive"]                = "NO",
    ["The Azure Vault"]                     = "AV",
    ["Algeth'ar Academy"]                   = "AA",
    ["Uldaman: Legacy of Tyr"]              = "ULD",
    ["Neltharus"]                           = "NELTH",
    ["Brackenhide Hollow"]                  = "BH",
    ["Halls of Infusion"]                   = "HOI",
    ["Dawn of the Infinite: Galakrond's Fall"]  = "DOTI-G",
    ["Dawn of the Infinite: Murozond's Rise"]   = "DOTI-M",

    -- Cataclysm
    ["Vortex Pinnacle"]                     = "VP",
    ["Throne of the Tides"]                 = "TOTT",

    -- The War Within
    ["Priory of the Sacred Flame"]          = "PSF",
    ["The Rookery"]                         = "ROOK",
    ["The Stonevault"]                      = "SV",
    ["City of Threads"]                     = "COT",
    ["Ara-Kara, City of Echoes"]            = "ARAK",
    ["Darkflame Cleft"]                     = "DFC",
    ["The Dawnbreaker"]                     = "DAWN",
    ["Cinderbrew Meadery"]                  = "BREW",
    ["Grim Batol"]                          = "GB",
    ["Operation: Floodgate"]                = "FLOOD",
    ["Eco-Dome Al'dani"]                    = "EDA",

    -- Midnight (12.x) — Season 1
    ["Windrunner Spire"]                    = "WIND",
    ["Magisters' Terrace"]                  = "MAGI",
    ["Nexus-Point Xenas"]                   = "XENAS",
    ["Maisara Caverns"]                     = "CAVNS",
    ["Murder Row"]                          = "MURDR",
    ["The Blinding Vale"]                   = "BLIND",
    ["Den of Nalorakk"]                     = "NALO",
    ["The Foraging"]                        = "FORAG",
    ["Voidscar Arena"]                      = "VSCAR",
    ["The Heart of Rage"]                   = "RAGE",
    ["Voidstorm"]                           = "VSTORM",
}

---------------------------------------------------------------------------
-- MAPID → TELEPORT SPELL
-- Only include dungeons where the spell ID has been confirmed in-game.
-- Unconfirmed entries are left out so the overlay is never created for them.
---------------------------------------------------------------------------

local MAPID_TO_SPELL = {
    -------------------------------------------------------------------------
    -- Classic: Wrath
    -------------------------------------------------------------------------
    [556] = 1254555,    -- Pit of Saron

    -------------------------------------------------------------------------
    -- Mists of Pandaria
    -------------------------------------------------------------------------
    [2]   = 131204,     -- Temple of the Jade Serpent
    [56]  = 131205,     -- Stormstout Brewery
    [57]  = 131206,     -- Shado-Pan Monastery
    [58]  = 131228,     -- Siege of Niuzao Temple
    [59]  = 131225,     -- Gate of the Setting Sun
    [60]  = 131222,     -- Mogu'shan Palace
    [76]  = 131232,     -- Scholomance
    [77]  = 131231,     -- Scarlet Halls
    [78]  = 131229,     -- Scarlet Monastery

    -------------------------------------------------------------------------
    -- Warlords of Draenor
    -------------------------------------------------------------------------
    [161] = 159895,     -- Bloodmaul Slag Mines
    [163] = 159897,     -- Auchindoun
    [164] = 159898,     -- Skyreach
    [165] = 159899,     -- Shadowmoon Burial Grounds
    [166] = 159900,     -- Grimrail Depot
    [167] = 159902,     -- Upper Blackrock Spire
    [168] = 159901,     -- The Everbloom
    [169] = 159896,     -- Iron Docks

    -------------------------------------------------------------------------
    -- Legion
    -------------------------------------------------------------------------
    [198] = 424163,     -- Darkheart Thicket
    [199] = 424153,     -- Black Rook Hold
    [200] = 393764,     -- Halls of Valor
    [206] = 410078,     -- Neltharion's Lair
    [210] = 393766,     -- Court of Stars
    [227] = 373262,     -- Return to Karazhan: Lower
    [234] = 373262,     -- Return to Karazhan: Upper (same portal spell)
    [239] = 1254551,    -- Seat of the Triumvirate

    -------------------------------------------------------------------------
    -- Battle for Azeroth
    -------------------------------------------------------------------------
    [244] = 424187,     -- Atal'Dazar
    [245] = 410071,     -- Freehold
    [247] = MOTHERLODE_SPELL,
    [248] = 424167,     -- Waycrest Manor
    [251] = 410074,     -- The Underrot
    [353] = SIEGE_SPELL,
    [369] = 373274,     -- Operation: Mechagon - Junkyard
    [370] = 373274,     -- Operation: Mechagon - Workshop (same portal spell)

    -------------------------------------------------------------------------
    -- Shadowlands
    -------------------------------------------------------------------------
    [375] = 354464,     -- Mists of Tirna Scithe
    [376] = 354462,     -- The Necrotic Wake
    [377] = 354468,     -- De Other Side
    [378] = 354465,     -- Halls of Atonement
    [379] = 354463,     -- Plaguefall
    [380] = 354469,     -- Sanguine Depths
    [381] = 354466,     -- Spires of Ascension
    [382] = 354467,     -- Theater of Pain
    [391] = 367416,     -- Tazavesh: Streets of Wonder
    [392] = 367416,     -- Tazavesh: So'leah's Gambit (same portal spell)

    -------------------------------------------------------------------------
    -- Dragonflight
    -------------------------------------------------------------------------
    [399] = 393256,     -- Ruby Life Pools
    [400] = 393262,     -- The Nokhud Offensive
    [401] = 393279,     -- The Azure Vault
    [402] = 393273,     -- Algeth'ar Academy
    [403] = 393222,     -- Uldaman: Legacy of Tyr
    [404] = 393276,     -- Neltharus
    [405] = 393267,     -- Brackenhide Hollow
    [406] = 393283,     -- Halls of Infusion
    [463] = 424197,     -- Dawn of the Infinite: Galakrond's Fall
    [464] = 424197,     -- Dawn of the Infinite: Murozond's Rise (same portal spell)

    -------------------------------------------------------------------------
    -- Cataclysm
    -------------------------------------------------------------------------
    [438] = 410080,     -- Vortex Pinnacle
    [456] = 424142,     -- Throne of the Tides

    -------------------------------------------------------------------------
    -- The War Within
    -------------------------------------------------------------------------
    [499] = 445444,     -- Priory of the Sacred Flame
    [500] = 445443,     -- The Rookery
    [501] = 445269,     -- The Stonevault
    [502] = 445416,     -- City of Threads
    [503] = 445417,     -- Ara-Kara, City of Echoes
    [504] = 445441,     -- Darkflame Cleft
    [505] = 445414,     -- The Dawnbreaker
    [506] = 445440,     -- Cinderbrew Meadery
    [507] = 445424,     -- Grim Batol
    [525] = 1216786,    -- Operation: Floodgate
    [542] = 1237215,    -- Eco-Dome Al'dani

    -------------------------------------------------------------------------
    -- Midnight — Season 1 (12.0.x)
    -- Spell IDs confirmed from spellbook; complete at +10 to unlock.
    -------------------------------------------------------------------------
    [557] = 1254840,    -- Windrunner Spire
    [558] = 1254572,    -- Magisters' Terrace
    [559] = 1254563,    -- Nexus-Point Xenas
    [560] = 1255247,    -- Maisara Caverns
    [561] = 1255801,    -- Murder Row
    [562] = 1255806,    -- The Blinding Vale
    [563] = 1255812,    -- Den of Nalorakk
    [564] = 1255818,    -- The Foraging

    -------------------------------------------------------------------------
    -- Midnight — datamined/alternate mapIDs (backward compatibility)
    -------------------------------------------------------------------------
    [15808] = 1254840,  -- Windrunner Spire (alt)
    [15829] = 1254572,  -- Magisters' Terrace (alt)
    [16573] = 1254563,  -- Nexus-Point Xenas (alt)
    [16395] = 1255247,  -- Maisara Caverns (alt)
    [16400] = 1255801,  -- Murder Row (alt)
    [16405] = 1255806,  -- The Blinding Vale (alt)
    [16410] = 1255812,  -- Den of Nalorakk (alt)
    [16415] = 1255818,  -- The Foraging (alt)
}

---------------------------------------------------------------------------
-- ACCESSOR FUNCTIONS
---------------------------------------------------------------------------

-- Returns the short abbreviation for a dungeon given its challenge mapID.
-- Falls back to an auto-generated abbreviation if the name is not in the table.
local function GetShortName(mapID)
    local name = C_ChallengeMode.GetMapUIInfo(mapID)
    if not name then return "???" end
    local short = NAME_TO_SHORT[name]
    if short then return short end
    -- Auto-abbreviate: use first word if ≤6 chars, else first 4 chars.
    local firstWord = name:match("^(%S+)")
    if firstWord and #firstWord <= 6 then
        return firstWord:upper()
    end
    return name:sub(1, 4):upper()
end

-- Returns the teleport spell ID for a dungeon, or nil if none is known.
local function GetTeleportSpellID(mapID)
    return MAPID_TO_SPELL[mapID]
end

-- Returns { short, spellID } for a mapID (legacy compatibility helper).
local function GetDungeonData(mapID)
    local name = C_ChallengeMode.GetMapUIInfo(mapID)
    if not name then return nil end
    return {
        short   = NAME_TO_SHORT[name] or name:sub(1, 4):upper(),
        spellID = MAPID_TO_SPELL[mapID],
    }
end

-- True if a teleport spell is registered for this mapID.
local function HasTeleport(mapID)
    return MAPID_TO_SPELL[mapID] ~= nil
end

-- Returns r, g, b for a key level (used by timer and datatext modules).
local function GetKeyColor(level)
    if not level or level == 0 then return 0.7, 0.7, 0.7 end
    if level >= 12 then return 1,    0.5,  0    end   -- orange  12+
    if level >= 10 then return 0.64, 0.21, 0.93 end   -- purple  10-11
    if level >= 7  then return 0,    0.44, 0.87 end   -- blue    7-9
    if level >= 5  then return 0.12, 0.75, 0.26 end   -- green   5-6
    return 1, 1, 1                                     -- white   2-4
end

---------------------------------------------------------------------------
-- EXPORT
---------------------------------------------------------------------------

ns.DungeonData = {
    nameToShort       = NAME_TO_SHORT,
    mapIdToSpell      = MAPID_TO_SPELL,
    GetShortName      = GetShortName,
    GetTeleportSpellID = GetTeleportSpellID,
    GetDungeonData    = GetDungeonData,
    HasTeleport       = HasTeleport,
    GetKeyColor       = GetKeyColor,
}

_G.PREY_DungeonData = ns.DungeonData
