local addonName, ns = ...
local PREYCore = ns.Addon


local InspectSkinning = {}
PREYCore.InspectSkinning = InspectSkinning


local CONFIG = {
    PANEL_WIDTH_EXTENSION = 0,
    PANEL_HEIGHT_EXTENSION = 50,
}


local customBg = nil


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


local function IsSkinningEnabled()
    local coreRef = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = coreRef and coreRef.db and coreRef.db.profile and coreRef.db.profile.general

    if settings and settings.skinInspectFrame == nil then
        return true
    end
    return settings and settings.skinInspectFrame
end


local function IsInspectOverlaysEnabled()
    local coreRef = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = coreRef and coreRef.db and coreRef.db.profile and coreRef.db.profile.character

    if settings and settings.inspectEnabled == nil then
        return true
    end
    return settings and settings.inspectEnabled
end


local function CreateOrUpdateBackground()
    if not InspectFrame then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()

    if not customBg then
        customBg = CreateFrame("Frame", "PREY_InspectFrameBg_Skin", InspectFrame, "BackdropTemplate")
        customBg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        customBg:SetFrameStrata("BACKGROUND")
        customBg:SetFrameLevel(0)
        customBg:EnableMouse(false)
    end

    customBg:SetBackdropColor(bgr, bgg, bgb, bga)
    customBg:SetBackdropBorderColor(sr, sg, sb, sa)

    return customBg
end


local function HideBlizzardDecorations()
    if not InspectFrame then return end


    if InspectFramePortrait then InspectFramePortrait:Hide() end
    if InspectFrame.PortraitContainer then InspectFrame.PortraitContainer:Hide() end
    if InspectFrame.portrait then InspectFrame.portrait:Hide() end


    if InspectFrame.NineSlice then InspectFrame.NineSlice:Hide() end


    if InspectFrame.Bg then InspectFrame.Bg:Hide() end
    if InspectFrame.Background then InspectFrame.Background:Hide() end
    if InspectFrameBg then InspectFrameBg:Hide() end


    if InspectFrame.TitleContainer then

        if InspectFrame.TitleContainer.TitleBg then
            InspectFrame.TitleContainer.TitleBg:Hide()
        end
    end
    if InspectFrame.TopTileStreaks then InspectFrame.TopTileStreaks:Hide() end


    if InspectFrame.Inset then
        if InspectFrame.Inset.Bg then InspectFrame.Inset.Bg:Hide() end
        if InspectFrame.Inset.NineSlice then InspectFrame.Inset.NineSlice:Hide() end
    end


    if InspectModelFrameBorderTopLeft then InspectModelFrameBorderTopLeft:Hide() end
    if InspectModelFrameBorderTopRight then InspectModelFrameBorderTopRight:Hide() end
    if InspectModelFrameBorderTop then InspectModelFrameBorderTop:Hide() end
    if InspectModelFrameBorderLeft then InspectModelFrameBorderLeft:Hide() end
    if InspectModelFrameBorderRight then InspectModelFrameBorderRight:Hide() end
    if InspectModelFrameBorderBottomLeft then InspectModelFrameBorderBottomLeft:Hide() end
    if InspectModelFrameBorderBottomRight then InspectModelFrameBorderBottomRight:Hide() end
    if InspectModelFrameBorderBottom then InspectModelFrameBorderBottom:Hide() end
    if InspectModelFrameBorderBottom2 then InspectModelFrameBorderBottom2:Hide() end


    if InspectModelFrame then
        if InspectModelFrame.BackgroundOverlay then
            InspectModelFrame.BackgroundOverlay:SetAlpha(0)
        end
    end
    for _, corner in pairs({ "TopLeft", "TopRight", "BotLeft", "BotRight" }) do
        local bg = rawget(_G, "InspectModelFrameBackground" .. corner)
        if bg then bg:Hide() end
    end
end


local function SetInspectFrameBgExtended(extended)
    if not customBg then
        CreateOrUpdateBackground()
    end
    if not customBg then return end

    customBg:ClearAllPoints()

    if extended then
        customBg:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 0, 0)
        customBg:SetPoint("BOTTOMRIGHT", InspectFrame, "BOTTOMRIGHT",
            CONFIG.PANEL_WIDTH_EXTENSION, -CONFIG.PANEL_HEIGHT_EXTENSION)
    else
        customBg:SetAllPoints(InspectFrame)
    end

    customBg:Show()
    HideBlizzardDecorations()
end


local function SetupInspectFrameSkinning()
    if not IsSkinningEnabled() then return end
    if not InspectFrame then return end


    CreateOrUpdateBackground()


    if InspectFrame:IsShown() then
        local extended = IsInspectOverlaysEnabled()
        SetInspectFrameBgExtended(extended)
    end
end


local function RefreshInspectFrameColors()
    if not IsSkinningEnabled() then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()


    if customBg then
        customBg:SetBackdropColor(bgr, bgg, bgb, bga)
        customBg:SetBackdropBorderColor(sr, sg, sb, sa)
    end
end


_G.PREY_InspectFrameSkinning = {

    CONFIG = CONFIG,


    IsEnabled = IsSkinningEnabled,
    SetExtended = SetInspectFrameBgExtended,
    Refresh = RefreshInspectFrameColors,
}


_G.PreyUI_RefreshInspectColors = RefreshInspectFrameColors


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == "Blizzard_InspectUI" then
        C_Timer.After(0.1, function()
            SetupInspectFrameSkinning()
        end)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
