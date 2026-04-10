local ADDON_NAME, ns = ...

local PREY_Anchoring_Options = {}
ns.PREY_Anchoring_Options = PREY_Anchoring_Options


local function GetGUI()
    local PREY = _G.PreyUI
    if PREY and PREY.GUI then
        return PREY.GUI
    end
    return nil
end


local function GetColors()
    local GUI = GetGUI()
    if GUI and GUI.Colors then
        return GUI.Colors
    end

    return {
        text = {1, 1, 1},
        border = {0.3, 0.3, 0.3},
        accent = {0.82, 0.18, 0.22}
    }
end


function PREY_Anchoring_Options:CreateAnchorDropdown(parent, label, settingsDB, anchorKey, x, y, width, onChange, includeList, excludeList, excludeSelf)
    if not ns.PREY_Anchoring or not ns.PREY_Anchoring.GetAnchorTargetList then
        return nil
    end

    local GUI = GetGUI()
    if not GUI then
        return nil
    end


    local function GetAnchorOptions()
        return ns.PREY_Anchoring:GetAnchorTargetList(includeList, excludeList, excludeSelf)
    end
    local anchorOptions = GetAnchorOptions()


    local dropdown = GUI:CreateFormDropdown(parent, label, anchorOptions, anchorKey, settingsDB, onChange, nil, nil, GetAnchorOptions)

    if x and y then
        dropdown:SetPoint("TOPLEFT", x, y)
    end

    if width then
        dropdown:SetPoint("RIGHT", parent, "RIGHT", -x or 0, 0)
    end

    return dropdown
end


function PREY_Anchoring_Options:CreateSnapButton(parent, text, x, y, width, height, onClick)
    width = width or 100
    height = height or 24

    local C = GetColors()

    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    if x and y then
        button:SetPoint("TOPLEFT", x, y)
    end

    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    button:SetBackdropColor(0.15, 0.15, 0.15, 1)
    button:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)

    local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    buttonText:SetPoint("CENTER")
    buttonText:SetText(text)
    buttonText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    end)

    if onClick then
        button:SetScript("OnClick", onClick)
    end

    return button
end


function PREY_Anchoring_Options:CreateSnapButtonsRow(parent, label, x, y, snapTargets, settingsDB, anchorKey, getFrame, onSnap, onFailure, spacing, buttonWidth, buttonHeight, labelWidth)
    spacing = spacing or 8
    buttonWidth = buttonWidth or 100
    buttonHeight = buttonHeight or 24
    labelWidth = labelWidth or 180

    local C = GetColors()

    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(buttonHeight)
    if x and y then
        container:SetPoint("TOPLEFT", x, y)
    end
    container:SetPoint("RIGHT", parent, "RIGHT", -x or 0, 0)

    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("LEFT", 0, 0)
    labelText:SetText(label)
    labelText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    local buttons = {}

    for i, snapTarget in ipairs(snapTargets) do
        local button = self:CreateSnapButton(
            container,
            snapTarget.text,
            labelWidth + (i - 1) * (buttonWidth + spacing),
            0,
            buttonWidth,
            buttonHeight,
            function()
                if not ns.PREY_Anchoring then
                    if onFailure then
                        onFailure("Anchoring system not available")
                    end
                    return
                end


                local frame = getFrame and getFrame() or nil

                if not frame then
                    if onFailure then
                        onFailure("Frame not found")
                    end
                    return
                end


                local success = ns.PREY_Anchoring:SnapTo(
                    frame,
                    snapTarget.anchorTarget,
                    snapTarget.anchorPoint,
                    snapTarget.offsetX or 0,
                    snapTarget.offsetY or 0,
                    {
                        checkVisible = snapTarget.checkVisible ~= false,
                        setWidth = snapTarget.setWidth,
                        clearWidth = snapTarget.clearWidth,
                        onSuccess = function()

                            settingsDB[anchorKey] = snapTarget.anchorTarget
                            if snapTarget.offsetX ~= nil then
                                settingsDB.offsetX = snapTarget.offsetX
                            end
                            if snapTarget.offsetY ~= nil then
                                settingsDB.offsetY = snapTarget.offsetY
                            end
                            if snapTarget.setWidth then
                                settingsDB.width = snapTarget.width or 0
                            end
                            if snapTarget.clearWidth then
                                settingsDB.width = 0
                            end

                            if onSnap then
                                onSnap(snapTarget.anchorTarget)
                            end
                        end,
                        onFailure = onFailure
                    }
                )
            end
        )

        table.insert(buttons, button)
    end

    return container, buttons
end


function PREY_Anchoring_Options:GetNinePointAnchorOptions()
    return {
        {value = "TOPLEFT", text = "Top Left"},
        {value = "TOP", text = "Top Center"},
        {value = "TOPRIGHT", text = "Top Right"},
        {value = "LEFT", text = "Center Left"},
        {value = "CENTER", text = "Center"},
        {value = "RIGHT", text = "Center Right"},
        {value = "BOTTOMLEFT", text = "Bottom Left"},
        {value = "BOTTOM", text = "Bottom Center"},
        {value = "BOTTOMRIGHT", text = "Bottom Right"},
    }
end


function PREY_Anchoring_Options:CreateAnchorPointSelector(parent, label, settingsDB, key, x, y, onChange, size)
    size = size or 200
    local C = GetColors()


    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(size, size + 30)

    if x and y then
        container:SetPoint("TOPLEFT", x, y)
    end


    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", 0, 0)
    labelText:SetText(label)
    labelText:SetTextColor(C.text[1], C.text[2], C.text[3], 1)


    local gridSize = size
    local cellSize = gridSize / 3
    local grid = CreateFrame("Frame", nil, container, "BackdropTemplate")
    grid:SetSize(gridSize, gridSize)
    grid:SetPoint("TOPLEFT", 0, -25)
    grid:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    grid:SetBackdropColor(0.1, 0.1, 0.1, 1)
    grid:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.5)


    local anchorPoints = {
        {"TOPLEFT", "TOP", "TOPRIGHT"},
        {"LEFT", "CENTER", "RIGHT"},
        {"BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"},
    }


    local cells = {}
    for row = 1, 3 do
        cells[row] = {}
        for col = 1, 3 do
            local cell = CreateFrame("Button", nil, grid, "BackdropTemplate")
            cell:SetSize(cellSize - 2, cellSize - 2)
            cell:SetPoint("TOPLEFT", grid, "TOPLEFT", (col - 1) * cellSize + 1, -(row - 1) * cellSize - 1)

            cell:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            cell:SetBackdropColor(0.15, 0.15, 0.15, 1)
            cell:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.3)


            local indicator = cell:CreateTexture(nil, "OVERLAY")
            indicator:SetSize(cellSize * 0.3, cellSize * 0.3)

            local anchorPoint = anchorPoints[row][col]
            local offsetX, offsetY = 0, 0


            if anchorPoint:find("LEFT") then
                offsetX = cellSize * 0.15
            elseif anchorPoint:find("RIGHT") then
                offsetX = cellSize * 0.55
            else
                offsetX = cellSize * 0.35
            end

            if anchorPoint:find("TOP") then
                offsetY = -cellSize * 0.15
            elseif anchorPoint:find("BOTTOM") then
                offsetY = -cellSize * 0.55
            else
                offsetY = -cellSize * 0.35
            end

            indicator:SetPoint("TOPLEFT", cell, "TOPLEFT", offsetX, offsetY)
            indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.6)


            cell.anchorPoint = anchorPoint
            cell.indicator = indicator


            cell:SetScript("OnEnter", function(self)
                self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
                indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
            end)

            cell:SetScript("OnLeave", function(self)
                local currentValue = settingsDB[key]
                if currentValue == self.anchorPoint then
                    self:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
                    if self.indicator then
                        self.indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.8)
                    end
                else
                    self:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.3)
                    if self.indicator then
                        self.indicator:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.6)
                    end
                end
            end)


            cell.cells = cells
            cell.settingsDB = settingsDB
            cell.key = key
            cell.C = C


            cell.UpdateSelection = function(self)
                local currentValue = self.settingsDB[self.key]
                for r = 1, 3 do
                    for c = 1, 3 do
                        local cellFrame = self.cells[r][c]
                        if cellFrame.anchorPoint == currentValue then
                            cellFrame:SetBackdropBorderColor(self.C.accent[1], self.C.accent[2], self.C.accent[3], 1)
                            cellFrame:SetBackdropColor(0.2, 0.2, 0.2, 1)
                            if cellFrame.indicator then
                                cellFrame.indicator:SetColorTexture(self.C.accent[1], self.C.accent[2], self.C.accent[3], 0.8)
                            end
                        else
                            cellFrame:SetBackdropBorderColor(self.C.border[1], self.C.border[2], self.C.border[3], 0.3)
                            cellFrame:SetBackdropColor(0.15, 0.15, 0.15, 1)
                            if cellFrame.indicator then
                                cellFrame.indicator:SetColorTexture(self.C.accent[1], self.C.accent[2], self.C.accent[3], 0.6)
                            end
                        end
                    end
                end
            end


            cell:SetScript("OnClick", function(self)
                self.settingsDB[self.key] = self.anchorPoint
                self:UpdateSelection()
                if onChange then
                    onChange()
                end
            end)

            cells[row][col] = cell
        end
    end


    if settingsDB[key] and cells[1][1] then
        cells[1][1]:UpdateSelection()
    end


    container.cells = cells
    container.UpdateSelection = function(self)
        if cells[1][1] then
            cells[1][1]:UpdateSelection()
        end
    end

    return container
end


function PREY_Anchoring_Options:CreateMultiAnchorPopover(anchorButton, settingsDB, onChange, anchorsKey, maxAnchors)
    anchorsKey = anchorsKey or "anchors"
    maxAnchors = maxAnchors or 2

    local C = GetColors()
    local GUI = GetGUI()
    if not GUI then return nil end


    if not settingsDB[anchorsKey] then
        settingsDB[anchorsKey] = {
            {source = "BOTTOMLEFT", target = "BOTTOMLEFT"}
        }
    end


    local popover = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")


    popover:SetSize(420, 300)
    popover:SetPoint("TOPLEFT", anchorButton, "BOTTOMLEFT", 0, -5)
    popover:SetFrameStrata("FULLSCREEN_DIALOG")
    popover:SetFrameLevel(500)
    popover:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    popover:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], 0.98)
    popover:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    popover:EnableMouse(true)
    popover:SetClampedToScreen(true)
    popover:Hide()


    local closeBtn = GUI:CreateButton(popover, "×", 24, 24, function()
        popover:Hide()
    end)
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    if closeBtn.text then
        local fontPath = GUI.GetFontPath and GUI:GetFontPath() or "Fonts\\FRIZQT__.TTF"
        closeBtn.text:SetFont(fontPath, 16, "")
    end


    local titleText = popover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOPLEFT", 5, -5)
    titleText:SetText("Advanced Anchor Settings")
    titleText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)


    local content = CreateFrame("Frame", nil, popover)
    content:SetPoint("TOPLEFT", 2, -28)
    content:SetPoint("BOTTOMRIGHT", -2, 2)


    local PAD = 5
    local FORM_ROW = 30
    local anchors = settingsDB[anchorsKey]
    local selectorSize = 75
    local spacing = 8
    local rowHeight = selectorSize + 30
    local currentY = -PAD


    popover.anchors = anchors
    popover.maxAnchors = maxAnchors
    popover.onChange = onChange
    popover.anchorRows = {}


    local function UpdateContentHeight()

    end


    local function RebuildAnchors()

        for i, row in ipairs(popover.anchorRows) do
            if row.frame then
                row.frame:Hide()
                row.frame:SetParent(nil)
            end
        end
        popover.anchorRows = {}
        currentY = -PAD


        for i, anchor in ipairs(anchors) do

            local rowFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
            rowFrame:SetHeight(rowHeight + 8)
            rowFrame:SetPoint("TOPLEFT", PAD, currentY)
            rowFrame:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)


            rowFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
                insets = {left = 2, right = 2, top = 2, bottom = 2}
            })
            rowFrame:SetBackdropColor(C.bg[1] * 1.2, C.bg[2] * 1.2, C.bg[3] * 1.2, 0.5)
            rowFrame:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 0.3)


            local label = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", 5, 0)
            label:SetText("Anchor " .. i)
            label:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)


            local sourceSelector = self:CreateAnchorPointSelector(
                rowFrame,
                "Source",
                anchor,
                "source",
                70,
                0,
                onChange,
                selectorSize
            )


            local targetSelector = self:CreateAnchorPointSelector(
                rowFrame,
                "Target",
                anchor,
                "target",
                70 + selectorSize + spacing,
                0,
                onChange,
                selectorSize
            )


            local removeButton
            if #anchors > 1 then
                removeButton = GUI:CreateButton(rowFrame, "×", 24, 24, function()
                    table.remove(anchors, i)
                    RebuildAnchors()
                    UpdateContentHeight()
                    if onChange then onChange() end
                end)
                removeButton:SetPoint("RIGHT", -5, 0)
                if removeButton.text then
                    local fontPath = GUI.GetFontPath and GUI:GetFontPath() or "Fonts\\FRIZQT__.TTF"
                    removeButton.text:SetFont(fontPath, 14, "")
                    removeButton.text:SetTextColor(0.9, 0.3, 0.3, 1)
                end
            end

            table.insert(popover.anchorRows, {
                frame = rowFrame,
                sourceSelector = sourceSelector,
                targetSelector = targetSelector,
                removeButton = removeButton
            })

            currentY = currentY - (rowHeight + 8) - 3
        end


        if #anchors < maxAnchors then
            if not popover.addButton then
                local addButtonFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
                addButtonFrame:SetHeight(FORM_ROW + 6)
                addButtonFrame:SetPoint("TOPLEFT", PAD, currentY)
                addButtonFrame:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)

                addButtonFrame:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                    insets = {left = 2, right = 2, top = 2, bottom = 2}
                })
                addButtonFrame:SetBackdropColor(C.bg[1] * 1.1, C.bg[2] * 1.1, C.bg[3] * 1.1, 0.3)
                addButtonFrame:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.5)

                popover.addButton = GUI:CreateButton(addButtonFrame, "+ Add Anchor", 100, 22, function()
                    table.insert(anchors, {source = "BOTTOMLEFT", target = "BOTTOMLEFT"})
                    RebuildAnchors()
                    UpdateContentHeight()
                    if onChange then onChange() end
                end)
                popover.addButton:SetPoint("CENTER", 0, 0)
                popover.addButtonFrame = addButtonFrame
            end
            popover.addButtonFrame:SetPoint("TOPLEFT", PAD, currentY)
            popover.addButtonFrame:Show()
            currentY = currentY - (FORM_ROW + 6) - 3
        else
            if popover.addButtonFrame then
                popover.addButtonFrame:Hide()
            end
        end

        UpdateContentHeight()
    end


    RebuildAnchors()


    local clickFrame = CreateFrame("Frame", nil, UIParent)
    clickFrame:SetAllPoints(UIParent)
    clickFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    clickFrame:SetFrameLevel(499)
    clickFrame:EnableMouse(true)
    clickFrame:Hide()
    clickFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            popover:Hide()
        end
    end)
    popover.clickFrame = clickFrame


    popover:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    popover:EnableKeyboard(true)


    popover.Show = function(self)
        self:SetShown(true)
        clickFrame:Show()

        self:ClearAllPoints()
        self:SetPoint("TOPLEFT", anchorButton, "BOTTOMLEFT", 0, -5)
    end

    popover.Hide = function(self)
        self:SetShown(false)
        clickFrame:Hide()
    end

    popover.Toggle = function(self)
        if self:IsShown() then
            self:Hide()
        else
            self:Show()
        end
    end

    popover.Refresh = function(self)
        RebuildAnchors()
    end

    return popover
end


function PREY_Anchoring_Options:CreateAnchorPresetControls(parent, settingsDB, x, y, onChange, PAD, FORM_ROW, anchorsKey, maxAnchors, onPresetChange)
    anchorsKey = anchorsKey or "anchors"
    maxAnchors = maxAnchors or 2

    local C = GetColors()
    local GUI = GetGUI()
    if not GUI then return nil, nil, nil, y end


    if not settingsDB[anchorsKey] then
        settingsDB[anchorsKey] = {
            {source = "BOTTOMLEFT", target = "BOTTOMLEFT"}
        }
    end

    local anchors = settingsDB[anchorsKey]


    local presetButtonContainer = CreateFrame("Frame", nil, parent)
    presetButtonContainer:SetHeight(FORM_ROW)
    presetButtonContainer:SetPoint("TOPLEFT", x or PAD, y)
    presetButtonContainer:SetPoint("RIGHT", parent, "RIGHT", -(x or PAD), 0)

    local presetLabel = presetButtonContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    presetLabel:SetPoint("LEFT", 0, 0)
    presetLabel:SetText("Anchor point(s):")
    presetLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)

    local buttonWidth = 110
    local buttonSpacing = 8


    local function ApplyPreset(presetAnchors, refreshPopover)
        while #anchors > 0 do
            table.remove(anchors, 1)
        end
        for _, anchor in ipairs(presetAnchors) do
            table.insert(anchors, anchor)
        end

        if settingsDB then
            settingsDB.offsetX = 0
            settingsDB.offsetY = 0


            if settingsDB._offsetXSlider then
                local container = settingsDB._offsetXSlider
                if container.slider and container.editBox then
                    container.value = 0
                    container.slider:SetValue(0)
                    container.editBox:SetText("0")

                    if container.trackFill and container.trackContainer then
                        local minVal, maxVal = container.min or -500, container.max or 500
                        local pct = (0 - minVal) / (maxVal - minVal)
                        pct = math.max(0, math.min(1, pct))
                        local trackWidth = container.trackContainer:GetWidth() - 2
                        local fillWidth = math.max(1, pct * trackWidth)
                        container.trackFill:SetWidth(fillWidth)
                        if container.thumbFrame then
                            local thumbX = pct * (trackWidth - 14) + 7
                            container.thumbFrame:ClearAllPoints()
                            container.thumbFrame:SetPoint("CENTER", container.trackContainer, "LEFT", thumbX + 1, 0)
                        end
                    end
                end
            end
            if settingsDB._offsetYSlider then
                local container = settingsDB._offsetYSlider
                if container.slider and container.editBox then
                    container.value = 0
                    container.slider:SetValue(0)
                    container.editBox:SetText("0")

                    if container.trackFill and container.trackContainer then
                        local minVal, maxVal = container.min or -500, container.max or 500
                        local pct = (0 - minVal) / (maxVal - minVal)
                        pct = math.max(0, math.min(1, pct))
                        local trackWidth = container.trackContainer:GetWidth() - 2
                        local fillWidth = math.max(1, pct * trackWidth)
                        container.trackFill:SetWidth(fillWidth)
                        if container.thumbFrame then
                            local thumbX = pct * (trackWidth - 14) + 7
                            container.thumbFrame:ClearAllPoints()
                            container.thumbFrame:SetPoint("CENTER", container.trackContainer, "LEFT", thumbX + 1, 0)
                        end
                    end
                end
            end
        end
        if onPresetChange then
            onPresetChange()
        end
        if onChange then
            onChange()
        end
        if refreshPopover then
            refreshPopover()
        end
    end


    local presetAboveBtn = GUI:CreateButton(presetButtonContainer, "Above (auto width)", buttonWidth, 24, function()
        ApplyPreset({
            {source = "BOTTOMLEFT", target = "TOPLEFT"},
            {source = "BOTTOMRIGHT", target = "TOPRIGHT"}
        })
    end)
    presetAboveBtn:SetPoint("LEFT", presetButtonContainer, "LEFT", 180, 0)


    local presetBelowBtn = GUI:CreateButton(presetButtonContainer, "Below (auto width)", buttonWidth, 24, function()
        ApplyPreset({
            {source = "TOPLEFT", target = "BOTTOMLEFT"},
            {source = "TOPRIGHT", target = "BOTTOMRIGHT"}
        })
    end)
    presetBelowBtn:SetPoint("LEFT", presetAboveBtn, "RIGHT", buttonSpacing, 0)


    local presetLeftBtn = GUI:CreateButton(presetButtonContainer, "Left (auto height)", buttonWidth, 24, function()
        ApplyPreset({
            {source = "TOPRIGHT", target = "TOPLEFT"},
            {source = "BOTTOMRIGHT", target = "BOTTOMLEFT"}
        })
    end)
    presetLeftBtn:SetPoint("LEFT", presetBelowBtn, "RIGHT", buttonSpacing, 0)


    local presetRightBtn = GUI:CreateButton(presetButtonContainer, "Right (auto height)", buttonWidth, 24, function()

    end)
    presetRightBtn:SetPoint("LEFT", presetLeftBtn, "RIGHT", buttonSpacing, 0)


    local advancedAnchorButton = GUI:CreateButton(
        presetButtonContainer,
        "Advanced...",
        100,
        24,
        function()

        end
    )
    advancedAnchorButton:SetPoint("RIGHT", presetButtonContainer, "RIGHT", 0, 0)

    y = y - FORM_ROW


    local advancedAnchorDialog = self:CreateMultiAnchorPopover(
        presetAboveBtn,
        settingsDB,
        onChange,
        anchorsKey,
        maxAnchors
    )


    advancedAnchorButton:SetScript("OnClick", function()
        if advancedAnchorDialog then
            advancedAnchorDialog:Toggle()
        end
    end)


    advancedAnchorButton._popover = advancedAnchorDialog


    local function RefreshPopover()
        if advancedAnchorDialog and advancedAnchorDialog.Refresh then
            advancedAnchorDialog:Refresh()
        end
    end


    local function UpdatePresetHandler(btn, presetAnchors)
        local originalOnClick = btn:GetScript("OnClick")
        btn:SetScript("OnClick", function()
            ApplyPreset(presetAnchors, RefreshPopover)
        end)
    end

    UpdatePresetHandler(presetAboveBtn, {
        {source = "BOTTOMLEFT", target = "TOPLEFT"},
        {source = "BOTTOMRIGHT", target = "TOPRIGHT"}
    })

    UpdatePresetHandler(presetBelowBtn, {
        {source = "TOPLEFT", target = "BOTTOMLEFT"},
        {source = "TOPRIGHT", target = "BOTTOMRIGHT"}
    })

    UpdatePresetHandler(presetLeftBtn, {
        {source = "TOPRIGHT", target = "TOPLEFT"},
        {source = "BOTTOMRIGHT", target = "BOTTOMLEFT"}
    })

    UpdatePresetHandler(presetRightBtn, {
        {source = "TOPLEFT", target = "TOPRIGHT"},
        {source = "BOTTOMLEFT", target = "BOTTOMRIGHT"}
    })

    return presetButtonContainer, advancedAnchorButton, advancedAnchorDialog, y
end


function PREY_Anchoring_Options:CreateMultiAnchorDialog(settingsDB, onChange, anchorsKey, maxAnchors)
    anchorsKey = anchorsKey or "anchors"
    maxAnchors = maxAnchors or 2

    local C = GetColors()
    local GUI = GetGUI()
    if not GUI then return nil end


    if not settingsDB[anchorsKey] then
        settingsDB[anchorsKey] = {
            {source = "BOTTOMLEFT", target = "BOTTOMLEFT"}
        }
    end


    local dialog = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    dialog:SetSize(600, 500)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(100)
    dialog:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    dialog:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], C.bg[4] or 0.98)
    dialog:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 1)
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    dialog:Hide()


    local titleBar = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
    titleBar:SetHeight(32)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    titleBar:SetBackdropColor(C.bgLight[1], C.bgLight[2], C.bgLight[3], 1)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() dialog:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() dialog:StopMovingOrSizing() end)

    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", 10, 0)
    titleText:SetText("Advanced Anchor Settings")
    titleText:SetTextColor(C.accent[1], C.accent[2], C.accent[3], 1)


    local closeBtn = GUI:CreateButton(titleBar, "×", 30, 30, function()
        dialog:Hide()
    end)
    closeBtn:SetPoint("RIGHT", -5, 0)
    if closeBtn.text then
        local fontPath = GUI.GetFontPath and GUI:GetFontPath() or "Fonts\\FRIZQT__.TTF"
        closeBtn.text:SetFont(fontPath, 18, "")
    end


    local scrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(570)
    scrollFrame:SetScrollChild(content)


    local scrollBar = scrollFrame.ScrollBar
    if scrollBar then
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 2, -2)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 2, 2)

        local thumb = scrollBar:GetThumbTexture()
        if thumb then
            thumb:SetColorTexture(0.35, 0.45, 0.5, 0.8)
        end

        local scrollUp = scrollBar.ScrollUpButton or scrollBar.Back
        local scrollDown = scrollBar.ScrollDownButton or scrollBar.Forward
        if scrollUp then scrollUp:Hide(); scrollUp:SetAlpha(0) end
        if scrollDown then scrollDown:Hide(); scrollDown:SetAlpha(0) end
    end


    local PAD = 10
    local FORM_ROW = 30
    local anchors = settingsDB[anchorsKey]
    local selectorSize = 75
    local spacing = 10
    local rowHeight = selectorSize + 30
    local currentY = -PAD


    dialog.anchors = anchors
    dialog.maxAnchors = maxAnchors
    dialog.onChange = onChange
    dialog.anchorRows = {}


    local function UpdateContentHeight()
        content:SetHeight(math.abs(currentY) + PAD)
    end


    local function RebuildAnchors()

        for i, row in ipairs(dialog.anchorRows) do
            if row.frame then
                row.frame:Hide()
                row.frame:SetParent(nil)
            end
        end
        dialog.anchorRows = {}
        currentY = -PAD


        for i, anchor in ipairs(anchors) do
            local rowFrame = CreateFrame("Frame", nil, content)
            rowFrame:SetHeight(rowHeight)
            rowFrame:SetPoint("TOPLEFT", PAD, currentY)
            rowFrame:SetPoint("RIGHT", content, "RIGHT", -PAD, 0)


            local label = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", 0, 0)
            label:SetText("Anchor " .. i)
            label:SetTextColor(C.text[1], C.text[2], C.text[3], 1)


            local sourceSelector = self:CreateAnchorPointSelector(
                rowFrame,
                "Source",
                anchor,
                "source",
                80,
                0,
                onChange,
                selectorSize
            )


            local targetSelector = self:CreateAnchorPointSelector(
                rowFrame,
                "Target",
                anchor,
                "target",
                80 + selectorSize + spacing,
                0,
                onChange,
                selectorSize
            )


            local removeButton
            if #anchors > 1 then
                removeButton = GUI:CreateButton(rowFrame, "Remove", 80, 24, function()
                    table.remove(anchors, i)
                    RebuildAnchors()
                    UpdateContentHeight()
                    if onChange then onChange() end
                end)
                removeButton:SetPoint("RIGHT", -10, 0)
            end

            table.insert(dialog.anchorRows, {
                frame = rowFrame,
                sourceSelector = sourceSelector,
                targetSelector = targetSelector,
                removeButton = removeButton
            })

            currentY = currentY - rowHeight - (FORM_ROW / 2)
        end


        if #anchors < maxAnchors then
            if not dialog.addButton then
                dialog.addButton = GUI:CreateButton(content, "Add Anchor", 100, 24, function()
                    table.insert(anchors, {source = "BOTTOMLEFT", target = "BOTTOMLEFT"})
                    RebuildAnchors()
                    UpdateContentHeight()
                    if onChange then onChange() end
                end)
            end
            dialog.addButton:SetPoint("TOPLEFT", PAD, currentY)
            dialog.addButton:Show()
            currentY = currentY - FORM_ROW
        else
            if dialog.addButton then
                dialog.addButton:Hide()
            end
        end


        UpdateContentHeight()
    end


    RebuildAnchors()


    dialog:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    dialog:EnableKeyboard(true)


    dialog.Show = function(self)
        self:SetShown(true)
    end

    dialog.Hide = function(self)
        self:SetShown(false)
    end

    dialog.Toggle = function(self)
        if self:IsShown() then
            self:Hide()
        else
            self:Show()
        end
    end

    return dialog
end


function PREY_Anchoring_Options:CreateMultiAnchorControls(parent, settingsDB, x, y, onChange, PAD, FORM_ROW, anchorsKey, maxAnchors)
    anchorsKey = anchorsKey or "anchors"
    maxAnchors = maxAnchors or 2

    local C = GetColors()
    local GUI = GetGUI()
    if not GUI then return nil, y end


    if not settingsDB[anchorsKey] then
        settingsDB[anchorsKey] = {
            {source = "BOTTOMLEFT", target = "BOTTOMLEFT"}
        }
    end


    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", x or PAD, y)
    container:SetPoint("RIGHT", parent, "RIGHT", -(x or PAD), 0)

    local anchors = settingsDB[anchorsKey]
    local selectorSize = 75
    local spacing = 10
    local rowHeight = selectorSize + 30
    local currentY = 0


    container.anchorRows = {}
    container.anchors = anchors
    container.maxAnchors = maxAnchors
    container.onChange = onChange


    local function RebuildAnchors()

        for i, row in ipairs(container.anchorRows) do
            if row.frame then
                row.frame:Hide()
                row.frame:SetParent(nil)
            end
        end
        container.anchorRows = {}
        currentY = 0


        for i, anchor in ipairs(anchors) do
            local rowFrame = CreateFrame("Frame", nil, container)
            rowFrame:SetHeight(rowHeight)
            rowFrame:SetPoint("TOPLEFT", 0, -currentY)
            rowFrame:SetPoint("RIGHT", container, "RIGHT", 0, 0)


            local label = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", 0, 0)
            label:SetText("Anchor " .. i)
            label:SetTextColor(C.text[1], C.text[2], C.text[3], 1)


            local sourceSelector = self:CreateAnchorPointSelector(
                rowFrame,
                "Source",
                anchor,
                "source",
                80,
                0,
                onChange,
                selectorSize
            )


            local targetSelector = self:CreateAnchorPointSelector(
                rowFrame,
                "Target",
                anchor,
                "target",
                80 + selectorSize + spacing,
                0,
                onChange,
                selectorSize
            )


            local removeButton
            if #anchors > 1 then
                removeButton = GUI:CreateButton(rowFrame, "Remove", 80, 24, function()
                    table.remove(anchors, i)
                    RebuildAnchors()
                    if onChange then onChange() end
                end)
                removeButton:SetPoint("RIGHT", -10, 0)
            end

            table.insert(container.anchorRows, {
                frame = rowFrame,
                sourceSelector = sourceSelector,
                targetSelector = targetSelector,
                removeButton = removeButton
            })

            currentY = currentY + rowHeight + (FORM_ROW / 2)
        end


        if #anchors < maxAnchors then
            if not container.addButton then
                container.addButton = GUI:CreateButton(container, "Add Anchor", 100, 24, function()
                    table.insert(anchors, {source = "BOTTOMLEFT", target = "BOTTOMLEFT"})
                    RebuildAnchors()
                    if onChange then onChange() end
                end)
            end
            container.addButton:SetPoint("TOPLEFT", 0, -currentY)
            container.addButton:Show()
            currentY = currentY + FORM_ROW
        else
            if container.addButton then
                container.addButton:Hide()
            end
        end


        if container.presetContainer then
            container.presetContainer:SetPoint("TOPLEFT", 0, -currentY)
        end

        container:SetHeight(currentY + FORM_ROW)
    end


    local presetContainer = CreateFrame("Frame", nil, container)
    presetContainer:SetHeight(FORM_ROW)
    presetContainer:SetPoint("TOPLEFT", 0, 0)
    presetContainer:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    container.presetContainer = presetContainer

    local presetLabel = presetContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    presetLabel:SetPoint("LEFT", 0, 0)
    presetLabel:SetText("Presets:")
    presetLabel:SetTextColor(C.text[1], C.text[2], C.text[3], 1)


    local preset1Btn = GUI:CreateButton(presetContainer, "Above Target", 120, 24, function()

        while #anchors > 0 do
            table.remove(anchors, 1)
        end

        table.insert(anchors, {source = "BOTTOMLEFT", target = "TOPLEFT"})
        table.insert(anchors, {source = "BOTTOMRIGHT", target = "TOPRIGHT"})
        RebuildAnchors()
        if onChange then onChange() end
    end)
    preset1Btn:SetPoint("LEFT", presetLabel, "RIGHT", 10, 0)


    local preset2Btn = GUI:CreateButton(presetContainer, "Below Target", 120, 24, function()

        while #anchors > 0 do
            table.remove(anchors, 1)
        end

        table.insert(anchors, {source = "TOPLEFT", target = "BOTTOMLEFT"})
        table.insert(anchors, {source = "TOPRIGHT", target = "BOTTOMRIGHT"})
        RebuildAnchors()
        if onChange then onChange() end
    end)
    preset2Btn:SetPoint("LEFT", preset1Btn, "RIGHT", 10, 0)


    RebuildAnchors()


    y = y - container:GetHeight()

    return container, y
end


function PREY_Anchoring_Options:CreateAnchorPointControls(parent, settingsDB, x, y, onChange, PAD, FORM_ROW, sourceKey, targetKey, sourceLabel, targetLabel)
    sourceKey = sourceKey or "anchorPoint"
    targetKey = targetKey or "targetAnchorPoint"
    sourceLabel = sourceLabel or "Source Anchor Point"
    targetLabel = targetLabel or "Target Anchor Point"


    if not settingsDB[sourceKey] then
        settingsDB[sourceKey] = "BOTTOMLEFT"
    end
    if not settingsDB[targetKey] then
        settingsDB[targetKey] = "BOTTOMLEFT"
    end


    local selectorSize = 150
    local spacing = 20


    local sourceSelector = self:CreateAnchorPointSelector(
        parent,
        sourceLabel,
        settingsDB,
        sourceKey,
        x or PAD,
        y,
        onChange,
        selectorSize
    )


    local targetSelector = self:CreateAnchorPointSelector(
        parent,
        targetLabel,
        settingsDB,
        targetKey,
        (x or PAD) + selectorSize + spacing,
        y,
        onChange,
        selectorSize
    )


    y = y - (selectorSize + 30) - (FORM_ROW / 2)

    return sourceSelector, targetSelector, y
end


function PREY_Anchoring_Options:CreateOffsetControls(parent, settingsDB, x, y, onChange, PAD, FORM_ROW)
    local GUI = GetGUI()
    if not GUI then
        return nil, nil, y
    end


    onChange = onChange or function() end

    local offsetXSlider = GUI:CreateFormSlider(parent, "Offset X", -500, 500, 1, "offsetX", settingsDB, onChange)
    if offsetXSlider then
        offsetXSlider:SetPoint("TOPLEFT", x or PAD, y)
        offsetXSlider:SetPoint("RIGHT", parent, "RIGHT", -(x or PAD), 0)
        y = y - FORM_ROW
    end

    local offsetYSlider = GUI:CreateFormSlider(parent, "Offset Y", -500, 500, 1, "offsetY", settingsDB, onChange)
    if offsetYSlider then
        offsetYSlider:SetPoint("TOPLEFT", x or PAD, y)
        offsetYSlider:SetPoint("RIGHT", parent, "RIGHT", -(x or PAD), 0)
        y = y - FORM_ROW
    end


    if settingsDB then
        settingsDB._offsetXSlider = offsetXSlider
        settingsDB._offsetYSlider = offsetYSlider
    end

    return offsetXSlider, offsetYSlider, y
end


function PREY_Anchoring_Options:CreateAnchorControls(parent, settingsDB, x, y, onChange, PAD, FORM_ROW, anchorKey, anchorsKey, maxAnchors, excludeSelf, dropdownLabel, offsetMin, offsetMax, onPresetChange)
    anchorKey = anchorKey or "anchorTo"
    anchorsKey = anchorsKey or "anchors"
    maxAnchors = maxAnchors or 2
    dropdownLabel = dropdownLabel or "Anchor To"
    offsetMin = offsetMin or -500
    offsetMax = offsetMax or 500

    local GUI = GetGUI()
    if not GUI then
        return nil, nil, nil, nil, nil, nil, y
    end


    if not settingsDB[anchorKey] then
        settingsDB[anchorKey] = "disabled"
    end
    if not settingsDB.offsetX then
        settingsDB.offsetX = 0
    end
    if not settingsDB.offsetY then
        settingsDB.offsetY = 0
    end


    local anchorDropdown = self:CreateAnchorDropdown(
        parent, dropdownLabel, settingsDB, anchorKey, x or PAD, y, nil, onChange, nil, nil, excludeSelf
    )
    local dropdownY = y
    if anchorDropdown then
        anchorDropdown:SetPoint("RIGHT", parent, "RIGHT", -(x or PAD), 0)
        dropdownY = y - FORM_ROW
    end


    local presetContainer, advancedButton, popover, presetY = self:CreateAnchorPresetControls(
        parent, settingsDB, x or PAD, dropdownY, onChange, PAD, FORM_ROW, anchorsKey, maxAnchors, onPresetChange
    )


    local offsetXSlider, offsetYSlider, offsetY
    if offsetMin ~= -500 or offsetMax ~= 500 then

        offsetXSlider = GUI:CreateFormSlider(parent, "Offset X", offsetMin, offsetMax, 1, "offsetX", settingsDB, onChange)
        if offsetXSlider then
            offsetXSlider:SetPoint("TOPLEFT", x or PAD, presetY)
            offsetXSlider:SetPoint("RIGHT", parent, "RIGHT", -(x or PAD), 0)
            offsetY = presetY - FORM_ROW
        end

        offsetYSlider = GUI:CreateFormSlider(parent, "Offset Y", offsetMin, offsetMax, 1, "offsetY", settingsDB, onChange)
        if offsetYSlider then
            offsetYSlider:SetPoint("TOPLEFT", x or PAD, offsetY)
            offsetYSlider:SetPoint("RIGHT", parent, "RIGHT", -(x or PAD), 0)
            offsetY = offsetY - FORM_ROW
        end


        if settingsDB then
            settingsDB._offsetXSlider = offsetXSlider
            settingsDB._offsetYSlider = offsetYSlider
        end
    else

        offsetXSlider, offsetYSlider, offsetY = self:CreateOffsetControls(
            parent, settingsDB, x or PAD, presetY, onChange, PAD, FORM_ROW
        )
    end

    return anchorDropdown, presetContainer, advancedButton, popover, offsetXSlider, offsetYSlider, offsetY
end

