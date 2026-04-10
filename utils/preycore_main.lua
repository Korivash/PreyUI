local ADDON_NAME, ns = ...
local PREY = PreyUI


local PREYCore = PREY:NewModule("PREYCore", "AceConsole-3.0", "AceEvent-3.0")
PREY.PREYCore = PREYCore


ns.Addon = PREYCore


ns.Utils = {}
local ViewerFrameOrder = setmetatable({}, { __mode = "k" })
local nextViewerFrameOrder = 0

local function GetViewerStableFrameOrder(frame)
    if not frame then return math.huge end
    local order = ViewerFrameOrder[frame]
    if not order then
        nextViewerFrameOrder = nextViewerFrameOrder + 1
        order = nextViewerFrameOrder
        ViewerFrameOrder[frame] = order
    end
    return order
end


function ns.Utils.IsInInstancedContent()
    local inInstance, instanceType = IsInInstance()
    return inInstance and (instanceType == "party" or instanceType == "raid")
end


function ns.Utils.IsSecretValue(value)
    if type(issecretvalue) == "function" then
        return issecretvalue(value)
    end
    return false
end


PREYCore.__pendingReload = false
PREYCore.__reloadEventFrame = nil


function PREYCore:SafeReload()
    if InCombatLockdown() then
        if not self.__pendingReload then
            self.__pendingReload = true
            print("|cFFB91C1CPreyUI:|r Reload queued - will execute when combat ends.")


            if not self.__reloadEventFrame then
                self.__reloadEventFrame = CreateFrame("Frame")
                self.__reloadEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                self.__reloadEventFrame:SetScript("OnEvent", function(frame, event)
                    if event == "PLAYER_REGEN_ENABLED" and PREYCore.__pendingReload then
                        PREYCore.__pendingReload = false

                        PREYCore:ShowReloadPopup()
                    end
                end)
            end
        end
    else
        ReloadUI()
    end
end


function PREYCore:ShowReloadPopup()

    if PreyUI and PreyUI.GUI and PreyUI.GUI.ShowConfirmation then
        PreyUI.GUI:ShowConfirmation({
            title = "Reload Ready",
            message = "Combat ended. Click to reload the UI.",
            acceptText = "Reload Now",
            cancelText = "Later",
            onAccept = function() ReloadUI() end,
        })
    else

        print("|cFFB91C1CPreyUI:|r Combat ended. Type /reload to reload.")
    end
end


function PREY:SafeReload()
    if self.PREYCore then
        self.PREYCore:SafeReload()
    else

        if InCombatLockdown() then
            print("|cFFB91C1CPreyUI:|r Cannot reload during combat.")
        else
            ReloadUI()
        end
    end
end

local LSM = LibStub("LibSharedMedia-3.0")
local LCG = LibStub("LibCustomGlow-1.0", true)

local AceSerializer = LibStub("AceSerializer-3.0", true)
local LibDeflate    = LibStub("LibDeflate", true)
local LibDualSpec   = LibStub("LibDualSpec-1.0", true)


function PREYCore:ExportProfileToString()
    if not self.db or not self.db.profile then
        return "No profile loaded."
    end
    if not AceSerializer or not LibDeflate then
        return "Export requires AceSerializer-3.0 and LibDeflate."
    end

    local serialized = AceSerializer:Serialize(self.db.profile)
    if not serialized or type(serialized) ~= "string" then
        return "Failed to serialize profile."
    end

    local compressed = LibDeflate:CompressDeflate(serialized)
    if not compressed then
        return "Failed to compress profile."
    end

    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then
        return "Failed to encode profile."
    end

    return "PREY1:" .. encoded
end

function PREYCore:ImportProfileFromString(str)
    if not self.db or not self.db.profile then
        return false, "No profile loaded."
    end
    if not AceSerializer or not LibDeflate then
        return false, "Import requires AceSerializer-3.0 and LibDeflate."
    end
    if not str or str == "" then
        return false, "No data provided."
    end

    str = str:gsub("%s+", "")
    str = str:gsub("^PREY1:", "")
    str = str:gsub("^KORI1:", "")
    str = str:gsub("^CDM1:", "")

    local compressed = LibDeflate:DecodeForPrint(str)
    if not compressed then
        return false, "Could not decode string (maybe corrupted)."
    end

    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then
        return false, "Could not decompress data."
    end

    local ok, t = AceSerializer:Deserialize(serialized)
    if not ok or type(t) ~= "table" then
        return false, "Could not deserialize profile."
    end

    local profile = self.db.profile
    for k in pairs(profile) do
        profile[k] = nil
    end
    for k, v in pairs(t) do
        profile[k] = v
    end

    if self.RefreshAll then
        self:RefreshAll()
    end

    return true
end


function PREYCore:GetHUDFrameLevel(priority)
    return 100 + (priority or 5) * 20
end


function PREYCore.SafeSetBackdrop(frame, backdropInfo, borderColor)
    if not frame or not frame.SetBackdrop then return false end


    local hasValidSize = false
    local ok, result = pcall(function()
        local w = frame:GetWidth()
        local h = frame:GetHeight()

        if w and h then
            local test = w + h
            if test > 0 then
                return true
            end
        end
        return false
    end)
    if ok and result then
        hasValidSize = true
    end


    if not hasValidSize then
        frame.__preyBackdropPending = backdropInfo
        frame.__preyBackdropBorderColor = borderColor
        PREYCore.__pendingBackdrops = PREYCore.__pendingBackdrops or {}
        PREYCore.__pendingBackdrops[frame] = true


        if not PREYCore.__backdropUpdateFrame then
            local updateFrame = CreateFrame("Frame")
            local elapsed = 0
            updateFrame:SetScript("OnUpdate", function(self, delta)
                elapsed = elapsed + delta
                if elapsed < 0.1 then return end
                elapsed = 0

                local processed = {}
                for pendingFrame in pairs(PREYCore.__pendingBackdrops or {}) do
                    if pendingFrame and pendingFrame.__preyBackdropPending ~= nil then

                        local checkOk, checkResult = pcall(function()
                            local w = pendingFrame:GetWidth()
                            local h = pendingFrame:GetHeight()
                            if w and h then
                                local test = w + h
                                return test > 0
                            end
                            return false
                        end)

                        if checkOk and checkResult and not InCombatLockdown() then
                            local setOk = pcall(pendingFrame.SetBackdrop, pendingFrame, pendingFrame.__preyBackdropPending)
                            if setOk and pendingFrame.__preyBackdropPending and pendingFrame.__preyBackdropBorderColor then
                                local c = pendingFrame.__preyBackdropBorderColor
                                pendingFrame:SetBackdropBorderColor(c[1], c[2], c[3], c[4] or 1)
                            end
                            pendingFrame.__preyBackdropPending = nil
                            pendingFrame.__preyBackdropBorderColor = nil
                            table.insert(processed, pendingFrame)
                        end
                    else
                        table.insert(processed, pendingFrame)
                    end
                end

                for _, pf in ipairs(processed) do
                    PREYCore.__pendingBackdrops[pf] = nil
                end


                local hasAny = false
                for _ in pairs(PREYCore.__pendingBackdrops or {}) do
                    hasAny = true
                    break
                end
                if not hasAny then
                    self:Hide()
                end
            end)
            PREYCore.__backdropUpdateFrame = updateFrame
        end
        PREYCore.__backdropUpdateFrame:Show()
        return false
    end


    if InCombatLockdown() then
        local alreadyPending = PREYCore.__pendingBackdrops and PREYCore.__pendingBackdrops[frame]
        if not alreadyPending then
            frame.__preyBackdropPending = backdropInfo
            frame.__preyBackdropBorderColor = borderColor

            if not PREYCore.__backdropEventFrame then
                local eventFrame = CreateFrame("Frame")
                eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                eventFrame:SetScript("OnEvent", function(self)
                    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                    for pendingFrame in pairs(PREYCore.__pendingBackdrops or {}) do
                        if pendingFrame and pendingFrame.__preyBackdropPending ~= nil then
                            if not InCombatLockdown() then
                                local setOk = pcall(pendingFrame.SetBackdrop, pendingFrame, pendingFrame.__preyBackdropPending)
                                if setOk and pendingFrame.__preyBackdropPending and pendingFrame.__preyBackdropBorderColor then
                                    local c = pendingFrame.__preyBackdropBorderColor
                                    pendingFrame:SetBackdropBorderColor(c[1], c[2], c[3], c[4] or 1)
                                end
                            end
                            pendingFrame.__preyBackdropPending = nil
                            pendingFrame.__preyBackdropBorderColor = nil
                        end
                    end
                    PREYCore.__pendingBackdrops = {}
                end)
                PREYCore.__backdropEventFrame = eventFrame
            end

            PREYCore.__pendingBackdrops = PREYCore.__pendingBackdrops or {}
            PREYCore.__pendingBackdrops[frame] = true
            PREYCore.__backdropEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
        return false
    end


    local setOk = pcall(frame.SetBackdrop, frame, backdropInfo)
    if setOk and backdropInfo and borderColor then
        frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
    end
    return setOk
end


PREYCore.viewers = {


}

local defaults = {
    profile = {

        nudgeAmount = 1,


        general = {
            uiScale = 0.64,
            eyefinity = false,
            ultrawide = false,
            font = "Prey",
            fontOutline = "OUTLINE",
            texture = "Prey v5",
            darkMode = false,
            darkModeHealthColor = { 0, 0, 0, 1 },
            darkModeBgColor = { 0.592, 0.592, 0.592, 1 },
            darkModeOpacity = 0.7,
            darkModeHealthOpacity = 0.7,
            darkModeBgOpacity = 0.7,
            masterColorNameText = false,
            masterColorToTText = false,
            masterColorPowerText = false,
            masterColorHealthText = false,
            masterColorCastbarText = false,
            defaultUseClassColor = true,
            defaultHealthColor = { 0.2, 0.2, 0.2, 1 },
            hostilityColorHostile = { 0.8, 0.2, 0.2, 1 },
            hostilityColorNeutral = { 1, 1, 0.2, 1 },
            hostilityColorFriendly = { 0.2, 0.8, 0.2, 1 },
            defaultBgColor = { 0, 0, 0, 1 },
            defaultOpacity = 1.0,
            defaultHealthOpacity = 1.0,
            defaultBgOpacity = 1.0,
            applyGlobalFontToBlizzard = true,
            autoInsertKey = true,
            skinKeystoneFrame = true,
            skinGameMenu = false,
            addPreyUIButton = false,
            gameMenuFontSize = 12,
            skinPowerBarAlt = true,
            skinOverrideActionBar = false,
            skinObjectiveTracker = false,
            objectiveTrackerHeight = 600,
            objectiveTrackerModuleFontSize = 12,
            objectiveTrackerTitleFontSize = 10,
            objectiveTrackerTextFontSize = 10,
            hideObjectiveTrackerBorder = false,
            objectiveTrackerModuleColor = { 1.0, 0.82, 0.0, 1.0 },
            objectiveTrackerTitleColor = { 1.0, 1.0, 1.0, 1.0 },
            objectiveTrackerTextColor = { 0.8, 0.8, 0.8, 1.0 },
            skinInstanceFrames = false,
            skinBgColor = { 0.008, 0.008, 0.008, 1 },
            skinAlerts = true,
            skinCharacterFrame = true,
            skinInspectFrame = true,
            skinLootWindow = true,
            skinLootUnderMouse = true,
            skinLootHistory = true,
            skinRollFrames = true,
            skinRollSpacing = 6,
            skinUseClassColor = true,
            skinCustomColor = { 0.820, 0.180, 0.220, 1 },

            sellJunk = true,
            autoRepair = "personal",
            autoRoleAccept = true,
            autoAcceptInvites = "all",
            autoAcceptQuest = false,
            autoTurnInQuest = false,
            questHoldShift = true,
            fastAutoLoot = true,
            autoSelectGossip = false,
            autoCombatLog = false,
            autoDeleteConfirm = true,

            quickSalvage = {
                enabled = false,
                modifier = "ALT",
            },

            mplusTeleportEnabled = true,
            keyTrackerEnabled = true,
            keyTrackerFontSize = 9,
        },


        alerts = {
            enabled = true,
            alertPosition = { point = "TOP", relPoint = "TOP", x = 1.667, y = -293.333 },
            toastPosition = { point = "CENTER", relPoint = "CENTER", x = -5.833, y = 268.333 },
        },


        raidBuffs = {
            enabled = true,
            showOnlyInGroup = true,
            providerMode = false,
            hideLabelBar = false,
            iconSize = 32,
            labelFontSize = 12,
            labelTextColor = nil,
            position = nil,
        },


        mplusTimer = {
            enabled = false,
            layoutMode = "sleek",
            showTimer = true,
            showBorder = true,
            showDeaths = true,
            showAffixes = true,
            showObjectives = true,
            position = { x = -11.667, y = -204.998 },
        },


        character = {
            enabled = true,
            showItemName = true,
            showItemLevel = true,
            showEnchants = true,
            showGems = true,
            showDurability = false,
            inspectEnabled = true,
            showModelBackground = true,

            showInspectItemName = true,
            showInspectItemLevel = true,
            showInspectEnchants = true,
            showInspectGems = true,


            panelScale = 1.0,
            overlayScale = 0.75,
            backgroundColor = {0, 0, 0, 0.762},
            statsTextSize = 13,
            statsTextColor = {1, 1, 1, 1},
            ilvlTextSize = 8,
            headerTextSize = 16,
            secondaryStatFormat = "both",
            compactStats = true,
            headerClassColor = true,
            headerColor = {0.820, 0.180, 0.220},
            enchantTextSize = 10,
            enchantClassColor = true,
            enchantTextColor = {0.820, 0.180, 0.220},
            enchantFont = nil,
            noEnchantTextColor = {1, 0.341, 0.314, 1},
            slotTextSize = 12,
            slotPadding = 0,
            upgradeTrackColor = {1, 0.816, 0.145, 1},
        },


        loot = {
            enabled = true,
            lootUnderMouse = false,
            showTransmogMarker = true,
            position = { point = "TOP", relPoint = "TOP", x = 289.166, y = -165.667 },
        },


        lootRoll = {
            enabled = true,
            growDirection = "DOWN",
            spacing = 4,
            position = { point = "TOP", relPoint = "TOP", x = -11.667, y = -166 },
        },


        lootResults = {
            enabled = true,
        },


        ncdm = {
            essential = {
                enabled = true,
                layoutDirection = "HORIZONTAL",
                row1 = {
                    iconCount = 8,
                    iconSize = 39,
                    borderSize = 1,
                    borderColorTable = {0, 0, 0, 1},
                    aspectRatioCrop = 1.0,
                    zoom = 0,
                    padding = 2,
                    xOffset = 0,
                    yOffset = 0,
                    durationSize = 16,
                    durationOffsetX = 0,
                    durationOffsetY = 0,
                    stackSize = 12,
                    stackOffsetX = 0,
                    stackOffsetY = 2,
                    durationTextColor = {1, 1, 1, 1},
                    durationAnchor = "CENTER",
                    stackTextColor = {1, 1, 1, 1},
                    stackAnchor = "BOTTOMRIGHT",
                },
                row2 = {
                    iconCount = 8,
                    iconSize = 39,
                    borderSize = 1,
                    borderColorTable = {0, 0, 0, 1},
                    aspectRatioCrop = 1.0,
                    zoom = 0,
                    padding = 2,
                    xOffset = 0,
                    yOffset = 3,
                    durationSize = 16,
                    durationOffsetX = 0,
                    durationOffsetY = 0,
                    stackSize = 12,
                    stackOffsetX = 0,
                    stackOffsetY = 2,
                    durationTextColor = {1, 1, 1, 1},
                    durationAnchor = "CENTER",
                    stackTextColor = {1, 1, 1, 1},
                    stackAnchor = "BOTTOMRIGHT",
                },
                row3 = {
                    iconCount = 8,
                    iconSize = 39,
                    borderSize = 1,
                    borderColorTable = {0, 0, 0, 1},
                    aspectRatioCrop = 1.0,
                    zoom = 0,
                    padding = 2,
                    xOffset = 0,
                    yOffset = 0,
                    durationSize = 16,
                    durationOffsetX = 0,
                    durationOffsetY = 0,
                    stackSize = 12,
                    stackOffsetX = 0,
                    stackOffsetY = 2,
                    durationTextColor = {1, 1, 1, 1},
                    durationAnchor = "CENTER",
                    stackTextColor = {1, 1, 1, 1},
                    stackAnchor = "BOTTOMRIGHT",
                },
                customEntries = {
                    enabled = true,
                },
            },
            utility = {
                enabled = true,
                layoutDirection = "HORIZONTAL",
                row1 = {
                    iconCount = 6,
                    iconSize = 30,
                    borderSize = 1,
                    borderColorTable = {0, 0, 0, 1},
                    aspectRatioCrop = 1.0,
                    zoom = 0,
                    padding = 2,
                    xOffset = 0,
                    yOffset = 0,
                    durationSize = 14,
                    durationOffsetX = 0,
                    durationOffsetY = 0,
                    stackSize = 14,
                    stackOffsetX = 0,
                    stackOffsetY = 0,
                    durationTextColor = {1, 1, 1, 1},
                    durationAnchor = "CENTER",
                    stackTextColor = {1, 1, 1, 1},
                    stackAnchor = "BOTTOMRIGHT",
                },
                row2 = {
                    iconCount = 0,
                    iconSize = 30,
                    borderSize = 1,
                    borderColorTable = {0, 0, 0, 1},
                    aspectRatioCrop = 1.0,
                    zoom = 0,
                    padding = 2,
                    xOffset = 0,
                    yOffset = 8,
                    durationSize = 14,
                    durationOffsetX = 0,
                    durationOffsetY = 0,
                    stackSize = 14,
                    stackOffsetX = 0,
                    stackOffsetY = 0,
                    durationTextColor = {1, 1, 1, 1},
                    durationAnchor = "CENTER",
                    stackTextColor = {1, 1, 1, 1},
                    stackAnchor = "BOTTOMRIGHT",
                },
                row3 = {
                    iconCount = 0,
                    iconSize = 30,
                    borderSize = 1,
                    borderColorTable = {0, 0, 0, 1},
                    aspectRatioCrop = 1.0,
                    zoom = 0,
                    padding = 2,
                    xOffset = 0,
                    yOffset = 4,
                    durationSize = 14,
                    durationOffsetX = 0,
                    durationOffsetY = 0,
                    stackSize = 14,
                    stackOffsetX = 0,
                    stackOffsetY = 0,
                    durationTextColor = {1, 1, 1, 1},
                    durationAnchor = "CENTER",
                    stackTextColor = {1, 1, 1, 1},
                    stackAnchor = "BOTTOMRIGHT",
                },
                anchorBelowEssential = false,
                anchorGap = 0,
                customEntries = {
                    enabled = true,
                    entries = {
                        { id = 58984, type = "spell" },
                    },
                },
            },
            buff = {
                enabled = true,
                iconSize = 32,
                borderSize = 1,
                shape = "square",
                aspectRatioCrop = 1.0,
                growthDirection = "CENTERED_HORIZONTAL",
                zoom = 0,
                padding = 4,
                durationSize = 14,
                durationOffsetX = 0,
                durationOffsetY = 8,
                durationAnchor = "TOP",
                stackSize = 14,
                stackOffsetX = 0,
                stackOffsetY = -8,
                stackAnchor = "BOTTOM",
            },
            trackedBar = {
                enabled = true,
                hideIcon = false,
                barHeight = 25,
                barWidth = 215,
                texture = "Prey v5",
                useClassColor = true,
                barColor = {0.820, 0.180, 0.220, 1},
                borderSize = 2,
                bgOpacity = 0.5,
                textSize = 14,
                spacing = 2,
                growUp = true,
                orientation = "horizontal",
                fillDirection = "UP",
                iconPosition = "top",
                showTextOnVertical = false,
            },
            customBuffs = {
                enabled = true,
                spellIDs = { 1254638 },
            },
        },


        cdmVisibility = {
            showAlways = true,
            showWhenTargetExists = true,
            showInCombat = false,
            showInGroup = false,
            showInInstance = false,
            showOnMouseover = false,
            fadeDuration = 0.2,
            fadeOutAlpha = 0,
            hideWhenMounted = false,
        },


        unitframesVisibility = {
            showAlways = true,
            showWhenTargetExists = false,
            showInCombat = false,
            showInGroup = false,
            showInInstance = false,
            showOnMouseover = false,
            fadeDuration = 0.2,
            fadeOutAlpha = 0,
            alwaysShowCastbars = false,
            hideWhenMounted = false,
        },


        customTrackersVisibility = {
            showAlways = true,
            showWhenTargetExists = false,
            showInCombat = false,
            showInGroup = false,
            showInInstance = false,
            showOnMouseover = false,
            fadeDuration = 0.2,
            fadeOutAlpha = 0,
            hideWhenMounted = false,
        },

        viewers = {
            EssentialCooldownViewer = {
                enabled          = true,
                iconSize         = 50,
                aspectRatioCrop  = 1.0,
                spacing          = -11,
                zoom             = 0,
                borderSize       = 1,
                borderColor      = { 0, 0, 0, 1 },
                chargeTextAnchor = "BOTTOMRIGHT",
                countTextSize    = 14,
                countTextOffsetX = 0,
                countTextOffsetY = 0,
                durationTextSize = 14,
                rowLimit         = 8,

                row1Icons        = 6,
                row2Icons        = 6,
                row3Icons        = 6,
                useRowPattern    = false,
                rowAlignment     = "CENTER",

                showKeybinds      = false,
                keybindTextSize   = 12,
                keybindTextColor  = { 1, 0.82, 0, 1 },
                keybindAnchor     = "TOPLEFT",
                keybindOffsetX    = 2,
                keybindOffsetY    = 2,

                showRotationHelper = false,
                rotationHelperColor = { 0.820, 0.180, 0.220, 1 },
                rotationHelperThickness = 2,
            },
            UtilityCooldownViewer = {
                enabled          = true,
                iconSize         = 42,
                aspectRatioCrop  = 1.0,
                spacing          = -11,
                zoom             = 0.08,
                borderSize       = 1,
                borderColor      = { 0, 0, 0, 1 },
                chargeTextAnchor = "BOTTOMRIGHT",
                countTextSize    = 14,
                countTextOffsetX = 0,
                countTextOffsetY = 0,
                durationTextSize = 14,
                rowLimit         = 0,

                row1Icons        = 8,
                row2Icons        = 8,
                useRowPattern    = false,
                rowAlignment     = "CENTER",

                anchorToEssential = false,
                anchorGap         = 10,

                showKeybinds      = false,
                keybindTextSize   = 12,
                keybindTextColor  = { 1, 0.82, 0, 1 },
                keybindAnchor     = "TOPLEFT",
                keybindOffsetX    = 2,
                keybindOffsetY    = 2,

                showRotationHelper = false,
                rotationHelperColor = { 0.820, 0.180, 0.220, 1 },
                rotationHelperThickness = 2,
            },


        },


        rotationAssistIcon = {
            enabled = false,
            isLocked = true,
            iconSize = 56,
            visibility = "always",
            frameStrata = "MEDIUM",

            showBorder = true,
            borderThickness = 2,
            borderColor = { 0, 0, 0, 1 },

            cooldownSwipeEnabled = true,

            showKeybind = true,
            keybindFont = nil,
            keybindSize = 13,
            keybindColor = { 1, 1, 1, 1 },
            keybindOutline = true,
            keybindAnchor = "BOTTOMRIGHT",
            keybindOffsetX = -2,
            keybindOffsetY = 2,

            positionX = 0,
            positionY = -180,
        },

        powerBar = {
            enabled           = true,
            autoAttach        = false,
            standaloneMode    = false,
            attachTo          = "EssentialCooldownViewer",
            height            = 8,
            borderSize        = 1,
            offsetY           = -204,
            offsetX           = 0,
            width             = 326,
            useRawPixels      = true,
            texture           = "Prey v5",
            colorMode         = "power",
            usePowerColor     = true,
            useClassColor     = false,
            customColor       = { 0.82, 0.18, 0.22, 1 },
            showPercent       = true,
            showText          = true,
            textSize          = 16,
            textX             = 1,
            textY             = 3,
            textUseClassColor = false,
            textCustomColor   = { 1, 1, 1, 1 },
            bgColor           = { 0.078, 0.078, 0.078, 1 },
            showTicks         = false,
            tickThickness     = 2,
            tickColor         = { 0, 0, 0, 1 },
            lockedToEssential = false,
            lockedToUtility   = false,
            snapGap           = 5,
            orientation       = "HORIZONTAL",
        },
        castBar = {
            enabled       = true,
            attachTo      = "EssentialCooldownViewer",
            height        = 24,
            offsetX       = 0,
            offsetY       = -108.5,
            texture       = "Prey",
            color         = { 0.188, 1, 0.988, 1 },
            useClassColor = false,
            textSize      = 16,
            width         = 0,
            bgColor       = { 0.078, 0.078, 0.067, 0.85 },
            showTimeText  = true,
            showIcon      = true,
        },
        targetCastBar = {
            enabled       = true,
            attachTo      = "PREYCore_Target",
            height        = 18,
            offsetX       = 0,
            offsetY       = -32,
            texture       = "Prey",
            color         = { 1.0, 0.0, 0.0, 1.0 },
            textSize      = 16,
            width         = 241.2,
            bgColor       = { 0.1, 0.1, 0.1, 1 },
            showTimeText  = true,
            showIcon      = true,
        },
        focusCastBar = {
            enabled       = true,
            attachTo      = "PREYCore_Focus",
            height        = 18,
            offsetX       = 0,
            offsetY       = -32,
            texture       = "Prey",
            color         = { 1.0, 0.0, 0.0, 1.0 },
            textSize      = 16,
            width         = 241.2,
            bgColor       = { 0.1, 0.1, 0.1, 1 },
            showTimeText  = true,
            showIcon      = true,
        },
        secondaryPowerBar = {
            enabled       = true,
            autoAttach    = false,
            standaloneMode = false,
            attachTo      = "EssentialCooldownViewer",
            height        = 8,
            borderSize    = 1,
            offsetY       = 0,
            offsetX       = 0,
            width         = 326,
            useRawPixels  = true,
            texture       = "Prey v5",
            colorMode     = "power",
            usePowerColor = true,
            useClassColor = false,
            customColor   = { 1, 0.8, 0.2, 1 },
            showPercent   = false,
            showText      = false,
            textSize      = 14,
            textX         = 0,
            textY         = 2,
            textUseClassColor = false,
            textCustomColor   = { 1, 1, 1, 1 },
            bgColor       = { 0.078, 0.078, 0.078, 0.83 },
            showTicks     = true,
            tickThickness = 2,
            tickColor     = { 0, 0, 0, 1 },
            lockedToEssential = false,
            lockedToUtility   = false,
            lockedToPrimary   = true,
            snapGap       = 5,
            orientation   = "AUTO",
            showFragmentedPowerBarText = false,
        },

        powerColors = {

            rage = { 1.00, 0.00, 0.00, 1 },
            energy = { 1.00, 1.00, 0.00, 1 },
            mana = { 0.00, 0.00, 1.00, 1 },
            focus = { 1.00, 0.50, 0.25, 1 },
            runicPower = { 0.00, 0.82, 1.00, 1 },
            fury = { 0.79, 0.26, 0.99, 1 },
            insanity = { 0.40, 0.00, 0.80, 1 },
            maelstrom = { 0.00, 0.50, 1.00, 1 },
            lunarPower = { 0.30, 0.52, 0.90, 1 },


            holyPower = { 0.95, 0.90, 0.60, 1 },
            chi = { 0.00, 1.00, 0.59, 1 },
            comboPoints = { 1.00, 0.96, 0.41, 1 },
            soulShards = { 0.58, 0.51, 0.79, 1 },
            arcaneCharges = { 0.10, 0.10, 0.98, 1 },
            essence = { 0.20, 0.58, 0.50, 1 },


            stagger = { 0.00, 1.00, 0.59, 1 },
            staggerLight = { 0.52, 1.00, 0.52, 1 },
            staggerModerate = { 1.00, 0.98, 0.72, 1 },
            staggerHeavy = { 1.00, 0.42, 0.42, 1 },
            useStaggerLevelColors = true,
            soulFragments = { 0.64, 0.19, 0.79, 1 },
            runes = { 0.77, 0.12, 0.23, 1 },
            bloodRunes = { 0.77, 0.12, 0.23, 1 },
            frostRunes = { 0.00, 0.82, 1.00, 1 },
            unholyRunes = { 0.00, 0.80, 0.00, 1 },
        },

        reticle = {
            enabled = false,

            reticleStyle = "dot",
            reticleSize = 10,

            ringStyle = "standard",
            ringSize = 40,

            useClassColor = false,
            customColor = {1, 1, 1, 1},

            inCombatAlpha = 1.0,
            outCombatAlpha = 1.0,
            hideOutOfCombat = false,

            offsetX = 0,
            offsetY = 0,

            gcdEnabled = true,
            gcdFadeRing = 0.35,
            gcdReverse = false,

            hideOnRightClick = false,
        },

        crosshair = {
            enabled = false,
            onlyInCombat = false,
            size = 9,
            thickness = 3,
            borderSize = 3,
            offsetX = 0,
            offsetY = 0,
            r = 0.796,
            g = 1,
            b = 0.780,
            a = 1,
            borderR = 0,
            borderG = 0,
            borderB = 0,
            borderA = 1,
            strata = "LOW",
            lineColor = { 0.796, 1, 0.780, 1 },
            borderColorTable = { 0, 0, 0, 1 },

            changeColorOnRange = false,
            outOfRangeColor = { 1, 0.2, 0.2, 1 },
            rangeColorInCombatOnly = false,
            hideUntilOutOfRange = false,
        },


        skyriding = {
            enabled = true,
            width = 250,
            vigorHeight = 20,
            secondWindHeight = 20,
            offsetX = 0,
            offsetY = 135,
            locked = false,
            useClassColorVigor = false,
            barColor = { 0.860, 0.220, 0.260, 1 },
            backgroundColor = { 0.102, 0.102, 0.102, 0.353 },
            segmentColor = { 0, 0, 0, 1 },
            rechargeColor = { 0.4, 0.9, 1.0, 1 },
            borderSize = 1,
            borderColor = { 0, 0, 0, 1 },
            barTexture = "Prey v4",
            showSegments = true,
            segmentThickness = 1,
            showSpeed = true,
            speedFormat = "PERCENT",
            speedFontSize = 11,
            showVigorText = true,
            vigorTextFormat = "FRACTION",
            vigorFontSize = 11,
            secondWindMode = "MINIBAR",
            secondWindScale = 2.1,
            useClassColorSecondWind = false,
            secondWindColor = { 1.0, 0.8, 0.2, 1 },
            secondWindBackgroundColor = { 0.102, 0.102, 0.102, 0.301 },
            visibility = "FLYING_ONLY",
            fadeDelay = 1,
            fadeDuration = 0.3,
        },


        chat = {
            enabled = true,

            glass = {
                enabled = true,
                bgAlpha = 0.25,
                bgColor = {0, 0, 0},
            },

            fade = {
                enabled = false,
                delay = 15,
                duration = 0.6,
            },

            font = {
                forceOutline = false,
            },

            urls = {
                enabled = true,
                color = {0.078, 0.608, 0.992, 1},
            },

            hideButtons = true,

            editBox = {
                enabled = true,
                bgAlpha = 0.25,
                bgColor = {0, 0, 0},
                height = 20,
                positionTop = false,
            },

            timestamps = {
                enabled = false,
                format = "24h",
                color = {0.6, 0.6, 0.6},
            },

            copyButtonMode = "always",

            showIntroMessage = true,
        },


        tooltip = {
            enabled = true,
            anchorToCursor = true,
            hideInCombat = true,
            classColorName = false,

            visibility = {
                npcs = "SHOW",
                abilities = "SHOW",
                items = "SHOW",
                frames = "SHOW",
                cdm = "SHOW",
                customTrackers = "SHOW",
            },
            combatKey = "SHIFT",
            hideHealthBar = true,
        },


        actionBars = {
            enabled = true,

            global = {
                skinEnabled = true,
                iconSize = 36,
                iconZoom = 0.05,
                showBackdrop = true,
                backdropAlpha = 0.8,
                showGloss = true,
                glossAlpha = 0.6,
                showBorders = true,
                showKeybinds = true,
                showMacroNames = false,
                showCounts = true,
                hideEmptyKeybinds = false,
                keybindFontSize = 16,
                keybindColor = {1, 1, 1, 1},
                keybindAnchor = "TOPRIGHT",
                keybindOffsetX = 0,
                keybindOffsetY = -5,
                macroNameFontSize = 10,
                macroNameColor = {1, 1, 1, 1},
                macroNameAnchor = "BOTTOM",
                macroNameOffsetX = 0,
                macroNameOffsetY = 0,
                countFontSize = 14,
                countColor = {1, 1, 1, 1},
                countAnchor = "BOTTOMRIGHT",
                countOffsetX = 0,
                countOffsetY = 0,

                barScale = 1.0,
                hideEmptySlots = false,
                lockButtons = false,

                rangeIndicator = false,
                rangeColor = {0.8, 0.1, 0.1, 1},

                usabilityIndicator = false,
                usabilityDesaturate = false,
                usabilityColor = {0.4, 0.4, 0.4, 1},
                manaColor = {0.5, 0.5, 1.0, 1},
                fastUsabilityUpdates = false,
            },

            fade = {
                enabled = true,
                fadeInDuration = 0.2,
                fadeOutDuration = 0.3,
                fadeOutAlpha = 0.0,
                fadeOutDelay = 0.5,
                alwaysShowInCombat = false,
                linkBars1to8 = false,
            },


            bars = {
                bar1 = {
                    enabled = true, fadeEnabled = nil, fadeOutAlpha = nil, alwaysShow = false,
                    hidePageArrow = true,

                    overrideEnabled = false,
                    iconZoom = 0.05, showBackdrop = nil, backdropAlpha = 0,
                    showGloss = nil, glossAlpha = 0,
                    showKeybinds = nil, hideEmptyKeybinds = nil, keybindFontSize = 8,
                    keybindColor = nil, keybindAnchor = nil, keybindOffsetX = -20, keybindOffsetY = -20,
                    showMacroNames = nil, macroNameFontSize = 8, macroNameColor = nil,
                    macroNameAnchor = nil, macroNameOffsetX = -20, macroNameOffsetY = -20,
                    showCounts = nil, countFontSize = 8, countColor = nil,
                    countAnchor = nil, countOffsetX = -20, countOffsetY = -20,
                },
                bar2 = {
                    enabled = true, fadeEnabled = nil, fadeOutAlpha = nil, alwaysShow = false,
                    overrideEnabled = false,
                    iconZoom = 0.05, showBackdrop = nil, backdropAlpha = 0,
                    showGloss = nil, glossAlpha = 0,
                    showKeybinds = nil, hideEmptyKeybinds = nil, keybindFontSize = 8,
                    keybindColor = nil, keybindAnchor = nil, keybindOffsetX = -20, keybindOffsetY = -20,
                    showMacroNames = nil, macroNameFontSize = 8, macroNameColor = nil,
                    macroNameAnchor = nil, macroNameOffsetX = -20, macroNameOffsetY = -20,
                    showCounts = nil, countFontSize = 8, countColor = nil,
                    countAnchor = nil, countOffsetX = -20, countOffsetY = -20,
                },
                bar3 = {
                    enabled = true, fadeEnabled = nil, fadeOutAlpha = nil, alwaysShow = false,
                    overrideEnabled = false,
                    iconZoom = 0.05, showBackdrop = nil, backdropAlpha = 0,
                    showGloss = nil, glossAlpha = 0,
                    showKeybinds = nil, hideEmptyKeybinds = nil, keybindFontSize = 8,
                    keybindColor = nil, keybindAnchor = nil, keybindOffsetX = -20, keybindOffsetY = -20,
                    showMacroNames = nil, macroNameFontSize = 8, macroNameColor = nil,
                    macroNameAnchor = nil, macroNameOffsetX = -20, macroNameOffsetY = -20,
                    showCounts = nil, countFontSize = 8, countColor = nil,
                    countAnchor = nil, countOffsetX = -20, countOffsetY = -20,
                },
                bar4 = {
                    enabled = true, fadeEnabled = nil, fadeOutAlpha = nil, alwaysShow = false,
                    overrideEnabled = false,
                    iconZoom = 0.05, showBackdrop = nil, backdropAlpha = 0,
                    showGloss = nil, glossAlpha = 0,
                    showKeybinds = nil, hideEmptyKeybinds = nil, keybindFontSize = 8,
                    keybindColor = nil, keybindAnchor = nil, keybindOffsetX = -20, keybindOffsetY = -20,
                    showMacroNames = nil, macroNameFontSize = 8, macroNameColor = nil,
                    macroNameAnchor = nil, macroNameOffsetX = -20, macroNameOffsetY = -20,
                    showCounts = nil, countFontSize = 8, countColor = nil,
                    countAnchor = nil, countOffsetX = -20, countOffsetY = -20,
                },
                bar5 = {
                    enabled = true, fadeEnabled = nil, fadeOutAlpha = nil, alwaysShow = false,
                    overrideEnabled = false,
                    iconZoom = 0.05, showBackdrop = nil, backdropAlpha = 0,
                    showGloss = nil, glossAlpha = 0,
                    showKeybinds = nil, hideEmptyKeybinds = nil, keybindFontSize = 8,
                    keybindColor = nil, keybindAnchor = nil, keybindOffsetX = -20, keybindOffsetY = -20,
                    showMacroNames = nil, macroNameFontSize = 8, macroNameColor = nil,
                    macroNameAnchor = nil, macroNameOffsetX = -20, macroNameOffsetY = -20,
                    showCounts = nil, countFontSize = 8, countColor = nil,
                    countAnchor = nil, countOffsetX = -20, countOffsetY = -20,
                },
                bar6 = {
                    enabled = true, fadeEnabled = nil, fadeOutAlpha = nil, alwaysShow = false,
                    overrideEnabled = false,
                    iconZoom = 0.05, showBackdrop = nil, backdropAlpha = 0,
                    showGloss = nil, glossAlpha = 0,
                    showKeybinds = nil, hideEmptyKeybinds = nil, keybindFontSize = 8,
                    keybindColor = nil, keybindAnchor = nil, keybindOffsetX = -20, keybindOffsetY = -20,
                    showMacroNames = nil, macroNameFontSize = 8, macroNameColor = nil,
                    macroNameAnchor = nil, macroNameOffsetX = -20, macroNameOffsetY = -20,
                    showCounts = nil, countFontSize = 8, countColor = nil,
                    countAnchor = nil, countOffsetX = -20, countOffsetY = -20,
                },
                bar7 = {
                    enabled = true, fadeEnabled = nil, fadeOutAlpha = nil, alwaysShow = false,
                    overrideEnabled = false,
                    iconZoom = 0.05, showBackdrop = nil, backdropAlpha = 0,
                    showGloss = nil, glossAlpha = 0,
                    showKeybinds = nil, hideEmptyKeybinds = nil, keybindFontSize = 8,
                    keybindColor = nil, keybindAnchor = nil, keybindOffsetX = -20, keybindOffsetY = -20,
                    showMacroNames = nil, macroNameFontSize = 8, macroNameColor = nil,
                    macroNameAnchor = nil, macroNameOffsetX = -20, macroNameOffsetY = -20,
                    showCounts = nil, countFontSize = 8, countColor = nil,
                    countAnchor = nil, countOffsetX = -20, countOffsetY = -20,
                },
                bar8 = {
                    enabled = true, fadeEnabled = nil, fadeOutAlpha = nil, alwaysShow = false,
                    overrideEnabled = false,
                    iconZoom = 0.05, showBackdrop = nil, backdropAlpha = 0,
                    showGloss = nil, glossAlpha = 0,
                    showKeybinds = nil, hideEmptyKeybinds = nil, keybindFontSize = 8,
                    keybindColor = nil, keybindAnchor = nil, keybindOffsetX = -20, keybindOffsetY = -20,
                    showMacroNames = nil, macroNameFontSize = 8, macroNameColor = nil,
                    macroNameAnchor = nil, macroNameOffsetX = -20, macroNameOffsetY = -20,
                    showCounts = nil, countFontSize = 8, countColor = nil,
                    countAnchor = nil, countOffsetX = -20, countOffsetY = -20,
                },

                pet = { enabled = true, fadeEnabled = nil, fadeOutAlpha = nil, alwaysShow = false },
                stance = { enabled = true, fadeEnabled = nil, fadeOutAlpha = nil, alwaysShow = false },
                microbar = { enabled = true, fadeEnabled = nil, fadeOutAlpha = nil, alwaysShow = false },
                bags = { enabled = true, fadeEnabled = nil, fadeOutAlpha = nil, alwaysShow = false },

                extraActionButton = {
                    enabled = true,
                    fadeEnabled = nil,
                    fadeOutAlpha = nil,
                    alwaysShow = true,
                    scale = 1.0,
                    offsetX = 0,
                    offsetY = 0,
                    position = { point = "CENTER", relPoint = "CENTER", x = -120.833, y = -25.833 },
                    hideArtwork = false,
                },

                zoneAbility = {
                    enabled = true,
                    fadeEnabled = nil,
                    fadeOutAlpha = nil,
                    alwaysShow = true,
                    scale = 1.0,
                    offsetX = 0,
                    offsetY = 0,
                    position = { point = "CENTER", relPoint = "CENTER", x = 150, y = -27.5 },
                    hideArtwork = false,
                },
            },
        },


        quiUnitFrames = {
            enabled = true,

            general = {
                darkMode = false,
                darkModeHealthColor = { 0.15, 0.15, 0.15, 1 },
                darkModeBgColor = { 0.25, 0.25, 0.25, 1 },
                darkModeOpacity = 1.0,
                darkModeHealthOpacity = 1.0,
                darkModeBgOpacity = 1.0,

                defaultUseClassColor = true,
                defaultHealthColor = { 0.2, 0.2, 0.2, 1 },
                defaultBgColor = { 0, 0, 0, 1 },
                defaultOpacity = 1.0,
                defaultHealthOpacity = 1.0,
                defaultBgOpacity = 1.0,
                classColorText = false,

                masterColorNameText = false,
                masterColorHealthText = false,
                masterColorPowerText = false,
                masterColorCastbarText = false,
                masterColorToTText = false,
                font = "Prey",
                fontSize = 12,
                fontOutline = "OUTLINE",
                showTooltips = true,
                smootherAnimation = false,

                hostilityColorHostile = { 0.8, 0.2, 0.2, 1 },
                hostilityColorNeutral = { 1, 1, 0.2, 1 },
                hostilityColorFriendly = { 0.2, 0.8, 0.2, 1 },
            },

            player = {
                enabled = true,
                borderSize = 1,
                width = 240,
                height = 40,
                offsetX = -290,
                offsetY = -219,

                anchorTo = "disabled",
                anchorGap = 10,
                anchorYOffset = 0,
                texture = "Prey v5",
                useClassColor = true,
                customHealthColor = { 0.2, 0.6, 0.2, 1 },

                showPortrait = false,
                portraitSide = "LEFT",
                portraitSize = 40,
                portraitBorderSize = 1,
                portraitBorderUseClassColor = false,
                portraitBorderColor = { 0, 0, 0, 1 },
                portraitGap = 0,

                showName = true,
                nameTextUseClassColor = false,
                nameTextColor = { 1, 1, 1, 1 },
                nameFontSize = 16,
                nameAnchor = "LEFT",
                nameOffsetX = 12,
                nameOffsetY = 0,
                maxNameLength = 0,

                showHealth = true,
                showHealthPercent = true,
                showHealthAbsolute = true,
                healthDisplayStyle = "both",
                healthDivider = " | ",
                healthFontSize = 16,
                healthAnchor = "RIGHT",
                healthOffsetX = -12,
                healthOffsetY = 0,
                healthTextUseClassColor = false,
                healthTextColor = { 1, 1, 1, 1 },

                showPowerText = false,
                powerTextFormat = "percent",
                powerTextUsePowerColor = true,
                powerTextUseClassColor = false,
                powerTextColor = { 1, 1, 1, 1 },
                powerTextFontSize = 12,
                powerTextAnchor = "BOTTOMRIGHT",
                powerTextOffsetX = -9,
                powerTextOffsetY = 4,

                showPowerBar = false,
                powerBarHeight = 4,
                powerBarBorder = true,
                powerBarUsePowerColor = true,
                powerBarColor = { 0, 0.5, 1, 1 },

                absorbs = {
                    enabled = false,
                    color = { 1, 1, 1, 1 },
                    opacity = 0.3,
                    texture = "PREY Stripes",
                },

                castbar = {
                    enabled = true,
                    showIcon = true,
                    width = 333,
                    height = 25,
                    offsetX = 0,
                    offsetY = -35,
                    widthAdjustment = 0,
                    fontSize = 14,
                    color = {0.860, 0.220, 0.260, 1},
                    anchor = "none",
                    texture = "Prey v5",
                    bgColor = {0.149, 0.149, 0.149, 1},
                    borderSize = 1,
                    useClassColor = false,
                    highlightInterruptible = false,
                    interruptibleColor = {0.2, 0.8, 0.2, 1},
                    maxLength = 0,
                },

                auras = {
                    showBuffs = false,
                    showDebuffs = false,

                    iconSize = 22,
                    debuffAnchor = "TOPLEFT",
                    debuffGrow = "RIGHT",
                    debuffMaxIcons = 4,
                    debuffOffsetX = 0,
                    debuffOffsetY = 0,

                    buffIconSize = 22,
                    buffAnchor = "BOTTOMLEFT",
                    buffGrow = "RIGHT",
                    buffMaxIcons = 4,
                    buffOffsetX = 0,
                    buffOffsetY = 0,

                    iconSpacing = 2,
                    buffSpacing = 2,
                    debuffSpacing = 2,
                    durationColor = {1, 1, 1, 1},
                    showDuration = false,
                    durationSize = 12,
                    durationAnchor = "CENTER",
                    durationOffsetX = 0,
                    durationOffsetY = 0,

                    stackColor = {1, 1, 1, 1},
                    showStack = true,
                    stackSize = 10,
                    stackAnchor = "BOTTOMRIGHT",
                    stackOffsetX = -1,
                    stackOffsetY = 1,

                    buffDuration = { show = true, fontSize = 12, anchor = "CENTER", offsetX = 0, offsetY = 0, color = {1, 1, 1, 1} },
                    buffStack = { show = true, fontSize = 10, anchor = "BOTTOMRIGHT", offsetX = -1, offsetY = 1, color = {1, 1, 1, 1} },
                    buffShowStack = true,
                    buffStackSize = 10,
                    buffStackAnchor = "BOTTOMRIGHT",
                    buffStackOffsetX = -1,
                    buffStackOffsetY = 1,
                    buffStackColor = {1, 1, 1, 1},

                    debuffDuration = { show = false, fontSize = 10, anchor = "CENTER", offsetX = 0, offsetY = 0, color = {1, 1, 1, 1} },
                    debuffStack = { show = true, fontSize = 10, anchor = "BOTTOMRIGHT", offsetX = -1, offsetY = 1, color = {1, 1, 1, 1} },
                    debuffShowStack = true,
                    debuffStackSize = 10,
                    debuffStackAnchor = "BOTTOMRIGHT",
                    debuffStackOffsetX = -1,
                    debuffStackOffsetY = 1,
                    debuffStackColor = {1, 1, 1, 1},
                },

                indicators = {
                    rested = {
                        enabled = false,
                        size = 16,
                        anchor = "TOPLEFT",
                        offsetX = -2,
                        offsetY = 2,
                    },
                    combat = {
                        enabled = false,
                        size = 16,
                        anchor = "TOPRIGHT",
                        offsetX = -2,
                        offsetY = 2,
                    },
                    stance = {
                        enabled = false,
                        fontSize = 12,
                        anchor = "BOTTOM",
                        offsetX = 0,
                        offsetY = -2,
                        useClassColor = true,
                        customColor = { 1, 1, 1, 1 },
                        showIcon = false,
                        iconSize = 14,
                        iconOffsetX = -2,
                    },
                },

                targetMarker = {
                    enabled = false,
                    size = 20,
                    anchor = "TOP",
                    xOffset = 0,
                    yOffset = 8,
                },

                leaderIcon = {
                    enabled = false,
                    size = 16,
                    anchor = "TOPLEFT",
                    xOffset = -8,
                    yOffset = 8,
                },
            },

            target = {
                enabled = true,
                borderSize = 1,
                width = 240,
                height = 40,
                offsetX = 290,
                offsetY = -219,

                anchorTo = "disabled",
                anchorGap = 10,
                anchorYOffset = 0,
                texture = "Prey v5 Inverse",
                useClassColor = true,
                useHostilityColor = true,
                customHealthColor = { 0.2, 0.6, 0.2, 1 },

                showPortrait = false,
                portraitSide = "RIGHT",
                portraitSize = 40,
                portraitBorderSize = 1,
                portraitBorderUseClassColor = false,
                portraitBorderColor = { 0, 0, 0, 1 },
                portraitGap = 0,

                showName = true,
                nameTextUseClassColor = false,
                nameTextColor = { 1, 1, 1, 1 },
                nameFontSize = 16,
                nameAnchor = "RIGHT",
                nameOffsetX = -9,
                nameOffsetY = 0,
                maxNameLength = 10,

                showInlineToT = false,
                totSeparator = " >> ",
                totUseClassColor = true,
                totDividerUseClassColor = false,
                totDividerColor = {1, 1, 1, 1},
                totNameCharLimit = 0,

                showHealth = true,
                showHealthPercent = true,
                showHealthAbsolute = true,
                healthDisplayStyle = "both",
                healthDivider = " | ",
                healthFontSize = 16,
                healthAnchor = "LEFT",
                healthOffsetX = 9,
                healthOffsetY = 0,
                healthTextUseClassColor = false,
                healthTextColor = { 1, 1, 1, 1 },

                showPowerText = false,
                powerTextFormat = "percent",
                powerTextUsePowerColor = false,
                powerTextUseClassColor = false,
                powerTextColor = { 1, 1, 1, 1 },
                powerTextFontSize = 14,
                powerTextAnchor = "BOTTOMRIGHT",
                powerTextOffsetX = -2,
                powerTextOffsetY = 2,

                showPowerBar = false,
                powerBarHeight = 4,
                powerBarBorder = true,
                powerBarUsePowerColor = true,
                powerBarColor = { 0, 0.5, 1, 1 },

                absorbs = {
                    enabled = true,
                    color = { 1, 1, 1, 1 },
                    opacity = 0.3,
                    texture = "PREY Stripes",
                },

                castbar = {
                    enabled = true,
                    showIcon = true,
                    width = 245,
                    height = 25,
                    offsetX = 0,
                    offsetY = 0,
                    widthAdjustment = 0,
                    fontSize = 14,
                    color = {0.82, 0.18, 0.22, 1},
                    anchor = "unitframe",
                    texture = "Prey v5",
                    bgColor = {0.149, 0.149, 0.149, 1},
                    borderSize = 1,
                    highlightInterruptible = true,
                    interruptibleColor = {0.2, 0.8, 0.2, 1},
                    maxLength = 12,
                },

                auras = {
                    showBuffs = false,
                    showDebuffs = false,

                    iconSize = 26,
                    debuffAnchor = "TOPLEFT",
                    debuffGrow = "RIGHT",
                    debuffMaxIcons = 4,
                    debuffOffsetX = 0,
                    debuffOffsetY = 0,

                    buffIconSize = 18,
                    buffAnchor = "BOTTOMLEFT",
                    buffGrow = "RIGHT",
                    buffMaxIcons = 4,
                    buffOffsetX = 0,
                    buffOffsetY = 0,

                    iconSpacing = 2,
                    buffSpacing = 2,
                    debuffSpacing = 2,
                    durationColor = {1, 1, 1, 1},
                    showDuration = false,
                    durationSize = 12,
                    durationAnchor = "CENTER",
                    durationOffsetX = 0,
                    durationOffsetY = 0,

                    stackColor = {1, 1, 1, 1},
                    showStack = true,
                    stackSize = 10,
                    stackAnchor = "BOTTOMRIGHT",
                    stackOffsetX = -1,
                    stackOffsetY = 1,

                    buffDuration = { show = true, fontSize = 12, anchor = "CENTER", offsetX = 0, offsetY = 0, color = {1, 1, 1, 1} },
                    buffStack = { show = true, fontSize = 10, anchor = "BOTTOMRIGHT", offsetX = -1, offsetY = 1, color = {1, 1, 1, 1} },
                    buffShowStack = true,
                    buffStackSize = 10,
                    buffStackAnchor = "BOTTOMRIGHT",
                    buffStackOffsetX = -1,
                    buffStackOffsetY = 1,
                    buffStackColor = {1, 1, 1, 1},

                    debuffDuration = { show = false, fontSize = 10, anchor = "CENTER", offsetX = 0, offsetY = 0, color = {1, 1, 1, 1} },
                    debuffStack = { show = true, fontSize = 10, anchor = "BOTTOMRIGHT", offsetX = -1, offsetY = 1, color = {1, 1, 1, 1} },
                    debuffShowStack = true,
                    debuffStackSize = 10,
                    debuffStackAnchor = "BOTTOMRIGHT",
                    debuffStackOffsetX = -1,
                    debuffStackOffsetY = 1,
                    debuffStackColor = {1, 1, 1, 1},
                },

                targetMarker = {
                    enabled = false,
                    size = 20,
                    anchor = "TOP",
                    xOffset = 0,
                    yOffset = 8,
                },

                leaderIcon = {
                    enabled = false,
                    size = 16,
                    anchor = "TOPLEFT",
                    xOffset = -8,
                    yOffset = 8,
                },
            },

            targettarget = {
                enabled = false,
                borderSize = 1,
                width = 160,
                height = 30,
                offsetX = 496,
                offsetY = -214,
                texture = "Prey",
                useClassColor = true,
                useHostilityColor = true,
                customHealthColor = { 0.2, 0.6, 0.2, 1 },

                showName = true,
                nameTextUseClassColor = false,
                nameTextColor = { 1, 1, 1, 1 },
                nameFontSize = 14,
                nameAnchor = "LEFT",
                nameOffsetX = 4,
                nameOffsetY = 0,
                maxNameLength = 0,

                showHealth = true,
                showHealthPercent = true,
                showHealthAbsolute = false,
                healthDisplayStyle = "percent",
                healthDivider = " | ",
                healthFontSize = 14,
                healthAnchor = "RIGHT",
                healthOffsetX = -4,
                healthOffsetY = 0,
                healthTextUseClassColor = false,
                healthTextColor = { 1, 1, 1, 1 },

                showPowerText = false,
                powerTextFormat = "percent",
                powerTextUsePowerColor = true,
                powerTextUseClassColor = false,
                powerTextColor = { 1, 1, 1, 1 },
                powerTextFontSize = 10,
                powerTextAnchor = "BOTTOMRIGHT",
                powerTextOffsetX = -4,
                powerTextOffsetY = 2,

                showPowerBar = false,
                powerBarHeight = 3,
                powerBarBorder = true,
                powerBarUsePowerColor = true,
                powerBarColor = { 0, 0.5, 1, 1 },

                absorbs = {
                    enabled = true,
                    color = { 1, 1, 1, 1 },
                    opacity = 0.7,
                    texture = "PREY Stripes",
                },

                castbar = {
                    enabled = false,
                    showIcon = true,
                    width = 50,
                    height = 12,
                    offsetX = 0,
                    offsetY = -20,
                    widthAdjustment = 0,
                    fontSize = 10,
                    color = {1, 0.7, 0, 1},
                },

                auras = {
                    showBuffs = false,
                    showDebuffs = false,

                    iconSize = 22,
                    debuffAnchor = "TOPLEFT",
                    debuffGrow = "RIGHT",
                    debuffMaxIcons = 4,
                    debuffOffsetX = 0,
                    debuffOffsetY = 0,

                    buffIconSize = 22,
                    buffAnchor = "BOTTOMLEFT",
                    buffGrow = "RIGHT",
                    buffMaxIcons = 4,
                    buffOffsetX = 0,
                    buffOffsetY = 0,
                },

                targetMarker = {
                    enabled = false,
                    size = 16,
                    anchor = "TOP",
                    xOffset = 0,
                    yOffset = 6,
                },
            },

            pet = {
                enabled = true,
                borderSize = 1,
                width = 140,
                height = 25,
                offsetX = -340,
                offsetY = -254,
                texture = "Prey",
                useClassColor = true,
                useHostilityColor = true,
                customHealthColor = { 0.2, 0.6, 0.2, 1 },

                showName = true,
                nameTextUseClassColor = false,
                nameTextColor = { 1, 1, 1, 1 },
                nameFontSize = 10,
                nameAnchor = "LEFT",
                nameOffsetX = 4,
                nameOffsetY = 0,
                maxNameLength = 0,

                showHealth = true,
                showHealthPercent = true,
                showHealthAbsolute = false,
                healthDisplayStyle = "percent",
                healthDivider = " | ",
                healthFontSize = 10,
                healthAnchor = "RIGHT",
                healthOffsetX = -4,
                healthOffsetY = 0,
                healthTextUseClassColor = false,
                healthTextColor = { 1, 1, 1, 1 },

                showPowerText = false,
                powerTextFormat = "percent",
                powerTextUsePowerColor = true,
                powerTextUseClassColor = false,
                powerTextColor = { 1, 1, 1, 1 },
                powerTextFontSize = 10,
                powerTextAnchor = "BOTTOMRIGHT",
                powerTextOffsetX = -4,
                powerTextOffsetY = 2,

                showPowerBar = true,
                powerBarHeight = 3,
                powerBarBorder = true,
                powerBarUsePowerColor = true,
                powerBarColor = { 0, 0.5, 1, 1 },

                absorbs = {
                    enabled = true,
                    color = { 1, 1, 1 },
                    opacity = 0.7,
                    texture = "PREY Stripes",
                },

                auras = {
                    showBuffs = false,
                    showDebuffs = false,

                    iconSize = 22,
                    debuffAnchor = "TOPLEFT",
                    debuffGrow = "RIGHT",
                    debuffMaxIcons = 4,
                    debuffOffsetX = 0,
                    debuffOffsetY = 0,

                    buffIconSize = 22,
                    buffAnchor = "BOTTOMLEFT",
                    buffGrow = "RIGHT",
                    buffMaxIcons = 4,
                    buffOffsetX = 0,
                    buffOffsetY = 0,
                },

                targetMarker = {
                    enabled = false,
                    size = 16,
                    anchor = "TOP",
                    xOffset = 0,
                    yOffset = 6,
                },

                castbar = {
                    enabled = false,
                    showIcon = true,
                    width = 140,
                    height = 15,
                    offsetX = 0,
                    offsetY = -20,
                    widthAdjustment = 0,
                    fontSize = 10,
                    color = {0.860, 0.220, 0.260, 1},
                },
            },

            focus = {
                enabled = false,
                borderSize = 1,
                width = 160,
                height = 30,
                offsetX = -496,
                offsetY = -214,
                texture = "Prey v5",
                useClassColor = true,
                useHostilityColor = true,
                customHealthColor = { 0.2, 0.6, 0.2, 1 },

                showPortrait = false,
                portraitSide = "RIGHT",
                portraitSize = 30,
                portraitBorderSize = 1,
                portraitBorderUseClassColor = false,
                portraitBorderColor = { 0, 0, 0, 1 },
                portraitGap = 0,

                showName = true,
                nameTextUseClassColor = false,
                nameTextColor = { 1, 1, 1, 1 },
                nameFontSize = 14,
                nameAnchor = "LEFT",
                nameOffsetX = 4,
                nameOffsetY = 0,
                maxNameLength = 0,

                showHealth = true,
                showHealthPercent = true,
                showHealthAbsolute = true,
                healthDisplayStyle = "percent",
                healthDivider = " | ",
                healthFontSize = 14,
                healthAnchor = "RIGHT",
                healthOffsetX = -4,
                healthOffsetY = 0,
                healthTextUseClassColor = false,
                healthTextColor = { 1, 1, 1, 1 },

                showPowerText = false,
                powerTextFormat = "percent",
                powerTextUsePowerColor = true,
                powerTextUseClassColor = false,
                powerTextColor = { 1, 1, 1, 1 },
                powerTextFontSize = 10,
                powerTextAnchor = "BOTTOMRIGHT",
                powerTextOffsetX = -4,
                powerTextOffsetY = 2,

                showPowerBar = true,
                powerBarHeight = 3,
                powerBarBorder = true,
                powerBarUsePowerColor = true,
                powerBarColor = { 0, 0.5, 1, 1 },

                absorbs = {
                    enabled = true,
                    color = { 1, 1, 1, 1 },
                    opacity = 0.7,
                    texture = "PREY Stripes",
                },

                castbar = {
                    enabled = true,
                    showIcon = false,
                    width = 160,
                    height = 20,
                    offsetX = 0,
                    offsetY = 0,
                    widthAdjustment = 0,
                    fontSize = 14,
                    color = {0.82, 0.18, 0.22, 1},
                    anchor = "unitframe",
                },

                auras = {
                    showBuffs = false,
                    showDebuffs = false,

                    iconSize = 20,
                    debuffAnchor = "TOPLEFT",
                    debuffGrow = "RIGHT",
                    debuffMaxIcons = 16,
                    debuffOffsetX = 0,
                    debuffOffsetY = 2,

                    buffIconSize = 20,
                    buffAnchor = "BOTTOMLEFT",
                    buffGrow = "RIGHT",
                    buffMaxIcons = 16,
                    buffOffsetX = 0,
                    buffOffsetY = -2,
                },

                targetMarker = {
                    enabled = false,
                    size = 18,
                    anchor = "TOP",
                    xOffset = 0,
                    yOffset = 6,
                },

                leaderIcon = {
                    enabled = false,
                    size = 16,
                    anchor = "TOPLEFT",
                    xOffset = -8,
                    yOffset = 8,
                },
            },

            boss = {
                enabled = true,
                borderSize = 1,
                width = 162,
                height = 36,
                offsetX = 974,
                offsetY = 106,
                spacing = 35,
                texture = "Prey v5",
                useClassColor = true,
                useHostilityColor = true,
                customHealthColor = { 0.6, 0.2, 0.2, 1 },

                showName = true,
                nameTextUseClassColor = false,
                nameTextColor = { 1, 1, 1, 1 },
                nameFontSize = 11,
                nameAnchor = "LEFT",
                nameOffsetX = 4,
                nameOffsetY = 0,
                maxNameLength = 0,

                showHealth = true,
                healthDisplayStyle = "both",
                healthDivider = " | ",
                healthFontSize = 11,
                healthAnchor = "RIGHT",
                healthOffsetX = -4,
                healthOffsetY = 0,
                healthTextUseClassColor = false,
                healthTextColor = { 1, 1, 1, 1 },

                showPowerText = false,
                powerTextFormat = "percent",
                powerTextUsePowerColor = true,
                powerTextUseClassColor = false,
                powerTextColor = { 1, 1, 1, 1 },
                powerTextFontSize = 10,
                powerTextAnchor = "BOTTOMRIGHT",
                powerTextOffsetX = -4,
                powerTextOffsetY = 2,

                showPowerBar = true,
                powerBarHeight = 3,
                powerBarBorder = true,
                powerBarUsePowerColor = true,
                powerBarColor = { 0, 0.5, 1, 1 },

                absorbs = {
                    enabled = true,
                    color = { 1, 1, 1 },
                    opacity = 0.7,
                    texture = "PREY Stripes",
                },

                castbar = {
                    enabled = true,
                    showIcon = true,
                    width = 162,
                    height = 16,
                    offsetX = 0,
                    offsetY = 0,
                    widthAdjustment = 0,
                    fontSize = 11,
                    color = {1, 0.7, 0, 1},
                    anchor = "unitframe",
                },

                auras = {
                    showBuffs = false,
                    showDebuffs = false,

                    iconSize = 22,
                    debuffAnchor = "TOPLEFT",
                    debuffGrow = "RIGHT",
                    debuffMaxIcons = 4,
                    debuffOffsetX = 0,
                    debuffOffsetY = 0,

                    buffIconSize = 22,
                    buffAnchor = "BOTTOMLEFT",
                    buffGrow = "RIGHT",
                    buffMaxIcons = 4,
                    buffOffsetX = 0,
                    buffOffsetY = 0,
                },

                targetMarker = {
                    enabled = false,
                    size = 20,
                    anchor = "TOP",
                    xOffset = 0,
                    yOffset = 8,
                },
            },
        },
        unitFrames = {
            enabled = true,
            General = {
                Font = "Prey",
                FontFlag = "OUTLINE",
                FontShadows = {
                    Color = {0, 0, 0, 0},
                    OffsetX = 0,
                    OffsetY = 0
                },
                ForegroundTexture = "Prey_v5",
                BackgroundTexture = "Solid",

                DarkMode = {
                    Enabled = false,
                    ForegroundColor = {0.15, 0.15, 0.15, 1},
                    BackgroundColor = {0.25, 0.25, 0.25, 1},
                    UseSolidTexture = true,
                },
                CustomColors = {
                    Reaction = {
                        [1] = {204/255, 64/255, 64/255},
                        [2] = {204/255, 64/255, 64/255},
                        [3] = {204/255, 128/255, 64/255},
                        [4] = {255/255, 234/255, 126/255},
                        [5] = {64/255, 204/255, 64/255},
                        [6] = {64/255, 204/255, 64/255},
                        [7] = {64/255, 204/255, 64/255},
                        [8] = {64/255, 204/255, 64/255},
                    },
                    Power = {
                        [0] = {0, 0.50, 1},
                        [1] = {1, 0, 0},
                        [2] = {1, 0.5, 0.25},
                        [3] = {1, 1, 0},
                        [6] = {0, 0.82, 1},
                        [8] = {0.3, 0.52, 0.9},
                        [11] = {0, 0.5, 1},
                        [13] = {0.4, 0, 0.8},
                        [17] = {0.79, 0.26, 0.99},
                        [18] = {1, 0.61, 0}
                    },
                },
            },
            player = {
                Enabled = true,
                Frame = {
                    Width = 244,
                    Height = 42,
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    Texture = "Prey",
                    ClassColor = true,
                    ReactionColor = false,
                    FGColor = {26/255, 26/255, 26/255, 1.0},
                    BGColor = {45/255, 45/255, 45/255, 1.0},
                },
                PowerBar = {
                    Enabled = true,
                    Height = 2,
                    ColorByType = true,
                    ColorBackgroundByType = false,
                    FGColor = {8/255, 8/255, 8/255, 0.8},
                    BGColor = {45/255, 45/255, 45/255, 1.0},
                },
                Tags = {
                    Name = {
                        Enabled = true,
                        AnchorFrom = "LEFT",
                        AnchorTo = "LEFT",
                        OffsetX = 3,
                        OffsetY = 0,
                        FontSize = 14,
                        Color = {1, 1, 1, 1},
                        ColorByStatus = false,
                    },
                    Health = {
                        Enabled = true,
                        AnchorFrom = "RIGHT",
                        AnchorTo = "RIGHT",
                        OffsetX = -3,
                        OffsetY = 0,
                        FontSize = 14,
                        Color = {1, 1, 1, 1},
                        DisplayPercent = true,
                    },
                    Power = {
                        Enabled = false,
                        AnchorFrom = "BOTTOMRIGHT",
                        AnchorTo = "BOTTOMRIGHT",
                        OffsetX = -4,
                        OffsetY = 4,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                    },
                },
                Absorb = {
                    Enabled = true,
                    Color = {0, 1, 0.96, 0.2},
                },
            },
            target = {
                Enabled = true,
                Frame = {
                    Width = 244,
                    Height = 42,
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    Texture = "Prey",
                    ClassColor = true,
                    ReactionColor = true,
                    FGColor = {26/255, 26/255, 26/255, 1.0},
                    BGColor = {45/255, 45/255, 45/255, 1.0},
                },
                PowerBar = {
                    Enabled = true,
                    Height = 2,
                    ColorByType = true,
                    ColorBackgroundByType = false,
                    FGColor = {8/255, 8/255, 8/255, 0.8},
                    BGColor = {45/255, 45/255, 45/255, 1.0},
                },
                Tags = {
                    Name = {
                        Enabled = true,
                        AnchorFrom = "LEFT",
                        AnchorTo = "LEFT",
                        OffsetX = 3,
                        OffsetY = 0,
                        FontSize = 14,
                        Color = {1, 1, 1, 1},
                        ColorByStatus = false,
                    },
                    Health = {
                        Enabled = true,
                        AnchorFrom = "RIGHT",
                        AnchorTo = "RIGHT",
                        OffsetX = -3,
                        OffsetY = 0,
                        FontSize = 14,
                        Color = {1, 1, 1, 1},
                        DisplayPercent = true,
                    },
                    Power = {
                        Enabled = false,
                        AnchorFrom = "BOTTOMRIGHT",
                        AnchorTo = "BOTTOMRIGHT",
                        OffsetX = -4,
                        OffsetY = 4,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                    },
                },
                Auras = {
                    Width = 0,
                    Height = 18,
                    Scale = 2.5,
                    Alpha = 1,
                    RowLimit = 0,

                    BorderSize = 1,
                    BorderColor = {0, 0, 0, 1},

                    ShowDebuffs = true,
                    DebuffOffsetX = 0,
                    DebuffOffsetY = 2,

                    ShowBuffs = true,
                    BuffOffsetX = 0,
                    BuffOffsetY = 40,
                },
                Absorb = {
                    Enabled = true,
                    Color = {0, 1, 0.96, 0.2},
                },
            },
            targettarget = {
                Enabled = true,
                Frame = {
                    Width = 122,
                    Height = 21,
                    XPosition = 183.1,
                    YPosition = -10,
                    AnchorFrom = "CENTER",
                    AnchorParent = "PREYCore_Target",
                    AnchorTo = "CENTER",
                    Texture = "Prey",
                    ClassColor = true,
                    ReactionColor = true,
                    FGColor = {26/255, 26/255, 26/255, 1.0},
                    BGColor = {45/255, 45/255, 45/255, 1.0},
                },
                Tags = {
                    Name = {
                        Enabled = true,
                        AnchorFrom = "CENTER",
                        AnchorTo = "CENTER",
                        OffsetX = 0,
                        OffsetY = 0,
                        FontSize = 14,
                        Color = {1, 1, 1, 1},
                        ColorByStatus = false,
                    },
                    Health = {
                        Enabled = false,
                        AnchorFrom = "RIGHT",
                        AnchorTo = "RIGHT",
                        OffsetX = -3,
                        OffsetY = 0,
                        FontSize = 14,
                        Color = {1, 1, 1, 1},
                        DisplayPercent = true,
                    },
                },
            },
            pet = {
                Enabled = true,
                Frame = {
                    Width = 244,
                    Height = 21,
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    Texture = "Prey",
                    ClassColor = true,
                    ReactionColor = false,
                    FGColor = {26/255, 26/255, 26/255, 1.0},
                    BGColor = {45/255, 45/255, 45/255, 1.0},
                },
                Tags = {
                    Name = {
                        Enabled = true,
                        AnchorFrom = "CENTER",
                        AnchorTo = "CENTER",
                        OffsetX = 0,
                        OffsetY = 0,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                        ColorByStatus = false,
                    },
                    Health = {
                        Enabled = false,
                        AnchorFrom = "RIGHT",
                        AnchorTo = "RIGHT",
                        OffsetX = -3,
                        OffsetY = 0,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                        DisplayPercent = true,
                    },
                    Power = {
                        Enabled = false,
                        AnchorFrom = "BOTTOMRIGHT",
                        AnchorTo = "BOTTOMRIGHT",
                        OffsetX = -4,
                        OffsetY = 4,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                    },
                },
            },
            focus = {
                Enabled = true,
                Frame = {
                    Width = 122,
                    Height = 21,
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    Texture = "Prey",
                    ClassColor = true,
                    ReactionColor = true,
                    FGColor = {26/255, 26/255, 26/255, 1.0},
                    BGColor = {45/255, 45/255, 45/255, 1.0},
                },
                PowerBar = {
                    Enabled = true,
                    Height = 2,
                    ColorByType = true,
                    ColorBackgroundByType = true,
                    FGColor = {8/255, 8/255, 8/255, 0.8},
                    BGColor = {45/255, 45/255, 45/255, 1.0},
                },
                Tags = {
                    Name = {
                        Enabled = true,
                        AnchorFrom = "CENTER",
                        AnchorTo = "CENTER",
                        OffsetX = 0,
                        OffsetY = 0,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                        ColorByStatus = false,
                    },
                    Health = {
                        Enabled = false,
                        AnchorFrom = "RIGHT",
                        AnchorTo = "RIGHT",
                        OffsetX = -3,
                        OffsetY = 0,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                        DisplayPercent = true,
                    },
                    Power = {
                        Enabled = false,
                        AnchorFrom = "BOTTOMRIGHT",
                        AnchorTo = "BOTTOMRIGHT",
                        OffsetX = -4,
                        OffsetY = 4,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                    },
                },
            },
            focus = {
                Enabled = true,
                Frame = {
                    Width = 122,
                    Height = 21,
                    AnchorFrom = "CENTER",
                    AnchorTo = "CENTER",
                    ClassColor = true,
                    ReactionColor = true,
                    FGColor = {26/255, 26/255, 26/255, 1.0},
                    BGColor = {45/255, 45/255, 45/255, 1.0},
                },
                PowerBar = {
                    Enabled = true,
                    Height = 2,
                    ColorByType = true,
                    ColorBackgroundByType = true,
                    FGColor = {8/255, 8/255, 8/255, 0.8},
                    BGColor = {45/255, 45/255, 45/255, 1.0},
                },
                Tags = {
                    Name = {
                        Enabled = true,
                        AnchorFrom = "CENTER",
                        AnchorTo = "CENTER",
                        OffsetX = 0,
                        OffsetY = 0,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                        ColorByStatus = false,
                    },
                    Health = {
                        Enabled = false,
                        AnchorFrom = "RIGHT",
                        AnchorTo = "RIGHT",
                        OffsetX = -3,
                        OffsetY = 0,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                        DisplayPercent = true,
                    },
                    Power = {
                        Enabled = false,
                        AnchorFrom = "BOTTOMRIGHT",
                        AnchorTo = "BOTTOMRIGHT",
                        OffsetX = -4,
                        OffsetY = 4,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                    },
                },
            },
            boss = {
                Enabled = true,
                Frame = {
                    Width = 200,
                    Height = 36,
                    XPosition = 350,
                    YPosition = 0,
                    AnchorFrom = "LEFT",
                    AnchorParent = "PREYCore_Target",
                    AnchorTo = "RIGHT",
                    Texture = "Prey",
                    ClassColor = true,
                    ReactionColor = true,
                    FGColor = {26/255, 26/255, 26/255, 1.0},
                    BGColor = {45/255, 45/255, 45/255, 1.0},
                },
                Tags = {
                    Name = {
                        Enabled = true,
                        AnchorFrom = "LEFT",
                        AnchorTo = "LEFT",
                        OffsetX = 4,
                        OffsetY = 0,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                        ColorByClass = false,
                        ColorByStatus = true,
                    },
                    Health = {
                        Enabled = true,
                        AnchorFrom = "RIGHT",
                        AnchorTo = "RIGHT",
                        OffsetX = -4,
                        OffsetY = 0,
                        FontSize = 12,
                        Color = {1, 1, 1, 1},
                    },
                },
            },
        },

        configPanelScale = 1.0,
        configPanelWidth = 750,
        configPanelAlpha = 0.97,


        combatText = {
            enabled = true,
            displayTime = 0.8,
            fadeTime = 0.3,
            fontSize = 14,
            xOffset = 0,
            yOffset = 0,
            enterCombatColor = {1, 0.98, 0.2, 1},
            leaveCombatColor = {1, 0.98, 0.2, 1},
        },


        combatTimer = {
            enabled = false,
            xOffset = 0,
            yOffset = -150,
            width = 80,
            height = 30,
            fontSize = 16,
            useCustomFont = false,
            font = "Prey",
            useClassColorText = false,
            textColor = {1, 1, 1, 1},

            showBackdrop = true,
            backdropColor = {0, 0, 0, 0.6},

            borderSize = 1,
            borderTexture = "None",
            useClassColorBorder = false,
            borderColor = {0, 0, 0, 1},
            hideBorder = false,
            onlyShowInEncounters = false,
        },


        cooldownSwipe = {
            showBuffSwipe = false,
            showBuffIconSwipe = false,
            showGCDSwipe = false,
            showCooldownSwipe = false,
            showRechargeEdge = false,
            showActionSwipe = true,
            showNcdmSwipe = true,
            showCustomTrackerSwipe = true,
            migratedToV2 = true,
        },
        cooldownEffects = {
            hideEssential = true,
            hideUtility = true,
        },
        cooldownManager = {

        },


        customGlow = {

            essentialEnabled = true,
            essentialGlowType = "Pixel Glow",
            essentialColor = {0.95, 0.95, 0.32, 1},
            essentialLines = 14,
            essentialFrequency = 0.25,
            essentialLength = nil,
            essentialThickness = 2,
            essentialScale = 1,
            essentialXOffset = 0,
            essentialYOffset = 0,


            utilityEnabled = true,
            utilityGlowType = "Pixel Glow",
            utilityColor = {0.95, 0.95, 0.32, 1},
            utilityLines = 14,
            utilityFrequency = 0.25,
            utilityLength = nil,
            utilityThickness = 2,
            utilityScale = 1,
            utilityXOffset = 0,
            utilityYOffset = 0,
        },


        buffBorders = {
            enableBuffs = true,
            enableDebuffs = true,
            borderSize = 2,
            fontSize = 12,
            fontOutline = true,
        },


        uiHider = {
            hideObjectiveTrackerAlways = false,
            hideObjectiveTrackerInstanceTypes = {
                mythicPlus = false,
                mythicDungeon = false,
                normalDungeon = false,
                heroicDungeon = false,
                followerDungeon = false,
                raid = false,
                pvp = false,
                arena = false,
            },
            hideMinimapBorder = true,
            hideTimeManager = true,
            hideGameTime = true,
            hideMinimapTracking = true,
            hideRaidFrameManager = true,
            hideMinimapZoneText = true,
            hideBuffCollapseButton = true,
            hideFriendlyPlayerNameplates = true,
            hideFriendlyNPCNameplates = true,
            hideTalkingHead = true,
            muteTalkingHead = false,
            hideErrorMessages = false,
            hideMinimapZoomButtons = true,
            hideWorldMapBlackout = true,
            hideTalkingHeadFrame = true,
            hideXPAtMaxLevel = false,
            hideExperienceBar = false,
            hideReputationBar = false,
            hideMainActionBarArt = false,
        },


        minimap = {
            enabled = true,


            shape = "SQUARE",
            size = 160,
            scale = 1.0,
            borderSize = 2,
            borderColor = {0, 0, 0, 1},
            useClassColorBorder = false,
            buttonRadius = 2,


            lock = false,
            position = { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = 790, y = 285 },


            autoZoom = false,
            hideAddonButtons = true,


            showZoomButtons = false,
            showMail = false,
            showCraftingOrder = false,
            showAddonCompartment = false,
            showDifficulty = false,
            showMissions = false,
            showCalendar = true,
            showTracking = false,


            dungeonEye = {
                enabled = true,
                corner = "BOTTOMLEFT",
                scale = 0.6,
                offsetX = 0,
                offsetY = 0,
            },


            showClock = false,
            clockConfig = {
                offsetX = 0,
                offsetY = 0,
                align = "LEFT",
                font = "Prey",
                fontSize = 12,
                monochrome = false,
                outline = "OUTLINE",
                color = {1, 1, 1, 1},
                useClassColor = false,
                timeFormat = "local",
            },


            showCoords = false,
            coordPrecision = "%d,%d",
            coordUpdateInterval = 1,
            coordsConfig = {
                offsetX = 0,
                offsetY = 0,
                align = "RIGHT",
                font = "Prey",
                fontSize = 12,
                monochrome = false,
                outline = "OUTLINE",
                color = {1, 1, 1, 1},
                useClassColor = false,
            },


            showZoneText = true,
            zoneTextConfig = {
                offsetX = 0,
                offsetY = 0,
                align = "CENTER",
                font = "Prey",
                fontSize = 12,
                allCaps = false,
                monochrome = false,
                outline = "OUTLINE",
                useClassColor = false,
                colorNormal = {1, 0.82, 0, 1},
                colorSanctuary = {0.41, 0.8, 0.94, 1},
                colorArena = {1.0, 0.1, 0.1, 1},
                colorFriendly = {0.1, 1.0, 0.1, 1},
                colorHostile = {1.0, 0.1, 0.1, 1},
                colorContested = {1.0, 0.7, 0.0, 1},
            },
        },


        minimapButton = {
            hide = false,
            minimapPos = 180,
        },


        datatext = {
            enabled = true,
            slots = {"fps", "durability", "time"},


            slot1 = { shortLabel = false, noLabel = false, xOffset = -1, yOffset = 0 },
            slot2 = { shortLabel = false, noLabel = false, xOffset = 6, yOffset = 0 },
            slot3 = { shortLabel = true, noLabel = false, xOffset = 3, yOffset = 0 },

            forceSingleLine = true,


            height = 22,
            offsetY = 0,
            bgOpacity = 60,
            borderSize = 2,
            borderColor = {0, 0, 0, 1},


            font = "Prey",
            fontSize = 13,
            fontOutline = "OUTLINE",


            useClassColor = false,
            valueColor = {0.1, 1.0, 0.1, 1},


            separator = "  ",


            showFPS = true,
            showLatency = false,
            showDurability = true,
            showGold = false,
            showTime = true,
            showCoords = false,
            showFriends = false,
            showGuild = false,
            showLootSpec = false,


            timeFormat = "local",
            use24Hour = true,
            useLocalTime = true,
            lockoutCacheMinutes = 5,


            showTotal = true,
            showGuildName = false,


            specDisplayMode = "full",


            system = {
                latencyType = "home",
                showLatency = true,
                showProtocols = true,
                showBandwidth = true,
                showAddonMemory = true,
                addonCount = 10,
                showFpsStats = true,
            },


            volume = {
                volumeStep = 5,
                controlType = "master",
                showIcon = false,
            },
        },


        quiDatatexts = {
            panels = {},
        },


        customTrackers = {
            bars = {
                {
                    id = "default_tracker_1",
                    name = "Trinket & Pot",
                    enabled = false,
                    locked = false,

                    offsetX = -406,
                    offsetY = -152,

                    growDirection = "RIGHT",
                    iconSize = 28,
                    spacing = 4,
                    borderSize = 2,
                    aspectRatioCrop = 1.0,
                    zoom = 0,

                    durationSize = 13,
                    durationColor = {1, 1, 1, 1},
                    durationAnchor = "CENTER",
                    durationOffsetX = 0,
                    durationOffsetY = 0,
                    hideDurationText = false,

                    stackSize = 9,
                    stackColor = {1, 1, 1, 1},
                    stackAnchor = "BOTTOMRIGHT",
                    stackOffsetX = 3,
                    stackOffsetY = -1,
                    hideStackText = false,
                    showItemCharges = true,

                    bgOpacity = 0,
                    bgColor = {0, 0, 0, 1},
                    hideGCD = true,
                    hideNonUsable = false,
                    showOnlyOnCooldown = false,
                    showOnlyWhenActive = false,
                    showOnlyWhenOffCooldown = false,
                    showOnlyInCombat = false,

                    showActiveState = true,
                    activeGlowEnabled = true,
                    activeGlowType = "Pixel Glow",
                    activeGlowColor = {1, 0.85, 0.3, 1},

                    entries = {
                        { type = "item", id = 224022 },
                    },
                },
            },

            keybinds = {
                showKeybinds = false,
                keybindTextSize = 12,
                keybindTextColor = { 1, 0.82, 0, 1 },
                keybindOffsetX = 2,
                keybindOffsetY = -2,
            },

            cdmBuffTracking = {
                trinketData = {},
                learnedBuffs = {},
            },
        },


        hudLayering = {

            essential = 5,
            utility = 5,
            buffIcon = 5,
            buffBar = 5,

            primaryPowerBar = 7,
            secondaryPowerBar = 6,

            playerFrame = 4,
            playerIndicators = 6,
            targetFrame = 4,
            totFrame = 3,
            petFrame = 3,
            focusFrame = 4,
            bossFrames = 4,

            playerCastbar = 5,
            targetCastbar = 5,

            customBars = 5,
        },
    },

    global = {

        goldData = {},

        spellScanner = {
            spells = {},
            items = {},
            autoScan = false,
        },
    },
}

function PREYCore:OnInitialize()
    if rawget(_G, "PreyUIDB") == nil and rawget(_G, "KoriUIDB") ~= nil then
        _G.PreyUIDB = _G.KoriUIDB
    end

    self.db = LibStub("AceDB-3.0"):New("PreyUIDB", defaults, true)
    PREY.db = self.db


    local profile = self.db.profile


    local function migrateToShowLogic(visTable)
        if not visTable then return end

        if visTable.hideOutOfCombat then
            visTable.showInCombat = true
        end

        if visTable.hideWhenNotInGroup then
            visTable.showInGroup = true
        end

        if visTable.hideWhenNotInInstance then
            visTable.showInInstance = true
        end

        visTable.hideOutOfCombat = nil
        visTable.hideWhenNotInGroup = nil
        visTable.hideWhenNotInInstance = nil
    end


    if profile.classHud then
        if not profile.cdmVisibility then
            profile.cdmVisibility = {}
        end
        if not profile.unitframesVisibility then
            profile.unitframesVisibility = {}
        end

        if profile.classHud.hideOutOfCombat then
            profile.cdmVisibility.showInCombat = true
            profile.unitframesVisibility.showInCombat = true
        end

        profile.cdmVisibility.fadeDuration = profile.cdmVisibility.fadeDuration or profile.classHud.fadeDuration or 0.2
        profile.unitframesVisibility.fadeDuration = profile.unitframesVisibility.fadeDuration or profile.classHud.fadeDuration or 0.2
        profile.classHud = nil
    end


    migrateToShowLogic(profile.cdmVisibility)
    migrateToShowLogic(profile.unitframesVisibility)


    self._preservedUIScale = nil


    self._lastKnownSpec = GetSpecialization() or 0


    self._lastKnownProfile = self.db:GetCurrentProfile()

    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied",  "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset",   "OnProfileChanged")


    if LibDualSpec then
        LibDualSpec:EnhanceDatabase(self.db, ADDON_NAME)
    end


    self:RegisterChatCommand("preycorerefresh", "ForceRefreshBuffIcons")
    self:RegisterChatCommand("quicorerefresh", "ForceRefreshBuffIcons")


    C_Timer.After(0.1, function()
        self:CreateMinimapButton()
    end)
end

function PREYCore:OnProfileChanged(event, db, profileKey)


    local inChallengeMode = false
    if C_ChallengeMode then


        inChallengeMode = (C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive())
            or (C_ChallengeMode.GetActiveChallengeMapID and C_ChallengeMode.GetActiveChallengeMapID() ~= nil)
    end
    if inChallengeMode then


        return
    end


    local currentProfile = self.db:GetCurrentProfile()
    if profileKey == self._lastKnownProfile and profileKey == currentProfile then
        return
    end
    self._lastKnownProfile = profileKey


    self._lastKnownSpec = GetSpecialization() or 0


    local function ApplyUIScale(scale)
        if InCombatLockdown() then
            PREYCore._pendingUIScale = scale
            if not PREYCore._scaleRegenFrame then
                PREYCore._scaleRegenFrame = CreateFrame("Frame")
                PREYCore._scaleRegenFrame:SetScript("OnEvent", function(self)
                    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                    if PREYCore._pendingUIScale and not InCombatLockdown() then
                        pcall(function() UIParent:SetScale(PREYCore._pendingUIScale) end)
                        PREYCore._pendingUIScale = nil
                        if PREYCore.UIMult then
                            PREYCore:UIMult()
                        end
                    end
                end)
            end
            PREYCore._scaleRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        else


            local success = pcall(function() UIParent:SetScale(scale) end)
            if not success then

                PREYCore._pendingUIScale = scale
                if not PREYCore._scaleRegenFrame then
                    PREYCore._scaleRegenFrame = CreateFrame("Frame")
                    PREYCore._scaleRegenFrame:SetScript("OnEvent", function(self)
                        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                        if PREYCore._pendingUIScale and not InCombatLockdown() then
                            pcall(function() UIParent:SetScale(PREYCore._pendingUIScale) end)
                            PREYCore._pendingUIScale = nil
                            if PREYCore.UIMult then
                                PREYCore:UIMult()
                            end
                        end
                    end)
                end
                PREYCore._scaleRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            end
        end
    end


    if self.db.profile.general then
        local newProfileScale = self.db.profile.general.uiScale

        if not newProfileScale or newProfileScale == 0 then

            local scaleToUse = self._preservedUIScale


            if not scaleToUse then
                if self.GetSmartDefaultScale then
                    scaleToUse = self:GetSmartDefaultScale()
                else

                    local _, screenHeight = GetPhysicalScreenSize()
                    if screenHeight >= 2160 then
                        scaleToUse = 0.53
                    elseif screenHeight >= 1440 then
                        scaleToUse = 0.64
                    else
                        scaleToUse = 1.0
                    end
                end
            end

            self.db.profile.general.uiScale = scaleToUse
            ApplyUIScale(scaleToUse)
        else

            ApplyUIScale(newProfileScale)

            self._preservedUIScale = newProfileScale
        end


        if not InCombatLockdown() and self.UIMult then
            self:UIMult()
        end
    end


    if self._preservedPanelScale then
        self.db.profile.configPanelScale = self._preservedPanelScale
    end
    if self._preservedPanelAlpha then
        self.db.profile.configPanelAlpha = self._preservedPanelAlpha
    end

    if self.RefreshAll then
        self:RefreshAll()
    end


    if PREYCore.Minimap then

        C_Timer.After(0.1, function()
            if PREYCore.Minimap.Refresh then
                PREYCore.Minimap:Refresh()
            end
        end)
    end


    C_Timer.After(0.2, function()
        if _G.PreyUI_RefreshUnitFrames then
            _G.PreyUI_RefreshUnitFrames()
        end
    end)


    C_Timer.After(0.3, function()
        if _G.PreyUI_RefreshNCDM then
            _G.PreyUI_RefreshNCDM()
        end
    end)


    C_Timer.After(0.4, function()
        if _G.PreyUI_RefreshCDMVisibility then
            _G.PreyUI_RefreshCDMVisibility()
        end
    end)


    C_Timer.After(0.45, function()
        if _G.PreyUI_RefreshReticle then
            _G.PreyUI_RefreshReticle()
        end
    end)


    C_Timer.After(0.47, function()
        if _G.PreyUI_RefreshCustomTrackers then
            _G.PreyUI_RefreshCustomTrackers()
        end
    end)


    if _G.PreyUI_RefreshSpecProfilesTab then
        _G.PreyUI_RefreshSpecProfilesTab()
    end


    C_Timer.After(0.5, function()
        self:ShowProfileChangeNotification()
    end)
end

function PREYCore:ShowProfileChangeNotification()

    if not self.profileChangePopup then
        local popup = CreateFrame("Frame", "PREYCore_ProfileChangePopup", UIParent, "BackdropTemplate")
        popup:SetSize(400, 120)
        popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        popup:SetFrameStrata("DIALOG")
        popup:SetFrameLevel(1000)
        popup:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        popup:SetBackdropColor(0, 0, 0, 0.9)
        popup:Hide()


        local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", popup, "TOP", 0, -20)
        title:SetText("Profile Changed")
        popup.title = title


        local message = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        message:SetPoint("CENTER", popup, "CENTER", 0, -10)
        message:SetWidth(360)
        message:SetJustifyH("CENTER")
        message:SetText("Profile changed please open edit mode for unit frame position updates")
        popup.message = message


        local closeButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
        closeButton:SetSize(100, 30)
        closeButton:SetPoint("BOTTOM", popup, "BOTTOM", 0, 15)
        closeButton:SetText("OK")
        closeButton:SetScript("OnClick", function(self)
            self:GetParent():Hide()

            DEFAULT_CHAT_FRAME.editBox:SetText("/editmode")
            ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
        end)
        popup.closeButton = closeButton

        self.profileChangePopup = popup
    end


    if self.profileChangePopup then
        self.profileChangePopup:Show()

        C_Timer.After(10, function()
            if self.profileChangePopup and self.profileChangePopup:IsShown() then
                self.profileChangePopup:Hide()
            end
        end)
    end
end


PREYCore.EditModeSelection = {
    selectedType = nil,
    selectedKey = nil,
}


function PREYCore:SelectEditModeElement(elementType, elementKey)

    if self.EditModeSelection.selectedType == elementType and self.EditModeSelection.selectedKey == elementKey then
        return
    end


    self:HideCurrentSelectionArrows()


    self.EditModeSelection.selectedType = elementType
    self.EditModeSelection.selectedKey = elementKey


    self:ShowSelectionArrows(elementType, elementKey)
end


function PREYCore:ClearEditModeSelection()
    self:HideCurrentSelectionArrows()
    self.EditModeSelection.selectedType = nil
    self.EditModeSelection.selectedKey = nil
end


function PREYCore:HideCurrentSelectionArrows()
    local sel = self.EditModeSelection
    if not sel.selectedType then return end

    if sel.selectedType == "unitframe" then

        if ns.PREY_UnitFrames and ns.PREY_UnitFrames.frames then
            local frame = ns.PREY_UnitFrames.frames[sel.selectedKey]
            if frame and frame.editOverlay then
                self:HideNudgeButtons(frame.editOverlay)
            end
        end
    elseif sel.selectedType == "powerbar" then
        local bar = (sel.selectedKey == "primary") and self.powerBar or self.secondaryPowerBar
        if bar and bar.editOverlay then
            self:HideNudgeButtons(bar.editOverlay)
        end
    elseif sel.selectedType == "cdm" then
        if self.cdmOverlays and self.cdmOverlays[sel.selectedKey] then
            self:HideNudgeButtons(self.cdmOverlays[sel.selectedKey])
        end
    elseif sel.selectedType == "blizzard" then
        if self.blizzardOverlays and self.blizzardOverlays[sel.selectedKey] then
            self:HideNudgeButtons(self.blizzardOverlays[sel.selectedKey])
        end
    elseif sel.selectedType == "minimap" then
        if self.minimapOverlay then
            self:HideNudgeButtons(self.minimapOverlay)
        end
    end
end


function PREYCore:ShowSelectionArrows(elementType, elementKey)
    if elementType == "unitframe" then
        if ns.PREY_UnitFrames and ns.PREY_UnitFrames.frames then
            local frame = ns.PREY_UnitFrames.frames[elementKey]
            if frame and frame.editOverlay then
                self:ShowNudgeButtons(frame.editOverlay)
            end
        end
    elseif elementType == "powerbar" then
        local bar = (elementKey == "primary") and self.powerBar or self.secondaryPowerBar
        if bar and bar.editOverlay then
            self:ShowNudgeButtons(bar.editOverlay)
        end
    elseif elementType == "cdm" then
        if self.cdmOverlays and self.cdmOverlays[elementKey] then
            self:ShowNudgeButtons(self.cdmOverlays[elementKey])
        end
    elseif elementType == "blizzard" then
        if self.blizzardOverlays and self.blizzardOverlays[elementKey] then
            self:ShowNudgeButtons(self.blizzardOverlays[elementKey])
        end
    elseif elementType == "minimap" then
        if self.minimapOverlay then
            self:ShowNudgeButtons(self.minimapOverlay)

            local settings = self.db and self.db.profile and self.db.profile.minimap
            if settings and settings.position and self.minimapOverlay.infoText then
                self.minimapOverlay.infoText:SetText(string.format("Minimap  X:%d Y:%d",
                    math.floor(settings.position[3] or 0),
                    math.floor(settings.position[4] or 0)))
            end
        end
    end
end


function PREYCore:ShowNudgeButtons(overlay)
    if not overlay then return end
    if overlay.nudgeUp then overlay.nudgeUp:Show() end
    if overlay.nudgeDown then overlay.nudgeDown:Show() end
    if overlay.nudgeLeft then overlay.nudgeLeft:Show() end
    if overlay.nudgeRight then overlay.nudgeRight:Show() end
    if overlay.infoText then overlay.infoText:Show() end
end


function PREYCore:HideNudgeButtons(overlay)
    if not overlay then return end
    if overlay.nudgeUp then overlay.nudgeUp:Hide() end
    if overlay.nudgeDown then overlay.nudgeDown:Hide() end
    if overlay.nudgeLeft then overlay.nudgeLeft:Hide() end
    if overlay.nudgeRight then overlay.nudgeRight:Hide() end
    if overlay.infoText then overlay.infoText:Hide() end
end


function PREYCore:OnEnable()


    SlashCmdList["RELOAD"] = function()
        PREY:SafeReload()
    end


    if self.InitializePixelPerfect then
        self:InitializePixelPerfect()
    end


    if self.ApplyUIScale then
        self:ApplyUIScale()
    elseif self.db.profile.general then

        local savedScale = self.db.profile.general.uiScale
        local scaleToApply
        if savedScale and savedScale > 0 then
            scaleToApply = savedScale
        else

            local _, screenHeight = GetPhysicalScreenSize()
            if screenHeight >= 2160 then
                scaleToApply = 0.53
            elseif screenHeight >= 1440 then
                scaleToApply = 0.64
            else
                scaleToApply = 1.0
            end
            self.db.profile.general.uiScale = scaleToApply
        end

        pcall(function() UIParent:SetScale(scaleToApply) end)
    end


    self._preservedUIScale = UIParent:GetScale()
    self._preservedPanelScale = self.db.profile.configPanelScale
    self._preservedPanelAlpha = self.db.profile.configPanelAlpha


    C_Timer.After(0.1, function()
        if not InCombatLockdown() then
            self:HookViewers()
            self:HookEditMode()
        end
    end)


    C_Timer.After(0.5, function()
        if self.UnitFrames and self.db.profile.unitFrames and self.db.profile.unitFrames.enabled then
            self.UnitFrames:Initialize()
        end

        if self.Alerts and self.db.profile.general and self.db.profile.general.skinAlerts then
            self.Alerts:Initialize()
        end

        if self.ApplyGlobalFont then
            self:ApplyGlobalFont()
        end

        local _, class = UnitClass("player")
        if class == "MONK" and PREY.InitStaggerBar then
            PREY:InitStaggerBar()
        end
    end)


    C_Timer.After(1.0, function()
        if not InCombatLockdown() then
            self:ForceReskinAllViewers()
        end
        if _G.PreyUI_RefreshUIHider then
            _G.PreyUI_RefreshUIHider()
        end
        if _G.PreyUI_RefreshBuffBorders then
            _G.PreyUI_RefreshBuffBorders()
        end
    end)


    C_Timer.After(2.0, function()
        if not InCombatLockdown() then
            self:ForceReskinAllViewers()
        end
    end)
end

function PREYCore:OpenConfig()

    if PreyUI and PreyUI.GUI then
        PreyUI.GUI:Toggle()
    end
end

function PREYCore:CreateMinimapButton()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local LibDBIcon = LibStub("LibDBIcon-1.0", true)

    if not LDB or not LibDBIcon then
        return
    end


    if not self.db.profile.minimapButton then
        self.db.profile.minimapButton = {
            hide = false,
        }
    end


    local dataObj = LDB:NewDataObject(ADDON_NAME, {
        type = "launcher",
        icon = "Interface\\AddOns\\PreyUI\\assets\\preyLogo.tga",
        label = "PreyUI",
        OnClick = function(clickedframe, button)
            if button == "LeftButton" then
                self:OpenConfig()
            elseif button == "RightButton" then


                self:OpenConfig()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText("|cFFB91C1CPreyUI|r")
            tooltip:AddLine("Left-click to open configuration", 1, 1, 1)
            tooltip:AddLine("Right-click to open configuration", 1, 1, 1)
        end,
    })


    LibDBIcon:Register(ADDON_NAME, dataObj, self.db.profile.minimapButton)
end


local function CreateBorder(frame)
    if frame.border then return frame.border end

    local bord = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    bord:SetPoint("TOPLEFT", frame, -1, 1)
    bord:SetPoint("BOTTOMRIGHT", frame, 1, -1)
    bord:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    bord:SetBackdropBorderColor(0, 0, 0, 1)

    frame.border = bord
    return bord
end

local function IsCooldownIconFrame(frame)
    return frame and (frame.icon or frame.Icon) and frame.Cooldown
end

local function StripBlizzardOverlay(icon)
    for _, region in ipairs({ icon:GetRegions() }) do
        if region:IsObjectType("Texture") and region.GetAtlas and region:GetAtlas() == "UI-HUD-CoolDownManager-IconOverlay" then
            region:SetTexture("")
            region:Hide()
            region.Show = function() end
        end
    end
end

local function GetIconCountFont(icon)
    if not icon then return nil end


    local charge = icon.ChargeCount
    if charge then
        local fs = charge.Current or charge.Text or charge.Count or nil

        if not fs and charge.GetRegions then
            for _, region in ipairs({ charge:GetRegions() }) do
                if region:GetObjectType() == "FontString" then
                    fs = region
                    break
                end
            end
        end

        if fs then
            return fs
        end
    end


    local apps = icon.Applications
    if apps and apps.GetRegions then
        for _, region in ipairs({ apps:GetRegions() }) do
            if region:GetObjectType() == "FontString" then
                return region
            end
        end
    end


    for _, region in ipairs({ icon:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            local name = region:GetName()
            if name and (name:find("Stack") or name:find("Applications")) then
                return region
            end
        end
    end

    return nil
end


function PREYCore:SkinIcon(icon, settings)

    local iconTexture = icon.icon or icon.Icon
    if not icon or not iconTexture then return end


    local iconSize = settings.iconSize or 40
    local aspectRatioValue = 1.0


    if settings.aspectRatioCrop then
        aspectRatioValue = settings.aspectRatioCrop
    elseif settings.aspectRatio then

        local aspectW, aspectH = settings.aspectRatio:match("^(%d+%.?%d*):(%d+%.?%d*)$")
        if aspectW and aspectH then
            aspectRatioValue = tonumber(aspectW) / tonumber(aspectH)
        end
    end

    local iconWidth = iconSize
    local iconHeight = iconSize


    if aspectRatioValue and aspectRatioValue ~= 1.0 then
        if aspectRatioValue > 1.0 then

            iconWidth = iconSize
            iconHeight = iconSize / aspectRatioValue
        elseif aspectRatioValue < 1.0 then

            iconWidth = iconSize * aspectRatioValue
            iconHeight = iconSize
        end
    end

    local padding   = settings.padding or 5
    local zoom      = settings.zoom or 0
    local border    = icon.__CDM_Border
    local cdPadding = math.floor(padding * 0.7 + 0.5)


    iconTexture:ClearAllPoints()


    iconTexture:SetPoint("TOPLEFT", icon, "TOPLEFT", padding, -padding)
    iconTexture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -padding, padding)


    local left, right, top, bottom = 0, 1, 0, 1

    if aspectRatioValue and aspectRatioValue ~= 1.0 then
        if aspectRatioValue > 1.0 then

            local cropAmount = 1.0 - (1.0 / aspectRatioValue)
            local offset = cropAmount / 2.0
            top = offset
            bottom = 1.0 - offset
        elseif aspectRatioValue < 1.0 then

            local cropAmount = 1.0 - aspectRatioValue
            local offset = cropAmount / 2.0
            left = offset
            right = 1.0 - offset
        end
    end


    if zoom > 0 then
        local currentWidth = right - left
        local currentHeight = bottom - top
        local visibleSize = 1.0 - (zoom * 2)

        local zoomedWidth = currentWidth * visibleSize
        local zoomedHeight = currentHeight * visibleSize

        local centerX = (left + right) / 2.0
        local centerY = (top + bottom) / 2.0

        left = centerX - (zoomedWidth / 2.0)
        right = centerX + (zoomedWidth / 2.0)
        top = centerY - (zoomedHeight / 2.0)
        bottom = centerY + (zoomedHeight / 2.0)
    end


    iconTexture:SetTexCoord(left, right, top, bottom)


    local sizeSet = pcall(function()
    icon:SetWidth(iconWidth)
    icon:SetHeight(iconHeight)
    icon:SetSize(iconWidth, iconHeight)
    end)


    if not sizeSet then
        iconTexture:SetTexCoord(0, 1, 0, 1)
        icon.__cdmSkinFailed = true
    else
        icon.__cdmSkinFailed = nil
    end


    if icon.CooldownFlash then
        icon.CooldownFlash:ClearAllPoints()
        icon.CooldownFlash:SetPoint("TOPLEFT", icon, "TOPLEFT", cdPadding, -cdPadding)
        icon.CooldownFlash:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -cdPadding, cdPadding)
    end


    if icon.Cooldown then
        icon.Cooldown:ClearAllPoints()
        icon.Cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", cdPadding, -cdPadding)
        icon.Cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -cdPadding, cdPadding)
    end


    local picon = icon.PandemicIcon or icon.pandemicIcon or icon.Pandemic or icon.pandemic
    if not picon then
        for _, region in ipairs({ icon:GetChildren() }) do
            if region:GetName() and region:GetName():find("Pandemic") then
                picon = region
                break
            end
        end
    end

    if picon and picon.ClearAllPoints then
        picon:ClearAllPoints()
        picon:SetPoint("TOPLEFT", icon, "TOPLEFT", padding, -padding)
        picon:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -padding, padding)
    end


    local oor = icon.OutOfRange or icon.outOfRange or icon.oor
    if oor and oor.ClearAllPoints then
        oor:ClearAllPoints()
        oor:SetPoint("TOPLEFT", icon, "TOPLEFT", padding, -padding)
        oor:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -padding, padding)
    end


    local fs = GetIconCountFont(icon)
    if fs and fs.ClearAllPoints then
        fs:ClearAllPoints()

        local point   = settings.chargeTextAnchor or "BOTTOMRIGHT"
        if point == "MIDDLE" then point = "CENTER" end

        local offsetX = settings.countTextOffsetX or 0
        local offsetY = settings.countTextOffsetY or 0

        fs:SetPoint(point, iconTexture, point, offsetX, offsetY)

        local desiredSize = settings.countTextSize
        if desiredSize and desiredSize > 0 then
            local font, _, flags = fs:GetFont()
            fs:SetFont(font, desiredSize, flags or "OUTLINE")
        end
    end


    local cooldown = icon.cooldown or icon.Cooldown
    if cooldown then

        local durationSize = settings.durationTextSize
        if durationSize and durationSize > 0 then

            if cooldown.text then
                local font, _, flags = cooldown.text:GetFont()
                if font then
                    cooldown.text:SetFont(font, durationSize, flags or "OUTLINE")
                end
            end


            for _, region in pairs({cooldown:GetRegions()}) do
                if region:GetObjectType() == "FontString" then
                    local font, _, flags = region:GetFont()
                    if font then
                        region:SetFont(font, durationSize, flags or "OUTLINE")
                    end
                end
            end
        end
    end


    StripBlizzardOverlay(icon)


    if icon.IsForbidden and icon:IsForbidden() then
        icon.__cdmSkinned = true
        return
    end

    local edgeSize = tonumber(settings.borderSize) or 1

    if edgeSize > 0 then
        if not border then
            border = icon:CreateTexture(nil, "BACKGROUND", nil, -8)
            icon.__CDM_Border = border
        end

        local r, g, b, a = unpack(settings.borderColor or { 0, 0, 0, 1 })
        border:SetColorTexture(r, g, b, a or 1)
        border:ClearAllPoints()
        border:SetPoint("TOPLEFT", iconTexture, "TOPLEFT", -edgeSize, edgeSize)
        border:SetPoint("BOTTOMRIGHT", iconTexture, "BOTTOMRIGHT", edgeSize, -edgeSize)
        border:Show()
    else
        if border then
            border:Hide()
        end
    end


    if not icon.__cdmSkinFailed then
    icon.__cdmSkinned = true
    end
    icon.__cdmSkinPending = nil
end

function PREYCore:SkinAllIconsInViewer(viewer)
    if not viewer or not viewer.GetName then return end

    local name     = viewer:GetName()
    local settings = self.db.profile.viewers[name]
    if not settings or not settings.enabled then return end

    local container = viewer.viewerFrame or viewer
    local children  = { container:GetChildren() }

    for _, icon in ipairs(children) do
        if IsCooldownIconFrame(icon) and (icon.icon or icon.Icon) then
            local ok, err = pcall(self.SkinIcon, self, icon, settings)
            if not ok then
                icon.__cdmSkinError = true
                print("|cffff4444[PREYCore] SkinIcon error for", name, "icon:", err, "|r")
            end
        end
    end
end


local function BuildRowPattern(settings, viewerName)
    local pattern = {}

    if viewerName == "EssentialCooldownViewer" then

        if (settings.row1Icons or 0) > 0 then table.insert(pattern, settings.row1Icons) end
        if (settings.row2Icons or 0) > 0 then table.insert(pattern, settings.row2Icons) end
        if (settings.row3Icons or 0) > 0 then table.insert(pattern, settings.row3Icons) end
    elseif viewerName == "UtilityCooldownViewer" then

        if (settings.row1Icons or 0) > 0 then table.insert(pattern, settings.row1Icons) end
        if (settings.row2Icons or 0) > 0 then table.insert(pattern, settings.row2Icons) end
    end


    if #pattern == 0 then
        return nil
    end

    return pattern
end


local function ComputeGrid(icons, pattern)
    local grid = {}
    local idx = 1

    for _, rowSize in ipairs(pattern) do
        if rowSize > 0 then
            local row = {}
            for i = 1, rowSize do
                if idx <= #icons then
                    row[#row + 1] = icons[idx]
                    idx = idx + 1
                end
            end
            if #row > 0 then
                grid[#grid + 1] = row
            end
        end
    end


    local lastRowSize = pattern[#pattern] or 6
    while idx <= #icons do
        local row = {}
        for i = 1, lastRowSize do
            if idx <= #icons then
                row[#row + 1] = icons[idx]
                idx = idx + 1
            end
        end
        if #row > 0 then
            grid[#grid + 1] = row
        end
    end

    return grid
end


local function MaxRowWidth(grid, iconWidth, spacing)
    local maxW = 0
    for _, row in ipairs(grid) do
        local rowW = (#row * iconWidth) + ((#row - 1) * spacing)
        if rowW > maxW then
            maxW = rowW
        end
    end
    return maxW
end

function PREYCore:ApplyViewerLayout(viewer)
    if not viewer or not viewer.GetName then return end
    local name     = viewer:GetName()
    local settings = self.db.profile.viewers[name]
    if not settings or not settings.enabled then return end

    local container = viewer.viewerFrame or viewer
    local icons = {}

    for _, child in ipairs({ container:GetChildren() }) do
        if IsCooldownIconFrame(child) and child:IsShown() then
            table.insert(icons, child)
        end
    end

    local count = #icons
    if count == 0 then return end


    table.sort(icons, function(a, b)
        return GetViewerStableFrameOrder(a) < GetViewerStableFrameOrder(b)
    end)


    local iconSize = settings.iconSize or 32
    local aspectRatioValue = 1.0


    if settings.aspectRatioCrop then
        aspectRatioValue = settings.aspectRatioCrop
    elseif settings.aspectRatio then

        local aspectW, aspectH = settings.aspectRatio:match("^(%d+%.?%d*):(%d+%.?%d*)$")
        if aspectW and aspectH then
            aspectRatioValue = tonumber(aspectW) / tonumber(aspectH)
        end
    end

    local iconWidth = iconSize
    local iconHeight = iconSize


    if aspectRatioValue and aspectRatioValue ~= 1.0 then
        if aspectRatioValue > 1.0 then

            iconWidth = iconSize
            iconHeight = iconSize / aspectRatioValue
        elseif aspectRatioValue < 1.0 then

            iconWidth = iconSize * aspectRatioValue
            iconHeight = iconSize
        end
    end

    local spacing    = settings.spacing or 4
    local rowLimit   = settings.rowLimit or 0


    for _, icon in ipairs(icons) do
        icon:ClearAllPoints()
        icon:SetWidth(iconWidth)
        icon:SetHeight(iconHeight)
        icon:SetSize(iconWidth, iconHeight)
    end


    local useRowPattern = settings.useRowPattern
    local rowPattern = nil

    if useRowPattern and (name == "EssentialCooldownViewer" or name == "UtilityCooldownViewer") then
        rowPattern = BuildRowPattern(settings, name)
    end


    local yOffset = 0
    if name == "UtilityCooldownViewer" and settings.anchorToEssential then
        local essentialViewer = _G.EssentialCooldownViewer
        if essentialViewer and essentialViewer.__cdmTotalHeight then
            local anchorGap = settings.anchorGap or 10

            yOffset = -(essentialViewer.__cdmTotalHeight + anchorGap)
        end
    end


    if rowPattern and #rowPattern > 0 then
        local grid = ComputeGrid(icons, rowPattern)
        local maxW = MaxRowWidth(grid, iconWidth, spacing)
        local alignment = settings.rowAlignment or "CENTER"
        local rowSpacing = iconHeight + spacing

        viewer.__cdmIconWidth = maxW

        viewer.__cdmTotalHeight = (#grid * iconHeight) + ((#grid - 1) * spacing)

        local y = yOffset
        for rowIdx, row in ipairs(grid) do
            local rowW = (#row * iconWidth) + ((#row - 1) * spacing)


            local startX
            if alignment == "LEFT" then
                startX = -maxW / 2 + iconWidth / 2
            elseif alignment == "RIGHT" then
                startX = maxW / 2 - rowW + iconWidth / 2
            else
                startX = -rowW / 2 + iconWidth / 2
            end


            for idx, icon in ipairs(row) do
                local x = startX + (idx - 1) * (iconWidth + spacing)
                icon:SetPoint("CENTER", container, "CENTER", x, y)
            end


            y = y - rowSpacing
        end


    elseif rowLimit <= 0 then

        local totalWidth = count * iconWidth + (count - 1) * spacing
        viewer.__cdmIconWidth = totalWidth
        viewer.__cdmTotalHeight = iconHeight

        local startX = -totalWidth / 2 + iconWidth / 2

        for i, icon in ipairs(icons) do
            local x = startX + (i - 1) * (iconWidth + spacing)
            icon:SetPoint("CENTER", container, "CENTER", x, yOffset)
        end
    else

        local numRows = math.ceil(count / rowLimit)
        local rowSpacing = iconHeight + spacing

        local maxRowWidth = 0
        for row = 1, numRows do
            local rowStart = (row - 1) * rowLimit + 1
            local rowEnd = math.min(row * rowLimit, count)
            local rowCount = rowEnd - rowStart + 1
            if rowCount > 0 then
                local rowWidth = rowCount * iconWidth + (rowCount - 1) * spacing
                if rowWidth > maxRowWidth then
                    maxRowWidth = rowWidth
                end
            end
        end

        viewer.__cdmIconWidth = maxRowWidth
        viewer.__cdmTotalHeight = (numRows * iconHeight) + ((numRows - 1) * spacing)

        local growDirection = "down"

        for i, icon in ipairs(icons) do
            local row = math.ceil(i / rowLimit)
            local rowStart = (row - 1) * rowLimit + 1
            local rowEnd = math.min(row * rowLimit, count)
            local rowCount = rowEnd - rowStart + 1
            local positionInRow = i - rowStart + 1

            local rowWidth = rowCount * iconWidth + (rowCount - 1) * spacing
            local startX = -rowWidth / 2 + iconWidth / 2
            local x = startX + (positionInRow - 1) * (iconWidth + spacing)

            local y
            if growDirection == "up" then
                y = yOffset + (row - 1) * rowSpacing
            else
                y = yOffset - (row - 1) * rowSpacing
            end

            icon:SetPoint("CENTER", container, "CENTER", x, y)
        end
    end
end

function PREYCore:RescanViewer(viewer)
    if not viewer or not viewer.GetName then return end
    local name     = viewer:GetName()
    local settings = self.db.profile.viewers[name]
    if not settings or not settings.enabled then return end

    local container = viewer.viewerFrame or viewer
    local icons = {}
    local changed = false
    local inCombat = InCombatLockdown()

    for _, child in ipairs({ container:GetChildren() }) do
        if IsCooldownIconFrame(child) and child:IsShown() then
            table.insert(icons, child)


            if not child.__cdmSkinned or child.__cdmSkinFailed then

                if not child.__cdmSkinPending then
                    child.__cdmSkinPending = true

                    if inCombat then

                        if not self.__cdmPendingIcons then
                            self.__cdmPendingIcons = {}
                        end
                        self.__cdmPendingIcons[child] = { icon = child, settings = settings, viewer = viewer }


                        if not self.__cdmIconSkinEventFrame then
                            local eventFrame = CreateFrame("Frame")
                            eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                            eventFrame:SetScript("OnEvent", function(self)
                                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                                PREYCore:ProcessPendingIcons()
                            end)
                            self.__cdmIconSkinEventFrame = eventFrame
                        end
                        self.__cdmIconSkinEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                    else

                        local success = pcall(self.SkinIcon, self, child, settings)
                        if success then
                            child.__cdmSkinPending = nil
                        end
                    end
                    changed = true
                end
            end
        end
    end

    local count = #icons


    if count ~= viewer.__cdmIconCount then
        viewer.__cdmIconCount = count
        changed = true
    end

    if changed then

        self:ApplyViewerLayout(viewer)


        if self.UpdatePowerBar then
            self:UpdatePowerBar()
        end
        if self.UpdateSecondaryPowerBar then
            self:UpdateSecondaryPowerBar()
        end
    end
end

function PREYCore:ApplyViewerSkin(viewer)
    if not viewer or not viewer.GetName then return end
    local name     = viewer:GetName()
    local settings = self.db.profile.viewers[name]
    if not settings or not settings.enabled then return end


    self:ApplyViewerLayout(viewer)
    self:SkinAllIconsInViewer(viewer)
    self:UpdatePowerBar()
    self:UpdateSecondaryPowerBar()


    if not InCombatLockdown() then
        self:ProcessPendingIcons()
    end
end

function PREYCore:ProcessPendingIcons()
    if not self.__cdmPendingIcons then return end
    if InCombatLockdown() then return end

    local processed = {}
    for icon, data in pairs(self.__cdmPendingIcons) do
        if icon and icon:IsShown() and not icon.__cdmSkinned then
            local success = pcall(self.SkinIcon, self, icon, data.settings)
            if success then
                icon.__cdmSkinPending = nil
                processed[icon] = true
            end
        elseif not icon or not icon:IsShown() then

            processed[icon] = true
        end
    end


    for icon in pairs(processed) do
        self.__cdmPendingIcons[icon] = nil
    end


    if not next(self.__cdmPendingIcons) then
        self.__cdmPendingIcons = nil
    end
end

function PREYCore:HookViewers()
    for _, name in ipairs(self.viewers) do
        local viewer = rawget(_G, name)
        if viewer and not viewer.__cdmHooked then
            viewer.__cdmHooked = true

            viewer:HookScript("OnShow", function(f)
                self:ApplyViewerSkin(f)
            end)

            viewer:HookScript("OnSizeChanged", function(f)
                self:ApplyViewerLayout(f)
            end)


            local updateInterval = 1.0

            viewer:HookScript("OnUpdate", function(f, elapsed)
                f.__cdmElapsed = (f.__cdmElapsed or 0) + elapsed
                if f.__cdmElapsed > updateInterval then
                    f.__cdmElapsed = 0
                    if f:IsShown() then
                        self:RescanViewer(f)

                        if not InCombatLockdown() then
                            if self.__cdmPendingIcons then
                            self:ProcessPendingIcons()
                            end
                            if self.__cdmPendingBackdrops then
                                self:ProcessPendingBackdrops()
                            end
                        end
                    end
                end
            end)

            self:ApplyViewerSkin(viewer)
        end
    end
end

function PREYCore:ForceRefreshBuffIcons()
    local viewer = rawget(_G, "BuffIconCooldownViewer")
    if viewer and viewer:IsShown() then
        viewer.__cdmIconCount = nil
        self:RescanViewer(viewer)

        if not InCombatLockdown() then
            self:ProcessPendingIcons()
        end
    end
end


function PREYCore:ForceReskinAllViewers()
    for _, name in ipairs(self.viewers) do
        local viewer = rawget(_G, name)
        if viewer then
            local container = viewer.viewerFrame or viewer
            local children = { container:GetChildren() }
            for _, child in ipairs(children) do

                child.__cdmSkinned = nil
                child.__cdmSkinPending = nil
                child.__cdmSkinFailed = nil
            end

            viewer.__cdmIconCount = nil


        end
    end


    for _, name in ipairs(self.viewers) do
        local viewer = rawget(_G, name)
        if viewer and viewer:IsShown() then
            self:RescanViewer(viewer)

            self:ApplyViewerSkin(viewer)
        end
    end
end


function PREYCore:HookEditMode()
    if self.__editModeHooked then return end
    self.__editModeHooked = true


    if EditModeManagerFrame then

        hooksecurefunc(EditModeManagerFrame, "EnterEditMode", function()
            C_Timer.After(0.1, function()
                self:ForceReskinAllViewers()
            end)


            if BossTargetFrameContainer and not BossTargetFrameContainer._preyScaledSidesHooked then
                if BossTargetFrameContainer.GetScaledSelectionSides then
                    local original = BossTargetFrameContainer.GetScaledSelectionSides
                    BossTargetFrameContainer.GetScaledSelectionSides = function(frame)
                        local left = frame:GetLeft()
                        if left == nil then

                            return -10000, -9999, 10000, 10001
                        end
                        return original(frame)
                    end
                    BossTargetFrameContainer._preyScaledSidesHooked = true
                end
            end
        end)


        hooksecurefunc(EditModeManagerFrame, "ExitEditMode", function()
            C_Timer.After(0.1, function()
                self:ForceReskinAllViewers()


                C_Timer.After(0.15, function()
                    for _, barName in ipairs({"PreyUIPrimaryPowerBar", "PreyUISecondaryPowerBar"}) do
                        local bar = rawget(_G, barName)
                        if bar and bar.editOverlay and bar.editOverlay:IsShown() then
                            bar.editOverlay:Hide()
                        end
                    end
                end)
            end)
        end)
            end


    local combatEndFrame = CreateFrame("Frame")
    combatEndFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatEndFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    combatEndFrame:SetScript("OnEvent", function(frame, event)
        if event == "PLAYER_REGEN_ENABLED" then

            C_Timer.After(0.2, function()

                local needsReskin = false
                for _, viewerName in ipairs(self.viewers) do
                    local viewer = rawget(_G, viewerName)
                    if viewer then
                        local container = viewer.viewerFrame or viewer
                        for _, child in ipairs({ container:GetChildren() }) do
                            if child.__cdmSkinFailed then
                                needsReskin = true
                                break
                            end
                end
            end
                    if needsReskin then break end
                end

                if needsReskin then
                    self:ForceReskinAllViewers()
                end
            end)
        elseif event == "PLAYER_ENTERING_WORLD" then

            C_Timer.After(1, function()
                if not InCombatLockdown() then
                    self:ForceReskinAllViewers()
            end
        end)
            end
        end)
    end


function PREYCore:ProcessPendingBackdrops()
    if not self.__cdmPendingBackdrops then return end

    local processed = {}
    for frame, _ in pairs(self.__cdmPendingBackdrops) do
        if frame then

            local ok, isValid = pcall(function()
                local w = frame:GetWidth()
                local h = frame:GetHeight()
                if w and h then
                    local test = w + h
                    return test > 0
                end
                return false
            end)

            if ok and isValid then

                local pendingInfo = frame.__cdmBackdropPending
                local pendingSettings = frame.__cdmBackdropSettings

                if pendingSettings then
                    if pendingSettings.backdropInfo then
                        local setOk = pcall(frame.SetBackdrop, frame, pendingSettings.backdropInfo)
                        if setOk and pendingSettings.borderColor then
                            pcall(frame.SetBackdropBorderColor, frame, unpack(pendingSettings.borderColor))
end
                    elseif pendingInfo then
                        pcall(frame.SetBackdrop, frame, pendingInfo)
                    end
                elseif pendingInfo then
                    pcall(frame.SetBackdrop, frame, pendingInfo)
                end

                frame.__cdmBackdropPending = nil
                frame.__cdmBackdropSettings = nil
                table.insert(processed, frame)
                end
            end
        end


    for _, frame in ipairs(processed) do
        self.__cdmPendingBackdrops[frame] = nil
            end
        end

function PREY:GetGlobalFont()
    local LSM = LibStub("LibSharedMedia-3.0")
    local fontName = "Prey"


    if PREYCore and PREYCore.db and PREYCore.db.profile and PREYCore.db.profile.general then
        fontName = PREYCore.db.profile.general.font or fontName
    end

    return LSM:Fetch("font", fontName) or [[Interface\AddOns\PreyUI\assets\Prey.ttf]]
end

function PREY:GetGlobalTexture()
    local LSM = LibStub("LibSharedMedia-3.0")

    local textureName = "Prey"
    return LSM:Fetch("statusbar", textureName) or "Interface\\AddOns\\PreyUI\\assets\\Prey"
end

function PREY:GetSkinColor()
    local db = PREY.db and PREY.db.profile
    if not db or not db.general then
        return 0.820, 0.180, 0.220, 1
    end

    if db.general.skinUseClassColor then
        local _, class = UnitClass("player")
        local color = RAID_CLASS_COLORS[class]
        if color then
            return color.r, color.g, color.b, 1
        end
    end

    local c = db.general.skinCustomColor or {0.820, 0.180, 0.220, 1}
    return c[1], c[2], c[3], c[4] or 1
end

function PREY:GetSkinBgColor()
    local db = PREY.db and PREY.db.profile
    if not db or not db.general then
        return 0.05, 0.05, 0.05, 0.95
    end

    local c = db.general.skinBgColor or { 0.05, 0.05, 0.05, 0.95 }
    return c[1], c[2], c[3], c[4] or 0.95
end


function PREYCore:SafeSetFont(fontString, fontPath, size, flags)
    if not fontString then return end
    fontString:SetFont(fontPath, size, flags or "")

    local actualFont = fontString:GetFont()
    if not actualFont then

        fontString:SetFont("Fonts\\FRIZQT__.TTF", size, flags or "")
    end
end

function PREYCore:RefreshAll()
    for _, name in ipairs(self.viewers) do
        local viewer = rawget(_G, name)
        if viewer and viewer:IsShown() then
            self:ApplyViewerSkin(viewer)
        end
    end
    self:UpdatePowerBar()
    self:UpdateSecondaryPowerBar()

    if self.ApplyGlobalFont then
        self:ApplyGlobalFont()
    end

    if _G.PreyUI_RefreshSkyriding then
        _G.PreyUI_RefreshSkyriding()
    end
end


local PREY_FONT_PATH = [[Interface\AddOns\PreyUI\assets\Prey.ttf]]


local BLIZZARD_FONT_OBJECTS = {

    "GameFontNormal", "GameFontHighlight", "GameFontNormalSmall",
    "GameFontHighlightSmall", "GameFontNormalLarge", "GameFontHighlightLarge",
    "GameFontDisable", "GameFontDisableSmall", "GameFontDisableLarge",

    "NumberFontNormal", "NumberFontNormalSmall", "NumberFontNormalLarge",
    "NumberFontNormalHuge", "NumberFontNormalSmallGray",

    "QuestFont", "QuestFontHighlight", "QuestFontNormalSmall",
    "QuestFontHighlightSmall",

    "GameTooltipHeaderText", "GameTooltipText", "GameTooltipTextSmall",

    "ChatFontNormal", "ChatFontSmall", "ChatFontLarge",
}


local globalFontHooksInitialized = false


local globalFontPending = false

local function GetGlobalFontPath()
    if not PREYCore.db or not PREYCore.db.profile or not PREYCore.db.profile.general then
        return PREY_FONT_PATH
    end
    local fontName = PREYCore.db.profile.general.font or "Prey"
    local fontPath = LSM:Fetch("font", fontName)
    return fontPath or PREY_FONT_PATH
end


local function ApplyFontToFontString(fontString, fontPath)
    if not fontString or not fontString.GetFont or not fontString.SetFont then return end
    local _, size, flags = fontString:GetFont()
    if size and size > 0 then
        fontString:SetFont(fontPath, size, flags or "")
    end
end


local function ApplyFontToFrameRecursive(frame, fontPath)
    if not frame then return end


    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region:IsObjectType("FontString") then
            ApplyFontToFontString(region, fontPath)
        end
    end


    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        ApplyFontToFrameRecursive(child, fontPath)
    end
end


local function ScheduleGlobalFontApply()
    if globalFontPending then return end
    globalFontPending = true
    C_Timer.After(0.05, function()
        globalFontPending = false
        if PREYCore.ApplyGlobalFont then
            PREYCore:ApplyGlobalFont()
        end
    end)
end

function PREYCore:ApplyGlobalFont()

    if not self.db or not self.db.profile or not self.db.profile.general then return end
    if not self.db.profile.general.applyGlobalFontToBlizzard then return end

    local fontPath = GetGlobalFontPath()


    for _, fontObjName in ipairs(BLIZZARD_FONT_OBJECTS) do
        local fontObj = rawget(_G, fontObjName)
        if fontObj and fontObj.GetFont and fontObj.SetFont then
            local _, size, flags = fontObj:GetFont()
            if size then
                fontObj:SetFont(fontPath, size, flags or "")
            end
        end
    end


    if not globalFontHooksInitialized then
        globalFontHooksInitialized = true


        if ObjectiveTrackerFrame then
            if type(ObjectiveTracker_Update) == "function" then
                hooksecurefunc("ObjectiveTracker_Update", function()
                    if not PREYCore.db.profile.general.applyGlobalFontToBlizzard then return end
                    local fp = GetGlobalFontPath()
                    ApplyFontToFrameRecursive(ObjectiveTrackerFrame, fp)
                end)
            else

                ObjectiveTrackerFrame:HookScript("OnShow", function(self)
                    if not PREYCore.db.profile.general.applyGlobalFontToBlizzard then return end
                    local fp = GetGlobalFontPath()
                    ApplyFontToFrameRecursive(self, fp)
                end)
            end
        end


        if GameTooltip then
            hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip)
                if not PREYCore.db.profile.general.applyGlobalFontToBlizzard then return end
                local fp = GetGlobalFontPath()
                ApplyFontToFrameRecursive(tooltip, fp)
            end)
        end


        if FCF_SetChatWindowFontSize then
            hooksecurefunc("FCF_SetChatWindowFontSize", function(chatFrame, fontSize)
                if not PREYCore.db.profile.general.applyGlobalFontToBlizzard then return end
                local fp = GetGlobalFontPath()
                if chatFrame and chatFrame.SetFont then

                    local _, size, flags = chatFrame:GetFont()
                    chatFrame:SetFont(fp, fontSize or size or 14, flags or "")
                end
            end)
        end


        local chatFontEventFrame = CreateFrame("Frame")
        chatFontEventFrame:RegisterEvent("UPDATE_CHAT_WINDOWS")
        chatFontEventFrame:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS")
        chatFontEventFrame:SetScript("OnEvent", function()
            if not PREYCore.db or not PREYCore.db.profile then return end
            if not PREYCore.db.profile.general.applyGlobalFontToBlizzard then return end
            C_Timer.After(0.05, function()
                local fp = GetGlobalFontPath()
                for i = 1, NUM_CHAT_WINDOWS do
                    local chatFrame = rawget(_G, "ChatFrame" .. i)
                    if chatFrame and chatFrame.SetFont then
                        local _, size, flags = chatFrame:GetFont()
                        if size then
                            chatFrame:SetFont(fp, size, flags or "")
                        end
                    end
                end
            end)
        end)
    end


    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = rawget(_G, "ChatFrame" .. i)
        if chatFrame and chatFrame.SetFont then
            local _, size, flags = chatFrame:GetFont()
            if size then
                chatFrame:SetFont(fontPath, size, flags or "")
            end
        end
    end


    if GameTooltip then
        ApplyFontToFrameRecursive(GameTooltip, fontPath)
    end
end
