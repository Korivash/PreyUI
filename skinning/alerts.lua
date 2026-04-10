local ADDON_NAME, ns = ...
local PREYCore = ns.Addon


local Alerts = {}
PREYCore.Alerts = Alerts


local PREY_TEXT_COLOR = { 0.953, 0.957, 0.965, 1 }


local ICON_TEX_COORDS = { 0.08, 0.92, 0.08, 0.92 }


local function GetDB()
    return PREYCore.db and PREYCore.db.profile or {}
end

local function GetGeneralSettings()
    local db = GetDB()
    return db.general or {}
end

local function GetAlertSettings()
    local db = GetDB()

    local alerts = db.alerts or {}
    local general = db.general or {}
    alerts.enabled = general.skinAlerts
    return alerts
end


local function GetThemeColors()
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


local function ForceAlpha(frame, alpha, forced)
    if alpha ~= 1 and forced ~= true then
        frame:SetAlpha(1, true)
    end
end


local function CreateAlertBackdrop(frame, xOffset1, yOffset1, xOffset2, yOffset2)
    if frame.preyBackdrop then return frame.preyBackdrop end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetThemeColors()

    local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    backdrop:SetFrameLevel(frame:GetFrameLevel())
    backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset1 or 0, yOffset1 or 0)
    backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", xOffset2 or 0, yOffset2 or 0)
    backdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    backdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    backdrop:SetBackdropBorderColor(sr, sg, sb, sa)

    frame.preyBackdrop = backdrop
    return backdrop
end


local function UpdateBackdropColors(frame)
    if not frame.preyBackdrop then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetThemeColors()
    frame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
    frame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
end


local function CreateIconBorder(icon, parent, qualityColor)
    local sr, sg, sb, sa = GetThemeColors()


    if icon.preyBorder then
        if qualityColor then
            icon.preyBorder:SetBackdropBorderColor(qualityColor.r or qualityColor[1], qualityColor.g or qualityColor[2], qualityColor.b or qualityColor[3], 1)
        else
            icon.preyBorder:SetBackdropBorderColor(sr, sg, sb, sa)
        end
        return icon.preyBorder
    end

    local border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    border:SetFrameLevel(parent:GetFrameLevel() + 1)
    border:SetPoint("TOPLEFT", icon, "TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    border:SetBackdrop({
        bgFile = nil,
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })


    if qualityColor then
        border:SetBackdropBorderColor(qualityColor.r or qualityColor[1], qualityColor.g or qualityColor[2], qualityColor.b or qualityColor[3], 1)
    else
        border:SetBackdropBorderColor(sr, sg, sb, sa)
    end

    icon.preyBorder = border
    return border
end


local function StyleIcon(icon, parent, qualityColor)
    if not icon then return end

    icon:SetTexCoord(unpack(ICON_TEX_COORDS))
    icon:SetDrawLayer("ARTWORK")

    CreateIconBorder(icon, parent, qualityColor)
end


local function Kill(obj)
    if obj then
        if obj.UnregisterAllEvents then
            obj:UnregisterAllEvents()
        end
        if obj.SetAlpha then
            obj:SetAlpha(0)
        end
        if obj.Hide then
            obj:Hide()
        end
        if obj.SetTexture then
            obj:SetTexture(nil)
        end
    end
end


local function SkinAchievementAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end


    CreateAlertBackdrop(frame, -2, -6, -2, 6)


    Kill(frame.Background)
    Kill(frame.glow)
    Kill(frame.shine)
    Kill(frame.GuildBanner)
    Kill(frame.GuildBorder)


    if frame.Unlocked then
        frame.Unlocked:SetTextColor(unpack(PREY_TEXT_COLOR))
    end
    if frame.Name then
        frame.Name:SetTextColor(1, 0.82, 0)
    end


    if frame.Icon and frame.Icon.Texture then
        Kill(frame.Icon.Overlay)
        StyleIcon(frame.Icon.Texture, frame)
    end

    frame.preySkinned = true
end


local function SkinCriteriaAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    CreateAlertBackdrop(frame, -2, -6, -2, 6)

    Kill(frame.Background)
    Kill(frame.glow)
    Kill(frame.shine)
    Kill(frame.Icon.Bling)
    Kill(frame.Icon.Overlay)

    if frame.Unlocked then frame.Unlocked:SetTextColor(unpack(PREY_TEXT_COLOR)) end
    if frame.Name then frame.Name:SetTextColor(1, 1, 0) end

    StyleIcon(frame.Icon.Texture, frame)

    frame.preySkinned = true
end


local function SkinLootWonAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    Kill(frame.Background)
    Kill(frame.glow)
    Kill(frame.shine)
    Kill(frame.BGAtlas)
    Kill(frame.PvPBackground)

    local lootItem = frame.lootItem or frame
    Kill(lootItem.IconBorder)
    Kill(lootItem.SpecRing)


    local qualityColor = nil
    local hyperlink = frame.hyperlink or (lootItem and lootItem.hyperlink)
    if hyperlink then
        local quality = C_Item.GetItemQualityByID(hyperlink)
        if quality and quality >= 1 then
            local r, g, b = GetItemQualityColor(quality)
            qualityColor = { r = r, g = g, b = b }
        end
    end

    StyleIcon(lootItem.Icon, frame, qualityColor)


    if not frame.preyBackdrop and lootItem.Icon.preyBorder then
        local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetThemeColors()

        local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        backdrop:SetFrameLevel(frame:GetFrameLevel())
        backdrop:SetPoint("TOPLEFT", lootItem.Icon.preyBorder, "TOPLEFT", -4, 4)
        backdrop:SetPoint("BOTTOMRIGHT", lootItem.Icon.preyBorder, "BOTTOMRIGHT", 180, -4)
        backdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        backdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        backdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        frame.preyBackdrop = backdrop
    end

    frame.preySkinned = true
end


local function SkinLootUpgradeAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    Kill(frame.Background)
    Kill(frame.Sheen)
    Kill(frame.BorderGlow)

    frame.Icon:SetTexCoord(unpack(ICON_TEX_COORDS))
    frame.Icon:SetDrawLayer("BORDER", 5)


    local qualityColor = nil
    local hyperlink = frame.hyperlink
    if hyperlink then
        local quality = C_Item.GetItemQualityByID(hyperlink)
        if quality and quality >= 1 then
            local r, g, b = GetItemQualityColor(quality)
            qualityColor = { r = r, g = g, b = b }
        end
    end

    CreateIconBorder(frame.Icon, frame, qualityColor)


    if not frame.preyBackdrop and frame.Icon.preyBorder then
        local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetThemeColors()

        local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        backdrop:SetFrameLevel(frame:GetFrameLevel())
        backdrop:SetPoint("TOPLEFT", frame.Icon.preyBorder, "TOPLEFT", -8, 8)
        backdrop:SetPoint("BOTTOMRIGHT", frame.Icon.preyBorder, "BOTTOMRIGHT", 180, -8)
        backdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        backdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        backdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        frame.preyBackdrop = backdrop
    end

    frame.preySkinned = true
end


local function SkinMoneyWonAlert(frame)
    if not frame or frame.preySkinned then return end

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetThemeColors()


    if frame.Background then frame.Background:SetAlpha(0) end
    if frame.IconBorder then frame.IconBorder:SetAlpha(0) end


    if frame.Icon then
        frame.Icon:SetTexCoord(unpack(ICON_TEX_COORDS))
    end


    if not frame.preyBackdrop then
        local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        backdrop:SetFrameLevel(frame:GetFrameLevel())
        backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
        backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
        backdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        backdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        backdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        frame.preyBackdrop = backdrop
    end

    frame.preySkinned = true
end


local function SkinHonorAwardedAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    Kill(frame.Background)
    Kill(frame.IconBorder)

    StyleIcon(frame.Icon, frame)

    if not frame.preyBackdrop and frame.Icon.preyBorder then
        local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetThemeColors()

        local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        backdrop:SetFrameLevel(frame:GetFrameLevel())
        backdrop:SetPoint("TOPLEFT", frame.Icon.preyBorder, "TOPLEFT", -4, 4)
        backdrop:SetPoint("BOTTOMRIGHT", frame.Icon.preyBorder, "BOTTOMRIGHT", 180, -4)
        backdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        backdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        backdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        frame.preyBackdrop = backdrop
    end

    frame.preySkinned = true
end


local function SkinNewRecipeLearnedAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    CreateAlertBackdrop(frame, 19, -6, -23, 6)

    Kill(frame.glow)
    Kill(frame.shine)


    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region:IsObjectType("Texture") then
            Kill(region)
            break
        end
    end

    if frame.Icon then
        frame.Icon:SetMask("")
        frame.Icon:SetTexCoord(unpack(ICON_TEX_COORDS))
        frame.Icon:SetDrawLayer("BORDER", 5)
        frame.Icon:ClearAllPoints()
        frame.Icon:SetPoint("LEFT", frame.preyBackdrop, 9, 0)

        CreateIconBorder(frame.Icon, frame)
    end

    frame.preySkinned = true
end


local function SkinDungeonCompletionAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    CreateAlertBackdrop(frame, -2, -6, -2, 6)

    if frame.glowFrame then
        Kill(frame.glowFrame)
        if frame.glowFrame.glow then Kill(frame.glowFrame.glow) end
    end

    Kill(frame.shine)
    Kill(frame.raidArt)
    Kill(frame.heroicIcon)
    Kill(frame.dungeonArt)
    Kill(frame.dungeonArt1)
    Kill(frame.dungeonArt2)
    Kill(frame.dungeonArt3)
    Kill(frame.dungeonArt4)

    if frame.dungeonTexture then
        frame.dungeonTexture:SetTexCoord(unpack(ICON_TEX_COORDS))
        frame.dungeonTexture:SetDrawLayer("OVERLAY")
        frame.dungeonTexture:ClearAllPoints()
        frame.dungeonTexture:SetPoint("LEFT", frame, 7, 0)

        CreateIconBorder(frame.dungeonTexture, frame)
    end

    frame.preySkinned = true
end


local function SkinScenarioAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    CreateAlertBackdrop(frame, 4, 4, -7, 6)


    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region:IsObjectType("Texture") then
            local atlas = region:GetAtlas()
            if atlas == "Toast-IconBG" or atlas == "Toast-Frame" then
                Kill(region)
            end
        end
    end

    Kill(frame.shine)
    Kill(frame.glowFrame)
    if frame.glowFrame then Kill(frame.glowFrame.glow) end

    if frame.dungeonTexture then
        frame.dungeonTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        frame.dungeonTexture:ClearAllPoints()
        frame.dungeonTexture:SetPoint("LEFT", frame.preyBackdrop, 9, 0)
        frame.dungeonTexture:SetDrawLayer("OVERLAY")

        CreateIconBorder(frame.dungeonTexture, frame)
    end

    frame.preySkinned = true
end


local function SkinWorldQuestCompleteAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    CreateAlertBackdrop(frame, 10, -6, -14, 6)

    Kill(frame.shine)
    Kill(frame.ToastBackground)

    if frame.QuestTexture then
        frame.QuestTexture:SetTexCoord(unpack(ICON_TEX_COORDS))
        frame.QuestTexture:SetDrawLayer("ARTWORK")

        CreateIconBorder(frame.QuestTexture, frame)
    end

    frame.preySkinned = true
end


local function SkinLegendaryItemAlert(frame, itemLink)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    Kill(frame.Background)
    Kill(frame.Background2)
    Kill(frame.Background3)
    Kill(frame.Ring1)
    Kill(frame.Particles3)
    Kill(frame.Particles2)
    Kill(frame.Particles1)
    Kill(frame.Starglow)
    Kill(frame.glow)
    Kill(frame.shine)

    CreateAlertBackdrop(frame, 20, -20, -20, 20)

    if frame.Icon then
        frame.Icon:SetTexCoord(unpack(ICON_TEX_COORDS))
        frame.Icon:SetDrawLayer("ARTWORK")

        local border = CreateIconBorder(frame.Icon, frame)


        if itemLink then
            local quality = C_Item.GetItemQualityByID(itemLink)
            if quality then
                local r, g, b = GetItemQualityColor(quality)
                border:SetBackdropBorderColor(r, g, b, 1)
            end
        end
    end

    frame.preySkinned = true
end


local function GetMiscAlertQuality(frame)


    return nil
end


local function SkinMiscAlert(frame)
    if not frame then return end


    local qualityColor = nil
    if frame.Icon then
        qualityColor = GetMiscAlertQuality(frame)

        CreateIconBorder(frame.Icon, frame, qualityColor)
    end


    if frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    Kill(frame.Background)
    Kill(frame.IconBorder)

    if frame.Icon then
        frame.Icon:SetMask("")
        frame.Icon:SetTexCoord(unpack(ICON_TEX_COORDS))
        frame.Icon:SetDrawLayer("BORDER", 5)

        CreateIconBorder(frame.Icon, frame, qualityColor)

        if not frame.preyBackdrop then
            local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetThemeColors()

            local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            backdrop:SetFrameLevel(frame:GetFrameLevel())
            backdrop:SetPoint("TOPLEFT", frame.Icon.preyBorder, "TOPLEFT", -8, 8)
            backdrop:SetPoint("BOTTOMRIGHT", frame.Icon.preyBorder, "BOTTOMRIGHT", 180, -8)
            backdrop:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            backdrop:SetBackdropColor(bgr, bgg, bgb, bga)
            backdrop:SetBackdropBorderColor(sr, sg, sb, sa)
            frame.preyBackdrop = backdrop
        end
    end

    frame.preySkinned = true
end


local function SkinEntitlementAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    CreateAlertBackdrop(frame, 10, -6, -14, 6)

    Kill(frame.Background)
    Kill(frame.StandardBackground)
    Kill(frame.glow)
    Kill(frame.shine)

    if frame.Icon then
        frame.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        frame.Icon:ClearAllPoints()
        frame.Icon:SetPoint("LEFT", frame.preyBackdrop, 9, 0)

        CreateIconBorder(frame.Icon, frame)
    end

    frame.preySkinned = true
end


local function SkinDigsiteCompleteAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    CreateAlertBackdrop(frame, -16, -6, 13, 6)

    Kill(frame.glow)
    Kill(frame.shine)


    local regions = { frame:GetRegions() }
    if regions[1] then Kill(regions[1]) end

    if frame.DigsiteTypeTexture then
        frame.DigsiteTypeTexture:SetPoint("LEFT", -10, -14)
    end

    frame.preySkinned = true
end


local function SkinGuildChallengeAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    CreateAlertBackdrop(frame, -2, -6, -2, 6)


    local region = select(2, frame:GetRegions())
    if region and region:IsObjectType("Texture") then
        if region:GetTexture() == [[Interface\GuildFrame\GuildChallenges]] then
            Kill(region)
        end
    end

    Kill(frame.glow)
    Kill(frame.shine)
    Kill(frame.EmblemBorder)

    if frame.EmblemIcon then
        CreateIconBorder(frame.EmblemIcon, frame)
        SetLargeGuildTabardTextures("player", frame.EmblemIcon)
    end

    frame.preySkinned = true
end


local function SkinInvasionAlert(frame)
    if not frame or frame.preySkinned then return end

    frame:SetAlpha(1)
    if not frame.preyHooked then
        hooksecurefunc(frame, "SetAlpha", ForceAlpha)
        frame.preyHooked = true
    end

    CreateAlertBackdrop(frame, 4, 4, -7, 6)


    if frame.GetRegions then
        local region, icon = frame:GetRegions()
        if region and region:IsObjectType("Texture") then
            if region:GetAtlas() == "legioninvasion-Toast-Frame" then
                Kill(region)
            end
        end

        if icon and icon:IsObjectType("Texture") then
            if icon:GetTexture() == 236293 then
                CreateIconBorder(icon, frame)
                icon:SetDrawLayer("OVERLAY")
                icon:SetTexCoord(unpack(ICON_TEX_COORDS))
            end
        end
    end

    frame.preySkinned = true
end


local function SkinBonusRollFrames()
    local db = GetAlertSettings()
    if not db.enabled then return end


    local moneyFrame = BonusRollMoneyWonFrame
    if moneyFrame and not moneyFrame.preySkinned then
        moneyFrame:SetAlpha(1)
        hooksecurefunc(moneyFrame, "SetAlpha", ForceAlpha)

        Kill(moneyFrame.Background)
        Kill(moneyFrame.IconBorder)

        StyleIcon(moneyFrame.Icon, moneyFrame)

        local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetThemeColors()
        local backdrop = CreateFrame("Frame", nil, moneyFrame, "BackdropTemplate")
        backdrop:SetFrameLevel(moneyFrame:GetFrameLevel())
        backdrop:SetPoint("TOPLEFT", moneyFrame.Icon.preyBorder, "TOPLEFT", -4, 4)
        backdrop:SetPoint("BOTTOMRIGHT", moneyFrame.Icon.preyBorder, "BOTTOMRIGHT", 180, -4)
        backdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        backdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        backdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        moneyFrame.preyBackdrop = backdrop
        moneyFrame.preySkinned = true
    end


    local lootFrame = BonusRollLootWonFrame
    if lootFrame and not lootFrame.preySkinned then
        lootFrame:SetAlpha(1)
        hooksecurefunc(lootFrame, "SetAlpha", ForceAlpha)

        Kill(lootFrame.Background)
        Kill(lootFrame.glow)
        Kill(lootFrame.shine)

        local lootItem = lootFrame.lootItem or lootFrame
        lootItem.Icon:SetTexCoord(unpack(ICON_TEX_COORDS))
        Kill(lootItem.IconBorder)

        local border = CreateIconBorder(lootItem.Icon, lootFrame)

        local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetThemeColors()
        local backdrop = CreateFrame("Frame", nil, lootFrame, "BackdropTemplate")
        backdrop:SetFrameLevel(lootFrame:GetFrameLevel())
        backdrop:SetPoint("TOPLEFT", border, "TOPLEFT", -4, 4)
        backdrop:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 180, -4)
        backdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        backdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        backdrop:SetBackdropBorderColor(sr, sg, sb, sa)
        lootFrame.preyBackdrop = backdrop
        lootFrame.preySkinned = true
    end
end


local alertHolder = nil
local alertMover = nil


local POSITION, ANCHOR_POINT, Y_OFFSET = "TOP", "BOTTOM", -5


local function AdjustQueuedAnchors(self, relativeAlert)


    if alertHolder and relativeAlert == AlertFrame then
        relativeAlert = alertHolder
    end
    for alert in self.alertFramePool:EnumerateActive() do
        alert:ClearAllPoints()
        alert:SetPoint(POSITION, relativeAlert, ANCHOR_POINT, 0, Y_OFFSET)
        relativeAlert = alert
    end
    return relativeAlert
end


local function AdjustSimpleAnchors(self, relativeAlert)

    if alertHolder and relativeAlert == AlertFrame then
        relativeAlert = alertHolder
    end
    local alert = self.alertFrame
    if alert:IsShown() then
        alert:ClearAllPoints()
        alert:SetPoint(POSITION, relativeAlert, ANCHOR_POINT, 0, Y_OFFSET)
        return alert
    end
    return relativeAlert
end


local function AdjustAnchorFrameAnchors(self, relativeAnchor)

    if alertHolder and relativeAnchor == AlertFrame then
        relativeAnchor = alertHolder
    end
    local anchor = self.anchorFrame
    if anchor:IsShown() then
        anchor:ClearAllPoints()
        anchor:SetPoint(POSITION, relativeAnchor, ANCHOR_POINT, 0, Y_OFFSET)
        return anchor
    end
    return relativeAnchor
end


local function IsTalkingHeadSubSystem(alertFrameSubSystem)
    if alertFrameSubSystem.anchorFrame == TalkingHeadFrame then return true end
    if alertFrameSubSystem.alertFrame == TalkingHeadFrame then return true end
    local frame = alertFrameSubSystem.anchorFrame or alertFrameSubSystem.alertFrame
    if frame and frame:GetName() and frame:GetName():find("TalkingHead") then return true end
    return false
end


local function ReplaceSubSystemAnchors(alertFrameSubSystem)

    if IsTalkingHeadSubSystem(alertFrameSubSystem) then return end

    if alertFrameSubSystem.alertFramePool then

        alertFrameSubSystem.AdjustAnchors = AdjustQueuedAnchors
    elseif not alertFrameSubSystem.anchorFrame then

        alertFrameSubSystem.AdjustAnchors = AdjustSimpleAnchors
    else

        alertFrameSubSystem.AdjustAnchors = AdjustAnchorFrameAnchors
    end
end


local function PostAlertMove()
    if not alertHolder then return end

    AlertFrame:ClearAllPoints()
    AlertFrame:SetAllPoints(alertHolder)

    if GroupLootContainer then
        GroupLootContainer:ClearAllPoints()
        GroupLootContainer:SetPoint(POSITION, alertHolder, ANCHOR_POINT, 0, Y_OFFSET)
    end
end

local function CreateAlertMover()
    local db = GetAlertSettings()
    if not db.enabled then return end


    if not alertHolder then
        alertHolder = CreateFrame("Frame", "PREY_AlertFrameHolder", UIParent)
        alertHolder:SetSize(180, 20)

        local pos = db.alertPosition
        if pos and pos.point then
            alertHolder:SetPoint(pos.point, UIParent, pos.relPoint or "TOP", pos.x or 0, pos.y or -20)
        else
            alertHolder:SetPoint("TOP", UIParent, "TOP", 0, -20)
        end
        alertHolder:SetMovable(true)
        alertHolder:SetClampedToScreen(true)


        alertMover = CreateFrame("Frame", "PREY_AlertFrameMover", alertHolder, "BackdropTemplate")
        alertMover:SetAllPoints(alertHolder)
        alertMover:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        alertMover:SetBackdropColor(0.2, 0.8, 0.8, 0.5)
        alertMover:SetBackdropBorderColor(0.2, 0.8, 0.8, 1)
        alertMover:EnableMouse(true)
        alertMover:SetMovable(true)
        alertMover:RegisterForDrag("LeftButton")
        alertMover:SetFrameStrata("FULLSCREEN_DIALOG")
        alertMover:Hide()


        local text = alertMover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText("Alert Frames")
        alertMover.text = text


        alertMover:SetScript("OnDragStart", function(self)
            alertHolder:StartMoving()
        end)

        alertMover:SetScript("OnDragStop", function(self)
            alertHolder:StopMovingOrSizing()

            local point, _, relPoint, x, y = alertHolder:GetPoint()
            local alertDB = GetAlertSettings()
            alertDB.alertPosition = { point = point, relPoint = relPoint, x = x, y = y }
        end)
    end


    for _, alertFrameSubSystem in ipairs(AlertFrame.alertFrameSubSystems) do
        ReplaceSubSystemAnchors(alertFrameSubSystem)
    end


    hooksecurefunc(AlertFrame, "AddAlertFrameSubSystem", function(_, alertFrameSubSystem)
        ReplaceSubSystemAnchors(alertFrameSubSystem)
    end)


    hooksecurefunc(AlertFrame, "UpdateAnchors", PostAlertMove)


    if GroupLootContainer then
        GroupLootContainer:EnableMouse(false)
        GroupLootContainer.ignoreInLayout = true
    end


    if WorldQuestCompleteAlertSystem and LootAlertSystem then
        AlertFrame:SetSubSystemAnchorPriority(WorldQuestCompleteAlertSystem, 100)
        AlertFrame:SetSubSystemAnchorPriority(LootAlertSystem, 200)
    end
end


local toastHolder = nil
local toastMover = nil

local function CreateEventToastMover()
    local db = GetAlertSettings()
    if not db.enabled then return end
    if not EventToastManagerFrame then return end


    if not toastHolder then
        toastHolder = CreateFrame("Frame", "PREY_EventToastHolder", UIParent)
        toastHolder:SetSize(300, 20)

        local pos = db.toastPosition
        if pos and pos.point then
            toastHolder:SetPoint(pos.point, UIParent, pos.relPoint or "TOP", pos.x or 0, pos.y or -150)
        else
            toastHolder:SetPoint("TOP", UIParent, "TOP", 0, -150)
        end
        toastHolder:SetMovable(true)
        toastHolder:SetClampedToScreen(true)


        toastMover = CreateFrame("Frame", "PREY_EventToastMover", toastHolder, "BackdropTemplate")
        toastMover:SetAllPoints(toastHolder)
        toastMover:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        toastMover:SetBackdropColor(0.8, 0.6, 0.2, 0.5)
        toastMover:SetBackdropBorderColor(0.8, 0.6, 0.2, 1)
        toastMover:EnableMouse(true)
        toastMover:SetMovable(true)
        toastMover:RegisterForDrag("LeftButton")
        toastMover:SetFrameStrata("FULLSCREEN_DIALOG")
        toastMover:Hide()


        local text = toastMover:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText("Event Toasts")
        toastMover.text = text


        toastMover:SetScript("OnDragStart", function(self)
            toastHolder:StartMoving()
        end)

        toastMover:SetScript("OnDragStop", function(self)
            toastHolder:StopMovingOrSizing()

            local point, _, relPoint, x, y = toastHolder:GetPoint()
            local alertDB = GetAlertSettings()
            alertDB.toastPosition = { point = point, relPoint = relPoint, x = x, y = y }

            EventToastManagerFrame:ClearAllPoints()
            EventToastManagerFrame:SetPoint("TOP", toastHolder, "TOP")
        end)
    end


    hooksecurefunc(EventToastManagerFrame, "UpdateAnchor", function(self)
        self:ClearAllPoints()
        self:SetPoint("TOP", toastHolder, "TOP")
    end)


    EventToastManagerFrame:ClearAllPoints()
    EventToastManagerFrame:SetPoint("TOP", toastHolder, "TOP")
end


function Alerts:ShowMovers()
    if alertMover then alertMover:Show() end
    if toastMover then toastMover:Show() end
end

function Alerts:HideMovers()
    if alertMover then alertMover:Hide() end
    if toastMover then toastMover:Hide() end
end

function Alerts:ToggleMovers()
    local isShown = (alertMover and alertMover:IsShown()) or (toastMover and toastMover:IsShown())
    if isShown then
        self:HideMovers()
    else
        self:ShowMovers()
    end
end


local function RefreshAlertColors()

    local sr, sg, sb, sa, bgr, bgg, bgb, bga = GetThemeColors()


    local alertSystems = {
        AchievementAlertSystem,
        CriteriaAlertSystem,
        MonthlyActivityAlertSystem,
        DungeonCompletionAlertSystem,
        GuildChallengeAlertSystem,
        InvasionAlertSystem,
        ScenarioAlertSystem,
        WorldQuestCompleteAlertSystem,
        HonorAwardedAlertSystem,
        LegendaryItemAlertSystem,
        LootAlertSystem,
        LootUpgradeAlertSystem,
        MoneyWonAlertSystem,
        EntitlementDeliveredAlertSystem,
        RafRewardDeliveredAlertSystem,
        DigsiteCompleteAlertSystem,
        NewRecipeLearnedAlertSystem,
        NewPetAlertSystem,
        NewMountAlertSystem,
        NewToyAlertSystem,
        NewCosmeticAlertFrameSystem,
        NewWarbandSceneAlertSystem,
    }

    for _, system in ipairs(alertSystems) do
        if system and system.alertFramePool then
            for frame in system.alertFramePool:EnumerateActive() do
                if frame.preyBackdrop then
                    frame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
                    frame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
                end

                if frame.Icon and frame.Icon.preyBorder then
                    frame.Icon.preyBorder:SetBackdropBorderColor(sr, sg, sb, sa)
                end
            end
        end
    end


    if BonusRollMoneyWonFrame and BonusRollMoneyWonFrame.preyBackdrop then
        BonusRollMoneyWonFrame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        BonusRollMoneyWonFrame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end
    if BonusRollLootWonFrame and BonusRollLootWonFrame.preyBackdrop then
        BonusRollLootWonFrame.preyBackdrop:SetBackdropColor(bgr, bgg, bgb, bga)
        BonusRollLootWonFrame.preyBackdrop:SetBackdropBorderColor(sr, sg, sb, sa)
    end
end


_G.PreyUI_RefreshAlertColors = RefreshAlertColors


function Alerts:HookAlertSystems()
    local db = GetAlertSettings()
    if not db.enabled then return end


    if AchievementAlertSystem then
        hooksecurefunc(AchievementAlertSystem, "setUpFunction", SkinAchievementAlert)
    end
    if CriteriaAlertSystem then
        hooksecurefunc(CriteriaAlertSystem, "setUpFunction", SkinCriteriaAlert)
    end
    if MonthlyActivityAlertSystem then
        hooksecurefunc(MonthlyActivityAlertSystem, "setUpFunction", SkinCriteriaAlert)
    end


    if DungeonCompletionAlertSystem then
        hooksecurefunc(DungeonCompletionAlertSystem, "setUpFunction", SkinDungeonCompletionAlert)
    end
    if GuildChallengeAlertSystem then
        hooksecurefunc(GuildChallengeAlertSystem, "setUpFunction", SkinGuildChallengeAlert)
    end
    if InvasionAlertSystem then
        hooksecurefunc(InvasionAlertSystem, "setUpFunction", SkinInvasionAlert)
    end
    if ScenarioAlertSystem then
        hooksecurefunc(ScenarioAlertSystem, "setUpFunction", SkinScenarioAlert)
    end
    if WorldQuestCompleteAlertSystem then
        hooksecurefunc(WorldQuestCompleteAlertSystem, "setUpFunction", SkinWorldQuestCompleteAlert)
    end


    if HonorAwardedAlertSystem then
        hooksecurefunc(HonorAwardedAlertSystem, "setUpFunction", SkinHonorAwardedAlert)
    end


    if LegendaryItemAlertSystem then
        hooksecurefunc(LegendaryItemAlertSystem, "setUpFunction", SkinLegendaryItemAlert)
    end
    if LootAlertSystem then
        hooksecurefunc(LootAlertSystem, "setUpFunction", SkinLootWonAlert)
    end
    if LootUpgradeAlertSystem then
        hooksecurefunc(LootUpgradeAlertSystem, "setUpFunction", SkinLootUpgradeAlert)
    end
    if MoneyWonAlertSystem then
        hooksecurefunc(MoneyWonAlertSystem, "setUpFunction", SkinMoneyWonAlert)
    end
    if EntitlementDeliveredAlertSystem then
        hooksecurefunc(EntitlementDeliveredAlertSystem, "setUpFunction", SkinEntitlementAlert)
    end
    if RafRewardDeliveredAlertSystem then
        hooksecurefunc(RafRewardDeliveredAlertSystem, "setUpFunction", SkinEntitlementAlert)
    end


    if DigsiteCompleteAlertSystem then
        hooksecurefunc(DigsiteCompleteAlertSystem, "setUpFunction", SkinDigsiteCompleteAlert)
    end
    if NewRecipeLearnedAlertSystem then
        hooksecurefunc(NewRecipeLearnedAlertSystem, "setUpFunction", SkinNewRecipeLearnedAlert)
    end


    if NewPetAlertSystem then
        hooksecurefunc(NewPetAlertSystem, "setUpFunction", SkinMiscAlert)
    end
    if NewMountAlertSystem then
        hooksecurefunc(NewMountAlertSystem, "setUpFunction", SkinMiscAlert)
    end
    if NewToyAlertSystem then
        hooksecurefunc(NewToyAlertSystem, "setUpFunction", SkinMiscAlert)
    end
    if NewCosmeticAlertFrameSystem then
        hooksecurefunc(NewCosmeticAlertFrameSystem, "setUpFunction", SkinMiscAlert)
    end
    if NewWarbandSceneAlertSystem then
        hooksecurefunc(NewWarbandSceneAlertSystem, "setUpFunction", SkinMiscAlert)
    end


    SkinBonusRollFrames()
end

function Alerts:Initialize()
    local db = GetAlertSettings()
    if not db.enabled then return end


    self:HookAlertSystems()


    CreateAlertMover()
    CreateEventToastMover()
end
