local ADDON_NAME, ns = ...
local PREYCore = ns.Addon


local PREY_Anchoring = {}
ns.PREY_Anchoring = PREY_Anchoring


PREY_Anchoring.anchorTargets = {}


PREY_Anchoring.categories = {}


PREY_Anchoring.anchoredFrames = {}

local Helpers = {}


function PREY_Anchoring:SetHelpers(helpers)
    Helpers = helpers or {}
end


local function Scale(x)
    return Helpers.Scale and Helpers.Scale(x) or (PREYCore and PREYCore.Scale and PREYCore:Scale(x) or x)
end


function PREY_Anchoring:RegisterAnchorTarget(name, frame, options)
    if not name or not frame then
        return false
    end

    options = options or {}
    self.anchorTargets[name] = {
        frame = frame,
        options = options
    }


    local category = options.category
    if category then
        if not self.categories[category] then
            self.categories[category] = {
                order = options.categoryOrder or 999
            }
        end
    end

    return true
end


function PREY_Anchoring:UnregisterAnchorTarget(name)
    if not name then return false end
    self.anchorTargets[name] = nil
    return true
end


function PREY_Anchoring:GetAnchorTarget(name)
    if not name then return nil end


    local registered = self.anchorTargets[name]
    if registered then
        return registered.frame
    end

    return nil
end


function PREY_Anchoring:GetAnchorTargetList(include, exclude, excludeSelf)
    include = include or {}
    exclude = exclude or {}


    local includeLookup = {}
    local excludeLookup = {}

    if type(include) == "table" and #include > 0 then
        for _, value in ipairs(include) do
            includeLookup[value] = true
        end
    elseif type(include) == "table" then

        includeLookup = nil
    end

    if type(exclude) == "table" then
        for _, value in ipairs(exclude) do
            excludeLookup[value] = true
        end
    end


    local function ShouldInclude(value)

        if excludeLookup[value] then
            return false
        end

        if excludeSelf and value == excludeSelf then
            return false
        end

        if includeLookup then
            return includeLookup[value] == true
        end

        return true
    end

    local list = {}


    if ShouldInclude("disabled") then
        table.insert(list, {value = "disabled", text = "Disabled"})
    end
    if ShouldInclude("screen") then
        table.insert(list, {value = "screen", text = "Screen Center"})
    end


    local categorized = {}
    local uncategorized = {}

    for name, data in pairs(self.anchorTargets) do
        if ShouldInclude(name) then
            local displayName = data.options and data.options.displayName or name

            displayName = displayName:gsub("^%l", string.upper)
            displayName = displayName:gsub("([a-z])([A-Z])", "%1 %2")

            local category = data.options and data.options.category
            local order = data.options and data.options.order or 999
            local item = {value = name, text = displayName, category = category, order = order}

            if category then
                if not categorized[category] then
                    categorized[category] = {}
                end
                table.insert(categorized[category], item)
            else
                table.insert(uncategorized, item)
            end
        end
    end


    local sortedCategories = {}
    for category, items in pairs(categorized) do
        local categoryInfo = self.categories[category] or {}
        local categoryOrder = categoryInfo.order or 999
        table.insert(sortedCategories, {name = category, order = categoryOrder})

        table.sort(items, function(a, b)
            if a.order ~= b.order then
                return a.order < b.order
            end
            return a.text < b.text
        end)
    end
    table.sort(sortedCategories, function(a, b)
        if a.order ~= b.order then
            return a.order < b.order
        end
        return a.name < b.name
    end)


    table.sort(uncategorized, function(a, b)
        if a.order ~= b.order then
            return a.order < b.order
        end
        return a.text < b.text
    end)


    for _, catInfo in ipairs(sortedCategories) do
        local category = catInfo.name

        table.insert(list, {value = nil, text = category, isHeader = true})

        for _, item in ipairs(categorized[category]) do
            table.insert(list, item)
        end
    end


    if #uncategorized > 0 then

        if #sortedCategories > 0 then
            table.insert(list, {value = nil, text = "Other", isHeader = true})
        end
        for _, item in ipairs(uncategorized) do
            table.insert(list, item)
        end
    end

    return list
end


function PREY_Anchoring:GetAnchorDimensions(anchorFrame, anchorTargetName)
    if not anchorFrame then return nil end

    local registered = self.anchorTargets[anchorTargetName]
    local options = registered and registered.options or {}

    local width, height
    if options.customWidth then
        width = type(options.customWidth) == "function" and options.customWidth(anchorFrame) or options.customWidth
    else
        width = anchorFrame:GetWidth()
    end

    if options.customHeight then
        height = type(options.customHeight) == "function" and options.customHeight(anchorFrame) or options.customHeight
    else
        height = anchorFrame:GetHeight()
    end


    if anchorTargetName == "essential" or anchorTargetName == "utility" then
        width = anchorFrame.__cdmRow1Width or width
        height = anchorFrame.__cdmTotalHeight or height
    end

    local centerX, centerY = anchorFrame:GetCenter()
    if not centerX or not centerY then return nil end

    return {
        width = width,
        height = height,
        centerX = centerX,
        centerY = centerY,
        top = centerY + (height / 2),
        bottom = centerY - (height / 2),
        left = centerX - (width / 2),
        right = centerX + (width / 2),
    }
end


local function GetBorderSize(frame)
    if not frame or not frame.GetBackdrop then
        return 0
    end

    local backdrop = frame:GetBackdrop()
    if not backdrop or not backdrop.edgeSize then
        return 0
    end

    return backdrop.edgeSize or 0
end


local VALID_ANCHOR_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true,
    LEFT = true, CENTER = true, RIGHT = true,
    BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}


function PREY_Anchoring:PositionFrame(frame, anchorTarget, anchorPoint, offsetX, offsetY, parentFrame, options)
    if not frame then return false end


    if InCombatLockdown() then
        C_Timer.After(0, function()
            self:PositionFrame(frame, anchorTarget, anchorPoint, offsetX, offsetY, parentFrame, options)
        end)
        return false
    end

    options = options or {}
    offsetX = offsetX or 0
    offsetY = offsetY or 0


    anchorPoint = anchorPoint or "CENTER"
    if not VALID_ANCHOR_POINTS[anchorPoint] then
        anchorPoint = "CENTER"
    end


    local targetAnchorPoint = options.targetAnchorPoint or anchorPoint
    if not VALID_ANCHOR_POINTS[targetAnchorPoint] then
        targetAnchorPoint = anchorPoint
    end


    local sourceAnchorPoint2 = options.sourceAnchorPoint2
    local targetAnchorPoint2 = options.targetAnchorPoint2
    local useExplicitDualAnchors = sourceAnchorPoint2 and targetAnchorPoint2 and
                                   VALID_ANCHOR_POINTS[sourceAnchorPoint2] and
                                   VALID_ANCHOR_POINTS[targetAnchorPoint2]


    local success = pcall(function()
        frame:ClearAllPoints()
    end)
    if not success then

        C_Timer.After(0, function()
            if frame and frame.ClearAllPoints then
                pcall(frame.ClearAllPoints, frame)
            end
        end)
        return false
    end


    if not anchorTarget or anchorTarget == "none" or anchorTarget == "disabled" or anchorTarget == "screen" then
        frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
        return true
    end


    if anchorTarget == "unitframe" and parentFrame then

        local sourceBorderSize = GetBorderSize(frame)
        local targetBorderSize = GetBorderSize(parentFrame)


        local function GetBorderAdjustment(anchorPoint, borderSize)
            if not borderSize or borderSize == 0 then return 0, 0 end

            local adjX, adjY = 0, 0
            if anchorPoint == "TOPLEFT" then
                adjX = borderSize
                adjY = -borderSize
            elseif anchorPoint == "TOP" then
                adjY = -borderSize
            elseif anchorPoint == "TOPRIGHT" then
                adjX = -borderSize
                adjY = -borderSize
            elseif anchorPoint == "LEFT" then
                adjX = borderSize
            elseif anchorPoint == "RIGHT" then
                adjX = -borderSize
            elseif anchorPoint == "BOTTOMLEFT" then
                adjX = borderSize
                adjY = borderSize
            elseif anchorPoint == "BOTTOM" then
                adjY = borderSize
            elseif anchorPoint == "BOTTOMRIGHT" then
                adjX = -borderSize
                adjY = borderSize
            end
            return adjX, adjY
        end

        local sourceAdjX, sourceAdjY = GetBorderAdjustment(anchorPoint, sourceBorderSize)
        local targetAdjX, targetAdjY = GetBorderAdjustment(targetAnchorPoint, targetBorderSize)
        local netAdjX = targetAdjX - sourceAdjX
        local netAdjY = targetAdjY - sourceAdjY

        local scaledOffsetX = Scale(offsetX) + netAdjX
        local scaledOffsetY = math.floor(Scale(offsetY) + 0.5) + netAdjY


        if useExplicitDualAnchors then
            local sourceAdjX2, sourceAdjY2 = GetBorderAdjustment(sourceAnchorPoint2, sourceBorderSize)
            local targetAdjX2, targetAdjY2 = GetBorderAdjustment(targetAnchorPoint2, targetBorderSize)
            local netAdjX2 = targetAdjX2 - sourceAdjX2
            local netAdjY2 = targetAdjY2 - sourceAdjY2

            local scaledOffsetX2 = Scale(offsetX) + netAdjX2
            local scaledOffsetY2 = math.floor(Scale(offsetY) + 0.5) + netAdjY2

            frame:SetPoint(anchorPoint, parentFrame, targetAnchorPoint, scaledOffsetX, scaledOffsetY)
            frame:SetPoint(sourceAnchorPoint2, parentFrame, targetAnchorPoint2, scaledOffsetX2, scaledOffsetY2)
            return true
        end


        frame:SetPoint(anchorPoint, parentFrame, targetAnchorPoint, scaledOffsetX, scaledOffsetY)
        return true
    end


    local anchorFrame = self:GetAnchorTarget(anchorTarget)
    if not anchorFrame then
        return false
    end

    if not anchorFrame:IsShown() then
        return false
    end


    local sourceBorderSize = GetBorderSize(frame)
    local targetBorderSize = GetBorderSize(anchorFrame)


    local function GetBorderAdjustment(anchorPoint, borderSize)
        if not borderSize or borderSize == 0 then return 0, 0 end

        local adjX, adjY = 0, 0
        if anchorPoint == "TOPLEFT" then
            adjX = borderSize
            adjY = -borderSize
        elseif anchorPoint == "TOP" then
            adjY = -borderSize
        elseif anchorPoint == "TOPRIGHT" then
            adjX = -borderSize
            adjY = -borderSize
        elseif anchorPoint == "LEFT" then
            adjX = borderSize
        elseif anchorPoint == "RIGHT" then
            adjX = -borderSize
        elseif anchorPoint == "BOTTOMLEFT" then
            adjX = borderSize
            adjY = borderSize
        elseif anchorPoint == "BOTTOM" then
            adjY = borderSize
        elseif anchorPoint == "BOTTOMRIGHT" then
            adjX = -borderSize
            adjY = borderSize
        end
        return adjX, adjY
    end

    local sourceAdjX, sourceAdjY = GetBorderAdjustment(anchorPoint, sourceBorderSize)
    local targetAdjX, targetAdjY = GetBorderAdjustment(targetAnchorPoint, targetBorderSize)
    local netAdjX = targetAdjX - sourceAdjX
    local netAdjY = targetAdjY - sourceAdjY


    local scaledOffsetX = Scale(offsetX) + netAdjX
    local scaledOffsetY = math.floor(Scale(offsetY) + 0.5) + netAdjY


    if useExplicitDualAnchors then
        local sourceAdjX2, sourceAdjY2 = GetBorderAdjustment(sourceAnchorPoint2, sourceBorderSize)
        local targetAdjX2, targetAdjY2 = GetBorderAdjustment(targetAnchorPoint2, targetBorderSize)
        local netAdjX2 = targetAdjX2 - sourceAdjX2
        local netAdjY2 = targetAdjY2 - sourceAdjY2


        local scaledOffsetX2 = Scale(offsetX) + netAdjX2
        local scaledOffsetY2 = math.floor(Scale(offsetY) + 0.5) + netAdjY2

        frame:SetPoint(anchorPoint, anchorFrame, targetAnchorPoint, scaledOffsetX, scaledOffsetY)
        frame:SetPoint(sourceAnchorPoint2, anchorFrame, targetAnchorPoint2, scaledOffsetX2, scaledOffsetY2)
        return true
    end


    frame:SetPoint(anchorPoint, anchorFrame, targetAnchorPoint, scaledOffsetX, scaledOffsetY)

    return true
end


function PREY_Anchoring:GetAnchorTargetName(frame)
    if not frame then return nil end

    for name, data in pairs(self.anchorTargets) do
        if data.frame == frame then
            return name
        end
    end

    return nil
end


function PREY_Anchoring:CheckCircularDependency(frame, anchorTarget)
    if not frame or not anchorTarget then return false end


    if anchorTarget == "disabled" or anchorTarget == "screen" or anchorTarget == "none" then
        return false
    end


    local targetFrame = self:GetAnchorTarget(anchorTarget)
    if not targetFrame then return false end


    if targetFrame == frame then
        return true
    end


    local targetConfig = self.anchoredFrames[targetFrame]
    if not targetConfig then

        return false
    end


    local visited = {}
    local function CheckCycle(currentFrame, startFrame)

        if currentFrame == startFrame then
            return true
        end


        if visited[currentFrame] then
            return false
        end
        visited[currentFrame] = true


        local config = self.anchoredFrames[currentFrame]
        if not config then

            return false
        end


        if config.anchorTarget == "disabled" or config.anchorTarget == "screen" or config.anchorTarget == "none" then
            return false
        end


        local nextTargetFrame = self:GetAnchorTarget(config.anchorTarget)
        if not nextTargetFrame then

            return false
        end


        return CheckCycle(nextTargetFrame, startFrame)
    end


    return CheckCycle(targetFrame, frame)
end


function PREY_Anchoring:RegisterAnchoredFrame(frame, config)
    if not frame or not config then return false end


    if config.anchorTarget and config.anchorTarget ~= "disabled" and config.anchorTarget ~= "screen" and config.anchorTarget ~= "none" then
        if self:CheckCircularDependency(frame, config.anchorTarget) then

            return false
        end
    end


    local anchors = config.anchors
    if not anchors or #anchors == 0 then

        local sourceAnchorPoint = config.anchorPoint or "CENTER"
        local targetAnchorPoint = config.targetAnchorPoint or sourceAnchorPoint
        anchors = {
            {source = sourceAnchorPoint, target = targetAnchorPoint}
        }
    end

    self.anchoredFrames[frame] = {
        anchorTarget = config.anchorTarget,
        anchors = anchors,
        offsetX = config.offsetX or 0,
        offsetY = config.offsetY or 0,
        parentFrame = config.parentFrame,
    }


    if InCombatLockdown() then
        C_Timer.After(0, function()
            self:RegisterAnchoredFrame(frame, config)
        end)
        return true
    end


    local success = pcall(function()
        frame:ClearAllPoints()
    end)
    if not success then

        C_Timer.After(0, function()
            if frame and frame.ClearAllPoints then
                pcall(frame.ClearAllPoints, frame)

                C_Timer.After(0.1, function()
                    self:RegisterAnchoredFrame(frame, config)
                end)
            end
        end)
        return true
    end

    if #anchors == 1 then

        local anchorPair = anchors[1]
        local source = anchorPair.source or "CENTER"
        local target = anchorPair.target or "CENTER"

        self:PositionFrame(
            frame,
            config.anchorTarget,
            source,
            config.offsetX or 0,
            config.offsetY or 0,
            config.parentFrame,
            {
                targetAnchorPoint = target,
            }
        )
    elseif #anchors == 2 then

        local anchorPair1 = anchors[1]
        local anchorPair2 = anchors[2]
        local source1 = anchorPair1.source or "CENTER"
        local target1 = anchorPair1.target or "CENTER"
        local source2 = anchorPair2.source or "CENTER"
        local target2 = anchorPair2.target or "CENTER"

        self:PositionFrame(
            frame,
            config.anchorTarget,
            source1,
            config.offsetX or 0,
            config.offsetY or 0,
            config.parentFrame,
            {
                targetAnchorPoint = target1,
                sourceAnchorPoint2 = source2,
                targetAnchorPoint2 = target2,
            }
        )
    end


    if frame._preyReRegisterStateDriver then
        C_Timer.After(0, function()
            if frame and frame._preyReRegisterStateDriver then
                frame._preyReRegisterStateDriver()
            end
        end)
    end

    return true
end


function PREY_Anchoring:UnregisterAnchoredFrame(frame)
    if not frame then return false end
    self.anchoredFrames[frame] = nil
    return true
end


function PREY_Anchoring:SnapTo(frame, anchorTarget, anchorPoint, offsetX, offsetY, options)
    if not frame or not anchorTarget then
        return false
    end

    options = options or {}
    offsetX = offsetX or 0
    offsetY = offsetY or 0


    local targetData = self:GetAnchorTarget(anchorTarget)
    if not targetData then
        if options.onFailure then
            options.onFailure("Anchor target not found: " .. tostring(anchorTarget))
        end
        return false
    end

    local targetFrame = targetData.frame


    if options.checkVisible ~= false then
        if not targetFrame:IsShown() then
            if options.onFailure then
                local displayName = targetData.options and targetData.options.displayName or anchorTarget
                options.onFailure(displayName .. " not visible.")
            end
            return false
        end
    end


    if not anchorPoint then
        if anchorTarget == "screen" or anchorTarget == "disabled" or anchorTarget == "none" then
            anchorPoint = "CENTER"
        else
            anchorPoint = "BOTTOMLEFT"
        end
    end


    local positionOptions = {
        targetAnchorPoint = options.targetAnchorPoint,
    }
    local success = self:PositionFrame(frame, anchorTarget, anchorPoint, offsetX, offsetY, nil, positionOptions)


    if success and frame._preyReRegisterStateDriver then
        C_Timer.After(0, function()
            if frame and frame._preyReRegisterStateDriver then
                frame._preyReRegisterStateDriver()
            end
        end)
    end

    if success and options.onSuccess then
        options.onSuccess()
    end

    return success
end


function PREY_Anchoring:UpdateAllAnchoredFrames()
    if InCombatLockdown() then

        C_Timer.After(0, function()
            self:UpdateAllAnchoredFrames()
        end)
        return
    end

    for frame, config in pairs(self.anchoredFrames) do
        if frame and frame:IsShown() then
            local anchors = config.anchors
            if not anchors or #anchors == 0 then

                local sourceAnchorPoint = config.anchorPoint or "CENTER"
                local targetAnchorPoint = config.targetAnchorPoint or sourceAnchorPoint
                anchors = {
                    {source = sourceAnchorPoint, target = targetAnchorPoint}
                }
            end


            local success = pcall(function()
                frame:ClearAllPoints()
            end)
            if not success then

                C_Timer.After(0, function()
                    if frame and frame:IsShown() then
                        pcall(frame.ClearAllPoints, frame)

                        local anchorPair = anchors[1]
                        if anchorPair then
                            local source = anchorPair.source or "CENTER"
                            local target = anchorPair.target or "CENTER"
                            self:PositionFrame(
                                frame,
                                config.anchorTarget,
                                source,
                                config.offsetX or 0,
                                config.offsetY or 0,
                                config.parentFrame,
                                {
                                    targetAnchorPoint = target,
                                }
                            )
                        end
                    end
                end)

            else

                if #anchors == 1 then

                    local anchorPair = anchors[1]
                    local source = anchorPair.source or "CENTER"
                    local target = anchorPair.target or "CENTER"

                    self:PositionFrame(
                        frame,
                        config.anchorTarget,
                        source,
                        config.offsetX or 0,
                        config.offsetY or 0,
                        config.parentFrame,
                        {
                            targetAnchorPoint = target,
                        }
                    )
                elseif #anchors == 2 then

                    local anchorPair1 = anchors[1]
                    local anchorPair2 = anchors[2]
                    local source1 = anchorPair1.source or "CENTER"
                    local target1 = anchorPair1.target or "CENTER"
                    local source2 = anchorPair2.source or "CENTER"
                    local target2 = anchorPair2.target or "CENTER"

                    self:PositionFrame(
                        frame,
                        config.anchorTarget,
                        source1,
                        config.offsetX or 0,
                        config.offsetY or 0,
                        config.parentFrame,
                        {
                            targetAnchorPoint = target1,
                            sourceAnchorPoint2 = source2,
                            targetAnchorPoint2 = target2,
                        }
                    )
                end
            end
        end
    end
end


function PREY_Anchoring:UpdateFramesForTarget(anchorTargetName)
    if InCombatLockdown() then

        C_Timer.After(0, function()
            self:UpdateFramesForTarget(anchorTargetName)
        end)
        return
    end

    for frame, config in pairs(self.anchoredFrames) do
        if frame and frame:IsShown() and config.anchorTarget == anchorTargetName then
            local anchors = config.anchors
            if not anchors or #anchors == 0 then

                local sourceAnchorPoint = config.anchorPoint or "CENTER"
                local targetAnchorPoint = config.targetAnchorPoint or sourceAnchorPoint
                anchors = {
                    {source = sourceAnchorPoint, target = targetAnchorPoint}
                }
            end


            local success = pcall(function()
                frame:ClearAllPoints()
            end)
            if not success then

                C_Timer.After(0, function()
                    if frame and frame:IsShown() then
                        pcall(frame.ClearAllPoints, frame)

                        local anchorPair = anchors[1]
                        if anchorPair then
                            local source = anchorPair.source or "CENTER"
                            local target = anchorPair.target or "CENTER"
                            self:PositionFrame(
                                frame,
                                config.anchorTarget,
                                source,
                                config.offsetX or 0,
                                config.offsetY or 0,
                                config.parentFrame,
                                {
                                    targetAnchorPoint = target,
                                }
                            )
                        end
                    end
                end)

            else

                if #anchors == 1 then

                    local anchorPair = anchors[1]
                    local source = anchorPair.source or "CENTER"
                    local target = anchorPair.target or "CENTER"

                    self:PositionFrame(
                        frame,
                        config.anchorTarget,
                        source,
                        config.offsetX or 0,
                        config.offsetY or 0,
                        config.parentFrame,
                        {
                            targetAnchorPoint = target,
                        }
                    )
                elseif #anchors == 2 then

                    local anchorPair1 = anchors[1]
                    local anchorPair2 = anchors[2]
                    local source1 = anchorPair1.source or "CENTER"
                    local target1 = anchorPair1.target or "CENTER"
                    local source2 = anchorPair2.source or "CENTER"
                    local target2 = anchorPair2.target or "CENTER"

                    self:PositionFrame(
                        frame,
                        config.anchorTarget,
                        source1,
                        config.offsetX or 0,
                        config.offsetY or 0,
                        config.parentFrame,
                        {
                            targetAnchorPoint = target1,
                            sourceAnchorPoint2 = source2,
                            targetAnchorPoint2 = target2,
                        }
                    )
                end
            end
        end
    end
end


_G.PreyUI_UpdateAnchoredFrames = function()
    if PREY_Anchoring then
        PREY_Anchoring:UpdateAllAnchoredFrames()
    end
end


_G.PreyUI_UpdateAnchoredUnitFrames = _G.PreyUI_UpdateAnchoredFrames
_G.PreyUI_UpdateCDMAnchoredUnitFrames = _G.PreyUI_UpdateAnchoredFrames

