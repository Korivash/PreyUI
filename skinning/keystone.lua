local addonName, ns = ...


local COLORS = {
    text = { 0.9, 0.9, 0.9, 1 },
    textMuted = { 0.6, 0.6, 0.6, 1 },
}

local FONT_FLAGS = "OUTLINE"


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
    if not button then return end

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
    if button.Middle then button.Middle:SetAlpha(0) end
    if button.LeftSeparator then button.LeftSeparator:SetAlpha(0) end
    if button.RightSeparator then button.RightSeparator:SetAlpha(0) end


    local highlight = button:GetHighlightTexture()
    if highlight then highlight:SetAlpha(0) end
    local pushed = button:GetPushedTexture()
    if pushed then pushed:SetAlpha(0) end


    local text = button:GetFontString()
    if text then
        text:SetFont(STANDARD_TEXT_FONT, 12, FONT_FLAGS)
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
end


local function StyleCloseButton(button)
    if not button then return end
    if button.Border then button.Border:SetAlpha(0) end
end


local function StyleKeystoneSlot(slot, sr, sg, sb, sa)
    if not slot then return end

    if not slot.preyBorder then
        slot.preyBorder = CreateFrame("Frame", nil, slot, "BackdropTemplate")
        slot.preyBorder:SetPoint("TOPLEFT", -4, 4)
        slot.preyBorder:SetPoint("BOTTOMRIGHT", 4, -4)
        slot.preyBorder:SetFrameLevel(slot:GetFrameLevel() - 1)
        slot.preyBorder:EnableMouse(false)
        slot.preyBorder:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        slot.preyBorder:SetBackdropColor(0, 0, 0, 0.5)
        slot.preyBorder:SetBackdropBorderColor(sr, sg, sb, sa)
    end
end


local function HideBlizzardDecorations(f)
    local region = f:GetRegions()
    if region then region:SetAlpha(0) end
    if f.InstructionBackground then f.InstructionBackground:SetAlpha(0) end
    if f.KeystoneSlotGlow then f.KeystoneSlotGlow:Hide() end
    if f.SlotBG then f.SlotBG:Hide() end
    if f.KeystoneFrame then f.KeystoneFrame:Hide() end
    if f.Divider then f.Divider:Hide() end
end


local function SkinKeystoneFrame()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
    if not settings or not settings.skinKeystoneFrame then return end

    local keystoneFrame = _G.ChallengesKeystoneFrame
    if not keystoneFrame or keystoneFrame.preySkinned then return end


    local PREY = _G.PreyUI
    local sr, sg, sb, sa
    local bgr, bgg, bgb, bga
    if PREY and PREY.GetSkinColor then
        sr, sg, sb, sa = PREY:GetSkinColor()
    else
        sr, sg, sb, sa = 0.820, 0.180, 0.220, 1
    end
    if PREY and PREY.GetSkinBgColor then
        bgr, bgg, bgb, bga = PREY:GetSkinBgColor()
    else
        bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95
    end


    CreatePREYBackdrop(keystoneFrame, sr, sg, sb, sa, bgr, bgg, bgb, bga)


    hooksecurefunc(keystoneFrame, "Reset", HideBlizzardDecorations)
    keystoneFrame:HookScript("OnShow", HideBlizzardDecorations)


    if keystoneFrame.DungeonName then
        keystoneFrame.DungeonName:SetFont(STANDARD_TEXT_FONT, 22, FONT_FLAGS)
        keystoneFrame.DungeonName:SetTextColor(unpack(COLORS.text))
    end

    if keystoneFrame.TimeLimit then
        keystoneFrame.TimeLimit:SetFont(STANDARD_TEXT_FONT, 16, FONT_FLAGS)
        keystoneFrame.TimeLimit:SetTextColor(unpack(COLORS.textMuted))
    end

    if keystoneFrame.Instructions then
        keystoneFrame.Instructions:SetFont(STANDARD_TEXT_FONT, 11, FONT_FLAGS)
        keystoneFrame.Instructions:SetTextColor(unpack(COLORS.textMuted))
    end


    StyleButton(keystoneFrame.StartButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    StyleCloseButton(keystoneFrame.CloseButton)


    StyleKeystoneSlot(keystoneFrame.KeystoneSlot, sr, sg, sb, sa)


    keystoneFrame.preySkinColor = { sr, sg, sb, sa }


    hooksecurefunc(keystoneFrame, "OnKeystoneSlotted", function(f)
        local r, g, b, a = unpack(f.preySkinColor or { 0.820, 0.180, 0.220, 1 })
        for i = 1, 4 do
            local affix = f["Affix" .. i]
            if affix and affix.Portrait then
                if not affix.preyBorder then
                    affix.preyBorder = affix:CreateTexture(nil, "OVERLAY")
                    affix.preyBorder:SetPoint("TOPLEFT", affix.Portrait, -1, 1)
                    affix.preyBorder:SetPoint("BOTTOMRIGHT", affix.Portrait, 1, -1)
                    affix.preyBorder:SetColorTexture(r, g, b, a)
                    affix.preyBorder:SetDrawLayer("OVERLAY", -1)
                end
            end
        end
    end)

    keystoneFrame.preySkinned = true
end


local function RefreshKeystoneColors()
    local keystoneFrame = _G.ChallengesKeystoneFrame
    if not keystoneFrame or not keystoneFrame.preySkinned then return end


    local PREY = _G.PreyUI
    local sr, sg, sb, sa = 0.820, 0.180, 0.220, 1
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95

    if PREY and PREY.GetSkinColor then
        sr, sg, sb, sa = PREY:GetSkinColor()
    end
    if PREY and PREY.GetSkinBgColor then
        bgr, bgg, bgb, bga = PREY:GetSkinBgColor()
    end


    if keystoneFrame.preyBackdrop then
        keystoneFrame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        keystoneFrame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end


    if keystoneFrame.StartButton and keystoneFrame.StartButton.preyBackdrop then
        local btnBgR = math.min(bgr + 0.07, 1)
        local btnBgG = math.min(bgg + 0.07, 1)
        local btnBgB = math.min(bgb + 0.07, 1)
        keystoneFrame.StartButton.preyBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
        keystoneFrame.StartButton.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        keystoneFrame.StartButton.preySkinColor = { sr, sg, sb, sa }
    end


    if keystoneFrame.KeystoneSlot and keystoneFrame.KeystoneSlot.preyBorder then
        keystoneFrame.KeystoneSlot.preyBorder:SetBackdropBorderColor(sr, sg, sb, sa)
    end


    for i = 1, 4 do
        local affix = keystoneFrame["Affix" .. i]
        if affix and affix.preyBorder then
            affix.preyBorder:SetColorTexture(sr, sg, sb, sa)
        end
    end


    keystoneFrame.preySkinned = true
    keystoneFrame.preySkinColor = { sr, sg, sb, sa }
end


_G.PreyUI_RefreshKeystoneColors = RefreshKeystoneColors


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == "Blizzard_ChallengesUI" then
        if ChallengesKeystoneFrame then
            SkinKeystoneFrame()
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
