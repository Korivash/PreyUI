local ADDON_NAME, ns = ...
local PREY = ns.PREY or {}
ns.PREY = PREY


local UIParent = UIParent
local CreateFrame = CreateFrame
local GetScaledCursorPosition = GetScaledCursorPosition
local InCombatLockdown = InCombatLockdown
local UnitClass = UnitClass
local C_ClassColor = C_ClassColor
local C_Spell = C_Spell
local GetTime = GetTime
local pcall = pcall
local type = type


local ringFrame, ringTexture, reticleTexture, gcdCooldown


local lastCombatState = nil
local cachedSettings = nil
local cursorUpdateEnabled = false


local cachedOffsetX, cachedOffsetY = 0, 0
local lastCursorX, lastCursorY = 0, 0


local EnableCursorUpdate, DisableCursorUpdate


local GCD_SPELL_ID = 61304


local RING_TEXTURES = {
    thin     = "Interface\\AddOns\\PreyUI\\assets\\cursor\\prey_ring_thin.png",
    standard = "Interface\\AddOns\\PreyUI\\assets\\cursor\\prey_ring_standard.png",
    thick    = "Interface\\AddOns\\PreyUI\\assets\\cursor\\prey_ring_thick.png",
    solid    = "Interface\\AddOns\\PreyUI\\assets\\cursor\\prey_ring_solid.png",
}


local RETICLE_OPTIONS = {
    dot     = { path = "Interface\\AddOns\\PreyUI\\assets\\cursor\\prey_reticle_dot.tga", isAtlas = false },
    cross   = { path = "uitools-icon-plus", isAtlas = true },
    chevron = { path = "uitools-icon-chevron-down", isAtlas = true },
    diamond = { path = "UF-SoulShard-FX-FrameGlow", isAtlas = true },
}


local function GetSettings()
    if cachedSettings then return cachedSettings end
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.reticle then
        cachedSettings = PREYCore.db.profile.reticle
        return cachedSettings
    end
    return nil
end


local function InvalidateCache()
    cachedSettings = nil
end


local function CacheOffsets()
    local settings = GetSettings()
    cachedOffsetX = settings and settings.offsetX or 0
    cachedOffsetY = settings and settings.offsetY or 0
end


local function GetRingColor()
    local settings = GetSettings()
    if not settings then return 1, 1, 1, 1 end

    if settings.useClassColor then
        local _, classFile = UnitClass("player")
        local color = C_ClassColor.GetClassColor(classFile)
        if color then
            return color.r, color.g, color.b, 1
        end
        return 1, 1, 1, 1
    else
        local c = settings.customColor or {0.820, 0.180, 0.220, 1}
        return c[1] or 0.290, c[2] or 0.620, c[3] or 1.0, c[4] or 1
    end
end


local function GetCurrentAlpha()
    local settings = GetSettings()
    if not settings then return 1 end

    if InCombatLockdown() then
        return settings.inCombatAlpha or 0.8
    else
        return settings.outCombatAlpha or 0.3
    end
end


local function IsCooldownActive(start, duration)
    if not start or not duration then return false end

    local ok, result = pcall(function()
        if duration == 0 or start == 0 then
            return false
        end
        return true
    end)

    if not ok then

        return true
    end

    return result and true or false
end


local function ReadSpellCooldown(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local a, b, c, d = C_Spell.GetSpellCooldown(spellID)
        if type(a) == "table" then

            local t = a
            local start = t.startTime or t.start
            local duration = t.duration
            local modRate = t.modRate
            return start, duration, modRate
        else

            return a, b, d
        end
    end

    if GetSpellCooldown then
        local s, d = GetSpellCooldown(spellID)
        return s, d, nil
    end
    return nil, nil, nil
end


local function TrySetCooldown(frame, start, duration, modRate)
    if not frame or not start or not duration then
        return false
    end

    local ok = pcall(function()
        local numericStart = start + 0
        local numericDuration = duration + 0
        local numericModRate = modRate

        if numericModRate ~= nil then
            numericModRate = numericModRate + 0
            frame:SetCooldown(numericStart, numericDuration, numericModRate)
        else
            frame:SetCooldown(numericStart, numericDuration)
        end
    end)

    return ok
end


local function CreateReticle()
    if ringFrame then return end


    ringFrame = CreateFrame("Frame", "PreyUI_Reticle", UIParent)
    ringFrame:SetFrameStrata("TOOLTIP")
    ringFrame:EnableMouse(false)
    ringFrame:SetSize(80, 80)


    ringTexture = ringFrame:CreateTexture(nil, "BACKGROUND")
    ringTexture:SetAllPoints()


    gcdCooldown = CreateFrame("Cooldown", nil, ringFrame, "CooldownFrameTemplate")
    gcdCooldown:SetAllPoints()
    gcdCooldown:EnableMouse(false)
    gcdCooldown:SetDrawSwipe(true)
    gcdCooldown:SetDrawEdge(false)
    gcdCooldown:SetHideCountdownNumbers(true)
    if gcdCooldown.SetDrawBling then gcdCooldown:SetDrawBling(false) end
    if gcdCooldown.SetUseCircularEdge then gcdCooldown:SetUseCircularEdge(true) end
    gcdCooldown:SetFrameLevel(ringFrame:GetFrameLevel() + 2)


    reticleTexture = ringFrame:CreateTexture(nil, "OVERLAY")
    reticleTexture:SetPoint("CENTER", ringFrame, "CENTER", 0, 0)

    ringFrame:Hide()
end


local function UpdateReticleDot()
    if not reticleTexture then return end

    local settings = GetSettings()
    if not settings then return end

    local style = settings.reticleStyle or "dot"
    local size = settings.reticleSize or 10
    local r, g, b, a = GetRingColor()

    local reticleInfo = RETICLE_OPTIONS[style] or RETICLE_OPTIONS.dot

    if reticleInfo.isAtlas then
        reticleTexture:SetAtlas(reticleInfo.path)
    else
        reticleTexture:SetTexture(reticleInfo.path)
    end

    reticleTexture:SetSize(size, size)
    reticleTexture:SetVertexColor(r, g, b, a)
end


local function UpdateRingAppearance()
    if not ringFrame or not ringTexture then return end

    local settings = GetSettings()
    if not settings then return end

    local style = settings.ringStyle or "standard"
    local size = settings.ringSize or 40
    local r, g, b, a = GetRingColor()


    local texturePath = RING_TEXTURES[style] or RING_TEXTURES.standard
    ringTexture:SetTexture(texturePath)
    ringTexture:SetVertexColor(r, g, b, 1)


    local baseAlpha = GetCurrentAlpha()
    local ringAlpha = baseAlpha


    if gcdCooldown and gcdCooldown:IsShown() and settings.gcdEnabled then
        local fadeAmount = settings.gcdFadeRing or 0.35
        ringAlpha = baseAlpha * (1 - fadeAmount)
    end

    ringTexture:SetAlpha(ringAlpha)


    ringFrame:SetSize(size, size)


    if gcdCooldown and settings.gcdEnabled then
        if gcdCooldown.SetSwipeTexture then
            gcdCooldown:SetSwipeTexture(texturePath)
        end
        gcdCooldown:SetSwipeColor(r, g, b, baseAlpha)
        if gcdCooldown.SetReverse then
            gcdCooldown:SetReverse(settings.gcdReverse or false)
        end
    end
end


local function UpdateGCDCooldown()
    if not gcdCooldown then return end

    local settings = GetSettings()
    if not settings or not settings.gcdEnabled then
        gcdCooldown:Hide()
        UpdateRingAppearance()
        return
    end

    local start, duration, modRate = ReadSpellCooldown(GCD_SPELL_ID)

    if IsCooldownActive(start, duration) then
        if TrySetCooldown(gcdCooldown, start, duration, modRate) then
            gcdCooldown:Show()
        else
            gcdCooldown:Hide()
        end
    else
        gcdCooldown:Hide()
    end

    UpdateRingAppearance()
end


local function UpdateVisibility(forcedInCombat)
    if not ringFrame then return end

    local settings = GetSettings()
    if not settings or not settings.enabled then
        ringFrame:Hide()
        DisableCursorUpdate()
        return
    end


    local inCombat = (forcedInCombat ~= nil) and forcedInCombat or InCombatLockdown()


    if settings.hideOutOfCombat and not inCombat then
        ringFrame:Hide()
        DisableCursorUpdate()
        return
    end

    ringFrame:Show()
    EnableCursorUpdate()
end


local function UpdateReticle()
    if not ringFrame then
        CreateReticle()
    end

    CacheOffsets()
    UpdateVisibility()
    UpdateReticleDot()
    UpdateRingAppearance()
    UpdateGCDCooldown()
end


local function OnCombatStart()
    UpdateVisibility(true)
    UpdateRingAppearance()
    UpdateGCDCooldown()
end

local function OnCombatEnd()
    UpdateVisibility(false)
    UpdateRingAppearance()
end


local function SetupRightClickHide()
    WorldFrame:HookScript("OnMouseDown", function(_, button)
        if button == "RightButton" then
            local settings = GetSettings()
            if settings and settings.hideOnRightClick and ringFrame then
                ringFrame:Hide()
            end
        end
    end)

    WorldFrame:HookScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            local settings = GetSettings()
            if settings and settings.enabled and settings.hideOnRightClick and ringFrame then

                if not settings.hideOutOfCombat or InCombatLockdown() then
                    ringFrame:Show()
                end
            end
        end
    end)
end


local function CursorOnUpdate(self, elapsed)
    local x, y = GetScaledCursorPosition()


    local dx, dy = x - lastCursorX, y - lastCursorY
    if dx > -0.5 and dx < 0.5 and dy > -0.5 and dy < 0.5 then
        return
    end
    lastCursorX, lastCursorY = x, y


    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x + cachedOffsetX, y + cachedOffsetY)
end

EnableCursorUpdate = function()
    if cursorUpdateEnabled or not ringFrame then return end
    cursorUpdateEnabled = true
    ringFrame:SetScript("OnUpdate", CursorOnUpdate)
end

DisableCursorUpdate = function()
    if not cursorUpdateEnabled or not ringFrame then return end
    cursorUpdateEnabled = false
    ringFrame:SetScript("OnUpdate", nil)
end

local function SetupCursorFollowing()

    local settings = GetSettings()
    if settings and settings.enabled then
        EnableCursorUpdate()
    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

eventFrame:SetScript("OnEvent", function(self, event, unit, _, spellID)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
            CreateReticle()
            UpdateReticle()
            SetupCursorFollowing()
            SetupRightClickHide()
            lastCombatState = InCombatLockdown()
        end)

    elseif event == "PLAYER_ENTERING_WORLD" then
        UpdateReticle()

    elseif event == "PLAYER_REGEN_DISABLED" then
        OnCombatStart()

    elseif event == "PLAYER_REGEN_ENABLED" then
        OnCombatEnd()

    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
        UpdateGCDCooldown()

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
        local settings = GetSettings()
        if not settings or not settings.gcdEnabled then
            if gcdCooldown then gcdCooldown:Hide() end
            return
        end


        if spellID then
            local start, duration, modRate = ReadSpellCooldown(spellID)
            if IsCooldownActive(start, duration) then
                if gcdCooldown then
                    if TrySetCooldown(gcdCooldown, start, duration, modRate) then
                        gcdCooldown:Show()
                    else
                        gcdCooldown:Hide()
                    end
                    UpdateRingAppearance()
                end
            else
                UpdateGCDCooldown()
            end
        else
            UpdateGCDCooldown()
        end
    end
end)


_G.PreyUI_RefreshReticle = function()
    InvalidateCache()
    UpdateReticle()
end


PREY.Reticle = {
    Update = UpdateReticle,
    Create = CreateReticle,
    Refresh = UpdateReticle,
    InvalidateCache = InvalidateCache,
}
