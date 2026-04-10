local ADDON_NAME, ns = ...
local PREY = ns.PREY or {}
ns.PREY = PREY

local crosshairFrame, horizLine, vertLine, horizBorder, vertBorder


local rangeCheckFrame


local isOutOfRange = false
local rangeCheckElapsed = 0
local RANGE_CHECK_INTERVAL = 0.1


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.crosshair then
        return PREYCore.db.profile.crosshair
    end
    return nil
end


local MELEE_RANGE_ABILITIES = {

    96231,
    6552,
    1766,
    116705,
    183752,


    228478,
    263642,

    49143,
    55090,
    206930,

    100780,
    100784,
    107428,

    5221,
    3252,
    1822,
    22568,
    22570,

    33917,
    6807,
}

local function IsOutOfMeleeRange()

    if not UnitExists("target") then
        return false
    end


    if not UnitCanAttack("player", "target") then
        return false
    end


    if UnitIsDeadOrGhost("target") then
        return false
    end


    if IsActionInRange then


        for slot = 1, 180 do
            local actionType, id, subType = GetActionInfo(slot)

            if id and (actionType == "spell" or (actionType == "macro" and subType == "spell")) then
                for _, abilityID in ipairs(MELEE_RANGE_ABILITIES) do
                    if id == abilityID then
                        local inRange = IsActionInRange(slot)
                        if inRange == true then
                            return false
                        elseif inRange == false then
                            return true
                        end

                    end
                end
            end
        end
    end


    if IsSpellInRange then
        local attackInRange = IsSpellInRange("Attack", "target")
        if attackInRange == 1 then
            return false
        elseif attackInRange == 0 then
            return true
        end

    end


    if C_Spell and C_Spell.IsSpellInRange then
        for _, spellID in ipairs(MELEE_RANGE_ABILITIES) do
            local spellKnown = IsSpellKnown and IsSpellKnown(spellID)
            if spellKnown then
                local inRange = C_Spell.IsSpellInRange(spellID, "target")
                if inRange == true then
                    return false
                elseif inRange == false then
                    return true
                end

            end
        end
    end


    local inRange = CheckInteractDistance("target", 3)
    if inRange ~= nil then
        return not inRange
    end

    return false
end


local function ApplyCrosshairColor(settings, outOfRange)
    if not horizLine or not vertLine then return end

    local r, g, b, a

    if outOfRange and settings.changeColorOnRange then

        local oorColor = settings.outOfRangeColor or { 1, 0.2, 0.2, 1 }
        r = oorColor[1] or 1
        g = oorColor[2] or 0.2
        b = oorColor[3] or 0.2
        a = oorColor[4] or 1
    else

        r = settings.r or 1
        g = settings.g or 0.949
        b = settings.b or 0
        a = settings.a or 1
    end

    horizLine:SetColorTexture(r, g, b, a)
    vertLine:SetColorTexture(r, g, b, a)
end


local function OnRangeUpdate(self, elapsed)
    rangeCheckElapsed = rangeCheckElapsed + elapsed
    if rangeCheckElapsed < RANGE_CHECK_INTERVAL then return end
    rangeCheckElapsed = 0

    local settings = GetSettings()
    if not settings or not settings.enabled or not settings.changeColorOnRange then

        self:SetScript("OnUpdate", nil)
        return
    end

    local inCombat = InCombatLockdown()


    if settings.rangeColorInCombatOnly and not inCombat then

        if isOutOfRange then
            isOutOfRange = false
            ApplyCrosshairColor(settings, false)
        end

        if settings.hideUntilOutOfRange and crosshairFrame then
            crosshairFrame:Hide()
        end
        return
    end

    local newOutOfRange = IsOutOfMeleeRange()
    if newOutOfRange ~= isOutOfRange then
        isOutOfRange = newOutOfRange
        ApplyCrosshairColor(settings, isOutOfRange)
    end


    if settings.hideUntilOutOfRange and crosshairFrame then
        if inCombat and isOutOfRange then
            crosshairFrame:Show()
        else
            crosshairFrame:Hide()
        end
    end
end


local function UpdateRangeChecking()
    if not crosshairFrame then return end


    if not rangeCheckFrame then
        rangeCheckFrame = CreateFrame("Frame", "PreyUI_CrosshairRangeCheck", UIParent)
        rangeCheckFrame:SetSize(1, 1)
        rangeCheckFrame:SetPoint("CENTER")
        rangeCheckFrame:Show()
    end

    local settings = GetSettings()
    if settings and settings.enabled and settings.changeColorOnRange then

        rangeCheckElapsed = 0
        rangeCheckFrame:SetScript("OnUpdate", OnRangeUpdate)

        local inCombat = InCombatLockdown()


        if settings.rangeColorInCombatOnly and not inCombat then
            isOutOfRange = false
            ApplyCrosshairColor(settings, false)
        else
            isOutOfRange = IsOutOfMeleeRange()
            ApplyCrosshairColor(settings, isOutOfRange)
        end


        if settings.hideUntilOutOfRange then
            if inCombat and isOutOfRange then
                crosshairFrame:Show()
            else
                crosshairFrame:Hide()
            end
        end
    else

        if rangeCheckFrame then
            rangeCheckFrame:SetScript("OnUpdate", nil)
        end
        isOutOfRange = false
    end
end


local function CreateCrosshair()
    if crosshairFrame then return end

    crosshairFrame = CreateFrame("Frame", "PreyUI_Crosshair", UIParent)
    crosshairFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    crosshairFrame:SetSize(1, 1)
    crosshairFrame:SetFrameStrata("HIGH")


    horizBorder = crosshairFrame:CreateTexture(nil, "BACKGROUND")
    horizBorder:SetPoint("CENTER", crosshairFrame)
    horizBorder:SetColorTexture(0, 0, 0, 1)

    vertBorder = crosshairFrame:CreateTexture(nil, "BACKGROUND")
    vertBorder:SetPoint("CENTER", crosshairFrame)
    vertBorder:SetColorTexture(0, 0, 0, 1)


    horizLine = crosshairFrame:CreateTexture(nil, "ARTWORK")
    horizLine:SetPoint("CENTER", crosshairFrame)
    horizLine:SetColorTexture(1, 0.949, 0, 1)

    vertLine = crosshairFrame:CreateTexture(nil, "ARTWORK")
    vertLine:SetPoint("CENTER", crosshairFrame)
    vertLine:SetColorTexture(1, 0.949, 0, 1)

    crosshairFrame:Hide()
end


local function UpdateCrosshair()
    if not crosshairFrame then
        CreateCrosshair()
    end

    local settings = GetSettings()
    if not settings then
        crosshairFrame:Hide()
        return
    end


    local enabled = settings.enabled
    local size = settings.size or 12
    local thickness = settings.thickness or 3
    local borderSize = settings.borderSize or 2
    local offsetX = settings.offsetX or 0
    local offsetY = settings.offsetY or 0
    local borderR = settings.borderR or 0
    local borderG = settings.borderG or 0
    local borderB = settings.borderB or 0
    local borderA = settings.borderA or 1
    local strata = settings.strata or "HIGH"
    local onlyInCombat = settings.onlyInCombat


    crosshairFrame:SetFrameStrata(strata)
    crosshairFrame:ClearAllPoints()
    crosshairFrame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)


    horizBorder:SetSize((size * 2) + borderSize * 2, thickness + borderSize * 2)
    vertBorder:SetSize(thickness + borderSize * 2, (size * 2) + borderSize * 2)
    horizBorder:SetColorTexture(borderR, borderG, borderB, borderA)
    vertBorder:SetColorTexture(borderR, borderG, borderB, borderA)


    horizLine:SetSize(size * 2, thickness)
    vertLine:SetSize(thickness, size * 2)


    if settings.changeColorOnRange then
        isOutOfRange = IsOutOfMeleeRange()
        ApplyCrosshairColor(settings, isOutOfRange)
    else

        local r = settings.r or 1
        local g = settings.g or 0.949
        local b = settings.b or 0
        local a = settings.a or 1
        horizLine:SetColorTexture(r, g, b, a)
        vertLine:SetColorTexture(r, g, b, a)
    end


    if not enabled then
        crosshairFrame:Hide()
        crosshairFrame:SetScript("OnUpdate", nil)
    elseif onlyInCombat then
        crosshairFrame:SetShown(InCombatLockdown())
    else
        crosshairFrame:Show()
    end


    UpdateRangeChecking()
end


local function OnCombatStart()
    local settings = GetSettings()
    if settings and settings.enabled and settings.onlyInCombat then
        if crosshairFrame then
            crosshairFrame:Show()
            UpdateRangeChecking()
        end
    end
end

local function OnCombatEnd()
    local settings = GetSettings()
    if settings and settings.onlyInCombat then
        if crosshairFrame then
            crosshairFrame:Hide()
            crosshairFrame:SetScript("OnUpdate", nil)
        end
    end
end


local function OnTargetChanged()
    local settings = GetSettings()
    if settings and settings.enabled and settings.changeColorOnRange then

        isOutOfRange = IsOutOfMeleeRange()
        ApplyCrosshairColor(settings, isOutOfRange)
    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
            CreateCrosshair()
            UpdateCrosshair()
        end)
    elseif event == "PLAYER_REGEN_DISABLED" then
        OnCombatStart()
    elseif event == "PLAYER_REGEN_ENABLED" then
        OnCombatEnd()
    elseif event == "PLAYER_TARGET_CHANGED" then
        OnTargetChanged()
    end
end)


_G.PreyUI_RefreshCrosshair = UpdateCrosshair

PREY.Crosshair = {
    Update = UpdateCrosshair,
    Create = CreateCrosshair,
}

