-- prey_spellscanner.lua
-- Spell Scanner System for Combat-Safe Buff Detection
--
-- Scans spell/item → buff mappings out of combat
-- Detects active states via UNIT_SPELLCAST_SUCCEEDED (works everywhere)
-- Enables accurate tracking of trinkets, potions, and class abilities during combat

local ADDON_NAME, _ = ...
local PREY = PreyUI

---------------------------------------------------------------------------
-- MODULE STATE
---------------------------------------------------------------------------
local SpellScanner = {}
PREY.SpellScanner = SpellScanner

-- Runtime state: currently active buffs
-- Structure: { [spellID] = { startTime, duration, expirationTime, source, sourceId } }
SpellScanner.activeBuffs = {}

-- Pending scanning: spells cast in combat that we'll try to scan after
-- Structure: { [spellID] = { timestamp, itemID (optional) } }
SpellScanner.pendingScanning = {}

-- Scan mode toggle (explicit /preyscan)
SpellScanner.scanMode = false

-- Auto-scan: try to scan unknown spells when cast out of combat (off by default)
-- Stored in database for persistence
SpellScanner.autoScan = false

-- Callback for UI refresh when spell is scanned (set by options panel)
SpellScanner.onScanCallback = nil

---------------------------------------------------------------------------
-- DATABASE ACCESS
-- Uses PreyUI.db.global.spellScanner for cross-character persistence
---------------------------------------------------------------------------

local function GetDB()
    if PREY and PREY.db and PREY.db.global then
        if not PREY.db.global.spellScanner then
            PREY.db.global.spellScanner = {
                spells = {},  -- [castSpellID] = { buffSpellID, duration, icon, name }
                items = {},   -- [itemID] = { useSpellID, buffSpellID, duration, icon, name }
                autoScan = false,  -- Auto-scan setting (off by default)
            }
        end
        -- Load autoScan from DB into runtime state
        if PREY.db.global.spellScanner.autoScan ~= nil then
            SpellScanner.autoScan = PREY.db.global.spellScanner.autoScan
        end
        return PREY.db.global.spellScanner
    end
    return nil
end

local function GetScannedSpell(spellID)
    local db = GetDB()
    if db and db.spells and db.spells[spellID] then
        return db.spells[spellID]
    end
    return nil
end

local function GetScannedItem(itemID)
    local db = GetDB()
    if db and db.items and db.items[itemID] then
        return db.items[itemID]
    end
    return nil
end

local function SaveScannedSpell(castSpellID, data)
    local db = GetDB()
    if not db then return false end

    db.spells[castSpellID] = {
        buffSpellID = data.buffSpellID,
        duration = data.duration,
        icon = data.icon,
        name = data.name,
        scannedAt = time(),
    }
    return true
end

local function SaveScannedItem(itemID, data)
    local db = GetDB()
    if not db then return false end

    db.items[itemID] = {
        useSpellID = data.useSpellID,
        buffSpellID = data.buffSpellID,
        duration = data.duration,
        icon = data.icon,
        name = data.name,
        scannedAt = time(),
    }
    return true
end

---------------------------------------------------------------------------
-- SCANNING LOGIC
---------------------------------------------------------------------------

local function ScanSpellFromBuffs(castSpellID, itemID)
    if InCombatLockdown() then
        -- Queue for post-combat scanning
        SpellScanner.pendingScanning[castSpellID] = {
            timestamp = GetTime(),
            itemID = itemID,
        }
        return false
    end

    -- Already scanned?
    if GetScannedSpell(castSpellID) then
        return true
    end

    -- Scan player buffs for recently applied ones
    local now = GetTime()
    local bestMatch = nil

    for i = 1, 40 do
        -- Wrap in pcall for combat safety (12.0.1 forbidden table protection)
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok or not aura then break end

        -- In 12.0.1, aura fields can be secret values - safely extract them
        local spellId, icon, name, auraInstanceID
        pcall(function()
            spellId = aura.spellId
            icon = aura.icon
            name = aura.name
            auraInstanceID = aura.auraInstanceID
        end)
        
        -- Skip if we couldn't get basic data
        if not auraInstanceID then
            -- Continue to next aura
        else
            -- Get timing info from duration object (combat-safe in 12.0.1)
            local duration, expirationTime, buffAge = nil, nil, 999
            
            if C_UnitAuras.GetAuraDuration then
                local durOk, durationObj = pcall(C_UnitAuras.GetAuraDuration, "player", auraInstanceID)
                if durOk and durationObj then
                    local eOK, elapsed = pcall(durationObj.GetElapsedDuration, durationObj)
                    local rOK, remaining = pcall(durationObj.GetRemainingDuration, durationObj)
                    if eOK and rOK and elapsed and remaining then
                        duration = elapsed + remaining
                        expirationTime = now + remaining
                        buffAge = elapsed
                    end
                end
            end

            -- Look for buffs applied in last 2 seconds with meaningful duration (>= 3s)
            local isRecentBuff = false
            if duration and buffAge then
                pcall(function()
                    isRecentBuff = buffAge < 2 and duration >= 3
                end)
            end

            if isRecentBuff then
                if not bestMatch or buffAge < bestMatch.age then
                    bestMatch = {
                        spellId = spellId,
                        duration = duration,
                    icon = icon,
                    name = name,
                    age = buffAge,
                    expirationTime = expirationTime,
                }
            end
        end
        end  -- end of else block for auraInstanceID check
    end

    if bestMatch then
        -- Save the mapping
        local success = SaveScannedSpell(castSpellID, {
            buffSpellID = bestMatch.spellId,
            duration = bestMatch.duration,
            icon = bestMatch.icon,
            name = bestMatch.name,
        })

        if success then
            -- Also save item mapping if this was an item use
            if itemID then
                SaveScannedItem(itemID, {
                    useSpellID = castSpellID,
                    buffSpellID = bestMatch.spellId,
                    duration = bestMatch.duration,
                    icon = bestMatch.icon,
                    name = bestMatch.name,
                })
            end

            -- Immediately activate the buff
            SpellScanner.activeBuffs[castSpellID] = {
                startTime = bestMatch.expirationTime - bestMatch.duration,
                duration = bestMatch.duration,
                expirationTime = bestMatch.expirationTime,
                source = itemID and "item" or "spell",
                sourceId = itemID or castSpellID,
            }

            -- Notify user in scan mode
            if SpellScanner.scanMode then
                print(string.format("|cff00ff00PreyUI:|r Scanned: %s = %.1fs",
                    bestMatch.name, bestMatch.duration))
            end

            -- Trigger UI refresh callback if registered
            if SpellScanner.onScanCallback then
                SpellScanner.onScanCallback()
            end

            return true
        end
    end

    return false
end

local function ProcessPendingScanning()
    if InCombatLockdown() then return end
    if not next(SpellScanner.pendingScanning) then return end

    for spellID, data in pairs(SpellScanner.pendingScanning) do
        -- Try to scan this spell now
        ScanSpellFromBuffs(spellID, data.itemID)
        SpellScanner.pendingScanning[spellID] = nil
    end
end

---------------------------------------------------------------------------
-- SPELL CAST DETECTION
---------------------------------------------------------------------------

local function OnSpellCastSucceeded(unit, castGUID, spellID)
    if unit ~= "player" then return end
    if not spellID or spellID <= 0 then return end

    -- Check if this spell is already scanned
    local data = GetScannedSpell(spellID)

    if data then
        -- Known spell: activate buff tracking (if we have valid duration data)
        local duration = data.duration
        if duration and type(duration) == "number" and duration > 0 then
            local now = GetTime()
            SpellScanner.activeBuffs[spellID] = {
                startTime = now,
                duration = duration,
                expirationTime = now + duration,
                source = "spell",
                sourceId = spellID,
            }
        end
        -- Even without duration data, we treat this as "known" and skip further scanning
        return
    end

    -- Unknown spell: try to scan if enabled
    if SpellScanner.scanMode or SpellScanner.autoScan then
        if InCombatLockdown() then
            -- Queue for post-combat scanning
            SpellScanner.pendingScanning[spellID] = {
                timestamp = GetTime(),
                itemID = nil,
            }
        else
            -- Scan immediately (with small delay for buff to appear)
            C_Timer.After(0.3, function()
                ScanSpellFromBuffs(spellID, nil)
            end)
        end
    end
end

---------------------------------------------------------------------------
-- CACHE MAINTENANCE
---------------------------------------------------------------------------

local function CleanupExpiredBuffs()
    local now = GetTime()
    for spellID, data in pairs(SpellScanner.activeBuffs) do
        if data.expirationTime and data.expirationTime < now then
            SpellScanner.activeBuffs[spellID] = nil
        end
    end
end

---------------------------------------------------------------------------
-- PUBLIC API (for Custom Trackers)
---------------------------------------------------------------------------

-- Check if a spell's buff is currently active
-- Returns: isActive, expirationTime, duration
function SpellScanner.IsSpellActive(spellID)
    if not spellID then return false end

    local buff = SpellScanner.activeBuffs[spellID]
    if buff and buff.expirationTime > GetTime() then
        return true, buff.expirationTime, buff.duration
    end

    -- Also check if this is a known spell with buff still applied
    -- (handles cases where we missed the cast event)
    local data = GetScannedSpell(spellID)
    if data and data.buffSpellID and not InCombatLockdown() then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, data.buffSpellID)
        if ok and aura then
            -- Safely extract auraInstanceID (can be forbidden in 12.0.1)
            local auraInstanceID
            pcall(function() auraInstanceID = aura.auraInstanceID end)
            
            if auraInstanceID then
                -- Use duration object API (combat-safe in 12.0.1)
                if C_UnitAuras.GetAuraDuration then
                    local durOk, durationObj = pcall(C_UnitAuras.GetAuraDuration, "player", auraInstanceID)
                    if durOk and durationObj then
                        local eOK, elapsed = pcall(durationObj.GetElapsedDuration, durationObj)
                        local rOK, remaining = pcall(durationObj.GetRemainingDuration, durationObj)
                        if eOK and rOK and elapsed and remaining then
                            local totalDuration = elapsed + remaining
                            local expirationTime = GetTime() + remaining
                            return true, expirationTime, totalDuration
                        end
                    end
                end
                -- Aura exists but couldn't get timing - still report as active
                return true, nil, nil
            end
        end
    end

    return false
end

-- Check if an item's buff is currently active
-- Returns: isActive, expirationTime, duration
function SpellScanner.IsItemActive(itemID)
    if not itemID then return false end

    local data = GetScannedItem(itemID)
    if data and data.useSpellID then
        return SpellScanner.IsSpellActive(data.useSpellID)
    end

    return false
end

-- Check if a spellID has been scanned
function SpellScanner.IsSpellScanned(spellID)
    return GetScannedSpell(spellID) ~= nil
end

-- Get scanned duration for a spell (or nil if not scanned)
function SpellScanner.GetScannedDuration(spellID)
    local data = GetScannedSpell(spellID)
    return data and data.duration or nil
end

-- Toggle scan mode
function SpellScanner.ToggleScanMode()
    SpellScanner.scanMode = not SpellScanner.scanMode
    return SpellScanner.scanMode
end

-- Toggle auto-scan and persist to DB
function SpellScanner.ToggleAutoScan()
    SpellScanner.autoScan = not SpellScanner.autoScan
    local db = GetDB()
    if db then
        db.autoScan = SpellScanner.autoScan
    end
    return SpellScanner.autoScan
end

-- Set auto-scan and persist to DB
function SpellScanner.SetAutoScan(enabled)
    SpellScanner.autoScan = enabled
    local db = GetDB()
    if db then
        db.autoScan = enabled
    end
end

-- Manual trigger to scan a spell (for testing)
function SpellScanner.ScanSpell(spellID, itemID)
    return ScanSpellFromBuffs(spellID, itemID)
end

---------------------------------------------------------------------------
-- EVENT HANDLING
---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    if event == "PLAYER_LOGIN" then
        -- Initialize database
        GetDB()

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Process pending scanning after combat
        C_Timer.After(0.3, ProcessPendingScanning)

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        OnSpellCastSucceeded(arg1, arg2, arg3)
    end
end)

-- Periodic cleanup of expired buffs (stored reference for potential cancellation)
SpellScanner.cleanupTicker = C_Timer.NewTicker(1, CleanupExpiredBuffs)

---------------------------------------------------------------------------
-- SLASH COMMANDS
---------------------------------------------------------------------------

-- /preyscan - Toggle scan mode
SLASH_PREYSCAN1 = "/preyscan"
SLASH_PREYSCAN2 = "/quiscan"
SlashCmdList["PREYSCAN"] = function()
    local enabled = SpellScanner.ToggleScanMode()
    if enabled then
        print("|cff00ff00PreyUI:|r Scan mode |cff00ff00ENABLED|r")
        print("|cffff8800-|r Cast abilities to scan their durations")
        print("|cffff8800-|r Type /preyscan again to stop")
    else
        print("|cff00ff00PreyUI:|r Scan mode |cffff0000DISABLED|r")
    end
end

-- /preyscanned - List scanned spells
SLASH_PREYSCANNED1 = "/preyscanned"
SLASH_PREYSCANNED2 = "/quiscanned"
SlashCmdList["PREYSCANNED"] = function()
    local db = GetDB()
    if not db then
        print("|cffff0000PreyUI:|r Database not available")
        return
    end

    print("|cff00ff00PreyUI Scanned Spells:|r")
    local spellCount = 0
    for spellID, data in pairs(db.spells or {}) do
        print(string.format("  [%d] %s = %.1fs", spellID, data.name or "?", data.duration or 0))
        spellCount = spellCount + 1
    end
    if spellCount == 0 then
        print("  |cff888888(none)|r")
    else
        print(string.format("  |cff888888Total: %d spells|r", spellCount))
    end

    print("|cff00ff00PreyUI Scanned Items:|r")
    local itemCount = 0
    for itemID, data in pairs(db.items or {}) do
        local itemName = C_Item.GetItemNameByID(itemID) or "Item " .. itemID
        print(string.format("  [%d] %s = %.1fs", itemID, itemName, data.duration or 0))
        itemCount = itemCount + 1
    end
    if itemCount == 0 then
        print("  |cff888888(none)|r")
    end

    -- Show pending queue
    local pendingCount = 0
    for spellID, data in pairs(SpellScanner.pendingScanning) do
        pendingCount = pendingCount + 1
    end
    if pendingCount > 0 then
        print(string.format("|cffff8800Pending scanning: %d spells|r", pendingCount))
    end

    -- Show active buffs
    local activeCount = 0
    for _ in pairs(SpellScanner.activeBuffs) do
        activeCount = activeCount + 1
    end
    print(string.format("|cff888888Active buffs tracked: %d|r", activeCount))
end

-- /preyclearspell <spellID> - Remove a scanned spell
SLASH_PREYCLEARSPELL1 = "/preyclearspell"
SlashCmdList["PREYCLEARSPELL"] = function(msg)
    local spellID = tonumber(msg:trim())
    if not spellID then
        print("|cffff0000PreyUI:|r Usage: /preyclearspell <spellID>")
        return
    end

    local db = GetDB()
    if db and db.spells and db.spells[spellID] then
        local name = db.spells[spellID].name or "Unknown"
        db.spells[spellID] = nil
        print(string.format("|cff00ff00PreyUI:|r Cleared spell: %s [%d]", name, spellID))
    else
        print(string.format("|cffff8800PreyUI:|r Spell %d not found in scanned list", spellID))
    end
end
