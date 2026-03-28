-- PreyUI Rebuild Layer
-- Replaces legacy options shell with the rebuilt PreyUI layout.

local PREY = PreyUI
if not PREY or not PREY.GUI then return end

local GUI = PREY.GUI

-- ---------------------------------------------------------------------------
-- Brand + Theme
-- ---------------------------------------------------------------------------
GUI.Brand = {
    product = "PreyUI",
    subtitle = "Version",
    accentLabel = "PREY",
}

local C = GUI.Colors or {}
GUI.Colors = C

C.bg = {0.05, 0.03, 0.04, 0.98}
C.bgLight = {0.10, 0.05, 0.06, 1}
C.bgDark = {0.02, 0.01, 0.02, 1}
C.bgContent = {0.09, 0.04, 0.05, 0.88}

C.accent = {0.840, 0.180, 0.220, 1}
C.accentLight = {1.000, 0.420, 0.450, 1}
C.accentDark = {0.420, 0.080, 0.100, 1}
C.accentHover = {1.000, 0.540, 0.580, 1}

C.tabSelected = {0.840, 0.180, 0.220, 1}
C.tabSelectedText = {1.00, 0.92, 0.93, 1}
C.tabNormal = {0.80, 0.73, 0.75, 1}
C.tabHover = {1.00, 0.97, 0.97, 1}

C.text = {0.96, 0.93, 0.94, 1}
C.textBright = {1, 1, 1, 1}
C.textMuted = {0.700, 0.600, 0.620, 1}

C.border = {0.28, 0.10, 0.12, 1}
C.borderLight = {0.45, 0.18, 0.21, 1}
C.borderAccent = {0.840, 0.180, 0.220, 1}
C.sectionHeader = {0.950, 0.360, 0.400, 1}

C.navBg = {0.05, 0.02, 0.03, 1}
C.navItemBg = {0.10, 0.04, 0.05, 1}
C.navItemActiveBg = {0.16, 0.05, 0.06, 1}
C.navActionBg = {0.11, 0.04, 0.05, 1}

local function CreateBackdrop(frame, bg, border)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(bg or C.bg))
    frame:SetBackdropBorderColor(unpack(border or C.border))
end

local function UseTitleFont(fs, size, color)
    local fontPath = GUI.FONT_PATH or "Fonts\\FRIZQT__.TTF"
    fs:SetFont(fontPath, size or 12, "")
    if color then
        fs:SetTextColor(unpack(color))
    end
end

-- ---------------------------------------------------------------------------
-- New shell frame
-- ---------------------------------------------------------------------------
function GUI:CreateMainFrame()
    if self.MainFrame then
        return self.MainFrame
    end

    local defaultWidth = 1020
    local defaultHeight = 680
    local savedWidth = (PREY.PREYCore and PREY.PREYCore.db and PREY.PREYCore.db.profile and PREY.PREYCore.db.profile.configPanelWidth) or defaultWidth
    local savedHeight = (PREY.PREYCore and PREY.PREYCore.db and PREY.PREYCore.db.profile and PREY.PREYCore.db.profile.configPanelHeight) or defaultHeight

    local frame = CreateFrame("Frame", "PreyUI_CommandDeck", UIParent, "BackdropTemplate")
    frame:SetSize(savedWidth, savedHeight)
    frame:SetPoint("CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(120)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    if frame.SetResizable then
        frame:SetResizable(true)
    end
    if frame.SetResizeBounds then
        frame:SetResizeBounds(760, 480, 1600, 1100)
    end
    CreateBackdrop(frame, C.bg, C.border)
    self.MainFrame = frame

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(72)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() frame:StartMoving() end)
    header:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    CreateBackdrop(header, C.bgDark, C.border)
    frame.header = header

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 16, -12)
    UseTitleFont(title, 18, C.accentLight)
    title:SetText(self.Brand.product)

    local version = PREY.versionString or "dev"
    local subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    UseTitleFont(subtitle, 11, C.textMuted)
    subtitle:SetText(self.Brand.subtitle .. " " .. version)

    local logo = header:CreateTexture(nil, "ARTWORK")
    logo:SetSize(36, 36)
    logo:SetPoint("RIGHT", header, "RIGHT", -28, 0)
    logo:SetTexture("Interface\\AddOns\\PreyUI\\assets\\preyLogo")
    logo:SetTexCoord(0, 1, 0, 1)
    header.logo = logo

    local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -3)
    close:SetScript("OnClick", function() frame:Hide() end)

    local leftRail = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    leftRail:SetPoint("TOPLEFT", 10, -80)
    leftRail:SetPoint("BOTTOMLEFT", 10, 10)
    leftRail:SetWidth(300)
    CreateBackdrop(leftRail, C.navBg, C.border)
    frame.sidebar = leftRail

    local railTitle = leftRail:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    railTitle:SetPoint("TOPLEFT", 12, -10)
    UseTitleFont(railTitle, 11, C.sectionHeader)
    railTitle:SetText("MODULE DIRECTORY")

    local railDivider = leftRail:CreateTexture(nil, "ARTWORK")
    railDivider:SetPoint("TOPLEFT", 10, -26)
    railDivider:SetPoint("TOPRIGHT", -10, -26)
    railDivider:SetHeight(1)
    railDivider:SetColorTexture(unpack(C.border))

    local actionContainer = CreateFrame("Frame", nil, leftRail)
    actionContainer:SetPoint("BOTTOMLEFT", 0, 0)
    actionContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    actionContainer:SetHeight(110)
    frame.actionContainer = actionContainer

    local navScroll = CreateFrame("ScrollFrame", nil, leftRail, "UIPanelScrollFrameTemplate")
    navScroll:SetPoint("TOPLEFT", 8, -30)
    navScroll:SetPoint("BOTTOMRIGHT", -28, 114)
    local navContent = CreateFrame("Frame", nil, navScroll)
    navContent:SetHeight(1)
    navContent:SetWidth(258)
    navScroll:SetScrollChild(navContent)

    local navScrollbar = navScroll.ScrollBar
    if navScrollbar then
        local up = navScrollbar.ScrollUpButton or navScrollbar.Back
        local down = navScrollbar.ScrollDownButton or navScrollbar.Forward
        if up then up:Hide() end
        if down then down:Hide() end
    end

    frame.navContainer = navContent
    frame.navScroll = navScroll

    local contentArea = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    contentArea:SetPoint("TOPLEFT", leftRail, "TOPRIGHT", 10, 0)
    contentArea:SetPoint("BOTTOMRIGHT", -10, 10)
    CreateBackdrop(contentArea, C.bgContent, C.border)
    frame.contentArea = contentArea

    local contentBanner = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    contentBanner:SetPoint("TOPLEFT", 0, 0)
    contentBanner:SetPoint("TOPRIGHT", 0, 0)
    contentBanner:SetHeight(40)
    CreateBackdrop(contentBanner, C.bgLight, C.border)

    local bannerLabel = contentBanner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bannerLabel:SetPoint("LEFT", 12, 0)
    UseTitleFont(bannerLabel, 11, C.text)
    bannerLabel:SetText("Select a module to configure visuals, automation, and gameplay tools.")

    frame.tabs = {}
    frame.pages = {}
    frame.activeTab = nil
    frame.NAV_BUTTON_HEIGHT = 28
    frame.NAV_SPACING = 5
    frame.ACTION_BUTTON_HEIGHT = 27

    frame:SetScript("OnSizeChanged", function(self, width, height)
        if GUI.RelayoutTabs then
            GUI:RelayoutTabs(self)
        end
        if PREY.PREYCore and PREY.PREYCore.db and PREY.PREYCore.db.profile then
            PREY.PREYCore.db.profile.configPanelWidth = math.floor(width + 0.5)
            PREY.PREYCore.db.profile.configPanelHeight = math.floor(height + 0.5)
        end
    end)

    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(20, 20)
    resizeHandle:SetPoint("BOTTOMRIGHT", -4, 4)
    resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 20)

    local grip = resizeHandle:CreateTexture(nil, "OVERLAY")
    grip:SetAllPoints()
    grip:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetVertexColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 0.9)

    local gripPushed = resizeHandle:CreateTexture(nil, "ARTWORK")
    gripPushed:SetAllPoints()
    gripPushed:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    gripPushed:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
    gripPushed:Hide()

    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        grip:Hide()
        gripPushed:Show()

        local left = frame:GetLeft()
        local top = frame:GetTop()
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)

        self.startX, self.startY = GetCursorPosition()
        self.startWidth = frame:GetWidth()
        self.startHeight = frame:GetHeight()
        self.isResizing = true
        self:SetScript("OnUpdate", function(btn)
            if not btn.isResizing then return end
            local cursorX, cursorY = GetCursorPosition()
            local scale = frame:GetEffectiveScale()
            local deltaX = (cursorX - btn.startX) / scale
            local deltaY = (btn.startY - cursorY) / scale
            local newWidth = math.max(760, math.min(1600, btn.startWidth + deltaX))
            local newHeight = math.max(480, math.min(1100, btn.startHeight + deltaY))
            frame:SetSize(newWidth, newHeight)
        end)
    end)

    resizeHandle:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" then return end
        self.isResizing = false
        self:SetScript("OnUpdate", nil)
        gripPushed:Hide()
        grip:Show()
    end)

    resizeHandle:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("Drag to resize", 1, 1, 1)
        GameTooltip:Show()
    end)

    resizeHandle:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.resizeHandle = resizeHandle

    return frame
end

function GUI:RelayoutTabs(frame)
    if not frame or not frame.tabs then return end
    local navY = 0
    local actionY = -8
    local navWidth = math.max(200, math.floor(frame.navContainer:GetWidth()) - 2)
    local actionWidth = frame.sidebar:GetWidth() - 16

    for _, tab in ipairs(frame.tabs) do
        if tab.isActionButton then
            tab:SetWidth(actionWidth)
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", frame.actionContainer, "TOPLEFT", 8, actionY)
            actionY = actionY - (frame.ACTION_BUTTON_HEIGHT + 6)
        else
            tab:SetWidth(navWidth)
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", frame.navContainer, "TOPLEFT", 0, -navY)
            navY = navY + frame.NAV_BUTTON_HEIGHT + frame.NAV_SPACING
        end
    end

    frame.navContainer:SetHeight(math.max(1, navY))
end

function GUI:AddTab(frame, name, pageCreateFunc)
    local index = #frame.tabs + 1
    local tab = CreateFrame("Button", nil, frame.navContainer, "BackdropTemplate")
    tab:SetSize(math.max(200, frame.navContainer:GetWidth() - 2), frame.NAV_BUTTON_HEIGHT)
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
    tab.accentBar:SetPoint("TOPLEFT", 0, 0)
    tab.accentBar:SetPoint("BOTTOMLEFT", 0, 0)
    tab.accentBar:SetWidth(3)
    tab.accentBar:SetColorTexture(unpack(C.accent))
    tab.accentBar:SetAlpha(0)

    tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tab.text:SetPoint("LEFT", 10, 0)
    tab.text:SetPoint("RIGHT", -6, 0)
    tab.text:SetJustifyH("LEFT")
    UseTitleFont(tab.text, 11, C.tabNormal)
    tab.text:SetText(name)

    frame.tabs[index] = tab
    frame.pages[index] = {createFunc = pageCreateFunc, frame = nil}

    tab:SetScript("OnEnter", function(self)
        if frame.activeTab ~= self.index then
            self:SetBackdropColor(unpack(C.bgLight))
            self:SetBackdropBorderColor(unpack(C.borderLight))
            self.text:SetTextColor(unpack(C.tabHover))
        end
    end)
    tab:SetScript("OnLeave", function(self)
        if frame.activeTab ~= self.index then
            self:SetBackdropColor(unpack(C.navItemBg))
            self:SetBackdropBorderColor(unpack(C.border))
            self.text:SetTextColor(unpack(C.tabNormal))
        end
    end)
    tab:SetScript("OnClick", function()
        GUI:SelectTab(frame, index)
    end)

    self:RelayoutTabs(frame)
    if index == 1 then
        self:SelectTab(frame, 1)
    end
    return tab
end

function GUI:AddActionButton(frame, name, onClick, accentColor)
    local index = #frame.tabs + 1
    local btn = CreateFrame("Button", nil, frame.actionContainer, "BackdropTemplate")
    btn:SetSize(frame.sidebar:GetWidth() - 16, frame.ACTION_BUTTON_HEIGHT)
    btn.index = index
    btn.name = name
    btn.isActionButton = true
    btn.bgColor = {unpack(C.navActionBg)}
    btn.borderColor = accentColor or C.accent

    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(unpack(btn.bgColor))
    btn:SetBackdropBorderColor(unpack(btn.borderColor))

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER", 0, 0)
    UseTitleFont(btn.text, 11, btn.borderColor)
    btn.text:SetText(name)

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.10, 0.20, 0.28, 1)
        self:SetBackdropBorderColor(unpack(C.accentLight))
        self.text:SetTextColor(unpack(C.accentLight))
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(self.bgColor))
        self:SetBackdropBorderColor(unpack(self.borderColor))
        self.text:SetTextColor(unpack(self.borderColor))
    end)
    btn:SetScript("OnClick", function()
        if onClick then onClick() end
    end)

    frame.tabs[index] = btn
    frame.pages[index] = nil
    self:RelayoutTabs(frame)
    return btn
end

function GUI:SelectTab(frame, index)
    local selectedTab = frame.tabs[index]
    if selectedTab and selectedTab.isActionButton then
        return
    end

    if index == self._searchTabIndex and self._allTabsAdded and not self._searchIndexBuilt then
        self:ForceLoadAllTabs()
        self._searchIndexBuilt = true
    end

    if frame._searchActive and frame.searchBox and frame.searchBox.editBox then
        frame.searchBox.editBox:SetText("")
        if self.ClearSearchResults then
            self:ClearSearchResults()
        end
    end

    if frame.activeTab then
        local prevTab = frame.tabs[frame.activeTab]
        local prevPage = frame.pages[frame.activeTab]
        if prevTab and not prevTab.isActionButton then
            prevTab:SetBackdropColor(unpack(C.navItemBg))
            prevTab:SetBackdropBorderColor(unpack(C.border))
            prevTab.text:SetTextColor(unpack(C.tabNormal))
            if prevTab.accentBar then
                prevTab.accentBar:SetAlpha(0)
            end
        end
        if prevPage and prevPage.frame then
            prevPage.frame:Hide()
        end
    end

    frame.activeTab = index
    local tab = frame.tabs[index]
    if tab and not tab.isActionButton then
        tab:SetBackdropColor(unpack(C.navItemActiveBg))
        tab:SetBackdropBorderColor(unpack(C.accent))
        tab.text:SetTextColor(unpack(C.tabSelectedText))
        if tab.accentBar then
            tab.accentBar:SetAlpha(1)
        end
    end

    local page = frame.pages[index]
    if not page then return end
    if not page.frame then
        page.frame = CreateFrame("Frame", nil, frame.contentArea)
        page.frame:SetPoint("TOPLEFT", 0, -40)
        page.frame:SetPoint("BOTTOMRIGHT", 0, 0)
        page.frame:EnableMouse(false)
        if page.createFunc then
            page.createFunc(page.frame)
            page.built = true
        end
    end
    page.frame:Show()

    local function TriggerOnShowRecursive(target)
        if target.GetScript and target:GetScript("OnShow") then
            target:GetScript("OnShow")(target)
        end
        for _, child in ipairs({target:GetChildren()}) do
            TriggerOnShowRecursive(child)
        end
    end
    TriggerOnShowRecursive(page.frame)
end
