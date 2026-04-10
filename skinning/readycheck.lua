local addonName, ns = ...


local FONT_FLAGS = "OUTLINE"


local readyCheckMover = nil


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        return PREYCore.db.profile.general
    end
    return nil
end

local function SaveReadyCheckPosition(point, relativeTo, relativePoint, x, y)
    local settings = GetSettings()
    if settings then
        settings.readyCheckPosition = {
            point = point,
            relativePoint = relativePoint,
            x = x,
            y = y
        }
    end
end

local function GetReadyCheckPosition()
    local settings = GetSettings()
    if settings and settings.readyCheckPosition then
        return settings.readyCheckPosition
    end
    return nil
end

local function ResetReadyCheckPosition()
    local settings = GetSettings()
    if settings then
        settings.readyCheckPosition = nil
    end

    local frame = _G.ReadyCheckFrame
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -10)
    end

    if readyCheckMover then
        readyCheckMover:ClearAllPoints()
        readyCheckMover:SetPoint("CENTER", UIParent, "CENTER", 0, -10)
    end
end


_G.PreyUI_ResetReadyCheckPosition = ResetReadyCheckPosition


local function CreateMover()
    if readyCheckMover then return end

    local frame = _G.ReadyCheckFrame
    if not frame then return end


    local PREY = _G.PreyUI
    local sr, sg, sb, sa = 0.820, 0.180, 0.220, 1
    if PREY and PREY.GetSkinColor then
        sr, sg, sb, sa = PREY:GetSkinColor()
    end


    readyCheckMover = CreateFrame("Frame", "PreyUI_ReadyCheckMover", UIParent, "BackdropTemplate")
    readyCheckMover:SetSize(frame:GetWidth() + 4, frame:GetHeight() + 4)
    readyCheckMover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    readyCheckMover:SetBackdropColor(sr, sg, sb, 0.3)
    readyCheckMover:SetBackdropBorderColor(sr, sg, sb, 1)
    readyCheckMover:EnableMouse(true)
    readyCheckMover:SetMovable(true)
    readyCheckMover:RegisterForDrag("LeftButton")
    readyCheckMover:SetFrameStrata("FULLSCREEN_DIALOG")
    readyCheckMover:Hide()


    local pos = GetReadyCheckPosition()
    if pos then
        readyCheckMover:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        readyCheckMover:SetPoint("CENTER", UIParent, "CENTER", 0, -10)
    end


    readyCheckMover.text = readyCheckMover:CreateFontString(nil, "OVERLAY")
    readyCheckMover.text:SetPoint("CENTER")
    readyCheckMover.text:SetFont(STANDARD_TEXT_FONT, 11, FONT_FLAGS)
    readyCheckMover.text:SetText("Ready Check")
    readyCheckMover.text:SetTextColor(1, 1, 1)


    readyCheckMover:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    readyCheckMover:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local point, _, relPoint, x, y = self:GetPoint()
        SaveReadyCheckPosition(point, nil, relPoint, x, y)
    end)
end

local function ShowMover()
    CreateMover()
    if readyCheckMover then
        readyCheckMover:Show()
    end
end

local function HideMover()
    if readyCheckMover then
        readyCheckMover:Hide()
    end
end

local function ToggleMover()
    if readyCheckMover and readyCheckMover:IsShown() then
        HideMover()
    else
        ShowMover()
    end
end


_G.PreyUI_ToggleReadyCheckMover = ToggleMover


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


local function CreatePREYBackdrop(frame)
    if frame.preyBackdrop then return frame.preyBackdrop end

    local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    backdrop:SetAllPoints()
    backdrop:SetFrameLevel(frame:GetFrameLevel())
    backdrop:EnableMouse(false)

    backdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })

    frame.preyBackdrop = backdrop
    return backdrop
end


local function SkinButton(button, sr, sg, sb, bgr, bgg, bgb, bga)
    if not button or button.preySkinned then return end


    if button.Left then button.Left:SetAlpha(0) end
    if button.Right then button.Right:SetAlpha(0) end
    if button.Middle then button.Middle:SetAlpha(0) end
    if button.LeftSeparator then button.LeftSeparator:SetAlpha(0) end
    if button.RightSeparator then button.RightSeparator:SetAlpha(0) end


    if button.NineSlice then button.NineSlice:SetAlpha(0) end


    for _, region in ipairs({button:GetRegions()}) do
        if region:GetObjectType() == "Texture" then
            local drawLayer = region:GetDrawLayer()
            if drawLayer == "BACKGROUND" then
                region:SetAlpha(0)
            end
        end
    end


    local backdrop = CreatePREYBackdrop(button)
    local btnBgr = math.min(bgr + 0.07, 1)
    local btnBgg = math.min(bgg + 0.07, 1)
    local btnBgb = math.min(bgb + 0.07, 1)
    backdrop:SetBackdropColor(btnBgr, btnBgg, btnBgb, bga)
    backdrop:SetBackdropBorderColor(sr, sg, sb, 1)


    button.preyNormalBg = { btnBgr, btnBgg, btnBgb, bga }
    button.preyHoverBg = { math.min(btnBgr + 0.1, 1), math.min(btnBgg + 0.1, 1), math.min(btnBgb + 0.1, 1), bga }
    button.preyBorderColor = { sr, sg, sb, 1 }


    button:HookScript("OnEnter", function(self)
        if self.preyBackdrop and self.preyHoverBg then
            self.preyBackdrop:SetBackdropColor(unpack(self.preyHoverBg))
        end
    end)
    button:HookScript("OnLeave", function(self)
        if self.preyBackdrop and self.preyNormalBg then
            self.preyBackdrop:SetBackdropColor(unpack(self.preyNormalBg))
        end
    end)


    local text = button:GetFontString()
    if text then
        text:SetFont(STANDARD_TEXT_FONT, 12, FONT_FLAGS)
        text:SetTextColor(0.9, 0.9, 0.9, 1)
    end

    button.preySkinned = true
end


local function RefreshButtonColors(button, sr, sg, sb, bgr, bgg, bgb, bga)
    if not button or not button.preyBackdrop then return end

    local btnBgr = math.min(bgr + 0.07, 1)
    local btnBgg = math.min(bgg + 0.07, 1)
    local btnBgb = math.min(bgb + 0.07, 1)

    button.preyNormalBg = { btnBgr, btnBgg, btnBgb, bga }
    button.preyHoverBg = { math.min(btnBgr + 0.1, 1), math.min(btnBgg + 0.1, 1), math.min(btnBgb + 0.1, 1), bga }
    button.preyBorderColor = { sr, sg, sb, 1 }

    button.preyBackdrop:SetBackdropColor(btnBgr, btnBgg, btnBgb, bga)
    button.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, 1)
end


local function HideBlizzardDecorations()
    local frame = _G.ReadyCheckFrame
    local listenerFrame = _G.ReadyCheckListenerFrame
    if not frame then return end


    if _G.ReadyCheckPortrait then
        _G.ReadyCheckPortrait:SetAlpha(0)
    end


    if listenerFrame then

        if listenerFrame.NineSlice then
            listenerFrame.NineSlice:SetAlpha(0)
        end


        if listenerFrame.PortraitContainer then
            listenerFrame.PortraitContainer:SetAlpha(0)
        end


        if listenerFrame.TitleContainer then
            listenerFrame.TitleContainer:SetAlpha(0)
        end


        if listenerFrame.Bg then
            listenerFrame.Bg:SetAlpha(0)
        end


        for _, region in ipairs({listenerFrame:GetRegions()}) do
            if region:GetObjectType() == "Texture" then
                region:SetAlpha(0)
            end
        end
    end


    for _, region in ipairs({frame:GetRegions()}) do
        if region:GetObjectType() == "Texture" then
            region:SetAlpha(0)
        end
    end
end


local function SkinReadyCheckFrame()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
    if not settings or not settings.skinReadyCheck then return end

    local frame = _G.ReadyCheckFrame
    local listenerFrame = _G.ReadyCheckListenerFrame
    if not frame or frame.preySkinned then return end


    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()


    HideBlizzardDecorations()


    local targetFrame = listenerFrame or frame
    local backdrop = CreatePREYBackdrop(targetFrame)
    backdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    backdrop:SetBackdropBorderColor(sr, sg, sb, sa)


    frame.preyBackdrop = backdrop


    local yesButton = _G.ReadyCheckFrameYesButton
    local noButton = _G.ReadyCheckFrameNoButton

    if yesButton then
        SkinButton(yesButton, sr, sg, sb, bgr, bgg, bgb, bga)
        yesButton:ClearAllPoints()
        yesButton:SetPoint("BOTTOMRIGHT", targetFrame, "BOTTOM", -5, 12)
    end
    if noButton then
        SkinButton(noButton, sr, sg, sb, bgr, bgg, bgb, bga)
        noButton:ClearAllPoints()
        noButton:SetPoint("BOTTOMLEFT", targetFrame, "BOTTOM", 5, 12)
    end


    local text = _G.ReadyCheckFrameText
    if text then
        text:ClearAllPoints()
        text:SetPoint("TOP", targetFrame, "TOP", 0, -30)
        text:SetFont(STANDARD_TEXT_FONT, 12, FONT_FLAGS)
        text:SetTextColor(0.9, 0.9, 0.9, 1)
    end


    if not frame.preyTitle then
        frame.preyTitle = targetFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.preyTitle:SetPoint("TOP", targetFrame, "TOP", 0, -8)
        frame.preyTitle:SetFont(STANDARD_TEXT_FONT, 13, FONT_FLAGS)
    end
    frame.preyTitle:SetText("Ready Check")
    frame.preyTitle:SetTextColor(sr, sg, sb, 1)


    frame:HookScript("OnShow", function(self)
        HideBlizzardDecorations()

        local pos = GetReadyCheckPosition()
        if pos then
            self:ClearAllPoints()
            self:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        end
    end)


    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if self.preyUnlocked then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        if self.preyUnlocked then
            self:StopMovingOrSizing()

            local point, _, relativePoint, x, y = self:GetPoint()
            SaveReadyCheckPosition(point, nil, relativePoint, x, y)
        end
    end)

    frame.preySkinned = true
end


local function RefreshReadyCheckColors()
    local frame = _G.ReadyCheckFrame
    if not frame or not frame.preySkinned then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()


    if frame.preyBackdrop then
        frame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        frame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end


    if frame.preyTitle then
        frame.preyTitle:SetTextColor(sr, sg, sb, 1)
    end


    RefreshButtonColors(_G.ReadyCheckFrameYesButton, sr, sg, sb, bgr, bgg, bgb, bga)
    RefreshButtonColors(_G.ReadyCheckFrameNoButton, sr, sg, sb, bgr, bgg, bgb, bga)
end


_G.PreyUI_RefreshReadyCheckColors = RefreshReadyCheckColors


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if _G.ReadyCheckFrame then
            SkinReadyCheckFrame()
        end
    end
end)
