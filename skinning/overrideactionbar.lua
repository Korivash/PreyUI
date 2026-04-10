local addonName, ns = ...


local FONT_FLAGS = "OUTLINE"
local BUTTON_SIZE = 40
local BUTTON_SPACING = 3
local LEAVE_BUTTON_SIZE = 28
local RESOURCE_BAR_WIDTH = 12
local RESOURCE_BAR_HEIGHT = 40


local function GetColors()
    local PREY = _G.PreyUI
    local sr, sg, sb, sa = 0.820, 0.180, 0.220, 1
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95

    if PREY and PREY.GetSkinColor then
        sr, sg, sb, sa = PREY:GetSkinColor()
    end
    if PREY and PREY.GetSkinBgColor then
        bgr, bgg, bgb, bga = PREY:GetSkinBgColor()
    end

    return sr, sg, sb, sa, bgr, bgg, bgb, bga
end


local function StyleActionButton(button, index, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not button then return end


    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)


    button:ClearAllPoints()
    if index == 1 then
        button:SetPoint("LEFT", button:GetParent(), "LEFT", RESOURCE_BAR_WIDTH + BUTTON_SPACING + 4, 0)
    else
        local prevButton = button:GetParent()["SpellButton" .. (index - 1)]
        if prevButton then
            button:SetPoint("LEFT", prevButton, "RIGHT", BUTTON_SPACING, 0)
        end
    end


    if not button.preyBackdrop then
        button.preyBackdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.preyBackdrop:SetPoint("TOPLEFT", -1, 1)
        button.preyBackdrop:SetPoint("BOTTOMRIGHT", 1, -1)
        button.preyBackdrop:SetFrameLevel(button:GetFrameLevel())
        button.preyBackdrop:EnableMouse(false)
    end

    button.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    button.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, 0.8)
    button.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)


    local normalTexture = button:GetNormalTexture()
    if normalTexture then normalTexture:SetAlpha(0) end


    local icon = button.icon or button.Icon
    if icon then
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    button.preySkinColor = { sr, sg, sb, sa }
    button.preyStyled = true
end


local function HideBlizzardElements(bar)

    local texturesToHide = {
        "_BG", "EndCapL", "EndCapR", "_Border",
        "Divider1", "Divider2", "Divider3",
        "ExitBG", "MicroBGL", "MicroBGR", "_MicroBGMid",
        "ButtonBGL", "ButtonBGR", "_ButtonBGMid",
        "PitchOverlay", "PitchButtonBG", "PitchBG", "PitchMarker",
        "HealthBarBG", "HealthBarOverlay",
        "PowerBarBG", "PowerBarOverlay",
    }

    for _, texName in ipairs(texturesToHide) do
        local tex = bar[texName]
        if tex and tex.SetAlpha then
            tex:SetAlpha(0)
        end
    end


    if bar.pitchFrame then
        bar.pitchFrame:Hide()
        bar.pitchFrame:SetAlpha(0)
    end


    if bar.leaveFrame then
        bar.leaveFrame:SetAlpha(0)

        if bar.LeaveButton then
            bar.LeaveButton:SetParent(bar)
            bar.LeaveButton:Show()
        end
    end


    if bar.xpBar then
        bar.xpBar:Hide()
        bar.xpBar:SetAlpha(0)
    end
end


local function SkinOverrideActionBar()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
    if not settings or not settings.skinOverrideActionBar then return end

    local bar = _G.OverrideActionBar
    if not bar or bar.preySkinned then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetColors()


    HideBlizzardElements(bar)


    local totalWidth = RESOURCE_BAR_WIDTH + BUTTON_SPACING + (BUTTON_SIZE * 6) + (BUTTON_SPACING * 5) + BUTTON_SPACING + LEAVE_BUTTON_SIZE + BUTTON_SPACING + RESOURCE_BAR_WIDTH + 16
    local totalHeight = BUTTON_SIZE + 8


    bar:SetSize(totalWidth, totalHeight)


    if not bar.preyBackdrop then
        bar.preyBackdrop = CreateFrame("Frame", nil, bar, "BackdropTemplate")
        bar.preyBackdrop:SetAllPoints()
        bar.preyBackdrop:SetFrameLevel(math.max(bar:GetFrameLevel() - 1, 0))
        bar.preyBackdrop:EnableMouse(false)
    end

    bar.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    bar.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    bar.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)


    for i = 1, 6 do
        local button = bar["SpellButton" .. i]
        if button then
            StyleActionButton(button, i, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end


    if bar.LeaveButton then
        local leaveBtn = bar.LeaveButton
        leaveBtn:SetSize(LEAVE_BUTTON_SIZE, LEAVE_BUTTON_SIZE)
        leaveBtn:ClearAllPoints()
        leaveBtn:SetPoint("LEFT", bar.SpellButton6, "RIGHT", BUTTON_SPACING + 4, 0)

        if not leaveBtn.preyBackdrop then
            leaveBtn.preyBackdrop = CreateFrame("Frame", nil, leaveBtn, "BackdropTemplate")
            leaveBtn.preyBackdrop:SetPoint("TOPLEFT", -1, 1)
            leaveBtn.preyBackdrop:SetPoint("BOTTOMRIGHT", 1, -1)
            leaveBtn.preyBackdrop:SetFrameLevel(leaveBtn:GetFrameLevel())
            leaveBtn.preyBackdrop:EnableMouse(false)
        end

        leaveBtn.preyBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        leaveBtn.preyBackdrop:SetBackdropColor(0.6, 0.1, 0.1, 0.9)
        leaveBtn.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end


    if bar.healthBar then
        local healthBar = bar.healthBar
        healthBar:Show()
        healthBar:SetAlpha(1)
        healthBar:SetOrientation("VERTICAL")
        healthBar:SetRotatesTexture(true)
        healthBar:SetSize(RESOURCE_BAR_WIDTH, RESOURCE_BAR_HEIGHT)
        healthBar:ClearAllPoints()
        healthBar:SetPoint("LEFT", bar, "LEFT", 4, 0)
        healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")


        if not healthBar.preyBackdrop then
            healthBar.preyBackdrop = CreateFrame("Frame", nil, healthBar, "BackdropTemplate")
            healthBar.preyBackdrop:SetPoint("TOPLEFT", -1, 1)
            healthBar.preyBackdrop:SetPoint("BOTTOMRIGHT", 1, -1)
            healthBar.preyBackdrop:SetFrameLevel(healthBar:GetFrameLevel())
            healthBar.preyBackdrop:EnableMouse(false)
        end

        healthBar.preyBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        healthBar.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, 0.8)
        healthBar.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end


    if bar.powerBar then
        local powerBar = bar.powerBar
        powerBar:Show()
        powerBar:SetAlpha(1)
        powerBar:SetOrientation("VERTICAL")
        powerBar:SetRotatesTexture(true)
        powerBar:SetSize(RESOURCE_BAR_WIDTH, RESOURCE_BAR_HEIGHT)
        powerBar:ClearAllPoints()
        powerBar:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
        powerBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")


        if not powerBar.preyBackdrop then
            powerBar.preyBackdrop = CreateFrame("Frame", nil, powerBar, "BackdropTemplate")
            powerBar.preyBackdrop:SetPoint("TOPLEFT", -1, 1)
            powerBar.preyBackdrop:SetPoint("BOTTOMRIGHT", 1, -1)
            powerBar.preyBackdrop:SetFrameLevel(powerBar:GetFrameLevel())
            powerBar.preyBackdrop:EnableMouse(false)
        end

        powerBar.preyBackdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        powerBar.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, 0.8)
        powerBar.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end

    bar.preySkinned = true


    if MicroMenu and MicroMenu.ResetMicroMenuPosition then
        C_Timer.After(0, function()
            if not InCombatLockdown() then
                MicroMenu:ResetMicroMenuPosition()
            end
        end)
    end
end


local function RefreshOverrideActionBarColors()
    local bar = _G.OverrideActionBar
    if not bar or not bar.preySkinned then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetColors()


    if bar.preyBackdrop then
        bar.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        bar.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end


    for i = 1, 6 do
        local button = bar["SpellButton" .. i]
        if button and button.preyBackdrop then
            button.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, 0.8)
            button.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
            button.preySkinColor = { sr, sg, sb, sa }
        end
    end


    if bar.LeaveButton and bar.LeaveButton.preyBackdrop then
        bar.LeaveButton.preyBackdrop:SetBackdropColor(0.6, 0.1, 0.1, 0.9)
        bar.LeaveButton.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end


    if bar.healthBar and bar.healthBar.preyBackdrop then
        bar.healthBar.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, 0.8)
        bar.healthBar.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end


    if bar.powerBar and bar.powerBar.preyBackdrop then
        bar.powerBar.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, 0.8)
        bar.powerBar.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end
end


_G.PreyUI_RefreshOverrideActionBarColors = RefreshOverrideActionBarColors


local function SetupOverrideBarHooks()
    local bar = _G.OverrideActionBar
    if not bar or bar.preyHooked then return end


    bar:HookScript("OnShow", function()
        C_Timer.After(0.15, SkinOverrideActionBar)
    end)


    if bar:IsShown() then
        C_Timer.After(0.15, SkinOverrideActionBar)
    end


    if bar.UpdateMicroButtons then
        hooksecurefunc(bar, "UpdateMicroButtons", function()
            if bar.preySkinned and MicroMenu and MicroMenu.ResetMicroMenuPosition then
                C_Timer.After(0, function()
                    if not InCombatLockdown() then
                        MicroMenu:ResetMicroMenuPosition()
                    end
                end)
            end
        end)
    end

    bar.preyHooked = true
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, addon)
    if event == "ADDON_LOADED" and addon == "Blizzard_OverrideActionBar" then
        SetupOverrideBarHooks()
    elseif event == "PLAYER_ENTERING_WORLD" then

        if _G.OverrideActionBar then
            SetupOverrideBarHooks()
        end
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)
