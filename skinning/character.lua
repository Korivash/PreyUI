local addonName, ns = ...
local PREYCore = ns.Addon


local CharacterSkinning = {}
PREYCore.CharacterSkinning = CharacterSkinning


local CONFIG = {
    PANEL_WIDTH_EXTENSION = 55,
    PANEL_HEIGHT_EXTENSION = 50,
}


local COLORS = {
    text = { 0.9, 0.9, 0.9, 1 },
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


local function GetFontPath()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.character
    return (LSM and settings and LSM:Fetch("font", settings.font or "Prey")) or STANDARD_TEXT_FONT
end


local function IsSkinningEnabled()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
    return settings and settings.skinCharacterFrame
end


local function CreateOrUpdateBackground()
    if not CharacterFrame then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()

    if not customBg then
        customBg = CreateFrame("Frame", "PREY_CharacterFrameBg_Skin", CharacterFrame, "BackdropTemplate")
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
    if CharacterFramePortrait then CharacterFramePortrait:Hide() end
    if CharacterFrame.Background then CharacterFrame.Background:Hide() end
    if CharacterFrame.NineSlice then CharacterFrame.NineSlice:Hide() end
    if CharacterFrameBg then CharacterFrameBg:Hide() end
    if CharacterStatsPane then CharacterStatsPane:Hide() end
end


local function SetCharacterFrameBgExtended(extended)
    if not customBg then
        CreateOrUpdateBackground()
    end
    if not customBg then return end

    customBg:ClearAllPoints()

    if extended then
        customBg:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 0, 0)
        customBg:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT",
            CONFIG.PANEL_WIDTH_EXTENSION, -CONFIG.PANEL_HEIGHT_EXTENSION)
    else
        customBg:SetAllPoints(CharacterFrame)
    end

    customBg:Show()
    HideBlizzardDecorations()
end


local function SkinReputationEntry(child)
    if child.preyCharSkinned then return end

    local sr, sg, sb, sa = GetSkinColors()
    local fontPath = GetFontPath()


    if child.Right then
        if child.Name then
            child.Name:SetFont(fontPath, 13, "")
            child.Name:SetTextColor(sr, sg, sb, 1)
        end


        local function UpdateCollapseIcon(texture, atlas)
            if not atlas or atlas == "Options_ListExpand_Right" or atlas == "Options_ListExpand_Right_Expanded" then
                if child.IsCollapsed and child:IsCollapsed() then
                    texture:SetAtlas("Soulbinds_Collection_CategoryHeader_Expand", true)
                else
                    texture:SetAtlas("Soulbinds_Collection_CategoryHeader_Collapse", true)
                end
            end
        end

        UpdateCollapseIcon(child.Right)
        UpdateCollapseIcon(child.HighlightRight)
        hooksecurefunc(child.Right, "SetAtlas", UpdateCollapseIcon)
        hooksecurefunc(child.HighlightRight, "SetAtlas", UpdateCollapseIcon)
    end


    local ReputationBar = child.Content and child.Content.ReputationBar
    if ReputationBar then
        ReputationBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")

        if ReputationBar.BarText then
            ReputationBar.BarText:SetFont(fontPath, 10, "")
            ReputationBar.BarText:SetTextColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], 1)
        end


        if not ReputationBar.preyBackdrop then
            local backdrop = CreateFrame("Frame", nil, ReputationBar:GetParent(), "BackdropTemplate")
            backdrop:SetFrameLevel(ReputationBar:GetFrameLevel())
            backdrop:SetPoint("TOPLEFT", ReputationBar, "TOPLEFT", -2, 2)
            backdrop:SetPoint("BOTTOMRIGHT", ReputationBar, "BOTTOMRIGHT", 2, -2)
            backdrop:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 2,
            })
            backdrop:SetBackdropColor(0, 0, 0, 0.9)
            backdrop:SetBackdropBorderColor(sr, sg, sb, 1)
            backdrop:Show()
            ReputationBar.preyBackdrop = backdrop
        end

        if child.Content.Name then
            child.Content.Name:SetFont(fontPath, 11, "")
        end
    end


    local ToggleCollapseButton = child.ToggleCollapseButton
    if ToggleCollapseButton and ToggleCollapseButton.RefreshIcon then
        local function UpdateToggleButton(button)
            local header = button.GetHeader and button:GetHeader()
            if not header then return end
            if header:IsCollapsed() then
                button:GetNormalTexture():SetAtlas("Gamepad_Expand", true)
                button:GetPushedTexture():SetAtlas("Gamepad_Expand", true)
            else
                button:GetNormalTexture():SetAtlas("Gamepad_Collapse", true)
                button:GetPushedTexture():SetAtlas("Gamepad_Collapse", true)
            end
        end
        hooksecurefunc(ToggleCollapseButton, "RefreshIcon", UpdateToggleButton)
        UpdateToggleButton(ToggleCollapseButton)
    end

    child.preyCharSkinned = true
end


local function SkinCurrencyEntry(child)
    if child.preyCharSkinned then return end

    local sr, sg, sb, sa = GetSkinColors()
    local fontPath = GetFontPath()


    if child.Right then
        if child.Name then
            child.Name:SetFont(fontPath, 13, "")
            child.Name:SetTextColor(sr, sg, sb, 1)
        end


        local function UpdateCollapseIcon(texture, atlas)
            if not atlas or atlas == "Options_ListExpand_Right" or atlas == "Options_ListExpand_Right_Expanded" then
                if child.IsCollapsed and child:IsCollapsed() then
                    texture:SetAtlas("Soulbinds_Collection_CategoryHeader_Expand", true)
                else
                    texture:SetAtlas("Soulbinds_Collection_CategoryHeader_Collapse", true)
                end
            end
        end

        UpdateCollapseIcon(child.Right)
        UpdateCollapseIcon(child.HighlightRight)
        hooksecurefunc(child.Right, "SetAtlas", UpdateCollapseIcon)
        hooksecurefunc(child.HighlightRight, "SetAtlas", UpdateCollapseIcon)
    end


    local CurrencyIcon = child.Content and child.Content.CurrencyIcon
    if CurrencyIcon then
        CurrencyIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        if not CurrencyIcon.preyBorder then
            local border = CreateFrame("Frame", nil, CurrencyIcon:GetParent(), "BackdropTemplate")
            local drawLayer = CurrencyIcon.GetDrawLayer and CurrencyIcon:GetDrawLayer()
            border:SetFrameLevel((drawLayer == "OVERLAY") and child:GetFrameLevel() + 2 or child:GetFrameLevel() + 1)
            border:SetPoint("TOPLEFT", CurrencyIcon, "TOPLEFT", -1, 1)
            border:SetPoint("BOTTOMRIGHT", CurrencyIcon, "BOTTOMRIGHT", 1, -1)
            border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            border:SetBackdropBorderColor(sr, sg, sb, 1)
            CurrencyIcon.preyBorder = border
        end
    end


    if child.Content then
        if child.Content.Name then
            child.Content.Name:SetFont(fontPath, 11, "")
        end
        if child.Content.Count then
            child.Content.Count:SetFont(fontPath, 11, "")
        end
    end


    local ToggleCollapseButton = child.ToggleCollapseButton
    if ToggleCollapseButton and ToggleCollapseButton.RefreshIcon then
        local function UpdateToggleButton(button)
            local header = button.GetHeader and button:GetHeader()
            if not header then return end
            if header:IsCollapsed() then
                button:GetNormalTexture():SetAtlas("Gamepad_Expand", true)
                button:GetPushedTexture():SetAtlas("Gamepad_Expand", true)
            else
                button:GetNormalTexture():SetAtlas("Gamepad_Collapse", true)
                button:GetPushedTexture():SetAtlas("Gamepad_Collapse", true)
            end
        end
        hooksecurefunc(ToggleCollapseButton, "RefreshIcon", UpdateToggleButton)
        UpdateToggleButton(ToggleCollapseButton)
    end

    child.preyCharSkinned = true
end


local function SetupCharacterFrameSkinning()
    if not IsSkinningEnabled() then return end
    if not CharacterFrame then return end


    CreateOrUpdateBackground()


    if ReputationFrame and ReputationFrame.ScrollBox then
        hooksecurefunc(ReputationFrame.ScrollBox, "Update", function(frame)
            if IsSkinningEnabled() then
                frame:ForEachFrame(SkinReputationEntry)
            end
        end)
    end


    if TokenFrame and TokenFrame.ScrollBox then
        hooksecurefunc(TokenFrame.ScrollBox, "Update", function(frame)
            if IsSkinningEnabled() then
                frame:ForEachFrame(SkinCurrencyEntry)
            end
        end)
    end


    if ReputationFrame then
        ReputationFrame:HookScript("OnShow", function()
            if IsSkinningEnabled() then
                SetCharacterFrameBgExtended(false)
            end
        end)

        if ReputationFrame:IsShown() then
            SetCharacterFrameBgExtended(false)
        end
    end

    if TokenFrame then
        TokenFrame:HookScript("OnShow", function()
            if IsSkinningEnabled() then
                SetCharacterFrameBgExtended(false)
            end
        end)

        if TokenFrame:IsShown() then
            SetCharacterFrameBgExtended(false)
        end
    end


    if PaperDollFrame then
        PaperDollFrame:HookScript("OnShow", function()
            if IsSkinningEnabled() then

                local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
                local charSettings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.character

                local charPaneEnabled = charSettings and charSettings.enabled
                if charPaneEnabled == nil then charPaneEnabled = true end

                if not charPaneEnabled then

                    SetCharacterFrameBgExtended(false)
                end

            end
        end)

        if PaperDollFrame:IsShown() then
            local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
            local charSettings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.character

            local charPaneEnabled = charSettings and charSettings.enabled
            if charPaneEnabled == nil then charPaneEnabled = true end
            if not charPaneEnabled then
                SetCharacterFrameBgExtended(false)
            end
        end
    end


    CharacterFrame:HookScript("OnShow", function()
        C_Timer.After(0.01, function()
            if IsSkinningEnabled() and not (PaperDollFrame and PaperDollFrame:IsShown()) then
                SetCharacterFrameBgExtended(false)
            end
        end)
    end)
end


local RefreshEquipmentManagerColors
local RefreshTitlePaneColors

local function RefreshCharacterFrameColors()
    if not IsSkinningEnabled() then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()


    if customBg then
        customBg:SetBackdropColor(bgr, bgg, bgb, bga)
        customBg:SetBackdropBorderColor(sr, sg, sb, sa)
    end


    if ReputationFrame and ReputationFrame.ScrollBox then
        ReputationFrame.ScrollBox:ForEachFrame(function(child)
            if not child.preyCharSkinned then return end
            if child.Right and child.Name then
                child.Name:SetTextColor(sr, sg, sb, 1)
            end
            local ReputationBar = child.Content and child.Content.ReputationBar
            if ReputationBar and ReputationBar.preyBackdrop then
                ReputationBar.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, 1)
            end
        end)
    end


    if TokenFrame and TokenFrame.ScrollBox then
        TokenFrame.ScrollBox:ForEachFrame(function(child)
            if not child.preyCharSkinned then return end
            if child.Right and child.Name then
                child.Name:SetTextColor(sr, sg, sb, 1)
            end
            local CurrencyIcon = child.Content and child.Content.CurrencyIcon
            if CurrencyIcon and CurrencyIcon.preyBorder then
                CurrencyIcon.preyBorder:SetBackdropBorderColor(sr, sg, sb, 1)
            end
        end)
    end


    if RefreshEquipmentManagerColors then RefreshEquipmentManagerColors() end


    if RefreshTitlePaneColors then RefreshTitlePaneColors() end
end


local function SkinEquipmentSetEntry(entry)
    if entry.preyCharSkinned then return end

    local sr, sg, sb, sa = GetSkinColors()
    local fontPath = GetFontPath()


    if entry.text then
        entry.text:SetFont(fontPath, 11, "")
        entry.text:SetTextColor(0.9, 0.9, 0.9, 1)
    end


    if entry.icon and not entry.icon.preyBorder then
        entry.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local border = CreateFrame("Frame", nil, entry, "BackdropTemplate")
        border:SetPoint("TOPLEFT", entry.icon, "TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", entry.icon, "BOTTOMRIGHT", 1, -1)
        border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        border:SetBackdropBorderColor(sr, sg, sb, 1)
        entry.icon.preyBorder = border
    end


    if entry.SelectedBar then
        entry.SelectedBar:SetColorTexture(sr, sg, sb, 0.3)
    end
    if entry.HighlightBar then
        entry.HighlightBar:SetColorTexture(sr, sg, sb, 0.15)
    end

    entry.preyCharSkinned = true
end


local function StyleEquipMgrButton(btn)
    if not btn or btn.preyCharSkinned then return end

    local sr, sg, sb, sa = GetSkinColors()
    local fontPath = GetFontPath()


    local origWidth = btn:GetWidth()


    if btn:GetNormalTexture() then btn:GetNormalTexture():SetTexture(nil) end
    if btn:GetHighlightTexture() then btn:GetHighlightTexture():SetTexture(nil) end
    if btn:GetPushedTexture() then btn:GetPushedTexture():SetTexture(nil) end
    if btn:GetDisabledTexture() then btn:GetDisabledTexture():SetTexture(nil) end


    if not btn.SetBackdrop then
        Mixin(btn, BackdropTemplateMixin)
    end
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    btn:SetBackdropBorderColor(sr, sg, sb, 0.5)


    local text = btn:GetFontString()
    if text then
        text:SetFont(fontPath, 11, "")
        text:SetTextColor(0.9, 0.9, 0.9, 1)
    end


    btn:SetWidth(origWidth)


    btn:HookScript("OnEnter", function(self)
        local r, g, b = GetSkinColors()
        self:SetBackdropBorderColor(r, g, b, 1)
    end)
    btn:HookScript("OnLeave", function(self)
        local r, g, b = GetSkinColors()
        self:SetBackdropBorderColor(r, g, b, 0.5)
    end)

    btn.preyCharSkinned = true
end


local function SkinEquipmentManager()
    if not IsSkinningEnabled() then return end

    local popup = _G.PreyUI_EquipMgrPopup
    if not popup then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()
    local fontPath = GetFontPath()


    if not popup.preyCharSkinned then
        popup:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        popup.preyCharSkinned = true
    end
    popup:SetBackdropColor(bgr, bgg, bgb, bga)
    popup:SetBackdropBorderColor(sr, sg, sb, sa)


    if popup.title then
        popup.title:SetFont(fontPath, 12, "")
        popup.title:SetTextColor(sr, sg, sb, 1)
    end


    local pane = PaperDollFrame and PaperDollFrame.EquipmentManagerPane
    if pane and pane.ScrollBox then

        if not pane.ScrollBox.preyCharHooked then
            hooksecurefunc(pane.ScrollBox, "Update", function(scrollBox)
                if IsSkinningEnabled() then
                    scrollBox:ForEachFrame(SkinEquipmentSetEntry)
                end
            end)
            pane.ScrollBox.preyCharHooked = true
        end

        pane.ScrollBox:ForEachFrame(SkinEquipmentSetEntry)
    end


    StyleEquipMgrButton(PaperDollFrameEquipSet)
    StyleEquipMgrButton(PaperDollFrameSaveSet)
end


RefreshEquipmentManagerColors = function()
    if not IsSkinningEnabled() then return end

    local popup = _G.PreyUI_EquipMgrPopup
    if not popup or not popup.preyCharSkinned then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()


    popup:SetBackdropColor(bgr, bgg, bgb, bga)
    popup:SetBackdropBorderColor(sr, sg, sb, sa)
    if popup.title then
        popup.title:SetTextColor(sr, sg, sb, 1)
    end


    local pane = PaperDollFrame and PaperDollFrame.EquipmentManagerPane
    if pane and pane.ScrollBox then
        pane.ScrollBox:ForEachFrame(function(entry)
            if not entry.preyCharSkinned then return end
            if entry.icon and entry.icon.preyBorder then
                entry.icon.preyBorder:SetBackdropBorderColor(sr, sg, sb, 1)
            end
            if entry.SelectedBar then
                entry.SelectedBar:SetColorTexture(sr, sg, sb, 0.3)
            end
            if entry.HighlightBar then
                entry.HighlightBar:SetColorTexture(sr, sg, sb, 0.15)
            end
        end)
    end


    if PaperDollFrameEquipSet and PaperDollFrameEquipSet.preyCharSkinned then
        PaperDollFrameEquipSet:SetBackdropBorderColor(sr, sg, sb, 0.5)
    end
    if PaperDollFrameSaveSet and PaperDollFrameSaveSet.preyCharSkinned then
        PaperDollFrameSaveSet:SetBackdropBorderColor(sr, sg, sb, 0.5)
    end
end


local function SkinTitleEntry(button)
    if button.preyCharSkinned then return end

    local sr, sg, sb, sa = GetSkinColors()
    local fontPath = GetFontPath()


    if button.text then
        button.text:SetFont(fontPath, 12, "")
        button.text:SetTextColor(0.9, 0.9, 0.9, 1)
    end


    if button.Check then
        button.Check:SetVertexColor(sr, sg, sb, 1)
    end


    if button.SelectedBar then
        button.SelectedBar:SetColorTexture(sr, sg, sb, 0.3)
    end


    if button.BgTop then button.BgTop:Hide() end
    if button.BgMiddle then button.BgMiddle:Hide() end
    if button.BgBottom then button.BgBottom:Hide() end


    if button.Highlight then
        button.Highlight:SetColorTexture(sr, sg, sb, 0.15)
    elseif not button.preyHighlight then
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(sr, sg, sb, 0.15)
        button.preyHighlight = highlight
    end

    button.preyCharSkinned = true
end


local function SkinTitleManagerPane()
    if not IsSkinningEnabled() then return end

    local popup = _G.PreyUI_TitlesPopup
    local pane = PaperDollFrame and PaperDollFrame.TitleManagerPane
    if not pane then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()
    local fontPath = GetFontPath()


    if popup and not popup.preyCharSkinned then
        popup:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        popup:SetBackdropColor(bgr, bgg, bgb, bga)
        popup:SetBackdropBorderColor(sr, sg, sb, sa)


        if popup.title then
            popup.title:SetFont(fontPath, 14, "")
            popup.title:SetTextColor(sr, sg, sb, 1)
        end

        popup.preyCharSkinned = true
    end


    if pane.preyCharSkinned then return end


    if pane.Bg then pane.Bg:Hide() end


    if pane.ScrollBox then

        hooksecurefunc(pane.ScrollBox, "Update", function(scrollBox)
            scrollBox:ForEachFrame(function(button)
                SkinTitleEntry(button)
            end)
        end)


        pane.ScrollBox:ForEachFrame(function(button)
            SkinTitleEntry(button)
        end)
    end


    if pane.ScrollBar then
        local scrollBar = pane.ScrollBar
        if scrollBar.Track then
            scrollBar.Track:SetAlpha(0.3)
        end
        if scrollBar.Thumb then
            scrollBar.Thumb:SetAlpha(0.5)
        end
    end

    pane.preyCharSkinned = true
end


RefreshTitlePaneColors = function()
    if not IsSkinningEnabled() then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetSkinColors()


    local popup = _G.PreyUI_TitlesPopup
    if popup and popup.preyCharSkinned then
        popup:SetBackdropColor(bgr, bgg, bgb, bga)
        popup:SetBackdropBorderColor(sr, sg, sb, sa)
        if popup.title then
            popup.title:SetTextColor(sr, sg, sb, 1)
        end
    end


    local pane = PaperDollFrame and PaperDollFrame.TitleManagerPane
    if not pane or not pane.preyCharSkinned then return end

    if pane.ScrollBox then
        pane.ScrollBox:ForEachFrame(function(button)
            if not button.preyCharSkinned then return end
            if button.Check then
                button.Check:SetVertexColor(sr, sg, sb, 1)
            end
            if button.SelectedBar then
                button.SelectedBar:SetColorTexture(sr, sg, sb, 0.3)
            end
            if button.preyHighlight then
                button.preyHighlight:SetColorTexture(sr, sg, sb, 0.15)
            end
        end)
    end
end


local function SetupTitlePaneHook()
    if PaperDollFrame and PaperDollFrame.TitleManagerPane then
        PaperDollFrame.TitleManagerPane:HookScript("OnShow", function()
            SkinTitleManagerPane()
        end)
    end
end


_G.PREY_CharacterFrameSkinning = {

    CONFIG = CONFIG,


    IsEnabled = IsSkinningEnabled,
    SetExtended = SetCharacterFrameBgExtended,
    Refresh = RefreshCharacterFrameColors,


    SkinEquipmentManager = SkinEquipmentManager,
    SkinTitleManager = SkinTitleManagerPane,
}


_G.PreyUI_RefreshCharacterFrameColors = RefreshCharacterFrameColors


_G.PREY_SkinEquipmentManager = SkinEquipmentManager
_G.PREY_SkinTitleManager = SkinTitleManagerPane
_G.PREY_SetCharacterFrameBgExtended = SetCharacterFrameBgExtended


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == "Blizzard_CharacterFrame" then
        C_Timer.After(0.1, function()
            SetupCharacterFrameSkinning()
            SetupTitlePaneHook()
        end)
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
