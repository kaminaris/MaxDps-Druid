local _, addonTable = ...
local Druid = addonTable.Druid
local MaxDps = _G.MaxDps
if not MaxDps then return end
local setSpell

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local UnitAuraByName = C_UnitAuras.GetAuraDataBySpellName
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCount = C_Spell.GetSpellCastCount

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local DemonicFuryPT = Enum.PowerType.DemonicFury
local BurningEmbersPT = Enum.PowerType.BurningEmbers
local LunarPowerPT = Enum.PowerType.LunarPower
local HolyPowerPT = Enum.PowerType.HolyPower
local MaelstromPT = Enum.PowerType.Maelstrom
local ChiPT = Enum.PowerType.Chi
local InsanityPT = Enum.PowerType.Insanity
local ArcaneChargesPT = Enum.PowerType.ArcaneCharges
local FuryPT = Enum.PowerType.Fury
local PainPT = Enum.PowerType.Pain
local EssencePT = Enum.PowerType.Essence
local RuneBloodPT = Enum.PowerType.RuneBlood
local RuneFrostPT = Enum.PowerType.RuneFrost
local RuneUnholyPT = Enum.PowerType.RuneUnholy

local fd
local ttd
local timeShift
local gcd
local cooldown
local buff
local debuff
local talents
local targets
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc
local timeInCombat
local className, classFilename, classId = UnitClass('player')
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local LunarPower
local LunarPowerMax
local LunarPowerDeficit
local Energy
local EnergyMax
local EnergyDeficit
local EnergyRegen
local EnergyTimeToMax
local ComboPoints
local ComboPointsMax
local ComboPointsDeficit
local Mana
local ManaMax
local ManaDeficit
local Rage
local RageMax
local RageDeficit
local EnergyPerc

local Feral = {}

function Feral:precombat()
    if (MaxDps:CheckSpellUsable(classtable.MarkoftheWild, 'MarkoftheWild')) and (not buff[classtable.MarkoftheWildBuff].up) and cooldown[classtable.MarkoftheWild].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MarkoftheWild end
    end
    if (MaxDps:CheckSpellUsable(classtable.CatForm, 'CatForm')) and (not buff[classtable.CatFormBuff].up) and cooldown[classtable.CatForm].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.CatForm end
    end
    if (MaxDps:CheckSpellUsable(classtable.SavageRoar, 'SavageRoar')) and cooldown[classtable.SavageRoar].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.SavageRoar end
    end
    --if (MaxDps:CheckSpellUsable(classtable.TolvirPotion, 'TolvirPotion')) and cooldown[classtable.TolvirPotion].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.TolvirPotion end
    --end
    if (MaxDps:CheckSpellUsable(classtable.Treants, 'Treants')) and ((talents[classtable.ForceofNature] and true or false)) and cooldown[classtable.Treants].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Treants end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.TigersFury, false)
    MaxDps:GlowCooldown(classtable.Incarnation, false)
    MaxDps:GlowCooldown(classtable.SkullBashCat, false)
    MaxDps:GlowCooldown(classtable.Berserk, false)
end

local buffedRip =  false
local buffedRake = false
local BuffedThrash = false

function Feral:single()
    if (MaxDps:CheckSpellUsable(classtable.SkullBashCat, 'SkullBashCat')) and cooldown[classtable.SkullBashCat].ready then
        MaxDps:GlowCooldown(classtable.SkullBashCat, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    -- Savage Roar
    if MaxDps:CheckSpellUsable(classtable.SavageRoar, 'SavageRoar') and
       (not buff[classtable.SavageRoarBuff].up or buff[classtable.SavageRoarBuff].remains <= 1) and
       cooldown[classtable.SavageRoar].ready then
        if not setSpell then setSpell = classtable.SavageRoar end
    end
    -- Tiger's Fury
    if MaxDps:CheckSpellUsable(classtable.TigersFury, 'TigersFury') and
       Energy <= 35 and
       cooldown[classtable.TigersFury].ready then
        MaxDps:GlowCooldown(classtable.TigersFury, true)
    end
    -- Berserk
    if MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk') and
       (Energy >= 90 or buff[classtable.TigersFuryBuff].up) and
       cooldown[classtable.Berserk].ready then
        MaxDps:GlowCooldown(classtable.Berserk, true)
    end
    -- Ferocious Bite (execute)
    if MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite') and
       targethealthPerc < 25 and
       debuff[classtable.RipDeBuff].up and
       ComboPoints >= 5 and
       cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    -- Rip
    if MaxDps:CheckSpellUsable(classtable.Rip, 'Rip') and
       ComboPoints == 5 and
       (not debuff[classtable.RipDeBuff].up or debuff[classtable.RipDeBuff].remains < 2) or
       (ComboPoints == 5 and (buff[classtable.TigersFuryBuff].up or buff[classtable.SavageRoarBuff].up) and ( bleeds and bleeds[UnitGUID("target")] and not bleeds[UnitGUID("target")].rip.tigersFury and not bleeds[UnitGUID("target")].rip.savageRoar )) and
       cooldown[classtable.Rip].ready then
        if not setSpell then setSpell = classtable.Rip end
    end
    -- Rake
    if MaxDps:CheckSpellUsable(classtable.Rake, 'Rake') and
       (not debuff[classtable.RakeDeBuff].up or debuff[classtable.RakeDeBuff].remains < 3) or
       ( (buff[classtable.TigersFuryBuff].up or buff[classtable.SavageRoarBuff].up) and ( bleeds and bleeds[UnitGUID("target")] and not bleeds[UnitGUID("target")].rake.tigersFury and not bleeds[UnitGUID("target")].rake.savageRoar )) and
       cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    -- Thrash (Clearcasting / dot refresh logic)
    if MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat') and
       (not debuff[classtable.ThrashCatDeBuff].up or debuff[classtable.ThrashCatDeBuff].remains < 3) or
       ( (buff[classtable.TigersFuryBuff].up or buff[classtable.SavageRoarBuff].up) and ( bleeds and bleeds[UnitGUID("target")] and not bleeds[UnitGUID("target")].thrash.tigersFury and not bleeds[UnitGUID("target")].thrash.savageRoar )) and
       (buff[classtable.OmenofClarityBuff].up or Energy >= 50) and
       cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end
    -- Shred (Clearcasting or Berserk)
    if MaxDps:CheckSpellUsable(classtable.Shred, 'Shred') and
       (not UnitThreatSituation("player", "target") or UnitThreatSituation("player", "target") <= 1) and
       (buff[classtable.OmenofClarityBuff].up or buff[classtable.BerserkBuff].up) and
       cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    -- Ferocious Bite
    if MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite') and
       ComboPoints >= 5 and
       cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    -- Mangle (Fallback generator to avoid energy cap)
    if MaxDps:CheckSpellUsable(classtable.Mangle, 'Mangle') and
       cooldown[classtable.Mangle].ready then
        if not setSpell then setSpell = classtable.Mangle end
    end
end

function Feral:aoe()
    -- Force of Nature
    if (MaxDps:CheckSpellUsable(classtable.Treants, 'Treants')) and ((talents[classtable.ForceofNature] and true or false)) and cooldown[classtable.Treants].ready then
        if not setSpell then setSpell = classtable.Treants end
    end

    -- Savage Roar
    if (MaxDps:CheckSpellUsable(classtable.SavageRoar, 'SavageRoar')) and (buff[classtable.SavageRoarBuff].remains <= 1 or not buff[classtable.SavageRoarBuff].up) and cooldown[classtable.SavageRoar].ready then
        if not setSpell then setSpell = classtable.SavageRoar end
    end

    -- Tiger's Fury
    if (MaxDps:CheckSpellUsable(classtable.TigersFury, 'TigersFury')) and (Energy <= 35) and cooldown[classtable.TigersFury].ready then
        MaxDps:GlowCooldown(classtable.TigersFury, cooldown[classtable.TigersFury].ready)
    end

    -- Berserk
    if (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and (Energy >= 90 or buff[classtable.TigersFuryBuff].up) and cooldown[classtable.Berserk].ready then
        MaxDps:GlowCooldown(classtable.Berserk, cooldown[classtable.Berserk].ready)
    end

    -- Thrash
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (debuff[classtable.ThrashCatDeBuff].remains < 3) and cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end

    -- Rip
    if (MaxDps:CheckSpellUsable(classtable.Rip, 'Rip')) and (ComboPoints == 5 and targets < 4 and (debuff[classtable.RipDeBuff].remains < 3 or not debuff[classtable.RipDeBuff].up)) and cooldown[classtable.Rip].ready then
        if not setSpell then setSpell = classtable.Rip end
    end

    -- Rake
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (targets <= 4 and (debuff[classtable.RakeDeBuff].remains < 2 or not debuff[classtable.RakeDeBuff].up)) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end

    -- Swipe
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (targets >= 4) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
end

function Feral:callaction()
    if targets >= 3 then
        Feral:aoe()
    end
    Feral:single()
end

function Druid:Feral()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    Energy = UnitPower('player', EnergyPT)
    EnergyMax = UnitPowerMax('player', EnergyPT)
    EnergyDeficit = EnergyMax - Energy
    EnergyRegen = GetPowerRegenForPowerType(Enum.PowerType.Energy)
    EnergyTimeToMax = EnergyDeficit / EnergyRegen
    EnergyPerc = (Energy / EnergyMax) * 100
    ComboPoints = GetComboPoints("player", "target")
    ComboPointsMax = 5
    ComboPointsDeficit = ComboPointsMax - ComboPoints
    classtable.Incarnation =  classtable.IncarnationAvatarofAshamane
    classtable.MoonfireCat =  classtable.Moonfire
    classtable.ThrashCat =  classtable.Thrash
    classtable.SwipeCat =  classtable.Swipe
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    local function debugg()
        talents[classtable.ForceofNature] = 1
        talents[classtable.Incarnation] = 1
    end

    classtable.CatFormBuff = 768
    classtable.MarkoftheWildBuff = 1126
    classtable.Treants = 1006737
    classtable.SkullBashCat = 80965
    classtable.Incarnation = 106731

    classtable.SavageRoarBuff = MaxDps:HasGlyphEnabled(127540) and 127538 or 52610
    classtable.OmenofClarityBuff = 135700
    classtable.TigersFuryBuff = 5217
    classtable.BerserkBuff = 106951
    classtable.WeakenedArmorDeBuff = 113746
    classtable.RipDeBuff = 1079
    classtable.RakeDeBuff = 1822
    classtable.ThrashCatDeBuff = 106830

    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Feral:precombat()

    Feral:callaction()
    if setSpell then return setSpell end
end

local bleedTracker = CreateFrame("Frame")
bleedTracker:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
local bleeds = {}  -- [targetGUID] = { rip = {}, rake = {}, thrash = {} }

bleedTracker:SetScript("OnEvent", function(self, event)
    if not classtable then return end
    local timestamp, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId = CombatLogGetCurrentEventInfo()

    if sourceGUID ~= UnitGUID("player") then return end

    -- Check if we cast a bleed
    if subEvent == "SPELL_CAST_SUCCESS" then
        local tigersFuryUp = AuraUtil.FindAuraByName("Tiger's Fury", "player")
        local savageRoarUp = AuraUtil.FindAuraByName("Savage Roar", "player")

        if spellId == classtable.Rip then
            bleeds[destGUID] = bleeds[destGUID] or {}
            bleeds[destGUID].rip = {
                tigersFury = buff[classtable.TigersFuryBuff].up,
                savageRoar = buff[classtable.SavageRoarBuff].up,
            }
        elseif spellId == classtable.Rake then
            bleeds[destGUID] = bleeds[destGUID] or {}
            bleeds[destGUID].rake = {
                tigersFury = buff[classtable.TigersFuryBuff].up,
                savageRoar = buff[classtable.SavageRoarBuff].up,
            }
        elseif spellId == classtable.ThrashCat then
            bleeds[destGUID] = bleeds[destGUID] or {}
            bleeds[destGUID].thrash = {
                tigersFury = buff[classtable.TigersFuryBuff].up,
                savageRoar = buff[classtable.SavageRoarBuff].up,
            }
        end
    end
end)

