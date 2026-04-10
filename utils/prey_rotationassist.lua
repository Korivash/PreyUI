local ADDON_NAME, PREY = ...
local LSM = LibStub("LibSharedMedia-3.0")


local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local UnitCanAttack = UnitCanAttack
local UnitExists = UnitExists


local UPDATE_INTERVAL_COMBAT = 0.3
local UPDATE_INTERVAL_IDLE = 1.0


local COLOR_USABLE = { 1, 1, 1 }
local COLOR_UNUSABLE = { 0.4, 0.4, 0.4 }
local COLOR_NO_MANA = { 0.5, 0.5, 1 }
local COLOR_OUT_OF_RANGE = { 0.8, 0.2, 0.2 }


local iconFrame = nil
local isInitialized = false
local lastSpellID = nil
local inCombat = false


local updateTicker = nil


local spellToKeybind = {}
local lastKeybindCacheTime = 0
local KEYBIND_CACHE_INTERVAL = 1.0


local GCD_SPELL_ID = 61304


local CreateIconFrame, RefreshIconFrame, UpdateIconDisplay, UpdateVisibility


local function FormatKeybind(keybind)
    if PREY.FormatKeybind then
        return PREY.FormatKeybind(keybind)
    end
    return keybind
end

local function GetKeybindForSpell(spellID)
    if not spellID then return nil end

    local keybind = nil


    if PREY.Keybinds and PREY.Keybinds.GetKeybindForSpell then
        keybind = PREY.Keybinds.GetKeybindForSpell(spellID)


        if not keybind then
            local ok, baseSpellID = pcall(function()
                return FindBaseSpellByID and FindBaseSpellByID(spellID)
            end)
            if ok and baseSpellID and baseSpellID ~= spellID then
                keybind = PREY.Keybinds.GetKeybindForSpell(baseSpellID)
            end
        end


        if not keybind then
            local ok, overrideID = pcall(function()
                return C_Spell.GetOverrideSpell and C_Spell.GetOverrideSpell(spellID)
            end)
            if ok and overrideID and overrideID ~= spellID then
                keybind = PREY.Keybinds.GetKeybindForSpell(overrideID)
            end
        end

        if keybind then return keybind end
    end


    local baseSpellID = FindBaseSpellByID and FindBaseSpellByID(spellID) or spellID
    local slots = C_ActionBar.FindSpellActionButtons(baseSpellID)

    if slots and #slots > 0 then
        for _, slot in ipairs(slots) do

            local actionName = "ACTIONBUTTON" .. slot
            if slot > 12 and slot <= 24 then
                actionName = "ACTIONBUTTON" .. (slot - 12)
            elseif slot > 24 and slot <= 36 then
                actionName = "MULTIACTIONBAR3BUTTON" .. (slot - 24)
            elseif slot > 36 and slot <= 48 then
                actionName = "MULTIACTIONBAR4BUTTON" .. (slot - 36)
            elseif slot > 48 and slot <= 60 then
                actionName = "MULTIACTIONBAR1BUTTON" .. (slot - 48)
            elseif slot > 60 and slot <= 72 then
                actionName = "MULTIACTIONBAR2BUTTON" .. (slot - 60)
            end

            local key1 = GetBindingKey(actionName)
            if key1 then
                return FormatKeybind(key1)
            end
        end
    end

    return nil
end


local function ReadSpellCooldown(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local a, b, c, d = C_Spell.GetSpellCooldown(spellID)
        if type(a) == "table" then

            local start = a.startTime or a.start
            local duration = a.duration
            local modRate = a.modRate
            return start, duration, modRate
        else

            return a, b, d
        end
    end
    return nil, nil, nil
end

local function IsCooldownActive(start, duration)
    if not start or not duration then return false end
    local ok, result = pcall(function()
        return duration > 0 and start > 0
    end)

    if not ok then return true end
    return result
end


local function GetDB()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile then
        return PREYCore.db.profile.rotationAssistIcon
    end
    return nil
end


CreateIconFrame = function()
    if iconFrame then return iconFrame end


    iconFrame = CreateFrame("Button", "PreyUI_RotationAssistIcon", UIParent, "BackdropTemplate")
    iconFrame:SetSize(56, 56)
    iconFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
    iconFrame:SetFrameStrata("MEDIUM")
    iconFrame:SetClampedToScreen(true)
    iconFrame:EnableMouse(true)
    iconFrame:SetMovable(true)
    iconFrame:RegisterForDrag("LeftButton")


    iconFrame.icon = iconFrame:CreateTexture(nil, "ARTWORK")
    iconFrame.icon:SetPoint("TOPLEFT", 2, -2)
    iconFrame.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    iconFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)


    iconFrame.cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
    iconFrame.cooldown:SetPoint("TOPLEFT", 2, -2)
    iconFrame.cooldown:SetPoint("BOTTOMRIGHT", -2, 2)
    iconFrame.cooldown:SetDrawSwipe(true)
    iconFrame.cooldown:SetDrawEdge(false)
    iconFrame.cooldown:SetSwipeColor(0, 0, 0, 0.8)
    iconFrame.cooldown:SetHideCountdownNumbers(true)


    iconFrame.keybindText = iconFrame:CreateFontString(nil, "OVERLAY")
    iconFrame.keybindText:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    iconFrame.keybindText:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
    iconFrame.keybindText:SetTextColor(1, 1, 1, 1)
    iconFrame.keybindText:SetShadowOffset(1, -1)
    iconFrame.keybindText:SetShadowColor(0, 0, 0, 1)


    iconFrame:SetScript("OnDragStart", function(self)
        local db = GetDB()
        if db and not db.isLocked then
            self:StartMoving()
        end
    end)

    iconFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()


        local db = GetDB()
        if db then
            local selfX, selfY = self:GetCenter()
            local parentX, parentY = UIParent:GetCenter()
            if selfX and selfY and parentX and parentY then
                db.positionX = selfX - parentX
                db.positionY = selfY - parentY
            end
        end
    end)


    iconFrame:Hide()

    return iconFrame
end


UpdateIconDisplay = function(spellID)
    if not iconFrame then return end

    local db = GetDB()
    if not db or not db.enabled then
        iconFrame:Hide()
        return
    end

    if not spellID or spellID == 0 then

        iconFrame:Hide()
        return
    end


    UpdateVisibility()


    local texture = C_Spell.GetSpellTexture(spellID)
    if texture then
        iconFrame.icon:SetTexture(texture)
    end


    local isUsable, notEnoughMana = C_Spell.IsSpellUsable(spellID)
    local inRange = true


    local hasRange = C_Spell.SpellHasRange(spellID)
    if hasRange and UnitExists("target") then
        local rangeCheck = C_Spell.IsSpellInRange(spellID, "target")
        if rangeCheck == false then
            inRange = false
        end
    end


    local color
    if not inRange then
        color = COLOR_OUT_OF_RANGE
    elseif notEnoughMana then
        color = COLOR_NO_MANA
    elseif not isUsable then
        color = COLOR_UNUSABLE
    else
        color = COLOR_USABLE
    end
    iconFrame.icon:SetVertexColor(color[1], color[2], color[3], 1)


    if db.showKeybind then
        local keybind = GetKeybindForSpell(spellID)
        iconFrame.keybindText:SetText(keybind or "")
        iconFrame.keybindText:Show()
    else
        iconFrame.keybindText:Hide()
    end
end


local function UpdateGCDCooldown()
    if not iconFrame or not iconFrame.cooldown then return end

    local db = GetDB()
    if not db or not db.cooldownSwipeEnabled then
        iconFrame.cooldown:Hide()
        return
    end


    if not iconFrame:IsShown() then return end

    local start, duration, modRate = ReadSpellCooldown(GCD_SPELL_ID)

    if IsCooldownActive(start, duration) then
        iconFrame.cooldown:Show()
        if modRate then
            iconFrame.cooldown:SetCooldown(start, duration, modRate)
        else
            iconFrame.cooldown:SetCooldown(start, duration)
        end
    else
        iconFrame.cooldown:Clear()
    end
end


UpdateVisibility = function()
    if not iconFrame then return end

    local db = GetDB()
    if not db or not db.enabled then
        iconFrame:Hide()
        return
    end

    local shouldShow = false
    local visibility = db.visibility or "always"

    if visibility == "always" then
        shouldShow = true
    elseif visibility == "combat" then
        shouldShow = inCombat
    elseif visibility == "hostile" then
        shouldShow = UnitExists("target") and UnitCanAttack("player", "target")
    end

    if shouldShow then
        iconFrame:Show()
    else
        iconFrame:Hide()
    end
end


local function DoUpdate()
    local db = GetDB()
    if not db or not db.enabled then return end


    if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then
        return
    end


    local ok, spellID = pcall(C_AssistedCombat.GetNextCastSpell, false)
    if not ok then
        spellID = nil
    end


    if spellID ~= lastSpellID then
        lastSpellID = spellID
        UpdateIconDisplay(spellID)
    end
end

local function StartUpdateTicker()

    if updateTicker then updateTicker:Cancel() end

    local db = GetDB()
    if not db or not db.enabled then return end


    local interval = inCombat and UPDATE_INTERVAL_COMBAT or UPDATE_INTERVAL_IDLE
    updateTicker = C_Timer.NewTicker(interval, DoUpdate)
end

local function StopUpdateTicker()
    if updateTicker then
        updateTicker:Cancel()
        updateTicker = nil
    end
end


RefreshIconFrame = function()
    if not iconFrame then
        CreateIconFrame()
    end

    local db = GetDB()
    if not db then
        if iconFrame then iconFrame:Hide() end
        return
    end

    if not db.enabled then
        iconFrame:Hide()
        StopUpdateTicker()
        return
    end


    StartUpdateTicker()


    local size = db.iconSize or 56
    pcall(iconFrame.SetSize, iconFrame, size, size)


    iconFrame:ClearAllPoints()
    local posX = db.positionX or 0
    local posY = db.positionY or -180
    iconFrame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)


    iconFrame:SetFrameStrata(db.frameStrata or "MEDIUM")


    local inset = 0
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local SafeSetBackdrop = PREYCore and PREYCore.SafeSetBackdrop

    if db.showBorder then
        local borderColor = db.borderColor or { 0, 0, 0, 1 }
        local thickness = db.borderThickness or 2
        inset = thickness


        local backdropInfo = {
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = thickness,
        }
        if not db.isLocked then

            if SafeSetBackdrop then
                SafeSetBackdrop(iconFrame, backdropInfo, { 0, 1, 0, 1 })
            else
                iconFrame:SetBackdrop(backdropInfo)
                iconFrame:SetBackdropBorderColor(0, 1, 0, 1)
            end
        else
            if SafeSetBackdrop then
                SafeSetBackdrop(iconFrame, backdropInfo, borderColor)
            else
                iconFrame:SetBackdrop(backdropInfo)
                iconFrame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
            end
        end
    else
        if SafeSetBackdrop then
            SafeSetBackdrop(iconFrame, nil)
        else
            iconFrame:SetBackdrop(nil)
        end
    end


    iconFrame.icon:ClearAllPoints()
    iconFrame.icon:SetPoint("TOPLEFT", inset, -inset)
    iconFrame.icon:SetPoint("BOTTOMRIGHT", -inset, inset)
    iconFrame.cooldown:ClearAllPoints()
    iconFrame.cooldown:SetPoint("TOPLEFT", inset, -inset)
    iconFrame.cooldown:SetPoint("BOTTOMRIGHT", -inset, inset)


    iconFrame.cooldown:SetDrawSwipe(db.cooldownSwipeEnabled)
    if not db.cooldownSwipeEnabled then
        iconFrame.cooldown:Hide()
    end


    iconFrame:EnableMouse(not db.isLocked or true)


    if db.showKeybind then

        local fontName = db.keybindFont
        if not fontName then
            local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
            if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
                fontName = PREYCore.db.profile.general.font
            end
        end
        local fontPath = LSM:Fetch("font", fontName) or STANDARD_TEXT_FONT
        local fontSize = db.keybindSize or 13
        local outline = db.keybindOutline and "OUTLINE" or ""
        iconFrame.keybindText:SetFont(fontPath, fontSize, outline)

        local color = db.keybindColor or { 1, 1, 1, 1 }
        iconFrame.keybindText:SetTextColor(color[1], color[2], color[3], color[4] or 1)


        local anchor = db.keybindAnchor or "BOTTOMRIGHT"
        local offsetX = db.keybindOffsetX or -2
        local offsetY = db.keybindOffsetY or 2
        iconFrame.keybindText:ClearAllPoints()
        iconFrame.keybindText:SetPoint(anchor, iconFrame, anchor, offsetX, offsetY)
    end


end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, function()
            if not isInitialized then
                CreateIconFrame()
                isInitialized = true
            end
            local db = GetDB()
            if db and db.enabled then
                RefreshIconFrame()

                StartUpdateTicker()
            end
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        local db = GetDB()
        if db and db.enabled then
            UpdateVisibility()

            StartUpdateTicker()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        local db = GetDB()
        if db and db.enabled then
            UpdateVisibility()

            StartUpdateTicker()
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateVisibility()

        lastSpellID = nil
        DoUpdate()
    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_COOLDOWN" then
        UpdateGCDCooldown()
    end
end)


local function RefreshRotationAssistIcon()
    RefreshIconFrame()
end

_G.PreyUI_RefreshRotationAssistIcon = RefreshRotationAssistIcon


PREY.RotationAssistIcon = {
    Refresh = RefreshRotationAssistIcon,
    GetFrame = function() return iconFrame end,
}
