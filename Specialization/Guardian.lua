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
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
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

local Guardian = {}

local if_build
local ripweaving
function Guardian:precombat()
    if (MaxDps:CheckSpellUsable(classtable.MarkoftheWild, 'MarkoftheWild')) and not buff[classtable.MarkoftheWild].up and cooldown[classtable.MarkoftheWild].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MarkoftheWild end
    end
    if talents[classtable.ThornsofIron] and talents[classtable.ReinforcedFur] then
        if_build = 1
    else
        if_build = 0
    end
    if talents[classtable.PrimalFury] and talents[classtable.FluidForm] and talents[classtable.WildpowerSurge] then
        ripweaving = 1
    else
        ripweaving = 0
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartoftheWild, 'HeartoftheWild')) and (talents[classtable.HeartoftheWild] and not talents[classtable.Rip]) and cooldown[classtable.HeartoftheWild].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.HeartoftheWild, cooldown[classtable.HeartoftheWild].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BearForm, 'BearForm')) and not buff[classtable.BearFormBuff].up and (not talents[classtable.FluidForm]) and cooldown[classtable.BearForm].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BearForm end
    end
end
function Guardian:bear()
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and (buff[classtable.RavageBuff].up and targets >1) and cooldown[classtable.Maul].ready then
        if not setSpell then setSpell = classtable.Maul end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartoftheWild, 'HeartoftheWild')) and (( talents[classtable.HeartoftheWild] and not talents[classtable.Rip] ) or talents[classtable.HeartoftheWild] and buff[classtable.FelinePotentialCounterBuff].count == 6 and targets <3) and cooldown[classtable.HeartoftheWild].ready then
        MaxDps:GlowCooldown(classtable.HeartoftheWild, cooldown[classtable.HeartoftheWild].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (buff[classtable.BearFormBuff].up and ( ( ( not debuff[classtable.MoonfireDeBuff].up and ttd >12 ) or ( debuff[classtable.MoonfireDeBuff].refreshable and ttd >12 ) ) and targets <7 and talents[classtable.FuryofNature] ) or ( ( ( not debuff[classtable.MoonfireDeBuff].up and ttd >12 ) or ( debuff[classtable.MoonfireDeBuff].refreshable and ttd >12 ) ) and targets <4 and not talents[classtable.FuryofNature] )) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashBear, 'ThrashBear')) and (debuff[classtable.ThrashBearDeBuff].refreshable or ( debuff[classtable.ThrashBearDeBuff].count <5 and (talents[classtable.FlashingClaws] and talents[classtable.FlashingClaws] or 0) == 2 or debuff[classtable.ThrashBearDeBuff].count <4 and (talents[classtable.FlashingClaws] and talents[classtable.FlashingClaws] or 0) == 1 or debuff[classtable.ThrashBearDeBuff].count <3 and not talents[classtable.FlashingClaws] )) and cooldown[classtable.ThrashBear].ready then
        if not setSpell then setSpell = classtable.ThrashBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.BristlingFur, 'BristlingFur')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and cooldown[classtable.RageoftheSleeper].remains >8) and cooldown[classtable.BristlingFur].ready then
        if not setSpell then setSpell = classtable.BristlingFur end
    end
    if (MaxDps:CheckSpellUsable(classtable.Barkskin, 'Barkskin')) and (buff[classtable.BearFormBuff].up) and cooldown[classtable.Barkskin].ready then
        MaxDps:GlowCooldown(classtable.Barkskin, cooldown[classtable.Barkskin].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.LunarBeam, 'LunarBeam')) and cooldown[classtable.LunarBeam].ready then
        MaxDps:GlowCooldown(classtable.LunarBeam, cooldown[classtable.LunarBeam].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ConvoketheSpirits, 'ConvoketheSpirits')) and (( talents[classtable.WildpowerSurge] and buff[classtable.CatFormBuff].up and buff[classtable.FelinePotentialBuff].up ) or not talents[classtable.WildpowerSurge]) and cooldown[classtable.ConvoketheSpirits].ready then
        MaxDps:GlowCooldown(classtable.ConvoketheSpirits, cooldown[classtable.ConvoketheSpirits].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BerserkBear, 'BerserkBear')) and not talents[classtable.Incarnation] and cooldown[classtable.BerserkBear].ready then
        if not setSpell then setSpell = classtable.BerserkBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incarnation, 'Incarnation')) and cooldown[classtable.Incarnation].ready then
        MaxDps:GlowCooldown(classtable.Incarnation, cooldown[classtable.Incarnation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RageoftheSleeper, 'RageoftheSleeper')) and (( ( ( not buff[classtable.IncarnationGuardianofUrsocBuff].up and cooldown[classtable.IncarnationGuardianofUrsoc].remains >60 ) or not buff[classtable.BerserkBearBuff].up ) and Rage >40 and ( not talents[classtable.ConvoketheSpirits] ) or ( buff[classtable.IncarnationGuardianofUrsocBuff].up or buff[classtable.BerserkBearBuff].up ) and Rage >40 and ( not talents[classtable.ConvoketheSpirits] ) or ( talents[classtable.ConvoketheSpirits] ) and Rage >40 )) and cooldown[classtable.RageoftheSleeper].ready then
        if not setSpell then setSpell = classtable.RageoftheSleeper end
    end
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and (buff[classtable.RavageBuff].up and targets <2) and cooldown[classtable.Maul].ready then
        if not setSpell then setSpell = classtable.Maul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Raze, 'Raze')) and (( buff[classtable.ToothandClawBuff].count >1 or buff[classtable.ToothandClawBuff].remains <1 + gcd ) and if_build == 1 and targets >1) and cooldown[classtable.Raze].ready then
        if not setSpell then setSpell = classtable.Raze end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashBear, 'ThrashBear')) and (targets >= 5 and talents[classtable.LunarCalling]) and cooldown[classtable.ThrashBear].ready then
        if not setSpell then setSpell = classtable.ThrashBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ironfur, 'Ironfur')) and (not debuff[classtable.ToothandClawDeBuff].up and not buff[classtable.IronfurBuff].up and Rage >50 and (UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and if_build == 0 and not buff[classtable.RageoftheSleeperBuff].up or Rage >90 and if_build == 0 or not debuff[classtable.ToothandClawDeBuff].up and not buff[classtable.IronfurBuff].up and Rage >50 and (UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and if_build == 0 and not buff[classtable.RageoftheSleeperBuff].up) and cooldown[classtable.Ironfur].ready then
        MaxDps:GlowCooldown(classtable.Ironfur, cooldown[classtable.Ironfur].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ironfur, 'Ironfur')) and (not buff[classtable.RavageBuff].up and ( ( Rage >40 and if_build == 1 and cooldown[classtable.RageoftheSleeper].remains >3 and talents[classtable.RageoftheSleeper] or ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and Rage >20 and if_build == 1 and cooldown[classtable.RageoftheSleeper].remains >3 and talents[classtable.RageoftheSleeper] or Rage >90 and if_build == 1 and not talents[classtable.FountofStrength] or Rage >110 and if_build == 1 and talents[classtable.FountofStrength] or ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and Rage >20 and if_build == 1 and buff[classtable.RageoftheSleeperBuff].up and talents[classtable.RageoftheSleeper] ) )) and cooldown[classtable.Ironfur].ready then
        MaxDps:GlowCooldown(classtable.Ironfur, cooldown[classtable.Ironfur].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Ironfur, 'Ironfur')) and (not buff[classtable.RavageBuff].up and ( ( Rage >40 and if_build == 1 and not talents[classtable.RageoftheSleeper] or ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and Rage >20 and if_build == 1 and not talents[classtable.RageoftheSleeper] or ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and Rage >20 and if_build == 1 and not talents[classtable.RageoftheSleeper] ) )) and cooldown[classtable.Ironfur].ready then
        MaxDps:GlowCooldown(classtable.Ironfur, cooldown[classtable.Ironfur].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (( buff[classtable.CatFormBuff].up and buff[classtable.FelinePotentialBuff].up and targets <3 and ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and not debuff[classtable.RipDeBuff].refreshable )) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rip, 'Rip')) and (( buff[classtable.CatFormBuff].up and buff[classtable.FelinePotentialBuff].up and targets <3 and ( not buff[classtable.IncarnationBuff].up or not buff[classtable.BerserkBearBuff].up ) ) or ( buff[classtable.CatFormBuff].up and buff[classtable.FelinePotentialBuff].up and targets <3 and ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and debuff[classtable.RipDeBuff].refreshable )) and cooldown[classtable.Rip].ready then
        if not setSpell then setSpell = classtable.Rip end
    end
    if (MaxDps:CheckSpellUsable(classtable.Raze, 'Raze')) and (if_build == 1 and buff[classtable.ViciousCycleMaulBuff].count == 3 and targets >1 and not talents[classtable.Ravage]) and cooldown[classtable.Raze].ready then
        if not setSpell then setSpell = classtable.Raze end
    end
    if (MaxDps:CheckSpellUsable(classtable.Mangle, 'Mangle')) and (buff[classtable.GoreBuff].up and targets <11 or buff[classtable.IncarnationGuardianofUrsocBuff].up and buff[classtable.FelinePotentialCounterBuff].count <6 and talents[classtable.WildpowerSurge]) and cooldown[classtable.Mangle].ready then
        if not setSpell then setSpell = classtable.Mangle end
    end
    if (MaxDps:CheckSpellUsable(classtable.Raze, 'Raze')) and (if_build == 0 and ( targets >1 or ( buff[classtable.ToothandClawBuff].up ) and targets >1 or buff[classtable.ViciousCycleMaulBuff].count == 3 and targets >1 )) and cooldown[classtable.Raze].ready then
        if not setSpell then setSpell = classtable.Raze end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (cooldown[classtable.RageoftheSleeper].remains <= 52 and buff[classtable.FelinePotentialCounterBuff].count == 6 and not buff[classtable.CatFormBuff].up and not debuff[classtable.RakeDeBuff].refreshable and targets <3 and talents[classtable.FluidForm]) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (cooldown[classtable.RageoftheSleeper].remains <= 52 and buff[classtable.FelinePotentialCounterBuff].count == 6 and not buff[classtable.CatFormBuff].up and targets <3 and talents[classtable.FluidForm]) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.Mangle, 'Mangle')) and (buff[classtable.CatFormBuff].up and talents[classtable.FluidForm]) and cooldown[classtable.Mangle].ready then
        if not setSpell then setSpell = classtable.Mangle end
    end
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and (if_build == 1 and ( ( ( buff[classtable.ToothandClawBuff].count >1 or buff[classtable.ToothandClawBuff].remains <1 + gcd ) and targets <= 5 and not talents[classtable.Raze] ) or ( ( buff[classtable.ToothandClawBuff].count >1 or buff[classtable.ToothandClawBuff].remains <1 + gcd ) and targets == 1 and talents[classtable.Raze] ) or ( ( buff[classtable.ToothandClawBuff].count >1 or buff[classtable.ToothandClawBuff].remains <1 + gcd ) and targets <= 5 and not talents[classtable.Raze] ) )) and cooldown[classtable.Maul].ready then
        if not setSpell then setSpell = classtable.Maul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and (if_build == 0 and ( ( buff[classtable.ToothandClawBuff].up and targets <= 5 and not talents[classtable.Raze] ) or ( buff[classtable.ToothandClawBuff].up and targets == 1 and talents[classtable.Raze] ) )) and cooldown[classtable.Maul].ready then
        if not setSpell then setSpell = classtable.Maul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and (( targets <= 5 and not talents[classtable.Raze] and if_build == 0 ) or ( targets == 1 and talents[classtable.Raze] and if_build == 0 ) or buff[classtable.ViciousCycleMaulBuff].count == 3 and targets <= 5 and not talents[classtable.Raze]) and cooldown[classtable.Maul].ready then
        if not setSpell then setSpell = classtable.Maul end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashBear, 'ThrashBear')) and (targets >= 5) and cooldown[classtable.ThrashBear].ready then
        if not setSpell then setSpell = classtable.ThrashBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.Mangle, 'Mangle')) and (( buff[classtable.IncarnationBuff].up and targets <= 4 ) or ( buff[classtable.IncarnationBuff].up and talents[classtable.SouloftheForest] and targets <= 5 ) or ( ( Rage <88 ) and targets <11 ) or ( ( Rage <83 ) and targets <11 and talents[classtable.SouloftheForest] )) and cooldown[classtable.Mangle].ready then
        if not setSpell then setSpell = classtable.Mangle end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashBear, 'ThrashBear')) and (targets >1) and cooldown[classtable.ThrashBear].ready then
        if not setSpell then setSpell = classtable.ThrashBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pulverize, 'Pulverize')) and cooldown[classtable.Pulverize].ready then
        if not setSpell then setSpell = classtable.Pulverize end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashBear, 'ThrashBear')) and cooldown[classtable.ThrashBear].ready then
        if not setSpell then setSpell = classtable.ThrashBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (buff[classtable.GalacticGuardianBuff].up and buff[classtable.BearFormBuff].up and talents[classtable.BoundlessMoonlight]) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (cooldown[classtable.RageoftheSleeper].remains <= 52 and Rage <40 and targets <3 and not talents[classtable.LunarInsight] and talents[classtable.FluidForm] and Energy >70 and debuff[classtable.RakeDeBuff].refreshable and ripweaving == 1) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (cooldown[classtable.RageoftheSleeper].remains <= 52 and Rage <40 and targets <3 and not talents[classtable.LunarInsight] and talents[classtable.FluidForm] and Energy >70 and not buff[classtable.RageoftheSleeperBuff].up and ripweaving == 1) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rip, 'Rip')) and (buff[classtable.CatFormBuff].up and not debuff[classtable.RipDeBuff].up and targets <3 and ripweaving == 1) and cooldown[classtable.Rip].ready then
        if not setSpell then setSpell = classtable.Rip end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (debuff[classtable.RipDeBuff].up and ComboPoints >4 and targets <3 and ripweaving == 1) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (talents[classtable.Starsurge] and Rage <20) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeBear, 'SwipeBear')) and (( talents[classtable.LunarInsight] and targets >4 ) or not talents[classtable.LunarInsight] or talents[classtable.LunarInsight] and targets <2) and cooldown[classtable.SwipeBear].ready then
        if not setSpell then setSpell = classtable.SwipeBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (( talents[classtable.LunarInsight] and targets >1 ) and buff[classtable.BearFormBuff].up) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
end
function Guardian:mitigation()
    if (MaxDps:CheckSpellUsable(classtable.Ironfur, 'Ironfur')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and not if_build and buff[classtable.IronfurBuff].remains <3 * SpellHaste and buff[classtable.IronfurBuff].count <5) and cooldown[classtable.Ironfur].ready then
        MaxDps:GlowCooldown(classtable.Ironfur, cooldown[classtable.Ironfur].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Regrowth, 'Regrowth')) and (curentHP <65) and cooldown[classtable.Regrowth].ready then
        MaxDps:GlowCooldown(classtable.Regrowth, cooldown[classtable.Regrowth].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Renewal, 'Renewal')) and (curentHP <65) and cooldown[classtable.Renewal].ready then
        MaxDps:GlowCooldown(classtable.Renewal, cooldown[classtable.Renewal].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrenziedRegeneration, 'FrenziedRegeneration')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and curentHP <65) and cooldown[classtable.FrenziedRegeneration].ready then
        MaxDps:GlowCooldown(classtable.FrenziedRegeneration, cooldown[classtable.FrenziedRegeneration].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Barkskin, 'Barkskin')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and curentHP <75) and cooldown[classtable.Barkskin].ready then
        MaxDps:GlowCooldown(classtable.Barkskin, cooldown[classtable.Barkskin].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SurvivalInstincts, 'SurvivalInstincts')) and (not buff[classtable.SurvivalInstinctsBuff].up and not buff[classtable.BarkskinBuff].up and curentHP <60) and cooldown[classtable.SurvivalInstincts].ready then
        MaxDps:GlowCooldown(classtable.SurvivalInstincts, cooldown[classtable.SurvivalInstincts].ready)
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.HeartoftheWild, false)
    MaxDps:GlowCooldown(classtable.SkullBash, false)
    MaxDps:GlowCooldown(classtable.Barkskin, false)
    MaxDps:GlowCooldown(classtable.LunarBeam, false)
    MaxDps:GlowCooldown(classtable.ConvoketheSpirits, false)
    MaxDps:GlowCooldown(classtable.Incarnation, false)
    MaxDps:GlowCooldown(classtable.Ironfur, false)
    MaxDps:GlowCooldown(classtable.Regrowth, false)
    MaxDps:GlowCooldown(classtable.Renewal, false)
    MaxDps:GlowCooldown(classtable.FrenziedRegeneration, false)
    MaxDps:GlowCooldown(classtable.SurvivalInstincts, false)
end

function Guardian:callaction()
    if (MaxDps:CheckSpellUsable(classtable.SkullBash, 'SkullBash')) and cooldown[classtable.SkullBash].ready then
        MaxDps:GlowCooldown(classtable.SkullBash, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (MaxDps:CheckSpellUsable(classtable.Soothe, 'Soothe')) and cooldown[classtable.Soothe].ready then
    --    if not setSpell then setSpell = classtable.Soothe end
    --end
    Guardian:mitigation()
    Guardian:bear()
end
function Druid:Guardian()
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
    ComboPoints = UnitPower('player', ComboPointsPT)
    ComboPointsMax = UnitPowerMax('player', ComboPointsPT)
    ComboPointsDeficit = ComboPointsMax - ComboPoints
    Rage = UnitPower('player', RagePT)
    RageMax = UnitPowerMax('player', RagePT)
    RageDeficit = RageMax - Rage
    classtable.Incarnation =  classtable.IncarnationGuardianofUrsoc
    classtable.ThrashBear =  classtable.Thrash
    classtable.SwipeBear =  classtable.Swipe
    classtable.BerserkBear = classtable.Berserk
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.RavageBuff = 0
    classtable.FelinePotentialCounterBuff = 0
    classtable.BearFormBuff = 5487
    classtable.MoonfireDeBuff = 164812
    classtable.ThrashBearDeBuff = 77758
    classtable.CatFormBuff = 768
    classtable.FelinePotentialBuff = 0
    classtable.IncarnationGuardianofUrsocBuff = 102558
    classtable.BerserkBearBuff = 50334
    classtable.ToothandClawBuff = 135286
    classtable.ToothandClawDeBuff = 135601
    classtable.IronfurBuff = 192081
    classtable.RageoftheSleeperBuff = 200851
    classtable.IncarnationBuff = 102558
    classtable.RipDeBuff = 1079
    classtable.ViciousCycleMaulBuff = 0
    classtable.GoreBuff = 93622
    classtable.RakeDeBuff = 155722
    classtable.GalacticGuardianBuff = 213708
    classtable.SurvivalInstinctsBuff = 0
    classtable.BarkskinBuff = 0
    setSpell = nil
    ClearCDs()

    Guardian:precombat()

    Guardian:callaction()
    if setSpell then return setSpell end
end
