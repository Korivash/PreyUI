local ADDON_NAME, ns = ...
local PREY = ns.PREY or {}
ns.PREY = PREY

local LSM = LibStub("LibSharedMedia-3.0")
local IsSecretValue = function(v) return ns.Utils and ns.Utils.IsSecretValue and ns.Utils.IsSecretValue(v) or false end


local VIGOR_SPELL_ID = 372608
local SECOND_WIND_SPELL_ID = 425782
local WHIRLING_SURGE_SPELL_ID = 361584


local skyridingFrame
local vigorBar, vigorBackground, rechargeOverlay, shadowTexture
local flashTexture, flashAnim
local segmentMarkers = {}
local secondWindPips = {}
local vigorText, speedText
local secondWindText, secondWindMiniBar
local swBackground, swBorder, swRechargeOverlay
local swSegmentMarkers = {}
local abilityIcon, abilityIconCooldown


local lastVigorCharges = -1
local lastMaxCharges = -1
local lastSecondWind = -1
local lastSecondWindMax = -1
local isGliding = false
local canGlide = false
local forwardSpeed = 0
local groundedTime = 0
local fadeStart = 0
local fadeStartAlpha = 1
local fadeTargetAlpha = 1
local inCombat = false


local targetBarValue = 0
local currentBarValue = 0
local swTargetValue = 0
local swCurrentValue = 0
local swMaxCharges = 0
local LERP_SPEED = 8


local UPDATE_THROTTLE = 0.05
local elapsed = 0


local DOT_TEXTURE = "Interface\\AddOns\\PreyUI\\assets\\cursor\\prey_reticle_dot"


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.skyriding then
        return PREYCore.db.profile.skyriding
    end
    return nil
end

local function Scale(x)
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.Scale then
        return PREYCore:Scale(x)
    end
    return x
end


local function GetVigorInfo()
    local data = C_Spell.GetSpellCharges(VIGOR_SPELL_ID)
    if not data then return 0, 6, 0, 0, 1 end


    if IsSecretValue(data.maxCharges) then
        return 0, 6, 0, 0, 1
    end

    return data.currentCharges or 0,
           data.maxCharges or 6,
           data.cooldownStartTime or 0,
           data.cooldownDuration or 0,
           data.chargeModRate or 1
end

local function GetSecondWindInfo()
    local data = C_Spell.GetSpellCharges(SECOND_WIND_SPELL_ID)
    if not data then return 0, 0, 0, 0, 1 end


    if IsSecretValue(data.maxCharges) then
        return 0, 0, 0, 0, 1
    end

    return data.currentCharges or 0,
           data.maxCharges or 0,
           data.cooldownStartTime or 0,
           data.cooldownDuration or 0,
           data.chargeModRate or 1
end

local function GetGlidingInfo()
    local gliding, canGlideNow, speed = C_PlayerInfo.GetGlidingInfo()
    return gliding or false, canGlideNow or false, speed or 0
end


local function GetFontPath()
    local PREY = _G.PreyUI
    if PREY and PREY.GetGlobalFont then
        return PREY:GetGlobalFont()
    end

    return [[Interface\AddOns\PreyUI\assets\Prey.ttf]]
end


local function ApplyCooldownFont(cooldown, fontSize)
    if not cooldown then return end
    local fontPath = GetFontPath()


    if cooldown.text then
        cooldown.text:SetFont(fontPath, fontSize, "OUTLINE")
    end


    local ok, regions = pcall(function() return { cooldown:GetRegions() } end)
    if ok and regions then
        for _, region in ipairs(regions) do
            if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                region:SetFont(fontPath, fontSize, "OUTLINE")
            end
        end
    end
end


local function CreateSkyridingFrame()
    if skyridingFrame then return end

    local settings = GetSettings()
    local width = settings and settings.width or 250
    local height = settings and settings.vigorHeight or 12


    skyridingFrame = CreateFrame("Frame", "PreyUI_Skyriding", UIParent)
    skyridingFrame:SetSize(width, height)
    skyridingFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    skyridingFrame:SetFrameStrata("MEDIUM")
    skyridingFrame:SetClampedToScreen(true)


    shadowTexture = skyridingFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
    shadowTexture:SetTexture("Interface\\Buttons\\WHITE8x8")
    shadowTexture:SetPoint("TOPLEFT", skyridingFrame, "BOTTOMLEFT", 2, 0)
    shadowTexture:SetPoint("BOTTOMRIGHT", skyridingFrame, "BOTTOMRIGHT", -2, -3)
    shadowTexture:SetGradient("VERTICAL",
        CreateColor(0, 0, 0, 0),
        CreateColor(0, 0, 0, 0.5)
    )


    vigorBackground = skyridingFrame:CreateTexture(nil, "BACKGROUND")
    vigorBackground:SetAllPoints(skyridingFrame)
    vigorBackground:SetColorTexture(0.1, 0.1, 0.1, 0.8)


    vigorBar = CreateFrame("StatusBar", nil, skyridingFrame)
    vigorBar:SetAllPoints(skyridingFrame)
    vigorBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    vigorBar:SetStatusBarColor(0.860, 0.220, 0.260, 1)
    vigorBar:SetMinMaxValues(0, 1)
    vigorBar:SetValue(0)


    rechargeOverlay = vigorBar:CreateTexture(nil, "OVERLAY")
    rechargeOverlay:SetTexture("Interface\\Buttons\\WHITE8x8")
    rechargeOverlay:SetVertexColor(0.4, 0.9, 1.0, 0.6)
    rechargeOverlay:SetHeight(height)
    rechargeOverlay:Hide()


    flashTexture = vigorBar:CreateTexture(nil, "OVERLAY", nil, 7)
    flashTexture:SetTexture("Interface\\Buttons\\WHITE8x8")
    flashTexture:SetBlendMode("ADD")
    flashTexture:SetVertexColor(1, 1, 1, 0)
    flashTexture:Hide()


    flashAnim = flashTexture:CreateAnimationGroup()
    local fadeIn = flashAnim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(0.5)
    fadeIn:SetDuration(0.08)
    fadeIn:SetOrder(1)
    local fadeOut = flashAnim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.5)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.25)
    fadeOut:SetOrder(2)
    flashAnim:SetScript("OnPlay", function() flashTexture:Show() end)
    flashAnim:SetScript("OnFinished", function() flashTexture:Hide() end)


    skyridingFrame.border = CreateFrame("Frame", nil, skyridingFrame, "BackdropTemplate")
    skyridingFrame.border:SetPoint("TOPLEFT", -1, 1)
    skyridingFrame.border:SetPoint("BOTTOMRIGHT", 1, -1)
    skyridingFrame.border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = Scale(1),
    })
    skyridingFrame.border:SetBackdropBorderColor(0, 0, 0, 1)
    if skyridingFrame.border.Center then skyridingFrame.border.Center:Hide() end


    vigorText = vigorBar:CreateFontString(nil, "OVERLAY")
    vigorText:SetFont(GetFontPath(), 11, "OUTLINE")
    vigorText:SetPoint("LEFT", vigorBar, "LEFT", 4, 0)
    vigorText:SetTextColor(1, 1, 1, 1)


    speedText = vigorBar:CreateFontString(nil, "OVERLAY")
    speedText:SetFont(GetFontPath(), 11, "OUTLINE")
    speedText:SetPoint("RIGHT", vigorBar, "RIGHT", -4, 0)
    speedText:SetTextColor(1, 1, 1, 1)


    secondWindText = skyridingFrame:CreateFontString(nil, "OVERLAY")
    secondWindText:SetFont(GetFontPath(), 10, "OUTLINE")
    secondWindText:SetPoint("TOP", skyridingFrame, "BOTTOM", 0, -2)
    secondWindText:SetTextColor(1, 0.8, 0.2, 1)
    secondWindText:Hide()


    for i = 1, 10 do
        local marker = vigorBar:CreateTexture(nil, "ARTWORK", nil, 3)
        marker:SetTexture("Interface\\Buttons\\WHITE8x8")
        marker:SetVertexColor(0, 0, 0, 0.5)
        marker:SetWidth(Scale(1))
        marker:SetHeight(height)
        marker:Hide()
        segmentMarkers[i] = marker
    end


    for i = 1, 5 do

        local glow = skyridingFrame:CreateTexture(nil, "ARTWORK", nil, -1)
        glow:SetTexture(DOT_TEXTURE)
        glow:SetBlendMode("ADD")
        glow:SetSize(14, 14)
        glow:SetVertexColor(1, 0.8, 0.2, 0.5)
        glow:Hide()


        local pip = skyridingFrame:CreateTexture(nil, "OVERLAY")
        pip:SetTexture(DOT_TEXTURE)
        pip:SetSize(6, 6)
        pip:Hide()

        pip.glow = glow
        secondWindPips[i] = pip
    end


    secondWindMiniBar = CreateFrame("StatusBar", nil, skyridingFrame)
    secondWindMiniBar:SetHeight(6)
    secondWindMiniBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    secondWindMiniBar:SetStatusBarColor(1, 0.8, 0.2, 1)
    secondWindMiniBar:SetMinMaxValues(0, 1)
    secondWindMiniBar:Hide()


    swBackground = secondWindMiniBar:CreateTexture(nil, "BACKGROUND")
    swBackground:SetAllPoints(secondWindMiniBar)
    swBackground:SetColorTexture(0.1, 0.1, 0.1, 0.8)


    swBorder = CreateFrame("Frame", nil, secondWindMiniBar, "BackdropTemplate")
    swBorder:SetPoint("TOPLEFT", -1, 1)
    swBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    swBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = Scale(1),
    })
    swBorder:SetBackdropBorderColor(0, 0, 0, 1)


    for i = 1, 5 do
        local marker = secondWindMiniBar:CreateTexture(nil, "ARTWORK", nil, 3)
        marker:SetTexture("Interface\\Buttons\\WHITE8x8")
        marker:SetVertexColor(0, 0, 0, 0.5)
        marker:SetWidth(Scale(1))
        marker:Hide()
        swSegmentMarkers[i] = marker
    end


    swRechargeOverlay = secondWindMiniBar:CreateTexture(nil, "OVERLAY")
    swRechargeOverlay:SetTexture("Interface\\Buttons\\WHITE8x8")
    swRechargeOverlay:SetVertexColor(1, 0.9, 0.4, 0.6)
    swRechargeOverlay:SetHeight(6)
    swRechargeOverlay:Hide()


    abilityIcon = CreateFrame("Frame", nil, skyridingFrame)
    abilityIcon:SetSize(height, height)
    abilityIcon:SetPoint("LEFT", skyridingFrame, "RIGHT", 2, 0)


    abilityIcon.texture = abilityIcon:CreateTexture(nil, "ARTWORK")
    abilityIcon.texture:SetAllPoints()
    local iconTexture = C_Spell.GetSpellTexture(WHIRLING_SURGE_SPELL_ID)
    abilityIcon.texture:SetTexture(iconTexture or 136116)
    abilityIcon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)


    abilityIcon.border = CreateFrame("Frame", nil, abilityIcon, "BackdropTemplate")
    abilityIcon.border:SetPoint("TOPLEFT", -1, 1)
    abilityIcon.border:SetPoint("BOTTOMRIGHT", 1, -1)
    abilityIcon.border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = Scale(1),
    })
    abilityIcon.border:SetBackdropBorderColor(0, 0, 0, 1)


    abilityIconCooldown = CreateFrame("Cooldown", nil, abilityIcon, "CooldownFrameTemplate")
    abilityIconCooldown:SetAllPoints(abilityIcon.texture)
    abilityIconCooldown:SetDrawEdge(true)
    abilityIconCooldown:SetHideCountdownNumbers(false)


    C_Timer.After(0, function()
        ApplyCooldownFont(abilityIconCooldown, 12)
    end)

    abilityIcon:Hide()


    skyridingFrame:SetMovable(true)
    skyridingFrame:EnableMouse(false)
    skyridingFrame:RegisterForDrag("LeftButton")
    skyridingFrame:SetScript("OnDragStart", function(self)
        local settings = GetSettings()
        if settings and not settings.locked then
            self:StartMoving()
        end
    end)
    skyridingFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local settings = GetSettings()
        if settings then
            local centerX, centerY = self:GetCenter()
            local uiCenterX, uiCenterY = UIParent:GetCenter()
            local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
            settings.offsetX = math.floor((centerX - uiCenterX) * scale + 0.5)
            settings.offsetY = math.floor((centerY - uiCenterY) * scale + 0.5)
        end
    end)

    skyridingFrame:Hide()
end


local function UpdateSegmentMarkers(maxCharges)
    local settings = GetSettings()
    if not settings or not skyridingFrame then return end

    local showSegments = settings.showSegments ~= false
    local barWidth = skyridingFrame:GetWidth()
    local barHeight = skyridingFrame:GetHeight()
    local segmentWidth = barWidth / maxCharges
    local thickness = Scale(settings.segmentThickness or 1)


    local barColor = settings.barColor or {0.860, 0.220, 0.260, 1}
    local softColor = {
        barColor[1] * 0.25,
        barColor[2] * 0.25,
        barColor[3] * 0.25,
        0.6
    }

    for i = 1, 10 do
        local marker = segmentMarkers[i]
        if showSegments and i < maxCharges then
            local xPos = i * segmentWidth
            marker:ClearAllPoints()
            marker:SetPoint("LEFT", vigorBar, "LEFT", Scale(xPos - (thickness / 2)), 0)
            marker:SetWidth(math.max(Scale(1), thickness))
            marker:SetHeight(barHeight)
            marker:SetVertexColor(softColor[1], softColor[2], softColor[3], softColor[4])
            marker:Show()
        else
            marker:Hide()
        end
    end
end


local function UpdateSecondWind()
    local settings = GetSettings()
    if not settings or not skyridingFrame then return end

    local mode = settings.secondWindMode or "PIPS"
    local current, max, _, _, _ = GetSecondWindInfo()


    local color
    if settings.useClassColorSecondWind then
        local _, class = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[class]
        if classColor then
            color = {classColor.r, classColor.g, classColor.b, 1}
        else
            color = settings.secondWindColor or {1, 0.8, 0.2, 1}
        end
    else
        color = settings.secondWindColor or {1, 0.8, 0.2, 1}
    end


    for i = 1, 5 do
        local pip = secondWindPips[i]
        pip:Hide()
        if pip.glow then pip.glow:Hide() end

        if swSegmentMarkers[i] then swSegmentMarkers[i]:Hide() end
    end
    secondWindText:Hide()
    secondWindMiniBar:Hide()


    if max == 0 then return end

    if mode == "PIPS" then
        local scale = settings.secondWindScale or 1.0
        local basePipSize = 6
        local baseGap = 4
        local baseGlowSize = 14

        local pipSize = basePipSize * scale
        local pipGap = baseGap * scale
        local glowSize = baseGlowSize * scale
        local totalWidth = (max * pipSize) + ((max - 1) * pipGap)
        local startX = -totalWidth / 2

        for i = 1, max do
            local pip = secondWindPips[i]
            local xPos = startX + ((i - 1) * (pipSize + pipGap))


            pip:ClearAllPoints()
            pip:SetPoint("BOTTOM", skyridingFrame, "TOP", xPos + (pipSize / 2), 3)
            pip:SetSize(pipSize, pipSize)


            if pip.glow then
                pip.glow:ClearAllPoints()
                pip.glow:SetPoint("CENTER", pip, "CENTER", 0, 0)
                pip.glow:SetSize(glowSize, glowSize)
            end

            if i <= current then

                pip:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
                pip:Show()
                if pip.glow then
                    pip.glow:SetVertexColor(color[1], color[2], color[3], 0.5)
                    pip.glow:Show()
                end
            else

                pip:SetVertexColor(0.25, 0.25, 0.25, 0.5)
                pip:Show()
                if pip.glow then pip.glow:Hide() end
            end
        end

    elseif mode == "TEXT" then
        secondWindText:SetText(string.format("SW: %d/%d", current, max))
        secondWindText:SetTextColor(color[1], color[2], color[3], color[4] or 1)
        secondWindText:Show()

    elseif mode == "MINIBAR" then
        local swHeight = settings.secondWindHeight or 6
        local barWidth = skyridingFrame:GetWidth()

        secondWindMiniBar:ClearAllPoints()
        secondWindMiniBar:SetPoint("TOPLEFT", skyridingFrame, "BOTTOMLEFT", 0, -2)
        secondWindMiniBar:SetPoint("TOPRIGHT", skyridingFrame, "BOTTOMRIGHT", 0, -2)
        secondWindMiniBar:SetHeight(swHeight)
        secondWindMiniBar:SetMinMaxValues(0, max)


        if current > lastSecondWind and lastSecondWind >= 0 then
            swCurrentValue = current / max
            secondWindMiniBar:SetValue(swCurrentValue * max)
        end


        swTargetValue = current / max
        swMaxCharges = max
        secondWindMiniBar:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)
        secondWindMiniBar:Show()


        local segmentWidth = barWidth / max
        local thickness = Scale(settings.segmentThickness or 1)
        local softColor = {
            color[1] * 0.25,
            color[2] * 0.25,
            color[3] * 0.25,
            0.6
        }

        for i = 1, 5 do
            local marker = swSegmentMarkers[i]
            if i < max then
                local xPos = i * segmentWidth
                marker:ClearAllPoints()
                marker:SetPoint("LEFT", secondWindMiniBar, "LEFT", Scale(xPos - (thickness / 2)), 0)
                marker:SetWidth(math.max(Scale(1), thickness))
                marker:SetHeight(swHeight)
                marker:SetVertexColor(softColor[1], softColor[2], softColor[3], softColor[4])
                marker:Show()
            else
                marker:Hide()
            end
        end
    end


    lastSecondWind = current
end


local function UpdateVigorBar()
    local settings = GetSettings()
    if not settings or not skyridingFrame then return end

    local current, max, startTime, duration, modRate = GetVigorInfo()


    if max ~= lastMaxCharges then
        UpdateSegmentMarkers(max)
        lastMaxCharges = max
    end


    if current > lastVigorCharges and lastVigorCharges >= 0 then


        currentBarValue = current / max
        vigorBar:SetValue(currentBarValue)


        if flashAnim and not flashAnim:IsPlaying() then
            local barWidth = skyridingFrame:GetWidth()
            local segmentWidth = barWidth / max
            local segmentStart = lastVigorCharges * segmentWidth
            flashTexture:ClearAllPoints()
            flashTexture:SetPoint("LEFT", vigorBar, "LEFT", segmentStart, 0)
            flashTexture:SetWidth(segmentWidth)
            flashTexture:SetHeight(skyridingFrame:GetHeight())
            flashAnim:Play()
        end
    end


    targetBarValue = current / max


    if settings.showVigorText ~= false then
        local format = settings.vigorTextFormat or "FRACTION"
        if format == "FRACTION" then
            vigorText:SetText(string.format("%d/%d", current, max))
        else
            vigorText:SetText(tostring(current))
        end
        vigorText:Show()
    else
        vigorText:Hide()
    end

    lastVigorCharges = current
end


local function UpdateRechargeAnimation()
    local settings = GetSettings()
    if not settings or not skyridingFrame then return end

    local current, max, startTime, duration, modRate = GetVigorInfo()


    if current >= max or duration == 0 then
        rechargeOverlay:Hide()
        return
    end


    local now = GetTime()
    local elapsedTime = (now - startTime) * modRate
    local progress = math.min(1, elapsedTime / duration)


    local barWidth = skyridingFrame:GetWidth()
    local segmentWidth = barWidth / max
    local segmentStart = current * segmentWidth
    local fillWidth = math.max(1, progress * segmentWidth)

    local color = settings.rechargeColor or {0.4, 0.9, 1.0, 0.6}

    rechargeOverlay:ClearAllPoints()
    rechargeOverlay:SetPoint("LEFT", vigorBar, "LEFT", segmentStart, 0)
    rechargeOverlay:SetWidth(fillWidth)
    rechargeOverlay:SetHeight(skyridingFrame:GetHeight())


    local pulse = 0.7 + 0.3 * math.sin(now * 4)
    rechargeOverlay:SetVertexColor(color[1], color[2], color[3], (color[4] or 0.6) * pulse)
    rechargeOverlay:Show()
end


local function UpdateSecondWindRecharge()
    local settings = GetSettings()
    if not settings or not secondWindMiniBar or not swRechargeOverlay then return end


    local mode = settings.secondWindMode or "PIPS"
    if mode ~= "MINIBAR" then
        swRechargeOverlay:Hide()
        return
    end

    local current, max, startTime, duration, modRate = GetSecondWindInfo()


    if max == 0 or current >= max or duration == 0 then
        swRechargeOverlay:Hide()
        return
    end


    local now = GetTime()
    local elapsedTime = (now - startTime) * modRate
    local progress = math.min(1, elapsedTime / duration)


    local barWidth = secondWindMiniBar:GetWidth()
    local barHeight = secondWindMiniBar:GetHeight()
    local segmentWidth = barWidth / max
    local segmentStart = current * segmentWidth
    local fillWidth = math.max(1, progress * segmentWidth)


    local color
    if settings.useClassColorSecondWind then
        local _, class = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[class]
        if classColor then
            color = {classColor.r, classColor.g, classColor.b, 0.6}
        else
            color = {1, 0.9, 0.4, 0.6}
        end
    else
        color = {1, 0.9, 0.4, 0.6}
    end

    swRechargeOverlay:ClearAllPoints()
    swRechargeOverlay:SetPoint("LEFT", secondWindMiniBar, "LEFT", segmentStart, 0)
    swRechargeOverlay:SetWidth(fillWidth)
    swRechargeOverlay:SetHeight(barHeight)


    local pulse = 0.7 + 0.3 * math.sin(now * 4)
    swRechargeOverlay:SetVertexColor(color[1], color[2], color[3], color[4] * pulse)
    swRechargeOverlay:Show()
end


local function UpdateSpeed()
    local settings = GetSettings()
    if not settings or not skyridingFrame then return end

    if settings.showSpeed == false then
        speedText:Hide()
        return
    end

    local _, _, speed = GetGlidingInfo()
    forwardSpeed = speed

    local format = settings.speedFormat or "PERCENT"
    if format == "PERCENT" then
        speedText:SetText(string.format("%d%%", math.floor(speed * 10)))
    else
        speedText:SetText(string.format("%.1f", speed))
    end
    speedText:Show()
end


local function UpdateAbilityIcon()
    if not abilityIcon or not abilityIconCooldown then return end

    local settings = GetSettings()
    if not settings then return end


    if settings.showAbilityIcon == false then
        abilityIcon:Hide()
        return
    end


    local _, canGlideNow, _ = GetGlidingInfo()
    if not canGlideNow then
        return
    end


    local vigorHeight = settings.vigorHeight or 12
    local swHeight = settings.secondWindHeight or 6
    local swMode = settings.secondWindMode or "PIPS"
    local _, swMax = GetSecondWindInfo()

    local totalHeight = vigorHeight
    local yOffset = 0
    if swMode == "MINIBAR" and swMax > 0 then
        totalHeight = vigorHeight + 2 + swHeight
        yOffset = -(2 + swHeight) / 2
    end
    abilityIcon:SetSize(totalHeight, totalHeight)
    abilityIcon:ClearAllPoints()
    abilityIcon:SetPoint("LEFT", skyridingFrame, "RIGHT", 2, yOffset)


    local cooldownInfo = C_Spell.GetSpellCooldown(WHIRLING_SURGE_SPELL_ID)
    if cooldownInfo and cooldownInfo.duration and not IsSecretValue(cooldownInfo.duration) and cooldownInfo.duration > 0 then
        abilityIconCooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
    else
        abilityIconCooldown:Clear()
    end

    abilityIcon:Show()
end


local function StartSkyridingFade(targetAlpha)
    if not skyridingFrame then return end

    local currentAlpha = skyridingFrame:GetAlpha()
    if math.abs(currentAlpha - targetAlpha) < 0.01 then return end

    fadeStart = GetTime()
    fadeStartAlpha = currentAlpha
    fadeTargetAlpha = targetAlpha
end


local function UpdateVisibility()
    local settings = GetSettings()
    if not settings or not skyridingFrame then return end

    if not settings.enabled then
        skyridingFrame:Hide()
        return
    end

    local gliding, canGlideNow, _ = GetGlidingInfo()
    isGliding = gliding
    canGlide = canGlideNow

    local visibility = settings.visibility or "AUTO"
    local fadeDelay = settings.fadeDelay or 3


    if inCombat and canGlideNow then
        local current, max = GetVigorInfo()
        if current == 0 and max == 6 then
            skyridingFrame:Hide()
            return
        end
    end

    if visibility == "ALWAYS" then
        skyridingFrame:Show()
        StartSkyridingFade(1)

    elseif visibility == "FLYING_ONLY" then
        if canGlideNow then
            skyridingFrame:Show()
            StartSkyridingFade(1)
        else
            StartSkyridingFade(0)
        end

    elseif visibility == "AUTO" then
        if isGliding then

            groundedTime = 0
            fadeStart = 0
            skyridingFrame:SetAlpha(1)

            if abilityIcon then
                abilityIcon:SetAlpha(1)
                if abilityIconCooldown then
                    abilityIconCooldown:SetAlpha(1)
                end
            end
            skyridingFrame:Show()
        elseif canGlideNow then

            if groundedTime >= fadeDelay then
                StartSkyridingFade(0)
            else
                skyridingFrame:Show()
                StartSkyridingFade(1)
            end
        else

            StartSkyridingFade(0)
        end
    end
end


local function ApplySettings()
    local settings = GetSettings()
    if not skyridingFrame then
        CreateSkyridingFrame()
    end
    if not settings then
        if skyridingFrame then skyridingFrame:Hide() end
        return
    end

    local width = settings.width or 250
    local height = settings.vigorHeight or 12
    local offsetX = settings.offsetX or 0
    local offsetY = settings.offsetY or -150
    local locked = settings.locked ~= false


    skyridingFrame:SetSize(width, height)
    skyridingFrame:ClearAllPoints()
    skyridingFrame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)


    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local db = PREYCore and PREYCore.db and PREYCore.db.profile
    local layerPriority = db and db.hudLayering and db.hudLayering.skyridingHUD or 5
    if PREYCore and PREYCore.GetHUDFrameLevel then
        local frameLevel = PREYCore:GetHUDFrameLevel(layerPriority)
        skyridingFrame:SetFrameLevel(frameLevel)
    end


    skyridingFrame:EnableMouse(not locked)


    local textureName = settings.barTexture or "Solid"
    local texturePath = LSM:Fetch("statusbar", textureName) or "Interface\\Buttons\\WHITE8x8"
    vigorBar:SetStatusBarTexture(texturePath)
    if secondWindMiniBar then
        secondWindMiniBar:SetStatusBarTexture(texturePath)
    end


    local barColor
    if settings.useClassColorVigor then
        local _, class = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[class]
        if classColor then
            barColor = {classColor.r, classColor.g, classColor.b, 1}
        else
            barColor = settings.barColor or {0.860, 0.220, 0.260, 1}
        end
    else
        barColor = settings.barColor or {0.860, 0.220, 0.260, 1}
    end
    vigorBar:SetStatusBarColor(barColor[1], barColor[2], barColor[3], barColor[4] or 1)


    local bgColor = settings.backgroundColor or {0.1, 0.1, 0.1, 0.8}
    vigorBackground:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 0.8)


    local swBgColor = settings.secondWindBackgroundColor or bgColor
    if swBackground then
        swBackground:SetColorTexture(swBgColor[1], swBgColor[2], swBgColor[3], swBgColor[4] or 0.8)
    end


    local borderSize = settings.borderSize or 1
    local borderColor = settings.borderColor or {0, 0, 0, 1}
    skyridingFrame.border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = borderSize,
    })
    skyridingFrame.border:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
    if skyridingFrame.border.Center then skyridingFrame.border.Center:Hide() end


    rechargeOverlay:SetHeight(height)


    local vigorFontSize = settings.vigorFontSize or 11
    local speedFontSize = settings.speedFontSize or 11
    local fontPath = GetFontPath()
    vigorText:SetFont(fontPath, vigorFontSize, "OUTLINE")
    speedText:SetFont(fontPath, speedFontSize, "OUTLINE")


    if abilityIconCooldown then
        ApplyCooldownFont(abilityIconCooldown, vigorFontSize)
    end


    local _, max = GetVigorInfo()
    UpdateSegmentMarkers(max)


    UpdateVigorBar()
    UpdateRechargeAnimation()
    UpdateSecondWind()
    UpdateSpeed()
    UpdateAbilityIcon()
    UpdateVisibility()
end


local function OnUpdate(self, delta)
    elapsed = elapsed + delta
    if elapsed < UPDATE_THROTTLE then return end
    elapsed = 0

    local settings = GetSettings()
    if not settings or not settings.enabled then return end


    local gliding, canGlideNow, _ = GetGlidingInfo()
    if not gliding and canGlideNow then
        groundedTime = groundedTime + UPDATE_THROTTLE
    else
        groundedTime = 0
    end


    if currentBarValue ~= targetBarValue then
        local diff = targetBarValue - currentBarValue
        if math.abs(diff) < 0.005 then

            currentBarValue = targetBarValue
        else

            currentBarValue = currentBarValue + diff * LERP_SPEED * UPDATE_THROTTLE
        end
        vigorBar:SetValue(currentBarValue)
    end


    if fadeStart > 0 then
        local now = GetTime()
        local elapsedTime = now - fadeStart
        local fadeDuration = settings.fadeDuration or 0.3
        local progress = math.min(elapsedTime / fadeDuration, 1)


        local alpha = fadeStartAlpha + (fadeTargetAlpha - fadeStartAlpha) * progress
        skyridingFrame:SetAlpha(alpha)


        if abilityIcon then
            abilityIcon:SetAlpha(alpha)
            if abilityIconCooldown then
                abilityIconCooldown:SetAlpha(alpha)
            end
        end


        if progress >= 1 then
            fadeStart = 0
            if fadeTargetAlpha < 0.01 then
                skyridingFrame:Hide()
            end
        end
    end


    if swCurrentValue ~= swTargetValue and swMaxCharges > 0 then
        local diff = swTargetValue - swCurrentValue
        if math.abs(diff) < 0.005 then

            swCurrentValue = swTargetValue
        else

            swCurrentValue = swCurrentValue + diff * LERP_SPEED * UPDATE_THROTTLE
        end
        secondWindMiniBar:SetValue(swCurrentValue * swMaxCharges)
    end


    UpdateVigorBar()
    UpdateRechargeAnimation()
    UpdateSecondWind()
    UpdateSecondWindRecharge()
    UpdateSpeed()
    UpdateAbilityIcon()
    UpdateVisibility()
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_CAN_GLIDE_CHANGED")
eventFrame:RegisterEvent("PLAYER_IS_GLIDING_CHANGED")
eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
            CreateSkyridingFrame()
            ApplySettings()

            if skyridingFrame then
                skyridingFrame:SetScript("OnUpdate", OnUpdate)
            end
        end)
    elseif event == "PLAYER_CAN_GLIDE_CHANGED" then
        canGlide = arg1
        UpdateVisibility()
    elseif event == "PLAYER_IS_GLIDING_CHANGED" then
        isGliding = arg1
        groundedTime = 0
        UpdateVisibility()
    elseif event == "UPDATE_BONUS_ACTIONBAR" or event == "SPELL_UPDATE_CHARGES" then
        if skyridingFrame and skyridingFrame:IsShown() then
            UpdateVigorBar()
            UpdateSecondWind()
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if skyridingFrame and skyridingFrame:IsShown() then
            UpdateAbilityIcon()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        UpdateVisibility()
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        UpdateVisibility()
    end
end)


_G.PreyUI_RefreshSkyriding = ApplySettings


PREY.Skyriding = {
    Refresh = ApplySettings,
    Create = CreateSkyridingFrame,
    UpdateVisibility = UpdateVisibility,
}
