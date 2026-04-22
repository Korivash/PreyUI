--============================================================--
-- PreyUI Initialization
--============================================================--

-- Keybinding display name (must be global before Bindings.xml loads)
BINDING_NAME_PREYUI_TOGGLE_OPTIONS = "Open PreyUI Options"

---@type table|AceAddon
PreyUI = LibStub("AceAddon-3.0"):NewAddon("PreyUI", "AceConsole-3.0", "AceEvent-3.0")

---@type table<string, string>
PreyUI.L = LibStub("AceLocale-3.0"):GetLocale("PreyUI")

local L = PreyUI.L
PreyUI.DF = rawget(_G, "DetailsFramework")
PreyUI.DEBUG_MODE = false

--============================================================--
-- Version & Defaults
--============================================================--

PreyUI.versionString = C_AddOns.GetAddOnMetadata("PreyUI", "Version") or "12.0.5.1"

---@type table
PreyUI.defaults = {
    global = {},
    char = {
        ---@type table
        debug = {
            reload = false
        }
    }
}

local function AdoptLegacySavedVariables()
    if rawget(_G, "PreyUI_DB") == nil and rawget(_G, "KoriUI_DB") ~= nil then
        _G.PreyUI_DB = _G.KoriUI_DB
    end

    if rawget(_G, "PreyUIDB") == nil and rawget(_G, "KoriUIDB") ~= nil then
        _G.PreyUIDB = _G.KoriUIDB
    end
end

--============================================================--
-- Initialization
--============================================================--

function PreyUI:OnInitialize()
    AdoptLegacySavedVariables()

    ---@type AceDBObject-3.0
    self.db = LibStub("AceDB-3.0"):New("PreyUI_DB", self.defaults, "Default")

    -- Slash Commands
    self:RegisterChatCommand("prey", "SlashCommandOpen")
    self:RegisterChatCommand("preyui", "SlashCommandOpen")
    self:RegisterChatCommand("rl", "SlashCommandReload")

    -- Media registration
    self:CheckMediaRegistration()
end

--============================================================--
-- Slash Commands
--============================================================--

function PreyUI:SlashCommandOpen(input)
    if input and input == "debug" then
        self.db.char.debug.reload = true
        PreyUI:SafeReload()
        return
    elseif input and input == "editmode" then
        if _G.PreyUI_ToggleUnitFrameEditMode then
            _G.PreyUI_ToggleUnitFrameEditMode()
        else
            print("|cFFF87171PreyUI:|r Unit Frames module not loaded.")
        end
        return
    end

    -- Default: Open GUI
    if self.GUI then
        self.GUI:Toggle()
    else
        print("|cFFF87171PreyUI:|r GUI not loaded yet. Try again in a moment.")
    end
end

function PreyUI:SlashCommandReload()
    PreyUI:SafeReload()
end

--============================================================--
-- Keybind Shortcuts
--============================================================--

-- Quick Keybind Mode (/kb)
SLASH_PREYKB1 = "/kb"
SlashCmdList["PREYKB"] = function()
    local LibKeyBound = LibStub("LibKeyBound-1.0", true)
    if LibKeyBound then
        LibKeyBound:Toggle()
    elseif QuickKeybindFrame then
        ShowUIPanel(QuickKeybindFrame)
    else
        print("|cffef4444PreyUI:|r Quick Keybind Mode not available.")
    end
end

-- Cooldown Manager Shortcut (/cdm)
SLASH_PREYUI_CDM1 = "/cdm"
SlashCmdList["PREYUI_CDM"] = function()
    if CooldownViewerSettings then
        CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
    else
        print("|cffef4444PreyUI:|r Cooldown Settings not available. Enable CDM first.")
    end
end

--============================================================--
-- OnEnable Lifecycle
--============================================================--

function PreyUI:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")

    local db = self.db
    if db and db.profile and db.profile.chat and db.profile.chat.showIntroMessage ~= false then
        print("|cFFB91C1CPreyUI|r v" .. self.versionString .. " loaded. Type |cFFFFFF00/prey|r to configure.")
    end
end

--============================================================--
-- Player World Entry
--============================================================--

function PreyUI:PLAYER_ENTERING_WORLD(_, isInitialLogin, isReloadingUi)
    self:BackwardsCompat()

    if not self.db.char.debug then
        self.db.char.debug = { reload = false }
    end

    if not self.DEBUG_MODE then
        if self.db.char.debug.reload then
            self.DEBUG_MODE = true
            self.db.char.debug.reload = false
            self:DebugPrint("Debug Mode Enabled")
        end
    else
        self:DebugPrint("Debug Mode Active")
    end
end

--============================================================--
-- Debug & Helper Functions
--============================================================--

function PreyUI:DebugPrint(...)
    if self.DEBUG_MODE then
        self:Print(...)
    end
end

--============================================================--
-- Addon Compartment Functions
--============================================================--

function PreyUI_CompartmentClick()
    if PreyUI.GUI then
        PreyUI.GUI:Toggle()
    end
end

function PreyUI_CompartmentOnEnter(self, button)
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(type(self) ~= "string" and self or button, "ANCHOR_LEFT")
    GameTooltip:AddLine(L["AddonName"] .. " v" .. PreyUI.versionString)
    GameTooltip:AddLine(L["LeftClickOpen"])
    GameTooltip:Show()
end

function PreyUI_CompartmentOnLeave()
    GameTooltip:Hide()
end

