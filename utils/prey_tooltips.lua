local ADDON_NAME, ns = ...
local PREY = ns.PREY or {}
ns.PREY = PREY


local GameTooltip = GameTooltip
local UIParent = UIParent
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown
local InCombatLockdown = InCombatLockdown
local strfind = string.find
local strmatch = string.match
local GetMouseFoci = GetMouseFoci
local WorldFrame = WorldFrame


local cachedMouseFrame = nil
local cachedMouseFrameTime = 0
local MOUSE_FRAME_CACHE_TTL = 0.2

local function GetTopMouseFrame()
    local now = GetTime()

    if cachedMouseFrame ~= nil and (now - cachedMouseFrameTime) < MOUSE_FRAME_CACHE_TTL then
        return cachedMouseFrame
    end


    if GetMouseFoci then
        local frames = GetMouseFoci()
        cachedMouseFrame = frames and frames[1]
    else
        cachedMouseFrame = GetMouseFocus and GetMouseFocus()
    end
    cachedMouseFrameTime = now
    return cachedMouseFrame
end

local function IsWorldMapOwnedFrame(frame)
    if not frame then return false end
    local mapFrame = rawget(_G, "WorldMapFrame")

    local check = frame
    while check do
        if mapFrame and check == mapFrame then
            return true
        end
        check = check:GetParent()
    end

    local name = frame.GetName and frame:GetName() or ""
    if strfind(name, "WorldMap") or strfind(name, "TaskPOI") or strfind(name, "MapCanvas") then
        return true
    end

    return false
end

local function IsTaintSensitiveTooltipOwner(frame)
    if not frame then return false end
    if IsWorldMapOwnedFrame(frame) then
        return true
    end

    local name = frame.GetName and frame:GetName() or ""
    if strfind(name, "AlertFrame") or
       strfind(name, "LootAlert") or
       strfind(name, "Scenario") or
       strfind(name, "Quest") or
       strfind(name, "BonusObjective") or
       strfind(name, "POI") then
        return true
    end

    return false
end


local function IsFrameBlockingMouse()
    local focus = GetTopMouseFrame()
    if not focus then return false end


    if focus == WorldFrame then return false end


    return focus:IsVisible()
end


local cachedSettings = nil
local originalSetDefaultAnchor = nil


local pendingSetUnit = nil


local FADED_ALPHA_THRESHOLD = 0.5


local function GetSettings()
    if cachedSettings then return cachedSettings end
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.tooltip then
        cachedSettings = PREYCore.db.profile.tooltip
        return cachedSettings
    end
    return nil
end


local function InvalidateCache()
    cachedSettings = nil
end


local function GetTooltipContext(owner)
    if not owner then return "npcs" end


    if owner.__cdmSkinned then
        return "cdm"
    end


    local parent = owner:GetParent()
    if parent then
        if parent.__cdmSkinned then
            return "cdm"
        end

        local parentName = parent:GetName() or ""
        if parentName == "EssentialCooldownViewer" or
           parentName == "UtilityCooldownViewer" or
           parentName == "BuffIconCooldownViewer" or
           parentName == "BuffBarCooldownViewer" then
            return "cdm"
        end
    end


    if owner.__customTrackerIcon then
        return "customTrackers"
    end

    local name = owner:GetName() or ""


    if strmatch(name, "ActionButton") or
       strmatch(name, "MultiBar") or
       strmatch(name, "PetActionButton") or
       strmatch(name, "StanceButton") or
       strmatch(name, "OverrideActionBar") or
       strmatch(name, "ExtraActionButton") or
       strmatch(name, "BT4Button") or
       strmatch(name, "DominosActionButton") or
       strmatch(name, "ElvUI_Bar") then


        local actionSlot = owner:GetAttribute("action")
        if actionSlot then
            local actionType, actionID = GetActionInfo(actionSlot)
            if actionType == "item" then
                return "items"
            end
        end

        return "abilities"
    end


    if strmatch(name, "ContainerFrame") or
       strmatch(name, "BagSlot") or
       strmatch(name, "BankFrame") or
       strmatch(name, "ReagentBank") or
       strmatch(name, "BagItem") or
       strmatch(name, "Baganator") then
        return "items"
    end


    if parent then
        local parentNameItems = parent:GetName() or ""
        if strmatch(parentNameItems, "ContainerFrame") or
           strmatch(parentNameItems, "BankFrame") or
           strmatch(parentNameItems, "Baganator") then
            return "items"
        end
    end


    if owner.unit or
       strmatch(name, "UnitFrame") or
       strmatch(name, "PlayerFrame") or
       strmatch(name, "TargetFrame") or
       strmatch(name, "FocusFrame") or
       strmatch(name, "PartyMemberFrame") or
       strmatch(name, "CompactRaidFrame") or
       strmatch(name, "CompactPartyFrame") or
       strmatch(name, "NamePlate") or
       strmatch(name, "Prey.*Frame") then
        return "frames"
    end


    return "npcs"
end


local function IsModifierActive(modKey)
    if modKey == "SHIFT" then return IsShiftKeyDown() end
    if modKey == "CTRL" then return IsControlKeyDown() end
    if modKey == "ALT" then return IsAltKeyDown() end
    return false
end


local function ShouldShowTooltip(context)
    local settings = GetSettings()
    if not settings or not settings.enabled then
        return true
    end


    if settings.hideInCombat and InCombatLockdown() then

        if settings.combatKey and settings.combatKey ~= "NONE" then
            if IsModifierActive(settings.combatKey) then
                return true
            end
        end
        return false
    end

    local visibility = settings.visibility and settings.visibility[context]
    if not visibility then
        return true
    end


    if visibility == "SHOW" then
        return true
    elseif visibility == "HIDE" then
        return false
    else

        return IsModifierActive(visibility)
    end
end


local function SetupTooltipHook()
    hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
        if tooltip ~= GameTooltip then
            return
        end

        local settings = GetSettings()
        if not settings or not settings.enabled then
            return
        end


        if IsTaintSensitiveTooltipOwner(parent) then
            return
        end


        local context = GetTooltipContext(parent)


        if not ShouldShowTooltip(context) then
            tooltip:Hide()
            return
        end


    end)


    hooksecurefunc(GameTooltip, "SetUnit", function(tooltip, unit)
        local settings = GetSettings()
        if not settings or not settings.enabled then return end


        if pendingSetUnit then return end
        pendingSetUnit = C_Timer.After(0.1, function()
            pendingSetUnit = nil

            if tooltip:GetOwner() == UIParent and IsFrameBlockingMouse() then
                tooltip:Hide()
            end
        end)
    end)


    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if tooltip ~= GameTooltip then return end

        local settings = GetSettings()
        if not settings or not settings.enabled or not settings.classColorName then return end

        local _, unit = tooltip:GetUnit()
        if not unit then return end


        local okPlayer, isPlayer = pcall(UnitIsPlayer, unit)
        if not okPlayer or not isPlayer then return end

        local okClass, _, class = pcall(UnitClass, unit)
        if not okClass or not class then return end

        local classColor = class and RAID_CLASS_COLORS[class]
        if classColor then
            local nameLine = GameTooltipTextLeft1
            if nameLine and nameLine:GetText() then
                nameLine:SetTextColor(classColor.r, classColor.g, classColor.b)
            end
        end
    end)


    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if tooltip ~= GameTooltip then return end

        local settings = GetSettings()
        if not settings or not settings.enabled then return end

        local hideBar = settings.hideHealthBar

        if GameTooltipStatusBar then
            GameTooltipStatusBar:SetShown(not hideBar)
            GameTooltipStatusBar:SetAlpha(hideBar and 0 or 1)
        end
    end)


    hooksecurefunc(GameTooltip, "SetSpellByID", function(tooltip, spellID)
        local settings = GetSettings()
        if not settings or not settings.enabled then return end

        local owner = tooltip:GetOwner()
        if IsTaintSensitiveTooltipOwner(owner) then return end


        if owner and owner.GetEffectiveAlpha and owner:GetEffectiveAlpha() < FADED_ALPHA_THRESHOLD then
            tooltip:Hide()
            return
        end

        local context = GetTooltipContext(owner)


        if context == "cdm" or context == "customTrackers" then
            if not ShouldShowTooltip(context) then
                tooltip:Hide()
            end
        end
    end)


    hooksecurefunc(GameTooltip, "SetItemByID", function(tooltip, itemID)
        local settings = GetSettings()
        if not settings or not settings.enabled then return end

        local owner = tooltip:GetOwner()
        if IsTaintSensitiveTooltipOwner(owner) then return end


        if owner and owner.GetEffectiveAlpha and owner:GetEffectiveAlpha() < FADED_ALPHA_THRESHOLD then
            tooltip:Hide()
            return
        end

        local context = GetTooltipContext(owner)


        if context == "customTrackers" then
            if not ShouldShowTooltip("customTrackers") then
                tooltip:Hide()
            end
        end
    end)


    hooksecurefunc("GameTooltip_Hide", function()
        if InCombatLockdown() and GameTooltip:IsVisible() then
            GameTooltip:Hide()
        end
    end)


    local tooltipMonitor = CreateFrame("Frame")
    local monitorElapsed = 0

    local function TooltipMonitorOnUpdate(self, delta)
        monitorElapsed = monitorElapsed + delta
        if monitorElapsed < 0.25 then return end
        monitorElapsed = 0

        local settings = GetSettings()
        if not settings or not settings.enabled then return end
        if settings.hideInCombat then return end

        if not GameTooltip:IsVisible() then return end

        local owner = GameTooltip:GetOwner()
        if not owner then return end

        local mouseFrame = GetTopMouseFrame()
        if not mouseFrame then return end


        local isOverOwner = false
        local checkFrame = mouseFrame
        while checkFrame do
            if checkFrame == owner then
                isOverOwner = true
                break
            end
            checkFrame = checkFrame:GetParent()
        end


        if not isOverOwner then
            GameTooltip:Hide()
        end
    end


    tooltipMonitor:RegisterEvent("PLAYER_REGEN_DISABLED")
    tooltipMonitor:RegisterEvent("PLAYER_REGEN_ENABLED")
    tooltipMonitor:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_DISABLED" then

            monitorElapsed = 0
            self:SetScript("OnUpdate", TooltipMonitorOnUpdate)
        else

            self:SetScript("OnUpdate", nil)
        end
    end)
end


local function OnModifierStateChanged()

    if not GameTooltip:IsShown() then return end

    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    local owner = GameTooltip:GetOwner()
    local context = GetTooltipContext(owner)


    if not ShouldShowTooltip(context) then
        GameTooltip:Hide()
    end
end


local function OnCombatStateChanged(inCombat)
    local settings = GetSettings()
    if not settings or not settings.enabled or not settings.hideInCombat then return end

    if inCombat then

        if not settings.combatKey or settings.combatKey == "NONE" or not IsModifierActive(settings.combatKey) then
            GameTooltip:Hide()
        end
    end

end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then

        C_Timer.After(0.5, function()
            SetupTooltipHook()


        end)
    elseif event == "MODIFIER_STATE_CHANGED" then
        OnModifierStateChanged()
    elseif event == "PLAYER_REGEN_DISABLED" then

        OnCombatStateChanged(true)
    elseif event == "PLAYER_REGEN_ENABLED" then

        OnCombatStateChanged(false)
    end
end)


_G.PreyUI_RefreshTooltips = function()
    InvalidateCache()

end
