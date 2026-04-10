if not GetSpellInfo and C_Spell and C_Spell.GetSpellInfo then
    function GetSpellInfo(spellID)
        if not spellID then
            return nil
        end

        local spellInfo = C_Spell.GetSpellInfo(spellID)
        if spellInfo then
            return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
        end
    end
end

if not GetSpellCooldown and C_Spell and C_Spell.GetSpellCooldown then
    function GetSpellCooldown(spellID)
        if not spellID then
            return nil
        end

        local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
        if cooldownInfo then
            return cooldownInfo.startTime or cooldownInfo.start or 0, cooldownInfo.duration or 0, cooldownInfo.isEnabled and 1 or 0, cooldownInfo.modRate
        end

        return 0, 0, 0, 1
    end
end

if not GetSpellCharges and C_Spell and C_Spell.GetSpellCharges then
    function GetSpellCharges(spellID)
        if not spellID then
            return nil
        end

        local chargeInfo = C_Spell.GetSpellCharges(spellID)
        if chargeInfo then
            return chargeInfo.currentCharges, chargeInfo.maxCharges, chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration, chargeInfo.chargeModRate
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

if not GetNumSpellTabs and C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
    function GetNumSpellTabs()
        return C_SpellBook.GetNumSpellBookSkillLines()
    end
end

if not GetSpellTabInfo and C_SpellBook and C_SpellBook.GetSpellBookSkillLineInfo then
    function GetSpellTabInfo(tabLine)
        if not tabLine then
            return nil
        end

        local skillLine = C_SpellBook.GetSpellBookSkillLineInfo(tabLine)
        if skillLine then
            return skillLine.name, skillLine.iconID, skillLine.itemIndexOffset, skillLine.numSpellBookItems, skillLine.isGuild, skillLine.specID
        end
    end
end

if not GetSpellBookItemName and C_SpellBook and C_SpellBook.GetSpellBookItemName then
    function GetSpellBookItemName(index, spellBank)
        return C_SpellBook.GetSpellBookItemName(index, spellBank)
    end
end
