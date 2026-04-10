local ADDON_NAME, ns = ...
local PREY = ns.PREY or {}
ns.PREY = PREY


local skinnedFrames = {}
local urlPopup = nil
local chatCopyFrame = nil
local copyButtons = {}


local tinsert = table.insert
local tconcat = table.concat


local CHAT_FRAME_TEXTURES = {
    "Background",
    "TopLeftTexture", "TopRightTexture",
    "BottomLeftTexture", "BottomRightTexture",
    "TopTexture", "BottomTexture",
    "LeftTexture", "RightTexture",
}


local URL_PATTERNS = {
    "%f[%S](%a[%w+.-]+://%S+)",
    "%f[%S](www%.[-%w_%%]+%.%a%a+/%S+)",
    "%f[%S](www%.[-%w_%%]+%.%a%a+)",
}


local CHAT_FILTER_EVENTS = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER",
    "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_EMOTE",
    "CHAT_MSG_TEXT_EMOTE",
    "CHAT_MSG_SYSTEM",
    "CHAT_MSG_AFK",
    "CHAT_MSG_DND",
    "CHAT_MSG_IGNORED",
}


local EDITBOX_TEXTURES = {
    "FocusLeft", "FocusMid", "FocusRight",
    "Header", "HeaderSuffix", "LanguageHeader",
    "Prompt", "NewcomerHint",
}


local PREY_COLORS = {
    bg = {0.067, 0.094, 0.153, 0.97},
    accent = {0.820, 0.180, 0.220, 1},
    text = {0.953, 0.957, 0.965, 1},
}


local function GetSettings()
    local PREYCore = _G.PreyUI and _G.PreyUI.PREYCore
    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.chat then
        return PREYCore.db.profile.chat
    end
    return nil
end


local function StripDefaultTextures(chatFrame)
    local frameName = chatFrame:GetName()
    if not frameName then return end

    for _, textureName in ipairs(CHAT_FRAME_TEXTURES) do
        local texture = rawget(_G, frameName .. textureName)
        if texture and texture.SetTexture then
            texture:SetTexture(0)
            texture:SetAlpha(0)
        end
    end
end


local function CreateGlassBackdrop(chatFrame)
    local settings = GetSettings()
    if not settings or not settings.glass or not settings.glass.enabled then return end


    if not chatFrame.__preyChatBackdrop then
        local backdrop = CreateFrame("Frame", nil, chatFrame, "BackdropTemplate")
        backdrop:SetFrameLevel(math.max(1, chatFrame:GetFrameLevel() - 1))
        backdrop:SetPoint("TOPLEFT", -8, 2)
        backdrop:SetPoint("BOTTOMRIGHT", 8, -8)
        backdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        chatFrame.__preyChatBackdrop = backdrop
    end


    local alpha = settings.glass.bgAlpha or 0.25
    local bgColor = settings.glass.bgColor or {0, 0, 0}
    chatFrame.__preyChatBackdrop:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], alpha)
    chatFrame.__preyChatBackdrop:SetBackdropBorderColor(bgColor[1], bgColor[2], bgColor[3], alpha)
    chatFrame.__preyChatBackdrop:Show()
end


local function RemoveGlassBackdrop(chatFrame)
    if chatFrame.__preyChatBackdrop then
        chatFrame.__preyChatBackdrop:Hide()
    end
end


local function StyleFontStrings(chatFrame)

    local fontFile, fontSize, fontFlags = chatFrame:GetFont()
    if fontFile and fontSize then

        local newFlags = fontFlags or ""
        if not newFlags:find("OUTLINE") then
            newFlags = "OUTLINE"
        end
        chatFrame:SetFont(fontFile, fontSize, newFlags)
        chatFrame:SetShadowOffset(0, 0)
    end
end


local function AddTimestamp(text)
    local settings = GetSettings()
    if not settings or not settings.timestamps or not settings.timestamps.enabled then
        return text
    end

    local fmt = settings.timestamps.format == "12h" and "%I:%M %p" or "%H:%M"
    local timestamp = date(fmt)
    local color = settings.timestamps.color
    if color then
        local hex = string.format("%02x%02x%02x", color[1]*255, color[2]*255, color[3]*255)
        return string.format("|cff%s[%s]|r %s", hex, timestamp, text)
    end
    return string.format("[%s] %s", timestamp, text)
end


local function MakeURLsClickable(text)
    local settings = GetSettings()
    if not settings or not settings.urls or not settings.urls.enabled then
        return text
    end


    local success, result = pcall(function()

        local r, g, b = 0.078, 0.608, 0.992
        if settings.urls.color then
            r, g, b = settings.urls.color[1] or r, settings.urls.color[2] or g, settings.urls.color[3] or b
        end
        local colorHex = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)


        local linkFormat = "|cff" .. colorHex .. "|Haddon:preyuichat:%1|h[%1]|h|r"

        local processed = text
        for _, pattern in ipairs(URL_PATTERNS) do
            processed = processed:gsub(pattern, linkFormat)
        end
        return processed
    end)


    if success then
        return result
    else
        return text
    end
end


local messageFiltersInstalled = false

local function ProcessChatTextSafely(text)
    if not text or type(text) ~= "string" then
        return text
    end

    local ok, processed = pcall(function()
        local result = AddTimestamp(text)
        result = MakeURLsClickable(result)
        return result
    end)

    if ok and type(processed) == "string" then
        return processed
    end

    return text
end

local function ChatMessageFilter(self, event, message, author, ...)
    local settings = GetSettings()
    if not settings or not settings.enabled then
        return false, message, author, ...
    end

    local useTimestamp = settings.timestamps and settings.timestamps.enabled
    local useURLs = settings.urls and settings.urls.enabled
    if not useTimestamp and not useURLs then
        return false, message, author, ...
    end

    local processed = ProcessChatTextSafely(message)
    return false, processed, author, ...
end

local function HookChatMessages()
    if messageFiltersInstalled then return end
    messageFiltersInstalled = true

    for _, eventName in ipairs(CHAT_FILTER_EVENTS) do
        ChatFrame_AddMessageEventFilter(eventName, ChatMessageFilter)
    end
end


local function CreateCopyPopup()
    if urlPopup then return urlPopup end

    urlPopup = CreateFrame("Frame", "PreyUI_ChatCopyPopup", UIParent, "BackdropTemplate")
    urlPopup:SetSize(420, 90)
    urlPopup:SetPoint("CENTER")
    urlPopup:SetFrameStrata("DIALOG")
    urlPopup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })

    urlPopup:SetBackdropColor(PREY_COLORS.bg[1], PREY_COLORS.bg[2], PREY_COLORS.bg[3], PREY_COLORS.bg[4])
    urlPopup:SetBackdropBorderColor(PREY_COLORS.accent[1], PREY_COLORS.accent[2], PREY_COLORS.accent[3], PREY_COLORS.accent[4])
    urlPopup:EnableMouse(true)
    urlPopup:SetMovable(true)
    urlPopup:RegisterForDrag("LeftButton")
    urlPopup:SetScript("OnDragStart", urlPopup.StartMoving)
    urlPopup:SetScript("OnDragStop", urlPopup.StopMovingOrSizing)
    urlPopup:Hide()


    local title = urlPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Press Ctrl+C to copy")
    title:SetTextColor(PREY_COLORS.accent[1], PREY_COLORS.accent[2], PREY_COLORS.accent[3], 1)


    local editBox = CreateFrame("EditBox", nil, urlPopup, "InputBoxTemplate")
    editBox:SetSize(380, 24)
    editBox:SetPoint("CENTER", 0, -8)
    editBox:SetAutoFocus(true)
    editBox:SetTextColor(PREY_COLORS.text[1], PREY_COLORS.text[2], PREY_COLORS.text[3], 1)
    editBox:SetScript("OnEscapePressed", function() urlPopup:Hide() end)
    editBox:SetScript("OnEnterPressed", function() urlPopup:Hide() end)
    urlPopup.editBox = editBox


    local closeBtn = CreateFrame("Button", nil, urlPopup, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetSize(24, 24)


    if not tContains(UISpecialFrames, "PreyUI_ChatCopyPopup") then
        tinsert(UISpecialFrames, "PreyUI_ChatCopyPopup")
    end

    return urlPopup
end


local function ShowCopyPopup(url)
    local popup = CreateCopyPopup()
    popup.editBox:SetText(url)
    popup.editBox:HighlightText()
    popup:Show()
    popup.editBox:SetFocus()
end


local function SetupURLClickHandler()

    EventRegistry:RegisterCallback("SetItemRef", function(_, link, text, button)
        if not link then return end

        local url = link:match("^addon:preyuichat:(.*)")
        if url then
            ShowCopyPopup(url)
            return true
        end
    end)
end


local function IsMessageProtected(message)

    if not message or type(message) ~= "string" then return false end

    if message:find("|K") then return true end
    return false
end


local function CleanMessage(message)

    if not message or type(message) ~= "string" then return "" end

    local cleaned = message

    cleaned = cleaned:gsub("|T[^|]*|t", "")

    cleaned = cleaned:gsub("|A[^|]*|a", "")

    cleaned = cleaned:gsub("|TInterface\\TargetingFrame\\UI%-RaidTargetingIcon_(%d):[^|]*|t", "{rt%1}")

    cleaned = cleaned:gsub("|H[^|]*|h%[?([^%]|]*)%]?|h", "%1")

    cleaned = cleaned:gsub("|c%x%x%x%x%x%x%x%x", "")
    cleaned = cleaned:gsub("|r", "")
    cleaned = cleaned:gsub("|n", "\n")

    return cleaned
end


local function GetChatLines(chatFrame)
    local lines = {}
    local numMessages = chatFrame:GetNumMessages()

    for i = 1, numMessages do
        local message, r, g, b = chatFrame:GetMessageInfo(i)
        if message and not IsMessageProtected(message) then
            local cleaned = CleanMessage(message)
            if cleaned and cleaned ~= "" then
                tinsert(lines, cleaned)
            end
        end
    end

    return lines
end


local function CreateChatCopyFrame()
    if chatCopyFrame then return chatCopyFrame end

    chatCopyFrame = CreateFrame("Frame", "PreyUI_ChatCopyFrame", UIParent, "BackdropTemplate")
    chatCopyFrame:SetSize(500, 400)
    chatCopyFrame:SetPoint("CENTER")
    chatCopyFrame:SetFrameStrata("DIALOG")
    chatCopyFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    chatCopyFrame:SetBackdropColor(PREY_COLORS.bg[1], PREY_COLORS.bg[2], PREY_COLORS.bg[3], PREY_COLORS.bg[4])
    chatCopyFrame:SetBackdropBorderColor(PREY_COLORS.accent[1], PREY_COLORS.accent[2], PREY_COLORS.accent[3], PREY_COLORS.accent[4])
    chatCopyFrame:EnableMouse(true)
    chatCopyFrame:SetMovable(true)
    chatCopyFrame:SetResizable(true)
    chatCopyFrame:SetResizeBounds(300, 200, 800, 600)
    chatCopyFrame:RegisterForDrag("LeftButton")
    chatCopyFrame:SetScript("OnDragStart", chatCopyFrame.StartMoving)
    chatCopyFrame:SetScript("OnDragStop", chatCopyFrame.StopMovingOrSizing)
    chatCopyFrame:Hide()


    local title = chatCopyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Chat History - Select and Ctrl+C to copy")
    title:SetTextColor(PREY_COLORS.accent[1], PREY_COLORS.accent[2], PREY_COLORS.accent[3], 1)


    local scrollFrame = CreateFrame("ScrollFrame", nil, chatCopyFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)


    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetAutoFocus(false)
    editBox:SetTextColor(PREY_COLORS.text[1], PREY_COLORS.text[2], PREY_COLORS.text[3], 1)
    editBox:SetScript("OnEscapePressed", function() chatCopyFrame:Hide() end)
    scrollFrame:SetScrollChild(editBox)
    chatCopyFrame.editBox = editBox
    chatCopyFrame.scrollFrame = scrollFrame


    local closeBtn = CreateFrame("Button", nil, chatCopyFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetSize(24, 24)


    local selectAllBtn = CreateFrame("Button", nil, chatCopyFrame, "UIPanelButtonTemplate")
    selectAllBtn:SetSize(100, 22)
    selectAllBtn:SetPoint("BOTTOMLEFT", 12, 10)
    selectAllBtn:SetText("Select All")
    selectAllBtn:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)


    local resizeBtn = CreateFrame("Button", nil, chatCopyFrame)
    resizeBtn:SetSize(16, 16)
    resizeBtn:SetPoint("BOTTOMRIGHT", -4, 4)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeBtn:SetScript("OnMouseDown", function() chatCopyFrame:StartSizing("BOTTOMRIGHT") end)
    resizeBtn:SetScript("OnMouseUp", function()
        chatCopyFrame:StopMovingOrSizing()
        editBox:SetWidth(scrollFrame:GetWidth())
    end)


    if not tContains(UISpecialFrames, "PreyUI_ChatCopyFrame") then
        tinsert(UISpecialFrames, "PreyUI_ChatCopyFrame")
    end

    return chatCopyFrame
end


local function ShowChatCopyFrame(chatFrame)
    local frame = CreateChatCopyFrame()
    local lines = GetChatLines(chatFrame)

    local text
    if #lines == 0 then
        text = "(No copyable messages in chat history)"
    else
        text = tconcat(lines, "\n")
    end

    frame.editBox:SetText(text)
    frame.editBox:SetWidth(frame.scrollFrame:GetWidth())
    frame:Show()
    frame.editBox:SetFocus()
    frame.editBox:HighlightText()
end


local COPY_BUTTON_IDLE_ALPHA = 0.35


local function GetOrCreateCopyButton(chatFrame)
    local frameName = chatFrame:GetName()
    if not frameName then return nil end


    if copyButtons[chatFrame] then
        return copyButtons[chatFrame]
    end

    local button = CreateFrame("Button", frameName .. "PreyCopyButton", chatFrame)
    button:SetSize(20, 22)

    button:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", 4, -2)
    button:SetFrameLevel(chatFrame:GetFrameLevel() + 5)


    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    button.icon = icon


    button:SetAlpha(COPY_BUTTON_IDLE_ALPHA)


    button:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Copy Chat", 1, 1, 1)
        GameTooltip:AddLine("Click to copy chat history", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function(self)
        local settings = GetSettings()
        local mode = settings and settings.copyButtonMode or "always"

        if mode == "hover" then
            if not chatFrame:IsMouseOver() then
                self:SetAlpha(0)
            end
        else
            self:SetAlpha(COPY_BUTTON_IDLE_ALPHA)
        end
        GameTooltip:Hide()
    end)


    button:SetScript("OnClick", function()
        ShowChatCopyFrame(chatFrame)
    end)

    copyButtons[chatFrame] = button
    return button
end


local function SetupCopyButtonHoverMode(chatFrame)

    if chatFrame.preyCopyButtonHooked then return end
    chatFrame.preyCopyButtonHooked = true

    local button = copyButtons[chatFrame]
    if not button then return end


    chatFrame:HookScript("OnEnter", function()
        local settings = GetSettings()
        local mode = settings and settings.copyButtonMode or "always"
        if mode == "hover" and button then
            button:SetAlpha(COPY_BUTTON_IDLE_ALPHA)
            button:Show()
        end
    end)
    chatFrame:HookScript("OnLeave", function()
        local settings = GetSettings()
        local mode = settings and settings.copyButtonMode or "always"
        if mode == "hover" and button then

            if not button:IsMouseOver() then
                button:SetAlpha(0)
            end
        end
    end)
end


local function ApplyCopyButtonMode(chatFrame)
    local settings = GetSettings()


    local mode = settings and settings.copyButtonMode
    if not mode and settings then

        if settings.copyButton == false then
            mode = "disabled"
        else
            mode = "always"
        end
    end
    mode = mode or "always"


    if mode == "disabled" then
        if copyButtons[chatFrame] then
            copyButtons[chatFrame]:Hide()
        end
        return
    end


    local button = GetOrCreateCopyButton(chatFrame)
    if not button then return end

    if mode == "always" then
        button:SetAlpha(COPY_BUTTON_IDLE_ALPHA)
        button:Show()
    elseif mode == "hover" then

        button:SetAlpha(0)
        button:Show()

        if not chatFrame.preyCopyButtonHooked then
            SetupCopyButtonHoverMode(chatFrame)
        end
    end
end


local function HideCopyButton(chatFrame)
    if copyButtons[chatFrame] then
        copyButtons[chatFrame]:Hide()
    end
end


local function SetupMessageFade(chatFrame)
    local settings = GetSettings()
    if not settings or not settings.fade then return end

    if settings.fade.enabled then
        chatFrame:SetFading(true)
        chatFrame:SetTimeVisible(settings.fade.delay or 60)
    else
        chatFrame:SetFading(false)
    end
end


local function preventShow(self)
    self:Hide()
end

local function HideChatButtons(chatFrame)
    local settings = GetSettings()
    if not settings or not settings.hideButtons then return end


    if chatFrame.buttonFrame then
        chatFrame.buttonFrame:SetScript("OnShow", preventShow)
        chatFrame.buttonFrame:Hide()
        chatFrame.buttonFrame:SetWidth(0.1)
    end


    if chatFrame.ScrollBar then
        chatFrame.ScrollBar:Hide()
    end
    if chatFrame.ScrollToBottomButton then
        chatFrame.ScrollToBottomButton:Hide()
    end


    local frameName = chatFrame:GetName()
    if frameName then
        local buttonFrame = rawget(_G, frameName .. "ButtonFrame")
        if buttonFrame then
            buttonFrame:SetScript("OnShow", preventShow)
            buttonFrame:Hide()
            buttonFrame:SetWidth(0.1)
        end

        local scrollBar = rawget(_G, frameName .. "ScrollBar")
        if scrollBar then scrollBar:Hide() end
    end


    if QuickJoinToastButton then
        QuickJoinToastButton:SetScript("OnShow", preventShow)
        QuickJoinToastButton:Hide()
    end


    if not InCombatLockdown() then
        chatFrame:SetClampedToScreen(false)
        chatFrame:SetClampRectInsets(0, 0, 0, 0)
    end
end


local function ShowChatButtons(chatFrame)
    if chatFrame.buttonFrame then
        chatFrame.buttonFrame:SetScript("OnShow", nil)
        chatFrame.buttonFrame:Show()
        chatFrame.buttonFrame:SetWidth(29)
    end
    if chatFrame.ScrollBar then
        chatFrame.ScrollBar:Show()
    end
    if chatFrame.ScrollToBottomButton then
        chatFrame.ScrollToBottomButton:Show()
    end

    local frameName = chatFrame:GetName()
    if frameName then
        local buttonFrame = rawget(_G, frameName .. "ButtonFrame")
        if buttonFrame then
            buttonFrame:SetScript("OnShow", nil)
            buttonFrame:Show()
            buttonFrame:SetWidth(29)
        end

        local scrollBar = rawget(_G, frameName .. "ScrollBar")
        if scrollBar then scrollBar:Show() end
    end


    if QuickJoinToastButton then
        QuickJoinToastButton:SetScript("OnShow", nil)
        QuickJoinToastButton:Show()
    end


    if not InCombatLockdown() then
        chatFrame:SetClampedToScreen(true)
    end
end


local function StyleEditBox(chatFrame)
    local settings = GetSettings()
    if not settings or not settings.editBox or not settings.editBox.enabled then return end
    if not settings.glass or not settings.glass.enabled then return end

    local frameName = chatFrame:GetName()
    if not frameName then return end


    local editBox = chatFrame.editBox or rawget(_G, frameName .. "EditBox")
    if not editBox then return end


    if not editBox.__preyChatStyled then
        editBox.__preyChatStyled = true


        local childSuffixes = {
            "Left", "Mid", "Right",
            "FocusLeft", "FocusMid", "FocusRight",
        }
        for _, suffix in ipairs(childSuffixes) do
            local child = rawget(_G, frameName .. "EditBox" .. suffix)
            if child and child.Hide then
                child:Hide()
            end
        end


        if editBox.focusLeft then editBox.focusLeft:SetAlpha(0) end
        if editBox.focusMid then editBox.focusMid:SetAlpha(0) end
        if editBox.focusRight then editBox.focusRight:SetAlpha(0) end


        for _, name in ipairs(EDITBOX_TEXTURES) do
            local tex = editBox[name]
            if tex and tex.Hide then
                tex:Hide()
            end
        end


        local regions = {editBox:GetRegions()}
        for _, region in ipairs(regions) do
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                if not region.__preyChatKeep then
                    region:SetAlpha(0)
                end
            end
        end
    end


    if not chatFrame.__preyEditBoxBackdrop then
        local backdrop = CreateFrame("Frame", nil, chatFrame, "BackdropTemplate")
        backdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        chatFrame.__preyEditBoxBackdrop = backdrop
    end

    local backdrop = chatFrame.__preyEditBoxBackdrop
    local positionTop = settings.editBox.positionTop


    backdrop:ClearAllPoints()
    if positionTop then

        backdrop:SetFrameLevel(chatFrame:GetFrameLevel() + 10)
        backdrop:SetPoint("BOTTOMLEFT", chatFrame, "TOPLEFT", -8, 0)
        backdrop:SetPoint("BOTTOMRIGHT", chatFrame, "TOPRIGHT", 8, 0)
        backdrop:SetHeight(24)
        backdrop:SetBackdropColor(0, 0, 0, 1)
        backdrop:SetBackdropBorderColor(0, 0, 0, 1)


        editBox:ClearAllPoints()
        editBox:SetPoint("LEFT", backdrop, "LEFT", -8, 0)
        editBox:SetPoint("RIGHT", backdrop, "RIGHT", -4, 0)
        editBox:SetPoint("CENTER", backdrop, "CENTER", 0, 0)


        editBox.__preyChatBackdrop = backdrop


        if not editBox.__preyTopModeHooked then
            editBox.__preyTopModeHooked = true
            editBox:HookScript("OnEditFocusGained", function(self)
                local s = GetSettings()
                if s and s.editBox and s.editBox.positionTop and self.__preyChatBackdrop then
                    self.__preyChatBackdrop:Show()
                end
            end)
            editBox:HookScript("OnEditFocusLost", function(self)
                if self.__preyChatBackdrop then
                    self.__preyChatBackdrop:Hide()
                end
            end)
        end


        backdrop:Hide()
        if editBox:HasFocus() then
            backdrop:Show()
        end
    else

        backdrop:SetFrameLevel(math.max(1, editBox:GetFrameLevel() - 1))
        backdrop:SetPoint("TOPLEFT", chatFrame, "BOTTOMLEFT", -8, -6)
        backdrop:SetPoint("TOPRIGHT", chatFrame, "BOTTOMRIGHT", 8, -6)
        backdrop:SetHeight(24)


        local alpha = settings.editBox.bgAlpha or 0.25
        local bgColor = settings.editBox.bgColor or {0, 0, 0}
        backdrop:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], alpha)
        backdrop:SetBackdropBorderColor(bgColor[1], bgColor[2], bgColor[3], alpha)


        editBox:ClearAllPoints()
        editBox:SetPoint("LEFT", backdrop, "LEFT", -8, 0)
        editBox:SetPoint("RIGHT", backdrop, "RIGHT", -4, 0)
        editBox:SetPoint("CENTER", backdrop, "CENTER", 0, 0)


        editBox.__preyChatBackdrop = backdrop


        backdrop:Show()
    end
end


local function UpdateTabColors(tab)
    local settings = GetSettings()
    if not settings or not tab.__preyBackdrop then return end

    local alpha = settings.glass and settings.glass.bgAlpha or 0.4


    local isSelected = false
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = rawget(_G, "ChatFrame" .. i)
        if chatFrame and chatFrame:IsShown() then
            local frameTab = rawget(_G, "ChatFrame" .. i .. "Tab")
            if frameTab == tab then
                isSelected = true
                break
            end
        end
    end


    if tab.GetButtonState and tab:GetButtonState() == "PUSHED" then
        isSelected = true
    end

    if isSelected then

        tab.__preyBackdrop:SetBackdropColor(0, 0, 0, alpha + 0.2)
        tab.__preyBackdrop:SetBackdropBorderColor(PREY_COLORS.accent[1], PREY_COLORS.accent[2], PREY_COLORS.accent[3], 1)
    else

        tab.__preyBackdrop:SetBackdropColor(0, 0, 0, alpha)
        tab.__preyBackdrop:SetBackdropBorderColor(0, 0, 0, alpha)
    end
end

local function StyleChatTab(tab)
    if not tab then return end

    local settings = GetSettings()
    if not settings or not settings.styleTabs then return end


    local tabName = tab:GetName()
    if tabName then
        local textures = {
            "Left", "Middle", "Right",
            "SelectedLeft", "SelectedMiddle", "SelectedRight",
            "HighlightLeft", "HighlightMiddle", "HighlightRight",
        }
        for _, suffix in ipairs(textures) do
            local tex = rawget(_G, tabName .. suffix)
            if tex and tex.SetAlpha then
                tex:SetAlpha(0)
            end
        end
    end


    if not tab.__preyBackdrop then
        local backdrop = CreateFrame("Frame", nil, tab, "BackdropTemplate")
        backdrop:SetFrameLevel(math.max(1, tab:GetFrameLevel() - 1))
        backdrop:SetPoint("TOPLEFT", 2, -4)
        backdrop:SetPoint("BOTTOMRIGHT", -2, 2)
        backdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        tab.__preyBackdrop = backdrop
    end


    UpdateTabColors(tab)


    local fontString = tab:GetFontString()
    if fontString then
        local font, size = fontString:GetFont()
        if font then
            fontString:SetFont(font, size or 12, "OUTLINE")
            fontString:SetShadowOffset(0, 0)
        end
    end
end

local function StyleAllChatTabs()
    local settings = GetSettings()
    if not settings or not settings.styleTabs then return end

    for i = 1, NUM_CHAT_WINDOWS do
        local tab = rawget(_G, "ChatFrame" .. i .. "Tab")
        if tab then
            StyleChatTab(tab)
        end
    end
end

local function RefreshAllTabColors()
    for i = 1, NUM_CHAT_WINDOWS do
        local tab = rawget(_G, "ChatFrame" .. i .. "Tab")
        if tab and tab.__preyBackdrop then
            UpdateTabColors(tab)
        end
    end
end


local function ApplyMessagePadding(chatFrame)
    local settings = GetSettings()
    if not settings then return end

    local padding = settings.messagePadding or 0


    local container = chatFrame.FontStringContainer
    if container then
        container:ClearAllPoints()
        if padding > 0 then

            container:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", padding, 0)
            container:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", 0, 0)
        else
            container:SetPoint("TOPLEFT", chatFrame, "TOPLEFT", 0, 0)
            container:SetPoint("BOTTOMRIGHT", chatFrame, "BOTTOMRIGHT", 0, 0)
        end
    end
end


local function RemoveEditBoxStyle(chatFrame)

    if chatFrame.__preyEditBoxBackdrop then
        chatFrame.__preyEditBoxBackdrop:Hide()
    end
end


local function SkinChatFrame(chatFrame)
    if not chatFrame or chatFrame:IsForbidden() then return end

    local settings = GetSettings()
    if not settings or not settings.enabled then return end

    local frameName = chatFrame:GetName()
    if not frameName then return end


    skinnedFrames[chatFrame] = true


    if settings.glass and settings.glass.enabled then
        StripDefaultTextures(chatFrame)
        CreateGlassBackdrop(chatFrame)
    end


    StyleFontStrings(chatFrame)


    if (settings.urls and settings.urls.enabled) or (settings.timestamps and settings.timestamps.enabled) then
        HookChatMessages()
    end


    if settings.fade and settings.fade.enabled then
        SetupMessageFade(chatFrame)
    end


    if settings.hideButtons then
        HideChatButtons(chatFrame)
    end


    if settings.editBox and settings.editBox.enabled then
        StyleEditBox(chatFrame)
    end


    ApplyMessagePadding(chatFrame)


    ApplyCopyButtonMode(chatFrame)
end


local function SkinAllChatFrames()
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = rawget(_G, "ChatFrame" .. i)
        if chatFrame then
            SkinChatFrame(chatFrame)
        end
    end
end


local function HookNewChatWindows()

    hooksecurefunc("FCF_OpenTemporaryWindow", function(...)
        C_Timer.After(0.1, function()
            SkinAllChatFrames()
            StyleAllChatTabs()
        end)
    end)


    if FCF_OpenNewWindow then
        hooksecurefunc("FCF_OpenNewWindow", function(...)
            C_Timer.After(0.1, function()
                SkinAllChatFrames()
                StyleAllChatTabs()
            end)
        end)
    end


    hooksecurefunc("FCF_Tab_OnClick", function(self)
        local tabID = self:GetID()
        C_Timer.After(0.05, function()
            RefreshAllTabColors()

            local chatFrame = rawget(_G, "ChatFrame" .. tabID)
            local settings = GetSettings()

            if chatFrame and settings and settings.editBox and settings.editBox.positionTop then


                local sharedBackdrop = ChatFrame1.__preyEditBoxBackdrop
                if sharedBackdrop then
                    sharedBackdrop:SetParent(UIParent)
                    sharedBackdrop:ClearAllPoints()
                    sharedBackdrop:SetFrameLevel(ChatFrame1:GetFrameLevel() + 10)
                    sharedBackdrop:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", -8, 0)
                    sharedBackdrop:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 8, 0)
                    sharedBackdrop:SetHeight(24)


                    ChatFrame1EditBox.__preyChatBackdrop = sharedBackdrop


                    if ChatFrame1EditBox:HasFocus() then
                        sharedBackdrop:Show()
                    end
                end
            end
        end)
    end)
end


local function RefreshAll()
    local settings = GetSettings()


    for chatFrame in pairs(skinnedFrames) do

        if not settings or not settings.enabled or not settings.glass or not settings.glass.enabled then
            RemoveGlassBackdrop(chatFrame)
        end


        if not settings or not settings.enabled or not settings.hideButtons then
            ShowChatButtons(chatFrame)
        else
            HideChatButtons(chatFrame)
        end


        if not settings or not settings.enabled or not settings.editBox or not settings.editBox.enabled then
            RemoveEditBoxStyle(chatFrame)
        else


            if chatFrame.__preyEditBoxBackdrop and not settings.editBox.positionTop then
                chatFrame.__preyEditBoxBackdrop:Show()
            end
        end


        SetupMessageFade(chatFrame)


        if not settings or not settings.enabled then
            HideCopyButton(chatFrame)
        else
            ApplyCopyButtonMode(chatFrame)
        end
    end


    if settings and settings.enabled then
        SkinAllChatFrames()
        StyleAllChatTabs()
    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0.5, function()
            local settings = GetSettings()
            if not settings or not settings.enabled then return end


            SetupURLClickHandler()


            SkinAllChatFrames()


            StyleAllChatTabs()


            HookNewChatWindows()
        end)
    end
end)


_G.PreyUI_RefreshChat = RefreshAll

PREY.Chat = {
    Refresh = RefreshAll,
    SkinFrame = SkinChatFrame,
    SkinAll = SkinAllChatFrames,
}
