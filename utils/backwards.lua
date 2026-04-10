local function MigrateDatatextSlots(dt)
    if not dt then return end
    if dt.slots then return end


    dt.slots = {}


    if dt.showTime then table.insert(dt.slots, "time") end
    if dt.showFriends then table.insert(dt.slots, "friends") end
    if dt.showGuild then table.insert(dt.slots, "guild") end


    while #dt.slots < 3 do
        table.insert(dt.slots, "")
    end
end


local function MigratePerSlotSettings(dt)
    if not dt then return end
    if dt.slot1 then return end


    local globalShortLabels = dt.shortLabels or false


    dt.slot1 = { shortLabel = globalShortLabels, xOffset = 0, yOffset = 0 }
    dt.slot2 = { shortLabel = globalShortLabels, xOffset = 0, yOffset = 0 }
    dt.slot3 = { shortLabel = globalShortLabels, xOffset = 0, yOffset = 0 }
end


local function MigrateMasterTextColors(general)
    if not general then return end


    if general.classColorText == true and general.masterColorNameText == nil then
        general.masterColorNameText = true
        general.masterColorHealthText = true

    end


    if general.masterColorNameText == nil then general.masterColorNameText = false end
    if general.masterColorHealthText == nil then general.masterColorHealthText = false end
    if general.masterColorPowerText == nil then general.masterColorPowerText = false end
    if general.masterColorCastbarText == nil then general.masterColorCastbarText = false end
    if general.masterColorToTText == nil then general.masterColorToTText = false end
end


local function MigrateChatEditBox(chat)
    if not chat then return end
    if chat.editBox then return end


    chat.editBox = {
        enabled = chat.styleEditBox ~= false,
        bgAlpha = 0.25,
        bgColor = {0, 0, 0},
    }


    chat.styleEditBox = nil
end


local function MigrateCooldownSwipeV2(profile)
    if not profile then return end
    if not profile.cooldownSwipe then profile.cooldownSwipe = {} end

    local cs = profile.cooldownSwipe
    if cs.migratedToV2 then return end


    local hadHideEssential = cs.hideEssential == true
    local hadHideUtility = cs.hideUtility == true
    local hadHideBuffSwipe = profile.cooldownManager and profile.cooldownManager.hideSwipe == true


    if hadHideEssential or hadHideUtility or hadHideBuffSwipe then
        cs.showBuffSwipe = true
        cs.showGCDSwipe = false
        cs.showCooldownSwipe = true
    else

        cs.showBuffSwipe = true
        cs.showGCDSwipe = true
        cs.showCooldownSwipe = true
    end


    cs.hideEssential = nil
    cs.hideUtility = nil
    if profile.cooldownManager then
        profile.cooldownManager.hideSwipe = nil
    end

    cs.migratedToV2 = true
end

local function GetLegacyProfileDB()
    return rawget(_G, "PreyUI_DB") or rawget(_G, "KoriUI_DB")
end

function PreyUI:BackwardsCompat()


    if self.db and self.db.profile and self.db.profile.datatext then
        MigrateDatatextSlots(self.db.profile.datatext)
        MigratePerSlotSettings(self.db.profile.datatext)
    end


    if self.db and self.db.profile and self.db.profile.quiUnitFrames and self.db.profile.quiUnitFrames.general then
        MigrateMasterTextColors(self.db.profile.quiUnitFrames.general)
    end


    if self.db and self.db.profile and self.db.profile.chat then
        MigrateChatEditBox(self.db.profile.chat)
    end


    if self.db and self.db.profile then
        MigrateCooldownSwipeV2(self.db.profile)
    end


    if not self.db.global then
        self:DebugPrint("DB Global not found")
        self.db.global = {
            isDone = false,
            lastVersion = 0,
            imports = {}
        }
    end


    if not self.db.global.isDone then
        self.db.global.isDone = false
    end
    if not self.db.global.lastVersion then
        self.db.global.lastVersion = 0
    end
    if not self.db.global.imports then
        self.db.global.imports = {}
    end


    if not self.db.global.specTrackerSpells then
        self.db.global.specTrackerSpells = {}
    end


    if self.db.char then
        if not self.db.char.debug then
            self.db.char.debug = { reload = false }
        end


        if self.db.char.lastVersion and not self.db.global.lastVersion then
            self:DebugPrint("Last version found in char profile, but not global.")
            self.db.global.lastVersion = self.db.char.lastVersion
            self.db.char.lastVersion = nil
        end
    end


    local legacyProfileDB = GetLegacyProfileDB()
    if legacyProfileDB and legacyProfileDB.profiles and legacyProfileDB.profiles.Default then
        self:DebugPrint("Profiles.Default.imports Exists: " .. tostring(not (not legacyProfileDB.profiles.Default.imports)))
        self:DebugPrint("global.imports Exists: " .. tostring(not (not self.db.global.imports)))
        self:DebugPrint("global.imports is {}: " .. tostring(next(self.db.global.imports) == nil))

        if legacyProfileDB.profiles.Default.imports and (not self.db.global.imports or next(self.db.global.imports) == nil) then
            self:DebugPrint("Import Data found in profile imports but not global imports.")
            self.db.global.imports = legacyProfileDB.profiles.Default.imports
        end
    end
end
