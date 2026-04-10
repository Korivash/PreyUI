local addonName, ns = ...


local function GetColors()
    local PREY = _G.PreyUI
    local sr, sg, sb, sa = 0.820, 0.180, 0.220, 1
    local bgr, bgg, bgb, bga = 0.05, 0.05, 0.05, 0.95

    if PREY and PREY.GetSkinColor then
        sr, sg, sb, sa = PREY:GetSkinColor()
    end
    if PREY and PREY.GetSkinBgColor then
        bgr, bgg, bgb, bga = PREY:GetSkinBgColor()
    end

    return sr, sg, sb, sa, bgr, bgg, bgb, bga
end


local function CreatePREYBackdrop(frame, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not frame.preyBackdrop then
        frame.preyBackdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.preyBackdrop:SetAllPoints()
        frame.preyBackdrop:SetFrameLevel(frame:GetFrameLevel())
        frame.preyBackdrop:EnableMouse(false)
    end

    frame.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    frame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
end


local function StripTextures(frame)
    if not frame then return end

    for i = 1, frame:GetNumRegions() do
        local region = select(i, frame:GetRegions())
        if region and region:IsObjectType("Texture") then
            region:SetAlpha(0)
        end
    end
end


local function StyleButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not button or button.preyStyled then return end

    if not button.preyBackdrop then
        button.preyBackdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.preyBackdrop:SetAllPoints()
        button.preyBackdrop:SetFrameLevel(button:GetFrameLevel())
        button.preyBackdrop:EnableMouse(false)
    end

    button.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })

    local btnBgR = math.min(bgr + 0.07, 1)
    local btnBgG = math.min(bgg + 0.07, 1)
    local btnBgB = math.min(bgb + 0.07, 1)
    button.preyBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
    button.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)


    if button.Left then button.Left:SetAlpha(0) end
    if button.Right then button.Right:SetAlpha(0) end
    if button.Middle then button.Middle:SetAlpha(0) end
    if button.Center then button.Center:SetAlpha(0) end

    local highlight = button:GetHighlightTexture()
    if highlight then highlight:SetAlpha(0) end
    local pushed = button:GetPushedTexture()
    if pushed then pushed:SetAlpha(0) end
    local normal = button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end


    button.preySkinColor = { sr, sg, sb, sa }

    button:HookScript("OnEnter", function(self)
        if self.preyBackdrop and self.preySkinColor then
            local r, g, b, a = unpack(self.preySkinColor)
            self.preyBackdrop:SetBackdropBorderColor(math.min(r * 1.3, 1), math.min(g * 1.3, 1), math.min(b * 1.3, 1), a)
        end
    end)
    button:HookScript("OnLeave", function(self)
        if self.preyBackdrop and self.preySkinColor then
            self.preyBackdrop:SetBackdropBorderColor(unpack(self.preySkinColor))
        end
    end)

    button.preyStyled = true
end


local function StyleDropdown(dropdown, sr, sg, sb, sa, bgr, bgg, bgb, bga, width)
    if not dropdown or dropdown.preyStyled then return end


    if width then
        dropdown:SetWidth(width)
    end


    if dropdown.NineSlice then dropdown.NineSlice:SetAlpha(0) end
    if dropdown.NormalTexture then dropdown.NormalTexture:SetAlpha(0) end
    if dropdown.HighlightTexture then dropdown.HighlightTexture:SetAlpha(0) end


    if not dropdown.preyBackdrop then
        dropdown.preyBackdrop = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
        dropdown.preyBackdrop:SetPoint("TOPLEFT", 0, -2)
        dropdown.preyBackdrop:SetPoint("BOTTOMRIGHT", 0, 2)
        dropdown.preyBackdrop:SetFrameLevel(dropdown:GetFrameLevel())
        dropdown.preyBackdrop:EnableMouse(false)
    end

    dropdown.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })

    local btnBgR = math.min(bgr + 0.07, 1)
    local btnBgG = math.min(bgg + 0.07, 1)
    local btnBgB = math.min(bgb + 0.07, 1)
    dropdown.preyBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
    dropdown.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)


    dropdown.preySkinColor = { sr, sg, sb, sa }

    dropdown:HookScript("OnEnter", function(self)
        if self.preyBackdrop and self.preySkinColor then
            local r, g, b, a = unpack(self.preySkinColor)
            self.preyBackdrop:SetBackdropBorderColor(math.min(r * 1.3, 1), math.min(g * 1.3, 1), math.min(b * 1.3, 1), a)
        end
    end)
    dropdown:HookScript("OnLeave", function(self)
        if self.preyBackdrop and self.preySkinColor then
            self.preyBackdrop:SetBackdropBorderColor(unpack(self.preySkinColor))
        end
    end)

    dropdown.preyStyled = true
end


local function StyleTab(tab, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not tab or tab.preyStyled then return end


    if tab.Left then tab.Left:SetAlpha(0) end
    if tab.Middle then tab.Middle:SetAlpha(0) end
    if tab.Right then tab.Right:SetAlpha(0) end
    if tab.LeftDisabled then tab.LeftDisabled:SetAlpha(0) end
    if tab.MiddleDisabled then tab.MiddleDisabled:SetAlpha(0) end
    if tab.RightDisabled then tab.RightDisabled:SetAlpha(0) end


    if tab.LeftActive then tab.LeftActive:SetAlpha(0) end
    if tab.MiddleActive then tab.MiddleActive:SetAlpha(0) end
    if tab.RightActive then tab.RightActive:SetAlpha(0) end


    if tab.LeftHighlight then tab.LeftHighlight:SetAlpha(0) end
    if tab.MiddleHighlight then tab.MiddleHighlight:SetAlpha(0) end
    if tab.RightHighlight then tab.RightHighlight:SetAlpha(0) end

    local highlight = tab:GetHighlightTexture()
    if highlight then highlight:SetAlpha(0) end


    if not tab.preyBackdrop then
        tab.preyBackdrop = CreateFrame("Frame", nil, tab, "BackdropTemplate")
        tab.preyBackdrop:SetPoint("TOPLEFT", 3, -3)
        tab.preyBackdrop:SetPoint("BOTTOMRIGHT", -3, 0)
        tab.preyBackdrop:SetFrameLevel(tab:GetFrameLevel())
        tab.preyBackdrop:EnableMouse(false)
    end

    tab.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    tab.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, 0.9)
    tab.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)

    tab.preyStyled = true
end


local function HidePVEDecorations()
    local PVEFrame = _G.PVEFrame
    if not PVEFrame then return end


    if PVEFrame.shadows then
        PVEFrame.shadows:Hide()

        StripTextures(PVEFrame.shadows)
    end


    if _G.PVEFrameBlueBg then _G.PVEFrameBlueBg:Hide() end
    if _G.PVEFrameTLCorner then _G.PVEFrameTLCorner:Hide() end
    if _G.PVEFrameTRCorner then _G.PVEFrameTRCorner:Hide() end
    if _G.PVEFrameBRCorner then _G.PVEFrameBRCorner:Hide() end
    if _G.PVEFrameBLCorner then _G.PVEFrameBLCorner:Hide() end
    if _G.PVEFrameLLVert then _G.PVEFrameLLVert:Hide() end
    if _G.PVEFrameRLVert then _G.PVEFrameRLVert:Hide() end
    if _G.PVEFrameBottomLine then _G.PVEFrameBottomLine:Hide() end
    if _G.PVEFrameTopLine then _G.PVEFrameTopLine:Hide() end
    if _G.PVEFrameTopFiligree then _G.PVEFrameTopFiligree:Hide() end
    if _G.PVEFrameBottomFiligree then _G.PVEFrameBottomFiligree:Hide() end


    if _G.PVEFrameLeftInset then _G.PVEFrameLeftInset:Hide() end
    if PVEFrame.Inset then
        PVEFrame.Inset:Hide()
        if PVEFrame.Inset.NineSlice then PVEFrame.Inset.NineSlice:Hide() end
        if PVEFrame.Inset.Bg then PVEFrame.Inset.Bg:Hide() end
    end


    if PVEFrame.NineSlice then PVEFrame.NineSlice:Hide() end
    if PVEFrame.Bg then PVEFrame.Bg:Hide() end
    if PVEFrame.Background then PVEFrame.Background:Hide() end


    if PVEFrame.PortraitContainer then PVEFrame.PortraitContainer:Hide() end
    if _G.PVEFramePortrait then _G.PVEFramePortrait:Hide() end


    if PVEFrame.TitleContainer then
        if PVEFrame.TitleContainer.TitleBg then PVEFrame.TitleContainer.TitleBg:Hide() end
    end
    if _G.PVEFrameTitleBg then _G.PVEFrameTitleBg:Hide() end


    if _G.PVEFrameTopBorder then _G.PVEFrameTopBorder:Hide() end
    if _G.PVEFrameTopRightCorner then _G.PVEFrameTopRightCorner:Hide() end
    if _G.PVEFrameRightBorder then _G.PVEFrameRightBorder:Hide() end
    if _G.PVEFrameBottomRightCorner then _G.PVEFrameBottomRightCorner:Hide() end
    if _G.PVEFrameBottomBorder then _G.PVEFrameBottomBorder:Hide() end
    if _G.PVEFrameBottomLeftCorner then _G.PVEFrameBottomLeftCorner:Hide() end
    if _G.PVEFrameLeftBorder then _G.PVEFrameLeftBorder:Hide() end
    if _G.PVEFrameBtnCornerLeft then _G.PVEFrameBtnCornerLeft:Hide() end
    if _G.PVEFrameBtnCornerRight then _G.PVEFrameBtnCornerRight:Hide() end
    if _G.PVEFrameButtonBottomBorder then _G.PVEFrameButtonBottomBorder:Hide() end


    if _G.PVEFrameBg then _G.PVEFrameBg:Hide() end
    if _G.PVEFrameBackground then _G.PVEFrameBackground:Hide() end
    if _G.PVEFrameInset then _G.PVEFrameInset:Hide() end
    if _G.PVEFrameNineSlice then _G.PVEFrameNineSlice:Hide() end


    StripTextures(PVEFrame)
end


local function StyleGroupFinderButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not button or button.preyStyled then return end


    if button.ring then button.ring:Hide() end
    if button.Ring then button.Ring:Hide() end
    if button.bg then button.bg:SetAlpha(0) end
    if button.Background then button.Background:Hide() end


    if not button.preyBackdrop then
        button.preyBackdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.preyBackdrop:SetAllPoints()
        button.preyBackdrop:SetFrameLevel(button:GetFrameLevel())
        button.preyBackdrop:EnableMouse(false)
    end

    button.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })

    local btnBgR = math.min(bgr + 0.07, 1)
    local btnBgG = math.min(bgg + 0.07, 1)
    local btnBgB = math.min(bgb + 0.07, 1)
    button.preyBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
    button.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)


    if button.icon then
        button.icon:SetSize(40, 40)
        button.icon:ClearAllPoints()
        button.icon:SetPoint("LEFT", 8, 0)
        button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)


        if not button.icon.preyBackdrop then
            button.icon.preyBackdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
            button.icon.preyBackdrop:SetPoint("TOPLEFT", button.icon, -1, 1)
            button.icon.preyBackdrop:SetPoint("BOTTOMRIGHT", button.icon, 1, -1)
            button.icon.preyBackdrop:SetFrameLevel(button:GetFrameLevel())
            button.icon.preyBackdrop:EnableMouse(false)
            button.icon.preyBackdrop:SetBackdrop({
                bgFile = nil,
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            button.icon.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        end
    end


    button.preySkinColor = { sr, sg, sb, sa }

    button:HookScript("OnEnter", function(self)
        if self.preyBackdrop and self.preySkinColor then
            local r, g, b, a = unpack(self.preySkinColor)
            self.preyBackdrop:SetBackdropBorderColor(math.min(r * 1.3, 1), math.min(g * 1.3, 1), math.min(b * 1.3, 1), a)
        end
    end)
    button:HookScript("OnLeave", function(self)
        if self.preyBackdrop and self.preySkinColor then
            self.preyBackdrop:SetBackdropBorderColor(unpack(self.preySkinColor))
        end
    end)

    button.preyStyled = true
end


local function StyleCloseButton(closeButton)
    if not closeButton then return end
    if closeButton.Border then closeButton.Border:SetAlpha(0) end
end


local function SkinPVEFrame()
    local PVEFrame = _G.PVEFrame
    if not PVEFrame or PVEFrame.preySkinned then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetColors()


    HidePVEDecorations()


    CreatePREYBackdrop(PVEFrame, sr, sg, sb, sa, bgr, bgg, bgb, bga)


    local closeButton = PVEFrame.CloseButton or _G.PVEFrameCloseButton
    if closeButton then
        StyleCloseButton(closeButton)
    end


    for i = 1, 4 do
        local tab = rawget(_G, "PVEFrameTab" .. i)
        if tab then
            StyleTab(tab, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end


    local tab1 = rawget(_G, "PVEFrameTab1")
    local tab2 = rawget(_G, "PVEFrameTab2")
    local tab3 = rawget(_G, "PVEFrameTab3")
    if tab1 then tab1:ClearAllPoints() end
    if tab2 then tab2:ClearAllPoints() end
    if tab3 then tab3:ClearAllPoints() end
    if tab1 then tab1:SetPoint("BOTTOMLEFT", PVEFrame, "BOTTOMLEFT", -3, -30) end
    if tab2 and tab1 then tab2:SetPoint("TOPLEFT", tab1, "TOPRIGHT", -5, 0) end
    if tab3 and tab2 then tab3:SetPoint("TOPLEFT", tab2, "TOPRIGHT", -5, 0) end


    hooksecurefunc("PVEFrame_ShowFrame", function()
        local tab4 = _G.PVEFrameTab4
        if not tab4 or not tab4:IsShown() then return end
        local twoShown = _G.PVEFrameTab2:IsShown()
        local threeShown = _G.PVEFrameTab3:IsShown()
        tab4:ClearAllPoints()
        tab4:SetPoint("TOPLEFT", (twoShown and threeShown and _G.PVEFrameTab3) or (twoShown and not threeShown and _G.PVEFrameTab2) or _G.PVEFrameTab1, "TOPRIGHT", -5, 0)
    end)


    local GroupFinderFrame = _G.GroupFinderFrame
    if GroupFinderFrame then
        for i = 1, 4 do
            local button = GroupFinderFrame["groupButton" .. i]
            if button then
                StyleGroupFinderButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            end
        end
    end

    PVEFrame.preySkinned = true
end


local function HideLFDDecorations()
    local LFDQueueFrame = _G.LFDQueueFrame
    if not LFDQueueFrame then return end


    if _G.LFDParentFrame then
        StripTextures(_G.LFDParentFrame)
    end
    if _G.LFDParentFrameInset then
        StripTextures(_G.LFDParentFrameInset)
        _G.LFDParentFrameInset:Hide()
    end


    if LFDQueueFrame.Bg then LFDQueueFrame.Bg:Hide() end
    if LFDQueueFrame.Background then LFDQueueFrame.Background:Hide() end
    if LFDQueueFrame.NineSlice then LFDQueueFrame.NineSlice:Hide() end


    if _G.LFDQueueFrameBackground then _G.LFDQueueFrameBackground:Hide() end
    if _G.LFDQueueFrameRandomScrollFrameScrollBarBorder then
        _G.LFDQueueFrameRandomScrollFrameScrollBarBorder:Hide()
    end


    if LFDQueueFrame.Dropdown then
        if LFDQueueFrame.Dropdown.Left then LFDQueueFrame.Dropdown.Left:SetAlpha(0) end
        if LFDQueueFrame.Dropdown.Right then LFDQueueFrame.Dropdown.Right:SetAlpha(0) end
        if LFDQueueFrame.Dropdown.Middle then LFDQueueFrame.Dropdown.Middle:SetAlpha(0) end
    end

    StripTextures(LFDQueueFrame)
end


local function HideRaidFinderDecorations()
    local RaidFinderFrame = _G.RaidFinderFrame
    if not RaidFinderFrame then return end

    StripTextures(RaidFinderFrame)


    if _G.RaidFinderFrameRoleBackground then
        _G.RaidFinderFrameRoleBackground:Hide()
    end
    if RaidFinderFrame.RoleBackground then
        RaidFinderFrame.RoleBackground:Hide()
    end


    local roleInset = _G.RaidFinderFrameRoleInset or (RaidFinderFrame.Inset)
    if roleInset then
        StripTextures(roleInset)
        roleInset:Hide()
    end


    local bottomInset = _G.RaidFinderFrameBottomInset
    if bottomInset then
        StripTextures(bottomInset)
        bottomInset:Hide()
    end


    local RaidFinderQueueFrame = _G.RaidFinderQueueFrame
    if RaidFinderQueueFrame then
        StripTextures(RaidFinderQueueFrame)
        if RaidFinderQueueFrame.Bg then RaidFinderQueueFrame.Bg:Hide() end
        if RaidFinderQueueFrame.Background then RaidFinderQueueFrame.Background:Hide() end


        local scrollFrame = _G.RaidFinderQueueFrameScrollFrame
        if scrollFrame then
            StripTextures(scrollFrame)
        end
    end


    if _G.RaidFinderQueueFrameBackground then _G.RaidFinderQueueFrameBackground:Hide() end


    for _, name in ipairs({"NineSlice", "Bg", "Border", "Background", "InsetBorderTop", "InsetBorderBottom", "InsetBorderLeft", "InsetBorderRight"}) do
        local child = RaidFinderFrame[name]
        if child and child.Hide then child:Hide() end
    end
end


local function SkinLFDFrame()
    local LFDQueueFrame = _G.LFDQueueFrame
    if not LFDQueueFrame or LFDQueueFrame.preySkinned then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetColors()


    HideLFDDecorations()


    local roles = { "Tank", "Healer", "DPS" }
    for _, role in ipairs(roles) do
        local button = rawget(_G, "LFDQueueFrameRoleButton" .. role)
        if button then

            if button.background then button.background:SetAlpha(0) end
            if button.Background then button.Background:SetAlpha(0) end

            local bgTex = rawget(_G, "LFDQueueFrameRoleButton" .. role .. "Background")
            if bgTex then bgTex:SetAlpha(0) end

            if button.shortageBorder then button.shortageBorder:SetAlpha(0) end
            if button.cover then button.cover:SetAlpha(0) end
            if button.checkButton then

                local check = button.checkButton
                if check.SetNormalTexture then check:SetNormalTexture("") end
                if check.SetPushedTexture then check:SetPushedTexture("") end
            end
            local incentiveIcon = rawget(_G, "LFDQueueFrameRoleButton" .. role .. "IncentiveIcon")
            if incentiveIcon then incentiveIcon:SetAlpha(0) end
        end
    end


    if _G.LFDQueueFrameFindGroupButton then
        StyleButton(_G.LFDQueueFrameFindGroupButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    end


    local typeDropdown = LFDQueueFrame.TypeDropdown or _G.LFDQueueFrameTypeDropdown
    if typeDropdown then
        StyleDropdown(typeDropdown, sr, sg, sb, sa, bgr, bgg, bgb, bga, 200)
    end

    LFDQueueFrame.preySkinned = true
end


local function SkinRaidFinderFrame()
    local RaidFinderQueueFrame = _G.RaidFinderQueueFrame
    if not RaidFinderQueueFrame or RaidFinderQueueFrame.preySkinned then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetColors()


    HideRaidFinderDecorations()


    local roles = { "Tank", "Healer", "DPS" }
    for _, role in ipairs(roles) do
        local button = rawget(_G, "RaidFinderQueueFrameRoleButton" .. role)
        if button then

            if button.background then button.background:SetAlpha(0) end
            if button.Background then button.Background:SetAlpha(0) end
            local bgTex = rawget(_G, "RaidFinderQueueFrameRoleButton" .. role .. "Background")
            if bgTex then bgTex:SetAlpha(0) end

            if button.shortageBorder then button.shortageBorder:SetAlpha(0) end
            if button.cover then button.cover:SetAlpha(0) end
            if button.checkButton then
                local check = button.checkButton
                if check.SetNormalTexture then check:SetNormalTexture("") end
                if check.SetPushedTexture then check:SetPushedTexture("") end
            end
            local incentiveIcon = rawget(_G, "RaidFinderQueueFrameRoleButton" .. role .. "IncentiveIcon")
            if incentiveIcon then incentiveIcon:SetAlpha(0) end
        end
    end


    if _G.RaidFinderFrameFindRaidButton then
        StyleButton(_G.RaidFinderFrameFindRaidButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    end


    local selectionDropdown = RaidFinderQueueFrame.SelectionDropdown
    if selectionDropdown then
        StyleDropdown(selectionDropdown, sr, sg, sb, sa, bgr, bgg, bgb, bga, 200)
    end

    RaidFinderQueueFrame.preySkinned = true
end


local function HideLFGListDecorations()
    local LFGListFrame = _G.LFGListFrame
    if not LFGListFrame then return end


    if LFGListFrame.Bg then LFGListFrame.Bg:Hide() end
    if LFGListFrame.Background then LFGListFrame.Background:Hide() end
    if LFGListFrame.NineSlice then LFGListFrame.NineSlice:Hide() end


    if LFGListFrame.CategorySelection then
        local cs = LFGListFrame.CategorySelection
        if cs.Inset then
            cs.Inset:Hide()
            if cs.Inset.NineSlice then cs.Inset.NineSlice:Hide() end
        end
        StripTextures(cs)
    end


    if LFGListFrame.SearchPanel then
        local sp = LFGListFrame.SearchPanel
        if sp.ResultsInset then
            sp.ResultsInset:Hide()
            if sp.ResultsInset.NineSlice then sp.ResultsInset.NineSlice:Hide() end
        end
        if sp.AutoCompleteFrame then
            StripTextures(sp.AutoCompleteFrame)
        end
        StripTextures(sp)
    end


    if LFGListFrame.ApplicationViewer then
        local av = LFGListFrame.ApplicationViewer
        if av.Inset then
            av.Inset:Hide()
            if av.Inset.NineSlice then av.Inset.NineSlice:Hide() end
        end
        if av.InfoBackground then av.InfoBackground:Hide() end
        StripTextures(av)
    end


    if LFGListFrame.EntryCreation then
        local ec = LFGListFrame.EntryCreation
        if ec.Inset then
            ec.Inset:Hide()
            if ec.Inset.NineSlice then ec.Inset.NineSlice:Hide() end
        end
        StripTextures(ec)
    end

    StripTextures(LFGListFrame)
end


local function SkinLFGListFrame()
    local LFGListFrame = _G.LFGListFrame
    if not LFGListFrame or LFGListFrame.preySkinned then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetColors()


    HideLFGListDecorations()


    if LFGListFrame.CategorySelection then
        local cs = LFGListFrame.CategorySelection
        if cs.StartGroupButton then
            StyleButton(cs.StartGroupButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
        if cs.FindGroupButton then
            StyleButton(cs.FindGroupButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end

        if cs.CategoryButtons then
            for _, catButton in pairs(cs.CategoryButtons) do
                if catButton and not catButton.preyStyled then
                    StripTextures(catButton)
                    StyleButton(catButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
                end
            end
        end
    end


    if LFGListFrame.SearchPanel then
        local sp = LFGListFrame.SearchPanel
        if sp.BackButton then
            StyleButton(sp.BackButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
        if sp.SignUpButton then
            StyleButton(sp.SignUpButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
        if sp.RefreshButton then
            StyleButton(sp.RefreshButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end

        if sp.SearchBox then
            StripTextures(sp.SearchBox)
            CreatePREYBackdrop(sp.SearchBox, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end

        if sp.FilterButton then
            StyleButton(sp.FilterButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end


    if LFGListFrame.ApplicationViewer then
        local av = LFGListFrame.ApplicationViewer
        if av.RefreshButton then
            StyleButton(av.RefreshButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
        if av.RemoveEntryButton then
            StyleButton(av.RemoveEntryButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
        if av.EditButton then
            StyleButton(av.EditButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end


    if LFGListFrame.EntryCreation then
        local ec = LFGListFrame.EntryCreation
        if ec.ListGroupButton then
            StyleButton(ec.ListGroupButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
        if ec.CancelButton then
            StyleButton(ec.CancelButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end

    LFGListFrame.preySkinned = true
end


local function HideChallengesDecorations()
    local ChallengesFrame = _G.ChallengesFrame
    if not ChallengesFrame then return end


    if ChallengesFrame.Background then ChallengesFrame.Background:Hide() end
    if ChallengesFrame.Bg then ChallengesFrame.Bg:Hide() end
    if ChallengesFrame.NineSlice then ChallengesFrame.NineSlice:Hide() end


    if ChallengesFrame.SeasonChangeNoticeFrame then
        StripTextures(ChallengesFrame.SeasonChangeNoticeFrame)
    end

    StripTextures(ChallengesFrame)
end


local function StyleDungeonIcon(icon, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not icon or icon.preyStyled then return end


    if icon.Bg then icon.Bg:SetAlpha(0) end
    if icon.Background then icon.Background:SetAlpha(0) end


    if icon.Icon then
        icon.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        if not icon.Icon.preyBackdrop then
            icon.Icon.preyBackdrop = CreateFrame("Frame", nil, icon, "BackdropTemplate")
            icon.Icon.preyBackdrop:SetPoint("TOPLEFT", icon.Icon, -1, 1)
            icon.Icon.preyBackdrop:SetPoint("BOTTOMRIGHT", icon.Icon, 1, -1)
            icon.Icon.preyBackdrop:SetFrameLevel(icon:GetFrameLevel())
            icon.Icon.preyBackdrop:EnableMouse(false)
            icon.Icon.preyBackdrop:SetBackdrop({
                bgFile = nil,
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            icon.Icon.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        end
    end


    icon.preySkinColor = { sr, sg, sb, sa }

    icon.preyStyled = true
end


local function StyleAffixIcon(affix, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not affix or affix.preyStyled then return end


    if affix.Border then affix.Border:SetAlpha(0) end


    if affix.Portrait then
        affix.Portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        if not affix.Portrait.preyBackdrop then
            affix.Portrait.preyBackdrop = CreateFrame("Frame", nil, affix, "BackdropTemplate")
            affix.Portrait.preyBackdrop:SetPoint("TOPLEFT", affix.Portrait, -1, 1)
            affix.Portrait.preyBackdrop:SetPoint("BOTTOMRIGHT", affix.Portrait, 1, -1)
            affix.Portrait.preyBackdrop:SetFrameLevel(affix:GetFrameLevel())
            affix.Portrait.preyBackdrop:EnableMouse(false)
            affix.Portrait.preyBackdrop:SetBackdrop({
                bgFile = nil,
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            affix.Portrait.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        end
    end

    affix.preyStyled = true
end


local function SkinChallengesFrame()
    local ChallengesFrame = _G.ChallengesFrame
    if not ChallengesFrame or ChallengesFrame.preySkinned then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetColors()


    HideChallengesDecorations()


    if ChallengesFrame.WeeklyInfo then
        local wi = ChallengesFrame.WeeklyInfo
        if wi.Child then
            if wi.Child.WeeklyChest then
                local chest = wi.Child.WeeklyChest
                if chest.Highlight then chest.Highlight:SetAlpha(0) end
            end

            if wi.Child.Label then
                local PREY = _G.PreyUI
                local fontPath = PREY and PREY.GetGlobalFont and PREY:GetGlobalFont() or STANDARD_TEXT_FONT
                wi.Child.Label:SetFont(fontPath, 14, "OUTLINE")
            end
        end
    end


    if ChallengesFrame.DungeonIcons then
        for _, icon in pairs(ChallengesFrame.DungeonIcons) do
            StyleDungeonIcon(icon, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end


    if ChallengesFrame.Update and not ChallengesFrame.preyUpdateHooked then
        hooksecurefunc(ChallengesFrame, "Update", function(self)
            if self.DungeonIcons then
                local sr2, sg2, sb2, sa2, bgr2, bgg2, bgb2, bga2 = GetColors()
                for _, icon in pairs(self.DungeonIcons) do
                    StyleDungeonIcon(icon, sr2, sg2, sb2, sa2, bgr2, bgg2, bgb2, bga2)
                end
            end
        end)
        ChallengesFrame.preyUpdateHooked = true
    end


    if ChallengesFrame.WeeklyInfo and ChallengesFrame.WeeklyInfo.Child then
        local affixContainer = ChallengesFrame.WeeklyInfo.Child.AffixesContainer
        if affixContainer and affixContainer.Affixes then
            for _, affix in pairs(affixContainer.Affixes) do
                StyleAffixIcon(affix, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            end
        end
    end


    for i = 1, 4 do
        local affix = ChallengesFrame["Affix" .. i]
        if affix then
            StyleAffixIcon(affix, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end

    ChallengesFrame.preySkinned = true
end


local function HidePVPDecorations()
    local PVPQueueFrame = _G.PVPQueueFrame
    if not PVPQueueFrame then return end


    if PVPQueueFrame.Bg then PVPQueueFrame.Bg:Hide() end
    if PVPQueueFrame.Background then PVPQueueFrame.Background:Hide() end
    if PVPQueueFrame.NineSlice then PVPQueueFrame.NineSlice:Hide() end


    if PVPQueueFrame.HonorInset then
        if PVPQueueFrame.HonorInset.NineSlice then PVPQueueFrame.HonorInset.NineSlice:Hide() end
    end


    if _G.HonorFrame then
        local hf = _G.HonorFrame
        if hf.Bg then hf.Bg:Hide() end
        if hf.Background then hf.Background:Hide() end
        if hf.NineSlice then hf.NineSlice:Hide() end
        if hf.Inset then
            hf.Inset:Hide()
            if hf.Inset.NineSlice then hf.Inset.NineSlice:Hide() end
        end

        if hf.BonusFrame then
            if hf.BonusFrame.ShadowOverlay then hf.BonusFrame.ShadowOverlay:Hide() end
            if hf.BonusFrame.WorldBattlesTexture then hf.BonusFrame.WorldBattlesTexture:Hide() end
            StripTextures(hf.BonusFrame)
        end
        StripTextures(hf)
    end


    if _G.ConquestFrame then
        local cf = _G.ConquestFrame
        if cf.Bg then cf.Bg:Hide() end
        if cf.Background then cf.Background:Hide() end
        if cf.NineSlice then cf.NineSlice:Hide() end
        if cf.Inset then
            cf.Inset:Hide()
            if cf.Inset.NineSlice then cf.Inset.NineSlice:Hide() end
        end
        if cf.ShadowOverlay then cf.ShadowOverlay:Hide() end
        StripTextures(cf)
    end

    StripTextures(PVPQueueFrame)
end


local function StylePVPActivityButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not button or button.preyStyled then return end


    if button.Bg then button.Bg:Hide() end
    if button.Border then button.Border:Hide() end
    if button.Ring then button.Ring:Hide() end


    if not button.preyBackdrop then
        button.preyBackdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.preyBackdrop:SetAllPoints()
        button.preyBackdrop:SetFrameLevel(button:GetFrameLevel())
        button.preyBackdrop:EnableMouse(false)
    end

    button.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })

    local btnBgR = math.min(bgr + 0.07, 1)
    local btnBgG = math.min(bgg + 0.07, 1)
    local btnBgB = math.min(bgb + 0.07, 1)
    button.preyBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
    button.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)


    if button.SelectedTexture then
        button.SelectedTexture:SetColorTexture(sr, sg, sb, 0.2)
    end


    if button.Reward then
        local reward = button.Reward
        if reward.Border then reward.Border:Hide() end
        if reward.CircleMask then reward.CircleMask:Hide() end
        if reward.Icon then
            reward.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            if not reward.Icon.preyBackdrop then
                reward.Icon.preyBackdrop = CreateFrame("Frame", nil, reward, "BackdropTemplate")
                reward.Icon.preyBackdrop:SetPoint("TOPLEFT", reward.Icon, -1, 1)
                reward.Icon.preyBackdrop:SetPoint("BOTTOMRIGHT", reward.Icon, 1, -1)
                reward.Icon.preyBackdrop:SetFrameLevel(reward:GetFrameLevel())
                reward.Icon.preyBackdrop:EnableMouse(false)
                reward.Icon.preyBackdrop:SetBackdrop({
                    bgFile = nil,
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                })
                reward.Icon.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
            end
        end
    end


    button.preySkinColor = { sr, sg, sb, sa }

    button:HookScript("OnEnter", function(self)
        if self.preyBackdrop and self.preySkinColor then
            local r, g, b, a = unpack(self.preySkinColor)
            self.preyBackdrop:SetBackdropBorderColor(math.min(r * 1.3, 1), math.min(g * 1.3, 1), math.min(b * 1.3, 1), a)
        end
    end)
    button:HookScript("OnLeave", function(self)
        if self.preyBackdrop and self.preySkinColor then
            self.preyBackdrop:SetBackdropBorderColor(unpack(self.preySkinColor))
        end
    end)

    button.preyStyled = true
end


local function StylePVPRoleIcon(roleIcon, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not roleIcon or roleIcon.preyStyled then return end


    if roleIcon.background then roleIcon.background:SetAlpha(0) end
    if roleIcon.Background then roleIcon.Background:SetAlpha(0) end
    if roleIcon.shortageBorder then roleIcon.shortageBorder:SetAlpha(0) end
    if roleIcon.cover then roleIcon.cover:SetAlpha(0) end

    roleIcon.preyStyled = true
end


local function StyleSpecificBGButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not button or button.preyStyled then return end


    if button.Bg then button.Bg:Hide() end
    if button.Border then button.Border:Hide() end
    if button.HighlightTexture then button.HighlightTexture:SetAlpha(0) end


    if not button.preyBackdrop then
        button.preyBackdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.preyBackdrop:SetAllPoints()
        button.preyBackdrop:SetFrameLevel(button:GetFrameLevel())
        button.preyBackdrop:EnableMouse(false)
    end

    button.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })

    local btnBgR = math.min(bgr + 0.05, 1)
    local btnBgG = math.min(bgg + 0.05, 1)
    local btnBgB = math.min(bgb + 0.05, 1)
    button.preyBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 0.9)
    button.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)


    if button.SelectedTexture then
        button.SelectedTexture:SetColorTexture(sr, sg, sb, 0.3)
        button.SelectedTexture:SetAllPoints()
    end


    if button.Icon then
        button.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        if not button.Icon.preyBackdrop then
            button.Icon.preyBackdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
            button.Icon.preyBackdrop:SetPoint("TOPLEFT", button.Icon, -1, 1)
            button.Icon.preyBackdrop:SetPoint("BOTTOMRIGHT", button.Icon, 1, -1)
            button.Icon.preyBackdrop:SetFrameLevel(button:GetFrameLevel())
            button.Icon.preyBackdrop:EnableMouse(false)
            button.Icon.preyBackdrop:SetBackdrop({
                bgFile = nil,
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            button.Icon.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        end
    end


    button:HookScript("OnEnter", function(self)
        if self.preyBackdrop then
            self.preyBackdrop:SetBackdropBorderColor(1, 1, 1, 1)
        end
    end)
    button:HookScript("OnLeave", function(self)
        if self.preyBackdrop then
            self.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        end
    end)

    button.preyStyled = true
end


local function StyleConquestBar(bar, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not bar or bar.preyStyled then return end

    if bar.Border then bar.Border:Hide() end
    if bar.Background then bar.Background:Hide() end


    if not bar.preyBackdrop then
        bar.preyBackdrop = CreateFrame("Frame", nil, bar, "BackdropTemplate")
        bar.preyBackdrop:SetAllPoints()
        bar.preyBackdrop:SetFrameLevel(bar:GetFrameLevel())
        bar.preyBackdrop:EnableMouse(false)
    end

    bar.preyBackdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    bar.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, 0.8)
    bar.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)


    if bar.Reward then
        if bar.Reward.Ring then bar.Reward.Ring:Hide() end
        if bar.Reward.CircleMask then bar.Reward.CircleMask:Hide() end
        if bar.Reward.Icon then
            bar.Reward.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
    end

    bar.preyStyled = true
end


local function GetRoleIcons(frame)
    if not frame then return nil, nil, nil end

    if frame.RoleList then
        return frame.RoleList.TankIcon, frame.RoleList.HealerIcon, frame.RoleList.DPSIcon
    end

    return frame.TankIcon, frame.HealerIcon, frame.DPSIcon
end


local function StylePVPFrameRoleIcons(frame, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    local tankIcon, healerIcon, dpsIcon = GetRoleIcons(frame)
    if tankIcon then StylePVPRoleIcon(tankIcon, sr, sg, sb, sa, bgr, bgg, bgb, bga) end
    if healerIcon then StylePVPRoleIcon(healerIcon, sr, sg, sb, sa, bgr, bgg, bgb, bga) end
    if dpsIcon then StylePVPRoleIcon(dpsIcon, sr, sg, sb, sa, bgr, bgg, bgb, bga) end
end


local function SkinPVPFrame()
    local PVPQueueFrame = _G.PVPQueueFrame
    if not PVPQueueFrame or PVPQueueFrame.preySkinned then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetColors()


    HidePVPDecorations()


    for i = 1, 5 do
        local catButton = PVPQueueFrame["CategoryButton" .. i] or rawget(_G, "PVPQueueFrameCategoryButton" .. i)
        if catButton then
            StyleGroupFinderButton(catButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end


    local HonorFrame = _G.HonorFrame
    if HonorFrame then

        if _G.HonorFrameQueueButton then
            StyleButton(_G.HonorFrameQueueButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end


        local typeDropdown = HonorFrame.TypeDropdown or _G.HonorFrameTypeDropdown
        if typeDropdown then
            StyleDropdown(typeDropdown, sr, sg, sb, sa, bgr, bgg, bgb, bga, 230)
        end


        StylePVPFrameRoleIcons(HonorFrame, sr, sg, sb, sa, bgr, bgg, bgb, bga)


        if HonorFrame.BonusFrame then
            local bf = HonorFrame.BonusFrame
            local bonusButtons = { "RandomBGButton", "Arena1Button", "RandomEpicBGButton", "BrawlButton", "BrawlButton2", "SpecialEventButton" }
            for _, btnName in ipairs(bonusButtons) do
                if bf[btnName] then
                    StylePVPActivityButton(bf[btnName], sr, sg, sb, sa, bgr, bgg, bgb, bga)
                end
            end
        end


        if HonorFrame.ConquestBar then
            StyleConquestBar(HonorFrame.ConquestBar, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end


        if HonorFrame.SpecificScrollBox and not HonorFrame.SpecificScrollBox.preyHooked then

            hooksecurefunc(HonorFrame.SpecificScrollBox, "Update", function(scrollBox)
                scrollBox:ForEachFrame(function(button)
                    StyleSpecificBGButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
                end)
            end)

            HonorFrame.SpecificScrollBox:ForEachFrame(function(button)
                StyleSpecificBGButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            end)
            HonorFrame.SpecificScrollBox.preyHooked = true
        end


        if HonorFrame.SpecificScrollBar then
            if HonorFrame.SpecificScrollBar.Background then
                HonorFrame.SpecificScrollBar.Background:Hide()
            end
        end
    end


    local ConquestFrame = _G.ConquestFrame
    if ConquestFrame then

        if _G.ConquestJoinButton then
            StyleButton(_G.ConquestJoinButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end


        StylePVPFrameRoleIcons(ConquestFrame, sr, sg, sb, sa, bgr, bgg, bgb, bga)


        local conquestButtons = { "RatedSoloShuffle", "RatedBGBlitz", "Arena2v2", "Arena3v3", "RatedBG" }
        for _, btnName in ipairs(conquestButtons) do
            if ConquestFrame[btnName] then
                StylePVPActivityButton(ConquestFrame[btnName], sr, sg, sb, sa, bgr, bgg, bgb, bga)
            end
        end


        if ConquestFrame.ConquestBar then
            StyleConquestBar(ConquestFrame.ConquestBar, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end


    local TrainingGroundsFrame = _G.TrainingGroundsFrame
    if TrainingGroundsFrame then

        StripTextures(TrainingGroundsFrame)
        if TrainingGroundsFrame.Bg then TrainingGroundsFrame.Bg:Hide() end
        if TrainingGroundsFrame.Background then TrainingGroundsFrame.Background:Hide() end


        if TrainingGroundsFrame.Inset then
            StripTextures(TrainingGroundsFrame.Inset)
            if TrainingGroundsFrame.Inset.NineSlice then
                TrainingGroundsFrame.Inset.NineSlice:Hide()
            end
        end


        local bonusList = TrainingGroundsFrame.BonusTrainingGroundList
        if bonusList then
            if bonusList.WorldBattlesTexture then bonusList.WorldBattlesTexture:Hide() end
            if bonusList.ShadowOverlay then bonusList.ShadowOverlay:Hide() end

            if bonusList.RandomTrainingGroundButton then
                StylePVPActivityButton(bonusList.RandomTrainingGroundButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            end
        end


        if TrainingGroundsFrame.QueueButton then
            StyleButton(TrainingGroundsFrame.QueueButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end


        if TrainingGroundsFrame.TypeDropdown then
            StyleDropdown(TrainingGroundsFrame.TypeDropdown, sr, sg, sb, sa, bgr, bgg, bgb, bga, 230)
        end


        StylePVPFrameRoleIcons(TrainingGroundsFrame, sr, sg, sb, sa, bgr, bgg, bgb, bga)


        if TrainingGroundsFrame.ConquestBar then
            StyleConquestBar(TrainingGroundsFrame.ConquestBar, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end


        local specificList = TrainingGroundsFrame.SpecificTrainingGroundList
        if specificList and specificList.ScrollBox and not specificList.ScrollBox.preyHooked then

            hooksecurefunc(specificList.ScrollBox, "Update", function(scrollBox)
                scrollBox:ForEachFrame(function(button)
                    StyleSpecificBGButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
                end)
            end)

            specificList.ScrollBox:ForEachFrame(function(button)
                StyleSpecificBGButton(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            end)
            specificList.ScrollBox.preyHooked = true


            if specificList.ScrollBar and specificList.ScrollBar.Background then
                specificList.ScrollBar.Background:Hide()
            end
        end

        TrainingGroundsFrame.preySkinned = true
    end


    local PlunderstormFrame = _G.PlunderstormFrame
    if PlunderstormFrame then

        StripTextures(PlunderstormFrame)
        if PlunderstormFrame.Bg then PlunderstormFrame.Bg:Hide() end
        if PlunderstormFrame.Background then PlunderstormFrame.Background:Hide() end


        if PlunderstormFrame.QueueButton then
            StyleButton(PlunderstormFrame.QueueButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end

        PlunderstormFrame.preySkinned = true
    end

    PVPQueueFrame.preySkinned = true
end


local function SkinInstanceFrames()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    local settings = PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general
    if not settings or not settings.skinInstanceFrames then return end

    SkinPVEFrame()
    SkinLFDFrame()
    SkinRaidFinderFrame()
    SkinLFGListFrame()
    SkinChallengesFrame()
    SkinPVPFrame()
end


local function UpdateButtonColors(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not button or not button.preyBackdrop then return end
    local btnBgR = math.min(bgr + 0.07, 1)
    local btnBgG = math.min(bgg + 0.07, 1)
    local btnBgB = math.min(bgb + 0.07, 1)
    button.preyBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
    button.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    button.preySkinColor = { sr, sg, sb, sa }
end


local function UpdateTabColors(tab, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not tab or not tab.preyBackdrop then return end
    tab.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, 0.9)
    tab.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
end


local function UpdateGroupFinderButtonColors(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not button or not button.preyBackdrop then return end
    local btnBgR = math.min(bgr + 0.07, 1)
    local btnBgG = math.min(bgg + 0.07, 1)
    local btnBgB = math.min(bgb + 0.07, 1)
    button.preyBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
    button.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    button.preySkinColor = { sr, sg, sb, sa }

    if button.icon and button.icon.preyBackdrop then
        button.icon.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end
end


local function UpdatePVPActivityButtonColors(button, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not button or not button.preyBackdrop then return end
    local btnBgR = math.min(bgr + 0.07, 1)
    local btnBgG = math.min(bgg + 0.07, 1)
    local btnBgB = math.min(bgb + 0.07, 1)
    button.preyBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
    button.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    button.preySkinColor = { sr, sg, sb, sa }
    if button.SelectedTexture then
        button.SelectedTexture:SetColorTexture(sr, sg, sb, 0.2)
    end
    if button.Reward and button.Reward.Icon and button.Reward.Icon.preyBackdrop then
        button.Reward.Icon.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end
end


local function UpdateConquestBarColors(bar, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not bar or not bar.preyBackdrop then return end
    bar.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, 0.8)
    bar.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
end


local function UpdateDungeonIconColors(icon, sr, sg, sb, sa)
    if not icon or not icon.Icon or not icon.Icon.preyBackdrop then return end
    icon.Icon.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    icon.preySkinColor = { sr, sg, sb, sa }
end


local function UpdateAffixIconColors(affix, sr, sg, sb, sa)
    if not affix or not affix.Portrait or not affix.Portrait.preyBackdrop then return end
    affix.Portrait.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
end


local function UpdateDropdownColors(dropdown, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    if not dropdown or not dropdown.preyBackdrop then return end
    local btnBgR = math.min(bgr + 0.07, 1)
    local btnBgG = math.min(bgg + 0.07, 1)
    local btnBgB = math.min(bgb + 0.07, 1)
    dropdown.preyBackdrop:SetBackdropColor(btnBgR, btnBgG, btnBgB, 1)
    dropdown.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    dropdown.preySkinColor = { sr, sg, sb, sa }
end


local function RefreshInstanceFramesColors()
    local PVEFrame = _G.PVEFrame
    if not PVEFrame or not PVEFrame.preySkinned then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetColors()


    if PVEFrame.preyBackdrop then
        PVEFrame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        PVEFrame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end


    for i = 1, 4 do
        UpdateTabColors(rawget(_G, "PVEFrameTab" .. i), sr, sg, sb, sa, bgr, bgg, bgb, bga)
    end


    local GroupFinderFrame = _G.GroupFinderFrame
    if GroupFinderFrame then
        for i = 1, 4 do
            UpdateGroupFinderButtonColors(GroupFinderFrame["groupButton" .. i], sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end


    UpdateButtonColors(_G.LFDQueueFrameFindGroupButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
    local LFDQueueFrame = _G.LFDQueueFrame
    if LFDQueueFrame then
        local typeDropdown = LFDQueueFrame.TypeDropdown or _G.LFDQueueFrameTypeDropdown
        if typeDropdown then
            UpdateDropdownColors(typeDropdown, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end


    local RaidFinderQueueFrame = _G.RaidFinderQueueFrame
    if RaidFinderQueueFrame and RaidFinderQueueFrame.preySkinned then
        UpdateButtonColors(_G.RaidFinderFrameFindRaidButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        if RaidFinderQueueFrame.SelectionDropdown then
            UpdateDropdownColors(RaidFinderQueueFrame.SelectionDropdown, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end


    local LFGListFrame = _G.LFGListFrame
    if LFGListFrame and LFGListFrame.preySkinned then
        if LFGListFrame.CategorySelection then
            UpdateButtonColors(LFGListFrame.CategorySelection.StartGroupButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            UpdateButtonColors(LFGListFrame.CategorySelection.FindGroupButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            if LFGListFrame.CategorySelection.CategoryButtons then
                for _, catButton in pairs(LFGListFrame.CategorySelection.CategoryButtons) do
                    UpdateButtonColors(catButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
                end
            end
        end
        if LFGListFrame.SearchPanel then
            UpdateButtonColors(LFGListFrame.SearchPanel.BackButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            UpdateButtonColors(LFGListFrame.SearchPanel.SignUpButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            UpdateButtonColors(LFGListFrame.SearchPanel.RefreshButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            UpdateButtonColors(LFGListFrame.SearchPanel.FilterButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            if LFGListFrame.SearchPanel.SearchBox and LFGListFrame.SearchPanel.SearchBox.preyBackdrop then
                LFGListFrame.SearchPanel.SearchBox.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
                LFGListFrame.SearchPanel.SearchBox.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
            end
        end
        if LFGListFrame.ApplicationViewer then
            UpdateButtonColors(LFGListFrame.ApplicationViewer.RefreshButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            UpdateButtonColors(LFGListFrame.ApplicationViewer.RemoveEntryButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            UpdateButtonColors(LFGListFrame.ApplicationViewer.EditButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
        if LFGListFrame.EntryCreation then
            UpdateButtonColors(LFGListFrame.EntryCreation.ListGroupButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            UpdateButtonColors(LFGListFrame.EntryCreation.CancelButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end


    local ChallengesFrame = _G.ChallengesFrame
    if ChallengesFrame and ChallengesFrame.preySkinned then
        if ChallengesFrame.DungeonIcons then
            for _, icon in pairs(ChallengesFrame.DungeonIcons) do
                UpdateDungeonIconColors(icon, sr, sg, sb, sa)
            end
        end

        if ChallengesFrame.WeeklyInfo and ChallengesFrame.WeeklyInfo.Child then
            local affixContainer = ChallengesFrame.WeeklyInfo.Child.AffixesContainer
            if affixContainer and affixContainer.Affixes then
                for _, affix in pairs(affixContainer.Affixes) do
                    UpdateAffixIconColors(affix, sr, sg, sb, sa)
                end
            end
        end
        for i = 1, 4 do
            local affix = ChallengesFrame["Affix" .. i]
            if affix then
                UpdateAffixIconColors(affix, sr, sg, sb, sa)
            end
        end
    end


    local PVPQueueFrame = _G.PVPQueueFrame
    if PVPQueueFrame and PVPQueueFrame.preySkinned then


        for i = 1, 5 do
            local catButton = PVPQueueFrame["CategoryButton" .. i] or rawget(_G, "PVPQueueFrameCategoryButton" .. i)
            UpdateGroupFinderButtonColors(catButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end


        local HonorFrame = _G.HonorFrame
        if HonorFrame then
            UpdateButtonColors(_G.HonorFrameQueueButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)

            local typeDropdown = HonorFrame.TypeDropdown or _G.HonorFrameTypeDropdown
            if typeDropdown then
                UpdateDropdownColors(typeDropdown, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            end

            if HonorFrame.BonusFrame then
                local bf = HonorFrame.BonusFrame
                local bonusButtons = { "RandomBGButton", "Arena1Button", "RandomEpicBGButton", "BrawlButton", "BrawlButton2", "SpecialEventButton" }
                for _, btnName in ipairs(bonusButtons) do
                    if bf[btnName] then
                        UpdatePVPActivityButtonColors(bf[btnName], sr, sg, sb, sa, bgr, bgg, bgb, bga)
                    end
                end
            end

            if HonorFrame.ConquestBar then
                UpdateConquestBarColors(HonorFrame.ConquestBar, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            end
        end


        local ConquestFrame = _G.ConquestFrame
        if ConquestFrame then
            UpdateButtonColors(_G.ConquestJoinButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)

            local conquestButtons = { "RatedSoloShuffle", "RatedBGBlitz", "Arena2v2", "Arena3v3", "RatedBG" }
            for _, btnName in ipairs(conquestButtons) do
                if ConquestFrame[btnName] then
                    UpdatePVPActivityButtonColors(ConquestFrame[btnName], sr, sg, sb, sa, bgr, bgg, bgb, bga)
                end
            end

            if ConquestFrame.ConquestBar then
                UpdateConquestBarColors(ConquestFrame.ConquestBar, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            end
        end


        local TrainingGroundsFrame = _G.TrainingGroundsFrame
        if TrainingGroundsFrame and TrainingGroundsFrame.preySkinned then
            UpdateButtonColors(TrainingGroundsFrame.QueueButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            if TrainingGroundsFrame.TypeDropdown then
                UpdateDropdownColors(TrainingGroundsFrame.TypeDropdown, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            end
            if TrainingGroundsFrame.ConquestBar then
                UpdateConquestBarColors(TrainingGroundsFrame.ConquestBar, sr, sg, sb, sa, bgr, bgg, bgb, bga)
            end
        end


        local PlunderstormFrame = _G.PlunderstormFrame
        if PlunderstormFrame and PlunderstormFrame.preySkinned then
            UpdateButtonColors(PlunderstormFrame.QueueButton, sr, sg, sb, sa, bgr, bgg, bgb, bga)
        end
    end
end


_G.PreyUI_RefreshInstanceFramesColors = RefreshInstanceFramesColors


local pveHooked = false
local function HookPVEFrame()
    if pveHooked then return end
    if _G.PVEFrame then
        _G.PVEFrame:HookScript("OnShow", function()
            C_Timer.After(0.1, SkinInstanceFrames)
        end)
        pveHooked = true
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, addon)
    if event == "ADDON_LOADED" then
        if addon == "Blizzard_PVPUI" or addon == "Blizzard_ChallengesUI" then
            C_Timer.After(0.1, SkinInstanceFrames)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        HookPVEFrame()
        C_Timer.After(1, SkinInstanceFrames)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)
