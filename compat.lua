-- PreyUI Compatibility Layer
-- Shims for WoW APIs removed or namespaced between versions.
-- Only define a global if Blizzard no longer provides it AND the C_* replacement exists.
-- Load order: this file runs before all addon modules.

-------------------------------------------------------------------------------
-- Spell API (removed in ~10.0, confirmed gone in 12.x)
-------------------------------------------------------------------------------

if not GetSpellInfo and C_Spell and C_Spell.GetSpellInfo then
    function GetSpellInfo(spellID)
        if not spellID then return nil end
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            return info.name, nil, info.iconID, info.castTime,
                   info.minRange, info.maxRange, info.spellID, info.originalIconID
        end
    end
end

if not GetSpellCooldown and C_Spell and C_Spell.GetSpellCooldown then
    function GetSpellCooldown(spellID)
        if not spellID then return nil end
        local cd = C_Spell.GetSpellCooldown(spellID)
        if cd then
            return cd.startTime or 0, cd.duration or 0,
                   cd.isEnabled and 1 or 0, cd.modRate
        end
        return 0, 0, 0, 1
    end
end

if not GetSpellCharges and C_Spell and C_Spell.GetSpellCharges then
    function GetSpellCharges(spellID)
        if not spellID then return nil end
        local info = C_Spell.GetSpellCharges(spellID)
        if info then
            return info.currentCharges, info.maxCharges,
                   info.cooldownStartTime, info.cooldownDuration, info.chargeModRate
        end
    end
end

if not GetSpellTexture and C_Spell and C_Spell.GetSpellTexture then
    function GetSpellTexture(spellID)
        return C_Spell.GetSpellTexture(spellID)
    end
end

if not IsSpellOverlayed and C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed then
    IsSpellOverlayed = C_SpellActivationOverlay.IsSpellOverlayed
end

-------------------------------------------------------------------------------
-- SpellBook API (removed in ~10.0, confirmed gone in 12.x)
-------------------------------------------------------------------------------

if not GetNumSpellTabs and C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
    function GetNumSpellTabs()
        return C_SpellBook.GetNumSpellBookSkillLines()
    end
end

if not GetSpellTabInfo and C_SpellBook and C_SpellBook.GetSpellBookSkillLineInfo then
    function GetSpellTabInfo(tabLine)
        if not tabLine then return nil end
        local info = C_SpellBook.GetSpellBookSkillLineInfo(tabLine)
        if info then
            return info.name, info.iconID, info.itemIndexOffset,
                   info.numSpellBookItems, info.isGuild, info.specID
        end
    end
end

if not GetSpellBookItemName and C_SpellBook and C_SpellBook.GetSpellBookItemName then
    function GetSpellBookItemName(index, spellBank)
        return C_SpellBook.GetSpellBookItemName(index, spellBank)
    end
end

-------------------------------------------------------------------------------
-- Item API (deprecated in 10.x, may be gone in 12.x)
-- C_Item.GetItemInfo has an identical multi-value return signature.
-------------------------------------------------------------------------------

if not GetItemInfo and C_Item and C_Item.GetItemInfo then
    GetItemInfo = C_Item.GetItemInfo
end

if not GetItemInfoInstant and C_Item and C_Item.GetItemInfoInstant then
    GetItemInfoInstant = C_Item.GetItemInfoInstant
end

-------------------------------------------------------------------------------
-- CVar API (deprecated in 10.x, may be gone in 12.x)
-- C_CVar equivalents have identical signatures.
-------------------------------------------------------------------------------

if not SetCVar and C_CVar and C_CVar.SetCVar then
    SetCVar = C_CVar.SetCVar
end

if not GetCVar and C_CVar and C_CVar.GetCVar then
    GetCVar = C_CVar.GetCVar
end

if not GetCVarBool and C_CVar and C_CVar.GetCVarBool then
    GetCVarBool = C_CVar.GetCVarBool
end

-------------------------------------------------------------------------------
-- Loot API (may move to C_Loot namespace in 12.x)
-------------------------------------------------------------------------------

if not GetNumLootItems and C_Loot and C_Loot.GetNumLootItems then
    GetNumLootItems = C_Loot.GetNumLootItems
end

if not LootSlotHasItem and C_Loot and C_Loot.LootSlotHasItem then
    LootSlotHasItem = C_Loot.LootSlotHasItem
end

if not LootSlot and C_Loot and C_Loot.LootSlot then
    LootSlot = C_Loot.LootSlot
end

-------------------------------------------------------------------------------
-- Quest API (may move to C_QuestOffer in 12.x)
-------------------------------------------------------------------------------

if not AcceptQuest and C_QuestOffer and C_QuestOffer.AcceptQuest then
    AcceptQuest = C_QuestOffer.AcceptQuest
end

if not GetQuestReward and C_QuestOffer and C_QuestOffer.GetQuestReward then
    GetQuestReward = C_QuestOffer.GetQuestReward
end

if not GetNumQuestChoices and C_QuestOffer and C_QuestOffer.GetNumQuestChoices then
    GetNumQuestChoices = C_QuestOffer.GetNumQuestChoices
end
