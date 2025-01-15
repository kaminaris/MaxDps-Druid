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

function Guardian:precombat()
    if (MaxDps:CheckSpellUsable(classtable.MarkoftheWild, 'MarkoftheWild')) and (not buff[classtable.StatBuffBuff].up) and cooldown[classtable.MarkoftheWild].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MarkoftheWild end
    end
    if (MaxDps:CheckSpellUsable(classtable.Thorns, 'Thorns')) and (not up) and cooldown[classtable.Thorns].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Thorns end
    end
    if (MaxDps:CheckSpellUsable(classtable.BearForm, 'BearForm')) and (not up) and cooldown[classtable.BearForm].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BearForm end
    end
end
function Guardian:bear_tank()
    if (MaxDps:CheckSpellUsable(classtable.FrenziedRegeneration, 'FrenziedRegeneration')) and (curentHP <30) and cooldown[classtable.FrenziedRegeneration].ready then
        if not setSpell then setSpell = classtable.FrenziedRegeneration end
    end
    if (MaxDps:CheckSpellUsable(classtable.SurvivalInstincts, 'SurvivalInstincts')) and (curentHP <40) and cooldown[classtable.SurvivalInstincts].ready then
        if not setSpell then setSpell = classtable.SurvivalInstincts end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralChargeBear, 'FeralChargeBear')) and (target.outside7) and cooldown[classtable.FeralChargeBear].ready then
        if not setSpell then setSpell = classtable.FeralChargeBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and (rage.current >= 55) and cooldown[classtable.Maul].ready then
        if not setSpell then setSpell = classtable.Maul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pulverize, 'Pulverize')) and (debuff[classtable.LacerateDeBuff].up and debuff[classtable.LacerateDeBuff].count == 3 and debuff[classtable.LacerateDeBuff].remains <4) and cooldown[classtable.Pulverize].ready then
        if not setSpell then setSpell = classtable.Pulverize end
    end
    if (MaxDps:CheckSpellUsable(classtable.Lacerate, 'Lacerate')) and (debuff[classtable.LacerateDeBuff].up and debuff[classtable.LacerateDeBuff].remains <4) and cooldown[classtable.Lacerate].ready then
        if not setSpell then setSpell = classtable.Lacerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.FaerieFireFeral, 'FaerieFireFeral')) and (false and ( not debuff[classtable.MajorArmorReductionDeBuff].up or ( debuff[classtable.FaerieFireDeBuff].up and debuff[classtable.FaerieFireDeBuff].remains <6 ) )) and cooldown[classtable.FaerieFireFeral].ready then
        if not setSpell then setSpell = classtable.FaerieFireFeral end
    end
    if (MaxDps:CheckSpellUsable(classtable.DemoralizingRoar, 'DemoralizingRoar')) and (false and ( not debuff[classtable.ApReductionDeBuff].up or ( debuff[classtable.DemoralizingRoarDeBuff].up and debuff[classtable.DemoralizingRoarDeBuff].remains <4 ) )) and cooldown[classtable.DemoralizingRoar].ready then
        if not setSpell then setSpell = classtable.DemoralizingRoar end
    end
    if (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and cooldown[classtable.Berserk].ready then
        if not setSpell then setSpell = classtable.Berserk end
    end
    if (MaxDps:CheckSpellUsable(classtable.Enrage, 'Enrage')) and (rage.current <= 80) and cooldown[classtable.Enrage].ready then
        if not setSpell then setSpell = classtable.Enrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.SynapseSprings, 'SynapseSprings')) and cooldown[classtable.SynapseSprings].ready then
        if not setSpell then setSpell = classtable.SynapseSprings end
    end
    if (MaxDps:CheckSpellUsable(classtable.Thrash, 'Thrash')) and cooldown[classtable.Thrash].ready then
        if not setSpell then setSpell = classtable.Thrash end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleBear, 'MangleBear')) and cooldown[classtable.MangleBear].ready then
        if not setSpell then setSpell = classtable.MangleBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.Lacerate, 'Lacerate')) and (not debuff[classtable.LacerateDeBuff].up and not buff[classtable.BerserkBuff].up) and cooldown[classtable.Lacerate].ready then
        if not setSpell then setSpell = classtable.Lacerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pulverize, 'Pulverize')) and (debuff[classtable.LacerateDeBuff].up and debuff[classtable.LacerateDeBuff].count == 3 and ( not buff[classtable.PulverizeBuff].up or buff[classtable.PulverizeBuff].remains <4 )) and cooldown[classtable.Pulverize].ready then
        if not setSpell then setSpell = classtable.Pulverize end
    end
    if (MaxDps:CheckSpellUsable(classtable.Lacerate, 'Lacerate')) and (debuff[classtable.LacerateDeBuff].count <3) and cooldown[classtable.Lacerate].ready then
        if not setSpell then setSpell = classtable.Lacerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.FaerieFireFeral, 'FaerieFireFeral')) and cooldown[classtable.FaerieFireFeral].ready then
        if not setSpell then setSpell = classtable.FaerieFireFeral end
    end
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and cooldown[classtable.Maul].ready then
        if not setSpell then setSpell = classtable.Maul end
    end
end
function Guardian:bear_tank_aoe()
    if (MaxDps:CheckSpellUsable(classtable.FrenziedRegeneration, 'FrenziedRegeneration')) and (curentHP <30) and cooldown[classtable.FrenziedRegeneration].ready then
        if not setSpell then setSpell = classtable.FrenziedRegeneration end
    end
    if (MaxDps:CheckSpellUsable(classtable.SurvivalInstincts, 'SurvivalInstincts')) and (curentHP <40) and cooldown[classtable.SurvivalInstincts].ready then
        if not setSpell then setSpell = classtable.SurvivalInstincts end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralChargeBear, 'FeralChargeBear')) and (target.outside7) and cooldown[classtable.FeralChargeBear].ready then
        if not setSpell then setSpell = classtable.FeralChargeBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and (rage.current >= 55) and cooldown[classtable.Maul].ready then
        if not setSpell then setSpell = classtable.Maul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pulverize, 'Pulverize')) and (debuff[classtable.LacerateDeBuff].up and debuff[classtable.LacerateDeBuff].count == 3 and debuff[classtable.LacerateDeBuff].remains <4) and cooldown[classtable.Pulverize].ready then
        if not setSpell then setSpell = classtable.Pulverize end
    end
    if (MaxDps:CheckSpellUsable(classtable.FaerieFireFeral, 'FaerieFireFeral')) and (false and ( not debuff[classtable.MajorArmorReductionDeBuff].up or ( debuff[classtable.FaerieFireDeBuff].up and debuff[classtable.FaerieFireDeBuff].remains <6 ) )) and cooldown[classtable.FaerieFireFeral].ready then
        if not setSpell then setSpell = classtable.FaerieFireFeral end
    end
    if (MaxDps:CheckSpellUsable(classtable.DemoralizingRoar, 'DemoralizingRoar')) and (false and ( not debuff[classtable.ApReductionDeBuff].up or ( debuff[classtable.DemoralizingRoarDeBuff].up and debuff[classtable.DemoralizingRoarDeBuff].remains <4 ) )) and cooldown[classtable.DemoralizingRoar].ready then
        if not setSpell then setSpell = classtable.DemoralizingRoar end
    end
    if (MaxDps:CheckSpellUsable(classtable.Thrash, 'Thrash')) and cooldown[classtable.Thrash].ready then
        if not setSpell then setSpell = classtable.Thrash end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeBear, 'SwipeBear')) and cooldown[classtable.SwipeBear].ready then
        if not setSpell then setSpell = classtable.SwipeBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and cooldown[classtable.Berserk].ready then
        if not setSpell then setSpell = classtable.Berserk end
    end
    if (MaxDps:CheckSpellUsable(classtable.Enrage, 'Enrage')) and (rage.current <= 80) and cooldown[classtable.Enrage].ready then
        if not setSpell then setSpell = classtable.Enrage end
    end
    if (MaxDps:CheckSpellUsable(classtable.SynapseSprings, 'SynapseSprings')) and cooldown[classtable.SynapseSprings].ready then
        if not setSpell then setSpell = classtable.SynapseSprings end
    end
    if (MaxDps:CheckSpellUsable(classtable.Lacerate, 'Lacerate')) and (not debuff[classtable.LacerateDeBuff].up and not buff[classtable.BerserkBuff].up) and cooldown[classtable.Lacerate].ready then
        if not setSpell then setSpell = classtable.Lacerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleBear, 'MangleBear')) and cooldown[classtable.MangleBear].ready then
        if not setSpell then setSpell = classtable.MangleBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.FaerieFireFeral, 'FaerieFireFeral')) and cooldown[classtable.FaerieFireFeral].ready then
        if not setSpell then setSpell = classtable.FaerieFireFeral end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pulverize, 'Pulverize')) and (debuff[classtable.LacerateDeBuff].up and debuff[classtable.LacerateDeBuff].count == 3 and ( not buff[classtable.PulverizeBuff].up or buff[classtable.PulverizeBuff].remains <4 )) and cooldown[classtable.Pulverize].ready then
        if not setSpell then setSpell = classtable.Pulverize end
    end
    if (MaxDps:CheckSpellUsable(classtable.Lacerate, 'Lacerate')) and (debuff[classtable.LacerateDeBuff].count <3) and cooldown[classtable.Lacerate].ready then
        if not setSpell then setSpell = classtable.Lacerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and cooldown[classtable.Maul].ready then
        if not setSpell then setSpell = classtable.Maul end
    end
end
function Guardian:cat()
    if (MaxDps:CheckSpellUsable(classtable.SynapseSprings, 'SynapseSprings')) and (try_tigers_fury or try_berserk) and cooldown[classtable.SynapseSprings].ready then
        if not setSpell then setSpell = classtable.SynapseSprings end
    end
    if (MaxDps:CheckSpellUsable(classtable.TigersFury, 'TigersFury')) and (try_tigers_fury) and cooldown[classtable.TigersFury].ready then
        if not setSpell then setSpell = classtable.TigersFury end
    end
    if (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and (try_berserk) and cooldown[classtable.Berserk].ready then
        if not setSpell then setSpell = classtable.Berserk end
    end
    if (MaxDps:CheckSpellUsable(classtable.FaerieFireFeral, 'FaerieFireFeral')) and (ff_now and target.outside2) and cooldown[classtable.FaerieFireFeral].ready then
        if not setSpell then setSpell = classtable.FaerieFireFeral end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralChargeCat, 'FeralChargeCat')) and (target.outside7) and cooldown[classtable.FeralChargeCat].ready then
        if not setSpell then setSpell = classtable.FeralChargeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (feral_t11_refresh_now) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rip, 'Rip')) and (rip_now) and cooldown[classtable.Rip].ready then
        if not setSpell then setSpell = classtable.Rip end
    end
    if (MaxDps:CheckSpellUsable(classtable.SavageRoar, 'SavageRoar')) and (roar_now and not rip_now) and cooldown[classtable.SavageRoar].ready then
        if not setSpell then setSpell = classtable.SavageRoar end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (bite_now and ( energy.current >= action.ferocious_bite.spend or not should_bearweave ) and not ( rip_now or roar_now )) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (mangle_now) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (rake_now) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (feral_t11_build_now) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.BearForm, 'BearForm')) and (should_bearweave and not ( feral_t11_refresh_now or rip_now or roar_now or mangle_now or rake_now or feral_t11_build_now )) and cooldown[classtable.BearForm].ready then
        if not setSpell then setSpell = classtable.BearForm end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralChargeCat, 'FeralChargeCat')) and (should_leaveweave) and cooldown[classtable.FeralChargeCat].ready then
        if not setSpell then setSpell = classtable.FeralChargeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravage, 'Ravage')) and (ravage_now) and cooldown[classtable.Ravage].ready then
        if not setSpell then setSpell = classtable.Ravage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (( excess_e >= action.shred.spend or buff[classtable.ClearcastingBuff].up or buff[classtable.BerserkBuff].up or energy.current >= EnergyMax - EnergyRegen * latency )) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
end
function Guardian:cat_aoe()
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (feral_t11_refresh_now and not debuff[classtable.MangleDeBuff].up and target.within2) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (feral_t11_refresh_now) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.SynapseSprings, 'SynapseSprings')) and (try_tigers_fury or try_berserk or buff[classtable.BerserkBuff].up) and cooldown[classtable.SynapseSprings].ready then
        if not setSpell then setSpell = classtable.SynapseSprings end
    end
    if (MaxDps:CheckSpellUsable(classtable.TigersFury, 'TigersFury')) and (try_tigers_fury) and cooldown[classtable.TigersFury].ready then
        if not setSpell then setSpell = classtable.TigersFury end
    end
    if (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and (try_berserk) and cooldown[classtable.Berserk].ready then
        if not setSpell then setSpell = classtable.Berserk end
    end
    if (MaxDps:CheckSpellUsable(classtable.SavageRoar, 'SavageRoar')) and (not up and ttd >2 + latency) and cooldown[classtable.SavageRoar].ready then
        if not setSpell then setSpell = classtable.SavageRoar end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (targets >6 or targets >3 and buff[classtable.TigersFuryBuff].up) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravage, 'Ravage')) and (ravage_now) and cooldown[classtable.Ravage].ready then
        if not setSpell then setSpell = classtable.Ravage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (targets <7 and target.within3 and ( ( not debuff[classtable.RakeDeBuff].up or ( debuff[classtable.RakeDeBuff].remains <debuff[classtable.RakeDeBuff].tick_time ) ) and ( ttd >debuff[classtable.RakeDeBuff].tick_time ) )) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.BearForm, 'BearForm')) and (should_bearweave) and cooldown[classtable.BearForm].ready then
        if not setSpell then setSpell = classtable.BearForm end
    end
end


local function ClearCDs()
end

function Guardian:callaction()
    if (MaxDps:CheckSpellUsable(classtable.HyperspeedAcceleration, 'HyperspeedAcceleration')) and cooldown[classtable.HyperspeedAcceleration].ready then
        if not setSpell then setSpell = classtable.HyperspeedAcceleration end
    end
    if (buff[classtable.BearFormBuff].up and targets >2) then
        Guardian:bear_tank_aoe()
    end
    if (buff[classtable.BearFormBuff].up) then
        Guardian:bear_tank()
    end
    if (buff[classtable.CatFormBuff].up and targets >2) then
        Guardian:cat_aoe()
    end
    if (buff[classtable.CatFormBuff].up) then
        Guardian:cat()
    end
    if (MaxDps:CheckSpellUsable(classtable.BearForm, 'BearForm')) and (not up) and cooldown[classtable.BearForm].ready then
        if not setSpell then setSpell = classtable.BearForm end
    end
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
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.StatBuffBuff = 0
    classtable.LacerateDeBuff = 33745
    classtable.MajorArmorReductionDeBuff = 0
    classtable.FaerieFireDeBuff = 0
    classtable.ApReductionDeBuff = 0
    classtable.DemoralizingRoarDeBuff = 48560
    classtable.BerserkBuff = 50334
    classtable.PulverizeBuff = 80951
    classtable.ClearcastingBuff = 16870
    classtable.MangleDeBuff = 0
    classtable.TigersFuryBuff = 5217
    classtable.RakeDeBuff = 1822
    classtable.BearFormBuff = 5487
    classtable.CatFormBuff = 768
    classtable.Thorns = 467
    classtable.BearForm = 5487
    classtable.FrenziedRegeneration = 22842
    classtable.SurvivalInstincts = 61336
    classtable.FeralChargeBear = 16979
    classtable.Maul = 6807
    classtable.Pulverize = 80313
    classtable.Lacerate = 33745
    classtable.FaerieFireFeral = 16857
    classtable.FaerieFire = 770
    classtable.DemoralizingRoar = 99
    classtable.Berserk = 50334
    classtable.Enrage = 5229
    classtable.Thrash = 77758
    classtable.MangleBear = 33878
    classtable.SwipeBear = 779
    classtable.TigersFury = 5217
    classtable.FeralChargeCat = 49376
    classtable.MangleCat = 33876
    classtable.Rip = 1079
    classtable.SavageRoar = 52610
    classtable.FerociousBite = 22568
    classtable.Rake = 1822
    classtable.Ravage = 6785
    classtable.Shred = 5221
    classtable.SwipeCat = 62078
    classtable.CatForm = 768

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Guardian:precombat()

    Guardian:callaction()
    if setSpell then return setSpell end
end
