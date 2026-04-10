local _, PREY = ...
local pendingObjectiveTrackerUpdate = false


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then
        return nil
    end

    if not PREYCore.db.profile.uiHider then
        PREYCore.db.profile.uiHider = {
            hideObjectiveTrackerAlways = false,
            hideObjectiveTrackerInstanceTypes = {
                mythicPlus = false,
                mythicDungeon = false,
                normalDungeon = false,
                heroicDungeon = false,
                followerDungeon = false,
                raid = false,
                pvp = false,
                arena = false,
            },
            hideMinimapBorder = false,
            hideTimeManager = false,
            hideGameTime = false,
            hideRaidFrameManager = false,
            hideMinimapZoneText = false,
            hideBuffCollapseButton = false,
            hideFriendlyPlayerNameplates = false,
            hideFriendlyNPCNameplates = false,
            hideTalkingHead = true,
            hideExperienceBar = false,
            hideReputationBar = false,
            hideErrorMessages = false,
            hideWorldMapBlackout = false,
        }
    end


    local uiHider = PREYCore.db.profile.uiHider
    if uiHider.hideObjectiveTracker ~= nil then
        if uiHider.hideObjectiveTrackerAlways == nil then
            uiHider.hideObjectiveTrackerAlways = uiHider.hideObjectiveTracker
        end
        uiHider.hideObjectiveTracker = nil
    end


    if uiHider.hideObjectiveTrackerInInstances ~= nil then
        if not uiHider.hideObjectiveTrackerInstanceTypes then
            if uiHider.hideObjectiveTrackerInInstances then

                uiHider.hideObjectiveTrackerInstanceTypes = {
                    mythicPlus = true,
                    mythicDungeon = true,
                    normalDungeon = true,
                    heroicDungeon = true,
                    followerDungeon = true,
                    raid = true,
                    pvp = true,
                    arena = true,
                }
            else

                uiHider.hideObjectiveTrackerInstanceTypes = {
                    mythicPlus = false,
                    mythicDungeon = false,
                    normalDungeon = false,
                    heroicDungeon = false,
                    followerDungeon = false,
                    raid = true,
                    pvp = false,
                    arena = false,
                }
            end
        end
        uiHider.hideObjectiveTrackerInInstances = nil
    elseif not uiHider.hideObjectiveTrackerInstanceTypes then

        uiHider.hideObjectiveTrackerInstanceTypes = {
            mythicPlus = false,
            mythicDungeon = false,
            normalDungeon = false,
            heroicDungeon = false,
            followerDungeon = false,
            raid = false,
            pvp = false,
            arena = false,
        }
    end

    return uiHider
end


local function IsInMythicPlus()
    local _, instanceType, difficulty = GetInstanceInfo()
    return instanceType == "party" and difficulty == 8
end


local function IsInNormalDungeon()
    local _, instanceType, difficulty = GetInstanceInfo()
    return instanceType == "party" and difficulty == 1
end


local function IsInHeroicDungeon()
    local _, instanceType, difficulty = GetInstanceInfo()
    return instanceType == "party" and difficulty == 2
end


local function IsInMythicDungeon()
    local _, instanceType, difficulty = GetInstanceInfo()
    return instanceType == "party" and difficulty == 23
end


local function IsInFollowerDungeon()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "party" then
        return false
    end
    local _, _, difficulty = GetInstanceInfo()
    return difficulty == 205
end


local function ShouldHideInCurrentInstance(instanceTypes)
    if not instanceTypes then return false end

    local inInstance, instanceType = IsInInstance()
    if not inInstance or not instanceType then return false end


    if instanceType == "party" then
        if IsInFollowerDungeon() and instanceTypes.followerDungeon then
            return true
        elseif IsInMythicPlus() and instanceTypes.mythicPlus then
            return true
        elseif IsInMythicDungeon() and instanceTypes.mythicDungeon then
            return true
        elseif IsInNormalDungeon() and instanceTypes.normalDungeon then
            return true
        elseif IsInHeroicDungeon() and instanceTypes.heroicDungeon then
            return true
        end

    elseif instanceTypes[instanceType] then
        return true
    end

    return false
end


local function ApplyWorldMapBlackoutState()
    local settings = GetSettings()
    if not settings or not WorldMapFrame or not WorldMapFrame.BlackoutFrame then
        return
    end


end


local function ApplyHideSettings()
    local settings = GetSettings()
    if not settings then
        return
    end


    if ObjectiveTrackerFrame then
        local function ApplyObjectiveTrackerStateDeferred()
            pendingObjectiveTrackerUpdate = false

            local s = GetSettings()
            if not s or not ObjectiveTrackerFrame then
                return
            end

            local shouldHideNow = false
            if s.hideObjectiveTrackerAlways then
                shouldHideNow = true
            elseif ShouldHideInCurrentInstance(s.hideObjectiveTrackerInstanceTypes) then
                shouldHideNow = true
            end


            if shouldHideNow then
                ObjectiveTrackerFrame:SetAlpha(0)
                ObjectiveTrackerFrame:EnableMouse(false)
                if ObjectiveTrackerFrame.SetCollapsed then
                    ObjectiveTrackerFrame:SetCollapsed(true)
                end
            else
                ObjectiveTrackerFrame:SetAlpha(1)
                ObjectiveTrackerFrame:EnableMouse(true)
                if ObjectiveTrackerFrame.SetCollapsed then
                    ObjectiveTrackerFrame:SetCollapsed(false)
                end
            end
        end

        if InCombatLockdown() then
            pendingObjectiveTrackerUpdate = true
        else
            C_Timer.After(0, ApplyObjectiveTrackerStateDeferred)
        end


        if not ObjectiveTrackerFrame._PREY_UpdateHooked and ObjectiveTrackerFrame.Update then
            ObjectiveTrackerFrame._PREY_UpdateHooked = true
            hooksecurefunc(ObjectiveTrackerFrame, "Update", function()
                local s = GetSettings()
                if not s then return end

                local shouldHideNow = false
                if s.hideObjectiveTrackerAlways then
                    shouldHideNow = true
                elseif ShouldHideInCurrentInstance(s.hideObjectiveTrackerInstanceTypes) then
                    shouldHideNow = true
                end

                if shouldHideNow then
                    C_Timer.After(0, function()
                        if InCombatLockdown() then
                            pendingObjectiveTrackerUpdate = true
                            return
                        end
                        if ObjectiveTrackerFrame then
                            ObjectiveTrackerFrame:SetAlpha(0)
                            ObjectiveTrackerFrame:EnableMouse(false)
                            if ObjectiveTrackerFrame.SetCollapsed then
                                ObjectiveTrackerFrame:SetCollapsed(true)
                            end
                        end
                    end)
                end
            end)
        end

    else


    end


    if MinimapCluster and MinimapCluster.BorderTop then
        if settings.hideMinimapBorder then
        MinimapCluster.BorderTop:Hide()
        else
            MinimapCluster.BorderTop:Show()
        end
    end


    if TimeManagerClockButton then
        if settings.hideTimeManager then
        TimeManagerClockButton:Hide()
        else
            TimeManagerClockButton:Show()
        end
    end


    if GameTimeFrame then
        if settings.hideGameTime then
            GameTimeFrame:Hide()
        else
            GameTimeFrame:Show()
        end

        if not GameTimeFrame._PREY_ShowHooked then
            GameTimeFrame._PREY_ShowHooked = true
            hooksecurefunc(GameTimeFrame, "Show", function(self)
                local s = GetSettings()
                if s and s.hideGameTime then
                    self:Hide()
                end
            end)
        end
    end


    if CompactRaidFrameManager then
        if InCombatLockdown() then

        elseif settings.hideRaidFrameManager then
            CompactRaidFrameManager:Hide()
            CompactRaidFrameManager:EnableMouse(false)


            if not CompactRaidFrameManager._PREY_ShowHooked then
                CompactRaidFrameManager._PREY_ShowHooked = true
                hooksecurefunc(CompactRaidFrameManager, "Show", function(self)
                    C_Timer.After(0, function()
                        if InCombatLockdown() then return end
                        local s = GetSettings()
                        if s and s.hideRaidFrameManager then
                            self:Hide()
                            self:EnableMouse(false)
                        end
                    end)
                end)
            end


            if not CompactRaidFrameManager._PREY_SetShownHooked then
                CompactRaidFrameManager._PREY_SetShownHooked = true
                hooksecurefunc(CompactRaidFrameManager, "SetShown", function(self, shown)
                    C_Timer.After(0, function()
                        if InCombatLockdown() then return end
                        local s = GetSettings()
                        if s and s.hideRaidFrameManager and shown then
                            self:Hide()
                            self:EnableMouse(false)
                        end
                    end)
                end)
            end
        else
            CompactRaidFrameManager:Show()
            CompactRaidFrameManager:EnableMouse(true)
        end
    end


    if MinimapZoneText then
        if settings.hideMinimapZoneText then
        MinimapZoneText:Hide()
        else
            MinimapZoneText:Show()
    end
end


    if BuffFrame and BuffFrame.CollapseAndExpandButton then
        local btn = BuffFrame.CollapseAndExpandButton
        if settings.hideBuffCollapseButton then

            if btn.NormalTexture then btn.NormalTexture:SetAlpha(0) end
            if btn.PushedTexture then btn.PushedTexture:SetAlpha(0) end
            if btn.HighlightTexture then btn.HighlightTexture:SetAlpha(0) end

            btn:EnableMouse(false)


            if not btn._PREY_AlphaHooked then
                btn._PREY_AlphaHooked = true
                local function BlockAlpha(texture, alpha)
                    local s = GetSettings()
                    if s and s.hideBuffCollapseButton and alpha > 0 then
                        texture:SetAlpha(0)
                    end
                end
                if btn.NormalTexture then hooksecurefunc(btn.NormalTexture, "SetAlpha", BlockAlpha) end
                if btn.PushedTexture then hooksecurefunc(btn.PushedTexture, "SetAlpha", BlockAlpha) end
                if btn.HighlightTexture then hooksecurefunc(btn.HighlightTexture, "SetAlpha", BlockAlpha) end
            end
        else

            if btn.NormalTexture then btn.NormalTexture:SetAlpha(1) end
            if btn.PushedTexture then btn.PushedTexture:SetAlpha(1) end
            if btn.HighlightTexture then btn.HighlightTexture:SetAlpha(1) end
            btn:EnableMouse(true)
        end
    end


    if settings.hideFriendlyPlayerNameplates then
        SetCVar("nameplateShowFriendlyPlayers", "0")
    else
        SetCVar("nameplateShowFriendlyPlayers", "1")
end


    if settings.hideFriendlyNPCNameplates then
        SetCVar("nameplateShowFriendlyNPCs", "0")
    else
        SetCVar("nameplateShowFriendlyNPCs", "1")
    end


    if TalkingHeadFrame then

        local function DisableTalkingHeadMouse()
            TalkingHeadFrame:EnableMouse(false)


            local childrenToDisable = {
                "MainFrame",
                "PortraitFrame",
                "BackgroundFrame",
                "TextFrame",
                "NameFrame",
            }
            for _, childName in ipairs(childrenToDisable) do
                local child = TalkingHeadFrame[childName]
                if child and child.EnableMouse then
                    child:EnableMouse(false)
                end
            end
        end


        local function EnableTalkingHeadMouse()
            TalkingHeadFrame:EnableMouse(true)
            local childrenToEnable = {
                "MainFrame",
                "PortraitFrame",
                "BackgroundFrame",
                "TextFrame",
                "NameFrame",
            }
            for _, childName in ipairs(childrenToEnable) do
                local child = TalkingHeadFrame[childName]
                if child and child.EnableMouse then
                    child:EnableMouse(true)
                end
            end
        end

        if settings.hideTalkingHead then
            TalkingHeadFrame:Hide()
            DisableTalkingHeadMouse()


            if not TalkingHeadFrame._PREY_ShowHooked then
                TalkingHeadFrame._PREY_ShowHooked = true
                hooksecurefunc(TalkingHeadFrame, "Show", function(self)
                    local s = GetSettings()
                    if s and s.hideTalkingHead then
                        self:Hide()
                        DisableTalkingHeadMouse()
                    end
                end)
            end
        else


            if not TalkingHeadFrame._PREY_MouseManaged then
                TalkingHeadFrame._PREY_MouseManaged = true


                DisableTalkingHeadMouse()


                hooksecurefunc(TalkingHeadFrame, "PlayCurrent", function()
                    EnableTalkingHeadMouse()
                end)


                TalkingHeadFrame:HookScript("OnHide", function()
                    DisableTalkingHeadMouse()
                end)
            end
        end


        if not TalkingHeadFrame._PREY_MuteHooked then
            TalkingHeadFrame._PREY_MuteHooked = true
            hooksecurefunc(TalkingHeadFrame, "PlayCurrent", function()
                local s = GetSettings()
                if s and s.muteTalkingHead and TalkingHeadFrame.voHandle then
                    StopSound(TalkingHeadFrame.voHandle, 0)
                    TalkingHeadFrame.voHandle = nil
                end
            end)
        end
    end


    if StatusTrackingBarManager then
        local hideXP = settings.hideExperienceBar
        local hideRep = settings.hideReputationBar


        local BarsEnum = StatusTrackingBarInfo and StatusTrackingBarInfo.BarsEnum
        local BARS_ENUM_EXPERIENCE = BarsEnum and BarsEnum.Experience or 4
        local BARS_ENUM_REPUTATION = BarsEnum and BarsEnum.Reputation or 1


        local function HideStatusBars()
            local s = GetSettings()
            if not s then return end

            local doHideXP = s.hideExperienceBar
            local doHideRep = s.hideReputationBar


            if doHideXP and doHideRep then
                StatusTrackingBarManager:Hide()
                return
            end


            StatusTrackingBarManager:Show()


            if StatusTrackingBarManager.barContainers then
                for _, container in ipairs(StatusTrackingBarManager.barContainers) do
                    local shownBarIndex = container.shownBarIndex

                    if shownBarIndex == BARS_ENUM_EXPERIENCE and doHideXP then
                        container:SetAlpha(0)
                        container:EnableMouse(false)
                    elseif shownBarIndex == BARS_ENUM_REPUTATION and doHideRep then
                        container:SetAlpha(0)
                        container:EnableMouse(false)
                    else
                        container:SetAlpha(1)
                        container:EnableMouse(true)
                    end
                end
            end
        end


        if hideXP and hideRep then
            StatusTrackingBarManager:Hide()

            if not StatusTrackingBarManager._PREY_ShowHooked then
                StatusTrackingBarManager._PREY_ShowHooked = true
                hooksecurefunc(StatusTrackingBarManager, "Show", function(self)
                    local s = GetSettings()
                    if s and s.hideExperienceBar and s.hideReputationBar then
                        self:Hide()
                    end
                end)
            end
        elseif hideXP or hideRep then

            StatusTrackingBarManager:Show()
            if StatusTrackingBarManager.barContainers then
                HideStatusBars()
            end


            if not StatusTrackingBarManager._PREY_BarsHooked then
                StatusTrackingBarManager._PREY_BarsHooked = true
                hooksecurefunc(StatusTrackingBarManager, "UpdateBarsShown", function()
                    C_Timer.After(0.01, HideStatusBars)
                end)
            end
        end

    end


    if UIErrorsFrame then
        if settings.hideErrorMessages then
            UIErrorsFrame:Hide()
            UIErrorsFrame:EnableMouse(false)
            UIErrorsFrame:UnregisterAllEvents()
        else
            UIErrorsFrame:Show()
            UIErrorsFrame:EnableMouse(false)
            UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
            UIErrorsFrame:RegisterEvent("UI_INFO_MESSAGE")
        end
    end


    ApplyWorldMapBlackoutState()
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:RegisterEvent("CHALLENGE_MODE_RESET")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event, addon)
    local settings = GetSettings()

    if event == "PLAYER_REGEN_ENABLED" then
        if pendingObjectiveTrackerUpdate then
            pendingObjectiveTrackerUpdate = false
            C_Timer.After(0, ApplyHideSettings)
        end
        return
    end


    if event == "ADDON_LOADED" and addon == "Blizzard_TalkingHeadUI" then

        if settings then
            _G.PreyUI_RefreshUIHider()
        end
        return
    end


    if event == "ADDON_LOADED" and addon == "Blizzard_WorldMap" then
        if settings then
            C_Timer.After(0, ApplyWorldMapBlackoutState)
        end
        return
    end


    if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED" then
        if settings and settings.hideRaidFrameManager and CompactRaidFrameManager then
            C_Timer.After(0, function()
                if not InCombatLockdown() then
                    CompactRaidFrameManager:Hide()
                    CompactRaidFrameManager:EnableMouse(false)
                end
            end)
        end
        return
    end


    if settings then
        ApplyHideSettings()
    end
end)


PREY.UIHider = {
    ApplySettings = ApplyHideSettings,
}


_G.PreyUI_RefreshUIHider = function()
    ApplyHideSettings()
end
