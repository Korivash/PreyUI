-- cooldownswipe.lua
-- Granular cooldown swipe control: Buff Duration / GCD / Cooldown swipes

local _, PREY = ...

-- Get settings from AceDB
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

-- Single unified hook for SetCooldown that handles ALL swipe types
-- This runs on EVERY cooldown update, ensuring settings are always applied
-- NOTE: In WoW 12.0.1, we must be careful not to taint secure CooldownViewer frames
local function HookSetCooldown(icon)
    if not icon or not icon.Cooldown then return end
    if icon._PREY_SetCooldownHooked then return end
    
    -- Check if this is a Blizzard CooldownViewer icon (secure frame)
    -- In 12.0.1, hooking these causes taint errors
    local parent = icon:GetParent()
    local parentName = parent and parent:GetName()
    if parentName and (parentName:find("CooldownViewer") or parentName:find("CooldownManager")) then
        -- Skip hooking Blizzard's secure CooldownViewer icons to avoid taint
        return
    end
    
    icon._PREY_SetCooldownHooked = true

    -- Store parent reference on Cooldown frame for hook access
    -- Use pcall to avoid errors on protected frames
    pcall(function()
        icon.Cooldown._PREYParentIcon = icon
    end)

    -- Wrap the hook in pcall to prevent taint propagation
    local ok = pcall(function()
        hooksecurefunc(icon.Cooldown, "SetCooldown", function(self)
            local parentIcon = self._PREYParentIcon
            if not parentIcon then return end

            -- Skip if we're the ones calling SetCooldown (recursion guard)
            if parentIcon._PREY_BypassCDHook then return end

            local settings = GetSettings()
            local showSwipe
            local auraActive = parentIcon.auraInstanceID and parentIcon.auraInstanceID > 0

        -- Swipe logic
        -- Priority 1: Buff duration (auraInstanceID > 0)
        if auraActive then
            -- Check if this icon is in BuffIconCooldownViewer (separate toggle)
            local parent = parentIcon:GetParent()
            local buffIconViewer = rawget(_G, "BuffIconCooldownViewer")
            if parent == buffIconViewer then
                showSwipe = settings.showBuffIconSwipe
            else
                showSwipe = settings.showBuffSwipe
            end
        -- Priority 2: GCD vs Cooldown (use CooldownFlash visibility)
        elseif parentIcon.CooldownFlash then
            if parentIcon.CooldownFlash:IsShown() then
                showSwipe = settings.showCooldownSwipe
            else
                showSwipe = settings.showGCDSwipe
            end
        -- Fallback: treat as cooldown
        else
            showSwipe = settings.showCooldownSwipe
        end

        self:SetDrawSwipe(showSwipe)

        -- Edge logic: Buff icons use their swipe setting, cooldowns use showRechargeEdge
        local showEdge
        if auraActive then
            showEdge = showSwipe  -- Buff icons: edge follows swipe toggle
        else
            showEdge = settings.showRechargeEdge  -- Cooldowns: separate setting
        end
        self:SetDrawEdge(showEdge)
    end)
    end) -- end pcall
end

-- Process all icons in a viewer
local function ProcessViewer(viewer)
    if not viewer then return end

    local children = {viewer:GetChildren()}

    for _, icon in ipairs(children) do
        if icon.Cooldown then
            HookSetCooldown(icon)
        end
    end
end

-- Apply settings to all CDM viewers
-- NOTE: In 12.0.1, we skip hooking Blizzard CooldownViewer frames to avoid taint
local function ApplyAllSettings()
    -- Skip CooldownViewer hooks entirely in 12.0.1 to avoid taint
    -- The swipe settings will only work on non-Blizzard cooldown frames
    local tocVersion = select(4, GetBuildInfo())
    if tocVersion and tocVersion >= 120000 then
        -- 12.0.1+ : Don't hook Blizzard CooldownViewer to avoid taint
        return
    end
    
    local viewers = {
        rawget(_G, "EssentialCooldownViewer"),
        rawget(_G, "UtilityCooldownViewer"),
        rawget(_G, "BuffIconCooldownViewer"),
    }

    for _, viewer in ipairs(viewers) do
        ProcessViewer(viewer)

        -- Hook Layout to catch new icons (wrapped in pcall for safety)
        if viewer and viewer.Layout and not viewer._PREY_LayoutHooked then
            viewer._PREY_LayoutHooked = true
            pcall(function()
                hooksecurefunc(viewer, "Layout", function()
                    C_Timer.After(0.15, function()  -- 150ms debounce for CPU efficiency
                        ProcessViewer(viewer)
                    end)
                end)
            end)
        end
    end
end

-- Initialize on addon load
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, arg)
    if event == "ADDON_LOADED" and arg == "Blizzard_CooldownManager" then
        C_Timer.After(0.5, ApplyAllSettings)
        C_Timer.After(1.5, ApplyAllSettings)  -- Apply again to catch late icons
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, ApplyAllSettings)
        C_Timer.After(1.5, ApplyAllSettings)  -- Apply again to catch late icons
    end
end)

-- Export to PREY namespace
PREY.CooldownSwipe = {
    Apply = ApplyAllSettings,
    GetSettings = GetSettings,
}

-- Global function for config panel to call
_G.PreyUI_RefreshCooldownSwipe = function()
    ApplyAllSettings()
end
