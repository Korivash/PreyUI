-- PreyUI Monk Stagger Bar
-- Real-time Brewmaster Stagger tracking with percentage display
-- Styled to match PreyUI resource bars with smooth animations

local ADDON_NAME, ns = ...
local LSM = LibStub("LibSharedMedia-3.0")

-- Reference the global PreyUI addon (must exist from init.lua)
local PreyUI = _G.PreyUI

-- Get addon reference (PreyUI is a global AceAddon)
local function GetAddon()
    return _G.PreyUI
end

-- Stagger Spell IDs
local STAGGER_LIGHT = 124275
local STAGGER_MODERATE = 124274
local STAGGER_HEAVY = 124273
local BREWMASTER_SPEC = 268

-- Pixel-perfect scaling helper
local function Scale(x)
    local addon = GetAddon()
    if addon and addon.Scale then return addon:Scale(x) end
    return x
end

local function GetGeneralFont()
    local addon = GetAddon()
    if addon and addon.db and addon.db.profile and addon.db.profile.general then
        local fontName = addon.db.profile.general.font or "Friz Quadrata TT"
        return LSM:Fetch("font", fontName) or "Fonts\\FRIZQT__.TTF"
    end
    return "Fonts\\FRIZQT__.TTF"
end

local function GetGeneralFontOutline()
    local addon = GetAddon()
    if addon and addon.db and addon.db.profile and addon.db.profile.general then
        return addon.db.profile.general.fontOutline or "OUTLINE"
    end
    return "OUTLINE"
end

local function GetBarTexture(cfg)
    if cfg and cfg.texture then
        local tex = LSM:Fetch("statusbar", cfg.texture)
        if tex then return tex end
    end
    local preyTex = LSM:Fetch("statusbar", "Prey")
    if preyTex then return preyTex end
    return "Interface\\TargetingFrame\\UI-StatusBar"
end

-- Helper to abbreviate numbers
local function AbbreviateNumbers(value)
    if not value then return "0" end
    local absValue = math.abs(value)
    local sign = value < 0 and "-" or ""
    if absValue >= 1000000000 then return sign .. string.format("%.1fB", absValue / 1000000000)
    elseif absValue >= 1000000 then return sign .. string.format("%.1fM", absValue / 1000000)
    elseif absValue >= 1000 then return sign .. string.format("%.1fK", absValue / 1000)
    else return sign .. tostring(math.floor(absValue)) end
end

-- Default configuration
local StaggerDefaults = {
    enabled = true, width = 250, height = 10, borderSize = 1, scale = 1, alpha = 1,
    useRawPixels = true, offsetX = 0, offsetY = -150, unlocked = false,
    showPercent = true, showAbsoluteValue = false, showLabel = false,
    textSize = 11, textX = 0, textY = 0, labelText = "STAGGER",
    texture = "Prey", bgColor = { 0.08, 0.08, 0.08, 0.9 },
    colors = {
        light = { 0.52, 1.0, 0.52, 1 },
        moderate = { 1.0, 0.98, 0.72, 1 },
        heavy = { 1.0, 0.42, 0.42, 1 },
    },
    thresholds = { yellow = 30, red = 60 },
    pulseOnHeavy = true, smoothAnimation = true, animationSpeed = 0.15,
    showThresholdTicks = true, tickThickness = 2, tickColor = { 0.3, 0.3, 0.3, 0.8 },
    glowOnCritical = true, criticalThreshold = 80,
}

local StaggerBar = nil
local lastStaggerValue, targetStaggerValue, updateElapsed = 0, 0, 0
local UPDATE_INTERVAL = 0.016

function PreyUI:InitStaggerBar()
    if self.db.profile.stagger == nil then
        self.db.profile.stagger = CopyTable(StaggerDefaults)
    else
        for key, value in pairs(StaggerDefaults) do
            if self.db.profile.stagger[key] == nil then
                self.db.profile.stagger[key] = type(value) == "table" and CopyTable(value) or value
            end
        end
    end
    self:CreateStaggerBar()
    self:UpdateStaggerBarVisibility()
    
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_AURA")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:SetScript("OnEvent", function(_, event, unit)
        local addon = _G.PreyUI
        if not addon then return end
        if event == "UNIT_AURA" or event == "UNIT_MAXHEALTH" then
            if unit == "player" then addon:UpdateStagger() end
        else
            addon:UpdateStaggerBarVisibility()
            addon:UpdateStagger()
        end
    end)
    self.StaggerEventFrame = frame
end

function PreyUI:CreateStaggerBar()
    local cfg = self.db.profile.stagger
    if StaggerBar then StaggerBar:Hide(); StaggerBar:SetParent(nil) end
    
    local bar = CreateFrame("Frame", "PreyUI_StaggerBar", UIParent)
    bar:SetFrameStrata("MEDIUM")
    bar:SetFrameLevel(10)
    
    local width = cfg.useRawPixels and cfg.width or Scale(cfg.width)
    local height = cfg.useRawPixels and cfg.height or Scale(cfg.height)
    bar:SetSize(width, height)
    bar:SetScale(cfg.scale)
    bar:SetAlpha(cfg.alpha)
    
    local offsetX = cfg.useRawPixels and cfg.offsetX or Scale(cfg.offsetX)
    local offsetY = cfg.useRawPixels and cfg.offsetY or Scale(cfg.offsetY)
    bar:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self)
        local addon = _G.PreyUI
        if addon and addon.db.profile.stagger.unlocked then self:StartMoving() end
    end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local selfX, selfY = self:GetCenter()
        local parentX, parentY = UIParent:GetCenter()
        local addon = _G.PreyUI
        if selfX and selfY and parentX and parentY and addon then
            addon.db.profile.stagger.offsetX = math.floor(selfX - parentX + 0.5)
            addon.db.profile.stagger.offsetY = math.floor(selfY - parentY + 0.5)
        end
    end)
    
    bar.Background = bar:CreateTexture(nil, "BACKGROUND")
    bar.Background:SetAllPoints()
    local bgc = cfg.bgColor
    bar.Background:SetColorTexture(bgc[1], bgc[2], bgc[3], bgc[4] or 0.9)
    
    bar.StatusBar = CreateFrame("StatusBar", nil, bar)
    bar.StatusBar:SetAllPoints()
    bar.StatusBar:SetMinMaxValues(0, 100)
    bar.StatusBar:SetValue(0)
    bar.StatusBar:SetStatusBarTexture(GetBarTexture(cfg))
    bar.StatusBar:SetFrameLevel(bar:GetFrameLevel())
    
    -- Border intentionally disabled to keep the stagger bar clean (no white frame).
    bar.Border = CreateFrame("Frame", nil, bar)
    bar.Border:Hide()
    
    bar.TextFrame = CreateFrame("Frame", nil, bar)
    bar.TextFrame:SetAllPoints()
    bar.TextFrame:SetFrameStrata("MEDIUM")
    bar.TextFrame:SetFrameLevel(bar:GetFrameLevel() + 2)
    
    bar.TextValue = bar.TextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.TextValue:SetPoint("CENTER", bar.TextFrame, "CENTER", Scale(cfg.textX or 0), Scale(cfg.textY or 0))
    bar.TextValue:SetJustifyH("CENTER")
    bar.TextValue:SetFont(GetGeneralFont(), Scale(cfg.textSize or 11), GetGeneralFontOutline())
    bar.TextValue:SetShadowOffset(1, -1)
    bar.TextValue:SetShadowColor(0, 0, 0, 1)
    
    bar.Label = bar.TextFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.Label:SetPoint("BOTTOM", bar, "TOP", 0, 4)
    bar.Label:SetFont(GetGeneralFont(), Scale((cfg.textSize or 11) - 2), GetGeneralFontOutline())
    bar.Label:SetShadowOffset(1, -1)
    bar.Label:SetShadowColor(0, 0, 0, 1)
    bar.Label:SetText(cfg.labelText or "STAGGER")
    bar.Label:SetTextColor(0.8, 0.8, 0.8, 1)
    if not cfg.showLabel then bar.Label:Hide() end
    
    bar.ThresholdTicks = {}
    if cfg.showThresholdTicks then
        local yellowTick = bar:CreateTexture(nil, "OVERLAY")
        yellowTick:SetColorTexture(cfg.tickColor[1], cfg.tickColor[2], cfg.tickColor[3], cfg.tickColor[4] or 0.8)
        local yellowPos = (cfg.thresholds.yellow / 100) * width
        yellowTick:SetSize(cfg.tickThickness or 2, height)
        yellowTick:SetPoint("LEFT", bar, "LEFT", yellowPos - ((cfg.tickThickness or 2) / 2), 0)
        bar.ThresholdTicks.yellow = yellowTick
        
        local redTick = bar:CreateTexture(nil, "OVERLAY")
        redTick:SetColorTexture(cfg.tickColor[1], cfg.tickColor[2], cfg.tickColor[3], cfg.tickColor[4] or 0.8)
        local redPos = (cfg.thresholds.red / 100) * width
        redTick:SetSize(cfg.tickThickness or 2, height)
        redTick:SetPoint("LEFT", bar, "LEFT", redPos - ((cfg.tickThickness or 2) / 2), 0)
        bar.ThresholdTicks.red = redTick
    end
    
    bar.PulseAnim = bar:CreateAnimationGroup()
    local pulseAlpha = bar.PulseAnim:CreateAnimation("Alpha")
    pulseAlpha:SetFromAlpha(1)
    pulseAlpha:SetToAlpha(0.4)
    pulseAlpha:SetDuration(0.4)
    pulseAlpha:SetSmoothing("IN_OUT")
    bar.PulseAnim:SetLooping("BOUNCE")
    
    bar.Glow = bar:CreateTexture(nil, "BACKGROUND", nil, -1)
    bar.Glow:SetPoint("TOPLEFT", bar, -8, 8)
    bar.Glow:SetPoint("BOTTOMRIGHT", bar, 8, -8)
    bar.Glow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    bar.Glow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
    bar.Glow:SetVertexColor(1, 0.2, 0.2, 0)
    bar.Glow:Hide()
    
    bar.GlowAnim = bar.Glow:CreateAnimationGroup()
    local glowPulse = bar.GlowAnim:CreateAnimation("Alpha")
    glowPulse:SetFromAlpha(0.6)
    glowPulse:SetToAlpha(0.2)
    glowPulse:SetDuration(0.5)
    glowPulse:SetSmoothing("IN_OUT")
    bar.GlowAnim:SetLooping("BOUNCE")
    
    bar:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Stagger", 1, 1, 1)
        GameTooltip:AddDoubleLine("Current:", string.format("%s (%.1f%%)", AbbreviateNumbers(self.currentStagger or 0), self.staggerPercent or 0), 0.8, 0.8, 0.8, 1, 1, 1)
        GameTooltip:AddDoubleLine("Max Health:", AbbreviateNumbers(UnitHealthMax("player") or 1), 0.8, 0.8, 0.8, 1, 1, 1)
        local addon = _G.PreyUI
        local c = addon and addon.db and addon.db.profile.stagger
        if c then
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Yellow:", c.thresholds.yellow .. "%", 0.6, 0.6, 0.6, 1, 0.9, 0)
            GameTooltip:AddDoubleLine("Red:", c.thresholds.red .. "%", 0.6, 0.6, 0.6, 1, 0.3, 0.3)
            GameTooltip:AddLine(c.unlocked and "\nDrag to move" or "\n/stagger unlock", 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    bar:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    if cfg.smoothAnimation then
        bar:SetScript("OnUpdate", function(self, elapsed)
            updateElapsed = updateElapsed + elapsed
            if updateElapsed >= UPDATE_INTERVAL then
                updateElapsed = 0
                if math.abs(targetStaggerValue - lastStaggerValue) > 0.1 then
                    local addon = _G.PreyUI
                    local speed = (addon and addon.db and addon.db.profile.stagger.animationSpeed) or 0.15
                    lastStaggerValue = lastStaggerValue + (targetStaggerValue - lastStaggerValue) * (speed * 4)
                    self.StatusBar:SetValue(lastStaggerValue)
                end
            end
        end)
    end
    
    bar.currentStagger = 0
    bar.staggerPercent = 0
    StaggerBar = bar
    self.StaggerFrame = bar
    self:UpdateStagger()
end

function PreyUI:UpdateStaggerBarVisibility()
    if not StaggerBar then return end
    local cfg = self.db.profile.stagger
    local _, class = UnitClass("player")
    local specID = GetSpecializationInfo(GetSpecialization() or 0) or 0
    local isBrewmaster = (class == "MONK" and specID == BREWMASTER_SPEC)
    if cfg.enabled and isBrewmaster then
        StaggerBar:Show()
        self:UpdateStagger()
    else
        StaggerBar:Hide()
    end
end

local function GetStaggerAmount()
    -- UnitStagger is the combat-safe API for stagger amount in 12.0.1
    local stagger = UnitStagger("player")
    if stagger and stagger > 0 then return stagger end
    
    -- Out of combat fallback: try to get stagger from aura using combat-safe methods
    -- In 12.0.1, aura.points is a forbidden table, so we use UnitStagger exclusively
    -- The stagger amount should always be available via UnitStagger for Brewmasters
    return 0
end

function PreyUI:UpdateStagger()
    if not StaggerBar or not StaggerBar:IsShown() then return end
    local cfg = self.db.profile.stagger
    local bar = StaggerBar
    
    local currentStagger = GetStaggerAmount()
    local maxHealth = UnitHealthMax("player") or 1
    local percent = (currentStagger / maxHealth) * 100
    local displayPercent = math.min(percent, 100)
    
    bar.currentStagger = currentStagger
    bar.staggerPercent = percent
    
    if cfg.smoothAnimation then
        targetStaggerValue = displayPercent
    else
        bar.StatusBar:SetValue(displayPercent)
        lastStaggerValue = displayPercent
        targetStaggerValue = displayPercent
    end
    
    local color, staggerLevel
    if percent >= cfg.thresholds.red then
        color = cfg.colors.heavy
        staggerLevel = "heavy"
    elseif percent >= cfg.thresholds.yellow then
        color = cfg.colors.moderate
        staggerLevel = "moderate"
    else
        color = cfg.colors.light
        staggerLevel = "light"
    end
    
    bar.StatusBar:SetStatusBarColor(color[1], color[2], color[3])
    
    if cfg.showPercent then
        local text = string.format("%.1f%%", percent)
        if cfg.showAbsoluteValue then text = text .. " (" .. AbbreviateNumbers(currentStagger) .. ")" end
        bar.TextValue:SetText(text)
        bar.TextValue:SetTextColor(color[1], color[2], color[3])
        bar.TextValue:Show()
    else
        bar.TextValue:Hide()
    end
    
    if cfg.showLabel then bar.Label:Show() else bar.Label:Hide() end
    
    if cfg.pulseOnHeavy and staggerLevel == "heavy" then
        if not bar.PulseAnim:IsPlaying() then bar.PulseAnim:Play() end
    else
        if bar.PulseAnim:IsPlaying() then bar.PulseAnim:Stop(); bar:SetAlpha(cfg.alpha) end
    end
    
    if cfg.glowOnCritical and percent >= (cfg.criticalThreshold or 80) then
        bar.Glow:Show()
        bar.Glow:SetVertexColor(color[1], color[2], color[3], 0.6)
        if not bar.GlowAnim:IsPlaying() then bar.GlowAnim:Play() end
    else
        bar.Glow:Hide()
        if bar.GlowAnim:IsPlaying() then bar.GlowAnim:Stop() end
    end
end

function PreyUI:RefreshStaggerBar()
    if not StaggerBar then return end
    local cfg = self.db.profile.stagger
    local bar = StaggerBar
    
    local width = cfg.useRawPixels and cfg.width or Scale(cfg.width)
    local height = cfg.useRawPixels and cfg.height or Scale(cfg.height)
    bar:SetSize(width, height)
    bar:SetScale(cfg.scale)
    bar:SetAlpha(cfg.alpha)
    
    bar:ClearAllPoints()
    local offsetX = cfg.useRawPixels and cfg.offsetX or Scale(cfg.offsetX)
    local offsetY = cfg.useRawPixels and cfg.offsetY or Scale(cfg.offsetY)
    bar:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    
    local bgc = cfg.bgColor
    bar.Background:SetColorTexture(bgc[1], bgc[2], bgc[3], bgc[4] or 0.9)
    bar.StatusBar:SetStatusBarTexture(GetBarTexture(cfg))
    
    -- Border intentionally disabled (kept hidden on refresh).
    if bar.Border then
        bar.Border:Hide()
    end
    
    bar.TextValue:SetFont(GetGeneralFont(), Scale(cfg.textSize or 11), GetGeneralFontOutline())
    bar.TextValue:ClearAllPoints()
    bar.TextValue:SetPoint("CENTER", bar.TextFrame, "CENTER", Scale(cfg.textX or 0), Scale(cfg.textY or 0))
    bar.Label:SetFont(GetGeneralFont(), Scale((cfg.textSize or 11) - 2), GetGeneralFontOutline())
    bar.Label:SetText(cfg.labelText or "STAGGER")
    
    if bar.ThresholdTicks then
        if cfg.showThresholdTicks then
            if bar.ThresholdTicks.yellow then
                local yellowPos = (cfg.thresholds.yellow / 100) * width
                bar.ThresholdTicks.yellow:ClearAllPoints()
                bar.ThresholdTicks.yellow:SetSize(cfg.tickThickness or 2, height)
                bar.ThresholdTicks.yellow:SetPoint("LEFT", bar, "LEFT", yellowPos - ((cfg.tickThickness or 2) / 2), 0)
                bar.ThresholdTicks.yellow:SetColorTexture(cfg.tickColor[1], cfg.tickColor[2], cfg.tickColor[3], cfg.tickColor[4] or 0.8)
                bar.ThresholdTicks.yellow:Show()
            end
            if bar.ThresholdTicks.red then
                local redPos = (cfg.thresholds.red / 100) * width
                bar.ThresholdTicks.red:ClearAllPoints()
                bar.ThresholdTicks.red:SetSize(cfg.tickThickness or 2, height)
                bar.ThresholdTicks.red:SetPoint("LEFT", bar, "LEFT", redPos - ((cfg.tickThickness or 2) / 2), 0)
                bar.ThresholdTicks.red:SetColorTexture(cfg.tickColor[1], cfg.tickColor[2], cfg.tickColor[3], cfg.tickColor[4] or 0.8)
                bar.ThresholdTicks.red:Show()
            end
        else
            if bar.ThresholdTicks.yellow then bar.ThresholdTicks.yellow:Hide() end
            if bar.ThresholdTicks.red then bar.ThresholdTicks.red:Hide() end
        end
    end
    
    if cfg.smoothAnimation then
        bar:SetScript("OnUpdate", function(self, elapsed)
            updateElapsed = updateElapsed + elapsed
            if updateElapsed >= UPDATE_INTERVAL then
                updateElapsed = 0
                if math.abs(targetStaggerValue - lastStaggerValue) > 0.1 then
                    local addon = _G.PreyUI
                    local speed = (addon and addon.db and addon.db.profile.stagger.animationSpeed) or 0.15
                    lastStaggerValue = lastStaggerValue + (targetStaggerValue - lastStaggerValue) * (speed * 4)
                    self.StatusBar:SetValue(lastStaggerValue)
                end
            end
        end)
    else
        bar:SetScript("OnUpdate", nil)
    end
    self:UpdateStagger()
end

-- Slash commands (basic quick access - full options in /prey menu)
SLASH_STAGGER1 = "/stagger"
SlashCmdList["STAGGER"] = function(msg)
    local addon = _G.PreyUI
    local function PrintMsg(text)
        if addon and addon.Print then
            addon:Print(text)
        else
            print("|cfffb7185PreyUI:|r " .. text)
        end
    end
    
    if not addon or not addon.db then
        PrintMsg("PreyUI not fully loaded yet")
        return
    end
    
    if msg == "unlock" then
        addon.db.profile.stagger.unlocked = not addon.db.profile.stagger.unlocked
        PrintMsg("Stagger Bar " .. (addon.db.profile.stagger.unlocked and "unlocked" or "locked"))
        if addon.RefreshStaggerBar then addon:RefreshStaggerBar() end
    elseif msg == "reset" then
        addon.db.profile.stagger = CopyTable(StaggerDefaults)
        addon:CreateStaggerBar()
        addon:UpdateStaggerBarVisibility()
        PrintMsg("Stagger Bar reset to defaults")
    elseif msg == "toggle" then
        addon.db.profile.stagger.enabled = not addon.db.profile.stagger.enabled
        addon:UpdateStaggerBarVisibility()
        PrintMsg("Stagger Bar " .. (addon.db.profile.stagger.enabled and "enabled" or "disabled"))
    elseif msg == "options" or msg == "config" or msg == "" then
        PrintMsg("Use /prey and go to 'Stagger Bar' tab for full options")
        -- Try to open options if available
        if addon.GUI and addon.GUI.Toggle then
            addon.GUI:Toggle()
        end
    else
        PrintMsg("Stagger commands: unlock, reset, toggle, options")
        PrintMsg("For full customization, use /prey > Stagger Bar tab")
    end
end

-- Store defaults for external access (safely)
if _G.PreyUI then
    _G.PreyUI.StaggerDefaults = StaggerDefaults
end
