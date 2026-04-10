local _, PREY = ...
local LSM = LibStub("LibSharedMedia-3.0")
local IS_MODERN_CLIENT = (tonumber((select(4, GetBuildInfo()))) or 0) >= 120000


local spellToKeybind = {}

local spellNameToKeybind = {}

local itemToKeybind = {}

local itemNameToKeybind = {}
local lastCacheUpdate = 0
local CACHE_UPDATE_INTERVAL = 1.0


local cachedActionButtons = {}
local actionButtonsCached = false


local macroNameToIndex = {}


local pendingRebuild = false


local rotationHelperEnabled = false
local lastNextSpellID = nil
local rotationHelperTicker = nil


local iconKeybindCache = {}


local KEYBIND_DEBUG = false


local function IsAnyKeybindFeatureEnabled()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then return false end

    local viewers = PREYCore.db.profile.viewers
    if not viewers then return false end

    for viewerName, settings in pairs(viewers) do
        if settings.showKeybinds or settings.showMacroNames or settings.showStackCounts then
            return true
        end
    end
    return false
end


local function GetGeneralFont()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        local general = PREYCore.db.profile.general
        local fontName = general.font or "Friz Quadrata TT"
        return LSM:Fetch("font", fontName) or "Fonts\\FRIZQT__.TTF"
    end
    return "Fonts\\FRIZQT__.TTF"
end

local function GetGeneralFontOutline()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        return PREYCore.db.profile.general.fontOutline or "OUTLINE"
    end
    return "OUTLINE"
end


local function FormatKeybind(keybind)
    if not keybind then return nil end

    local upper = keybind:upper()


    upper = upper:gsub(" ", "")


    upper = upper:gsub("MOUSEWHEELUP", "WU")
    upper = upper:gsub("MOUSEWHEELDOWN", "WD")
    upper = upper:gsub("MIDDLEMOUSE", "B3")
    upper = upper:gsub("MIDDLEBUTTON", "B3")
    upper = upper:gsub("BUTTON(%d+)", "B%1")


    upper = upper:gsub("SHIFT%-", "S")
    upper = upper:gsub("CTRL%-", "C")
    upper = upper:gsub("ALT%-", "A")
    upper = upper:gsub("^S%-(.+)", "S%1")
    upper = upper:gsub("^C%-(.+)", "C%1")
    upper = upper:gsub("^A%-(.+)", "A%1")


    upper = upper:gsub("NUMPADPLUS", "N+")
    upper = upper:gsub("NUMPADMINUS", "N-")
    upper = upper:gsub("NUMPADMULTIPLY", "N*")
    upper = upper:gsub("NUMPADDIVIDE", "N/")
    upper = upper:gsub("NUMPADPERIOD", "N.")
    upper = upper:gsub("NUMPADENTER", "NE")


    upper = upper:gsub("NUMPAD", "N")
    upper = upper:gsub("CAPSLOCK", "CAP")
    upper = upper:gsub("DELETE", "DEL")
    upper = upper:gsub("ESCAPE", "ESC")
    upper = upper:gsub("BACKSPACE", "BS")
    upper = upper:gsub("SPACE", "SP")
    upper = upper:gsub("INSERT", "INS")
    upper = upper:gsub("PAGEUP", "PU")
    upper = upper:gsub("PAGEDOWN", "PD")
    upper = upper:gsub("HOME", "HM")
    upper = upper:gsub("END", "ED")
    upper = upper:gsub("PRINTSCREEN", "PS")
    upper = upper:gsub("SCROLLLOCK", "SL")
    upper = upper:gsub("PAUSE", "PA")
    upper = upper:gsub("TILDE", "`")
    upper = upper:gsub("GRAVE", "`")


    upper = upper:gsub("UPARROW", "UP")
    upper = upper:gsub("DOWNARROW", "DN")
    upper = upper:gsub("LEFTARROW", "LF")
    upper = upper:gsub("RIGHTARROW", "RT")


    upper = upper:gsub("SEMICOLON", ";")
    upper = upper:gsub("APOSTROPHE", "'")
    upper = upper:gsub("LEFTBRACKET", "[")
    upper = upper:gsub("RIGHTBRACKET", "]")
    upper = upper:gsub("BACKSLASH", "\\")
    upper = upper:gsub("MINUS", "-")
    upper = upper:gsub("EQUALS", "=")
    upper = upper:gsub("COMMA", ",")

    upper = upper:gsub("^PERIOD$", ".")
    upper = upper:gsub("SLASH", "/")


    if #upper > 4 then
        upper = upper:sub(1, 4)
    end

    return upper
end


PREY.FormatKeybind = FormatKeybind


local BT4_BINDING_MAPPINGS = {
    [1] = "ACTIONBUTTON%d",
    [3] = "MULTIACTIONBAR3BUTTON%d",
    [4] = "MULTIACTIONBAR4BUTTON%d",
    [5] = "MULTIACTIONBAR2BUTTON%d",
    [6] = "MULTIACTIONBAR1BUTTON%d",
    [13] = "MULTIACTIONBAR5BUTTON%d",
    [14] = "MULTIACTIONBAR6BUTTON%d",
    [15] = "MULTIACTIONBAR7BUTTON%d",
}


local function GetBT4BindingName(buttonNum)
    local bar = math.ceil(buttonNum / 12)
    local buttonInBar = ((buttonNum - 1) % 12) + 1
    local template = BT4_BINDING_MAPPINGS[bar]
    if template then
        return string.format(template, buttonInBar)
    end
    return nil
end


local function GetBindingNameFromActionSlot(slot)
    if not slot or slot < 1 then return nil end
    if slot <= 12 then
        return "ACTIONBUTTON" .. slot
    elseif slot <= 24 then
        return "ACTIONBUTTON" .. (slot - 12)
    elseif slot <= 36 then
        return "MULTIACTIONBAR3BUTTON" .. (slot - 24)
    elseif slot <= 48 then
        return "MULTIACTIONBAR4BUTTON" .. (slot - 36)
    elseif slot <= 60 then
        return "MULTIACTIONBAR1BUTTON" .. (slot - 48)
    elseif slot <= 72 then
        return "MULTIACTIONBAR2BUTTON" .. (slot - 60)
    end
    return nil
end


local function GetKeybindFromActionButton(button, actionSlot)
    if not button then return nil end


    if button.HotKey then
        local ok, hotkeyText = pcall(function() return button.HotKey:GetText() end)
        if ok and hotkeyText and hotkeyText ~= "" and hotkeyText ~= RANGE_INDICATOR then
            return FormatKeybind(hotkeyText)
        end
    end


    if button.hotKey then
        local ok, hotkeyText = pcall(function() return button.hotKey:GetText() end)
        if ok and hotkeyText and hotkeyText ~= "" and hotkeyText ~= RANGE_INDICATOR then
            return FormatKeybind(hotkeyText)
        end
    end


    if button.GetHotkey then
        local ok, hotkey = pcall(function() return button:GetHotkey() end)
        if ok and hotkey and hotkey ~= "" then
            return FormatKeybind(hotkey)
        end
    end


    local buttonName = button:GetName()
    if buttonName then

        local key1 = GetBindingKey("CLICK " .. buttonName .. ":LeftButton")
        if key1 then
            return FormatKeybind(key1)
        end


        if buttonName:match("ActionButton(%d+)$") then
            local num = tonumber(buttonName:match("ActionButton(%d+)$"))
            if num then
                key1 = GetBindingKey("ACTIONBUTTON" .. num)
                if key1 then return FormatKeybind(key1) end
            end
        elseif buttonName:match("MultiBarBottomLeftButton(%d+)$") then
            local num = tonumber(buttonName:match("MultiBarBottomLeftButton(%d+)$"))
            if num then
                key1 = GetBindingKey("MULTIACTIONBAR1BUTTON" .. num)
                if key1 then return FormatKeybind(key1) end
            end
        elseif buttonName:match("MultiBarBottomRightButton(%d+)$") then
            local num = tonumber(buttonName:match("MultiBarBottomRightButton(%d+)$"))
            if num then
                key1 = GetBindingKey("MULTIACTIONBAR2BUTTON" .. num)
                if key1 then return FormatKeybind(key1) end
            end
        elseif buttonName:match("MultiBarRightButton(%d+)$") then
            local num = tonumber(buttonName:match("MultiBarRightButton(%d+)$"))
            if num then
                key1 = GetBindingKey("MULTIACTIONBAR3BUTTON" .. num)
                if key1 then return FormatKeybind(key1) end
            end
        elseif buttonName:match("MultiBarLeftButton(%d+)$") then
            local num = tonumber(buttonName:match("MultiBarLeftButton(%d+)$"))
            if num then
                key1 = GetBindingKey("MULTIACTIONBAR4BUTTON" .. num)
                if key1 then return FormatKeybind(key1) end
            end
        elseif buttonName:match("^BT4Button(%d+)$") then
            local num = tonumber(buttonName:match("^BT4Button(%d+)$"))
            if num then

                key1 = GetBindingKey("CLICK " .. buttonName .. ":Keybind")
                if not key1 then
                    key1 = GetBindingKey("CLICK " .. buttonName .. ":LeftButton")
                end

                if not key1 then
                    local bindingName = GetBT4BindingName(num)
                    if bindingName then
                        key1 = GetBindingKey(bindingName)
                    end
                end

                if not key1 and actionSlot then
                    local bindingName = GetBindingNameFromActionSlot(actionSlot)
                    if bindingName then
                        key1 = GetBindingKey(bindingName)
                    end
                end
                if key1 then return FormatKeybind(key1) end
            end
        elseif buttonName:match("^BT4PetButton(%d+)$") then
            local num = buttonName:match("^BT4PetButton(%d+)$")
            if num then
                key1 = GetBindingKey("CLICK " .. buttonName .. ":LeftButton")
                if not key1 then
                    key1 = GetBindingKey("BONUSACTIONBUTTON" .. num)
                end
                if key1 then return FormatKeybind(key1) end
            end
        elseif buttonName:match("^BT4StanceButton(%d+)$") then
            local num = buttonName:match("^BT4StanceButton(%d+)$")
            if num then
                key1 = GetBindingKey("CLICK " .. buttonName .. ":LeftButton")
                if not key1 then
                    key1 = GetBindingKey("SHAPESHIFTBUTTON" .. num)
                end
                if key1 then return FormatKeybind(key1) end
            end
        end
    end

    return nil
end


local function ParseMacroForSpells(macroIndex)
    local spellIDs = {}
    local spellNames = {}


    local macroName, iconTexture, body = GetMacroInfo(macroIndex)
    if not body then return spellIDs, spellNames end


    local simpleSpell = GetMacroSpell(macroIndex)
    if simpleSpell then
        spellIDs[simpleSpell] = true

        local spellInfo = C_Spell.GetSpellInfo(simpleSpell)
        if spellInfo and spellInfo.name then
            spellNames[spellInfo.name:lower()] = true
        end
    end


    for line in body:gmatch("[^\r\n]+") do
        local lineLower = line:lower()


        if not lineLower:match("^%s*%-%-") then
            local spellName = nil


            if lineLower:match("/cast") then

                local afterCast = line:match("/[cC][aA][sS][tT]%s*(.*)")
                if afterCast then

                    afterCast = afterCast:gsub("%[.-%]", "")

                    spellName = afterCast:match("^%s*(.-)%s*$")
                end
            end


            if not spellName or spellName == "" then
                if lineLower:match("/use") then
                    local afterUse = line:match("/[uU][sS][eE]%s*(.*)")
                    if afterUse then
                        afterUse = afterUse:gsub("%[.-%]", "")
                        spellName = afterUse:match("^%s*(.-)%s*$")
                    end
                end
            end


            if not spellName or spellName == "" then
                if lineLower:match("#showtooltip") then
                    spellName = line:match("#[sS][hH][oO][wW][tT][oO][oO][lL][tT][iI][pP]%s+(.+)")
                    if spellName then
                        spellName = spellName:match("^%s*(.-)%s*$")
                    end
                end
            end


            if spellName and spellName ~= "" and spellName ~= "?" then

                spellName = spellName:match("^([^;/]+)")
                if spellName then
                    spellName = spellName:match("^%s*(.-)%s*$")
                end

                if spellName and spellName ~= "" then

                    spellNames[spellName:lower()] = true


                    local spellInfo = C_Spell.GetSpellInfo(spellName)
                    if spellInfo and spellInfo.spellID then
                        spellIDs[spellInfo.spellID] = true
                    end
                end
            end
        end
    end

    return spellIDs, spellNames
end


local function ProcessActionButton(button)
    if not button then return end

    local buttonName = button:GetName()
    local action


    if buttonName and buttonName:match("^BT4Button") then
        action = button._state_action

        if not action and button.GetAction then
            local actionType, actionSlot = button:GetAction()
            if actionType == "action" then
                action = actionSlot
            end
        end
    else

        action = button.action or (button.GetAction and button:GetAction())
    end

    if not action or action == 0 then return end

    local actionType, id = GetActionInfo(action)
    local keybind = nil

    if actionType == "spell" and id then

        keybind = keybind or GetKeybindFromActionButton(button, action)
        if keybind then
            if not spellToKeybind[id] then
                spellToKeybind[id] = keybind
            end

            local spellInfo = C_Spell.GetSpellInfo(id)
            if spellInfo and spellInfo.name then
                local nameLower = spellInfo.name:lower()
                if not spellNameToKeybind[nameLower] then
                    spellNameToKeybind[nameLower] = keybind
                end
            end
        end
    elseif actionType == "item" and id then

        keybind = keybind or GetKeybindFromActionButton(button, action)
        if keybind then
            if not itemToKeybind[id] then
                itemToKeybind[id] = keybind
            end

            local itemName = C_Item.GetItemInfo(id)
            if itemName then
                local nameLower = itemName:lower()
                if not itemNameToKeybind[nameLower] then
                    itemNameToKeybind[nameLower] = keybind
                end
            end
        end
    elseif actionType == "macro" then
        keybind = keybind or GetKeybindFromActionButton(button, action)
        if not keybind then return end


        local macroName = id and GetMacroInfo(id)

        if macroName then

            local macroSpells, macroSpellNames = ParseMacroForSpells(id)


            for spellID in pairs(macroSpells) do
                if not spellToKeybind[spellID] then
                    spellToKeybind[spellID] = keybind
                end
            end

            for spellName in pairs(macroSpellNames) do
                if not spellNameToKeybind[spellName] then
                    spellNameToKeybind[spellName] = keybind
                end
            end
        else


            local actionText = GetActionText(action)

            if id and id > 0 then

                if not spellToKeybind[id] then
                    spellToKeybind[id] = keybind
                end

                local spellInfo = C_Spell.GetSpellInfo(id)
                if spellInfo and spellInfo.name then
                    local nameLower = spellInfo.name:lower()
                    if not spellNameToKeybind[nameLower] then
                        spellNameToKeybind[nameLower] = keybind
                    end
                end
            end


            if actionText and actionText ~= "" then
                local macroIndex = macroNameToIndex[actionText:lower()]
                if macroIndex then
                    local macroSpells, macroSpellNames = ParseMacroForSpells(macroIndex)
                    for spellID in pairs(macroSpells) do
                        if not spellToKeybind[spellID] then
                            spellToKeybind[spellID] = keybind
                        end
                    end
                    for spellName in pairs(macroSpellNames) do
                        if not spellNameToKeybind[spellName] then
                            spellNameToKeybind[spellName] = keybind
                        end
                    end
                end
            end
        end
    end
end


local function BuildActionButtonCache()
    if actionButtonsCached then return end

    wipe(cachedActionButtons)


    for globalName, frame in pairs(_G) do
        if type(globalName) == "string" and type(frame) == "table" then


            if type(frame.GetObjectType) ~= "function" then

            else

                local isActionButton = false


                if frame.action or (frame.GetAction and type(frame.GetAction) == "function") then
                    isActionButton = true
                end


                if not isActionButton then
                    if globalName:match("ActionButton%d+$") or
                       globalName:match("Button%d+$") and globalName:match("Bar") then
                        if frame.action or frame.GetAction then
                            isActionButton = true
                        end
                    end
                end

                if isActionButton then
                    table.insert(cachedActionButtons, frame)
                end
            end
        end
    end


    local addedButtons = {}
    for _, btn in ipairs(cachedActionButtons) do
        addedButtons[btn] = true
    end

    local buttonPrefixes = {

        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
        "MultiBar5Button",
        "MultiBar6Button",
        "MultiBar7Button",

        "MultiBarBottomLeftActionButton",
        "MultiBarBottomRightActionButton",
        "MultiBarRightActionButton",
        "MultiBarLeftActionButton",
        "MultiBar5ActionButton",
        "MultiBar6ActionButton",
        "MultiBar7ActionButton",

        "OverrideActionBarButton",

        "BT4Button",

        "DominosActionButton",

        "ElvUI_Bar1Button",
        "ElvUI_Bar2Button",
        "ElvUI_Bar3Button",
        "ElvUI_Bar4Button",
        "ElvUI_Bar5Button",
        "ElvUI_Bar6Button",
    }


    for _, prefix in ipairs(buttonPrefixes) do
        for i = 1, 12 do
            local button = rawget(_G, prefix .. i)
            if button and not addedButtons[button] then
                table.insert(cachedActionButtons, button)
                addedButtons[button] = true
            end
        end
    end


    for i = 1, 180 do
        local button = rawget(_G, "DominosActionButton" .. i)
        if button and not addedButtons[button] then
            table.insert(cachedActionButtons, button)
            addedButtons[button] = true
        end
    end


    for i = 1, 120 do
        local button = rawget(_G, "BT4Button" .. i)
        if button and not addedButtons[button] then
            table.insert(cachedActionButtons, button)
            addedButtons[button] = true
        end
    end


    for i = 1, 10 do
        local button = rawget(_G, "BT4PetButton" .. i)
        if button and not addedButtons[button] then
            table.insert(cachedActionButtons, button)
            addedButtons[button] = true
        end
    end


    for i = 1, 10 do
        local button = rawget(_G, "BT4StanceButton" .. i)
        if button and not addedButtons[button] then
            table.insert(cachedActionButtons, button)
            addedButtons[button] = true
        end
    end


    table.sort(cachedActionButtons, function(a, b)
        local nameA = (type(a.GetName) == "function") and a:GetName() or ""
        local nameB = (type(b.GetName) == "function") and b:GetName() or ""


        local numA = nameA:match("^BT4Button(%d+)$")
        local numB = nameB:match("^BT4Button(%d+)$")
        if numA and numB then
            return tonumber(numA) < tonumber(numB)
        end


        numA = nameA:match("^DominosActionButton(%d+)$")
        numB = nameB:match("^DominosActionButton(%d+)$")
        if numA and numB then
            return tonumber(numA) < tonumber(numB)
        end


        local barA, slotA = nameA:match("^ElvUI_Bar(%d+)Button(%d+)$")
        local barB, slotB = nameB:match("^ElvUI_Bar(%d+)Button(%d+)$")
        if barA and barB then
            if barA ~= barB then return tonumber(barA) < tonumber(barB) end
            return tonumber(slotA) < tonumber(slotB)
        end


        local priorityA = nameA:match("^BT4") and 1 or nameA:match("^Dominos") and 2 or nameA:match("^ElvUI") and 3 or 4
        local priorityB = nameB:match("^BT4") and 1 or nameB:match("^Dominos") and 2 or nameB:match("^ElvUI") and 3 or 4
        if priorityA ~= priorityB then
            return priorityA < priorityB
        end


        return false
    end)

    actionButtonsCached = true
end


local function ForceRebuildButtonCache()
    actionButtonsCached = false
    wipe(cachedActionButtons)
    BuildActionButtonCache()
end


local function RebuildCache()


    if not IsAnyKeybindFeatureEnabled() then
        lastCacheUpdate = GetTime()
        return
    end


    if InCombatLockdown() then
        pendingRebuild = true
        return
    end


    if not actionButtonsCached then
        BuildActionButtonCache()
    end

    wipe(spellToKeybind)
    wipe(spellNameToKeybind)
    wipe(itemToKeybind)
    wipe(itemNameToKeybind)


    wipe(macroNameToIndex)
    for i = 1, 138 do
        local name = GetMacroInfo(i)
        if name then
            macroNameToIndex[name:lower()] = i
        end
    end


    for _, button in ipairs(cachedActionButtons) do
        pcall(ProcessActionButton, button)
    end

    lastCacheUpdate = GetTime()
    pendingRebuild = false
end


local function GetKeybindForSpell(spellID)
    if not spellID then return nil end


    local now = GetTime()
    if now - lastCacheUpdate > CACHE_UPDATE_INTERVAL then
        RebuildCache()
    end


    local ok, result = pcall(function()
        return spellToKeybind[spellID]
    end)

    if ok then
        return result
    end
    return nil
end


local function GetKeybindForSpellName(spellName)
    if not spellName then return nil end


    local now = GetTime()
    if now - lastCacheUpdate > CACHE_UPDATE_INTERVAL then
        RebuildCache()
    end


    local ok, nameLower = pcall(function() return spellName:lower() end)
    if not ok or not nameLower then return nil end

    return spellNameToKeybind[nameLower]
end


local function GetKeybindForItem(itemID)
    if not itemID then return nil end


    local now = GetTime()
    if now - lastCacheUpdate > CACHE_UPDATE_INTERVAL then
        RebuildCache()
    end

    return itemToKeybind[itemID]
end


local function GetKeybindForItemName(itemName)
    if not itemName then return nil end


    local now = GetTime()
    if now - lastCacheUpdate > CACHE_UPDATE_INTERVAL then
        RebuildCache()
    end


    local ok, nameLower = pcall(function() return itemName:lower() end)
    if not ok or not nameLower then return nil end

    return itemNameToKeybind[nameLower]
end


local function ApplyKeybindToIcon(icon, viewerName)
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then return end

    local settings = PREYCore.db.profile.viewers[viewerName]
    if not settings then return end


    if not settings.showKeybinds then
        if icon.keybindText then
            icon.keybindText:Hide()
        end
        return
    end


    local spellID
    local spellName
    local ok, result = pcall(function()
        local id = icon.spellID
        if not id and icon.GetSpellID then
            id = icon:GetSpellID()
        end
        return id
    end)

    if ok then
        spellID = result
    end


    if not spellID and icon.action then
        local actionOk, actionType, id = pcall(GetActionInfo, icon.action)
        if actionOk and actionType == "spell" then
            spellID = id
        end
    end


    pcall(function()

        if icon.cooldownInfo and icon.cooldownInfo.name then

            local testOk, _ = pcall(function() return icon.cooldownInfo.name:len() end)
            if testOk then
                spellName = icon.cooldownInfo.name
            end
        end

        if not spellName and spellID then
            local info = C_Spell.GetSpellInfo(spellID)
            if info and info.name then
                local testOk, _ = pcall(function() return info.name:len() end)
                if testOk then
                    spellName = info.name
                end
            end
        end
    end)


    local keybind = nil
    local baseSpellID = nil

    if spellID then
        keybind = GetKeybindForSpell(spellID)


        if not keybind and icon.cooldownInfo and icon.cooldownInfo.spellID then
            local baseFromInfo = icon.cooldownInfo.spellID

            local compareOk, isDifferent = pcall(function() return baseFromInfo ~= spellID end)
            if compareOk and isDifferent then
                keybind = GetKeybindForSpell(baseFromInfo)
                if keybind then baseSpellID = baseFromInfo end
            end
        end


        if not keybind and C_Spell.GetBaseSpell then
            local ok, result = pcall(C_Spell.GetBaseSpell, spellID)
            if ok and result then

                local compareOk, isDifferent = pcall(function() return result ~= spellID end)
                if compareOk and isDifferent then
                    baseSpellID = result
                    keybind = GetKeybindForSpell(baseSpellID)
                end
            end
        end
    end


    if not keybind and spellName then
        keybind = GetKeybindForSpellName(spellName)
    end


    local debugSpellName = "?"
    pcall(function() debugSpellName = spellName or "?" end)

    if KEYBIND_DEBUG then
        print(string.format("|cFFFFAA00[KB Debug]|r Icon=%s spellID=%s base=%s name=%s found=%s",
            tostring(icon):sub(1,20), tostring(spellID), tostring(baseSpellID),
            tostring(debugSpellName):sub(1,15), tostring(keybind)))
    end

    if keybind and KEYBIND_DEBUG then
        print("|cFF00FF00[KB Debug] Using keybind:|r " .. keybind)
    end


    if not keybind then
        if KEYBIND_DEBUG then
            print("|cFFFF0000[KB Debug] No keybind found, hiding|r")
        end
        if icon.keybindText then
            icon.keybindText:SetText("")
            icon.keybindText:Hide()
        end
        return
    end


    local fontSize = settings.keybindTextSize or 10
    local anchor = settings.keybindAnchor or "TOPLEFT"
    local offsetX = settings.keybindOffsetX or 2
    local offsetY = settings.keybindOffsetY or -2
    local textColor = settings.keybindTextColor or { 1, 1, 1, 1 }


    if not icon.keybindText then
        icon.keybindText = icon:CreateFontString(nil, "OVERLAY")
        icon.keybindText:SetShadowOffset(1, -1)
        icon.keybindText:SetShadowColor(0, 0, 0, 1)
    end


    icon.keybindText:ClearAllPoints()
    icon.keybindText:SetPoint(anchor, icon, anchor, offsetX, offsetY)


    icon.keybindText:SetFont(GetGeneralFont(), fontSize, GetGeneralFontOutline())


    icon.keybindText:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)


    if keybind then
        icon.keybindText:SetText(keybind)
        icon.keybindText:Show()
    else
        icon.keybindText:SetText("")
        icon.keybindText:Hide()
    end
end


local function UpdateViewerKeybinds(viewerName)
    if IS_MODERN_CLIENT and (viewerName == "EssentialCooldownViewer" or viewerName == "UtilityCooldownViewer") then
        return
    end

    local viewer = rawget(_G, viewerName)
    if not viewer then return end

    local container = viewer.viewerFrame or viewer
    local children = { container:GetChildren() }

    for _, child in ipairs(children) do
        if child:IsShown() then
            ApplyKeybindToIcon(child, viewerName)
        end
    end
end


local function ClearStoredKeybinds(viewerName)
    local viewer = rawget(_G, viewerName)
    if not viewer then return end

    local container = viewer.viewerFrame or viewer
    local children = { container:GetChildren() }

    for _, child in ipairs(children) do
        child._preyKeybind = nil
        child._preyKeybindSpellID = nil
    end
end

local function ClearAllStoredKeybinds()
    ClearStoredKeybinds("EssentialCooldownViewer")
    ClearStoredKeybinds("UtilityCooldownViewer")
end


local function UpdateAllKeybinds()
    if IS_MODERN_CLIENT then
        return
    end


    lastCacheUpdate = 0
    RebuildCache()

    UpdateViewerKeybinds("EssentialCooldownViewer")
    UpdateViewerKeybinds("UtilityCooldownViewer")
end


local updatePending = false
local UPDATE_THROTTLE = 0.5

local function ThrottledUpdate()
    if updatePending then return end
    updatePending = true

    C_Timer.After(UPDATE_THROTTLE, function()
        updatePending = false

        if InCombatLockdown() then
            pendingRebuild = true
            return
        end
        UpdateAllKeybinds()
    end)
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
eventFrame:RegisterEvent("UPDATE_BINDINGS")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event)
    if IS_MODERN_CLIENT then
        return
    end


    if event ~= "PLAYER_ENTERING_WORLD" and event ~= "PLAYER_REGEN_ENABLED" then
        if not IsAnyKeybindFeatureEnabled() then return end
    end

    if event == "PLAYER_REGEN_ENABLED" then

        if pendingRebuild and IsAnyKeybindFeatureEnabled() then
            C_Timer.After(0.2, UpdateAllKeybinds)
        end
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then

        C_Timer.After(0.5, function()
            if not IsAnyKeybindFeatureEnabled() then return end
            actionButtonsCached = false
            wipe(iconKeybindCache)
            UpdateAllKeybinds()
        end)
        return
    end

    if event == "UPDATE_BINDINGS" or event == "ACTIONBAR_SLOT_CHANGED" then

        wipe(iconKeybindCache)
        ClearAllStoredKeybinds()
    end


    ThrottledUpdate()
end)


local function HookViewerLayout(viewerName)

    local tocVersion = select(4, GetBuildInfo())
    if tocVersion and tocVersion >= 120000 then
        return
    end

    local viewer = rawget(_G, viewerName)
    if not viewer then return end

    if viewer.Layout and not viewer._PREY_KeybindHooked then
        viewer._PREY_KeybindHooked = true
        pcall(function()
            hooksecurefunc(viewer, "Layout", function()

                if not IsAnyKeybindFeatureEnabled() then return end
                C_Timer.After(0.25, function()

                    if not IsAnyKeybindFeatureEnabled() then return end
                    UpdateViewerKeybinds(viewerName)
                end)
            end)
        end)
    end
end


local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

initFrame:SetScript("OnEvent", function(self, event, arg)
    if event == "ADDON_LOADED" and arg == "Blizzard_CooldownManager" then
        C_Timer.After(0.5, function()
            HookViewerLayout("EssentialCooldownViewer")
            HookViewerLayout("UtilityCooldownViewer")

            if IsAnyKeybindFeatureEnabled() then
                UpdateAllKeybinds()
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1.0, function()
            HookViewerLayout("EssentialCooldownViewer")
            HookViewerLayout("UtilityCooldownViewer")

            if IsAnyKeybindFeatureEnabled() then
                UpdateAllKeybinds()
            end
        end)
    end
end)


_G.PreyUI_UpdateViewerKeybinds = function(viewerName)
    if IS_MODERN_CLIENT then return end


    if not IsAnyKeybindFeatureEnabled() then return end
    UpdateViewerKeybinds(viewerName)
end


local function DebugPrintCache()
    print("|cFFF87171[PREY Keybinds]|r Cache contents:")


    print("|cFF00FF00Spell ID Cache:|r")
    local count = 0
    for spellID, keybind in pairs(spellToKeybind) do
        local spellInfo = C_Spell.GetSpellInfo(spellID)
        local spellName = spellInfo and spellInfo.name or "Unknown"
        print(string.format("  SpellID %d (%s) = %s", spellID, spellName, keybind))
        count = count + 1
        if count >= 15 then
            print("  ... and more (showing first 15)")
            break
        end
    end
    if count == 0 then
        print("  |cFFFF0000Spell ID cache is empty!|r")
    end


    print("|cFF00FF00Spell Name Cache:|r")
    local nameCount = 0
    for spellName, keybind in pairs(spellNameToKeybind) do
        print(string.format("  '%s' = %s", spellName, keybind))
        nameCount = nameCount + 1
        if nameCount >= 15 then
            print("  ... and more (showing first 15)")
            break
        end
    end
    if nameCount == 0 then
        print("  |cFFFF0000Spell Name cache is empty!|r")
    end

    if count == 0 and nameCount == 0 then
        print("  Scanning for action buttons...")


        local foundButtons = {}
        for globalName, frame in pairs(_G) do
            if type(globalName) == "string" and type(frame) == "table" then
                if frame.action or (frame.GetAction and type(frame.GetAction) == "function") then
                    table.insert(foundButtons, globalName)
                    if #foundButtons >= 10 then break end
                end
            end
        end

        if #foundButtons > 0 then
            print("  Found action buttons: " .. table.concat(foundButtons, ", "))
        else
            print("  |cFFFF0000No action buttons found in _G!|r")
        end
    end
end


local function DebugMacro(macroName)

    local macroIndex = nil
    for i = 1, 138 do
        local name = GetMacroInfo(i)
        if name and name:lower() == macroName:lower() then
            macroIndex = i
            break
        end
    end

    if not macroIndex then
        print("|cFFFF0000Macro '" .. macroName .. "' not found!|r")
        return
    end

    local name, iconTexture, body = GetMacroInfo(macroIndex)
    print("|cFFF87171[PREY Keybinds]|r Macro Debug: " .. name)
    print("  Index: " .. macroIndex)
    print("  Body:")
    for line in body:gmatch("[^\r\n]+") do
        print("    |cFF888888" .. line .. "|r")
    end


    local simpleSpell = GetMacroSpell(macroIndex)
    if simpleSpell then
        local spellInfo = C_Spell.GetSpellInfo(simpleSpell)
        print("  GetMacroSpell: " .. simpleSpell .. " (" .. (spellInfo and spellInfo.name or "?") .. ")")
    else
        print("  GetMacroSpell: |cFFFF0000nil|r")
    end


    local spellIDs, spellNames = ParseMacroForSpells(macroIndex)
    print("  Parsed Spell IDs:")
    for id in pairs(spellIDs) do
        local info = C_Spell.GetSpellInfo(id)
        print("    " .. id .. " (" .. (info and info.name or "?") .. ")")
    end
    print("  Parsed Spell Names:")
    for spellName in pairs(spellNames) do
        print("    '" .. spellName .. "'")
    end
end


local function DebugFindMacro(macroName)

    local targetMacroIndex = nil
    for i = 1, 138 do
        local name = GetMacroInfo(i)
        if name and name:lower() == macroName:lower() then
            targetMacroIndex = i
            break
        end
    end

    if not targetMacroIndex then
        print("|cFFFF0000Macro '" .. macroName .. "' not found!|r")
        return
    end

    print("|cFFF87171[PREY Keybinds]|r Searching for macro '" .. macroName .. "' (index " .. targetMacroIndex .. ") on action buttons...")


    local foundButtons = {}
    local scannedCount = 0

    for globalName, frame in pairs(_G) do
        if type(globalName) == "string" and type(frame) == "table" then
            local action = nil

            if type(frame.action) == "number" then
                action = frame.action
            elseif frame.GetAction and type(frame.GetAction) == "function" then
                local ok, result = pcall(function() return frame:GetAction() end)
                if ok and type(result) == "number" then
                    action = result
                end
            end

            if action and action >= 1 and action <= 180 then
                scannedCount = scannedCount + 1
                local ok, actionType, id = pcall(GetActionInfo, action)
                if ok and actionType == "macro" and id == targetMacroIndex then
                    local keybind = GetKeybindFromActionButton(frame, action)
                    table.insert(foundButtons, {
                        name = globalName,
                        action = action,
                        keybind = keybind or "none"
                    })
                end
            end
        end
    end

    print("  Scanned " .. scannedCount .. " action buttons")

    if #foundButtons > 0 then
        print("  |cFF00FF00Found on " .. #foundButtons .. " button(s):|r")
        for _, btn in ipairs(foundButtons) do
            print("    " .. btn.name .. " (action=" .. btn.action .. ", keybind=" .. btn.keybind .. ")")
        end


        print("  Checking if in cachedActionButtons...")
        for _, btn in ipairs(foundButtons) do
            local inCache = false
            for _, cachedBtn in ipairs(cachedActionButtons) do
                if cachedBtn:GetName() == btn.name then
                    inCache = true
                    break
                end
            end
            print("    " .. btn.name .. ": " .. (inCache and "|cFF00FF00YES|r" or "|cFFFF0000NO|r"))
        end
    else
        print("  |cFFFF0000Not found on any action button!|r")
        print("  Is the macro placed on an action bar?")


        print("  Checking for direct macro binding...")
        local macroBindingName = "MACRO " .. macroName
        local key1, key2 = GetBindingKey(macroBindingName)
        if key1 or key2 then
            print("  |cFF00FF00Found direct binding:|r " .. (key1 or "") .. " " .. (key2 or ""))
        else
            print("  No direct binding found for '" .. macroBindingName .. "'")
        end
    end
end


local function DebugKey(keyName)
    print("|cFFF87171[PREY Keybinds]|r Checking what '" .. keyName .. "' is bound to...")


    local action = GetBindingAction(keyName)
    if action and action ~= "" then
        print("  GetBindingAction: |cFF00FF00" .. action .. "|r")


        if action:match("BUTTON%d+$") then

            local buttonNum = action:match("BUTTON(%d+)$")
            local possibleFrames = {}

            if action:match("^ACTIONBUTTON") then
                table.insert(possibleFrames, "ActionButton" .. buttonNum)
                table.insert(possibleFrames, "DominosActionButton" .. buttonNum)
            elseif action:match("^MULTIACTIONBAR1") then
                table.insert(possibleFrames, "MultiBarBottomLeftButton" .. buttonNum)
                table.insert(possibleFrames, "DominosActionButton" .. (12 + tonumber(buttonNum)))
            elseif action:match("^MULTIACTIONBAR2") then
                table.insert(possibleFrames, "MultiBarBottomRightButton" .. buttonNum)
                table.insert(possibleFrames, "DominosActionButton" .. (24 + tonumber(buttonNum)))
            elseif action:match("^MULTIACTIONBAR3") then
                table.insert(possibleFrames, "MultiBarRightButton" .. buttonNum)
            elseif action:match("^MULTIACTIONBAR4") then
                table.insert(possibleFrames, "MultiBarLeftButton" .. buttonNum)
            end

            print("  Looking for button frames...")
            for _, frameName in ipairs(possibleFrames) do
                local frame = rawget(_G, frameName)
                if frame then
                    print("    Found: " .. frameName)
                    local btnAction = frame.action or (frame.GetAction and frame:GetAction())
                    if btnAction then
                        print("      action slot = " .. tostring(btnAction))
                        local ok, actionType, id = pcall(GetActionInfo, btnAction)
                        if ok and actionType then
                            print("      type = " .. actionType .. ", id = " .. tostring(id))
                            if actionType == "macro" then
                                local macroName = GetMacroInfo(id)
                                print("      |cFF00FF00Macro: " .. (macroName or "?") .. "|r")
                            elseif actionType == "spell" then
                                local spellInfo = C_Spell.GetSpellInfo(id)
                                print("      Spell: " .. (spellInfo and spellInfo.name or "?"))
                            end
                        end
                    end
                end
            end


            print("  Scanning Dominos buttons for binding '" .. action .. "'...")
            for i = 1, 180 do
                local btn = rawget(_G, "DominosActionButton" .. i)
                if btn then

                    local btnName = btn:GetName()
                    local key1, key2 = GetBindingKey(action)

                    local hotkey = btn.HotKey and btn.HotKey:GetText()
                    if hotkey and hotkey ~= "" and hotkey ~= RANGE_INDICATOR then

                        local btnAction = btn.action or (btn.GetAction and btn:GetAction())
                        if btnAction then
                            local ok, actionType, id = pcall(GetActionInfo, btnAction)
                            if ok and actionType == "macro" then
                                local macroName = GetMacroInfo(id)
                                if macroName and macroName:lower():match("shield") then
                                    print("    |cFF00FF00Found Shield macro on " .. btnName .. "!|r")
                                    print("      action slot = " .. btnAction)
                                    print("      hotkey text = " .. hotkey)
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        print("  GetBindingAction: |cFFFF0000nothing|r")
    end
end


SLASH_PREYKEYBINDS1 = "/preykeybinds"
SlashCmdList["PREYKEYBINDS"] = function(msg)
    if msg == "debug" then
        RebuildCache()
        DebugPrintCache()
    elseif msg == "refresh" then
        UpdateAllKeybinds()
        print("|cFFF87171[PREY Keybinds]|r Refreshed keybinds")
    elseif msg == "rebuild" then
        ForceRebuildButtonCache()
        RebuildCache()
        print("|cFFF87171[PREY Keybinds]|r Force rebuilt button and spell caches")
        print("  Button count: " .. #cachedActionButtons)
    elseif msg:match("^macro%s+") then
        local macroName = msg:match("^macro%s+(.+)")
        if macroName then
            DebugMacro(macroName)
        end
    elseif msg:match("^find%s+") then
        local macroName = msg:match("^find%s+(.+)")
        if macroName then
            DebugFindMacro(macroName)
        end
    elseif msg == "buttons" then

        print("|cFFF87171[PREY Keybinds]|r Action button cache:")
        print("  Cached: " .. (actionButtonsCached and "YES" or "NO"))
        print("  Button count: " .. #cachedActionButtons)
        local sample = {}
        for i = 1, math.min(10, #cachedActionButtons) do
            local name = cachedActionButtons[i]:GetName() or "unnamed"
            table.insert(sample, name)
        end
        if #sample > 0 then
            print("  Sample: " .. table.concat(sample, ", "))
        end
    elseif msg:match("^key%s+") then
        local keyName = msg:match("^key%s+(.+)")
        if keyName then
            DebugKey(keyName)
        end
    elseif msg == "dominos" then

        print("|cFFF87171[PREY Keybinds]|r Scanning Dominos buttons for macros...")
        local found = 0
        for i = 1, 180 do
            local btn = rawget(_G, "DominosActionButton" .. i)
            if btn then
                local btnAction = btn.action or (btn.GetAction and btn:GetAction())
                if btnAction then
                    local ok, actionType, id = pcall(GetActionInfo, btnAction)
                    if ok and actionType == "macro" then
                        local macroName = GetMacroInfo(id)
                        local hotkey = btn.HotKey and btn.HotKey:GetText()
                        print("  DominosActionButton" .. i .. ": |cFFFFFF00" .. (macroName or "?") .. "|r (slot " .. btnAction .. ", key: " .. (hotkey or "none") .. ")")
                        found = found + 1
                    end
                end
            end
        end
        print("  Found " .. found .. " macros on Dominos buttons")
    elseif msg == "bartender" then

        print("|cFFF87171[PREY Keybinds]|r Scanning Bartender4 buttons for macros...")
        local found = 0
        for i = 1, 120 do
            local btn = rawget(_G, "BT4Button" .. i)
            if btn then
                local btnAction = btn.action or (btn.GetAction and btn:GetAction())
                if btnAction then
                    local ok, actionType, id = pcall(GetActionInfo, btnAction)
                    if ok and actionType == "macro" then
                        local macroName = GetMacroInfo(id)
                        local hotkey = btn.HotKey and btn.HotKey:GetText()
                        if not hotkey and btn.GetHotkey then
                            local hotkeyOk, hotkeyResult = pcall(function() return btn:GetHotkey() end)
                            if hotkeyOk then hotkey = hotkeyResult end
                        end
                        print("  BT4Button" .. i .. ": |cFFFFFF00" .. (macroName or "?") .. "|r (slot " .. btnAction .. ", key: " .. (hotkey or "none") .. ")")
                        found = found + 1
                    end
                end
            end
        end
        print("  Found " .. found .. " macros on Bartender4 buttons")
    elseif msg:match("^trace%s+") then

        local btnName = msg:match("^trace%s+(.+)")
        local btn = rawget(_G, btnName)
        if not btn then
            print("|cFFFF0000Button '" .. btnName .. "' not found!|r")
            return
        end
        print("|cFFF87171[PREY Keybinds]|r Tracing button: " .. btnName)


        local inCache = false
        for _, cachedBtn in ipairs(cachedActionButtons) do
            local cachedName = cachedBtn.GetName and cachedBtn:GetName()
            if cachedName and cachedName == btnName then
                inCache = true
                break
            end
        end
        print("  In cachedActionButtons: " .. (inCache and "|cFF00FF00YES|r" or "|cFFFF0000NO|r"))


        local btnAction = btn.action or (btn.GetAction and btn:GetAction())
        print("  action slot: " .. tostring(btnAction))

        if btnAction then
            local ok, actionType, id = pcall(GetActionInfo, btnAction)
            if ok then
                print("  actionType: " .. tostring(actionType))
                print("  id: " .. tostring(id))
            end
        end


        local keybind = GetKeybindFromActionButton(btn, btnAction)
        print("  GetKeybindFromActionButton: " .. (keybind and ("|cFF00FF00" .. keybind .. "|r") or "|cFFFF0000nil|r"))


        print("  Manual binding checks:")
        local hotkey = btn.HotKey and btn.HotKey:GetText()
        print("    HotKey text: " .. (hotkey or "nil"))

        local key1, key2 = GetBindingKey("CLICK " .. btnName .. ":LeftButton")
        print("    CLICK " .. btnName .. ":LeftButton -> " .. (key1 or "nil"))


        if btnName:match("^MultiBarBottomRight") then
            local num = btnName:match("Button(%d+)$")
            local bindingName = "MULTIACTIONBAR2BUTTON" .. num
            key1, key2 = GetBindingKey(bindingName)
            print("    " .. bindingName .. " -> " .. (key1 or "nil"))
        end


        if btnName:match("^BT4Button(%d+)$") then
            local num = tonumber(btnName:match("^BT4Button(%d+)$"))
            print("  |cFFFFFF00BT4-specific checks:|r")


            local stateAction = btn._state_action
            print("    _state_action: " .. tostring(stateAction))


            key1 = GetBindingKey("CLICK " .. btnName .. ":Keybind")
            print("    CLICK " .. btnName .. ":Keybind -> " .. (key1 or "nil"))


            local bt4BindingName = GetBT4BindingName(num)
            print("    GetBT4BindingName(" .. num .. ") -> " .. (bt4BindingName or "nil"))

            if bt4BindingName then
                key1 = GetBindingKey(bt4BindingName)
                print("    GetBindingKey(\"" .. bt4BindingName .. "\") -> " .. (key1 or "nil"))
            end


            if num <= 12 then
                print("    |cFF00FFFFBar 1 button - checking action slot binding:|r")
                local actionSlot = stateAction or btnAction
                if actionSlot and actionSlot >= 1 and actionSlot <= 12 then
                    local slotBinding = "ACTIONBUTTON" .. actionSlot
                    key1 = GetBindingKey(slotBinding)
                    print("      Action slot " .. actionSlot .. " -> " .. slotBinding .. " -> " .. (key1 or "nil"))
                end
            end


            for i, cachedBtn in ipairs(cachedActionButtons) do
                local cachedName = cachedBtn.GetName and cachedBtn:GetName()
                if cachedName == btnName then
                    print("    Cache position: " .. i .. " of " .. #cachedActionButtons)
                    break
                end
            end
        end
    elseif msg == "proctest" then

        KEYBIND_DEBUG = not KEYBIND_DEBUG
        print("|cFFF87171[PREY Keybinds]|r Proc debug mode: " .. (KEYBIND_DEBUG and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"))
        if KEYBIND_DEBUG then
            print("  Watch chat for keybind tracking messages when spells proc")
        end
    else
        print("|cFFF87171[PREY Keybinds]|r Commands:")
        print("  /preykeybinds debug - Show cache contents")
        print("  /preykeybinds refresh - Force refresh keybinds")
        print("  /preykeybinds rebuild - Force rebuild button cache")
        print("  /preykeybinds macro <name> - Debug a specific macro")
        print("  /preykeybinds find <name> - Find which button has a macro")
        print("  /preykeybinds buttons - Show cached action buttons")
        print("  /preykeybinds key <key> - Check what a key is bound to")
        print("  /preykeybinds trace <button> - Trace a specific button")
        print("  /preykeybinds dominos - Scan Dominos buttons for macros")
        print("  /preykeybinds bartender - Scan Bartender4 buttons for macros")
        print("  /preykeybinds proctest - Toggle proc debug mode")
    end
end


local function GetRotationHelperOverlay(icon)
    if icon._rotationHelperOverlay then
        return icon._rotationHelperOverlay
    end


    local overlay = CreateFrame("Frame", nil, icon)
    overlay:SetAllPoints(icon)
    overlay:SetFrameLevel(icon:GetFrameLevel() + 15)


    local borderSize = 2
    local borders = {}


    borders.top = overlay:CreateTexture(nil, "OVERLAY")
    borders.top:SetColorTexture(0, 1, 0, 0.8)
    borders.top:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
    borders.top:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
    borders.top:SetHeight(borderSize)


    borders.bottom = overlay:CreateTexture(nil, "OVERLAY")
    borders.bottom:SetColorTexture(0, 1, 0, 0.8)
    borders.bottom:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
    borders.bottom:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
    borders.bottom:SetHeight(borderSize)


    borders.left = overlay:CreateTexture(nil, "OVERLAY")
    borders.left:SetColorTexture(0, 1, 0, 0.8)
    borders.left:SetPoint("TOPLEFT", overlay, "TOPLEFT", 0, 0)
    borders.left:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", 0, 0)
    borders.left:SetWidth(borderSize)


    borders.right = overlay:CreateTexture(nil, "OVERLAY")
    borders.right:SetColorTexture(0, 1, 0, 0.8)
    borders.right:SetPoint("TOPRIGHT", overlay, "TOPRIGHT", 0, 0)
    borders.right:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", 0, 0)
    borders.right:SetWidth(borderSize)

    overlay.borders = borders


    overlay.SetBorderColor = function(self, r, g, b, a)
        for _, tex in pairs(self.borders) do
            tex:SetColorTexture(r, g, b, a or 0.8)
        end
    end


    overlay.SetBorderSize = function(self, size)
        self.borders.top:SetHeight(size)
        self.borders.bottom:SetHeight(size)
        self.borders.left:SetWidth(size)
        self.borders.right:SetWidth(size)
    end

    overlay:Hide()
    icon._rotationHelperOverlay = overlay
    return overlay
end


local function ApplyRotationHelperToIcon(icon, viewerName, nextSpellID)
    if IS_MODERN_CLIENT then
        return
    end

    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then return end

    local settings = PREYCore.db.profile.viewers[viewerName]
    if not settings or not settings.showRotationHelper then

        if icon._rotationHelperOverlay then
            icon._rotationHelperOverlay:Hide()
        end
        return
    end


    local iconSpellID
    local ok, result = pcall(function()

        if icon.cooldownID then
            return icon.cooldownID
        end

        if icon.cooldownInfo and icon.cooldownInfo.spellID then
            return icon.cooldownInfo.spellID
        end

        if icon.spellID then
            return icon.spellID
        end
        return nil
    end)

    if ok then
        iconSpellID = result
    end

    if not iconSpellID then
        if icon._rotationHelperOverlay then
            icon._rotationHelperOverlay:Hide()
        end
        return
    end


    local isNextSpell = false
    if nextSpellID then

        if iconSpellID == nextSpellID then
            isNextSpell = true
        end

        if not isNextSpell and icon.cooldownInfo and icon.cooldownInfo.overrideSpellID then
            if icon.cooldownInfo.overrideSpellID == nextSpellID then
                isNextSpell = true
            end
        end
    end

    local overlay = GetRotationHelperOverlay(icon)

    if isNextSpell then
        local color = settings.rotationHelperColor or { 0, 1, 0, 0.8 }
        local thickness = settings.rotationHelperThickness or 2
        overlay:SetBorderColor(color[1], color[2], color[3], color[4] or 0.8)
        overlay:SetBorderSize(thickness)
        overlay:Show()
    else
        overlay:Hide()
    end
end


local function UpdateViewerRotationHelper(viewerName, nextSpellID)
    local viewer = rawget(_G, viewerName)
    if not viewer then return end

    local container = viewer.viewerFrame or viewer
    local children = { container:GetChildren() }

    for _, child in ipairs(children) do
        if child:IsShown() then
            ApplyRotationHelperToIcon(child, viewerName, nextSpellID)
        end
    end
end


local function UpdateAllRotationHelpers()
    if IS_MODERN_CLIENT then
        return
    end


    if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then
        return
    end


    local ok, nextSpellID = pcall(C_AssistedCombat.GetNextCastSpell, false)
    if not ok then
        nextSpellID = nil
    end


    if nextSpellID == lastNextSpellID then
        return
    end
    lastNextSpellID = nextSpellID

    UpdateViewerRotationHelper("EssentialCooldownViewer", nextSpellID)
    UpdateViewerRotationHelper("UtilityCooldownViewer", nextSpellID)
end


local function ShouldRunRotationHelper()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then return false end

    local viewers = PREYCore.db.profile.viewers
    if not viewers then return false end

    local essential = viewers.EssentialCooldownViewer
    local utility = viewers.UtilityCooldownViewer

    return (essential and essential.showRotationHelper) or (utility and utility.showRotationHelper)
end


local ROTATION_HELPER_INTERVAL = 0.1

local function StartRotationHelperTicker()
    if IS_MODERN_CLIENT then
        return
    end

    if rotationHelperTicker then rotationHelperTicker:Cancel() end
    rotationHelperTicker = C_Timer.NewTicker(ROTATION_HELPER_INTERVAL, function()
        if not rotationHelperEnabled then return end
        if not ShouldRunRotationHelper() then return end
        UpdateAllRotationHelpers()
    end)
end

local function StopRotationHelperTicker()
    if rotationHelperTicker then
        rotationHelperTicker:Cancel()
        rotationHelperTicker = nil
    end
end


local function RefreshRotationHelper()
    if IS_MODERN_CLIENT then
        rotationHelperEnabled = false
        lastNextSpellID = nil
        StopRotationHelperTicker()
        return
    end

    rotationHelperEnabled = ShouldRunRotationHelper()

    if not rotationHelperEnabled then

        lastNextSpellID = nil
        UpdateViewerRotationHelper("EssentialCooldownViewer", nil)
        UpdateViewerRotationHelper("UtilityCooldownViewer", nil)
        StopRotationHelperTicker()
    else

        StartRotationHelperTicker()
    end
end


local rotationHelperInitFrame = CreateFrame("Frame")
rotationHelperInitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
rotationHelperInitFrame:SetScript("OnEvent", function()
    C_Timer.After(1.0, RefreshRotationHelper)
end)


PREY.Keybinds = {
    UpdateAll = UpdateAllKeybinds,
    UpdateViewer = UpdateViewerKeybinds,
    GetKeybindForSpell = GetKeybindForSpell,
    GetKeybindForSpellName = GetKeybindForSpellName,
    GetKeybindForItem = GetKeybindForItem,
    GetKeybindForItemName = GetKeybindForItemName,
    RebuildCache = RebuildCache,
    DebugPrintCache = DebugPrintCache,
    RefreshRotationHelper = RefreshRotationHelper,
    UpdateAllRotationHelpers = UpdateAllRotationHelpers,
}


_G.PreyUI_RefreshKeybinds = UpdateAllKeybinds
_G.PreyUI_RefreshRotationHelper = RefreshRotationHelper

