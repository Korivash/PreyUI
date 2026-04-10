local ADDON_NAME, ns = ...
local PREYCore = ns.Addon
local LibEditModeOverride = LibStub("LibEditModeOverride-1.0", true)


local UNIT_ANCHOR_FRAMES = {
    PlayerFrame = "Player",
    TargetFrame = "Target",
    FocusFrame  = "Focus",
    PetFrame    = "Pet",
}


local BLIZZARD_FRAME_LABELS = {
    BuffFrame = "Buff Frame",
    DebuffFrame = "Debuff Frame",
    DamageMeterSessionWindow1 = "Damage Meter",
    BuffBarCooldownViewer = "Tracked Bars",
}

local function IsNudgeTargetFrameName(frameName)
    if not frameName then return false end


    if PREYCore.viewers then
        for _, viewerName in ipairs(PREYCore.viewers) do
            if frameName == viewerName then
                return true
            end
        end
    end


    if UNIT_ANCHOR_FRAMES[frameName] then
        return true
    end


    if BLIZZARD_FRAME_LABELS[frameName] then
        return true
    end

    return false
end

local function GetNudgeDisplayName(frameName)
    if not frameName then
        return ""
    end


    local unitLabel = UNIT_ANCHOR_FRAMES[frameName]
    if unitLabel then
        return unitLabel
    end


    local blizzLabel = BLIZZARD_FRAME_LABELS[frameName]
    if blizzLabel then
        return blizzLabel
    end


    return frameName
        :gsub("CooldownViewer", "")
        :gsub("Icon", " Icon")
end


local NudgeFrame = nil


local function CreateNudgeUI()
    if NudgeFrame then return NudgeFrame end

    NudgeFrame = CreateFrame("Frame", ADDON_NAME .. "NudgeFrame", UIParent, "BackdropTemplate")
    PREYCore.nudgeFrame = NudgeFrame


    NudgeFrame:SetSize(200, 320)
    NudgeFrame:SetFrameStrata("DIALOG")
    NudgeFrame:SetClampedToScreen(true)
    NudgeFrame:EnableMouse(true)
    NudgeFrame:SetMovable(false)
    NudgeFrame:Hide()


    NudgeFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })


    function NudgeFrame:UpdatePosition()
        if EditModeManagerFrame then
            self:ClearAllPoints()
            self:SetPoint("RIGHT", EditModeManagerFrame, "LEFT", -5, 0)
        end
    end


    local title = NudgeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Viewer Position")


    local infoText = NudgeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOP", title, "BOTTOM", 0, -8)
    infoText:SetWidth(180)
    infoText:SetWordWrap(true)
    NudgeFrame.infoText = infoText


    local posText = NudgeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    posText:SetPoint("TOP", infoText, "BOTTOM", 0, -8)
    posText:SetWidth(180)
    posText:SetJustifyH("CENTER")
    NudgeFrame.posText = posText


    local function CreateArrowButton(parent, direction, x, yFromTop)
        local button = CreateFrame("Button", nil, parent)
        button:SetSize(32, 32)
        button:SetPoint("TOP", parent, "TOP", x, yFromTop)


        button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
        button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
        button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")


        local texture = button:GetNormalTexture()
        if direction == "UP" then
            texture:SetRotation(math.rad(90))
            button:GetPushedTexture():SetRotation(math.rad(90))
        elseif direction == "DOWN" then
            texture:SetRotation(math.rad(270))
            button:GetPushedTexture():SetRotation(math.rad(270))
        elseif direction == "LEFT" then
            texture:SetRotation(math.rad(180))
            button:GetPushedTexture():SetRotation(math.rad(180))
        elseif direction == "RIGHT" then
            texture:SetRotation(math.rad(0))
            button:GetPushedTexture():SetRotation(math.rad(0))
        end

        button:SetScript("OnClick", function()
            PREYCore:NudgeSelectedViewer(direction)
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        end)


        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Nudge " .. direction:lower())
            GameTooltip:AddLine("Move selected viewer 1 pixel " .. direction:lower(), 1, 1, 1)
            GameTooltip:Show()
        end)

        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        return button
    end


    NudgeFrame.upButton = CreateArrowButton(NudgeFrame, "UP", 0, -90)
    NudgeFrame.downButton = CreateArrowButton(NudgeFrame, "DOWN", 0, -150)
    NudgeFrame.leftButton = CreateArrowButton(NudgeFrame, "LEFT", -25, -120)
    NudgeFrame.rightButton = CreateArrowButton(NudgeFrame, "RIGHT", 25, -120)


    local closeButton = CreateFrame("Button", nil, NudgeFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        NudgeFrame:Hide()
    end)


    local amountSlider = CreateFrame("Slider", nil, NudgeFrame, "OptionsSliderTemplate")
    amountSlider:SetPoint("BOTTOM", 0, 60)
    amountSlider:SetMinMaxValues(0.1, 10)
    amountSlider:SetValueStep(0.1)
    amountSlider:SetObeyStepOnDrag(true)
    amountSlider:SetWidth(150)
    amountSlider:SetHeight(15)
    NudgeFrame.amountSlider = amountSlider


    local amountLabel = NudgeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    amountLabel:SetPoint("BOTTOM", amountSlider, "TOP", 0, 2)
    amountLabel:SetText("Nudge Amount: 1px")
    NudgeFrame.amountLabel = amountLabel


    amountSlider.Low:SetText("0.1")
    amountSlider.High:SetText("10")


    amountSlider:SetScript("OnValueChanged", function(self, value)

        value = math.floor(value * 10 + 0.5) / 10
        PREYCore.db.profile.nudgeAmount = value

        local displayValue = (value % 1 == 0) and tostring(math.floor(value)) or string.format("%.1f", value)
        amountLabel:SetText("Nudge Amount: " .. displayValue .. "px")
    end)


    local viewerDropdown = CreateFrame("Frame", ADDON_NAME .. "ViewerDropdown", NudgeFrame, "UIDropDownMenuTemplate")
    viewerDropdown:SetPoint("BOTTOM", 0, 20)
    NudgeFrame.viewerDropdown = viewerDropdown


    local dropdownLabel = NudgeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownLabel:SetPoint("BOTTOM", viewerDropdown, "TOP", 0, 0)
    dropdownLabel:SetText("Select Viewer:")


    local function ViewerDropdown_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()


        if PREYCore.viewers then
            for _, viewerName in ipairs(PREYCore.viewers) do
                local displayName = GetNudgeDisplayName(viewerName)

                info.text = displayName
                info.value = viewerName
                info.func = function()
                    PREYCore:SelectViewer(viewerName)
                    UIDropDownMenu_SetText(viewerDropdown, displayName)
                    CloseDropDownMenus()
                end
                info.checked = (PREYCore.selectedViewer == viewerName)
                UIDropDownMenu_AddButton(info, level)
            end
        end


        for frameName, label in pairs(UNIT_ANCHOR_FRAMES) do
            local displayName = label

            info.text = displayName
            info.value = frameName
            info.func = function()
                PREYCore:SelectViewer(frameName)
                UIDropDownMenu_SetText(viewerDropdown, displayName)
                CloseDropDownMenus()
            end
            info.checked = (PREYCore.selectedViewer == frameName)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(viewerDropdown, ViewerDropdown_Initialize)
    UIDropDownMenu_SetWidth(viewerDropdown, 150)
    UIDropDownMenu_SetText(viewerDropdown, "Select...")


    function NudgeFrame:UpdateInfo()
        local viewerName = PREYCore.selectedViewer
        local viewer = viewerName and rawget(_G, viewerName)

        if viewer then
            local displayName = GetNudgeDisplayName(viewerName)
            self.infoText:SetText(displayName)
            self.infoText:SetTextColor(0, 1, 0)


            local point, relativeTo, relativePoint, xOfs, yOfs = viewer:GetPoint(1)
            if point then
                self.posText:SetFormattedText("Position: %.1f, %.1f", xOfs or 0, yOfs or 0)
                self.posText:SetTextColor(1, 1, 1)
            else
                self.posText:SetText("No position data")
                self.posText:SetTextColor(0.7, 0.7, 0.7)
            end


            self.upButton:Enable()
            self.downButton:Enable()
            self.leftButton:Enable()
            self.rightButton:Enable()
            self.amountSlider:Enable()
        else
            self.infoText:SetText("Click a viewer in Edit Mode")
            self.infoText:SetTextColor(0.7, 0.7, 0.7)
            self.posText:SetText("")


            self.upButton:Disable()
            self.downButton:Disable()
            self.leftButton:Disable()
            self.rightButton:Disable()
            self.amountSlider:Disable()
        end
    end


    function NudgeFrame:UpdateAmountSlider()
        local amount = PREYCore.db.profile.nudgeAmount or 1
        self.amountSlider:SetValue(amount)

        local displayAmount = (amount % 1 == 0) and tostring(math.floor(amount)) or string.format("%.1f", amount)
        self.amountLabel:SetText("Nudge Amount: " .. displayAmount .. "px")
    end


    function NudgeFrame:UpdateVisibility()
        self:Hide()
    end


    NudgeFrame:SetScript("OnShow", function(self)
        self:UpdatePosition()
        self:UpdateInfo()
        self:UpdateAmountSlider()
    end)

    return NudgeFrame
end


local function EnsureNudgeFrame()
    if not NudgeFrame then
        CreateNudgeUI()
    end
    return NudgeFrame
end


local viewerOverlays = {}


local CDM_VIEWERS = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
    "BuffIconCooldownViewer",
}


local BLIZZARD_EDITMODE_FRAMES = {
    { name = "BuffFrame", label = "Buff Frame" },
    { name = "DebuffFrame", label = "Debuff Frame" },
    { name = "DamageMeterSessionWindow1", label = "Damage Meter" },
    { name = "BuffBarCooldownViewer", label = "Tracked Bars" },
}

local blizzardOverlays = {}


local function CreateViewerNudgeButton(parent, direction, viewerName)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(18, 18)


    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.7)
    btn.bg = bg


    local line1 = btn:CreateTexture(nil, "ARTWORK")
    line1:SetColorTexture(1, 1, 1, 0.9)
    line1:SetSize(7, 2)

    local line2 = btn:CreateTexture(nil, "ARTWORK")
    line2:SetColorTexture(1, 1, 1, 0.9)
    line2:SetSize(7, 2)


    if direction == "DOWN" then
        line1:SetPoint("CENTER", btn, "CENTER", -2, 1)
        line1:SetRotation(math.rad(-45))
        line2:SetPoint("CENTER", btn, "CENTER", 2, 1)
        line2:SetRotation(math.rad(45))
    elseif direction == "UP" then
        line1:SetPoint("CENTER", btn, "CENTER", -2, -1)
        line1:SetRotation(math.rad(45))
        line2:SetPoint("CENTER", btn, "CENTER", 2, -1)
        line2:SetRotation(math.rad(-45))
    elseif direction == "LEFT" then
        line1:SetPoint("CENTER", btn, "CENTER", 1, -2)
        line1:SetRotation(math.rad(-45))
        line2:SetPoint("CENTER", btn, "CENTER", 1, 2)
        line2:SetRotation(math.rad(45))
    elseif direction == "RIGHT" then
        line1:SetPoint("CENTER", btn, "CENTER", -1, -2)
        line1:SetRotation(math.rad(45))
        line2:SetPoint("CENTER", btn, "CENTER", -1, 2)
        line2:SetRotation(math.rad(-45))
    end

    btn.line1 = line1
    btn.line2 = line2


    btn:SetScript("OnEnter", function(self)
        self.line1:SetVertexColor(1, 0.8, 0, 1)
        self.line2:SetVertexColor(1, 0.8, 0, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self.line1:SetVertexColor(1, 1, 1, 0.9)
        self.line2:SetVertexColor(1, 1, 1, 0.9)
    end)

    btn:SetScript("OnClick", function()

        PREYCore:SelectViewer(viewerName)
        PREYCore:NudgeSelectedViewer(direction)
    end)

    return btn
end


local minimapOverlay = nil


local function CreateMinimapNudgeButton(parent, direction)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(18, 18)


    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.7)
    btn.bg = bg


    local line1 = btn:CreateTexture(nil, "ARTWORK")
    line1:SetColorTexture(1, 1, 1, 0.9)
    line1:SetSize(7, 2)

    local line2 = btn:CreateTexture(nil, "ARTWORK")
    line2:SetColorTexture(1, 1, 1, 0.9)
    line2:SetSize(7, 2)


    if direction == "DOWN" then
        line1:SetPoint("CENTER", btn, "CENTER", -2, 1)
        line1:SetRotation(math.rad(-45))
        line2:SetPoint("CENTER", btn, "CENTER", 2, 1)
        line2:SetRotation(math.rad(45))
    elseif direction == "UP" then
        line1:SetPoint("CENTER", btn, "CENTER", -2, -1)
        line1:SetRotation(math.rad(45))
        line2:SetPoint("CENTER", btn, "CENTER", 2, -1)
        line2:SetRotation(math.rad(-45))
    elseif direction == "LEFT" then
        line1:SetPoint("CENTER", btn, "CENTER", 1, -2)
        line1:SetRotation(math.rad(-45))
        line2:SetPoint("CENTER", btn, "CENTER", 1, 2)
        line2:SetRotation(math.rad(45))
    elseif direction == "RIGHT" then
        line1:SetPoint("CENTER", btn, "CENTER", -1, -2)
        line1:SetRotation(math.rad(45))
        line2:SetPoint("CENTER", btn, "CENTER", -1, 2)
        line2:SetRotation(math.rad(-45))
    end

    btn.line1 = line1
    btn.line2 = line2


    btn:SetScript("OnEnter", function(self)
        self.line1:SetVertexColor(1, 0.8, 0, 1)
        self.line2:SetVertexColor(1, 0.8, 0, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self.line1:SetVertexColor(1, 1, 1, 0.9)
        self.line2:SetVertexColor(1, 1, 1, 0.9)
    end)


    btn:SetScript("OnClick", function()
        PREYCore:SelectEditModeElement("minimap", "minimap")
        PREYCore:NudgeMinimap(direction)
    end)

    return btn
end


local function CreateViewerOverlay(viewerName)
    local viewer = rawget(_G, viewerName)
    if not viewer then return nil end

    local overlay = CreateFrame("Frame", nil, viewer, "BackdropTemplate")
    overlay:SetAllPoints()
    overlay:SetFrameStrata("TOOLTIP")
    overlay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    overlay:SetBackdropColor(0.2, 0.8, 1, 0.3)
    overlay:SetBackdropBorderColor(0.2, 0.8, 1, 1)
    overlay:EnableMouse(false)


    local displayName = GetNudgeDisplayName(viewerName)
    local label = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOP", overlay, "TOP", 0, -4)
    label:SetText(displayName)
    label:SetTextColor(0.2, 0.8, 1, 1)


    local nudgeUp = CreateViewerNudgeButton(overlay, "UP", viewerName)
    nudgeUp:SetPoint("BOTTOM", overlay, "TOP", 0, 4)

    local nudgeDown = CreateViewerNudgeButton(overlay, "DOWN", viewerName)
    nudgeDown:SetPoint("TOP", overlay, "BOTTOM", 0, -4)

    local nudgeLeft = CreateViewerNudgeButton(overlay, "LEFT", viewerName)
    nudgeLeft:SetPoint("RIGHT", overlay, "LEFT", -4, 0)

    local nudgeRight = CreateViewerNudgeButton(overlay, "RIGHT", viewerName)
    nudgeRight:SetPoint("LEFT", overlay, "RIGHT", 4, 0)

    overlay.nudgeUp = nudgeUp
    overlay.nudgeDown = nudgeDown
    overlay.nudgeLeft = nudgeLeft
    overlay.nudgeRight = nudgeRight


    overlay.elementKey = viewerName


    nudgeUp:Hide()
    nudgeDown:Hide()
    nudgeLeft:Hide()
    nudgeRight:Hide()

    overlay:Hide()
    return overlay
end


local function CreateBlizzardFrameOverlay(frameInfo)
    local frameName = frameInfo.name
    local label = frameInfo.label
    local frame = rawget(_G, frameName)
    if not frame then return nil end

    local overlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    overlay:SetAllPoints()
    overlay:SetFrameStrata("TOOLTIP")
    overlay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    overlay:SetBackdropColor(0.2, 0.8, 1, 0.3)
    overlay:SetBackdropBorderColor(0.2, 0.8, 1, 1)
    overlay:EnableMouse(false)


    local labelText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOP", overlay, "TOP", 0, -4)
    labelText:SetText(label)
    labelText:SetTextColor(0.2, 0.8, 1, 1)


    local nudgeUp = CreateViewerNudgeButton(overlay, "UP", frameName)
    nudgeUp:SetPoint("BOTTOM", overlay, "TOP", 0, 4)

    local nudgeDown = CreateViewerNudgeButton(overlay, "DOWN", frameName)
    nudgeDown:SetPoint("TOP", overlay, "BOTTOM", 0, -4)

    local nudgeLeft = CreateViewerNudgeButton(overlay, "LEFT", frameName)
    nudgeLeft:SetPoint("RIGHT", overlay, "LEFT", -4, 0)

    local nudgeRight = CreateViewerNudgeButton(overlay, "RIGHT", frameName)
    nudgeRight:SetPoint("LEFT", overlay, "RIGHT", 4, 0)

    overlay.nudgeUp = nudgeUp
    overlay.nudgeDown = nudgeDown
    overlay.nudgeLeft = nudgeLeft
    overlay.nudgeRight = nudgeRight


    overlay.elementKey = frameName


    nudgeUp:Hide()
    nudgeDown:Hide()
    nudgeLeft:Hide()
    nudgeRight:Hide()

    overlay:Hide()
    return overlay
end


local function CreateMinimapOverlay()
    if not Minimap then return nil end

    local overlay = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
    overlay:SetAllPoints()
    overlay:SetFrameStrata("TOOLTIP")
    overlay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    overlay:SetBackdropColor(0.2, 0.8, 1, 0.3)
    overlay:SetBackdropBorderColor(0.2, 0.8, 1, 1)
    overlay:EnableMouse(false)


    local labelText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOP", overlay, "TOP", 0, -4)
    labelText:SetText("Minimap")
    labelText:SetTextColor(0.2, 0.8, 1, 1)


    local infoText = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetTextColor(0.7, 0.7, 0.7, 1)
    overlay.infoText = infoText


    local nudgeUp = CreateMinimapNudgeButton(overlay, "UP")
    nudgeUp:SetPoint("BOTTOM", overlay, "TOP", 0, 4)

    local nudgeDown = CreateMinimapNudgeButton(overlay, "DOWN")
    nudgeDown:SetPoint("TOP", overlay, "BOTTOM", 0, -4)

    local nudgeLeft = CreateMinimapNudgeButton(overlay, "LEFT")
    nudgeLeft:SetPoint("RIGHT", overlay, "LEFT", -4, 0)

    local nudgeRight = CreateMinimapNudgeButton(overlay, "RIGHT")
    nudgeRight:SetPoint("LEFT", overlay, "RIGHT", 4, 0)


    infoText:SetPoint("BOTTOM", nudgeUp, "TOP", 0, 2)

    overlay.nudgeUp = nudgeUp
    overlay.nudgeDown = nudgeDown
    overlay.nudgeLeft = nudgeLeft
    overlay.nudgeRight = nudgeRight


    overlay.elementKey = "minimap"


    nudgeUp:Hide()
    nudgeDown:Hide()
    nudgeLeft:Hide()
    nudgeRight:Hide()
    infoText:Hide()

    overlay:Hide()
    return overlay
end


function PREYCore:ShowViewerOverlays()
    for _, viewerName in ipairs(CDM_VIEWERS) do
        if not viewerOverlays[viewerName] then
            viewerOverlays[viewerName] = CreateViewerOverlay(viewerName)
        end
        local overlay = viewerOverlays[viewerName]
        if overlay then
            overlay:Show()


            overlay:EnableMouse(true)
            overlay:SetScript("OnMouseDown", function(self, button)
                if button == "LeftButton" then
                    PREYCore:SelectViewer(viewerName)

                    local viewer = rawget(_G, viewerName)
                    if viewer then
                        viewer:SetMovable(true)
                        viewer:StartMoving()
                    end
                end
            end)
            overlay:SetScript("OnMouseUp", function(self, button)
                local viewer = rawget(_G, viewerName)
                if viewer then
                    viewer:StopMovingOrSizing()

                    if LibEditModeOverride and EnsureEditModeReady() and LibEditModeOverride:HasEditModeSettings(viewer) then
                        local point, relativeTo, relativePoint, x, y = viewer:GetPoint(1)
                        pcall(function()
                            LibEditModeOverride:ReanchorFrame(viewer, point, relativeTo, relativePoint, x, y)
                        end)
                    end
                end
            end)
        end
    end

    self.cdmOverlays = viewerOverlays
end


function PREYCore:HideViewerOverlays()
    for _, viewerName in ipairs(CDM_VIEWERS) do
        local overlay = viewerOverlays[viewerName]
        if overlay then
            overlay:Hide()
            overlay:EnableMouse(false)
            overlay:SetScript("OnMouseDown", nil)
            overlay:SetScript("OnMouseUp", nil)
        end
    end
end


function PREYCore:ShowBlizzardFrameOverlays()
    for _, frameInfo in ipairs(BLIZZARD_EDITMODE_FRAMES) do
        local frameName = frameInfo.name
        local frame = rawget(_G, frameName)


        if frame then
            if not blizzardOverlays[frameName] then
                blizzardOverlays[frameName] = CreateBlizzardFrameOverlay(frameInfo)
            end
            local overlay = blizzardOverlays[frameName]
            if overlay then
                overlay:Show()


                overlay:EnableMouse(true)
                overlay:SetScript("OnMouseDown", function(self, button)
                    if button == "LeftButton" then
                        PREYCore:SelectViewer(frameName)

                        frame:SetMovable(true)
                        frame:StartMoving()
                    end
                end)
                overlay:SetScript("OnMouseUp", function(self, button)
                    if frame then
                        frame:StopMovingOrSizing()

                        if LibEditModeOverride and EnsureEditModeReady() and LibEditModeOverride:HasEditModeSettings(frame) then
                            local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
                            pcall(function()
                                LibEditModeOverride:ReanchorFrame(frame, point, relativeTo, relativePoint, x, y)
                            end)
                        end
                    end
                end)
            end
        end
    end

    self.blizzardOverlays = blizzardOverlays
end


function PREYCore:HideBlizzardFrameOverlays()
    for _, frameInfo in ipairs(BLIZZARD_EDITMODE_FRAMES) do
        local overlay = blizzardOverlays[frameInfo.name]
        if overlay then
            overlay:Hide()
            overlay:EnableMouse(false)
            overlay:SetScript("OnMouseDown", nil)
            overlay:SetScript("OnMouseUp", nil)
        end
    end
end


function PREYCore:ShowMinimapOverlay()
    if not minimapOverlay then
        minimapOverlay = CreateMinimapOverlay()
    end
    if minimapOverlay then
        minimapOverlay:Show()


        minimapOverlay:EnableMouse(true)
        minimapOverlay:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                PREYCore:SelectEditModeElement("minimap", "minimap")

                if Minimap:IsMovable() then
                    Minimap:StartMoving()
                end
            end
        end)
        minimapOverlay:SetScript("OnMouseUp", function(self, button)
            Minimap:StopMovingOrSizing()

            local settings = PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.minimap
            if settings then
                local point, _, relPoint, x, y = Minimap:GetPoint()
                settings.position = {point, relPoint, x, y}
            end

            if minimapOverlay and minimapOverlay.infoText and settings and settings.position then
                minimapOverlay.infoText:SetText(string.format("Minimap  X:%d Y:%d",
                    math.floor(settings.position[3] or 0),
                    math.floor(settings.position[4] or 0)))
            end
        end)


        self.minimapOverlay = minimapOverlay
    end
end


function PREYCore:HideMinimapOverlay()
    if minimapOverlay then
        minimapOverlay:Hide()
        minimapOverlay:EnableMouse(false)
        minimapOverlay:SetScript("OnMouseDown", nil)
        minimapOverlay:SetScript("OnMouseUp", nil)
    end
end


local clickDetector = CreateFrame("Frame")
clickDetector:Hide()
local lastClickedFrame = nil

function PREYCore:EnableClickDetection()
    clickDetector:Show()
    clickDetector._elapsed = 0
    clickDetector:SetScript("OnUpdate", function(self, elapsed)
        self._elapsed = self._elapsed + elapsed
        if self._elapsed < 0.033 then return end
        self._elapsed = 0
        if IsMouseButtonDown("LeftButton") then
            local frames = GetMouseFoci()
            if frames and #frames > 0 then
                for _, frame in ipairs(frames) do
                    if frame and frame ~= WorldFrame then
                        local frameName = frame:GetName()


                        if IsNudgeTargetFrameName(frameName) then
                            if lastClickedFrame ~= frame then
                                lastClickedFrame = frame
                                PREYCore:SelectViewer(frameName)
                            end
                            return
                        end


                        if not frameName and frame:GetParent() then
                            local parentName = frame:GetParent():GetName()
                            if IsNudgeTargetFrameName(parentName) then
                                if lastClickedFrame ~= frame then
                                    lastClickedFrame = frame
                                    PREYCore:SelectViewer(parentName)
                                end
                                return
                            end
                        end
                    end
                end
            end
        else
            lastClickedFrame = nil
        end
    end)
end

function PREYCore:DisableClickDetection()
    clickDetector:Hide()
    clickDetector:SetScript("OnUpdate", nil)
    lastClickedFrame = nil
end


function PREYCore:SelectViewer(viewerName)
    if not viewerName or not rawget(_G, viewerName) then
        self.selectedViewer = nil
        if self.nudgeFrame then
            self.nudgeFrame:UpdateInfo()
        end
        return
    end

    self.selectedViewer = viewerName


    if self.SelectEditModeElement then
        local elementType = BLIZZARD_FRAME_LABELS[viewerName] and "blizzard" or "cdm"
        self:SelectEditModeElement(elementType, viewerName)
    end

    if self.nudgeFrame then
        self.nudgeFrame:UpdateInfo()
        local displayName = GetNudgeDisplayName(viewerName)
        UIDropDownMenu_SetText(self.nudgeFrame.viewerDropdown, displayName)

    end
end


local function EnsureEditModeReady()
    if not LibEditModeOverride then
        return false
    end

    if not LibEditModeOverride:IsReady() then
        return false
    end

    if not LibEditModeOverride:AreLayoutsLoaded() then
        LibEditModeOverride:LoadLayouts()
    end

    return LibEditModeOverride:CanEditActiveLayout()
end


function PREYCore:NudgeSelectedViewer(direction)
    if not self.selectedViewer then return false end

    local viewer = rawget(_G, self.selectedViewer)
    if not viewer then return false end

    local amount = 1


    local point, relativeTo, relativePoint, xOfs, yOfs = viewer:GetPoint(1)
    if not point then return false end

    local newX = xOfs or 0
    local newY = yOfs or 0

    if direction == "UP" then
        newY = newY + amount
    elseif direction == "DOWN" then
        newY = newY - amount
    elseif direction == "LEFT" then
        newX = newX - amount
    elseif direction == "RIGHT" then
        newX = newX + amount
    end


    if LibEditModeOverride and EnsureEditModeReady() and LibEditModeOverride:HasEditModeSettings(viewer) then

        local success, err = pcall(function()
            LibEditModeOverride:ReanchorFrame(viewer, point, relativeTo, relativePoint, newX, newY)
        end)

        if success then

            if self.nudgeFrame and self.nudgeFrame:IsShown() then
                self.nudgeFrame:UpdateInfo()
            end
            return true
        end
    end


    viewer:ClearAllPoints()
    viewer:SetPoint(point, relativeTo, relativePoint, newX, newY)


    if EditModeManagerFrame and EditModeManagerFrame.editModeActive then
        if EditModeManagerFrame.OnSystemPositionChange then

            EditModeManagerFrame:OnSystemPositionChange(viewer)
        elseif EditModeManagerFrame.SetHasActiveChanges then

            EditModeManagerFrame:SetHasActiveChanges(true)
        end
    end


    if self.nudgeFrame and self.nudgeFrame:IsShown() then
        self.nudgeFrame:UpdateInfo()
    end

    return true
end


function PREYCore:NudgeMinimap(direction)
    local db = self.db and self.db.profile and self.db.profile.minimap
    if not db or not db.position then return end

    local amount = self.nudgeAmount or 1
    if IsShiftKeyDown() then amount = amount * 10 end


    local xOfs = db.position[3] or 0
    local yOfs = db.position[4] or 0

    if direction == "UP" then
        yOfs = yOfs + amount
    elseif direction == "DOWN" then
        yOfs = yOfs - amount
    elseif direction == "LEFT" then
        xOfs = xOfs - amount
    elseif direction == "RIGHT" then
        xOfs = xOfs + amount
    end

    db.position[3] = xOfs
    db.position[4] = yOfs


    Minimap:ClearAllPoints()
    Minimap:SetPoint(db.position[1], UIParent, db.position[2], xOfs, yOfs)


    if minimapOverlay and minimapOverlay.infoText then
        minimapOverlay.infoText:SetText(string.format("Minimap  X:%d Y:%d", math.floor(xOfs), math.floor(yOfs)))
    end
end


local function SetupEditModeHooks()
    if not EditModeManagerFrame then return end

    hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()

        if LibEditModeOverride and LibEditModeOverride:IsReady() then
            if not LibEditModeOverride:AreLayoutsLoaded() then
                LibEditModeOverride:LoadLayouts()
            end
        end


        if PREYCore.nudgeFrame then
            PREYCore.nudgeFrame:UpdateVisibility()
        end
        PREYCore:EnableClickDetection()


        PREYCore:ShowMinimapOverlay()
        PREYCore:EnableMinimapEditMode()
    end)

    hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()

        if PREYCore.nudgeFrame then
            PREYCore.nudgeFrame:Hide()
        end
        PREYCore:DisableClickDetection()


        PREYCore:HideMinimapOverlay()
        PREYCore:DisableMinimapEditMode()
        PREYCore.selectedViewer = nil

        if PREYCore.ClearEditModeSelection then
            PREYCore:ClearEditModeSelection()
        end


        C_Timer.After(0.066, function()
            local uiCenterX, uiCenterY = UIParent:GetCenter()


            local buffViewer = rawget(_G, "BuffIconCooldownViewer")
            if buffViewer then
                local point = buffViewer:GetPoint(1)
                if point == "TOPLEFT" then
                    local frameCenterX, frameCenterY = buffViewer:GetCenter()
                    if frameCenterX and frameCenterY then
                        local offsetX = frameCenterX - uiCenterX
                        local offsetY = frameCenterY - uiCenterY


                        local success = false
                        if LibEditModeOverride and LibEditModeOverride:HasEditModeSettings(buffViewer) then
                            success = pcall(function()
                                LibEditModeOverride:ReanchorFrame(buffViewer, "CENTER", UIParent, "CENTER", offsetX, offsetY)
                            end)
                        end


                        if not success then
                            buffViewer:ClearAllPoints()
                            buffViewer:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
                        end
                    end
                end
            end


            local barViewer = rawget(_G, "BuffBarCooldownViewer")
            if barViewer then
                local point = barViewer:GetPoint(1)
                if point == "TOPLEFT" then
                    local frameCenterX, frameCenterY = barViewer:GetCenter()
                    if frameCenterX and frameCenterY then
                        local offsetX = frameCenterX - uiCenterX
                        local offsetY = frameCenterY - uiCenterY


                        local success = false
                        if LibEditModeOverride and LibEditModeOverride:HasEditModeSettings(barViewer) then
                            success = pcall(function()
                                LibEditModeOverride:ReanchorFrame(barViewer, "CENTER", UIParent, "CENTER", offsetX, offsetY)
                            end)
                        end


                        if not success then
                            barViewer:ClearAllPoints()
                            barViewer:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
                        end
                    end
                end
            end
        end)
    end)
end

if EditModeManagerFrame then
    SetupEditModeHooks()
else

    local waitFrame = CreateFrame("Frame")
    waitFrame:RegisterEvent("ADDON_LOADED")
    waitFrame:SetScript("OnEvent", function(self, event, addon)
        if EditModeManagerFrame then
            SetupEditModeHooks()
            self:UnregisterAllEvents()
        end
    end)
end


local viewerAnchorFixFrame = CreateFrame("Frame")
viewerAnchorFixFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
viewerAnchorFixFrame:SetScript("OnEvent", function(self, event, isInitialLogin, isReloadingUi)

    if not isReloadingUi then return end


    C_Timer.After(0.5, function()

        local uiCenterX, uiCenterY = UIParent:GetCenter()


        local barViewer = rawget(_G, "BuffBarCooldownViewer")
        if barViewer then
            local point = barViewer:GetPoint(1)
            if point == "TOPLEFT" then

                local frameCenterX, frameCenterY = barViewer:GetCenter()
                if frameCenterX and frameCenterY then

                    local offsetX = frameCenterX - uiCenterX
                    local offsetY = frameCenterY - uiCenterY


                    barViewer:ClearAllPoints()
                    barViewer:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
                end
            end
        end


        local iconViewer = rawget(_G, "BuffIconCooldownViewer")
        if iconViewer then
            local point = iconViewer:GetPoint(1)
            if point == "TOPLEFT" then
                local frameCenterX, frameCenterY = iconViewer:GetCenter()
                if frameCenterX and frameCenterY then
                    local offsetX = frameCenterX - uiCenterX
                    local offsetY = frameCenterY - uiCenterY

                    iconViewer:ClearAllPoints()
                    iconViewer:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
                end
            end
        end
    end)
end)


local oldOnInitialize = PREYCore.OnInitialize
function PREYCore:OnInitialize()
    if oldOnInitialize then
        oldOnInitialize(self)
    end


    if not self.db.profile.nudgeAmount then
        self.db.profile.nudgeAmount = 1
    end
end