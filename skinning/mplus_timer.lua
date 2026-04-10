local ADDON_NAME, ns = ...


local function GetLuminance(r, g, b)

    return 0.299 * r + 0.587 * g + 0.114 * b
end

local function IsDarkBackground(r, g, b)
    return GetLuminance(r, g, b) < 0.35
end


local function GetSkinColors()
    local PREY = _G.PreyUI
    local sr, sg, sb, sa = 0.820, 0.180, 0.220, 1
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95

    if PREY and PREY.GetSkinColor then
        sr, sg, sb, sa = PREY:GetSkinColor()
    end
    if PREY and PREY.GetSkinBgColor then
        bgr, bgg, bgb, bga = PREY:GetSkinBgColor()
    end

    return sr, sg, sb, sa, bgr, bgg, bgb, bga
end


local function GetMPlusTimerSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.mplusTimer then
        return PREYCore.db.profile.mplusTimer
    end
    return { showBorder = true }
end


local function GetContrastColors(bgr, bgg, bgb)
    local isDark = IsDarkBackground(bgr, bgg, bgb)

    if isDark then

        return {
            text = { 1.0, 1.0, 1.0, 1 },
            textMuted = { 0.75, 0.75, 0.75, 1 },
            textRed = { 1.0, 0.45, 0.45, 1 },
            textGreen = { 0.45, 1.0, 0.65, 1 },
            textYellow = { 1.0, 0.9, 0.3, 1 },
            barBg = { 0.18, 0.18, 0.20, 1 },
            barBorder = 1.0,
        }
    else

        return {
            text = { 0.1, 0.1, 0.1, 1 },
            textMuted = { 0.3, 0.3, 0.3, 1 },
            textRed = { 0.8, 0.15, 0.15, 1 },
            textGreen = { 0.1, 0.6, 0.3, 1 },
            textYellow = { 0.7, 0.5, 0.0, 1 },
            barBg = { 0.15, 0.15, 0.15, 0.9 },
            barBorder = 0.5,
        }
    end
end


local function ApplyBackdrop(frame, sr, sg, sb, sa, bgr, bgg, bgb, bga, showBorder)
    if not frame then return end

    if not frame.preyBackdrop then
        frame.preyBackdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.preyBackdrop:SetAllPoints()
        frame.preyBackdrop:SetFrameLevel(math.max(1, frame:GetFrameLevel() - 1))
        frame.preyBackdrop:EnableMouse(false)
    end

    frame.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)


    local borderAlpha = showBorder and sa or 0
    frame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, borderAlpha)
end


local function ApplyBarSkin(bar, sr, sg, sb, colors, isTimerBar, barIndex, showBorder)
    if not bar or not bar.frame then return end

    local barBg = colors.barBg
    local borderMult = colors.barBorder


    bar.frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    bar.frame:SetBackdropColor(barBg[1], barBg[2], barBg[3], barBg[4])


    local borderAlpha = showBorder and 1 or 0
    bar.frame:SetBackdropBorderColor(sr * borderMult, sg * borderMult, sb * borderMult, borderAlpha)


    if bar.bar then
        bar.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")

        if isTimerBar then

            if barIndex == 3 then

                bar.bar:SetStatusBarColor(0.2, 0.85, 0.4, 1)
            elseif barIndex == 2 then

                bar.bar:SetStatusBarColor(0.95, 0.75, 0.2, 1)
            else

                bar.bar:SetStatusBarColor(sr, sg, sb, 1)
            end
        else

            bar.bar:SetStatusBarColor(sr, sg, sb, 1)
        end
    end


    if bar.overlay then

        bar.overlay:SetVertexColor(
            math.min(sr * 1.3, 1),
            math.min(sg * 1.3, 1),
            math.min(sb * 1.3, 1),
            0.6
        )
    end


    if bar.text then
        bar.text:SetTextColor(colors.text[1], colors.text[2], colors.text[3], colors.text[4])
    end
end


local function ApplyMPlusTimerSkin()
    local MPlusTimer = _G.PreyUI_MPlusTimer
    if not MPlusTimer or not MPlusTimer.frames or not MPlusTimer.frames.root then
        return
    end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()
    local colors = GetContrastColors(bgr, bgg, bgb)
    local settings = GetMPlusTimerSettings()
    local showBorder = settings.showBorder ~= false


    ApplyBackdrop(MPlusTimer.frames.root, sr, sg, sb, sa, bgr, bgg, bgb, bga, showBorder)


    if MPlusTimer.frames.deathsText then
        MPlusTimer.frames.deathsText:SetTextColor(
            colors.textRed[1], colors.textRed[2], colors.textRed[3], colors.textRed[4]
        )
    end


    if MPlusTimer.frames.timerText then
        MPlusTimer.frames.timerText:SetTextColor(
            colors.text[1], colors.text[2], colors.text[3], colors.text[4]
        )
    end


    if MPlusTimer.frames.dungeonText then
        MPlusTimer.frames.dungeonText:SetTextColor(
            colors.text[1], colors.text[2], colors.text[3], colors.text[4]
        )
    end


    if MPlusTimer.frames.keyText then

        local kr, kg, kb = sr, sg, sb
        if IsDarkBackground(bgr, bgg, bgb) then

            local lum = GetLuminance(sr, sg, sb)
            if lum < 0.4 then
                kr = math.min(sr * 1.5, 1)
                kg = math.min(sg * 1.5, 1)
                kb = math.min(sb * 1.5, 1)
            end
        end
        MPlusTimer.frames.keyText:SetTextColor(kr, kg, kb, 1)
    end


    if MPlusTimer.frames.affixText then
        MPlusTimer.frames.affixText:SetTextColor(
            colors.textMuted[1], colors.textMuted[2], colors.textMuted[3], colors.textMuted[4]
        )
    end


    if MPlusTimer.bars then
        for i = 1, 3 do
            if MPlusTimer.bars[i] then
                ApplyBarSkin(MPlusTimer.bars[i], sr, sg, sb, colors, true, i, showBorder)
            end
        end


        if MPlusTimer.bars.forces then
            ApplyBarSkin(MPlusTimer.bars.forces, sr, sg, sb, colors, false, nil, showBorder)
        end
    end


    if MPlusTimer.frames.sleekBar then
        local barBg = colors.barBg
        local borderMult = colors.barBorder
        local borderAlpha = showBorder and 1 or 0

        MPlusTimer.frames.sleekBar:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        MPlusTimer.frames.sleekBar:SetBackdropColor(barBg[1], barBg[2], barBg[3], barBg[4])
        MPlusTimer.frames.sleekBar:SetBackdropBorderColor(sr * borderMult, sg * borderMult, sb * borderMult, borderAlpha)
    end


    if MPlusTimer.sleekSegments then

        if MPlusTimer.sleekSegments[3] then
            MPlusTimer.sleekSegments[3]:SetVertexColor(0.2, 0.85, 0.4, 1)
        end

        if MPlusTimer.sleekSegments[2] then
            MPlusTimer.sleekSegments[2]:SetVertexColor(0.95, 0.75, 0.2, 1)
        end

        if MPlusTimer.sleekSegments[1] then
            MPlusTimer.sleekSegments[1]:SetVertexColor(sr, sg, sb, 1)
        end
    end


    if MPlusTimer.frames.sleekPosMarker then

        MPlusTimer.frames.sleekPosMarker:SetVertexColor(1, 1, 1, 0.95)
    end


    if MPlusTimer.objectives then
        for i, objText in ipairs(MPlusTimer.objectives) do
            if objText and objText.SetTextColor then
                objText:SetTextColor(
                    colors.text[1], colors.text[2], colors.text[3], colors.text[4]
                )
            end
        end
    end


    MPlusTimer.frames.root.preySkinned = true
    MPlusTimer.frames.root.preyColors = colors
end


local function RefreshMPlusTimerColors()
    local MPlusTimer = _G.PreyUI_MPlusTimer
    if not MPlusTimer or not MPlusTimer.frames or not MPlusTimer.frames.root then
        return
    end
    if not MPlusTimer.frames.root.preySkinned then return end


    ApplyMPlusTimerSkin()
end


_G.PreyUI_ApplyMPlusTimerSkin = ApplyMPlusTimerSkin
_G.PreyUI_RefreshMPlusTimerColors = RefreshMPlusTimerColors
