local ADDON_NAME, ns = ...
local PREY = ns.PREY or {}
ns.PREY = PREY


local CombatTimerState = {
    combatStartTime = 0,
    timerFrame = nil,
    isInCombat = false,
    isPreviewMode = false,
    isInEncounter = false,
}


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.combatTimer then
        return PREYCore.db.profile.combatTimer
    end
    return nil
end


local LSM = LibStub("LibSharedMedia-3.0", true)

local function GetBackdropInfo(borderTextureName, borderSize)
    local edgeFile = nil
    local edgeSize = 0


    if borderTextureName and borderTextureName ~= "None" and LSM then
        edgeFile = LSM:Fetch("border", borderTextureName)
        edgeSize = borderSize or 1
    end

    return {
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = edgeFile,
        tile = false,
        tileSize = 0,
        edgeSize = edgeSize,
        insets = { left = 0, right = 1, top = 0, bottom = 1 },
    }
end


local function CreateBorderLines(frame)
    if frame.borderLines then return frame.borderLines end

    local borders = {}


    borders.top = frame:CreateTexture(nil, "OVERLAY")
    borders.top:SetColorTexture(0, 0, 0, 1)
    borders.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borders.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, 0)

    borders.bottom = frame:CreateTexture(nil, "OVERLAY")
    borders.bottom:SetColorTexture(0, 0, 0, 1)
    borders.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 1)
    borders.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

    borders.left = frame:CreateTexture(nil, "OVERLAY")
    borders.left:SetColorTexture(0, 0, 0, 1)
    borders.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    borders.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 1)

    borders.right = frame:CreateTexture(nil, "OVERLAY")
    borders.right:SetColorTexture(0, 0, 0, 1)
    borders.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    borders.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 1)

    frame.borderLines = borders
    return borders
end

local function UpdateBorderLines(frame, size, r, g, b, a, hide)
    local borders = frame.borderLines
    if not borders then return end


    if hide or size <= 0 then
        for _, line in pairs(borders) do
            line:Hide()
        end
        return
    end


    borders.top:SetHeight(size)
    borders.bottom:SetHeight(size)
    borders.left:SetWidth(size)
    borders.right:SetWidth(size)

    borders.top:SetColorTexture(r or 0, g or 0, b or 0, a or 1)
    borders.bottom:SetColorTexture(r or 0, g or 0, b or 0, a or 1)
    borders.left:SetColorTexture(r or 0, g or 0, b or 0, a or 1)
    borders.right:SetColorTexture(r or 0, g or 0, b or 0, a or 1)

    for _, line in pairs(borders) do
        line:Show()
    end
end


local function GetFontPath(fontName)
    if LSM and fontName then
        local path = LSM:Fetch("font", fontName)
        if path then return path end
    end
    return "Fonts\\FRIZQT__.TTF"
end


local function CreateTimerFrame()
    if CombatTimerState.timerFrame then return end

    local frame = CreateFrame("Frame", "PreyUI_CombatTimer", UIParent, "BackdropTemplate")
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    frame:SetSize(80, 30)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(50)


    frame:SetBackdrop(GetBackdropInfo())
    frame:SetBackdropColor(0, 0, 0, 0.6)


    CreateBorderLines(frame)
    UpdateBorderLines(frame, 1, 0, 0, 0, 1)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    text:SetTextColor(1, 1, 1, 1)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetText("0:00")
    frame.text = text

    frame:Hide()
    CombatTimerState.timerFrame = frame
end


local function FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", mins, secs)
end


local function OnTimerUpdate(self, elapsed)
    if not CombatTimerState.isInCombat then return end

    local now = GetTime()
    local elapsedTime = now - CombatTimerState.combatStartTime

    if CombatTimerState.timerFrame and CombatTimerState.timerFrame.text then
        CombatTimerState.timerFrame.text:SetText(FormatTime(elapsedTime))
    end
end


local function GetGlobalFont()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general and PREYCore.db.profile.general.font then
        return PREYCore.db.profile.general.font
    end
    return "Prey"
end


local function GetClassColor()
    local _, class = UnitClass("player")
    if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return {c.r, c.g, c.b, 1}
    end
    return {1, 1, 1, 1}
end


local function UpdateTimerAppearance()
    if not CombatTimerState.timerFrame then
        CreateTimerFrame()
    end

    local settings = GetSettings()
    if not settings then return end

    local frame = CombatTimerState.timerFrame


    local width = settings.width or 80
    local height = settings.height or 30
    frame:SetSize(width, height)


    local xOffset = settings.xOffset or 0
    local yOffset = settings.yOffset or -150
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)


    local fontSize = settings.fontSize or 16
    local fontName = settings.useCustomFont and settings.font or GetGlobalFont()
    local fontPath = GetFontPath(fontName)
    frame.text:SetFont(fontPath, fontSize, "OUTLINE")


    local textColor
    if settings.useClassColorText then
        textColor = GetClassColor()
    else
        textColor = settings.textColor or {1, 1, 1, 1}
    end
    frame.text:SetTextColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)


    local showBackdrop = settings.showBackdrop
    if showBackdrop == nil then showBackdrop = true end

    local borderSize = settings.borderSize or 1
    local borderTexture = settings.borderTexture or "None"
    local useLSMBorder = borderTexture ~= "None" and borderSize > 0


    local borderColor
    if settings.useClassColorBorder then
        borderColor = GetClassColor()
    else
        borderColor = settings.borderColor or {0, 0, 0, 1}
    end


    local hideBorder = settings.hideBorder
    local effectiveUseLSMBorder = useLSMBorder and not hideBorder

    if showBackdrop or effectiveUseLSMBorder then
        frame:SetBackdrop(GetBackdropInfo(hideBorder and "None" or borderTexture, hideBorder and 0 or borderSize))

        if showBackdrop then
            local bgColor = settings.backdropColor or {0, 0, 0, 0.6}
            frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 0.6)
        else
            frame:SetBackdropColor(0, 0, 0, 0)
        end

        if effectiveUseLSMBorder then
            frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
        end
    else
        frame:SetBackdrop(nil)
    end


    local hideBorder = settings.hideBorder
    CreateBorderLines(frame)
    UpdateBorderLines(frame, borderSize, borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1, useLSMBorder or hideBorder)


    frame.text:ClearAllPoints()
    frame.text:SetPoint("CENTER", frame, "CENTER", 0, 1)
end


local function OnCombatStart()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end


    if CombatTimerState.isPreviewMode then return end


    if settings.onlyShowInEncounters and not CombatTimerState.isInEncounter then
        CombatTimerState.isInCombat = true
        return
    end

    CreateTimerFrame()
    UpdateTimerAppearance()

    CombatTimerState.combatStartTime = GetTime()
    CombatTimerState.isInCombat = true

    if CombatTimerState.timerFrame then
        CombatTimerState.timerFrame.text:SetText("00:00")
        CombatTimerState.timerFrame:Show()
        CombatTimerState.timerFrame:SetScript("OnUpdate", OnTimerUpdate)
    end
end


local function OnCombatEnd()

    if CombatTimerState.isPreviewMode then return end

    CombatTimerState.isInCombat = false

    if CombatTimerState.timerFrame then
        CombatTimerState.timerFrame:SetScript("OnUpdate", nil)
        CombatTimerState.timerFrame:Hide()
    end
end


local function OnEncounterStart()
    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    CombatTimerState.isInEncounter = true


    if CombatTimerState.isPreviewMode then return end


    if settings.onlyShowInEncounters and CombatTimerState.isInCombat then
        CreateTimerFrame()
        UpdateTimerAppearance()

        CombatTimerState.combatStartTime = GetTime()

        if CombatTimerState.timerFrame then
            CombatTimerState.timerFrame.text:SetText("00:00")
            CombatTimerState.timerFrame:Show()
            CombatTimerState.timerFrame:SetScript("OnUpdate", OnTimerUpdate)
        end
    end
end


local function OnEncounterEnd()
    CombatTimerState.isInEncounter = false

    local settings = GetSettings()
    if not settings then return end


    if CombatTimerState.isPreviewMode then return end


    if settings.onlyShowInEncounters and CombatTimerState.timerFrame then
        CombatTimerState.timerFrame:SetScript("OnUpdate", nil)
        CombatTimerState.timerFrame:Hide()
    end
end


local function RefreshCombatTimer()
    local settings = GetSettings()


    if (not settings or not settings.enabled) and not CombatTimerState.isPreviewMode then
        CombatTimerState.isInCombat = false
        if CombatTimerState.timerFrame then
            CombatTimerState.timerFrame:SetScript("OnUpdate", nil)
            CombatTimerState.timerFrame:Hide()
        end
        return
    end


    UpdateTimerAppearance()


    if InCombatLockdown() and CombatTimerState.timerFrame and not CombatTimerState.isPreviewMode then
        if not CombatTimerState.isInCombat then

            CombatTimerState.combatStartTime = GetTime()
            CombatTimerState.isInCombat = true
            CombatTimerState.timerFrame.text:SetText("0:00")
            CombatTimerState.timerFrame:Show()
            CombatTimerState.timerFrame:SetScript("OnUpdate", OnTimerUpdate)
        end
    end
end


local function TogglePreview(enable)
    CreateTimerFrame()
    if not CombatTimerState.timerFrame then return end

    CombatTimerState.isPreviewMode = enable

    if enable then

        UpdateTimerAppearance()
        CombatTimerState.timerFrame.text:SetText("01:23")
        CombatTimerState.timerFrame:Show()
        CombatTimerState.timerFrame:SetScript("OnUpdate", nil)
    else

        local settings = GetSettings()
        if settings and settings.enabled and InCombatLockdown() then

            CombatTimerState.isInCombat = true
            CombatTimerState.combatStartTime = GetTime()
            CombatTimerState.timerFrame.text:SetText("0:00")
            CombatTimerState.timerFrame:SetScript("OnUpdate", OnTimerUpdate)
        else
            CombatTimerState.timerFrame:SetScript("OnUpdate", nil)
            CombatTimerState.timerFrame:Hide()
        end
    end
end

local function IsPreviewMode()
    return CombatTimerState.isPreviewMode
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
            CreateTimerFrame()
        end)
    elseif event == "PLAYER_REGEN_DISABLED" then
        OnCombatStart()
    elseif event == "PLAYER_REGEN_ENABLED" then
        OnCombatEnd()
    elseif event == "ENCOUNTER_START" then
        OnEncounterStart()
    elseif event == "ENCOUNTER_END" then
        OnEncounterEnd()
    end
end)


_G.PreyUI_RefreshCombatTimer = RefreshCombatTimer
_G.PreyUI_ToggleCombatTimerPreview = TogglePreview
_G.PreyUI_IsCombatTimerPreviewMode = IsPreviewMode

PREY.CombatTimer = {
    Refresh = RefreshCombatTimer,
    TogglePreview = TogglePreview,
    IsPreviewMode = IsPreviewMode,
}
