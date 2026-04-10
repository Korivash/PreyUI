local ADDON_NAME, ns = ...


local PREYCore = ns.Addon or (PreyUI and PreyUI.PREYCore)

if not PREYCore then
    print("|cFFFF0000[PreyUI] ERROR: perfectpixel.lua loaded before preycore_main.lua!|r")
    return
end

local min, max, format = min, max, string.format

local _G = _G
local UIParent = UIParent
local GetScreenWidth = GetScreenWidth
local GetScreenHeight = GetScreenHeight
local InCombatLockdown = InCombatLockdown
local GetPhysicalScreenSize = GetPhysicalScreenSize


function PREYCore:RefreshGlobalFX()
    if _G.GlobalFXDialogModelScene then
        _G.GlobalFXDialogModelScene:Hide()
        _G.GlobalFXDialogModelScene:Show()
    end

    if _G.GlobalFXMediumModelScene then
        _G.GlobalFXMediumModelScene:Hide()
        _G.GlobalFXMediumModelScene:Show()
    end

    if _G.GlobalFXBackgroundModelScene then
        _G.GlobalFXBackgroundModelScene:Hide()
        _G.GlobalFXBackgroundModelScene:Show()
    end
end


function PREYCore:IsEyefinity(width, height)
    if PREYCore.db and PREYCore.db.profile.general.eyefinity and width >= 3840 then

        if width >= 9840 then return 3280 end
        if width >= 7680 and width < 9840 then return 2560 end
        if width >= 5760 and width < 7680 then return 1920 end
        if width >= 5040 and width < 5760 then return 1680 end


        if width >= 4800 and width < 5760 and height == 900 then return 1600 end


        if width >= 4320 and width < 4800 then return 1440 end
        if width >= 4080 and width < 4320 then return 1360 end
        if width >= 3840 and width < 4080 then return 1224 end
    end
end


function PREYCore:IsUltrawide(width, height)
    if PREYCore.db and PREYCore.db.profile.general.ultrawide and width >= 2560 then

        if width >= 3440 and (height == 1440 or height == 1600) then return 2560 end


        if width >= 2560 and (height == 1080 or height == 1200) then return 1920 end
    end
end


function PREYCore:UIMult()
    local uiScale = 1.0
    if PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        uiScale = PREYCore.db.profile.general.uiScale or 1.0
    end
    PREYCore.mult = PREYCore.perfect / uiScale
end


function PREYCore:UIScale()
    if InCombatLockdown() then

        if not self._UIScalePending then
            self._UIScalePending = true
            self:RegisterEvent('PLAYER_REGEN_ENABLED', function()
                self._UIScalePending = nil
                self:UnregisterEvent('PLAYER_REGEN_ENABLED')
                self:UIScale()
            end)
        end
    else
        local uiScale = 1.0
        if PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
            uiScale = PREYCore.db.profile.general.uiScale or 1.0
        end


        local success = pcall(function() UIParent:SetScale(uiScale) end)
        if not success then

            if not self._UIScalePending then
                self._UIScalePending = true
                self:RegisterEvent('PLAYER_REGEN_ENABLED', function()
                    self._UIScalePending = nil
                    self:UnregisterEvent('PLAYER_REGEN_ENABLED')
                    self:UIScale()
                end)
            end
            return
        end

        PREYCore.uiscale = UIParent:GetScale()
        PREYCore.screenWidth, PREYCore.screenHeight = GetScreenWidth(), GetScreenHeight()

        local width, height = PREYCore.physicalWidth, PREYCore.physicalHeight
        PREYCore.eyefinity = PREYCore:IsEyefinity(width, height)
        PREYCore.ultrawide = PREYCore:IsUltrawide(width, height)

        local newWidth = PREYCore.eyefinity or PREYCore.ultrawide
        if newWidth then

            width, height = newWidth / (height / PREYCore.screenHeight), PREYCore.screenHeight
        else
            width, height = PREYCore.screenWidth, PREYCore.screenHeight
        end


        if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and _G.GlobalFXDialogModelScene then
            PREYCore:RefreshGlobalFX()
        end
    end
end


function PREYCore:PixelBestSize()
    return max(0.4, min(1.15, PREYCore.perfect))
end


function PREYCore:PixelScaleChanged(event)
    if event == 'UI_SCALE_CHANGED' then
        PREYCore.physicalWidth, PREYCore.physicalHeight = GetPhysicalScreenSize()
        PREYCore.resolution = format('%dx%d', PREYCore.physicalWidth, PREYCore.physicalHeight)
        PREYCore.perfect = 768 / PREYCore.physicalHeight
    end

    PREYCore:UIMult()
    PREYCore:UIScale()
end


function PREYCore:Scale(x)
    local m = PREYCore.mult
    if m == 1 or x == 0 then
        return x
    else
        local y = m > 1 and m or -m
        return x - x % (x < 0 and y or -y)
    end
end


function PREYCore:InitializePixelPerfect()

    self.physicalWidth, self.physicalHeight = GetPhysicalScreenSize()
    self.resolution = format('%dx%d', self.physicalWidth, self.physicalHeight)
    self.perfect = 768 / self.physicalHeight


    self.mult = 1.0


    if self.db and self.db.profile then
        self:UIMult()
    end


    self:RegisterEvent('UI_SCALE_CHANGED', 'PixelScaleChanged')
end


function PREYCore:GetSmartDefaultScale()
    local _, screenHeight = GetPhysicalScreenSize()

    if screenHeight >= 2160 then
        return 0.53
    elseif screenHeight >= 1440 then
        return 0.64
    else
        return 1.0
    end
end


function PREYCore:ApplyUIScale()
    if self.db and self.db.profile and self.db.profile.general then
        local savedScale = self.db.profile.general.uiScale
        local scaleToApply
        if savedScale and savedScale > 0 then
            scaleToApply = savedScale
        else

            scaleToApply = self:GetSmartDefaultScale()
            self.db.profile.general.uiScale = scaleToApply
        end


        if InCombatLockdown() then

            if not self._UIScalePending then
                self._UIScalePending = true
                self:RegisterEvent('PLAYER_REGEN_ENABLED', function()
                    self._UIScalePending = nil
                    self:UnregisterEvent('PLAYER_REGEN_ENABLED')
                    self:ApplyUIScale()
                end)
            end
            return
        end

        local success = pcall(function() UIParent:SetScale(scaleToApply) end)
        if not success then

            if not self._UIScalePending then
                self._UIScalePending = true
                self:RegisterEvent('PLAYER_REGEN_ENABLED', function()
                    self._UIScalePending = nil
                    self:UnregisterEvent('PLAYER_REGEN_ENABLED')
                    self:ApplyUIScale()
                end)
            end
            return
        end
    end


    if self.UIMult and self.UIScale then
        self:UIMult()
        self:UIScale()
    end
end

