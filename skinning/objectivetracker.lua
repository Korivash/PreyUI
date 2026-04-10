local addonName, ns = ...


local FONT_FLAGS = "OUTLINE"


local pendingBackdropUpdate = false


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
    return settings
end


local function GetColors()
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


local function SafeSetTextColor(fontString, colorTable)
    if not fontString or not colorTable then return end
    if type(colorTable) ~= "table" or #colorTable < 3 then return end
    fontString:SetTextColor(colorTable[1] or 1, colorTable[2] or 1, colorTable[3] or 1, colorTable[4] or 1)
end


local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)


local function StyleQuestPOIIcon(button)
    if not button or button.preyStyled then return end


    if button.NormalTexture then
        button.NormalTexture:SetAlpha(0)
    end
    if button.PushedTexture then
        button.PushedTexture:SetAlpha(0)
    end
    if button.HighlightTexture then
        button.HighlightTexture:SetAlpha(0.3)
    end


    if LCG and LCG.PixelGlow_Stop then
        LCG.PixelGlow_Stop(button, "_PREYQuestGlow")
    end

    button.preyStyled = true
end


local function StyleCompletionCheck(check)
    if not check or check.preyStyled then return end

    local sr, sg, sb = GetColors()
    check:SetAtlas("checkmark-minimal")
    check:SetDesaturated(true)
    check:SetVertexColor(sr, sg, sb)

    check.preyStyled = true
end


local function HandleQuestBlockIcons(tracker, block)
    if not block then return end


    local itemButton = block.ItemButton or block.itemButton
    if itemButton then
        StyleQuestPOIIcon(itemButton)
    end


    local check = block.currentLine and block.currentLine.Check
    if check then
        StyleCompletionCheck(check)
    end

end


local trackerModules = {
    "ScenarioObjectiveTracker",
    "UIWidgetObjectiveTracker",
    "CampaignQuestObjectiveTracker",
    "QuestObjectiveTracker",
    "AdventureObjectiveTracker",
    "AchievementObjectiveTracker",
    "MonthlyActivitiesObjectiveTracker",
    "ProfessionsRecipeTracker",
    "BonusObjectiveTracker",
    "WorldQuestObjectiveTracker",
}


local function SkinTrackerHeader(header)
    if not header then return end


    if header.Background then
        header.Background:SetAtlas(nil)
        header.Background:SetAlpha(0)
    end


    if header.Text then
        header.Text:ClearAllPoints()
        header.Text:SetPoint("LEFT", header, "LEFT", -7, 0)
        header.Text:SetJustifyH("LEFT")
    end
end


local function SyncBlizzardHeight()
    local TrackerFrame = _G.ObjectiveTrackerFrame
    if not TrackerFrame then return end

    local settings = GetSettings()
    local maxHeight = settings and settings.objectiveTrackerHeight or 600


    TrackerFrame.editModeHeight = maxHeight
    if TrackerFrame.UpdateHeight then
        TrackerFrame:UpdateHeight()
    end
end


local function HideScenarioStageArtwork()
    local scenario = _G.ScenarioObjectiveTracker
    if not scenario then return end

    local stageBlock = scenario.StageBlock
    if not stageBlock then return end


    if stageBlock.NormalBG then
        stageBlock.NormalBG:Hide()
        stageBlock.NormalBG:SetAlpha(0)
    end
    if stageBlock.FinalBG then
        stageBlock.FinalBG:Hide()
        stageBlock.FinalBG:SetAlpha(0)
    end
    if stageBlock.GlowTexture then
        stageBlock.GlowTexture:Hide()
        stageBlock.GlowTexture:SetAlpha(0)
    end


    if stageBlock.Stage then
        stageBlock.Stage:ClearAllPoints()
        stageBlock.Stage:SetPoint("TOPLEFT", stageBlock, "TOPLEFT", 0, -5)
        if stageBlock.Name then
            stageBlock.Name:ClearAllPoints()
            stageBlock.Name:SetPoint("TOPLEFT", stageBlock.Stage, "BOTTOMLEFT", 0, -2)
        end
    end
end


local function UpdateMinimizeButtonAtlas(btn, collapsed)
    if not btn then return end
    local normalTex = btn:GetNormalTexture()
    local pushedTex = btn:GetPushedTexture()
    if collapsed then
        if normalTex then normalTex:SetAtlas("ui-questtrackerbutton-secondary-expand") end
        if pushedTex then pushedTex:SetAtlas("ui-questtrackerbutton-secondary-expand-pressed") end
    else
        if normalTex then normalTex:SetAtlas("ui-questtrackerbutton-secondary-collapse") end
        if pushedTex then pushedTex:SetAtlas("ui-questtrackerbutton-secondary-collapse-pressed") end
    end
end


local function IsScenarioActive()
    local scenario = _G.ScenarioObjectiveTracker
    if not scenario or not scenario:IsShown() then return false end

    if scenario.GetContentsHeight then
        local height = scenario:GetContentsHeight()
        if height and height > 0 then return true end
    end
    return false
end


local function ApplyMaxWidth(settings)
    local TrackerFrame = _G.ObjectiveTrackerFrame
    if not TrackerFrame then return end


    local maxWidth
    if IsScenarioActive() then
        maxWidth = 260
    else
        maxWidth = settings and settings.objectiveTrackerWidth or 260
    end
    TrackerFrame:SetWidth(maxWidth)


    if TrackerFrame.Header then
        TrackerFrame.Header:SetWidth(maxWidth)
        local minBtn = TrackerFrame.Header.MinimizeButton
        if minBtn then

            minBtn:ClearAllPoints()
            minBtn:SetPoint("RIGHT", TrackerFrame.Header, "RIGHT", 0, 0)

            minBtn:SetSize(16, 16)

            if not minBtn.preyHighlightSet and minBtn:GetHighlightTexture() then
                minBtn:GetHighlightTexture():SetAtlas("ui-questtrackerbutton-yellow-highlight")
                minBtn.preyHighlightSet = true
            end
        end


        if TrackerFrame.Header.SetCollapsed and not TrackerFrame.Header.preySetCollapsedHooked then
            hooksecurefunc(TrackerFrame.Header, "SetCollapsed", function(self, collapsed)
                UpdateMinimizeButtonAtlas(self.MinimizeButton, collapsed)
            end)
            TrackerFrame.Header.preySetCollapsedHooked = true


            local isCollapsed = false
            if type(TrackerFrame.IsCollapsed) == "function" then
                isCollapsed = TrackerFrame:IsCollapsed()
            end
            UpdateMinimizeButtonAtlas(minBtn, isCollapsed)
        end
    end


    for _, trackerName in ipairs(trackerModules) do
        local tracker = rawget(_G, trackerName)
        if tracker then
            tracker:SetWidth(maxWidth)
            if tracker.Header then
                tracker.Header:SetWidth(maxWidth)
            end
        end
    end


    HideScenarioStageArtwork()
end


local function UpdateBackdropAnchors()
    local TrackerFrame = _G.ObjectiveTrackerFrame
    if not TrackerFrame or not TrackerFrame.preyBackdrop then return end

    local settings = GetSettings()
    local maxHeight = settings and settings.objectiveTrackerHeight or 600


    local bottomModule = nil
    local lowestBottom = math.huge

    for _, trackerName in ipairs(trackerModules) do
        local tracker = rawget(_G, trackerName)
        if tracker and tracker:IsShown() then

            local hasContent = false
            if tracker.GetContentsHeight then
                local contentHeight = tracker:GetContentsHeight()
                hasContent = contentHeight and contentHeight > 0
            end

            if not hasContent then
                local frameHeight = tracker:GetHeight()
                hasContent = frameHeight and frameHeight > 1
            end

            if hasContent then
                local bottom = tracker:GetBottom()
                if bottom and bottom < lowestBottom then
                    lowestBottom = bottom
                    bottomModule = tracker
                end
            end
        end
    end


    TrackerFrame.preyBackdrop:ClearAllPoints()
    TrackerFrame.preyBackdrop:SetPoint("TOPLEFT", TrackerFrame, "TOPLEFT", -15, 0)
    TrackerFrame.preyBackdrop:SetPoint("TOPRIGHT", TrackerFrame, "TOPRIGHT", 10, 0)

    if bottomModule then

        local trackerTop = TrackerFrame:GetTop()
        local contentHeight = 0
        if trackerTop and lowestBottom and trackerTop > lowestBottom then
            contentHeight = trackerTop - lowestBottom + 15
        end

        if contentHeight > maxHeight then

            TrackerFrame.preyBackdrop:SetHeight(maxHeight)
        else

            TrackerFrame.preyBackdrop:SetPoint("BOTTOM", bottomModule, "BOTTOM", 0, -15)
        end
        TrackerFrame.preyBackdrop:Show()
    else

        TrackerFrame.preyBackdrop:Hide()
    end
end


local function HidePOIButtonGlows()
    for _, trackerName in ipairs(trackerModules) do
        local tracker = rawget(_G, trackerName)
        if tracker and tracker.usedBlocks then
            for template, blocks in pairs(tracker.usedBlocks) do
                if type(blocks) == "table" then
                    for id, block in pairs(blocks) do

                        if block.poiButton and block.poiButton.Glow then
                            block.poiButton.Glow:Hide()
                            block.poiButton.Glow:SetAlpha(0)

                            if not block.poiButton.Glow.preyHooked then
                                hooksecurefunc(block.poiButton.Glow, "Show", function(self)
                                    self:Hide()
                                end)
                                block.poiButton.Glow.preyHooked = true
                            end
                        end

                        if LCG and LCG.PixelGlow_Stop and block.poiButton then
                            LCG.PixelGlow_Stop(block.poiButton, "_PREYQuestGlow")
                        end

                        local itemButton = block.ItemButton or block.itemButton
                        if LCG and LCG.PixelGlow_Stop and itemButton then
                            LCG.PixelGlow_Stop(itemButton, "_PREYQuestGlow")
                        end
                    end
                end
            end
        end
    end
end


local function ScheduleBackdropUpdate()
    if pendingBackdropUpdate then return end
    pendingBackdropUpdate = true
    C_Timer.After(0.15, function()
        pendingBackdropUpdate = false
        UpdateBackdropAnchors()
        HidePOIButtonGlows()
    end)
end


local function KillNineSlice(nineSlice)
    if not nineSlice then return end


    nineSlice:Hide()
    nineSlice:SetAlpha(0)


    for _, region in ipairs({nineSlice:GetRegions()}) do
        if region:IsObjectType("Texture") then
            region:SetTexture(nil)
            region:SetAtlas(nil)
            region:Hide()
        end
    end


    local parts = {"TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
                   "TopEdge", "BottomEdge", "LeftEdge", "RightEdge", "Center"}
    for _, part in ipairs(parts) do
        local tex = nineSlice[part]
        if tex then
            tex:SetTexture(nil)
            tex:SetAtlas(nil)
            tex:Hide()
        end
    end
end


local function ApplyPREYBackdrop(trackerFrame, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not trackerFrame then return end


    KillNineSlice(trackerFrame.NineSlice)


    if trackerFrame.SetBackgroundAlpha and not trackerFrame.preyBackgroundHooked then
        hooksecurefunc(trackerFrame, "SetBackgroundAlpha", function(self, alpha)

            if self.NineSlice then
                self.NineSlice:Hide()
                self.NineSlice:SetAlpha(0)
            end

            if self.preyBackdrop then
                local _, _, _, _, currBgR, currBgG, currBgB = GetColors()
                self.preyBackdrop:SetBackdropColor(currBgR, currBgG, currBgB, alpha)
            end
        end)
        trackerFrame.preyBackgroundHooked = true
    end


    local manager = _G.ObjectiveTrackerManager
    local opacity
    if manager and manager.backgroundAlpha ~= nil then
        opacity = manager.backgroundAlpha
    else
        opacity = bga or 0.95
    end


    if not trackerFrame.preyBackdrop then
        trackerFrame.preyBackdrop = CreateFrame("Frame", nil, trackerFrame, "BackdropTemplate")
        trackerFrame.preyBackdrop:SetFrameLevel(math.max(trackerFrame:GetFrameLevel() - 1, 0))
        trackerFrame.preyBackdrop:EnableMouse(false)
    end

    local settings = GetSettings()
    local hideBorder = settings and settings.hideObjectiveTrackerBorder

    trackerFrame.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = hideBorder and 0 or 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    trackerFrame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, opacity)
    if hideBorder then
        trackerFrame.preyBackdrop:SetBackdropBorderColor(0, 0, 0, 0)
    else
        trackerFrame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end


    UpdateBackdropAnchors()
end


local function GetFontPath()
    local PREY = _G.PreyUI
    return PREY and PREY.GetGlobalFont and PREY:GetGlobalFont() or STANDARD_TEXT_FONT
end


local function StyleLine(line, fontPath, textFontSize, textColor)
    if not line then return end
    if line.Text then
        line.Text:SetFont(fontPath, textFontSize, FONT_FLAGS)
        SafeSetTextColor(line.Text, textColor)
    end
    if line.Dash then
        line.Dash:SetFont(fontPath, textFontSize, FONT_FLAGS)
        SafeSetTextColor(line.Dash, textColor)
    end
end


local function StyleBlock(block, fontPath, titleFontSize, textFontSize, titleColor, textColor)
    if not block then return end


    if titleFontSize > 0 and block.HeaderText then
        block.HeaderText:SetFont(fontPath, titleFontSize, FONT_FLAGS)
        SafeSetTextColor(block.HeaderText, titleColor)
    end


    if textFontSize > 0 and block.usedLines then
        for _, line in pairs(block.usedLines) do
            StyleLine(line, fontPath, textFontSize, textColor)
        end
    end
end


local function ApplyFontStyles(moduleFontSize, titleFontSize, textFontSize, moduleColor, titleColor, textColor)
    local fontPath = GetFontPath()

    for _, trackerName in ipairs(trackerModules) do
        local tracker = rawget(_G, trackerName)
        if tracker then

            if moduleFontSize > 0 and tracker.Header and tracker.Header.Text then
                tracker.Header.Text:SetFont(fontPath, moduleFontSize, FONT_FLAGS)
                SafeSetTextColor(tracker.Header.Text, moduleColor)
            end


            if tracker.usedBlocks then
                for template, blocks in pairs(tracker.usedBlocks) do
                    for blockID, block in pairs(blocks) do
                        StyleBlock(block, fontPath, titleFontSize, textFontSize, titleColor, textColor)
                    end
                end
            end
        end
    end


    local TrackerFrame = _G.ObjectiveTrackerFrame
    if TrackerFrame and TrackerFrame.Header and TrackerFrame.Header.Text then
        if moduleFontSize > 0 then
            TrackerFrame.Header.Text:SetFont(fontPath, moduleFontSize, FONT_FLAGS)
            SafeSetTextColor(TrackerFrame.Header.Text, moduleColor)
        end
    end
end


local function HookLineCreation()
    local settings = GetSettings()
    if not settings then return end

    local textFontSize = settings.objectiveTrackerTextFontSize or 0
    if textFontSize <= 0 then return end

    local fontPath = GetFontPath()


    if ObjectiveTrackerBlockMixin and ObjectiveTrackerBlockMixin.AddObjective and not ObjectiveTrackerBlockMixin.preyAddObjectiveHooked then
        hooksecurefunc(ObjectiveTrackerBlockMixin, "AddObjective", function(self, objectiveKey, text, template, useFullHeight, dashStyle, colorStyle, adjustForNoText, overrideHeight)
            local line = self.usedLines and self.usedLines[objectiveKey]
            if line then
                local currentSettings = GetSettings()
                local currentTextSize = currentSettings and currentSettings.objectiveTrackerTextFontSize or 0
                local currentTextColor = currentSettings and currentSettings.objectiveTrackerTextColor
                if currentTextSize > 0 then
                    StyleLine(line, GetFontPath(), currentTextSize, currentTextColor)
                end
            end
        end)
        ObjectiveTrackerBlockMixin.preyAddObjectiveHooked = true
    end


    if ObjectiveTrackerBlockMixin and ObjectiveTrackerBlockMixin.SetHeader and not ObjectiveTrackerBlockMixin.preySetHeaderHooked then
        hooksecurefunc(ObjectiveTrackerBlockMixin, "SetHeader", function(self, text)
            local currentSettings = GetSettings()
            local currentTitleSize = currentSettings and currentSettings.objectiveTrackerTitleFontSize or 0
            local currentTitleColor = currentSettings and currentSettings.objectiveTrackerTitleColor
            if currentTitleSize > 0 and self.HeaderText then
                self.HeaderText:SetFont(GetFontPath(), currentTitleSize, FONT_FLAGS)
                SafeSetTextColor(self.HeaderText, currentTitleColor)
            end
        end)
        ObjectiveTrackerBlockMixin.preySetHeaderHooked = true
    end


end


local function SkinObjectiveTracker()
    local settings = GetSettings()
    if not settings or not settings.skinObjectiveTracker then return end

    local TrackerFrame = _G.ObjectiveTrackerFrame
    if not TrackerFrame then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetColors()


    SyncBlizzardHeight()


    ApplyMaxWidth(settings)


    ApplyPREYBackdrop(TrackerFrame, sr, sg, sb, sa, bgr, bgg, bgb, bga)


    local moduleFontSize = settings.objectiveTrackerModuleFontSize or 12
    local titleFontSize = settings.objectiveTrackerTitleFontSize or 10
    local textFontSize = settings.objectiveTrackerTextFontSize or 10
    local moduleColor = settings.objectiveTrackerModuleColor
    local titleColor = settings.objectiveTrackerTitleColor
    local textColor = settings.objectiveTrackerTextColor
    ApplyFontStyles(moduleFontSize, titleFontSize, textFontSize, moduleColor, titleColor, textColor)


    HookLineCreation()


    if TrackerFrame.Header then
        SkinTrackerHeader(TrackerFrame.Header)
    end


    for _, trackerName in ipairs(trackerModules) do
        local tracker = rawget(_G, trackerName)
        if tracker then
            SkinTrackerHeader(tracker.Header)
        end
    end


    if TrackerFrame.Update and not TrackerFrame.preyUpdateHooked then
        hooksecurefunc(TrackerFrame, "Update", ScheduleBackdropUpdate)
        TrackerFrame.preyUpdateHooked = true
    end


    if TrackerFrame.SetCollapsed and not TrackerFrame.preyCollapseHooked then
        hooksecurefunc(TrackerFrame, "SetCollapsed", ScheduleBackdropUpdate)
        TrackerFrame.preyCollapseHooked = true
    end


    for _, trackerName in ipairs(trackerModules) do
        local tracker = rawget(_G, trackerName)
        if tracker and not tracker.preyCollapseHooked then

            if tracker.Header and tracker.Header.MinimizeButton then
                tracker.Header.MinimizeButton:HookScript("OnClick", ScheduleBackdropUpdate)
            end


            if tracker.SetCollapsed then
                hooksecurefunc(tracker, "SetCollapsed", ScheduleBackdropUpdate)
            end


            if tracker.LayoutContents then
                hooksecurefunc(tracker, "LayoutContents", ScheduleBackdropUpdate)
            end


            if tracker.AddBlock and not tracker.preyAddBlockHooked then
                hooksecurefunc(tracker, "AddBlock", HandleQuestBlockIcons)
                tracker.preyAddBlockHooked = true
            end

            tracker.preyCollapseHooked = true
        end
    end


    if not TrackerFrame.preySizeChangedHooked then
        TrackerFrame:HookScript("OnSizeChanged", UpdateBackdropAnchors)
        TrackerFrame.preySizeChangedHooked = true
    end


    local manager = _G.ObjectiveTrackerManager
    if manager and manager.SetOpacity and not manager.preyOpacityHooked then
        hooksecurefunc(manager, "SetOpacity", function(self, opacityPercent)
            local alpha = (opacityPercent or 0) / 100
            local _, _, _, _, currBgR, currBgG, currBgB = GetColors()
            if TrackerFrame.preyBackdrop then
                TrackerFrame.preyBackdrop:SetBackdropColor(currBgR, currBgG, currBgB, alpha)
            end
        end)
        manager.preyOpacityHooked = true
    end


    C_Timer.After(0.5, HidePOIButtonGlows)

    TrackerFrame.preySkinned = true
end


local function RefreshObjectiveTracker()
    local settings = GetSettings()
    if not settings or not settings.skinObjectiveTracker then return end

    local TrackerFrame = _G.ObjectiveTrackerFrame
    if not TrackerFrame then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetColors()


    SyncBlizzardHeight()


    ApplyMaxWidth(settings)


    if TrackerFrame.preyBackdrop then
        local hideBorder = settings.hideObjectiveTrackerBorder


        local manager = _G.ObjectiveTrackerManager
        local opacity
        if manager and manager.backgroundAlpha ~= nil then
            opacity = manager.backgroundAlpha
        else
            opacity = bga or 0.95
        end


        TrackerFrame.preyBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = hideBorder and 0 or 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        TrackerFrame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, opacity)
        if hideBorder then
            TrackerFrame.preyBackdrop:SetBackdropBorderColor(0, 0, 0, 0)
        else
            TrackerFrame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        end
    end


    UpdateBackdropAnchors()


    local moduleFontSize = settings.objectiveTrackerModuleFontSize or 12
    local titleFontSize = settings.objectiveTrackerTitleFontSize or 10
    local textFontSize = settings.objectiveTrackerTextFontSize or 10
    local moduleColor = settings.objectiveTrackerModuleColor
    local titleColor = settings.objectiveTrackerTitleColor
    local textColor = settings.objectiveTrackerTextColor
    ApplyFontStyles(moduleFontSize, titleFontSize, textFontSize, moduleColor, titleColor, textColor)


    HookLineCreation()
end


_G.PreyUI_RefreshObjectiveTracker = RefreshObjectiveTracker
_G.PreyUI_RefreshObjectiveTrackerColors = RefreshObjectiveTracker


local trackingEvents = {

    "CONTENT_TRACKING_UPDATE",
    "TRACKED_ACHIEVEMENT_UPDATE",
    "TRACKED_ACHIEVEMENT_LIST_CHANGED",
    "ACHIEVEMENT_EARNED",

    "SUPER_TRACKING_CHANGED",
    "TRANSMOG_COLLECTION_SOURCE_ADDED",
    "TRACKING_TARGET_INFO_UPDATE",
    "TRACKABLE_INFO_UPDATE",
    "HOUSE_DECOR_ADDED_TO_CHEST",

    "CRITERIA_COMPLETE",
    "QUEST_TURNED_IN",
    "QUEST_LOG_UPDATE",
    "QUEST_WATCH_LIST_CHANGED",
    "SCENARIO_BONUS_VISIBILITY_UPDATE",
    "SCENARIO_CRITERIA_UPDATE",
    "SCENARIO_UPDATE",
    "QUEST_ACCEPTED",
    "QUEST_REMOVED",


    "PERKS_ACTIVITY_COMPLETED",
    "PERKS_ACTIVITIES_TRACKED_UPDATED",
    "PERKS_ACTIVITIES_TRACKED_LIST_CHANGED",

    "ZONE_CHANGED_NEW_AREA",
    "ZONE_CHANGED_INDOORS",

    "CURRENCY_DISPLAY_UPDATE",
    "TRACKED_RECIPE_UPDATE",
    "BAG_UPDATE_DELAYED",

    "QUEST_AUTOCOMPLETE",
    "QUEST_POI_UPDATE",

    "SCENARIO_SPELL_UPDATE",
    "SCENARIO_COMPLETED",
    "SCENARIO_CRITERIA_SHOW_STATE_UPDATE",


}

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then

        C_Timer.After(1, function()
            SkinObjectiveTracker()

            for _, trackEvent in ipairs(trackingEvents) do
                self:RegisterEvent(trackEvent)
            end
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    elseif event == "SUPER_TRACKING_CHANGED" then

        C_Timer.After(0.01, HidePOIButtonGlows)
        ScheduleBackdropUpdate()
    elseif event == "SCENARIO_UPDATE" or event == "SCENARIO_COMPLETED" then

        C_Timer.After(0.2, function()
            local settings = GetSettings()
            if settings and settings.skinObjectiveTracker then
                ApplyMaxWidth(settings)
            end
        end)
        ScheduleBackdropUpdate()
    else

        ScheduleBackdropUpdate()
    end
end)
