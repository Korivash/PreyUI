local _, PREY = ...


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then
        return nil
    end

    if not PREYCore.db.profile.buffBorders then
        PREYCore.db.profile.buffBorders = {
            enableBuffs = true,
            enableDebuffs = true,
            hideBuffFrame = false,
            hideDebuffFrame = false,
            borderSize = 2,
            fontSize = 12,
            fontOutline = true,
        }
    end
    return PREYCore.db.profile.buffBorders
end


local BORDER_COLOR_BUFF = {0, 0, 0, 1}
local BORDER_COLOR_DEBUFF = {0.5, 0, 0, 1}


local borderedButtons = {}


local function AddBorderToButton(button, isBuff)
    if not button or borderedButtons[button] then
        return
    end


    local settings = GetSettings()
    if not settings then return end
    if isBuff and not settings.enableBuffs then
        return
    end
    if not isBuff and not settings.enableDebuffs then
        return
    end


    local icon = button.Icon or button.icon
    if not icon then
        return
    end


    if not button.CreateTexture or type(button.CreateTexture) ~= "function" then
        return
    end

    local borderSize = settings.borderSize or 2


    local borderColor = isBuff and BORDER_COLOR_BUFF or BORDER_COLOR_DEBUFF


    if not button.preyBorderTop then

        button.preyBorderTop = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.preyBorderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        button.preyBorderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)


        button.preyBorderBottom = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.preyBorderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        button.preyBorderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)


        button.preyBorderLeft = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.preyBorderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        button.preyBorderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)


        button.preyBorderRight = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.preyBorderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        button.preyBorderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    end


    button.preyBorderTop:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    button.preyBorderBottom:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    button.preyBorderLeft:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    button.preyBorderRight:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])


    button.preyBorderTop:SetHeight(borderSize)
    button.preyBorderBottom:SetHeight(borderSize)
    button.preyBorderLeft:SetWidth(borderSize)
    button.preyBorderRight:SetWidth(borderSize)

    button.preyBorderTop:Show()
    button.preyBorderBottom:Show()
    button.preyBorderLeft:Show()
    button.preyBorderRight:Show()

    borderedButtons[button] = true
end


local function HideBorderOnButton(button)
    if button.preyBorderTop then button.preyBorderTop:Hide() end
    if button.preyBorderBottom then button.preyBorderBottom:Hide() end
    if button.preyBorderLeft then button.preyBorderLeft:Hide() end
    if button.preyBorderRight then button.preyBorderRight:Hide() end
end


local function ApplyFontSettings(button)
    if not button then return end

    local settings = GetSettings()
    if not settings then return end


    local LSM = LibStub("LibSharedMedia-3.0", true)
    local generalFont = "Fonts\\FRIZQT__.TTF"
    local generalOutline = "OUTLINE"

    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        local general = PREYCore.db.profile.general
        if general.font and LSM then
            generalFont = LSM:Fetch("font", general.font) or generalFont
        end
        generalOutline = general.fontOutline or "OUTLINE"
    end


    local duration = button.Duration or button.duration
    if duration and duration.SetFont then
        local fontSize = settings.fontSize or 12
        duration:SetFont(generalFont, fontSize, generalOutline)
    end
end


local function ProcessAuraContainer(container, isBuff)
    if not container then return end


    local frames = {container:GetChildren()}
    for _, frame in ipairs(frames) do

        if frame.Icon or frame.icon then
            AddBorderToButton(frame, isBuff)
            ApplyFontSettings(frame)
        end
    end
end


local function ApplyFrameHiding()
    local settings = GetSettings()
    if not settings then return end


    if BuffFrame then
        if settings.hideBuffFrame then
            BuffFrame:Hide()
        else
            BuffFrame:Show()
        end

        if not BuffFrame._PREY_ShowHooked then
            BuffFrame._PREY_ShowHooked = true
            hooksecurefunc(BuffFrame, "Show", function(self)
                local s = GetSettings()
                if s and s.hideBuffFrame then
                    self:Hide()
                end
            end)
        end
    end


    if DebuffFrame then
        if settings.hideDebuffFrame then
            DebuffFrame:Hide()
        else
            DebuffFrame:Show()
        end

        if not DebuffFrame._PREY_ShowHooked then
            DebuffFrame._PREY_ShowHooked = true
            hooksecurefunc(DebuffFrame, "Show", function(self)
                local s = GetSettings()
                if s and s.hideDebuffFrame then
                    self:Hide()
                end
            end)
        end
    end
end


local function ApplyBuffBorders()

    ApplyFrameHiding()

    if BuffFrame and BuffFrame.AuraContainer then
        ProcessAuraContainer(BuffFrame.AuraContainer, true)
    end


    if DebuffFrame and DebuffFrame.AuraContainer then
        ProcessAuraContainer(DebuffFrame.AuraContainer, false)
    end


    if TemporaryEnchantFrame then
        local frames = {TemporaryEnchantFrame:GetChildren()}
        for _, frame in ipairs(frames) do
            AddBorderToButton(frame, true)
            ApplyFontSettings(frame)
        end
    end
end


local buffBorderPending = false


local function ScheduleBuffBorders()
    if buffBorderPending then return end
    buffBorderPending = true
    C_Timer.After(0.15, function()
        buffBorderPending = false
        ApplyBuffBorders()
    end)
end


local function HookAuraUpdates()

    if BuffFrame and BuffFrame.Update then
        hooksecurefunc(BuffFrame, "Update", ScheduleBuffBorders)
    end


    if BuffFrame and BuffFrame.AuraContainer and BuffFrame.AuraContainer.Update then
        hooksecurefunc(BuffFrame.AuraContainer, "Update", ScheduleBuffBorders)
    end


    if DebuffFrame and DebuffFrame.Update then
        hooksecurefunc(DebuffFrame, "Update", ScheduleBuffBorders)
    end


    if DebuffFrame and DebuffFrame.AuraContainer and DebuffFrame.AuraContainer.Update then
        hooksecurefunc(DebuffFrame.AuraContainer, "Update", ScheduleBuffBorders)
    end


    if type(AuraButton_Update) == "function" then
        hooksecurefunc("AuraButton_Update", ScheduleBuffBorders)
    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")

eventFrame:SetScript("OnEvent", function(self, event, arg)
    if event == "UNIT_AURA" and arg == "player" then
        ScheduleBuffBorders()
    end
end)


C_Timer.After(2, HookAuraUpdates)


PREY.BuffBorders = {
    Apply = ApplyBuffBorders,
    AddBorder = AddBorderToButton,
}


_G.PreyUI_RefreshBuffBorders = function()
    borderedButtons = {}
    ApplyBuffBorders()
end

