local _, PREY = ...
local IS_MODERN_CLIENT = (tonumber((select(4, GetBuildInfo()))) or 0) >= 120000


local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)


local IsSpellOverlayed = C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed


local activeGlowIcons = {}


local GlowTemplates = {
    LoopGlow = {
        {
            name = "Default Blizzard Glow",
            atlas = "UI-HUD-ActionBar-Proc-Loop-Flipbook",
            rows = 6, columns = 5, frames = 30, duration = 1.0,
        },
        {
            name = "Blue Assist Glow",
            atlas = "RotationHelper-ProcLoopBlue-Flipbook",
            rows = 6, columns = 5, frames = 30, duration = 1.0,
        },
        {
            name = "Classic Ants",
            texture = "Interface\\SpellActivationOverlay\\IconAlertAnts",
            rows = 5, columns = 5, frames = 25, duration = 0.8,
        },
    },
}


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then
        return nil
    end
    return PREYCore.db.profile.customGlow
end

local function GetEffectsSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then
        return { hideEssential = true, hideUtility = true }
    end
    return PREYCore.db.profile.cooldownEffects or { hideEssential = true, hideUtility = true }
end


local function GetViewerType(icon)
    if not icon then return nil end

    local parent = icon:GetParent()
    if not parent then return nil end

    local parentName = parent:GetName()
    if not parentName then return nil end

    if parentName:find("EssentialCooldown") then
        return "Essential"
    elseif parentName:find("UtilityCooldown") then
        return "Utility"
    end

    return nil
end


local function GetViewerSettings(viewerType)
    local settings = GetSettings()
    if not settings then return nil end

    local effectsSettings = GetEffectsSettings()

    if viewerType == "Essential" then
        if not effectsSettings.hideEssential then return nil end
        if not settings.essentialEnabled then return nil end
        local glowType = settings.essentialGlowType or "Pixel Glow"
        if glowType == "Proc Glow" then glowType = "Pixel Glow" end
        return {
            enabled = true,
            glowType = glowType,
            color = settings.essentialColor or {0.95, 0.95, 0.32, 1},
            lines = settings.essentialLines or 14,
            frequency = settings.essentialFrequency or 0.25,
            thickness = settings.essentialThickness or 2,
            scale = settings.essentialScale or 1,
            xOffset = settings.essentialXOffset or 0,
            yOffset = settings.essentialYOffset or 0,
        }
    elseif viewerType == "Utility" then
        if not effectsSettings.hideUtility then return nil end
        if not settings.utilityEnabled then return nil end
        local glowType = settings.utilityGlowType or "Pixel Glow"
        if glowType == "Proc Glow" then glowType = "Pixel Glow" end
        return {
            enabled = true,
            glowType = glowType,
            color = settings.utilityColor or {0.95, 0.95, 0.32, 1},
            lines = settings.utilityLines or 14,
            frequency = settings.utilityFrequency or 0.25,
            thickness = settings.utilityThickness or 2,
            scale = settings.utilityScale or 1,
            xOffset = settings.utilityXOffset or 0,
            yOffset = settings.utilityYOffset or 0,
        }
    end

    return nil
end


local function CustomizeBlizzardGlow(button, viewerSettings)
    if not button then return false end

    local region = button.SpellActivationAlert
    if not region then return false end


    local loopFlipbook = region.ProcLoopFlipbook
    if not loopFlipbook then return false end


    local color = viewerSettings.color or {0.95, 0.95, 0.32, 1}
    loopFlipbook:SetDesaturated(true)
    loopFlipbook:SetVertexColor(color[1], color[2], color[3], color[4] or 1)


    local startFlipbook = region.ProcStartFlipbook
    if startFlipbook then
        startFlipbook:SetDesaturated(true)
        startFlipbook:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    end


    button._PREYCustomGlowActive = true
    activeGlowIcons[button] = true

    return true
end


local function ApplyLibCustomGlow(icon, viewerSettings)
    if not LCG then return false end
    if not icon then return false end

    local glowType = viewerSettings.glowType
    local color = viewerSettings.color
    local lines = viewerSettings.lines
    local frequency = viewerSettings.frequency
    local thickness = viewerSettings.thickness
    local scale = viewerSettings.scale or 1
    local xOffset = viewerSettings.xOffset or 0
    local yOffset = viewerSettings.yOffset or 0


    StopGlow(icon)

    if glowType == "Pixel Glow" then


        LCG.PixelGlow_Start(icon, color, lines, frequency, nil, thickness, 0, 0, true, "_PREYCustomGlow")
        local glowFrame = icon["_PixelGlow_PREYCustomGlow"]
        if glowFrame then
            glowFrame:ClearAllPoints()

            glowFrame:SetPoint("TOPLEFT", icon, "TOPLEFT", -xOffset, xOffset)
            glowFrame:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", xOffset, -xOffset)
        end

    elseif glowType == "Autocast Shine" then


        LCG.AutoCastGlow_Start(icon, color, lines, frequency, scale, 0, 0, "_PREYCustomGlow")
        local glowFrame = icon["_AutoCastGlow_PREYCustomGlow"]
        if glowFrame then
            glowFrame:ClearAllPoints()
            glowFrame:SetPoint("TOPLEFT", icon, "TOPLEFT", -xOffset, xOffset)
            glowFrame:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", xOffset, -xOffset)
        end
    end


    icon._PREYCustomGlowActive = true
    activeGlowIcons[icon] = true

    return true
end


local function StartGlow(icon)
    if not icon then return end


    if icon._PREYCustomGlowActive then return end

    local viewerType = GetViewerType(icon)
    if not viewerType then return end

    local viewerSettings = GetViewerSettings(viewerType)
    if not viewerSettings then return end


    icon._PREYCustomGlowActive = true
    activeGlowIcons[icon] = true

    ApplyLibCustomGlow(icon, viewerSettings)
end


function StopGlow(icon)
    if not icon then return end


    if LCG then
        pcall(LCG.PixelGlow_Stop, icon, "_PREYCustomGlow")
        pcall(LCG.AutoCastGlow_Stop, icon, "_PREYCustomGlow")
    end

    icon._PREYCustomGlowActive = nil
    activeGlowIcons[icon] = nil
end


local function HookCDMIcon(icon)
    if not icon then return end
    if icon._PREYGlowHooked then return end

    local viewerType = GetViewerType(icon)
    if not viewerType then return end


    if icon.OnSpellActivationOverlayGlowShowEvent then
        hooksecurefunc(icon, "OnSpellActivationOverlayGlowShowEvent", function(self, spellID)

            local shouldProcess = true
            if self.NeedSpellActivationUpdate then
                pcall(function()
                    if not self:NeedSpellActivationUpdate(spellID) then
                        shouldProcess = false
                    end
                end)
            end
            if not shouldProcess then return end

            local settings = GetViewerSettings(viewerType)
            if not settings then return end

            if self:IsShown() then
                StartGlow(self)
            end
        end)
    end


    if icon.OnSpellActivationOverlayGlowHideEvent then
        hooksecurefunc(icon, "OnSpellActivationOverlayGlowHideEvent", function(self, spellID)

            local shouldProcess = true
            if self.NeedSpellActivationUpdate then
                pcall(function()
                    if not self:NeedSpellActivationUpdate(spellID) then
                        shouldProcess = false
                    end
                end)
            end
            if not shouldProcess then return end

            StopGlow(self)
        end)
    end


    if icon.RefreshOverlayGlow then
        hooksecurefunc(icon, "RefreshOverlayGlow", function(self)
            local settings = GetViewerSettings(viewerType)
            if not settings then return end

            local shouldGlow = false


            pcall(function()
                local spellID = self.GetSpellID and self:GetSpellID()
                if spellID and IsSpellOverlayed and IsSpellOverlayed(spellID) then
                    shouldGlow = true
                end
            end)


            if not shouldGlow then
                pcall(function()
                    if self.overlay and self.overlay:IsShown() then
                        shouldGlow = true
                    elseif self.SpellActivationAlert and self.SpellActivationAlert:IsShown() then
                        shouldGlow = true
                    elseif self.OverlayGlow and self.OverlayGlow:IsShown() then
                        shouldGlow = true
                    end
                end)
            end

            if shouldGlow then
                StartGlow(self)
            else
                StopGlow(self)
            end
        end)
    end

    icon._PREYGlowHooked = true
end


local function HookViewerIcons(viewerName)
    local viewer = rawget(_G, viewerName)
    if not viewer then return end

    local children = {viewer:GetChildren()}
    for _, child in ipairs(children) do
        if child and child ~= viewer.Selection then
            HookCDMIcon(child)
        end
    end
end


local function SetupViewerHooking(viewerName, trackerKey)

    local tocVersion = select(4, GetBuildInfo())
    if tocVersion and tocVersion >= 120000 then
        return
    end

    local viewer = rawget(_G, viewerName)
    if not viewer then return end


    HookViewerIcons(viewerName)


    if not viewer._PREYGlowLayoutHooked then
        pcall(function()
            viewer:HookScript("OnSizeChanged", function()
                C_Timer.After(0.1, function()
                    HookViewerIcons(viewerName)
                end)
            end)
        end)
        viewer._PREYGlowLayoutHooked = true
    end
end


local function SetupGlowHooks()


    if IS_MODERN_CLIENT then
        return
    end


    if type(ActionButton_ShowOverlayGlow) == "function" then
        hooksecurefunc("ActionButton_ShowOverlayGlow", function(button)
            if not button then return end
            local viewerType = GetViewerType(button)
            if not viewerType then return end
            local viewerSettings = GetViewerSettings(viewerType)
            if not viewerSettings then return end
            if button:IsShown() then
                StartGlow(button)
            end
        end)
    end

    if type(ActionButton_HideOverlayGlow) == "function" then
        hooksecurefunc("ActionButton_HideOverlayGlow", function(button)
            if not button then return end
            local viewerType = GetViewerType(button)
            if viewerType then
                StopGlow(button)
            end
        end)
    end


    C_Timer.After(0.5, function()
        SetupViewerHooking("EssentialCooldownViewer", "Essential")
        SetupViewerHooking("UtilityCooldownViewer", "Utility")
    end)


    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", function(self, event)

        C_Timer.After(0.2, function()
            SetupViewerHooking("EssentialCooldownViewer", "Essential")
            SetupViewerHooking("UtilityCooldownViewer", "Utility")
        end)
    end)
end


local function RefreshAllGlows()

    local iconsWithGlows = {}
    for icon, _ in pairs(activeGlowIcons) do
        if icon then
            iconsWithGlows[icon] = true
        end
    end


    for icon, _ in pairs(activeGlowIcons) do
        if icon then
            StopGlow(icon)
        end
    end
    wipe(activeGlowIcons)


    for icon, _ in pairs(iconsWithGlows) do
        if icon and icon:IsShown() then
            StartGlow(icon)
        end
    end
end


local glowHooksSetup = false

local function EnsureGlowHooks()
    if glowHooksSetup then return end
    glowHooksSetup = true
    SetupGlowHooks()
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, arg)
    if event == "ADDON_LOADED" and arg == "Blizzard_CooldownManager" then

        EnsureGlowHooks()
    elseif event == "PLAYER_LOGIN" then

        EnsureGlowHooks()
    end
end)


PREY.CustomGlows = {
    StartGlow = StartGlow,
    StopGlow = StopGlow,
    RefreshAllGlows = RefreshAllGlows,
    GetViewerType = GetViewerType,
    activeGlowIcons = activeGlowIcons,

    HookCDMIcon = HookCDMIcon,
    HookViewerIcons = HookViewerIcons,
}


_G.PreyUI_RefreshCustomGlows = RefreshAllGlows


_G.PreyUI_TestCustomGlow = function(viewerType)
    viewerType = viewerType or "Essential"
    local viewer = rawget(_G, viewerType .. "CooldownViewer")
    if viewer then
        local children = {viewer:GetChildren()}
        for i, child in ipairs(children) do
            if child:IsShown() then
                StartGlow(child)
                print("|cFF00FF00[PreyUI]|r Test glow applied to " .. viewerType .. " icon #" .. i)
                return
            end
        end
        print("|cFFFF0000[PreyUI]|r No visible icons in " .. viewerType .. " viewer")
    else
        print("|cFFFF0000[PreyUI]|r " .. viewerType .. "CooldownViewer not found")
    end
end

_G.PreyUI_StopAllCustomGlows = function()
    for icon, _ in pairs(activeGlowIcons) do
        if icon then
            StopGlow(icon)
        end
    end
    wipe(activeGlowIcons)
    print("|cFF00FF00[PreyUI]|r All custom glows stopped")
end
