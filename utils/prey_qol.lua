local addonName, ns = ...


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        return PREYCore.db.profile.general
    end
    return nil
end

local qolFrame = CreateFrame("Frame")


local function OnMerchantShow()
    local settings = GetSettings()
    if not settings then return end


    if settings.sellJunk then
        for bag = 0, 4 do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.quality == Enum.ItemQuality.Poor then
                    C_Container.UseContainerItem(bag, slot)
                end
            end
        end
    end


    local repairMode = settings.autoRepair
    if repairMode and repairMode ~= "off" and CanMerchantRepair() then
        local repairCost = GetRepairAllCost()
        if repairCost and repairCost > 0 then
            if repairMode == "guild" then
                RepairAllItems(CanGuildBankRepair())
            else
                RepairAllItems(false)
            end
        end
    end
end


local function OnRoleCheckShow()
    local settings = GetSettings()
    if settings and settings.autoRoleAccept then
        CompleteLFGRoleCheck(true)
    end
end


local function IsFriendOrBNet(name)
    if not name then return false end

    if C_FriendList.IsFriend(name) then return true end

    local numBNetTotal = BNGetNumFriends()
    for i = 1, numBNetTotal do
        local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
        if accountInfo and accountInfo.gameAccountInfo then
            local charName = accountInfo.gameAccountInfo.characterName
            local realmName = accountInfo.gameAccountInfo.realmName
            if charName then
                local fullName = realmName and (charName .. "-" .. realmName) or charName
                if fullName == name or charName == name:match("^([^-]+)") then
                    return true
                end
            end
        end
    end
    return false
end

local function IsGuildMemberByName(name)
    if not name or not IsInGuild() then return false end
    local numMembers = GetNumGuildMembers()
    local searchName = name:match("^([^-]+)") or name
    for i = 1, numMembers do
        local memberName = GetGuildRosterInfo(i)
        if memberName then
            local memberShort = memberName:match("^([^-]+)") or memberName
            if memberShort == searchName then
                return true
            end
        end
    end
    return false
end

local function OnPartyInvite(inviterName)
    local settings = GetSettings()
    if not settings then return end


    local mode = settings.autoAcceptInvites
    if not mode or mode == "off" then return end

    local shouldAccept = false

    if mode == "all" then
        shouldAccept = true
    elseif mode == "friends" then
        shouldAccept = IsFriendOrBNet(inviterName)
    elseif mode == "guild" then
        shouldAccept = IsGuildMemberByName(inviterName)
    elseif mode == "both" then
        shouldAccept = IsFriendOrBNet(inviterName) or IsGuildMemberByName(inviterName)
    end

    if shouldAccept then
        AcceptGroup()
        StaticPopup_Hide("PARTY_INVITE")
    end
end


local function ShouldPauseQuest(settings)
    return settings.questHoldShift and IsShiftKeyDown()
end

local function OnQuestDetail()
    local settings = GetSettings()
    if not settings or not settings.autoAcceptQuest then return end
    if ShouldPauseQuest(settings) then return end

    AcceptQuest()
end

local function OnQuestComplete()
    local settings = GetSettings()
    if not settings or not settings.autoTurnInQuest then return end
    if ShouldPauseQuest(settings) then return end


    local numChoices = GetNumQuestChoices()
    if numChoices > 1 then return end

    GetQuestReward(numChoices > 0 and 1 or nil)
end


local gossipClicked = {}

local function OnGossipShow()
    local settings = GetSettings()
    if not settings or not settings.autoSelectGossip then return end


    if settings.questHoldShift and IsShiftKeyDown() then return end


    local availableQuests = C_GossipInfo.GetAvailableQuests()
    local numActiveQuests = C_GossipInfo.GetNumActiveQuests()


    if (availableQuests and #availableQuests > 0) or (numActiveQuests and numActiveQuests > 0) then
        return
    end


    local options = C_GossipInfo.GetOptions()
    if not options or #options == 0 then return end


    local validOptions = {}
    for _, option in pairs(options) do
        if option.gossipOptionID then
            table.insert(validOptions, option)
        end
    end


    if #validOptions == 1 then
        local option = validOptions[1]
        local optionID = option.gossipOptionID

        if optionID and not gossipClicked[optionID] then
            gossipClicked[optionID] = true
            C_GossipInfo.SelectOption(optionID)

            local optionName = option.name or "gossip"
            print(string.format("|cFFB91C1CPreyUI:|r %s", optionName))
        end
    end


end

local function OnGossipClosed()
    gossipClicked = {}
end


local lootRetryPending = false

local function TryLootAll()
    local numItems = GetNumLootItems()
    for slotIndex = 1, numItems do
        if LootSlotHasItem(slotIndex) then
            LootSlot(slotIndex)
        end
    end
end

local function CheckRemainingLoot()
    lootRetryPending = false
    local settings = GetSettings()
    if not settings or not settings.fastAutoLoot then return end


    local numItems = GetNumLootItems()
    for slotIndex = 1, numItems do
        if LootSlotHasItem(slotIndex) then
            TryLootAll()
            return
        end
    end
end

local function OnLootReady()
    local settings = GetSettings()
    if not settings or not settings.fastAutoLoot then return end


    if not GetCVarBool("autoLootDefault") then
        SetCVar("autoLootDefault", "1")
    end

    TryLootAll()


    if not lootRetryPending then
        lootRetryPending = true
        C_Timer.After(0.1, CheckRemainingLoot)
    end
end


local wasLoggingBeforeChallenge = false

local function OnChallengeModeStart()
    local settings = GetSettings()
    if not settings or not settings.autoCombatLog then return end


    wasLoggingBeforeChallenge = LoggingCombat()

    if not wasLoggingBeforeChallenge then
        LoggingCombat(true)
        print("|cFFB91C1CPreyUI:|r Combat logging started for M+")
    end
end

local function OnChallengeModeEnd()
    local settings = GetSettings()
    if not settings or not settings.autoCombatLog then return end


    if not wasLoggingBeforeChallenge and LoggingCombat() then
        LoggingCombat(false)
        print("|cFFB91C1CPreyUI:|r Combat logging stopped")
    end
    wasLoggingBeforeChallenge = false
end


local function CheckResumeLogging()
    local settings = GetSettings()
    if not settings or not settings.autoCombatLog then return end

    if C_ChallengeMode.IsChallengeModeActive() and not LoggingCombat() then
        LoggingCombat(true)
        print("|cFFB91C1CPreyUI:|r Combat logging resumed (reconnected to M+)")
    end
end


local deletePopups = {
    ["DELETE_ITEM"] = true,
    ["DELETE_GOOD_ITEM"] = true,
    ["DELETE_GOOD_QUEST_ITEM"] = true,
    ["DELETE_QUEST_ITEM"] = true,
}

hooksecurefunc("StaticPopup_Show", function(which)
    if not deletePopups[which] then return end

    local settings = GetSettings()
    if not settings or not settings.autoDeleteConfirm then return end


    for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
        local frame = rawget(_G, "StaticPopup" .. i)
        if frame and frame.which == which and frame:IsShown() then
            local editBox = frame.editBox or rawget(_G, "StaticPopup" .. i .. "EditBox")
            if editBox then
                editBox:SetText(DELETE_ITEM_CONFIRM_STRING or "DELETE")

                local handler = editBox:GetScript("OnTextChanged")
                if handler then
                    handler(editBox)
                end

            end
            break
        end
    end
end)


qolFrame:RegisterEvent("MERCHANT_SHOW")
qolFrame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
qolFrame:RegisterEvent("PARTY_INVITE_REQUEST")
qolFrame:RegisterEvent("QUEST_DETAIL")
qolFrame:RegisterEvent("QUEST_COMPLETE")
qolFrame:RegisterEvent("GOSSIP_SHOW")
qolFrame:RegisterEvent("GOSSIP_CLOSED")
qolFrame:RegisterEvent("LOOT_READY")
qolFrame:RegisterEvent("CHALLENGE_MODE_START")
qolFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
qolFrame:RegisterEvent("CHALLENGE_MODE_RESET")
qolFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

qolFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MERCHANT_SHOW" then
        OnMerchantShow()
    elseif event == "LFG_ROLE_CHECK_SHOW" then
        OnRoleCheckShow()
    elseif event == "PARTY_INVITE_REQUEST" then
        OnPartyInvite(...)
    elseif event == "QUEST_DETAIL" then
        OnQuestDetail()
    elseif event == "QUEST_COMPLETE" then
        OnQuestComplete()
    elseif event == "GOSSIP_SHOW" then
        OnGossipShow()
    elseif event == "GOSSIP_CLOSED" then
        OnGossipClosed()
    elseif event == "LOOT_READY" then
        OnLootReady()
    elseif event == "CHALLENGE_MODE_START" then
        OnChallengeModeStart()
    elseif event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
        OnChallengeModeEnd()
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, CheckResumeLogging)
    end
end)
