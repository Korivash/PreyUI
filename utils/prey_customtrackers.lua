local ADDON_NAME, ns = ...
local PREY = PreyUI
local LSM = LibStub("LibSharedMedia-3.0")
local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)
local IsSecretValue = function(v) return ns.Utils and ns.Utils.IsSecretValue and ns.Utils.IsSecretValue(v) or false end


local CustomTrackers = {}
CustomTrackers.activeBars = {}
CustomTrackers.infoCache = {}


local PREYCore


local ASPECT_RATIOS = {
    square = { w = 1, h = 1 },
    flat = { w = 4, h = 3 },
}


local function MigrateBarAspect(config)
    if config and config.aspectRatioCrop == nil and config.shape then
        if config.shape == "flat" then
            config.aspectRatioCrop = 1.33
        else
            config.aspectRatioCrop = 1.0
        end
    end
    return config.aspectRatioCrop or 1.0
end

local BASE_CROP = 0.08


local HOUSING_INSTANCE_TYPES = {
    ["neighborhood"] = true,
    ["interior"] = true,
}


local function IsPlayerInInstance()
    local _, instanceType = GetInstanceInfo()
    if instanceType == "none" or instanceType == nil then
        return false
    end
    if HOUSING_INSTANCE_TYPES[instanceType] then
        return false
    end
    return true
end


local function GetRechargeEdgeSetting()
    local core = _G.PreyUI and _G.PreyUI.PREYCore
    if core and core.db and core.db.profile and core.db.profile.cooldownSwipe then
        return core.db.profile.cooldownSwipe.showRechargeEdge
    end
    return false
end


local function PositionBar(bar)
    if not bar or not bar.config then return end
    local config = bar.config


    if config.position and not config.offsetX then
        config.offsetX = config.position[3] or 0
        config.offsetY = config.position[4] or -300
    end

    bar:ClearAllPoints()


    if config.lockedToPlayer then
        local playerFrame = rawget(_G, "PREY_Player")
        if playerFrame then
            bar:SetParent(playerFrame)
            bar:SetFrameLevel(playerFrame:GetFrameLevel() + 10)
            local lockPos = config.lockPosition or "bottomcenter"
            local borderSize = config.borderSize or 2

            local userOffsetX = config.offsetX or 0
            local userOffsetY = config.offsetY or 0


            if lockPos == "topleft" then
                bar:SetPoint("BOTTOMLEFT", playerFrame, "TOPLEFT", borderSize + userOffsetX, borderSize + userOffsetY)
            elseif lockPos == "topcenter" then
                bar:SetPoint("BOTTOM", playerFrame, "TOP", userOffsetX, borderSize + userOffsetY)
            elseif lockPos == "topright" then
                bar:SetPoint("BOTTOMRIGHT", playerFrame, "TOPRIGHT", -borderSize + userOffsetX, borderSize + userOffsetY)
            elseif lockPos == "bottomleft" then
                bar:SetPoint("TOPLEFT", playerFrame, "BOTTOMLEFT", borderSize + userOffsetX, -borderSize + userOffsetY)
            elseif lockPos == "bottomcenter" then
                bar:SetPoint("TOP", playerFrame, "BOTTOM", userOffsetX, -borderSize + userOffsetY)
            elseif lockPos == "bottomright" then
                bar:SetPoint("TOPRIGHT", playerFrame, "BOTTOMRIGHT", -borderSize + userOffsetX, -borderSize + userOffsetY)
            end
            return
        end
    end


    if config.lockedToTarget then
        local targetFrame = rawget(_G, "PREY_Target")
        if targetFrame then
            bar:SetParent(targetFrame)
            bar:SetFrameLevel(targetFrame:GetFrameLevel() + 10)
            local lockPos = config.targetLockPosition or "bottomcenter"
            local borderSize = config.borderSize or 2
            local userOffsetX = config.offsetX or 0
            local userOffsetY = config.offsetY or 0


            if lockPos == "topleft" then
                bar:SetPoint("BOTTOMLEFT", targetFrame, "TOPLEFT", borderSize + userOffsetX, borderSize + userOffsetY)
            elseif lockPos == "topcenter" then
                bar:SetPoint("BOTTOM", targetFrame, "TOP", userOffsetX, borderSize + userOffsetY)
            elseif lockPos == "topright" then
                bar:SetPoint("BOTTOMRIGHT", targetFrame, "TOPRIGHT", -borderSize + userOffsetX, borderSize + userOffsetY)
            elseif lockPos == "bottomleft" then
                bar:SetPoint("TOPLEFT", targetFrame, "BOTTOMLEFT", borderSize + userOffsetX, -borderSize + userOffsetY)
            elseif lockPos == "bottomcenter" then
                bar:SetPoint("TOP", targetFrame, "BOTTOM", userOffsetX, -borderSize + userOffsetY)
            elseif lockPos == "bottomright" then
                bar:SetPoint("TOPRIGHT", targetFrame, "BOTTOMRIGHT", -borderSize + userOffsetX, -borderSize + userOffsetY)
            end
            return
        end
    end


    bar:SetParent(UIParent)


    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetClampedToScreen(true)

    local offsetX = config.offsetX or 0
    local offsetY = config.offsetY or -300
    local growDir = config.growDirection or "RIGHT"


    if growDir == "RIGHT" then
        bar:SetPoint("LEFT", UIParent, "CENTER", offsetX, offsetY)
    elseif growDir == "LEFT" then
        bar:SetPoint("RIGHT", UIParent, "CENTER", offsetX, offsetY)
    elseif growDir == "DOWN" then
        bar:SetPoint("TOP", UIParent, "CENTER", offsetX, offsetY)
    elseif growDir == "UP" then
        bar:SetPoint("BOTTOM", UIParent, "CENTER", offsetX, offsetY)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    end
end


local function GetDB()
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.customTrackers then
        return PREYCore.db.profile.customTrackers
    end
    return nil
end

local function GetGlobalDB()
    if PREYCore and PREYCore.db and PREYCore.db.global then
        return PREYCore.db.global
    end
    return nil
end


local function GetCurrentSpecKey()
    local _, className = UnitClass("player")
    local specIndex = GetSpecialization()
    if specIndex then
        local specID = GetSpecializationInfo(specIndex)
        if specID and className then
            return className .. "-" .. specID
        end
    end
    return nil
end


local function GetClassSpecName(specKey)
    if not specKey then return "Unknown" end
    local className, specID = specKey:match("^(.+)-(%d+)$")
    if not className or not specID then return specKey end

    specID = tonumber(specID)
    if not specID then return specKey end

    local _, specName = GetSpecializationInfoByID(specID)
    if specName then

        local classDisplay = className:sub(1, 1):upper() .. className:sub(2):lower()
        return classDisplay .. " - " .. specName
    end
    return specKey
end


local function GetAllClassSpecs()
    local _, className = UnitClass("player")
    local specs = {}
    local numSpecs = GetNumSpecializations()

    for i = 1, numSpecs do
        local specID, specName = GetSpecializationInfo(i)
        if specID and specName then
            table.insert(specs, {
                key = className .. "-" .. specID,
                specID = specID,
                specIndex = i,
                name = className:sub(1, 1):upper() .. className:sub(2):lower() .. " - " .. specName,
                className = className,
                specName = specName,
            })
        end
    end

    return specs
end


local function GetBarEntries(barConfig, specKey)
    if not barConfig then return {} end


    if not barConfig.specSpecificSpells then
        return barConfig.entries or {}
    end


    local globalDB = GetGlobalDB()
    if not globalDB then
        return barConfig.entries or {}
    end


    if not globalDB.specTrackerSpells then
        globalDB.specTrackerSpells = {}
    end


    local barSpecSpells = globalDB.specTrackerSpells[barConfig.id]
    if not barSpecSpells then
        barSpecSpells = {}
        globalDB.specTrackerSpells[barConfig.id] = barSpecSpells
    end


    local key = specKey or GetCurrentSpecKey()
    if not key then
        return barConfig.entries or {}
    end


    return barSpecSpells[key] or {}
end


function CustomTrackers:GetSpecEntries(barConfig, specKey)
    if not barConfig or not specKey then return {} end

    local globalDB = GetGlobalDB()
    if not globalDB then return {} end

    if not globalDB.specTrackerSpells then
        globalDB.specTrackerSpells = {}
    end

    local barSpecSpells = globalDB.specTrackerSpells[barConfig.id]
    if not barSpecSpells then return {} end

    return barSpecSpells[specKey] or {}
end

function CustomTrackers:SetSpecEntries(barConfig, specKey, entries)
    if not barConfig or not specKey then return end

    local globalDB = GetGlobalDB()
    if not globalDB then return end

    if not globalDB.specTrackerSpells then
        globalDB.specTrackerSpells = {}
    end

    if not globalDB.specTrackerSpells[barConfig.id] then
        globalDB.specTrackerSpells[barConfig.id] = {}
    end

    globalDB.specTrackerSpells[barConfig.id][specKey] = entries
end


function CustomTrackers:CopyEntriesToSpec(barConfig, specKey)
    if not barConfig or not specKey then return end
    if not barConfig.entries or #barConfig.entries == 0 then return end


    local copiedEntries = {}
    for _, entry in ipairs(barConfig.entries) do
        table.insert(copiedEntries, {
            type = entry.type,
            id = entry.id,
            customName = entry.customName,
        })
    end

    self:SetSpecEntries(barConfig, specKey, copiedEntries)
end


CustomTrackers.GetCurrentSpecKey = GetCurrentSpecKey
CustomTrackers.GetClassSpecName = GetClassSpecName
CustomTrackers.GetAllClassSpecs = GetAllClassSpecs
CustomTrackers.GetBarEntries = GetBarEntries


local function GetGeneralFont()
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        local general = PREYCore.db.profile.general
        local fontName = general.font or "Friz Quadrata TT"
        return LSM:Fetch("font", fontName) or "Fonts\\FRIZQT__.TTF"
    end
    return "Fonts\\FRIZQT__.TTF"
end

local function GetGeneralFontOutline()
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        return PREYCore.db.profile.general.fontOutline or "OUTLINE"
    end
    return "OUTLINE"
end


local function GetCachedSpellInfo(spellID)
    if not spellID then return nil end
    local cacheKey = "spell_" .. spellID
    if CustomTrackers.infoCache[cacheKey] then
        return CustomTrackers.infoCache[cacheKey]
    end
    local info = C_Spell.GetSpellInfo(spellID)
    if info then
        CustomTrackers.infoCache[cacheKey] = {
            name = info.name,
            icon = info.iconID,
            id = spellID,
            type = "spell",
        }
        return CustomTrackers.infoCache[cacheKey]
    end
    return nil
end

local function GetCachedItemInfo(itemID)
    if not itemID then return nil end
    local cacheKey = "item_" .. itemID
    if CustomTrackers.infoCache[cacheKey] then
        return CustomTrackers.infoCache[cacheKey]
    end
    local name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemID)
    if name then
        CustomTrackers.infoCache[cacheKey] = {
            name = name,
            icon = icon,
            id = itemID,
            type = "item",
        }
        return CustomTrackers.infoCache[cacheKey]
    end

    C_Item.RequestLoadItemDataByID(itemID)
    return nil
end


local function GetSpellCooldownInfo(spellID)
    if not spellID then return 0, 0, false, nil end
    local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
    if cooldownInfo then
        return cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.isEnabled, cooldownInfo.isOnGCD
    end
    return 0, 0, true, nil
end

local function GetItemCooldownInfo(itemID)
    if not itemID then return 0, 0, false end
    local startTime, duration, enable = C_Item.GetItemCooldown(itemID)
    return startTime or 0, duration or 0, enable ~= 0
end

local function GetItemStackCount(itemID, includeCharges)
    if not itemID then return 0 end


    local includeUses = includeCharges ~= false
    local count = C_Item.GetItemCount(itemID, false, includeUses, true)

    if count == nil then return 0 end


    return count
end

local function GetSpellChargeCount(spellID)
    if not spellID then return 0, 1, 0, 0 end
    local chargeInfo = C_Spell.GetSpellCharges(spellID)

    if not chargeInfo or not chargeInfo.maxCharges then
        return 0, 1, 0, 0
    end


    if IsSecretValue(chargeInfo.maxCharges) then

        return chargeInfo.currentCharges, 2,
               chargeInfo.cooldownStartTime or 0,
               chargeInfo.cooldownDuration or 0
    end


    if chargeInfo.maxCharges > 1 then
        return chargeInfo.currentCharges or 0, chargeInfo.maxCharges,
               chargeInfo.cooldownStartTime or 0,
               chargeInfo.cooldownDuration or 0
    end
    return 0, 1, 0, 0
end


local function IsCooldownFrameActive(cooldownFrame)
    if not cooldownFrame then return false end
    local ok, visible = pcall(cooldownFrame.IsVisible, cooldownFrame)
    return ok and visible == true
end


local function IsEquipmentItem(itemID)
    local classID = select(6, C_Item.GetItemInfoInstant(itemID))
    if not classID then return false end
    return classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon
end


local function IsItemUsable(itemID, itemCount)
    if IsEquipmentItem(itemID) then

        return C_Item.IsEquippedItem(itemID)
    else

        return itemCount and itemCount > 0
    end
end


local function IsSpellUsable(spellID)

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if not spellInfo then return false end


    if IsSpellKnownOrOverridesKnown then
        return IsSpellKnownOrOverridesKnown(spellID)
    elseif IsPlayerSpell then
        return IsPlayerSpell(spellID)
    end

    return IsSpellKnown(spellID)
end


local function GetSpellCastInfo(spellID)
    if not spellID then return false end
    local _, _, _, startTimeMS, endTimeMS, _, _, _, castSpellID = UnitCastingInfo("player")
    if castSpellID and castSpellID == spellID then
        return true, startTimeMS, endTimeMS
    end
    return false
end


local function GetSpellChannelInfo(spellID)
    if not spellID then return false end
    local _, _, _, startTimeMS, endTimeMS, _, _, _, channelSpellID = UnitChannelInfo("player")
    if channelSpellID and channelSpellID == spellID then
        return true, startTimeMS, endTimeMS
    end
    return false
end


local function GetSpellBuffInfo(spellID)
    if not spellID then return false end


    local scanner = PREY and PREY.SpellScanner
    if scanner and scanner.IsSpellActive then
        local isActive, expiration, duration = scanner.IsSpellActive(spellID)
        if isActive then
            return true, expiration, duration
        end

        if InCombatLockdown() then
            return false
        end
    elseif InCombatLockdown() then

        return false
    end


    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        local ok, auraData = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if ok and auraData then

            local auraInstanceID
            pcall(function() auraInstanceID = auraData.auraInstanceID end)

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


local function GetSpellActiveInfo(spellID)
    if not spellID then return false end


    local isCasting, castStart, castEnd = GetSpellCastInfo(spellID)
    if isCasting and castStart and castEnd then
        local startSec = castStart / 1000
        local durationSec = (castEnd - castStart) / 1000
        return true, startSec, durationSec, "cast"
    end


    local isChanneling, channelStart, channelEnd = GetSpellChannelInfo(spellID)
    if isChanneling and channelStart and channelEnd then
        local startSec = channelStart / 1000
        local durationSec = (channelEnd - channelStart) / 1000
        return true, startSec, durationSec, "channel"
    end


    local hasBuff, expiration, buffDuration = GetSpellBuffInfo(spellID)
    if hasBuff and expiration and buffDuration then
        local startSec = expiration - buffDuration
        return true, startSec, buffDuration, "buff"
    end

    return false
end


local function GetItemActiveInfo(itemID)
    if not itemID then return false end
    local itemSpellID = select(2, C_Item.GetItemSpell(itemID))
    if itemSpellID then
        return GetSpellActiveInfo(itemSpellID)
    end
    return false
end


local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)


local PROC_GLOW_MASK = "Interface\\AddOns\\PreyUI\\assets\\iconskin\\ProcGlowMask"

local function StartActiveGlow(icon, config)
    if not icon or not LCG then return end
    if icon._activeGlowShown then return end
    if icon._activeGlowPending then return end

    if config and config.activeGlowEnabled == false then return end


    local iconWidth, iconHeight = icon:GetSize()
    if not iconWidth or not iconHeight or iconWidth < 10 or iconHeight < 10 then
        return
    end

    local glowType = (config and config.activeGlowType) or "Pixel Glow"

    local color = (config and config.activeGlowColor) or { 1, 0.85, 0.3, 1 }
    local lines = (config and config.activeGlowLines) or 8
    local frequency = (config and config.activeGlowFrequency) or 0.25
    local thickness = (config and config.activeGlowThickness) or 2
    local scale = (config and config.activeGlowScale) or 1.0

    if glowType == "Proc Glow" then


        local duration = 1.0 / (frequency * 4)
        duration = math.max(0.5, math.min(2.0, duration))


        if icon.border and icon.border:IsShown() then
            icon._borderWasShown = true
            icon.border:Hide()
        end


        if icon.tex then
            if not icon._procGlowMask then
                icon._procGlowMask = icon:CreateMaskTexture()
                icon._procGlowMask:SetTexture(PROC_GLOW_MASK)
                icon._procGlowMask:SetAllPoints(icon.tex)
            end
            icon.tex:AddMaskTexture(icon._procGlowMask)
        end


        icon._activeGlowPending = true
        icon._activeGlowType = glowType
        C_Timer.After(0, function()
            icon._activeGlowPending = nil

            if not icon or not icon:IsShown() then return end
            if icon._activeGlowShown then return end

            LCG.ProcGlow_Start(icon, {
                color = color,
                duration = duration,
                startAnim = true,
                key = "_PREYActiveGlow",
            })
            icon._activeGlowShown = true
        end)
    elseif glowType == "Pixel Glow" then
        LCG.PixelGlow_Start(icon, color, lines, frequency, nil, thickness, 0, 0, true, "_PREYActiveGlow")
        icon._activeGlowShown = true
        icon._activeGlowType = glowType
    elseif glowType == "Autocast Shine" then
        LCG.AutoCastGlow_Start(icon, color, lines, frequency, scale, 0, 0, "_PREYActiveGlow")
        icon._activeGlowShown = true
        icon._activeGlowType = glowType
    end
end

local function StopActiveGlow(icon)
    if not icon or not LCG then return end


    icon._activeGlowPending = nil

    if not icon._activeGlowShown then

        if icon._borderWasShown and icon.border then
            icon.border:Show()
            icon._borderWasShown = nil
        end
        if icon.tex and icon._procGlowMask then
            icon.tex:RemoveMaskTexture(icon._procGlowMask)
        end
        return
    end

    local glowType = icon._activeGlowType or "Pixel Glow"

    if glowType == "Proc Glow" then
        pcall(LCG.ProcGlow_Stop, icon, "_PREYActiveGlow")


        if icon.tex and icon._procGlowMask then
            icon.tex:RemoveMaskTexture(icon._procGlowMask)
        end


        if icon._borderWasShown and icon.border then
            icon.border:Show()
            icon._borderWasShown = nil
        end
    elseif glowType == "Pixel Glow" then
        pcall(LCG.PixelGlow_Stop, icon, "_PREYActiveGlow")
    elseif glowType == "Autocast Shine" then
        pcall(LCG.AutoCastGlow_Stop, icon, "_PREYActiveGlow")
    end

    icon._activeGlowShown = nil
    icon._activeGlowType = nil
end


local function CreateTrackerIcon(parent)
    local icon = CreateFrame("Frame", nil, parent)
    icon.__customTrackerIcon = true
    icon:SetSize(36, 36)


    icon.border = icon:CreateTexture(nil, "BACKGROUND", nil, -8)
    icon.border:SetColorTexture(0, 0, 0, 1)


    icon.tex = icon:CreateTexture(nil, "ARTWORK")
    icon.tex:SetAllPoints()


    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints()
    icon.cooldown:SetDrawSwipe(false)
    icon.cooldown:SetDrawEdge(false)
    icon.cooldown:SetHideCountdownNumbers(false)
    icon.cooldown:EnableMouse(false)
    if icon.cooldown.SetDrawBling then icon.cooldown:SetDrawBling(false) end


    icon.durationText = icon:CreateFontString(nil, "OVERLAY")
    icon.durationText:SetFont(GetGeneralFont(), 14, GetGeneralFontOutline())


    icon.stackText = icon:CreateFontString(nil, "OVERLAY")
    icon.stackText:SetFont(GetGeneralFont(), 12, GetGeneralFontOutline())


    icon.keybindText = icon:CreateFontString(nil, "OVERLAY")
    icon.keybindText:SetFont(GetGeneralFont(), 10, GetGeneralFontOutline())
    icon.keybindText:SetShadowOffset(1, -1)
    icon.keybindText:SetShadowColor(0, 0, 0, 1)
    icon.keybindText:Hide()


    icon.lastKnownCDEnd = 0


    icon:SetScript("OnEnter", function(self)
        if self:GetAlpha() == 0 then return end
        if self.entry then

            local tooltipSettings = PREY.PREYCore and PREY.PREYCore.db and PREY.PREYCore.db.profile and PREY.PREYCore.db.profile.tooltip
            if tooltipSettings and tooltipSettings.anchorToCursor then
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            else
                GameTooltip_SetDefaultAnchor(GameTooltip, self)
            end
            if self.entry.type == "spell" then
                GameTooltip:SetSpellByID(self.entry.id)
            elseif self.entry.type == "item" then

                pcall(GameTooltip.SetItemByID, GameTooltip, self.entry.id)
            end
        end
    end)

    icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)


    icon:RegisterForDrag("LeftButton")
    icon:SetScript("OnDragStart", function(self)
        local bar = self:GetParent()
        if bar and bar.config and not bar.config.locked and not bar.config.lockedToPlayer and not bar.config.lockedToTarget then
            bar:StartMoving()
        end
    end)
    icon:SetScript("OnDragStop", function(self)
        local bar = self:GetParent()
        if bar then
            bar:StopMovingOrSizing()

            local dragStopHandler = bar:GetScript("OnDragStop")
            if dragStopHandler then
                dragStopHandler(bar)
            end
        end
    end)

    return icon
end


local function StyleTrackerIcon(icon, config)
    if not icon or not config then return end


    MigrateBarAspect(config)
    local aspectRatio = config.aspectRatioCrop or 1.0
    local width = config.iconSize or 36
    local height = width / aspectRatio
    icon:SetSize(width, height)


    local bs = config.borderSize or 2
    if bs > 0 then
        icon.border:Show()
        icon.border:ClearAllPoints()
        icon.border:SetPoint("TOPLEFT", -bs, bs)
        icon.border:SetPoint("BOTTOMRIGHT", bs, -bs)
    else
        icon.border:Hide()
    end


    local zoom = config.zoom or 0
    local aspectRatio = config.aspectRatioCrop or 1.0


    local left = BASE_CROP + zoom
    local right = 1 - BASE_CROP - zoom
    local top = BASE_CROP + zoom
    local bottom = 1 - BASE_CROP - zoom


    if aspectRatio > 1.0 then

        local cropAmount = 1.0 - (1.0 / aspectRatio)
        local availableHeight = bottom - top
        local offset = (cropAmount * availableHeight) / 2.0
        top = top + offset
        bottom = bottom - offset
    end

    icon.tex:SetTexCoord(left, right, top, bottom)


    local fontPath = GetGeneralFont()
    local fontOutline = GetGeneralFontOutline()

    icon.durationText:SetFont(fontPath, config.durationSize or 14, fontOutline)
    local dColor = config.durationColor or {1, 1, 1, 1}
    icon.durationText:SetTextColor(dColor[1], dColor[2], dColor[3], dColor[4] or 1)
    icon.durationText:ClearAllPoints()
    icon.durationText:SetPoint(
        config.durationAnchor or "CENTER",
        icon,
        config.durationAnchor or "CENTER",
        config.durationOffsetX or 0,
        config.durationOffsetY or 0
    )


    if icon.cooldown then
        local cooldown = icon.cooldown
        if cooldown.text then
            cooldown.text:SetFont(fontPath, config.durationSize or 14, fontOutline)
            cooldown.text:SetTextColor(dColor[1], dColor[2], dColor[3], dColor[4] or 1)
            pcall(function()
                cooldown.text:ClearAllPoints()
                cooldown.text:SetPoint(
                    config.durationAnchor or "CENTER",
                    icon,
                    config.durationAnchor or "CENTER",
                    config.durationOffsetX or 0,
                    config.durationOffsetY or 0
                )
            end)
        end


        local ok, regions = pcall(function() return { cooldown:GetRegions() } end)
        if ok and regions then
            for _, region in ipairs(regions) do
                if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                    region:SetFont(fontPath, config.durationSize or 14, fontOutline)
                    region:SetTextColor(dColor[1], dColor[2], dColor[3], dColor[4] or 1)
                    pcall(function()
                        region:ClearAllPoints()
                        region:SetPoint(
                            config.durationAnchor or "CENTER",
                            icon,
                            config.durationAnchor or "CENTER",
                            config.durationOffsetX or 0,
                            config.durationOffsetY or 0
                        )
                    end)
                end
            end
        end
    end


    icon.stackText:SetFont(fontPath, config.stackSize or 12, fontOutline)
    local sColor = config.stackColor or {1, 1, 1, 1}
    icon.stackText:SetTextColor(sColor[1], sColor[2], sColor[3], sColor[4] or 1)
    icon.stackText:ClearAllPoints()
    icon.stackText:SetPoint(
        config.stackAnchor or "BOTTOMRIGHT",
        icon,
        config.stackAnchor or "BOTTOMRIGHT",
        config.stackOffsetX or -2,
        config.stackOffsetY or 2
    )


    if icon.keybindText then
        local db = PREYCore and PREYCore.db and PREYCore.db.profile
        local keybindSettings = db and db.customTrackers and db.customTrackers.keybinds
        if keybindSettings then
            icon.keybindText:SetFont(fontPath, keybindSettings.keybindTextSize or 10, fontOutline)
            local kColor = keybindSettings.keybindTextColor or {1, 0.82, 0, 1}
            icon.keybindText:SetTextColor(kColor[1], kColor[2], kColor[3], kColor[4] or 1)
            icon.keybindText:ClearAllPoints()
            icon.keybindText:SetPoint("TOPLEFT", icon, "TOPLEFT",
                keybindSettings.keybindOffsetX or 2,
                keybindSettings.keybindOffsetY or -2
            )
        end
    end
end


local function ApplyKeybindToTrackerIcon(icon)
    if not icon or not icon.entry then return end

    local db = PREYCore and PREYCore.db and PREYCore.db.profile
    local keybindSettings = db and db.customTrackers and db.customTrackers.keybinds

    if not keybindSettings or not keybindSettings.showKeybinds then
        if icon.keybindText then
            icon.keybindText:SetText("")
            icon.keybindText:Hide()
        end
        return
    end


    local keybind = nil
    local entry = icon.entry


    local PREYKeybinds = ns and ns.Keybinds
    if not PREYKeybinds then
        if icon.keybindText then
            icon.keybindText:Hide()
        end
        return
    end

    if entry.type == "spell" and entry.id then
        keybind = PREYKeybinds.GetKeybindForSpell(entry.id)

        if not keybind and PREYKeybinds.GetKeybindForSpellName then
            local spellInfo = C_Spell.GetSpellInfo(entry.id)
            if spellInfo and spellInfo.name then
                keybind = PREYKeybinds.GetKeybindForSpellName(spellInfo.name)
            end
        end
    elseif entry.type == "item" and entry.id then
        keybind = PREYKeybinds.GetKeybindForItem(entry.id)

        if not keybind and PREYKeybinds.GetKeybindForItemName then
            local itemName = C_Item.GetItemInfo(entry.id)
            if itemName then
                keybind = PREYKeybinds.GetKeybindForItemName(itemName)
            end
        end
    end

    if not icon.keybindText then return end

    if keybind then
        icon.keybindText:SetText(keybind)
        icon.keybindText:Show()
    else
        icon.keybindText:SetText("")
        icon.keybindText:Hide()
    end
end


local function LayoutBarIcons(bar)
    if not bar or not bar.icons then return end

    local config = bar.config
    local growDir = config.growDirection or "RIGHT"
    local spacing = config.spacing or 4


    local aspectRatio = config.aspectRatioCrop or 1.0
    local iconWidth = config.iconSize or 36
    local iconHeight = iconWidth / aspectRatio


    for _, icon in ipairs(bar.icons) do
        icon:ClearAllPoints()
    end


    local numIcons = #bar.icons
    for i, icon in ipairs(bar.icons) do
        local offset = (i - 1) * (iconWidth + spacing)

        if growDir == "RIGHT" then
            icon:SetPoint("LEFT", bar, "LEFT", offset, 0)
        elseif growDir == "LEFT" then
            icon:SetPoint("RIGHT", bar, "RIGHT", -offset, 0)
        elseif growDir == "DOWN" then
            offset = (i - 1) * (iconHeight + spacing)
            icon:SetPoint("TOP", bar, "TOP", 0, -offset)
        elseif growDir == "UP" then
            offset = (i - 1) * (iconHeight + spacing)
            icon:SetPoint("BOTTOM", bar, "BOTTOM", 0, offset)
        elseif growDir == "CENTER" then

            local totalWidth = (numIcons * iconWidth) + ((numIcons - 1) * spacing)
            local startX = -totalWidth / 2 + iconWidth / 2
            local x = startX + (i - 1) * (iconWidth + spacing)
            icon:SetPoint("CENTER", bar, "CENTER", x, 0)
        elseif growDir == "CENTER_VERTICAL" then

            local totalHeight = (numIcons * iconHeight) + ((numIcons - 1) * spacing)
            local startY = totalHeight / 2 - iconHeight / 2
            local y = startY - (i - 1) * (iconHeight + spacing)
            icon:SetPoint("CENTER", bar, "CENTER", 0, y)
        end

        icon:Show()
    end


    if numIcons == 0 then
        bar:SetSize(1, 1)
        return
    end

    if growDir == "RIGHT" or growDir == "LEFT" or growDir == "CENTER" then
        local totalWidth = (numIcons * iconWidth) + ((numIcons - 1) * spacing)
        bar:SetSize(totalWidth, iconHeight)
    else
        local totalHeight = (numIcons * iconHeight) + ((numIcons - 1) * spacing)
        bar:SetSize(iconWidth, totalHeight)
    end
end


local function LayoutVisibleIcons(bar)
    if not bar or not bar.icons then return end

    local config = bar.config
    local growDir = config.growDirection or "RIGHT"
    local spacing = config.spacing or 4


    local aspectRatio = config.aspectRatioCrop or 1.0
    local iconWidth = config.iconSize or 36
    local iconHeight = iconWidth / aspectRatio


    local visibleIcons = {}
    for _, icon in ipairs(bar.icons) do
        if icon.isVisible ~= false then
            table.insert(visibleIcons, icon)
        end
    end


    for _, icon in ipairs(bar.icons) do
        icon:ClearAllPoints()
    end


    local numIcons = #visibleIcons
    for i, icon in ipairs(visibleIcons) do
        local offset = (i - 1) * (iconWidth + spacing)

        if growDir == "RIGHT" then
            icon:SetPoint("LEFT", bar, "LEFT", offset, 0)
        elseif growDir == "LEFT" then
            icon:SetPoint("RIGHT", bar, "RIGHT", -offset, 0)
        elseif growDir == "DOWN" then
            offset = (i - 1) * (iconHeight + spacing)
            icon:SetPoint("TOP", bar, "TOP", 0, -offset)
        elseif growDir == "UP" then
            offset = (i - 1) * (iconHeight + spacing)
            icon:SetPoint("BOTTOM", bar, "BOTTOM", 0, offset)
        elseif growDir == "CENTER" then

            local totalWidth = (numIcons * iconWidth) + ((numIcons - 1) * spacing)
            local startX = -totalWidth / 2 + iconWidth / 2
            local x = startX + (i - 1) * (iconWidth + spacing)
            icon:SetPoint("CENTER", bar, "CENTER", x, 0)
        elseif growDir == "CENTER_VERTICAL" then

            local totalHeight = (numIcons * iconHeight) + ((numIcons - 1) * spacing)
            local startY = totalHeight / 2 - iconHeight / 2
            local y = startY - (i - 1) * (iconHeight + spacing)
            icon:SetPoint("CENTER", bar, "CENTER", 0, y)
        end
    end


    if numIcons == 0 then
        bar:SetSize(1, 1)
        return
    end

    if growDir == "RIGHT" or growDir == "LEFT" or growDir == "CENTER" then
        local totalWidth = (numIcons * iconWidth) + ((numIcons - 1) * spacing)
        bar:SetSize(totalWidth, iconHeight)
    else
        local totalHeight = (numIcons * iconHeight) + ((numIcons - 1) * spacing)
        bar:SetSize(iconWidth, totalHeight)
    end
end


function CustomTrackers:UpdateBarIcons(bar)
    if not bar then return end

    local config = bar.config

    local entries = GetBarEntries(config)


    for _, icon in ipairs(bar.icons or {}) do
        icon:Hide()
        icon:SetParent(nil)
    end
    bar.icons = {}

    if #entries == 0 then
        bar:SetSize(1, 1)
        if bar.bg then bar.bg:SetAlpha(0) end
        return
    end


    for i, entry in ipairs(entries) do
        local icon = CreateTrackerIcon(bar)
        StyleTrackerIcon(icon, config)


        icon.entry = entry
        icon.isVisible = true


        local info
        if entry.type == "spell" then
            info = GetCachedSpellInfo(entry.id)
        else
            info = GetCachedItemInfo(entry.id)
        end

        if info and info.icon then
            icon.tex:SetTexture(info.icon)
        else
            icon.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        table.insert(bar.icons, icon)
    end


    LayoutBarIcons(bar)


    PositionBar(bar)


    if bar.bg then
        bar.bg:SetAlpha(config.bgOpacity or 0)
    end
end


local function FormatDuration(seconds)
    if seconds >= 3600 then
        return string.format("%dh", math.floor(seconds / 3600))
    elseif seconds >= 60 then
        return string.format("%dm", math.floor(seconds / 60))
    elseif seconds >= 10 then
        return string.format("%d", math.floor(seconds))
    elseif seconds > 0 then
        return string.format("%.1f", seconds)
    end
    return ""
end


local function RebuildActiveSet(bar)
    if not bar then return end

    bar.activeIcons = bar.activeIcons or {}
    wipe(bar.activeIcons)

    local config = bar.config
    local hideNonUsable = config.hideNonUsable


    for _, icon in ipairs(bar.icons or {}) do
        local entry = icon.entry
        if entry and entry.id then
            local isUsable = true
            if entry.type == "spell" then
                isUsable = IsSpellUsable(entry.id)
            elseif entry.type == "item" then

                if IsEquipmentItem(entry.id) then
                    isUsable = C_Item.IsEquippedItem(entry.id)
                else
                    isUsable = true
                end
            end


            if isUsable then
                table.insert(bar.activeIcons, icon)
                icon._usable = true
                icon.isVisible = true
                icon.tex:SetDesaturated(false)
                icon:Show()
            else

                if hideNonUsable then
                    icon:Hide()
                    icon.isVisible = false
                else
                    icon:Show()
                    icon.isVisible = true
                    icon.tex:SetDesaturated(true)
                    icon.cooldown:Clear()
                end
                icon._usable = false
            end
        end
    end


    LayoutVisibleIcons(bar)


end


CustomTrackers.RebuildActiveSet = RebuildActiveSet

function CustomTrackers:StartCooldownPolling(bar)
    if not bar then return end

    if bar.ticker then
        bar.ticker:Cancel()
    end


    bar.DoUpdate = function()
        if not bar:IsShown() then return end

        local config = bar.config
        local hideNonUsable = config.hideNonUsable
        local showOnlyOnCooldown = config.showOnlyOnCooldown
        local showOnlyWhenActive = config.showOnlyWhenActive
        local showOnlyWhenOffCooldown = config.showOnlyWhenOffCooldown
        local showOnlyInCombat = config.showOnlyInCombat
        local dynamicLayout = config.dynamicLayout == true
        local showActiveState = config.showActiveState ~= false
        local stackColor = config.stackColor or {1, 1, 1, 1}
        local visibilityChanged = false


        for _, icon in ipairs(bar.activeIcons or bar.icons or {}) do
            local entry = icon.entry
            if entry and entry.id then
                local startTime, duration, enabled, isOnGCD
                local count = 0
                local maxCharges = 1
                local chargeStartTime, chargeDuration = 0, 0

                if entry.type == "spell" then
                    startTime, duration, enabled, isOnGCD = GetSpellCooldownInfo(entry.id)
                    count, maxCharges, chargeStartTime, chargeDuration = GetSpellChargeCount(entry.id)
                else
                    startTime, duration, enabled = GetItemCooldownInfo(entry.id)
                    count = GetItemStackCount(entry.id, config.showItemCharges)
                    isOnGCD = false

                    icon._usable = IsItemUsable(entry.id, count)
                end


                local isActive, activeStartTime, activeDuration, activeType = false, nil, nil, nil
                if showActiveState then
                    if entry.type == "spell" then
                        isActive, activeStartTime, activeDuration, activeType = GetSpellActiveInfo(entry.id)
                    elseif entry.type == "item" then
                        isActive, activeStartTime, activeDuration, activeType = GetItemActiveInfo(entry.id)
                    end
                end


                local hideGCD = config.hideGCD ~= false


                local isOnCD = false


                if isActive and activeStartTime and activeDuration and activeDuration > 0 then

                    pcall(function()
                        icon.cooldown:SetReverse(true)
                        icon.cooldown:SetCooldown(activeStartTime, activeDuration)
                    end)
                    isOnCD = false
                else

                    local isChargeSpell = maxCharges > 1
                    local rechargeActive = false

                    icon.cooldown:SetReverse(false)

                    if isChargeSpell then

                        if chargeStartTime and chargeDuration then

                            pcall(function()
                                icon.cooldown:SetCooldown(chargeStartTime, chargeDuration)
                            end)

                            rechargeActive = IsCooldownFrameActive(icon.cooldown)
                        else
                            icon.cooldown:Clear()
                        end


                        if config.showRechargeSwipe then
                            pcall(icon.cooldown.SetSwipeColor, icon.cooldown, 0, 0, 0, 0.6)
                            pcall(icon.cooldown.SetDrawSwipe, icon.cooldown, true)
                        else
                            pcall(icon.cooldown.SetSwipeColor, icon.cooldown, 0, 0, 0, 0)
                            pcall(icon.cooldown.SetDrawSwipe, icon.cooldown, false)
                        end
                        local showEdge = rechargeActive and GetRechargeEdgeSetting()
                        pcall(icon.cooldown.SetDrawEdge, icon.cooldown, showEdge)


                        if rechargeActive then
                            icon.cooldown:Show()
                        else
                            icon.cooldown:Hide()
                        end


                        local mainCDActive = false


                        icon.cooldown:Clear()
                        pcall(function()
                            icon.cooldown:SetCooldown(startTime, duration)
                        end)


                        mainCDActive = IsCooldownFrameActive(icon.cooldown)


                        if chargeStartTime and chargeDuration then
                            pcall(function()
                                icon.cooldown:SetCooldown(chargeStartTime, chargeDuration)
                            end)
                        end


                        if hideGCD then
                            local isJustGCD = isOnGCD
                            if not isJustGCD then

                                local gcdCheckOk, gcdCheckResult = pcall(function()
                                    return duration and duration > 0 and duration <= 1.5
                                end)
                                if gcdCheckOk and gcdCheckResult then
                                    isJustGCD = true
                                end
                            end
                            if isJustGCD then
                                mainCDActive = false
                            end
                        end

                        isOnCD = mainCDActive

                    else

                        if startTime and duration then
                            pcall(function()
                                icon.cooldown:SetCooldown(startTime, duration)
                            end)
                        end

                        pcall(icon.cooldown.SetDrawSwipe, icon.cooldown, false)
                        pcall(icon.cooldown.SetDrawEdge, icon.cooldown, false)

                        if hideGCD then


                            local isJustGCD = isOnGCD
                            if not isJustGCD then


                                local gcdCheckOk, gcdCheckResult = pcall(function()
                                    return duration and duration > 0 and duration <= 1.5
                                end)
                                if gcdCheckOk and gcdCheckResult then
                                    isJustGCD = true
                                end
                            end

                            if isJustGCD then

                                icon.cooldown:Clear()
                                isOnCD = false
                            else

                                local checkSuccess, checkResult = pcall(function()
                                    return startTime and startTime > 0 and duration and duration > 0
                                end)
                                if checkSuccess then
                                    isOnCD = checkResult
                                else
                                    isOnCD = IsCooldownFrameActive(icon.cooldown)
                                end
                            end
                        else

                            local checkSuccess, checkResult = pcall(function()
                                return startTime and startTime > 0 and duration and duration > 0
                            end)
                            if checkSuccess then
                                isOnCD = checkResult
                            else
                                isOnCD = IsCooldownFrameActive(icon.cooldown)
                            end
                        end
                    end
                end


                local isUsable = icon._usable ~= false


                local baseVisible = isUsable or (not hideNonUsable)


                local inCombat = UnitAffectingCombat("player")
                local combatVisible = (not showOnlyInCombat) or inCombat


                local layoutVisible = baseVisible and combatVisible
                if layoutVisible then
                    if showOnlyWhenActive then
                        layoutVisible = isActive
                    elseif showOnlyOnCooldown then

                        layoutVisible = isActive or isOnCD
                    elseif showOnlyWhenOffCooldown then


                        local hasChargesRemaining = false
                        if maxCharges > 1 then
                            local chargeCheckOk, chargeCheckResult = pcall(function()
                                return count and count > 0
                            end)
                            hasChargesRemaining = chargeCheckOk and chargeCheckResult
                        end
                        layoutVisible = not isOnCD and (not isActive or hasChargesRemaining)
                    end
                end

                if dynamicLayout then

                    if layoutVisible ~= icon.isVisible then
                        visibilityChanged = true
                        icon.isVisible = layoutVisible
                        if layoutVisible then
                            icon:Show()
                        else
                            StopActiveGlow(icon)
                            icon:Hide()
                        end
                    end
                else

                    if baseVisible ~= icon.isVisible then
                        visibilityChanged = true
                        icon.isVisible = baseVisible
                        if baseVisible then
                            icon:Show()
                        else
                            StopActiveGlow(icon)
                            icon:Hide()
                        end
                    end
                end


                local shouldRender = dynamicLayout and layoutVisible or (baseVisible and combatVisible)
                if shouldRender then
                    if isActive then

                        icon:SetAlpha(1)
                        icon.tex:SetDesaturated(false)
                        StartActiveGlow(icon, config)
                    elseif showOnlyWhenActive then

                        StopActiveGlow(icon)
                        if dynamicLayout then

                            icon:SetAlpha(1)
                        else
                            icon:SetAlpha(0)
                        end
                        icon.tex:SetDesaturated(false)
                    elseif showOnlyOnCooldown then
                        StopActiveGlow(icon)
                        if dynamicLayout then

                            icon:SetAlpha(1)
                            icon.tex:SetDesaturated(true)
                        else

                            if isOnCD then
                                icon:SetAlpha(1)
                                icon.tex:SetDesaturated(true)
                            else
                                icon:SetAlpha(0)
                                icon.tex:SetDesaturated(false)
                            end
                        end
                    elseif showOnlyWhenOffCooldown then
                        StopActiveGlow(icon)
                        if dynamicLayout then

                            icon:SetAlpha(1)
                            icon.tex:SetDesaturated(false)
                        else

                            if not isOnCD then
                                icon:SetAlpha(1)
                                icon.tex:SetDesaturated(false)
                            else
                                icon:SetAlpha(0)
                                icon.tex:SetDesaturated(true)
                            end
                        end
                    else

                        StopActiveGlow(icon)
                        icon:SetAlpha(1)
                        if not isUsable then

                            icon.tex:SetDesaturated(true)
                            icon.cooldown:Clear()
                        elseif isOnCD then

                            icon.tex:SetDesaturated(true)
                        else

                            icon.tex:SetDesaturated(false)
                        end
                    end
                end


                icon.durationText:Hide()
                icon.cooldown:SetHideCountdownNumbers(config.hideDurationText == true)


                local showStack = (entry.type == "item") or (entry.type == "spell" and maxCharges > 1)

                if showStack then

                    local isSecret = IsSecretValue(count)
                    if isSecret then

                        icon.stackText:SetText(count)
                        icon.stackText:SetTextColor(stackColor[1], stackColor[2], stackColor[3], stackColor[4] or 1)
                        if not config.hideStackText then
                            icon.stackText:Show()
                        else
                            icon.stackText:Hide()
                        end
                    elseif count > 1 then
                        icon.stackText:SetText(count)
                        icon.stackText:SetTextColor(stackColor[1], stackColor[2], stackColor[3], stackColor[4] or 1)
                        if not config.hideStackText then
                            icon.stackText:Show()
                        else
                            icon.stackText:Hide()
                        end
                    elseif count == 1 then
                        icon.stackText:SetText("")
                        icon.stackText:Hide()
                    else

                        icon.stackText:SetText("0")
                        icon.stackText:SetTextColor(stackColor[1] * 0.5, stackColor[2] * 0.5, stackColor[3] * 0.5, stackColor[4] or 1)
                        if not config.hideStackText then
                            icon.stackText:Show()
                        else
                            icon.stackText:Hide()
                        end
                    end
                else
                    icon.stackText:Hide()
                end


                ApplyKeybindToTrackerIcon(icon)
            end
        end


        if visibilityChanged then
            LayoutVisibleIcons(bar)
        end
    end


    bar.ticker = C_Timer.NewTicker(0.5, bar.DoUpdate)
end


function CustomTrackers:SetupDragging(bar)
    if not bar then return end

    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetClampedToScreen(true)

    bar:SetScript("OnDragStart", function(self)
        if not self.config.locked and not self.config.lockedToPlayer and not self.config.lockedToTarget then
            self:StartMoving()
        end
    end)

    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()


        local screenX, screenY = UIParent:GetCenter()
        local growDir = self.config.growDirection or "RIGHT"

        if growDir == "RIGHT" then

            local left = self:GetLeft()
            local centerY = select(2, self:GetCenter())
            if left and screenX and centerY and screenY then
                self.config.offsetX = math.floor(left - screenX + 0.5)
                self.config.offsetY = math.floor(centerY - screenY + 0.5)
            end
        elseif growDir == "LEFT" then

            local right = self:GetRight()
            local centerY = select(2, self:GetCenter())
            if right and screenX and centerY and screenY then
                self.config.offsetX = math.floor(right - screenX + 0.5)
                self.config.offsetY = math.floor(centerY - screenY + 0.5)
            end
        elseif growDir == "DOWN" then

            local centerX = self:GetCenter()
            local top = self:GetTop()
            if centerX and screenX and top and screenY then
                self.config.offsetX = math.floor(centerX - screenX + 0.5)
                self.config.offsetY = math.floor(top - screenY + 0.5)
            end
        elseif growDir == "UP" then

            local centerX = self:GetCenter()
            local bottom = self:GetBottom()
            if centerX and screenX and bottom and screenY then
                self.config.offsetX = math.floor(centerX - screenX + 0.5)
                self.config.offsetY = math.floor(bottom - screenY + 0.5)
            end
        else

            local barX, barY = self:GetCenter()
            if barX and screenX and barY and screenY then
                self.config.offsetX = math.floor(barX - screenX + 0.5)
                self.config.offsetY = math.floor(barY - screenY + 0.5)
            end
        end


        PositionBar(self)


        local db = GetDB()
        if db and db.bars then
            for _, barConfig in ipairs(db.bars) do
                if barConfig.id == self.barID then
                    barConfig.offsetX = self.config.offsetX
                    barConfig.offsetY = self.config.offsetY
                    break
                end
            end
        end


        if CustomTrackers.onPositionChanged then
            CustomTrackers.onPositionChanged(self.barID, self.config.offsetX, self.config.offsetY)
        end
    end)
end


function CustomTrackers:RefreshBarPosition(barID)
    local bar = self.activeBars[barID]
    if bar then
        PositionBar(bar)
    end
end


function CustomTrackers:CreateBar(barID, config)
    if not barID or not config then return nil end

    if self.activeBars[barID] then
        return self.activeBars[barID]
    end

    local bar = CreateFrame("Frame", "PREY_CustomTracker_" .. barID, UIParent, "BackdropTemplate")
    bar:SetFrameStrata("MEDIUM")


    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local hudLayering = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.hudLayering
    local layerPriority = hudLayering and hudLayering.customBars or 5
    local frameLevel = 50
    if PREYCore and PREYCore.GetHUDFrameLevel then
        frameLevel = PREYCore:GetHUDFrameLevel(layerPriority)
    end
    bar:SetFrameLevel(frameLevel)


    bar.barID = barID
    bar.config = config


    PositionBar(bar)


    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    local bgColor = config.bgColor or {0, 0, 0, 1}
    bar:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], config.bgOpacity or 0)


    bar.icons = {}


    self:SetupDragging(bar)


    self:UpdateBarIcons(bar)


    RebuildActiveSet(bar)


    self:StartCooldownPolling(bar)

    self.activeBars[barID] = bar

    if config.enabled then
        bar:Show()
    else
        bar:Hide()
    end

    return bar
end


function CustomTrackers:DeleteBar(barID)
    local bar = self.activeBars[barID]
    if bar then
        if bar.ticker then
            bar.ticker:Cancel()
        end

        for _, icon in ipairs(bar.icons or {}) do
            icon:Hide()
            icon:SetParent(nil)
        end
        bar:Hide()
        bar:SetParent(nil)
        self.activeBars[barID] = nil
    end
end


function CustomTrackers:UpdateBar(barID)
    local bar = self.activeBars[barID]
    if not bar then return end

    local db = GetDB()
    if not db or not db.bars then return end

    for _, barConfig in ipairs(db.bars) do
        if barConfig.id == barID then
            bar.config = barConfig


            local bgColor = barConfig.bgColor or {0, 0, 0, 1}
            bar:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], barConfig.bgOpacity or 0)


            self:UpdateBarIcons(bar)


            RebuildActiveSet(bar)


            if barConfig.enabled then
                bar:Show()
            else
                bar:Hide()
            end

            break
        end
    end
end


function CustomTrackers:RefreshAll()

    for barID in pairs(self.activeBars) do
        self:DeleteBar(barID)
    end


    local db = GetDB()
    if not db or not db.bars then return end

    for _, barConfig in ipairs(db.bars) do
        if barConfig.id then
            self:CreateBar(barConfig.id, barConfig)
        end
    end
end


function CustomTrackers:AddEntry(barID, entryType, entryID, specKeyOverride)
    local db = GetDB()
    if not db or not db.bars then return false end

    for _, barConfig in ipairs(db.bars) do
        if barConfig.id == barID then

            local entries
            local specKey

            if barConfig.specSpecificSpells then

                specKey = specKeyOverride or GetCurrentSpecKey()
                if not specKey then
                    return false
                end

                local globalDB = GetGlobalDB()
                if not globalDB then return false end

                if not globalDB.specTrackerSpells then
                    globalDB.specTrackerSpells = {}
                end
                if not globalDB.specTrackerSpells[barID] then
                    globalDB.specTrackerSpells[barID] = {}
                end
                if not globalDB.specTrackerSpells[barID][specKey] then
                    globalDB.specTrackerSpells[barID][specKey] = {}
                end

                entries = globalDB.specTrackerSpells[barID][specKey]
            else

                if not barConfig.entries then barConfig.entries = {} end
                entries = barConfig.entries
            end


            for _, entry in ipairs(entries) do
                if entry.type == entryType and entry.id == entryID then
                    return false
                end
            end

            table.insert(entries, {
                type = entryType,
                id = entryID,
            })


            if self.activeBars[barID] then
                local currentSpec = GetCurrentSpecKey()
                if not barConfig.specSpecificSpells or specKey == currentSpec then
                    self.activeBars[barID].config = barConfig
                    self:UpdateBarIcons(self.activeBars[barID])
                    RebuildActiveSet(self.activeBars[barID])
                end
            end

            return true
        end
    end
    return false
end

function CustomTrackers:RemoveEntry(barID, entryType, entryID, specKeyOverride)
    local db = GetDB()
    if not db or not db.bars then return false end

    for _, barConfig in ipairs(db.bars) do
        if barConfig.id == barID then

            local entries
            local specKey

            if barConfig.specSpecificSpells then

                specKey = specKeyOverride or GetCurrentSpecKey()
                if not specKey then
                    return false
                end

                local globalDB = GetGlobalDB()
                if not globalDB then return false end

                if not globalDB.specTrackerSpells or
                   not globalDB.specTrackerSpells[barID] or
                   not globalDB.specTrackerSpells[barID][specKey] then
                    return false
                end

                entries = globalDB.specTrackerSpells[barID][specKey]
            else

                entries = barConfig.entries
            end

            if entries then
                for i, entry in ipairs(entries) do
                    if entry.type == entryType and entry.id == entryID then
                        table.remove(entries, i)


                        if self.activeBars[barID] then
                            local currentSpec = GetCurrentSpecKey()
                            if not barConfig.specSpecificSpells or specKey == currentSpec then
                                self.activeBars[barID].config = barConfig
                                self:UpdateBarIcons(self.activeBars[barID])
                                RebuildActiveSet(self.activeBars[barID])
                            end
                        end

                        return true
                    end
                end
            end
        end
    end
    return false
end

function CustomTrackers:MoveEntry(barID, entryIndex, direction, specKeyOverride)
    local db = GetDB()
    if not db or not db.bars then return false end

    for _, barConfig in ipairs(db.bars) do
        if barConfig.id == barID then

            local entries
            local specKey

            if barConfig.specSpecificSpells then

                specKey = specKeyOverride or GetCurrentSpecKey()
                if not specKey then
                    return false
                end

                local globalDB = GetGlobalDB()
                if not globalDB or not globalDB.specTrackerSpells or
                   not globalDB.specTrackerSpells[barID] or
                   not globalDB.specTrackerSpells[barID][specKey] then
                    return false
                end

                entries = globalDB.specTrackerSpells[barID][specKey]
            else

                entries = barConfig.entries
            end

            if not entries then return false end

            local newIndex = entryIndex + direction
            if newIndex < 1 or newIndex > #entries then return false end


            local entry = table.remove(entries, entryIndex)
            table.insert(entries, newIndex, entry)


            if self.activeBars[barID] then
                local currentSpec = GetCurrentSpecKey()
                if not barConfig.specSpecificSpells or specKey == currentSpec then
                    self.activeBars[barID].config = barConfig
                    self:UpdateBarIcons(self.activeBars[barID])
                    RebuildActiveSet(self.activeBars[barID])
                end
            end
            return true
        end
    end
    return false
end


_G.PreyUI_RefreshCustomTrackers = function()

    if CustomTrackers then
        CustomTrackers:RefreshAll()
    end
end


local pendingTalentRebuild = false

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
initFrame:RegisterEvent("BAG_UPDATE_DELAYED")
initFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
initFrame:RegisterEvent("SPELL_UPDATE_USABLE")
initFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
initFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")

initFrame:RegisterEvent("UNIT_AURA")
initFrame:RegisterEvent("UNIT_SPELLCAST_START")
initFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
initFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
initFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
initFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")

initFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

initFrame:RegisterEvent("PLAYER_TALENT_UPDATE")

initFrame:RegisterEvent("UNIT_PET")
initFrame:SetScript("OnEvent", function(self, event, ...)


    if event == "PLAYER_SPECIALIZATION_CHANGED" then

        C_Timer.After(0.1, function()

            for _, bar in pairs(CustomTrackers.activeBars) do
                if bar then
                    RebuildActiveSet(bar)
                end
            end
            CustomTrackers:RefreshAll()
        end)
        return
    end


    if event == "PLAYER_TALENT_UPDATE" then

        if pendingTalentRebuild then return end
        pendingTalentRebuild = true
        C_Timer.After(0.1, function()
            pendingTalentRebuild = false
            for _, bar in pairs(CustomTrackers.activeBars) do
                if bar then
                    RebuildActiveSet(bar)
                end
            end
        end)
        return
    end


    if event == "UNIT_PET" then
        local unit = ...
        if unit == "player" then

            C_Timer.After(0.2, function()
                for _, bar in pairs(CustomTrackers.activeBars) do
                    if bar then
                        RebuildActiveSet(bar)


                        if bar.DoUpdate then
                            bar.DoUpdate()
                        end
                    end
                end
            end)
        end
        return
    end


    if event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_COOLDOWN" then

        for _, bar in pairs(CustomTrackers.activeBars) do
            if bar and bar:IsShown() and bar.DoUpdate then
                bar.DoUpdate()
            end
        end
        return
    end


    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_STOP" or
       event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_CHANNEL_START" or
       event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unit = ...
        if unit == "player" then
            for _, bar in pairs(CustomTrackers.activeBars) do
                if bar and bar:IsShown() and bar.DoUpdate and bar.config and bar.config.showActiveState ~= false then
                    bar.DoUpdate()
                end
            end
        end
        return
    end

    if event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            for _, bar in pairs(CustomTrackers.activeBars) do
                if bar and bar:IsShown() and bar.DoUpdate and bar.config and bar.config.showActiveState ~= false then
                    bar.DoUpdate()
                end
            end
        end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then

        PREYCore = PREY.PREYCore
        if PREYCore then
            PREYCore.CustomTrackers = CustomTrackers
        end

        C_Timer.After(0.6, function()
            CustomTrackers:RefreshAll()
        end)
    elseif event == "GET_ITEM_INFO_RECEIVED" then

        local itemID = ...
        if itemID then

            CustomTrackers.infoCache["item_" .. itemID] = nil

            for _, bar in pairs(CustomTrackers.activeBars) do
                for _, icon in ipairs(bar.icons or {}) do
                    if icon.entry and icon.entry.type == "item" and icon.entry.id == itemID then
                        local info = GetCachedItemInfo(itemID)
                        if info and info.icon then
                            icon.tex:SetTexture(info.icon)
                        end
                    end
                end
            end
        end
    end
end)


local CustomTrackersVisibility = {
    currentlyHidden = false,
    isFading = false,
    fadeStart = 0,
    fadeStartAlpha = 1,
    fadeTargetAlpha = 1,
    fadeFrame = nil,
    mouseOver = false,
    mouseoverDetector = nil,
}

local function GetCustomTrackersVisibilitySettings()
    local db = PREY.PREYCore and PREY.PREYCore.db
    if not db or not db.profile then return nil end
    return db.profile.customTrackersVisibility
end

local function GetCustomTrackerFrames()
    local frames = {}
    if CustomTrackers and CustomTrackers.activeBars then
        for _, bar in pairs(CustomTrackers.activeBars) do

            if bar and bar.config and bar.config.enabled and bar:IsShown() then
                table.insert(frames, bar)
            end
        end
    end
    return frames
end

local function ShouldCustomTrackersBeVisible()
    local vis = GetCustomTrackersVisibilitySettings()
    if not vis then return true end


    if vis.hideWhenMounted and (IsMounted() or GetShapeshiftFormID() == 27) then return false end


    if vis.showAlways then return true end


    if vis.showWhenTargetExists and UnitExists("target") then return true end
    if vis.showInCombat and UnitAffectingCombat("player") then return true end
    if vis.showInGroup and IsInGroup() then return true end
    if vis.showInInstance and IsPlayerInInstance() then return true end
    if vis.showOnMouseover and CustomTrackersVisibility.mouseOver then return true end

    return false
end

local function OnCustomTrackersFadeUpdate(self, elapsed)
    local now = GetTime()
    local vis = GetCustomTrackersVisibilitySettings()
    local duration = vis and vis.fadeDuration or 0.2

    local progress = (now - CustomTrackersVisibility.fadeStart) / duration
    if progress >= 1 then
        progress = 1
        CustomTrackersVisibility.isFading = false
        self:SetScript("OnUpdate", nil)
    end

    local alpha = CustomTrackersVisibility.fadeStartAlpha +
        (CustomTrackersVisibility.fadeTargetAlpha - CustomTrackersVisibility.fadeStartAlpha) * progress

    local frames = GetCustomTrackerFrames()
    for _, frame in ipairs(frames) do
        frame:SetAlpha(alpha)
    end
end

local function StartCustomTrackersFade(targetAlpha)
    local frames = GetCustomTrackerFrames()
    if #frames == 0 then return end

    local currentAlpha = frames[1]:GetAlpha()


    if math.abs(currentAlpha - targetAlpha) < 0.01 and not CustomTrackersVisibility.isFading then
        return
    end

    CustomTrackersVisibility.fadeStart = GetTime()
    CustomTrackersVisibility.fadeStartAlpha = currentAlpha
    CustomTrackersVisibility.fadeTargetAlpha = targetAlpha
    CustomTrackersVisibility.isFading = true

    if not CustomTrackersVisibility.fadeFrame then
        CustomTrackersVisibility.fadeFrame = CreateFrame("Frame")
    end
    CustomTrackersVisibility.fadeFrame:SetScript("OnUpdate", OnCustomTrackersFadeUpdate)
end

local function UpdateCustomTrackersVisibility()
    local vis = GetCustomTrackersVisibilitySettings()
    if not vis then return end

    local shouldShow = ShouldCustomTrackersBeVisible()

    if shouldShow then
        StartCustomTrackersFade(1)
        CustomTrackersVisibility.currentlyHidden = false
    else
        StartCustomTrackersFade(vis.fadeOutAlpha or 0)
        CustomTrackersVisibility.currentlyHidden = true
    end
end

local function SetupCustomTrackersMouseoverDetector()
    local vis = GetCustomTrackersVisibilitySettings()
    if not vis then return end


    if CustomTrackersVisibility.mouseoverDetector then
        CustomTrackersVisibility.mouseoverDetector:SetScript("OnUpdate", nil)
        CustomTrackersVisibility.mouseoverDetector:Hide()
        CustomTrackersVisibility.mouseoverDetector = nil
    end


    if not vis.showOnMouseover or vis.showAlways then
        return
    end

    local detector = CreateFrame("Frame")
    local lastCheck = 0
    detector:SetScript("OnUpdate", function(self, elapsed)

        if InCombatLockdown() then return end

        lastCheck = lastCheck + elapsed
        if lastCheck < 0.066 then return end
        lastCheck = 0

        local wasOver = CustomTrackersVisibility.mouseOver
        local isOver = false

        local frames = GetCustomTrackerFrames()
        for _, frame in ipairs(frames) do
            if frame:IsMouseOver() then
                isOver = true
                break
            end
        end

        if isOver ~= wasOver then
            CustomTrackersVisibility.mouseOver = isOver
            UpdateCustomTrackersVisibility()
        end
    end)
    detector:Show()
    CustomTrackersVisibility.mouseoverDetector = detector
end


local visibilityEventFrame = CreateFrame("Frame")
visibilityEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
visibilityEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
visibilityEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
visibilityEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
visibilityEventFrame:RegisterEvent("GROUP_JOINED")
visibilityEventFrame:RegisterEvent("GROUP_LEFT")
visibilityEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
visibilityEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
visibilityEventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
visibilityEventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
visibilityEventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1.5, function()
            SetupCustomTrackersMouseoverDetector()
            UpdateCustomTrackersVisibility()
        end)
    else
        UpdateCustomTrackersVisibility()
    end
end)


_G.PreyUI_RefreshCustomTrackersVisibility = UpdateCustomTrackersVisibility
_G.PreyUI_RefreshCustomTrackersMouseover = SetupCustomTrackersMouseoverDetector


_G.PreyUI_RefreshCustomTrackerKeybinds = function()
    for _, bar in pairs(CustomTrackers.activeBars or {}) do
        if bar and bar.icons then
            for _, icon in ipairs(bar.icons) do

                StyleTrackerIcon(icon, bar.config)

                ApplyKeybindToTrackerIcon(icon)
            end
        end
    end
end
