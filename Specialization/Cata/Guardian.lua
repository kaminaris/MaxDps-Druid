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
    if (MaxDps:CheckSpellUsable(classtable.Thorns, 'Thorns')) and (not buff[classtable.ThornsBuff].up) and cooldown[classtable.Thorns].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Thorns end
    end
    if (MaxDps:CheckSpellUsable(classtable.BearForm, 'BearForm')) and (not buff[classtable.BearFormBuff].up) and cooldown[classtable.BearForm].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.BearForm end
    end
end
function Guardian:bear_tank()
    if (MaxDps:CheckSpellUsable(classtable.FrenziedRegeneration, 'FrenziedRegeneration')) and (healthPerc <30) and cooldown[classtable.FrenziedRegeneration].ready then
        if not setSpell then setSpell = classtable.FrenziedRegeneration end
    end
    if (MaxDps:CheckSpellUsable(classtable.SurvivalInstincts, 'SurvivalInstincts')) and (healthPerc <40) and cooldown[classtable.SurvivalInstincts].ready then
        if not setSpell then setSpell = classtable.SurvivalInstincts end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralChargeBear, 'FeralChargeBear')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) >7 or false)) and cooldown[classtable.FeralChargeBear].ready then
        if not setSpell then setSpell = classtable.FeralChargeBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and (Rage >= 55) and cooldown[classtable.Maul].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.Enrage, 'Enrage')) and (Rage <= 80) and cooldown[classtable.Enrage].ready then
        if not setSpell then setSpell = classtable.Enrage end
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
    if (MaxDps:CheckSpellUsable(classtable.FrenziedRegeneration, 'FrenziedRegeneration')) and (healthPerc <30) and cooldown[classtable.FrenziedRegeneration].ready then
        if not setSpell then setSpell = classtable.FrenziedRegeneration end
    end
    if (MaxDps:CheckSpellUsable(classtable.SurvivalInstincts, 'SurvivalInstincts')) and (healthPerc <40) and cooldown[classtable.SurvivalInstincts].ready then
        if not setSpell then setSpell = classtable.SurvivalInstincts end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralChargeBear, 'FeralChargeBear')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) >7 or false)) and cooldown[classtable.FeralChargeBear].ready then
        if not setSpell then setSpell = classtable.FeralChargeBear end
    end
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and (Rage >= 55) and cooldown[classtable.Maul].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.Enrage, 'Enrage')) and (Rage <= 80) and cooldown[classtable.Enrage].ready then
        if not setSpell then setSpell = classtable.Enrage end
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

local function ClearCDs()
end

function Guardian:callaction()
    if (buff[classtable.BearFormBuff].up and targets >2) then
        Guardian:bear_tank_aoe()
    end
    if (buff[classtable.BearFormBuff].up) then
        Guardian:bear_tank()
    end
    if (MaxDps:CheckSpellUsable(classtable.BearForm, 'BearForm')) and (not buff[classtable.BearFormBuff].up) and cooldown[classtable.BearForm].ready then
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
    classtable.BearFormBuff = 5487
    classtable.CatFormBuff = 768
    classtable.BerserkBuff = 50334
    classtable.PulverizeBuff = 80951
    classtable.PrimalMadnessBuff = 80886
    classtable.ClearcastingBuff = 16870
    classtable.TigersFuryBuff = 5217
    classtable.LacerateDeBuff = 33745
    classtable.DemoralizingRoarDeBuff = 48560
    classtable.RakeDeBuff = 1822
    classtable.MarkoftheWild = 1126
    classtable.Thorns = 467
    classtable.BearForm = 5487
    classtable.FrenziedRegeneration = 22842
    classtable.SurvivalInstincts = 61336
    classtable.FeralChargeBear = 16979
    classtable.Maul = 6807
    classtable.Pulverize = 80313
    classtable.Lacerate = 33745
    classtable.FaerieFireFeral = 16857
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
