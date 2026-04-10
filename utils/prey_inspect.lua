local ADDON_NAME, ns = ...
local PREY = ns.PREY or {}
ns.PREY = PREY


local inspectPaneInitialized = false
local inspectOverlays = {}
local inspectLayoutApplied = false
local currentInspectTab = 1
local inspectSettingsPanel = nil
local currentInspectGUID = nil


local function GetShared()
    return ns.PREY.CharacterShared or {}
end


local function GetSettings()
    local shared = GetShared()
    if shared.GetSettings then
        return shared.GetSettings()
    end

    return {
        inspectEnabled = true,
        showInspectItemName = true,
        showInspectItemLevel = true,
        showInspectEnchants = true,
        showInspectGems = true,
        inspectPanelScale = 1.0,
        inspectSlotTextSize = 12,
        inspectEnchantClassColor = true,
        inspectEnchantTextColor = {0.820, 0.180, 0.220},
        inspectNoEnchantTextColor = {0.5, 0.5, 0.5},
        inspectUpgradeTrackColor = {0.98, 0.60, 0.35, 1},
    }
end


local function GetColors()
    local shared = GetShared()
    return shared.C or {
        bg = { 0.067, 0.094, 0.153, 0.95 },
        accent = { 0.820, 0.180, 0.220, 1 },
        text = { 0.953, 0.957, 0.965, 1 },
        border = { 0.2, 0.25, 0.3, 1 },
    }
end


local INSPECT_CONFIG = {
    FRAME_TARGET_WIDTH = 500,
    FRAME_DEFAULT_WIDTH = 338,
    CLOSE_BUTTON_EXTENDED_X = -2,
    CLOSE_BUTTON_NORMAL_X = -2,
    CLOSE_BUTTON_Y = -2,

    MAINHAND_X_OFFSET = -25,
    MAINHAND_Y_OFFSET = -42,
    OFFHAND_SPACING = 30,

    BASE_SCALE = 1.30,
}


local INSPECT_SLOT_NAMES = {
    "InspectHeadSlot", "InspectNeckSlot", "InspectShoulderSlot",
    "InspectBackSlot", "InspectChestSlot", "InspectShirtSlot",
    "InspectTabardSlot", "InspectWristSlot", "InspectHandsSlot",
    "InspectWaistSlot", "InspectLegsSlot", "InspectFeetSlot",
    "InspectFinger0Slot", "InspectFinger1Slot",
    "InspectTrinket0Slot", "InspectTrinket1Slot",
    "InspectMainHandSlot", "InspectSecondaryHandSlot",
}


local function GetCurrentInspectTab()
    return currentInspectTab
end


local function RepositionInspectTabs()
    local tabs = { InspectFrameTab1, InspectFrameTab2, InspectFrameTab3 }
    local firstTab = tabs[1]

    if firstTab then
        firstTab:ClearAllPoints()
        firstTab:SetPoint("BOTTOMLEFT", InspectFrame, "BOTTOMLEFT", 15, -75)
    end


    local talentsBtn = InspectPaperDollItemsFrame and InspectPaperDollItemsFrame.InspectTalents
    if talentsBtn and InspectTrinket1Slot then
        talentsBtn:ClearAllPoints()
        talentsBtn:SetPoint("TOP", InspectTrinket1Slot, "BOTTOM", -12, -31)
    end
end


local function ResetInspectTabsPosition()
    local firstTab = InspectFrameTab1
    if firstTab then
        firstTab:ClearAllPoints()
        firstTab:SetPoint("BOTTOMLEFT", InspectFrame, "BOTTOMLEFT", 15, -30)
    end
end


local function RepositionInspectSlots()
    if not InspectFrame then return end

    local vpad = 14
    local SLOT_SCALE = 0.90
    local TOP_OFFSET = -75
    local LEFT_X = 20
    local RIGHT_X = 493


    local allSlots = {
        InspectHeadSlot, InspectNeckSlot, InspectShoulderSlot,
        InspectBackSlot, InspectChestSlot, InspectShirtSlot,
        InspectTabardSlot, InspectWristSlot,
        InspectHandsSlot, InspectWaistSlot, InspectLegsSlot,
        InspectFeetSlot, InspectFinger0Slot, InspectFinger1Slot,
        InspectTrinket0Slot, InspectTrinket1Slot,
        InspectMainHandSlot, InspectSecondaryHandSlot,
    }


    for _, slot in ipairs(allSlots) do
        if slot then slot:SetScale(SLOT_SCALE) end
    end


    if InspectHeadSlot then
        InspectHeadSlot:ClearAllPoints()
        InspectHeadSlot:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", LEFT_X, TOP_OFFSET)
    end

    if InspectNeckSlot then
        InspectNeckSlot:ClearAllPoints()
        InspectNeckSlot:SetPoint("TOPLEFT", InspectHeadSlot, "BOTTOMLEFT", 0, -vpad)
    end

    if InspectShoulderSlot then
        InspectShoulderSlot:ClearAllPoints()
        InspectShoulderSlot:SetPoint("TOPLEFT", InspectNeckSlot, "BOTTOMLEFT", 0, -vpad)
    end

    if InspectBackSlot then
        InspectBackSlot:ClearAllPoints()
        InspectBackSlot:SetPoint("TOPLEFT", InspectShoulderSlot, "BOTTOMLEFT", 0, -vpad)
    end

    if InspectChestSlot then
        InspectChestSlot:ClearAllPoints()
        InspectChestSlot:SetPoint("TOPLEFT", InspectBackSlot, "BOTTOMLEFT", 0, -vpad)
    end

    if InspectShirtSlot then
        InspectShirtSlot:ClearAllPoints()
        InspectShirtSlot:SetPoint("TOPLEFT", InspectChestSlot, "BOTTOMLEFT", 0, -vpad)
    end

    if InspectTabardSlot then
        InspectTabardSlot:ClearAllPoints()
        InspectTabardSlot:SetPoint("TOPLEFT", InspectShirtSlot, "BOTTOMLEFT", 0, -vpad)
    end


    if InspectHandsSlot then
        InspectHandsSlot:ClearAllPoints()
        InspectHandsSlot:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", RIGHT_X, TOP_OFFSET)
    end

    if InspectWaistSlot then
        InspectWaistSlot:ClearAllPoints()
        InspectWaistSlot:SetPoint("TOPLEFT", InspectHandsSlot, "BOTTOMLEFT", 0, -vpad)
    end

    if InspectLegsSlot then
        InspectLegsSlot:ClearAllPoints()
        InspectLegsSlot:SetPoint("TOPLEFT", InspectWaistSlot, "BOTTOMLEFT", 0, -vpad)
    end

    if InspectFeetSlot then
        InspectFeetSlot:ClearAllPoints()
        InspectFeetSlot:SetPoint("TOPLEFT", InspectLegsSlot, "BOTTOMLEFT", 0, -vpad)
    end

    if InspectFinger0Slot then
        InspectFinger0Slot:ClearAllPoints()
        InspectFinger0Slot:SetPoint("TOPLEFT", InspectFeetSlot, "BOTTOMLEFT", 0, -vpad)
    end

    if InspectFinger1Slot then
        InspectFinger1Slot:ClearAllPoints()
        InspectFinger1Slot:SetPoint("TOPLEFT", InspectFinger0Slot, "BOTTOMLEFT", 0, -vpad)
    end

    if InspectTrinket0Slot then
        InspectTrinket0Slot:ClearAllPoints()
        InspectTrinket0Slot:SetPoint("TOPLEFT", InspectFinger1Slot, "BOTTOMLEFT", 0, -vpad)
    end

    if InspectTrinket1Slot then
        InspectTrinket1Slot:ClearAllPoints()
        InspectTrinket1Slot:SetPoint("TOPLEFT", InspectTrinket0Slot, "BOTTOMLEFT", 0, -vpad)
    end


    if InspectWristSlot and InspectTrinket1Slot and InspectHeadSlot then
        InspectWristSlot:ClearAllPoints()
        InspectWristSlot:SetPoint("TOP", InspectTrinket1Slot, "TOP", 0, 0)
        InspectWristSlot:SetPoint("LEFT", InspectHeadSlot, "LEFT", 0, 0)
    end


    if InspectMainHandSlot then
        InspectMainHandSlot:ClearAllPoints()
        InspectMainHandSlot:SetPoint("BOTTOM", InspectFrame, "BOTTOM", INSPECT_CONFIG.MAINHAND_X_OFFSET, INSPECT_CONFIG.MAINHAND_Y_OFFSET)
    end

    if InspectSecondaryHandSlot and InspectMainHandSlot then
        InspectSecondaryHandSlot:ClearAllPoints()
        InspectSecondaryHandSlot:SetPoint("LEFT", InspectMainHandSlot, "RIGHT", INSPECT_CONFIG.OFFHAND_SPACING, 0)
    end

    RepositionInspectTabs()
end


local function BlockInspectIconBorder(iconBorder)
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


local function SkinInspectEquipmentSlot(slot)
    if not slot or slot._preySkinned then return end
    slot._preySkinned = true


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
        BlockInspectIconBorder(slot.IconBorder)
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


local function UpdateInspectSlotBorder(slot, unit)
    if not slot or not slot._preyBorderFrame then return end

    local slotID = slot:GetID()
    unit = unit or "target"


    local itemLink = GetInventoryItemLink(unit, slotID)
    local quality = nil
    if itemLink then
        local ok, q = pcall(C_Item.GetItemQualityByID, itemLink)
        if ok then quality = q end
    end

    if quality and quality >= 1 then
        local r, g, b = C_Item.GetItemQualityColor(quality)
        slot._preyBorderFrame:SetBackdropBorderColor(r, g, b, 1)
        slot._preyBorderFrame:Show()
    else
        slot._preyBorderFrame:Hide()
    end
end


local function SkinAllInspectSlots()
    for _, slotName in ipairs(INSPECT_SLOT_NAMES) do
        local slot = rawget(_G, slotName)
        if slot then
            SkinInspectEquipmentSlot(slot)
        end
    end
end


local function UpdateAllInspectSlotBorders(unit)
    for _, slotName in ipairs(INSPECT_SLOT_NAMES) do
        local slot = rawget(_G, slotName)
        if slot then
            UpdateInspectSlotBorder(slot, unit)
        end
    end
end


local function PositionInspectModelScene()
    if not InspectModelFrame then return end


    InspectModelFrame:ClearAllPoints()
    InspectModelFrame:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 55, -85)
    InspectModelFrame:SetPoint("BOTTOMRIGHT", InspectFrame, "BOTTOMRIGHT", -55, 65)
    InspectModelFrame:SetFrameLevel(2)


    if InspectModelFrame.ControlFrame then
        InspectModelFrame.ControlFrame:Hide()
    end


    if InspectModelFrame.ResetModel then
        InspectModelFrame:ResetModel()
    end

    InspectModelFrame:Show()
end


local function CalculateInspectAverageILvl(unit)
    local shared = GetShared()
    if not shared.GetSlotItemLevel or not shared.EQUIPMENT_SLOTS then
        return 0
    end

    local totalIlvl = 0
    local slotCount = 0


    local countedSlots = {
        [1] = true,
        [2] = true,
        [3] = true,
        [5] = true,
        [6] = true,
        [7] = true,
        [8] = true,
        [9] = true,
        [10] = true,
        [11] = true,
        [12] = true,
        [13] = true,
        [14] = true,
        [15] = true,
        [16] = true,
        [17] = true,
    }

    for slotId, counted in pairs(countedSlots) do
        if counted then
            local ilvl = shared.GetSlotItemLevel(unit, slotId)
            if ilvl and ilvl > 0 then
                totalIlvl = totalIlvl + ilvl
                slotCount = slotCount + 1
            end
        end
    end


    local mainHandLink = GetInventoryItemLink(unit, 16)
    local offHandLink = GetInventoryItemLink(unit, 17)
    if mainHandLink and not offHandLink then
        local mainIlvl = shared.GetSlotItemLevel(unit, 16)
        if mainIlvl and mainIlvl > 0 then
            totalIlvl = totalIlvl + mainIlvl
            slotCount = slotCount + 1
        end
    end

    if slotCount > 0 then
        return totalIlvl / slotCount
    end
    return 0
end


local function SetupInspectTitleArea()
    if not InspectFrame then return end

    local shared = GetShared()
    local font = shared.GetGlobalFont and shared.GetGlobalFont() or "Fonts\\FRIZQT__.TTF"


    if InspectFrame.TitleContainer and InspectFrame.TitleContainer.TitleText then
        InspectFrame.TitleContainer.TitleText:Hide()
    end


    if InspectLevelText then
        InspectLevelText:Hide()
    end


    if not InspectFrame._preyILvlDisplay then
        local displayFrame = CreateFrame("Frame", nil, InspectFrame)
        displayFrame:SetSize(400, 30)
        displayFrame:SetPoint("TOPLEFT", InspectFrame, "TOPLEFT", 19, -10)
        displayFrame:SetFrameLevel(InspectFrame:GetFrameLevel() + 10)


        local nameText = displayFrame:CreateFontString(nil, "OVERLAY")
        nameText:SetFont(font, 12, "")
        nameText:SetPoint("TOPLEFT", displayFrame, "TOPLEFT", 0, 0)
        nameText:SetJustifyH("LEFT")


        local specText = InspectFrame:CreateFontString(nil, "OVERLAY")
        specText:SetFont(font, 12, "")
        specText:SetPoint("TOPRIGHT", InspectFrame, "TOPRIGHT", -70, -10)
        specText:SetJustifyH("RIGHT")

        displayFrame.text = nameText
        displayFrame.specText = specText
        InspectFrame._preyILvlDisplay = displayFrame
    end


    if not InspectFrame._preyCenterILvl then
        local centerFrame = CreateFrame("Frame", nil, InspectFrame)
        centerFrame:SetSize(200, 20)
        centerFrame:SetPoint("TOP", InspectFrame, "TOP", 0, -10)
        centerFrame:SetFrameLevel(InspectFrame:GetFrameLevel() + 10)

        local centerText = centerFrame:CreateFontString(nil, "OVERLAY")
        centerText:SetFont(font, 21, "OUTLINE")
        centerText:SetPoint("CENTER")
        centerText:SetJustifyH("CENTER")

        centerFrame.text = centerText
        InspectFrame._preyCenterILvl = centerFrame
    end
end


local function UpdateInspectILvlDisplay()
    if not InspectFrame or not InspectFrame._preyILvlDisplay then return end

    local settings = GetSettings()
    if settings.inspectEnabled == false then return end

    local displayFrame = InspectFrame._preyILvlDisplay
    if not displayFrame.text then return end

    local shared = GetShared()
    local unit = InspectFrame.unit or "target"


    if currentInspectGUID and UnitGUID(unit) ~= currentInspectGUID then
        return
    end


    local name = UnitName(unit) or "Unknown"
    local level = UnitLevel(unit) or 0


    local className = ""
    local _, classToken = UnitClass(unit)
    if classToken then
        local classInfo = C_CreatureInfo.GetClassInfo(select(3, UnitClass(unit)))
        className = classInfo and classInfo.className or classToken
    end


    local specName = ""
    local specID = GetInspectSpecialization(unit)
    if specID and specID > 0 then
        local _, specNameLocal = GetSpecializationInfoByID(specID)
        specName = specNameLocal or ""
    end


    local classColor = RAID_CLASS_COLORS[classToken]
    local r, g, b = 1, 1, 1
    if classColor then
        r, g, b = classColor.r, classColor.g, classColor.b
    end


    displayFrame.text:SetText(name)
    displayFrame.text:SetTextColor(r, g, b, 1)


    if displayFrame.specText then
        local abbreviatedClass = shared.AbbreviateClassName and shared.AbbreviateClassName(className) or className
        local specLine = string.format("%d %s %s", level, specName, abbreviatedClass)
        displayFrame.specText:SetText(specLine)
        displayFrame.specText:SetTextColor(r, g, b, 1)
    end


    local centerFrame = InspectFrame._preyCenterILvl
    if centerFrame and centerFrame.text then
        local equipped = CalculateInspectAverageILvl(unit)

        if equipped > 0 and shared.GetILvlColor then
            local eR, eG, eB = shared.GetILvlColor(equipped)
            local equippedHex = string.format("%02x%02x%02x", math.floor(eR*255), math.floor(eG*255), math.floor(eB*255))
            local equippedStr = string.format("%.1f", equipped)
            centerFrame.text:SetText(string.format("|cff%s%s|r", equippedHex, equippedStr))
        else
            centerFrame.text:SetText("")
        end
    end
end


local function RepositionInspectCloseButton(extended)
    local closeButton = InspectFrame and (InspectFrame.CloseButton or InspectFrameCloseButton)
    if closeButton then
        closeButton:ClearAllPoints()
        local xOffset = extended and INSPECT_CONFIG.CLOSE_BUTTON_EXTENDED_X or INSPECT_CONFIG.CLOSE_BUTTON_NORMAL_X
        closeButton:SetPoint("TOPRIGHT", InspectFrame, "TOPRIGHT", xOffset, INSPECT_CONFIG.CLOSE_BUTTON_Y)
    end
end


local function SetInspectExtendedMode(tabNum)
    if not InspectFrame then return end
    currentInspectTab = tabNum
    InspectFrame:SetWidth(INSPECT_CONFIG.FRAME_TARGET_WIDTH)
    RepositionInspectTabs()
    RepositionInspectCloseButton(true)
    if _G.PREY_InspectFrameSkinning and _G.PREY_InspectFrameSkinning.SetExtended then
        _G.PREY_InspectFrameSkinning.SetExtended(true)
    end

    if InspectFrame._preyCenterILvl then
        InspectFrame._preyCenterILvl:Show()
    end
end


local function SetInspectNormalMode()
    if not InspectFrame then return end
    currentInspectTab = 3
    InspectFrame:SetWidth(INSPECT_CONFIG.FRAME_DEFAULT_WIDTH)
    ResetInspectTabsPosition()
    RepositionInspectCloseButton(false)
    if _G.PREY_InspectFrameSkinning and _G.PREY_InspectFrameSkinning.SetExtended then
        _G.PREY_InspectFrameSkinning.SetExtended(false)
    end

    if InspectFrame._preyCenterILvl then
        InspectFrame._preyCenterILvl:Hide()
    end
end


local function CreateInspectSettingsButton()
    if not InspectFrame then return end
    if InspectFrame._preyGearBtn then return end

    local GUI = _G.PreyUI and _G.PreyUI.GUI
    if not GUI then return end

    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not (PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.character) then
        C_Timer.After(0.5, CreateInspectSettingsButton)
        return
    end
    local charDB = PREYCore.db.profile.character


    if charDB.inspectEnchantTextColor == nil then
        charDB.inspectEnchantTextColor = {0.820, 0.180, 0.220}
    end
    if charDB.inspectNoEnchantTextColor == nil then
        charDB.inspectNoEnchantTextColor = {0.5, 0.5, 0.5}
    end
    if charDB.inspectUpgradeTrackColor == nil then
        charDB.inspectUpgradeTrackColor = {0.98, 0.60, 0.35, 1}
    end
    if charDB.inspectSlotTextSize == nil then
        charDB.inspectSlotTextSize = 12
    end

    local C = GetColors()
    local shared = GetShared()


    local gearBtn = CreateFrame("Button", "PREY_InspectSettingsBtn", InspectFrame, "BackdropTemplate")
    gearBtn:SetSize(70, 20)
    gearBtn:SetPoint("TOPRIGHT", InspectFrame, "TOPRIGHT", -5, -28)
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

    InspectFrame._preyGearBtn = gearBtn


    inspectSettingsPanel = CreateFrame("Frame", "PreyUI_InspectSettingsPanel", InspectFrame, "BackdropTemplate")
    inspectSettingsPanel:SetSize(450, 600)
    inspectSettingsPanel:SetPoint("TOPLEFT", InspectFrame, "TOPRIGHT", 5, 0)
    inspectSettingsPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    inspectSettingsPanel:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 0.98)
    inspectSettingsPanel:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    inspectSettingsPanel:SetFrameStrata("DIALOG")
    inspectSettingsPanel:SetFrameLevel(200)
    inspectSettingsPanel:EnableMouse(true)
    inspectSettingsPanel:Hide()
    InspectFrame._preySettingsPanel = inspectSettingsPanel


    local title = inspectSettingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", inspectSettingsPanel, "TOP", 0, -8)
    title:SetText("PREY Inspect Panel")
    title:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)


    local closeBtn = CreateFrame("Button", nil, inspectSettingsPanel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -3, -3)
    closeBtn:SetScript("OnClick", function() inspectSettingsPanel:Hide() end)


    local scrollFrame = CreateFrame("ScrollFrame", nil, inspectSettingsPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", inspectSettingsPanel, "TOPLEFT", 5, -28)
    scrollFrame:SetPoint("BOTTOMRIGHT", inspectSettingsPanel, "BOTTOMRIGHT", -26, 40)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(419)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)


    local scrollBar = scrollFrame.ScrollBar
    if scrollBar then
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 2, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 2, 16)
    end


    local PAD = 8
    local FORM_ROW = 28
    local y = -5


    local function RefreshInspect()
        if InspectFrame and InspectFrame:IsShown() and shared.ScheduleUpdate then
            shared.ScheduleUpdate()
        end
    end


    local function RefreshInspectFonts()
        local settings = GetSettings()
        local slotTextSize = settings.inspectSlotTextSize or 12
        local slotFont = shared.GetGlobalFont and shared.GetGlobalFont() or "Fonts\\FRIZQT__.TTF"
        local FONT_FLAGS = "OUTLINE"

        for _, overlay in pairs(inspectOverlays) do
            if overlay then
                if overlay.itemName and overlay.itemName.SetFont then
                    overlay.itemName:SetFont(slotFont, slotTextSize, FONT_FLAGS)
                end
                if overlay.itemLevel and overlay.itemLevel.SetFont then
                    overlay.itemLevel:SetFont(slotFont, slotTextSize, FONT_FLAGS)
                end
                if overlay.enchant and overlay.enchant.SetFont then
                    overlay.enchant:SetFont(slotFont, slotTextSize, FONT_FLAGS)
                end
            end
        end

        RefreshInspect()
    end


    local appearHeader = GUI:CreateSectionHeader(scrollChild, "Appearance")
    appearHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - appearHeader.gap


    local scaleSlider = GUI:CreateFormSlider(scrollChild, "Panel Scale", 0.75, 1.5, 0.05, "inspectPanelScale", charDB, function()
        local multiplier = charDB.inspectPanelScale or 1.0
        if InspectFrame then
            InspectFrame:SetScale(INSPECT_CONFIG.BASE_SCALE * multiplier)
        end
    end, { deferOnDrag = true })
    scaleSlider:SetPoint("TOPLEFT", PAD, y)
    scaleSlider:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
    y = y - FORM_ROW


    local generalDB = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
    local bgColorPicker = nil
    if generalDB then
        bgColorPicker = GUI:CreateFormColorPicker(scrollChild, "Background Color", "skinBgColor", generalDB, function()

            if _G.PreyUI_RefreshInspectColors then
                _G.PreyUI_RefreshInspectColors()
            end
            if _G.PREY_InspectFrameSkinning and _G.PREY_InspectFrameSkinning.Refresh then
                _G.PREY_InspectFrameSkinning.Refresh()
            end
        end)
        bgColorPicker:SetPoint("TOPLEFT", PAD, y)
        bgColorPicker:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
        y = y - FORM_ROW


        inspectSettingsPanel:HookScript("OnShow", function()
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

    local showItemName = GUI:CreateFormCheckbox(scrollChild, "Show Equipment Name", "showInspectItemName", charDB, RefreshInspect)
    showItemName:SetPoint("TOPLEFT", PAD, y)
    showItemName:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local showIlvl = GUI:CreateFormCheckbox(scrollChild, "Show Item Level", "showInspectItemLevel", charDB, RefreshInspect)
    showIlvl:SetPoint("TOPLEFT", PAD, y)
    showIlvl:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local showEnchants = GUI:CreateFormCheckbox(scrollChild, "Show Enchant Status", "showInspectEnchants", charDB, RefreshInspect)
    showEnchants:SetPoint("TOPLEFT", PAD, y)
    showEnchants:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local showGems = GUI:CreateFormCheckbox(scrollChild, "Show Gem Indicators", "showInspectGems", charDB, RefreshInspect)
    showGems:SetPoint("TOPLEFT", PAD, y)
    showGems:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    y = y - 10


    local textSizeHeader = GUI:CreateSectionHeader(scrollChild, "Text Sizes")
    textSizeHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - textSizeHeader.gap

    local slotTextSize = GUI:CreateFormSlider(scrollChild, "Slot Text Size", 6, 40, 1, "inspectSlotTextSize", charDB, RefreshInspectFonts)
    slotTextSize:SetPoint("TOPLEFT", PAD, y)
    slotTextSize:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    y = y - 10


    local textColorHeader = GUI:CreateSectionHeader(scrollChild, "Text Colors")
    textColorHeader:SetPoint("TOPLEFT", PAD, y)
    y = y - textColorHeader.gap


    local widgetRefs = {}


    local enchantClassColor = GUI:CreateFormCheckbox(scrollChild, "Enchant Class Color", "inspectEnchantClassColor", charDB, function()
        RefreshInspect()
        if widgetRefs.enchantColor then
            local alpha = charDB.inspectEnchantClassColor and 0.4 or 1.0
            widgetRefs.enchantColor:SetAlpha(alpha)
        end
    end)
    enchantClassColor:SetPoint("TOPLEFT", PAD, y)
    enchantClassColor:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local enchantColor = GUI:CreateFormColorPicker(scrollChild, "Enchant Text Color", "inspectEnchantTextColor", charDB, RefreshInspect)
    enchantColor:SetPoint("TOPLEFT", PAD, y)
    enchantColor:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
    widgetRefs.enchantColor = enchantColor
    enchantColor:SetAlpha(charDB.inspectEnchantClassColor and 0.4 or 1.0)
    y = y - FORM_ROW

    local noEnchantColor = GUI:CreateFormColorPicker(scrollChild, "No Enchant Color", "inspectNoEnchantTextColor", charDB, RefreshInspect)
    noEnchantColor:SetPoint("TOPLEFT", PAD, y)
    noEnchantColor:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    local upgradeTrackColor = GUI:CreateFormColorPicker(scrollChild, "Upgrade Track Color", "inspectUpgradeTrackColor", charDB, RefreshInspect)
    upgradeTrackColor:SetPoint("TOPLEFT", PAD, y)
    upgradeTrackColor:SetPoint("RIGHT", scrollChild, "RIGHT", -PAD, 0)
    y = y - FORM_ROW

    y = y - 10


    scrollChild:SetHeight(math.abs(y) + 20)


    local resetBtn = GUI:CreateButton(inspectSettingsPanel, "Reset", 80, 24, function()

        charDB.inspectPanelScale = 1.0
        charDB.showInspectItemName = true
        charDB.showInspectItemLevel = true
        charDB.showInspectEnchants = true
        charDB.showInspectGems = true
        charDB.inspectSlotTextSize = 12
        charDB.inspectEnchantClassColor = true
        charDB.inspectEnchantTextColor = {0.820, 0.180, 0.220}
        charDB.inspectNoEnchantTextColor = {0.5, 0.5, 0.5}
        charDB.inspectUpgradeTrackColor = {0.98, 0.60, 0.35, 1}


        if InspectFrame then
            InspectFrame:SetScale(INSPECT_CONFIG.BASE_SCALE)
        end


        RefreshInspectFonts()
        inspectSettingsPanel:Hide()
        C_Timer.After(0.1, function()
            inspectSettingsPanel:Show()
        end)
    end)
    resetBtn:SetPoint("BOTTOM", inspectSettingsPanel, "BOTTOM", 0, 10)


    gearBtn:SetScript("OnClick", function()
        inspectSettingsPanel:SetShown(not inspectSettingsPanel:IsShown())
    end)
end


local function ApplyInspectPaneLayout()
    local settings = GetSettings()
    if settings.inspectEnabled == false then return end
    if not InspectFrame then return end

    if inspectLayoutApplied then return end

    InspectFrame:SetWidth(INSPECT_CONFIG.FRAME_TARGET_WIDTH)
    RepositionInspectCloseButton(true)


    local scaleMultiplier = settings.inspectPanelScale or 1.0
    InspectFrame:SetScale(INSPECT_CONFIG.BASE_SCALE * scaleMultiplier)

    C_Timer.After(0.1, function()
        RepositionInspectSlots()
        PositionInspectModelScene()
        SetupInspectTitleArea()
        CreateInspectSettingsButton()
        SkinAllInspectSlots()

        if _G.PREY_InspectFrameSkinning and _G.PREY_InspectFrameSkinning.SetExtended then
            _G.PREY_InspectFrameSkinning.SetExtended(true)
        end


        C_Timer.After(0.05, function()
            RepositionInspectSlots()
            PositionInspectModelScene()
            UpdateAllInspectSlotBorders("target")
        end)
    end)

    inspectLayoutApplied = true
end


local function InitializeInspectOverlays()
    if inspectPaneInitialized then return end

    local shared = GetShared()
    if not shared.CreateSlotOverlay or not shared.EQUIPMENT_SLOTS then return end

    for _, slotInfo in ipairs(shared.EQUIPMENT_SLOTS) do
        local slotFrame = rawget(_G, "Inspect" .. slotInfo.name .. "Slot")
        if slotFrame then
            inspectOverlays[slotInfo.id] = shared.CreateSlotOverlay(slotFrame, slotInfo, "target")
        end
    end

    inspectPaneInitialized = true
end


local function UpdateInspectFrame()
    if not InspectFrame or not InspectFrame:IsShown() then return end

    local shared = GetShared()
    if shared.UpdateAllSlotOverlays then
        shared.UpdateAllSlotOverlays("target", inspectOverlays)
    end


    UpdateInspectILvlDisplay()


    UpdateAllInspectSlotBorders("target")
end


local function HookInspectFrame()
    if not InspectFrame then return end

    local settings = GetSettings()
    if settings.inspectEnabled == false then return end

    local shared = GetShared()

    InspectFrame:HookScript("OnShow", function()
        currentInspectTab = 1
        ApplyInspectPaneLayout()
        InitializeInspectOverlays()

        C_Timer.After(0.1, function()
            local unit = InspectFrame.unit or "target"

            local ok, canInspect = pcall(function() return UnitExists(unit) and CanInspect(unit) end)
            if ok and canInspect then
                NotifyInspect(unit)
            end
        end)

        if shared.ScheduleUpdate then
            C_Timer.After(0.3, shared.ScheduleUpdate)
        end
    end)

    InspectFrame:HookScript("OnHide", function()
        inspectLayoutApplied = false
        InspectFrame:SetWidth(INSPECT_CONFIG.FRAME_DEFAULT_WIDTH)
        GameTooltip:Hide()
    end)

    if InspectFrameTab1 then
        InspectFrameTab1:HookScript("OnClick", function()
            SetInspectExtendedMode(1)
        end)
    end

    if InspectFrameTab2 then
        InspectFrameTab2:HookScript("OnClick", function()
            SetInspectExtendedMode(2)
        end)
    end

    if InspectFrameTab3 then
        InspectFrameTab3:HookScript("OnClick", function()
            SetInspectNormalMode()
        end)
    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("INSPECT_READY")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_InspectUI" then
            C_Timer.After(0.1, function()
                HookInspectFrame()
            end)
        end
    elseif event == "INSPECT_READY" then

        currentInspectGUID = arg1
        local shared = GetShared()
        if shared.ScheduleUpdate then
            shared.ScheduleUpdate()
        end
    end
end)


PREY.InspectPane = {
    UpdateInspectFrame = UpdateInspectFrame,
    GetCurrentTab = GetCurrentInspectTab,
    INSPECT_CONFIG = INSPECT_CONFIG,
}

ns.InspectPane = PREY.InspectPane
