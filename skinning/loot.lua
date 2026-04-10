local ADDON_NAME, ns = ...
local PREYCore = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")

local tinsert, tremove = tinsert, tremove


local Loot = {}
PREYCore.Loot = Loot


local function GetThemeColors()
    local PREY = _G.PreyUI
    if PREY and PREY.GetSkinColor and PREY.GetSkinBgColor then
        local sr, sg, sb, sa = PREY:GetSkinColor()
        local bgr, bgg, bgb, bga = PREY:GetSkinBgColor()
        return {bgr, bgg, bgb, bga}, {sr, sg, sb, sa}, {0.95, 0.96, 0.97, 1}
    end

    return {0.05, 0.05, 0.05, 0.95}, {0.820, 0.180, 0.220, 1}, {0.95, 0.96, 0.97, 1}
end


local MAX_LOOT_SLOTS = 10
local MAX_ROLL_FRAMES = 8
local SLOT_HEIGHT = 32
local SLOT_WIDTH = 230
local SLOT_SPACING = 2
local HEADER_HEIGHT = 30
local LOOT_FRAME_WIDTH = 250
local LOOT_FRAME_HEIGHT = 200
local ICON_SIZE = 28
local ICON_BORDER_SIZE = 30
local ROLL_FRAME_HEIGHT = 50
local ROLL_FRAME_WIDTH = 340
local ROLL_ICON_SIZE = 32
local ROLL_BUTTON_SIZE = 26
local ROLL_TIMER_HEIGHT = 6


local ROLL_TEXTURES = {
    pass = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
    disenchant = "Interface\\Buttons\\UI-GroupLoot-DE-Up",
    greed = "Interface\\Buttons\\UI-GroupLoot-Coin-Up",
    need = "Interface\\Buttons\\UI-GroupLoot-Dice-Up",
    transmog = "Interface\\MINIMAP\\TRACKING\\Transmogrifier",
}


local lootFrame = nil
local rollFramePool = {}
local activeRolls = {}
local rollAnchor = nil
local waitingRolls = {}


local ProcessRollQueue
local StartRoll


local function GetGeneralFont()
    local db = PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
    return (db and db.font) or "Prey"
end

local function GetDB()
    return PREYCore.db and PREYCore.db.profile or {}
end

local function IsUncollectedTransmog(itemLink)
    if not itemLink then return false end
    if not C_TransmogCollection or not C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance then
        return false
    end
    local itemID = GetItemInfoInstant(itemLink)
    if not itemID then return false end


    local _, _, _, _, _, classID = GetItemInfoInstant(itemLink)
    if classID ~= 2 and classID ~= 4 then return false end


    local _, sourceID = C_TransmogCollection.GetItemInfo(itemLink)
    if sourceID then
        local _, canCollect = C_TransmogCollection.PlayerCanCollectSource(sourceID)
        if canCollect then
            local collected = C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance(sourceID)
            return not collected
        end
    end
    return false
end


local function CreateLootSlot(parent, index)
    local bgColor, borderColor, textColor = GetThemeColors()

    local slot = CreateFrame("Button", "PREY_LootSlot"..index, parent)
    slot:SetSize(SLOT_WIDTH, SLOT_HEIGHT)
    slot:SetPoint("TOP", parent, "TOP", 0, -HEADER_HEIGHT - ((index-1) * (SLOT_HEIGHT + SLOT_SPACING)))


    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetSize(ICON_SIZE, ICON_SIZE)
    slot.icon:SetPoint("LEFT", 4, 0)
    slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)


    slot.iconBorder = CreateFrame("Frame", nil, slot, "BackdropTemplate")
    slot.iconBorder:SetSize(ICON_BORDER_SIZE, ICON_BORDER_SIZE)
    slot.iconBorder:SetPoint("CENTER", slot.icon, "CENTER")
    slot.iconBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })


    slot.name = slot:CreateFontString(nil, "OVERLAY")
    slot.name:SetFont(LSM:Fetch("font", GetGeneralFont()), 11, "OUTLINE")
    slot.name:SetPoint("LEFT", slot.icon, "RIGHT", 6, 0)
    slot.name:SetPoint("RIGHT", slot, "RIGHT", -40, 0)
    slot.name:SetJustifyH("LEFT")
    slot.name:SetWordWrap(false)


    slot.count = slot:CreateFontString(nil, "OVERLAY")
    slot.count:SetFont(LSM:Fetch("font", GetGeneralFont()), 10, "OUTLINE")
    slot.count:SetPoint("BOTTOMRIGHT", slot.icon, "BOTTOMRIGHT", -2, 2)
    slot.count:SetTextColor(1, 1, 1)


    slot.transmogMarker = slot:CreateFontString(nil, "OVERLAY")
    slot.transmogMarker:SetFont(LSM:Fetch("font", GetGeneralFont()), 12, "OUTLINE")
    slot.transmogMarker:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -4, -4)
    slot.transmogMarker:SetText("*")
    slot.transmogMarker:SetTextColor(1, 0.82, 0)
    slot.transmogMarker:Hide()


    slot.questIcon = slot:CreateTexture(nil, "OVERLAY")
    slot.questIcon:SetSize(14, 14)
    slot.questIcon:SetPoint("TOPLEFT", slot.icon, "TOPLEFT", -2, 2)
    slot.questIcon:SetAtlas("QuestNormal")
    slot.questIcon:Hide()


    slot:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
    slot:GetHighlightTexture():SetVertexColor(borderColor[1], borderColor[2], borderColor[3], 0.2)


    slot:SetScript("OnClick", function(self)
        if self.slotIndex then
            LootSlot(self.slotIndex)
        end
    end)


    slot:SetScript("OnEnter", function(self)
        if self.slotIndex then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local ok = pcall(GameTooltip.SetLootItem, GameTooltip, self.slotIndex)
            if ok then
                GameTooltip:Show()
            else
                GameTooltip:Hide()
            end
        end
    end)
    slot:SetScript("OnLeave", GameTooltip_Hide)

    slot:Hide()
    return slot
end

local function CreateLootWindow()
    local bgColor, borderColor, textColor = GetThemeColors()

    local frame = CreateFrame("Frame", "PREY_LootFrame", UIParent, "BackdropTemplate")
    frame:SetSize(LOOT_FRAME_WIDTH, LOOT_FRAME_HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:Hide()


    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(bgColor))
    frame:SetBackdropBorderColor(unpack(borderColor))


    frame.header = frame:CreateFontString(nil, "OVERLAY")
    frame.header:SetFont(LSM:Fetch("font", GetGeneralFont()), 12, "OUTLINE")
    frame.header:SetPoint("TOP", 0, -8)
    frame.header:SetTextColor(unpack(textColor))
    frame.header:SetText("Loot")


    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db = GetDB()
        if db.loot then
            local point, _, relPoint, x, y = self:GetPoint()
            db.loot.position = { point = point, relPoint = relPoint, x = x, y = y }
        end
    end)


    frame.closeBtn = CreateFrame("Button", nil, frame)
    frame.closeBtn:SetSize(16, 16)
    frame.closeBtn:SetPoint("TOPRIGHT", -4, -4)
    frame.closeBtn.text = frame.closeBtn:CreateFontString(nil, "OVERLAY")
    frame.closeBtn.text:SetFont(LSM:Fetch("font", GetGeneralFont()), 14, "OUTLINE")
    frame.closeBtn.text:SetAllPoints()
    frame.closeBtn.text:SetText("x")
    frame.closeBtn.text:SetTextColor(0.8, 0.8, 0.8)
    frame.closeBtn:SetScript("OnClick", function() CloseLoot() end)
    frame.closeBtn:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 0.3, 0.3) end)
    frame.closeBtn:SetScript("OnLeave", function(self) self.text:SetTextColor(0.8, 0.8, 0.8) end)


    frame.slots = {}
    for i = 1, MAX_LOOT_SLOTS do
        frame.slots[i] = CreateLootSlot(frame, i)
    end

    return frame
end

local function OnLootOpened(autoLoot)
    local numItems = GetNumLootItems()
    if numItems == 0 then return end

    local db = GetDB()
    if not db.loot or not db.loot.enabled then return end


    if db.general and db.general.fastAutoLoot then return end


    if db.loot.lootUnderMouse then
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        lootFrame:ClearAllPoints()
        lootFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x/scale, y/scale)
    elseif db.loot.position and db.loot.position.point then
        lootFrame:ClearAllPoints()
        lootFrame:SetPoint(db.loot.position.point, UIParent, db.loot.position.relPoint or "CENTER",
                           db.loot.position.x or 0, db.loot.position.y or 100)
    else
        lootFrame:ClearAllPoints()
        lootFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end


    local visibleSlots = 0
    for i = 1, numItems do
        local slot = lootFrame.slots[i]
        if slot and LootSlotHasItem(i) then
            local texture, name, quantity, currencyID, quality, locked, isQuestItem,
                  questID, isActive = GetLootSlotInfo(i)

            slot.slotIndex = i
            slot.icon:SetTexture(texture)
            slot.name:SetText(name or "")


            local r, g, b = GetItemQualityColor(quality or 1)
            slot.iconBorder:SetBackdropBorderColor(r, g, b, 1)
            slot.name:SetTextColor(r, g, b)


            if quantity and quantity > 1 then
                slot.count:SetText(quantity)
                slot.count:Show()
            else
                slot.count:Hide()
            end


            slot.questIcon:SetShown(isQuestItem or (questID and questID > 0))


            if db.loot.showTransmogMarker then
                local link = GetLootSlotLink(i)
                local isUncollected = IsUncollectedTransmog(link)
                slot.transmogMarker:SetShown(isUncollected)
            else
                slot.transmogMarker:Hide()
            end

            slot:Show()
            visibleSlots = visibleSlots + 1
        elseif slot then
            slot:Hide()
        end
    end


    for i = numItems + 1, MAX_LOOT_SLOTS do
        if lootFrame.slots[i] then
            lootFrame.slots[i]:Hide()
        end
    end


    local height = 40 + (visibleSlots * (SLOT_HEIGHT + SLOT_SPACING))
    lootFrame:SetHeight(height)
    lootFrame:Show()
end

local function OnLootSlotCleared(slot)
    if lootFrame and lootFrame.slots[slot] then
        lootFrame.slots[slot]:Hide()


    end
end

local function OnLootClosed()
    if lootFrame then
        lootFrame:Hide()
        for i = 1, MAX_LOOT_SLOTS do
            if lootFrame.slots[i] then
                lootFrame.slots[i]:Hide()
            end
        end
    end
end


local function CreateRollButton(parent, rollType, rollValue, texture)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(ROLL_BUTTON_SIZE, ROLL_BUTTON_SIZE)

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexture(texture)


    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0, 0, 0, 0.3)

    btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    btn.rollValue = rollValue
    btn.rollType = rollType


    btn:SetScript("OnClick", function(self)
        local frame = self:GetParent()
        if frame.rollID then
            local rollID = frame.rollID
            RollOnLoot(rollID, self.rollValue)

            frame:Hide()
            frame.rollID = nil
            frame.timer:SetScript("OnUpdate", nil)
            activeRolls[rollID] = nil

            C_Timer.After(0, ProcessRollQueue)
        end
    end)


    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(rollType)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    return btn
end


local QUALITY_BG_TINTS = {
    [0] = { 0.5, 0.5, 0.5, 0.08 },
    [1] = { 1.0, 1.0, 1.0, 0.05 },
    [2] = { 0.12, 1.0, 0.0, 0.08 },
    [3] = { 0.0, 0.44, 0.87, 0.1 },
    [4] = { 0.64, 0.21, 0.93, 0.12 },
    [5] = { 1.0, 0.5, 0.0, 0.15 },
}


local function CreateRollFrame(index)
    local bgColor, borderColor, textColor = GetThemeColors()

    local frame = CreateFrame("Frame", "PREY_LootRollFrame"..index, UIParent, "BackdropTemplate")
    frame:SetSize(ROLL_FRAME_WIDTH, ROLL_FRAME_HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)


    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], 0.95)
    frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 0.3)


    frame.qualityTint = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    frame.qualityTint:SetAllPoints()
    frame.qualityTint:SetColorTexture(1, 1, 1, 0.1)
    frame.qualityTint:SetBlendMode("ADD")


    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(ROLL_ICON_SIZE, ROLL_ICON_SIZE)
    frame.icon:SetPoint("LEFT", 4, 4)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)


    frame.iconBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.iconBorder:SetSize(ROLL_ICON_SIZE + 4, ROLL_ICON_SIZE + 4)
    frame.iconBorder:SetPoint("CENTER", frame.icon, "CENTER")
    frame.iconBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })


    frame.name = frame:CreateFontString(nil, "OVERLAY")
    frame.name:SetFont(LSM:Fetch("font", GetGeneralFont()), 12, "OUTLINE")
    frame.name:SetPoint("LEFT", frame.icon, "RIGHT", 8, 0)
    frame.name:SetPoint("RIGHT", frame, "RIGHT", -120, 4)
    frame.name:SetJustifyH("LEFT")
    frame.name:SetWordWrap(false)


    frame.timer = CreateFrame("StatusBar", nil, frame)
    frame.timer:SetHeight(ROLL_TIMER_HEIGHT)
    frame.timer:SetPoint("BOTTOMLEFT", 4, 4)
    frame.timer:SetPoint("BOTTOMRIGHT", -4, 4)
    frame.timer:SetStatusBarTexture(LSM:Fetch("statusbar", "Prey") or "Interface\\TargetingFrame\\UI-StatusBar")
    frame.timer:SetStatusBarColor(borderColor[1], borderColor[2], borderColor[3], 1)
    frame.timer:SetMinMaxValues(0, 1)
    frame.timer:SetValue(1)


    frame.timer.bg = frame.timer:CreateTexture(nil, "BACKGROUND")
    frame.timer.bg:SetAllPoints()
    frame.timer.bg:SetColorTexture(0, 0, 0, 0.6)


    local buttonY = 4
    frame.passBtn = CreateRollButton(frame, "Pass", 0, ROLL_TEXTURES.pass)
    frame.passBtn:SetPoint("RIGHT", frame, "RIGHT", -6, buttonY)

    frame.disenchantBtn = CreateRollButton(frame, "Disenchant", 3, ROLL_TEXTURES.disenchant)
    frame.disenchantBtn:SetPoint("RIGHT", frame.passBtn, "LEFT", -4, 0)

    frame.greedBtn = CreateRollButton(frame, "Greed", 2, ROLL_TEXTURES.greed)
    frame.greedBtn:SetPoint("RIGHT", frame.disenchantBtn, "LEFT", -4, 0)


    frame.transmogBtn = CreateRollButton(frame, TRANSMOGRIFY, 4, ROLL_TEXTURES.transmog)
    frame.transmogBtn:SetPoint("RIGHT", frame.disenchantBtn, "LEFT", -4, 0)
    frame.transmogBtn:Hide()

    frame.needBtn = CreateRollButton(frame, "Need", 1, ROLL_TEXTURES.need)
    frame.needBtn:SetPoint("RIGHT", frame.greedBtn, "LEFT", -4, 0)


    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        if self.rollID then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
            GameTooltip:SetLootRollItem(self.rollID)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", GameTooltip_Hide)

    frame:Hide()
    return frame
end

local function GetAvailableRollFrame()
    local db = GetDB()
    local maxVisible = (db.lootRoll and db.lootRoll.maxFrames) or 4


    local visibleCount = 0
    for i = 1, MAX_ROLL_FRAMES do
        if rollFramePool[i] and rollFramePool[i]:IsShown() then
            visibleCount = visibleCount + 1
        end
    end


    if visibleCount >= maxVisible then
        return nil
    end


    for i = 1, MAX_ROLL_FRAMES do
        if not rollFramePool[i] then
            rollFramePool[i] = CreateRollFrame(i)
        end
        if not rollFramePool[i]:IsShown() then
            return rollFramePool[i]
        end
    end
    return nil
end

local function PositionRollFrame(frame)
    local db = GetDB()
    local growDirection = (db.lootRoll and db.lootRoll.growDirection) or "DOWN"
    local spacing = (db.lootRoll and db.lootRoll.spacing) or 4

    local index = 0
    for _, f in pairs(activeRolls) do
        if f:IsShown() and f ~= frame then
            index = index + 1
        end
    end

    frame:ClearAllPoints()
    if growDirection == "UP" then
        frame:SetPoint("BOTTOM", rollAnchor, "TOP", 0, (index * (ROLL_FRAME_HEIGHT + spacing)))
    else
        frame:SetPoint("TOP", rollAnchor, "BOTTOM", 0, -(index * (ROLL_FRAME_HEIGHT + spacing)))
    end
end

local function RepositionAllRolls()
    local db = GetDB()
    local growDirection = (db.lootRoll and db.lootRoll.growDirection) or "DOWN"
    local spacing = (db.lootRoll and db.lootRoll.spacing) or 4

    local index = 0
    for _, frame in pairs(activeRolls) do
        if frame:IsShown() then
            frame:ClearAllPoints()
            if growDirection == "UP" then
                frame:SetPoint("BOTTOM", rollAnchor, "TOP", 0, (index * (ROLL_FRAME_HEIGHT + spacing)))
            else
                frame:SetPoint("TOP", rollAnchor, "BOTTOM", 0, -(index * (ROLL_FRAME_HEIGHT + spacing)))
            end
            index = index + 1
        end
    end
end


ProcessRollQueue = function()
    RepositionAllRolls()
    if #waitingRolls > 0 then
        local nextRoll = tremove(waitingRolls, 1)

        local texture = GetLootRollItemInfo(nextRoll.rollID)
        if texture then
            StartRoll(nextRoll.rollID, nextRoll.rollTime)
        elseif #waitingRolls > 0 then

            ProcessRollQueue()
        end
    end
end

StartRoll = function(rollID, rollTime, lootHandle)
    local db = GetDB()
    if not db.lootRoll or not db.lootRoll.enabled then return end

    local texture, name, count, quality, bop, canNeed, canGreed, canDE, reason, deReason, _, _, canTransmog = GetLootRollItemInfo(rollID)
    if not texture then return end

    local frame = GetAvailableRollFrame()
    if not frame then

        tinsert(waitingRolls, { rollID = rollID, rollTime = rollTime })
        return
    end


    frame:SetAlpha(1)
    frame:SetScript("OnUpdate", nil)


    local buttons = { frame.needBtn, frame.greedBtn, frame.disenchantBtn, frame.passBtn, frame.transmogBtn }
    for _, btn in ipairs(buttons) do
        btn:Enable()
        btn:SetAlpha(1)
        btn.icon:SetDesaturated(false)
        btn:Show()
    end

    frame.rollID = rollID
    frame.rollTime = rollTime
    frame.startTime = GetTime()

    frame.icon:SetTexture(texture)
    frame.name:SetText(name or "")


    local r, g, b = GetItemQualityColor(quality or 1)
    frame.iconBorder:SetBackdropBorderColor(r, g, b, 1)
    frame.name:SetTextColor(r, g, b)


    local tint = QUALITY_BG_TINTS[quality or 1] or QUALITY_BG_TINTS[1]
    frame.qualityTint:SetColorTexture(tint[1], tint[2], tint[3], tint[4])


    frame.needBtn:SetEnabled(canNeed)
    frame.needBtn.icon:SetDesaturated(not canNeed)
    frame.needBtn:SetAlpha(canNeed and 1 or 0.4)

    frame.greedBtn:SetEnabled(canGreed)
    frame.greedBtn.icon:SetDesaturated(not canGreed)
    frame.greedBtn:SetAlpha(canGreed and 1 or 0.4)

    frame.disenchantBtn:SetEnabled(canDE)
    frame.disenchantBtn.icon:SetDesaturated(not canDE)
    frame.disenchantBtn:SetAlpha(canDE and 1 or 0.4)
    frame.disenchantBtn:SetShown(canDE)


    if canTransmog then

        frame.transmogBtn:SetEnabled(true)
        frame.transmogBtn.icon:SetDesaturated(false)
        frame.transmogBtn:SetAlpha(1)
        frame.transmogBtn:Show()
        frame.greedBtn:Hide()

        frame.needBtn:ClearAllPoints()
        frame.needBtn:SetPoint("RIGHT", frame.transmogBtn, "LEFT", -4, 0)
    else

        frame.transmogBtn:Hide()
        frame.greedBtn:Show()

        frame.needBtn:ClearAllPoints()
        frame.needBtn:SetPoint("RIGHT", frame.greedBtn, "LEFT", -4, 0)
    end


    PositionRollFrame(frame)


    local _, accentColor = GetThemeColors()
    frame.timer:SetStatusBarColor(accentColor[1], accentColor[2], accentColor[3], 1)
    frame.timer:SetScript("OnUpdate", function(self, elapsed)
        local remaining = frame.rollTime - (GetTime() - frame.startTime)
        if remaining > 0 then
            self:SetValue(remaining / frame.rollTime)
        else
            self:SetValue(0)
            self:SetScript("OnUpdate", nil)
        end
    end)

    activeRolls[rollID] = frame
    frame:Show()
end

local function CancelRoll(rollID)

    for i = #waitingRolls, 1, -1 do
        if waitingRolls[i].rollID == rollID then
            tremove(waitingRolls, i)
            return
        end
    end


    local frame = activeRolls[rollID]
    if frame then
        frame:Hide()
        frame.rollID = nil
        frame.timer:SetScript("OnUpdate", nil)
        activeRolls[rollID] = nil

        C_Timer.After(0, ProcessRollQueue)
    end
end


local function CreateRollAnchor()
    local anchor = CreateFrame("Frame", "PREY_LootRollAnchor", UIParent, "BackdropTemplate")
    anchor:SetSize(ROLL_FRAME_WIDTH, 1)
    anchor:SetPoint("TOP", UIParent, "TOP", 0, -200)
    anchor:SetMovable(true)
    anchor:EnableMouse(false)


    anchor:Hide()

    return anchor
end


local lootHistorySkinned = false


local function SkinLootHistoryElement(button)
    if button.PREYSkinned then return end


    if button.BackgroundArtFrame then
        button.BackgroundArtFrame:SetAlpha(0)
    end

    if button.NameFrame then
        button.NameFrame:SetAlpha(0)
    end

    if button.BorderFrame then
        button.BorderFrame:SetAlpha(0)
    end


    local item = button.Item
    if item then
        local icon = item.icon or item.Icon
        if icon then

            if item.NormalTexture then item.NormalTexture:SetAlpha(0) end
            if item.PushedTexture then item.PushedTexture:SetAlpha(0) end
            if item.HighlightTexture then item.HighlightTexture:SetAlpha(0) end


            if not item.preyBorder then
                item.preyBorder = CreateFrame("Frame", nil, item, "BackdropTemplate")
                item.preyBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
                item.preyBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
                item.preyBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
                item.preyBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
            end


            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)


            if item.IconBorder and not item._preyBorderHooked then
                item._preyBorderHooked = true
                hooksecurefunc(item.IconBorder, "SetVertexColor", function(self, r, g, b)
                    if item.preyBorder then
                        item.preyBorder:SetBackdropBorderColor(r, g, b, 1)
                    end
                end)
                item.IconBorder:SetAlpha(0)
            end
        end
    end

    button.PREYSkinned = true
end


local function HandleLootHistoryScrollUpdate(scrollBox)
    scrollBox:ForEachFrame(SkinLootHistoryElement)
end


local function SkinGroupLootHistoryFrame()
    if lootHistorySkinned then return end

    local HistoryFrame = _G.GroupLootHistoryFrame
    if not HistoryFrame then return end

    local db = GetDB()
    local bgColor, borderColor, textColor = GetThemeColors()


    if HistoryFrame.NineSlice then
        HistoryFrame.NineSlice:SetAlpha(0)
    end
    if HistoryFrame.Bg then
        HistoryFrame.Bg:SetAlpha(0)
    end


    if not HistoryFrame.preyBackdrop then
        HistoryFrame.preyBackdrop = CreateFrame("Frame", nil, HistoryFrame, "BackdropTemplate")
        HistoryFrame.preyBackdrop:SetAllPoints()
        HistoryFrame.preyBackdrop:SetFrameLevel(HistoryFrame:GetFrameLevel())
        HistoryFrame.preyBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
    end
    HistoryFrame.preyBackdrop:SetBackdropColor(unpack(bgColor))
    HistoryFrame.preyBackdrop:SetBackdropBorderColor(unpack(borderColor))


    local Timer = HistoryFrame.Timer
    if Timer then
        if Timer.Background then Timer.Background:SetAlpha(0) end
        if Timer.Border then Timer.Border:SetAlpha(0) end

        if Timer.Fill then
            Timer.Fill:SetTexture(LSM:Fetch("statusbar", "Prey") or "Interface\\TargetingFrame\\UI-StatusBar")
            Timer.Fill:SetVertexColor(borderColor[1], borderColor[2], borderColor[3], 1)
        end


        if not Timer.preyBg then
            Timer.preyBg = Timer:CreateTexture(nil, "BACKGROUND")
            Timer.preyBg:SetAllPoints()
            Timer.preyBg:SetColorTexture(0, 0, 0, 0.5)
        end
    end


    local Dropdown = HistoryFrame.EncounterDropdown
    if Dropdown then

        if Dropdown.NineSlice then Dropdown.NineSlice:SetAlpha(0) end
    end


    if HistoryFrame.ClosePanelButton then
        local closeBtn = HistoryFrame.ClosePanelButton

        if closeBtn:GetNormalTexture() then
            closeBtn:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8)
        end
    end


    local ResizeButton = HistoryFrame.ResizeButton
    if ResizeButton then
        if ResizeButton.NineSlice then ResizeButton.NineSlice:SetAlpha(0) end

        if not ResizeButton.preyBackdrop then
            ResizeButton.preyBackdrop = CreateFrame("Frame", nil, ResizeButton, "BackdropTemplate")
            ResizeButton.preyBackdrop:SetAllPoints()
            ResizeButton.preyBackdrop:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            ResizeButton.preyBackdrop:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], 0.8)
            ResizeButton.preyBackdrop:SetBackdropBorderColor(unpack(borderColor))


            ResizeButton.preyText = ResizeButton:CreateFontString(nil, "OVERLAY")
            ResizeButton.preyText:SetFont(LSM:Fetch("font", GetGeneralFont()), 12, "OUTLINE")
            ResizeButton.preyText:SetPoint("CENTER")
            ResizeButton.preyText:SetText("v v v")
            ResizeButton.preyText:SetTextColor(unpack(textColor))
        end
    end


    if HistoryFrame.ScrollBox then
        hooksecurefunc(HistoryFrame.ScrollBox, "Update", HandleLootHistoryScrollUpdate)

        HandleLootHistoryScrollUpdate(HistoryFrame.ScrollBox)
    end


    hooksecurefunc(HistoryFrame, "Show", function()
        Loot:ApplyLootHistoryTheme()
    end)

    lootHistorySkinned = true
end


function Loot:ApplyLootHistoryTheme()
    local HistoryFrame = _G.GroupLootHistoryFrame
    if not HistoryFrame then return end

    local db = GetDB()
    local enabled = db.lootResults and db.lootResults.enabled ~= false


    if not enabled then
        if HistoryFrame.preyBackdrop then
            HistoryFrame.preyBackdrop:Hide()
        end
        if HistoryFrame.NineSlice then
            HistoryFrame.NineSlice:SetAlpha(1)
        end
        if HistoryFrame.Bg then
            HistoryFrame.Bg:SetAlpha(1)
        end
        if HistoryFrame.Timer then
            if HistoryFrame.Timer.Background then HistoryFrame.Timer.Background:SetAlpha(1) end
            if HistoryFrame.Timer.Border then HistoryFrame.Timer.Border:SetAlpha(1) end
            if HistoryFrame.Timer.preyBg then HistoryFrame.Timer.preyBg:Hide() end
        end
        if HistoryFrame.ResizeButton and HistoryFrame.ResizeButton.preyBackdrop then
            HistoryFrame.ResizeButton.preyBackdrop:Hide()
            if HistoryFrame.ResizeButton.NineSlice then
                HistoryFrame.ResizeButton.NineSlice:SetAlpha(1)
            end
            if HistoryFrame.ResizeButton.preyText then
                HistoryFrame.ResizeButton.preyText:Hide()
            end
        end
        return
    end


    if not HistoryFrame.preyBackdrop then return end

    local bgColor, borderColor, textColor = GetThemeColors()


    HistoryFrame.preyBackdrop:Show()
    if HistoryFrame.NineSlice then HistoryFrame.NineSlice:SetAlpha(0) end
    if HistoryFrame.Bg then HistoryFrame.Bg:SetAlpha(0) end

    HistoryFrame.preyBackdrop:SetBackdropColor(unpack(bgColor))
    HistoryFrame.preyBackdrop:SetBackdropBorderColor(unpack(borderColor))

    if HistoryFrame.Timer then
        if HistoryFrame.Timer.Background then HistoryFrame.Timer.Background:SetAlpha(0) end
        if HistoryFrame.Timer.Border then HistoryFrame.Timer.Border:SetAlpha(0) end
        if HistoryFrame.Timer.preyBg then HistoryFrame.Timer.preyBg:Show() end
        if HistoryFrame.Timer.Fill then
            HistoryFrame.Timer.Fill:SetVertexColor(borderColor[1], borderColor[2], borderColor[3], 1)
        end
    end

    if HistoryFrame.ResizeButton and HistoryFrame.ResizeButton.preyBackdrop then
        HistoryFrame.ResizeButton.preyBackdrop:Show()
        if HistoryFrame.ResizeButton.NineSlice then
            HistoryFrame.ResizeButton.NineSlice:SetAlpha(0)
        end
        HistoryFrame.ResizeButton.preyBackdrop:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], 0.8)
        HistoryFrame.ResizeButton.preyBackdrop:SetBackdropBorderColor(unpack(borderColor))
        if HistoryFrame.ResizeButton.preyText then
            HistoryFrame.ResizeButton.preyText:Show()
            HistoryFrame.ResizeButton.preyText:SetTextColor(unpack(textColor))
        end
    end
end


function Loot:ApplyResultsTheme()
    self:ApplyLootHistoryTheme()
end


local function DisableBlizzardLoot()
    local db = GetDB()


    if db.loot and db.loot.enabled then
        LootFrame:UnregisterAllEvents()
        LootFrame:Hide()
    end


    if db.lootRoll and db.lootRoll.enabled then

        if GroupLootContainer then
            GroupLootContainer:UnregisterAllEvents()
            GroupLootContainer:Hide()

            if not GroupLootContainer._preyHooked then
                hooksecurefunc(GroupLootContainer, "Show", function(self)
                    self:Hide()
                end)
                GroupLootContainer._preyHooked = true
            end
        end


        local numRollFrames = NUM_GROUP_LOOT_FRAMES or 4
        for i = 1, numRollFrames do
            local frame = rawget(_G, "GroupLootFrame"..i)
            if frame then
                frame:UnregisterAllEvents()
                frame:Hide()
                if not frame._preyHooked then
                    hooksecurefunc(frame, "Show", function(self)
                        self:Hide()
                    end)
                    frame._preyHooked = true
                end
            end
        end
    end
end

local function EnableBlizzardLoot()

    LootFrame:RegisterEvent("LOOT_OPENED")
    LootFrame:RegisterEvent("LOOT_SLOT_CLEARED")
    LootFrame:RegisterEvent("LOOT_SLOT_CHANGED")
    LootFrame:RegisterEvent("LOOT_CLOSED")


    UIParent:RegisterEvent("START_LOOT_ROLL")
    UIParent:RegisterEvent("CANCEL_LOOT_ROLL")
    if GroupLootContainer then
        GroupLootContainer:SetAlpha(1)
    end
end

function Loot:Initialize()
    local db = GetDB()


    if not lootFrame then
        lootFrame = CreateLootWindow()
    end

    if not rollAnchor then
        rollAnchor = CreateRollAnchor()
    end


    if db.lootRoll and db.lootRoll.position and db.lootRoll.position.point then
        rollAnchor:ClearAllPoints()
        rollAnchor:SetPoint(db.lootRoll.position.point, UIParent,
                           db.lootRoll.position.relPoint or "TOP",
                           db.lootRoll.position.x or 0,
                           db.lootRoll.position.y or -200)
    end


    DisableBlizzardLoot()


    if db.lootResults and db.lootResults.enabled ~= false then


        local function TrySkinLootHistory()
            if GroupLootHistoryFrame and not lootHistorySkinned then
                SkinGroupLootHistoryFrame()

                Loot:ApplyLootHistoryTheme()
                return true
            end
            return false
        end


        if not TrySkinLootHistory() then

            local checkFrame = CreateFrame("Frame")
            checkFrame.elapsed = 0
            checkFrame:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = self.elapsed + elapsed
                if self.elapsed > 1 then
                    self.elapsed = 0
                    if TrySkinLootHistory() then
                        self:SetScript("OnUpdate", nil)
                    end
                end
            end)
        end
    end


    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("LOOT_READY")
    eventFrame:RegisterEvent("LOOT_OPENED")
    eventFrame:RegisterEvent("LOOT_SLOT_CLEARED")
    eventFrame:RegisterEvent("LOOT_CLOSED")
    eventFrame:RegisterEvent("START_LOOT_ROLL")
    eventFrame:RegisterEvent("CANCEL_LOOT_ROLL")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        local db = GetDB()

        if event == "LOOT_READY" or event == "LOOT_OPENED" then
            if db.loot and db.loot.enabled then
                OnLootOpened(...)
            end
        elseif event == "LOOT_SLOT_CLEARED" then
            if db.loot and db.loot.enabled then
                OnLootSlotCleared(...)
            end
        elseif event == "LOOT_CLOSED" then
            if db.loot and db.loot.enabled then
                OnLootClosed()
            end
        elseif event == "START_LOOT_ROLL" then
            if db.lootRoll and db.lootRoll.enabled then
                StartRoll(...)
            end
        elseif event == "CANCEL_LOOT_ROLL" then
            if db.lootRoll and db.lootRoll.enabled then
                CancelRoll(...)
            end
        end
    end)

    self.eventFrame = eventFrame
end

function Loot:Refresh()
    local db = GetDB()


    if lootFrame and db.loot and db.loot.position and db.loot.position.point then
        lootFrame:ClearAllPoints()
        lootFrame:SetPoint(db.loot.position.point, UIParent,
                          db.loot.position.relPoint or "CENTER",
                          db.loot.position.x or 0,
                          db.loot.position.y or 100)
    end


    if rollAnchor and db.lootRoll and db.lootRoll.position and db.lootRoll.position.point then
        rollAnchor:ClearAllPoints()
        rollAnchor:SetPoint(db.lootRoll.position.point, UIParent,
                           db.lootRoll.position.relPoint or "TOP",
                           db.lootRoll.position.x or 0,
                           db.lootRoll.position.y or -200)
    end


    RepositionAllRolls()


    if db.loot and db.loot.enabled then
        LootFrame:UnregisterAllEvents()
        LootFrame:Hide()
    else
        EnableBlizzardLoot()
    end

    if db.lootRoll and db.lootRoll.enabled then
        UIParent:UnregisterEvent("START_LOOT_ROLL")
        UIParent:UnregisterEvent("CANCEL_LOOT_ROLL")
    else
        UIParent:RegisterEvent("START_LOOT_ROLL")
        UIParent:RegisterEvent("CANCEL_LOOT_ROLL")
    end
end


function Loot:ApplyLootTheme()
    if not lootFrame then return end
    local bgColor, borderColor, textColor = GetThemeColors()

    lootFrame:SetBackdropColor(unpack(bgColor))
    lootFrame:SetBackdropBorderColor(unpack(borderColor))
    lootFrame.header:SetTextColor(unpack(textColor))


    for i = 1, MAX_LOOT_SLOTS do
        local slot = lootFrame.slots[i]
        if slot then
            slot:GetHighlightTexture():SetVertexColor(borderColor[1], borderColor[2], borderColor[3], 0.2)
        end
    end
end


function Loot:ApplyRollTheme()
    local bgColor, borderColor, textColor = GetThemeColors()

    for i = 1, MAX_ROLL_FRAMES do
        local frame = rollFramePool[i]
        if frame then
            frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], 0.95)
            frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 0.3)
            frame.timer:SetStatusBarColor(borderColor[1], borderColor[2], borderColor[3], 1)
        end
    end
end


function Loot:RefreshColors()

    self:ApplyLootTheme()
    self:ApplyRollTheme()
    self:ApplyLootHistoryTheme()
end


_G.PreyUI_RefreshLootColors = function()
    if PREYCore and PREYCore.Loot then
        PREYCore.Loot:RefreshColors()
    end
end


local lootPreviewActive = false
local rollPreviewActive = false


function Loot:ShowLootPreview()
    if not lootFrame then
        lootFrame = CreateLootWindow()
    end

    local db = GetDB()


    self:ApplyLootTheme()


    if db.loot and db.loot.position and db.loot.position.point then
        lootFrame:ClearAllPoints()
        lootFrame:SetPoint(db.loot.position.point, UIParent,
                          db.loot.position.relPoint or "CENTER",
                          db.loot.position.x or 0,
                          db.loot.position.y or 100)
    else
        lootFrame:ClearAllPoints()
        lootFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end


    lootFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    lootFrame._previewMode = true


    local testItems = {
        { texture = "Interface\\Icons\\INV_Misc_Gem_Diamond_02", name = "Test Epic Item", quality = 4 },
        { texture = "Interface\\Icons\\INV_Misc_Coin_02", name = "Gold Coin", quality = 1, count = 47 },
        { texture = "Interface\\Icons\\INV_Misc_Herb_Icethorn", name = "Test Herb", quality = 2, count = 5 },
    }

    for i, item in ipairs(testItems) do
        local slot = lootFrame.slots[i]
        slot.slotIndex = nil
        slot.icon:SetTexture(item.texture)
        slot.name:SetText(item.name)
        local r, g, b = GetItemQualityColor(item.quality)
        slot.iconBorder:SetBackdropBorderColor(r, g, b, 1)
        slot.name:SetTextColor(r, g, b)
        if item.count and item.count > 1 then
            slot.count:SetText(item.count)
            slot.count:Show()
        else
            slot.count:Hide()
        end
        slot.questIcon:Hide()
        slot.transmogMarker:Hide()
        slot:Show()
    end


    for i = #testItems + 1, MAX_LOOT_SLOTS do
        lootFrame.slots[i]:Hide()
    end


    local height = 40 + (#testItems * (SLOT_HEIGHT + SLOT_SPACING))
    lootFrame:SetHeight(height)
    lootFrame:Show()

    lootPreviewActive = true
end


function Loot:HideLootPreview()
    if lootFrame then
        lootFrame:Hide()

        lootFrame:SetScript("OnDragStart", function(self)
            if IsShiftKeyDown() then
                self:StartMoving()
            end
        end)
        lootFrame._previewMode = false
    end
    lootPreviewActive = false
end


function Loot:IsLootPreviewActive()
    return lootPreviewActive
end


local PREVIEW_ROLL_ITEMS = {
    { texture = "Interface\\Icons\\INV_Sword_39", name = "Blade of Eternal Night", quality = 4, timer = 0.85 },
    { texture = "Interface\\Icons\\INV_Helmet_25", name = "Crown of the Fallen King", quality = 4, timer = 0.7 },
    { texture = "Interface\\Icons\\INV_Chest_Chain_15", name = "Burnished Chestguard", quality = 3, timer = 0.55 },
    { texture = "Interface\\Icons\\INV_Boots_Plate_08", name = "Boots of Striding", quality = 3, timer = 0.4 },
    { texture = "Interface\\Icons\\INV_Gauntlets_29", name = "Gauntlets of the Ancients", quality = 4, timer = 0.3 },
    { texture = "Interface\\Icons\\INV_Belt_13", name = "Girdle of Fortitude", quality = 2, timer = 0.25 },
    { texture = "Interface\\Icons\\INV_Misc_Cape_18", name = "Cloak of Shadows", quality = 3, timer = 0.15 },
    { texture = "Interface\\Icons\\INV_Jewelry_Ring_36", name = "Band of Eternal Champions", quality = 4, timer = 0.1 },
}


function Loot:ShowRollPreview()
    if not rollAnchor then
        rollAnchor = CreateRollAnchor()
    end

    local db = GetDB()
    local growDirection = (db.lootRoll and db.lootRoll.growDirection) or "DOWN"
    local spacing = (db.lootRoll and db.lootRoll.spacing) or 4
    local maxFrames = (db.lootRoll and db.lootRoll.maxFrames) or 4


    if db.lootRoll and db.lootRoll.position and db.lootRoll.position.point then
        rollAnchor:ClearAllPoints()
        rollAnchor:SetPoint(db.lootRoll.position.point, UIParent,
                           db.lootRoll.position.relPoint or "TOP",
                           db.lootRoll.position.x or 0,
                           db.lootRoll.position.y or -200)
    end

    local bgColor, borderColor, textColor = GetThemeColors()


    self._previewMaxFrames = maxFrames


    for i = 1, maxFrames do
        local item = PREVIEW_ROLL_ITEMS[i] or PREVIEW_ROLL_ITEMS[1]

        if not rollFramePool[i] then
            rollFramePool[i] = CreateRollFrame(i)
        end
        local frame = rollFramePool[i]


        frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], 0.95)
        frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 0.3)

        frame.rollID = nil
        frame.icon:SetTexture(item.texture)
        frame.name:SetText(item.name)
        local r, g, b = GetItemQualityColor(item.quality)
        frame.iconBorder:SetBackdropBorderColor(r, g, b, 1)
        frame.name:SetTextColor(r, g, b)


        local tint = QUALITY_BG_TINTS[item.quality] or QUALITY_BG_TINTS[1]
        frame.qualityTint:SetColorTexture(tint[1], tint[2], tint[3], tint[4])


        frame.timer:SetValue(item.timer)
        frame.timer:SetStatusBarColor(borderColor[1], borderColor[2], borderColor[3], 1)
        frame.timer:SetScript("OnUpdate", nil)


        if i == 1 then
            frame:SetMovable(true)
            frame:EnableMouse(true)
            frame:RegisterForDrag("LeftButton")
            frame:SetScript("OnDragStart", function(self)
                self:StartMoving()
            end)
            frame:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()

                local point, _, relPoint, x, y = self:GetPoint()
                local db = GetDB()
                if db.lootRoll then
                    db.lootRoll.position = { point = point, relPoint = relPoint, x = x, y = y }
                end

                if rollAnchor then
                    rollAnchor:ClearAllPoints()
                    rollAnchor:SetPoint(point, UIParent, relPoint, x, y + ROLL_FRAME_HEIGHT)
                end

                local previewCount = Loot._previewMaxFrames or 4
                for j = 2, previewCount do
                    if rollFramePool[j] then
                        rollFramePool[j]:ClearAllPoints()
                        if growDirection == "UP" then
                            rollFramePool[j]:SetPoint("BOTTOM", rollAnchor, "TOP", 0, ((j-1) * (ROLL_FRAME_HEIGHT + spacing)))
                        else
                            rollFramePool[j]:SetPoint("TOP", rollAnchor, "BOTTOM", 0, -((j-1) * (ROLL_FRAME_HEIGHT + spacing)))
                        end
                    end
                end
            end)
        end


        frame:ClearAllPoints()
        if growDirection == "UP" then
            frame:SetPoint("BOTTOM", rollAnchor, "TOP", 0, ((i-1) * (ROLL_FRAME_HEIGHT + spacing)))
        else
            frame:SetPoint("TOP", rollAnchor, "BOTTOM", 0, -((i-1) * (ROLL_FRAME_HEIGHT + spacing)))
        end
        frame:Show()
    end

    rollPreviewActive = true
end


function Loot:HideRollPreview()

    for i = 1, MAX_ROLL_FRAMES do
        if rollFramePool[i] then
            rollFramePool[i]:Hide()

            if i == 1 then
                rollFramePool[i]:SetMovable(false)
                rollFramePool[i]:RegisterForDrag()
                rollFramePool[i]:SetScript("OnDragStart", nil)
                rollFramePool[i]:SetScript("OnDragStop", nil)
            end
        end
    end
    self._previewMaxFrames = nil
    rollPreviewActive = false
end


function Loot:IsRollPreviewActive()
    return rollPreviewActive
end


local editModeActive = false


function Loot:ToggleMovers()
    if editModeActive then
        self:DisableEditMode()
    else
        self:EnableEditMode()
    end
end
local EDIT_BORDER_COLOR = { 0.820, 0.180, 0.220, 1 }
local EDIT_BORDER_SIZE = 2


local function CreateEditModeBorder(frame)
    if frame.editBorder then return frame.editBorder end

    local border = {}


    border.top = frame:CreateTexture(nil, "OVERLAY")
    border.top:SetColorTexture(unpack(EDIT_BORDER_COLOR))
    border.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    border.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    border.top:SetHeight(EDIT_BORDER_SIZE)


    border.bottom = frame:CreateTexture(nil, "OVERLAY")
    border.bottom:SetColorTexture(unpack(EDIT_BORDER_COLOR))
    border.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border.bottom:SetHeight(EDIT_BORDER_SIZE)


    border.left = frame:CreateTexture(nil, "OVERLAY")
    border.left:SetColorTexture(unpack(EDIT_BORDER_COLOR))
    border.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    border.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border.left:SetWidth(EDIT_BORDER_SIZE)


    border.right = frame:CreateTexture(nil, "OVERLAY")
    border.right:SetColorTexture(unpack(EDIT_BORDER_COLOR))
    border.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    border.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border.right:SetWidth(EDIT_BORDER_SIZE)

    frame.editBorder = border
    return border
end

local function ShowEditModeBorder(frame)
    if not frame.editBorder then
        CreateEditModeBorder(frame)
    end
    for _, tex in pairs(frame.editBorder) do
        tex:Show()
    end
end

local function HideEditModeBorder(frame)
    if frame.editBorder then
        for _, tex in pairs(frame.editBorder) do
            tex:Hide()
        end
    end
end

function Loot:EnableEditMode()
    if editModeActive then return end
    editModeActive = true


    self:ShowLootPreview()
    if lootFrame then

        ShowEditModeBorder(lootFrame)


        if not lootFrame.editLabel then
            local label = lootFrame:CreateFontString(nil, "OVERLAY")
            label:SetFont(LSM:Fetch("font", GetGeneralFont()), 10, "OUTLINE")
            label:SetPoint("BOTTOM", lootFrame, "TOP", 0, 4)
            label:SetText("PREY Loot Window")
            label:SetTextColor(0.2, 0.8, 0.8)
            lootFrame.editLabel = label
        end
        lootFrame.editLabel:Show()
    end


    self:ShowRollPreview()
    local rollFrame = rollFramePool[1]
    if rollFrame then
        ShowEditModeBorder(rollFrame)

        if not rollFrame.editLabel then
            local label = rollFrame:CreateFontString(nil, "OVERLAY")
            label:SetFont(LSM:Fetch("font", GetGeneralFont()), 10, "OUTLINE")
            label:SetPoint("BOTTOM", rollFrame, "TOP", 0, 4)
            label:SetText("PREY Roll Frame")
            label:SetTextColor(0.2, 0.8, 0.8)
            rollFrame.editLabel = label
        end
        rollFrame.editLabel:Show()
    end
end

function Loot:DisableEditMode()
    if not editModeActive then return end
    editModeActive = false


    if lootFrame then
        HideEditModeBorder(lootFrame)
        if lootFrame.editLabel then lootFrame.editLabel:Hide() end
    end

    local rollFrame = rollFramePool[1]
    if rollFrame then
        HideEditModeBorder(rollFrame)
        if rollFrame.editLabel then rollFrame.editLabel:Hide() end
    end


    self:HideLootPreview()
    self:HideRollPreview()
end

function Loot:IsEditModeActive()
    return editModeActive
end


function Loot:HookBlizzardEditMode()
    if not EditModeManagerFrame then return end
    if self._editModeHooked then return end
    self._editModeHooked = true


    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
        if InCombatLockdown() then return end
        self:DisableEditMode()
    end)
end


local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)

    C_Timer.After(0.5, function()
        local db = GetDB()
        if db.loot or db.lootRoll then
            Loot:Initialize()

            Loot:HookBlizzardEditMode()
        end
    end)
    self:UnregisterEvent("PLAYER_LOGIN")
end)
