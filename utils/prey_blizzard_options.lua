local ADDON_NAME, ns = ...
local PREY = PreyUI

local ADDON_DISPLAY_NAME = "PreyUI"

local function OpenPreyUI()
    if PREY.GUI then
        PREY.GUI:Toggle()
        return true
    end
    print("|cFFF87171PreyUI:|r GUI not loaded yet. Try /prey instead.")
    return false
end

local function CreateSettingsPanel()

    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end

    local panel = CreateFrame("Frame", "PreyUI_BlizzardSettingsPanel")
    panel.name = ADDON_DISPLAY_NAME


    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ADDON_DISPLAY_NAME)


    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(520)
    desc:SetJustifyH("LEFT")
    desc:SetText("Open the PreyUI configuration window.")


    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(180, 32)
    btn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    btn:SetText("Open PreyUI")
    btn:SetScript("OnClick", OpenPreyUI)


    local category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_DISPLAY_NAME)
    Settings.RegisterAddOnCategory(category)
end


C_Timer.After(0.1, CreateSettingsPanel)
