local ADDON_NAME, _ = ...
local PREY = PreyUI


local SpellScanner = {}
PREY.SpellScanner = SpellScanner


SpellScanner.activeBuffs = {}


SpellScanner.pendingScanning = {}


SpellScanner.scanMode = false


SpellScanner.autoScan = false


SpellScanner.onScanCallback = nil


local function GetDB()
    if PREY and PREY.db and PREY.db.global then
        if not PREY.db.global.spellScanner then
            PREY.db.global.spellScanner = {
                spells = {},
                items = {},
                autoScan = false,
            }
        end

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


local function ScanSpellFromBuffs(castSpellID, itemID)
    if InCombatLockdown() then

        SpellScanner.pendingScanning[castSpellID] = {
            timestamp = GetTime(),
            itemID = itemID,
        }
        return false
    end


    if GetScannedSpell(castSpellID) then
        return true
    end


    local now = GetTime()
    local bestMatch = nil

    for i = 1, 40 do

        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
        if not ok or not aura then break end


        local spellId, icon, name, auraInstanceID
        pcall(function()
            spellId = aura.spellId
            icon = aura.icon
            name = aura.name
            auraInstanceID = aura.auraInstanceID
        end)


        if not auraInstanceID then

        else

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
        end
    end

    if bestMatch then

        local success = SaveScannedSpell(castSpellID, {
            buffSpellID = bestMatch.spellId,
            duration = bestMatch.duration,
            icon = bestMatch.icon,
            name = bestMatch.name,
        })

        if success then

            if itemID then
                SaveScannedItem(itemID, {
                    useSpellID = castSpellID,
                    buffSpellID = bestMatch.spellId,
                    duration = bestMatch.duration,
                    icon = bestMatch.icon,
                    name = bestMatch.name,
                })
            end


            SpellScanner.activeBuffs[castSpellID] = {
                startTime = bestMatch.expirationTime - bestMatch.duration,
                duration = bestMatch.duration,
                expirationTime = bestMatch.expirationTime,
                source = itemID and "item" or "spell",
                sourceId = itemID or castSpellID,
            }


            if SpellScanner.scanMode then
                print(string.format("|cff00ff00PreyUI:|r Scanned: %s = %.1fs",
                    bestMatch.name, bestMatch.duration))
            end


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

        ScanSpellFromBuffs(spellID, data.itemID)
        SpellScanner.pendingScanning[spellID] = nil
    end
end


local function OnSpellCastSucceeded(unit, castGUID, spellID)
    if unit ~= "player" then return end
    if not spellID or spellID <= 0 then return end


    local data = GetScannedSpell(spellID)

    if data then

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

        return
    end


    if SpellScanner.scanMode or SpellScanner.autoScan then
        if InCombatLockdown() then

            SpellScanner.pendingScanning[spellID] = {
                timestamp = GetTime(),
                itemID = nil,
            }
        else

            C_Timer.After(0.3, function()
                ScanSpellFromBuffs(spellID, nil)
            end)
        end
    end
end


local function CleanupExpiredBuffs()
    local now = GetTime()
    for spellID, data in pairs(SpellScanner.activeBuffs) do
        if data.expirationTime and data.expirationTime < now then
            SpellScanner.activeBuffs[spellID] = nil
        end
    end
end


function SpellScanner.IsSpellActive(spellID)
    if not spellID then return false end

    local buff = SpellScanner.activeBuffs[spellID]
    if buff and buff.expirationTime > GetTime() then
        return true, buff.expirationTime, buff.duration
    end


    local data = GetScannedSpell(spellID)
    if data and data.buffSpellID and not InCombatLockdown() then
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, data.buffSpellID)
        if ok and aura then

            local auraInstanceID
            pcall(function() auraInstanceID = aura.auraInstanceID end)

            if auraInstanceID then

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

                return true, nil, nil
            end
        end
    end

    return false
end


function SpellScanner.IsItemActive(itemID)
    if not itemID then return false end

    local data = GetScannedItem(itemID)
    if data and data.useSpellID then
        return SpellScanner.IsSpellActive(data.useSpellID)
    end

    return false
end


function SpellScanner.IsSpellScanned(spellID)
    return GetScannedSpell(spellID) ~= nil
end


function SpellScanner.GetScannedDuration(spellID)
    local data = GetScannedSpell(spellID)
    return data and data.duration or nil
end


function SpellScanner.ToggleScanMode()
    SpellScanner.scanMode = not SpellScanner.scanMode
    return SpellScanner.scanMode
end


function SpellScanner.ToggleAutoScan()
    SpellScanner.autoScan = not SpellScanner.autoScan
    local db = GetDB()
    if db then
        db.autoScan = SpellScanner.autoScan
    end
    return SpellScanner.autoScan
end


function SpellScanner.SetAutoScan(enabled)
    SpellScanner.autoScan = enabled
    local db = GetDB()
    if db then
        db.autoScan = enabled
    end
end


function SpellScanner.ScanSpell(spellID, itemID)
    return ScanSpellFromBuffs(spellID, itemID)
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3)
    if event == "PLAYER_LOGIN" then

        GetDB()

    elseif event == "PLAYER_REGEN_ENABLED" then

        C_Timer.After(0.3, ProcessPendingScanning)

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        OnSpellCastSucceeded(arg1, arg2, arg3)
    end
end)


SpellScanner.cleanupTicker = C_Timer.NewTicker(1, CleanupExpiredBuffs)


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


    local pendingCount = 0
    for spellID, data in pairs(SpellScanner.pendingScanning) do
        pendingCount = pendingCount + 1
    end
    if pendingCount > 0 then
        print(string.format("|cffff8800Pending scanning: %d spells|r", pendingCount))
    end


    local activeCount = 0
    for _ in pairs(SpellScanner.activeBuffs) do
        activeCount = activeCount + 1
    end
    print(string.format("|cff888888Active buffs tracked: %d|r", activeCount))
end


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
