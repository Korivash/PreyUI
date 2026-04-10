local ADDON_NAME, ns = ...
local PREYCore = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")
local LibDBIcon = LibStub("LibDBIcon-1.0", true)


local Minimap_Module = {}
PREYCore.Minimap = Minimap_Module


local Minimap = Minimap
local MinimapCluster = MinimapCluster
local UIParent = UIParent


local backdropFrame, backdrop, mask
local clockFrame, clockText
local coordsFrame, coordsText
local zoneTextFrame, zoneTextFont
local minimapTooltip


local datatextFrame


local cachedSettings = nil
local clockTicker = nil
local coordsTicker = nil


do
    local function EnsureLayoutMethods()

        if Minimap and not Minimap.Layout then
            Minimap.Layout = function() end
        end

        if MinimapCluster and MinimapCluster.IndicatorFrame and not MinimapCluster.IndicatorFrame.Layout then
            MinimapCluster.IndicatorFrame.Layout = function() end
        end
    end


    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGIN")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(self, event)
        EnsureLayoutMethods()
    end)


    EnsureLayoutMethods()
end


local function GetSettings()
    if cachedSettings then return cachedSettings end
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then
        return nil
    end
    cachedSettings = PREYCore.db.profile.minimap
    return cachedSettings
end

local function InvalidateSettingsCache()
    cachedSettings = nil
end

local function GetClassColor()
    local _, class = UnitClass("player")
    local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
    return color
end


local function SetMinimapShape(shape)
    if shape == "SQUARE" then
        Minimap:SetMaskTexture("Interface\\BUTTONS\\WHITE8X8")
        if mask then
            mask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
        end
        _G.GetMinimapShape = function() return "SQUARE" end


        if HybridMinimap then
            HybridMinimap.MapCanvas:SetUseMaskTexture(false)
            HybridMinimap.CircleMask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
            HybridMinimap.MapCanvas:SetUseMaskTexture(true)
        end


        Minimap:SetArchBlobRingScalar(0)
        Minimap:SetArchBlobRingAlpha(0)
        Minimap:SetQuestBlobRingScalar(0)
        Minimap:SetQuestBlobRingAlpha(0)
    else

        Minimap:SetMaskTexture("Interface\\MINIMAP\\UI-Minimap-Background")
        if mask then
            mask:SetTexture("Interface\\MINIMAP\\UI-Minimap-Background")
        end
        _G.GetMinimapShape = function() return "ROUND" end

        if HybridMinimap then
            HybridMinimap.MapCanvas:SetUseMaskTexture(false)
            HybridMinimap.CircleMask:SetTexture("Interface\\MINIMAP\\UI-Minimap-Background")
            HybridMinimap.MapCanvas:SetUseMaskTexture(true)
        end
    end


    if LibDBIcon then
        local buttons = LibDBIcon:GetButtonList()
        for i = 1, #buttons do
            LibDBIcon:Refresh(buttons[i])
        end
    end
end


local function CreateBackdrop()
    if backdropFrame then return end

    backdropFrame = CreateFrame("Frame", "PREY_MinimapBackdrop", Minimap)
    backdropFrame:SetFrameStrata("BACKGROUND")
    backdropFrame:SetFrameLevel(1)
    backdropFrame:SetFixedFrameStrata(true)
    backdropFrame:SetFixedFrameLevel(true)
    backdropFrame:Show()

    backdrop = backdropFrame:CreateTexture(nil, "BACKGROUND")
    backdrop:SetPoint("CENTER", Minimap, "CENTER")

    mask = backdropFrame:CreateMaskTexture()
    mask:SetAllPoints(backdrop)
    mask:SetParent(backdropFrame)
    backdrop:AddMaskTexture(mask)
end

local function UpdateBackdrop()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end
    if not backdrop then CreateBackdrop() end


    local fullSize = settings.size + (settings.borderSize * 2)
    backdrop:SetSize(fullSize, fullSize)


    local r, g, b, a = unpack(settings.borderColor)
    if settings.useClassColorBorder then
        local color = GetClassColor()
        if color then
            r, g, b = color.r, color.g, color.b
        end
    end
    backdrop:SetColorTexture(r, g, b, a)


    if settings.shape == "SQUARE" then
        mask:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    else
        mask:SetTexture("Interface\\MINIMAP\\UI-Minimap-Background")
    end
end


local function GetDatatextSettings()
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then
        return nil
    end
    return PREYCore.db.profile.datatext
end

local function ColorWrap(text, r, g, b)
    return string.format("|cff%02x%02x%02x%s|r", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255), text)
end

local function FormatGold(copper)
    local gold = math.floor(copper / 10000)
    local goldStr = tostring(gold)
    if gold >= 1000 then
        goldStr = string.format("%d,%03d", math.floor(gold / 1000), gold % 1000)
    end
    if gold >= 1000000 then
        local millions = math.floor(gold / 1000000)
        local thousands = math.floor((gold % 1000000) / 1000)
        goldStr = string.format("%d,%03d,%03d", millions, thousands, gold % 1000)
    end
    return goldStr .. "g"
end


local function CreateDatatextPanel()
    if datatextFrame then return end


    datatextFrame = CreateFrame("Frame", "PREY_DatatextPanel", UIParent)
    datatextFrame:SetFrameStrata("LOW")
    datatextFrame:SetFrameLevel(100)


    datatextFrame.borderLeft = datatextFrame:CreateTexture(nil, "BACKGROUND")
    datatextFrame.borderRight = datatextFrame:CreateTexture(nil, "BACKGROUND")
    datatextFrame.borderTop = datatextFrame:CreateTexture(nil, "BACKGROUND")
    datatextFrame.borderBottom = datatextFrame:CreateTexture(nil, "BACKGROUND")


    datatextFrame.bg = datatextFrame:CreateTexture(nil, "BACKGROUND")
    datatextFrame.bg:SetAllPoints()


    datatextFrame.slots = {}
    for i = 1, 3 do
        local slot = CreateFrame("Button", nil, datatextFrame)
        slot:EnableMouse(true)
        slot:RegisterForClicks("AnyUp")


        slot.text = slot:CreateFontString(nil, "OVERLAY")

        slot.text:SetPoint("LEFT", slot, "LEFT", 1, 0)
        slot.text:SetPoint("RIGHT", slot, "RIGHT", -1, 0)
        slot.text:SetJustifyH("CENTER")
        slot.text:SetWordWrap(false)
        slot.index = i

        datatextFrame.slots[i] = slot
    end
end


local function RefreshDatatextSlots()
    if not datatextFrame or not datatextFrame.slots then return end
    if not PREYCore or not PREYCore.Datatexts then return end

    local dtSettings = GetDatatextSettings()
    if not dtSettings then return end

    local slots = dtSettings.slots or {"time", "friends", "guild"}


    local generalFont = "Prey"
    local generalOutline = "OUTLINE"
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        local general = PREYCore.db.profile.general
        generalFont = general.font or "Prey"
        generalOutline = general.fontOutline or "OUTLINE"
    end
    local fontPath = LSM:Fetch("font", generalFont) or "Fonts\\FRIZQT__.TTF"
    local fontSize = dtSettings.fontSize or 12


    local activeCount = 0
    for i = 1, 3 do
        local datatextID = slots[i]
        if datatextID and datatextID ~= "" then
            activeCount = activeCount + 1
        end
    end


    local panelWidth = datatextFrame:GetWidth()
    local slotWidth = panelWidth / math.max(1, activeCount)
    local slotHeight = datatextFrame:GetHeight()


    local xPos = 0
    for i, slot in ipairs(datatextFrame.slots) do
        local datatextID = slots[i]
        local slotConfig = dtSettings["slot" .. i] or {}


        if slot.datatextInstance then
            PREYCore.Datatexts:DetachFromSlot(slot)
        end


        PREYCore:SafeSetFont(slot.text, fontPath, fontSize, generalOutline)

        if datatextID and datatextID ~= "" then

            slot:SetSize(slotWidth, slotHeight)
            slot:ClearAllPoints()

            local xOff = slotConfig.xOffset or 0
            local yOff = slotConfig.yOffset or 0
            slot:SetPoint("LEFT", datatextFrame, "LEFT", xPos + xOff, yOff)
            slot:Show()
            xPos = xPos + slotWidth

            slot.text:SetTextColor(1, 1, 1, 1)


            slot.shortLabel = slotConfig.shortLabel or false
            slot.noLabel = slotConfig.noLabel or false


            PREYCore.Datatexts:AttachToSlot(slot, datatextID, dtSettings)
        else

            slot:Hide()
            slot.text:SetText("")
        end
    end
end

local function UpdateDatatextPanel()
    local minimapSettings = GetSettings()
    local dtSettings = GetDatatextSettings()

    if not minimapSettings or not minimapSettings.enabled then return end
    if not dtSettings or not dtSettings.enabled then
        if datatextFrame then datatextFrame:Hide() end
        return
    end

    if not datatextFrame then CreateDatatextPanel() end

    local minimapSize = minimapSettings.size or 160
    local minimapScale = minimapSettings.scale or 1.0
    local minimapBorderSize = minimapSettings.borderSize or 3
    local dtBorderSize = dtSettings.borderSize or 2
    local dtBorderColor = dtSettings.borderColor or {0, 0, 0, 1}
    local dtHeight = dtSettings.height or 22
    local yOffset = dtSettings.offsetY or 0
    local bgAlpha = (dtSettings.bgOpacity or 60) / 100


    datatextFrame:SetSize(minimapSize, dtHeight)


    if minimapScale ~= 1.0 then
        datatextFrame:SetScale(minimapScale)
    elseif datatextFrame:GetScale() ~= 1 then
        datatextFrame:SetScale(1)
    end


    datatextFrame:ClearAllPoints()
    datatextFrame:SetPoint("TOP", Minimap, "BOTTOM", 0, -(minimapBorderSize + yOffset))


    datatextFrame.borderLeft:ClearAllPoints()
    datatextFrame.borderLeft:SetPoint("TOPRIGHT", datatextFrame, "TOPLEFT", 0, dtBorderSize)
    datatextFrame.borderLeft:SetPoint("BOTTOMRIGHT", datatextFrame, "BOTTOMLEFT", 0, -dtBorderSize)
    datatextFrame.borderLeft:SetWidth(dtBorderSize)
    datatextFrame.borderLeft:SetColorTexture(unpack(dtBorderColor))


    datatextFrame.borderRight:ClearAllPoints()
    datatextFrame.borderRight:SetPoint("TOPLEFT", datatextFrame, "TOPRIGHT", 0, dtBorderSize)
    datatextFrame.borderRight:SetPoint("BOTTOMLEFT", datatextFrame, "BOTTOMRIGHT", 0, -dtBorderSize)
    datatextFrame.borderRight:SetWidth(dtBorderSize)
    datatextFrame.borderRight:SetColorTexture(unpack(dtBorderColor))


    datatextFrame.borderTop:ClearAllPoints()
    datatextFrame.borderTop:SetPoint("BOTTOMLEFT", datatextFrame, "TOPLEFT", 0, 0)
    datatextFrame.borderTop:SetPoint("BOTTOMRIGHT", datatextFrame, "TOPRIGHT", 0, 0)
    datatextFrame.borderTop:SetHeight(dtBorderSize)
    datatextFrame.borderTop:SetColorTexture(unpack(dtBorderColor))


    datatextFrame.borderBottom:ClearAllPoints()
    datatextFrame.borderBottom:SetPoint("TOPLEFT", datatextFrame, "BOTTOMLEFT", 0, 0)
    datatextFrame.borderBottom:SetPoint("TOPRIGHT", datatextFrame, "BOTTOMRIGHT", 0, 0)
    datatextFrame.borderBottom:SetHeight(dtBorderSize)
    datatextFrame.borderBottom:SetColorTexture(unpack(dtBorderColor))


    local showBorder = dtBorderSize > 0
    datatextFrame.borderLeft:SetShown(showBorder)
    datatextFrame.borderRight:SetShown(showBorder)
    datatextFrame.borderTop:SetShown(showBorder)
    datatextFrame.borderBottom:SetShown(showBorder)


    datatextFrame.bg:SetColorTexture(0, 0, 0, bgAlpha)

    datatextFrame:Show()


    RefreshDatatextSlots()
end


local function CreateClock()
    if clockFrame then return end

    clockFrame = CreateFrame("Button", nil, Minimap)
    clockText = clockFrame:CreateFontString(nil, "OVERLAY")
    clockText:SetAllPoints(clockFrame)


    if TimeManagerClockButton then
        TimeManagerClockButton:SetParent(CreateFrame("Frame"))
        TimeManagerClockButton:Hide()
    end
    if TimeManagerClockTicker then
        TimeManagerClockTicker:SetParent(CreateFrame("Frame"))
        TimeManagerClockTicker:Hide()
    end

    clockFrame:EnableMouse(true)
    clockFrame:RegisterForClicks("AnyUp")

    clockFrame:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            ToggleCalendar()
        elseif button == "RightButton" then
            if TimeManagerFrame then
                if TimeManagerFrame:IsShown() then
                    TimeManagerFrame:Hide()
                else
                    TimeManagerFrame:Show()
                end
            end
        end
    end)

    clockFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(TIMEMANAGER_TOOLTIP_TITLE, 1, 1, 1)
        GameTooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_REALMTIME, GameTime_GetGameTime(true), 0.8, 0.8, 0.8, 1, 1, 1)
        GameTooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_LOCALTIME, GameTime_GetLocalTime(true), 0.8, 0.8, 0.8, 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Open Calendar", 0.2, 1, 0.2)
        GameTooltip:AddLine("|cffFFFFFFRight Click:|r Toggle Clock", 0.2, 1, 0.2)
        GameTooltip:Show()
    end)

    clockFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function UpdateClock()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end
    if not clockFrame then CreateClock() end

    local clockConfig = settings.clockConfig

    if not settings.showClock then
        clockFrame:Hide()
        return
    end

    clockFrame:Show()
    clockFrame:ClearAllPoints()
    clockFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", clockConfig.offsetX, clockConfig.offsetY)
    clockFrame:SetHeight(clockConfig.fontSize + 1)


    local flags = nil
    if clockConfig.monochrome and clockConfig.outline ~= "NONE" then
        flags = "MONOCHROME," .. clockConfig.outline
    elseif clockConfig.monochrome then
        flags = "MONOCHROME"
    elseif clockConfig.outline ~= "NONE" then
        flags = clockConfig.outline
    end

    local fontPath = LSM:Fetch("font", clockConfig.font) or "Fonts\\FRIZQT__.TTF"
    PREYCore:SafeSetFont(clockText, fontPath, clockConfig.fontSize, flags)
    clockText:SetJustifyH(clockConfig.align)


    local r, g, b, a = unpack(clockConfig.color)
    if clockConfig.useClassColor then
        local color = GetClassColor()
        if color then
            r, g, b = color.r, color.g, color.b
        end
    end
    clockText:SetTextColor(r, g, b, a)


    clockText:SetText("99:99")
    local width = clockText:GetUnboundedStringWidth()
    clockFrame:SetWidth(width + 5)
end

local function UpdateClockTime()
    if not clockFrame or not clockText then return end
    local settings = GetSettings()
    if not settings or not settings.showClock then return end

    local clockConfig = settings.clockConfig


    local currentFont = clockText:GetFont()
    if not currentFont then
        local fontPath = LSM:Fetch("font", clockConfig.font) or "Fonts\\FRIZQT__.TTF"
        local flags = nil
        if clockConfig.monochrome and clockConfig.outline ~= "NONE" then
            flags = "MONOCHROME," .. clockConfig.outline
        elseif clockConfig.monochrome then
            flags = "MONOCHROME"
        elseif clockConfig.outline ~= "NONE" then
            flags = clockConfig.outline
        end
        PREYCore:SafeSetFont(clockText, fontPath, clockConfig.fontSize, flags)
    end

    local hour, minute


    local useLocalTime = (clockConfig.timeFormat == "local")

    if useLocalTime then
        hour, minute = tonumber(date("%H")), tonumber(date("%M"))
    else
        hour, minute = GetGameTime()
    end

    if GetCVarBool("timeMgrUseMilitaryTime") then
        clockText:SetFormattedText(TIMEMANAGER_TICKER_24HOUR, hour, minute)
    else
        if hour == 0 then
            hour = 12
        elseif hour > 12 then
            hour = hour - 12
        end
        clockText:SetFormattedText(TIMEMANAGER_TICKER_12HOUR, hour, minute)
    end
end


local function CreateCoords()
    if coordsFrame then return end

    coordsFrame = CreateFrame("Frame", nil, Minimap)
    coordsText = coordsFrame:CreateFontString(nil, "OVERLAY")
    coordsText:SetAllPoints(coordsFrame)
end

local function UpdateCoords()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end
    if not coordsFrame then CreateCoords() end

    local coordsConfig = settings.coordsConfig

    if not settings.showCoords then
        coordsFrame:Hide()
        return
    end

    coordsFrame:Show()
    coordsFrame:ClearAllPoints()
    coordsFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", coordsConfig.offsetX, coordsConfig.offsetY)
    coordsFrame:SetHeight(coordsConfig.fontSize + 1)


    local flags = nil
    if coordsConfig.monochrome and coordsConfig.outline ~= "NONE" then
        flags = "MONOCHROME," .. coordsConfig.outline
    elseif coordsConfig.monochrome then
        flags = "MONOCHROME"
    elseif coordsConfig.outline ~= "NONE" then
        flags = coordsConfig.outline
    end

    local fontPath = LSM:Fetch("font", coordsConfig.font) or "Fonts\\FRIZQT__.TTF"
    PREYCore:SafeSetFont(coordsText, fontPath, coordsConfig.fontSize, flags)
    coordsText:SetJustifyH(coordsConfig.align)


    local r, g, b, a = unpack(coordsConfig.color)
    if coordsConfig.useClassColor then
        local color = GetClassColor()
        if color then
            r, g, b = color.r, color.g, color.b
        end
    end
    coordsText:SetTextColor(r, g, b, a)


    coordsText:SetFormattedText(settings.coordPrecision, 100.77, 100.77)
    local width = coordsText:GetUnboundedStringWidth()
    coordsFrame:SetWidth(width + 5)
end

local function UpdateCoordsPosition()
    if not coordsFrame or not coordsText then return end
    local settings = GetSettings()
    if not settings or not settings.showCoords then return end


    local coordsConfig = settings.coordsConfig
    local currentFont = coordsText:GetFont()
    if not currentFont then
        local fontPath = LSM:Fetch("font", coordsConfig.font) or "Fonts\\FRIZQT__.TTF"
        local flags = nil
        if coordsConfig.monochrome and coordsConfig.outline ~= "NONE" then
            flags = "MONOCHROME," .. coordsConfig.outline
        elseif coordsConfig.monochrome then
            flags = "MONOCHROME"
        elseif coordsConfig.outline ~= "NONE" then
            flags = coordsConfig.outline
        end
        PREYCore:SafeSetFont(coordsText, fontPath, coordsConfig.fontSize, flags)
    end

    local uiMapID = C_Map.GetBestMapForUnit("player")
    if uiMapID then
        local pos = C_Map.GetPlayerMapPosition(uiMapID, "player")
        if pos then
            coordsText:SetFormattedText(settings.coordPrecision, pos.x * 100, pos.y * 100)
            return
        end
    end
    coordsText:SetText("0,0")
end


local function CreateZoneText()
    if zoneTextFrame then return end

    zoneTextFrame = CreateFrame("Button", nil, Minimap)
    zoneTextFont = zoneTextFrame:CreateFontString(nil, "OVERLAY")
    zoneTextFont:SetAllPoints(zoneTextFrame)


    if MinimapCluster and MinimapCluster.ZoneTextButton then
        MinimapCluster.ZoneTextButton:SetParent(CreateFrame("Frame"))
        MinimapCluster.ZoneTextButton:Hide()
    end
    if MinimapCluster and MinimapCluster.BorderTop then
        MinimapCluster.BorderTop:SetParent(CreateFrame("Frame"))
        MinimapCluster.BorderTop:Hide()
    end

    zoneTextFrame:RegisterEvent("ZONE_CHANGED")
    zoneTextFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    zoneTextFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    zoneTextFrame:SetScript("OnEvent", function()
        UpdateZoneTextDisplay()
    end)

    zoneTextFrame:SetScript("OnEnter", function(self)
        local GetZonePVPInfo = C_PvP and C_PvP.GetZonePVPInfo or GetZonePVPInfo
        local pvpType, _, factionName = GetZonePVPInfo()
        local zoneName = GetZoneText()
        local subzoneName = GetSubZoneText()

        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(zoneName, 1, 1, 1)

        if subzoneName and subzoneName ~= "" and subzoneName ~= zoneName then
            if pvpType == "sanctuary" then
                GameTooltip:AddLine(subzoneName, 0.41, 0.8, 0.94)
                GameTooltip:AddLine(SANCTUARY_TERRITORY, 0.41, 0.8, 0.94)
            elseif pvpType == "arena" or pvpType == "combat" then
                GameTooltip:AddLine(subzoneName, 1, 0.1, 0.1)
                GameTooltip:AddLine(pvpType == "arena" and FREE_FOR_ALL_TERRITORY or COMBAT_ZONE, 1, 0.1, 0.1)
            elseif pvpType == "friendly" then
                GameTooltip:AddLine(subzoneName, 0.1, 1, 0.1)
                if factionName and factionName ~= "" then
                    GameTooltip:AddLine(FACTION_CONTROLLED_TERRITORY:format(factionName), 0.1, 1, 0.1)
                end
            elseif pvpType == "hostile" then
                GameTooltip:AddLine(subzoneName, 1, 0.1, 0.1)
                if factionName and factionName ~= "" then
                    GameTooltip:AddLine(FACTION_CONTROLLED_TERRITORY:format(factionName), 1, 0.1, 0.1)
                end
            elseif pvpType == "contested" then
                GameTooltip:AddLine(subzoneName, 1, 0.7, 0)
                GameTooltip:AddLine(CONTESTED_TERRITORY, 1, 0.7, 0)
            else
                GameTooltip:AddLine(subzoneName, 1, 0.82, 0)
            end
        end

        GameTooltip:Show()
    end)

    zoneTextFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function UpdateZoneText()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end
    if not zoneTextFrame then CreateZoneText() end

    local zoneConfig = settings.zoneTextConfig

    if not settings.showZoneText then
        zoneTextFrame:Hide()
        return
    end

    zoneTextFrame:Show()
    zoneTextFrame:ClearAllPoints()
    zoneTextFrame:SetPoint("TOP", Minimap, "TOP", zoneConfig.offsetX, zoneConfig.offsetY)
    zoneTextFrame:SetWidth(settings.size)
    zoneTextFrame:SetHeight(zoneConfig.fontSize + 1)


    local flags = nil
    if zoneConfig.monochrome and zoneConfig.outline ~= "NONE" then
        flags = "MONOCHROME," .. zoneConfig.outline
    elseif zoneConfig.monochrome then
        flags = "MONOCHROME"
    elseif zoneConfig.outline ~= "NONE" then
        flags = generalOutline
    end


    local generalFont = "Prey"
    local generalOutline = "OUTLINE"
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        local general = PREYCore.db.profile.general
        generalFont = general.font or "Prey"
        generalOutline = general.fontOutline or "OUTLINE"
    end


    if not zoneConfig.monochrome then
        flags = generalOutline
    end

    local fontPath = LSM:Fetch("font", generalFont) or "Fonts\\FRIZQT__.TTF"
    PREYCore:SafeSetFont(zoneTextFont, fontPath, zoneConfig.fontSize, flags)
    zoneTextFont:SetJustifyH(zoneConfig.align)

    UpdateZoneTextDisplay()
end

function UpdateZoneTextDisplay()
    if not zoneTextFrame or not zoneTextFont then return end
    local settings = GetSettings()
    if not settings or not settings.showZoneText then return end

    local zoneConfig = settings.zoneTextConfig


    local currentFont = zoneTextFont:GetFont()
    if not currentFont then

        local generalFont = "Prey"
        local generalOutline = "OUTLINE"
        if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
            local general = PREYCore.db.profile.general
            generalFont = general.font or "Prey"
            generalOutline = general.fontOutline or "OUTLINE"
        end

        local fontPath = LSM:Fetch("font", generalFont) or "Fonts\\FRIZQT__.TTF"
        local flags = nil
        if zoneConfig.monochrome and generalOutline ~= "NONE" then
            flags = "MONOCHROME," .. generalOutline
        elseif zoneConfig.monochrome then
            flags = "MONOCHROME"
        elseif generalOutline ~= "NONE" then
            flags = generalOutline
        end
        PREYCore:SafeSetFont(zoneTextFont, fontPath, zoneConfig.fontSize, flags)
    end

    local text = GetMinimapZoneText()


    if zoneConfig.allCaps then
        text = string.upper(text)
    end

    zoneTextFont:SetText(text)


    local GetZonePVPInfo = C_PvP and C_PvP.GetZonePVPInfo or GetZonePVPInfo
    local pvpType = GetZonePVPInfo()

    local r, g, b, a
    if zoneConfig.useClassColor then
        local color = GetClassColor()
        if color then
            r, g, b, a = color.r, color.g, color.b, 1
        end
    elseif pvpType == "sanctuary" then
        r, g, b, a = unpack(zoneConfig.colorSanctuary)
    elseif pvpType == "arena" then
        r, g, b, a = unpack(zoneConfig.colorArena)
    elseif pvpType == "friendly" then
        r, g, b, a = unpack(zoneConfig.colorFriendly)
    elseif pvpType == "hostile" then
        r, g, b, a = unpack(zoneConfig.colorHostile)
    elseif pvpType == "contested" then
        r, g, b, a = unpack(zoneConfig.colorContested)
    else
        r, g, b, a = unpack(zoneConfig.colorNormal)
    end

    zoneTextFont:SetTextColor(r, g, b, a)
end


local hiddenButtonParent = CreateFrame("Frame")
hiddenButtonParent:Hide()
hiddenButtonParent.Layout = function() end


if Minimap.ZoomIn and not Minimap.ZoomIn._PREY_ShowHooked then
    Minimap.ZoomIn._PREY_ShowHooked = true
    hooksecurefunc(Minimap.ZoomIn, "Show", function(self)
        local s = GetSettings()
        if s and not s.showZoomButtons then
            self:Hide()
        end
    end)
end

if Minimap.ZoomOut and not Minimap.ZoomOut._PREY_ShowHooked then
    Minimap.ZoomOut._PREY_ShowHooked = true
    hooksecurefunc(Minimap.ZoomOut, "Show", function(self)
        local s = GetSettings()
        if s and not s.showZoomButtons then
            self:Hide()
        end
    end)
end

local function UpdateButtonVisibility()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    local minimapSize = settings.size or 160
    local halfSize = minimapSize / 2


    if Minimap.ZoomIn and Minimap.ZoomOut then
        if settings.showZoomButtons then
            Minimap.ZoomIn:SetParent(Minimap)
            Minimap.ZoomIn:ClearAllPoints()
            Minimap.ZoomIn:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -5, 25)
            Minimap.ZoomIn:Show()

            Minimap.ZoomOut:SetParent(Minimap)
            Minimap.ZoomOut:ClearAllPoints()
            Minimap.ZoomOut:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -5, 5)
            Minimap.ZoomOut:Show()
        else
            Minimap.ZoomIn:SetParent(hiddenButtonParent)
            Minimap.ZoomIn:Hide()
            Minimap.ZoomOut:SetParent(hiddenButtonParent)
            Minimap.ZoomOut:Hide()
        end
    end


    if MinimapCluster and MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.MailFrame then
        local mailFrame = MinimapCluster.IndicatorFrame.MailFrame


        if not mailFrame.Layout then
            mailFrame.Layout = function() end
        end

        if settings.showMail then
            mailFrame:SetParent(Minimap)
            mailFrame:ClearAllPoints()
            mailFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 2, 2)
            mailFrame:SetScale(0.8)
            mailFrame:Show()
        else
            mailFrame:SetParent(hiddenButtonParent)
            mailFrame:Hide()
        end
    end


    if MinimapCluster and MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.CraftingOrderFrame then
        local craftingFrame = MinimapCluster.IndicatorFrame.CraftingOrderFrame


        if not craftingFrame.Layout then
            craftingFrame.Layout = function() end
        end

        if settings.showCraftingOrder then
            craftingFrame:SetParent(Minimap)
            craftingFrame:ClearAllPoints()
            craftingFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 28, 2)
            craftingFrame:SetScale(0.8)
            craftingFrame:Show()
        else
            craftingFrame:SetParent(hiddenButtonParent)
            craftingFrame:Hide()
        end
    end


    if AddonCompartmentFrame then
        if settings.showAddonCompartment then
            AddonCompartmentFrame:SetParent(Minimap)
            AddonCompartmentFrame:ClearAllPoints()
            AddonCompartmentFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -2, -2)
            AddonCompartmentFrame:Show()
        else
            AddonCompartmentFrame:SetParent(hiddenButtonParent)
            AddonCompartmentFrame:Hide()
        end
    end


    if MinimapCluster and MinimapCluster.InstanceDifficulty then
        local diffFrame = MinimapCluster.InstanceDifficulty
        if settings.showDifficulty then
            diffFrame:SetParent(Minimap)
            diffFrame:ClearAllPoints()
            diffFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
        else
            diffFrame:SetParent(hiddenButtonParent)
        end
    end


    if ExpansionLandingPageMinimapButton then
        if settings.showMissions then
            ExpansionLandingPageMinimapButton:SetParent(Minimap)
            ExpansionLandingPageMinimapButton:ClearAllPoints()
            ExpansionLandingPageMinimapButton:SetPoint("LEFT", Minimap, "LEFT", -5, 0)
            ExpansionLandingPageMinimapButton:Show()
        else
            ExpansionLandingPageMinimapButton:SetParent(hiddenButtonParent)
            ExpansionLandingPageMinimapButton:Hide()
        end
    end


    if GameTimeFrame then
        if settings.showCalendar then
            GameTimeFrame:SetParent(Minimap)
            GameTimeFrame:ClearAllPoints()
            if settings.showAddonCompartment then
                GameTimeFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -28, -2)
            else
                GameTimeFrame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -2, -2)
            end
            GameTimeFrame:Show()
        else
            GameTimeFrame:SetParent(hiddenButtonParent)
            GameTimeFrame:Hide()
        end
    end


    if MinimapCluster and MinimapCluster.Tracking then
        local trackingFrame = MinimapCluster.Tracking
        if settings.showTracking then
            trackingFrame:SetParent(Minimap)
            trackingFrame:ClearAllPoints()
            if settings.showDifficulty then
                trackingFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 35, -2)
            else
                trackingFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
            end
        else
            trackingFrame:SetParent(hiddenButtonParent)
        end
    end
end


local dungeonEyeOriginalParent = nil
local dungeonEyeOriginalPoint = nil
local dungeonEyeHooked = false

local function RestoreDungeonEye()
    local btn = QueueStatusButton
    if not btn then return end


    if dungeonEyeOriginalParent then
        btn:SetParent(dungeonEyeOriginalParent)
    end


    if dungeonEyeOriginalPoint then
        btn:ClearAllPoints()
        local point, relativeTo, relativePoint, x, y = unpack(dungeonEyeOriginalPoint)
        if point and relativePoint then
            btn:SetPoint(point, relativeTo, relativePoint, x or 0, y or 0)
        end
    end


    btn:SetScale(1.0)
end

local function UpdateDungeonEyePosition()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    local eyeSettings = settings.dungeonEye
    if not eyeSettings then return end

    local btn = QueueStatusButton
    if not btn then return end


    if not dungeonEyeOriginalParent then
        dungeonEyeOriginalParent = btn:GetParent()
        local point, relativeTo, relativePoint, x, y = btn:GetPoint()
        if point then
            dungeonEyeOriginalPoint = {point, relativeTo, relativePoint, x, y}
        end
    end

    if eyeSettings.enabled then

        btn:SetParent(Minimap)
        btn:ClearAllPoints()


        local corner = eyeSettings.corner or "BOTTOMRIGHT"
        local offsetX = eyeSettings.offsetX or 0
        local offsetY = eyeSettings.offsetY or 0


        local cornerOffsets = {
            TOPRIGHT    = { anchor = "TOPRIGHT",    x = -5 + offsetX, y = -5 + offsetY },
            TOPLEFT     = { anchor = "TOPLEFT",     x = 5 + offsetX,  y = -5 + offsetY },
            BOTTOMRIGHT = { anchor = "BOTTOMRIGHT", x = -5 + offsetX, y = 5 + offsetY },
            BOTTOMLEFT  = { anchor = "BOTTOMLEFT",  x = 5 + offsetX,  y = 5 + offsetY },
        }

        local pos = cornerOffsets[corner] or cornerOffsets.BOTTOMRIGHT
        btn:SetPoint(pos.anchor, Minimap, pos.anchor, pos.x, pos.y)


        local scale = eyeSettings.scale or 1.0
        btn:SetScale(scale)

    else

        RestoreDungeonEye()
    end
end

local function SetupDungeonEyeHook()
    if dungeonEyeHooked then return end
    if not QueueStatusButton then return end


    if QueueStatusButton.UpdatePosition then
        hooksecurefunc(QueueStatusButton, "UpdatePosition", function()
            local settings = GetSettings()
            if settings and settings.dungeonEye and settings.dungeonEye.enabled then

                C_Timer.After(0, UpdateDungeonEyePosition)
            end
        end)
        dungeonEyeHooked = true
    end
end


local function SetupAddonButtonHiding()
    local settings = GetSettings()
    if not settings or not settings.enabled or not LibDBIcon then return end

    if settings.hideAddonButtons then
        local buttons = LibDBIcon:GetButtonList()
        for i = 1, #buttons do
            LibDBIcon:ShowOnEnter(buttons[i], true)
        end


        LibDBIcon.RegisterCallback(Minimap_Module, "LibDBIcon_IconCreated", function(_, _, buttonName)
            LibDBIcon:ShowOnEnter(buttonName, true)
        end)
    else
        local buttons = LibDBIcon:GetButtonList()
        for i = 1, #buttons do
            LibDBIcon:ShowOnEnter(buttons[i], false)
        end
        LibDBIcon.UnregisterCallback(Minimap_Module, "LibDBIcon_IconCreated")
    end
end


local function UpdateMinimapSize()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end


    Minimap:SetSize(settings.size, settings.size)


    Minimap:SetScale(settings.scale or 1.0)


    if Minimap:GetZoom() ~= 5 then
        Minimap.ZoomIn:Click()
        Minimap.ZoomOut:Click()
    else
        Minimap.ZoomOut:Click()
        Minimap.ZoomIn:Click()
    end


    if LibDBIcon then
        if settings.shape == "SQUARE" then
            LibDBIcon:SetButtonRadius(settings.buttonRadius or 2)
        else
            LibDBIcon:SetButtonRadius(1)
        end
    end
end

local function SetupMinimapDragging()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end


    Minimap:SetParent(UIParent)
    Minimap:SetFrameStrata("LOW")
    Minimap:SetFrameLevel(2)
    Minimap:SetFixedFrameStrata(true)
    Minimap:SetFixedFrameLevel(true)


    if MinimapCluster then
        MinimapCluster:EnableMouse(false)
    end


    Minimap:EnableMouse(true)
    Minimap:SetMovable(not settings.lock)
    Minimap:SetClampedToScreen(true)
    Minimap:RegisterForDrag("LeftButton")

    Minimap:SetScript("OnDragStart", function(self)
        if self:IsMovable() then
            self:StartMoving()
        end
    end)

    Minimap:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        settings.position = {point, relPoint, x, y}
    end)


    local pos = settings.position
    if pos then
        local point = pos[1] or pos.point or "TOPLEFT"
        local relPoint = pos[2] or pos.relPoint or "BOTTOMLEFT"
        local x = pos[3] or pos.x or 790
        local y = pos[4] or pos.y or 285
        Minimap:ClearAllPoints()
        Minimap:SetPoint(point, UIParent, relPoint, x, y)
    else

        Minimap:ClearAllPoints()
        Minimap:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 790, 285)
    end
end


local editModeWasLocked = nil


function PREYCore:EnableMinimapEditMode()
    local settings = GetSettings()
    if not settings then return end


    editModeWasLocked = settings.lock


    Minimap:SetMovable(true)
end


function PREYCore:DisableMinimapEditMode()
    local settings = GetSettings()
    if not settings then return end


    if editModeWasLocked ~= nil then
        Minimap:SetMovable(not editModeWasLocked)
        editModeWasLocked = nil
    else
        Minimap:SetMovable(not settings.lock)
    end
end


local function SetupMouseWheelZoom()
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 then
            Minimap.ZoomIn:Click()
        else
            Minimap.ZoomOut:Click()
        end
    end)
end


local autoZoomTimer = 0
local autoZoomCurrent = 0

local function SetupAutoZoom()
    local settings = GetSettings()
    if not settings or not settings.enabled or not settings.autoZoom then return end

    local function ZoomOut()
        autoZoomCurrent = autoZoomCurrent + 1
        if autoZoomTimer == autoZoomCurrent then
            Minimap:SetZoom(0)
            if Minimap.ZoomIn then Minimap.ZoomIn:Enable() end
            if Minimap.ZoomOut then Minimap.ZoomOut:Disable() end
            autoZoomTimer, autoZoomCurrent = 0, 0
        end
    end

    local function OnZoom()
        if settings.autoZoom then
            autoZoomTimer = autoZoomTimer + 1
            C_Timer.After(10, ZoomOut)
        end
    end

    if Minimap.ZoomIn then
        Minimap.ZoomIn:HookScript("OnClick", OnZoom)
    end
    if Minimap.ZoomOut then
        Minimap.ZoomOut:HookScript("OnClick", OnZoom)
    end


    OnZoom()
end


local function StartUpdateTickers()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end


    if clockTicker then clockTicker:Cancel() end
    if coordsTicker then coordsTicker:Cancel() end


    clockTicker = C_Timer.NewTicker(1, function()
        local s = GetSettings()
        if s and s.enabled then
            UpdateClockTime()
        end
    end)


    local coordInterval = settings.coordUpdateInterval or 1
    coordsTicker = C_Timer.NewTicker(coordInterval, function()
        local s = GetSettings()
        if s and s.enabled then
            UpdateCoordsPosition()
        end
    end)


end

local function StopUpdateTickers()
    if clockTicker then clockTicker:Cancel(); clockTicker = nil end
    if coordsTicker then coordsTicker:Cancel(); coordsTicker = nil end
end


function Minimap_Module:Initialize()
    local settings = GetSettings()
    if not settings then return end

    if not settings.enabled then

        return
    end


    SetMinimapShape(settings.shape)


    CreateBackdrop()
    UpdateBackdrop()

    SetupMinimapDragging()
    UpdateMinimapSize()

    CreateClock()
    UpdateClock()
    UpdateClockTime()

    CreateCoords()
    UpdateCoords()
    UpdateCoordsPosition()

    CreateZoneText()
    UpdateZoneText()


    CreateDatatextPanel()
    UpdateDatatextPanel()

    UpdateButtonVisibility()
    SetupAddonButtonHiding()
    SetupDungeonEyeHook()
    UpdateDungeonEyePosition()
    SetupMouseWheelZoom()
    SetupAutoZoom()


    StartUpdateTickers()


    if MinimapBackdrop then
        MinimapBackdrop:Hide()
    end
    if MinimapNorthTag then
        MinimapNorthTag:SetParent(CreateFrame("Frame"))
    end
    if MinimapBorder then
        MinimapBorder:SetParent(CreateFrame("Frame"))
    end
    if MinimapBorderTop then
        MinimapBorderTop:SetParent(CreateFrame("Frame"))
    end


    if Minimap.SetBackdrop then
        Minimap:SetBackdrop(nil)
    end


    local edgeNames = {"LeftEdge", "RightEdge", "TopEdge", "BottomEdge", "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner", "Center"}
    for _, edgeName in ipairs(edgeNames) do
        if Minimap[edgeName] then
            Minimap[edgeName]:Hide()
            Minimap[edgeName]:SetAlpha(0)
        end
    end


    if Minimap.backdropInfo then
        for _, edgeName in ipairs(edgeNames) do
            if Minimap.backdropInfo[edgeName] then
                Minimap.backdropInfo[edgeName] = nil
            end
        end
    end


    if MinimapCluster and MinimapCluster.SetBackdrop then
        MinimapCluster:SetBackdrop(nil)
    end


    if Minimap.BorderTop then
        Minimap.BorderTop:Hide()
    end
    if Minimap.Background then
        Minimap.Background:Hide()
    end


    for _, child in pairs({Minimap:GetChildren()}) do

        local name = child:GetName()
        if name and (name:find("Edge") or name:find("Corner") or name:find("Border")) then
            child:Hide()
        end

        if child.SetBackdrop then
            child:SetBackdrop(nil)
        end
    end
end

function Minimap_Module:Refresh()

    InvalidateSettingsCache()

    local settings = GetSettings()


    if not settings then
        return
    end


    if not settings.enabled then
        StopUpdateTickers()

        if minimapBackdrop then
            minimapBackdrop:Hide()
        end
        if datatextPanel then
            datatextPanel:Hide()
        end

        Minimap:Show()
        return
    end


    StartUpdateTickers()

    SetMinimapShape(settings.shape)
    UpdateBackdrop()
    UpdateMinimapSize()
    UpdateClock()
    UpdateCoords()
    UpdateZoneText()
    UpdateDatatextPanel()
    UpdateButtonVisibility()
    SetupAddonButtonHiding()
    UpdateDungeonEyePosition()


    Minimap:SetMovable(not settings.lock)
    Minimap:EnableMouse(true)
    Minimap:RegisterForDrag("LeftButton")


    Minimap:SetScript("OnDragStart", function(self)
        if self:IsMovable() then
            self:StartMoving()
        end
    end)

    Minimap:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        settings.position = {point, relPoint, x, y}
    end)


    if settings.position and settings.position[1] and settings.position[2] then
        Minimap:ClearAllPoints()
        Minimap:SetPoint(settings.position[1], UIParent, settings.position[2], settings.position[3] or 0, settings.position[4] or 0)
    end
end


function Minimap_Module:RefreshDatatext()
    UpdateDatatextPanel()
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_HybridMinimap" then

        local settings = GetSettings()
        if settings and settings.enabled then
            SetMinimapShape(settings.shape)
        end
    elseif event == "PLAYER_LOGIN" then

        C_Timer.After(0.5, function()
            Minimap_Module:Initialize()
        end)
    end
end)


local calendarFrame = CreateFrame("Frame")
calendarFrame:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES")
calendarFrame:RegisterEvent("CALENDAR_ACTION_PENDING")
calendarFrame:SetScript("OnEvent", function()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    if settings.showCalendar and GameTimeFrame then
        if C_Calendar.GetNumPendingInvites() < 1 then
            GameTimeFrame:Hide()
        else
            GameTimeFrame:Show()
        end
    end
end)


local petBattleFrame = CreateFrame("Frame")
petBattleFrame:RegisterEvent("PET_BATTLE_OPENING_START")
petBattleFrame:RegisterEvent("PET_BATTLE_CLOSE")
petBattleFrame:SetScript("OnEvent", function(self, event)
    if event == "PET_BATTLE_OPENING_START" then
        Minimap:Hide()
    else
        Minimap:Show()
    end
end)

