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

local Feral = {}

function Feral:precombat()
    if (MaxDps:CheckSpellUsable(classtable.MarkoftheWild, 'MarkoftheWild')) and (not buff[classtable.MarkoftheWildBuff].up) and cooldown[classtable.MarkoftheWild].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MarkoftheWild end
    end
    --if (MaxDps:CheckSpellUsable(classtable.CatForm, 'CatForm')) and (not buff[classtable.CatFormBuff].up) and cooldown[classtable.CatForm].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.CatForm end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.FaerieFireFeral, 'FaerieFireFeral')) and (not debuff[classtable.FaerieFireFeral].up) and cooldown[classtable.FaerieFireFeral].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.FaerieFireFeral end
    --end
end
function Feral:cat()
    if (MaxDps:CheckSpellUsable(classtable.Ravage, 'Ravage')) and ( talents[classtable.Stampede] and buff[classtable.StampedeBuff].up and (not UnitThreatSituation("player")) or (UnitThreatSituation("player") and UnitThreatSituation("player") <= 2) ) and cooldown[classtable.Ravage].ready then
        if not setSpell then setSpell = classtable.Ravage end
    end
    if (MaxDps:CheckSpellUsable(classtable.TigersFury, 'TigersFury')) and (Energy <= 40) and cooldown[classtable.TigersFury].ready then
        if not setSpell then setSpell = classtable.TigersFury end
    end
    if (cooldown[classtable.TigersFury].remains >=15 and Energy < 90) and cooldown[classtable.Berserk].ready then
        if not setSpell then setSpell = "" end
    elseif (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and (cooldown[classtable.TigersFury].remains <=15 and Energy >= 90) and cooldown[classtable.Berserk].ready then
        if not setSpell then setSpell = classtable.Berserk end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (not debuff[classtable.MangleCat].up or debuff[classtable.MangleCat].refreshable) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (ComboPoints >= 5 and targethealthPerc <= 25 and debuff[classtable.Rip].up) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rip, 'Rip')) and (ComboPoints >= 5 and not debuff[classtable.Rip].up) and cooldown[classtable.Rip].ready then
        if not setSpell then setSpell = classtable.Rip end
    end
    if (MaxDps:CheckSpellUsable(classtable.SavageRoar, 'SavageRoar')) and (ComboPoints >= 5 and not buff[classtable.SavageRoar].up) and cooldown[classtable.SavageRoar].ready then
        if not setSpell then setSpell = classtable.SavageRoar end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (not debuff[classtable.Rake].up) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralChargeCat, 'FeralChargeCat')) and ( talents[classtable.Stampede] and (not UnitThreatSituation("player")) or (UnitThreatSituation("player") and UnitThreatSituation("player") <= 2) ) and cooldown[classtable.FeralChargeCat].ready then
        if not setSpell then setSpell = classtable.FeralChargeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and ( (not UnitThreatSituation("player")) or (UnitThreatSituation("player") and UnitThreatSituation("player") <= 2) ) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
end
function Feral:cat_aoe()
    if (MaxDps:CheckSpellUsable(classtable.TigersFury, 'TigersFury')) and (Energy <= 40) and cooldown[classtable.TigersFury].ready then
        if not setSpell then setSpell = classtable.TigersFury end
    end
    if (cooldown[classtable.TigersFury].remains >=15 and Energy < 90) and cooldown[classtable.Berserk].ready then
        if not setSpell then setSpell = "" end
    elseif (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and (cooldown[classtable.TigersFury].remains <=15 and Energy >= 90) and cooldown[classtable.Berserk].ready then
        if not setSpell then setSpell = classtable.Berserk end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
end

function Feral:bear_tank()
    if (MaxDps:CheckSpellUsable(classtable.FrenziedRegeneration, 'FrenziedRegeneration')) and (healthPerc <30) and cooldown[classtable.FrenziedRegeneration].ready then
        if not setSpell then setSpell = classtable.FrenziedRegeneration end
    end
    if (MaxDps:CheckSpellUsable(classtable.SurvivalInstincts, 'SurvivalInstincts')) and (healthPerc <40) and cooldown[classtable.SurvivalInstincts].ready then
        if not setSpell then setSpell = classtable.SurvivalInstincts end
    end
    --if (MaxDps:CheckSpellUsable(classtable.FeralChargeBear, 'FeralChargeBear')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) >7 or false)) and cooldown[classtable.FeralChargeBear].ready then
    --    if not setSpell then setSpell = classtable.FeralChargeBear end
    --end
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
function Feral:bear_tank_aoe()
    if (MaxDps:CheckSpellUsable(classtable.FrenziedRegeneration, 'FrenziedRegeneration')) and (healthPerc <30) and cooldown[classtable.FrenziedRegeneration].ready then
        if not setSpell then setSpell = classtable.FrenziedRegeneration end
    end
    if (MaxDps:CheckSpellUsable(classtable.SurvivalInstincts, 'SurvivalInstincts')) and (healthPerc <40) and cooldown[classtable.SurvivalInstincts].ready then
        if not setSpell then setSpell = classtable.SurvivalInstincts end
    end
    --if (MaxDps:CheckSpellUsable(classtable.FeralChargeBear, 'FeralChargeBear')) and ((LibRangeCheck and LibRangeCheck:GetRange('target', false, true) >7 or false)) and cooldown[classtable.FeralChargeBear].ready then
    --    if not setSpell then setSpell = classtable.FeralChargeBear end
    --end
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

function Feral:callaction()
    --if (MaxDps:CheckSpellUsable(classtable.CatForm, 'CatForm')) and (not buff[classtable.CatFormBuff].up) and cooldown[classtable.CatForm].ready then
    --    if not setSpell then setSpell = classtable.CatForm end
    --end
    if (buff[classtable.CatFormBuff].up and targets >2) then
        Feral:cat_aoe()
    end
    if (buff[classtable.CatFormBuff].up) then
        Feral:cat()
    end
    if (buff[classtable.BearFormBuff].up and targets >2) then
        Feral:bear_tank_aoe()
    end
    if (buff[classtable.BearFormBuff].up) then
        Feral:bear_tank()
    end
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
    ComboPoints = UnitPower('player', ComboPointsPT)
    ComboPointsMax = UnitPowerMax('player', ComboPointsPT)
    ComboPointsDeficit = ComboPointsMax - ComboPoints
    Rage = UnitPower('player', RagePT)
    RageMax = UnitPowerMax('player', RagePT)
    RageDeficit = RageMax - Rage
    classtable.Incarnation =  classtable.IncarnationAvatarofAshamane
    classtable.MoonfireCat =  classtable.Moonfire
    classtable.ThrashCat =  classtable.Thrash
    classtable.SwipeCat =  classtable.Swipe
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.BearFormBuff = 5487
    classtable.TigersFuryBuff = 5217
    classtable.CatFormBuff = 768
    classtable.BerserkBuff = 50334
    classtable.PrimalMadnessBuff = 80886
    classtable.ClearcastingBuff = 16870
    classtable.PulverizeBuff = 80951
    classtable.RakeDeBuff = 1822
    classtable.LacerateDeBuff = 33745
    classtable.DemoralizingRoarDeBuff = 48560
    classtable.MarkoftheWild = 1126
    classtable.MarkoftheWildBuff = 79061
    classtable.CatForm = 768
    classtable.TigersFury = 5217
    classtable.Berserk = 50334
    classtable.FaerieFireFeral = 16857
    classtable.FeralChargeCat = 49376
    classtable.MangleCat = 33876
    classtable.Rip = 1079
    classtable.SavageRoar = 52610
    classtable.FerociousBite = 22568
    classtable.Rake = 1822
    classtable.BearForm = 5487
    classtable.Ravage = 6785
    classtable.Shred = 5221
    classtable.SwipeCat = 62078
    classtable.Maul = 6807
    classtable.Enrage = 5229
    classtable.MangleBear = 33878
    classtable.Thrash = 77758
    classtable.SwipeBear = 779
    classtable.FrenziedRegeneration = 22842
    classtable.SurvivalInstincts = 61336
    classtable.FeralChargeBear = 16979
    classtable.Pulverize = 80313
    classtable.Lacerate = 33745
    classtable.DemoralizingRoar = 99
    classtable.Stampede = 78893
    classtable.StampedeBuff = 81022

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

    Feral:precombat()

    Feral:callaction()
    if setSpell then return setSpell end
end
