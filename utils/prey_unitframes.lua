local ADDON_NAME, ns = ...
local PREYCore = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")


local function SafeIndex(tbl, key, fallback)
    if not tbl then return fallback end
    local ok, val = pcall(function() return tbl[key] end)
    if ok then return val end
    return fallback
end

local IsSecretValue = function(v) return ns.Utils and ns.Utils.IsSecretValue and ns.Utils.IsSecretValue(v) or false end


local PREY_UF = {}
ns.PREY_UnitFrames = PREY_UF


PREY_UF.frames = {}
PREY_UF.castbars = {}
PREY_UF.previewMode = {}
PREY_UF.auraPreviewMode = {}


local PREY_Castbar = ns.PREY_Castbar


PREY_UF.editModeSliders = {}


local POWER_COLORS = {
    [0] = { 0, 0.50, 1 },
    [1] = { 1, 0, 0 },
    [2] = { 1, 0.5, 0.25 },
    [3] = { 1, 1, 0 },
    [6] = { 0, 0.82, 1 },
    [8] = { 0.3, 0.52, 0.9 },
    [11] = { 0, 0.5, 1 },
    [13] = { 0.4, 0, 0.8 },
}


local PREVIEW_AURAS = {
    buffs = {
        {icon = "Interface\\Icons\\spell_nature_regenerate", stacks = 0, duration = 10},
        {icon = "Interface\\Icons\\spell_holy_powerwordshield", stacks = 0, duration = 10},
        {icon = "Interface\\Icons\\spell_nature_lightningshield", stacks = 3, duration = 10},
        {icon = "Interface\\Icons\\ability_warrior_battleshout", stacks = 5, duration = 10},
    },
    debuffs = {
        {icon = "Interface\\Icons\\spell_shadow_shadowwordpain", stacks = 0, duration = 10},
        {icon = "Interface\\Icons\\spell_shadow_mindblast", stacks = 0, duration = 10},
        {icon = "Interface\\Icons\\spell_nature_slow", stacks = 2, duration = 10},
        {icon = "Interface\\Icons\\spell_shadow_shadesofdarkness", stacks = 5, duration = 10},
    }
}


local tocVersion = tonumber((select(4, GetBuildInfo()))) or 0

local function GetHealthPct(unit, usePredicted)
    if tocVersion >= 120000 and type(UnitHealthPercent) == "function" then
        local ok, pct

        if CurveConstants and CurveConstants.ScaleTo100 then
            ok, pct = pcall(UnitHealthPercent, unit, usePredicted, CurveConstants.ScaleTo100)
        end

        if not ok or pct == nil then
            ok, pct = pcall(UnitHealthPercent, unit, usePredicted)
        end
        if ok and pct ~= nil then
            return pct
        end
    end

    if UnitHealth and UnitHealthMax then
        local cur = UnitHealth(unit)
        local max = UnitHealthMax(unit)
        if cur and max and max > 0 then

            local ok, pct = pcall(function() return (cur / max) * 100 end)
            if ok then return pct end
        end
    end
    return nil
end


local function GetPowerPct(unit, powerType, usePredicted)

    if tocVersion >= 120000 and type(UnitPowerPercent) == "function" then
        local ok, pct

        if CurveConstants and CurveConstants.ScaleTo100 then
            ok, pct = pcall(UnitPowerPercent, unit, powerType, usePredicted, CurveConstants.ScaleTo100)
        end

        if not ok or pct == nil then
            ok, pct = pcall(UnitPowerPercent, unit, powerType, usePredicted)
        end
        if ok and pct ~= nil then
            return pct
        end
    end

    local cur = UnitPower(unit, powerType)
    local max = UnitPowerMax(unit, powerType)
    local calcOk, result = pcall(function()
        if cur and max and max > 0 then
            return (cur / max) * 100
        end
        return nil
    end)
    if calcOk and result then
        return result
    end
    return nil
end


local function GetDB()
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.quiUnitFrames then
        return PREYCore.db.profile.quiUnitFrames
    end
    return nil
end

local function GetGeneralSettings()

    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        return PREYCore.db.profile.general
    end
    return nil
end

local function GetUnitSettings(unit)
    local db = GetDB()
    return db and db[unit]
end


local function Scale(x)
    if PREYCore and PREYCore.Scale then
        return PREYCore:Scale(x)
    end
    return x
end


local function ShowUnitTooltip(frame)
    local ufdb = GetDB()
    local general = ufdb and ufdb.general


    if not general or general.showTooltips == false then
        return
    end


    local unit = frame.unit or (frame.GetAttribute and frame:GetAttribute("unit"))
    if not unit then

        local parent = frame:GetParent()
        if parent then
            unit = parent.unit or (parent.GetAttribute and parent:GetAttribute("unit"))
        end
    end

    if not unit or not UnitExists(unit) then return end


    GameTooltip_SetDefaultAnchor(GameTooltip, frame)
    GameTooltip:SetUnit(unit)
    GameTooltip:Show()
end

local function HideUnitTooltip()
    GameTooltip:Hide()
end


local function GetFontPath()
    local general = GetGeneralSettings()
    if not general then return "Fonts\\FRIZQT__.TTF" end

    local fontName = general.font or "Friz Quadrata TT"
    return LSM:Fetch("font", fontName) or "Fonts\\FRIZQT__.TTF"
end


local function GetFontOutline()
    local general = GetGeneralSettings()
    if not general then return "OUTLINE" end
    return general.fontOutline or "OUTLINE"
end


local function GetTexturePath(textureName)
    local name = textureName

    if not name or name == "" then
        local general = GetGeneralSettings()
        name = general and general.texture or "Prey"
    end
    return LSM:Fetch("statusbar", name) or "Interface\\Buttons\\WHITE8x8"
end

local function GetAbsorbTexturePath(textureName)
    local name = textureName
    if not name or name == "" then
        name = "PREY Stripes"
    end
    return LSM:Fetch("statusbar", name) or "Interface\\AddOns\\PreyUI\\assets\\absorb_stripe"
end


local function GetUnitClassColor(unit)
    if not UnitExists(unit) then
        return 0.5, 0.5, 0.5, 1
    end


    local isPlayer = UnitIsPlayer(unit)
    if isPlayer then
        local _, class = UnitClass(unit)
        if class then
            local color = RAID_CLASS_COLORS[class]
            if color then
                return color.r, color.g, color.b, 1
            end
        end
    end


    local reaction = UnitReaction(unit, "player")
    if reaction then
        if reaction >= 5 then
            return 0.2, 0.8, 0.2, 1
        elseif reaction == 4 then
            return 1, 1, 0.2, 1
        else
            return 0.8, 0.2, 0.2, 1
        end
    end

    return 0.5, 0.5, 0.5, 1
end


local function GetTextAnchorInfo(anchor)
    local anchorMap = {
        TOPLEFT     = { point = "TOPLEFT",     justify = "LEFT" },
        TOP         = { point = "TOP",         justify = "CENTER" },
        TOPRIGHT    = { point = "TOPRIGHT",    justify = "RIGHT" },
        LEFT        = { point = "LEFT",        justify = "LEFT" },
        CENTER      = { point = "CENTER",      justify = "CENTER" },
        RIGHT       = { point = "RIGHT",       justify = "RIGHT" },
        BOTTOMLEFT  = { point = "BOTTOMLEFT",  justify = "LEFT" },
        BOTTOM      = { point = "BOTTOM",      justify = "CENTER" },
        BOTTOMRIGHT = { point = "BOTTOMRIGHT", justify = "RIGHT" },
    }
    return anchorMap[anchor] or anchorMap.LEFT
end


local function TruncateName(name, maxLength)
    if not name or type(name) ~= "string" then return name end
    if not maxLength or maxLength <= 0 then return name end


    if IsSecretValue(name) then
        return string.format("%." .. maxLength .. "s", name)
    end


    local lenOk, nameLen = pcall(function() return #name end)
    if not lenOk then

        return string.format("%." .. maxLength .. "s", name)
    end


    if nameLen <= maxLength then
        return name
    end


    local byte = string.byte
    local i = 1
    local c = 0
    while i <= nameLen and c < maxLength do
        c = c + 1
        local b = byte(name, i)
        if b < 0x80 then
            i = i + 1
        elseif b < 0xE0 then
            i = i + 2
        elseif b < 0xF0 then
            i = i + 3
        else
            i = i + 4
        end
    end

    local subOk, truncated = pcall(string.sub, name, 1, i - 1)
    if subOk and truncated then
        return truncated
    end


    return string.format("%." .. maxLength .. "s", name)
end


local function FormatHealthText(hp, hpPct, style, divider, maxHp)
    style = style or "both"
    divider = divider or " | "


    local success, hpStr = pcall(function()
        local abbr = AbbreviateNumbers or AbbreviateLargeNumbers
        return abbr and abbr(hp) or tostring(hp)
    end)
    if not success then hpStr = "" end

    if style == "percent" then
        if hpPct then
            local success, result = pcall(function() return string.format("%d%%", hpPct) end)
            return success and result or ""
        end
        return ""
    elseif style == "absolute" then
        return hpStr or ""
    elseif style == "both" then
        if hpPct then
            local success, result = pcall(function() return string.format("%s%s%d%%", hpStr or "", divider, hpPct) end)
            return success and result or hpStr or ""
        end
        return hpStr or ""
    elseif style == "both_reverse" then
        if hpPct then
            local success, result = pcall(function() return string.format("%d%%%s%s", hpPct, divider, hpStr or "") end)
            return success and result or hpStr or ""
        end
        return hpStr or ""
    elseif style == "missing_percent" then
        if hpPct then

            local success, missing = pcall(function() return 100 - hpPct end)
            if not success then return "" end
            if missing > 0 then
                return string.format("-%d%%", missing)
            end
            return "0%"
        end
        return ""
    elseif style == "missing_value" then
        if hp and maxHp then

            local success, missing = pcall(function() return maxHp - hp end)
            if not success then return "" end
            if missing > 0 then
                local abbr = AbbreviateNumbers or AbbreviateLargeNumbers
                local missingStr = abbr and abbr(missing) or tostring(missing)
                return "-" .. missingStr
            end
            return "0"
        end
        return ""
    end

    return hpStr or ""
end


local function FormatPowerText(power, powerPct, style, divider)
    style = style or "percent"
    divider = divider or " | "


    local powerStr = ""
    pcall(function()
        local abbr = AbbreviateNumbers or AbbreviateLargeNumbers
        powerStr = abbr and abbr(power) or tostring(power)
    end)


    local result = ""

    if style == "percent" then
        local fmtOk = pcall(function()
            if powerPct then
                result = string.format("%d%%", powerPct)
            end
        end)
        if not fmtOk then result = "" end
    elseif style == "current" then
        local fmtOk = pcall(function()
            result = powerStr or ""
        end)
        if not fmtOk then result = "" end
    elseif style == "both" then
        local fmtOk = pcall(function()
            if powerPct then
                result = string.format("%s%s%d%%", powerStr or "", divider, powerPct)
            else
                result = powerStr or ""
            end
        end)
        if not fmtOk then result = "" end
    else
        local fmtOk = pcall(function()
            result = powerStr or ""
        end)
        if not fmtOk then result = "" end
    end

    return result
end


local function GetUnitHostilityColor(unit)
    if not UnitExists(unit) then
        return 0.5, 0.5, 0.5, 1
    end


    local db = GetDB()
    local general = db and db.general

    local reaction = UnitReaction(unit, "player")
    if type(reaction) == "number" then
        if reaction >= 5 then
            local c = general and general.hostilityColorFriendly or { 0.2, 0.8, 0.2, 1 }
            return c[1], c[2], c[3], c[4] or 1
        elseif reaction == 4 then
            local c = general and general.hostilityColorNeutral or { 1, 1, 0.2, 1 }
            return c[1], c[2], c[3], c[4] or 1
        else
            local c = general and general.hostilityColorHostile or { 0.8, 0.2, 0.2, 1 }
            return c[1], c[2], c[3], c[4] or 1
        end
    end


    return 0.5, 0.5, 0.5, 1
end


local function GetHealthBarColor(unit, settings)
    if not UnitExists(unit) then
        return 0.5, 0.5, 0.5, 1
    end


    local general = GetGeneralSettings()


    local useClassColor = false
    if settings and settings.useClassColor ~= nil then
        useClassColor = settings.useClassColor
    else
        useClassColor = general and general.defaultUseClassColor
    end

    if useClassColor then
        local isPlayer = UnitIsPlayer(unit)
        if type(isPlayer) == "boolean" and isPlayer then

            local _, class = UnitClass(unit)
            if type(class) == "string" then
                local color = RAID_CLASS_COLORS[class]
                if color then
                    return color.r, color.g, color.b, 1
                end
            end
        else

            local petCheck = UnitIsUnit(unit, "pet")
            local playerPetCheck = UnitIsUnit(unit, "playerpet")
            local isPet = (not IsSecretValue(petCheck) and petCheck == true) or (not IsSecretValue(playerPetCheck) and playerPetCheck == true)
            if isPet then

                local _, class = UnitClass("player")
                if type(class) == "string" then
                    local color = RAID_CLASS_COLORS[class]
                    if color then
                        return color.r, color.g, color.b, 1
                    end
                end
            end
        end
    end


    if settings and settings.useHostilityColor then
        local reaction = UnitReaction(unit, "player")
        if type(reaction) == "number" then
            if reaction >= 5 then
                local c = general and general.hostilityColorFriendly or { 0.2, 0.8, 0.2, 1 }
                return c[1], c[2], c[3], c[4] or 1
            elseif reaction == 4 then
                local c = general and general.hostilityColorNeutral or { 1, 1, 0.2, 1 }
                return c[1], c[2], c[3], c[4] or 1
            else
                local c = general and general.hostilityColorHostile or { 0.8, 0.2, 0.2, 1 }
                return c[1], c[2], c[3], c[4] or 1
            end
        end
    end


    if settings and settings.customHealthColor then
        local c = settings.customHealthColor
        return c[1], c[2], c[3], c[4] or 1
    end


    local c = general and general.defaultHealthColor or { 0.2, 0.2, 0.2, 1 }
    return c[1], c[2], c[3], c[4] or 1
end


local function GetUnitPowerColor(unit)
    local powerType = UnitPowerType(unit)
    local color = POWER_COLORS[powerType]
    if color then
        return color[1], color[2], color[3], 1
    end
    return 0.5, 0.5, 0.5, 1
end


local function UpdateHealth(frame)
    if not frame or not frame.unit or not frame.healthBar then return end
    local unit = frame.unit


    if not UnitExists(unit) then
        return
    end


    local hp = UnitHealth(unit)
    local maxHP = UnitHealthMax(unit)


    frame.healthBar:SetMinMaxValues(0, maxHP or 1)
    frame.healthBar:SetValue(hp or 0)


    if frame.healthText then
        local settings = GetUnitSettings(frame.unitKey)


        if settings and settings.showHealth == false then
            frame.healthText:Hide()
        else

            local displayStyle = settings and settings.healthDisplayStyle
            if not displayStyle then

                local showAbsolute = settings and settings.showHealthAbsolute
                local showPercent = settings and settings.showHealthPercent
                if showPercent == nil then showPercent = true end

                if showAbsolute and showPercent then
                    displayStyle = "both"
                elseif showAbsolute then
                    displayStyle = "absolute"
                elseif showPercent then
                    displayStyle = "percent"
                else
                    displayStyle = "percent"
                end
            end

            local divider = settings and settings.healthDivider or " | "

            if hp then
                local hpPct = GetHealthPct(unit, false)
                local healthStr = FormatHealthText(hp, hpPct, displayStyle, divider, maxHP)
                frame.healthText:SetText(healthStr)
                frame.healthText:Show()
            else
                frame.healthText:SetText("")
            end
        end
    end


    local general = GetGeneralSettings()
    local settings = GetUnitSettings(frame.unitKey)

    if general and general.darkMode then
        local c = general.darkModeHealthColor or { 0.15, 0.15, 0.15, 1 }
        frame.healthBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
    else
        local r, g, b, a = GetHealthBarColor(frame.unit, settings)
        frame.healthBar:SetStatusBarColor(r, g, b, a)
    end
end


local function UpdateAbsorbs(frame)
    if not frame or not frame.unit or not frame.healthBar then return end
    if not frame.absorbBar then return end

    local unit = frame.unit
    local settings = GetUnitSettings(frame.unitKey)


    if not settings or not settings.absorbs or settings.absorbs.enabled == false then
        frame.absorbBar:Hide()
        if frame.absorbOverflowBar then frame.absorbOverflowBar:Hide() end
        if frame.healAbsorbBar then frame.healAbsorbBar:Hide() end
        return
    end

    if not UnitExists(unit) then
        frame.absorbBar:Hide()
        if frame.absorbOverflowBar then frame.absorbOverflowBar:Hide() end
        if frame.healAbsorbBar then frame.healAbsorbBar:Hide() end
        return
    end


    local maxHealth = UnitHealthMax(unit)
    local absorbAmount = UnitGetTotalAbsorbs(unit)
    local healthTexture = frame.healthBar:GetStatusBarTexture()


    local absorbSettings = settings.absorbs or {}
    local c = absorbSettings.color or { 1, 1, 1 }
    local a = absorbSettings.opacity or 0.7


    local hideAbsorb = false
    if not absorbAmount then
        hideAbsorb = true
    else
        local success, isZero = pcall(function() return absorbAmount == 0 end)
        if success and isZero then
            hideAbsorb = true
        end
    end

    if hideAbsorb then
        frame.absorbBar:Hide()
        if frame.absorbOverflowBar then frame.absorbOverflowBar:Hide() end
        return
    end


    do


        local absorbTexturePath = GetAbsorbTexturePath(absorbSettings.texture)
        if not frame.absorbOverflowBar then
            frame.absorbOverflowBar = CreateFrame("StatusBar", nil, frame.healthBar)
            frame.absorbOverflowBar:SetStatusBarTexture(absorbTexturePath)
            local overflowBarTex = frame.absorbOverflowBar:GetStatusBarTexture()
            if overflowBarTex then
                overflowBarTex:SetHorizTile(false)
                overflowBarTex:SetVertTile(false)
                overflowBarTex:SetTexCoord(0, 1, 0, 1)
            end
            frame.absorbOverflowBar:SetFrameLevel(frame.healthBar:GetFrameLevel() + 2)
            frame.absorbOverflowBar:EnableMouse(false)
        else

            frame.absorbOverflowBar:SetStatusBarTexture(absorbTexturePath)
        end


        if not frame.attachedVisHelper then
            frame.attachedVisHelper = frame.absorbBar:CreateTexture(nil, "BACKGROUND")
            frame.attachedVisHelper:SetSize(1, 1)
            frame.attachedVisHelper:SetColorTexture(0, 0, 0, 0)
        end
        if not frame.overflowVisHelper then
            frame.overflowVisHelper = frame.absorbOverflowBar:CreateTexture(nil, "BACKGROUND")
            frame.overflowVisHelper:SetSize(1, 1)
            frame.overflowVisHelper:SetColorTexture(0, 0, 0, 0)
        end


        local clampedAbsorbs = absorbAmount


        frame.attachedVisHelper:SetAlpha(1)
        frame.overflowVisHelper:SetAlpha(0)

        if CreateUnitHealPredictionCalculator and unit then

            if not frame.absorbCalculator then
                frame.absorbCalculator = CreateUnitHealPredictionCalculator()
            end
            local calc = frame.absorbCalculator


            pcall(function() calc:SetDamageAbsorbClampMode(1) end)


            UnitGetDetailedHealPrediction(unit, nil, calc)


            local results = { pcall(function() return calc:GetDamageAbsorbs() end) }
            local success = results[1]


            if success then

                clampedAbsorbs = results[2]


                pcall(function()
                    frame.attachedVisHelper:SetAlphaFromBoolean(results[3], 0, 1)
                    frame.overflowVisHelper:SetAlphaFromBoolean(results[3], 1, 0)
                end)
            end
        end


        frame.absorbBar:ClearAllPoints()
        frame.absorbBar:SetPoint("LEFT", healthTexture, "RIGHT", 0, 0)
        frame.absorbBar:SetHeight(frame.healthBar:GetHeight())
        frame.absorbBar:SetWidth(frame.healthBar:GetWidth())
        frame.absorbBar:SetReverseFill(false)
        frame.absorbBar:SetMinMaxValues(0, maxHealth or 1)
        frame.absorbBar:SetValue(clampedAbsorbs)
        frame.absorbBar:SetStatusBarTexture(absorbTexturePath)
        frame.absorbBar:SetStatusBarColor(c[1], c[2], c[3], a)
        frame.absorbBar:SetAlpha(frame.attachedVisHelper:GetAlpha())
        frame.absorbBar:Show()


        frame.absorbOverflowBar:ClearAllPoints()
        frame.absorbOverflowBar:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT", 0, 0)
        frame.absorbOverflowBar:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, 0)
        frame.absorbOverflowBar:SetReverseFill(true)
        frame.absorbOverflowBar:SetMinMaxValues(0, maxHealth or 1)
        frame.absorbOverflowBar:SetValue(absorbAmount)
        frame.absorbOverflowBar:SetStatusBarColor(c[1], c[2], c[3], a)
        frame.absorbOverflowBar:SetAlpha(frame.overflowVisHelper:GetAlpha())
        frame.absorbOverflowBar:Show()
    end


    if frame.healAbsorbBar then
        local healAbsorbAmount = UnitGetTotalHealAbsorbs(unit)
        frame.healAbsorbBar:ClearAllPoints()
        frame.healAbsorbBar:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT", 0, 0)
        frame.healAbsorbBar:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, 0)
        frame.healAbsorbBar:SetReverseFill(false)
        frame.healAbsorbBar:SetMinMaxValues(0, maxHealth or 1)
        frame.healAbsorbBar:SetValue(healAbsorbAmount or 0)


        local hideHealAbsorb = false
        if not healAbsorbAmount then
            hideHealAbsorb = true
        else
            local success, isZero = pcall(function() return healAbsorbAmount == 0 end)
            if success and isZero then
                hideHealAbsorb = true
            end
        end

        if hideHealAbsorb then
            frame.healAbsorbBar:Hide()
        else
            frame.healAbsorbBar:Show()
        end
    end
end


local function UpdatePower(frame)
    if not frame or not frame.unit or not frame.powerBar then return end
    local unit = frame.unit

    if not UnitExists(unit) then return end

    local settings = GetUnitSettings(frame.unitKey)
    if not settings or not settings.showPowerBar then
        frame.powerBar:Hide()
        return
    end


    local p = UnitPower(unit)
    local pMax = UnitPowerMax(unit)


    frame.powerBar:SetMinMaxValues(0, pMax or 1)
    frame.powerBar:SetValue(p or 0)
    frame.powerBar:Show()


    if settings.powerBarUsePowerColor ~= false then
        local r, g, b = GetUnitPowerColor(unit)
        frame.powerBar:SetStatusBarColor(r, g, b, 1)
    else
        local c = settings.powerBarColor or { 0, 0.5, 1, 1 }
        frame.powerBar:SetStatusBarColor(c[1], c[2], c[3], 1)
    end
end


local function UpdatePowerText(frame)
    if not frame or not frame.unit then return end
    if not frame.powerText then return end

    local unit = frame.unit
    local settings = GetUnitSettings(frame.unitKey)


    if not settings or not settings.showPowerText then
        frame.powerText:Hide()
        return
    end

    if not UnitExists(unit) then
        frame.powerText:Hide()
        return
    end


    local powerPct = GetPowerPct(unit)


    local power = UnitPower(unit)


    local style = settings.powerTextFormat or "percent"
    local divider = settings.healthDivider or " | "
    local powerStr = FormatPowerText(power, powerPct, style, divider)


    if powerStr then
        local setOk = pcall(function()
            frame.powerText:SetText(powerStr)
        end)

        if setOk then

            local general = GetGeneralSettings()
            if general and general.masterColorPowerText then

                local r, g, b = GetUnitClassColor(unit)
                frame.powerText:SetTextColor(r, g, b, 1)
            elseif settings.powerTextUsePowerColor then

                local r, g, b = GetUnitPowerColor(unit)
                frame.powerText:SetTextColor(r, g, b, 1)
            elseif settings.powerTextUseClassColor then

                local r, g, b = GetUnitClassColor(unit)
                frame.powerText:SetTextColor(r, g, b, 1)
            elseif settings.powerTextColor then

                local c = settings.powerTextColor
                frame.powerText:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
            else

                frame.powerText:SetTextColor(1, 1, 1, 1)
            end
            frame.powerText:Show()
        else
            frame.powerText:Hide()
        end
    else
        frame.powerText:Hide()
    end
end


local function UpdateIndicators(frame)
    if not frame or frame.unitKey ~= "player" then return end
    local settings = GetUnitSettings("player")
    if not settings or not settings.indicators then return end

    local indSettings = settings.indicators


    if frame.restedIndicator then
        local rested = indSettings.rested
        if rested and rested.enabled and IsResting() then
            frame.restedIndicator:Show()
        else
            frame.restedIndicator:Hide()
        end
    end


    if frame.combatIndicator then
        local combat = indSettings.combat
        if combat and combat.enabled and UnitAffectingCombat("player") then
            frame.combatIndicator:Show()
        else
            frame.combatIndicator:Hide()
        end
    end
end


local function UpdateStance(frame)
    if not frame or frame.unitKey ~= "player" then return end
    if not frame.stanceText then return end

    local settings = GetUnitSettings("player")
    if not settings or not settings.indicators or not settings.indicators.stance then
        frame.stanceText:Hide()
        if frame.stanceIcon then frame.stanceIcon:Hide() end
        return
    end

    local stanceSettings = settings.indicators.stance
    if not stanceSettings.enabled then
        frame.stanceText:Hide()
        if frame.stanceIcon then frame.stanceIcon:Hide() end
        return
    end

    local general = GetGeneralSettings()


    local fontPath = GetFontPath()
    local fontOutline = general and general.fontOutline or "OUTLINE"
    local fontSize = stanceSettings.fontSize or 12
    frame.stanceText:SetFont(fontPath, fontSize, fontOutline)


    local anchorInfo = GetTextAnchorInfo(stanceSettings.anchor or "BOTTOM")
    local offsetX = stanceSettings.offsetX or 0
    local offsetY = stanceSettings.offsetY or -2

    frame.stanceText:ClearAllPoints()
    frame.stanceText:SetPoint(anchorInfo.point, frame, anchorInfo.point, offsetX, offsetY)
    frame.stanceText:SetJustifyH(anchorInfo.justify)


    local formIndex = GetShapeshiftForm()
    local formName = nil
    local formIcon = nil

    if formIndex and formIndex > 0 then
        local icon, active, castable, spellID = GetShapeshiftFormInfo(formIndex)
        if spellID then
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            if spellInfo then
                formName = spellInfo.name
            end
        end
        formIcon = icon
    end


    if not formName or formName == "" then
        frame.stanceText:Hide()
        if frame.stanceIcon then frame.stanceIcon:Hide() end
        return
    end


    frame.stanceText:SetText(formName)


    if stanceSettings.useClassColor then
        local _, class = UnitClass("player")
        if class then
            local color = RAID_CLASS_COLORS[class]
            if color then
                frame.stanceText:SetTextColor(color.r, color.g, color.b, 1)
            else
                frame.stanceText:SetTextColor(1, 1, 1, 1)
            end
        end
    else
        local c = stanceSettings.customColor or { 1, 1, 1, 1 }
        frame.stanceText:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    end

    frame.stanceText:Show()


    if frame.stanceIcon then
        local iconSize = stanceSettings.iconSize or 14
        local iconOffsetX = stanceSettings.iconOffsetX or -2
        frame.stanceIcon:SetSize(iconSize, iconSize)
        frame.stanceIcon:ClearAllPoints()
        frame.stanceIcon:SetPoint("RIGHT", frame.stanceText, "LEFT", iconOffsetX, 0)

        if stanceSettings.showIcon and formIcon then
            frame.stanceIcon:SetTexture(formIcon)
            frame.stanceIcon:Show()
        else
            frame.stanceIcon:Hide()
        end
    end
end


local function UpdateTargetMarker(frame)
    if not frame or not frame.unit or not frame.targetMarker then return end
    local settings = GetUnitSettings(frame.unitKey)
    if not settings or not settings.targetMarker or not settings.targetMarker.enabled then
        frame.targetMarker:Hide()
        return
    end

    local index = GetRaidTargetIndex(frame.unit)
    if index then
        SetRaidTargetIconTexture(frame.targetMarker, index)
        frame.targetMarker:Show()
    else
        frame.targetMarker:Hide()
    end
end


local function UpdateLeaderIcon(frame)
    if not frame or not frame.unit or not frame.leaderIcon then return end
    local settings = GetUnitSettings(frame.unitKey)
    if not settings or not settings.leaderIcon or not settings.leaderIcon.enabled then
        frame.leaderIcon:Hide()
        return
    end


    if not IsInGroup() then
        frame.leaderIcon:Hide()
        return
    end


    if UnitIsGroupLeader(frame.unit) then
        frame.leaderIcon:SetTexture([[Interface\GroupFrame\UI-Group-LeaderIcon]])
        frame.leaderIcon:Show()
    elseif IsInRaid() and UnitIsGroupAssistant(frame.unit) then
        frame.leaderIcon:SetTexture([[Interface\GroupFrame\UI-Group-AssistantIcon]])
        frame.leaderIcon:Show()
    else
        frame.leaderIcon:Hide()
    end
end


local function UpdateHealthTextColor(frame)
    if not frame or not frame.healthText or not frame.unit then return end

    local settings = GetUnitSettings(frame.unitKey)
    if not settings then return end

    local general = GetGeneralSettings()

    if general and general.masterColorHealthText then
        local r, g, b = GetUnitClassColor(frame.unit)
        frame.healthText:SetTextColor(r, g, b, 1)
    elseif settings.healthTextUseClassColor then
        local r, g, b = GetUnitClassColor(frame.unit)
        frame.healthText:SetTextColor(r, g, b, 1)
    elseif settings.healthTextColor then
        local c = settings.healthTextColor
        frame.healthText:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
    elseif general and general.classColorText then
        local r, g, b = GetUnitClassColor(frame.unit)
        frame.healthText:SetTextColor(r, g, b, 1)
    else
        frame.healthText:SetTextColor(1, 1, 1, 1)
    end
end


local function UpdateName(frame)
    if not frame or not frame.unit or not frame.nameText then return end
    local unit = frame.unit

    local settings = GetUnitSettings(frame.unitKey)
    if not settings or not settings.showName then
        frame.nameText:Hide()
        return
    end

    local name = UnitName(unit) or ""


    local maxLen = settings.maxNameLength
    if maxLen and maxLen > 0 then
        name = TruncateName(name, maxLen)
    end


    if frame.unitKey == "target" and settings.showInlineToT then
        local totUnit = "targettarget"
        if UnitExists(totUnit) then
            local totName = UnitName(totUnit) or ""
            local totCharLimit = settings.totNameCharLimit
            if totCharLimit and totCharLimit > 0 then
                totName = TruncateName(totName, totCharLimit)
            elseif maxLen and maxLen > 0 then
                totName = TruncateName(totName, maxLen)
            end
            local separator = settings.totSeparator or " >> "


            local dividerColorHex
            if settings.totDividerUseClassColor then

                local dR, dG, dB = GetUnitClassColor(totUnit)
                dividerColorHex = string.format("|cff%02x%02x%02x", dR * 255, dG * 255, dB * 255)
            elseif settings.totDividerColor then

                local c = settings.totDividerColor
                dividerColorHex = string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
            else

                dividerColorHex = "|cFFFFFFFF"
            end


            local general = GetGeneralSettings()
            if general and general.masterColorToTText then

                local totR, totG, totB = GetUnitClassColor(totUnit)
                local totColorHex = string.format("|cff%02x%02x%02x", totR * 255, totG * 255, totB * 255)
                name = name .. dividerColorHex .. separator .. "|r" .. totColorHex .. totName .. "|r"
            elseif settings.totUseClassColor then

                local totR, totG, totB = GetUnitClassColor(totUnit)
                local totColorHex = string.format("|cff%02x%02x%02x", totR * 255, totG * 255, totB * 255)
                name = name .. dividerColorHex .. separator .. "|r" .. totColorHex .. totName .. "|r"
            else

                name = name .. dividerColorHex .. separator .. "|r" .. totName
            end
        end
    end

    frame.nameText:SetText(name)


    local general = GetGeneralSettings()
    if general and general.masterColorNameText then

        local r, g, b = GetUnitClassColor(unit)
        frame.nameText:SetTextColor(r, g, b, 1)
    elseif settings.nameTextUseClassColor then

        local r, g, b = GetUnitClassColor(unit)
        frame.nameText:SetTextColor(r, g, b, 1)
    elseif settings.nameTextColor then

        local c = settings.nameTextColor
        frame.nameText:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
    elseif general and general.classColorText then

        local r, g, b = GetUnitClassColor(unit)
        frame.nameText:SetTextColor(r, g, b, 1)
    else

        frame.nameText:SetTextColor(1, 1, 1, 1)
    end

    frame.nameText:Show()
end


local function UpdateFrame(frame)
    if not frame then return end


    if frame.healthBar then
        local general = GetGeneralSettings()
        local settings = GetUnitSettings(frame.unitKey)

        if general and general.darkMode then
            local c = general.darkModeHealthColor or { 0.15, 0.15, 0.15, 1 }
            frame.healthBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
        else

            local r, g, b, a = GetHealthBarColor(frame.unit, settings)
            frame.healthBar:SetStatusBarColor(r, g, b, a)
        end
    end

    UpdateHealth(frame)
    UpdateAbsorbs(frame)
    UpdatePower(frame)
    UpdatePowerText(frame)
    UpdateName(frame)
    UpdateHealthTextColor(frame)
    UpdateIndicators(frame)
    UpdateStance(frame)
    UpdateTargetMarker(frame)
    UpdateLeaderIcon(frame)


    if frame.portraitTexture and frame.portrait and frame.portrait:IsShown() then
        if UnitExists(frame.unit) then
            SetPortraitTexture(frame.portraitTexture, frame.unit, true)
            frame.portraitTexture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
        end
    end
end


local function CreateBossFrame(unit, frameKey, bossIndex)

    local settings = GetUnitSettings("boss")
    local general = GetGeneralSettings()

    if not settings then return nil end


    local frameName = "PREY_Boss" .. bossIndex
    local frame = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate, BackdropTemplate, PingableUnitFrameTemplate")

    frame.unit = unit
    frame.unitKey = "boss"


    local width = Scale(settings.width or 220)
    local height = Scale(settings.height or 35)
    frame:SetSize(width, height)


    local offsetX = Scale(settings.offsetX or 0)
    local offsetY = Scale(settings.offsetY or 0)
    frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)


    frame:SetMovable(true)
    frame:SetClampedToScreen(true)


    frame:SetAttribute("unit", unit)
    frame:SetAttribute("*type1", "target")
    frame:SetAttribute("*type2", "togglemenu")
    frame:RegisterForClicks("AnyUp")


    frame:HookScript("OnEnter", function(self)
        ShowUnitTooltip(self)
    end)
    frame:HookScript("OnLeave", HideUnitTooltip)


    RegisterStateDriver(frame, "visibility", "[@" .. unit .. ",exists] show; hide")


    frame:HookScript("OnShow", function(self)
        local bossKey = "boss" .. bossIndex
        if PREY_UF.previewMode[bossKey] then return end
        UpdateFrame(self)
    end)


    local bgColor = { 0.1, 0.1, 0.1, 0.9 }
    if general and general.darkMode then
        bgColor = general.darkModeBgColor or { 0.25, 0.25, 0.25, 1 }
    end

    local borderSize = Scale(settings.borderSize or 1)

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = borderSize > 0 and "Interface\\Buttons\\WHITE8x8" or nil,
        edgeSize = borderSize > 0 and borderSize or nil,
    })
    frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    if borderSize > 0 then
        frame:SetBackdropBorderColor(0, 0, 0, 1)
    end


    local powerHeight = settings.showPowerBar and Scale(settings.powerBarHeight or 4) or 0
    local separatorHeight = (settings.showPowerBar and settings.powerBarBorder ~= false) and 1 or 0
    local healthBar = CreateFrame("StatusBar", nil, frame)
    healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", borderSize, -borderSize)
    healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize + powerHeight + separatorHeight)
    healthBar:SetStatusBarTexture(GetTexturePath(settings.texture))
    healthBar:SetMinMaxValues(0, 100)
    healthBar:SetValue(100)
    healthBar:EnableMouse(false)
    frame.healthBar = healthBar


    local absorbSettings = settings.absorbs or {}
    local absorbBar = CreateFrame("StatusBar", nil, healthBar)
    absorbBar:SetStatusBarTexture(GetAbsorbTexturePath(absorbSettings.texture))
    local absorbBarTex = absorbBar:GetStatusBarTexture()
    if absorbBarTex then
        absorbBarTex:SetHorizTile(false)
        absorbBarTex:SetVertTile(false)
        absorbBarTex:SetTexCoord(0, 1, 0, 1)
    end
    local ac = absorbSettings.color or { 1, 1, 1 }
    local aa = absorbSettings.opacity or 0.7
    absorbBar:SetStatusBarColor(ac[1], ac[2], ac[3], aa)
    absorbBar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
    absorbBar:SetPoint("TOP", healthBar, "TOP", 0, 0)
    absorbBar:SetPoint("BOTTOM", healthBar, "BOTTOM", 0, 0)
    absorbBar:SetMinMaxValues(0, 1)
    absorbBar:SetValue(0)
    absorbBar:Hide()
    frame.absorbBar = absorbBar


    local healAbsorbBar = CreateFrame("StatusBar", nil, healthBar)
    healAbsorbBar:SetStatusBarTexture(GetTexturePath(settings.texture))
    healAbsorbBar:SetFrameLevel(healthBar:GetFrameLevel() + 2)
    healAbsorbBar:SetAllPoints(healthBar)
    healAbsorbBar:SetMinMaxValues(0, 1)
    healAbsorbBar:SetValue(0)
    healAbsorbBar:SetStatusBarColor(0.6, 0.1, 0.1, 0.8)
    healAbsorbBar:SetReverseFill(true)
    frame.healAbsorbBar = healAbsorbBar


    if general and general.darkMode then
        local c = general.darkModeHealthColor or { 0.15, 0.15, 0.15, 1 }
        healthBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
    else
        local r, g, b, a = GetHealthBarColor(unit, settings)
        healthBar:SetStatusBarColor(r, g, b, a)
    end


    if settings.showPowerBar then
        local powerBar = CreateFrame("StatusBar", nil, frame)
        powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", borderSize, borderSize)
        powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize)
        powerBar:SetHeight(powerHeight)
        powerBar:SetStatusBarTexture(GetTexturePath(settings.texture))
        local powerColor = settings.powerBarColor or { 0, 0.5, 1, 1 }
        powerBar:SetStatusBarColor(powerColor[1], powerColor[2], powerColor[3], powerColor[4] or 1)
        powerBar:SetMinMaxValues(0, 100)
        powerBar:SetValue(100)
        powerBar:EnableMouse(false)
        frame.powerBar = powerBar


        if settings.powerBarBorder ~= false then
            local separator = powerBar:CreateTexture(nil, "OVERLAY")
            separator:SetHeight(1)
            separator:SetPoint("BOTTOMLEFT", powerBar, "TOPLEFT", 0, 0)
            separator:SetPoint("BOTTOMRIGHT", powerBar, "TOPRIGHT", 0, 0)
            separator:SetTexture("Interface\\Buttons\\WHITE8x8")
            separator:SetVertexColor(0, 0, 0, 1)
            frame.powerBarSeparator = separator
        end
    end


    if settings.showName then
        local nameAnchorInfo = GetTextAnchorInfo(settings.nameAnchor or "LEFT")
        local nameOffsetX = Scale(settings.nameOffsetX or 4)
        local nameOffsetY = Scale(settings.nameOffsetY or 0)
        local nameText = healthBar:CreateFontString(nil, "OVERLAY")
        nameText:SetFont(GetFontPath(), settings.nameFontSize or 12, GetFontOutline())
        nameText:SetShadowOffset(0, 0)
        nameText:SetPoint(nameAnchorInfo.point, healthBar, nameAnchorInfo.point, nameOffsetX, nameOffsetY)
        nameText:SetJustifyH(nameAnchorInfo.justify)
        nameText:SetText("Boss " .. bossIndex)
        frame.nameText = nameText
    end


    if settings.showHealth then
        local healthAnchorInfo = GetTextAnchorInfo(settings.healthAnchor or "RIGHT")
        local healthOffsetX = Scale(settings.healthOffsetX or -4)
        local healthOffsetY = Scale(settings.healthOffsetY or 0)
        local healthText = healthBar:CreateFontString(nil, "OVERLAY")
        healthText:SetFont(GetFontPath(), settings.healthFontSize or 11, GetFontOutline())
        healthText:SetShadowOffset(0, 0)
        healthText:SetPoint(healthAnchorInfo.point, healthBar, healthAnchorInfo.point, healthOffsetX, healthOffsetY)
        healthText:SetJustifyH(healthAnchorInfo.justify)
        healthText:SetText("100%")
        frame.healthText = healthText
    end


    local powerAnchorInfo = GetTextAnchorInfo(settings.powerTextAnchor or "BOTTOMRIGHT")
    local powerText = healthBar:CreateFontString(nil, "OVERLAY")
    powerText:SetFont(GetFontPath(), settings.powerTextFontSize or 10, GetFontOutline())
    powerText:SetShadowOffset(0, 0)
    local pOffX = Scale(settings.powerTextOffsetX or -4)
    local pOffY = Scale(settings.powerTextOffsetY or 2)
    powerText:SetPoint(powerAnchorInfo.point, healthBar, powerAnchorInfo.point, pOffX, pOffY)
    powerText:SetJustifyH(powerAnchorInfo.justify)
    powerText:Hide()
    frame.powerText = powerText


    if settings.targetMarker then

        local indicatorFrame = CreateFrame("Frame", nil, frame)
        indicatorFrame:SetAllPoints()
        indicatorFrame:SetFrameLevel(healthBar:GetFrameLevel() + 5)
        frame.indicatorFrame = indicatorFrame

        local marker = settings.targetMarker
        local targetMarker = indicatorFrame:CreateTexture(nil, "OVERLAY")
        targetMarker:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
        targetMarker:SetSize(marker.size or 20, marker.size or 20)
        local anchorInfo = GetTextAnchorInfo(marker.anchor or "TOP")
        targetMarker:SetPoint(anchorInfo.point, frame, anchorInfo.point, marker.xOffset or 0, marker.yOffset or 8)
        targetMarker:Hide()
        frame.targetMarker = targetMarker
    end


    frame:SetScript("OnEvent", function(self, event, ...)
        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            local eventUnit = ...
            if eventUnit == self.unit then
                UpdateHealth(self)
                UpdateAbsorbs(self)
            end
        elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
            local eventUnit = ...
            if eventUnit == self.unit then
                UpdateAbsorbs(self)
            end
        elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" then
            local eventUnit = ...
            if eventUnit == self.unit then
                UpdatePower(self)
                UpdatePowerText(self)
            end
        elseif event == "UNIT_NAME_UPDATE" then
            local eventUnit = ...
            if eventUnit == self.unit then
                UpdateName(self)
            end
        elseif event == "RAID_TARGET_UPDATE" then
            UpdateTargetMarker(self)
        end
    end)

    frame:RegisterUnitEvent("UNIT_HEALTH", unit)
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)
    frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unit)
    frame:RegisterUnitEvent("UNIT_POWER_UPDATE", unit)
    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", unit)
    frame:RegisterUnitEvent("UNIT_MAXPOWER", unit)
    frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
    frame:RegisterEvent("RAID_TARGET_UPDATE")


    if _G.ClickCastFrames then
        _G.ClickCastFrames[frame] = true
    end

    return frame
end


local function ForceUpdateToT()
    local totFrame = PREY_UF.frames and PREY_UF.frames.targettarget
    if not totFrame or not UnitExists("targettarget") then return end
    UpdateHealth(totFrame)
    UpdateAbsorbs(totFrame)
    UpdatePower(totFrame)
    UpdatePowerText(totFrame)
    UpdateName(totFrame)
end


local totUpdateTicker = nil
local TOT_UPDATE_INTERVAL = 0.2

local function StartToTTicker()
    if totUpdateTicker then return end
    totUpdateTicker = C_Timer.NewTicker(TOT_UPDATE_INTERVAL, function()
        if UnitExists("targettarget") then
            ForceUpdateToT()
        end
    end)
end

local function StopToTTicker()
    if totUpdateTicker then
        totUpdateTicker:Cancel()
        totUpdateTicker = nil
    end
end


local function CreateUnitFrame(unit, unitKey)
    local settings = GetUnitSettings(unitKey)
    local general = GetGeneralSettings()

    if not settings then return nil end


    local frameName = "PREY_" .. unitKey:gsub("^%l", string.upper)
    local frame = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate, BackdropTemplate, PingableUnitFrameTemplate")

    frame.unit = unit
    frame.unitKey = unitKey


    local width = Scale(settings.width or 220)
    local height = Scale(settings.height or 35)
    frame:SetSize(width, height)


    local offsetX = Scale(settings.offsetX or 0)
    local offsetY = Scale(settings.offsetY or 0)
    frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)


    frame:SetMovable(true)
    frame:SetClampedToScreen(true)


    frame:SetAttribute("unit", unit)
    frame:SetAttribute("*type1", "target")
    frame:SetAttribute("*type2", "togglemenu")
    frame:RegisterForClicks("AnyUp")


    frame:HookScript("OnEnter", function(self)
        ShowUnitTooltip(self)
    end)
    frame:HookScript("OnLeave", HideUnitTooltip)


    if unit == "target" then
        RegisterStateDriver(frame, "visibility", "[@target,exists] show; hide")
    elseif unit == "focus" then
        RegisterStateDriver(frame, "visibility", "[@focus,exists] show; hide")
    elseif unit == "pet" then
        RegisterStateDriver(frame, "visibility", "[@pet,exists] show; hide")
    elseif unit == "targettarget" then

        RegisterStateDriver(frame, "visibility", "[@targettarget,exists] show; hide")

        frame:HookScript("OnShow", StartToTTicker)
        frame:HookScript("OnHide", StopToTTicker)

        if frame:IsShown() then
            StartToTTicker()
        end
    elseif unit:match("^boss%d+$") then

        RegisterStateDriver(frame, "visibility", "[@" .. unit .. ",exists] show; hide")
    end


    local bgColor = { 0.1, 0.1, 0.1, 0.9 }
    if general and general.darkMode then
        bgColor = general.darkModeBgColor or { 0.25, 0.25, 0.25, 1 }
    end


    local borderSize = Scale(settings.borderSize or 1)

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = borderSize > 0 and "Interface\\Buttons\\WHITE8x8" or nil,
        edgeSize = borderSize > 0 and borderSize or nil,
    })
    frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    if borderSize > 0 then
        frame:SetBackdropBorderColor(0, 0, 0, 1)
    end


    local powerHeight = settings.showPowerBar and Scale(settings.powerBarHeight or 4) or 0
    local separatorHeight = (settings.showPowerBar and settings.powerBarBorder ~= false) and 1 or 0
    local healthBar = CreateFrame("StatusBar", nil, frame)
    healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", borderSize, -borderSize)
    healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize + powerHeight + separatorHeight)
    healthBar:SetStatusBarTexture(GetTexturePath(settings.texture))
    healthBar:SetMinMaxValues(0, 100)
    healthBar:SetValue(100)
    healthBar:EnableMouse(false)
    frame.healthBar = healthBar


    local absorbSettings = settings.absorbs or {}
    local absorbBar = CreateFrame("StatusBar", nil, healthBar)
    absorbBar:SetStatusBarTexture(GetAbsorbTexturePath(absorbSettings.texture))
    local absorbBarTex = absorbBar:GetStatusBarTexture()
    if absorbBarTex then
        absorbBarTex:SetHorizTile(false)
        absorbBarTex:SetVertTile(false)
        absorbBarTex:SetTexCoord(0, 1, 0, 1)
    end
    local ac = absorbSettings.color or { 1, 1, 1 }
    local aa = absorbSettings.opacity or 0.7
    absorbBar:SetStatusBarColor(ac[1], ac[2], ac[3], aa)
    absorbBar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
    absorbBar:SetPoint("TOP", healthBar, "TOP", 0, 0)
    absorbBar:SetPoint("BOTTOM", healthBar, "BOTTOM", 0, 0)
    absorbBar:SetMinMaxValues(0, 1)
    absorbBar:SetValue(0)
    absorbBar:Hide()
    frame.absorbBar = absorbBar


    local healAbsorbBar = CreateFrame("StatusBar", nil, healthBar)
    healAbsorbBar:SetStatusBarTexture(GetTexturePath(settings.texture))
    healAbsorbBar:SetFrameLevel(healthBar:GetFrameLevel() + 2)
    healAbsorbBar:SetAllPoints(healthBar)
    healAbsorbBar:SetMinMaxValues(0, 1)
    healAbsorbBar:SetValue(0)
    healAbsorbBar:SetStatusBarColor(0.6, 0.1, 0.1, 0.8)
    healAbsorbBar:SetReverseFill(true)
    frame.healAbsorbBar = healAbsorbBar


    if general and general.darkMode then
        local c = general.darkModeHealthColor or { 0.15, 0.15, 0.15, 1 }
        healthBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
    else
        local r, g, b, a = GetHealthBarColor(unit, settings)
        healthBar:SetStatusBarColor(r, g, b, a)
    end


    if settings.showPowerBar then
        local powerBar = CreateFrame("StatusBar", nil, frame)
        powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", borderSize, borderSize)
        powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize)
        powerBar:SetHeight(powerHeight)
        powerBar:SetStatusBarTexture(GetTexturePath(settings.texture))
        powerBar:SetMinMaxValues(0, 100)
        powerBar:SetValue(100)

        local powerColor = settings.powerBarColor or { 0, 0.5, 1, 1 }
        powerBar:SetStatusBarColor(powerColor[1], powerColor[2], powerColor[3], powerColor[4] or 1)
        powerBar:EnableMouse(false)
        frame.powerBar = powerBar


        if settings.powerBarBorder ~= false then
            local separator = powerBar:CreateTexture(nil, "OVERLAY")
            separator:SetHeight(1)
            separator:SetPoint("BOTTOMLEFT", powerBar, "TOPLEFT", 0, 0)
            separator:SetPoint("BOTTOMRIGHT", powerBar, "TOPRIGHT", 0, 0)
            separator:SetTexture("Interface\\Buttons\\WHITE8x8")
            separator:SetVertexColor(0, 0, 0, 1)
            frame.powerBarSeparator = separator
        end
    end


    if settings.showPortrait then
        local portrait = CreateFrame("Button", nil, frame, "SecureUnitButtonTemplate, BackdropTemplate")
        local portraitSize = Scale(settings.portraitSize or 40)
        local portraitBorderSize = Scale(settings.portraitBorderSize or 1)
        portrait:SetSize(portraitSize, portraitSize)

        local portraitGap = Scale(settings.portraitGap or 0)
        local portraitOffsetX = Scale(settings.portraitOffsetX or 0)
        local portraitOffsetY = Scale(settings.portraitOffsetY or 0)
        local side = settings.portraitSide or "LEFT"
        if side == "LEFT" then
            portrait:SetPoint("RIGHT", frame, "LEFT", -portraitGap + portraitOffsetX, portraitOffsetY)
        else
            portrait:SetPoint("LEFT", frame, "RIGHT", portraitGap + portraitOffsetX, portraitOffsetY)
        end


        portrait:SetAttribute("unit", unit)
        portrait:SetAttribute("*type1", "target")
        portrait:SetAttribute("*type2", "togglemenu")
        portrait:RegisterForClicks("AnyUp")


        portrait:HookScript("OnEnter", function(self)
            ShowUnitTooltip(frame)
        end)
        portrait:HookScript("OnLeave", HideUnitTooltip)


        portrait:SetBackdrop({
            bgFile = nil,
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = portraitBorderSize,
        })


        local borderR, borderG, borderB = 0, 0, 0
        if settings.portraitBorderUseClassColor then
            local _, class = UnitClass(unit)
            if class then
                local classColor = RAID_CLASS_COLORS[class]
                if classColor then
                    borderR, borderG, borderB = classColor.r, classColor.g, classColor.b
                end
            end
        elseif settings.portraitBorderColor then
            borderR = settings.portraitBorderColor[1] or 0
            borderG = settings.portraitBorderColor[2] or 0
            borderB = settings.portraitBorderColor[3] or 0
        end
        portrait:SetBackdropBorderColor(borderR, borderG, borderB, 1)

        local portraitTex = portrait:CreateTexture(nil, "ARTWORK")
        portraitTex:SetPoint("TOPLEFT", portraitBorderSize, -portraitBorderSize)
        portraitTex:SetPoint("BOTTOMRIGHT", -portraitBorderSize, portraitBorderSize)
        frame.portraitTexture = portraitTex
        frame.portrait = portrait

        SetPortraitTexture(portraitTex, unit, true)
        portraitTex:SetTexCoord(0.15, 0.85, 0.15, 0.85)
    end


    local textFrame = CreateFrame("Frame", nil, frame)
    textFrame:SetAllPoints()
    textFrame:SetFrameLevel(healthBar:GetFrameLevel() + 2)


    local fontPath = GetFontPath()
    local fontOutline = general and general.fontOutline or "OUTLINE"
    local nameFontSize = settings.nameFontSize or 12
    local nameAnchorInfo = GetTextAnchorInfo(settings.nameAnchor or "LEFT")
    local nameOffsetX = settings.nameOffsetX or 4
    local nameOffsetY = settings.nameOffsetY or 0

    local nameText = textFrame:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(fontPath, nameFontSize, fontOutline)
    nameText:SetPoint(nameAnchorInfo.point, frame, nameAnchorInfo.point, nameOffsetX, nameOffsetY)
    nameText:SetJustifyH(nameAnchorInfo.justify)
    nameText:SetTextColor(1, 1, 1, 1)
    frame.nameText = nameText


    local healthFontSize = settings.healthFontSize or 12
    local healthAnchorInfo = GetTextAnchorInfo(settings.healthAnchor or "RIGHT")
    local healthOffsetX = settings.healthOffsetX or -4
    local healthOffsetY = settings.healthOffsetY or 0

    local healthText = textFrame:CreateFontString(nil, "OVERLAY")
    healthText:SetFont(fontPath, healthFontSize, fontOutline)
    healthText:SetPoint(healthAnchorInfo.point, frame, healthAnchorInfo.point, healthOffsetX, healthOffsetY)
    healthText:SetJustifyH(healthAnchorInfo.justify)
    healthText:SetTextColor(1, 1, 1, 1)
    frame.healthText = healthText


    local powerTextFontSize = settings.powerTextFontSize or 12
    local powerAnchorInfo = GetTextAnchorInfo(settings.powerTextAnchor or "BOTTOMRIGHT")
    local powerTextOffsetX = settings.powerTextOffsetX or -4
    local powerTextOffsetY = settings.powerTextOffsetY or 2

    local powerText = textFrame:CreateFontString(nil, "OVERLAY")
    powerText:SetFont(fontPath, powerTextFontSize, fontOutline)
    powerText:SetPoint(powerAnchorInfo.point, frame, powerAnchorInfo.point, powerTextOffsetX, powerTextOffsetY)
    powerText:SetJustifyH(powerAnchorInfo.justify)
    powerText:SetTextColor(1, 1, 1, 1)
    powerText:Hide()
    frame.powerText = powerText


    if unitKey == "player" then
        local indSettings = settings.indicators


        local indicatorFrame = CreateFrame("Frame", nil, frame)
        indicatorFrame:SetAllPoints()
        indicatorFrame:SetFrameLevel(textFrame:GetFrameLevel() + 5)
        frame.indicatorFrame = indicatorFrame


        if indSettings and indSettings.rested then
            local rested = indSettings.rested
            local restedIndicator = indicatorFrame:CreateTexture(nil, "OVERLAY")
            restedIndicator:SetSize(rested.size or 16, rested.size or 16)
            local anchorInfo = GetTextAnchorInfo(rested.anchor or "TOPLEFT")
            restedIndicator:SetPoint(anchorInfo.point, frame, anchorInfo.point, rested.offsetX or -2, rested.offsetY or 2)
            restedIndicator:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
            restedIndicator:SetTexCoord(0.0625, 0.4375, 0.0625, 0.4375)
            restedIndicator:Hide()
            frame.restedIndicator = restedIndicator
        end


        if indSettings and indSettings.combat then
            local combat = indSettings.combat
            local combatIndicator = indicatorFrame:CreateTexture(nil, "OVERLAY")
            combatIndicator:SetSize(combat.size or 16, combat.size or 16)
            local anchorInfo = GetTextAnchorInfo(combat.anchor or "TOPLEFT")
            combatIndicator:SetPoint(anchorInfo.point, frame, anchorInfo.point, combat.offsetX or -2, combat.offsetY or 2)
            combatIndicator:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
            combatIndicator:SetTexCoord(0.5625, 0.9375, 0.0625, 0.4375)
            combatIndicator:Hide()
            frame.combatIndicator = combatIndicator
        end


        local general = GetGeneralSettings()
        local fontOutline = general and general.fontOutline or "OUTLINE"

        local stanceText = indicatorFrame:CreateFontString(nil, "OVERLAY")
        stanceText:SetFont(fontPath, 12, fontOutline)
        stanceText:SetPoint("BOTTOM", frame, "BOTTOM", 0, -2)
        stanceText:SetJustifyH("CENTER")
        stanceText:SetTextColor(1, 1, 1, 1)
        stanceText:Hide()
        frame.stanceText = stanceText

        local stanceIcon = indicatorFrame:CreateTexture(nil, "OVERLAY")
        stanceIcon:SetSize(14, 14)
        stanceIcon:SetPoint("RIGHT", stanceText, "LEFT", -2, 0)
        stanceIcon:Hide()
        frame.stanceIcon = stanceIcon
    end


    if settings.targetMarker then

        if not frame.indicatorFrame then
            local indicatorFrame = CreateFrame("Frame", nil, frame)
            indicatorFrame:SetAllPoints()
            indicatorFrame:SetFrameLevel(textFrame:GetFrameLevel() + 5)
            frame.indicatorFrame = indicatorFrame
        end

        local marker = settings.targetMarker
        local targetMarker = frame.indicatorFrame:CreateTexture(nil, "OVERLAY")
        targetMarker:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
        targetMarker:SetSize(marker.size or 20, marker.size or 20)
        local anchorInfo = GetTextAnchorInfo(marker.anchor or "TOP")
        targetMarker:SetPoint(anchorInfo.point, frame, anchorInfo.point, marker.xOffset or 0, marker.yOffset or 8)
        targetMarker:Hide()
        frame.targetMarker = targetMarker
    end


    if settings.leaderIcon and settings.leaderIcon.enabled and (unitKey == "player" or unitKey == "target" or unitKey == "focus") then

        if not frame.indicatorFrame then
            local indicatorFrame = CreateFrame("Frame", nil, frame)
            indicatorFrame:SetAllPoints()
            indicatorFrame:SetFrameLevel(textFrame:GetFrameLevel() + 5)
            frame.indicatorFrame = indicatorFrame
        end

        local leader = settings.leaderIcon
        local leaderIcon = frame.indicatorFrame:CreateTexture(nil, "OVERLAY")
        leaderIcon:SetSize(leader.size or 16, leader.size or 16)
        local anchorInfo = GetTextAnchorInfo(leader.anchor or "TOPLEFT")
        leaderIcon:SetPoint(anchorInfo.point, frame, anchorInfo.point, leader.xOffset or -8, leader.yOffset or 8)
        leaderIcon:Hide()
        frame.leaderIcon = leaderIcon
    end


    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
    frame:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_POWER_FREQUENT")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UNIT_NAME_UPDATE")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    frame:RegisterEvent("UNIT_PET")
    frame:RegisterEvent("UNIT_TARGET")
    frame:RegisterEvent("RAID_TARGET_UPDATE")


    if settings.leaderIcon and settings.leaderIcon.enabled and (unitKey == "player" or unitKey == "target" or unitKey == "focus") then
        frame:RegisterEvent("PARTY_LEADER_CHANGED")
        frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    end


    if unitKey == "player" then
        frame:RegisterEvent("PLAYER_UPDATE_RESTING")
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    end

    frame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_ENTERING_WORLD" then
            UpdateFrame(self)
        elseif event == "PLAYER_TARGET_CHANGED" then
            if self.unitKey == "target" then

                if UnitExists(self.unit) then
                    UpdateFrame(self)
                end
            elseif self.unitKey == "targettarget" then


                if UnitExists(self.unit) then
                    UpdateFrame(self)
                else

                    if self.nameText then self.nameText:SetText("") end
                    if self.healthText then self.healthText:SetText("") end
                    if self.powerText then self.powerText:Hide() end
                    if self.healthBar then
                        self.healthBar:SetValue(0)
                    end
                end
            end
        elseif event == "UNIT_TARGET" then
            if arg1 == "target" then

                if self.unitKey == "target" then
                    UpdateName(self)

                elseif self.unitKey == "targettarget" then
                    if UnitExists(self.unit) then
                        UpdateFrame(self)
                    else

                        if self.nameText then self.nameText:SetText("") end
                        if self.healthText then self.healthText:SetText("") end
                        if self.powerText then self.powerText:Hide() end
                        if self.healthBar then self.healthBar:SetValue(0) end
                    end
                end
            end
        elseif event == "PLAYER_FOCUS_CHANGED" then
            if self.unitKey == "focus" then

                if UnitExists(self.unit) then
                    UpdateFrame(self)
                end
            end
        elseif event == "UNIT_PET" then
            if self.unitKey == "pet" then

                if UnitExists(self.unit) then
                    UpdateFrame(self)
                end
            end
        elseif event == "PLAYER_UPDATE_RESTING"
               or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then

            if self.unitKey == "player" then
                UpdateIndicators(self)
            end
        elseif event == "UPDATE_SHAPESHIFT_FORM" then

            if self.unitKey == "player" then
                UpdateStance(self)
            end
        elseif event == "RAID_TARGET_UPDATE" then

            UpdateTargetMarker(self)
        elseif event == "PARTY_LEADER_CHANGED" or event == "GROUP_ROSTER_UPDATE" then

            UpdateLeaderIcon(self)
        elseif arg1 == self.unit then
            if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
                UpdateHealth(self)
                UpdateAbsorbs(self)

                if self.unitKey == "target" then
                    ForceUpdateToT()
                end
            elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
                UpdateAbsorbs(self)
                if self.unitKey == "target" then
                    ForceUpdateToT()
                end
            elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" then
                UpdatePower(self)
                UpdatePowerText(self)
                if self.unitKey == "target" then
                    ForceUpdateToT()
                end
            elseif event == "UNIT_NAME_UPDATE" then
                UpdateName(self)
            end
        end
    end)


    if UnitExists(unit) or unitKey == "player" then
        UpdateFrame(frame)
    end


    if unitKey == "player" then
        frame:Show()
    end


    if _G.ClickCastFrames then
        _G.ClickCastFrames[frame] = true
    end

    return frame
end


local function CreateCastbar(unitFrame, unit, unitKey)

    if PREY_Castbar then
        return PREY_Castbar:CreateCastbar(unitFrame, unit, unitKey)
    end
    return nil
end


local function CreateBossCastbar(unitFrame, unit, bossIndex)

    if PREY_Castbar then
        return PREY_Castbar:CreateBossCastbar(unitFrame, unit, bossIndex)
    end
    return nil
end


local AURA_THROTTLE = 0.15
local lastAuraUpdate = {}


local function ApplyAuraIconSettings(icon, auraSettings, isDebuff)
    if not icon then return end
    auraSettings = auraSettings or {}

    local fontPath = GetFontPath()
    local fontOutline = GetFontOutline()


    local prefix = isDebuff and "debuff" or "buff"


    local showStack = auraSettings[prefix .. "ShowStack"]
    if showStack == nil then showStack = auraSettings.showStack end
    if showStack == nil then showStack = true end

    local stackSize = auraSettings[prefix .. "StackSize"] or auraSettings.stackSize or 10
    local stackAnchor = auraSettings[prefix .. "StackAnchor"] or auraSettings.stackAnchor or "BOTTOMRIGHT"
    local stackOffsetX = auraSettings[prefix .. "StackOffsetX"] or auraSettings.stackOffsetX or -1
    local stackOffsetY = auraSettings[prefix .. "StackOffsetY"] or auraSettings.stackOffsetY or 1
    local stackColor = auraSettings[prefix .. "StackColor"] or auraSettings.stackColor or {1, 1, 1, 1}

    if icon.count then
        icon.count:SetFont(fontPath, stackSize, fontOutline)
        icon.count:ClearAllPoints()
        icon.count:SetPoint(stackAnchor, icon, stackAnchor, stackOffsetX, stackOffsetY)
        icon.count:SetTextColor(stackColor[1] or 1, stackColor[2] or 1, stackColor[3] or 1, stackColor[4] or 1)
    end
    icon._showStack = showStack


    local hideSwipe = auraSettings[prefix .. "HideSwipe"]
    if hideSwipe == nil then hideSwipe = false end
    if icon.cooldown then
        icon.cooldown:SetDrawSwipe(not hideSwipe)
    end


    local showDuration = auraSettings[prefix .. "ShowDuration"]
    if showDuration == nil then showDuration = true end

    local durationSize = auraSettings[prefix .. "DurationSize"] or 12
    local durationAnchor = auraSettings[prefix .. "DurationAnchor"] or "CENTER"
    local durationOffsetX = auraSettings[prefix .. "DurationOffsetX"] or 0
    local durationOffsetY = auraSettings[prefix .. "DurationOffsetY"] or 0
    local durationColor = auraSettings[prefix .. "DurationColor"] or {1, 1, 1, 1}


    if icon.cooldown then
        pcall(function()

            if icon.cooldown.SetHideCountdownNumbers then
                icon.cooldown:SetHideCountdownNumbers(not showDuration)
            end


            if showDuration and icon.cooldown.GetRegions then
                for _, region in ipairs({ icon.cooldown:GetRegions() }) do
                    if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                        if region.SetFont then
                            region:SetFont(fontPath, durationSize, fontOutline)
                        end
                        if region.ClearAllPoints and region.SetPoint then
                            region:ClearAllPoints()
                            region:SetPoint(durationAnchor, icon, durationAnchor, durationOffsetX, durationOffsetY)
                        end
                        if region.SetTextColor then
                            region:SetTextColor(durationColor[1] or 1, durationColor[2] or 1, durationColor[3] or 1, durationColor[4] or 1)
                        end
                        break
                    end
                end
            end
        end)
    end
end

local function CreateAuraIcon(parent, index, size, auraSettings, isDebuff)


    local icon = CreateFrame("Frame", nil, parent)


    icon:SetFrameLevel(parent:GetFrameLevel() + 10)
    icon:SetSize(size, size)


    icon:EnableMouse(true)


    icon.unit = nil
    icon.auraInstanceID = nil
    icon.filter = nil


    icon:SetScript("OnEnter", function(self)
        if self.unit and self.auraInstanceID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if self.filter == "HELPFUL" then
                GameTooltip:SetUnitBuffByAuraInstanceID(self.unit, self.auraInstanceID)
            else
                GameTooltip:SetUnitDebuffByAuraInstanceID(self.unit, self.auraInstanceID)
            end
            GameTooltip:Show()
        end
    end)

    icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)


    local border = icon:CreateTexture(nil, "BACKGROUND", nil, -8)
    border:SetColorTexture(0, 0, 0, 1)
    border:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    icon.border = border


    local tex = icon:CreateTexture(nil, "ARTWORK")
    tex:SetPoint("TOPLEFT", 0, 0)
    tex:SetPoint("BOTTOMRIGHT", 0, 0)
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon.icon = tex


    local cd = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    cd:SetAllPoints(icon)
    cd:SetDrawEdge(false)
    cd:SetReverse(true)
    cd:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
    cd:SetSwipeColor(0, 0, 0, 0.8)
    cd.noOCC = true

    icon.cooldown = cd


    local count = icon:CreateFontString(nil, "OVERLAY")
    count:SetPoint("BOTTOMRIGHT", -1, 1)
    count:SetTextColor(1, 1, 1, 1)
    icon.count = count
    icon._showStack = true


    ApplyAuraIconSettings(icon, auraSettings, isDebuff)

    icon:Hide()
    return icon
end

local function GetAuraIcon(container, index, parent, size, auraSettings, isDebuff)
    if container[index] then
        container[index]:SetSize(size, size)

        ApplyAuraIconSettings(container[index], auraSettings, isDebuff)
        return container[index]
    end

    local icon = CreateAuraIcon(parent, index, size, auraSettings, isDebuff)
    container[index] = icon
    return icon
end

local function UpdateAuras(frame)
    if not frame or not frame.unit then return end
    local unit = frame.unit

    if not UnitExists(unit) then

        if frame.buffIcons then
            for _, icon in ipairs(frame.buffIcons) do
                icon:Hide()
            end
        end
        if frame.debuffIcons then
            for _, icon in ipairs(frame.debuffIcons) do
                icon:Hide()
            end
        end
        return
    end


    local now = GetTime()
    local lastUpdate = lastAuraUpdate[unit] or 0
    if (now - lastUpdate) < AURA_THROTTLE then
        return
    end
    lastAuraUpdate[unit] = now


    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then
        return
    end


    local settings = GetUnitSettings(frame.unitKey)
    local auraSettings = settings and settings.auras or {}

    local iconSize = auraSettings.iconSize or 22
    local buffIconSize = auraSettings.buffIconSize or 22
    local showBuffs = auraSettings.showBuffs ~= false
    local showDebuffs = auraSettings.showDebuffs ~= false
    local onlyMyDebuffs = auraSettings.onlyMyDebuffs ~= false


    local unitKey = frame.unitKey
    local buffPreviewActive = PREY_UF.auraPreviewMode[unitKey .. "_buff"]
    local debuffPreviewActive = PREY_UF.auraPreviewMode[unitKey .. "_debuff"]


    local debuffAnchor = auraSettings.debuffAnchor or "TOPLEFT"
    local debuffGrow = auraSettings.debuffGrow or "RIGHT"
    local debuffMaxIcons = auraSettings.debuffMaxIcons or 16
    local debuffOffsetX = auraSettings.debuffOffsetX or 0
    local debuffOffsetY = auraSettings.debuffOffsetY or 2
    local debuffSpacing = auraSettings.debuffSpacing or auraSettings.iconSpacing or 2


    local buffAnchor = auraSettings.buffAnchor or "BOTTOMLEFT"
    local buffGrow = auraSettings.buffGrow or "RIGHT"
    local buffMaxIcons = auraSettings.buffMaxIcons or 16
    local buffOffsetX = auraSettings.buffOffsetX or 0
    local buffOffsetY = auraSettings.buffOffsetY or -2
    local buffSpacing = auraSettings.buffSpacing or auraSettings.iconSpacing or 2


    frame.buffIcons = frame.buffIcons or {}
    frame.debuffIcons = frame.debuffIcons or {}


    if not buffPreviewActive then
        for _, icon in ipairs(frame.buffIcons) do
            icon:Hide()
        end
    end
    if not debuffPreviewActive then
        for _, icon in ipairs(frame.debuffIcons) do
            icon:Hide()
        end
    end


    local function SafeSetCooldown(cooldownFrame, auraData, unit)
        if not cooldownFrame then return false end
        if not auraData then return false end

        local applied = false


        local auraInstanceID
        pcall(function() auraInstanceID = auraData.auraInstanceID end)


        if cooldownFrame.SetCooldownFromDurationObject and auraInstanceID then
            local durationObj
            if C_UnitAuras and C_UnitAuras.GetAuraDuration then
                local ok, obj = pcall(C_UnitAuras.GetAuraDuration, unit, auraInstanceID)
                if ok and obj then
                    durationObj = obj
                end
            end

            if durationObj then
                local setOk = pcall(cooldownFrame.SetCooldownFromDurationObject, cooldownFrame, durationObj, true)
                if setOk then
                    applied = true
                else

                    local eOK, elapsed = pcall(durationObj.GetElapsedDuration, durationObj)
                    local rOK, remaining = pcall(durationObj.GetRemainingDuration, durationObj)
                    if eOK and rOK and elapsed and remaining then
                        local startTime = GetTime() - elapsed
                        local total = elapsed + remaining
                        local numOk = pcall(cooldownFrame.SetCooldown, cooldownFrame, startTime, total)
                        if numOk then
                            applied = true
                        end
                    end
                end
            end
        end


        if not applied then

            local duration, expirationTime
            pcall(function()
                duration = auraData.duration
                expirationTime = auraData.expirationTime
            end)
            if duration and expirationTime then
                local ok = pcall(function()
                    local startTime = expirationTime - duration
                    cooldownFrame:SetCooldown(startTime, duration)
                end)
                if ok then
                    applied = true
                end
            end
        end

        return applied
    end


    local function DisplayStackCount(countText, unit, auraInstanceID)
        if not auraInstanceID or not C_UnitAuras.GetAuraApplicationDisplayCount then
            countText:SetText("")
            return
        end


        local ok, stackText = pcall(C_UnitAuras.GetAuraApplicationDisplayCount, unit, auraInstanceID, 2, 99)
        if ok then
            countText:SetText(stackText)
        else
            countText:SetText("")
        end
    end


    local debuffCount = 0
    local debuffIndex = 1

    local debuffFilter = "HARMFUL"
    if unit ~= "player" and onlyMyDebuffs then
        debuffFilter = "HARMFUL|PLAYER"
    end
    if showDebuffs and not debuffPreviewActive then
        while debuffCount < debuffMaxIcons do

            local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, debuffIndex, debuffFilter)
            if not ok or not auraData then break end


            local auraInstanceID, auraIcon
            pcall(function()
                auraInstanceID = auraData.auraInstanceID
                auraIcon = auraData.icon
            end)


            if not auraInstanceID then
                debuffIndex = debuffIndex + 1

            else
                debuffCount = debuffCount + 1

                local icon = GetAuraIcon(frame.debuffIcons, debuffCount, frame, iconSize, auraSettings, true)


                icon.unit = unit
                icon.auraInstanceID = auraInstanceID
                icon.filter = debuffFilter


                if auraIcon then
                    pcall(icon.icon.SetTexture, icon.icon, auraIcon)
                end


                if icon.border then
                    icon.border:SetColorTexture(0.8, 0.2, 0.2, 1)
                end


                if SafeSetCooldown(icon.cooldown, auraData, unit) then
                    icon.cooldown:Show()
                else
                    icon.cooldown:Hide()
                end


                if icon._showStack then
                    DisplayStackCount(icon.count, unit, auraInstanceID)
                    icon.count:Show()
                else
                    icon.count:Hide()
                end


                local idx = debuffCount - 1
                local xPos, yPos = debuffOffsetX, debuffOffsetY
                if debuffGrow == "RIGHT" then
                xPos = xPos + idx * (iconSize + debuffSpacing)
            elseif debuffGrow == "LEFT" then
                xPos = xPos - idx * (iconSize + debuffSpacing)
            elseif debuffGrow == "UP" then
                yPos = yPos + idx * (iconSize + debuffSpacing)
            elseif debuffGrow == "DOWN" then
                yPos = yPos - idx * (iconSize + debuffSpacing)
            end


            local iconPoint, framePoint, borderOffsetX
            if debuffAnchor == "TOPLEFT" then
                iconPoint, framePoint, borderOffsetX = "BOTTOMLEFT", "TOPLEFT", 1
            elseif debuffAnchor == "TOPRIGHT" then
                iconPoint, framePoint, borderOffsetX = "BOTTOMRIGHT", "TOPRIGHT", -1
            elseif debuffAnchor == "BOTTOMLEFT" then
                iconPoint, framePoint, borderOffsetX = "TOPLEFT", "BOTTOMLEFT", 1
            elseif debuffAnchor == "BOTTOMRIGHT" then
                iconPoint, framePoint, borderOffsetX = "TOPRIGHT", "BOTTOMRIGHT", -1
            end

                icon:ClearAllPoints()
                icon:SetPoint(iconPoint, frame, framePoint, xPos + (borderOffsetX or 0), yPos)
                icon:Show()
            end

            debuffIndex = debuffIndex + 1
        end
    end


    local buffCount = 0
    local buffIndex = 1
    if showBuffs and not buffPreviewActive then
        while buffCount < buffMaxIcons do

            local ok, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unit, buffIndex, "HELPFUL")
            if not ok or not auraData then break end


            local auraInstanceID, auraIcon
            pcall(function()
                auraInstanceID = auraData.auraInstanceID
                auraIcon = auraData.icon
            end)


            if not auraInstanceID then
                buffIndex = buffIndex + 1

            else
                buffCount = buffCount + 1

                local icon = GetAuraIcon(frame.buffIcons, buffCount, frame, buffIconSize, auraSettings, false)


                icon.unit = unit
                icon.auraInstanceID = auraInstanceID
                icon.filter = "HELPFUL"


                if auraIcon then
                    pcall(icon.icon.SetTexture, icon.icon, auraIcon)
                end


                if icon.border then
                    icon.border:SetColorTexture(0, 0, 0, 1)
                end


                if SafeSetCooldown(icon.cooldown, auraData, unit) then
                    icon.cooldown:Show()
                else
                    icon.cooldown:Hide()
                end


                if icon._showStack then
                    DisplayStackCount(icon.count, unit, auraInstanceID)
                    icon.count:Show()
                else
                    icon.count:Hide()
                end


                local idx = buffCount - 1
                local xPos, yPos = buffOffsetX, buffOffsetY
                if buffGrow == "RIGHT" then
                xPos = xPos + idx * (buffIconSize + buffSpacing)
            elseif buffGrow == "LEFT" then
                xPos = xPos - idx * (buffIconSize + buffSpacing)
            elseif buffGrow == "UP" then
                yPos = yPos + idx * (buffIconSize + buffSpacing)
            elseif buffGrow == "DOWN" then
                yPos = yPos - idx * (buffIconSize + buffSpacing)
            end


            local iconPoint, framePoint, borderOffsetX
            if buffAnchor == "TOPLEFT" then
                iconPoint, framePoint, borderOffsetX = "BOTTOMLEFT", "TOPLEFT", 1
            elseif buffAnchor == "TOPRIGHT" then
                iconPoint, framePoint, borderOffsetX = "BOTTOMRIGHT", "TOPRIGHT", -1
            elseif buffAnchor == "BOTTOMLEFT" then
                iconPoint, framePoint, borderOffsetX = "TOPLEFT", "BOTTOMLEFT", 1
            elseif buffAnchor == "BOTTOMRIGHT" then
                iconPoint, framePoint, borderOffsetX = "TOPRIGHT", "BOTTOMRIGHT", -1
            end

                icon:ClearAllPoints()
                icon:SetPoint(iconPoint, frame, framePoint, xPos + (borderOffsetX or 0), yPos)
                icon:Show()
            end

            buffIndex = buffIndex + 1
        end
    end
end


local function SetupAuraTracking(frame)
    if not frame then return end

    local unit = frame.unit


    frame:RegisterEvent("UNIT_AURA")
    if unit == "target" then
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    elseif unit == "focus" then
        frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    elseif unit == "pet" then
        frame:RegisterEvent("UNIT_PET")
    elseif unit == "targettarget" then
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        frame:RegisterEvent("UNIT_TARGET")
    elseif unit:match("^boss%d+$") then
        frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    end


    local oldOnEvent = frame:GetScript("OnEvent")
    frame:SetScript("OnEvent", function(self, event, arg1, ...)
        if oldOnEvent then
            oldOnEvent(self, event, arg1, ...)
        end

        if event == "UNIT_AURA" and arg1 == self.unit then

            lastAuraUpdate[self.unit] = 0
            UpdateAuras(self)
        elseif event == "PLAYER_TARGET_CHANGED" then

            if self.unit == "target" or self.unit == "targettarget" then
                lastAuraUpdate[self.unit] = 0
                UpdateAuras(self)
            end
        elseif event == "PLAYER_FOCUS_CHANGED" and self.unit == "focus" then

            lastAuraUpdate["focus"] = 0
            UpdateAuras(self)
        elseif event == "UNIT_PET" and self.unit == "pet" then

            lastAuraUpdate["pet"] = 0
            UpdateAuras(self)
        elseif event == "UNIT_TARGET" and self.unit == "targettarget" then

            lastAuraUpdate["targettarget"] = 0
            UpdateAuras(self)
        elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" and self.unit:match("^boss%d+$") then

            lastAuraUpdate[self.unit] = 0
            UpdateFrame(self)
            UpdateAuras(self)
        end
    end)


    C_Timer.After(0.1, function()
        lastAuraUpdate[unit] = 0
        UpdateAuras(frame)
    end)
    C_Timer.After(0.5, function()
        lastAuraUpdate[unit] = 0
        UpdateAuras(frame)
    end)
    C_Timer.After(1.0, function()
        lastAuraUpdate[unit] = 0
        UpdateAuras(frame)
    end)
end


function PREY_UF:ShowPreview(unitKey)

    if unitKey == "boss" then
        local general = GetGeneralSettings()
        local settings = GetUnitSettings("boss")
        local spacing = settings and settings.spacing or 40


        self:RefreshFrame("boss")

        for i = 1, 5 do
            local bossKey = "boss" .. i
            local frame = self.frames[bossKey]
            if frame then
                self.previewMode[bossKey] = true
                if not InCombatLockdown() then
                    UnregisterStateDriver(frame, "visibility")
                end
                frame:Show()
                frame.healthBar:SetMinMaxValues(0, 100)
                frame.healthBar:SetValue(75 - (i * 5))
                if frame.nameText then
                    frame.nameText:SetText("Boss " .. i)
                end
                if frame.healthText then
                    frame.healthText:SetText("75.0K - " .. (75 - (i * 5)) .. "%")
                end
                if frame.powerBar and settings and settings.showPowerBar then
                    frame.powerBar:SetMinMaxValues(0, 100)
                    frame.powerBar:SetValue(60)
                    frame.powerBar:Show()
                end


                if frame.powerText then
                    if settings and settings.showPowerText then
                        frame.powerText:SetText("60%")
                        if settings.powerTextUsePowerColor then
                            frame.powerText:SetTextColor(0, 0.6, 1, 1)
                        elseif settings.powerTextUseClassColor then
                            frame.powerText:SetTextColor(0.96, 0.55, 0.73, 1)
                        elseif settings.powerTextColor then
                            local c = settings.powerTextColor
                            frame.powerText:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, 1)
                        else
                            frame.powerText:SetTextColor(1, 1, 1, 1)
                        end
                        frame.powerText:Show()
                    else
                        frame.powerText:Hide()
                    end
                end


                if general and general.darkMode then
                    local c = general.darkModeHealthColor or { 0.15, 0.15, 0.15, 1 }
                    frame.healthBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
                else

                    if general and general.defaultUseClassColor then
                        local _, class = UnitClass("player")
                        if class and RAID_CLASS_COLORS[class] then
                            local color = RAID_CLASS_COLORS[class]
                            frame.healthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
                        else
                            local c = general.defaultHealthColor or { 0.2, 0.2, 0.2, 1 }
                            frame.healthBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
                        end
                    else
                        local c = general and general.defaultHealthColor or { 0.2, 0.2, 0.2, 1 }
                        frame.healthBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
                    end
                end


                if settings and settings.castbar and settings.castbar.previewMode then
                    local castbar = self.castbars[bossKey]
                    if castbar and PREY_Castbar then

                        PREY_Castbar:RefreshBossCastbar(castbar, bossKey, settings.castbar, frame)
                    end
                end


                if self.auraPreviewMode["boss_buff"] then
                    self:ShowAuraPreviewForFrame(frame, "boss", "buff")
                end
                if self.auraPreviewMode["boss_debuff"] then
                    self:ShowAuraPreviewForFrame(frame, "boss", "debuff")
                end
            end
        end
        return
    end

    local frame = self.frames[unitKey]
    if not frame then return end

    self.previewMode[unitKey] = true


    if not InCombatLockdown() then
        UnregisterStateDriver(frame, "visibility")
    end


    frame:Show()


    frame.healthBar:SetMinMaxValues(0, 100)
    frame.healthBar:SetValue(75)


    if frame.nameText then
        local names = {
            player = UnitName("player") or "Player",
            target = "Target Dummy",
            targettarget = "ToT Name",
            pet = "Pet Name",
            focus = "Focus Target",
        }
        frame.nameText:SetText(names[unitKey] or "Preview")
    end


    if frame.healthText then
        frame.healthText:SetText("75.0K - 75%")
    end


    if frame.powerBar then
        frame.powerBar:SetMinMaxValues(0, 100)
        frame.powerBar:SetValue(60)
        frame.powerBar:Show()
    end


    local settings = GetUnitSettings(unitKey)
    if frame.powerText then
        if settings and settings.showPowerText then
            frame.powerText:SetText("60%")
            if settings.powerTextUsePowerColor then
                frame.powerText:SetTextColor(0, 0.6, 1, 1)
            elseif settings.powerTextUseClassColor then
                frame.powerText:SetTextColor(0.96, 0.55, 0.73, 1)
            elseif settings.powerTextColor then
                local c = settings.powerTextColor
                frame.powerText:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
            else
                frame.powerText:SetTextColor(1, 1, 1, 1)
            end
            frame.powerText:Show()
        else
            frame.powerText:Hide()
        end
    end


    local general = GetGeneralSettings()

    if general and general.darkMode then
        local c = general.darkModeHealthColor or { 0.15, 0.15, 0.15, 1 }
        frame.healthBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
    else

        if general and general.defaultUseClassColor then
            local _, class = UnitClass("player")
            if class and RAID_CLASS_COLORS[class] then
                local color = RAID_CLASS_COLORS[class]
                frame.healthBar:SetStatusBarColor(color.r, color.g, color.b, 1)
            else
                local c = general.defaultHealthColor or { 0.2, 0.2, 0.2, 1 }
                frame.healthBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
            end
        else
            local c = general and general.defaultHealthColor or { 0.2, 0.2, 0.2, 1 }
            frame.healthBar:SetStatusBarColor(c[1], c[2], c[3], c[4] or 1)
        end
    end
end

function PREY_UF:HidePreview(unitKey)

    if unitKey == "boss" then
        for i = 1, 5 do
            local bossKey = "boss" .. i
            local frame = self.frames[bossKey]
            if frame then
                self.previewMode[bossKey] = false

                if frame.nameText then
                    frame.nameText:SetText("")
                end
                if not InCombatLockdown() then
                    RegisterStateDriver(frame, "visibility", "[@boss" .. i .. ",exists] show; hide")
                end
                if UnitExists("boss" .. i) then
                    UpdateFrame(frame)
                    frame:Show()
                else
                    frame:Hide()
                end


                local castbar = self.castbars[bossKey]
                if castbar then
                    castbar.isPreviewSimulation = false
                    castbar:SetScript("OnUpdate", nil)
                    castbar:Hide()
                end


                self:HideAuraPreviewForFrame(frame, bossKey, "buff")
                self:HideAuraPreviewForFrame(frame, bossKey, "debuff")
            end
        end


        return
    end

    local frame = self.frames[unitKey]
    if not frame then return end

    self.previewMode[unitKey] = false


    if not InCombatLockdown() then
        local unit = frame.unit
        if unit == "target" then
            RegisterStateDriver(frame, "visibility", "[@target,exists] show; hide")
        elseif unit == "focus" then
            RegisterStateDriver(frame, "visibility", "[@focus,exists] show; hide")
        elseif unit == "pet" then
            RegisterStateDriver(frame, "visibility", "[@pet,exists] show; hide")
        elseif unit == "targettarget" then
            RegisterStateDriver(frame, "visibility", "[@targettarget,exists] show; hide")
        end
    end


    if UnitExists(frame.unit) or unitKey == "player" then
        UpdateFrame(frame)
        frame:Show()
    else
        frame:Hide()
    end
end


function PREY_UF:ShowAuraPreview(unitKey, auraType)

    if unitKey == "boss" then
        local previewKey = "boss_" .. auraType
        self.auraPreviewMode[previewKey] = true

        for i = 1, 5 do
            local bossKey = "boss" .. i
            local frame = self.frames[bossKey]
            if frame and self.previewMode[bossKey] then
                self:ShowAuraPreviewForFrame(frame, "boss", auraType)
            end
        end
        return
    end

    local frame = self.frames[unitKey]
    if not frame then return end

    local previewKey = unitKey .. "_" .. auraType
    self.auraPreviewMode[previewKey] = true

    self:ShowAuraPreviewForFrame(frame, unitKey, auraType)
end

function PREY_UF:ShowAuraPreviewForFrame(frame, unitKey, auraType)
    if not frame then return end


    local settings = GetUnitSettings(unitKey)
    local auraSettings = settings and settings.auras or {}


    local previewData = (auraType == "buff") and PREVIEW_AURAS.buffs or PREVIEW_AURAS.debuffs
    local isDebuff = (auraType == "debuff")


    local iconSize, anchor, grow, offsetX, offsetY, spacing, maxIcons
    if isDebuff then
        iconSize = auraSettings.iconSize or 22
        anchor = auraSettings.debuffAnchor or "TOPLEFT"
        grow = auraSettings.debuffGrow or "RIGHT"
        offsetX = auraSettings.debuffOffsetX or 0
        offsetY = auraSettings.debuffOffsetY or 2
        spacing = auraSettings.debuffSpacing or 2
        maxIcons = auraSettings.debuffMaxIcons or 16
    else
        iconSize = auraSettings.buffIconSize or 22
        anchor = auraSettings.buffAnchor or "BOTTOMLEFT"
        grow = auraSettings.buffGrow or "RIGHT"
        offsetX = auraSettings.buffOffsetX or 0
        offsetY = auraSettings.buffOffsetY or -2
        spacing = auraSettings.buffSpacing or 2
        maxIcons = auraSettings.buffMaxIcons or 16
    end


    local containerKey = isDebuff and "previewDebuffIcons" or "previewBuffIcons"
    frame[containerKey] = frame[containerKey] or {}
    local container = frame[containerKey]


    local realContainer = isDebuff and frame.debuffIcons or frame.buffIcons
    if realContainer then
        for _, icon in ipairs(realContainer) do
            icon:Hide()
        end
    end


    for _, icon in ipairs(container) do
        icon:SetScript("OnUpdate", nil)
        icon:Hide()
    end


    local previewStartTime = GetTime()
    local previewDuration = 10
    local previewDataCount = #previewData


    for i = 1, maxIcons do

        local dataIndex = ((i - 1) % previewDataCount) + 1
        local auraData = previewData[dataIndex]
        local icon = container[i]
        if not icon then

            icon = CreateFrame("Frame", nil, frame)
            icon:SetFrameLevel(frame:GetFrameLevel() + 10)


            local border = icon:CreateTexture(nil, "BACKGROUND", nil, -8)
            border:SetColorTexture(0, 0, 0, 1)
            border:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
            border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
            icon.border = border


            local tex = icon:CreateTexture(nil, "ARTWORK")
            tex:SetPoint("TOPLEFT", 0, 0)
            tex:SetPoint("BOTTOMRIGHT", 0, 0)
            tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            icon.icon = tex


            local cd = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
            cd:SetAllPoints(icon)
            cd:SetDrawEdge(false)
            cd:SetReverse(true)
            cd:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
            cd:SetSwipeColor(0, 0, 0, 0.8)
            cd.noOCC = true
            cd.noCooldownCount = true
            icon.cooldown = cd


            local count = icon:CreateFontString(nil, "OVERLAY")
            count:SetTextColor(1, 1, 1, 1)
            icon.count = count

            container[i] = icon
        end


        icon:SetSize(iconSize, iconSize)


        local fontPath = GetFontPath()
        local fontOutline = GetFontOutline()
        local prefix = isDebuff and "debuff" or "buff"

        local showStack = auraSettings[prefix .. "ShowStack"]
        if showStack == nil then showStack = auraSettings.showStack end
        if showStack == nil then showStack = true end

        local stackSize = auraSettings[prefix .. "StackSize"] or auraSettings.stackSize or 10
        local stackAnchor = auraSettings[prefix .. "StackAnchor"] or auraSettings.stackAnchor or "BOTTOMRIGHT"
        local stackOffsetX = auraSettings[prefix .. "StackOffsetX"] or auraSettings.stackOffsetX or -1
        local stackOffsetY = auraSettings[prefix .. "StackOffsetY"] or auraSettings.stackOffsetY or 1
        local stackColor = auraSettings[prefix .. "StackColor"] or auraSettings.stackColor or {1, 1, 1, 1}

        icon.count:SetFont(fontPath, stackSize, fontOutline)
        icon.count:ClearAllPoints()
        icon.count:SetPoint(stackAnchor, icon, stackAnchor, stackOffsetX, stackOffsetY)
        icon.count:SetTextColor(stackColor[1] or 1, stackColor[2] or 1, stackColor[3] or 1, stackColor[4] or 1)


        local hideSwipe = auraSettings[prefix .. "HideSwipe"]
        if hideSwipe == nil then hideSwipe = false end
        icon.cooldown:SetDrawSwipe(not hideSwipe)


        icon.icon:SetTexture(auraData.icon)


        if isDebuff then
            icon.border:SetColorTexture(0.8, 0.2, 0.2, 1)
        else
            icon.border:SetColorTexture(0, 0, 0, 1)
        end


        local showStackText = false
        if showStack then
            pcall(function()
                if auraData.stacks and auraData.stacks > 1 then
                    showStackText = true
                end
            end)
        end
        if showStackText then
            icon.count:SetText(auraData.stacks)
            icon.count:Show()
        else
            icon.count:Hide()
        end


        local idx = i - 1
        local xPos, yPos = offsetX, offsetY
        if grow == "RIGHT" then
            xPos = xPos + idx * (iconSize + spacing)
        elseif grow == "LEFT" then
            xPos = xPos - idx * (iconSize + spacing)
        elseif grow == "UP" then
            yPos = yPos + idx * (iconSize + spacing)
        elseif grow == "DOWN" then
            yPos = yPos - idx * (iconSize + spacing)
        end


        local iconPoint, framePoint, borderOffsetX
        if anchor == "TOPLEFT" then
            iconPoint, framePoint, borderOffsetX = "BOTTOMLEFT", "TOPLEFT", 1
        elseif anchor == "TOPRIGHT" then
            iconPoint, framePoint, borderOffsetX = "BOTTOMRIGHT", "TOPRIGHT", -1
        elseif anchor == "BOTTOMLEFT" then
            iconPoint, framePoint, borderOffsetX = "TOPLEFT", "BOTTOMLEFT", 1
        elseif anchor == "BOTTOMRIGHT" then
            iconPoint, framePoint, borderOffsetX = "TOPRIGHT", "BOTTOMRIGHT", -1
        end

        icon:ClearAllPoints()
        icon:SetPoint(iconPoint, frame, framePoint, xPos + (borderOffsetX or 0), yPos)


        icon.cooldown:SetCooldown(previewStartTime, previewDuration)
        icon.cooldown:Show()


        icon._previewStartTime = previewStartTime
        icon._previewDuration = previewDuration

        icon:SetScript("OnUpdate", function(self, elapsed)
            local now = GetTime()
            local elapsedTime = now - self._previewStartTime
            if elapsedTime >= self._previewDuration then
                self._previewStartTime = now
                self.cooldown:SetCooldown(now, self._previewDuration)
            end
        end)

        icon:Show()
    end
end

function PREY_UF:HideAuraPreview(unitKey, auraType)

    if unitKey == "boss" then
        local previewKey = "boss_" .. auraType
        self.auraPreviewMode[previewKey] = false
        for i = 1, 5 do
            local bossKey = "boss" .. i
            local frame = self.frames[bossKey]
            if frame then
                self:HideAuraPreviewForFrame(frame, bossKey, auraType)
            end
        end
        return
    end

    local frame = self.frames[unitKey]
    if not frame then return end

    local previewKey = unitKey .. "_" .. auraType
    self.auraPreviewMode[previewKey] = false

    self:HideAuraPreviewForFrame(frame, unitKey, auraType)
end

function PREY_UF:HideAuraPreviewForFrame(frame, unitKey, auraType)
    if not frame then return end

    local isDebuff = (auraType == "debuff")
    local containerKey = isDebuff and "previewDebuffIcons" or "previewBuffIcons"
    local container = frame[containerKey]


    if container then
        for _, icon in ipairs(container) do
            icon:SetScript("OnUpdate", nil)
            icon:Hide()
        end
    end


    lastAuraUpdate[unitKey] = 0
    UpdateAuras(frame)
end


function PREY_UF:RefreshFrame(unitKey)

    if unitKey == "boss" then
        local settings = GetUnitSettings("boss")
        local general = GetGeneralSettings()
        local spacing = settings and settings.spacing or 40

        if not settings or InCombatLockdown() then

            for i = 1, 5 do
                local frame = self.frames["boss" .. i]
                if frame then UpdateFrame(frame) end
            end
            return
        end

        local borderSize = Scale(settings.borderSize or 1)
        local powerHeight = settings.showPowerBar and Scale(settings.powerBarHeight or 4) or 0
        local separatorHeight = (settings.showPowerBar and settings.powerBarBorder ~= false) and 1 or 0
        local texturePath = GetTexturePath(settings.texture)


        local hudLayering = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.hudLayering
        local bossLayerPriority = hudLayering and hudLayering.bossFrames or 4
        local bossFrameLevel
        if PREYCore and PREYCore.GetHUDFrameLevel then
            bossFrameLevel = PREYCore:GetHUDFrameLevel(bossLayerPriority)
        end

        for i = 1, 5 do
            local bossKey = "boss" .. i
            local frame = self.frames[bossKey]
            if frame then

                if bossFrameLevel then
                    frame:SetFrameLevel(bossFrameLevel)
                end


                frame:SetSize(settings.width or 220, settings.height or 35)


                frame:ClearAllPoints()
                if i == 1 then
                    frame:SetPoint("CENTER", UIParent, "CENTER", settings.offsetX or 0, settings.offsetY or 0)
                else
                    local prevFrame = self.frames["boss" .. (i - 1)]
                    if prevFrame then
                        frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
                    end
                end


                local bgColor, healthOpacity, bgOpacity
                if general and general.darkMode then
                    bgColor = general.darkModeBgColor or { 0.25, 0.25, 0.25, 1 }
                    healthOpacity = general.darkModeHealthOpacity or general.darkModeOpacity or 1.0
                    bgOpacity = general.darkModeBgOpacity or general.darkModeOpacity or 1.0
                else
                    bgColor = general and general.defaultBgColor or { 0.1, 0.1, 0.1, 0.9 }
                    healthOpacity = general and general.defaultHealthOpacity or general and general.defaultOpacity or 1.0
                    bgOpacity = general and general.defaultBgOpacity or general and general.defaultOpacity or 1.0
                end
                local bgAlpha = (bgColor[4] or 1) * bgOpacity


                frame:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = borderSize > 0 and "Interface\\Buttons\\WHITE8x8" or nil,
                    edgeSize = borderSize > 0 and borderSize or nil,
                })
                frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgAlpha)
                if borderSize > 0 then
                    frame:SetBackdropBorderColor(0, 0, 0, 1)
                end


                frame.healthBar:SetAlpha(healthOpacity)
                if frame.powerBar then frame.powerBar:SetAlpha(healthOpacity) end


                frame.healthBar:SetStatusBarTexture(texturePath)
                frame.healthBar:ClearAllPoints()
                frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", borderSize, -borderSize)
                frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize + powerHeight + separatorHeight)


                if frame.powerBar then
                    if settings.showPowerBar then
                        frame.powerBar:SetStatusBarTexture(texturePath)
                        frame.powerBar:ClearAllPoints()
                        frame.powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", borderSize, borderSize)
                        frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize)
                        frame.powerBar:SetHeight(powerHeight)
                        frame.powerBar:Show()
                    else
                        frame.powerBar:Hide()
                    end
                end


                if frame.powerBarSeparator then
                    if settings.showPowerBar and settings.powerBarBorder ~= false then
                        frame.powerBarSeparator:Show()
                    else
                        frame.powerBarSeparator:Hide()
                    end
                end


                if settings.showName then
                    if not frame.nameText then
                        local nameText = frame.healthBar:CreateFontString(nil, "OVERLAY")
                        nameText:SetShadowOffset(0, 0)
                        frame.nameText = nameText
                    end
                    frame.nameText:SetFont(GetFontPath(), settings.nameFontSize or 11, GetFontOutline())
                    local nameAnchorInfo = GetTextAnchorInfo(settings.nameAnchor or "LEFT")
                    local nameOffsetX = Scale(settings.nameOffsetX or 4)
                    local nameOffsetY = Scale(settings.nameOffsetY or 0)
                    frame.nameText:ClearAllPoints()
                    frame.nameText:SetPoint(nameAnchorInfo.point, frame.healthBar, nameAnchorInfo.point, nameOffsetX, nameOffsetY)
                    frame.nameText:SetJustifyH(nameAnchorInfo.justify)
                    frame.nameText:Show()

                    if self.previewMode[bossKey] then
                        frame.nameText:SetText("Boss " .. i)
                    else
                        UpdateName(frame)
                    end
                elseif frame.nameText then
                    frame.nameText:Hide()
                end


                if settings.showHealth then
                    if not frame.healthText then
                        local healthText = frame.healthBar:CreateFontString(nil, "OVERLAY")
                        healthText:SetShadowOffset(0, 0)
                        frame.healthText = healthText
                    end
                    frame.healthText:SetFont(GetFontPath(), settings.healthFontSize or 11, GetFontOutline())
                    local healthAnchorInfo = GetTextAnchorInfo(settings.healthAnchor or "RIGHT")
                    local healthOffsetX = Scale(settings.healthOffsetX or -4)
                    local healthOffsetY = Scale(settings.healthOffsetY or 0)
                    frame.healthText:ClearAllPoints()
                    frame.healthText:SetPoint(healthAnchorInfo.point, frame.healthBar, healthAnchorInfo.point, healthOffsetX, healthOffsetY)
                    frame.healthText:SetJustifyH(healthAnchorInfo.justify)
                    frame.healthText:Show()

                    if self.previewMode[bossKey] then

                        frame.healthText:SetText("75.0K - " .. (75 - (i * 5)) .. "%")
                    else
                        UpdateHealth(frame)
                    end
                elseif frame.healthText then
                    frame.healthText:Hide()
                end


                if settings.showPowerText then
                    if not frame.powerText then
                        local powerText = frame.healthBar:CreateFontString(nil, "OVERLAY")
                        powerText:SetShadowOffset(0, 0)
                        frame.powerText = powerText
                    end
                    local fontPath = GetFontPath()
                    local fontOutline = GetFontOutline()
                    frame.powerText:SetFont(fontPath, settings.powerTextFontSize or 12, fontOutline)
                    frame.powerText:ClearAllPoints()
                    local powerAnchorInfo = GetTextAnchorInfo(settings.powerTextAnchor or "BOTTOMRIGHT")
                    local powerOffsetX = Scale(settings.powerTextOffsetX or -4)
                    local powerOffsetY = Scale(settings.powerTextOffsetY or 2)
                    frame.powerText:SetPoint(powerAnchorInfo.point, frame.healthBar, powerAnchorInfo.point, powerOffsetX, powerOffsetY)
                    frame.powerText:SetJustifyH(powerAnchorInfo.justify)
                    frame.powerText:Show()

                    if self.previewMode[bossKey] then

                        frame.powerText:SetText("60%")
                    else
                        UpdatePowerText(frame)
                    end
                elseif frame.powerText then
                    frame.powerText:Hide()
                end


                if frame.targetMarker and settings.targetMarker then
                    local marker = settings.targetMarker
                    frame.targetMarker:SetSize(marker.size or 20, marker.size or 20)
                    frame.targetMarker:ClearAllPoints()
                    local anchorInfo = GetTextAnchorInfo(marker.anchor or "TOP")
                    frame.targetMarker:SetPoint(anchorInfo.point, frame, anchorInfo.point, marker.xOffset or 0, marker.yOffset or 8)
                    UpdateTargetMarker(frame)
                end


                if not self.previewMode[bossKey] then
                    UpdateFrame(frame)
                end


                local castbar = self.castbars[bossKey]
                if castbar and PREY_Castbar and PREY_Castbar.RefreshBossCastbar then
                    local castSettings = settings.castbar
                    if castSettings then
                        PREY_Castbar:RefreshBossCastbar(castbar, bossKey, castSettings, frame)
                    end
                end
            end
        end
        return
    end

    local frame = self.frames[unitKey]
    if not frame then return end


    if InCombatLockdown() then

        UpdateFrame(frame)
        return
    end

    local settings = GetUnitSettings(unitKey)
    local general = GetGeneralSettings()
    if not settings then return end


    local hudLayering = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.hudLayering
    local layerKey = unitKey .. "Frame"

    local layerPriority
    if unitKey == "player" then
        layerPriority = hudLayering and hudLayering.playerFrame or 4
    elseif unitKey == "target" then
        layerPriority = hudLayering and hudLayering.targetFrame or 4
    elseif unitKey == "targettarget" then
        layerPriority = hudLayering and hudLayering.totFrame or 3
    elseif unitKey == "pet" then
        layerPriority = hudLayering and hudLayering.petFrame or 3
    elseif unitKey == "focus" then
        layerPriority = hudLayering and hudLayering.focusFrame or 4
    else
        layerPriority = 4
    end
    if PREYCore and PREYCore.GetHUDFrameLevel then
        local frameLevel = PREYCore:GetHUDFrameLevel(layerPriority)
        frame:SetFrameLevel(frameLevel)
    end


    frame:SetSize(settings.width or 220, settings.height or 35)


    frame:ClearAllPoints()
    local isAnchored = settings.anchorTo and settings.anchorTo ~= "disabled"
    if isAnchored and (unitKey == "player" or unitKey == "target") then

        _G.PreyUI_UpdateAnchoredUnitFrames()
    else

        frame:SetPoint("CENTER", UIParent, "CENTER", settings.offsetX or 0, settings.offsetY or 0)
    end


    local bgColor, healthOpacity, bgOpacity
    if general and general.darkMode then
        bgColor = general.darkModeBgColor or { 0.25, 0.25, 0.25, 1 }
        healthOpacity = general.darkModeHealthOpacity or general.darkModeOpacity or 1.0
        bgOpacity = general.darkModeBgOpacity or general.darkModeOpacity or 1.0
    else
        bgColor = general and general.defaultBgColor or { 0.1, 0.1, 0.1, 0.9 }
        healthOpacity = general and general.defaultHealthOpacity or general and general.defaultOpacity or 1.0
        bgOpacity = general and general.defaultBgOpacity or general and general.defaultOpacity or 1.0
    end
    local bgAlpha = (bgColor[4] or 1) * bgOpacity


    local borderSize = Scale(settings.borderSize or 1)


    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = borderSize > 0 and "Interface\\Buttons\\WHITE8x8" or nil,
        edgeSize = borderSize > 0 and borderSize or nil,
    })
    frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgAlpha)
    if borderSize > 0 then
        frame:SetBackdropBorderColor(0, 0, 0, 1)
    end


    frame.healthBar:SetAlpha(healthOpacity)
    if frame.powerBar then frame.powerBar:SetAlpha(healthOpacity) end


    local powerHeight = settings.showPowerBar and Scale(settings.powerBarHeight or 4) or 0
    local separatorHeight = (settings.showPowerBar and settings.powerBarBorder ~= false) and 1 or 0


    local texturePath = GetTexturePath(settings.texture)
    frame.healthBar:SetStatusBarTexture(texturePath)


    frame.healthBar:ClearAllPoints()
    frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", borderSize, -borderSize)
    frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize + powerHeight + separatorHeight)


    if settings.showPowerBar then
        if not frame.powerBar then

            local powerBar = CreateFrame("StatusBar", nil, frame)
            powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", borderSize, borderSize)
            powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize)
            powerBar:SetHeight(powerHeight)
            powerBar:SetStatusBarTexture(texturePath)
            powerBar:SetMinMaxValues(0, 100)
            powerBar:SetValue(100)
            local powerColor = settings.powerBarColor or { 0, 0.5, 1, 1 }
            powerBar:SetStatusBarColor(powerColor[1], powerColor[2], powerColor[3], powerColor[4] or 1)
            powerBar:EnableMouse(false)
            frame.powerBar = powerBar
        end

        frame.powerBar:SetStatusBarTexture(texturePath)
        frame.powerBar:ClearAllPoints()
        frame.powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", borderSize, borderSize)
        frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderSize, borderSize)
        frame.powerBar:SetHeight(powerHeight)
        frame.powerBar:Show()
    elseif frame.powerBar then
        frame.powerBar:Hide()
    end


    if settings.showPowerBar and settings.powerBarBorder ~= false then
        if not frame.powerBarSeparator then

            local separator = frame.powerBar:CreateTexture(nil, "OVERLAY")
            separator:SetHeight(1)
            separator:SetPoint("BOTTOMLEFT", frame.powerBar, "TOPLEFT", 0, 0)
            separator:SetPoint("BOTTOMRIGHT", frame.powerBar, "TOPRIGHT", 0, 0)
            separator:SetTexture("Interface\\Buttons\\WHITE8x8")
            separator:SetVertexColor(0, 0, 0, 1)
            frame.powerBarSeparator = separator
        end
        frame.powerBarSeparator:Show()
    elseif frame.powerBarSeparator then
        frame.powerBarSeparator:Hide()
    end


    if settings.showPortrait then
        local portraitSize = Scale(settings.portraitSize or 40)
        local portraitBorderSize = Scale(settings.portraitBorderSize or 1)
        local portraitGap = Scale(settings.portraitGap or 0)
        local portraitOffsetX = Scale(settings.portraitOffsetX or 0)
        local portraitOffsetY = Scale(settings.portraitOffsetY or 0)
        local side = settings.portraitSide or "LEFT"

        if not frame.portrait then
            local portrait = CreateFrame("Button", nil, frame, "SecureUnitButtonTemplate, BackdropTemplate")
            local portraitTex = portrait:CreateTexture(nil, "ARTWORK")
            frame.portraitTexture = portraitTex
            frame.portrait = portrait


            portrait:SetAttribute("unit", frame.unit)
            portrait:SetAttribute("*type1", "target")
            portrait:SetAttribute("*type2", "togglemenu")
            portrait:RegisterForClicks("AnyUp")


            portrait:HookScript("OnEnter", function(self)
                ShowUnitTooltip(frame)
            end)
            portrait:HookScript("OnLeave", HideUnitTooltip)
        end


        frame.portrait:SetSize(portraitSize, portraitSize)
        frame.portrait:ClearAllPoints()
        if side == "LEFT" then
            frame.portrait:SetPoint("RIGHT", frame, "LEFT", -portraitGap + portraitOffsetX, portraitOffsetY)
        else
            frame.portrait:SetPoint("LEFT", frame, "RIGHT", portraitGap + portraitOffsetX, portraitOffsetY)
        end


        local borderR, borderG, borderB = 0, 0, 0
        if settings.portraitBorderUseClassColor then
            local _, class = UnitClass(frame.unit)
            if class then
                local classColor = RAID_CLASS_COLORS[class]
                if classColor then
                    borderR, borderG, borderB = classColor.r, classColor.g, classColor.b
                end
            end
        elseif settings.portraitBorderColor then
            borderR = settings.portraitBorderColor[1] or 0
            borderG = settings.portraitBorderColor[2] or 0
            borderB = settings.portraitBorderColor[3] or 0
        end

        frame.portrait:SetBackdrop({
            bgFile = nil,
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = portraitBorderSize,
        })
        frame.portrait:SetBackdropBorderColor(borderR, borderG, borderB, 1)


        frame.portraitTexture:ClearAllPoints()
        frame.portraitTexture:SetPoint("TOPLEFT", portraitBorderSize, -portraitBorderSize)
        frame.portraitTexture:SetPoint("BOTTOMRIGHT", -portraitBorderSize, portraitBorderSize)


        if UnitExists(frame.unit) then
            SetPortraitTexture(frame.portraitTexture, frame.unit, true)
            frame.portraitTexture:SetTexCoord(0.15, 0.85, 0.15, 0.85)
        end

        frame.portrait:Show()
    elseif frame.portrait then
        frame.portrait:Hide()
    end


    local fontPath = GetFontPath()
    local fontOutline = general and general.fontOutline or "OUTLINE"

    if frame.nameText then
        frame.nameText:SetFont(fontPath, settings.nameFontSize or 12, fontOutline)
        frame.nameText:ClearAllPoints()
        local nameAnchorInfo = GetTextAnchorInfo(settings.nameAnchor or "LEFT")
        frame.nameText:SetPoint(nameAnchorInfo.point, frame, nameAnchorInfo.point, Scale(settings.nameOffsetX or 4), Scale(settings.nameOffsetY or 0))
        frame.nameText:SetJustifyH(nameAnchorInfo.justify)
        if settings.showName then
            frame.nameText:Show()
        else
            frame.nameText:Hide()
        end
    end

    if frame.healthText then
        frame.healthText:SetFont(fontPath, settings.healthFontSize or 12, fontOutline)
        frame.healthText:ClearAllPoints()
        local healthAnchorInfo = GetTextAnchorInfo(settings.healthAnchor or "RIGHT")
        frame.healthText:SetPoint(healthAnchorInfo.point, frame, healthAnchorInfo.point, Scale(settings.healthOffsetX or -4), Scale(settings.healthOffsetY or 0))
        frame.healthText:SetJustifyH(healthAnchorInfo.justify)

        if settings.showHealth == false then
            frame.healthText:Hide()
        else

            local displayStyle = settings.healthDisplayStyle
            if displayStyle and displayStyle ~= "" then
                frame.healthText:Show()
            else

                local showAbsolute = settings.showHealthAbsolute
                local showPercent = settings.showHealthPercent
                if showAbsolute or showPercent then
                    frame.healthText:Show()
                else
                    frame.healthText:Hide()
                end
            end
        end
    end


    if frame.powerText then
        frame.powerText:SetFont(fontPath, settings.powerTextFontSize or 12, fontOutline)
        frame.powerText:ClearAllPoints()
        local powerAnchorInfo = GetTextAnchorInfo(settings.powerTextAnchor or "BOTTOMRIGHT")
        frame.powerText:SetPoint(powerAnchorInfo.point, frame, powerAnchorInfo.point, Scale(settings.powerTextOffsetX or -4), Scale(settings.powerTextOffsetY or 2))
        frame.powerText:SetJustifyH(powerAnchorInfo.justify)

    end


    if unitKey == "player" and settings.indicators then
        local indSettings = settings.indicators


        if frame.restedIndicator and indSettings.rested then
            local rested = indSettings.rested
            frame.restedIndicator:SetSize(rested.size or 16, rested.size or 16)
            frame.restedIndicator:ClearAllPoints()
            local anchorInfo = GetTextAnchorInfo(rested.anchor or "TOPLEFT")
            frame.restedIndicator:SetPoint(anchorInfo.point, frame, anchorInfo.point, rested.offsetX or -2, rested.offsetY or 2)
        end


        if frame.combatIndicator and indSettings.combat then
            local combat = indSettings.combat
            frame.combatIndicator:SetSize(combat.size or 16, combat.size or 16)
            frame.combatIndicator:ClearAllPoints()
            local anchorInfo = GetTextAnchorInfo(combat.anchor or "TOPLEFT")
            frame.combatIndicator:SetPoint(anchorInfo.point, frame, anchorInfo.point, combat.offsetX or -2, combat.offsetY or 2)
        end


        if frame.stanceText then
            UpdateStance(frame)
        end


        if frame.indicatorFrame then
            local indicatorPriority = hudLayering and hudLayering.playerIndicators or 6
            if PREYCore and PREYCore.GetHUDFrameLevel then
                local indicatorLevel = PREYCore:GetHUDFrameLevel(indicatorPriority)
                frame.indicatorFrame:SetFrameLevel(indicatorLevel)
            end
        end
    end


    if frame.targetMarker and settings.targetMarker then
        local marker = settings.targetMarker
        frame.targetMarker:SetSize(marker.size or 20, marker.size or 20)
        frame.targetMarker:ClearAllPoints()
        local anchorInfo = GetTextAnchorInfo(marker.anchor or "TOP")
        frame.targetMarker:SetPoint(anchorInfo.point, frame, anchorInfo.point, marker.xOffset or 0, marker.yOffset or 8)
        UpdateTargetMarker(frame)
    end


    if settings.leaderIcon and (unitKey == "player" or unitKey == "target" or unitKey == "focus") then
        local leader = settings.leaderIcon
        if leader.enabled then

            if not frame.leaderIcon then
                if not frame.indicatorFrame then
                    local indicatorFrame = CreateFrame("Frame", nil, frame)
                    indicatorFrame:SetAllPoints()
                    indicatorFrame:SetFrameLevel(frame.textFrame:GetFrameLevel() + 5)
                    frame.indicatorFrame = indicatorFrame
                end
                local leaderIcon = frame.indicatorFrame:CreateTexture(nil, "OVERLAY")
                leaderIcon:Hide()
                frame.leaderIcon = leaderIcon

                frame:RegisterEvent("PARTY_LEADER_CHANGED")
                frame:RegisterEvent("GROUP_ROSTER_UPDATE")
            end

            frame.leaderIcon:SetSize(leader.size or 16, leader.size or 16)
            frame.leaderIcon:ClearAllPoints()
            local anchorInfo = GetTextAnchorInfo(leader.anchor or "TOPLEFT")
            frame.leaderIcon:SetPoint(anchorInfo.point, frame, anchorInfo.point, leader.xOffset or -8, leader.yOffset or 8)
            UpdateLeaderIcon(frame)
        elseif frame.leaderIcon then

            frame.leaderIcon:Hide()
        end
    end


    if self.previewMode[unitKey] then
        self:ShowPreview(unitKey)
    else
        UpdateFrame(frame)
    end


    local castbar = self.castbars[unitKey]
    local castSettings = settings.castbar
    if castSettings and castSettings.enabled then
        if castbar and PREY_Castbar and PREY_Castbar.RefreshCastbar then

            PREY_Castbar:RefreshCastbar(castbar, unitKey, castSettings, frame)
        elseif not castbar and PREY_Castbar and PREY_Castbar.CreateCastbar then

            self.castbars[unitKey] = PREY_Castbar:CreateCastbar(frame, unitKey, unitKey)
        end
    end
end

function PREY_UF:RefreshAll()

    local bossRefreshed = false

    for unitKey, frame in pairs(self.frames) do

        if unitKey:match("^boss%d+$") then
            if not bossRefreshed then
                self:RefreshFrame("boss")
                bossRefreshed = true
            end
        else
            self:RefreshFrame(unitKey)
        end
    end
end


PREY_UF.editModeActive = false


function PREY_UF:RegisterEditModeSliders(unitKey, xSlider, ySlider)
    self.editModeSliders[unitKey] = self.editModeSliders[unitKey] or {}
    self.editModeSliders[unitKey].x = xSlider
    self.editModeSliders[unitKey].y = ySlider
end


function PREY_UF:NotifyPositionChanged(unitKey, offsetX, offsetY)

    local sliders = self.editModeSliders[unitKey]
    if sliders then
        if sliders.x and sliders.x.SetValue then
            sliders.x.SetValue(offsetX, true)
        end
        if sliders.y and sliders.y.SetValue then
            sliders.y.SetValue(offsetY, true)
        end
    end


    local frame = self.frames[unitKey]
    if frame and frame.editOverlay and frame.editOverlay.infoText then
        local label = frame.editOverlay.unitLabel or unitKey
        frame.editOverlay.infoText:SetText(string.format("%s  X:%d Y:%d", label, offsetX, offsetY))
    end
end


local function CreateNudgeButton(parent, direction, deltaX, deltaY, unitKey)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(18, 18)


    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.7)
    btn.bg = bg


    local line1 = btn:CreateTexture(nil, "ARTWORK")
    line1:SetColorTexture(1, 1, 1, 0.9)
    line1:SetSize(7, 2)

    local line2 = btn:CreateTexture(nil, "ARTWORK")
    line2:SetColorTexture(1, 1, 1, 0.9)
    line2:SetSize(7, 2)


    if direction == "DOWN" then
        line1:SetPoint("CENTER", btn, "CENTER", -2, 1)
        line1:SetRotation(math.rad(-45))
        line2:SetPoint("CENTER", btn, "CENTER", 2, 1)
        line2:SetRotation(math.rad(45))
    elseif direction == "UP" then
        line1:SetPoint("CENTER", btn, "CENTER", -2, -1)
        line1:SetRotation(math.rad(45))
        line2:SetPoint("CENTER", btn, "CENTER", 2, -1)
        line2:SetRotation(math.rad(-45))
    elseif direction == "LEFT" then
        line1:SetPoint("CENTER", btn, "CENTER", -1, -2)
        line1:SetRotation(math.rad(-45))
        line2:SetPoint("CENTER", btn, "CENTER", -1, 2)
        line2:SetRotation(math.rad(45))
    elseif direction == "RIGHT" then
        line1:SetPoint("CENTER", btn, "CENTER", 1, -2)
        line1:SetRotation(math.rad(45))
        line2:SetPoint("CENTER", btn, "CENTER", 1, 2)
        line2:SetRotation(math.rad(-45))
    end
    btn.line1 = line1
    btn.line2 = line2


    btn:SetScript("OnEnter", function(self)
        self.line1:SetColorTexture(0.820, 0.180, 0.220, 1)
        self.line2:SetColorTexture(0.820, 0.180, 0.220, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self.line1:SetColorTexture(1, 1, 1, 0.9)
        self.line2:SetColorTexture(1, 1, 1, 0.9)
    end)

    btn:SetScript("OnClick", function()
        local frame = parent:GetParent()
        local settingsKey = frame.unitKey
        if settingsKey and settingsKey:match("^boss%d+$") then
            settingsKey = "boss"
        end
        local settings = GetUnitSettings(settingsKey)


        local isAnchored = settings and settings.anchorTo and settings.anchorTo ~= "disabled"
        if isAnchored and (settingsKey == "player" or settingsKey == "target") then
            return
        end

        if settings then
            local shift = IsShiftKeyDown()
            local step = shift and 10 or 1
            settings.offsetX = (settings.offsetX or 0) + (deltaX * step)
            settings.offsetY = (settings.offsetY or 0) + (deltaY * step)
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", settings.offsetX, settings.offsetY)


            PREY_UF:NotifyPositionChanged(settingsKey, settings.offsetX, settings.offsetY)
        end
    end)

    return btn
end

function PREY_UF:EnableEditMode()
    if InCombatLockdown() then
        print("|cFFF87171PreyUI|r: Cannot enter Edit Mode during combat.")
        return
    end

    self.editModeActive = true


    self:HideBlizzardSelectionFrames()


    for unitKey, frame in pairs(self.frames) do
        UnregisterStateDriver(frame, "visibility")
    end


    if not self.exitEditModeBtn then
        local exitBtn = CreateFrame("Button", "PREY_ExitEditModeBtn", UIParent, "BackdropTemplate")
        exitBtn:SetSize(180, 40)
        exitBtn:SetPoint("TOP", UIParent, "TOP", 0, -100)
        exitBtn:SetFrameStrata("TOOLTIP")
        exitBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
        })
        exitBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
        exitBtn:SetBackdropBorderColor(0.34, 0.82, 1, 1)

        local exitText = exitBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        exitText:SetPoint("CENTER")
        exitText:SetText("SAVE AND EXIT")
        exitText:SetTextColor(0.34, 0.82, 1, 1)
        exitBtn.text = exitText


        local hintText = exitBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hintText:SetPoint("TOP", exitBtn, "BOTTOM", 0, -5)
        hintText:SetText("Drag frames or click arrow buttons to nudge (Shift=1px)")
        hintText:SetTextColor(0.7, 0.7, 0.7, 1)
        exitBtn.hint = hintText

        exitBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(1, 1, 0, 1)
            self.text:SetTextColor(1, 1, 0, 1)
        end)
        exitBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.34, 0.82, 1, 1)
            self.text:SetTextColor(0.34, 0.82, 1, 1)
        end)
        exitBtn:SetScript("OnClick", function()
            if EditModeManagerFrame and EditModeManagerFrame:IsShown() then

                if EditModeManagerFrame.SaveLayoutChanges then
                    EditModeManagerFrame:SaveLayoutChanges()
                end

                HideUIPanel(EditModeManagerFrame)
            else

                PREY_UF:DisableEditMode()
            end
        end)

        self.exitEditModeBtn = exitBtn
    end
    self.exitEditModeBtn:Show()

    for unitKey, frame in pairs(self.frames) do

        if not frame.editOverlay then
            local overlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            overlay:SetAllPoints()
            overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
            overlay:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 2,
            })
            overlay:SetBackdropColor(0.2, 0.8, 1, 0.3)
            overlay:SetBackdropBorderColor(0.2, 0.8, 1, 1)


            local nudgeLeft = CreateNudgeButton(overlay, "LEFT", -1, 0, unitKey)
            nudgeLeft:SetPoint("RIGHT", overlay, "LEFT", -4, 0)
            overlay.nudgeLeft = nudgeLeft

            local nudgeRight = CreateNudgeButton(overlay, "RIGHT", 1, 0, unitKey)
            nudgeRight:SetPoint("LEFT", overlay, "RIGHT", 4, 0)
            overlay.nudgeRight = nudgeRight

            local nudgeUp = CreateNudgeButton(overlay, "UP", 0, 1, unitKey)
            nudgeUp:SetPoint("BOTTOM", overlay, "TOP", 0, 4)
            overlay.nudgeUp = nudgeUp


            local infoText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            infoText:SetPoint("BOTTOM", nudgeUp, "TOP", 0, 2)
            infoText:SetTextColor(0.7, 0.7, 0.7, 1)
            overlay.infoText = infoText
            overlay.unitLabel = unitKey:gsub("^%l", string.upper):gsub("(%l)(%u)", "%1 %2")

            local nudgeDown = CreateNudgeButton(overlay, "DOWN", 0, -1, unitKey)
            nudgeDown:SetPoint("TOP", overlay, "BOTTOM", 0, -4)
            overlay.nudgeDown = nudgeDown


            overlay.elementKey = unitKey


            nudgeLeft:Hide()
            nudgeRight:Hide()
            nudgeUp:Hide()
            nudgeDown:Hide()
            infoText:Hide()


            overlay:EnableMouse(false)

            frame.editOverlay = overlay
        end


        local settingsKey = unitKey
        if unitKey:match("^boss%d+$") then
            settingsKey = "boss"
        end
        local settings = GetUnitSettings(settingsKey)
        if settings and frame.editOverlay.infoText then
            local label = frame.editOverlay.unitLabel or unitKey
            local isAnchored = settings.anchorTo and settings.anchorTo ~= "disabled"
            if isAnchored and (settingsKey == "player" or settingsKey == "target") then
                local anchorNames = {essential = "Essential", utility = "Utility", primary = "Primary", secondary = "Secondary"}
                local anchorName = anchorNames[settings.anchorTo] or settings.anchorTo
                frame.editOverlay.infoText:SetText(label .. "  (Locked to " .. anchorName .. ")")
            else
                local x = settings.offsetX or 0
                local y = settings.offsetY or 0
                frame.editOverlay.infoText:SetText(string.format("%s  X:%d Y:%d", label, x, y))
            end
        end

        frame.editOverlay:Show()


        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")


        frame._editModeUnitKey = unitKey


        frame:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" and PREY_UF.editModeActive then
                local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
                if PREYCore and PREYCore.SelectEditModeElement then
                    PREYCore:SelectEditModeElement("unitframe", self._editModeUnitKey)
                end
            end
        end)

        frame:SetScript("OnDragStart", function(self)
            if PREY_UF.editModeActive then

                local settingsKey = self.unitKey
                if self.unitKey:match("^boss%d+$") then settingsKey = "boss" end
                local settings = GetUnitSettings(settingsKey)
                local isAnchored = settings and settings.anchorTo and settings.anchorTo ~= "disabled"
                if isAnchored and (settingsKey == "player" or settingsKey == "target") then
                    return
                end

                self:StartMoving()
                self._isMoving = true


                self:SetScript("OnUpdate", function(self)
                    if not self._isMoving then
                        self:SetScript("OnUpdate", nil)
                        return
                    end


                    local selfX, selfY = self:GetCenter()
                    local parentX, parentY = UIParent:GetCenter()
                    if selfX and selfY and parentX and parentY then
                        local offsetX = math.floor(selfX - parentX + 0.5)
                        local offsetY = math.floor(selfY - parentY + 0.5)


                        local settingsKey = self.unitKey
                        if self.unitKey:match("^boss%d+$") then
                            settingsKey = "boss"
                        end
                        local settings = GetUnitSettings(settingsKey)
                        if settings then
                            settings.offsetX = offsetX
                            settings.offsetY = offsetY


                            PREY_UF:NotifyPositionChanged(settingsKey, offsetX, offsetY)
                        end
                    end
                end)
            end
        end)

        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            self._isMoving = false
            self:SetScript("OnUpdate", nil)


            local selfX, selfY = self:GetCenter()
            local parentX, parentY = UIParent:GetCenter()
            if selfX and selfY and parentX and parentY then
                local offsetX = math.floor(selfX - parentX + 0.5)
                local offsetY = math.floor(selfY - parentY + 0.5)


                local settingsKey = self.unitKey
                if self.unitKey:match("^boss%d+$") then
                    settingsKey = "boss"
                end
                local settings = GetUnitSettings(settingsKey)
                if settings then
                    settings.offsetX = offsetX
                    settings.offsetY = offsetY


                    PREY_UF:NotifyPositionChanged(settingsKey, offsetX, offsetY)
                end
            end
        end)


        local isBossFrame = frame.unit and frame.unit:match("^boss%d$")
        if not isBossFrame then
            frame:EnableKeyboard(true)
        end
        frame:SetScript("OnKeyDown", function(self, key)
            if not PREY_UF.editModeActive then return end

            local deltaX, deltaY = 0, 0
            if key == "LEFT" then deltaX = -1
            elseif key == "RIGHT" then deltaX = 1
            elseif key == "UP" then deltaY = 1
            elseif key == "DOWN" then deltaY = -1
            else return end

            local settingsKey = self.unitKey
            if settingsKey and settingsKey:match("^boss%d+$") then
                settingsKey = "boss"
            end
            local settings = GetUnitSettings(settingsKey)


            local isAnchored = settings and settings.anchorTo and settings.anchorTo ~= "disabled"
            if isAnchored and (settingsKey == "player" or settingsKey == "target") then
                return
            end

            local shift = IsShiftKeyDown()
            local step = shift and 10 or 1

            if settings then
                settings.offsetX = (settings.offsetX or 0) + (deltaX * step)
                settings.offsetY = (settings.offsetY or 0) + (deltaY * step)
                self:ClearAllPoints()
                self:SetPoint("CENTER", UIParent, "CENTER", settings.offsetX, settings.offsetY)


                PREY_UF:NotifyPositionChanged(settingsKey, settings.offsetX, settings.offsetY)
            end
        end)


        frame:Show()


        self:ShowPreview(unitKey)
    end

    print("|cFFF87171PreyUI|r: Edit Mode |cff00ff00ENABLED|r - Drag frames to reposition.")
end

function PREY_UF:DisableEditMode()
    self.editModeActive = false


    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.ClearEditModeSelection then
        PREYCore:ClearEditModeSelection()
    end


    if self.exitEditModeBtn then
        self.exitEditModeBtn:Hide()
    end

    for unitKey, frame in pairs(self.frames) do

        if frame.editOverlay then
            frame.editOverlay:Hide()
        end


        frame:RegisterForDrag()

        local isBossFrame = frame.unit and frame.unit:match("^boss%d$")
        if not isBossFrame then
            frame:EnableKeyboard(false)
        end
        frame:SetScript("OnMouseDown", nil)
        frame:SetScript("OnDragStart", nil)
        frame:SetScript("OnDragStop", nil)
        frame:SetScript("OnKeyDown", nil)


        self.previewMode[unitKey] = false


        if not InCombatLockdown() then
            local unit = frame.unit
            if unit == "target" then
                RegisterStateDriver(frame, "visibility", "[@target,exists] show; hide")
            elseif unit == "focus" then
                RegisterStateDriver(frame, "visibility", "[@focus,exists] show; hide")
            elseif unit == "pet" then
                RegisterStateDriver(frame, "visibility", "[@pet,exists] show; hide")
            elseif unit == "targettarget" then
                RegisterStateDriver(frame, "visibility", "[@targettarget,exists] show; hide")
            elseif unit and unit:match("^boss%d$") then
                local bossNum = unit:match("^boss(%d)$")
                if bossNum then
                    RegisterStateDriver(frame, "visibility", "[@boss" .. bossNum .. ",exists] show; hide")
                end
            end
        end


        if UnitExists(frame.unit) or unitKey == "player" then
            UpdateFrame(frame)
        end
    end

    print("|cFFF87171PreyUI|r: Edit Mode |cffff0000DISABLED|r - Positions saved.")
end

function PREY_UF:ToggleEditMode()
    if self.editModeActive then
        self:DisableEditMode()
    else
        self:EnableEditMode()
    end
end


local function KillBlizzardFrame(frame, allowInEditMode)
    if not frame then return end


    pcall(function()

        frame:UnregisterAllEvents()
    end)

    pcall(function()


        frame:SetAlpha(0)
    end)

    pcall(function()
        frame:EnableMouse(false)
    end)

    pcall(function()

        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10000, 10000)
    end)


    if not InCombatLockdown() then
        pcall(RegisterStateDriver, frame, "visibility", "hide")
    end
end

local function KillBlizzardChildFrame(frame)
    if not frame then return end

    pcall(function()
        if frame.UnregisterAllEvents then
            frame:UnregisterAllEvents()
        end
    end)


    pcall(function() frame:Hide() end)

    pcall(function()
        if frame.EnableMouse then
            frame:EnableMouse(false)
        end
    end)


    pcall(function() frame:SetAlpha(0) end)

    pcall(function()
        frame:SetScript("OnShow", function(f)
            pcall(function() f:Hide() end)
            pcall(function() f:SetAlpha(0) end)
        end)
    end)
end

local function HideBlizzardTargetVisuals()
    if not TargetFrame then return end


    local function SafeGetChild(parent, childName)
        local ok, child = pcall(function() return parent[childName] end)
        return ok and child or nil
    end


    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "TargetFrameContainer"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "TargetFrameContent"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "healthbar"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "manabar"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "powerBarAlt"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "overAbsorbGlow"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "overHealAbsorbGlow"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "totalAbsorbBar"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "tempMaxHealthLossBar"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "myHealPredictionBar"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "otherHealPredictionBar"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "name"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "portrait"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "threatIndicator"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "threatNumericIndicator"))


    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "BuffFrame"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "DebuffFrame"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "buffsContainer"))
    KillBlizzardChildFrame(SafeGetChild(TargetFrame, "debuffsContainer"))


    for i = 1, 40 do
        local buffFrame = rawget(_G, "TargetFrameBuff"..i)
        local debuffFrame = rawget(_G, "TargetFrameDebuff"..i)
        KillBlizzardChildFrame(buffFrame)
        KillBlizzardChildFrame(debuffFrame)
    end


    local auraPools = SafeGetChild(TargetFrame, "auraPools")
    if auraPools and auraPools.ReleaseAll then
        pcall(auraPools.ReleaseAll, auraPools)
    end


    KillBlizzardFrame(TargetFrame)
end

local function HideBlizzardFocusVisuals()
    if not FocusFrame then return end


    local function SafeGetChild(parent, childName)
        local ok, child = pcall(function() return parent[childName] end)
        return ok and child or nil
    end

    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "TargetFrameContainer"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "TargetFrameContent"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "healthbar"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "manabar"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "powerBarAlt"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "overAbsorbGlow"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "overHealAbsorbGlow"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "totalAbsorbBar"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "tempMaxHealthLossBar"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "myHealPredictionBar"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "otherHealPredictionBar"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "name"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "portrait"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "threatIndicator"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "threatNumericIndicator"))


    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "BuffFrame"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "DebuffFrame"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "buffsContainer"))
    KillBlizzardChildFrame(SafeGetChild(FocusFrame, "debuffsContainer"))


    for i = 1, 40 do
        local buffFrame = rawget(_G, "FocusFrameBuff"..i)
        local debuffFrame = rawget(_G, "FocusFrameDebuff"..i)
        KillBlizzardChildFrame(buffFrame)
        KillBlizzardChildFrame(debuffFrame)
    end


    local auraPools = SafeGetChild(FocusFrame, "auraPools")
    if auraPools and auraPools.ReleaseAll then
        pcall(auraPools.ReleaseAll, auraPools)
    end


    KillBlizzardFrame(FocusFrame)
end

function PREY_UF:HideBlizzardFrames()
    local db = GetDB()
    if not db or not db.enabled then return end


    if db.player and db.player.enabled then
        KillBlizzardFrame(PlayerFrame)
    end


    if db.player and db.player.castbar and db.player.castbar.enabled then
        if PlayerCastingBarFrame then
            PlayerCastingBarFrame:SetAlpha(0)
            PlayerCastingBarFrame:SetScale(0.0001)
            PlayerCastingBarFrame:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", -10000, 10000)
            PlayerCastingBarFrame:UnregisterAllEvents()


            if not PlayerCastingBarFrame._preyShowHooked then
                PlayerCastingBarFrame._preyShowHooked = true
                hooksecurefunc(PlayerCastingBarFrame, "Show", function(self)
                    pcall(self.Hide, self)
                end)
            end
        end

        if PetCastingBarFrame then
            PetCastingBarFrame:SetAlpha(0)
            PetCastingBarFrame:SetScale(0.0001)
            PetCastingBarFrame:UnregisterAllEvents()

        end
    end


    local targetEnabled = db.target and (db.target.enabled == true or db.target.enabled == nil)
    if targetEnabled then
        HideBlizzardTargetVisuals()
    end


    if db.targettarget and db.targettarget.enabled then
        KillBlizzardFrame(TargetFrameToT)
    end


    if db.pet and db.pet.enabled then
        KillBlizzardFrame(PetFrame)
    end


    HideBlizzardFocusVisuals()


    if db.boss and db.boss.enabled then
        for i = 1, 5 do
            local bf = rawget(_G, "Boss" .. i .. "TargetFrame")
            KillBlizzardFrame(bf, true)
        end


        if BossTargetFrameContainer and not BossTargetFrameContainer._preyEditModeFixed then

            if BossTargetFrameContainer.GetScaledSelectionSides then
                local originalGetScaledSelectionSides = BossTargetFrameContainer.GetScaledSelectionSides
                BossTargetFrameContainer.GetScaledSelectionSides = function(self)
                    local left, bottom, width, height = self:GetRect()
                    if left == nil then

                        return -10000, -9999, 10000, 10001
                    end
                    return originalGetScaledSelectionSides(self)
                end
            end


            BossTargetFrameContainer:SetSize(1, 1)
            if not BossTargetFrameContainer:GetPoint() then
                BossTargetFrameContainer:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            end

            BossTargetFrameContainer._preyEditModeFixed = true
        end
    end
end


function PREY_UF:Initialize()

    if InCombatLockdown() then
        PREY_UF.pendingInitialize = true
        return
    end

    local db = GetDB()
    if not db or not db.enabled then return end


    if PREY_Castbar then
        PREY_Castbar:SetHelpers({
            GetUnitSettings = GetUnitSettings,
            Scale = Scale,
            GetFontPath = GetFontPath,
            GetFontOutline = GetFontOutline,
            GetTexturePath = GetTexturePath,
            GetUnitClassColor = GetUnitClassColor,
            TruncateName = TruncateName,
            GetGeneralSettings = GetGeneralSettings,
            GetDB = GetDB,
        })
        PREY_Castbar:SetUnitFramesModule(self)
        PREY_Castbar.castbars = self.castbars
    end


    self:HideBlizzardFrames()


    if db.player and db.player.enabled then
        self.frames.player = CreateUnitFrame("player", "player")

        if db.player.castbar and db.player.castbar.enabled then
            self.castbars.player = CreateCastbar(self.frames.player, "player", "player")
        end

        SetupAuraTracking(self.frames.player)
    end


    local targetEnabled = db.target and (db.target.enabled == true or db.target.enabled == nil)
    if targetEnabled then
        self.frames.target = CreateUnitFrame("target", "target")

        if db.target.castbar and db.target.castbar.enabled then
            self.castbars.target = CreateCastbar(self.frames.target, "target", "target")
        end

        SetupAuraTracking(self.frames.target)
    end


    if db.targettarget and db.targettarget.enabled then
        self.frames.targettarget = CreateUnitFrame("targettarget", "targettarget")

        if db.targettarget.castbar and db.targettarget.castbar.enabled then
            self.castbars.targettarget = CreateCastbar(self.frames.targettarget, "targettarget", "targettarget")
        end

        SetupAuraTracking(self.frames.targettarget)
    end


    if db.pet and db.pet.enabled then
        self.frames.pet = CreateUnitFrame("pet", "pet")

        if db.pet.castbar and db.pet.castbar.enabled then
            self.castbars.pet = CreateCastbar(self.frames.pet, "pet", "pet")
        end

        SetupAuraTracking(self.frames.pet)
    end


    if db.focus and db.focus.enabled then
        self.frames.focus = CreateUnitFrame("focus", "focus")

        if db.focus.castbar and db.focus.castbar.enabled then
            self.castbars.focus = CreateCastbar(self.frames.focus, "focus", "focus")
        end

        SetupAuraTracking(self.frames.focus)
    end


    if db.boss and db.boss.enabled then
        local spacing = db.boss.spacing or 40
        for i = 1, 5 do
            local bossUnit = "boss" .. i
            local bossKey = "boss" .. i

            self.frames[bossKey] = CreateBossFrame(bossUnit, bossKey, i)


            if self.frames[bossKey] and i > 1 then
                local prevFrame = self.frames["boss" .. (i - 1)]
                if prevFrame then
                    self.frames[bossKey]:ClearAllPoints()
                    self.frames[bossKey]:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
                end
            end


            if self.frames[bossKey] and db.boss.castbar and db.boss.castbar.enabled then
                self.castbars[bossKey] = CreateBossCastbar(self.frames[bossKey], bossUnit, i)
            end


            SetupAuraTracking(self.frames[bossKey])
        end
    end


    C_Timer.After(1.5, function() self:RefreshAll() end)


end


function PREY_UF:HookBlizzardEditMode()
    if not EditModeManagerFrame then return end
    if self._blizzEditModeHooked then return end
    self._blizzEditModeHooked = true


    self.triggeredByBlizzEditMode = false

    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
        if InCombatLockdown() then return end
        if self.editModeActive then return end
        self.triggeredByBlizzEditMode = true
        self:EnableEditMode()
    end)

    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        if InCombatLockdown() then return end
        if not self.editModeActive then return end
        if not self.triggeredByBlizzEditMode then return end
        self.triggeredByBlizzEditMode = false
        self:DisableEditMode()
    end)
end


function PREY_UF:HideBlizzardSelectionFrames()
    local function HideSelection(parent, unitKey)
        if not parent or not parent.Selection then return end

        local db = GetDB()
        if not db or not db[unitKey] or not db[unitKey].enabled then return end

        parent.Selection:Hide()


        if not parent.Selection._preyHooked then
            parent.Selection._preyHooked = true
            parent.Selection:HookScript("OnShow", function(self)
                local db = GetDB()
                if db and db[unitKey] and db[unitKey].enabled then
                    self:Hide()
                end
            end)
        end
    end

    HideSelection(PlayerFrame, "player")
    HideSelection(TargetFrame, "target")
    HideSelection(FocusFrame, "focus")
    HideSelection(PetFrame, "pet")
    HideSelection(TargetFrameToT, "targettarget")

end


function PREY_UF:RegisterWithClique()

    local _, cliqueLoaded = C_AddOns.IsAddOnLoaded("Clique")
    if not cliqueLoaded then return end


    _G.ClickCastFrames = _G.ClickCastFrames or {}


    for unitKey, frame in pairs(self.frames) do
        if frame and frame.GetName then
            _G.ClickCastFrames[frame] = true
        end
    end
end


local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then

        C_Timer.After(0.5, function()
            PREY_UF:Initialize()

            PREY_UF:HookBlizzardEditMode()

            C_Timer.After(0.5, function()
                PREY_UF:RegisterWithClique()
            end)
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then

        C_Timer.After(1.0, function()
            PREY_UF:RefreshAll()
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then

        if PREY_UF.pendingInitialize then
            PREY_UF.pendingInitialize = false
            PREY_UF:Initialize()
            PREY_UF:HookBlizzardEditMode()
            C_Timer.After(0.5, function()
                PREY_UF:RegisterWithClique()
            end)
        end
    end
end)


_G.PreyUI_RefreshUnitFrames = function()
    PREY_UF:RefreshAll()
end


_G.PreyUI_RefreshAuras = function(unitKey)
    if unitKey then

        if unitKey == "boss" then
            for i = 1, 5 do
                local bossKey = "boss" .. i
                local frame = PREY_UF.frames[bossKey]
                if frame then
                    lastAuraUpdate[bossKey] = 0
                    UpdateAuras(frame)
                end
            end
        else
            local frame = PREY_UF.frames[unitKey]
            if frame then
                lastAuraUpdate[unitKey] = 0
                UpdateAuras(frame)
            end
        end
    else

        for _, key in ipairs({"player", "target", "focus", "pet", "targettarget"}) do
            local frame = PREY_UF.frames[key]
            if frame then
                lastAuraUpdate[key] = 0
                UpdateAuras(frame)
            end
        end

        for i = 1, 5 do
            local bossKey = "boss" .. i
            local frame = PREY_UF.frames[bossKey]
            if frame then
                lastAuraUpdate[bossKey] = 0
                UpdateAuras(frame)
            end
        end
    end
end

_G.PreyUI_ShowUnitFramePreview = function(unitKey)
    PREY_UF:ShowPreview(unitKey)
end

_G.PreyUI_HideUnitFramePreview = function(unitKey)
    PREY_UF:HidePreview(unitKey)
end

_G.PreyUI_ShowAuraPreview = function(unitKey, auraType)
    PREY_UF:ShowAuraPreview(unitKey, auraType)
end

_G.PreyUI_HideAuraPreview = function(unitKey, auraType)
    PREY_UF:HideAuraPreview(unitKey, auraType)
end

_G.PreyUI_ToggleUnitFrameEditMode = function()
    PREY_UF:ToggleEditMode()
end


_G.PreyUI_RegisterEditModeSliders = function(unitKey, xSlider, ySlider)
    PREY_UF:RegisterEditModeSliders(unitKey, xSlider, ySlider)
end


_G.PreyUI_UnitFrames = PREY_UF.frames
_G.PreyUI_Castbars = PREY_UF.castbars


local function GetAnchorFrame(anchorType)
    if anchorType == "essential" then
        return rawget(_G, "EssentialCooldownViewer")
    elseif anchorType == "utility" then
        return rawget(_G, "UtilityCooldownViewer")
    elseif anchorType == "primary" then
        local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
        return PREYCore and PREYCore.powerBar
    elseif anchorType == "secondary" then
        local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
        return PREYCore and PREYCore.secondaryPowerBar
    end
    return nil
end


local function GetAnchorDimensions(anchorFrame, anchorType)
    if not anchorFrame then return nil end

    local width, height
    if anchorType == "essential" or anchorType == "utility" then

        width = anchorFrame.__cdmRow1Width or anchorFrame:GetWidth()
        height = anchorFrame.__cdmTotalHeight or anchorFrame:GetHeight()
    else

        width = anchorFrame:GetWidth()
        height = anchorFrame:GetHeight()
    end

    local centerX, centerY = anchorFrame:GetCenter()
    if not centerX or not centerY then return nil end

    return {
        width = width,
        height = height,
        centerX = centerX,
        centerY = centerY,
        top = centerY + (height / 2),
        left = centerX - (width / 2),
        right = centerX + (width / 2),
    }
end


_G.PreyUI_UpdateAnchoredUnitFrames = function()
    if InCombatLockdown() then return end
    local db = GetDB()
    if not db then return end

    local screenCenterX, screenCenterY = UIParent:GetCenter()
    if not screenCenterX or not screenCenterY then return end


    local playerSettings = db.player
    local playerAnchorType = playerSettings and playerSettings.anchorTo
    if playerAnchorType and playerAnchorType ~= "disabled" and PREY_UF.frames.player then
        local anchorFrame = GetAnchorFrame(playerAnchorType)
        if anchorFrame and anchorFrame:IsShown() then
            local anchor = GetAnchorDimensions(anchorFrame, playerAnchorType)
            if anchor then
                local frame = PREY_UF.frames.player
                local frameWidth = frame:GetWidth()
                local frameHeight = frame:GetHeight()
                local gap = Scale(playerSettings.anchorGap or 10)
                local yOffset = Scale(playerSettings.anchorYOffset or 0)


                local frameX = anchor.left - gap - (frameWidth / 2) - screenCenterX

                local frameY = (anchor.top - (frameHeight / 2) - screenCenterY) + yOffset

                frame:ClearAllPoints()
                frame:SetPoint("CENTER", UIParent, "CENTER", frameX, frameY)
            end
        else

            local frame = PREY_UF.frames.player
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER",
                Scale(playerSettings.offsetX or 0),
                Scale(playerSettings.offsetY or 0))
        end
    end


    local targetSettings = db.target
    local targetAnchorType = targetSettings and targetSettings.anchorTo
    if targetAnchorType and targetAnchorType ~= "disabled" and PREY_UF.frames.target then
        local anchorFrame = GetAnchorFrame(targetAnchorType)
        if anchorFrame and anchorFrame:IsShown() then
            local anchor = GetAnchorDimensions(anchorFrame, targetAnchorType)
            if anchor then
                local frame = PREY_UF.frames.target
                local frameWidth = frame:GetWidth()
                local frameHeight = frame:GetHeight()
                local gap = Scale(targetSettings.anchorGap or 10)
                local yOffset = Scale(targetSettings.anchorYOffset or 0)


                local frameX = anchor.right + gap + (frameWidth / 2) - screenCenterX

                local frameY = (anchor.top - (frameHeight / 2) - screenCenterY) + yOffset

                frame:ClearAllPoints()
                frame:SetPoint("CENTER", UIParent, "CENTER", frameX, frameY)
            end
        else

            local frame = PREY_UF.frames.target
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER",
                Scale(targetSettings.offsetX or 0),
                Scale(targetSettings.offsetY or 0))
        end
    end
end


_G.PreyUI_UpdateCDMAnchoredUnitFrames = _G.PreyUI_UpdateAnchoredUnitFrames


_G.PreyUI_UpdateLockedCastbarToEssential = function(forceUpdate)
    local db = GetDB()
    if not db or not db.player then return end

    local castDB = db.player.castbar
    if not castDB or castDB.anchor ~= "essential" then return end


    if _G.PreyUI_RefreshCastbar then
        _G.PreyUI_RefreshCastbar("player")
    end
end


_G.PreyUI_UpdateLockedCastbarToUtility = function(forceUpdate)
    local db = GetDB()
    if not db or not db.player then return end

    local castDB = db.player.castbar
    if not castDB or castDB.anchor ~= "utility" then return end


    if _G.PreyUI_RefreshCastbar then
        _G.PreyUI_RefreshCastbar("player")
    end
end


_G.PreyUI_UpdateLockedCastbarToFrame = function()
    local db = GetDB()
    if not db or not db.player then return end

    local castDB = db.player.castbar
    if not castDB or castDB.anchor ~= "unitframe" then return end


    if _G.PreyUI_RefreshCastbar then
        _G.PreyUI_RefreshCastbar("player")
    end
end

