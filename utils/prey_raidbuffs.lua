local ADDON_NAME, ns = ...
local PREYCore = ns.Addon
local IsSecretValue = function(v) return ns.Utils and ns.Utils.IsSecretValue and ns.Utils.IsSecretValue(v) or false end


local PREY_RaidBuffs = {}
ns.RaidBuffs = PREY_RaidBuffs


local ICON_SIZE = 32
local ICON_SPACING = 4
local FRAME_PADDING = 6
local UPDATE_THROTTLE = 0.5
local MAX_AURA_INDEX = 40


local RAID_BUFFS = {
    {
        spellId = 21562,
        name = "Power Word: Fortitude",
        stat = "Stamina",
        providerClass = "PRIEST",
        range = 40,
    },
    {
        spellId = 6673,
        name = "Battle Shout",
        stat = "Attack Power",
        providerClass = "WARRIOR",
        range = 100,
    },
    {
        spellId = 1459,
        name = "Arcane Intellect",
        stat = "Intellect",
        providerClass = "MAGE",
        range = 40,
    },
    {
        spellId = 1126,
        name = "Mark of the Wild",
        stat = "Versatility",
        providerClass = "DRUID",
        range = 40,
    },
    {

        spellId = 381748,
        name = "Blessing of the Bronze",
        stat = "Movement Speed",
        providerClass = "EVOKER",
        range = 40,
    },
    {
        spellId = 462854,
        name = "Skyfury",
        stat = "Mastery",
        providerClass = "SHAMAN",
        range = 100,
    },
}


local function GetBuffIcon(spellId)
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(spellId)
    elseif GetSpellTexture then
        return GetSpellTexture(spellId)
    end
    return 134400
end


local mainFrame
local buffIcons = {}
local lastUpdate = 0
local groupClasses = {}
local previewMode = false
local previewBuffs = nil


local function GetSettings()
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.raidBuffs then
        return PREYCore.db.profile.raidBuffs
    end
    return {
        enabled = true,
        showOnlyInGroup = true,
        showOnlyInInstance = false,
        providerMode = false,
        hideLabelBar = false,
        iconSize = 32,
        labelFontSize = 12,
        labelTextColor = nil,
        position = nil,
    }
end


local function SafeBooleanCheck(value)
    if IsSecretValue(value) then
        return nil
    end
    return value
end


local function IsUnitInRange(unit, rangeYards)
    rangeYards = rangeYards or 40
    local rangeSquared = rangeYards * rangeYards


    if UnitDistanceSquared then
        local ok, distSq = pcall(UnitDistanceSquared, unit)
        if ok and distSq then
            local dist = SafeBooleanCheck(distSq)
            if dist and type(dist) == "number" then
                return dist <= rangeSquared
            end
        end
    end


    if rangeYards <= 30 then
        local ok2, canInteract = pcall(CheckInteractDistance, unit, 1)
        if ok2 and canInteract ~= nil then
            local result = SafeBooleanCheck(canInteract)
            if result ~= nil then
                return result
            end
        end
    end


    local ok, inRange, checkedRange = pcall(UnitInRange, unit)
    if ok then
        local safeChecked = SafeBooleanCheck(checkedRange)
        if safeChecked then
            local safeInRange = SafeBooleanCheck(inRange)
            if safeInRange ~= nil then

                if rangeYards > 28 and safeInRange then
                    return true
                end
                return safeInRange
            end
        end
    end


    return true
end


local function IsUnitAvailable(unit, rangeYards)

    local exists = SafeBooleanCheck(UnitExists(unit))
    if not exists then return false end

    local dead = SafeBooleanCheck(UnitIsDeadOrGhost(unit))
    if dead == nil or dead then return false end

    local connected = SafeBooleanCheck(UnitIsConnected(unit))
    if connected == nil or not connected then return false end

    return IsUnitInRange(unit, rangeYards)
end


local function SafeUnitClass(unit)
    local ok, localized, class = pcall(UnitClass, unit)
    if ok and class and type(class) == "string" then
        return class
    end
    return nil
end


local function SafeGetAuraField(auraData, fieldName)
    local success, value = pcall(function() return auraData[fieldName] end)
    if not success then return nil end

    local compareOk = pcall(function() return value == value end)
    if not compareOk then return nil end
    return value
end

local function ScanGroupClasses()
    wipe(groupClasses)


    local playerClass = SafeUnitClass("player")
    if playerClass then
        groupClasses[playerClass] = true
    end


    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            local exists = SafeBooleanCheck(UnitExists(unit))
            local connected = SafeBooleanCheck(UnitIsConnected(unit))
            if exists and connected then
                local class = SafeUnitClass(unit)
                if class then
                    groupClasses[class] = true
                end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            local exists = SafeBooleanCheck(UnitExists(unit))
            local connected = SafeBooleanCheck(UnitIsConnected(unit))
            if exists and connected then
                local class = SafeUnitClass(unit)
                if class then
                    groupClasses[class] = true
                end
            end
        end
    end
end


local function UnitHasBuff(unit, spellId, spellName)
    if not unit then return false end
    local exists = SafeBooleanCheck(UnitExists(unit))
    if not exists then return false end


    if AuraUtil and AuraUtil.ForEachAura then
        local found = false
        AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(auraData)
            if auraData then

                local auraSpellId = SafeGetAuraField(auraData, "spellId")
                local auraName = SafeGetAuraField(auraData, "name")
                if auraSpellId and auraSpellId == spellId then
                    found = true
                elseif spellName and auraName and auraName == spellName then
                    found = true
                end
            end
            if found then return true end
        end, true)
        if found then return true end
    end


    if spellName and C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
        local success, auraData = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, spellName, "HELPFUL")
        if success and auraData then return true end
    end


    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, MAX_AURA_INDEX do
            local success, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
            if not success or not auraData then break end

            local auraSpellId = SafeGetAuraField(auraData, "spellId")
            local auraName = SafeGetAuraField(auraData, "name")
            if auraSpellId and auraSpellId == spellId then
                return true
            elseif spellName and auraName and auraName == spellName then
                return true
            end
        end
    end

    return false
end


local function PlayerHasBuff(spellId, spellName)
    return UnitHasBuff("player", spellId, spellName)
end


local function AnyGroupMemberMissingBuff(spellId, spellName, rangeYards)

    if not PlayerHasBuff(spellId, spellName) then
        return true
    end


    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            local isPlayer = UnitIsUnit(unit, "player")
            if IsUnitAvailable(unit, rangeYards) and not IsSecretValue(isPlayer) and not isPlayer then
                if not UnitHasBuff(unit, spellId, spellName) then
                    return true
                end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            if IsUnitAvailable(unit, rangeYards) then
                if not UnitHasBuff(unit, spellId, spellName) then
                    return true
                end
            end
        end
    end

    return false
end


local function GetPlayerClass()
    return SafeUnitClass("player")
end


local function IsProviderClassInRange(providerClass, rangeYards)
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            local isPlayer = UnitIsUnit(unit, "player")
            if not IsSecretValue(isPlayer) and not isPlayer then
                local class = SafeUnitClass(unit)
                if class == providerClass and IsUnitAvailable(unit, rangeYards) then
                    return true
                end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            local class = SafeUnitClass(unit)
            if class == providerClass and IsUnitAvailable(unit, rangeYards) then
                return true
            end
        end
    end
    return false
end

local function GetMissingBuffs()
    local missing = {}
    local settings = GetSettings()


    if previewMode and previewBuffs then
        return previewBuffs
    end


    if settings.showOnlyInGroup and not IsInGroup() then
        return missing
    end


    if settings.showOnlyInInstance and not ns.Utils.IsInInstancedContent() then
        return missing
    end


    if InCombatLockdown() then
        return missing
    end


    if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then
        return missing
    end


    ScanGroupClasses()

    local playerClass = GetPlayerClass()


    for _, buff in ipairs(RAID_BUFFS) do
        local dominated = false
        local buffRange = buff.range or 40


        if groupClasses[buff.providerClass] and not PlayerHasBuff(buff.spellId, buff.name) then
            if IsProviderClassInRange(buff.providerClass, buffRange) then
                table.insert(missing, buff)
                dominated = true
            end
        end


        if settings.providerMode and not dominated then
            if buff.providerClass == playerClass and AnyGroupMemberMissingBuff(buff.spellId, buff.name, buffRange) then
                table.insert(missing, buff)
            end
        end
    end

    return missing
end


local function CreateBuffIcon(parent, index)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(ICON_SIZE, ICON_SIZE)


    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    button:SetBackdropColor(0, 0, 0, 0.8)


    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 1, -1)
    button.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)


    button:SetScript("OnEnter", function(self)
        if self.buffData then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.buffData.name, 1, 1, 1)
            GameTooltip:AddLine(self.buffData.stat, 0.7, 0.7, 0.7)
            GameTooltip:AddLine(" ")
            local className = LOCALIZED_CLASS_NAMES_MALE[self.buffData.providerClass] or self.buffData.providerClass
            GameTooltip:AddLine("Provided by: " .. className, 0.5, 0.8, 1)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

local function CreateMainFrame()
    if mainFrame then return mainFrame end


    mainFrame = CreateFrame("Frame", "PreyUI_MissingRaidBuffs", UIParent)
    mainFrame:SetSize(200, 70)
    mainFrame:SetPoint("TOP", UIParent, "TOP", 0, -200)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetClampedToScreen(true)
    mainFrame:EnableMouse(true)
    mainFrame:SetMovable(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local settings = GetSettings()
        if settings then
            local point, _, relPoint, x, y = self:GetPoint()
            settings.position = { point = point, relPoint = relPoint, x = x, y = y }
        end
    end)


    mainFrame.iconContainer = CreateFrame("Frame", nil, mainFrame)
    mainFrame.iconContainer:SetPoint("TOP", mainFrame, "TOP", 0, 0)
    mainFrame.iconContainer:SetSize(200, ICON_SIZE)


    mainFrame.labelBar = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    mainFrame.labelBar:SetPoint("TOP", mainFrame.iconContainer, "BOTTOM", 0, -2)
    mainFrame.labelBar:SetSize(100, 18)
    mainFrame.labelBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    mainFrame.labelBar:SetBackdropColor(0.05, 0.05, 0.05, 0.95)


    mainFrame.labelBar.text = mainFrame.labelBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mainFrame.labelBar.text:SetPoint("CENTER", 0, 0)
    mainFrame.labelBar.text:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    mainFrame.labelBar.text:SetText("Missing Buffs")


    for i = 1, #RAID_BUFFS do
        buffIcons[i] = CreateBuffIcon(mainFrame.iconContainer, i)
        buffIcons[i]:Hide()
    end

    mainFrame:Hide()

    return mainFrame
end


local function ApplySkin()
    if not mainFrame then return end

    local PREY = _G.PreyUI
    local sr, sg, sb, sa = 0.820, 0.180, 0.220, 1
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95

    if PREY and PREY.GetSkinColor then
        sr, sg, sb, sa = PREY:GetSkinColor()
    end
    if PREY and PREY.GetSkinBgColor then
        bgr, bgg, bgb, bga = PREY:GetSkinBgColor()
    end


    if mainFrame.labelBar then
        mainFrame.labelBar:SetBackdropColor(bgr, bgg, bgb, bga)
        mainFrame.labelBar:SetBackdropBorderColor(sr, sg, sb, sa)
        if mainFrame.labelBar.text then

            local settings = GetSettings()
            local textColor = settings.labelTextColor
            if textColor then
                mainFrame.labelBar.text:SetTextColor(textColor[1], textColor[2], textColor[3], 1)
            else
                mainFrame.labelBar.text:SetTextColor(1, 1, 1, 1)
            end
        end
    end


    for _, icon in ipairs(buffIcons) do
        icon:SetBackdropBorderColor(sr, sg, sb, sa)
        icon:SetBackdropColor(0, 0, 0, 0.8)
    end

    mainFrame.preySkinColor = { sr, sg, sb, sa }
    mainFrame.preyBgColor = { bgr, bgg, bgb, bga }
end


function PREY_RaidBuffs:RefreshColors()
    ApplySkin()
end

_G.PreyUI_RefreshRaidBuffColors = function()
    PREY_RaidBuffs:RefreshColors()
end


local function UpdateDisplay()
    local settings = GetSettings()
    if not settings.enabled then
        if mainFrame then mainFrame:Hide() end
        return
    end

    if not mainFrame then
        CreateMainFrame()
        ApplySkin()
    end

    local missing = GetMissingBuffs()

    if #missing == 0 then
        mainFrame:Hide()
        return
    end


    local iconSize = settings.iconSize or ICON_SIZE
    local totalWidth = (#missing * iconSize) + ((#missing - 1) * ICON_SPACING)
    local startX = -totalWidth / 2 + iconSize / 2

    for i, icon in ipairs(buffIcons) do
        if i <= #missing then
            local buff = missing[i]
            icon:SetSize(iconSize, iconSize)
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", mainFrame.iconContainer, "CENTER", startX + (i - 1) * (iconSize + ICON_SPACING), 0)
            icon.icon:SetTexture(GetBuffIcon(buff.spellId))
            icon.buffData = buff
            icon:Show()
        else
            icon:Hide()
        end
    end


    local fontSize = settings.labelFontSize or 12
    local labelBarHeight = fontSize + 8
    local labelBarGap = 2

    mainFrame.labelBar.text:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    mainFrame.labelBar.text:SetText("Missing Buffs")


    local hideLabelBar = settings.hideLabelBar
    local minIconsWidth = (3 * iconSize) + (2 * ICON_SPACING)
    local minTextWidth = fontSize * 8 + 10
    local minWidth = math.max(minIconsWidth, minTextWidth)
    local frameWidth = math.max(totalWidth, hideLabelBar and 0 or minWidth)

    mainFrame.iconContainer:SetSize(frameWidth, iconSize)


    if hideLabelBar then
        mainFrame.labelBar:Hide()
        mainFrame:SetSize(totalWidth, iconSize)
    else
        mainFrame.labelBar:SetSize(frameWidth, labelBarHeight)
        mainFrame.labelBar:Show()
        mainFrame:SetSize(frameWidth, iconSize + labelBarGap + labelBarHeight)
    end


    if settings.position then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(settings.position.point, UIParent, settings.position.relPoint, settings.position.x, settings.position.y)
    end

    mainFrame:Show()
end

local function ThrottledUpdate()
    local now = GetTime()
    if now - lastUpdate < UPDATE_THROTTLE then return end
    lastUpdate = now
    UpdateDisplay()
end


local eventFrame = CreateFrame("Frame")


local StartRangeCheck, StopRangeCheck

local function OnEvent(self, event, ...)
    local settings = GetSettings()


    if event == "PLAYER_LOGIN" or event == "GROUP_ROSTER_UPDATE" then
        if settings and settings.enabled and IsInGroup() then
            if StartRangeCheck then StartRangeCheck() end
        else
            if StopRangeCheck then StopRangeCheck() end
        end
    end

    if not settings or not settings.enabled then return end

    if event == "PLAYER_LOGIN" then
        CreateMainFrame()
        ApplySkin()
        C_Timer.After(2, UpdateDisplay)
    elseif event == "GROUP_ROSTER_UPDATE" then
        ThrottledUpdate()
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then

            ThrottledUpdate()
        elseif unit and settings.providerMode and (unit:match("^party") or unit:match("^raid")) then

            ThrottledUpdate()
        end
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
        ThrottledUpdate()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        C_Timer.After(1, UpdateDisplay)
    elseif event == "UNIT_FLAGS" then

        local unit = ...
        if unit and (unit:match("^party") or unit:match("^raid")) then
            ThrottledUpdate()
        end
    elseif event == "PLAYER_DEAD" or event == "PLAYER_UNGHOST" then

        ThrottledUpdate()
    end
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("UNIT_FLAGS")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("PLAYER_UNGHOST")
eventFrame:SetScript("OnEvent", OnEvent)


local rangeCheckTicker

StopRangeCheck = function()
    if rangeCheckTicker then
        rangeCheckTicker:Cancel()
        rangeCheckTicker = nil
    end
end

StartRangeCheck = function()
    if rangeCheckTicker then return end
    rangeCheckTicker = C_Timer.NewTicker(5, function()
        local settings = GetSettings()
        if not settings or not settings.enabled then
            StopRangeCheck()
            return
        end
        if InCombatLockdown() then return end
        if not IsInGroup() then
            StopRangeCheck()
            return
        end
        UpdateDisplay()
    end)
end


function PREY_RaidBuffs:Toggle()
    local settings = GetSettings()
    settings.enabled = not settings.enabled
    UpdateDisplay()
end

function PREY_RaidBuffs:ForceUpdate()
    UpdateDisplay()
    ApplySkin()
end

function PREY_RaidBuffs:Debug()
    local settings = GetSettings()
    local lines = {}
    local playerClass = SafeUnitClass("player")
    table.insert(lines, "PREY RaidBuffs Debug")
    table.insert(lines, "Provider Mode: " .. (settings.providerMode and "ON" or "OFF"))
    table.insert(lines, "Player Class: " .. (playerClass or "UNKNOWN"))
    table.insert(lines, "In Group: " .. (IsInGroup() and "YES" or "NO"))
    table.insert(lines, "In Raid: " .. (IsInRaid() and "YES" or "NO"))
    table.insert(lines, "In Combat: " .. (InCombatLockdown() and "YES" or "NO"))


    ScanGroupClasses()
    local classes = {}
    for class, _ in pairs(groupClasses) do
        table.insert(classes, class)
    end
    table.insert(lines, "Group Classes: " .. (#classes > 0 and table.concat(classes, ", ") or "NONE"))


    table.insert(lines, "")
    table.insert(lines, "Party Members:")
    local numMembers = GetNumGroupMembers()
    table.insert(lines, "  GetNumGroupMembers: " .. numMembers)
    if IsInGroup() and not IsInRaid() then
        for i = 1, numMembers - 1 do
            local unit = "party" .. i
            local exists = SafeBooleanCheck(UnitExists(unit))
            local connected = SafeBooleanCheck(UnitIsConnected(unit))
            local dead = SafeBooleanCheck(UnitIsDeadOrGhost(unit))
            local available = IsUnitAvailable(unit)
            local name = UnitName(unit) or "?"
            local uClass = SafeUnitClass(unit)


            local uirRange, uirChecked = "?", "?"
            local ok1, r1, r2 = pcall(UnitInRange, unit)
            if ok1 then
                uirRange = IsSecretValue(r1) and "SECRET" or tostring(r1)
                uirChecked = IsSecretValue(r2) and "SECRET" or tostring(r2)
            end
            local cidResult = "?"
            local ok2, cid = pcall(CheckInteractDistance, unit, 1)
            if ok2 then
                cidResult = IsSecretValue(cid) and "SECRET" or tostring(cid)
            end
            local udsResult = "N/A"
            if UnitDistanceSquared then
                local ok3, distSq = pcall(UnitDistanceSquared, unit)
                if ok3 then
                    udsResult = IsSecretValue(distSq) and "SECRET" or tostring(distSq)
                end
            end
            local rangeInfo = " UnitInRange:" .. uirRange .. "/" .. uirChecked .. " CheckInteract:" .. cidResult .. " DistSq:" .. udsResult

            table.insert(lines, "  " .. unit .. ": " .. name .. " (" .. (uClass or "?") .. ") exists:" .. tostring(exists) .. " connected:" .. tostring(connected) .. " dead:" .. tostring(dead) .. " available:" .. tostring(available))
            table.insert(lines, "    Range APIs:" .. rangeInfo)
        end
    end


    table.insert(lines, "")
    table.insert(lines, "Buff Status:")
    for _, buff in ipairs(RAID_BUFFS) do
        local buffRange = buff.range or 40
        local hasProvider = groupClasses[buff.providerClass] and true or false
        local providerInRange = IsProviderClassInRange(buff.providerClass, buffRange)
        local playerHas = PlayerHasBuff(buff.spellId, buff.name)
        local canProvide = buff.providerClass == playerClass
        local anyMissing = AnyGroupMemberMissingBuff(buff.spellId, buff.name, buffRange)
        local status = ""
        if hasProvider and not playerHas then
            if providerInRange then
                status = "MISSING"
            else
                status = "MISSING (out of range)"
            end
        elseif playerHas then
            status = "HAVE"
        else
            status = "No provider"
        end
        local providerInfo = " range:" .. buffRange .. "yd canProvide:" .. tostring(canProvide) .. " anyMissing:" .. tostring(anyMissing) .. " providerInRange:" .. tostring(providerInRange)
        table.insert(lines, "  " .. buff.name .. ": " .. status .. " (provider:" .. buff.providerClass .. " inGroup:" .. tostring(hasProvider) .. " hasBuff:" .. tostring(playerHas) .. providerInfo .. ")")


        if canProvide and settings.providerMode and IsInGroup() and not IsInRaid() then
            for i = 1, numMembers - 1 do
                local unit = "party" .. i
                if IsUnitAvailable(unit, buffRange) then
                    local has = UnitHasBuff(unit, buff.spellId, buff.name)
                    local name = UnitName(unit) or "?"
                    table.insert(lines, "    -> " .. unit .. " (" .. name .. "): " .. (has and "HAS" or "MISSING"))
                end
            end
        end
    end


    error(table.concat(lines, "\n"), 0)
end


SLASH_PREYRAIDBUFFS1 = "/preybuffs"
SlashCmdList["PREYRAIDBUFFS"] = function()
    if ns.RaidBuffs then
        ns.RaidBuffs:Debug()
    end
end

function PREY_RaidBuffs:GetFrame()
    return mainFrame
end

function PREY_RaidBuffs:TogglePreview()
    previewMode = not previewMode
    if previewMode then

        previewBuffs = {}
        for i, buff in ipairs(RAID_BUFFS) do
            previewBuffs[i] = buff
        end
    else
        previewBuffs = nil
    end
    UpdateDisplay()
    return previewMode
end

function PREY_RaidBuffs:IsPreviewMode()
    return previewMode
end


_G.PreyUI_ToggleRaidBuffsPreview = function()
    if ns.RaidBuffs then
        return ns.RaidBuffs:TogglePreview()
    end
    return false
end
