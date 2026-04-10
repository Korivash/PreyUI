BINDING_NAME_PREYUI_TOGGLE_OPTIONS = "Open PreyUI Options"


PreyUI = LibStub("AceAddon-3.0"):NewAddon("PreyUI", "AceConsole-3.0", "AceEvent-3.0")


PreyUI.L = LibStub("AceLocale-3.0"):GetLocale("PreyUI")

local L = PreyUI.L
PreyUI.DF = rawget(_G, "DetailsFramework")
PreyUI.DEBUG_MODE = false


PreyUI.versionString = C_AddOns.GetAddOnMetadata("PreyUI", "Version") or "3.0.12"


PreyUI.defaults = {
    global = {},
    char = {

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


function PreyUI:OnInitialize()
    AdoptLegacySavedVariables()


    self.db = LibStub("AceDB-3.0"):New("PreyUI_DB", self.defaults, "Default")


    self:RegisterChatCommand("prey", "SlashCommandOpen")
    self:RegisterChatCommand("preyui", "SlashCommandOpen")
    self:RegisterChatCommand("rl", "SlashCommandReload")


    self:CheckMediaRegistration()
end


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


    if self.GUI then
        self.GUI:Toggle()
    else
        print("|cFFF87171PreyUI:|r GUI not loaded yet. Try again in a moment.")
    end
end

function PreyUI:SlashCommandReload()
    PreyUI:SafeReload()
end


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


SLASH_PREYUI_CDM1 = "/cdm"
SlashCmdList["PREYUI_CDM"] = function()
    if CooldownViewerSettings then
        CooldownViewerSettings:SetShown(not CooldownViewerSettings:IsShown())
    else
        print("|cffef4444PreyUI:|r Cooldown Settings not available. Enable CDM first.")
    end
end


function PreyUI:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")


    if self.PREYCore then
        if self.db.profile and self.db.profile.chat and self.db.profile.chat.showIntroMessage ~= false then
            print("|cFFB91C1CPreyUI|r loaded. |cFFFFFF00/prey|r to configure.")
            print("|cFFB91C1CPREY UI REMINDER:|r")
            print("|cFFEF44441.|r ENABLE |cFFFFFF00Cooldown Manager|r in Options > Gameplay Enhancement")
            print("|cFFEF44442.|r Action Bars & Menu Bar |cFFFFFF00HIDDEN|r on mouseover |cFFFFFF00by default|r. Use |cFFFFFF00'Actionbars'|r tab in |cFFFFFF00/prey|r to unhide.")
            print("|cFFEF44443.|r Use |cFFFFFF00100% Icon Size|r on CDM Essential & Utility bars via |cFFFFFF00Edit Mode|r for best results.")
            print("|cFFEF44444.|r Position your |cFFFFFF00CDM bars|r in |cFFFFFF00Edit Mode|r and click |cFFFFFF00Save|r before exiting.")
        end
    end
end


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
        self:DebugPrint("Debug Mode Enabled")
    end

end


function PreyUI:DebugPrint(...)
    if self.DEBUG_MODE then
        self:Print(...)
    end
end


function PreyUI_CompartmentClick()
    if PreyUI.GUI then
        PreyUI.GUI:Toggle()
    end
end

local GameTooltip = GameTooltip

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

