local ADDON_NAME, ns = ...
local LSM = LibStub("LibSharedMedia-3.0")


local IS_MIDNIGHT = select(4, GetBuildInfo()) >= 120000


local TEXTURE_PATH = [[Interface\AddOns\PreyUI\assets\iconskin\]]
local TEXTURES = {
    normal = TEXTURE_PATH .. "Normal",
    gloss = TEXTURE_PATH .. "Gloss",
    highlight = TEXTURE_PATH .. "Highlight",
    pushed = TEXTURE_PATH .. "Pushed",
    checked = TEXTURE_PATH .. "Checked",
    flash = TEXTURE_PATH .. "Flash",
}


local ICON_TEXCOORD = {0.07, 0.93, 0.07, 0.93}


local RANGE_INDICATOR = RANGE_INDICATOR or "●"


local BAR_FRAMES = {
    bar1 = "MainMenuBar",
    bar2 = "MultiBarBottomLeft",
    bar3 = "MultiBarBottomRight",
    bar4 = "MultiBarRight",
    bar5 = "MultiBarLeft",
    bar6 = "MultiBar5",
    bar7 = "MultiBar6",
    bar8 = "MultiBar7",
    pet = "PetActionBar",
    stance = "StanceBar",

    microbar = "MicroMenuContainer",
    bags = "BagsBar",
    extraActionButton = "ExtraActionBarFrame",
    zoneAbility = "ZoneAbilityFrame",
}


local BUTTON_PATTERNS = {
    bar1 = "ActionButton%d",
    bar2 = "MultiBarBottomLeftButton%d",
    bar3 = "MultiBarBottomRightButton%d",
    bar4 = "MultiBarRightButton%d",
    bar5 = "MultiBarLeftButton%d",
    bar6 = "MultiBar5Button%d",
    bar7 = "MultiBar6Button%d",
    bar8 = "MultiBar7Button%d",
    pet = "PetActionButton%d",
    stance = "StanceButton%d",
}


local BUTTON_COUNTS = {
    bar1 = 12, bar2 = 12, bar3 = 12, bar4 = 12, bar5 = 12,
    bar6 = 12, bar7 = 12, bar8 = 12, pet = 10, stance = 10,
}


local BINDING_COMMANDS = {
    bar1 = "ACTIONBUTTON",
    bar2 = "MULTIACTIONBAR1BUTTON",
    bar3 = "MULTIACTIONBAR2BUTTON",
    bar4 = "MULTIACTIONBAR3BUTTON",
    bar5 = "MULTIACTIONBAR4BUTTON",
    bar6 = "MULTIACTIONBAR5BUTTON",
    bar7 = "MULTIACTIONBAR6BUTTON",
    bar8 = "MULTIACTIONBAR7BUTTON",
    pet = "BONUSACTIONBUTTON",
    stance = "SHAPESHIFTBUTTON",
}


local ActionBars = {
    initialized = false,
    skinnedButtons = {},
    fadeState = {},
    fadeFrame = nil,
}


local function SafeHasAction(action)
    if IS_MIDNIGHT then
        local ok, result = pcall(function()
            local has = HasAction(action)

            if has then return true end
            return false
        end)
        if not ok then return true end
        return result
    else
        return HasAction(action)
    end
end

local function GetDB()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then
        return nil
    end
    return PREYCore.db.profile.actionBars
end

local function GetGlobalSettings()
    local db = GetDB()
    return db and db.global
end

local function GetBarSettings(barKey)
    local db = GetDB()
    return db and db.bars and db.bars[barKey]
end

local function GetFadeSettings()
    local db = GetDB()
    return db and db.fade
end


local function GetBarKeyFromButton(button)
    local name = button and button:GetName()
    if not name then return nil end

    if name:match("^ActionButton%d+$") then return "bar1" end
    if name:match("^MultiBarBottomLeftButton%d+$") then return "bar2" end
    if name:match("^MultiBarBottomRightButton%d+$") then return "bar3" end
    if name:match("^MultiBarRightButton%d+$") then return "bar4" end
    if name:match("^MultiBarLeftButton%d+$") then return "bar5" end
    if name:match("^MultiBar5Button%d+$") then return "bar6" end
    if name:match("^MultiBar6Button%d+$") then return "bar7" end
    if name:match("^MultiBar7Button%d+$") then return "bar8" end
    if name:match("^PetActionButton%d+$") then return "pet" end
    if name:match("^StanceButton%d+$") then return "stance" end
    return nil
end


local function GetButtonIndex(button)
    local name = button and button:GetName()
    if not name then return nil end
    return tonumber(name:match("%d+$"))
end


local function AddKeybindMethods(button, barKey)
    if not button or button._preyKeybindMethods then return end

    local bindingPrefix = BINDING_COMMANDS[barKey]
    if not bindingPrefix then return end

    local buttonIndex = GetButtonIndex(button)
    if not buttonIndex then return end

    local bindingCommand = bindingPrefix .. buttonIndex
    button._preyBindingCommand = bindingCommand
    button._preyKeybindMethods = true


    function button:GetHotkey()
        local key = GetBindingKey(self._preyBindingCommand)
        if key then
            local LibKeyBound = LibStub("LibKeyBound-1.0", true)
            return LibKeyBound and LibKeyBound:ToShortKey(key) or key
        end
        return nil
    end


    function button:SetKey(key)
        if InCombatLockdown() then return end
        SetBinding(key, self._preyBindingCommand)
    end


    function button:GetBindings()
        local keys = {}
        for i = 1, select("#", GetBindingKey(self._preyBindingCommand)) do
            local key = select(i, GetBindingKey(self._preyBindingCommand))
            if key then
                table.insert(keys, key)
            end
        end
        return #keys > 0 and table.concat(keys, ", ") or nil
    end


    function button:ClearBindings()
        if InCombatLockdown() then return end
        while GetBindingKey(self._preyBindingCommand) do
            SetBinding(GetBindingKey(self._preyBindingCommand), nil)
        end
    end


    function button:GetActionName()
        return self._preyBindingCommand
    end
end


local function GetEffectiveSettings(barKey)
    local global = GetGlobalSettings()
    if not global then return nil end

    local barSettings = GetBarSettings(barKey)


    if not barSettings or not barSettings.overrideEnabled then
        return global
    end


    local effective = {}
    for key, value in pairs(global) do
        effective[key] = value
    end


    local overrideKeys = {
        "iconZoom", "showBackdrop", "backdropAlpha", "showGloss", "glossAlpha",
        "showKeybinds", "hideEmptyKeybinds", "keybindFontSize", "keybindColor",
        "keybindAnchor", "keybindOffsetX", "keybindOffsetY",
        "showMacroNames", "macroNameFontSize", "macroNameColor",
        "macroNameAnchor", "macroNameOffsetX", "macroNameOffsetY",
        "showCounts", "countFontSize", "countColor",
        "countAnchor", "countOffsetX", "countOffsetY",
    }

    for _, key in ipairs(overrideKeys) do
        if barSettings[key] ~= nil then
            effective[key] = barSettings[key]
        end
    end

    return effective
end


local function GetBarButtons(barKey)
    local buttons = {}


    if barKey == "microbar" then

        if MicroMenu then
            for _, child in ipairs({MicroMenu:GetChildren()}) do
                if child.IsObjectType and child:IsObjectType("Button") then
                    table.insert(buttons, child)
                end
            end
        end
        return buttons
    elseif barKey == "bags" then

        if MainMenuBarBackpackButton then
            table.insert(buttons, MainMenuBarBackpackButton)
        end
        for i = 0, 3 do
            local slot = rawget(_G, "CharacterBag" .. i .. "Slot")
            if slot then table.insert(buttons, slot) end
        end
        if CharacterReagentBag0Slot then
            table.insert(buttons, CharacterReagentBag0Slot)
        end
        return buttons
    elseif barKey == "extraActionButton" then

        if ExtraActionBarFrame and ExtraActionBarFrame.button then
            table.insert(buttons, ExtraActionBarFrame.button)
        end
        return buttons
    elseif barKey == "zoneAbility" then

        if ZoneAbilityFrame and ZoneAbilityFrame.SpellButtonContainer then
            for button in ZoneAbilityFrame.SpellButtonContainer:EnumerateActive() do
                table.insert(buttons, button)
            end
        end
        return buttons
    end


    local pattern = BUTTON_PATTERNS[barKey]
    local count = BUTTON_COUNTS[barKey] or 12

    if not pattern then return buttons end

    for i = 1, count do
        local buttonName = string.format(pattern, i)
        local button = rawget(_G, buttonName)
        if button then
            table.insert(buttons, button)
        end
    end

    return buttons
end


local function GetBarFrame(barKey)
    local frameName = BAR_FRAMES[barKey]
    return frameName and rawget(_G, frameName)
end


local extraActionHolder = nil
local extraActionMover = nil
local zoneAbilityHolder = nil
local zoneAbilityMover = nil
local extraButtonMoversVisible = false


local function GetExtraButtonDB(buttonType)
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then return nil end
    return PREYCore.db.profile.actionBars and PREYCore.db.profile.actionBars.bars
        and PREYCore.db.profile.actionBars.bars[buttonType]
end


local function CreateExtraButtonHolder(buttonType, displayName)
    local settings = GetExtraButtonDB(buttonType)
    if not settings then return nil, nil end


    local holder = CreateFrame("Frame", "PREY_" .. buttonType .. "Holder", UIParent)
    holder:SetSize(64, 64)
    holder:SetMovable(true)
    holder:SetClampedToScreen(true)


    local pos = settings.position
    if pos and pos.point then
        holder:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    else

        if buttonType == "extraActionButton" then
            holder:SetPoint("CENTER", UIParent, "CENTER", -100, -200)
        else
            holder:SetPoint("CENTER", UIParent, "CENTER", 100, -200)
        end
    end


    local mover = CreateFrame("Frame", "PREY_" .. buttonType .. "Mover", holder, "BackdropTemplate")
    mover:SetAllPoints(holder)
    mover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    mover:SetBackdropColor(0.2, 0.8, 0.6, 0.5)
    mover:SetBackdropBorderColor(0.820, 0.180, 0.220, 1)
    mover:EnableMouse(true)
    mover:SetMovable(true)
    mover:RegisterForDrag("LeftButton")
    mover:SetFrameStrata("FULLSCREEN_DIALOG")
    mover:Hide()


    local text = mover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText(displayName)
    mover.text = text


    mover:SetScript("OnDragStart", function(self)
        holder:StartMoving()
    end)

    mover:SetScript("OnDragStop", function(self)
        holder:StopMovingOrSizing()
        local point, _, relPoint, x, y = holder:GetPoint()
        local db = GetExtraButtonDB(buttonType)
        if db then
            db.position = { point = point, relPoint = relPoint, x = x, y = y }
        end
    end)

    return holder, mover
end


local function ApplyExtraButtonSettings(buttonType)
    if InCombatLockdown() then
        ActionBars.pendingExtraButtonRefresh = true
        return
    end

    local settings = GetExtraButtonDB(buttonType)
    if not settings or not settings.enabled then return end

    local blizzFrame
    local holder, mover

    if buttonType == "extraActionButton" then
        blizzFrame = ExtraActionBarFrame
        holder = extraActionHolder
        mover = extraActionMover
    else
        blizzFrame = ZoneAbilityFrame
        holder = zoneAbilityHolder
        mover = zoneAbilityMover
    end

    if not blizzFrame or not holder then return end


    local scale = settings.scale or 1.0
    blizzFrame:SetScale(scale)


    local offsetX = settings.offsetX or 0
    local offsetY = settings.offsetY or 0


    blizzFrame:SetParent(holder)
    blizzFrame:ClearAllPoints()
    blizzFrame:SetPoint("CENTER", holder, "CENTER", offsetX, offsetY)


    local width = (blizzFrame:GetWidth() or 64) * scale
    local height = (blizzFrame:GetHeight() or 64) * scale
    holder:SetSize(math.max(width, 64), math.max(height, 64))


    if settings.hideArtwork then
        if buttonType == "extraActionButton" and blizzFrame.button and blizzFrame.button.style then
            blizzFrame.button.style:SetAlpha(0)
        end
        if buttonType == "zoneAbility" and blizzFrame.Style then
            blizzFrame.Style:SetAlpha(0)
        end
    else

        if buttonType == "extraActionButton" and blizzFrame.button and blizzFrame.button.style then
            blizzFrame.button.style:SetAlpha(1)
        end
        if buttonType == "zoneAbility" and blizzFrame.Style then
            blizzFrame.Style:SetAlpha(1)
        end
    end


    if not settings.fadeEnabled then
        blizzFrame:SetAlpha(1)
    end
end


local function HookExtraButtonPositioning()
    if ExtraActionBarFrame and not ExtraActionBarFrame._preyHooked then
        ExtraActionBarFrame._preyHooked = true
        ExtraActionBarFrame:HookScript("OnShow", function()
            local settings = GetExtraButtonDB("extraActionButton")
            if not settings or not settings.enabled then return end
            if InCombatLockdown() then
                ActionBars.pendingExtraButtonRefresh = true
                return
            end
            C_Timer.After(0, function()
                ApplyExtraButtonSettings("extraActionButton")
            end)
        end)
    end

    if ZoneAbilityFrame and not ZoneAbilityFrame._preyHooked then
        ZoneAbilityFrame._preyHooked = true
        ZoneAbilityFrame:HookScript("OnShow", function()
            local settings = GetExtraButtonDB("zoneAbility")
            if not settings or not settings.enabled then return end
            if InCombatLockdown() then
                ActionBars.pendingExtraButtonRefresh = true
                return
            end
            C_Timer.After(0, function()
                ApplyExtraButtonSettings("zoneAbility")
            end)
        end)
    end
end


local function ShowExtraButtonMovers()
    extraButtonMoversVisible = true
    if extraActionMover then extraActionMover:Show() end
    if zoneAbilityMover then zoneAbilityMover:Show() end
end

local function HideExtraButtonMovers()
    extraButtonMoversVisible = false
    if extraActionMover then extraActionMover:Hide() end
    if zoneAbilityMover then zoneAbilityMover:Hide() end
end

local function ToggleExtraButtonMovers()
    if extraButtonMoversVisible then
        HideExtraButtonMovers()
    else
        ShowExtraButtonMovers()
    end
end


local function InitializeExtraButtons()
    if InCombatLockdown() then
        ActionBars.pendingExtraButtonInit = true
        return
    end


    extraActionHolder, extraActionMover = CreateExtraButtonHolder("extraActionButton", "Extra Action Button")
    zoneAbilityHolder, zoneAbilityMover = CreateExtraButtonHolder("zoneAbility", "Zone Ability")


    C_Timer.After(0.5, function()
        ApplyExtraButtonSettings("extraActionButton")
        ApplyExtraButtonSettings("zoneAbility")
        HookExtraButtonPositioning()
    end)
end


local function RefreshExtraButtons()
    if InCombatLockdown() then
        ActionBars.pendingExtraButtonRefresh = true
        return
    end
    ApplyExtraButtonSettings("extraActionButton")
    ApplyExtraButtonSettings("zoneAbility")
end


_G.PreyUI_ToggleExtraButtonMovers = ToggleExtraButtonMovers
_G.PreyUI_RefreshExtraButtons = RefreshExtraButtons


local function StripColorCodes(text)
    if not text then return "" end
    return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end


local function IsValidKeybindText(text)
    if not text or text == "" then return false end

    local stripped = StripColorCodes(text)
    if stripped == "" then return false end
    if stripped == RANGE_INDICATOR then return false end
    if stripped == "[]" then return false end

    return true
end


local function StripBlizzardArtwork(button)
    if button._preyStripped then return end
    button._preyStripped = true


    local normalTex = button:GetNormalTexture()
    if normalTex then
        normalTex:SetAlpha(0)
    end
    if button.NormalTexture then
        button.NormalTexture:SetAlpha(0)
    end


    local icon = button.icon or button.Icon
    if icon and icon.GetMaskTexture and icon.RemoveMaskTexture then
        for i = 1, 10 do
            local mask = icon:GetMaskTexture(i)
            if mask then
                icon:RemoveMaskTexture(mask)
            end
        end
    end


    if button.FloatingBG then
        button.FloatingBG:SetAlpha(0)
    end


    if button.SlotBackground then
        button.SlotBackground:SetAlpha(0)
    end


    if button.SlotArt then
        button.SlotArt:SetAlpha(0)
    end
end


local function SkinButton(button, settings)
    if not button or not settings or not settings.skinEnabled then return end


    local settingsKey = string.format("%d_%.2f_%s_%.2f_%s_%.2f",
        settings.iconSize or 36,
        settings.iconZoom or 0.07,
        tostring(settings.showBackdrop),
        settings.backdropAlpha or 0.8,
        tostring(settings.showGloss),
        settings.glossAlpha or 0.6
    )
    if button._preySkinKey == settingsKey then return end
    button._preySkinKey = settingsKey


    StripBlizzardArtwork(button)

    local iconSize = settings.iconSize or 36
    local zoom = settings.iconZoom or 0.07


    local icon = button.icon or button.Icon
    if icon then
        icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
        icon:ClearAllPoints()
        icon:SetAllPoints(button)
    end


    if settings.showBackdrop then
        if not button._preyBackdrop then
            button._preyBackdrop = button:CreateTexture(nil, "BACKGROUND", nil, -8)
            button._preyBackdrop:SetColorTexture(0, 0, 0, 1)
        end
        button._preyBackdrop:SetAlpha(settings.backdropAlpha or 0.8)
        button._preyBackdrop:ClearAllPoints()
        button._preyBackdrop:SetAllPoints(button)
        button._preyBackdrop:Show()
    elseif button._preyBackdrop then
        button._preyBackdrop:Hide()
    end


    if settings.showBorders ~= false then
        if not button._preyNormal then
            button._preyNormal = button:CreateTexture(nil, "OVERLAY", nil, 1)
            button._preyNormal:SetTexture(TEXTURES.normal)
            button._preyNormal:SetVertexColor(0, 0, 0, 1)
        end
        button._preyNormal:SetSize(iconSize, iconSize)
        button._preyNormal:ClearAllPoints()
        button._preyNormal:SetAllPoints(button)
        button._preyNormal:Show()
    elseif button._preyNormal then
        button._preyNormal:Hide()
    end


    if settings.showGloss then
        if not button._preyGloss then
            button._preyGloss = button:CreateTexture(nil, "OVERLAY", nil, 2)
            button._preyGloss:SetTexture(TEXTURES.gloss)
            button._preyGloss:SetBlendMode("ADD")
        end
        button._preyGloss:SetVertexColor(1, 1, 1, settings.glossAlpha or 0.6)
        button._preyGloss:SetAllPoints(button)
        button._preyGloss:Show()
    elseif button._preyGloss then
        button._preyGloss:Hide()
    end


    local cooldown = button.cooldown or button.Cooldown
    if cooldown then
        cooldown:ClearAllPoints()
        cooldown:SetAllPoints(button)
    end

    ActionBars.skinnedButtons[button] = true
end


local function UpdateKeybindText(button, settings)
    local hotkey = button.HotKey or button.hotKey
    if not hotkey then return end


    if not settings.showKeybinds then
        hotkey:SetAlpha(0)
        hotkey:Hide()
        return
    end


    local buttonName = button:GetName()
    local bindingName = nil
    local abbreviated = nil

    if buttonName then
        local num


        num = buttonName:match("^ActionButton(%d+)$")
        if num then bindingName = "ACTIONBUTTON" .. num end

        if not bindingName then
            num = buttonName:match("^MultiBarBottomRightButton(%d+)$")
            if num then bindingName = "MULTIACTIONBAR2BUTTON" .. num end
        end

        if not bindingName then
            num = buttonName:match("^MultiBarBottomLeftButton(%d+)$")
            if num then bindingName = "MULTIACTIONBAR1BUTTON" .. num end
        end

        if not bindingName then
            num = buttonName:match("^MultiBarRightButton(%d+)$")
            if num then bindingName = "MULTIACTIONBAR3BUTTON" .. num end
        end

        if not bindingName then
            num = buttonName:match("^MultiBarLeftButton(%d+)$")
            if num then bindingName = "MULTIACTIONBAR4BUTTON" .. num end
        end


        if not bindingName then
            num = buttonName:match("^MultiBar5Button(%d+)$")
            if num then bindingName = "MULTIACTIONBAR5BUTTON" .. num end
        end

        if not bindingName then
            num = buttonName:match("^MultiBar6Button(%d+)$")
            if num then bindingName = "MULTIACTIONBAR6BUTTON" .. num end
        end

        if not bindingName then
            num = buttonName:match("^MultiBar7Button(%d+)$")
            if num then bindingName = "MULTIACTIONBAR7BUTTON" .. num end
        end


        if bindingName then
            local key = GetBindingKey(bindingName)
            if key and ns and ns.FormatKeybind then
                abbreviated = ns.FormatKeybind(key)
            end
        end
    end


    local shouldShow = abbreviated and abbreviated ~= ""


    if shouldShow and settings.hideEmptyKeybinds then
        if button.action then
            local hasAction = SafeHasAction(button.action)
            if not hasAction then
                shouldShow = false
            end
        end
    end

    if not shouldShow then
        hotkey:SetAlpha(0)
        hotkey:Hide()
        return
    end


    hotkey:SetText(abbreviated)
    hotkey:Show()
    hotkey:SetAlpha(1)


    local fontPath = "Fonts\\FRIZQT__.TTF"
    local outline = "OUTLINE"
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        local general = PREYCore.db.profile.general
        if general.font and LSM then
            fontPath = LSM:Fetch("font", general.font) or fontPath
        end
        outline = general.fontOutline or outline
    end

    hotkey:SetFont(fontPath, settings.keybindFontSize or 11, outline)

    local color = settings.keybindColor
    local r = color and color[1] or 1
    local g = color and color[2] or 1
    local b = color and color[3] or 1
    local a = color and color[4] or 1
    hotkey:SetTextColor(r, g, b, a)


    hotkey:ClearAllPoints()
    local anchor = settings.keybindAnchor or "TOPRIGHT"
    hotkey:SetPoint(anchor, button, anchor, (settings.keybindOffsetX or 0), (settings.keybindOffsetY or 0))
end


local function UpdateMacroText(button, settings)
    local name = button.Name
    if not name then return end

    if not settings.showMacroNames then
        name:SetAlpha(0)
        return
    end

    name:SetAlpha(1)


    local fontPath = "Fonts\\FRIZQT__.TTF"
    local outline = "OUTLINE"
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        local general = PREYCore.db.profile.general
        if general.font and LSM then
            fontPath = LSM:Fetch("font", general.font) or fontPath
        end
        outline = general.fontOutline or outline
    end

    name:SetFont(fontPath, settings.macroNameFontSize or 10, outline)

    local color = settings.macroNameColor
    local r = color and color[1] or 1
    local g = color and color[2] or 1
    local b = color and color[3] or 1
    local a = color and color[4] or 1
    name:SetTextColor(r, g, b, a)


    name:ClearAllPoints()
    local anchor = settings.macroNameAnchor or "BOTTOM"
    name:SetPoint(anchor, button, anchor, (settings.macroNameOffsetX or 0), (settings.macroNameOffsetY or 0))
end


local function UpdateCountText(button, settings)
    local count = button.Count
    if not count then return end

    if not settings.showCounts then
        count:SetAlpha(0)
        return
    end

    count:SetAlpha(1)


    local fontPath = "Fonts\\FRIZQT__.TTF"
    local outline = "OUTLINE"
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        local general = PREYCore.db.profile.general
        if general.font and LSM then
            fontPath = LSM:Fetch("font", general.font) or fontPath
        end
        outline = general.fontOutline or outline
    end

    count:SetFont(fontPath, settings.countFontSize or 14, outline)

    local color = settings.countColor
    local r = color and color[1] or 1
    local g = color and color[2] or 1
    local b = color and color[3] or 1
    local a = color and color[4] or 1
    count:SetTextColor(r, g, b, a)


    count:ClearAllPoints()
    local anchor = settings.countAnchor or "BOTTOMRIGHT"
    count:SetPoint(anchor, button, anchor, (settings.countOffsetX or 0), (settings.countOffsetY or 0))
end


local function UpdateButtonText(button, settings)
    UpdateKeybindText(button, settings)
    UpdateMacroText(button, settings)
    UpdateCountText(button, settings)
end


local function ApplyBarScale()

end


local function UpdateEmptySlotVisibility(button, settings)
    if not settings then return end


    local barKey = GetBarKeyFromButton(button)
    local fadeState = barKey and ActionBars.fadeState and ActionBars.fadeState[barKey]
    local targetAlpha = fadeState and fadeState.currentAlpha or 1

    if not settings.hideEmptySlots then

        if button._preyHiddenEmpty then
            button:SetAlpha(targetAlpha)
            button._preyHiddenEmpty = nil
        end
        return
    end


    if button.action then
        local hasAction = SafeHasAction(button.action)
        if hasAction then
            button:SetAlpha(targetAlpha)
            button._preyHiddenEmpty = nil
        else
            button:SetAlpha(0)
            button._preyHiddenEmpty = true
        end
    end
end


local function MigrateLockSetting()
    local settings = GetGlobalSettings()
    if not settings then return end


    if settings.lockButtons and not settings._lockMigrated then
        SetCVar('lockActionBars', '1')
        settings._lockMigrated = true
    end
end


local function ApplyButtonLock()
    local locked = GetCVar('lockActionBars') == '1'
    LOCK_ACTIONBAR = locked and '1' or '0'
end


local usabilityCheckFrame = nil

local RANGE_CHECK_INTERVAL_NORMAL = 0.25
local RANGE_CHECK_INTERVAL_FAST = 0.05

local function GetUpdateInterval()
    local settings = GetGlobalSettings()
    if settings and settings.fastUsabilityUpdates then
        return RANGE_CHECK_INTERVAL_FAST
    end
    return RANGE_CHECK_INTERVAL_NORMAL
end


local function SafeIsActionInRange(action)
    if IS_MIDNIGHT then


        local ok, result = pcall(function()
            local inRange = IsActionInRange(action)

            if inRange == false then return false end
            if inRange == true then return true end
            return nil
        end)
        if not ok then return nil end
        return result
    else
        return IsActionInRange(action)
    end
end

local function SafeIsUsableAction(action)
    if IS_MIDNIGHT then


        local ok, isUsable, notEnoughMana = pcall(function()
            local usable, noMana = IsUsableAction(action)

            local boolUsable = usable and true or false
            local boolNoMana = noMana and true or false
            return boolUsable, boolNoMana
        end)
        if not ok then return true, false end
        return isUsable, notEnoughMana
    else
        return IsUsableAction(action)
    end
end


local function UpdateButtonUsability(button, settings)
    if not settings then return end
    if not button.action then return end

    local icon = button.icon or button.Icon
    if not icon then return end


    if not settings.rangeIndicator and not settings.usabilityIndicator then
        if button._preyTinted then
            icon:SetVertexColor(1, 1, 1, 1)
            icon:SetDesaturated(false)
            button._preyTinted = nil
        end
        return
    end


    if settings.rangeIndicator then
        local inRange = SafeIsActionInRange(button.action)
        if inRange == false then
            local c = settings.rangeColor
            local r = c and c[1] or 0.8
            local g = c and c[2] or 0.1
            local b = c and c[3] or 0.1
            local a = c and c[4] or 1
            icon:SetVertexColor(r, g, b, a)
            icon:SetDesaturated(false)
            button._preyTinted = "range"
            return
        end
    end


    if settings.usabilityIndicator then
        local isUsable, notEnoughMana = SafeIsUsableAction(button.action)

        if notEnoughMana then

            local c = settings.manaColor
            local r = c and c[1] or 0.5
            local g = c and c[2] or 0.5
            local b = c and c[3] or 1.0
            local a = c and c[4] or 1
            icon:SetVertexColor(r, g, b, a)
            icon:SetDesaturated(false)
            button._preyTinted = "mana"
            return
        elseif not isUsable then

            if settings.usabilityDesaturate then
                icon:SetDesaturated(true)
                icon:SetVertexColor(0.6, 0.6, 0.6, 1)
            else
                local c = settings.usabilityColor
                local r = c and c[1] or 0.4
                local g = c and c[2] or 0.4
                local b = c and c[3] or 0.4
                local a = c and c[4] or 1
                icon:SetVertexColor(r, g, b, a)
                icon:SetDesaturated(false)
            end
            button._preyTinted = "unusable"
            return
        end
    end


    if button._preyTinted then
        icon:SetVertexColor(1, 1, 1, 1)
        icon:SetDesaturated(false)
        button._preyTinted = nil
    end
end


local function UpdateAllButtonUsability()
    local globalSettings = GetGlobalSettings()
    if not globalSettings then return end
    if not globalSettings.rangeIndicator and not globalSettings.usabilityIndicator then return end


    for i = 1, 8 do
        local barKey = "bar" .. i
        local buttons = GetBarButtons(barKey)
        for _, button in ipairs(buttons) do
            if button:IsVisible() then
                UpdateButtonUsability(button, globalSettings)
            end
        end
    end
end


local usabilityUpdatePending = false
local function ScheduleUsabilityUpdate()
    if usabilityUpdatePending then return end
    usabilityUpdatePending = true
    C_Timer.After(0.05, function()
        usabilityUpdatePending = false
        UpdateAllButtonUsability()
    end)
end


local function ResetAllButtonTints()
    for i = 1, 8 do
        local barKey = "bar" .. i
        local buttons = GetBarButtons(barKey)
        for _, button in ipairs(buttons) do
            local icon = button.icon or button.Icon
            if icon and button._preyTinted then
                icon:SetVertexColor(1, 1, 1, 1)
                icon:SetDesaturated(false)
                button._preyTinted = nil
            end
        end
    end
end


local function UpdateUsabilityPolling()
    local settings = GetGlobalSettings()
    local usabilityEnabled = settings and settings.usabilityIndicator
    local rangeEnabled = settings and settings.rangeIndicator


    if not usabilityCheckFrame then
        usabilityCheckFrame = CreateFrame("Frame")
        usabilityCheckFrame.elapsed = 0
    end


    if usabilityEnabled or rangeEnabled then
        usabilityCheckFrame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
        usabilityCheckFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
        usabilityCheckFrame:RegisterEvent("SPELL_UPDATE_USABLE")
        usabilityCheckFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
        usabilityCheckFrame:RegisterEvent("UNIT_POWER_UPDATE")
        usabilityCheckFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

        usabilityCheckFrame:SetScript("OnEvent", function(self, event, ...)
            ScheduleUsabilityUpdate()
        end)


        ScheduleUsabilityUpdate()
    else
        usabilityCheckFrame:UnregisterAllEvents()
        usabilityCheckFrame:SetScript("OnEvent", nil)
    end


    if rangeEnabled then
        usabilityCheckFrame:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            if self.elapsed < GetUpdateInterval() then return end
            self.elapsed = 0
            UpdateAllButtonUsability()
        end)
        usabilityCheckFrame:Show()
    else
        usabilityCheckFrame:SetScript("OnUpdate", nil)
        usabilityCheckFrame.elapsed = 0

        if not usabilityEnabled then
            usabilityCheckFrame:Hide()
            ResetAllButtonTints()
        end
    end
end


local function ApplyBarLayoutSettings()
    ApplyBarScale()
    ApplyButtonLock()
    UpdateUsabilityPolling()


    local settings = GetGlobalSettings()
    if settings then
        for barKey, _ in pairs(BUTTON_PATTERNS) do
            local buttons = GetBarButtons(barKey)
            for _, button in ipairs(buttons) do
                UpdateEmptySlotVisibility(button, settings)
            end
        end
    end
end


local function GetBarFadeState(barKey)
    if not ActionBars.fadeState[barKey] then
        ActionBars.fadeState[barKey] = {
            isFading = false,
            currentAlpha = 1,
            targetAlpha = 1,
            fadeStart = 0,
            fadeStartAlpha = 1,
            fadeDuration = 0.3,
            isMouseOver = false,
            delayTimer = nil,
            detector = nil,
        }
    end
    return ActionBars.fadeState[barKey]
end


local function SetBarAlpha(barKey, alpha)
    local buttons = GetBarButtons(barKey)
    local settings = GetGlobalSettings()
    local hideEmptyEnabled = settings and settings.hideEmptySlots

    for _, button in ipairs(buttons) do

        if hideEmptyEnabled and button._preyHiddenEmpty then
            button:SetAlpha(0)
        else
            button:SetAlpha(alpha)
        end
    end

    local barFrame = GetBarFrame(barKey)
    if barFrame then
        barFrame:SetAlpha(alpha)
    end

    GetBarFadeState(barKey).currentAlpha = alpha
end


local function StartBarFade(barKey, targetAlpha)
    local state = GetBarFadeState(barKey)
    local fadeSettings = GetFadeSettings()

    local duration = targetAlpha > state.currentAlpha
        and (fadeSettings and fadeSettings.fadeInDuration or 0.2)
        or (fadeSettings and fadeSettings.fadeOutDuration or 0.3)


    if math.abs(state.currentAlpha - targetAlpha) < 0.01 then
        state.isFading = false
        return
    end

    state.isFading = true
    state.targetAlpha = targetAlpha
    state.fadeStart = GetTime()
    state.fadeStartAlpha = state.currentAlpha
    state.fadeDuration = duration


    if not ActionBars.fadeFrame then
        ActionBars.fadeFrame = CreateFrame("Frame")
        ActionBars.fadeFrame:SetScript("OnUpdate", function(self, elapsed)
            local now = GetTime()
            local anyFading = false

            for bKey, bState in pairs(ActionBars.fadeState) do
                if bState.isFading then
                    anyFading = true
                    local elapsedTime = now - bState.fadeStart
                    local progress = math.min(elapsedTime / bState.fadeDuration, 1)


                    local easedProgress = progress * (2 - progress)

                    local alpha = bState.fadeStartAlpha +
                        (bState.targetAlpha - bState.fadeStartAlpha) * easedProgress

                    SetBarAlpha(bKey, alpha)

                    if progress >= 1 then
                        bState.isFading = false
                        SetBarAlpha(bKey, bState.targetAlpha)
                    end
                end
            end

            if not anyFading then
                self:Hide()
            end
        end)
    end
    ActionBars.fadeFrame:Show()
end


local function IsMouseOverBar(barKey)
    local barFrame = GetBarFrame(barKey)
    if barFrame and barFrame:IsMouseOver() then
        return true
    end


    local buttons = GetBarButtons(barKey)
    for _, button in ipairs(buttons) do
        if button:IsMouseOver() then
            return true
        end
    end

    return false
end


local LINKED_BAR_KEYS = {"bar1", "bar2", "bar3", "bar4", "bar5", "bar6", "bar7", "bar8"}

local function IsLinkedBar(barKey)
    for _, key in ipairs(LINKED_BAR_KEYS) do
        if key == barKey then return true end
    end
    return false
end

local function IsMouseOverAnyLinkedBar()
    for _, barKey in ipairs(LINKED_BAR_KEYS) do
        if IsMouseOverBar(barKey) then
            return true
        end
    end
    return false
end


local function ShowLinkedBarDirect(barKey)
    local barSettings = GetBarSettings(barKey)
    local fadeSettings = GetFadeSettings()

    if not barSettings then return end
    if barSettings.alwaysShow then return end

    local fadeEnabled = barSettings.fadeEnabled
    if fadeEnabled == nil then
        fadeEnabled = fadeSettings and fadeSettings.enabled
    end
    if not fadeEnabled then return end

    local state = GetBarFadeState(barKey)


    if state.delayTimer then
        state.delayTimer:Cancel()
        state.delayTimer = nil
    end
    if state.leaveCheckTimer then
        state.leaveCheckTimer:Cancel()
        state.leaveCheckTimer = nil
    end

    StartBarFade(barKey, 1)
end


local function FadeLinkedBarDirect(barKey)
    local barSettings = GetBarSettings(barKey)
    local fadeSettings = GetFadeSettings()

    if not barSettings then return end
    if barSettings.alwaysShow then return end

    local fadeEnabled = barSettings.fadeEnabled
    if fadeEnabled == nil then
        fadeEnabled = fadeSettings and fadeSettings.enabled
    end
    if not fadeEnabled then return end

    local state = GetBarFadeState(barKey)
    state.isMouseOver = false

    local fadeOutAlpha = barSettings.fadeOutAlpha
    if fadeOutAlpha == nil then
        fadeOutAlpha = fadeSettings and fadeSettings.fadeOutAlpha or 0
    end

    local delay = fadeSettings and fadeSettings.fadeOutDelay or 0.5

    if state.delayTimer then
        state.delayTimer:Cancel()
    end

    state.delayTimer = C_Timer.NewTimer(delay, function()
        state.delayTimer = nil

        if not IsMouseOverAnyLinkedBar() then
            StartBarFade(barKey, fadeOutAlpha)
        end
    end)
end


local function OnBarMouseEnter(barKey)
    local state = GetBarFadeState(barKey)
    local fadeSettings = GetFadeSettings()
    local barSettings = GetBarSettings(barKey)


    if barSettings and barSettings.alwaysShow then return end


    local fadeEnabled = barSettings and barSettings.fadeEnabled
    if fadeEnabled == nil then
        fadeEnabled = fadeSettings and fadeSettings.enabled
    end
    if not fadeEnabled then return end

    state.isMouseOver = true


    if fadeSettings and fadeSettings.linkBars1to8 and IsLinkedBar(barKey) then
        for _, linkedKey in ipairs(LINKED_BAR_KEYS) do
            if linkedKey ~= barKey then
                ShowLinkedBarDirect(linkedKey)
            end
        end
    end


    if state.delayTimer then
        state.delayTimer:Cancel()
        state.delayTimer = nil
    end
    if state.leaveCheckTimer then
        state.leaveCheckTimer:Cancel()
        state.leaveCheckTimer = nil
    end

    StartBarFade(barKey, 1)
end


local function OnBarMouseLeave(barKey)
    local state = GetBarFadeState(barKey)
    local fadeSettings = GetFadeSettings()
    local barSettings = GetBarSettings(barKey)


    if barSettings and barSettings.alwaysShow then return end


    local isMainBar = barKey and barKey:match("^bar%d$")
    if isMainBar and InCombatLockdown() and fadeSettings and fadeSettings.alwaysShowInCombat then
        return
    end


    local fadeEnabled = barSettings and barSettings.fadeEnabled
    if fadeEnabled == nil then
        fadeEnabled = fadeSettings and fadeSettings.enabled
    end
    if not fadeEnabled then return end


    if state.leaveCheckTimer then
        state.leaveCheckTimer:Cancel()
    end


    state.leaveCheckTimer = C_Timer.NewTimer(0.066, function()
        state.leaveCheckTimer = nil


        if IsMouseOverBar(barKey) then return end


        if fadeSettings and fadeSettings.linkBars1to8 and IsLinkedBar(barKey) then
            if IsMouseOverAnyLinkedBar() then
                return
            end

            for _, linkedKey in ipairs(LINKED_BAR_KEYS) do
                FadeLinkedBarDirect(linkedKey)
            end
            return
        end

        state.isMouseOver = false


        local fadeOutAlpha = barSettings and barSettings.fadeOutAlpha
        if fadeOutAlpha == nil then
            fadeOutAlpha = fadeSettings and fadeSettings.fadeOutAlpha or 0
        end

        local delay = fadeSettings and fadeSettings.fadeOutDelay or 0.5

        if state.delayTimer then
            state.delayTimer:Cancel()
        end

        state.delayTimer = C_Timer.NewTimer(delay, function()
            if not state.isMouseOver then

                local freshBarSettings = GetBarSettings(barKey)
                local freshFadeSettings = GetFadeSettings()
                local freshFadeOutAlpha = freshBarSettings and freshBarSettings.fadeOutAlpha
                if freshFadeOutAlpha == nil then
                    freshFadeOutAlpha = freshFadeSettings and freshFadeSettings.fadeOutAlpha or 0
                end
                StartBarFade(barKey, freshFadeOutAlpha)
            end
            state.delayTimer = nil
        end)
    end)
end


local function HookFrameForMouseover(frame, barKey)
    if not frame or frame._preyMouseoverHooked then return end
    frame._preyMouseoverHooked = true

    frame:HookScript("OnEnter", function()
        OnBarMouseEnter(barKey)
    end)

    frame:HookScript("OnLeave", function()
        OnBarMouseLeave(barKey)
    end)
end


local function SetupBarMouseover(barKey)
    local barSettings = GetBarSettings(barKey)
    local fadeSettings = GetFadeSettings()
    local db = GetDB()

    if not db or not db.enabled then return end


    if barKey == "extraActionButton" or barKey == "zoneAbility" then
        if not barSettings or barSettings.fadeEnabled ~= true then
            return
        end
    end

    local state = GetBarFadeState(barKey)


    if barSettings and barSettings.alwaysShow then
        SetBarAlpha(barKey, 1)
        return
    end


    local fadeEnabled = barSettings and barSettings.fadeEnabled
    if fadeEnabled == nil then
        fadeEnabled = fadeSettings and fadeSettings.enabled
    end

    if not fadeEnabled then

        SetBarAlpha(barKey, 1)
        return
    end


    local fadeOutAlpha = barSettings and barSettings.fadeOutAlpha
    if fadeOutAlpha == nil then
        fadeOutAlpha = fadeSettings and fadeSettings.fadeOutAlpha or 0
    end


    local barFrame = GetBarFrame(barKey)
    if barFrame then
        HookFrameForMouseover(barFrame, barKey)
    end


    local buttons = GetBarButtons(barKey)
    for _, button in ipairs(buttons) do
        HookFrameForMouseover(button, barKey)
    end


    state.targetAlpha = fadeOutAlpha


    state.isFading = false
    if state.delayTimer then
        state.delayTimer:Cancel()
        state.delayTimer = nil
    end
    if state.leaveCheckTimer then
        state.leaveCheckTimer:Cancel()
        state.leaveCheckTimer = nil
    end


    if not IsMouseOverBar(barKey) then
        SetBarAlpha(barKey, fadeOutAlpha)
    end
end


local COMBAT_FADE_BARS = {
    bar1 = true, bar2 = true, bar3 = true, bar4 = true,
    bar5 = true, bar6 = true, bar7 = true, bar8 = true,
}

local combatFadeFrame = CreateFrame("Frame")
combatFadeFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFadeFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

combatFadeFrame:SetScript("OnEvent", function(self, event)
    local fadeSettings = GetFadeSettings()
    if not fadeSettings or not fadeSettings.enabled then return end
    if not fadeSettings.alwaysShowInCombat then return end

    if event == "PLAYER_REGEN_DISABLED" then

        for barKey, _ in pairs(COMBAT_FADE_BARS) do
            local state = GetBarFadeState(barKey)

            if state.delayTimer then
                state.delayTimer:Cancel()
                state.delayTimer = nil
            end
            if state.leaveCheckTimer then
                state.leaveCheckTimer:Cancel()
                state.leaveCheckTimer = nil
            end

            StartBarFade(barKey, 1)
        end
    else

        for barKey, _ in pairs(COMBAT_FADE_BARS) do
            SetupBarMouseover(barKey)
        end
    end
end)


local function SkinBar(barKey)
    local db = GetDB()
    if not db or not db.enabled then return end

    local barSettings = GetBarSettings(barKey)
    if not barSettings or not barSettings.enabled then return end


    local effectiveSettings = GetEffectiveSettings(barKey)
    if not effectiveSettings then return end

    local buttons = GetBarButtons(barKey)

    for _, button in ipairs(buttons) do
        SkinButton(button, effectiveSettings)
        UpdateButtonText(button, effectiveSettings)


        AddKeybindMethods(button, barKey)


        if not button._preyOnEnterHooked then
            button._preyOnEnterHooked = true
            button:HookScript("OnEnter", function(self)
                local LibKeyBound = LibStub("LibKeyBound-1.0", true)
                if LibKeyBound and LibKeyBound:IsShown() then
                    LibKeyBound:Set(self)
                end
            end)
        end
    end
end


local function SkinAllBars()
    local db = GetDB()
    if not db or not db.enabled then return end


    for barKey, _ in pairs(BAR_FRAMES) do

        if BUTTON_PATTERNS[barKey] then
            SkinBar(barKey)
        end

        SetupBarMouseover(barKey)
    end
end


local function ApplyPageArrowVisibility(hide)
    local pageNum = MainActionBar and MainActionBar.ActionBarPageNumber
    if not pageNum then return end

    if hide then
        pageNum:Hide()
        if not pageNum._PREY_ShowHooked then
            pageNum._PREY_ShowHooked = true
            hooksecurefunc(pageNum, "Show", function(self)
                local db = GetDB()
                if db and db.bars and db.bars.bar1 and db.bars.bar1.hidePageArrow then
                    self:Hide()
                end
            end)
        end
    else
        pageNum:Show()
    end
end

_G.PreyUI_ApplyPageArrowVisibility = ApplyPageArrowVisibility


function ActionBars:Refresh()
    if not ActionBars.initialized then return end


    for button, _ in pairs(ActionBars.skinnedButtons) do
        button._preySkinKey = nil
    end

    SkinAllBars()
    ApplyBarLayoutSettings()


    local db = GetDB()
    if db and db.bars and db.bars.bar1 then
        ApplyPageArrowVisibility(db.bars.bar1.hidePageArrow)
    end
end


function ActionBars:Initialize()
    if ActionBars.initialized then return end


    if InCombatLockdown() then
        ActionBars.pendingInitialize = true
        return
    end

    local db = GetDB()
    if not db or not db.enabled then return end

    ActionBars.initialized = true


    MigrateLockSetting()


    SkinAllBars()


    ApplyBarLayoutSettings()


    if db.bars and db.bars.bar1 then
        ApplyPageArrowVisibility(db.bars.bar1.hidePageArrow)
    end


    InitializeExtraButtons()


    local pendingButtonUpdates = {}
    local buttonUpdatePending = false

    local function ProcessPendingButtonUpdates()
        buttonUpdatePending = false
        for button, updateType in pairs(pendingButtonUpdates) do
            local barKey = GetBarKeyFromButton(button)
            local settings = barKey and GetEffectiveSettings(barKey) or GetGlobalSettings()
            if settings then
                if updateType == "hotkey" or updateType == "both" then
                    UpdateKeybindText(button, settings)
                end
                if updateType == "action" or updateType == "both" then
                    UpdateButtonText(button, settings)
                    UpdateEmptySlotVisibility(button, settings)
                end
            end
        end
        wipe(pendingButtonUpdates)
    end

    local function ScheduleButtonUpdate(button, updateType)
        local existing = pendingButtonUpdates[button]
        if existing and existing ~= updateType then
            pendingButtonUpdates[button] = "both"
        else
            pendingButtonUpdates[button] = updateType
        end
        if not buttonUpdatePending then
            buttonUpdatePending = true
            C_Timer.After(0.05, ProcessPendingButtonUpdates)
        end
    end


end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then

        C_Timer.After(0.5, function()
            ActionBars:Initialize()
        end)

    elseif event == "ACTIONBAR_SLOT_CHANGED" then

        C_Timer.After(0.1, function()
            for barKey, _ in pairs(BUTTON_PATTERNS) do
                local effectiveSettings = GetEffectiveSettings(barKey)
                if effectiveSettings then
                    local buttons = GetBarButtons(barKey)
                    for _, button in ipairs(buttons) do
                        UpdateButtonText(button, effectiveSettings)
                    end
                end
            end
        end)

    elseif event == "UPDATE_BINDINGS" then

        C_Timer.After(0.1, function()
            for barKey, _ in pairs(BUTTON_PATTERNS) do
                local effectiveSettings = GetEffectiveSettings(barKey)
                if effectiveSettings then
                    local buttons = GetBarButtons(barKey)
                    for _, button in ipairs(buttons) do
                        UpdateKeybindText(button, effectiveSettings)
                    end
                end
            end
        end)

    elseif event == "PLAYER_REGEN_ENABLED" then

        if ActionBars.pendingInitialize then
            ActionBars.pendingInitialize = false
            ActionBars:Initialize()
        end

        if ActionBars.pendingRefresh then
            ActionBars.pendingRefresh = false
            ActionBars:Refresh()
        end

        if ActionBars.pendingExtraButtonInit then
            ActionBars.pendingExtraButtonInit = false
            InitializeExtraButtons()
        end
        if ActionBars.pendingExtraButtonRefresh then
            ActionBars.pendingExtraButtonRefresh = false
            RefreshExtraButtons()
        end
    end
end)


_G.PreyUI_RefreshActionBars = function()
    if InCombatLockdown() then
        ActionBars.pendingRefresh = true
        return
    end
    ActionBars:Refresh()
end


local function SetupEditModeHooks()
    if not EditModeManagerFrame then return end


    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
        local extraSettings = GetExtraButtonDB("extraActionButton")
        local zoneSettings = GetExtraButtonDB("zoneAbility")

        if (extraSettings and extraSettings.enabled) or (zoneSettings and zoneSettings.enabled) then
            ShowExtraButtonMovers()
        end
    end)


    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        HideExtraButtonMovers()
    end)
end


C_Timer.After(1, SetupEditModeHooks)


local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
if PREYCore then
    PREYCore.ActionBars = ActionBars
end
