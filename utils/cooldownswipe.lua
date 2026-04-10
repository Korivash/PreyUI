local _, PREY = ...


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then
        return {
            showBuffSwipe = true,
            showBuffIconSwipe = false,
            showGCDSwipe = true,
            showCooldownSwipe = true,
        }
    end
    local cs = PREYCore.db.profile.cooldownSwipe
    if not cs then
        cs = {
            showBuffSwipe = true,
            showBuffIconSwipe = false,
            showGCDSwipe = true,
            showCooldownSwipe = true,
        }
        PREYCore.db.profile.cooldownSwipe = cs
    end
    return cs
end


local function HookSetCooldown(icon)
    if not icon or not icon.Cooldown then return end
    if icon._PREY_SetCooldownHooked then return end


    local parent = icon:GetParent()
    local parentName = parent and parent:GetName()
    if parentName and (parentName:find("CooldownViewer") or parentName:find("CooldownManager")) then

        return
    end

    icon._PREY_SetCooldownHooked = true


    pcall(function()
        icon.Cooldown._PREYParentIcon = icon
    end)


    local ok = pcall(function()
        hooksecurefunc(icon.Cooldown, "SetCooldown", function(self)
            local parentIcon = self._PREYParentIcon
            if not parentIcon then return end


            if parentIcon._PREY_BypassCDHook then return end

            local settings = GetSettings()
            local showSwipe
            local auraActive = parentIcon.auraInstanceID and parentIcon.auraInstanceID > 0


        if auraActive then

            local parent = parentIcon:GetParent()
            local buffIconViewer = rawget(_G, "BuffIconCooldownViewer")
            if parent == buffIconViewer then
                showSwipe = settings.showBuffIconSwipe
            else
                showSwipe = settings.showBuffSwipe
            end

        elseif parentIcon.CooldownFlash then
            if parentIcon.CooldownFlash:IsShown() then
                showSwipe = settings.showCooldownSwipe
            else
                showSwipe = settings.showGCDSwipe
            end

        else
            showSwipe = settings.showCooldownSwipe
        end

        self:SetDrawSwipe(showSwipe)


        local showEdge
        if auraActive then
            showEdge = showSwipe
        else
            showEdge = settings.showRechargeEdge
        end
        self:SetDrawEdge(showEdge)
    end)
    end)
end


local function ProcessViewer(viewer)
    if not viewer then return end

    local children = {viewer:GetChildren()}

    for _, icon in ipairs(children) do
        if icon.Cooldown then
            HookSetCooldown(icon)
        end
    end
end


local function ApplyAllSettings()


    local tocVersion = select(4, GetBuildInfo())
    if tocVersion and tocVersion >= 120000 then

        return
    end

    local viewers = {
        rawget(_G, "EssentialCooldownViewer"),
        rawget(_G, "UtilityCooldownViewer"),
        rawget(_G, "BuffIconCooldownViewer"),
    }

    for _, viewer in ipairs(viewers) do
        ProcessViewer(viewer)


        if viewer and viewer.Layout and not viewer._PREY_LayoutHooked then
            viewer._PREY_LayoutHooked = true
            pcall(function()
                hooksecurefunc(viewer, "Layout", function()
                    C_Timer.After(0.15, function()
                        ProcessViewer(viewer)
                    end)
                end)
            end)
        end
    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, arg)
    if event == "ADDON_LOADED" and arg == "Blizzard_CooldownManager" then
        C_Timer.After(0.5, ApplyAllSettings)
        C_Timer.After(1.5, ApplyAllSettings)
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, ApplyAllSettings)
        C_Timer.After(1.5, ApplyAllSettings)
    end
end)


PREY.CooldownSwipe = {
    Apply = ApplyAllSettings,
    GetSettings = GetSettings,
}


_G.PreyUI_RefreshCooldownSwipe = function()
    ApplyAllSettings()
end
