local ADDON_NAME, ns = ...
local PREY = ns.PREY or {}
ns.PREY = PREY


local CombatTextState = {
    fadeStart = 0,
    fadeStartAlpha = 1,
    fadeTargetAlpha = 0,
    fadeFrame = nil,
    textFrame = nil,
    displayTimer = nil,
}


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.combatText then
        return PREYCore.db.profile.combatText
    end
    return nil
end


local function CreateTextFrame()
    if CombatTextState.textFrame then return end

    local frame = CreateFrame("Frame", "PreyUI_CombatText", UIParent)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetSize(200, 50)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(100)

    local text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    text:SetTextColor(0.820, 0.180, 0.220, 1)
    text:SetJustifyH("CENTER")
    frame.text = text

    frame:Hide()
    CombatTextState.textFrame = frame
end


local function OnFadeUpdate(self, elapsed)
    local settings = GetSettings()
    local duration = (settings and settings.fadeTime) or 0.3

    local now = GetTime()
    local progress = math.min((now - CombatTextState.fadeStart) / duration, 1)


    local alpha = CombatTextState.fadeStartAlpha +
        (CombatTextState.fadeTargetAlpha - CombatTextState.fadeStartAlpha) * progress

    if CombatTextState.textFrame then
        CombatTextState.textFrame:SetAlpha(alpha)
    end


    if progress >= 1 then
        if CombatTextState.textFrame then
            CombatTextState.textFrame:Hide()
        end
        self:SetScript("OnUpdate", nil)
    end
end


local function StartFade()
    if not CombatTextState.textFrame then return end

    local currentAlpha = CombatTextState.textFrame:GetAlpha()

    CombatTextState.fadeStart = GetTime()
    CombatTextState.fadeStartAlpha = currentAlpha
    CombatTextState.fadeTargetAlpha = 0


    if not CombatTextState.fadeFrame then
        CombatTextState.fadeFrame = CreateFrame("Frame")
    end
    CombatTextState.fadeFrame:SetScript("OnUpdate", OnFadeUpdate)
end


local function ShowCombatText(message)
    local settings = GetSettings()
    if not settings or not settings.enabled then return end


    CreateTextFrame()

    if not CombatTextState.textFrame then return end


    if CombatTextState.displayTimer then
        CombatTextState.displayTimer:Cancel()
        CombatTextState.displayTimer = nil
    end


    if CombatTextState.fadeFrame then
        CombatTextState.fadeFrame:SetScript("OnUpdate", nil)
    end


    local xOffset = settings.xOffset or 0
    local yOffset = settings.yOffset or 100
    CombatTextState.textFrame:ClearAllPoints()
    CombatTextState.textFrame:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)


    local fontSize = settings.fontSize or 24
    CombatTextState.textFrame.text:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")


    local color
    if message == "+Combat" then
        color = settings.enterCombatColor or {0.820, 0.180, 0.220, 1}
    else
        color = settings.leaveCombatColor or {0.820, 0.180, 0.220, 1}
    end
    CombatTextState.textFrame.text:SetTextColor(color[1], color[2], color[3], color[4] or 1)


    CombatTextState.textFrame.text:SetText(message)
    CombatTextState.textFrame:SetAlpha(1)
    CombatTextState.textFrame:Show()


    local displayTime = settings.displayTime or 0.8
    CombatTextState.displayTimer = C_Timer.NewTimer(displayTime, function()
        StartFade()
        CombatTextState.displayTimer = nil
    end)
end


local function OnCombatStart()
    ShowCombatText("+Combat")
end

local function OnCombatEnd()
    ShowCombatText("-Combat")
end


local function RefreshCombatText()
    local settings = GetSettings()


    if not settings or not settings.enabled then
        if CombatTextState.displayTimer then
            CombatTextState.displayTimer:Cancel()
            CombatTextState.displayTimer = nil
        end
        if CombatTextState.fadeFrame then
            CombatTextState.fadeFrame:SetScript("OnUpdate", nil)
        end
        if CombatTextState.textFrame then
            CombatTextState.textFrame:Hide()
        end
    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
            CreateTextFrame()
        end)
    elseif event == "PLAYER_REGEN_DISABLED" then
        OnCombatStart()
    elseif event == "PLAYER_REGEN_ENABLED" then
        OnCombatEnd()
    end
end)


_G.PreyUI_RefreshCombatText = RefreshCombatText


_G.PreyUI_PreviewCombatText = function(message)

    local settings = GetSettings()
    if not settings then return end


    CreateTextFrame()

    if not CombatTextState.textFrame then return end


    if CombatTextState.displayTimer then
        CombatTextState.displayTimer:Cancel()
        CombatTextState.displayTimer = nil
    end


    if CombatTextState.fadeFrame then
        CombatTextState.fadeFrame:SetScript("OnUpdate", nil)
    end


    local xOffset = settings.xOffset or 0
    local yOffset = settings.yOffset or 100
    CombatTextState.textFrame:ClearAllPoints()
    CombatTextState.textFrame:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)


    local fontSize = settings.fontSize or 24
    CombatTextState.textFrame.text:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")


    local color
    if message == "+Combat" then
        color = settings.enterCombatColor or {0.820, 0.180, 0.220, 1}
    else
        color = settings.leaveCombatColor or {0.820, 0.180, 0.220, 1}
    end
    CombatTextState.textFrame.text:SetTextColor(color[1], color[2], color[3], color[4] or 1)


    CombatTextState.textFrame.text:SetText(message or "+Combat")
    CombatTextState.textFrame:SetAlpha(1)
    CombatTextState.textFrame:Show()


    local displayTime = settings.displayTime or 0.8
    CombatTextState.displayTimer = C_Timer.NewTimer(displayTime, function()
        StartFade()
        CombatTextState.displayTimer = nil
    end)
end

PREY.CombatText = {
    Refresh = RefreshCombatText,
    Show = ShowCombatText,
    Preview = _G.PreyUI_PreviewCombatText,
}
