local addonName, ns = ...

---------------------------------------------------------------------------
-- PLAYER POWER BAR ALT SKINNING
---------------------------------------------------------------------------
-- Replaces the encounter/quest-specific power bar (PlayerPowerBarAlt)
-- with a clean PREY-styled bar. Used for: Atramedes sound, Cho'gall
-- corruption, Darkmoon games, etc.
--
-- Approach: Hide Blizzard's bar, create custom replacement

local FONT_FLAGS = "OUTLINE"

-- Bar dimensions
local BAR_WIDTH = 250
local BAR_HEIGHT = 20

-- Locals for performance
local floor = math.floor
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local GetUnitPowerBarInfo = GetUnitPowerBarInfo
local GetUnitPowerBarStrings = GetUnitPowerBarStrings
local ALTERNATE_POWER_INDEX = Enum.PowerType.Alternate or 10

-- Module state
local PREYAltPowerBar = nil
local powerBarMover = nil
local isEnabled = false

---------------------------------------------------------------------------
-- DATABASE ACCESS
---------------------------------------------------------------------------

local function GetDB()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    return PREYCore and PREYCore.db and PREYCore.db.profile or {}
end

local function GetBarPosition()
    local db = GetDB()
    return db.powerBarAltPosition
end

local function SaveBarPosition(point, relPoint, x, y)
    local db = GetDB()
    db.powerBarAltPosition = { point = point, relPoint = relPoint, x = x, y = y }
end

---------------------------------------------------------------------------
-- TOOLTIP HANDLING
---------------------------------------------------------------------------

local function OnEnter(self)
    if not self:IsVisible() or GameTooltip:IsForbidden() then return end

    GameTooltip:ClearAllPoints()
    GameTooltip_SetDefaultAnchor(GameTooltip, self)

    if self.powerName and self.powerTooltip then
        GameTooltip:SetText(self.powerName, 1, 1, 1)
        GameTooltip:AddLine(self.powerTooltip, nil, nil, nil, true)
        GameTooltip:Show()
    end
end

local function OnLeave()
    GameTooltip:Hide()
end

---------------------------------------------------------------------------
-- BAR UPDATE
---------------------------------------------------------------------------

local function UpdateBar(self)
    local barInfo = GetUnitPowerBarInfo("player")

    if barInfo then
        local powerName, powerTooltip = GetUnitPowerBarStrings("player")
        local power = UnitPower("player", ALTERNATE_POWER_INDEX)
        local maxPower = UnitPowerMax("player", ALTERNATE_POWER_INDEX)

        -- Calculate percentage safely (handles secret values from Midnight API)
        -- BUG-004: UnitPower can return secret values that pass nil checks but fail arithmetic
        local perc = 0
        local calcOk, calcResult = pcall(function()
            if power and maxPower and maxPower > 0 then
                return floor(power / maxPower * 100)
            end
            return 0
        end)
        if calcOk and calcResult then
            perc = calcResult
        end

        self.powerName = powerName
        self.powerTooltip = powerTooltip
        self.powerValue = power
        self.powerMaxValue = maxPower
        self.powerPercent = perc

        -- StatusBar handles secret values natively in SetMinMaxValues/SetValue
        self:SetMinMaxValues(barInfo.minPower or 0, maxPower or 0)
        self:SetValue(power or 0)

        -- Update text (perc is guaranteed safe from pcall)
        if powerName then
            self.text:SetText(string.format("%s: %d%%", powerName, perc))
        else
            self.text:SetText(string.format("%d%%", perc))
        end

        self:Show()
    else
        self.powerName = nil
        self.powerTooltip = nil
        self.powerValue = nil
        self.powerMaxValue = nil
        self.powerPercent = nil

        self:Hide()
    end
end

local function OnEvent(self, event, arg1, arg2)
    if event == "UNIT_POWER_UPDATE" then
        if arg1 == "player" and arg2 == "ALTERNATE" then
            UpdateBar(self)
        end
    elseif event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" then
        if arg1 == "player" then
            UpdateBar(self)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        UpdateBar(self)
    end
end

---------------------------------------------------------------------------
-- BAR CREATION
---------------------------------------------------------------------------

local function CreatePREYAltPowerBar()
    -- Get skin colors
    local PREY = _G.PreyUI
    local sr, sg, sb, sa = 0.820, 0.180, 0.220, 1
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95

    if PREY and PREY.GetSkinColor then
        sr, sg, sb, sa = PREY:GetSkinColor()
    end
    if PREY and PREY.GetSkinBgColor then
        bgr, bgg, bgb, bga = PREY:GetSkinBgColor()
    end

    -- Create the status bar
    local bar = CreateFrame("StatusBar", "PreyUI_AltPowerBar", UIParent)
    bar:SetSize(BAR_WIDTH, BAR_HEIGHT)

    -- Load saved position or use default
    local pos = GetBarPosition()
    if pos and pos.point then
        bar:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    else
        bar:SetPoint("TOP", UIParent, "TOP", 0, -100)
    end

    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    bar:SetStatusBarColor(sr, sg, sb)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    bar:Hide()

    -- Make movable (controlled by mover overlay)
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)

    -- Create backdrop
    bar.backdrop = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.backdrop:SetPoint("TOPLEFT", -2, 2)
    bar.backdrop:SetPoint("BOTTOMRIGHT", 2, -2)
    bar.backdrop:SetFrameLevel(bar:GetFrameLevel() - 1)
    bar.backdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    bar.backdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    bar.backdrop:SetBackdropBorderColor(sr, sg, sb, sa)

    -- Create text
    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.text:SetPoint("CENTER", bar, "CENTER")
    bar.text:SetFont(STANDARD_TEXT_FONT, 11, FONT_FLAGS)
    bar.text:SetTextColor(1, 1, 1)
    bar.text:SetJustifyH("CENTER")

    -- Store colors for refresh and mark as skinned
    bar.preySkinColor = { sr, sg, sb, sa }
    bar.preyBgColor = { bgr, bgg, bgb, bga }
    bar.preySkinned = true

    -- Tooltip support
    bar:EnableMouse(true)
    bar:SetScript("OnEnter", OnEnter)
    bar:SetScript("OnLeave", OnLeave)

    -- Event handling
    bar:RegisterEvent("UNIT_POWER_UPDATE")
    bar:RegisterEvent("UNIT_POWER_BAR_SHOW")
    bar:RegisterEvent("UNIT_POWER_BAR_HIDE")
    bar:RegisterEvent("PLAYER_ENTERING_WORLD")
    bar:SetScript("OnEvent", OnEvent)

    return bar
end

---------------------------------------------------------------------------
-- BLIZZARD BAR HIDING
---------------------------------------------------------------------------

local blizzardBarHooked = false

local function HideBlizzardBar()
    local bar = _G.PlayerPowerBarAlt
    if bar then
        bar:UnregisterAllEvents()
        bar:Hide()
        bar:SetAlpha(0)
    end

    -- Hook UnitPowerBarAlt_SetUp to catch bar creation/setup
    -- IMPORTANT: Skip during combat to avoid taint - let Blizzard's bar show if needed
    if not blizzardBarHooked and _G.UnitPowerBarAlt_SetUp then
        hooksecurefunc("UnitPowerBarAlt_SetUp", function(self)
            if InCombatLockdown() then return end  -- Avoid taint during combat
            if self == _G.PlayerPowerBarAlt and isEnabled then
                self:UnregisterAllEvents()
                self:Hide()
                self:SetAlpha(0)
            end
        end)
        blizzardBarHooked = true
    end
end

---------------------------------------------------------------------------
-- REFRESH COLORS
---------------------------------------------------------------------------

local function RefreshPowerBarAltColors()
    if not PREYAltPowerBar then return end

    local PREY = _G.PreyUI
    local sr, sg, sb, sa = 0.820, 0.180, 0.220, 1
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95

    if PREY and PREY.GetSkinColor then
        sr, sg, sb, sa = PREY:GetSkinColor()
    end
    if PREY and PREY.GetSkinBgColor then
        bgr, bgg, bgb, bga = PREY:GetSkinBgColor()
    end

    PREYAltPowerBar:SetStatusBarColor(sr, sg, sb)
    PREYAltPowerBar.backdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    PREYAltPowerBar.backdrop:SetBackdropBorderColor(sr, sg, sb, sa)

    PREYAltPowerBar.preySkinColor = { sr, sg, sb, sa }
    PREYAltPowerBar.preyBgColor = { bgr, bgg, bgb, bga }

    -- Update mover colors if it exists
    if powerBarMover then
        powerBarMover:SetBackdropColor(sr, sg, sb, 0.3)
        powerBarMover:SetBackdropBorderColor(sr, sg, sb, 1)
    end
end

_G.PreyUI_RefreshPowerBarAltColors = RefreshPowerBarAltColors

---------------------------------------------------------------------------
-- MOVER OVERLAY
---------------------------------------------------------------------------

local function CreateMover()
    if powerBarMover then return end
    if not PREYAltPowerBar then return end

    -- Get skin colors for mover
    local PREY = _G.PreyUI
    local sr, sg, sb, sa = 0.820, 0.180, 0.220, 1
    if PREY and PREY.GetSkinColor then
        sr, sg, sb, sa = PREY:GetSkinColor()
    end

    -- Create mover overlay
    powerBarMover = CreateFrame("Frame", "PreyUI_AltPowerBarMover", UIParent, "BackdropTemplate")
    powerBarMover:SetSize(BAR_WIDTH + 4, BAR_HEIGHT + 4)
    powerBarMover:SetPoint("CENTER", PREYAltPowerBar, "CENTER")
    powerBarMover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    powerBarMover:SetBackdropColor(sr, sg, sb, 0.3)
    powerBarMover:SetBackdropBorderColor(sr, sg, sb, 1)
    powerBarMover:EnableMouse(true)
    powerBarMover:SetMovable(true)
    powerBarMover:RegisterForDrag("LeftButton")
    powerBarMover:SetFrameStrata("FULLSCREEN_DIALOG")
    powerBarMover:Hide()

    -- Mover label
    powerBarMover.text = powerBarMover:CreateFontString(nil, "OVERLAY")
    powerBarMover.text:SetPoint("CENTER")
    powerBarMover.text:SetFont(STANDARD_TEXT_FONT, 10, FONT_FLAGS)
    powerBarMover.text:SetText("Encounter Power Bar")
    powerBarMover.text:SetTextColor(1, 1, 1)

    -- Drag handlers
    powerBarMover:SetScript("OnDragStart", function(self)
        PREYAltPowerBar:StartMoving()
    end)

    powerBarMover:SetScript("OnDragStop", function(self)
        PREYAltPowerBar:StopMovingOrSizing()
        -- Save position
        local point, _, relPoint, x, y = PREYAltPowerBar:GetPoint()
        SaveBarPosition(point, relPoint, x, y)
        -- Re-anchor mover to bar
        self:ClearAllPoints()
        self:SetPoint("CENTER", PREYAltPowerBar, "CENTER")
    end)
end

---------------------------------------------------------------------------
-- MOVER TOGGLE (called from options)
---------------------------------------------------------------------------

local function ShowMover()
    CreateMover()
    if powerBarMover then
        powerBarMover:Show()
        -- Show the bar too so user can see what they're positioning
        if PREYAltPowerBar then
            PREYAltPowerBar:Show()
            -- Show placeholder if no active power bar
            if not PREYAltPowerBar.powerName then
                PREYAltPowerBar.text:SetText("Encounter Power Bar")
                PREYAltPowerBar:SetMinMaxValues(0, 100)
                PREYAltPowerBar:SetValue(50)
            end
        end
    end
end

local function HideMover()
    if powerBarMover then
        powerBarMover:Hide()
    end
    -- Re-update bar visibility based on actual power state
    if PREYAltPowerBar then
        UpdateBar(PREYAltPowerBar)
    end
end

local function ToggleMover()
    if powerBarMover and powerBarMover:IsShown() then
        HideMover()
    else
        ShowMover()
    end
end

-- Expose toggle function globally
_G.PreyUI_TogglePowerBarAltMover = ToggleMover

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

local function Initialize()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general

    if not settings or not settings.skinPowerBarAlt then return end
    if isEnabled then return end

    -- Hide Blizzard's bar
    HideBlizzardBar()

    -- Create our bar
    PREYAltPowerBar = CreatePREYAltPowerBar()

    -- Initial update
    UpdateBar(PREYAltPowerBar)

    isEnabled = true
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    -- Delay slightly to ensure PREY is loaded
    C_Timer.After(0.1, Initialize)
end)
