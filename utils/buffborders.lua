-- buffborders.lua
-- Adds configurable black borders around buff/debuff icons in the top right

local _, PREY = ...

-- Get settings from AceDB
local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if not PREYCore or not PREYCore.db or not PREYCore.db.profile then
        return nil
    end
    -- Ensure buffBorders table exists
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

-- Border colors
local BORDER_COLOR_BUFF = {0, 0, 0, 1}        -- Black for buffs
local BORDER_COLOR_DEBUFF = {0.5, 0, 0, 1}    -- Dark red for debuffs

-- Track which buttons we've already bordered
local borderedButtons = {}

-- Add border to a single buff/debuff button
local function AddBorderToButton(button, isBuff)
    if not button or borderedButtons[button] then
        return
    end
    
    -- Check if borders are enabled for this type
    local settings = GetSettings()
    if not settings then return end
    if isBuff and not settings.enableBuffs then
        return
    end
    if not isBuff and not settings.enableDebuffs then
        return
    end
    
    -- Find the icon texture (the actual square icon, not the full button frame)
    local icon = button.Icon or button.icon
    if not icon then
        return
    end

    -- Validate button is a proper frame that supports CreateTexture
    -- (Boss fight frames may have Icon but not be valid Frame objects)
    if not button.CreateTexture or type(button.CreateTexture) ~= "function" then
        return
    end
    
    local borderSize = settings.borderSize or 2
    
    -- Choose border color based on buff/debuff
    local borderColor = isBuff and BORDER_COLOR_BUFF or BORDER_COLOR_DEBUFF
    
    -- Create 4 separate edge textures for clean borders around the ICON only
    if not button.preyBorderTop then
        -- Top border
        button.preyBorderTop = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.preyBorderTop:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        button.preyBorderTop:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        
        -- Bottom border
        button.preyBorderBottom = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.preyBorderBottom:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        button.preyBorderBottom:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        
        -- Left border
        button.preyBorderLeft = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.preyBorderLeft:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
        button.preyBorderLeft:SetPoint("BOTTOMLEFT", icon, "BOTTOMLEFT", 0, 0)
        
        -- Right border
        button.preyBorderRight = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.preyBorderRight:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 0, 0)
        button.preyBorderRight:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    end
    
    -- Update border color based on type
    button.preyBorderTop:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    button.preyBorderBottom:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    button.preyBorderLeft:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    button.preyBorderRight:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    
    -- Update border size
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

-- Hide borders on a button
local function HideBorderOnButton(button)
    if button.preyBorderTop then button.preyBorderTop:Hide() end
    if button.preyBorderBottom then button.preyBorderBottom:Hide() end
    if button.preyBorderLeft then button.preyBorderLeft:Hide() end
    if button.preyBorderRight then button.preyBorderRight:Hide() end
end

-- Apply font settings to duration text
local function ApplyFontSettings(button)
    if not button then return end

    local settings = GetSettings()
    if not settings then return end

    -- Get font and outline from general settings
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

    -- Duration text (timer showing remaining time)
    local duration = button.Duration or button.duration
    if duration and duration.SetFont then
        local fontSize = settings.fontSize or 12
        duration:SetFont(generalFont, fontSize, generalOutline)
    end
end

-- Process all aura buttons in a container
local function ProcessAuraContainer(container, isBuff)
    if not container then return end
    
    -- Get all child frames
    local frames = {container:GetChildren()}
    for _, frame in ipairs(frames) do
        -- Check if this looks like an aura button
        if frame.Icon or frame.icon then
            AddBorderToButton(frame, isBuff)
            ApplyFontSettings(frame)
        end
    end
end

-- Hide/show entire BuffFrame or DebuffFrame based on settings
local function ApplyFrameHiding()
    local settings = GetSettings()
    if not settings then return end

    -- BuffFrame hiding (simple Hide + Show hook, no EnableMouse)
    if BuffFrame then
        if settings.hideBuffFrame then
            BuffFrame:Hide()
        else
            BuffFrame:Show()
        end
        -- Hook Show() once to prevent Blizzard from re-showing
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

    -- DebuffFrame hiding (simple Hide + Show hook, no EnableMouse)
    if DebuffFrame then
        if settings.hideDebuffFrame then
            DebuffFrame:Hide()
        else
            DebuffFrame:Show()
        end
        -- Hook Show() once to prevent Blizzard from re-showing
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

-- Main function to process all buff/debuff frames
local function ApplyBuffBorders()
    -- Apply frame hiding first
    ApplyFrameHiding()
    -- Process BuffFrame containers (top right buffs)
    if BuffFrame and BuffFrame.AuraContainer then
        ProcessAuraContainer(BuffFrame.AuraContainer, true) -- true = buff
    end
    
    -- Process DebuffFrame if it exists separately
    if DebuffFrame and DebuffFrame.AuraContainer then
        ProcessAuraContainer(DebuffFrame.AuraContainer, false) -- false = debuff
    end
    
    -- Process temporary enchant frames (treat as buffs)
    if TemporaryEnchantFrame then
        local frames = {TemporaryEnchantFrame:GetChildren()}
        for _, frame in ipairs(frames) do
            AddBorderToButton(frame, true) -- true = buff
            ApplyFontSettings(frame)
        end
    end
end

-- Debounce state for buff border updates (shared across all hooks)
local buffBorderPending = false

-- Schedule a debounced buff border update
-- Only one timer runs at a time, no matter how many hooks fire
local function ScheduleBuffBorders()
    if buffBorderPending then return end
    buffBorderPending = true
    C_Timer.After(0.15, function()  -- 150ms debounce for CPU efficiency
        buffBorderPending = false
        ApplyBuffBorders()
    end)
end

-- Hook into aura update functions
local function HookAuraUpdates()
    -- Hook BuffFrame updates
    if BuffFrame and BuffFrame.Update then
        hooksecurefunc(BuffFrame, "Update", ScheduleBuffBorders)
    end

    -- Hook AuraContainer updates if it exists (buffs)
    if BuffFrame and BuffFrame.AuraContainer and BuffFrame.AuraContainer.Update then
        hooksecurefunc(BuffFrame.AuraContainer, "Update", ScheduleBuffBorders)
    end

    -- Hook DebuffFrame updates
    if DebuffFrame and DebuffFrame.Update then
        hooksecurefunc(DebuffFrame, "Update", ScheduleBuffBorders)
    end

    -- Hook DebuffFrame.AuraContainer updates if it exists
    if DebuffFrame and DebuffFrame.AuraContainer and DebuffFrame.AuraContainer.Update then
        hooksecurefunc(DebuffFrame.AuraContainer, "Update", ScheduleBuffBorders)
    end

    -- Hook the global aura update function if available
    if type(AuraButton_Update) == "function" then
        hooksecurefunc("AuraButton_Update", ScheduleBuffBorders)
    end
end

-- Performance: Removed redundant 1-second polling loop
-- UNIT_AURA event and AuraButton_Update hook already handle all buff border updates

-- Initialize (UNIT_AURA handles dynamic updates)
-- Note: Initial application is now called from preycore_main.lua OnEnable() to ensure AceDB is ready
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")

eventFrame:SetScript("OnEvent", function(self, event, arg)
    if event == "UNIT_AURA" and arg == "player" then
        ScheduleBuffBorders()  -- Use shared debounce
    end
end)

-- Hook aura updates on first load
C_Timer.After(2, HookAuraUpdates)

-- Export to PREY namespace
PREY.BuffBorders = {
    Apply = ApplyBuffBorders,
    AddBorder = AddBorderToButton,
}

-- Global function for config panel to call
_G.PreyUI_RefreshBuffBorders = function()
    borderedButtons = {}  -- Clear cache to force re-border
    ApplyBuffBorders()
end

