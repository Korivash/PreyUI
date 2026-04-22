-- PreyUI Rebuild Layer — 2026 Edition
-- Modern shell: layered header, class-colored accents, animated glow, category nav rail.

local PREY = PreyUI
if not PREY or not PREY.GUI then return end

local GUI = PREY.GUI

-- ---------------------------------------------------------------------------
-- Brand
-- ---------------------------------------------------------------------------
GUI.Brand = {
    product    = "PreyUI",
    subtitle   = "Version",
    accentLabel = "PREY",
}

-- ---------------------------------------------------------------------------
-- Theme Colors
-- ---------------------------------------------------------------------------
local C = GUI.Colors or {}
GUI.Colors = C

C.bg              = {0.048, 0.028, 0.036, 0.98}
C.bgLight         = {0.100, 0.050, 0.062, 1}
C.bgDark          = {0.022, 0.010, 0.014, 1}
C.bgContent       = {0.068, 0.030, 0.040, 0.92}
C.bgHeader        = {0.030, 0.013, 0.018, 1}

C.accent          = {0.840, 0.180, 0.220, 1}
C.accentLight     = {1.000, 0.420, 0.450, 1}
C.accentDark      = {0.420, 0.080, 0.100, 1}
C.accentHover     = {1.000, 0.540, 0.580, 1}

C.tabSelected     = {0.840, 0.180, 0.220, 1}
C.tabSelectedText = {1.000, 0.940, 0.950, 1}
C.tabNormal       = {0.700, 0.620, 0.640, 1}
C.tabHover        = {1.000, 0.960, 0.970, 1}

C.text            = {0.960, 0.930, 0.940, 1}
C.textBright      = {1,     1,     1,     1}
C.textMuted       = {0.680, 0.580, 0.600, 1}
C.textDim         = {0.480, 0.410, 0.430, 1}

C.border          = {0.280, 0.100, 0.120, 1}
C.borderLight     = {0.450, 0.180, 0.210, 1}
C.borderAccent    = {0.840, 0.180, 0.220, 1}
C.sectionHeader   = {0.950, 0.360, 0.400, 1}

C.navBg           = {0.038, 0.014, 0.018, 1}
C.navItemBg       = {0.074, 0.030, 0.038, 1}
C.navItemActiveBg = {0.130, 0.046, 0.058, 1}
C.navItemHoverBg  = {0.096, 0.038, 0.048, 1}
C.navActionBg     = {0.082, 0.030, 0.038, 1}

-- Category label accent colors
C.catCore         = {0.970, 0.720, 0.240, 1}   -- warm gold  → Interface
C.catCooldown     = {0.840, 0.180, 0.220, 1}   -- crimson    → Cooldown System
C.catConfig       = {0.440, 0.820, 0.480, 1}   -- sage green → Configuration

-- Slider / toggle (kept for widget compat)
C.sliderTrack     = {0.16, 0.08, 0.09, 1}
C.sliderThumb     = {1,    1,    1,    1}
C.toggleOff       = {0.17, 0.10, 0.11, 1}
C.toggleThumb     = {1,    1,    1,    1}
C.warning         = {0.961, 0.620, 0.043, 1}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function CreateBackdrop(frame, bg, border)
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(bg or C.bg))
    frame:SetBackdropBorderColor(unpack(border or C.border))
end

local function UseFont(fs, size, color, flags)
    local path = GUI.FONT_PATH or "Fonts\\FRIZQT__.TTF"
    fs:SetFont(path, size or 12, flags or "")
    if color then fs:SetTextColor(unpack(color)) end
end

-- Returns player class color as {r,g,b,1}, falls back to crimson accent.
local function GetPlayerClassColor()
    local _, className = UnitClass("player")
    if className and RAID_CLASS_COLORS then
        local cc = RAID_CLASS_COLORS[className]
        if cc then return {cc.r, cc.g, cc.b, 1} end
    end
    return {C.accent[1], C.accent[2], C.accent[3], 1}
end

-- ---------------------------------------------------------------------------
-- Layout constants
-- ---------------------------------------------------------------------------
local HEADER_H         = 84
local SIDEBAR_W        = 308
local CONTENT_BANNER_H = 52
local ACTION_H         = 110   -- height reserved for action buttons in sidebar
local CAT_H            = 22    -- height of a nav-category label row
local NAV_BTN_H        = 30
local NAV_GAP          = 4
local ACTION_BTN_H     = 28

-- ---------------------------------------------------------------------------
-- CREATE MAIN FRAME
-- ---------------------------------------------------------------------------
function GUI:CreateMainFrame()
    if self.MainFrame then return self.MainFrame end

    local db          = PREY.PREYCore and PREY.PREYCore.db and PREY.PREYCore.db.profile
    local savedWidth  = (db and db.configPanelWidth)  or 1080
    local savedHeight = (db and db.configPanelHeight) or 720

    -- ── Root Frame ──────────────────────────────────────────────────────────
    local frame = CreateFrame("Frame", "PreyUI_CommandDeck", UIParent, "BackdropTemplate")
    frame:SetSize(savedWidth, savedHeight)
    frame:SetPoint("CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(120)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    if frame.SetResizable    then frame:SetResizable(true) end
    if frame.SetResizeBounds then frame:SetResizeBounds(800, 560, 1600, 1100) end
    CreateBackdrop(frame, C.bg, C.border)
    self.MainFrame = frame

    -- Subtle outer glow ring (renders behind the 1px border)
    local outerGlow = frame:CreateTexture(nil, "BACKGROUND")
    outerGlow:SetPoint("TOPLEFT",     frame, "TOPLEFT",     -1,  1)
    outerGlow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",  1, -1)
    outerGlow:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.10)

    -- ── HEADER ──────────────────────────────────────────────────────────────
    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT",  frame, "TOPLEFT",  0, 0)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    header:SetHeight(HEADER_H)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() frame:StartMoving() end)
    header:SetScript("OnDragStop",  function() frame:StopMovingOrSizing() end)
    header:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    header:SetBackdropColor(C.bgHeader[1], C.bgHeader[2], C.bgHeader[3], 1)
    header:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    frame.header = header

    -- Header: mid gradient wash (lighter upper half)
    local hGrad = header:CreateTexture(nil, "ARTWORK")
    hGrad:SetPoint("TOPLEFT",  header, "TOPLEFT",  1, -1)
    hGrad:SetPoint("TOPRIGHT", header, "TOPRIGHT", -1, -1)
    hGrad:SetHeight(math.floor(HEADER_H * 0.55))
    hGrad:SetColorTexture(0.12, 0.04, 0.06, 0.22)

    -- Header: left crimson rail (4px)
    local hRail = header:CreateTexture(nil, "OVERLAY")
    hRail:SetPoint("TOPLEFT",    header, "TOPLEFT",    1, -1)
    hRail:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 1,  1)
    hRail:SetWidth(4)
    hRail:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)

    -- Header: bottom separator (solid)
    local hSepSolid = header:CreateTexture(nil, "OVERLAY")
    hSepSolid:SetPoint("BOTTOMLEFT",  header, "BOTTOMLEFT",  1,  0)
    hSepSolid:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -1, 0)
    hSepSolid:SetHeight(2)
    hSepSolid:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)

    -- Header: bottom glow (animated, behind solid line)
    local hSepGlow = header:CreateTexture(nil, "ARTWORK")
    hSepGlow:SetPoint("BOTTOMLEFT",  header, "BOTTOMLEFT",  0, -2)
    hSepGlow:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, -2)
    hSepGlow:SetHeight(10)
    hSepGlow:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.20)
    frame._hSepGlow = hSepGlow

    -- Logo (left side)
    local logo = header:CreateTexture(nil, "ARTWORK")
    logo:SetSize(46, 46)
    logo:SetPoint("LEFT", header, "LEFT", 14, 0)
    logo:SetTexture("Interface\\AddOns\\PreyUI\\assets\\preyLogo")
    logo:SetTexCoord(0, 1, 0, 1)
    header.logo = logo

    -- Title block (right of logo)
    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, -6)
    UseFont(title, 22, C.accentLight, "OUTLINE")
    title:SetText("PreyUI")

    local subtitle = header:CreateFontString(nil, "OVERLAY")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    UseFont(subtitle, 10, C.textDim)
    subtitle:SetText("Control Deck  —  " .. (PREY.versionString or "dev"))

    -- Version badge (styled pill, top-right area)
    local vBadge = CreateFrame("Frame", nil, header, "BackdropTemplate")
    vBadge:SetSize(90, 22)
    vBadge:SetPoint("TOPRIGHT", header, "TOPRIGHT", -46, -10)
    vBadge:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    vBadge:SetBackdropColor(C.accentDark[1], C.accentDark[2], C.accentDark[3], 0.75)
    vBadge:SetBackdropBorderColor(C.accent[1], C.accent[2], C.accent[3], 0.90)
    local vBadgeTxt = vBadge:CreateFontString(nil, "OVERLAY")
    UseFont(vBadgeTxt, 10, C.accentLight)
    vBadgeTxt:SetPoint("CENTER", 0, 0)
    vBadgeTxt:SetText("v" .. (PREY.versionString or "dev"))

    -- Player info (below version badge, top-right)
    local playerName  = UnitName("player")       or "Unknown"
    local realmName   = GetRealmName and GetRealmName() or ""
    local classColor  = GetPlayerClassColor()

    local pNameTxt = header:CreateFontString(nil, "OVERLAY")
    UseFont(pNameTxt, 12, classColor)
    pNameTxt:SetPoint("TOPRIGHT", vBadge, "BOTTOMRIGHT", 0, -5)
    pNameTxt:SetText(playerName)

    local pRealmTxt = header:CreateFontString(nil, "OVERLAY")
    UseFont(pRealmTxt, 9, C.textDim)
    pRealmTxt:SetPoint("TOPRIGHT", pNameTxt, "BOTTOMRIGHT", 0, -2)
    pRealmTxt:SetText(realmName)

    -- Spec icon (left of version badge)
    local specIcon = header:CreateTexture(nil, "ARTWORK")
    specIcon:SetSize(30, 30)
    specIcon:SetPoint("RIGHT", vBadge, "LEFT", -8, 0)
    do
        local specIndex = GetSpecialization and GetSpecialization()
        if specIndex then
            local _, _, _, iconID = GetSpecializationInfo(specIndex)
            if iconID then
                specIcon:SetTexture(iconID)
            else
                specIcon:Hide()
            end
        else
            specIcon:Hide()
        end
    end

    -- Close button
    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", header, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() frame:Hide() end)

    -- ── ANIMATIONS ──────────────────────────────────────────────────────────
    frame._glowElapsed = 0
    frame._fadeIn      = false

    frame:SetScript("OnShow", function(self)
        self:SetAlpha(0)
        self._fadeElapsed = 0
        self._fadeIn      = true
    end)

    frame:SetScript("OnUpdate", function(self, elapsed)
        -- Fade-in (0.18s)
        if self._fadeIn then
            self._fadeElapsed = (self._fadeElapsed or 0) + elapsed
            local a = math.min(1, self._fadeElapsed / 0.18)
            self:SetAlpha(a)
            if a >= 1 then self._fadeIn = false end
        end
        -- Pulsing glow on header bottom
        self._glowElapsed = self._glowElapsed + elapsed
        if self._hSepGlow then
            local pulse = 0.5 + 0.5 * math.sin(self._glowElapsed * 1.6)
            self._hSepGlow:SetAlpha(0.10 + 0.18 * pulse)
        end
    end)

    -- ── LEFT NAV RAIL ───────────────────────────────────────────────────────
    local leftRail = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    leftRail:SetPoint("TOPLEFT",    frame, "TOPLEFT",    10, -(HEADER_H + 8))
    leftRail:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10,  10)
    leftRail:SetWidth(SIDEBAR_W)
    CreateBackdrop(leftRail, C.navBg, C.border)
    frame.sidebar = leftRail

    -- Sidebar top crimson strip
    local sideTopStrip = leftRail:CreateTexture(nil, "OVERLAY")
    sideTopStrip:SetPoint("TOPLEFT",  leftRail, "TOPLEFT",  1, -1)
    sideTopStrip:SetPoint("TOPRIGHT", leftRail, "TOPRIGHT", -1, -1)
    sideTopStrip:SetHeight(2)
    sideTopStrip:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.65)

    -- Sidebar header background band
    local sideHeaderBand = leftRail:CreateTexture(nil, "BACKGROUND")
    sideHeaderBand:SetPoint("TOPLEFT",  leftRail, "TOPLEFT",  1, -1)
    sideHeaderBand:SetPoint("TOPRIGHT", leftRail, "TOPRIGHT", -1, -1)
    sideHeaderBand:SetHeight(30)
    sideHeaderBand:SetColorTexture(0.10, 0.036, 0.046, 0.7)

    -- Sidebar rail indicator dot
    local railDot = leftRail:CreateTexture(nil, "ARTWORK")
    railDot:SetSize(7, 7)
    railDot:SetPoint("TOPLEFT", leftRail, "TOPLEFT", 11, -12)
    railDot:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)

    -- Sidebar "MODULES" label
    local railLabel = leftRail:CreateFontString(nil, "OVERLAY")
    railLabel:SetPoint("TOPLEFT", railDot, "TOPRIGHT", 6, 1)
    UseFont(railLabel, 10, C.sectionHeader, "OUTLINE")
    railLabel:SetText("MODULES")

    -- Sidebar header divider
    local railDiv = leftRail:CreateTexture(nil, "ARTWORK")
    railDiv:SetPoint("TOPLEFT",  leftRail, "TOPLEFT",  8, -28)
    railDiv:SetPoint("TOPRIGHT", leftRail, "TOPRIGHT", -8, -28)
    railDiv:SetHeight(1)
    railDiv:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.28)

    -- Action button container (bottom of sidebar)
    local actionContainer = CreateFrame("Frame", nil, leftRail)
    actionContainer:SetPoint("BOTTOMLEFT",  leftRail, "BOTTOMLEFT",  0, 0)
    actionContainer:SetPoint("BOTTOMRIGHT", leftRail, "BOTTOMRIGHT", 0, 0)
    actionContainer:SetHeight(ACTION_H)
    frame.actionContainer = actionContainer

    -- Separator above action buttons
    local actionSep = actionContainer:CreateTexture(nil, "ARTWORK")
    actionSep:SetPoint("TOPLEFT",  actionContainer, "TOPLEFT",  8, 0)
    actionSep:SetPoint("TOPRIGHT", actionContainer, "TOPRIGHT", -8, 0)
    actionSep:SetHeight(1)
    actionSep:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.28)

    -- Nav scroll area
    local navScroll = CreateFrame("ScrollFrame", nil, leftRail, "UIPanelScrollFrameTemplate")
    navScroll:SetPoint("TOPLEFT",     leftRail, "TOPLEFT",     8,  -33)
    navScroll:SetPoint("BOTTOMRIGHT", leftRail, "BOTTOMRIGHT", -28, ACTION_H + 6)

    local navContent = CreateFrame("Frame", nil, navScroll)
    navContent:SetHeight(1)
    navContent:SetWidth(SIDEBAR_W - 38)
    navScroll:SetScrollChild(navContent)

    local navScrollbar = navScroll.ScrollBar
    if navScrollbar then
        local up   = navScrollbar.ScrollUpButton   or navScrollbar.Back
        local down = navScrollbar.ScrollDownButton or navScrollbar.Forward
        if up   then up:Hide()   end
        if down then down:Hide() end
        local thumb = navScrollbar.GetThumbTexture and navScrollbar:GetThumbTexture()
        if thumb then thumb:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.5) end
    end

    frame.navContainer = navContent
    frame.navScroll    = navScroll

    -- ── CONTENT AREA ────────────────────────────────────────────────────────
    local contentArea = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    contentArea:SetPoint("TOPLEFT",     leftRail, "TOPRIGHT",    10, 0)
    contentArea:SetPoint("BOTTOMRIGHT", frame,    "BOTTOMRIGHT", -10, 10)
    CreateBackdrop(contentArea, C.bgContent, C.border)
    frame.contentArea = contentArea

    -- Content area: top accent strip
    local caTopStrip = contentArea:CreateTexture(nil, "OVERLAY")
    caTopStrip:SetPoint("TOPLEFT",  contentArea, "TOPLEFT",  1, -1)
    caTopStrip:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", -1, -1)
    caTopStrip:SetHeight(2)
    caTopStrip:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.55)

    -- Content banner frame (shows active module name)
    local contentBanner = CreateFrame("Frame", nil, contentArea, "BackdropTemplate")
    contentBanner:SetPoint("TOPLEFT",  contentArea, "TOPLEFT",  2, -2)
    contentBanner:SetPoint("TOPRIGHT", contentArea, "TOPRIGHT", -2, -2)
    contentBanner:SetHeight(CONTENT_BANNER_H)
    contentBanner:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    contentBanner:SetBackdropColor(0.085, 0.036, 0.046, 0.92)
    contentBanner:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
    frame.contentBanner = contentBanner

    -- Banner: left accent bar (4px)
    local bannerRail = contentBanner:CreateTexture(nil, "OVERLAY")
    bannerRail:SetPoint("TOPLEFT",    contentBanner, "TOPLEFT",    0, 0)
    bannerRail:SetPoint("BOTTOMLEFT", contentBanner, "BOTTOMLEFT", 0, 0)
    bannerRail:SetWidth(4)
    bannerRail:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.85)

    -- Banner: module name (large text, updates on tab select)
    local bannerTitle = contentBanner:CreateFontString(nil, "OVERLAY")
    UseFont(bannerTitle, 16, C.accentLight)
    bannerTitle:SetPoint("TOPLEFT", contentBanner, "TOPLEFT", 16, -9)
    bannerTitle:SetText("PreyUI Settings")
    frame.bannerTitle = bannerTitle

    -- Banner: description (small, muted)
    local bannerDesc = contentBanner:CreateFontString(nil, "OVERLAY")
    UseFont(bannerDesc, 10, C.textMuted)
    bannerDesc:SetPoint("TOPLEFT", bannerTitle, "BOTTOMLEFT", 0, -3)
    bannerDesc:SetText("Select a module from the left panel to begin configuration")
    frame.bannerDesc = bannerDesc

    -- Banner: bottom separator
    local bannerSep = contentBanner:CreateTexture(nil, "ARTWORK")
    bannerSep:SetPoint("BOTTOMLEFT",  contentBanner, "BOTTOMLEFT",  2, 0)
    bannerSep:SetPoint("BOTTOMRIGHT", contentBanner, "BOTTOMRIGHT", -2, 0)
    bannerSep:SetHeight(1)
    bannerSep:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.35)

    -- ── FRAME STATE ─────────────────────────────────────────────────────────
    frame.tabs             = {}
    frame.pages            = {}
    frame.navItems         = {}     -- Ordered: {type="tab"|"category", widget, [height]}
    frame.activeTab        = nil
    frame.NAV_BUTTON_HEIGHT  = NAV_BTN_H
    frame.NAV_SPACING        = NAV_GAP
    frame.ACTION_BUTTON_HEIGHT = ACTION_BTN_H
    frame.CONTENT_BANNER_H   = CONTENT_BANNER_H
    frame._realTabCount    = 0      -- Tracks real nav-tab count (categories excluded)

    -- Per-tab descriptions shown in the banner
    frame.tabDescriptions = {
        [1]  = "General gameplay improvements, quality of life tweaks, and accessibility options",
        [2]  = "Unit frame appearance, health bars, nameplates, and castbar configuration",
        [3]  = "Minimap sizing, position, data text panels, and minimap button ring",
        [4]  = "Action bar layout, button size, visibility rules, and paging behavior",
        [5]  = "UI element visibility toggles, skin overrides, and cosmetic controls",
        [6]  = "Cooldown Manager setup, class resource bars, and spell tracking",
        [7]  = "Cooldown animations, GCD ring display, and visual effect options",
        [8]  = "Keybind overlay display, rotation assistance, and proc alert settings",
        [9]  = "Custom item, spell, and aura tracker creation and layout",
        [10] = "HUD element z-ordering, layer priorities, and overlap rules",
        [11] = "Brewmaster Monk stagger bar display, thresholds, and color settings",
        [12] = "Per-specialization profile management and automatic spec-switching",
        [13] = "Import and export PreyUI profiles and share settings with others",
        [14] = "Search across all settings to quickly find any option by keyword",
    }

    -- ── RESIZE / SAVE ───────────────────────────────────────────────────────
    frame:SetScript("OnSizeChanged", function(self, width, height)
        if GUI.RelayoutTabs then GUI:RelayoutTabs(self) end
        local db2 = PREY.PREYCore and PREY.PREYCore.db and PREY.PREYCore.db.profile
        if db2 then
            db2.configPanelWidth  = math.floor(width  + 0.5)
            db2.configPanelHeight = math.floor(height + 0.5)
        end
    end)

    -- ── RESIZE HANDLE (bottom-right corner) ─────────────────────────────────
    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(20, 20)
    resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    resizeHandle:SetFrameLevel(frame:GetFrameLevel() + 20)

    local grip = resizeHandle:CreateTexture(nil, "OVERLAY")
    grip:SetAllPoints()
    grip:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetVertexColor(C.accentLight[1], C.accentLight[2], C.accentLight[3], 0.90)

    local gripDown = resizeHandle:CreateTexture(nil, "ARTWORK")
    gripDown:SetAllPoints()
    gripDown:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    gripDown:SetVertexColor(C.accent[1], C.accent[2], C.accent[3], 1)
    gripDown:Hide()

    resizeHandle:SetScript("OnMouseDown", function(self, btn)
        if btn ~= "LeftButton" then return end
        grip:Hide(); gripDown:Show()
        local left, top = frame:GetLeft(), frame:GetTop()
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        self.startX, self.startY = GetCursorPosition()
        self.startW = frame:GetWidth()
        self.startH = frame:GetHeight()
        self.resizing = true
        self:SetScript("OnUpdate", function(r)
            if not r.resizing then return end
            local cx, cy = GetCursorPosition()
            local sc     = frame:GetEffectiveScale()
            local newW   = math.max(800,  math.min(1600, r.startW + (cx - r.startX) / sc))
            local newH   = math.max(560,  math.min(1100, r.startH + (r.startY - cy) / sc))
            frame:SetSize(newW, newH)
        end)
    end)

    resizeHandle:SetScript("OnMouseUp", function(self, btn)
        if btn ~= "LeftButton" then return end
        self.resizing = false
        self:SetScript("OnUpdate", nil)
        gripDown:Hide(); grip:Show()
    end)

    resizeHandle:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText("Drag to resize", 1, 1, 1)
        GameTooltip:Show()
    end)
    resizeHandle:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.resizeHandle = resizeHandle

    return frame
end

-- ---------------------------------------------------------------------------
-- NAV CATEGORY DIVIDER
-- Inserts a visual group label between nav items (not added to frame.tabs).
-- ---------------------------------------------------------------------------
function GUI:_InsertNavCategory(frame, label, color)
    local col = color or C.sectionHeader

    local cat = CreateFrame("Frame", nil, frame.navContainer)
    cat:SetHeight(CAT_H)

    -- Small colored dot bullet
    local dot = cat:CreateTexture(nil, "ARTWORK")
    dot:SetSize(5, 5)
    dot:SetPoint("TOPLEFT", cat, "TOPLEFT", 2, -math.floor((CAT_H - 5) * 0.5))
    dot:SetColorTexture(col[1], col[2], col[3], 1)

    -- Category label text
    local lbl = cat:CreateFontString(nil, "OVERLAY")
    UseFont(lbl, 9, col, "OUTLINE")
    lbl:SetText(label)
    lbl:SetPoint("LEFT", dot, "RIGHT", 5, 0)

    -- Thin line extending to the right of the label
    local ln = cat:CreateTexture(nil, "ARTWORK")
    ln:SetPoint("LEFT",  lbl, "RIGHT",  8, 0)
    ln:SetPoint("RIGHT", cat, "RIGHT", -4, 0)
    ln:SetHeight(1)
    ln:SetColorTexture(col[1], col[2], col[3], 0.28)

    table.insert(frame.navItems, {type = "category", widget = cat, height = CAT_H})
    return cat
end

-- ---------------------------------------------------------------------------
-- RELAYOUT TABS
-- Lays out navItems (categories + nav tabs) and action buttons.
-- ---------------------------------------------------------------------------
function GUI:RelayoutTabs(frame)
    if not frame or not frame.navItems then return end

    local navY       = 0
    local actionY    = -8
    local navWidth   = math.max(180, math.floor(frame.navContainer:GetWidth()) - 2)
    local actionWidth = frame.sidebar:GetWidth() - 16

    for _, item in ipairs(frame.navItems) do
        if item.type == "category" then
            item.widget:SetWidth(navWidth)
            item.widget:ClearAllPoints()
            item.widget:SetPoint("TOPLEFT", frame.navContainer, "TOPLEFT", 4, -navY)
            navY = navY + item.height + 2
        elseif item.type == "tab" then
            item.widget:SetWidth(navWidth)
            item.widget:ClearAllPoints()
            item.widget:SetPoint("TOPLEFT", frame.navContainer, "TOPLEFT", 0, -navY)
            navY = navY + frame.NAV_BUTTON_HEIGHT + frame.NAV_SPACING
        end
    end

    for _, tab in ipairs(frame.tabs) do
        if tab.isActionButton then
            tab:SetWidth(actionWidth)
            tab:ClearAllPoints()
            tab:SetPoint("TOPLEFT", frame.actionContainer, "TOPLEFT", 8, actionY)
            actionY = actionY - (frame.ACTION_BUTTON_HEIGHT + 6)
        end
    end

    frame.navContainer:SetHeight(math.max(1, navY))
end

-- ---------------------------------------------------------------------------
-- ADD TAB
-- Auto-inserts category headers at the right nav positions.
-- ---------------------------------------------------------------------------
function GUI:AddTab(frame, name, pageCreateFunc)
    frame._realTabCount = (frame._realTabCount or 0) + 1
    local realIndex     = frame._realTabCount

    -- Inject category labels at group boundaries
    if     realIndex == 1  then self:_InsertNavCategory(frame, "INTERFACE",       C.catCore)
    elseif realIndex == 6  then self:_InsertNavCategory(frame, "COOLDOWN SYSTEM", C.catCooldown)
    elseif realIndex == 10 then self:_InsertNavCategory(frame, "CONFIGURATION",   C.catConfig)
    end

    local index = #frame.tabs + 1

    local tab = CreateFrame("Button", nil, frame.navContainer, "BackdropTemplate")
    tab:SetSize(math.max(180, frame.navContainer:GetWidth() - 2), frame.NAV_BUTTON_HEIGHT)
    tab:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    tab:SetBackdropColor(unpack(C.navItemBg))
    tab:SetBackdropBorderColor(unpack(C.border))
    tab.index     = index
    tab.name      = name
    tab.realIndex = realIndex

    -- Left accent bar (4px, crimson, hidden until active)
    tab.accentBar = tab:CreateTexture(nil, "OVERLAY")
    tab.accentBar:SetPoint("TOPLEFT",    tab, "TOPLEFT",    0, 0)
    tab.accentBar:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
    tab.accentBar:SetWidth(4)
    tab.accentBar:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 1)
    tab.accentBar:SetAlpha(0)

    -- Crimson glow sweep (wide, very faint, behind accent bar)
    tab.accentGlow = tab:CreateTexture(nil, "BACKGROUND")
    tab.accentGlow:SetPoint("TOPLEFT",    tab, "TOPLEFT",    0, 0)
    tab.accentGlow:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
    tab.accentGlow:SetWidth(50)
    tab.accentGlow:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.11)
    tab.accentGlow:SetAlpha(0)

    -- Tab number badge (right-aligned, dim)
    tab.badge = tab:CreateFontString(nil, "OVERLAY")
    UseFont(tab.badge, 8, C.textDim)
    tab.badge:SetPoint("RIGHT", tab, "RIGHT", -8, 0)
    tab.badge:SetText(tostring(realIndex))
    tab.badge:SetAlpha(0.55)

    -- Arrow indicator (shown when active, right of label)
    tab.arrow = tab:CreateFontString(nil, "OVERLAY")
    UseFont(tab.arrow, 12, C.accentLight)
    tab.arrow:SetPoint("RIGHT", tab, "RIGHT", -20, 0)
    tab.arrow:SetText("›")
    tab.arrow:SetAlpha(0)

    -- Tab label text
    tab.text = tab:CreateFontString(nil, "OVERLAY")
    tab.text:SetPoint("LEFT",  tab, "LEFT",  10, 0)
    tab.text:SetPoint("RIGHT", tab, "RIGHT", -28, 0)
    tab.text:SetJustifyH("LEFT")
    UseFont(tab.text, 11, C.tabNormal)
    tab.text:SetText(name)

    frame.tabs[index]  = tab
    frame.pages[index] = {createFunc = pageCreateFunc, frame = nil}
    table.insert(frame.navItems, {type = "tab", widget = tab})

    -- Hover states
    tab:SetScript("OnEnter", function(self)
        if frame.activeTab ~= self.index then
            pcall(self.SetBackdropColor,       self, unpack(C.navItemHoverBg))
            pcall(self.SetBackdropBorderColor, self, unpack(C.borderLight))
            self.text:SetTextColor(unpack(C.tabHover))
        end
    end)
    tab:SetScript("OnLeave", function(self)
        if frame.activeTab ~= self.index then
            pcall(self.SetBackdropColor,       self, unpack(C.navItemBg))
            pcall(self.SetBackdropBorderColor, self, unpack(C.border))
            self.text:SetTextColor(unpack(C.tabNormal))
        end
    end)
    tab:SetScript("OnClick", function() GUI:SelectTab(frame, index) end)

    self:RelayoutTabs(frame)

    if index == 1 then
        self:SelectTab(frame, 1)
    end

    return tab
end

-- ---------------------------------------------------------------------------
-- ADD ACTION BUTTON
-- Footer utility buttons (appear at the bottom of the sidebar).
-- ---------------------------------------------------------------------------
function GUI:AddActionButton(frame, name, onClick, accentColor)
    local index = #frame.tabs + 1
    local btn   = CreateFrame("Button", nil, frame.actionContainer, "BackdropTemplate")
    btn:SetSize(frame.sidebar:GetWidth() - 16, frame.ACTION_BUTTON_HEIGHT)
    btn.index          = index
    btn.name           = name
    btn.isActionButton = true
    btn.bgColor        = {unpack(C.navActionBg)}
    btn.borderColor    = accentColor or {C.accent[1], C.accent[2], C.accent[3], 1}

    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(unpack(btn.bgColor))
    btn:SetBackdropBorderColor(unpack(btn.borderColor))

    -- Left strip accent
    btn.strip = btn:CreateTexture(nil, "ARTWORK")
    btn.strip:SetPoint("TOPLEFT",    btn, "TOPLEFT",    0, 0)
    btn.strip:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    btn.strip:SetWidth(3)
    btn.strip:SetColorTexture(btn.borderColor[1], btn.borderColor[2], btn.borderColor[3], 0.80)

    -- Button label
    btn.text = btn:CreateFontString(nil, "OVERLAY")
    btn.text:SetPoint("CENTER", btn, "CENTER", 2, 0)
    UseFont(btn.text, 11, btn.borderColor)
    btn.text:SetText(name)

    btn:SetScript("OnEnter", function(self)
        pcall(self.SetBackdropColor,       self, 0.08, 0.06, 0.09, 1)
        pcall(self.SetBackdropBorderColor, self, unpack(C.accentLight))
        self.text:SetTextColor(unpack(C.accentLight))
    end)
    btn:SetScript("OnLeave", function(self)
        pcall(self.SetBackdropColor,       self, unpack(self.bgColor))
        pcall(self.SetBackdropBorderColor, self, unpack(self.borderColor))
        self.text:SetTextColor(unpack(self.borderColor))
    end)
    btn:SetScript("OnClick", function() if onClick then onClick() end end)

    frame.tabs[index]  = btn
    frame.pages[index] = nil
    self:RelayoutTabs(frame)
    return btn
end

-- ---------------------------------------------------------------------------
-- SELECT TAB
-- Switches the active nav item and updates the content area.
-- ---------------------------------------------------------------------------
function GUI:SelectTab(frame, index)
    local selectedTab = frame.tabs[index]
    if selectedTab and selectedTab.isActionButton then return end

    -- Lazy-build search index when the Search tab is first opened
    if index == self._searchTabIndex and self._allTabsAdded and not self._searchIndexBuilt then
        self:ForceLoadAllTabs()
        self._searchIndexBuilt = true
    end

    -- Clear live search if active
    if frame._searchActive and frame.searchBox and frame.searchBox.editBox then
        frame.searchBox.editBox:SetText("")
        if self.ClearSearchResults then self:ClearSearchResults() end
    end

    -- Deselect previous tab
    if frame.activeTab then
        local prev     = frame.tabs[frame.activeTab]
        local prevPage = frame.pages[frame.activeTab]

        if prev and not prev.isActionButton then
            pcall(prev.SetBackdropColor,       prev, unpack(C.navItemBg))
            pcall(prev.SetBackdropBorderColor, prev, unpack(C.border))
            prev.text:SetTextColor(unpack(C.tabNormal))
            if prev.accentBar  then prev.accentBar:SetAlpha(0)   end
            if prev.accentGlow then prev.accentGlow:SetAlpha(0)  end
            if prev.arrow      then prev.arrow:SetAlpha(0)       end
            if prev.badge      then prev.badge:SetAlpha(0.55)    end
        end

        if prevPage and prevPage.frame then prevPage.frame:Hide() end
    end

    -- Activate the new tab
    frame.activeTab = index
    local tab = frame.tabs[index]

    if tab and not tab.isActionButton then
        pcall(tab.SetBackdropColor,       tab, unpack(C.navItemActiveBg))
        pcall(tab.SetBackdropBorderColor, tab, unpack(C.accent))
        tab.text:SetTextColor(unpack(C.tabSelectedText))
        if tab.accentBar  then tab.accentBar:SetAlpha(1)   end
        if tab.accentGlow then tab.accentGlow:SetAlpha(1)  end
        if tab.arrow      then tab.arrow:SetAlpha(1)       end
        if tab.badge      then tab.badge:SetAlpha(1)       end

        -- Update content banner labels
        if frame.bannerTitle then
            frame.bannerTitle:SetText(tab.name or "Settings")
        end
        if frame.bannerDesc and frame.tabDescriptions then
            local ri  = tab.realIndex or index
            local desc = frame.tabDescriptions[ri]
            frame.bannerDesc:SetText(desc or "Configure this module's settings below")
        end
    end

    -- Build / show the page frame
    local page = frame.pages[index]
    if not page then return end

    if not page.frame then
        local bannerOffset = frame.CONTENT_BANNER_H + 4   -- 2px top margin + banner + 2px gap
        page.frame = CreateFrame("Frame", nil, frame.contentArea)
        page.frame:SetPoint("TOPLEFT",     frame.contentArea, "TOPLEFT",     2, -bannerOffset)
        page.frame:SetPoint("BOTTOMRIGHT", frame.contentArea, "BOTTOMRIGHT", -2,  2)
        page.frame:EnableMouse(false)
        if page.createFunc then
            page.createFunc(page.frame)
            page.built = true
        end
    end

    page.frame:Show()

    -- Fire OnShow on all children (refreshes dynamic widgets like dropdowns)
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
