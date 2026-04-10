local _, PREY = ...


local viewerPending = {}
local updateBucket = {}


local function RemovePadding(viewer)

    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return
    end


    if viewer._layoutApplying then
        return
    end

    local children = {viewer:GetChildren()}


    local visibleChildren = {}
    for _, child in ipairs(children) do
        if child:IsShown() then

            local point, relativeTo, relativePoint, x, y = child:GetPoint(1)
            child.originalX = x or 0
            child.originalY = y or 0
            table.insert(visibleChildren, child)
        end
    end

    if #visibleChildren == 0 then return end


    local isHorizontal = viewer.isHorizontal
    if isHorizontal then

        table.sort(visibleChildren, function(a, b)
            if math.abs(a.originalY - b.originalY) < 1 then
                return a.originalX < b.originalX
            end
            return a.originalY > b.originalY
        end)
    else

        table.sort(visibleChildren, function(a, b)
            if math.abs(a.originalX - b.originalX) < 1 then
                return a.originalY > b.originalY
            end
            return a.originalX < b.originalX
        end)
    end


    local stride = viewer.stride or #visibleChildren


    local overlap = -3
    local iconScale = 1.15


    for _, child in ipairs(visibleChildren) do
        if child.Icon then
            child.Icon:ClearAllPoints()
            child.Icon:SetPoint("CENTER", child, "CENTER", 0, 0)
            child.Icon:SetSize(child:GetWidth() * iconScale, child:GetHeight() * iconScale)
        end


    end


    local buttonWidth = visibleChildren[1]:GetWidth()
    local buttonHeight = visibleChildren[1]:GetHeight()


    local numIcons = #visibleChildren
    local totalWidth, totalHeight

    if isHorizontal then
        local cols = math.min(stride, numIcons)
        local rows = math.ceil(numIcons / stride)
        totalWidth = cols * buttonWidth + (cols - 1) * overlap
        totalHeight = rows * buttonHeight + (rows - 1) * overlap
    else
        local rows = math.min(stride, numIcons)
        local cols = math.ceil(numIcons / stride)
        totalWidth = cols * buttonWidth + (cols - 1) * overlap
        totalHeight = rows * buttonHeight + (rows - 1) * overlap
    end


    local startX = -totalWidth / 2
    local startY = totalHeight / 2

    if isHorizontal then

        for i, child in ipairs(visibleChildren) do
            local index = i - 1
			local row = math.floor(index / stride)
			local col = index % stride


			local rowStart = row * stride + 1
			local rowEnd = math.min(rowStart + stride - 1, numIcons)
			local iconsInRow = rowEnd - rowStart + 1


			local rowWidth = iconsInRow * buttonWidth + (iconsInRow - 1) * overlap


			local rowStartX = -rowWidth / 2


			local xOffset = rowStartX + col * (buttonWidth + overlap)
			local yOffset = startY - row * (buttonHeight + overlap)

			child:ClearAllPoints()
			child:SetPoint("CENTER", viewer, "CENTER", xOffset + buttonWidth/2, yOffset - buttonHeight/2)
        end
    else

        for i, child in ipairs(visibleChildren) do
            local row = (i - 1) % stride
            local col = math.floor((i - 1) / stride)

            local xOffset = startX + col * (buttonWidth + overlap)
            local yOffset = startY - row * (buttonHeight + overlap)

            child:ClearAllPoints()
            child:SetPoint("CENTER", viewer, "CENTER", xOffset + buttonWidth/2, yOffset - buttonHeight/2)
        end
    end
end


local updatePending = false


local function ScheduleUpdate(viewer)
    updateBucket[viewer] = true
    if updatePending then return end
    updatePending = true
    C_Timer.After(0, function()
        updatePending = false
        for v in pairs(updateBucket) do
            updateBucket[v] = nil
            RemovePadding(v)
        end
    end)
end


PREY.CooldownManager = {
    RemovePadding = RemovePadding,
    ScheduleUpdate = ScheduleUpdate,
}

