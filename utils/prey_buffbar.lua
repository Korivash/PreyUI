local ADDON_NAME, ns = ...
local PREYCore = ns.Addon
local LSM = LibStub("LibSharedMedia-3.0")


local PREY_BuffBar = {}
ns.BuffBar = PREY_BuffBar


local IconMeta = setmetatable({}, { __mode = "k" })
local BarMeta = setmetatable({}, { __mode = "k" })
local TextureMeta = setmetatable({}, { __mode = "k" })
local ViewerMeta = setmetatable({}, { __mode = "k" })
local FrameOrderMeta = setmetatable({}, { __mode = "k" })
local nextFrameOrder = 0

local function GetIconMeta(icon)
    if not icon then return nil end
    local meta = IconMeta[icon]
    if not meta then
        meta = {}
        IconMeta[icon] = meta
    end
    return meta
end

local function GetBarMeta(frame)
    if not frame then return nil end
    local meta = BarMeta[frame]
    if not meta then
        meta = {}
        BarMeta[frame] = meta
    end
    return meta
end

local function GetViewerMeta(viewer)
    if not viewer then return nil end
    local meta = ViewerMeta[viewer]
    if not meta then
        meta = {}
        ViewerMeta[viewer] = meta
    end
    return meta
end

local function GetStableFrameOrder(frame)
    if not frame then return math.huge end
    local order = FrameOrderMeta[frame]
    if not order then
        nextFrameOrder = nextFrameOrder + 1
        order = nextFrameOrder
        FrameOrderMeta[frame] = order
    end
    return order
end


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


local floor = math.floor

local function roundPixel(value)
    if not value then return 0 end
    return floor(value + 0.5)
end


local abs = math.abs
local function PositionMatchesTolerance(icon, expectedX, tolerance)
    if not icon then return false end
    local point, _, _, xOfs = icon:GetPoint(1)
    if not point then return false end
    return abs((xOfs or 0) - expectedX) <= (tolerance or 2)
end


local function GetDB()
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.ncdm then
        return PREYCore.db.profile.ncdm
    end
    return nil
end

local function GetBuffSettings()
    local db = GetDB()
    if db and db.buff then
        local buff = db.buff

        if buff.aspectRatioCrop == nil and buff.shape then
            if buff.shape == "rectangle" or buff.shape == "flat" then
                buff.aspectRatioCrop = 1.33
            else
                buff.aspectRatioCrop = 1.0
            end
        end
        return buff
    end

    return {
        enabled = true,
        iconSize = 42,
        borderSize = 2,
        aspectRatioCrop = 1.0,
        zoom = 0,
        padding = 0,
        opacity = 1.0,
    }
end

local function GetTrackedBarSettings()
    local db = GetDB()
    if db and db.trackedBar then
        return db.trackedBar
    end

    return {
        enabled = true,
        barHeight = 24,
        barWidth = 200,
        texture = "Prey v5",
        useClassColor = true,
        barColor = {0.820, 0.180, 0.220, 1},
        barOpacity = 1.0,
        borderSize = 1,
        bgColor = {0, 0, 0, 1},
        bgOpacity = 0.7,
        textSize = 12,
        spacing = 4,
        growUp = true,
        hideText = false,

        orientation = "horizontal",
        fillDirection = "up",
        iconPosition = "top",
        showTextOnVertical = false,
    }
end


local LayoutBuffIcons
local LayoutBuffBars


local isIconLayoutRunning = false
local isBarLayoutRunning = false


local layoutSuppressed = 0

local function SuppressLayout()
    layoutSuppressed = layoutSuppressed + 1
end

local function UnsuppressLayout()
    layoutSuppressed = math.max(0, layoutSuppressed - 1)
end

local function IsLayoutSuppressed()
    return layoutSuppressed > 0
end


local function GetBuffIconFrames()
    if not BuffIconCooldownViewer then
        return {}
    end

    local all = {}

    for _, child in ipairs({ BuffIconCooldownViewer:GetChildren() }) do
        if child then

            if child == BuffIconCooldownViewer.Selection then

            else
                local hasIcon = child.icon or child.Icon
                local hasCooldown = child.cooldown or child.Cooldown

                if hasIcon or hasCooldown then
                    table.insert(all, child)
                end
            end
        end
    end

    table.sort(all, function(a, b)
        return GetStableFrameOrder(a) < GetStableFrameOrder(b)
    end)


    local visible = {}
    for _, icon in ipairs(all) do
        if icon:IsShown() and (icon.icon or icon.Icon) and (icon.cooldown or icon.Cooldown) then
            table.insert(visible, icon)
        end
    end

    return visible
end


local function GetBuffBarFrames()
    if not BuffBarCooldownViewer then
        return {}
    end

    local frames = {}


    if BuffBarCooldownViewer.GetItemFrames then
        local ok, items = pcall(BuffBarCooldownViewer.GetItemFrames, BuffBarCooldownViewer)
        if ok and items then
            frames = items
        end
    end


    if #frames == 0 then
        local okc, children = pcall(BuffBarCooldownViewer.GetChildren, BuffBarCooldownViewer)
        if okc and children then
            for _, child in ipairs({ children }) do
                if child and child:IsObjectType("Frame") then

                    if child ~= BuffBarCooldownViewer.Selection then
                        table.insert(frames, child)
                    end
                end
            end
        end
    end


    local active = {}
    for _, frame in ipairs(frames) do
        if frame:IsShown() and frame:IsVisible() then
            table.insert(active, frame)
        end
    end

    table.sort(active, function(a, b)
        return GetStableFrameOrder(a) < GetStableFrameOrder(b)
    end)

    return active
end


local function StripBlizzardOverlay(icon)
    if not icon or not icon.GetRegions then return end

    for _, region in ipairs({ icon:GetRegions() }) do
        if region:IsObjectType("Texture") then

            if region.GetAtlas then
                local atlas = region:GetAtlas()
                if atlas == "UI-HUD-CoolDownManager-IconOverlay" then
                    region:SetTexture("")
                    region:Hide()
                    region.Show = function() end
                end
            end
        end
    end
end


local function DisableAtlasBorder(tex)
    if not tex then return end


    if tex.SetAtlas then tex:SetAtlas(nil) end
    if tex.SetTexture then tex:SetTexture(nil) end
    if tex.SetAlpha then tex:SetAlpha(0) end
    if tex.Hide then tex:Hide() end


    if tex.SetAtlas and not TextureMeta[tex] then
        TextureMeta[tex] = true
        hooksecurefunc(tex, "SetAtlas", function(self)
            C_Timer.After(0, function()

                if not self or (self.IsForbidden and self:IsForbidden()) then return end

                pcall(function()
                    self:SetAtlas(nil)
                    self:SetTexture(nil)
                    self:SetAlpha(0)
                    self:Hide()
                end)
            end)
        end)
    end
end


local function SetupIconOnce(icon)
    local meta = GetIconMeta(icon)
    if meta.setupDone then return end


    local textures = { icon.Icon, icon.icon, icon.texture, icon.Texture }
    for _, tex in ipairs(textures) do
        if tex and tex.GetMaskTexture then
            for i = 1, 10 do
                local mask = tex:GetMaskTexture(i)
                if mask then
                    tex:RemoveMaskTexture(mask)
                end
            end
        end
    end


    if icon.NormalTexture then icon.NormalTexture:SetAlpha(0) end
    if icon.GetNormalTexture then
        local normalTex = icon:GetNormalTexture()
        if normalTex then normalTex:SetAlpha(0) end
    end


    StripBlizzardOverlay(icon)


    DisableAtlasBorder(icon.DebuffBorder)
    DisableAtlasBorder(icon.BuffBorder)
    DisableAtlasBorder(icon.TempEnchantBorder)

    meta.setupDone = true
end


local function ApplyIconStyle(icon, settings)
    if not icon then return end

    SetupIconOnce(icon)

    local size = settings.iconSize or 42
    local aspectRatio = settings.aspectRatioCrop or 1.0
    local zoom = settings.zoom or 0
    local borderSize = settings.borderSize or 2


    local width, height = size, size
    if aspectRatio > 1.0 then

        height = size / aspectRatio
    elseif aspectRatio < 1.0 then

        width = size * aspectRatio
    end

    icon:SetSize(width, height)


    local meta = GetIconMeta(icon)
    if borderSize > 0 then
        if not meta.borderTexture then
            meta.borderTexture = icon:CreateTexture(nil, "BACKGROUND", nil, -8)
            meta.borderTexture:SetColorTexture(0, 0, 0, 1)
        end

        meta.borderTexture:ClearAllPoints()
        meta.borderTexture:SetPoint("TOPLEFT", icon, "TOPLEFT", -borderSize, borderSize)
        meta.borderTexture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", borderSize, -borderSize)
        meta.borderTexture:Show()
        meta.borderSize = borderSize
    else
        if meta.borderTexture then
            meta.borderTexture:Hide()
        end
        meta.borderSize = 0
    end


    local BASE_CROP = 0.08
    local left, right, top, bottom = BASE_CROP, 1 - BASE_CROP, BASE_CROP, 1 - BASE_CROP


    if aspectRatio > 1.0 then

        local cropAmount = 1.0 - (1.0 / aspectRatio)
        local availableHeight = bottom - top
        local offset = (cropAmount * availableHeight) / 2.0
        top = top + offset
        bottom = bottom - offset
    elseif aspectRatio < 1.0 then

        local cropAmount = 1.0 - aspectRatio
        local availableWidth = right - left
        local offset = (cropAmount * availableWidth) / 2.0
        left = left + offset
        right = right - offset
    end


    if zoom > 0 then
        local centerX = (left + right) / 2.0
        local centerY = (top + bottom) / 2.0
        local currentWidth = right - left
        local currentHeight = bottom - top
        local visibleSize = 1.0 - (zoom * 2)
        left = centerX - (currentWidth * visibleSize / 2.0)
        right = centerX + (currentWidth * visibleSize / 2.0)
        top = centerY - (currentHeight * visibleSize / 2.0)
        bottom = centerY + (currentHeight * visibleSize / 2.0)
    end

    local function ProcessTexture(tex)
        if not tex then return end
        tex:ClearAllPoints()
        tex:SetAllPoints(icon)
        if tex.SetTexCoord then
            tex:SetTexCoord(left, right, top, bottom)
        end
    end


    ProcessTexture(icon.Icon)
    ProcessTexture(icon.icon)
    ProcessTexture(icon.texture)
    ProcessTexture(icon.Texture)


    local cooldown = icon.Cooldown or icon.cooldown
    if cooldown then
        cooldown:ClearAllPoints()
        cooldown:SetAllPoints(icon)

        cooldown:SetSwipeTexture("Interface\\Buttons\\WHITE8X8")
        cooldown:SetSwipeColor(0, 0, 0, 0.8)


        local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
        local showBuffIconSwipe = PREYCore and PREYCore.db and PREYCore.db.profile.cooldownSwipe
            and PREYCore.db.profile.cooldownSwipe.showBuffIconSwipe or false
        if cooldown.SetDrawSwipe then
            cooldown:SetDrawSwipe(showBuffIconSwipe)
        end
        if cooldown.SetDrawEdge then
            cooldown:SetDrawEdge(showBuffIconSwipe)
        end
    end


    if icon.CooldownFlash then
        icon.CooldownFlash:ClearAllPoints()
        icon.CooldownFlash:SetAllPoints(icon)
    end


    local durationSize = settings.durationSize or 12
    local stackSize = settings.stackSize or 12
    local durationOffsetX = settings.durationOffsetX or 0
    local durationOffsetY = settings.durationOffsetY or 0
    local durationAnchor = settings.durationAnchor or "CENTER"
    local stackOffsetX = settings.stackOffsetX or 0
    local stackOffsetY = settings.stackOffsetY or 0
    local stackAnchor = settings.stackAnchor or "BOTTOMRIGHT"


    local generalFont = GetGeneralFont()
    local generalOutline = GetGeneralFontOutline()


    if cooldown and durationSize then

        if cooldown.text then
            cooldown.text:SetFont(generalFont, durationSize, generalOutline)
            pcall(function()
                cooldown.text:ClearAllPoints()
                cooldown.text:SetPoint(durationAnchor, icon, durationAnchor, durationOffsetX, durationOffsetY)
            end)
        end


        for _, region in ipairs({ cooldown:GetRegions() }) do
            if region:GetObjectType() == "FontString" then
                region:SetFont(generalFont, durationSize, generalOutline)
                pcall(function()
                    region:ClearAllPoints()
                    region:SetPoint(durationAnchor, icon, durationAnchor, durationOffsetX, durationOffsetY)
                end)
            end
        end
    end


    local fs = nil


    local charge = icon.ChargeCount
    if charge then
        fs = charge.Current or charge.Text or charge.Count or nil
        if not fs and charge.GetRegions then
            for _, region in ipairs({ charge:GetRegions() }) do
                if region:GetObjectType() == "FontString" then
                    fs = region
                    break
                end
            end
        end
    end


    if not fs then
        local apps = icon.Applications
        if apps and apps.GetRegions then
            for _, region in ipairs({ apps:GetRegions() }) do
                if region:GetObjectType() == "FontString" then
                    fs = region
                    break
                end
            end
        end
    end


    if not fs and icon.GetRegions then
        for _, region in ipairs({ icon:GetRegions() }) do
            if region:GetObjectType() == "FontString" then
                local name = region:GetName()
                if name and (name:find("Stack") or name:find("Applications") or name:find("Count")) then
                    fs = region
                    break
                end
            end
        end
    end


    if fs and stackSize then
        fs:SetFont(generalFont, stackSize, generalOutline)
        pcall(function()
            fs:ClearAllPoints()
            fs:SetPoint(stackAnchor, icon, stackAnchor, stackOffsetX, stackOffsetY)
        end)
    end


    local opacity = settings.opacity or 1.0
    icon:SetAlpha(opacity)
end


local function ApplyBarStyle(frame, settings)
    if not frame then return end
    if frame.IsForbidden and frame:IsForbidden() then return end

    local barHeight = settings.barHeight or 24
    local barWidth = settings.barWidth or 200
    local texture = settings.texture or "Prey v5"
    local useClassColor = settings.useClassColor
    local barColor = settings.barColor or {0.820, 0.180, 0.220, 1}
    local barOpacity = settings.barOpacity or 1.0
    local borderSize = settings.borderSize or 1
    local bgColor = settings.bgColor or {0, 0, 0, 1}
    local bgOpacity = settings.bgOpacity or 0.7
    local textSize = settings.textSize or 12
    local hideIcon = settings.hideIcon
    local hideText = settings.hideText


    local orientation = settings.orientation or "horizontal"
    local isVertical = (orientation == "vertical")
    local fillDirection = settings.fillDirection or "up"
    local iconPosition = settings.iconPosition or "top"
    local showTextOnVertical = settings.showTextOnVertical or false


    local frameWidth, frameHeight
    if isVertical then
        frameWidth = barHeight
        frameHeight = barWidth
    else
        frameWidth = barWidth
        frameHeight = barHeight
    end


    local statusBar = frame.Bar
    if not statusBar and frame.GetChildren then
        local okC, children = pcall(frame.GetChildren, frame)
        if okC and children then
            for _, child in ipairs({children}) do
                if child and child.IsObjectType and child:IsObjectType("StatusBar") then
                    statusBar = child
                    break
                end
            end
        end
    end


    if statusBar and statusBar.GetRegions then
        pcall(function()
            local mainTex = statusBar:GetStatusBarTexture()
            for _, region in ipairs({statusBar:GetRegions()}) do
                if region and region:IsObjectType("Texture") and region ~= mainTex then
                    region:SetTexture(nil)
                    region:Hide()
                end
            end
        end)
    end


    DisableAtlasBorder(frame.DebuffBorder)
    DisableAtlasBorder(frame.BuffBorder)
    DisableAtlasBorder(frame.TempEnchantBorder)


    pcall(function()
        frame:SetHeight(frameHeight)
        frame:SetWidth(frameWidth)
        if statusBar then
            statusBar:SetHeight(frameHeight)
            statusBar:SetWidth(frameWidth)

            if statusBar.SetOrientation then
                statusBar:SetOrientation(isVertical and "VERTICAL" or "HORIZONTAL")
            end

            if isVertical and statusBar.SetReverseFill then
                statusBar:SetReverseFill(fillDirection == "down")
            end
        end
    end)


    local iconContainer = frame.Icon
    if iconContainer then
        if hideIcon then

            pcall(function()
                iconContainer:Hide()
                iconContainer:SetAlpha(0)
            end)
        else

            pcall(function()
                iconContainer:Show()
                iconContainer:SetAlpha(1)


                DisableAtlasBorder(iconContainer.DebuffBorder)
                DisableAtlasBorder(iconContainer.BuffBorder)
                DisableAtlasBorder(iconContainer.TempEnchantBorder)


                local iconSize = isVertical and frameWidth or frameHeight
                iconContainer:SetSize(iconSize, iconSize)


            local iconTexture = iconContainer.Icon or iconContainer.icon or iconContainer.texture
            if iconTexture and iconTexture.IsObjectType and iconTexture:IsObjectType("Texture") then

                if iconTexture.GetMaskTexture then
                    local i = 1
                    local mask = iconTexture:GetMaskTexture(i)
                    while mask do
                        iconTexture:RemoveMaskTexture(mask)
                        i = i + 1
                        mask = iconTexture:GetMaskTexture(i)
                    end
                end


                local cooldown = iconContainer.Cooldown or iconContainer.cooldown
                if cooldown then
                    if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(false) end
                    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
                end


                iconTexture:ClearAllPoints()
                iconTexture:SetPoint("TOPLEFT", iconContainer, "TOPLEFT", 0, 0)
                iconTexture:SetPoint("BOTTOMRIGHT", iconContainer, "BOTTOMRIGHT", 0, 0)


                iconTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)


                for _, region in ipairs({iconContainer:GetRegions()}) do
                    if region:IsObjectType("Texture") and region ~= iconTexture then
                        region:SetTexture(nil)
                        region:Hide()
                    end
                end


                if iconContainer.GetChildren then
                    for _, child in ipairs({iconContainer:GetChildren()}) do
                        if child and child ~= iconTexture then

                            local childName = child.GetName and child:GetName() or ""
                            if not childName:find("Cooldown") then
                                for _, reg in ipairs({child:GetRegions()}) do
                                    if reg:IsObjectType("Texture") then
                                        reg:SetTexture(nil)
                                        reg:Hide()
                                    end
                                end
                            end
                        end
                    end
                end
            end


            for _, region in ipairs({iconContainer:GetRegions()}) do
                if region:IsObjectType("FontString") then
                    region:SetAlpha(0)
                end
            end

            if iconContainer.GetChildren then
                for _, child in ipairs({iconContainer:GetChildren()}) do
                    if child.GetRegions then
                        for _, region in ipairs({child:GetRegions()}) do
                            if region:IsObjectType("FontString") then
                                region:SetAlpha(0)
                            end
                        end
                    end
                end
            end


            if iconTexture and iconTexture.SetAtlas and not iconTexture._preyAtlasHooked then
                iconTexture._preyAtlasHooked = true
                hooksecurefunc(iconTexture, "SetAtlas", function(self)

                    self:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                end)
            end
        end)
        end
    end


    if statusBar then
        pcall(function()
            statusBar:ClearAllPoints()

            if isVertical then

                if hideIcon or not iconContainer then

                    statusBar:SetAllPoints(frame)
                else

                    iconContainer:ClearAllPoints()
                    if iconPosition == "bottom" then
                        iconContainer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
                        statusBar:SetPoint("TOP", frame, "TOP", 0, 0)
                        statusBar:SetPoint("LEFT", frame, "LEFT", 0, 0)
                        statusBar:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
                        statusBar:SetPoint("BOTTOM", iconContainer, "TOP", 0, 0)
                    else
                        iconContainer:SetPoint("TOP", frame, "TOP", 0, 0)
                        statusBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
                        statusBar:SetPoint("LEFT", frame, "LEFT", 0, 0)
                        statusBar:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
                        statusBar:SetPoint("TOP", iconContainer, "BOTTOM", 0, 0)
                    end
                end
            else

                if hideIcon or not iconContainer then
                    statusBar:SetPoint("LEFT", frame, "LEFT", 0, 0)
                else
                    statusBar:SetPoint("LEFT", iconContainer, "RIGHT", 0, 0)
                end
                statusBar:SetPoint("TOP", frame, "TOP", 0, 0)
                statusBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
                statusBar:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
            end
        end)
    end


    if statusBar and statusBar.SetStatusBarTexture then
        local texturePath = LSM:Fetch("statusbar", texture) or LSM:Fetch("statusbar", "Prey v5")
        if texturePath then
            pcall(statusBar.SetStatusBarTexture, statusBar, texturePath)
        end
    end


    if statusBar and statusBar.SetStatusBarColor then
        pcall(function()
            if useClassColor then
                local _, class = UnitClass("player")
                local color = RAID_CLASS_COLORS[class]
                if color then
                    statusBar:SetStatusBarColor(color.r, color.g, color.b, barOpacity)
                end
            else
                local c = barColor
                statusBar:SetStatusBarColor(c[1] or 0.2, c[2] or 0.8, c[3] or 0.6, barOpacity)
            end
        end)
    end


    local barMeta = GetBarMeta(frame)
    if not barMeta.bgTexture then
        barMeta.bgTexture = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    end

    local bgR, bgG, bgB = bgColor[1] or 0, bgColor[2] or 0, bgColor[3] or 0
    barMeta.bgTexture:SetColorTexture(bgR, bgG, bgB, 1)
    if statusBar then
        barMeta.bgTexture:ClearAllPoints()
        barMeta.bgTexture:SetAllPoints(statusBar)
    end
    barMeta.bgTexture:SetAlpha(bgOpacity)
    barMeta.bgTexture:Show()


    if borderSize > 0 then
        if not barMeta.borderContainer then
            local container = CreateFrame("Frame", nil, frame)
            container:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 5)


            container._top = container:CreateTexture(nil, "OVERLAY", nil, 7)
            container._top:SetColorTexture(0, 0, 0, 1)
            container._bottom = container:CreateTexture(nil, "OVERLAY", nil, 7)
            container._bottom:SetColorTexture(0, 0, 0, 1)
            container._left = container:CreateTexture(nil, "OVERLAY", nil, 7)
            container._left:SetColorTexture(0, 0, 0, 1)
            container._right = container:CreateTexture(nil, "OVERLAY", nil, 7)
            container._right:SetColorTexture(0, 0, 0, 1)

            barMeta.borderContainer = container
        end

        local container = barMeta.borderContainer

        container:ClearAllPoints()
        container:SetPoint("TOPLEFT", frame, "TOPLEFT", -borderSize, borderSize)
        container:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", borderSize, -borderSize)


        container._top:ClearAllPoints()
        container._top:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        container._top:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
        container._top:SetHeight(borderSize)


        container._bottom:ClearAllPoints()
        container._bottom:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
        container._bottom:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
        container._bottom:SetHeight(borderSize)


        container._left:ClearAllPoints()
        container._left:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        container._left:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
        container._left:SetWidth(borderSize)


        container._right:ClearAllPoints()
        container._right:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
        container._right:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
        container._right:SetWidth(borderSize)

        container:Show()
    else
        if barMeta.borderContainer then
            barMeta.borderContainer:Hide()
        end
    end


    local generalFont = GetGeneralFont()
    local generalOutline = GetGeneralFontOutline()
    local showText = not hideText and (not isVertical or showTextOnVertical)

    if frame.GetRegions then
        for _, region in ipairs({frame:GetRegions()}) do
            if region and region:GetObjectType() == "FontString" then
                pcall(function()
                    if showText then
                        region:SetFont(generalFont, textSize, generalOutline)
                        region:SetAlpha(1)
                    else
                        region:SetAlpha(0)
                    end
                end)
            end
        end
    end

    if statusBar and statusBar.GetRegions then
        for _, region in ipairs({statusBar:GetRegions()}) do
            if region and region:GetObjectType() == "FontString" then
                pcall(function()
                    if showText then
                        region:SetFont(generalFont, textSize, generalOutline)
                        region:SetAlpha(1)
                    else
                        region:SetAlpha(0)
                    end
                end)
            end
        end
    end

    barMeta.styled = true
end


local iconState = {
    isInitialized = false,
    lastCount     = 0,
}

LayoutBuffIcons = function()
    if not BuffIconCooldownViewer then return end
    if isIconLayoutRunning then return end
    if IsLayoutSuppressed() then return end

    isIconLayoutRunning = true

    local settings = GetBuffSettings()
    if not settings.enabled then
        isIconLayoutRunning = false
        return
    end


    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local hudLayering = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.hudLayering
    local layerPriority = hudLayering and hudLayering.buffIcon or 5
    if PREYCore and PREYCore.GetHUDFrameLevel then
        local frameLevel = PREYCore:GetHUDFrameLevel(layerPriority)
        BuffIconCooldownViewer:SetFrameLevel(frameLevel)
    end

    local icons = GetBuffIconFrames()
    local currentCount = #icons


    if currentCount == 0 then
        iconState.lastCount = 0
        iconState.isInitialized = false
        isIconLayoutRunning = false
        return
    end


    local iconSize = settings.iconSize or 42
    local padding = settings.padding or 0
    local aspectRatio = settings.aspectRatioCrop or 1.0
    local growthDirection = settings.growthDirection or "CENTERED_HORIZONTAL"


    local iconWidth, iconHeight = iconSize, iconSize
    if aspectRatio > 1.0 then

        iconHeight = iconSize / aspectRatio
    elseif aspectRatio < 1.0 then

        iconWidth = iconSize * aspectRatio
    end

    local targetCount = currentCount
    iconState.lastCount = currentCount
    iconState.isInitialized = true


    local isVertical = (growthDirection == "UP" or growthDirection == "DOWN")


    local totalWidth, totalHeight
    if isVertical then
        totalWidth = iconWidth
        totalHeight = (targetCount * iconHeight) + ((targetCount - 1) * padding)
        totalHeight = roundPixel(totalHeight)
    else
        totalWidth = (targetCount * iconWidth) + ((targetCount - 1) * padding)
        totalWidth = roundPixel(totalWidth)
        totalHeight = iconHeight
    end


    local startX, startY
    if isVertical then
        startX = 0
        if growthDirection == "UP" then

            startY = -totalHeight / 2 + iconHeight / 2
        else

            startY = totalHeight / 2 - iconHeight / 2
        end
        startY = roundPixel(startY)
    else

        startX = -totalWidth / 2 + iconWidth / 2
        startX = roundPixel(startX)
        startY = 0
    end


    local needsReposition = false
    for i, icon in ipairs(icons) do
        local expectedX, expectedY
        if isVertical then
            expectedX = 0
            if growthDirection == "UP" then
                expectedY = roundPixel(startY + (i - 1) * (iconHeight + padding))
            else
                expectedY = roundPixel(startY - (i - 1) * (iconHeight + padding))
            end

            local point, _, _, xOfs, yOfs = icon:GetPoint(1)
            if not point or abs((yOfs or 0) - expectedY) > 2 then
                needsReposition = true
                break
            end
        else
            expectedX = roundPixel(startX + (i - 1) * (iconWidth + padding))
            if not PositionMatchesTolerance(icon, expectedX, 2) then
                needsReposition = true
                break
            end
        end
    end

    if needsReposition then


        for _, icon in ipairs(icons) do
            icon:ClearAllPoints()
        end


        for i, icon in ipairs(icons) do
            ApplyIconStyle(icon, settings)
            if isVertical then
                local y
                if growthDirection == "UP" then
                    y = startY + (i - 1) * (iconHeight + padding)
                else
                    y = startY - (i - 1) * (iconHeight + padding)
                end
                icon:SetPoint("CENTER", BuffIconCooldownViewer, "CENTER", 0, roundPixel(y))
            else
                local x = startX + (i - 1) * (iconWidth + padding)
                icon:SetPoint("CENTER", BuffIconCooldownViewer, "CENTER", roundPixel(x), 0)
            end
        end
    else

        for _, icon in ipairs(icons) do
            ApplyIconStyle(icon, settings)
        end
    end


    if not InCombatLockdown() then
        SuppressLayout()
        BuffIconCooldownViewer:SetSize(roundPixel(totalWidth), roundPixel(totalHeight))
        UnsuppressLayout()


        if BuffIconCooldownViewer.Selection then
            BuffIconCooldownViewer.Selection:ClearAllPoints()
            BuffIconCooldownViewer.Selection:SetPoint("TOPLEFT", BuffIconCooldownViewer, "TOPLEFT", 0, 0)
            BuffIconCooldownViewer.Selection:SetPoint("BOTTOMRIGHT", BuffIconCooldownViewer, "BOTTOMRIGHT", 0, 0)
            BuffIconCooldownViewer.Selection:SetFrameLevel(BuffIconCooldownViewer:GetFrameLevel())
        end
    end

    isIconLayoutRunning = false
end


local barState = {
    lastCount      = 0,
    lastBarWidth   = nil,
    lastBarHeight  = nil,
    lastSpacing    = nil,
}

LayoutBuffBars = function()
    if not BuffBarCooldownViewer then return end
    if isBarLayoutRunning then return end
    if IsLayoutSuppressed() then return end
    if InCombatLockdown() then return end

    isBarLayoutRunning = true


    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local hudLayering = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.hudLayering
    local layerPriority = hudLayering and hudLayering.buffBar or 5
    local frameLevel = 200
    if PREYCore and PREYCore.GetHUDFrameLevel then
        frameLevel = PREYCore:GetHUDFrameLevel(layerPriority)
    end

    BuffBarCooldownViewer:SetFrameLevel(frameLevel)

    local bars = GetBuffBarFrames()
    local count = #bars
    if count == 0 then
        barState.lastCount = 0
        isBarLayoutRunning = false
        return
    end

    local refBar = bars[1]
    if not refBar then
        isBarLayoutRunning = false
        return
    end


    local settings = GetTrackedBarSettings()
    local stylingEnabled = settings.enabled


    local barWidth = refBar:GetWidth()
    local barHeight = stylingEnabled and settings.barHeight or refBar:GetHeight()
    local spacing = stylingEnabled and settings.spacing or 0
    local growFromBottom = (not stylingEnabled) or (settings.growUp ~= false)


    local orientation = stylingEnabled and settings.orientation or "horizontal"
    local isVertical = (orientation == "vertical")


    local effectiveBarWidth, effectiveBarHeight
    if isVertical then
        effectiveBarWidth = barHeight
        effectiveBarHeight = stylingEnabled and settings.barWidth or 200
    else
        effectiveBarWidth = barWidth
        effectiveBarHeight = barHeight
    end

    if not effectiveBarHeight or effectiveBarHeight == 0 then
        isBarLayoutRunning = false
        return
    end

    barState.lastCount = count
    barState.lastBarWidth = effectiveBarWidth
    barState.lastBarHeight = effectiveBarHeight
    barState.lastSpacing = spacing


    local totalSize
    if isVertical then
        totalSize = (count * effectiveBarWidth) + ((count - 1) * spacing)
    else
        totalSize = (count * effectiveBarHeight) + ((count - 1) * spacing)
    end
    totalSize = roundPixel(totalSize)


    local needsReposition = false
    for index, bar in ipairs(bars) do
        local offsetIndex = index - 1

        if isVertical then

            local expectedX
            if growFromBottom then
                expectedX = roundPixel(offsetIndex * (effectiveBarWidth + spacing))
            else
                expectedX = roundPixel(-offsetIndex * (effectiveBarWidth + spacing))
            end
            local point, _, _, xOfs = bar:GetPoint(1)
            if not point or abs((xOfs or 0) - expectedX) > 2 then
                needsReposition = true
                break
            end
        else

            local expectedY
            if growFromBottom then
                expectedY = roundPixel(offsetIndex * (effectiveBarHeight + spacing))
            else
                expectedY = roundPixel(-offsetIndex * (effectiveBarHeight + spacing))
            end
            local point, _, _, _, yOfs = bar:GetPoint(1)
            if not point or abs((yOfs or 0) - expectedY) > 2 then
                needsReposition = true
                break
            end
        end
    end

    if needsReposition then

        for _, bar in ipairs(bars) do
            bar:ClearAllPoints()
        end


        for index, bar in ipairs(bars) do
            local offsetIndex = index - 1

            if isVertical then

                local x
                if growFromBottom then

                    x = offsetIndex * (effectiveBarWidth + spacing)
                    x = roundPixel(x)
                    bar:SetPoint("LEFT", BuffBarCooldownViewer, "LEFT", x, 0)
                else

                    x = -offsetIndex * (effectiveBarWidth + spacing)
                    x = roundPixel(x)
                    bar:SetPoint("RIGHT", BuffBarCooldownViewer, "RIGHT", x, 0)
                end
            else

                local y
                if growFromBottom then
                    y = offsetIndex * (effectiveBarHeight + spacing)
                    y = roundPixel(y)
                    bar:SetPoint("BOTTOM", BuffBarCooldownViewer, "BOTTOM", 0, y)
                else
                    y = -offsetIndex * (effectiveBarHeight + spacing)
                    y = roundPixel(y)
                    bar:SetPoint("TOP", BuffBarCooldownViewer, "TOP", 0, y)
                end
            end
        end
    end


    for _, bar in ipairs(bars) do
        if stylingEnabled then
            ApplyBarStyle(bar, settings)
        end

        bar:SetFrameLevel(frameLevel)
        if bar.Bar then
            bar.Bar:SetFrameLevel(frameLevel + 1)
        end
        if bar.Icon then
            bar.Icon:SetFrameLevel(frameLevel + 1)
        end
    end


    if isVertical then
        SuppressLayout()


        local currentWidth = BuffBarCooldownViewer:GetWidth()
        BuffBarCooldownViewer:SetSize(currentWidth, roundPixel(effectiveBarHeight))

        UnsuppressLayout()
    else


        SuppressLayout()


        BuffBarCooldownViewer:SetSize(roundPixel(effectiveBarWidth), roundPixel(effectiveBarHeight))

        UnsuppressLayout()
    end

    isBarLayoutRunning = false
end


local lastIconHash = ""


local function BuildIconHash(count, settings)
    return string.format("%d_%d_%d_%.2f_%d_%s",
        count,
        settings.iconSize or 42,
        settings.padding or 0,
        settings.aspectRatioCrop or 1.0,
        settings.borderSize or 2,
        settings.growthDirection or "CENTERED_HORIZONTAL"
    )
end

local function CheckIconChanges()
    if not BuffIconCooldownViewer then return end
    if isIconLayoutRunning then return end
    if IsLayoutSuppressed() then return end


    local visibleCount = 0
    for _, child in ipairs({ BuffIconCooldownViewer:GetChildren() }) do
        if child and child ~= BuffIconCooldownViewer.Selection then
            if (child.icon or child.Icon) and child:IsShown() then
                visibleCount = visibleCount + 1
            end
        end
    end


    local settings = GetBuffSettings()
    local hash = BuildIconHash(visibleCount, settings)


    if hash == lastIconHash then
        return
    end

    lastIconHash = hash
    LayoutBuffIcons()
end

local function CheckBarChanges()
    if not BuffBarCooldownViewer then return end
    if isBarLayoutRunning then return end


    LayoutBuffBars()
end


local forcePopulateDone = false

local function ForcePopulateBuffIcons()
    if forcePopulateDone then return end
    if InCombatLockdown() then return end

    local viewer = BuffIconCooldownViewer
    if not viewer then return end

    forcePopulateDone = true


    if not InCombatLockdown() then
        local w, h = viewer:GetSize()
        if w and h and w > 0 and h > 0 then

            pcall(function()
                viewer:SetSize(w + 0.1, h)
                C_Timer.After(0.05, function()
                    if viewer and not InCombatLockdown() then
                        pcall(function() viewer:SetSize(w, h) end)
                    end
                end)
            end)
        end
    end


    if _G.PreyUI and _G.PreyUI.PREYCore then
        local PREYCore = _G.PreyUI.PREYCore
        if PREYCore.ForceRefreshBuffIcons then
            C_Timer.After(0.2, function()
                pcall(function() PREYCore:ForceRefreshBuffIcons() end)
            end)
        end
    end
end


local initialized = false

local function Initialize()
    if initialized then return end
    initialized = true


    ForcePopulateBuffIcons()


    if BuffIconCooldownViewer and not GetViewerMeta(BuffIconCooldownViewer).onUpdateHooked then
        local viewerMeta = GetViewerMeta(BuffIconCooldownViewer)
        viewerMeta.onUpdateHooked = true
        viewerMeta.elapsed = 0
        BuffIconCooldownViewer:HookScript("OnUpdate", function(self, elapsed)
            local meta = GetViewerMeta(self)
            meta.elapsed = (meta.elapsed or 0) + elapsed
            if meta.elapsed > 0.05 then
                meta.elapsed = 0
                if self:IsShown() then
                    CheckIconChanges()
                end
            end
        end)
    end

    if BuffBarCooldownViewer and not GetViewerMeta(BuffBarCooldownViewer).onUpdateHooked then
        local viewerMeta = GetViewerMeta(BuffBarCooldownViewer)
        viewerMeta.onUpdateHooked = true
        viewerMeta.elapsed = 0
        BuffBarCooldownViewer:HookScript("OnUpdate", function(self, elapsed)
            local meta = GetViewerMeta(self)
            meta.elapsed = (meta.elapsed or 0) + elapsed
            if meta.elapsed > 0.05 then
                meta.elapsed = 0
                if self:IsShown() then
                    CheckBarChanges()
                end
            end
        end)
    end


    if BuffIconCooldownViewer then
        BuffIconCooldownViewer:HookScript("OnSizeChanged", function(self)
            if IsLayoutSuppressed() then return end
            if isIconLayoutRunning then return end
            LayoutBuffIcons()
        end)
    end


    if BuffIconCooldownViewer then
        BuffIconCooldownViewer:HookScript("OnShow", function(self)
            if IsLayoutSuppressed() then return end
            if isIconLayoutRunning then return end
            LayoutBuffIcons()
        end)
    end


    if BuffIconCooldownViewer and BuffIconCooldownViewer.Layout then
        hooksecurefunc(BuffIconCooldownViewer, "Layout", function()
            if IsLayoutSuppressed() then return end
            if isIconLayoutRunning then return end
            LayoutBuffIcons()
        end)
    end

    if BuffBarCooldownViewer and BuffBarCooldownViewer.Layout then
        hooksecurefunc(BuffBarCooldownViewer, "Layout", function()
            if IsLayoutSuppressed() then return end
            if isBarLayoutRunning then return end
            LayoutBuffBars()
        end)
    end


    if BuffIconCooldownViewer and not GetViewerMeta(BuffIconCooldownViewer).auraHook then
        local viewerMeta = GetViewerMeta(BuffIconCooldownViewer)
        viewerMeta.auraHook = CreateFrame("Frame")
        viewerMeta.auraHook:RegisterEvent("UNIT_AURA")
        viewerMeta.auraHook:SetScript("OnEvent", function(_, event, unit)
            if unit == "player" and BuffIconCooldownViewer:IsShown() then

                if not viewerMeta.rescanPending then
                    viewerMeta.rescanPending = true
                    C_Timer.After(0.1, function()
                        viewerMeta.rescanPending = nil

                        if BuffIconCooldownViewer:IsShown() then
                            if isIconLayoutRunning then return end
                            if IsLayoutSuppressed() then return end

                            lastIconHash = ""
                            CheckIconChanges()
                        end
                    end)
                end
            end
        end)
    end


    C_Timer.After(0.3, function()
        LayoutBuffIcons()
        LayoutBuffBars()
    end)
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, Initialize)

        C_Timer.After(2, ForcePopulateBuffIcons)
        C_Timer.After(4, ForcePopulateBuffIcons)
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        if isInitialLogin or isReloadingUi then
            C_Timer.After(1.5, function()
                ForcePopulateBuffIcons()
                LayoutBuffIcons()
                LayoutBuffBars()
            end)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then

        C_Timer.After(0.5, function()
            ForcePopulateBuffIcons()
            LayoutBuffIcons()
            LayoutBuffBars()
        end)
    end
end)


C_Timer.After(0, function()
    if BuffIconCooldownViewer or BuffBarCooldownViewer then
        Initialize()
    end
end)


PREY_BuffBar.LayoutIcons = LayoutBuffIcons
PREY_BuffBar.LayoutBars = LayoutBuffBars
PREY_BuffBar.Initialize = Initialize


function PREY_BuffBar.Refresh()

    iconState.isInitialized = false
    iconState.lastCount = 0
    barState.lastCount = 0
    lastIconHash = ""

    LayoutBuffIcons()
    LayoutBuffBars()
end


_G.PreyUI_RefreshBuffBar = PREY_BuffBar.Refresh
