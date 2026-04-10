local _, PREY = ...


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then
        return { hideEssential = true, hideUtility = true }
    end
    if not PREYCore.db.profile.cooldownEffects then
        PREYCore.db.profile.cooldownEffects = { hideEssential = true, hideUtility = true }
    end
    return PREYCore.db.profile.cooldownEffects
end


local function HideCooldownEffects(child)
    if not child then return end

    local effectFrames = {"PandemicIcon", "ProcStartFlipbook", "Finish"}

    for _, frameName in ipairs(effectFrames) do
        local frame = child[frameName]
        if frame then
            frame:Hide()
            frame:SetAlpha(0)


            if not frame._PreyUI_NoShow then
                frame._PreyUI_NoShow = true


                if frame.Show then
                    hooksecurefunc(frame, "Show", function(self)
                        self:Hide()
                        self:SetAlpha(0)
                    end)
                end


                if child.HookScript then
                    child:HookScript("OnShow", function(self)
                        local f = self[frameName]
                        if f then
                            f:Hide()
                            f:SetAlpha(0)
                        end
                    end)
                end
            end
        end
    end
end


local function HideBlizzardGlows(button)
    if not button then return end


    if button.SpellActivationAlert then
        button.SpellActivationAlert:Hide()
        button.SpellActivationAlert:SetAlpha(0)
    end


    if button.OverlayGlow then
        button.OverlayGlow:Hide()
        button.OverlayGlow:SetAlpha(0)
    end


    if button._ButtonGlow then
        button._ButtonGlow:Hide()
    end
end


local HideAllGlows = HideBlizzardGlows


local viewers = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer"

}

local function ProcessViewer(viewerName)
    local viewer = rawget(_G, viewerName)
    if not viewer then return end


    local settings = GetSettings()
    local shouldHide = false
    if viewerName == "EssentialCooldownViewer" then
        shouldHide = settings.hideEssential
    elseif viewerName == "UtilityCooldownViewer" then
        shouldHide = settings.hideUtility
    end

    if not shouldHide then return end

    local function ProcessIcons()
        local children = {viewer:GetChildren()}
        for _, child in ipairs(children) do
            if child:IsShown() then

                HideCooldownEffects(child)


                pcall(HideAllGlows, child)


                    child._PreyUI_EffectsHidden = true
            end
        end
    end


    ProcessIcons()


    if viewer.Layout and not viewer._PreyUI_EffectsHooked then
        viewer._PreyUI_EffectsHooked = true
        hooksecurefunc(viewer, "Layout", function()
            C_Timer.After(0.15, ProcessIcons)
        end)
    end


    if not viewer._PreyUI_EffectsShowHooked then
        viewer._PreyUI_EffectsShowHooked = true
        viewer:HookScript("OnShow", function()
            C_Timer.After(0.15, ProcessIcons)
        end)
    end
end

local function ApplyToAllViewers()
    for _, viewerName in ipairs(viewers) do
        ProcessViewer(viewerName)
    end
end


local function HideExistingBlizzardGlows()
    local viewerNames = {"EssentialCooldownViewer", "UtilityCooldownViewer"}
    for _, viewerName in ipairs(viewerNames) do
        local viewer = rawget(_G, viewerName)
        if viewer then
            local children = {viewer:GetChildren()}
            for _, child in ipairs(children) do
                pcall(HideBlizzardGlows, child)
            end
        end
    end
end

local function HookAllGlows()


    if type(ActionButton_ShowOverlayGlow) == "function" then
        hooksecurefunc("ActionButton_ShowOverlayGlow", function(button)

            if button and button:GetParent() then
                local parent = button:GetParent()
                local parentName = parent:GetName()
                if parentName and (
                    parentName:find("EssentialCooldown") or
                    parentName:find("UtilityCooldown")

                ) then


                    C_Timer.After(0.01, function()
                        if button then
                            pcall(HideBlizzardGlows, button)
                        end
                    end)
                end
            end
        end)
    end


    HideExistingBlizzardGlows()
end


local function StartMonitoring()

end


local glowHooksSetup = false

local function EnsureGlowHooks()
    if glowHooksSetup then return end
    glowHooksSetup = true
    HookAllGlows()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg)
    if event == "ADDON_LOADED" and arg == "Blizzard_CooldownManager" then
        EnsureGlowHooks()

        C_Timer.After(0.5, function()
            ApplyToAllViewers()
            HideExistingBlizzardGlows()
        end)
        C_Timer.After(1, HideExistingBlizzardGlows)
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, function()
            ApplyToAllViewers()
            HideExistingBlizzardGlows()
        end)
    elseif event == "PLAYER_LOGIN" then
        EnsureGlowHooks()
        C_Timer.After(0.5, HideExistingBlizzardGlows)
    end
end)


PREY.CooldownEffects = {
    HideCooldownEffects = HideCooldownEffects,
    HideAllGlows = HideAllGlows,
    ApplyToAllViewers = ApplyToAllViewers,
}


_G.PreyUI_RefreshCooldownEffects = function()
    ApplyToAllViewers()
end

