local ADDON_NAME, ns = ...
local PREY = PreyUI
local LSM = LibStub("LibSharedMedia-3.0")


PREY.GUI = PREY.GUI or {}
local GUI = PREY.GUI


GUI.Colors = {

    bg = {0.050, 0.030, 0.036, 0.97},
    bgLight = {0.115, 0.060, 0.074, 1},
    bgDark = {0.022, 0.014, 0.018, 1},
    bgContent = {0.095, 0.042, 0.054, 0.62},


    accent = {0.840, 0.180, 0.220, 1},
    accentLight = {1.000, 0.420, 0.450, 1},
    accentDark = {0.420, 0.080, 0.100, 1},
    accentHover = {1.000, 0.540, 0.580, 1},


    tabSelected = {0.840, 0.180, 0.220, 1},
    tabSelectedText = {1.00, 0.92, 0.93, 1},
    tabNormal = {0.80, 0.73, 0.75, 1},
    tabHover = {1.00, 0.97, 0.97, 1},


    text = {0.96, 0.93, 0.94, 1},
    textBright = {1, 1, 1, 1},
    textMuted = {0.70, 0.60, 0.62, 1},


    border = {0.29, 0.12, 0.14, 1},
    borderLight = {0.45, 0.21, 0.24, 1},
    borderAccent = {0.840, 0.180, 0.220, 1},


    sectionHeader = {0.950, 0.360, 0.400, 1},


    sliderTrack = {0.16, 0.08, 0.09, 1},
    sliderThumb = {1, 1, 1, 1},
    sliderThumbBorder = {0.45, 0.18, 0.20, 1},


    toggleOff = {0.17, 0.10, 0.11, 1},
    toggleThumb = {1, 1, 1, 1},


    warning = {0.961, 0.620, 0.043, 1},


    navBg = {0.060, 0.028, 0.034, 1},
    navItemBg = {0.110, 0.050, 0.060, 1},
    navItemActiveBg = {0.180, 0.060, 0.070, 1},
    navActionBg = {0.120, 0.040, 0.050, 1},
}

local C = GUI.Colors


GUI.PANEL_WIDTH = 750
GUI.CONTENT_WIDTH = 710


GUI.SettingsRegistry = {}


GUI._searchContext = {
    tabIndex = nil,
    tabName = nil,
    subTabIndex = nil,
    subTabName = nil,
    sectionName = nil,
}


GUI._suppressSearchRegistration = false


GUI.SettingsRegistryKeys = {}


GUI.WidgetInstances = {}


local function GetWidgetKey(dbTable, dbKey)
    if not dbTable or not dbKey then return nil end
    return tostring(dbTable) .. "_" .. dbKey
end


local function RegisterWidgetInstance(widget, dbTable, dbKey)
    local widgetKey = GetWidgetKey(dbTable, dbKey)
    if not widgetKey then return end
    GUI.WidgetInstances[widgetKey] = GUI.WidgetInstances[widgetKey] or {}
    table.insert(GUI.WidgetInstances[widgetKey], widget)
    widget._widgetKey = widgetKey
end


local function UnregisterWidgetInstance(widget)
    if not widget._widgetKey then return end
    local instances = GUI.WidgetInstances[widget._widgetKey]
    if not instances then return end
    for i = #instances, 1, -1 do
        if instances[i] == widget then
            table.remove(instances, i)
            break
        end
    end
end


local function BroadcastToSiblings(widget, val)
    if not widget._widgetKey then return end
    local instances = GUI.WidgetInstances[widget._widgetKey]
    if not instances then return end
    for _, sibling in ipairs(instances) do
        if sibling ~= widget and sibling.UpdateVisual then
            sibling.UpdateVisual(val)
        end
    end
end


function GUI:SetSearchContext(info)
    self._searchContext.tabIndex = info.tabIndex
    self._searchContext.tabName = info.tabName
    self._searchContext.subTabIndex = info.subTabIndex or nil
    self._searchContext.subTabName = info.subTabName or nil
    self._searchContext.sectionName = info.sectionName or nil
end


function GUI:SetSearchSection(sectionName)
    self._searchContext.sectionName = sectionName
end


function GUI:ClearSearchContext()
    self._searchContext = {
        tabIndex = nil,
        tabName = nil,
        subTabIndex = nil,
        subTabName = nil,
        sectionName = nil,
    }
end


GUI._searchIndexBuilt = false


function GUI:ForceLoadAllTabs()
    local frame = self.MainFrame
    if not frame or not frame.pages then return end


    if not self.SettingsRegistry then
        self.SettingsRegistry = {}
    end
    if not self.SettingsRegistryKeys then
        self.SettingsRegistryKeys = {}
    end


    for tabIndex, page in pairs(frame.pages) do
        if tabIndex ~= self._searchTabIndex then
            if page and page.createFunc and not page.built then

                if not page.frame then
                    page.frame = CreateFrame("Frame", nil, frame.contentArea)
                    page.frame:SetAllPoints()
                    page.frame:EnableMouse(false)
                end
                page.frame:Hide()


                page.createFunc(page.frame)
                page.built = true
            end
        end
    end
end


local FONT_PATH = LSM:Fetch("font", "Prey") or [[Interface\AddOns\PreyUI\assets\Prey.ttf]]
GUI.FONT_PATH = FONT_PATH


local function GetFontPath()
    return FONT_PATH
end


local function CreateBackdrop(frame, bgColor, borderColor)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(bgColor or C.bg))
    frame:SetBackdropBorderColor(unpack(borderColor or C.border))
end

local function SetFont(fontString, size, flags, color)
    fontString:SetFont(GetFontPath(), size or 12, flags or "")
    if color then
        fontString:SetTextColor(unpack(color))
    end
end


function GUI:CreateLabel(parent, text, size, color, anchor, x, y)

    if parent._hasContent ~= nil then
        parent._hasContent = true
    end
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(label, size or 12, "", color or C.text)
    label:SetText(text or "")
    if anchor then
        label:SetPoint(anchor, parent, anchor, x or 0, y or 0)
    end
    return label
end


function GUI:CreateButton(parent, text, width, height, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width or 120, height or 26)


    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    btn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)


    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btnText:SetFont(GetFontPath(), 12, "")
    btnText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    btnText:SetPoint("CENTER", 0, 0)
    btnText:SetText(text or "Button")
    btn.text = btnText


    btn:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropBorderColor, self, C.accent[1], C.accent[2], C.accent[3], 1)
    end)

    btn:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropBorderColor, self, C.border[1], C.border[2], C.border[3], 1)
    end)


    if onClick then
        btn:SetScript("OnClick", onClick)
    end


    function btn:SetText(newText)
        btnText:SetText(newText)
    end

    return btn
end


local confirmDialog = nil

function GUI:ShowConfirmation(options)


    if not confirmDialog then

        confirmDialog = CreateFrame("Frame", "PREY_ConfirmDialog", UIParent, "BackdropTemplate")
        confirmDialog:SetSize(320, 160)
        confirmDialog:SetPoint("CENTER")
        confirmDialog:SetFrameStrata("FULLSCREEN_DIALOG")
        confirmDialog:SetFrameLevel(500)
        confirmDialog:EnableMouse(true)
        confirmDialog:SetMovable(true)
        confirmDialog:RegisterForDrag("LeftButton")
        confirmDialog:SetScript("OnDragStart", function(self) self:StartMoving() end)
        confirmDialog:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        confirmDialog:SetClampedToScreen(true)
        confirmDialog:Hide()


        confirmDialog:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        confirmDialog:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 0.98)
        confirmDialog:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)


        confirmDialog.title = confirmDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(confirmDialog.title, 14, "", C.accentLight)
        confirmDialog.title:SetPoint("TOP", 0, -18)


        confirmDialog.message = confirmDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(confirmDialog.message, 12, "", C.text)
        confirmDialog.message:SetPoint("TOP", 0, -50)
        confirmDialog.message:SetWidth(280)
        confirmDialog.message:SetJustifyH("CENTER")


        confirmDialog.warning = confirmDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(confirmDialog.warning, 11, "", C.warning)
        confirmDialog.warning:SetPoint("TOP", confirmDialog.message, "BOTTOM", 0, -8)


        confirmDialog.acceptBtn = CreateFrame("Button", nil, confirmDialog, "BackdropTemplate")
        confirmDialog.acceptBtn:SetSize(100, 28)
        confirmDialog.acceptBtn:SetPoint("BOTTOMLEFT", 40, 20)
        confirmDialog.acceptBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        confirmDialog.acceptBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        confirmDialog.acceptBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        confirmDialog.acceptBtn.text = confirmDialog.acceptBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        confirmDialog.acceptBtn.text:SetFont(GetFontPath(), 12, "")
        confirmDialog.acceptBtn.text:SetPoint("CENTER", 0, 0)

        confirmDialog.acceptBtn:SetScript("OnEnter", function(self)
            pcall(self.SetBackdropBorderColor, self, C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        confirmDialog.acceptBtn:SetScript("OnLeave", function(self)
            pcall(self.SetBackdropBorderColor, self, C.border[1], C.border[2], C.border[3], 1)
        end)


        confirmDialog.cancelBtn = CreateFrame("Button", nil, confirmDialog, "BackdropTemplate")
        confirmDialog.cancelBtn:SetSize(100, 28)
        confirmDialog.cancelBtn:SetPoint("BOTTOMRIGHT", -40, 20)
        confirmDialog.cancelBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        confirmDialog.cancelBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        confirmDialog.cancelBtn:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

        confirmDialog.cancelBtn.text = confirmDialog.cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        confirmDialog.cancelBtn.text:SetFont(GetFontPath(), 12, "")
        confirmDialog.cancelBtn.text:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
        confirmDialog.cancelBtn.text:SetPoint("CENTER", 0, 0)

        confirmDialog.cancelBtn:SetScript("OnEnter", function(self)
            pcall(self.SetBackdropBorderColor, self, C.accent[1], C.accent[2], C.accent[3], 1)
        end)
        confirmDialog.cancelBtn:SetScript("OnLeave", function(self)
            pcall(self.SetBackdropBorderColor, self, C.border[1], C.border[2], C.border[3], 1)
        end)


        confirmDialog:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:SetPropagateKeyboardInput(false)
                if self._onCancel then self._onCancel() end
                self:Hide()
            else
                self:SetPropagateKeyboardInput(true)
            end
        end)
    end


    confirmDialog.title:SetText(options.title or "Confirm")
    confirmDialog.message:SetText(options.message or "")

    if options.warningText then
        confirmDialog.warning:SetText(options.warningText)
        confirmDialog.warning:Show()
    else
        confirmDialog.warning:Hide()
    end


    confirmDialog.acceptBtn.text:SetText(options.acceptText or "OK")
    if options.isDestructive then
        confirmDialog.acceptBtn.text:SetTextColor(C.warning[1], C.warning[2], C.warning[3], 1)
    else
        confirmDialog.acceptBtn.text:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    end


    confirmDialog.cancelBtn.text:SetText(options.cancelText or "Cancel")


    confirmDialog._onCancel = options.onCancel


    confirmDialog.acceptBtn:SetScript("OnClick", function()
        confirmDialog:Hide()
        if options.onAccept then options.onAccept() end
    end)

    confirmDialog.cancelBtn:SetScript("OnClick", function()
        confirmDialog:Hide()
        if options.onCancel then options.onCancel() end
    end)


    confirmDialog:Show()
    confirmDialog:EnableKeyboard(true)
end


function GUI:CreateSectionHeader(parent, text)

    local isFirstElement = (parent._hasContent == false)
    if parent._hasContent ~= nil then
        parent._hasContent = true
    end


    local topMargin = isFirstElement and 0 or 12
    local containerHeight = isFirstElement and 18 or 30

    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(containerHeight)

    local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(header, 13, "", C.sectionHeader)
    header:SetText(text or "Section")
    header:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -topMargin)


    container.text = header
    container.parent = parent
    container.gap = isFirstElement and 34 or 46


    container.SetText = function(self, newText)
        header:SetText(newText)
    end


    local originalSetPoint = container.SetPoint
    container.SetPoint = function(self, point, ...)
        originalSetPoint(self, point, ...)

        if point == "TOPLEFT" then
            originalSetPoint(self, "RIGHT", parent, "RIGHT", -10, 0)

            if not container.underline then
                local underline = container:CreateTexture(nil, "ARTWORK")
                underline:SetHeight(2)
                underline:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
                underline:SetPoint("RIGHT", container, "RIGHT", 0, 0)
                underline:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.6)
                container.underline = underline
            end
        end
    end

    return container
end


function GUI:CreateSectionBox(parent, title)
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.05, 0.05, 0.08, 0.8)
    box:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)


    if title and title ~= "" then
        local titleText = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleText:SetFont(GetFontPath(), 12, "")
        titleText:SetTextColor(unpack(C.accentLight))
        titleText:SetText(title)
        titleText:SetPoint("TOPLEFT", 10, -8)
        box.title = titleText
    end


    box.currentY = -30
    box.padding = 12
    box.elementSpacing = 8


    function box:AddElement(element, height, spacing)
        local sp = spacing or self.elementSpacing
        element:SetPoint("TOPLEFT", self.padding, self.currentY)
        if element.SetPoint then

            element:SetPoint("TOPRIGHT", -self.padding, self.currentY)
        end
        self.currentY = self.currentY - (height or 25) - sp
    end


    function box:FinishLayout(bottomPadding)
        local pad = bottomPadding or 12
        self:SetHeight(math.abs(self.currentY) + pad)
        return math.abs(self.currentY) + pad
    end

    return box
end


function GUI:CreateCollapsibleSection(parent, title, isExpandedByDefault, badgeConfig)
    local container = CreateFrame("Frame", nil, parent)
    local isExpanded = isExpandedByDefault ~= false


    local header = CreateFrame("Button", nil, container, "BackdropTemplate")
    header:SetHeight(28)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    header:SetBackdropColor(C.bgLight[1], C.bgLight[2], C.bgLight[3], 0.6)
    header:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.5)


    local chevron = header:CreateFontString(nil, "OVERLAY")
    chevron:SetFont(GetFontPath(), 12, "")
    chevron:SetPoint("LEFT", 10, 0)
    chevron:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)


    local titleText = header:CreateFontString(nil, "OVERLAY")
    SetFont(titleText, 12, "", C.accent)
    titleText:SetText(title or "Section")
    titleText:SetPoint("LEFT", chevron, "RIGHT", 6, 0)


    local badge = nil
    if badgeConfig and badgeConfig.text then
        badge = CreateFrame("Frame", nil, header, "BackdropTemplate")
        badge:SetHeight(18)
        badge:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        badge:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.2)
        badge:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.5)

        local badgeText = badge:CreateFontString(nil, "OVERLAY")
        badgeText:SetFont(GetFontPath(), 10, "")
        badgeText:SetText(badgeConfig.text)
        badgeText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)
        badgeText:SetPoint("CENTER", 0, 0)


        local textWidth = badgeText:GetStringWidth() or 40
        badge:SetWidth(textWidth + 12)
        badge:SetPoint("RIGHT", header, "RIGHT", -10, 0)


        if badgeConfig.showFunc then
            badge:SetShown(badgeConfig.showFunc())
        end
    end


    local content = CreateFrame("Frame", nil, container)
    content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    content:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    content._hasContent = false


    local function UpdateState()
        if isExpanded then
            chevron:SetText("v")
            content:Show()
            container:SetHeight(header:GetHeight() + 4 + (content:GetHeight() or 0))
        else
            chevron:SetText(">")
            content:Hide()
            container:SetHeight(header:GetHeight())
        end
    end


    header:SetScript("OnClick", function()
        isExpanded = not isExpanded
        UpdateState()
        if container.OnExpandChanged then
            container.OnExpandChanged(isExpanded)
        end
    end)


    header:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.8)
    end)
    header:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.5)
    end)


    container.SetExpanded = function(self, expanded)
        isExpanded = expanded
        UpdateState()
    end

    container.GetExpanded = function()
        return isExpanded
    end

    container.UpdateHeight = function()
        UpdateState()
    end

    container.SetTitle = function(self, newTitle)
        titleText:SetText(newTitle)
    end


    container.UpdateBadge = function()
        if badge and badgeConfig and badgeConfig.showFunc then
            badge:SetShown(badgeConfig.showFunc())
        end
    end

    container.content = content
    container.header = header
    container.badge = badge

    UpdateState()
    return container
end


function GUI:CreateColorPicker(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 20)


    local swatch = CreateFrame("Button", nil, container, "BackdropTemplate")
    swatch:SetSize(16, 16)
    swatch:SetPoint("LEFT", 0, 0)
    swatch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    swatch:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)


    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Color")
    text:SetPoint("LEFT", swatch, "RIGHT", 6, 0)

    container.swatch = swatch
    container.label = text

    local function GetColor()
        if dbTable and dbKey then
            local c = dbTable[dbKey]
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
        end
        return 1, 1, 1, 1
    end

    local function SetColor(r, g, b, a)
        swatch:SetBackdropColor(r, g, b, a or 1)
        if dbTable and dbKey then
            dbTable[dbKey] = {r, g, b, a or 1}
        end
        if onChange then onChange(r, g, b, a) end
    end


    local r, g, b, a = GetColor()
    swatch:SetBackdropColor(r, g, b, a)

    container.GetColor = GetColor
    container.SetColor = SetColor


    swatch:SetScript("OnClick", function()
        local r, g, b, a = GetColor()
        local originalA = a or 1

        local info = {
            r = r,
            g = g,
            b = b,
            opacity = originalA,
            hasOpacity = true,
            swatchFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local newA = ColorPickerFrame:GetColorAlpha()
                SetColor(newR, newG, newB, newA)
            end,
            opacityFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local newA = ColorPickerFrame:GetColorAlpha()
                SetColor(newR, newG, newB, newA)
            end,
            cancelFunc = function(prev)
                SetColor(prev.r, prev.g, prev.b, originalA)
            end,
        }

        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)


    swatch:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
    end)
    swatch:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropBorderColor, self, 0.4, 0.4, 0.4, 1)
    end)

    return container
end


function GUI:CreateSubTabs(parent, tabs)
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(28)

    local tabButtons = {}
    local tabContents = {}
    local buttonWidth = 90
    local spacing = 2

    for i, tabInfo in ipairs(tabs) do

        local btn = CreateFrame("Button", nil, container, "BackdropTemplate")
        btn:SetSize(buttonWidth, 24)
        btn:SetPoint("TOPLEFT", 10 + (i-1) * (buttonWidth + spacing), 0)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(btn.text, 10, "", C.text)
        btn.text:SetText(tabInfo.name)
        btn.text:SetPoint("CENTER", 0, 0)

        btn.index = i
        tabButtons[i] = btn


        local content = CreateFrame("Frame", nil, container)
        content:SetPoint("TOPLEFT", 0, -30)
        content:SetPoint("BOTTOMRIGHT", 0, 0)
        content:Hide()
        content:EnableMouse(false)
        content._hasContent = false
        tabContents[i] = content


        if tabInfo.builder then
            tabInfo.builder(content)
        end
    end


    local function RelayoutSubTabs()
        local containerWidth = container:GetWidth()
        if containerWidth < 1 then return end

        local separatorSpacing = 15
        local availableWidth = containerWidth - 20


        local separatorCount = 0
        for _, tabInfo in ipairs(tabs) do
            if tabInfo.isSeparator then separatorCount = separatorCount + 1 end
        end

        local totalSpacing = (#tabButtons - 1) * spacing + (separatorCount * separatorSpacing)
        local newButtonWidth = math.floor((availableWidth - totalSpacing) / #tabButtons)
        newButtonWidth = math.max(newButtonWidth, 50)

        local xOffset = 10
        for i, btn in ipairs(tabButtons) do
            btn:SetWidth(newButtonWidth)
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", xOffset, 0)
            xOffset = xOffset + newButtonWidth + spacing


            if tabs[i] and tabs[i].isSeparator then
                xOffset = xOffset + separatorSpacing
            end
        end
    end


    container:SetScript("OnSizeChanged", RelayoutSubTabs)


    local function SelectSubTab(index)
        for i, btn in ipairs(tabButtons) do
            if i == index then

                pcall(btn.SetBackdropColor, btn, 0.12, 0.18, 0.18, 1)
                pcall(btn.SetBackdropBorderColor, btn, unpack(C.accent))
                btn.text:SetFont(GetFontPath(), 10, "")
                btn.text:SetTextColor(unpack(C.accent))
                tabContents[i]:Show()
            else

                pcall(btn.SetBackdropColor, btn, 0.15, 0.15, 0.15, 1)
                pcall(btn.SetBackdropBorderColor, btn, 0.3, 0.3, 0.3, 1)
                btn.text:SetFont(GetFontPath(), 10, "")
                btn.text:SetTextColor(unpack(C.text))
                tabContents[i]:Hide()
            end
        end
        container.selectedTab = index
    end


    for i, btn in ipairs(tabButtons) do
        btn:SetScript("OnClick", function() SelectSubTab(i) end)
        btn:SetScript("OnEnter", function(self)
            if container.selectedTab ~= i then
                pcall(self.SetBackdropBorderColor, self, unpack(C.accentHover))
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if container.selectedTab ~= i then
                pcall(self.SetBackdropBorderColor, self, 0.3, 0.3, 0.3, 1)
            end
        end)
    end

    container.tabButtons = tabButtons
    container.tabContents = tabContents
    container.SelectTab = SelectSubTab
    container.RelayoutSubTabs = RelayoutSubTabs


    SelectSubTab(1)


    C_Timer.After(0, RelayoutSubTabs)

    return container
end


function GUI:CreateDescription(parent, text, color)
    local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(desc, 11, "", color or C.textMuted)
    desc:SetText(text)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(true)
    return desc
end


function GUI:CreateCheckbox(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(300, 20)

    local box = CreateFrame("Button", nil, container, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 0, 0)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.1, 0.1, 0.1, 1)
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)


    box.check = box:CreateTexture(nil, "OVERLAY")
    box.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    box.check:SetPoint("CENTER", 0, 0)
    box.check:SetSize(20, 20)
    box.check:SetVertexColor(0.820, 0.180, 0.220, 1)
    box.check:SetDesaturated(true)
    box.check:Hide()

    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Option")
    text:SetPoint("LEFT", box, "RIGHT", 6, 0)

    container.box = box
    container.label = text

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.checked
    end

    local function SetValue(val)
        container.checked = val
        if val then
            box.check:Show()
            box:SetBackdropBorderColor(unpack(C.accent))
            box:SetBackdropColor(0.1, 0.2, 0.15, 1)
        else
            box.check:Hide()
            box:SetBackdropBorderColor(unpack(C.border))
            box:SetBackdropColor(0.1, 0.1, 0.1, 1)
        end
        if dbTable and dbKey then dbTable[dbKey] = val end
        if onChange then onChange(val) end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue
    SetValue(GetValue())

    box:SetScript("OnClick", function() SetValue(not GetValue()) end)
    box:SetScript("OnEnter", function(self) pcall(self.SetBackdropBorderColor, self, unpack(C.accentHover)) end)
    box:SetScript("OnLeave", function(self)
        if GetValue() then
            pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        else
            pcall(self.SetBackdropBorderColor, self, unpack(C.border))
        end
    end)

    return container
end


function GUI:CreateCheckboxCentered(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(100, 40)


    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 11, "", C.accentLight)
    text:SetText(label or "Option")
    text:SetPoint("TOP", container, "TOP", 0, 0)


    local box = CreateFrame("Button", nil, container, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("TOP", text, "BOTTOM", 0, -4)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.1, 0.1, 0.1, 1)
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)


    box.check = box:CreateTexture(nil, "OVERLAY")
    box.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    box.check:SetPoint("CENTER", 0, 0)
    box.check:SetSize(20, 20)
    box.check:SetVertexColor(0.820, 0.180, 0.220, 1)
    box.check:SetDesaturated(true)
    box.check:Hide()

    container.box = box
    container.label = text

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.checked
    end

    local function SetValue(val)
        container.checked = val
        if val then
            box.check:Show()
            box:SetBackdropBorderColor(unpack(C.accent))
            box:SetBackdropColor(0.1, 0.2, 0.15, 1)
        else
            box.check:Hide()
            box:SetBackdropBorderColor(unpack(C.border))
            box:SetBackdropColor(0.1, 0.1, 0.1, 1)
        end
        if dbTable and dbKey then dbTable[dbKey] = val end
        if onChange then onChange(val) end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue
    SetValue(GetValue())

    box:SetScript("OnClick", function() SetValue(not GetValue()) end)
    box:SetScript("OnEnter", function(self) pcall(self.SetBackdropBorderColor, self, unpack(C.accentHover)) end)
    box:SetScript("OnLeave", function(self)
        if GetValue() then
            pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        else
            pcall(self.SetBackdropBorderColor, self, unpack(C.border))
        end
    end)

    return container
end


function GUI:CreateColorPickerCentered(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(100, 40)


    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 11, "", C.accentLight)
    text:SetText(label or "Color")
    text:SetPoint("TOP", container, "TOP", 0, 0)


    local swatch = CreateFrame("Button", nil, container, "BackdropTemplate")
    swatch:SetSize(16, 16)
    swatch:SetPoint("TOP", text, "BOTTOM", 0, -4)
    swatch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    swatch:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    container.swatch = swatch
    container.label = text

    local function GetColor()
        if dbTable and dbKey then
            local c = dbTable[dbKey]
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
        end
        return 1, 1, 1, 1
    end

    local function SetColor(r, g, b, a)
        swatch:SetBackdropColor(r, g, b, a or 1)
        if dbTable and dbKey then
            dbTable[dbKey] = {r, g, b, a or 1}
        end
        if onChange then onChange(r, g, b, a) end
    end


    local r, g, b, a = GetColor()
    swatch:SetBackdropColor(r, g, b, a)

    container.GetColor = GetColor
    container.SetColor = SetColor


    swatch:SetScript("OnClick", function()
        local r, g, b, a = GetColor()
        local originalA = a or 1
        local info = {
            hasOpacity = true,
            opacity = originalA,
            r = r, g = g, b = b,
            swatchFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local newA = ColorPickerFrame:GetColorAlpha()
                SetColor(newR, newG, newB, newA)
            end,
            opacityFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                local newA = ColorPickerFrame:GetColorAlpha()
                SetColor(newR, newG, newB, newA)
            end,
            cancelFunc = function(prev)
                SetColor(prev.r, prev.g, prev.b, originalA)
            end,
        }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end)

    swatch:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
    end)
    swatch:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropBorderColor, self, 0.4, 0.4, 0.4, 1)
    end)

    return container
end


function GUI:CreateCheckboxInverted(parent, label, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(300, 20)

    local box = CreateFrame("Button", nil, container, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 0, 0)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.1, 0.1, 0.1, 1)
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    box.check = box:CreateTexture(nil, "OVERLAY")
    box.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    box.check:SetPoint("CENTER", 0, 0)
    box.check:SetSize(20, 20)
    box.check:SetVertexColor(0.820, 0.180, 0.220, 1)
    box.check:SetDesaturated(true)
    box.check:Hide()

    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Option")
    text:SetPoint("LEFT", box, "RIGHT", 6, 0)

    container.box = box
    container.label = text


    local function GetDBValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return true
    end

    local function IsChecked()
        return not GetDBValue()
    end

    local function SetChecked(checked)
        container.checked = checked
        local dbVal = not checked
        if checked then
            box.check:Show()
            box:SetBackdropBorderColor(unpack(C.accent))
            box:SetBackdropColor(0.1, 0.2, 0.15, 1)
        else
            box.check:Hide()
            box:SetBackdropBorderColor(unpack(C.border))
            box:SetBackdropColor(0.1, 0.1, 0.1, 1)
        end
        if dbTable and dbKey then dbTable[dbKey] = dbVal end
        if onChange then onChange(dbVal) end
    end

    container.GetValue = IsChecked
    container.SetValue = SetChecked
    SetChecked(IsChecked())

    box:SetScript("OnClick", function() SetChecked(not IsChecked()) end)
    box:SetScript("OnEnter", function(self) pcall(self.SetBackdropBorderColor, self, unpack(C.accentHover)) end)
    box:SetScript("OnLeave", function(self)
        if IsChecked() then
            pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        else
            pcall(self.SetBackdropBorderColor, self, unpack(C.border))
        end
    end)

    return container
end


function GUI:CreateSlider(parent, label, min, max, step, dbKey, dbTable, onChange, options)
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(60)
    container:EnableMouse(true)


    options = options or {}
    local deferOnDrag = options.deferOnDrag or false


    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 11, "", C.accentLight)
    text:SetText(label or "Setting")
    text:SetPoint("TOP", 0, 0)


    local trackContainer = CreateFrame("Frame", nil, container)
    trackContainer:SetHeight(6)
    trackContainer:SetPoint("TOPLEFT", 35, -18)
    trackContainer:SetPoint("TOPRIGHT", -35, -18)


    local trackBg = CreateFrame("Frame", nil, trackContainer, "BackdropTemplate")
    trackBg:SetAllPoints()
    trackBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    trackBg:SetBackdropColor(C.sliderTrack[1], C.sliderTrack[2], C.sliderTrack[3], 1)
    trackBg:SetBackdropBorderColor(0.1, 0.12, 0.15, 1)


    local trackFill = CreateFrame("Frame", nil, trackContainer, "BackdropTemplate")
    trackFill:SetPoint("TOPLEFT", 1, -1)
    trackFill:SetPoint("BOTTOMLEFT", 1, 1)
    trackFill:SetWidth(1)
    trackFill:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    trackFill:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 1)


    local slider = CreateFrame("Slider", nil, trackContainer)
    slider:SetAllPoints()
    slider:SetOrientation("HORIZONTAL")
    slider:EnableMouse(true)
    slider:SetHitRectInsets(0, 0, -10, -10)


    local thumbFrame = CreateFrame("Frame", nil, slider, "BackdropTemplate")
    thumbFrame:SetSize(14, 14)
    thumbFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    thumbFrame:SetBackdropColor(C.sliderThumb[1], C.sliderThumb[2], C.sliderThumb[3], 1)
    thumbFrame:SetBackdropBorderColor(C.sliderThumbBorder[1], C.sliderThumbBorder[2], C.sliderThumbBorder[3], 1)
    thumbFrame:SetFrameLevel(slider:GetFrameLevel() + 2)
    thumbFrame:EnableMouse(false)


    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(14, 14)
    thumb:SetAlpha(0)


    local minText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(minText, 10, "", C.textMuted)
    minText:SetText(tostring(min or 0))
    minText:SetPoint("RIGHT", trackContainer, "LEFT", -5, 0)


    local maxText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(maxText, 10, "", C.textMuted)
    maxText:SetText(tostring(max or 100))
    maxText:SetPoint("LEFT", trackContainer, "RIGHT", 5, 0)


    local editBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    editBox:SetSize(70, 22)
    editBox:SetPoint("TOP", trackContainer, "BOTTOM", 0, -6)
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editBox:SetBackdropColor(0.08, 0.08, 0.08, 1)
    editBox:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    editBox:SetFont(GetFontPath(), 11, "")
    editBox:SetTextColor(unpack(C.text))
    editBox:SetJustifyH("CENTER")
    editBox:SetAutoFocus(false)


    slider:SetMinMaxValues(min or 0, max or 100)
    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)

    container.slider = slider
    container.editBox = editBox
    container.trackFill = trackFill
    container.thumbFrame = thumbFrame
    container.trackContainer = trackContainer
    container.min = min or 0
    container.max = max or 100
    container.step = step or 1


    local isDragging = false


    local function UpdateTrackFill(value)
        local minVal, maxVal = container.min, container.max
        local pct = (value - minVal) / (maxVal - minVal)
        pct = math.max(0, math.min(1, pct))

        local trackWidth = trackContainer:GetWidth() - 2
        local fillWidth = math.max(1, pct * trackWidth)
        trackFill:SetWidth(fillWidth)

        local thumbX = pct * (trackWidth - 14) + 7
        thumbFrame:ClearAllPoints()
        thumbFrame:SetPoint("CENTER", trackContainer, "LEFT", thumbX + 1, 0)
    end

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] or container.min end
        return container.value or container.min
    end

    local function FormatVal(val)
        if container.step >= 1 then
            return tostring(math.floor(val))
        else
            return string.format("%.2f", val)
        end
    end

    local function SetValue(val, skipCallback)
        val = math.max(container.min, math.min(container.max, val))
        if container.step >= 1 then
            val = math.floor(val / container.step + 0.5) * container.step
        else
            local mult = 1 / container.step
            val = math.floor(val * mult + 0.5) / mult
        end

        container.value = val
        slider:SetValue(val)
        editBox:SetText(FormatVal(val))
        UpdateTrackFill(val)

        if dbTable and dbKey then dbTable[dbKey] = val end
        if onChange and not skipCallback then onChange(val) end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue


    slider:SetScript("OnValueChanged", function(self, value)
        if container.step >= 1 then
            value = math.floor(value / container.step + 0.5) * container.step
        else
            local mult = 1 / container.step
            value = math.floor(value * mult + 0.5) / mult
        end
        editBox:SetText(FormatVal(value))
        container.value = value
        UpdateTrackFill(value)
        if dbTable and dbKey then dbTable[dbKey] = value end


        if deferOnDrag then
            if not isDragging then
                if onChange then onChange(value) end
            end
        else
            if onChange then onChange(value) end
        end
    end)


    slider:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDragging = true
        end
    end)

    slider:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and isDragging then
            isDragging = false
            if deferOnDrag and onChange then
                local value = self:GetValue()
                if container.step >= 1 then
                    value = math.floor(value / container.step + 0.5) * container.step
                else
                    local mult = 1 / container.step
                    value = math.floor(value * mult + 0.5) / mult
                end
                onChange(value)
            end
        end
    end)


    slider:SetScript("OnEnter", function()
        thumbFrame:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    slider:SetScript("OnLeave", function()
        thumbFrame:SetBackdropBorderColor(C.sliderThumbBorder[1], C.sliderThumbBorder[2], C.sliderThumbBorder[3], 1)
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val then SetValue(val) end
        self:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        editBox:SetText(FormatVal(GetValue()))
        self:ClearFocus()
    end)


    editBox:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    editBox:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    editBox:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    end)
    editBox:SetScript("OnLeave", function(self)
        if not self:HasFocus() then
            self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end
    end)


    C_Timer.After(0, function()
        SetValue(GetValue(), true)
    end)

    return container
end


local CHEVRON_ZONE_WIDTH = 28
local CHEVRON_BG_ALPHA = 0.15
local CHEVRON_BG_ALPHA_HOVER = 0.25
local CHEVRON_TEXT_ALPHA = 0.7

function GUI:CreateDropdown(parent, label, options, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(60)
    container:SetWidth(200)


    if label and label ~= "" then
        local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(text, 11, "", C.accentLight)
        text:SetText(label)
        text:SetPoint("TOP", container, "TOP", 0, 0)
    end


    local dropdown = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropdown:SetHeight(24)
    dropdown:SetPoint("TOPLEFT", container, "TOPLEFT", 35, -16)
    dropdown:SetPoint("RIGHT", container, "RIGHT", -35, 0)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dropdown:SetBackdropColor(0.08, 0.08, 0.08, 1)
    dropdown:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)


    local chevronZone = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    chevronZone:SetWidth(CHEVRON_ZONE_WIDTH)
    chevronZone:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", -1, -1)
    chevronZone:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -1, 1)
    chevronZone:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)


    local separator = chevronZone:CreateTexture(nil, "ARTWORK")
    separator:SetWidth(1)
    separator:SetPoint("TOPLEFT", chevronZone, "TOPLEFT", 0, 0)
    separator:SetPoint("BOTTOMLEFT", chevronZone, "BOTTOMLEFT", 0, 0)
    separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)


    local chevronLeft = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronLeft:SetSize(7, 2)
    chevronLeft:SetPoint("CENTER", chevronZone, "CENTER", -2, -1)
    chevronLeft:SetRotation(math.rad(-45))

    local chevronRight = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronRight:SetSize(7, 2)
    chevronRight:SetPoint("CENTER", chevronZone, "CENTER", 2, -1)
    chevronRight:SetRotation(math.rad(45))

    dropdown.chevronLeft = chevronLeft
    dropdown.chevronRight = chevronRight
    dropdown.chevronZone = chevronZone
    dropdown.separator = separator


    dropdown.selected = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(dropdown.selected, 11, "", C.text)
    dropdown.selected:SetPoint("LEFT", 8, 0)
    dropdown.selected:SetPoint("RIGHT", chevronZone, "LEFT", -5, 0)
    dropdown.selected:SetJustifyH("CENTER")


    dropdown:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA_HOVER)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropBorderColor, self, 0.35, 0.35, 0.35, 1)
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    end)

    container.dropdown = dropdown


    local normalizedOptions = {}
    if type(options) == "table" then
        for i, opt in ipairs(options) do
            if type(opt) == "table" then
                normalizedOptions[i] = opt
            else

                normalizedOptions[i] = {value = opt:lower(), text = opt}
            end
        end
    end
    container.options = normalizedOptions

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.value
    end

    local function GetDisplayText(val)
        for _, opt in ipairs(container.options) do
            if opt.value == val then return opt.text end
        end

        if type(val) == "string" then
            return val:sub(1,1):upper() .. val:sub(2)
        end
        return tostring(val or "Select...")
    end

    local function SetValue(val, skipCallback)
        container.value = val
        dropdown.selected:SetText(GetDisplayText(val))
        if dbTable and dbKey then dbTable[dbKey] = val end
        if onChange and not skipCallback then onChange(val) end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue


    SetValue(GetValue(), true)


    local menuFrame = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    menuFrame:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menuFrame:SetPoint("TOPRIGHT", dropdown, "BOTTOMRIGHT", 0, -2)
    menuFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menuFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
    menuFrame:SetBackdropBorderColor(unpack(C.accent))
    menuFrame:SetFrameStrata("TOOLTIP")
    menuFrame:Hide()

    local menuButtons = {}
    local buttonHeight = 22

    for i, opt in ipairs(container.options) do
        local btn = CreateFrame("Button", nil, menuFrame, "BackdropTemplate")
        btn:SetHeight(buttonHeight)
        btn:SetPoint("TOPLEFT", 2, -2 - (i-1) * buttonHeight)
        btn:SetPoint("TOPRIGHT", -2, -2 - (i-1) * buttonHeight)

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(btn.text, 11, "", C.text)
        btn.text:SetText(opt.text)
        btn.text:SetPoint("LEFT", 8, 0)

        btn:SetScript("OnEnter", function(self)
            pcall(function()
                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
                self:SetBackdropColor(0.820, 0.180, 0.220, 0.25)
            end)

        end)
        btn:SetScript("OnLeave", function(self)
            pcall(function()
                self:SetBackdrop(nil)
            end)
        end)
        btn:SetScript("OnClick", function()
            SetValue(opt.value)
            menuFrame:Hide()
        end)

        menuButtons[i] = btn
    end

    menuFrame:SetHeight(4 + #container.options * buttonHeight)


    dropdown:SetScript("OnClick", function()
        if menuFrame:IsShown() then
            menuFrame:Hide()
        else
            menuFrame:Show()
        end
    end)


    local closeTimer = 0
    local CLOSE_DELAY = 0.15

    menuFrame:SetScript("OnShow", function()
        closeTimer = 0
        menuFrame.__checkElapsed = 0
        menuFrame:SetScript("OnUpdate", function(self, elapsed)

            self.__checkElapsed = self.__checkElapsed + elapsed
            if self.__checkElapsed < 0.066 then return end
            local deltaTime = self.__checkElapsed
            self.__checkElapsed = 0


            local isOverDropdown = dropdown:IsMouseOver()
            local isOverMenu = self:IsMouseOver()


            local scale = dropdown:GetEffectiveScale()
            local mouseX, mouseY = GetCursorPosition()
            mouseX, mouseY = mouseX / scale, mouseY / scale

            local dLeft, dBottom, dWidth, dHeight = dropdown:GetRect()
            local mLeft, mBottom, mWidth, mHeight = self:GetRect()

            if dLeft and mLeft then

                local inHorizontalBounds = mouseX >= dLeft and mouseX <= (dLeft + dWidth)

                local inGap = mouseY >= mBottom and mouseY <= (dBottom + dHeight) and inHorizontalBounds

                if isOverDropdown or isOverMenu or inGap then
                    closeTimer = 0
                else
                    closeTimer = closeTimer + deltaTime
                    if closeTimer > CLOSE_DELAY then
                        self:Hide()
                    end
                end
            else

                if not isOverDropdown and not isOverMenu then
                    closeTimer = closeTimer + deltaTime
                    if closeTimer > CLOSE_DELAY then
                        self:Hide()
                    end
                else
                    closeTimer = 0
                end
            end
        end)
    end)

    menuFrame:SetScript("OnHide", function()
        menuFrame:SetScript("OnUpdate", nil)
        closeTimer = 0
    end)

    return container
end


function GUI:CreateDropdownFullWidth(parent, label, options, dbKey, dbTable, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(45)
    container:SetWidth(200)


    if label and label ~= "" then
        local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(text, 11, "", C.accentLight)
        text:SetText(label)
        text:SetPoint("TOP", container, "TOP", 0, 0)
    end


    local dropdown = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropdown:SetHeight(24)
    dropdown:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -18)
    dropdown:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dropdown:SetBackdropColor(0.08, 0.08, 0.08, 1)
    dropdown:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)


    local chevronZone = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    chevronZone:SetWidth(CHEVRON_ZONE_WIDTH)
    chevronZone:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", -1, -1)
    chevronZone:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -1, 1)
    chevronZone:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)


    local separator = chevronZone:CreateTexture(nil, "ARTWORK")
    separator:SetWidth(1)
    separator:SetPoint("TOPLEFT", chevronZone, "TOPLEFT", 0, 0)
    separator:SetPoint("BOTTOMLEFT", chevronZone, "BOTTOMLEFT", 0, 0)
    separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)


    local chevronLeft = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronLeft:SetSize(7, 2)
    chevronLeft:SetPoint("CENTER", chevronZone, "CENTER", -2, -1)
    chevronLeft:SetRotation(math.rad(-45))

    local chevronRight = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronRight:SetSize(7, 2)
    chevronRight:SetPoint("CENTER", chevronZone, "CENTER", 2, -1)
    chevronRight:SetRotation(math.rad(45))

    dropdown.chevronLeft = chevronLeft
    dropdown.chevronRight = chevronRight
    dropdown.chevronZone = chevronZone
    dropdown.separator = separator


    dropdown.selected = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(dropdown.selected, 11, "", C.text)
    dropdown.selected:SetPoint("LEFT", 10, 0)
    dropdown.selected:SetPoint("RIGHT", chevronZone, "LEFT", -5, 0)
    dropdown.selected:SetJustifyH("CENTER")


    dropdown:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA_HOVER)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropBorderColor, self, 0.35, 0.35, 0.35, 1)
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    end)

    container.dropdown = dropdown


    local normalizedOptions = {}
    if type(options) == "table" then
        for i, opt in ipairs(options) do
            if type(opt) == "table" then
                normalizedOptions[i] = opt
            else
                normalizedOptions[i] = {value = opt:lower(), text = opt}
            end
        end
    end
    container.options = normalizedOptions

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.value
    end

    local function GetDisplayText(val)
        for _, opt in ipairs(container.options) do
            if opt.value == val then return opt.text end
        end
        if type(val) == "string" then
            return val:sub(1,1):upper() .. val:sub(2)
        end
        return tostring(val or "Select...")
    end

    local function SetValue(val, skipCallback)
        container.value = val
        dropdown.selected:SetText(GetDisplayText(val))
        if dbTable and dbKey then dbTable[dbKey] = val end
        if onChange and not skipCallback then onChange(val) end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue
    SetValue(GetValue(), true)


    local menuFrame = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    menuFrame:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menuFrame:SetPoint("TOPRIGHT", dropdown, "BOTTOMRIGHT", 0, -2)
    menuFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menuFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
    menuFrame:SetBackdropBorderColor(unpack(C.accent))
    menuFrame:SetFrameStrata("TOOLTIP")
    menuFrame:Hide()

    local buttonHeight = 22
    for i, opt in ipairs(container.options) do
        local btn = CreateFrame("Button", nil, menuFrame, "BackdropTemplate")
        btn:SetHeight(buttonHeight)
        btn:SetPoint("TOPLEFT", 2, -2 - (i-1) * buttonHeight)
        btn:SetPoint("TOPRIGHT", -2, -2 - (i-1) * buttonHeight)

        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        SetFont(btn.text, 11, "", C.text)
        btn.text:SetText(opt.text)
        btn.text:SetPoint("LEFT", 8, 0)

        btn:SetScript("OnEnter", function(self)
            pcall(function()
                self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
                self:SetBackdropColor(0.820, 0.180, 0.220, 0.25)
            end)

        end)
        btn:SetScript("OnLeave", function(self)
            pcall(function() self:SetBackdrop(nil) end)
        end)
        btn:SetScript("OnClick", function()
            SetValue(opt.value)
            menuFrame:Hide()
        end)
    end

    menuFrame:SetHeight(4 + #container.options * buttonHeight)

    dropdown:SetScript("OnClick", function()
        if menuFrame:IsShown() then
            menuFrame:Hide()
        else
            menuFrame:Show()
        end
    end)


    local closeTimer = 0
    menuFrame:SetScript("OnShow", function()
        closeTimer = 0
        menuFrame.__checkElapsed = 0
        menuFrame:SetScript("OnUpdate", function(self, elapsed)

            self.__checkElapsed = self.__checkElapsed + elapsed
            if self.__checkElapsed < 0.066 then return end
            local deltaTime = self.__checkElapsed
            self.__checkElapsed = 0

            local isOverDropdown = dropdown:IsMouseOver()
            local isOverMenu = self:IsMouseOver()
            if not isOverDropdown and not isOverMenu then
                closeTimer = closeTimer + deltaTime
                if closeTimer > 0.15 then
                    self:Hide()
                end
            else
                closeTimer = 0
            end
        end)
    end)

    menuFrame:SetScript("OnHide", function()
        menuFrame:SetScript("OnUpdate", nil)
        closeTimer = 0
    end)

    return container
end


local FORM_ROW_HEIGHT = 28


function GUI:CreateFormToggle(parent, label, dbKey, dbTable, onChange, registryInfo)
    if parent._hasContent ~= nil then parent._hasContent = true end
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(FORM_ROW_HEIGHT)


    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Option")
    text:SetPoint("LEFT", 0, 0)


    local track = CreateFrame("Button", nil, container, "BackdropTemplate")
    track:SetSize(40, 20)
    track:SetPoint("LEFT", container, "LEFT", 180, 0)
    track:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })


    local thumb = CreateFrame("Frame", nil, track, "BackdropTemplate")
    thumb:SetSize(16, 16)
    thumb:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    thumb:SetBackdropColor(C.toggleThumb[1], C.toggleThumb[2], C.toggleThumb[3], 1)
    thumb:SetBackdropBorderColor(0.85, 0.85, 0.85, 1)
    thumb:SetFrameLevel(track:GetFrameLevel() + 1)

    container.track = track
    container.thumb = thumb
    container.label = text

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.checked
    end

    local function UpdateVisual(val)
        if val then

            track:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 1)
            track:SetBackdropBorderColor(C.accent[1] * 0.8, C.accent[2] * 0.8, C.accent[3] * 0.8, 1)
            thumb:ClearAllPoints()
            thumb:SetPoint("RIGHT", track, "RIGHT", -2, 0)
        else

            track:SetBackdropColor(C.toggleOff[1], C.toggleOff[2], C.toggleOff[3], 1)
            track:SetBackdropBorderColor(0.12, 0.14, 0.18, 1)
            thumb:ClearAllPoints()
            thumb:SetPoint("LEFT", track, "LEFT", 2, 0)
        end
    end

    local function SetValue(val, skipCallback)
        container.checked = val
        UpdateVisual(val)
        if dbTable and dbKey then dbTable[dbKey] = val end
        BroadcastToSiblings(container, val)
        if onChange and not skipCallback then onChange(val) end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue
    container.UpdateVisual = UpdateVisual


    RegisterWidgetInstance(container, dbTable, dbKey)

    SetValue(GetValue(), true)


    track:SetScript("OnClick", function() SetValue(not GetValue()) end)


    track:SetScript("OnEnter", function(self)
        if GetValue() then
            self:SetBackdropBorderColor(C.accentHover[1], C.accentHover[2], C.accentHover[3], 1)
        else
            self:SetBackdropBorderColor(0.25, 0.28, 0.35, 1)
        end
    end)
    track:SetScript("OnLeave", function(self)
        if GetValue() then
            self:SetBackdropBorderColor(C.accent[1] * 0.8, C.accent[2] * 0.8, C.accent[3] * 0.8, 1)
        else
            self:SetBackdropBorderColor(0.12, 0.14, 0.18, 1)
        end
    end)


    container.SetEnabled = function(self, enabled)
        track:EnableMouse(enabled)

        container:SetAlpha(enabled and 1 or 0.4)
    end


    if GUI._searchContext.tabIndex and label and not GUI._suppressSearchRegistration then
        local regKey = label .. "_" .. (GUI._searchContext.tabIndex or 0) .. "_" .. (GUI._searchContext.subTabIndex or 0)
        if not GUI.SettingsRegistryKeys[regKey] then
            GUI.SettingsRegistryKeys[regKey] = true
            local entry = {
                label = label,
                widgetType = "toggle",
                tabIndex = GUI._searchContext.tabIndex,
                tabName = GUI._searchContext.tabName,
                subTabIndex = GUI._searchContext.subTabIndex,
                subTabName = GUI._searchContext.subTabName,
                sectionName = GUI._searchContext.sectionName,
                widgetBuilder = function(p)
                    return GUI:CreateFormToggle(p, label, dbKey, dbTable, onChange)
                end,
            }

            if registryInfo and registryInfo.keywords then
                entry.keywords = registryInfo.keywords
            end
            table.insert(GUI.SettingsRegistry, entry)
        end
    end

    return container
end


function GUI:CreateFormToggleInverted(parent, label, dbKey, dbTable, onChange)
    if parent._hasContent ~= nil then parent._hasContent = true end
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(FORM_ROW_HEIGHT)


    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Option")
    text:SetPoint("LEFT", 0, 0)


    local track = CreateFrame("Button", nil, container, "BackdropTemplate")
    track:SetSize(40, 20)
    track:SetPoint("LEFT", container, "LEFT", 180, 0)
    track:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })


    local thumb = CreateFrame("Frame", nil, track, "BackdropTemplate")
    thumb:SetSize(16, 16)
    thumb:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    thumb:SetBackdropColor(C.toggleThumb[1], C.toggleThumb[2], C.toggleThumb[3], 1)
    thumb:SetBackdropBorderColor(0.85, 0.85, 0.85, 1)
    thumb:SetFrameLevel(track:GetFrameLevel() + 1)

    container.track = track
    container.thumb = thumb
    container.label = text


    local function GetDBValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return true
    end

    local function IsOn()
        return not GetDBValue()
    end

    local function UpdateVisual(isOn)
        if isOn then
            track:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 1)
            track:SetBackdropBorderColor(C.accent[1] * 0.8, C.accent[2] * 0.8, C.accent[3] * 0.8, 1)
            thumb:ClearAllPoints()
            thumb:SetPoint("RIGHT", track, "RIGHT", -2, 0)
        else
            track:SetBackdropColor(C.toggleOff[1], C.toggleOff[2], C.toggleOff[3], 1)
            track:SetBackdropBorderColor(0.12, 0.14, 0.18, 1)
            thumb:ClearAllPoints()
            thumb:SetPoint("LEFT", track, "LEFT", 2, 0)
        end
    end

    local function SetOn(isOn, skipCallback)
        container.checked = isOn
        local dbVal = not isOn
        UpdateVisual(isOn)
        if dbTable and dbKey then dbTable[dbKey] = dbVal end
        BroadcastToSiblings(container, isOn)
        if onChange and not skipCallback then onChange(dbVal) end
    end

    container.GetValue = IsOn
    container.SetValue = SetOn
    container.UpdateVisual = UpdateVisual


    RegisterWidgetInstance(container, dbTable, dbKey)

    SetOn(IsOn(), true)

    track:SetScript("OnClick", function() SetOn(not IsOn()) end)

    track:SetScript("OnEnter", function(self)
        if IsOn() then
            self:SetBackdropBorderColor(C.accentHover[1], C.accentHover[2], C.accentHover[3], 1)
        else
            self:SetBackdropBorderColor(0.25, 0.28, 0.35, 1)
        end
    end)
    track:SetScript("OnLeave", function(self)
        if IsOn() then
            self:SetBackdropBorderColor(C.accent[1] * 0.8, C.accent[2] * 0.8, C.accent[3] * 0.8, 1)
        else
            self:SetBackdropBorderColor(0.12, 0.14, 0.18, 1)
        end
    end)


    container.SetEnabled = function(self, enabled)
        track:EnableMouse(enabled)

        container:SetAlpha(enabled and 1 or 0.4)
    end

    return container
end


function GUI:CreateFormCheckbox(parent, label, dbKey, dbTable, onChange, registryInfo)

    return GUI:CreateFormToggle(parent, label, dbKey, dbTable, onChange, registryInfo)
end


function GUI:CreateFormCheckboxOriginal(parent, label, dbKey, dbTable, onChange)
    if parent._hasContent ~= nil then parent._hasContent = true end
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(FORM_ROW_HEIGHT)


    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Option")
    text:SetPoint("LEFT", 0, 0)


    local box = CreateFrame("Button", nil, container, "BackdropTemplate")
    box:SetSize(18, 18)
    box:SetPoint("LEFT", container, "LEFT", 180, 0)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0.1, 0.1, 0.1, 1)
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)


    box.check = box:CreateTexture(nil, "OVERLAY")
    box.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    box.check:SetPoint("CENTER", 0, 0)
    box.check:SetSize(22, 22)
    box.check:SetVertexColor(0.820, 0.180, 0.220, 1)
    box.check:SetDesaturated(true)
    box.check:Hide()

    container.box = box
    container.label = text

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.checked
    end

    local function UpdateVisual(val)
        if val then
            box.check:Show()
            box:SetBackdropBorderColor(unpack(C.accent))
            box:SetBackdropColor(0.1, 0.2, 0.15, 1)
        else
            box.check:Hide()
            box:SetBackdropBorderColor(unpack(C.border))
            box:SetBackdropColor(0.1, 0.1, 0.1, 1)
        end
    end

    local function SetValue(val, skipCallback)
        container.checked = val
        UpdateVisual(val)
        if dbTable and dbKey then dbTable[dbKey] = val end
        BroadcastToSiblings(container, val)
        if onChange and not skipCallback then onChange(val) end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue
    container.UpdateVisual = UpdateVisual


    RegisterWidgetInstance(container, dbTable, dbKey)

    SetValue(GetValue(), true)

    box:SetScript("OnClick", function() SetValue(not GetValue()) end)
    box:SetScript("OnEnter", function(self) pcall(self.SetBackdropBorderColor, self, unpack(C.accentHover)) end)
    box:SetScript("OnLeave", function(self)
        if GetValue() then
            pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        else
            pcall(self.SetBackdropBorderColor, self, unpack(C.border))
        end
    end)

    return container
end


function GUI:CreateFormCheckboxInverted(parent, label, dbKey, dbTable, onChange)

    return GUI:CreateFormToggleInverted(parent, label, dbKey, dbTable, onChange)
end

function GUI:CreateFormSlider(parent, label, min, max, step, dbKey, dbTable, onChange, options, registryInfo)
    if parent._hasContent ~= nil then parent._hasContent = true end
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(FORM_ROW_HEIGHT)
    container:EnableMouse(true)

    options = options or {}
    local deferOnDrag = options.deferOnDrag or false
    local precision = options.precision
    local formatStr = precision and string.format("%%.%df", precision) or (step < 1 and "%.2f" or "%d")


    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Setting")
    text:SetPoint("LEFT", 0, 0)
    container.label = text


    local trackContainer = CreateFrame("Frame", nil, container)
    trackContainer:SetHeight(6)
    trackContainer:SetPoint("LEFT", container, "LEFT", 180, 0)
    trackContainer:SetPoint("RIGHT", container, "RIGHT", -70, 0)


    local trackBg = CreateFrame("Frame", nil, trackContainer, "BackdropTemplate")
    trackBg:SetAllPoints()
    trackBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 0, right = 0, top = 0, bottom = 0},
    })
    trackBg:SetBackdropColor(C.sliderTrack[1], C.sliderTrack[2], C.sliderTrack[3], 1)
    trackBg:SetBackdropBorderColor(0.1, 0.12, 0.15, 1)


    local trackFill = CreateFrame("Frame", nil, trackContainer, "BackdropTemplate")
    trackFill:SetPoint("TOPLEFT", 1, -1)
    trackFill:SetPoint("BOTTOMLEFT", 1, 1)
    trackFill:SetWidth(1)
    trackFill:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    trackFill:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 1)


    local slider = CreateFrame("Slider", nil, trackContainer)
    slider:SetAllPoints()
    slider:SetOrientation("HORIZONTAL")
    slider:SetHitRectInsets(0, 0, -10, -10)


    local thumbFrame = CreateFrame("Frame", nil, slider, "BackdropTemplate")
    thumbFrame:SetSize(14, 14)
    thumbFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    thumbFrame:SetBackdropColor(C.sliderThumb[1], C.sliderThumb[2], C.sliderThumb[3], 1)
    thumbFrame:SetBackdropBorderColor(C.sliderThumbBorder[1], C.sliderThumbBorder[2], C.sliderThumbBorder[3], 1)
    thumbFrame:SetFrameLevel(slider:GetFrameLevel() + 2)
    thumbFrame:EnableMouse(false)


    local thumbRound = thumbFrame:CreateTexture(nil, "OVERLAY")
    thumbRound:SetAllPoints()
    thumbRound:SetColorTexture(1, 1, 1, 0)


    slider.thumbFrame = thumbFrame


    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(14, 14)
    thumb:SetAlpha(0)


    local editBox = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    editBox:SetSize(60, 22)
    editBox:SetPoint("RIGHT", 0, 0)
    editBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    editBox:SetBackdropColor(0.08, 0.08, 0.08, 1)
    editBox:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    editBox:SetFont(GetFontPath(), 11, "")
    editBox:SetTextColor(unpack(C.text))
    editBox:SetJustifyH("CENTER")
    editBox:SetAutoFocus(false)


    slider:SetMinMaxValues(min or 0, max or 100)
    slider:SetValueStep(step or 1)
    slider:SetObeyStepOnDrag(true)
    slider:EnableMouse(true)

    container.slider = slider
    container.editBox = editBox
    container.trackFill = trackFill
    container.thumbFrame = thumbFrame
    container.trackContainer = trackContainer
    container.min = min or 0
    container.max = max or 100
    container.step = step or 1

    local isDragging = false


    local function UpdateTrackFill(value)
        local minVal, maxVal = container.min, container.max
        local pct = (value - minVal) / (maxVal - minVal)
        pct = math.max(0, math.min(1, pct))

        local trackWidth = trackContainer:GetWidth() - 2
        local fillWidth = math.max(1, pct * trackWidth)
        trackFill:SetWidth(fillWidth)


        local thumbX = pct * (trackWidth - 14) + 7
        thumbFrame:SetPoint("CENTER", trackContainer, "LEFT", thumbX + 1, 0)
    end

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] or container.min end
        return container.value or container.min
    end

    local function UpdateVisual(val)
        val = math.max(container.min, math.min(container.max, val))
        if not precision then
            val = math.floor(val / container.step + 0.5) * container.step
        end
        slider:SetValue(val)
        editBox:SetText(string.format(formatStr, val))
        UpdateTrackFill(val)
    end

    local function SetValue(val, skipOnChange)
        val = math.max(container.min, math.min(container.max, val))
        if precision then
            local factor = 10 ^ precision
            val = math.floor(val * factor + 0.5) / factor
        else
            val = math.floor(val / container.step + 0.5) * container.step
        end
        container.value = val
        UpdateVisual(val)
        if dbTable and dbKey then dbTable[dbKey] = val end
        BroadcastToSiblings(container, val)
        if not skipOnChange and onChange then onChange(val) end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue
    container.UpdateVisual = UpdateVisual


    RegisterWidgetInstance(container, dbTable, dbKey)

    slider:SetScript("OnValueChanged", function(self, value, userInput)

        if userInput and container.isEnabled == false then return end

        value = math.floor(value / container.step + 0.5) * container.step
        editBox:SetText(string.format(formatStr, value))
        UpdateTrackFill(value)
        if dbTable and dbKey then dbTable[dbKey] = value end
        if userInput then
            BroadcastToSiblings(container, value)
            if deferOnDrag and isDragging then return end
            if onChange then onChange(value) end
        end
    end)

    slider:SetScript("OnMouseDown", function() isDragging = true end)
    slider:SetScript("OnMouseUp", function()
        if isDragging and deferOnDrag then
            isDragging = false
            if onChange then onChange(slider:GetValue()) end
        end
        isDragging = false
    end)


    slider:SetScript("OnEnter", function()
        thumbFrame:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    slider:SetScript("OnLeave", function()
        thumbFrame:SetBackdropBorderColor(C.sliderThumbBorder[1], C.sliderThumbBorder[2], C.sliderThumbBorder[3], 1)
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText()) or container.min
        SetValue(val)
        self:ClearFocus()
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(string.format(formatStr, GetValue()))
        self:ClearFocus()
    end)


    editBox:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    editBox:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    editBox:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    end)
    editBox:SetScript("OnLeave", function(self)
        if not self:HasFocus() then
            self:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
        end
    end)


    trackContainer:SetScript("OnSizeChanged", function(self, width, height)
        if width and width > 0 then
            UpdateTrackFill(GetValue())
        end
    end)


    SetValue(GetValue(), true)


    container.SetEnabled = function(self, enabled)
        slider:EnableMouse(enabled)
        editBox:EnableMouse(enabled)
        editBox:SetEnabled(enabled)


        container.isEnabled = enabled


        container:SetAlpha(enabled and 1 or 0.4)
    end


    container.isEnabled = true


    if GUI._searchContext.tabIndex and label and not GUI._suppressSearchRegistration then
        local regKey = label .. "_" .. (GUI._searchContext.tabIndex or 0) .. "_" .. (GUI._searchContext.subTabIndex or 0)
        if not GUI.SettingsRegistryKeys[regKey] then
            GUI.SettingsRegistryKeys[regKey] = true
            table.insert(GUI.SettingsRegistry, {
                label = label,
                widgetType = "slider",
                tabIndex = GUI._searchContext.tabIndex,
                tabName = GUI._searchContext.tabName,
                subTabIndex = GUI._searchContext.subTabIndex,
                subTabName = GUI._searchContext.subTabName,
                sectionName = GUI._searchContext.sectionName,
                widgetBuilder = function(p)
                    return GUI:CreateFormSlider(p, label, min, max, step, dbKey, dbTable, onChange, options)
                end,
            })
        end
    end

    return container
end

function GUI:CreateFormDropdown(parent, label, options, dbKey, dbTable, onChange, registryInfo)
    if parent._hasContent ~= nil then parent._hasContent = true end
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(FORM_ROW_HEIGHT)


    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Setting")
    text:SetPoint("LEFT", 0, 0)


    local dropdown = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropdown:SetHeight(24)
    dropdown:SetPoint("LEFT", container, "LEFT", 180, 0)
    dropdown:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    dropdown:SetBackdropColor(0.08, 0.08, 0.08, 1)
    dropdown:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)


    local chevronZone = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    chevronZone:SetWidth(CHEVRON_ZONE_WIDTH)
    chevronZone:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", -1, -1)
    chevronZone:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -1, 1)
    chevronZone:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)


    local separator = chevronZone:CreateTexture(nil, "ARTWORK")
    separator:SetWidth(1)
    separator:SetPoint("TOPLEFT", chevronZone, "TOPLEFT", 0, 0)
    separator:SetPoint("BOTTOMLEFT", chevronZone, "BOTTOMLEFT", 0, 0)
    separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)


    local chevronLeft = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronLeft:SetSize(7, 2)
    chevronLeft:SetPoint("CENTER", chevronZone, "CENTER", -2, -1)
    chevronLeft:SetRotation(math.rad(-45))

    local chevronRight = chevronZone:CreateTexture(nil, "OVERLAY")
    chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    chevronRight:SetSize(7, 2)
    chevronRight:SetPoint("CENTER", chevronZone, "CENTER", 2, -1)
    chevronRight:SetRotation(math.rad(45))

    dropdown.chevronLeft = chevronLeft
    dropdown.chevronRight = chevronRight
    dropdown.chevronZone = chevronZone
    dropdown.separator = separator


    dropdown.selected = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(dropdown.selected, 11, "", C.text)
    dropdown.selected:SetPoint("LEFT", 8, 0)
    dropdown.selected:SetPoint("RIGHT", chevronZone, "LEFT", -5, 0)
    dropdown.selected:SetJustifyH("LEFT")


    dropdown:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA_HOVER)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    dropdown:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropBorderColor, self, 0.35, 0.35, 0.35, 1)
        chevronZone:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], CHEVRON_BG_ALPHA)
        separator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)
        chevronLeft:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
        chevronRight:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], CHEVRON_TEXT_ALPHA)
    end)


    local menuFrame = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
    menuFrame:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menuFrame:SetPoint("TOPRIGHT", dropdown, "BOTTOMRIGHT", 0, -2)
    menuFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menuFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
    menuFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    menuFrame:SetFrameStrata("TOOLTIP")
    menuFrame:SetClipsChildren(true)
    menuFrame:Hide()


    local scrollFrame = CreateFrame("ScrollFrame", nil, menuFrame)
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    scrollFrame:EnableMouseWheel(true)


    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetWidth(menuFrame:GetWidth() or 200)
    scrollFrame:SetScrollChild(scrollContent)
    menuFrame.scrollContent = scrollContent


    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local currentScroll = self:GetVerticalScroll()
        local maxScroll = math.max(0, scrollContent:GetHeight() - menuFrame:GetHeight())
        local newScroll = currentScroll - (delta * 20)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)


    menuFrame:SetScript("OnShow", function(self)
        scrollContent:SetWidth(self:GetWidth() - 2)
    end)

    container.dropdown = dropdown
    container.menuFrame = menuFrame
    container.options = options or {}

    local function GetValue()
        if dbTable and dbKey then return dbTable[dbKey] end
        return container.selectedValue
    end

    local function UpdateVisual(val)
        for _, opt in ipairs(container.options) do
            if opt.value == val then
                dropdown.selected:SetText(opt.text)
                break
            end
        end
    end

    local function SetValue(val, skipOnChange)
        container.selectedValue = val
        if dbTable and dbKey then dbTable[dbKey] = val end
        UpdateVisual(val)
        BroadcastToSiblings(container, val)
        if not skipOnChange and onChange then onChange(val) end
    end

    local function BuildMenu()

        local scrollContent = menuFrame.scrollContent
        if scrollContent then
            for _, child in ipairs({scrollContent:GetChildren()}) do child:Hide() end
        end

        local yOff = -4
        local itemHeight = 20
        local maxVisibleItems = 8
        local numItems = #container.options

        for i, opt in ipairs(container.options) do
            local btn = CreateFrame("Button", nil, scrollContent or menuFrame)
            btn:SetHeight(itemHeight)
            btn:SetPoint("TOPLEFT", 4, yOff)
            btn:SetPoint("TOPRIGHT", -4, yOff)
            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            SetFont(btnText, 11, "", C.text)
            btnText:SetText(opt.text)
            btnText:SetPoint("LEFT", 4, 0)
            btn:SetScript("OnClick", function()
                SetValue(opt.value)
                menuFrame:Hide()
            end)
            btn:SetScript("OnEnter", function() btnText:SetTextColor(unpack(C.accent)) end)
            btn:SetScript("OnLeave", function() btnText:SetTextColor(unpack(C.text)) end)
            yOff = yOff - itemHeight
        end

        local totalHeight = math.abs(yOff) + 4
        local maxHeight = (maxVisibleItems * itemHeight) + 8


        if scrollContent then
            scrollContent:SetHeight(totalHeight)
        end


        menuFrame:SetHeight(math.min(totalHeight, maxHeight))
    end

    dropdown:SetScript("OnClick", function()
        if menuFrame:IsShown() then
            menuFrame:Hide()
        else
            BuildMenu()
            menuFrame:Show()
        end
    end)

    local function SetOptions(newOptions)
        container.options = newOptions or {}

        local currentVal = GetValue()
        local found = false
        for _, opt in ipairs(container.options) do
            if opt.value == currentVal then
                dropdown.selected:SetText(opt.text)
                found = true
                break
            end
        end
        if not found then
            dropdown.selected:SetText("")
            container.selectedValue = nil
            if dbTable and dbKey then dbTable[dbKey] = "" end
        end
    end

    container.GetValue = GetValue
    container.SetValue = SetValue
    container.SetOptions = SetOptions
    container.UpdateVisual = UpdateVisual


    RegisterWidgetInstance(container, dbTable, dbKey)

    SetValue(GetValue(), true)


    container.SetEnabled = function(self, enabled)
        dropdown:EnableMouse(enabled)
        container.isEnabled = enabled
        container:SetAlpha(enabled and 1 or 0.4)
    end
    container.isEnabled = true


    if GUI._searchContext.tabIndex and label and not GUI._suppressSearchRegistration then
        local regKey = label .. "_" .. (GUI._searchContext.tabIndex or 0) .. "_" .. (GUI._searchContext.subTabIndex or 0)
        if not GUI.SettingsRegistryKeys[regKey] then
            GUI.SettingsRegistryKeys[regKey] = true
            table.insert(GUI.SettingsRegistry, {
                label = label,
                widgetType = "dropdown",
                tabIndex = GUI._searchContext.tabIndex,
                tabName = GUI._searchContext.tabName,
                subTabIndex = GUI._searchContext.subTabIndex,
                subTabName = GUI._searchContext.subTabName,
                sectionName = GUI._searchContext.sectionName,
                widgetBuilder = function(p)
                    return GUI:CreateFormDropdown(p, label, options, dbKey, dbTable, onChange)
                end,
            })
        end
    end

    return container
end

function GUI:CreateFormColorPicker(parent, label, dbKey, dbTable, onChange, options)
    options = options or {}
    local noAlpha = options.noAlpha or false

    if parent._hasContent ~= nil then parent._hasContent = true end
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(FORM_ROW_HEIGHT)


    local text = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(text, 12, "", C.text)
    text:SetText(label or "Color")
    text:SetPoint("LEFT", 0, 0)


    local swatch = CreateFrame("Button", nil, container, "BackdropTemplate")
    swatch:SetSize(50, 18)
    swatch:SetPoint("LEFT", container, "LEFT", 180, 0)
    swatch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    swatch:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    container.swatch = swatch
    container.label = text

    local function GetColor()
        if dbTable and dbKey then
            local c = dbTable[dbKey]
            if c then return c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1 end
        end
        return 1, 1, 1, 1
    end

    local function SetColor(r, g, b, a)
        local finalAlpha = noAlpha and 1 or (a or 1)
        swatch:SetBackdropColor(r, g, b, finalAlpha)
        if dbTable and dbKey then
            dbTable[dbKey] = {r, g, b, finalAlpha}
        end
        if onChange then onChange(r, g, b, finalAlpha) end
    end

    container.GetColor = GetColor
    container.SetColor = SetColor

    local r, g, b, a = GetColor()
    swatch:SetBackdropColor(r, g, b, a)

    swatch:SetScript("OnClick", function()
        local currentR, currentG, currentB, currentA = GetColor()
        local originalA = currentA
        ColorPickerFrame:SetupColorPickerAndShow({
            r = currentR, g = currentG, b = currentB, opacity = currentA,
            hasOpacity = not noAlpha,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = noAlpha and 1 or ColorPickerFrame:GetColorAlpha()
                SetColor(r, g, b, a)
            end,
            cancelFunc = function(prev)
                SetColor(prev.r, prev.g, prev.b, noAlpha and 1 or originalA)
            end,
        })
    end)

    swatch:SetScript("OnEnter", function(self) pcall(self.SetBackdropBorderColor, self, unpack(C.accent)) end)
    swatch:SetScript("OnLeave", function(self) pcall(self.SetBackdropBorderColor, self, 0.4, 0.4, 0.4, 1) end)


    container.SetEnabled = function(self, enabled)
        swatch:EnableMouse(enabled)
        container:SetAlpha(enabled and 1 or 0.4)
    end


    if GUI._searchContext.tabIndex and label and not GUI._suppressSearchRegistration then
        local regKey = label .. "_" .. (GUI._searchContext.tabIndex or 0) .. "_" .. (GUI._searchContext.subTabIndex or 0)
        if not GUI.SettingsRegistryKeys[regKey] then
            GUI.SettingsRegistryKeys[regKey] = true
            table.insert(GUI.SettingsRegistry, {
                label = label,
                widgetType = "colorpicker",
                tabIndex = GUI._searchContext.tabIndex,
                tabName = GUI._searchContext.tabName,
                subTabIndex = GUI._searchContext.subTabIndex,
                subTabName = GUI._searchContext.subTabName,
                sectionName = GUI._searchContext.sectionName,
                widgetBuilder = function(p)
                    return GUI:CreateFormColorPicker(p, label, dbKey, dbTable, onChange, options)
                end,
            })
        end
    end

    return container
end


local SEARCH_DEBOUNCE = 0.15
local SEARCH_MIN_CHARS = 2
local SEARCH_MAX_RESULTS = 30


GUI._searchTimer = nil


function GUI:CreateSearchBox(parent)
    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(160, 20)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0.08, 0.10, 0.14, 1)
    container:SetBackdropBorderColor(0.25, 0.28, 0.32, 1)


    local icon = container:CreateFontString(nil, "OVERLAY")
    SetFont(icon, 11, "", C.textMuted)
    icon:SetText("|TInterface\\Common\\UI-Searchbox-Icon:12:12:0:0|t")
    icon:SetPoint("LEFT", 6, 0)


    local editBox = CreateFrame("EditBox", nil, container)
    editBox:SetPoint("LEFT", 24, 0)
    editBox:SetPoint("RIGHT", container, "RIGHT", -24, 0)
    editBox:SetHeight(16)
    editBox:SetAutoFocus(false)
    editBox:SetFont(GetFontPath(), 11, "")
    editBox:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    editBox:SetMaxLetters(50)


    local placeholder = editBox:CreateFontString(nil, "OVERLAY")
    SetFont(placeholder, 11, "", {C.textMuted[1], C.textMuted[2], C.textMuted[3], 0.6})
    placeholder:SetText("Search settings...")
    placeholder:SetPoint("LEFT", 0, 0)


    local clearBtn = CreateFrame("Button", nil, container)
    clearBtn:SetSize(14, 14)
    clearBtn:SetPoint("RIGHT", -4, 0)
    clearBtn:Hide()

    local clearText = clearBtn:CreateFontString(nil, "OVERLAY")
    SetFont(clearText, 12, "", C.textMuted)
    clearText:SetText("x")
    clearText:SetPoint("CENTER", 0, 0)

    clearBtn:SetScript("OnEnter", function()
        clearText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)
    end)
    clearBtn:SetScript("OnLeave", function()
        clearText:SetTextColor(C.textMuted[1], C.textMuted[2], C.textMuted[3], 1)
    end)
    clearBtn:SetScript("OnClick", function()
        editBox:SetText("")
        editBox:ClearFocus()

    end)


    editBox:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end

        local text = self:GetText()


        placeholder:SetShown(text == "")
        clearBtn:SetShown(text ~= "")


        if GUI._searchTimer then
            GUI._searchTimer:Cancel()
            GUI._searchTimer = nil
        end


        if text:len() >= SEARCH_MIN_CHARS then
            GUI._searchTimer = C_Timer.NewTimer(SEARCH_DEBOUNCE, function()
                if container.onSearch then
                    container.onSearch(text)
                end
            end)
        elseif text == "" then
            if container.onClear then
                container.onClear()
            end
        end
    end)


    editBox:SetScript("OnEditFocusGained", function()
        container:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    editBox:SetScript("OnEditFocusLost", function()
        container:SetBackdropBorderColor(0.25, 0.28, 0.32, 1)
    end)


    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        if container.onClear then
            container.onClear()
        end
    end)


    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    container.editBox = editBox
    container.placeholder = placeholder
    container.clearBtn = clearBtn

    return container
end


function GUI:ExecuteSearch(searchTerm)
    if not searchTerm or searchTerm:len() < SEARCH_MIN_CHARS then
        return {}
    end

    local results = {}
    local lowerSearch = searchTerm:lower()

    for _, entry in ipairs(self.SettingsRegistry) do
        local score = 0


        local lowerLabel = (entry.label or ""):lower()
        if lowerLabel:find(lowerSearch, 1, true) then
            score = 100

            if lowerLabel:sub(1, lowerSearch:len()) == lowerSearch then
                score = score + 50
            end
        end


        if score == 0 and entry.keywords then
            for _, keyword in ipairs(entry.keywords) do
                if keyword:lower():find(lowerSearch, 1, true) then
                    score = 50
                    break
                end
            end
        end


        if score > 0 then
            table.insert(results, {data = entry, score = score})
        end
    end


    table.sort(results, function(a, b)
        if a.score ~= b.score then
            return a.score > b.score
        end
        return (a.data.label or "") < (b.data.label or "")
    end)


    if #results > SEARCH_MAX_RESULTS then
        for i = SEARCH_MAX_RESULTS + 1, #results do
            results[i] = nil
        end
    end

    return results
end


function GUI:RenderSearchResults(content, results, searchTerm)
    if not content then return end


    for _, child in ipairs({content:GetChildren()}) do
        UnregisterWidgetInstance(child)
        child:Hide()
        child:SetParent(nil)
    end


    if content._fontStrings then
        for _, fs in ipairs(content._fontStrings) do
            fs:Hide()
            fs:SetText("")
        end
    end
    content._fontStrings = {}


    if content._textures then
        for _, tex in ipairs(content._textures) do
            tex:Hide()
        end
    end
    content._textures = {}

    local y = -10
    local PADDING = 15
    local FORM_ROW = 32


    if not results or #results == 0 then
        if searchTerm and searchTerm ~= "" then
            local noResults = content:CreateFontString(nil, "OVERLAY")
            SetFont(noResults, 12, "", C.textMuted)
            noResults:SetText("No settings found for \"" .. searchTerm .. "\"")
            noResults:SetPoint("TOPLEFT", PADDING, y)
            table.insert(content._fontStrings, noResults)
            y = y - 30

            local tip = content:CreateFontString(nil, "OVERLAY")
            SetFont(tip, 10, "", {C.textMuted[1], C.textMuted[2], C.textMuted[3], 0.7})
            tip:SetText("Try different keywords, or visit other tabs first to index their settings")
            tip:SetPoint("TOPLEFT", PADDING, y)
            table.insert(content._fontStrings, tip)
            y = y - 30
        else

            local instructions = content:CreateFontString(nil, "OVERLAY")
            SetFont(instructions, 12, "", C.textMuted)
            instructions:SetText("Type at least 2 characters to search settings")
            instructions:SetPoint("TOPLEFT", PADDING, y)
            table.insert(content._fontStrings, instructions)
            y = y - 30

            local tip2 = content:CreateFontString(nil, "OVERLAY")
            SetFont(tip2, 10, "", {C.textMuted[1], C.textMuted[2], C.textMuted[3], 0.7})
            tip2:SetText("Settings are indexed when you visit each tab")
            tip2:SetPoint("TOPLEFT", PADDING, y)
            table.insert(content._fontStrings, tip2)
            y = y - 20
        end

        content:SetHeight(math.abs(y) + 20)
        return
    end


    local groupedResults = {}
    local tabOrder = {}

    for _, result in ipairs(results) do
        local tabName = result.data.tabName or "Other"
        if not groupedResults[tabName] then
            groupedResults[tabName] = {}
            table.insert(tabOrder, tabName)
        end
        table.insert(groupedResults[tabName], result)
    end


    GUI._suppressSearchRegistration = true


    for _, tabName in ipairs(tabOrder) do
        local group = groupedResults[tabName]


        local header = content:CreateFontString(nil, "OVERLAY")
        SetFont(header, 12, "", C.accentLight)
        header:SetText(tabName)
        header:SetPoint("TOPLEFT", PADDING, y)
        table.insert(content._fontStrings, header)
        y = y - 24


        local sep = content:CreateTexture(nil, "ARTWORK")
        sep:SetPoint("TOPLEFT", PADDING, y + 2)
        sep:SetSize(content:GetWidth() - (PADDING * 2), 1)
        sep:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.3)
        table.insert(content._textures, sep)
        y = y - 12


        for _, result in ipairs(group) do
            local entry = result.data

            if entry.widgetBuilder then
                local widget = entry.widgetBuilder(content)
                if widget then
                    widget:SetPoint("TOPLEFT", PADDING, y)
                    widget:SetPoint("RIGHT", content, "RIGHT", -PADDING, 0)
                    y = y - FORM_ROW
                end
            else

                local fallbackLabel = content:CreateFontString(nil, "OVERLAY")
                SetFont(fallbackLabel, 11, "", C.textMuted)
                fallbackLabel:SetText(entry.label or "Unknown setting")
                fallbackLabel:SetPoint("TOPLEFT", PADDING, y)
                table.insert(content._fontStrings, fallbackLabel)
                y = y - 24
            end
        end

        y = y - 10
    end


    GUI._suppressSearchRegistration = false

    content:SetHeight(math.abs(y) + 20)
end


function GUI:ClearSearchInTab(content)
    self:RenderSearchResults(content, nil, nil)
end


function GUI:CreateMainFrame()
    if self.MainFrame then
        return self.MainFrame
    end

    local FRAME_WIDTH = GUI.PANEL_WIDTH
    local FRAME_HEIGHT = 850
    local HEADER_HEIGHT = 54
    local SIDEBAR_WIDTH = 235
    local NAV_BUTTON_HEIGHT = 26
    local NAV_SPACING = 5
    local ACTION_BUTTON_HEIGHT = 25

    local savedWidth = PREY.PREYCore and PREY.PREYCore.db and PREY.PREYCore.db.profile.configPanelWidth or FRAME_WIDTH
    local frame = CreateFrame("Frame", "PreyUI_Options", UIParent, "BackdropTemplate")
    frame:SetSize(savedWidth, FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    CreateBackdrop(frame, C.bg, C.border)


    local savedAlpha = PREY.PREYCore and PREY.PREYCore.db and PREY.PREYCore.db.profile.configPanelAlpha or 0.97
    frame:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], savedAlpha)

    self.MainFrame = frame


    frame:SetScript("OnSizeChanged", function(self, width, height)
        if GUI.RelayoutTabs then
            GUI:RelayoutTabs(self)
        end
    end)


    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetHeight(HEADER_HEIGHT)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    local headerBg = titleBar:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.07, 0.065, 0.08, 0.95)

    local headerAccent = titleBar:CreateTexture(nil, "ARTWORK")
    headerAccent:SetPoint("LEFT", 0, 0)
    headerAccent:SetPoint("TOP", 0, 0)
    headerAccent:SetPoint("BOTTOM", 0, 0)
    headerAccent:SetWidth(3)
    headerAccent:SetColorTexture(unpack(C.accent))

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(title, 15, "OUTLINE", C.accentLight)
    title:SetText("PreyUI Control Deck")
    title:SetPoint("TOPLEFT", 14, -10)

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(subtitle, 10, "", C.textMuted)
    subtitle:SetText("Navigation and profile management")
    subtitle:SetPoint("TOPLEFT", 14, -29)

    local addonVersion = "Unknown"
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        addonVersion = C_AddOns.GetAddOnMetadata("PreyUI", "Version") or addonVersion
    elseif GetAddOnMetadata then
        addonVersion = GetAddOnMetadata("PreyUI", "Version") or addonVersion
    end

    local version = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(version, 10, "", C.textMuted)
    version:SetText("v" .. tostring(addonVersion))
    version:SetPoint("TOPRIGHT", -28, -10)


    local scaleContainer = CreateFrame("Frame", nil, frame)
    scaleContainer:SetSize(180, 20)
    scaleContainer:SetPoint("TOPRIGHT", -68, -31)

    local scaleLabel = scaleContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(scaleLabel, 10, "", C.textMuted)
    scaleLabel:SetText("Scale")
    scaleLabel:SetPoint("LEFT", scaleContainer, "LEFT", 0, 0)

    local scaleEditBox = CreateFrame("EditBox", nil, scaleContainer, "BackdropTemplate")
    scaleEditBox:SetSize(38, 16)
    scaleEditBox:SetPoint("LEFT", scaleLabel, "RIGHT", 5, 0)
    scaleEditBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    scaleEditBox:SetBackdropColor(0.08, 0.08, 0.08, 1)
    scaleEditBox:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    scaleEditBox:SetFont(GetFontPath(), 10, "")
    scaleEditBox:SetTextColor(unpack(C.text))
    scaleEditBox:SetJustifyH("CENTER")
    scaleEditBox:SetAutoFocus(false)
    scaleEditBox:SetMaxLetters(4)

    local scaleSlider = CreateFrame("Slider", nil, scaleContainer, "BackdropTemplate")
    scaleSlider:SetSize(84, 12)
    scaleSlider:SetPoint("LEFT", scaleEditBox, "RIGHT", 5, 0)
    scaleSlider:SetOrientation("HORIZONTAL")
    scaleSlider:SetMinMaxValues(0.8, 1.5)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:EnableMouse(true)
    scaleSlider:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
    scaleSlider:SetBackdropColor(0.22, 0.22, 0.22, 0.9)
    local thumb = scaleSlider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(8, 14)
    thumb:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    scaleSlider:SetThumbTexture(thumb)

    local function ApplyScale(value)
        value = math.max(0.8, math.min(1.5, value))
        value = math.floor(value * 20 + 0.5) / 20
        frame:SetScale(value)
        if PREY.PREYCore and PREY.PREYCore.db then
            PREY.PREYCore.db.profile.configPanelScale = value
        end
        return value
    end

    local savedScale = PREY.PREYCore and PREY.PREYCore.db and PREY.PREYCore.db.profile.configPanelScale or 1.0
    scaleSlider:SetValue(savedScale)
    scaleEditBox:SetText(string.format("%.2f", savedScale))
    frame:SetScale(savedScale)

    local isDragging = false

    scaleSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 20 + 0.5) / 20
        scaleEditBox:SetText(string.format("%.2f", value))
        if not isDragging then
            ApplyScale(value)
        end
    end)

    scaleSlider:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDragging = true
        end
    end)

    scaleSlider:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and isDragging then
            isDragging = false
            local value = self:GetValue()
            ApplyScale(value)
        end
    end)

    scaleEditBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText())
        if val then
            val = ApplyScale(val)
            scaleSlider:SetValue(val)
            self:SetText(string.format("%.2f", val))
        end
        self:ClearFocus()
    end)

    scaleEditBox:SetScript("OnEscapePressed", function(self)
        self:SetText(string.format("%.2f", scaleSlider:GetValue()))
        self:ClearFocus()
    end)

    scaleEditBox:SetScript("OnEditFocusGained", function(self)
        pcall(self.SetBackdropBorderColor, self, unpack(C.accent))
    end)

    scaleEditBox:SetScript("OnEditFocusLost", function(self)
        pcall(self.SetBackdropBorderColor, self, 0.25, 0.25, 0.25, 1)

        local val = tonumber(self:GetText())
        if not val then
            self:SetText(string.format("%.2f", scaleSlider:GetValue()))
        end
    end)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)
    close:SetScript("OnClick", function() frame:Hide() end)

    local titleSep = frame:CreateTexture(nil, "ARTWORK")
    titleSep:SetPoint("TOPLEFT", 0, -HEADER_HEIGHT)
    titleSep:SetPoint("TOPRIGHT", 0, -HEADER_HEIGHT)
    titleSep:SetHeight(1)
    titleSep:SetColorTexture(unpack(C.border))


    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", 10, -(HEADER_HEIGHT + 8))
    sidebar:SetPoint("BOTTOMLEFT", 10, 10)
    sidebar:SetWidth(SIDEBAR_WIDTH)
    CreateBackdrop(sidebar, C.navBg, C.border)
    frame.sidebar = sidebar

    local navTitle = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(navTitle, 11, "OUTLINE", C.sectionHeader)
    navTitle:SetText("CONFIGURATION")
    navTitle:SetPoint("TOPLEFT", 10, -9)

    local navDivider = sidebar:CreateTexture(nil, "ARTWORK")
    navDivider:SetPoint("TOPLEFT", 8, -25)
    navDivider:SetPoint("TOPRIGHT", -8, -25)
    navDivider:SetHeight(1)
    navDivider:SetColorTexture(unpack(C.border))

    local actionContainer = CreateFrame("Frame", nil, sidebar)
    actionContainer:SetPoint("BOTTOMLEFT", 0, 0)
    actionContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    actionContainer:SetHeight(76)
    frame.actionContainer = actionContainer

    local navScroll = CreateFrame("ScrollFrame", nil, sidebar, "UIPanelScrollFrameTemplate")
    navScroll:SetPoint("TOPLEFT", 6, -30)
    navScroll:SetPoint("BOTTOMRIGHT", -26, 78)
    local navContent = CreateFrame("Frame", nil, navScroll)
    navContent:SetWidth(SIDEBAR_WIDTH - 34)
    navContent:SetHeight(1)
    navScroll:SetScrollChild(navContent)
    frame.navContainer = navContent
    frame.navScroll = navScroll

    navScroll:SetScript("OnSizeChanged", function(self, width)
        navContent:SetWidth(width)
        if GUI.RelayoutTabs then
            GUI:RelayoutTabs(frame)
        end
    end)

    local navScrollbar = navScroll.ScrollBar
    if navScrollbar then
        navScrollbar:SetPoint("TOPLEFT", navScroll, "TOPRIGHT", 4, -14)
        navScrollbar:SetPoint("BOTTOMLEFT", navScroll, "BOTTOMRIGHT", 4, 14)
        local thumbTex = navScrollbar:GetThumbTexture()
        if thumbTex then
            thumbTex:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.7)
        end
        local navUp = navScrollbar.ScrollUpButton or navScrollbar.Back
        local navDown = navScrollbar.ScrollDownButton or navScrollbar.Forward
        if navUp then navUp:Hide(); navUp:SetAlpha(0) end
        if navDown then navDown:Hide(); navDown:SetAlpha(0) end
    end


    local contentArea = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    contentArea:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0)
    contentArea:SetPoint("BOTTOMRIGHT", -10, 10)
    contentArea:EnableMouse(false)
    CreateBackdrop(contentArea, C.bgContent, C.border)

    local contentBg = contentArea:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints()
    contentBg:SetColorTexture(0.08, 0.075, 0.10, 0.42)

    local topLine = contentArea:CreateTexture(nil, "ARTWORK")
    topLine:SetPoint("TOPLEFT", contentArea, "TOPLEFT", 0, 0)
    topLine:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", 0, 0)
    topLine:SetHeight(1)
    topLine:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.75)

    frame.contentArea = contentArea


    frame.tabs = {}
    frame.pages = {}
    frame.activeTab = nil
    frame.NAV_BUTTON_HEIGHT = NAV_BUTTON_HEIGHT
    frame.NAV_SPACING = NAV_SPACING
    frame.ACTION_BUTTON_HEIGHT = ACTION_BUTTON_HEIGHT
    frame.SIDEBAR_WIDTH = SIDEBAR_WIDTH


    local MIN_HEIGHT = 400
    local MAX_HEIGHT = 1200
    local MIN_WIDTH = 600
    local MAX_WIDTH = 1000

    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(20, 20)
    resizeHandle:SetPoint("BOTTOMRIGHT", -4, 4)
    resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 10)


    local gripTexture = resizeHandle:CreateTexture(nil, "OVERLAY")
    gripTexture:SetAllPoints()
    gripTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    gripTexture:SetVertexColor(0.5, 0.65, 0.9, 0.8)


    local gripHighlight = resizeHandle:CreateTexture(nil, "HIGHLIGHT")
    gripHighlight:SetAllPoints()
    gripHighlight:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    gripHighlight:SetVertexColor(0.820, 0.180, 0.220, 1)


    local gripPushed = resizeHandle:CreateTexture(nil, "ARTWORK")
    gripPushed:SetAllPoints()
    gripPushed:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    gripPushed:SetVertexColor(0.820, 0.180, 0.220, 1)
    gripPushed:Hide()

    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            gripPushed:Show()
            gripTexture:Hide()


            local left = frame:GetLeft()
            local top = frame:GetTop()
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)


            local cursorX, cursorY = GetCursorPosition()
            local scale = frame:GetEffectiveScale()
            self.startX = cursorX / scale
            self.startY = cursorY / scale
            self.startWidth = frame:GetWidth()
            self.startHeight = frame:GetHeight()
            self.isResizing = true


            self._resizeElapsed = 0
            self:SetScript("OnUpdate", function(self, elapsed)
                if not self.isResizing then return end
                self._resizeElapsed = (self._resizeElapsed or 0) + elapsed
                if self._resizeElapsed < 0.016 then return end
                self._resizeElapsed = 0

                local cursorX, cursorY = GetCursorPosition()
                local scale = frame:GetEffectiveScale()
                local currentX = cursorX / scale
                local currentY = cursorY / scale


                local deltaX = currentX - self.startX
                local deltaY = self.startY - currentY


                local newWidth = math.max(MIN_WIDTH, math.min(MAX_WIDTH, self.startWidth + deltaX))
                local newHeight = math.max(MIN_HEIGHT, math.min(MAX_HEIGHT, self.startHeight + deltaY))

                frame:SetSize(newWidth, newHeight)
            end)
        end
    end)

    resizeHandle:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            gripPushed:Hide()
            gripTexture:Show()
            self.isResizing = false
            self:SetScript("OnUpdate", nil)


            if PREY.PREYCore and PREY.PREYCore.db then
                PREY.PREYCore.db.profile.configPanelWidth = frame:GetWidth()
            end
        end
    end)


    resizeHandle:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("Drag to resize", 1, 1, 1)
        GameTooltip:Show()
    end)

    resizeHandle:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    frame.resizeHandle = resizeHandle


    function GUI:RelayoutTabs(targetFrame)
        if not targetFrame.tabs or #targetFrame.tabs == 0 then return end
        if not targetFrame.navContainer or not targetFrame.sidebar or not targetFrame.actionContainer then return end

        local navY = 0
        local actionY = -8
        local navButtonWidth = math.max(120, math.floor(targetFrame.navContainer:GetWidth()) - 2)
        local actionButtonWidth = targetFrame.sidebar:GetWidth() - 16

        for _, tab in ipairs(targetFrame.tabs) do
            if tab.isActionButton then
                tab:SetWidth(actionButtonWidth)
                tab:ClearAllPoints()
                tab:SetPoint("TOPLEFT", targetFrame.actionContainer, "TOPLEFT", 8, actionY)
                actionY = actionY - (targetFrame.ACTION_BUTTON_HEIGHT + 6)
            else
                tab:SetWidth(navButtonWidth)
                tab:ClearAllPoints()
                tab:SetPoint("TOPLEFT", targetFrame.navContainer, "TOPLEFT", 0, -navY)
                navY = navY + targetFrame.NAV_BUTTON_HEIGHT + targetFrame.NAV_SPACING
            end
        end

        targetFrame.navContainer:SetHeight(math.max(1, navY))
    end

    return frame
end


function GUI:AddTab(frame, name, pageCreateFunc)
    local index = #frame.tabs + 1

    local tab = CreateFrame("Button", nil, frame.navContainer, "BackdropTemplate")
    tab:SetSize(math.max(120, math.floor(frame.navContainer:GetWidth()) - 2), frame.NAV_BUTTON_HEIGHT)
    tab:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    tab:SetBackdropColor(unpack(C.navItemBg))
    tab:SetBackdropBorderColor(unpack(C.border))
    tab.index = index
    tab.name = name

    tab.accentBar = tab:CreateTexture(nil, "ARTWORK")
    tab.accentBar:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
    tab.accentBar:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
    tab.accentBar:SetWidth(2)
    tab.accentBar:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0)

    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(tab.text, 11, "", C.tabNormal)
    tab.text:SetText(name)
    tab.text:SetPoint("LEFT", tab, "LEFT", 9, 0)
    tab.text:SetPoint("RIGHT", tab, "RIGHT", -6, 0)
    tab.text:SetJustifyH("LEFT")

    frame.tabs[index] = tab
    frame.pages[index] = {
        createFunc = pageCreateFunc,
        frame = nil
    }

    tab:SetScript("OnClick", function()
        GUI:SelectTab(frame, index)
    end)

    tab:SetScript("OnEnter", function(self)
        if frame.activeTab ~= self.index then
            self.text:SetTextColor(unpack(C.tabHover))
            pcall(self.SetBackdropColor, self, C.bgLight[1], C.bgLight[2], C.bgLight[3], 1)
            pcall(self.SetBackdropBorderColor, self, unpack(C.borderLight))
        end
    end)

    tab:SetScript("OnLeave", function(self)
        if frame.activeTab ~= self.index then
            pcall(self.SetBackdropColor, self, unpack(C.navItemBg))
            self.text:SetTextColor(unpack(C.tabNormal))
            pcall(self.SetBackdropBorderColor, self, unpack(C.border))
        end
    end)

    GUI:RelayoutTabs(frame)

    if index == 1 then
        GUI:SelectTab(frame, 1)
    end

    return tab
end


function GUI:AddActionButton(frame, name, onClick, accentColor)
    local index = #frame.tabs + 1

    local btn = CreateFrame("Button", nil, frame.actionContainer, "BackdropTemplate")
    btn:SetSize(frame.sidebar:GetWidth() - 16, frame.ACTION_BUTTON_HEIGHT)

    local bgColor = {unpack(C.navActionBg)}
    local borderColor = accentColor or C.sectionHeader

    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(unpack(bgColor))
    btn:SetBackdropBorderColor(unpack(borderColor))
    btn.index = index
    btn.name = name
    btn.isActionButton = true
    btn.bgColor = bgColor
    btn.borderColor = borderColor

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    SetFont(btn.text, 11, "OUTLINE", borderColor)
    btn.text:SetText(name)
    btn.text:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btn.text:SetJustifyH("CENTER")

    frame.tabs[index] = btn
    frame.pages[index] = nil

    btn:SetScript("OnClick", function()
        if onClick then
            onClick()
        end
    end)

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.11, 0.16, 0.18, 1)
        self:SetBackdropBorderColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 1)
        self.text:SetTextColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 1)
    end)

    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(self.bgColor))
        self:SetBackdropBorderColor(unpack(self.borderColor))
        self.text:SetTextColor(unpack(self.borderColor))
    end)

    GUI:RelayoutTabs(frame)

    return btn
end


function GUI:SelectTab(frame, index)

    local targetTab = frame.tabs[index]
    if targetTab and targetTab.isActionButton then
        return
    end


    if index == self._searchTabIndex and self._allTabsAdded and not self._searchIndexBuilt then
        self:ForceLoadAllTabs()
        self._searchIndexBuilt = true
    end


    if frame._searchActive then
        if frame.searchBox and frame.searchBox.editBox then
            frame.searchBox.editBox:SetText("")
        end
        self:ClearSearchResults()
    end


    if frame.activeTab then
        local prevTab = frame.tabs[frame.activeTab]
        if prevTab and not prevTab.isActionButton then
            prevTab.text:SetTextColor(unpack(C.tabNormal))
            pcall(prevTab.SetBackdropColor, prevTab, unpack(C.navItemBg))
            pcall(prevTab.SetBackdropBorderColor, prevTab, unpack(C.border))
            if prevTab.accentBar then
                prevTab.accentBar:SetAlpha(0)
            end
        end

        if frame.pages[frame.activeTab] and frame.pages[frame.activeTab].frame then
            frame.pages[frame.activeTab].frame:Hide()
        end
    end


    frame.activeTab = index
    local tab = frame.tabs[index]
    if tab and not tab.isActionButton then
        tab.text:SetTextColor(unpack(C.tabSelectedText))
        pcall(tab.SetBackdropColor, tab, unpack(C.navItemActiveBg))
        pcall(tab.SetBackdropBorderColor, tab, unpack(C.accent))
        if tab.accentBar then
            tab.accentBar:SetAlpha(1)
        end
    end


    local page = frame.pages[index]
    if page then
        if not page.frame then
            page.frame = CreateFrame("Frame", nil, frame.contentArea)
            page.frame:SetAllPoints()
            page.frame:EnableMouse(false)
            if page.createFunc then
                page.createFunc(page.frame)
                page.built = true
            end
        end
        page.frame:Show()


        local function TriggerOnShow(frame)
            if frame.GetScript and frame:GetScript("OnShow") then
                frame:GetScript("OnShow")(frame)
            end
            if frame.GetChildren then
                for _, child in ipairs({frame:GetChildren()}) do
                    TriggerOnShow(child)
                end
            end
        end
        TriggerOnShow(page.frame)
    end
end


function GUI:Show()
    if not self.MainFrame then
        self:InitializeOptions()
    end
    self.MainFrame:Show()
end


function GUI:Hide()
    if self.MainFrame then
        self.MainFrame:Hide()
    end
end


function GUI:Toggle()
    if self.MainFrame and self.MainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end


PREY.GUI = GUI
