local ADDON_NAME, ns = ...
local PREY = ns.PREY or {}
ns.PREY = PREY


local EQUIPMENT_SLOTS = {
    { name = "Head", id = INVSLOT_HEAD, side = "left" },
    { name = "Neck", id = INVSLOT_NECK, side = "left" },
    { name = "Shoulder", id = INVSLOT_SHOULDER, side = "left" },
    { name = "Back", id = INVSLOT_BACK, side = "left" },
    { name = "Chest", id = INVSLOT_CHEST, side = "left" },
    { name = "Shirt", id = INVSLOT_BODY, side = "left" },
    { name = "Tabard", id = INVSLOT_TABARD, side = "left" },
    { name = "Wrist", id = INVSLOT_WRIST, side = "left" },
    { name = "MainHand", id = INVSLOT_MAINHAND, side = "bottom" },
    { name = "SecondaryHand", id = INVSLOT_OFFHAND, side = "bottom" },
    { name = "Hands", id = INVSLOT_HAND, side = "right" },
    { name = "Waist", id = INVSLOT_WAIST, side = "right" },
    { name = "Legs", id = INVSLOT_LEGS, side = "right" },
    { name = "Feet", id = INVSLOT_FEET, side = "right" },
    { name = "Finger0", id = INVSLOT_FINGER1, side = "right" },
    { name = "Finger1", id = INVSLOT_FINGER2, side = "right" },
    { name = "Trinket0", id = INVSLOT_TRINKET1, side = "right" },
    { name = "Trinket1", id = INVSLOT_TRINKET2, side = "right" },
}


local C = {
    bg = { 0.067, 0.094, 0.153, 0.95 },
    bgLight = { 0.122, 0.161, 0.216, 1 },
    accent = { 0.820, 0.180, 0.220, 1 },
    text = { 0.953, 0.957, 0.965, 1 },
    textMuted = { 0.6, 0.65, 0.7, 1 },
    border = { 0.2, 0.25, 0.3, 1 },


    health = { 0.937, 0.267, 0.267, 1 },
    mana = { 0.231, 0.510, 0.965, 1 },
    crit = { 0.976, 0.451, 0.086, 1 },
    haste = { 0.918, 0.702, 0.031, 1 },
    mastery = { 0.545, 0.361, 0.965, 1 },
    versatility = { 0.024, 0.714, 0.831, 1 },


    enchanted = { 0.820, 0.180, 0.220, 1 },
    missing = { 0.6, 0.6, 0.6, 0.7 },
}


local GEM_COLORS = {
    Red = { 1, 0.2, 0.2, 1 },
    Blue = { 0.2, 0.4, 1, 1 },
    Yellow = { 1, 0.8, 0.2, 1 },
    Meta = { 0.8, 0.8, 0.8, 1 },
    Prismatic = { 1, 1, 1, 1 },
    Hydraulic = { 0.2, 0.8, 0.8, 1 },
    Cogwheel = { 0.7, 0.7, 0.7, 1 },
    Domination = { 0.6, 0.2, 0.8, 1 },
    Tinker = { 0.4, 0.8, 0.4, 1 },
    Primordial = { 0.4, 0.6, 0.8, 1 },
}


local CLASS_ABBREVIATIONS = {
    ["Demon Hunter"] = "DH",
    ["Death Knight"] = "DK",
}

local function AbbreviateClassName(className)
    return CLASS_ABBREVIATIONS[className] or className
end


local characterPaneInitialized = false
local slotOverlays = {}
local statsPanel = nil
local pendingUpdate = false
local updatingStatsPanel = false


local CreateStatsPanel
local ScheduleUpdate


local defaultSettings = {
    enabled = true,
    showItemName = true,
    showItemLevel = true,
    showEnchants = true,
    showGems = true,
    showDurability = false,
    inspectEnabled = true,
    showModelBackground = true,
    secondaryStatFormat = "both",
    showTooltips = false,

    showInspectItemName = true,
    showInspectItemLevel = true,
    showInspectEnchants = true,
    showInspectGems = true,
}

local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.character then
        return PREYCore.db.profile.character
    end

    return defaultSettings
end


local trackedEnchantFonts = {}
local trackedILvlFonts = {}
local trackedItemNameFonts = {}


local function GetGlobalFont()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile then
        local fontName = PREYCore.db.profile.general and PREYCore.db.profile.general.font
        if fontName then
            local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
            if LSM then
                local fontPath = LSM:Fetch("font", fontName)
                if fontPath then
                    return fontPath
                end
            end
        end
    end
    return STANDARD_TEXT_FONT
end


local function GetItemQualityColorRGB(quality)
    if quality and quality >= 0 then
        local r, g, b = GetItemQualityColor(quality)
        return r, g, b
    end
    return 1, 1, 1
end


local function FormatNumber(num)
    if not num or num == 0 then return "0" end
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(math.floor(num))
    end
end


local function FormatPercent(value, decimals)
    decimals = decimals or 2
    return string.format("%." .. decimals .. "f%%", value or 0)
end


local function GetSlotItemLevel(unit, slotId)
    local itemLink = GetInventoryItemLink(unit, slotId)
    if not itemLink then return nil end

    local itemLevel = nil


    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if itemID and C_Item and C_Item.RequestLoadItemDataByID then
        if not C_Item.IsItemDataCachedByID(itemID) then
            C_Item.RequestLoadItemDataByID(itemID)
        end
    end


    if C_Item and C_Item.GetItemInfo then
        local _, _, _, ilvl = C_Item.GetItemInfo(itemLink)
        if ilvl then
            itemLevel = ilvl
        end
    end


    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local tooltipData = C_TooltipInfo.GetInventoryItem(unit, slotId)
        if tooltipData and tooltipData.lines then

            local pattern
            if ITEM_LEVEL then
                pattern = ITEM_LEVEL:gsub("%%d", "(%%d+)")
            else
                pattern = "Item Level (%d+)"
            end
            for _, line in ipairs(tooltipData.lines) do
                local text = line.leftText or ""
                local tooltipIlvl = text:match(pattern)
                if tooltipIlvl then
                    local parsed = tonumber(tooltipIlvl)
                    if parsed then
                        itemLevel = parsed
                    end
                    break
                end
            end
        end
    end

    return itemLevel
end


local function GetSlotItemQuality(unit, slotId)
    local ok, quality = pcall(function()
        return GetInventoryItemQuality(unit, slotId)
    end)
    if ok then
        return quality
    end
    return nil
end


local function GetEnchantText(unit, slotId)
    local itemLink = GetInventoryItemLink(unit, slotId)
    if not itemLink then return nil, nil end


    local enchantableSlots = {
        [INVSLOT_CHEST] = true,
        [INVSLOT_BACK] = true,
        [INVSLOT_WRIST] = true,
        [INVSLOT_LEGS] = true,
        [INVSLOT_FEET] = true,
        [INVSLOT_FINGER1] = true,
        [INVSLOT_FINGER2] = true,
        [INVSLOT_MAINHAND] = true,
        [INVSLOT_OFFHAND] = true,
    }

    if not enchantableSlots[slotId] then
        return nil, false
    end


    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local tooltipData = C_TooltipInfo.GetInventoryItem(unit, slotId)
        if tooltipData and tooltipData.lines then
            for _, line in ipairs(tooltipData.lines) do
                local text = line.leftText or ""

                local enchant
                if ENCHANTED_TOOLTIP_LINE then

                    local pattern = ENCHANTED_TOOLTIP_LINE:gsub("%%s", "(.+)")
                    enchant = text:match(pattern)
                end

                if not enchant then
                    enchant = text:match("Enchanted:%s*(.+)")
                end
                if enchant then

                    enchant = enchant:gsub("Enchant%s+%w+%s*%-%s*", "")

                    enchant = enchant:gsub("|c%x%x%x%x%x%x%x%x", "")
                    enchant = enchant:gsub("|r", "")
                    enchant = enchant:gsub("|A.-|a", "")
                    enchant = enchant:gsub("|T.-|t", "")

                    enchant = enchant:match("^%s*(.-)%s*$")
                    if enchant and enchant ~= "" then
                        return enchant, true
                    end
                end
            end
        end
        return nil, true
    end


    return nil, true
end


local function GetUpgradeTrack(unit, slotId)
    if not C_TooltipInfo or not C_TooltipInfo.GetInventoryItem then
        return nil, nil, nil
    end

    local tooltipData = C_TooltipInfo.GetInventoryItem(unit, slotId)
    if not tooltipData or not tooltipData.lines then
        return nil, nil, nil
    end

    for _, line in ipairs(tooltipData.lines) do
        local text = line.leftText or ""


        if ITEM_UPGRADE_FRAME_CURRENT_UPGRADE_FORMAT_STRING then
            local pattern = ITEM_UPGRADE_FRAME_CURRENT_UPGRADE_FORMAT_STRING:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
            local track, current, max = text:match(pattern)
            if track and current and max then
                return track, current, max
            end
        end


        local track, current, max = text:match("Upgrade Level:%s*(.+)%s+(%d+)%s*/%s*(%d+)")
        if track and current and max then
            return track, current, max
        end


        track, current, max = text:match(": (.+)%s+(%d+)%s*/%s*(%d+)")
        if track and current and max then
            return track, current, max
        end
    end

    return nil, nil, nil
end


local function GetGemInfo(unit, slotId)
    local itemLink = GetInventoryItemLink(unit, slotId)
    if not itemLink then return {}, 0 end

    local gems = {}
    local totalSockets = 0


    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        local tooltipData = C_TooltipInfo.GetInventoryItem(unit, slotId)
        if tooltipData and tooltipData.lines then
            for _, line in ipairs(tooltipData.lines) do

                if line.type == 3 then
                    totalSockets = totalSockets + 1
                end
            end
        end
    end


    local filledCount = 0
    for i = 1, 4 do

        local gemName, gemLink = GetItemGem(itemLink, i)

        if gemLink then
            filledCount = filledCount + 1

            local _, _, _, _, _, _, gemSubType, _, _, gemIcon = GetItemInfo(gemLink)


            if not gemIcon and C_Item and C_Item.GetItemIconByID then
                local itemID = GetItemInfoInstant(gemLink)
                if itemID then
                    gemIcon = C_Item.GetItemIconByID(itemID)
                end
            end

            table.insert(gems, {
                link = gemLink,
                icon = gemIcon,
                type = gemSubType or "Prismatic",
                filled = true,
            })
        end
    end


    if totalSockets < filledCount then
        totalSockets = filledCount
    end


    local emptySockets = totalSockets - filledCount
    for i = 1, emptySockets do
        table.insert(gems, {
            link = nil,
            icon = nil,
            type = "Empty",
            filled = false,
        })
    end

    return gems, totalSockets
end


local function GetSlotDurability(slotId)
    local current, max = GetInventoryItemDurability(slotId)
    if current and max and max > 0 then
        return current, max, (current / max) * 100
    end
    return nil, nil, nil
end


local function CreateSlotOverlay(slotFrame, slotInfo, unit)
    if not slotFrame then return nil end


    local settings = GetSettings()
    local scale = 1.0


    local ITEM_LEVEL_FONT = math.floor(12 * scale)
    local ENCHANT_FONT = math.floor(9 * scale)
    local ENCHANT_WIDTH_LEFT = math.floor(110 * scale)
    local ENCHANT_WIDTH_RIGHT = math.floor(75 * scale)
    local GEM_SIZE = math.floor(12 * scale)
    local GEM_SPACING = math.floor(2 * scale)

    local overlay = CreateFrame("Frame", nil, slotFrame)
    overlay:SetAllPoints(slotFrame)
    overlay:SetFrameLevel(slotFrame:GetFrameLevel() + 10)
    overlay:SetClipsChildren(false)
    overlay.unit = unit or "player"


    local slotFont = GetGlobalFont()
    local slotTextSize
    if unit == "target" then
        slotTextSize = settings.inspectSlotTextSize or 12
    else
        slotTextSize = settings.slotTextSize or ENCHANT_FONT
    end
    local TEXT_WIDTH = math.floor(140 * scale)
    local FONT_FLAGS = "OUTLINE"


    overlay.itemName = overlay:CreateFontString(nil, "OVERLAY")
    overlay.itemName:SetFont(slotFont, slotTextSize, FONT_FLAGS)
    overlay.itemName:SetTextColor(1, 1, 1, 1)
    overlay.itemName:SetWordWrap(false)
    overlay.itemName:SetWidth(TEXT_WIDTH)

    if unit ~= "target" then
        table.insert(trackedItemNameFonts, overlay.itemName)
    end


    overlay.itemLevel = overlay:CreateFontString(nil, "OVERLAY")
    overlay.itemLevel:SetFont(slotFont, slotTextSize, FONT_FLAGS)
    overlay.itemLevel:SetTextColor(1, 1, 1, 1)
    overlay.itemLevel:SetWordWrap(false)
    if unit ~= "target" then
        table.insert(trackedILvlFonts, overlay.itemLevel)
    end


    local enchantColor
    local useClassColor = unit == "target" and settings.inspectEnchantClassColor or settings.enchantClassColor
    local customEnchantColor = unit == "target" and settings.inspectEnchantTextColor or settings.enchantTextColor
    if useClassColor then
        local _, class = UnitClass(unit or "player")
        local classColor = RAID_CLASS_COLORS[class]
        if classColor then
            enchantColor = {classColor.r, classColor.g, classColor.b}
        else
            enchantColor = customEnchantColor or C.enchanted
        end
    else
        enchantColor = customEnchantColor or C.enchanted
    end
    overlay.enchant = overlay:CreateFontString(nil, "OVERLAY")
    overlay.enchant:SetFont(slotFont, slotTextSize, FONT_FLAGS)
    overlay.enchant:SetTextColor(enchantColor[1], enchantColor[2], enchantColor[3], 1)
    overlay.enchant:SetWordWrap(false)
    overlay.enchant:SetWidth(TEXT_WIDTH)
    if unit ~= "target" then
        table.insert(trackedEnchantFonts, overlay.enchant)
    end


    if slotInfo.side == "left" then

        overlay.itemName:SetPoint("TOPLEFT", overlay, "TOPRIGHT", 4, 2)
        overlay.itemName:SetJustifyH("LEFT")
        overlay.itemLevel:SetPoint("TOPLEFT", overlay.itemName, "BOTTOMLEFT", 0, -1)
        overlay.itemLevel:SetJustifyH("LEFT")
        overlay.enchant:SetPoint("TOPLEFT", overlay.itemLevel, "BOTTOMLEFT", 0, -1)
        overlay.enchant:SetJustifyH("LEFT")
    elseif slotInfo.side == "right" then

        overlay.itemName:SetPoint("TOPRIGHT", overlay, "TOPLEFT", -4, 2)
        overlay.itemName:SetJustifyH("RIGHT")
        overlay.itemLevel:SetPoint("TOPRIGHT", overlay.itemName, "BOTTOMRIGHT", 0, -1)
        overlay.itemLevel:SetJustifyH("RIGHT")
        overlay.enchant:SetPoint("TOPRIGHT", overlay.itemLevel, "BOTTOMRIGHT", 0, -1)
        overlay.enchant:SetJustifyH("RIGHT")
    elseif slotInfo.id == INVSLOT_MAINHAND then

        overlay.itemName:SetPoint("TOPRIGHT", overlay, "TOPLEFT", -4, 2)
        overlay.itemName:SetJustifyH("RIGHT")
        overlay.itemLevel:SetPoint("TOPRIGHT", overlay.itemName, "BOTTOMRIGHT", 0, -1)
        overlay.itemLevel:SetJustifyH("RIGHT")
        overlay.enchant:SetPoint("TOPRIGHT", overlay.itemLevel, "BOTTOMRIGHT", 0, -1)
        overlay.enchant:SetJustifyH("RIGHT")
    else

        overlay.itemName:SetPoint("TOPLEFT", overlay, "TOPRIGHT", 4, 2)
        overlay.itemName:SetJustifyH("LEFT")
        overlay.itemLevel:SetPoint("TOPLEFT", overlay.itemName, "BOTTOMLEFT", 0, -1)
        overlay.itemLevel:SetJustifyH("LEFT")
        overlay.enchant:SetPoint("TOPLEFT", overlay.itemLevel, "BOTTOMLEFT", 0, -1)
        overlay.enchant:SetJustifyH("LEFT")
    end


    overlay.gems = {}
    for i = 1, 4 do
        local gem = overlay:CreateTexture(nil, "OVERLAY")
        gem:SetSize(GEM_SIZE, GEM_SIZE)
        gem:SetTexCoord(0.08, 0.92, 0.08, 0.92)


        if slotInfo.side == "left" then

            local yOffset = (i - 1) * (GEM_SIZE + GEM_SPACING)
            gem:SetPoint("TOPRIGHT", overlay, "TOPLEFT", -2, -yOffset)
        elseif slotInfo.side == "right" then

            local yOffset = (i - 1) * (GEM_SIZE + GEM_SPACING)
            gem:SetPoint("TOPLEFT", overlay, "TOPRIGHT", 2, -yOffset)
        elseif slotInfo.id == INVSLOT_MAINHAND then

            local yOffset = (i - 1) * (GEM_SIZE + GEM_SPACING)
            gem:SetPoint("TOPLEFT", overlay, "TOPRIGHT", 2, -yOffset)
        else

            local yOffset = (i - 1) * (GEM_SIZE + GEM_SPACING)
            gem:SetPoint("TOPRIGHT", overlay, "TOPLEFT", -2, -yOffset)
        end
        gem:Hide()

        overlay.gems[i] = gem
    end


    overlay.currentScale = scale


    overlay.durabilityBar = CreateFrame("StatusBar", nil, overlay)
    overlay.durabilityBar:SetSize(3, slotFrame:GetHeight() - 4)
    overlay.durabilityBar:SetPoint("LEFT", overlay, "LEFT", 2, 0)
    overlay.durabilityBar:SetOrientation("VERTICAL")
    overlay.durabilityBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    overlay.durabilityBar:SetMinMaxValues(0, 100)
    overlay.durabilityBar:SetStatusBarColor(0.2, 0.8, 0.2, 1)
    overlay.durabilityBar:Hide()


    local duraBg = overlay.durabilityBar:CreateTexture(nil, "BACKGROUND")
    duraBg:SetAllPoints()
    duraBg:SetColorTexture(0, 0, 0, 0.5)

    overlay.slotInfo = slotInfo
    return overlay
end


local function UpdateSlotOverlay(overlay, unit)
    if not overlay or not overlay.slotInfo then return end

    local settings = GetSettings()
    if not settings.enabled then
        overlay:Hide()
        return
    end


    local isInspect = unit ~= "player"
    local showItemName, showItemLevel, showEnchants, showGems
    if isInspect then
        showItemName = settings.showInspectItemName ~= false
        showItemLevel = settings.showInspectItemLevel ~= false
        showEnchants = settings.showInspectEnchants ~= false
        showGems = settings.showInspectGems ~= false
    else
        showItemName = settings.showItemName ~= false
        showItemLevel = settings.showItemLevel ~= false
        showEnchants = settings.showEnchants ~= false
        showGems = settings.showGems ~= false
    end

    local slotId = overlay.slotInfo.id
    local itemLink = GetInventoryItemLink(unit, slotId)

    if not itemLink then
        overlay:Hide()
        return
    end

    overlay:Show()


    local itemName = GetItemInfo(itemLink)
    local quality = GetSlotItemQuality(unit, slotId)
    local r, g, b = GetItemQualityColorRGB(quality)


    if overlay.itemName then
        if showItemName and itemName then
            overlay.itemName:SetText(itemName)
            overlay.itemName:SetTextColor(r, g, b, 1)
            overlay.itemName:Show()
        else
            overlay.itemName:Hide()
        end
    end


    if showItemLevel then
        local itemLevel = GetSlotItemLevel(unit, slotId)

        if itemLevel then

            local track, current, max = GetUpgradeTrack(unit, slotId)
            local ilvlText
            if track and current and max then


                local trackColor = unit == "target" and settings.inspectUpgradeTrackColor or settings.upgradeTrackColor
                trackColor = trackColor or {0.98, 0.60, 0.35, 1}
                local trackHex = string.format("%02x%02x%02x",
                    math.floor(trackColor[1] * 255),
                    math.floor(trackColor[2] * 255),
                    math.floor(trackColor[3] * 255))


                local slotSide = overlay.slotInfo and overlay.slotInfo.side
                local slotId = overlay.slotInfo and overlay.slotInfo.id
                if slotSide == "right" or slotId == INVSLOT_MAINHAND then

                    ilvlText = string.format("|cff%s(%s %s/%s)|r %d", trackHex, track, current, max, itemLevel)
                else

                    ilvlText = string.format("%d |cff%s(%s %s/%s)|r", itemLevel, trackHex, track, current, max)
                end
            else
                ilvlText = tostring(itemLevel)
            end
            overlay.itemLevel:SetText(ilvlText)
            overlay.itemLevel:SetTextColor(1, 1, 1, 1)
            overlay.itemLevel:Show()
        else
            overlay.itemLevel:Hide()
        end
    else
        overlay.itemLevel:Hide()
    end


    if showEnchants then
        local enchantText, isEnchantable = GetEnchantText(unit, slotId)


        local enchantColor
        local useClassColor = unit == "target" and settings.inspectEnchantClassColor or settings.enchantClassColor
        local customEnchantColor = unit == "target" and settings.inspectEnchantTextColor or settings.enchantTextColor
        local noEnchantColor = unit == "target" and settings.inspectNoEnchantTextColor or settings.noEnchantTextColor
        noEnchantColor = noEnchantColor or {0.5, 0.5, 0.5}
        if useClassColor then
            local _, class = UnitClass(unit)
            local classColor = RAID_CLASS_COLORS[class]
            if classColor then
                enchantColor = {classColor.r, classColor.g, classColor.b}
            else
                enchantColor = customEnchantColor or C.enchanted
            end
        else
            enchantColor = customEnchantColor or C.enchanted
        end

        if isEnchantable then
            if enchantText then
                overlay.enchant:SetText(enchantText)
                overlay.enchant:SetTextColor(enchantColor[1], enchantColor[2], enchantColor[3], 1)
            else

                overlay.enchant:SetText("No Enchant")
                overlay.enchant:SetTextColor(noEnchantColor[1], noEnchantColor[2], noEnchantColor[3], 1)
            end
            overlay.enchant:Show()
        else
            overlay.enchant:Hide()
        end
    else
        overlay.enchant:Hide()
    end


    if showGems then
        local gems, totalSockets = GetGemInfo(unit, slotId)
        for i, gemTex in ipairs(overlay.gems) do
            if gems[i] then
                if gems[i].filled then

                    local gemIcon = gems[i].icon

                    if gemIcon and gemIcon ~= 0 and type(gemIcon) == "number" then
                        gemTex:SetTexture(gemIcon)
                        gemTex:SetDesaturated(false)
                        gemTex:SetVertexColor(1, 1, 1, 1)
                        gemTex:Show()
                    else

                        local gemType = gems[i].type or "Prismatic"
                        local color = GEM_COLORS[gemType] or GEM_COLORS.Prismatic
                        gemTex:SetColorTexture(color[1], color[2], color[3], color[4])
                        gemTex:SetDesaturated(false)
                        gemTex:Show()
                    end
                else

                    gemTex:SetTexture("Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic")
                    gemTex:SetDesaturated(true)
                    gemTex:SetVertexColor(0.6, 0.6, 0.6, 0.9)
                    gemTex:Show()
                end
            else
                gemTex:Hide()
            end
        end
    else
        for _, gemTex in ipairs(overlay.gems) do
            gemTex:Hide()
        end
    end


    if settings.showDurability and unit == "player" then
        local current, max, pct = GetSlotDurability(slotId)
        if pct then
            overlay.durabilityBar:SetValue(pct)

            if pct > 50 then
                overlay.durabilityBar:SetStatusBarColor(0.2, 0.8, 0.2, 1)
            elseif pct > 25 then
                overlay.durabilityBar:SetStatusBarColor(0.8, 0.8, 0.2, 1)
            else
                overlay.durabilityBar:SetStatusBarColor(0.8, 0.2, 0.2, 1)
            end
            overlay.durabilityBar:Show()
        else
            overlay.durabilityBar:Hide()
        end
    else
        overlay.durabilityBar:Hide()
    end
end


local layoutApplied = false
local repositionPending = false
local customBg = nil
local equipMgrPopup = nil
local titlesPopup = nil
local allEquipmentSlots = {}
local UpdateEquipmentSlotBorder = nil


local function IsSkinningHandlingBackground()
    local skinningAPI = _G.PREY_CharacterFrameSkinning
    return skinningAPI and skinningAPI.IsEnabled and skinningAPI.IsEnabled()
end


local function HideBlizzardDecorations()
    local settings = GetSettings()


    if CharacterFrame.TopTileStreaks then CharacterFrame.TopTileStreaks:Hide() end


    if CharacterFrameTitleText then CharacterFrameTitleText:Hide() end
    if CharacterFrame.TitleText then CharacterFrame.TitleText:Hide() end


    if PaperDollSidebarTabs then
        if PaperDollSidebarTabs.DecorLeft then PaperDollSidebarTabs.DecorLeft:Hide() end
        if PaperDollSidebarTabs.DecorRight then PaperDollSidebarTabs.DecorRight:Hide() end

        PaperDollSidebarTabs:ClearAllPoints()
        PaperDollSidebarTabs:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", 50, -30)
    end


    if CharacterFrame.CloseButton then
        CharacterFrame.CloseButton:ClearAllPoints()
        CharacterFrame.CloseButton:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", 52, -5)
    end


    if CharacterFrameTab1 then
        CharacterFrameTab1:ClearAllPoints()
        CharacterFrameTab1:SetPoint("TOPLEFT", CharacterFrame, "BOTTOMLEFT", 11, -48)
    end


    if CharacterFrameInset then
        if CharacterFrameInset.NineSlice then CharacterFrameInset.NineSlice:Hide() end
        if CharacterFrameInset.Bg then CharacterFrameInset.Bg:SetAlpha(0) end
    end


    if CharacterFrameInsetRight then
        if CharacterFrameInsetRight.Bg then CharacterFrameInsetRight.Bg:SetAlpha(0) end
        if CharacterFrameInsetRight.NineSlice then CharacterFrameInsetRight.NineSlice:Hide() end
    end


    if CharacterStatsPane then
        CharacterStatsPane:Hide()
        if CharacterStatsPane.ClassBackground then
            CharacterStatsPane.ClassBackground:Hide()
        end
    end


    local innerBorders = {
        "PaperDollInnerBorderBottom", "PaperDollInnerBorderBottom2",
        "PaperDollInnerBorderBottomLeft", "PaperDollInnerBorderBottomRight",
        "PaperDollInnerBorderLeft", "PaperDollInnerBorderRight",
        "PaperDollInnerBorderTop", "PaperDollInnerBorderTopLeft",
        "PaperDollInnerBorderTopRight",
    }
    for _, borderName in ipairs(innerBorders) do
        local border = rawget(_G, borderName)
        if border then border:Hide() end
    end


    local slotFrames = {
        "CharacterBackSlotFrame", "CharacterChestSlotFrame", "CharacterFeetSlotFrame",
        "CharacterFinger0SlotFrame", "CharacterFinger1SlotFrame", "CharacterHandsSlotFrame",
        "CharacterHeadSlotFrame", "CharacterLegsSlotFrame", "CharacterMainHandSlotFrame",
        "CharacterNeckSlotFrame", "CharacterSecondaryHandSlotFrame", "CharacterShirtSlotFrame",
        "CharacterShoulderSlotFrame", "CharacterTabardSlotFrame", "CharacterTrinket0SlotFrame",
        "CharacterTrinket1SlotFrame", "CharacterWaistSlotFrame", "CharacterWristSlotFrame",
    }
    for _, frameName in ipairs(slotFrames) do
        local frame = rawget(_G, frameName)
        if frame then
            frame:Hide()

            if not frame._preyHideHooked then
                hooksecurefunc(frame, "Show", function(self) self:Hide() end)
                frame._preyHideHooked = true
            end
        end
    end


    local function BlockIconBorder(iconBorder)
        if not iconBorder or iconBorder._preyBlocked then return end
        iconBorder._preyBlocked = true
        iconBorder:SetAlpha(0)
        if iconBorder.SetTexture then iconBorder:SetTexture(nil) end
        if iconBorder.SetAtlas then
            hooksecurefunc(iconBorder, "SetAtlas", function(self)
                if self.SetTexture then self:SetTexture(nil) end
                if self.SetAlpha then self:SetAlpha(0) end
            end)
        end
    end


    local function SkinEquipmentSlot(slot)
        if not slot then return end


        local normalTex = slot:GetNormalTexture()
        if normalTex then normalTex:SetAlpha(0) end


        if slot.BottomRightSlotTexture then
            slot.BottomRightSlotTexture:Hide()
        end


        for i = 1, select("#", slot:GetRegions()) do
            local region = select(i, slot:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                local isIcon = region == slot.icon or region == slot.Icon
                if not isIcon then
                    region:SetAlpha(0)
                end
            end
        end


        if slot.IconBorder then
            BlockIconBorder(slot.IconBorder)
        end


        local iconTex = slot.icon or slot.Icon
        if iconTex and iconTex.SetTexCoord then
            iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end


        if not slot._preyBorderFrame then
            slot._preyBorderFrame = CreateFrame("Frame", nil, slot, "BackdropTemplate")
            slot._preyBorderFrame:SetFrameLevel(slot:GetFrameLevel() + 10)
            slot._preyBorderFrame:SetAllPoints(slot)
            slot._preyBorderFrame:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
        end
    end


    local function UpdateSlotBorder(slot)
        if not slot or not slot._preyBorderFrame then return end

        local slotID = slot:GetID()


        local quality = GetInventoryItemQuality("player", slotID)

        if quality and quality >= 1 then
            local r, g, b = C_Item.GetItemQualityColor(quality)
            slot._preyBorderFrame:SetBackdropBorderColor(r, g, b, 1)
            slot._preyBorderFrame:Show()
        else
            slot._preyBorderFrame:Hide()
        end
    end


    local equipmentSlotNames = {
        "CharacterHeadSlot", "CharacterNeckSlot", "CharacterShoulderSlot",
        "CharacterBackSlot", "CharacterChestSlot", "CharacterShirtSlot",
        "CharacterTabardSlot", "CharacterWristSlot", "CharacterHandsSlot",
        "CharacterWaistSlot", "CharacterLegsSlot", "CharacterFeetSlot",
        "CharacterFinger0Slot", "CharacterFinger1Slot",
        "CharacterTrinket0Slot", "CharacterTrinket1Slot",
        "CharacterMainHandSlot", "CharacterSecondaryHandSlot",
    }


    local allSlots = {}
    for _, slotName in ipairs(equipmentSlotNames) do
        local slot = rawget(_G, slotName)
        if slot then
            SkinEquipmentSlot(slot)
            UpdateSlotBorder(slot)
            table.insert(allSlots, slot)
        end
    end


    allEquipmentSlots = allSlots
    UpdateEquipmentSlotBorder = UpdateSlotBorder


    local firstSlot = allSlots[1]
    if firstSlot and not firstSlot._preyEquipHooked then
        firstSlot:HookScript("OnEvent", function(self, event)
            if event == "PLAYER_EQUIPMENT_CHANGED" then
                C_Timer.After(0.1, function()
                    for _, slot in ipairs(allSlots) do
                        UpdateSlotBorder(slot)
                    end
                end)
            end
        end)
        firstSlot._preyEquipHooked = true
    end


    local modelBgs = {
        "CharacterModelFrameBackgroundTopLeft", "CharacterModelFrameBackgroundBotLeft",
        "CharacterModelFrameBackgroundTopRight", "CharacterModelFrameBackgroundBotRight",
        "CharacterModelFrameBackgroundOverlay",
    }
    for _, bgName in ipairs(modelBgs) do
        local bg = rawget(_G, bgName)
        if bg then bg:Hide() end
    end


    if CharacterModelScene and CharacterModelScene.ControlFrame then
        CharacterModelScene.ControlFrame:Hide()
    end
end


local function CreateCustomBackground()
    local settings = GetSettings()


    local skinningAPI = _G.PREY_CharacterFrameSkinning
    if skinningAPI and skinningAPI.IsEnabled and skinningAPI.IsEnabled() then

        if skinningAPI.SetExtended then
            skinningAPI.SetExtended(true)
        end
    else


        local PREY = _G.PreyUI
        local sr, sg, sb, sa = C.border[1], C.border[2], C.border[3], 1
        local bgr, bgg, bgb, bga = C.bg[1], C.bg[2], C.bg[3], C.bg[4] or 0.95

        if PREY and PREY.GetSkinColor then
            sr, sg, sb, sa = PREY:GetSkinColor()
        end
        if PREY and PREY.GetSkinBgColor then
            bgr, bgg, bgb, bga = PREY:GetSkinBgColor()
        end

        if not customBg then
            customBg = CreateFrame("Frame", "PREY_CharacterFrameBg_CharPane", CharacterFrame, "BackdropTemplate")
            customBg:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            customBg:SetFrameStrata("BACKGROUND")
            customBg:SetFrameLevel(0)
            customBg:EnableMouse(false)
        end


        local PANEL_HEIGHT_EXTENSION = 50
        local PANEL_WIDTH_EXTENSION = 55
        customBg:ClearAllPoints()
        customBg:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 0, 0)
        customBg:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", PANEL_WIDTH_EXTENSION, -PANEL_HEIGHT_EXTENSION)


        customBg:SetBackdropColor(bgr, bgg, bgb, bga)
        customBg:SetBackdropBorderColor(sr, sg, sb, sa)
        customBg:Show()
    end


    local BASE_SCALE = 1.30
    local scaleMultiplier = settings.panelScale or 1.0
    CharacterFrame:SetScale(BASE_SCALE * scaleMultiplier)
end


local LEFT_COLUMN_SLOTS = {
    "CharacterHeadSlot",
    "CharacterNeckSlot",
    "CharacterShoulderSlot",
    "CharacterBackSlot",
    "CharacterChestSlot",
    "CharacterWristSlot",
}

local RIGHT_COLUMN_SLOTS = {
    "CharacterHandsSlot",
    "CharacterWaistSlot",
    "CharacterLegsSlot",
    "CharacterFeetSlot",
    "CharacterFinger0Slot",
    "CharacterFinger1Slot",
    "CharacterTrinket0Slot",
    "CharacterTrinket1Slot",
}


local function RepositionSlots()
    local settings = GetSettings()
    if not CharacterFrameBg then return end

    local vpad = 14
    local SLOT_SCALE = 0.90


    local allSlots = {
        CharacterHeadSlot, CharacterNeckSlot, CharacterShoulderSlot,
        CharacterBackSlot, CharacterChestSlot, CharacterShirtSlot,
        CharacterTabardSlot, CharacterWristSlot,
        CharacterHandsSlot, CharacterWaistSlot, CharacterLegsSlot,
        CharacterFeetSlot, CharacterFinger0Slot, CharacterFinger1Slot,
        CharacterTrinket0Slot, CharacterTrinket1Slot,
        CharacterMainHandSlot, CharacterSecondaryHandSlot,
    }


    for _, slot in ipairs(allSlots) do
        if slot then slot:SetScale(SLOT_SCALE) end
    end


    CharacterHeadSlot:ClearAllPoints()
    CharacterHeadSlot:SetPoint("TOPLEFT", CharacterFrameBg, "TOPLEFT", 20, -30)

    CharacterNeckSlot:ClearAllPoints()
    CharacterNeckSlot:SetPoint("TOPLEFT", CharacterHeadSlot, "BOTTOMLEFT", 0, -vpad)

    CharacterShoulderSlot:ClearAllPoints()
    CharacterShoulderSlot:SetPoint("TOPLEFT", CharacterNeckSlot, "BOTTOMLEFT", 0, -vpad)

    CharacterBackSlot:ClearAllPoints()
    CharacterBackSlot:SetPoint("TOPLEFT", CharacterShoulderSlot, "BOTTOMLEFT", 0, -vpad)

    CharacterChestSlot:ClearAllPoints()
    CharacterChestSlot:SetPoint("TOPLEFT", CharacterBackSlot, "BOTTOMLEFT", 0, -vpad)

    CharacterShirtSlot:ClearAllPoints()
    CharacterShirtSlot:SetPoint("TOPLEFT", CharacterChestSlot, "BOTTOMLEFT", 0, -vpad)

    CharacterTabardSlot:ClearAllPoints()
    CharacterTabardSlot:SetPoint("TOPLEFT", CharacterShirtSlot, "BOTTOMLEFT", 0, -vpad)


    CharacterHandsSlot:ClearAllPoints()
    CharacterHandsSlot:SetPoint("TOPLEFT", CharacterFrameBg, "TOPLEFT", 413, -30)

    CharacterWaistSlot:ClearAllPoints()
    CharacterWaistSlot:SetPoint("TOPLEFT", CharacterHandsSlot, "BOTTOMLEFT", 0, -vpad)

    CharacterLegsSlot:ClearAllPoints()
    CharacterLegsSlot:SetPoint("TOPLEFT", CharacterWaistSlot, "BOTTOMLEFT", 0, -vpad)

    CharacterFeetSlot:ClearAllPoints()
    CharacterFeetSlot:SetPoint("TOPLEFT", CharacterLegsSlot, "BOTTOMLEFT", 0, -vpad)

    CharacterFinger0Slot:ClearAllPoints()
    CharacterFinger0Slot:SetPoint("TOPLEFT", CharacterFeetSlot, "BOTTOMLEFT", 0, -vpad)

    CharacterFinger1Slot:ClearAllPoints()
    CharacterFinger1Slot:SetPoint("TOPLEFT", CharacterFinger0Slot, "BOTTOMLEFT", 0, -vpad)

    CharacterTrinket0Slot:ClearAllPoints()
    CharacterTrinket0Slot:SetPoint("TOPLEFT", CharacterFinger1Slot, "BOTTOMLEFT", 0, -vpad)

    CharacterTrinket1Slot:ClearAllPoints()
    CharacterTrinket1Slot:SetPoint("TOPLEFT", CharacterTrinket0Slot, "BOTTOMLEFT", 0, -vpad)


    CharacterWristSlot:ClearAllPoints()
    CharacterWristSlot:SetPoint("TOP", CharacterTrinket1Slot, "TOP", 0, 0)
    CharacterWristSlot:SetPoint("LEFT", CharacterHeadSlot, "LEFT", 0, 0)


    CharacterMainHandSlot:ClearAllPoints()
    CharacterMainHandSlot:SetPoint("BOTTOM", CharacterFrameBg, "BOTTOM", -102, -29)

    CharacterSecondaryHandSlot:ClearAllPoints()
    CharacterSecondaryHandSlot:SetPoint("LEFT", CharacterMainHandSlot, "RIGHT", 30, 0)
end


local function PositionModelScene()
    local settings = GetSettings()
    if not CharacterModelScene then return end


    CharacterModelScene:ClearAllPoints()
    CharacterModelScene:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 86, -85)
    CharacterModelScene:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", -204, 65)
    CharacterModelScene:SetFrameLevel(2)
    CharacterModelScene:Show()

end


local function PositionStatsPanelForLayout()
    local settings = GetSettings()


    local justCreated = false
    if not statsPanel then
        statsPanel = CreateStatsPanel(CharacterFrame, "player")
        justCreated = true
    end

    if statsPanel then
        statsPanel:ClearAllPoints()
        statsPanel:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", 42, -70)
        statsPanel:SetPoint("BOTTOMRIGHT", CharacterFrame, "BOTTOMRIGHT", 42, -35)
        statsPanel:SetWidth(160)
        statsPanel:SetFrameLevel(10)
        statsPanel:Show()


        if justCreated then
            C_Timer.After(0.05, ScheduleUpdate)
        end
    end
end


local function SetupTitleArea()
    local font = GetGlobalFont()


    if CharacterLevelText then
        CharacterLevelText:Hide()
    end


    if not CharacterFrame._preyILvlDisplay then
        local displayFrame = CreateFrame("Frame", nil, CharacterFrame)
        displayFrame:SetSize(400, 30)
        displayFrame:SetPoint("TOPLEFT", CharacterFrame, "TOPLEFT", 19, -10)
        displayFrame:SetFrameLevel(CharacterFrame:GetFrameLevel() + 10)


        local nameText = displayFrame:CreateFontString(nil, "OVERLAY")
        nameText:SetFont(font, 12, "")
        nameText:SetPoint("TOPLEFT", displayFrame, "TOPLEFT", 0, 0)
        nameText:SetJustifyH("LEFT")


        local specText = CharacterFrame:CreateFontString(nil, "OVERLAY")
        specText:SetFont(font, 12, "")
        specText:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -132, -10)
        specText:SetJustifyH("RIGHT")

        displayFrame.text = nameText
        displayFrame.specText = specText
        CharacterFrame._preyILvlDisplay = displayFrame
    end


    if not CharacterFrame._preyCenterILvl then
        local centerFrame = CreateFrame("Frame", nil, CharacterFrame)
        centerFrame:SetSize(200, 20)
        centerFrame:SetPoint("TOP", CharacterFrame, "TOP", -62, -10)
        centerFrame:SetFrameLevel(CharacterFrame:GetFrameLevel() + 10)

        local centerText = centerFrame:CreateFontString(nil, "OVERLAY")
        centerText:SetFont(font, 21, "OUTLINE")
        centerText:SetPoint("CENTER")
        centerText:SetJustifyH("CENTER")

        centerFrame.text = centerText
        CharacterFrame._preyCenterILvl = centerFrame
    end
end


local function ApplyCharacterPaneLayout()
    local settings = GetSettings()
    if not settings.enabled then return end


    if layoutApplied then return end

    HideBlizzardDecorations()
    CreateCustomBackground()
    SetupTitleArea()

    C_Timer.After(0.1, function()
        RepositionSlots()
        PositionModelScene()
        PositionStatsPanelForLayout()
    end)

    layoutApplied = true
end


local currentOverlayScale = nil

local function InitializeCharacterOverlays(forceRecreate)
    local settings = GetSettings()
    local newScale = 1.0


    if characterPaneInitialized and currentOverlayScale == newScale and not forceRecreate then
        return
    end


    if characterPaneInitialized and currentOverlayScale ~= newScale then
        for slotId, overlay in pairs(slotOverlays) do
            if overlay then
                overlay:Hide()
                overlay:SetParent(nil)
            end
        end
        slotOverlays = {}
        characterPaneInitialized = false
    end

    if characterPaneInitialized then return end

    for _, slotInfo in ipairs(EQUIPMENT_SLOTS) do
        local slotFrame = rawget(_G, "Character" .. slotInfo.name .. "Slot")
        if slotFrame then
            slotOverlays[slotInfo.id] = CreateSlotOverlay(slotFrame, slotInfo)
        end
    end

    currentOverlayScale = newScale
    characterPaneInitialized = true
end


local function UpdateAllSlotOverlays(unit, overlayTable)
    overlayTable = overlayTable or slotOverlays
    unit = unit or "player"

    for _, overlay in pairs(overlayTable) do
        UpdateSlotOverlay(overlay, unit)
    end
end


CreateStatsPanel = function(parent, unit)
    local settings = GetSettings()


    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetSize(200, 400)


    panel:SetBackdrop(nil)


    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(130, 1)
    scrollFrame:SetScrollChild(scrollChild)

    panel.scrollChild = scrollChild
    panel.unit = unit

    return panel
end


local trackedFontStrings = {}
local trackedUnderlines = {}


local function TrackFontString(fontString, category)
    table.insert(trackedFontStrings, { fs = fontString, cat = category })
end


local function RefreshCharacterPanelFonts()
    local settings = GetSettings()
    local font = GetGlobalFont()


    local statsSize = settings.statsTextSize or (settings.textSize and math.floor(11 * settings.textSize)) or 11
    local statsColor = settings.statsTextColor or settings.textColor or {0.953, 0.957, 0.965}
    local headerSize = settings.headerTextSize or (settings.headerSize and math.floor(12 * settings.headerSize)) or 12


    local headerColor
    if settings.headerClassColor then
        local _, class = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[class]
        if classColor then
            headerColor = {classColor.r, classColor.g, classColor.b}
        else
            headerColor = settings.headerColor or {0.820, 0.180, 0.220}
        end
    else
        headerColor = settings.headerColor or {0.820, 0.180, 0.220}
    end


    local validStrings = {}
    for _, entry in ipairs(trackedFontStrings) do
        if entry.fs and entry.fs.SetFont then
            table.insert(validStrings, entry)
        end
    end
    trackedFontStrings = validStrings


    for _, entry in ipairs(trackedFontStrings) do
        local fs = entry.fs
        local cat = entry.cat

        if cat == "sectionHeader" then
            fs:SetFont(font, math.max(headerSize - 2, 10), "THINOUTLINE")
            fs:SetTextColor(headerColor[1], headerColor[2], headerColor[3], 1)
            fs:SetShadowOffset(0, 0)
            fs:SetText(fs:GetText() or "")
        elseif cat == "statLabel" or cat == "barLabel" then
            local size = (cat == "barLabel") and math.max(statsSize - 2, 7) or math.max(statsSize - 1, 8)
            fs:SetFont(font, size, "")
            fs:SetTextColor(statsColor[1], statsColor[2], statsColor[3], 1)
            fs:SetShadowOffset(0, 0)
        elseif cat == "statValue" or cat == "barValue" then
            local size = (cat == "barValue") and math.max(statsSize - 2, 7) or math.max(statsSize - 1, 8)
            fs:SetFont(font, size, "")
            fs:SetShadowOffset(0, 0)
        end
    end


    if trackedUnderlines then
        for _, line in ipairs(trackedUnderlines) do
            if line and line.SetColorTexture then
                line:SetColorTexture(headerColor[1], headerColor[2], headerColor[3], 0.3)
            end
        end
    end


    local enchantSize = settings.enchantTextSize or 10
    local noEnchantColor = settings.noEnchantTextColor or {0.5, 0.5, 0.5}


    local enchantColor
    if settings.enchantClassColor then
        local _, class = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[class]
        if classColor then
            enchantColor = {classColor.r, classColor.g, classColor.b}
        else
            enchantColor = settings.enchantTextColor or {0.820, 0.180, 0.220}
        end
    else
        enchantColor = settings.enchantTextColor or {0.820, 0.180, 0.220}
    end


    local enchantFont = font
    if settings.enchantFont then
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        if LSM then
            local fontPath = LSM:Fetch("font", settings.enchantFont)
            if fontPath then
                enchantFont = fontPath
            end
        end
    end


    local slotTextSize = settings.slotTextSize or 10
    local FONT_FLAGS = "OUTLINE"


    local validItemNames = {}
    for _, fs in ipairs(trackedItemNameFonts) do
        if fs and fs.SetFont then
            fs:SetFont(font, slotTextSize, FONT_FLAGS)
            table.insert(validItemNames, fs)
        end
    end
    trackedItemNameFonts = validItemNames


    local validILvl = {}
    for _, fs in ipairs(trackedILvlFonts) do
        if fs and fs.SetFont then
            fs:SetFont(font, slotTextSize, FONT_FLAGS)
            table.insert(validILvl, fs)
        end
    end
    trackedILvlFonts = validILvl


    local validEnchants = {}
    for _, fs in ipairs(trackedEnchantFonts) do
        if fs and fs.SetFont then
            fs:SetFont(font, slotTextSize, FONT_FLAGS)

            local text = fs:GetText()
            if text and text == "No Enchant" then
                fs:SetTextColor(noEnchantColor[1], noEnchantColor[2], noEnchantColor[3], 1)
            elseif text then
                fs:SetTextColor(enchantColor[1], enchantColor[2], enchantColor[3], 1)
            end
            table.insert(validEnchants, fs)
        end
    end
    trackedEnchantFonts = validEnchants
end


_G.PreyUI_RefreshCharacterPanelFonts = RefreshCharacterPanelFonts


local function ShowStatTooltip(self)
    local settings = GetSettings()
    if not settings.showTooltips then
        return
    end
    if not self.tooltip then
        return
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.tooltip)
    if self.tooltip2 then
        GameTooltip:AddLine(self.tooltip2, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    end
    if self.tooltip3 then
        GameTooltip:AddLine(self.tooltip3, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    end
    GameTooltip:Show()
end


local function CreateStatRow(parent, yOffset)
    local settings = GetSettings()
    local font = GetGlobalFont()
    local statsSize = settings.statsTextSize or 11
    local statsColor = settings.statsTextColor or {0.953, 0.957, 0.965}
    local rowHeight = 14
    local fontSize = math.max(statsSize - 1, 8)

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(parent:GetWidth() - 10, rowHeight)
    row:SetPoint("TOPLEFT", 5, yOffset)


    if settings.showTooltips then
        row:EnableMouse(true)
        row:SetScript("OnEnter", ShowStatTooltip)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    else
        row:EnableMouse(false)
        row:SetScript("OnEnter", nil)
        row:SetScript("OnLeave", nil)
    end

    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetFont(font, fontSize, "")
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label:SetTextColor(statsColor[1], statsColor[2], statsColor[3], 1)
    row.label:SetShadowOffset(0, 0)
    TrackFontString(row.label, "statLabel")

    row.value = row:CreateFontString(nil, "OVERLAY")
    row.value:SetFont(font, fontSize, "")
    row.value:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.value:SetTextColor(1, 1, 1, 1)
    row.value:SetShadowOffset(0, 0)
    TrackFontString(row.value, "statValue")

    return row
end


local function CreateSectionHeader(parent, text, yOffset)
    local settings = GetSettings()
    local font = GetGlobalFont()
    local headerSize = settings.headerTextSize or 12
    local fontSize = math.max(headerSize - 2, 10)
    local headerHeight = 14

    local headerColor
    if settings.headerClassColor then
        local _, class = UnitClass("player")
        local classColor = RAID_CLASS_COLORS[class]
        if classColor then
            headerColor = {classColor.r, classColor.g, classColor.b}
        else
            headerColor = settings.headerColor or {0.820, 0.180, 0.220}
        end
    else
        headerColor = settings.headerColor or {0.820, 0.180, 0.220}
    end

    local header = parent:CreateFontString(nil, "OVERLAY")
    header:SetFont(font, fontSize, "THINOUTLINE")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 5, yOffset)
    header:SetTextColor(headerColor[1], headerColor[2], headerColor[3], 1)
    header:SetText(text)
    header:SetShadowOffset(0, 0)
    TrackFontString(header, "sectionHeader")


    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    line:SetPoint("RIGHT", parent, "RIGHT", -5, 0)
    line:SetColorTexture(headerColor[1], headerColor[2], headerColor[3], 0.3)
    table.insert(trackedUnderlines, line)

    local spacingAfterHeader = 4
    return header, headerHeight + spacingAfterHeader
end


local function CreateStatBar(parent, yOffset, color)
    local settings = GetSettings()
    local font = GetGlobalFont()
    local statsSize = settings.statsTextSize or 11
    local statsColor = settings.statsTextColor or {0.953, 0.957, 0.965}
    local barTextSize = math.max(statsSize - 2, 7)
    local rowHeight = 16
    local barHeight = 3
    local labelOffset = 2
    local barOffset = 1

    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(parent:GetWidth() - 10, rowHeight)
    row:SetPoint("TOPLEFT", 5, yOffset)


    if settings.showTooltips then
        row:EnableMouse(true)
        row:SetScript("OnEnter", ShowStatTooltip)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    else
        row:EnableMouse(false)
        row:SetScript("OnEnter", nil)
        row:SetScript("OnLeave", nil)
    end

    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetFont(font, barTextSize, "")
    row.label:SetPoint("LEFT", row, "LEFT", 0, labelOffset)
    row.label:SetTextColor(statsColor[1], statsColor[2], statsColor[3], 1)
    row.label:SetShadowOffset(0, 0)
    TrackFontString(row.label, "barLabel")

    row.value = row:CreateFontString(nil, "OVERLAY")
    row.value:SetFont(font, barTextSize, "")
    row.value:SetPoint("RIGHT", row, "RIGHT", 0, labelOffset)
    row.value:SetTextColor(1, 1, 1, 1)
    row.value:SetShadowOffset(0, 0)
    TrackFontString(row.value, "barValue")


    row.bar = CreateFrame("StatusBar", nil, row)
    row.bar:SetSize(row:GetWidth(), barHeight)
    row.bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, barOffset)
    row.bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, barOffset)
    row.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    row.bar:SetMinMaxValues(0, 100)
    row.bar:SetStatusBarColor(color[1], color[2], color[3], color[4])


    local barBg = row.bar:CreateTexture(nil, "BACKGROUND")
    barBg:SetAllPoints()
    barBg:SetColorTexture(0, 0, 0, 0.4)

    return row
end


local function UpdateStatsPanel(panel, unit)
    if not panel or not panel.scrollChild then return end

    if updatingStatsPanel then return end
    updatingStatsPanel = true

    local success, err = pcall(function()
        local settings = GetSettings()
        panel:Show()

        local scrollChild = panel.scrollChild
        unit = unit or panel.unit or "player"


        for _, entry in ipairs(trackedFontStrings) do
            if entry.fs and entry.fs.Hide then
                entry.fs:Hide()
                entry.fs:SetText("")
            end
        end


        for _, line in ipairs(trackedUnderlines) do
            if line and line.Hide then
                line:Hide()
            end
        end


        wipe(trackedFontStrings)
        wipe(trackedUnderlines)


        local children = {scrollChild:GetChildren()}
        for i = #children, 1, -1 do
            local frame = children[i]
            if frame then
                frame:Hide()
                frame:SetParent(nil)
                if frame.SetScript then
                    frame:SetScript("OnShow", nil)
                    frame:SetScript("OnHide", nil)
                    frame:SetScript("OnUpdate", nil)
                end
            end
        end


        local regions = {scrollChild:GetRegions()}
        for i = #regions, 1, -1 do
            local region = regions[i]
            if region then
                region:Hide()
                if region.SetText then
                    region:SetText("")
                end
            end
        end

        local y = -5
        local ROW_HEIGHT = 14
        local SECTION_GAP = 8
        local BAR_HEIGHT = 16


    local function SafeGetStat(func, ...)
        local ok, result = pcall(func, ...)
        return ok and result or 0
    end


    local healthMax = SafeGetStat(UnitHealthMax, unit)
    local row = CreateStatRow(scrollChild, y)
    row.label:SetText("Health")
    row.value:SetText(FormatNumber(healthMax))
    row.value:SetTextColor(C.health[1], C.health[2], C.health[3], 1)

    local healthText = BreakUpLargeNumbers(healthMax)
    row.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, HEALTH).." "..healthText..FONT_COLOR_CODE_CLOSE
    if unit == "player" then
        row.tooltip2 = STAT_HEALTH_TOOLTIP
    else
        row.tooltip2 = STAT_HEALTH_PET_TOOLTIP
    end
    y = y - ROW_HEIGHT

    local powerType = UnitPowerType(unit)
    local powerMax = SafeGetStat(UnitPowerMax, unit, powerType)
    local powerName = powerType == 0 and "Mana" or (powerType == 1 and "Rage" or (powerType == 2 and "Focus" or (powerType == 3 and "Energy" or "Power")))
    local powerToken = powerType == 0 and "MANA" or (powerType == 1 and "RAGE" or (powerType == 2 and "FOCUS" or (powerType == 3 and "ENERGY" or "POWER")))

    row = CreateStatRow(scrollChild, y)
    row.label:SetText(powerName)
    row.value:SetText(FormatNumber(powerMax))
    row.value:SetTextColor(C.mana[1], C.mana[2], C.mana[3], 1)

    local powerText = BreakUpLargeNumbers(powerMax)
    if powerType == 0 then
        row.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, MANA).." "..powerText..FONT_COLOR_CODE_CLOSE
        row.tooltip2 = rawget(_G, "STAT_MANA_TOOLTIP")
    else
        local powerLabel = rawget(_G, powerToken) or powerName
        row.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, powerLabel).." "..powerText..FONT_COLOR_CODE_CLOSE
        row.tooltip2 = rawget(_G, "STAT_"..powerToken.."_TOOLTIP")
    end
    y = y - ROW_HEIGHT

    y = y - 5


    local _, headerHeight = CreateSectionHeader(scrollChild, "Attributes", y)
    y = y - headerHeight


    local stats = {
        { label = "Strength", statIndex = 1, func = function() return UnitStat(unit, 1) end },
        { label = "Agility", statIndex = 2, func = function() return UnitStat(unit, 2) end },
        { label = "Stamina", statIndex = 3, func = function() return UnitStat(unit, 3) end },
        { label = "Intellect", statIndex = 4, func = function() return UnitStat(unit, 4) end },
    }

    for _, stat in ipairs(stats) do
        local statValue, effectiveStat, posBuff, negBuff = UnitStat(unit, stat.statIndex)
        if effectiveStat and effectiveStat > 0 then
            row = CreateStatRow(scrollChild, y)
            row.label:SetText(stat.label)
            row.value:SetText(FormatNumber(effectiveStat))


            local statName = rawget(_G, "SPELL_STAT"..stat.statIndex.."_NAME")
            local tooltipText = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName).." "
            local effectiveStatDisplay = BreakUpLargeNumbers(effectiveStat)

            if (posBuff == 0) and (negBuff == 0) then
                row.tooltip = tooltipText..effectiveStatDisplay..FONT_COLOR_CODE_CLOSE
            else
                tooltipText = tooltipText..effectiveStatDisplay
                if (posBuff > 0 or negBuff < 0) then
                    tooltipText = tooltipText.." ("..BreakUpLargeNumbers(statValue - posBuff - negBuff)..FONT_COLOR_CODE_CLOSE
                end
                if (posBuff > 0) then
                    tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..BreakUpLargeNumbers(posBuff)..FONT_COLOR_CODE_CLOSE
                end
                if (negBuff < 0) then
                    tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..BreakUpLargeNumbers(negBuff)..FONT_COLOR_CODE_CLOSE
                end
                if (posBuff > 0 or negBuff < 0) then
                    tooltipText = tooltipText..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE
                end
                row.tooltip = tooltipText
            end

            row.tooltip2 = rawget(_G, "DEFAULT_STAT"..stat.statIndex.."_TOOLTIP")


            if unit == "player" then
                local success, result = pcall(function()
                    local _, unitClass = UnitClass("player")
                    unitClass = strupper(unitClass)
                    local primaryStat, spec, role
                    spec = C_SpecializationInfo.GetSpecialization()
                    if spec then
                        role = GetSpecializationRole(spec)
                        primaryStat = select(6, C_SpecializationInfo.GetSpecializationInfo(spec, false, false, nil, UnitSex("player")))
                    end

                    if stat.statIndex == 1 then
                        if GetAttackPowerForStat then
                            local attackPower = GetAttackPowerForStat(1, effectiveStat)
                            if HasAPEffectsSpellPower and HasAPEffectsSpellPower() then
                                row.tooltip2 = STAT_TOOLTIP_BONUS_AP_SP
                            end
                            if (not primaryStat or primaryStat == 1) then
                                row.tooltip2 = format(row.tooltip2 or STAT_TOOLTIP_BONUS_AP, BreakUpLargeNumbers(attackPower))
                                if role == "TANK" and GetParryChanceFromAttribute then
                                    local increasedParryChance = GetParryChanceFromAttribute()
                                    if increasedParryChance and increasedParryChance > 0 then
                                        row.tooltip2 = row.tooltip2.."|n|n"..format(CR_PARRY_BASE_STAT_TOOLTIP, increasedParryChance)
                                    end
                                end
                            else
                                row.tooltip2 = STAT_NO_BENEFIT_TOOLTIP
                            end
                        end
                    elseif stat.statIndex == 2 then
                        if (not primaryStat or primaryStat == 2) then
                            if HasAPEffectsSpellPower and HasAPEffectsSpellPower() then
                                row.tooltip2 = STAT_TOOLTIP_BONUS_AP_SP
                            else
                                row.tooltip2 = STAT_TOOLTIP_BONUS_AP
                            end
                            if role == "TANK" and GetDodgeChanceFromAttribute then
                                local increasedDodgeChance = GetDodgeChanceFromAttribute()
                                if increasedDodgeChance and increasedDodgeChance > 0 then
                                    row.tooltip2 = row.tooltip2.."|n|n"..format(CR_DODGE_BASE_STAT_TOOLTIP, increasedDodgeChance)
                                end
                            end
                        else
                            row.tooltip2 = STAT_NO_BENEFIT_TOOLTIP
                        end
                    elseif stat.statIndex == 3 then
                        if UnitHPPerStamina and GetUnitMaxHealthModifier then
                            row.tooltip2 = format(row.tooltip2, BreakUpLargeNumbers(((effectiveStat*UnitHPPerStamina("player")))*GetUnitMaxHealthModifier("player")))
                        end
                    elseif stat.statIndex == 4 then
                        if HasAPEffectsSpellPower and HasAPEffectsSpellPower() then
                            row.tooltip2 = STAT_NO_BENEFIT_TOOLTIP
                        elseif HasSPEffectsAttackPower and HasSPEffectsAttackPower() then
                            row.tooltip2 = STAT_TOOLTIP_BONUS_AP_SP
                        elseif (not primaryStat or primaryStat == 4) then
                            row.tooltip2 = format(row.tooltip2, max(0, effectiveStat))
                        else
                            row.tooltip2 = STAT_NO_BENEFIT_TOOLTIP
                        end
                    end
                end)

            end

            y = y - ROW_HEIGHT
        end
    end

    y = y - 5


    _, headerHeight = CreateSectionHeader(scrollChild, "Secondary", y)
    y = y - headerHeight

    local secondaryStats = {
        { label = "Crit", statKey = "CRIT", percentFunc = GetCritChance, ratingFunc = function() return GetCombatRating(CR_CRIT_MELEE) end, color = C.crit },
        { label = "Haste", statKey = "HASTE", percentFunc = GetHaste, ratingFunc = function() return GetCombatRating(CR_HASTE_MELEE) end, color = C.haste },
        { label = "Mastery", statKey = "MASTERY", percentFunc = GetMasteryEffect, ratingFunc = function() return GetCombatRating(CR_MASTERY) end, color = C.mastery },
        { label = "Versatility", statKey = "VERSATILITY", percentFunc = function() return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) end, ratingFunc = function() return GetCombatRating(CR_VERSATILITY_DAMAGE_DONE) end, color = C.versatility },
    }

    local statFormat = settings.secondaryStatFormat or "percent"

    for _, stat in ipairs(secondaryStats) do
        local percentValue = SafeGetStat(stat.percentFunc)
        local ratingValue = SafeGetStat(stat.ratingFunc)
        row = CreateStatBar(scrollChild, y, stat.color)
        row.label:SetText(stat.label)


        if statFormat == "percent" then
            row.value:SetText(FormatPercent(percentValue))
        elseif statFormat == "rating" then
            row.value:SetText(FormatNumber(ratingValue))
        else
            row.value:SetText(string.format("%s (%s)", FormatNumber(ratingValue), FormatPercent(percentValue, 1)))
        end

        row.bar:SetValue(math.min(percentValue or 0, 100))


        if stat.statKey == "CRIT" then
            local statName = STAT_CRITICAL_STRIKE
            row.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName)..FONT_COLOR_CODE_CLOSE
            if GetSecondaryBonus and GetCombatRating then
                local extraCritChance = GetSecondaryBonus(CR_CRIT_MELEE, percentValue)
                local extraCritRating = GetCombatRating(CR_CRIT_MELEE)
                if GetCritChanceProvidesParryEffect and GetCritChanceProvidesParryEffect() and GetCombatRatingBonusForCombatRatingValue then
                    row.tooltip2 = format(CR_CRIT_PARRY_RATING_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance, GetCombatRatingBonusForCombatRatingValue(CR_PARRY, extraCritRating))
                else
                    row.tooltip2 = format(CR_CRIT_TOOLTIP, BreakUpLargeNumbers(extraCritRating), extraCritChance)
                end
            end
        elseif stat.statKey == "HASTE" then
            local statName = STAT_HASTE
            row.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName)..FONT_COLOR_CODE_CLOSE
            local _, class = UnitClass(unit)
            row.tooltip2 = rawget(_G, "STAT_HASTE_"..class.."_TOOLTIP")
            if not row.tooltip2 then
                row.tooltip2 = STAT_HASTE_TOOLTIP
            end
            if GetCombatRating and GetSecondaryBonus then
                local hasteRating = GetCombatRating(CR_HASTE_MELEE)
                local hasteBonus = GetSecondaryBonus(CR_HASTE_MELEE, percentValue)
                row.tooltip2 = row.tooltip2 .. format(STAT_HASTE_BASE_TOOLTIP, BreakUpLargeNumbers(hasteRating), hasteBonus)
            end
        elseif stat.statKey == "MASTERY" then

            local statName = STAT_MASTERY
            row.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName)..FONT_COLOR_CODE_CLOSE
            if GetMasteryEffect and GetSecondaryBonus then
                local mastery, bonusCoeff = GetMasteryEffect()
                local masteryBonus = GetSecondaryBonus(CR_MASTERY, mastery, bonusCoeff)
                row.tooltip2 = format(STAT_MASTERY_TOOLTIP, BreakUpLargeNumbers(ratingValue), masteryBonus)
            end
        elseif stat.statKey == "VERSATILITY" then
            local statName = STAT_VERSATILITY
            row.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, statName)..FONT_COLOR_CODE_CLOSE
            if GetCombatRatingBonus and GetVersatilityBonus then
                local versatilityDamageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + (GetVersatilityBonus and GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE) or 0)
                local versatilityDamageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) + (GetVersatilityBonus and GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN) or 0)
                row.tooltip2 = format(CR_VERSATILITY_TOOLTIP, versatilityDamageBonus, versatilityDamageTakenReduction, BreakUpLargeNumbers(ratingValue), versatilityDamageBonus, versatilityDamageTakenReduction)
            end
        end

        y = y - BAR_HEIGHT
    end

    y = y - 5


    _, headerHeight = CreateSectionHeader(scrollChild, "Attack", y)
    y = y - headerHeight

    local attackStats = {
        { label = "Attack Power", func = function() return UnitAttackPower(unit) end, format = FormatNumber, statKey = "ATTACK_POWER" },
        { label = "Spell Power", func = function() return GetSpellBonusDamage(2) end, format = FormatNumber, statKey = "SPELLPOWER" },
        { label = "Attack Speed", func = function() return UnitAttackSpeed(unit) end, format = function(v) return string.format("%.2fs", v or 0) end, statKey = "ATTACK_SPEED" },
    }

    for _, stat in ipairs(attackStats) do
        local value = SafeGetStat(stat.func)
        if value and value > 0 then
            row = CreateStatRow(scrollChild, y)
            row.label:SetText(stat.label)
            row.value:SetText(stat.format(value))


            if stat.statKey == "ATTACK_POWER" then
                if PaperDollFormatStat then
                    local base, posBuff, negBuff = UnitAttackPower(unit)
                    local damageBonus = BreakUpLargeNumbers(max((base+posBuff+negBuff), 0)/ATTACK_POWER_MAGIC_NUMBER)
                    local tag, tooltip = MELEE_ATTACK_POWER, MELEE_ATTACK_POWER_TOOLTIP
                    local valueText, tooltipText = PaperDollFormatStat(tag, base, posBuff, negBuff)
                    row.tooltip = tooltipText
                    row.tooltip2 = format(tooltip, damageBonus)
                end
            elseif stat.statKey == "SPELLPOWER" then
                row.tooltip = STAT_SPELLPOWER
                row.tooltip2 = STAT_SPELLPOWER_TOOLTIP
            elseif stat.statKey == "ATTACK_SPEED" then
                local speed = UnitAttackSpeed(unit)
                local displaySpeed = format("%.2F", speed)
                row.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED).." "..displaySpeed..FONT_COLOR_CODE_CLOSE
                local meleeHaste = GetMeleeHaste()
                row.tooltip2 = format(STAT_ATTACK_SPEED_BASE_TOOLTIP, BreakUpLargeNumbers(meleeHaste))
            end

            y = y - ROW_HEIGHT
        end
    end

    y = y - 5


    _, headerHeight = CreateSectionHeader(scrollChild, "Defense", y)
    y = y - headerHeight

    local baselineArmor, effectiveArmor = UnitArmor(unit)
    local dodge = SafeGetStat(GetDodgeChance)
    local parry = SafeGetStat(GetParryChance)
    local block = SafeGetStat(GetBlockChance)

    local defenseStats = {
        { label = "Armor", value = FormatNumber(effectiveArmor or 0), statKey = "ARMOR" },
        { label = "Dodge", value = FormatPercent(dodge), statKey = "DODGE" },
        { label = "Parry", value = FormatPercent(parry), statKey = "PARRY" },
        { label = "Block", value = FormatPercent(block), statKey = "BLOCK" },
    }

    for _, stat in ipairs(defenseStats) do
        row = CreateStatRow(scrollChild, y)
        row.label:SetText(stat.label)
        row.value:SetText(stat.value)


        if stat.statKey == "ARMOR" then
            row.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ARMOR).." "..BreakUpLargeNumbers(effectiveArmor)..FONT_COLOR_CODE_CLOSE
            if PaperDollFrame_GetArmorReduction then
                local armorReduction = PaperDollFrame_GetArmorReduction(effectiveArmor, UnitEffectiveLevel(unit))
                row.tooltip2 = format(STAT_ARMOR_TOOLTIP, armorReduction)
                if PaperDollFrame_GetArmorReductionAgainstTarget then
                    local armorReductionAgainstTarget = PaperDollFrame_GetArmorReductionAgainstTarget(effectiveArmor)
                    if armorReductionAgainstTarget then
                        row.tooltip3 = format(STAT_ARMOR_TARGET_TOOLTIP, armorReductionAgainstTarget)
                    end
                end
            end
        elseif stat.statKey == "DODGE" then
            local chance = GetDodgeChance()
            row.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE).." "..string.format("%.2F", chance).."%"..FONT_COLOR_CODE_CLOSE
            row.tooltip2 = format(CR_DODGE_TOOLTIP, GetCombatRating(CR_DODGE), GetCombatRatingBonus(CR_DODGE))
        elseif stat.statKey == "PARRY" then
            local chance = GetParryChance()
            row.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE).." "..string.format("%.2F", chance).."%"..FONT_COLOR_CODE_CLOSE
            row.tooltip2 = format(CR_PARRY_TOOLTIP, GetCombatRating(CR_PARRY), GetCombatRatingBonus(CR_PARRY))
        elseif stat.statKey == "BLOCK" then
            local chance = GetBlockChance()
            row.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE).." "..string.format("%.2F", chance).."%"..FONT_COLOR_CODE_CLOSE
            if GetShieldBlock and PaperDollFrame_GetArmorReduction then
                local shieldBlockArmor = GetShieldBlock()
                local blockArmorReduction = PaperDollFrame_GetArmorReduction(shieldBlockArmor, UnitEffectiveLevel(unit))
                row.tooltip2 = CR_BLOCK_TOOLTIP:format(blockArmorReduction)
                if PaperDollFrame_GetArmorReductionAgainstTarget then
                    local blockArmorReductionAgainstTarget = PaperDollFrame_GetArmorReductionAgainstTarget(shieldBlockArmor)
                    if blockArmorReductionAgainstTarget then
                        row.tooltip3 = format(STAT_BLOCK_TARGET_TOOLTIP, blockArmorReductionAgainstTarget)
                    end
                end
            end
        end

        y = y - ROW_HEIGHT
    end

    y = y - 5


    _, headerHeight = CreateSectionHeader(scrollChild, "General", y)
    y = y - headerHeight

    local leech = SafeGetStat(GetLifesteal)
    local speed = SafeGetStat(GetSpeed)

    local generalStats = {
        { label = "Leech", value = FormatPercent(leech), statKey = "LIFESTEAL" },
        { label = "Speed", value = FormatPercent(speed), statKey = "SPEED" },
    }

    for _, stat in ipairs(generalStats) do
        row = CreateStatRow(scrollChild, y)
        row.label:SetText(stat.label)
        row.value:SetText(stat.value)


        if stat.statKey == "LIFESTEAL" then
            local lifesteal = GetLifesteal()
            row.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_LIFESTEAL) .. " " .. format("%.2F%%", lifesteal) .. FONT_COLOR_CODE_CLOSE
            row.tooltip2 = format(CR_LIFESTEAL_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_LIFESTEAL)), GetCombatRatingBonus(CR_LIFESTEAL))
        elseif stat.statKey == "SPEED" then
            local speedValue = GetSpeed()
            row.tooltip = HIGHLIGHT_FONT_COLOR_CODE .. format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_SPEED) .. " " .. format("%.2F%%", speedValue) .. FONT_COLOR_CODE_CLOSE
            row.tooltip2 = format(CR_SPEED_TOOLTIP, BreakUpLargeNumbers(GetCombatRating(CR_SPEED)), GetCombatRatingBonus(CR_SPEED))
        end

        y = y - ROW_HEIGHT
    end


    local contentHeight = math.abs(y) + 20
    scrollChild:SetHeight(contentHeight)


    panel:SetScale(0.92)


    local scrollFrame = panel.scrollFrame
    if scrollFrame then
        local scrollBar = scrollFrame.ScrollBar
        if scrollBar then
            C_Timer.After(0.01, function()
                local maxScroll = scrollFrame:GetVerticalScrollRange()

                if maxScroll <= 1 then
                    scrollBar:Hide()
                    scrollFrame:SetVerticalScroll(0)
                    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -5, 5)
                else
                    scrollBar:Show()
                    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -25, 5)
                end
            end)
        end
    end
    end)

    updatingStatsPanel = false

    if not success then
        print("PreyUI: Error updating stats panel:", err)
    end
end


local function GetILvlColor(ilvl)

    if ilvl >= 285 then
        return 1, 0.5, 0
    elseif ilvl >= 275 then
        return 0.64, 0.21, 0.93
    elseif ilvl >= 265 then
        return 0, 0.44, 0.87
    elseif ilvl >= 255 then
        return 0, 1, 0
    elseif ilvl >= 245 then
        return 1, 1, 1
    else
        return 0.62, 0.62, 0.62
    end
end


local function UpdateILvlDisplay()
    if not CharacterFrame or not CharacterFrame._preyILvlDisplay then return end

    local settings = GetSettings()
    if not settings.enabled then return end

    local displayFrame = CharacterFrame._preyILvlDisplay
    if not displayFrame.text then return end


    local name = UnitName("player") or "Unknown"
    local level = UnitLevel("player") or 0
    local overall, equipped = GetAverageItemLevel()
    local ilvlStr = string.format("%.0f", equipped)


    local specName = ""
    local className = ""
    local specIndex = GetSpecialization()
    if specIndex then
        local _, specNameLocal = GetSpecializationInfo(specIndex)
        specName = specNameLocal or ""
    end
    local _, classNameLocal = UnitClass("player")
    if classNameLocal then

        local classInfo = C_CreatureInfo.GetClassInfo(select(3, UnitClass("player")))
        className = classInfo and classInfo.className or classNameLocal
    end


    local classColor = RAID_CLASS_COLORS[classNameLocal]
    local r, g, b = 1, 1, 1
    if classColor then
        r, g, b = classColor.r, classColor.g, classColor.b
    end


    displayFrame.text:SetText(name)
    displayFrame.text:SetTextColor(r, g, b, 1)


    if displayFrame.specText then
        local specLine = string.format("%d %s %s", level, specName, AbbreviateClassName(className))
        displayFrame.specText:SetText(specLine)
        displayFrame.specText:SetTextColor(r, g, b, 1)
    end


    local centerFrame = CharacterFrame._preyCenterILvl
    if centerFrame and centerFrame.text then

        local eR, eG, eB = GetILvlColor(equipped)
        local oR, oG, oB = GetILvlColor(overall)


        local equippedHex = string.format("%02x%02x%02x", math.floor(eR*255), math.floor(eG*255), math.floor(eB*255))
        local overallHex = string.format("%02x%02x%02x", math.floor(oR*255), math.floor(oG*255), math.floor(oB*255))
        local equippedStr = string.format("%.1f", equipped)
        local overallStr = string.format("%.1f", overall)

        local centerStr = string.format("|cff%s%s  |  |cff%s%s|r", equippedHex, equippedStr, overallHex, overallStr)
        centerFrame.text:SetText(centerStr)
    end
end


ScheduleUpdate = function()
    if pendingUpdate then return end
    pendingUpdate = true

    C_Timer.After(0.05, function()
        pendingUpdate = false


        if CharacterFrame and CharacterFrame:IsShown() and PaperDollFrame and PaperDollFrame:IsShown() then
            UpdateAllSlotOverlays("player", slotOverlays)
            UpdateILvlDisplay()
            if statsPanel then

                local equipMgrOpen = PaperDollFrame.EquipmentManagerPane
                                     and PaperDollFrame.EquipmentManagerPane:IsShown()
                if not equipMgrOpen then
                    UpdateStatsPanel(statsPanel, "player")
                end
            end
        end


        if ns.PREY.InspectPane and ns.PREY.InspectPane.UpdateInspectFrame then
            ns.PREY.InspectPane.UpdateInspectFrame()
        end
    end)
end


local function CreateEquipMgrPopup()
    if equipMgrPopup then return equipMgrPopup end


    local PANEL_WIDTH_EXTENSION = 55
    equipMgrPopup = CreateFrame("Frame", "PreyUI_EquipMgrPopup", UIParent, "BackdropTemplate")
    equipMgrPopup:SetSize(205, 400)
    equipMgrPopup:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", PANEL_WIDTH_EXTENSION + 10, 0)
    equipMgrPopup:SetFrameStrata("DIALOG")
    equipMgrPopup:EnableMouse(true)
    equipMgrPopup:SetMovable(true)
    equipMgrPopup:RegisterForDrag("LeftButton")
    equipMgrPopup:SetScript("OnDragStart", equipMgrPopup.StartMoving)
    equipMgrPopup:SetScript("OnDragStop", equipMgrPopup.StopMovingOrSizing)
    equipMgrPopup:Hide()


    equipMgrPopup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })


    local title = equipMgrPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Equipment Manager")
    equipMgrPopup.title = title


    _G.PreyUI_EquipMgrPopup = equipMgrPopup

    return equipMgrPopup
end


local function CreateTitlesPopup()
    if titlesPopup then return titlesPopup end


    local PANEL_WIDTH_EXTENSION = 55
    titlesPopup = CreateFrame("Frame", "PreyUI_TitlesPopup", UIParent, "BackdropTemplate")
    titlesPopup:SetSize(205, 400)
    titlesPopup:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", PANEL_WIDTH_EXTENSION + 10, 0)
    titlesPopup:SetFrameStrata("DIALOG")
    titlesPopup:EnableMouse(true)
    titlesPopup:SetMovable(true)
    titlesPopup:RegisterForDrag("LeftButton")
    titlesPopup:SetScript("OnDragStart", titlesPopup.StartMoving)
    titlesPopup:SetScript("OnDragStop", titlesPopup.StopMovingOrSizing)
    titlesPopup:Hide()


    titlesPopup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })


    local title = titlesPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Titles")
    titlesPopup.title = title


    _G.PreyUI_TitlesPopup = titlesPopup

    return titlesPopup
end


local characterFrameHooked = false

local function HookCharacterFrame()
    if not CharacterFrame then return end
    if characterFrameHooked then return end
    characterFrameHooked = true


    local gearBtn, settingsPanel


    CharacterFrame:HookScript("OnShow", function()

        C_Timer.After(0.01, function()
            if PaperDollFrame and PaperDollFrame:IsShown() then

                ApplyCharacterPaneLayout()
                InitializeCharacterOverlays()
                ScheduleUpdate()
            else


                if not IsSkinningHandlingBackground() and customBg then
                    customBg:Hide()
                end
                if statsPanel then statsPanel:Hide() end
                for _, overlay in pairs(slotOverlays) do
                    if overlay then overlay:Hide() end
                end
                if equipMgrPopup then equipMgrPopup:Hide() end
                if CharacterFrame._preyILvlDisplay then CharacterFrame._preyILvlDisplay:Hide() end
                if CharacterFrame._preyCenterILvl then CharacterFrame._preyCenterILvl:Hide() end
                CharacterFrame:SetScale(1.0)
            end
        end)
    end)

    CharacterFrame:HookScript("OnHide", function()

        layoutApplied = false


        GameTooltip:Hide()


        if equipMgrPopup then
            equipMgrPopup:Hide()
        end

        local equipPane = PaperDollFrame and PaperDollFrame.EquipmentManagerPane
        if equipPane and equipPane._preyOriginalParent then
            equipPane:SetParent(equipPane._preyOriginalParent)
        end


        if titlesPopup then
            titlesPopup:Hide()
        end

        local titlesPane = PaperDollFrame and PaperDollFrame.TitleManagerPane
        if titlesPane and titlesPane._preyOriginalParent then
            titlesPane:SetParent(titlesPane._preyOriginalParent)
        end
    end)


    if CharacterStatsPane then
        hooksecurefunc(CharacterStatsPane, "Show", function()
            local settings = GetSettings()
            if settings.enabled then
                CharacterStatsPane:Hide()
            end
        end)
    end


    if PaperDollSidebarTab3 and not PaperDollSidebarTab3._preyHooked then
        PaperDollSidebarTab3:HookScript("OnClick", function()
            local settings = GetSettings()
            if not settings.enabled then return end


            if titlesPopup then
                titlesPopup:Hide()
            end
            local titlesPane = PaperDollFrame and PaperDollFrame.TitleManagerPane
            if titlesPane and titlesPane._preyOriginalParent then
                titlesPane:SetParent(titlesPane._preyOriginalParent)
            end


            local popup = CreateEquipMgrPopup()


            local pane = PaperDollFrame and PaperDollFrame.EquipmentManagerPane
            if pane then

                if not pane._preyOriginalParent then
                    pane._preyOriginalParent = pane:GetParent()
                end


                pane:SetParent(popup)
                pane:ClearAllPoints()
                pane:SetPoint("TOPLEFT", popup, "TOPLEFT", 5, -30)
                pane:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -5, 5)
                pane:Show()


                if pane.ScrollBox then
                    pane.ScrollBox:ClearAllPoints()
                    pane.ScrollBox:SetPoint("TOPLEFT", pane, "TOPLEFT", 5, -35)
                    pane.ScrollBox:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -25, 5)
                end

                popup:Show()


                local skinningAPI = _G.PREY_CharacterFrameSkinning
                if skinningAPI and skinningAPI.SkinEquipmentManager then
                    skinningAPI.SkinEquipmentManager()
                end
            end


        end)
        PaperDollSidebarTab3._preyHooked = true
    end


    if PaperDollSidebarTab2 and not PaperDollSidebarTab2._preyHooked then
        PaperDollSidebarTab2:HookScript("OnClick", function()
            local settings = GetSettings()
            if not settings.enabled then return end


            if equipMgrPopup then
                equipMgrPopup:Hide()
            end
            local equipPane = PaperDollFrame and PaperDollFrame.EquipmentManagerPane
            if equipPane and equipPane._preyOriginalParent then
                equipPane:SetParent(equipPane._preyOriginalParent)
            end


            local popup = CreateTitlesPopup()


            local pane = PaperDollFrame and PaperDollFrame.TitleManagerPane
            if pane then

                if not pane._preyOriginalParent then
                    pane._preyOriginalParent = pane:GetParent()
                end


                pane:SetParent(popup)
                pane:ClearAllPoints()
                pane:SetPoint("TOPLEFT", popup, "TOPLEFT", 5, -30)
                pane:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -5, 5)
                pane:Show()


                if pane.ScrollBox then
                    pane.ScrollBox:ClearAllPoints()
                    pane.ScrollBox:SetPoint("TOPLEFT", pane, "TOPLEFT", 5, -5)
                    pane.ScrollBox:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -25, 5)
                end

                popup:Show()


                local skinningAPI = _G.PREY_CharacterFrameSkinning
                if skinningAPI and skinningAPI.SkinTitleManager then
                    skinningAPI.SkinTitleManager()
                end
            end
        end)
        PaperDollSidebarTab2._preyHooked = true
    end


    if GearManagerPopupFrame then
        GearManagerPopupFrame:SetFrameStrata("DIALOG")
        if GearManagerPopupFrame.IconSelector then
            GearManagerPopupFrame.IconSelector:SetFrameStrata("FULLSCREEN")
        end


        hooksecurefunc(GearManagerPopupFrame, "Show", function(self)
            if equipMgrPopup and equipMgrPopup:IsShown() then
                self:ClearAllPoints()
                self:SetPoint("TOPLEFT", equipMgrPopup, "TOPRIGHT", 5, 0)
            end
        end)
    end


    if PaperDollSidebarTab1 then
        PaperDollSidebarTab1:HookScript("OnClick", function()
            local settings = GetSettings()


            if equipMgrPopup then
                equipMgrPopup:Hide()
            end

            local equipPane = PaperDollFrame and PaperDollFrame.EquipmentManagerPane
            if equipPane and equipPane._preyOriginalParent then
                equipPane:SetParent(equipPane._preyOriginalParent)
            end


            if titlesPopup then
                titlesPopup:Hide()
            end

            local titlesPane = PaperDollFrame and PaperDollFrame.TitleManagerPane
            if titlesPane and titlesPane._preyOriginalParent then
                titlesPane:SetParent(titlesPane._preyOriginalParent)
            end


            if settings.enabled then
                if statsPanel then statsPanel:Show() end
            end
        end)
    end


    local function AdjustForNonCharacterTab()

        if CharacterFrameTab1 then
            CharacterFrameTab1:ClearAllPoints()
            CharacterFrameTab1:SetPoint("TOPLEFT", CharacterFrame, "BOTTOMLEFT", 11, 2)
        end

        if CharacterFrame.CloseButton then
            CharacterFrame.CloseButton:ClearAllPoints()
            CharacterFrame.CloseButton:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", -3, -5)
        end
    end

    local function RestoreCharacterTabPositions()

        if CharacterFrameTab1 then
            CharacterFrameTab1:ClearAllPoints()
            CharacterFrameTab1:SetPoint("TOPLEFT", CharacterFrame, "BOTTOMLEFT", 11, -48)
        end

        if CharacterFrame.CloseButton then
            CharacterFrame.CloseButton:ClearAllPoints()
            CharacterFrame.CloseButton:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", 52, -5)
        end
    end


    local function HideCustomElements()
        if statsPanel then statsPanel:Hide() end
        for _, overlay in pairs(slotOverlays) do
            if overlay then overlay:Hide() end
        end

        if equipMgrPopup then equipMgrPopup:Hide() end

        if CharacterFrame._preyILvlDisplay then CharacterFrame._preyILvlDisplay:Hide() end
        if CharacterFrame._preyCenterILvl then CharacterFrame._preyCenterILvl:Hide() end
        if CharacterFrame._preyGearBtn then CharacterFrame._preyGearBtn:Hide() end
        if CharacterFrame._preySettingsPanel then CharacterFrame._preySettingsPanel:Hide() end


        if IsSkinningHandlingBackground() then

            local skinningAPI = _G.PREY_CharacterFrameSkinning
            if skinningAPI and skinningAPI.SetExtended then
                skinningAPI.SetExtended(false)
            end

        else

            if customBg then customBg:Hide() end
            if CharacterFramePortrait then CharacterFramePortrait:Show() end
            if CharacterFrame.Background then CharacterFrame.Background:Show() end
            if CharacterFrame.NineSlice then CharacterFrame.NineSlice:Show() end
            if CharacterFrameBg then CharacterFrameBg:Show() end
        end


        CharacterFrame:SetScale(1.0)

        AdjustForNonCharacterTab()
    end


    if ReputationFrame then
        ReputationFrame:HookScript("OnShow", HideCustomElements)
    end


    if TokenFrame then
        TokenFrame:HookScript("OnShow", HideCustomElements)
    end


    if PaperDollFrame then
        PaperDollFrame:HookScript("OnShow", function()
            local settings = GetSettings()
            if settings.enabled then

                RestoreCharacterTabPositions()

                local BASE_SCALE = 1.30
                local scaleMultiplier = settings.panelScale or 1.0
                CharacterFrame:SetScale(BASE_SCALE * scaleMultiplier)


                if not layoutApplied then
                    ApplyCharacterPaneLayout()
                    InitializeCharacterOverlays()
                end


                if IsSkinningHandlingBackground() then

                    local skinningAPI = _G.PREY_CharacterFrameSkinning
                    if skinningAPI and skinningAPI.SetExtended then
                        skinningAPI.SetExtended(true)
                    end

                else

                    if customBg then customBg:Show() end
                    if CharacterFramePortrait then CharacterFramePortrait:Hide() end
                    if CharacterFrame.Background then CharacterFrame.Background:Hide() end
                    if CharacterFrame.NineSlice then CharacterFrame.NineSlice:Hide() end
                    if CharacterFrameBg then CharacterFrameBg:Hide() end
                end


                if CharacterStatsPane then CharacterStatsPane:Hide() end
                if statsPanel then statsPanel:Show() end
                for _, overlay in pairs(slotOverlays) do
                    if overlay then overlay:Show() end
                end

                if CharacterFrame._preyILvlDisplay then CharacterFrame._preyILvlDisplay:Show() end
                if CharacterFrame._preyCenterILvl then CharacterFrame._preyCenterILvl:Show() end
                if CharacterFrame._preyGearBtn then CharacterFrame._preyGearBtn:Show() end
                ScheduleUpdate()

                if #allEquipmentSlots > 0 and UpdateEquipmentSlotBorder then
                    C_Timer.After(0.05, function()
                        for _, slot in ipairs(allEquipmentSlots) do
                            UpdateEquipmentSlotBorder(slot)
                        end
                    end)
                end

                C_Timer.After(0.15, function()
                    if statsPanel then
                        statsPanel:Show()
                    end
                end)
            end
        end)
    end


    local settings = GetSettings()
    if not settings.enabled then

        if CharacterFrame._preyGearBtn then
            CharacterFrame._preyGearBtn:Hide()
        end
        if CharacterFrame._preySettingsPanel then
            CharacterFrame._preySettingsPanel:Hide()
        end
        return
    end


    if not CharacterFrame._preyGearBtn then
        gearBtn = CreateFrame("Button", "PREY_CharacterSettingsBtn", CharacterFrame, "BackdropTemplate")
        gearBtn:SetSize(70, 20)
        gearBtn:SetPoint("TOPRIGHT", CharacterFrame, "TOPRIGHT", 20, -5)
        gearBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        gearBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        gearBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        gearBtn:SetFrameStrata("HIGH")
        gearBtn:SetFrameLevel(100)


        local gearIcon = gearBtn:CreateTexture(nil, "ARTWORK")
        gearIcon:SetSize(14, 14)
        gearIcon:SetPoint("LEFT", gearBtn, "LEFT", 5, 0)
        gearIcon:SetTexture("Interface\\Buttons\\UI-OptionsButton")


        local gearLabel = gearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        gearLabel:SetPoint("LEFT", gearIcon, "RIGHT", 4, 0)
        gearLabel:SetText("Settings")
        gearLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)


        gearBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        gearBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        end)

        CharacterFrame._preyGearBtn = gearBtn


        settingsPanel = CreateFrame("Frame", "PreyUI_CharSettingsPanel", CharacterFrame, "BackdropTemplate")
        settingsPanel:SetSize(450, 600)
        settingsPanel:SetPoint("TOPLEFT", CharacterFrame, "TOPRIGHT", 53, 0)
        settingsPanel:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        settingsPanel:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 0.98)
        settingsPanel:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
        settingsPanel:SetFrameStrata("DIALOG")
        settingsPanel:SetFrameLevel(200)
        settingsPanel:EnableMouse(true)
        settingsPanel:Hide()
        CharacterFrame._preySettingsPanel = settingsPanel


        local title = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", settingsPanel, "TOP", 0, -8)
        title:SetText("PREY Character Panel")
        title:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)


        local closeBtn = CreateFrame("Button", nil, settingsPanel, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -3, -3)
        closeBtn:SetScript("OnClick", function() settingsPanel:Hide() end)


        local scrollFrame = CreateFrame("ScrollFrame", nil, settingsPanel, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 5, -28)
        scrollFrame:SetPoint("BOTTOMRIGHT", settingsPanel, "BOTTOMRIGHT", -26, 40)

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetWidth(419)
        scrollChild:SetHeight(1)
        scrollFrame:SetScrollChild(scrollChild)


        local scrollBar = scrollFrame.ScrollBar
        if scrollBar then
            scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 2, -16)
            scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 2, 16)
        end


        local GUI = _G.PreyUI and _G.PreyUI.GUI
        if not GUI then return end
        local settings = GetSettings()
        local charDB = settings


        local PAD = 8
        local FORM_ROW = 28
        local y = -5


        local function RefreshAll()
            if _G.PreyUI_RefreshCharacterPanelFonts then
                _G.PreyUI_RefreshCharacterPanelFonts()
            end
            ScheduleUpdate()
        end


        local widgetRefs = {}


        local appearHeader = GUI:CreateSectionHeader(scrollChild, "Appearance")
        appearHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - appearHeader.gap


        local BASE_SCALE = 1.30
        local scaleSlider = GUI:CreateFormSlider(scrollChild, "Panel Scale", 0.75, 1.5, 0.05, "panelScale", charDB, function()
            local multiplier = charDB.panelScale or 1.0
            CharacterFrame:SetScale(BASE_SCALE * multiplier)
        end, { deferOnDrag = true })
        scaleSlider:SetPoint("TOPLEFT", PAD, y)
        scaleSlider:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW


        local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
        local generalDB = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
        local bgColorPicker = nil
        if generalDB then
            bgColorPicker = GUI:CreateFormColorPicker(scrollChild, "Background Color", "skinBgColor", generalDB, function()

                if customBg and not IsSkinningHandlingBackground() then
                    local col = generalDB.skinBgColor or C.bg
                    customBg:SetBackdropColor(col[1], col[2], col[3], col[4] or 0.95)
                end

                if _G.PreyUI_RefreshCharacterFrameColors then
                    _G.PreyUI_RefreshCharacterFrameColors()
                end
            end)
            bgColorPicker:SetPoint("TOPLEFT", PAD, y)
            bgColorPicker:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
            y = y - FORM_ROW


            settingsPanel:HookScript("OnShow", function()
                if bgColorPicker and bgColorPicker.swatch and generalDB and generalDB.skinBgColor then
                    local col = generalDB.skinBgColor
                    bgColorPicker.swatch:SetBackdropColor(col[1], col[2], col[3], col[4] or 1)
                end
            end)
        end

        y = y - 10


        local overlayHeader = GUI:CreateSectionHeader(scrollChild, "Slot Overlays")
        overlayHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - overlayHeader.gap

        local showItemName = GUI:CreateFormCheckbox(scrollChild, "Show Equipment Name", "showItemName", charDB, RefreshAll)
        showItemName:SetPoint("TOPLEFT", PAD, y)
        showItemName:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local showIlvl = GUI:CreateFormCheckbox(scrollChild, "Show Item Level & Track", "showItemLevel", charDB, RefreshAll)
        showIlvl:SetPoint("TOPLEFT", PAD, y)
        showIlvl:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local showEnchants = GUI:CreateFormCheckbox(scrollChild, "Show Enchant Status", "showEnchants", charDB, RefreshAll)
        showEnchants:SetPoint("TOPLEFT", PAD, y)
        showEnchants:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local showGems = GUI:CreateFormCheckbox(scrollChild, "Show Gem Indicators", "showGems", charDB, RefreshAll)
        showGems:SetPoint("TOPLEFT", PAD, y)
        showGems:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local showDura = GUI:CreateFormCheckbox(scrollChild, "Show Durability Bars", "showDurability", charDB, RefreshAll)
        showDura:SetPoint("TOPLEFT", PAD, y)
        showDura:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        y = y - 10


        local statsPanelHeader = GUI:CreateSectionHeader(scrollChild, "Stats Panel")
        statsPanelHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - statsPanelHeader.gap

        local showTooltips = GUI:CreateFormCheckbox(scrollChild, "Show Stat Tooltips", "showTooltips", charDB, function()
            RefreshAll()

            if statsPanel then
                UpdateStatsPanel(statsPanel, "player")
            end
        end)
        showTooltips:SetPoint("TOPLEFT", PAD, y)
        showTooltips:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        y = y - 10


        local secondaryStatsHeader = GUI:CreateSectionHeader(scrollChild, "Secondary Stats")
        secondaryStatsHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - secondaryStatsHeader.gap

        local formatOptions = {
            { value = "percent", text = "Percentage (19.52%)" },
            { value = "rating", text = "Rating (1,234)" },
            { value = "both", text = "Both (1,234 (19.5%))" },
        }
        local secondaryFormat = GUI:CreateFormDropdown(scrollChild, "Display Format", formatOptions, "secondaryStatFormat", charDB, RefreshAll)
        secondaryFormat:SetPoint("TOPLEFT", PAD, y)
        secondaryFormat:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        y = y - 10


        local textSizeHeader = GUI:CreateSectionHeader(scrollChild, "Text Sizes")
        textSizeHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - textSizeHeader.gap

        local slotTextSize = GUI:CreateFormSlider(scrollChild, "Slot Text Size", 6, 40, 1, "slotTextSize", charDB, RefreshAll)
        slotTextSize:SetPoint("TOPLEFT", PAD, y)
        slotTextSize:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local headerTextSize = GUI:CreateFormSlider(scrollChild, "Header Text Size", 6, 40, 1, "headerTextSize", charDB, RefreshAll)
        headerTextSize:SetPoint("TOPLEFT", PAD, y)
        headerTextSize:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local statsTextSize = GUI:CreateFormSlider(scrollChild, "Stats Text Size", 6, 40, 1, "statsTextSize", charDB, RefreshAll)
        statsTextSize:SetPoint("TOPLEFT", PAD, y)
        statsTextSize:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        y = y - 10


        local textColorHeader = GUI:CreateSectionHeader(scrollChild, "Text Colors")
        textColorHeader:SetPoint("TOPLEFT", PAD, y)
        y = y - textColorHeader.gap

        local statsTextColor = GUI:CreateFormColorPicker(scrollChild, "Stats Text Color", "statsTextColor", charDB, RefreshAll)
        statsTextColor:SetPoint("TOPLEFT", PAD, y)
        statsTextColor:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW


        local headerClassColor = GUI:CreateFormCheckbox(scrollChild, "Header Class Color", "headerClassColor", charDB, function()
            RefreshAll()
            if widgetRefs.headerColor then
                local alpha = charDB.headerClassColor and 0.4 or 1.0
                widgetRefs.headerColor:SetAlpha(alpha)
            end
        end)
        headerClassColor:SetPoint("TOPLEFT", PAD, y)
        headerClassColor:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local headerColor = GUI:CreateFormColorPicker(scrollChild, "Header Color", "headerColor", charDB, RefreshAll)
        headerColor:SetPoint("TOPLEFT", PAD, y)
        headerColor:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        widgetRefs.headerColor = headerColor
        headerColor:SetAlpha(charDB.headerClassColor and 0.4 or 1.0)
        y = y - FORM_ROW


        local enchantClassColor = GUI:CreateFormCheckbox(scrollChild, "Enchant Class Color", "enchantClassColor", charDB, function()
            RefreshAll()
            if widgetRefs.enchantColor then
                local alpha = charDB.enchantClassColor and 0.4 or 1.0
                widgetRefs.enchantColor:SetAlpha(alpha)
            end
        end)
        enchantClassColor:SetPoint("TOPLEFT", PAD, y)
        enchantClassColor:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local enchantColor = GUI:CreateFormColorPicker(scrollChild, "Enchant Text Color", "enchantTextColor", charDB, RefreshAll)
        enchantColor:SetPoint("TOPLEFT", PAD, y)
        enchantColor:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        widgetRefs.enchantColor = enchantColor
        enchantColor:SetAlpha(charDB.enchantClassColor and 0.4 or 1.0)
        y = y - FORM_ROW

        local noEnchantColor = GUI:CreateFormColorPicker(scrollChild, "No Enchant Color", "noEnchantTextColor", charDB, RefreshAll)
        noEnchantColor:SetPoint("TOPLEFT", PAD, y)
        noEnchantColor:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        local upgradeTrackColor = GUI:CreateFormColorPicker(scrollChild, "Upgrade Track Color", "upgradeTrackColor", charDB, RefreshAll)
        upgradeTrackColor:SetPoint("TOPLEFT", PAD, y)
        upgradeTrackColor:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW

        y = y - 10


        scrollChild:SetHeight(math.abs(y) + 20)


        local resetBtn = GUI:CreateButton(settingsPanel, "Reset", 80, 24, function()

            charDB.panelScale = 1.0
            charDB.showItemName = true
            charDB.showItemLevel = true
            charDB.showEnchants = true
            charDB.showGems = true
            charDB.showDurability = false
            charDB.secondaryStatFormat = "both"
            charDB.slotTextSize = 12
            charDB.headerTextSize = 12
            charDB.statsTextSize = 12
            charDB.statsTextColor = {0.953, 0.957, 0.965}
            charDB.headerClassColor = true
            charDB.headerColor = {0.820, 0.180, 0.220}
            charDB.enchantClassColor = true
            charDB.enchantTextColor = {0.820, 0.180, 0.220}
            charDB.noEnchantTextColor = {0.5, 0.5, 0.5}
            charDB.upgradeTrackColor = {0.98, 0.60, 0.35, 1}


            CharacterFrame:SetScale(1.30)


            RefreshAll()


            settingsPanel:Hide()
            C_Timer.After(0.1, function()
                settingsPanel:Show()
            end)
        end)
        resetBtn:SetPoint("BOTTOM", settingsPanel, "BOTTOM", 0, 10)


        gearBtn:SetScript("OnClick", function()
            settingsPanel:SetShown(not settingsPanel:IsShown())
        end)
    end


    CharacterFrame:HookScript("OnHide", function()
        if CharacterFrame._preySettingsPanel then
            CharacterFrame._preySettingsPanel:Hide()
        end
    end)
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
eventFrame:RegisterEvent("SOCKET_INFO_UPDATE")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("UNIT_STATS")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("INSPECT_READY")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then

        if arg1 == "Blizzard_CharacterFrame" then
            C_Timer.After(0.1, function()
                HookCharacterFrame()
            end)
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "UPDATE_INVENTORY_DURABILITY" or
           event == "SOCKET_INFO_UPDATE" or event == "PLAYER_SPECIALIZATION_CHANGED" or
           event == "UNIT_STATS" then
        ScheduleUpdate()
    elseif event == "PLAYER_ENTERING_WORLD" then

        C_Timer.After(0.5, function()
            if CharacterFrame then
                HookCharacterFrame()
            end
        end)
    elseif event == "INSPECT_READY" then
        ScheduleUpdate()
    end
end)


_G.PreyUI_RefreshCharacterPane = function()
    ScheduleUpdate()
end


PREY.CharacterPane = {
    Refresh = function()
        ScheduleUpdate()
    end,

    GetSettings = GetSettings,
}

ns.CharacterPane = PREY.CharacterPane


PREY.CharacterShared = {

    EQUIPMENT_SLOTS = EQUIPMENT_SLOTS,
    C = C,


    GetSettings = GetSettings,
    GetGlobalFont = GetGlobalFont,


    CreateSlotOverlay = CreateSlotOverlay,
    UpdateAllSlotOverlays = UpdateAllSlotOverlays,
    ScheduleUpdate = ScheduleUpdate,
    GetSlotItemLevel = GetSlotItemLevel,
    GetILvlColor = GetILvlColor,
    AbbreviateClassName = AbbreviateClassName,
}
