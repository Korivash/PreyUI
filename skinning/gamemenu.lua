local addonName, ns = ...


local COLORS = {
    text = { 0.9, 0.9, 0.9, 1 },
}

local FONT_FLAGS = "OUTLINE"


local function GetGameMenuFontSize()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
    return settings and settings.gameMenuFontSize or 12
end


local function GetGameMenuColors()
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


local function CreatePREYBackdrop(frame, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not frame.preyBackdrop then
        frame.preyBackdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.preyBackdrop:SetAllPoints()
        frame.preyBackdrop:SetFrameLevel(frame:GetFrameLevel())
        frame.preyBackdrop:EnableMouse(false)
    end

    frame.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    frame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
end


local function StyleButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not button or button.preyStyled then return end

    if not button.preyBackdrop then
        button.preyBackdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.preyBackdrop:SetAllPoints()
        button.preyBackdrop:SetFrameLevel(button:GetFrameLevel())
        button.preyBackdrop:EnableMouse(false)
    end

    button.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })


    local btnBgR = math.min(bgr + 0.07, 1)
    local btnBgG = math.min(bgg + 0.07, 1)
    local btnBgB = math.min(bgb + 0.07, 1)
    button.preyBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
    button.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)


    if button.Left then button.Left:SetAlpha(0) end
    if button.Right then button.Right:SetAlpha(0) end
    if button.Center then button.Center:SetAlpha(0) end
    if button.Middle then button.Middle:SetAlpha(0) end


    local highlight = button:GetHighlightTexture()
    if highlight then highlight:SetAlpha(0) end
    local pushed = button:GetPushedTexture()
    if pushed then pushed:SetAlpha(0) end
    local normal = button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    local disabled = button:GetDisabledTexture()
    if disabled then disabled:SetAlpha(0) end


    local text = button:GetFontString()
    if text then
        local PREY = _G.PreyUI
        local fontPath = PREY and PREY.GetGlobalFont and PREY:GetGlobalFont() or STANDARD_TEXT_FONT
        local fontSize = GetGameMenuFontSize()
        text:SetFont(fontPath, fontSize, FONT_FLAGS)
        text:SetTextColor(unpack(COLORS.text))
    end


    button.preySkinColor = { sr, sg, sb, sa }


    button:HookScript("OnEnter", function(self)
        if self.preyBackdrop and self.preySkinColor then
            local r, g, b, a = unpack(self.preySkinColor)
            self.preyBackdrop:SetBackdropBorderColor(math.min(r * 1.3, 1), math.min(g * 1.3, 1), math.min(b * 1.3, 1), a)
        end
    end)
    button:HookScript("OnLeave", function(self)
        if self.preyBackdrop and self.preySkinColor then
            self.preyBackdrop:SetBackdropBorderColor(unpack(self.preySkinColor))
        end
    end)

    button.preyStyled = true
end


local function UpdateButtonColors(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not button or not button.preyBackdrop then return end

    local btnBgR = math.min(bgr + 0.07, 1)
    local btnBgG = math.min(bgg + 0.07, 1)
    local btnBgB = math.min(bgb + 0.07, 1)
    button.preyBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
    button.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    button.preySkinColor = { sr, sg, sb, sa }
end


local function HideBlizzardDecorations()
    if GameMenuFrame.Border then GameMenuFrame.Border:Hide() end
    if GameMenuFrame.Header then GameMenuFrame.Header:Hide() end
end


local function SkinGameMenu()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
    if not settings or not settings.skinGameMenu then return end

    if not GameMenuFrame then return end
    if GameMenuFrame.preySkinned then return end


    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetGameMenuColors()


    HideBlizzardDecorations()


    CreatePREYBackdrop(GameMenuFrame, sr, sg, sb, sa, bgr, bgg, bgb, bga)


    GameMenuFrame.topPadding = 15
    GameMenuFrame.bottomPadding = 15
    GameMenuFrame.leftPadding = 15
    GameMenuFrame.rightPadding = 15
    GameMenuFrame.spacing = 2


    if GameMenuFrame.buttonPool then
        for button in GameMenuFrame.buttonPool:EnumerateActive() do
            StyleButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end

    GameMenuFrame:MarkDirty()
    GameMenuFrame.preySkinned = true
end


local function RefreshGameMenuColors()
    if not GameMenuFrame or not GameMenuFrame.preySkinned then return end


    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetGameMenuColors()


    if GameMenuFrame.preyBackdrop then
        GameMenuFrame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        GameMenuFrame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end


    if GameMenuFrame.buttonPool then
        for button in GameMenuFrame.buttonPool:EnumerateActive() do
            UpdateButtonColors(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end
end


local function RefreshGameMenuFontSize()
    if not GameMenuFrame then return end

    local fontSize = GetGameMenuFontSize()
    local PREY = _G.PreyUI
    local fontPath = PREY and PREY.GetGlobalFont and PREY:GetGlobalFont() or STANDARD_TEXT_FONT

    if GameMenuFrame.buttonPool then
        for button in GameMenuFrame.buttonPool:EnumerateActive() do
            local text = button:GetFontString()
            if text then
                text:SetFont(fontPath, fontSize, FONT_FLAGS)
            end
        end
    end


    if GameMenuFrame.MarkDirty then
        GameMenuFrame:MarkDirty()
    end
end


_G.PreyUI_RefreshGameMenuColors = RefreshGameMenuColors
_G.PreyUI_RefreshGameMenuFontSize = RefreshGameMenuFontSize


local function InjectPreyUIButton()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
    if not settings or settings.addPreyUIButton == false then return end

    if not GameMenuFrame or not GameMenuFrame.buttonPool then return end

    for button in GameMenuFrame.buttonPool:EnumerateActive() do
        if button:GetText() == "PreyUI" then
            return
        end
    end


    GameMenuFrame:AddButton("PreyUI", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
        HideUIPanel(GameMenuFrame)
        local PREY = _G.PreyUI
        if PREY and PREY.GUI then
            PREY.GUI:Show()
        end
    end)
    GameMenuFrame:MarkDirty()
end


if GameMenuFrame and GameMenuFrame.InitButtons then
    hooksecurefunc(GameMenuFrame, "InitButtons", function()

        InjectPreyUIButton()


        C_Timer.After(0, function()
            SkinGameMenu()


            if GameMenuFrame.preySkinned and GameMenuFrame.buttonPool then
                local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetGameMenuColors()

                for button in GameMenuFrame.buttonPool:EnumerateActive() do
                    if not button.preyStyled then
                        StyleButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
                    end
                end
            end
        end)
    end)
end
