local ADDON_NAME, ns = ...
local PREYCore = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")


pcall(function() SetCVar("cooldownViewerEnabled", 1) end)


local function GetGeneralFont()
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        local general = PREYCore.db.profile.general
        local fontName = general.font or "Friz Quadrata TT"
        return LSM:Fetch("font", fontName) or "Fonts\\FRIZQT__.TTF"
    end
    return "Fonts\\FRIZQT__.TTF"
end

local function GetGeneralFontOutline()
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        return PREYCore.db.profile.general.fontOutline or "OUTLINE"
    end
    return "OUTLINE"
end


local VIEWER_ESSENTIAL = "EssentialCooldownViewer"
local VIEWER_UTILITY = "UtilityCooldownViewer"


local ASPECT_RATIOS = {
    square = { w = 1, h = 1 },
    rectangle = { w = 4, h = 3 },
}


local HookFrameForMouseover


local function MigrateRowAspect(rowData)
    if rowData and rowData.aspectRatioCrop == nil and rowData.shape then
        if rowData.shape == "rectangle" or rowData.shape == "flat" then
            rowData.aspectRatioCrop = 1.33
        else
            rowData.aspectRatioCrop = 1.0
        end
    end
    return rowData.aspectRatioCrop or 1.0
end


local NCDM = {
    hooked = {},
    applying = {},
    initialized = false,
    pendingIcons = {},
    pendingTicker = nil,
    settingsVersion = {},
}


local IconState = setmetatable({}, { __mode = "k" })
local AtlasBorderBlocked = setmetatable({}, { __mode = "k" })
local CooldownFlashHooked = setmetatable({}, { __mode = "k" })
local FrameOrderState = setmetatable({}, { __mode = "k" })
local nextFrameOrder = 0

local function GetIconState(icon)
    if not icon then return nil end
    local state = IconState[icon]
    if not state then
        state = {}
        IconState[icon] = state
    end
    return state
end

local function GetStableFrameOrder(frame)
    if not frame then return math.huge end
    local order = FrameOrderState[frame]
    if not order then
        nextFrameOrder = nextFrameOrder + 1
        order = nextFrameOrder
        FrameOrderState[frame] = order
    end
    return order
end


local function GetDB()
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.ncdm then
        return PREYCore.db.profile.ncdm
    end
    return nil
end


local function GetTrackerSettings(trackerKey)
    local db = GetDB()
    if db and db[trackerKey] then
        return db[trackerKey]
    end
    return nil
end


local function UpdateCooldownViewerCVar()
    local db = GetDB()
    if not db then return end

    local essentialEnabled = db.essential and db.essential.enabled
    local utilityEnabled = db.utility and db.utility.enabled


    if essentialEnabled or utilityEnabled then
        pcall(function() SetCVar("cooldownViewerEnabled", 1) end)
    else
        pcall(function() SetCVar("cooldownViewerEnabled", 0) end)
    end
end


local function IsIconFrame(child)
    if not child then return false end
    return (child.Icon or child.icon) and (child.Cooldown or child.cooldown)
end


local function GetTotalIconCapacity(settings)
    local total = 0
    for i = 1, 3 do
        local rowKey = "row" .. i
        if settings[rowKey] and settings[rowKey].iconCount then
            total = total + settings[rowKey].iconCount
        end
    end
    return total
end


local function StripBlizzardOverlay(icon)
    if not icon or not icon.GetRegions then return end

    for _, region in ipairs({ icon:GetRegions() }) do
        if region:IsObjectType("Texture") and region.GetAtlas then
            local ok, atlas = pcall(region.GetAtlas, region)
            if ok and atlas == "UI-HUD-CoolDownManager-IconOverlay" then
                region:SetTexture("")
                region:Hide()
                region.Show = function() end
            end
        end
    end
end


local function PreventAtlasBorder(texture)
    if not texture or AtlasBorderBlocked[texture] then return end
    AtlasBorderBlocked[texture] = true


    if texture.SetAtlas then
        hooksecurefunc(texture, "SetAtlas", function(self)
            if self.SetTexture then self:SetTexture(nil) end
            if self.SetAlpha then self:SetAlpha(0) end
        end)
    end

    if texture.SetTexture then texture:SetTexture(nil) end
    if texture.SetAlpha then texture:SetAlpha(0) end
end


local function ApplyTexCoord(icon)
    if not icon then return end
    local state = GetIconState(icon)
    local z = (state and state.zoom) or 0
    local aspectRatio = (state and state.aspectRatio) or 1.0
    local baseCrop = 0.08


    local left = baseCrop + z
    local right = 1 - baseCrop - z
    local top = baseCrop + z
    local bottom = 1 - baseCrop - z


    if aspectRatio > 1.0 then

        local cropAmount = 1.0 - (1.0 / aspectRatio)
        local availableHeight = bottom - top
        local offset = (cropAmount * availableHeight) / 2.0
        top = top + offset
        bottom = bottom - offset
    end

    local tex = icon.Icon or icon.icon
    if tex and tex.SetTexCoord then
        tex:SetTexCoord(left, right, top, bottom)
    end
end


local function SetupIconOnce(icon)
    if not icon then return end
    local state = GetIconState(icon)
    if state.setupDone then return end
    state.setupDone = true


    local textures = { icon.Icon, icon.icon }
    for _, tex in ipairs(textures) do
        if tex and tex.GetMaskTexture and tex.RemoveMaskTexture then
            for i = 1, 10 do
                local mask = tex:GetMaskTexture(i)
                if mask then
                    tex:RemoveMaskTexture(mask)
                end
            end
        end
    end


    StripBlizzardOverlay(icon)


    if icon.NormalTexture then
        icon.NormalTexture:SetAlpha(0)
    end
    if icon.GetNormalTexture then
        local normalTex = icon:GetNormalTexture()
        if normalTex then
            normalTex:SetAlpha(0)
        end
    end


    if icon.DebuffBorder then PreventAtlasBorder(icon.DebuffBorder) end
    if icon.BuffBorder then PreventAtlasBorder(icon.BuffBorder) end
    if icon.TempEnchantBorder then PreventAtlasBorder(icon.TempEnchantBorder) end


end


local function SkinIcon(icon, size, aspectRatioCrop, zoom, borderSize, borderColorTable)
    if not icon then return end


    local state = GetIconState(icon)
    state.zoom = zoom or 0
    state.aspectRatio = aspectRatioCrop or 1.0


    SetupIconOnce(icon)


    local aspectRatio = aspectRatioCrop or 1.0
    local width = size
    local height = size / aspectRatio


    icon:SetSize(width, height)


    borderSize = borderSize or 0
    if borderSize > 0 then
        if not state.borderTexture then
            state.borderTexture = icon:CreateTexture(nil, "BACKGROUND", nil, -8)
        end
        local bc = borderColorTable or {0, 0, 0, 1}
        state.borderTexture:SetColorTexture(bc[1], bc[2], bc[3], bc[4])

        state.borderTexture:ClearAllPoints()
        state.borderTexture:SetPoint("TOPLEFT", icon, "TOPLEFT", -borderSize, borderSize)
        state.borderTexture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", borderSize, -borderSize)
        state.borderTexture:Show()


        icon:SetHitRectInsets(-borderSize, -borderSize, -borderSize, -borderSize)
    else
        if state.borderTexture then
            state.borderTexture:Hide()
        end

        icon:SetHitRectInsets(0, 0, 0, 0)
    end


    if not state.positioned then
        state.positioned = true

        local textures = { icon.Icon, icon.icon }
        for _, tex in ipairs(textures) do
            if tex then
                tex:ClearAllPoints()
                tex:SetAllPoints(icon)
            end
        end


        if icon.CooldownFlash then
            icon.CooldownFlash:SetAlpha(0)

            if not CooldownFlashHooked[icon.CooldownFlash] then
                CooldownFlashHooked[icon.CooldownFlash] = true
                hooksecurefunc(icon.CooldownFlash, "Show", function(self)
                    self:SetAlpha(0)
                end)
            end
        end
    end


    local cooldown = icon.Cooldown or icon.cooldown
    if cooldown then
        cooldown:ClearAllPoints()
        cooldown:SetAllPoints(icon)

        cooldown:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
        cooldown:SetSwipeColor(0, 0, 0, 0.8)
    end


    ApplyTexCoord(icon)


    icon:EnableMouse(true)
    HookFrameForMouseover(icon)

    return true
end


local function ProcessPendingIcons()
    if InCombatLockdown() then return end
    if not next(NCDM.pendingIcons) then

        if NCDM.pendingTicker then
            NCDM.pendingTicker:Cancel()
            NCDM.pendingTicker = nil
        end
        return
    end

    for icon, data in pairs(NCDM.pendingIcons) do
        if icon and icon:IsShown() then
            local success = pcall(SkinIcon, icon, data.size, data.aspectRatioCrop, data.zoom, data.borderSize, data.borderColorTable)
            if success then
                pcall(ApplyIconTextSizes, icon, data.durationSize, data.stackSize,
                    data.durationOffsetX, data.durationOffsetY, data.stackOffsetX, data.stackOffsetY,
                    data.durationTextColor, data.durationAnchor, data.stackTextColor, data.stackAnchor)
                local state = GetIconState(icon)
                state.skinned = true
                state.skinPending = nil
            end
        end
        NCDM.pendingIcons[icon] = nil
    end


    if not next(NCDM.pendingIcons) and NCDM.pendingTicker then
        NCDM.pendingTicker:Cancel()
        NCDM.pendingTicker = nil
    end
end


local combatEndFrame = CreateFrame("Frame")
combatEndFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatEndFrame:SetScript("OnEvent", function()
    ProcessPendingIcons()


    C_Timer.After(0.1, function()
        if not InCombatLockdown() and _G.PreyUI_RefreshNCDM then
            _G.PreyUI_RefreshNCDM()
        end
    end)
end)


local function QueueIconForSkinning(icon, size, aspectRatioCrop, zoom, borderSize, borderColorTable, durationSize, stackSize, durationOffsetX, durationOffsetY, stackOffsetX, stackOffsetY, durationTextColor, durationAnchor, stackTextColor, stackAnchor)
    if not icon then return end

    local state = GetIconState(icon)
    state.skinPending = true
    NCDM.pendingIcons[icon] = {
        size = size,
        aspectRatioCrop = aspectRatioCrop,
        zoom = zoom,
        borderSize = borderSize,
        borderColorTable = borderColorTable or {0, 0, 0, 1},
        durationSize = durationSize,
        stackSize = stackSize,
        durationOffsetX = durationOffsetX or 0,
        durationOffsetY = durationOffsetY or 0,
        stackOffsetX = stackOffsetX or 0,
        stackOffsetY = stackOffsetY or 0,
        durationTextColor = durationTextColor or {1, 1, 1, 1},
        durationAnchor = durationAnchor or "CENTER",
        stackTextColor = stackTextColor or {1, 1, 1, 1},
        stackAnchor = stackAnchor or "BOTTOMRIGHT",
    }


    if not NCDM.pendingTicker then
        NCDM.pendingTicker = C_Timer.NewTicker(1.0, function()
            ProcessPendingIcons()
        end)
    end
end


local function ApplyIconTextSizes(icon, durationSize, stackSize, durationOffsetX, durationOffsetY, stackOffsetX, stackOffsetY, durationTextColor, durationAnchor, stackTextColor, stackAnchor)
    if not icon then return end


    local generalFont = GetGeneralFont()
    local generalOutline = GetGeneralFontOutline()


    durationOffsetX = durationOffsetX or 0
    durationOffsetY = durationOffsetY or 0
    stackOffsetX = stackOffsetX or 0
    stackOffsetY = stackOffsetY or 0


    durationTextColor = durationTextColor or {1, 1, 1, 1}
    stackTextColor = stackTextColor or {1, 1, 1, 1}


    durationAnchor = durationAnchor or "CENTER"
    stackAnchor = stackAnchor or "BOTTOMRIGHT"


    local cooldown = icon.Cooldown or icon.cooldown
    if cooldown and durationSize and durationSize > 0 then
        if cooldown.text then
            cooldown.text:SetFont(generalFont, durationSize, generalOutline)
            cooldown.text:SetTextColor(durationTextColor[1], durationTextColor[2], durationTextColor[3], durationTextColor[4] or 1)
            pcall(function()
                cooldown.text:ClearAllPoints()
                cooldown.text:SetPoint(durationAnchor, icon, durationAnchor, durationOffsetX, durationOffsetY)
                cooldown.text:SetDrawLayer("OVERLAY", 7)
            end)
        end

        local ok, regions = pcall(function() return { cooldown:GetRegions() } end)
        if ok and regions then
            for _, region in ipairs(regions) do
                if region and region.GetObjectType and region:GetObjectType() == "FontString" then
                    region:SetFont(generalFont, durationSize, generalOutline)
                    region:SetTextColor(durationTextColor[1], durationTextColor[2], durationTextColor[3], durationTextColor[4] or 1)
                    pcall(function()
                        region:ClearAllPoints()
                        region:SetPoint(durationAnchor, icon, durationAnchor, durationOffsetX, durationOffsetY)
                        region:SetDrawLayer("OVERLAY", 7)
                    end)
                end
            end
        end
    end


    if stackSize and stackSize > 0 then
        local foundFS = nil


        local chargeFrame = icon.ChargeCount
        if chargeFrame then
            foundFS = chargeFrame.Current or chargeFrame.Count or chargeFrame.count
            if not foundFS and chargeFrame.GetRegions then
                pcall(function()
                    for _, region in ipairs({ chargeFrame:GetRegions() }) do
                        if region:GetObjectType() == "FontString" then
                            foundFS = region
                            break
                        end
                    end
                end)
            end
        end

        if not foundFS then
            foundFS = icon.Count or icon.count
        end

        if not foundFS and icon.GetChildren then
            pcall(function()
                for _, child in ipairs({ icon:GetChildren() }) do
                    if child then
                        local fs = child.Current or child.Count or child.count
                        if fs and fs.SetFont then
                            foundFS = fs
                            break
                        end
                    end
                end
            end)
        end


        if foundFS and foundFS.SetFont then
            pcall(function()
                foundFS:SetFont(generalFont, stackSize, generalOutline)
                foundFS:SetTextColor(stackTextColor[1], stackTextColor[2], stackTextColor[3], stackTextColor[4] or 1)
                foundFS:ClearAllPoints()
                foundFS:SetPoint(stackAnchor, icon, stackAnchor, stackOffsetX, stackOffsetY)
                foundFS:SetDrawLayer("OVERLAY", 7)


                local parentFrame = foundFS:GetParent()
                if parentFrame and parentFrame.SetFrameLevel and icon.GetFrameLevel then
                    local iconLevel = icon:GetFrameLevel() or 0
                    local currentLevel = parentFrame:GetFrameLevel() or 0
                    parentFrame:SetFrameLevel(math.max(currentLevel, iconLevel + 10))
                end
            end)
        end
    end
end


local function CollectIcons(viewer)
    local icons = {}
    if not viewer or not viewer.GetNumChildren then return icons end

    local numChildren = viewer:GetNumChildren()
    for i = 1, numChildren do
        local child = select(i, viewer:GetChildren())
        if child and child ~= viewer.Selection and IsIconFrame(child) then

            local state = GetIconState(child)
            if child:IsShown() or state.hidden then
                table.insert(icons, child)
            end
        end
    end


    table.sort(icons, function(a, b)
        return GetStableFrameOrder(a) < GetStableFrameOrder(b)
    end)

    return icons
end


local function LayoutViewer(viewerName, trackerKey)
    local viewer = rawget(_G, viewerName)
    if not viewer then return end

    local settings = GetTrackerSettings(trackerKey)
    if not settings or not settings.enabled then return end


    if NCDM.applying[trackerKey] then return end
    if viewer.__cdmLayoutRunning then return end

    NCDM.applying[trackerKey] = true
    viewer.__cdmLayoutRunning = true


    local hudLayering = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.hudLayering
    local layerPriority = hudLayering and hudLayering[trackerKey] or 5
    if PREYCore and PREYCore.GetHUDFrameLevel then
        local frameLevel = PREYCore:GetHUDFrameLevel(layerPriority)
        viewer:SetFrameLevel(frameLevel)
    end


    local layoutDirection = settings.layoutDirection or "HORIZONTAL"
    local isVertical = (layoutDirection == "VERTICAL")


    viewer.__cdmLayoutDirection = layoutDirection

    local allIcons = CollectIcons(viewer)
    local totalCapacity = GetTotalIconCapacity(settings)


    local iconsToLayout = {}
    for i = 1, math.min(#allIcons, totalCapacity) do
        local icon = allIcons[i]
        iconsToLayout[i] = icon
        GetIconState(icon).hidden = nil
        icon:Show()
    end


    for i = totalCapacity + 1, #allIcons do
        local icon = allIcons[i]
        if icon then
            GetIconState(icon).hidden = true
            icon:Hide()
            icon:ClearAllPoints()
        end
    end

    if #iconsToLayout == 0 then
        NCDM.applying[trackerKey] = false
        viewer.__cdmLayoutRunning = nil
        return
    end


    local rows = {}
    for i = 1, 3 do
        local rowKey = "row" .. i
        if settings[rowKey] and settings[rowKey].iconCount and settings[rowKey].iconCount > 0 then

            MigrateRowAspect(settings[rowKey])
            table.insert(rows, {
                count = settings[rowKey].iconCount,
                size = settings[rowKey].iconSize or 50,
                borderSize = settings[rowKey].borderSize or 2,
                borderColorTable = settings[rowKey].borderColorTable or {0, 0, 0, 1},
                aspectRatioCrop = settings[rowKey].aspectRatioCrop or 1.0,
                zoom = settings[rowKey].zoom or 0,
                padding = settings[rowKey].padding or 0,
                yOffset = settings[rowKey].yOffset or 0,
                xOffset = settings[rowKey].xOffset or 0,
                durationSize = settings[rowKey].durationSize or 14,
                durationOffsetX = settings[rowKey].durationOffsetX or 0,
                durationOffsetY = settings[rowKey].durationOffsetY or 0,
                durationTextColor = settings[rowKey].durationTextColor or {1, 1, 1, 1},
                durationAnchor = settings[rowKey].durationAnchor or "CENTER",
                stackSize = settings[rowKey].stackSize or 14,
                stackOffsetX = settings[rowKey].stackOffsetX or 0,
                stackOffsetY = settings[rowKey].stackOffsetY or 0,
                stackTextColor = settings[rowKey].stackTextColor or {1, 1, 1, 1},
                stackAnchor = settings[rowKey].stackAnchor or "BOTTOMRIGHT",
                opacity = settings[rowKey].opacity or 1.0,
            })
        end
    end


    local potentialRow1Width = 0
    local potentialBottomRowWidth = 0
    if rows[1] then
        local iconWidth = rows[1].size
        local iconCount = rows[1].count
        local padding = rows[1].padding or 0
        potentialRow1Width = (iconCount * iconWidth) + ((iconCount - 1) * padding)
    end
    if rows[#rows] then
        local iconWidth = rows[#rows].size
        local iconCount = rows[#rows].count
        local padding = rows[#rows].padding or 0
        potentialBottomRowWidth = (iconCount * iconWidth) + ((iconCount - 1) * padding)
    end

    if #rows == 0 then
        NCDM.applying[trackerKey] = false
        viewer.__cdmLayoutRunning = nil
        return
    end


    local iconIndex = 1
    local maxRowWidth = 0
    local maxColHeight = 0
    local rowWidths = {}
    local colHeights = {}
    local tempIndex = 1
    local rowGap = 5

    for rowNum, rowConfig in ipairs(rows) do
        local iconsInRow = math.min(rowConfig.count, #iconsToLayout - tempIndex + 1)
        if iconsInRow <= 0 then break end

        local iconWidth = rowConfig.size
        local aspectRatio = rowConfig.aspectRatioCrop or 1.0
        local iconHeight = rowConfig.size / aspectRatio

        if isVertical then

            local colHeight = (iconsInRow * iconHeight) + ((iconsInRow - 1) * rowConfig.padding)
            colHeights[rowNum] = colHeight
            rowWidths[rowNum] = iconWidth
            if colHeight > maxColHeight then
                maxColHeight = colHeight
            end
        else

            local rowWidth = (iconsInRow * iconWidth) + ((iconsInRow - 1) * rowConfig.padding)
            rowWidths[rowNum] = rowWidth
            if rowWidth > maxRowWidth then
                maxRowWidth = rowWidth
            end
        end
        tempIndex = tempIndex + iconsInRow
    end


    local totalHeight = 0
    local totalWidth = 0
    local rowHeights = {}
    local numRowsUsed = 0
    local tempIdx = 1

    for rowNum, rowConfig in ipairs(rows) do
        local iconsInRow = math.min(rowConfig.count, #iconsToLayout - tempIdx + 1)
        if iconsInRow <= 0 then break end

        local aspectRatio = rowConfig.aspectRatioCrop or 1.0
        local iconHeight = rowConfig.size / aspectRatio
        local iconWidth = rowConfig.size
        rowHeights[rowNum] = iconHeight

        numRowsUsed = numRowsUsed + 1

        if isVertical then

            totalWidth = totalWidth + iconWidth
            if numRowsUsed > 1 then
                totalWidth = totalWidth + rowGap
            end
        else

            totalHeight = totalHeight + iconHeight
            if numRowsUsed > 1 then
                totalHeight = totalHeight + rowGap
            end
        end
        tempIdx = tempIdx + iconsInRow
    end


    if isVertical then
        totalHeight = maxColHeight
        maxRowWidth = totalWidth
    end


    local currentY = totalHeight / 2
    local currentX = -totalWidth / 2

    for rowNum, rowConfig in ipairs(rows) do
        local rowIcons = {}
        local iconsInRow = 0

        for i = 1, rowConfig.count do
            if iconIndex <= #iconsToLayout then
                table.insert(rowIcons, iconsToLayout[iconIndex])
                iconIndex = iconIndex + 1
                iconsInRow = iconsInRow + 1
            end
        end

        if iconsInRow == 0 then break end

        local aspectRatio = rowConfig.aspectRatioCrop or 1.0
        local iconWidth = rowConfig.size
        local iconHeight = rowConfig.size / aspectRatio
        local rowWidth = rowWidths[rowNum] or (iconsInRow * iconWidth) + ((iconsInRow - 1) * rowConfig.padding)
        local colHeight = colHeights[rowNum] or (iconsInRow * iconHeight) + ((iconsInRow - 1) * rowConfig.padding)

        for i, icon in ipairs(rowIcons) do
            local x, y

            if isVertical then


                local colCenterX = currentX + (iconWidth / 2)
                local colStartY = totalHeight / 2 - iconHeight / 2
                y = colStartY - ((i - 1) * (iconHeight + rowConfig.padding)) + rowConfig.yOffset
                x = colCenterX + (rowConfig.xOffset or 0)
            else


                local rowCenterY = currentY - (iconHeight / 2) + rowConfig.yOffset
                local rowStartX = -rowWidth / 2 + iconWidth / 2
                x = rowStartX + ((i - 1) * (iconWidth + rowConfig.padding)) + (rowConfig.xOffset or 0)
                y = rowCenterY
            end


            local state = GetIconState(icon)
            if not state.skinned and not state.skinPending then
                if InCombatLockdown() then

                    QueueIconForSkinning(icon, rowConfig.size, rowConfig.aspectRatioCrop, rowConfig.zoom,
                        rowConfig.borderSize, rowConfig.borderColorTable, rowConfig.durationSize, rowConfig.stackSize,
                        rowConfig.durationOffsetX, rowConfig.durationOffsetY,
                        rowConfig.stackOffsetX, rowConfig.stackOffsetY,
                        rowConfig.durationTextColor, rowConfig.durationAnchor,
                        rowConfig.stackTextColor, rowConfig.stackAnchor)
                else
                    local success = pcall(SkinIcon, icon, rowConfig.size, rowConfig.aspectRatioCrop, rowConfig.zoom, rowConfig.borderSize, rowConfig.borderColorTable)
                    if success then
                        pcall(ApplyIconTextSizes, icon, rowConfig.durationSize, rowConfig.stackSize,
                            rowConfig.durationOffsetX, rowConfig.durationOffsetY,
                            rowConfig.stackOffsetX, rowConfig.stackOffsetY,
                            rowConfig.durationTextColor, rowConfig.durationAnchor,
                            rowConfig.stackTextColor, rowConfig.stackAnchor)
                        state.skinned = true
                    end
                end
            end


            icon:ClearAllPoints()
            icon:SetPoint("CENTER", viewer, "CENTER", x, y)
            icon:Show()


            local opacity = rowConfig.opacity or 1.0
            icon:SetAlpha(opacity)
        end

        if isVertical then
            currentX = currentX + iconWidth + rowGap
        else
            currentY = currentY - iconHeight - rowGap
        end
    end


    viewer.__cdmIconWidth = maxRowWidth
    viewer.__cdmTotalHeight = totalHeight
    viewer.__cdmRow1BorderSize = rows[1] and rows[1].borderSize or 0
    viewer.__cdmBottomRowBorderSize = rows[#rows] and rows[#rows].borderSize or 0
    viewer.__cdmBottomRowYOffset = rows[#rows] and rows[#rows].yOffset or 0

    if isVertical then
        viewer.__cdmRow1Width = maxRowWidth
        viewer.__cdmBottomRowWidth = maxRowWidth
        viewer.__cdmPotentialRow1Width = maxRowWidth
        viewer.__cdmPotentialBottomRowWidth = maxRowWidth
    else
        viewer.__cdmRow1Width = rowWidths[1] or maxRowWidth
        viewer.__cdmBottomRowWidth = rowWidths[#rows] or maxRowWidth
        viewer.__cdmPotentialRow1Width = potentialRow1Width
        viewer.__cdmPotentialBottomRowWidth = potentialBottomRowWidth
    end


    if maxRowWidth > 0 and totalHeight > 0 then
        viewer.__cdmLayoutSuppressed = (viewer.__cdmLayoutSuppressed or 0) + 1
        pcall(function()
            viewer:SetSize(maxRowWidth, totalHeight)
        end)
        viewer.__cdmLayoutSuppressed = viewer.__cdmLayoutSuppressed - 1
        if viewer.__cdmLayoutSuppressed <= 0 then
            viewer.__cdmLayoutSuppressed = nil
        end

        if viewer.Selection then
            viewer.Selection:ClearAllPoints()
            viewer.Selection:SetPoint("TOPLEFT", viewer, "TOPLEFT", 0, 0)
            viewer.Selection:SetPoint("BOTTOMRIGHT", viewer, "BOTTOMRIGHT", 0, 0)
            viewer.Selection:SetFrameLevel(viewer:GetFrameLevel())
        end
    end

    NCDM.applying[trackerKey] = false
    viewer.__cdmLayoutRunning = nil


    if trackerKey == "essential" then
        local db = GetDB()
        if db and db.utility and db.utility.anchorBelowEssential then
            C_Timer.After(0.05, function()
                if _G.PreyUI_ApplyUtilityAnchor then
                    _G.PreyUI_ApplyUtilityAnchor()
                end
            end)
        end
    end


    if not viewer.__cdmUpdatePending then
        viewer.__cdmUpdatePending = true
        C_Timer.After(0.05, function()
            viewer.__cdmUpdatePending = nil
            if trackerKey == "essential" then
                if _G.PreyUI_UpdateLockedPowerBar then
                    _G.PreyUI_UpdateLockedPowerBar()
                end
                if _G.PreyUI_UpdateLockedSecondaryPowerBar then
                    _G.PreyUI_UpdateLockedSecondaryPowerBar()
                end
                if _G.PreyUI_UpdateLockedCastbarToEssential then
                    _G.PreyUI_UpdateLockedCastbarToEssential()
                end
            elseif trackerKey == "utility" then
                if _G.PreyUI_UpdateLockedPowerBarToUtility then
                    _G.PreyUI_UpdateLockedPowerBarToUtility()
                end
                if _G.PreyUI_UpdateLockedSecondaryPowerBarToUtility then
                    _G.PreyUI_UpdateLockedSecondaryPowerBarToUtility()
                end
                if _G.PreyUI_UpdateLockedCastbarToUtility then
                    _G.PreyUI_UpdateLockedCastbarToUtility()
                end
            end

            if _G.PreyUI_UpdateCDMAnchoredUnitFrames then
                _G.PreyUI_UpdateCDMAnchoredUnitFrames()
            end

            if _G.PreyUI_UpdateViewerKeybinds then
                _G.PreyUI_UpdateViewerKeybinds(viewerName)
            end
        end)
    end
end


local function HookViewer(viewerName, trackerKey)
    local viewer = rawget(_G, viewerName)
    if not viewer then return end
    if NCDM.hooked[trackerKey] then return end

    NCDM.hooked[trackerKey] = true


    viewer:HookScript("OnShow", function(self)

        if self.__ncdmUpdateFrame then
            self.__ncdmUpdateFrame:Show()
        end

        C_Timer.After(0.02, function()
            if self:IsShown() then
                LayoutViewer(viewerName, trackerKey)

                if trackerKey == "utility" and _G.PreyUI_ApplyUtilityAnchor then
                    _G.PreyUI_ApplyUtilityAnchor()
                end
            end
        end)
    end)


    viewer:HookScript("OnHide", function(self)
        if self.__ncdmUpdateFrame then
            self.__ncdmUpdateFrame:Hide()
        end
    end)


    viewer:HookScript("OnSizeChanged", function(self)

        self.__ncdmBlizzardLayoutCount = (self.__ncdmBlizzardLayoutCount or 0) + 1
        if self.__cdmLayoutSuppressed or self.__cdmLayoutRunning then
            return
        end
        LayoutViewer(viewerName, trackerKey)
    end)


    local updateFrame = CreateFrame("Frame")
    viewer.__ncdmUpdateFrame = updateFrame

    local lastIconCount = 0
    local lastSettingsVersion = 0
    local lastBlizzardLayoutCount = 0

    local combatInterval = 1.0
    local idleInterval = 0.5

    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        viewer.__ncdmElapsed = (viewer.__ncdmElapsed or 0) + elapsed


        local updateInterval = UnitAffectingCombat("player") and combatInterval or idleInterval


        if viewer.__ncdmEventFired then
            viewer.__ncdmEventFired = nil
            viewer.__ncdmElapsed = 0
        elseif viewer.__ncdmElapsed < updateInterval then
            return
        else
            viewer.__ncdmElapsed = 0
        end

        if NCDM.applying[trackerKey] then return end


        if InCombatLockdown() then return end


        local currentBlizzardCount = viewer.__ncdmBlizzardLayoutCount or 0
        local currentVersion = NCDM.settingsVersion[trackerKey] or 0


        local inGracePeriod = viewer.__ncdmGraceUntil and GetTime() < viewer.__ncdmGraceUntil
        if not inGracePeriod then

            if currentBlizzardCount == lastBlizzardLayoutCount and currentVersion == lastSettingsVersion then
                return
            end
        end

        if viewer.__ncdmGraceUntil and GetTime() >= viewer.__ncdmGraceUntil then
            viewer.__ncdmGraceUntil = nil
        end
        lastBlizzardLayoutCount = currentBlizzardCount


        local icons = {}
        for i = 1, viewer:GetNumChildren() do
            local child = select(i, viewer:GetChildren())
            if child and child ~= viewer.Selection and IsIconFrame(child) and child:IsShown() then
                table.insert(icons, child)
            end
        end
        local count = #icons

        local needsLayout = false


        if count ~= lastIconCount or currentVersion ~= lastSettingsVersion then
            needsLayout = true

            if currentVersion ~= lastSettingsVersion then
                for _, icon in ipairs(icons) do
                    local state = GetIconState(icon)
                    state.skinned = nil
                    state.skinPending = nil
                    NCDM.pendingIcons[icon] = nil
                end
            end
        end


        if not needsLayout and count > 0 then
            local firstIcon = icons[1]
            if firstIcon then
                local point = firstIcon:GetPoint(1)

                if point and point ~= "CENTER" then
                    needsLayout = true
                end
            end
        end

        if needsLayout then
            lastIconCount = count
            lastSettingsVersion = currentVersion
            LayoutViewer(viewerName, trackerKey)
        end
    end)


    if viewer:IsShown() then
        updateFrame:Show()
    else
        updateFrame:Hide()
    end


    local layoutEventFrame = CreateFrame("Frame")
    layoutEventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    layoutEventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
    layoutEventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    layoutEventFrame:SetScript("OnEvent", function()

        if InCombatLockdown() then return end

        if viewer:IsShown() then
            viewer.__ncdmEventFired = true
        end
    end)


    if viewer.__pendingTicker then
        viewer.__pendingTicker:Cancel()
        viewer.__pendingTicker = nil
    end


    C_Timer.After(0.02, function()
        LayoutViewer(viewerName, trackerKey)
    end)
end


local function IncrementSettingsVersion(trackerKey)
    if trackerKey then
        NCDM.settingsVersion[trackerKey] = (NCDM.settingsVersion[trackerKey] or 0) + 1
    else

        NCDM.settingsVersion["essential"] = (NCDM.settingsVersion["essential"] or 0) + 1
        NCDM.settingsVersion["utility"] = (NCDM.settingsVersion["utility"] or 0) + 1
    end
end


local function RefreshAll()
    UpdateCooldownViewerCVar()
    NCDM.applying["essential"] = false
    NCDM.applying["utility"] = false


    IncrementSettingsVersion()


    C_Timer.After(0.01, function()
        LayoutViewer(VIEWER_ESSENTIAL, "essential")
    end)
    C_Timer.After(0.02, function()
        LayoutViewer(VIEWER_UTILITY, "utility")
    end)

    C_Timer.After(0.03, function()
        LayoutViewer(VIEWER_ESSENTIAL, "essential")
    end)
    C_Timer.After(0.04, function()
        LayoutViewer(VIEWER_UTILITY, "utility")

        if _G.PreyUI_ApplyUtilityAnchor then
            _G.PreyUI_ApplyUtilityAnchor()
        end
    end)


    C_Timer.After(0.10, function()

        if _G.PreyUI_UpdateLockedPowerBar then
            _G.PreyUI_UpdateLockedPowerBar()
        end
        if _G.PreyUI_UpdateLockedSecondaryPowerBar then
            _G.PreyUI_UpdateLockedSecondaryPowerBar()
        end
        if _G.PreyUI_UpdateLockedCastbarToEssential then
            _G.PreyUI_UpdateLockedCastbarToEssential()
        end

        if _G.PreyUI_UpdateLockedPowerBarToUtility then
            _G.PreyUI_UpdateLockedPowerBarToUtility()
        end
        if _G.PreyUI_UpdateLockedSecondaryPowerBarToUtility then
            _G.PreyUI_UpdateLockedSecondaryPowerBarToUtility()
        end
        if _G.PreyUI_UpdateLockedCastbarToUtility then
            _G.PreyUI_UpdateLockedCastbarToUtility()
        end

        if _G.PreyUI_UpdateCDMAnchoredUnitFrames then
            _G.PreyUI_UpdateCDMAnchoredUnitFrames()
        end
    end)
end


local function ApplyUtilityAnchor()
    local db = GetDB()
    if not db or not db.utility then return end

    local utilSettings = db.utility
    local utilViewer = rawget(_G, VIEWER_UTILITY)
    if not utilViewer then return end

    if not utilSettings.anchorBelowEssential then
        utilViewer.__cdmAnchoredToEssential = nil
        return
    end

    local essViewer = rawget(_G, VIEWER_ESSENTIAL)
    if not essViewer then return end

    local utilityTopBorder = utilSettings.row1 and utilSettings.row1.borderSize or 0
    local totalOffset = (utilSettings.anchorGap or 0) - utilityTopBorder

    utilViewer:ClearAllPoints()
    utilViewer:SetPoint("TOP", essViewer, "BOTTOM", 0, -totalOffset)
    utilViewer.__cdmAnchoredToEssential = true
end

_G.PreyUI_RefreshNCDM = RefreshAll
_G.PreyUI_IncrementNCDMVersion = IncrementSettingsVersion
_G.PreyUI_ApplyUtilityAnchor = ApplyUtilityAnchor


local function ForceLoadCDM()
    local settingsFrame = rawget(_G, "CooldownViewerSettings")
    if settingsFrame then
        settingsFrame:Show()
        settingsFrame:Raise()


        C_Timer.After(1.5, function()
            if settingsFrame and settingsFrame:IsShown() then
                settingsFrame:Hide()
            end
        end)
    end
end


local function Initialize()
    if NCDM.initialized then return end
    NCDM.initialized = true

    if rawget(_G, VIEWER_ESSENTIAL) then
        HookViewer(VIEWER_ESSENTIAL, "essential")
    end

    if rawget(_G, VIEWER_UTILITY) then
        HookViewer(VIEWER_UTILITY, "utility")
    end


    C_Timer.After(2.5, RefreshAll)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then

        C_Timer.After(0.3, ForceLoadCDM)
        C_Timer.After(0.5, Initialize)
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...


        if not isLogin and not isReload then

            for _, viewerName in ipairs({VIEWER_ESSENTIAL, VIEWER_UTILITY}) do
                local viewer = rawget(_G, viewerName)
                if viewer then
                    viewer.__ncdmGraceUntil = GetTime() + 2.0

                    for i = 1, viewer:GetNumChildren() do
                        local child = select(i, viewer:GetChildren())
                        if child and child ~= viewer.Selection then
                            local state = GetIconState(child)
                            state.skinned = nil
                            state.skinPending = nil
                        end
                    end
                end
            end
            C_Timer.After(0.3, RefreshAll)
        end
    elseif event == "CHALLENGE_MODE_START" then

        for _, viewerName in ipairs({VIEWER_ESSENTIAL, VIEWER_UTILITY}) do
            local viewer = rawget(_G, viewerName)
            if viewer then
                viewer.__ncdmGraceUntil = GetTime() + 2.0
            end
        end
        C_Timer.After(0.5, RefreshAll)
    end
end)

C_Timer.After(0, function()
    if rawget(_G, VIEWER_ESSENTIAL) or rawget(_G, VIEWER_UTILITY) then
        Initialize()
    end
end)


local function IsPlayerInGroup()
    return IsInGroup() or IsInRaid()
end


local HOUSING_INSTANCE_TYPES = {
    ["neighborhood"] = true,
    ["interior"] = true,
}


local function IsPlayerInInstance()
    local _, instanceType = GetInstanceInfo()
    if instanceType == "none" or instanceType == nil then
        return false
    end

    if HOUSING_INSTANCE_TYPES[instanceType] then
        return false
    end
    return true
end


local CDMVisibility = {
    currentlyHidden = false,
    isFading = false,
    fadeStart = 0,
    fadeStartAlpha = 1,
    fadeTargetAlpha = 1,
    fadeFrame = nil,
    mouseOver = false,
    mouseoverDetector = nil,
    hoverCount = 0,
    leaveTimer = nil,
}


local function GetCDMFrames()
    local frames = {}


    if _G.EssentialCooldownViewer then
        table.insert(frames, _G.EssentialCooldownViewer)
    end
    if _G.UtilityCooldownViewer then
        table.insert(frames, _G.UtilityCooldownViewer)
    end
    if _G.BuffIconCooldownViewer then
        table.insert(frames, _G.BuffIconCooldownViewer)
    end
    if _G.BuffBarCooldownViewer then
        table.insert(frames, _G.BuffBarCooldownViewer)
    end


    if PREYCore then
        if PREYCore.powerBar then
            table.insert(frames, PREYCore.powerBar)
        end
        if PREYCore.secondaryPowerBar then
            table.insert(frames, PREYCore.secondaryPowerBar)
        end
    end

    return frames
end


local function GetCDMVisibilitySettings()
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.cdmVisibility then
        return PREYCore.db.profile.cdmVisibility
    end
    return nil
end


local function ShouldCDMBeVisible()
    local vis = GetCDMVisibilitySettings()
    if not vis then return true end


    if vis.hideWhenMounted and (IsMounted() or GetShapeshiftFormID() == 27) then return false end


    if vis.showAlways then return true end


    if vis.showWhenTargetExists and UnitExists("target") then return true end
    if vis.showInCombat and UnitAffectingCombat("player") then return true end
    if vis.showInGroup and IsPlayerInGroup() then return true end
    if vis.showInInstance and IsPlayerInInstance() then return true end
    if vis.showOnMouseover and CDMVisibility.mouseOver then return true end

    return false
end


local function OnCDMFadeUpdate(self, elapsed)
    local vis = GetCDMVisibilitySettings()
    local duration = (vis and vis.fadeDuration) or 0.2

    local now = GetTime()
    local elapsedTime = now - CDMVisibility.fadeStart
    local progress = math.min(elapsedTime / duration, 1)


    local alpha = CDMVisibility.fadeStartAlpha +
        (CDMVisibility.fadeTargetAlpha - CDMVisibility.fadeStartAlpha) * progress


    local frames = GetCDMFrames()
    for _, frame in ipairs(frames) do
        frame:SetAlpha(alpha)
    end


    if progress >= 1 then
        CDMVisibility.isFading = false
        CDMVisibility.currentlyHidden = (CDMVisibility.fadeTargetAlpha < 1)
        self:SetScript("OnUpdate", nil)
    end
end


local function StartCDMFade(targetAlpha)
    local frames = GetCDMFrames()
    if #frames == 0 then return end


    local currentAlpha = frames[1]:GetAlpha()


    if math.abs(currentAlpha - targetAlpha) < 0.01 then
        CDMVisibility.currentlyHidden = (targetAlpha < 1)
        return
    end

    CDMVisibility.isFading = true
    CDMVisibility.fadeStart = GetTime()
    CDMVisibility.fadeStartAlpha = currentAlpha
    CDMVisibility.fadeTargetAlpha = targetAlpha


    if not CDMVisibility.fadeFrame then
        CDMVisibility.fadeFrame = CreateFrame("Frame")
    end
    CDMVisibility.fadeFrame:SetScript("OnUpdate", OnCDMFadeUpdate)
end


local function UpdateCDMVisibility()
    local shouldShow = ShouldCDMBeVisible()
    local vis = GetCDMVisibilitySettings()

    if shouldShow then
        StartCDMFade(1)
    else
        StartCDMFade(vis and vis.fadeOutAlpha or 0)
    end
end


HookFrameForMouseover = function(frame)
    if not frame or frame._preyMouseoverHooked then return end

    frame._preyMouseoverHooked = true

    frame:HookScript("OnEnter", function()
        local vis = GetCDMVisibilitySettings()
        if not vis or vis.showAlways or not vis.showOnMouseover then return end


        if CDMVisibility.leaveTimer then
            CDMVisibility.leaveTimer:Cancel()
            CDMVisibility.leaveTimer = nil
        end

        CDMVisibility.hoverCount = CDMVisibility.hoverCount + 1
        if CDMVisibility.hoverCount == 1 then
            CDMVisibility.mouseOver = true
            UpdateCDMVisibility()
        end
    end)

    frame:HookScript("OnLeave", function()
        local vis = GetCDMVisibilitySettings()
        if not vis or vis.showAlways or not vis.showOnMouseover then return end

        CDMVisibility.hoverCount = math.max(0, CDMVisibility.hoverCount - 1)

        if CDMVisibility.hoverCount == 0 then

            if CDMVisibility.leaveTimer then
                CDMVisibility.leaveTimer:Cancel()
            end


            CDMVisibility.leaveTimer = C_Timer.After(0.5, function()
                CDMVisibility.leaveTimer = nil

                if CDMVisibility.hoverCount == 0 then
                    CDMVisibility.mouseOver = false
                    UpdateCDMVisibility()
                end
            end)
        end
    end)
end


local function SetupCDMMouseoverDetector()
    local vis = GetCDMVisibilitySettings()


    if CDMVisibility.mouseoverDetector then
        CDMVisibility.mouseoverDetector:SetScript("OnUpdate", nil)
        CDMVisibility.mouseoverDetector:Hide()
        CDMVisibility.mouseoverDetector = nil
    end


    if CDMVisibility.leaveTimer then
        CDMVisibility.leaveTimer:Cancel()
        CDMVisibility.leaveTimer = nil
    end

    CDMVisibility.mouseOver = false
    CDMVisibility.hoverCount = 0


    if not vis or vis.showAlways or not vis.showOnMouseover then
        return
    end


    local cdmFrames = GetCDMFrames()
    for _, frame in ipairs(cdmFrames) do
        HookFrameForMouseover(frame)
    end


    local viewers = {"EssentialCooldownViewer", "UtilityCooldownViewer", "BuffIconCooldownViewer", "BuffBarCooldownViewer"}
    for _, viewerName in ipairs(viewers) do
        local viewer = rawget(_G, viewerName)
        if viewer then
            local icons = CollectIcons(viewer)
            for _, icon in ipairs(icons) do
                HookFrameForMouseover(icon)
            end
        end
    end


    local detector = CreateFrame("Frame", nil, UIParent)
    detector:EnableMouse(false)
    CDMVisibility.mouseoverDetector = detector
end


local UnitframesVisibility = {
    currentlyHidden = false,
    isFading = false,
    fadeStart = 0,
    fadeStartAlpha = 1,
    fadeTargetAlpha = 1,
    fadeFrame = nil,
    mouseOver = false,
    mouseoverDetector = nil,
}


local function GetUnitframesVisibilitySettings()
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.unitframesVisibility then
        return PREYCore.db.profile.unitframesVisibility
    end
    return nil
end


local function GetUnitframeFrames()
    local frames = {}


    if _G.PreyUI_UnitFrames then
        for unitKey, frame in pairs(_G.PreyUI_UnitFrames) do
            if frame then
                table.insert(frames, frame)
            end
        end
    end


    local vis = GetUnitframesVisibilitySettings()
    if not (vis and vis.alwaysShowCastbars) then
        if _G.PreyUI_Castbars then
            for unitKey, castbar in pairs(_G.PreyUI_Castbars) do
                if castbar then
                    table.insert(frames, castbar)
                end
            end
        end
    end

    return frames
end


local function ShouldUnitframesBeVisible()
    local vis = GetUnitframesVisibilitySettings()
    if not vis then return true end


    if vis.hideWhenMounted and (IsMounted() or GetShapeshiftFormID() == 27) then return false end


    if vis.showAlways then return true end


    if vis.showWhenTargetExists and UnitExists("target") then return true end
    if vis.showInCombat and UnitAffectingCombat("player") then return true end
    if vis.showInGroup and IsPlayerInGroup() then return true end
    if vis.showInInstance and IsPlayerInInstance() then return true end
    if vis.showOnMouseover and UnitframesVisibility.mouseOver then return true end

    return false
end


local function OnUnitframesFadeUpdate(self, elapsed)
    local vis = GetUnitframesVisibilitySettings()
    local duration = (vis and vis.fadeDuration) or 0.2

    local now = GetTime()
    local elapsedTime = now - UnitframesVisibility.fadeStart
    local progress = math.min(elapsedTime / duration, 1)


    local alpha = UnitframesVisibility.fadeStartAlpha +
        (UnitframesVisibility.fadeTargetAlpha - UnitframesVisibility.fadeStartAlpha) * progress


    local frames = GetUnitframeFrames()
    for _, frame in ipairs(frames) do
        frame:SetAlpha(alpha)
    end


    if progress >= 1 then
        UnitframesVisibility.isFading = false
        UnitframesVisibility.currentlyHidden = (UnitframesVisibility.fadeTargetAlpha < 1)
        self:SetScript("OnUpdate", nil)
    end
end


local function StartUnitframesFade(targetAlpha)
    local frames = GetUnitframeFrames()
    if #frames == 0 then return end


    local currentAlpha = frames[1]:GetAlpha()


    if math.abs(currentAlpha - targetAlpha) < 0.01 then
        UnitframesVisibility.currentlyHidden = (targetAlpha < 1)
        return
    end

    UnitframesVisibility.isFading = true
    UnitframesVisibility.fadeStart = GetTime()
    UnitframesVisibility.fadeStartAlpha = currentAlpha
    UnitframesVisibility.fadeTargetAlpha = targetAlpha


    if not UnitframesVisibility.fadeFrame then
        UnitframesVisibility.fadeFrame = CreateFrame("Frame")
    end
    UnitframesVisibility.fadeFrame:SetScript("OnUpdate", OnUnitframesFadeUpdate)
end


local function UpdateUnitframesVisibility()
    local vis = GetUnitframesVisibilitySettings()
    local shouldShow = ShouldUnitframesBeVisible()


    if _G.PreyUI_Castbars then
        local targetAlpha = 1

        if vis and vis.alwaysShowCastbars then
            targetAlpha = 1
        else

            if _G.PreyUI_UnitFrames then
                for _, frame in pairs(_G.PreyUI_UnitFrames) do
                    if frame then
                        targetAlpha = frame:GetAlpha()
                        break
                    end
                end
            end
        end

        for unitKey, castbar in pairs(_G.PreyUI_Castbars) do
            if castbar then
                castbar:SetAlpha(targetAlpha)
            end
        end
    end

    if shouldShow then
        StartUnitframesFade(1)
    else
        StartUnitframesFade(vis and vis.fadeOutAlpha or 0)
    end
end


local function SetupUnitframesMouseoverDetector()
    local vis = GetUnitframesVisibilitySettings()


    if UnitframesVisibility.mouseoverDetector then
        UnitframesVisibility.mouseoverDetector:SetScript("OnUpdate", nil)
        UnitframesVisibility.mouseoverDetector:Hide()
        UnitframesVisibility.mouseoverDetector = nil
    end
    UnitframesVisibility.mouseOver = false


    if not vis or vis.showAlways or not vis.showOnMouseover then
        return
    end


    local ufFrames = GetUnitframeFrames()
    local hoverCount = 0

    for _, frame in ipairs(ufFrames) do
        if frame and not frame._preyMouseoverHooked then
            frame._preyMouseoverHooked = true


            frame:HookScript("OnEnter", function()
                hoverCount = hoverCount + 1
                if hoverCount == 1 then
                    UnitframesVisibility.mouseOver = true
                    UpdateUnitframesVisibility()
                end
            end)


            frame:HookScript("OnLeave", function()
                hoverCount = math.max(0, hoverCount - 1)
                if hoverCount == 0 then
                    UnitframesVisibility.mouseOver = false
                    UpdateUnitframesVisibility()
                end
            end)
        end
    end


    local detector = CreateFrame("Frame", nil, UIParent)
    detector:EnableMouse(false)
    UnitframesVisibility.mouseoverDetector = detector
end


local visibilityEventFrame = CreateFrame("Frame")
visibilityEventFrame:RegisterEvent("PLAYER_LOGIN")
visibilityEventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
visibilityEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
visibilityEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
visibilityEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
visibilityEventFrame:RegisterEvent("GROUP_JOINED")
visibilityEventFrame:RegisterEvent("GROUP_LEFT")
visibilityEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
visibilityEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
visibilityEventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
visibilityEventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")

visibilityEventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then

        C_Timer.After(1.5, function()
            SetupCDMMouseoverDetector()
            SetupUnitframesMouseoverDetector()
            UpdateCDMVisibility()
            UpdateUnitframesVisibility()
        end)
    else

        UpdateCDMVisibility()
        UpdateUnitframesVisibility()
    end
end)


_G.PreyUI_RefreshCDMVisibility = UpdateCDMVisibility
_G.PreyUI_RefreshUnitframesVisibility = UpdateUnitframesVisibility
_G.PreyUI_RefreshCDMMouseover = SetupCDMMouseoverDetector
_G.PreyUI_RefreshUnitframesMouseover = SetupUnitframesMouseoverDetector


NCDM.Refresh = RefreshAll
NCDM.LayoutViewer = LayoutViewer
ns.NCDM = NCDM
