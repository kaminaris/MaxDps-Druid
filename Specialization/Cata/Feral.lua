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



local function active_bt_triggers()
    return 2
end




local function ClearCDs()
    MaxDps:GlowCooldown(classtable.TigersFury, false)
end

function Feral:callaction()
    if (MaxDps:CheckSpellUsable(classtable.MarkoftheWild, 'MarkoftheWild')) and cooldown[classtable.MarkoftheWild].ready then
        if not setSpell then setSpell = classtable.MarkoftheWild end
    end
    if (MaxDps:CheckSpellUsable(classtable.CatForm, 'CatForm')) and cooldown[classtable.CatForm].ready then
        if not setSpell then setSpell = classtable.CatForm end
    end
    if (MaxDps:CheckSpellUsable(classtable.TolvirPotion, 'TolvirPotion')) and (not in_combat) and cooldown[classtable.TolvirPotion].ready then
        if not setSpell then setSpell = classtable.TolvirPotion end
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralChargeCat, 'FeralChargeCat')) and (not in_combat) and cooldown[classtable.FeralChargeCat].ready then
        if not setSpell then setSpell = classtable.FeralChargeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.SkullBashCat, 'SkullBashCat')) and cooldown[classtable.SkullBashCat].ready then
        if not setSpell then setSpell = classtable.SkullBashCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.TigersFury, 'TigersFury')) and (Energy <= 45 and ( not buff[classtable.OmenofClarityBuff].up )) and cooldown[classtable.TigersFury].ready then
        MaxDps:GlowCooldown(classtable.TigersFury, cooldown[classtable.TigersFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and (buff[classtable.TigersFuryBuff].up or ( ttd <25 and cooldown[classtable.TigersFury].remains >6 )) and cooldown[classtable.Berserk].ready then
        if not setSpell then setSpell = classtable.Berserk end
    end
    if (MaxDps:CheckSpellUsable(classtable.FaerieFireFeral, 'FaerieFireFeral')) and (debuff[classtable.FaerieFireDeBuff].count <3 or not ( debuff[classtable.SunderArmorDeBuff].up or debuff[classtable.ExposeArmorDeBuff].up )) and cooldown[classtable.FaerieFireFeral].ready then
        if not setSpell then setSpell = classtable.FaerieFireFeral end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (debuff[classtable.MangleDeBuff].remains <= 2 and ( not debuff[classtable.MangleDeBuff].up or debuff[classtable.MangleDeBuff].remains >= 0.0 )) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravage, 'Ravage')) and (( buff[classtable.StampedeCatBuff].up or buff[classtable.T134pcMeleeBuff].up ) and ( buff[classtable.StampedeCatBuff].remains <= 1 or buff[classtable.T134pcMeleeBuff].remains <= 1 )) and cooldown[classtable.Ravage].ready then
        if not setSpell then setSpell = classtable.Ravage end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (buff[classtable.ComboPointsBuff].count >= 1 and debuff[classtable.RipDeBuff].up and debuff[classtable.RipDeBuff].remains <= 2.1 and targetHP <= 60) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (buff[classtable.ComboPointsBuff].count >= 5 and debuff[classtable.RipDeBuff].up and targetHP <= 60) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (position_back and debuff[classtable.RipDeBuff].up and debuff[classtable.RipDeBuff].remains <= 4) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (position_front and debuff[classtable.RipDeBuff].up and debuff[classtable.RipDeBuff].remains <= 4 and targetHP >60) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rip, 'Rip')) and (buff[classtable.ComboPointsBuff].count >= 5 and ttd >= 6 and debuff[classtable.RipDeBuff].remains <2.0 and ( buff[classtable.BerserkBuff].up or debuff[classtable.RipDeBuff].remains <= cooldown[classtable.TigersFury].remains )) and cooldown[classtable.Rip].ready then
        if not setSpell then setSpell = classtable.Rip end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (buff[classtable.ComboPointsBuff].count >= 5 and debuff[classtable.RipDeBuff].remains >5.0 and buff[classtable.SavageRoarBuff].remains >= 3.0 and buff[classtable.BerserkBuff].up) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (ttd >= 8.5 and buff[classtable.TigersFuryBuff].up and debuff[classtable.RakeDeBuff].remains <9.0 and ( not debuff[classtable.RakeDeBuff].up or debuff[classtable.RakeDeBuff].multiplier <multiplier )) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (ttd >= debuff[classtable.RakeDeBuff].remains and debuff[classtable.RakeDeBuff].remains <3.0 and ( buff[classtable.BerserkBuff].up or Energy >= 71 or ( cooldown[classtable.TigersFury].remains + 0.8 ) >= debuff[classtable.RakeDeBuff].remains )) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (position_back and buff[classtable.OmenofClarityBuff].up) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (position_front and buff[classtable.OmenofClarityBuff].up) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.SavageRoar, 'SavageRoar')) and (buff[classtable.ComboPointsBuff].count >= 1 and buff[classtable.SavageRoarBuff].remains <= 1) and cooldown[classtable.SavageRoar].ready then
        if not setSpell then setSpell = classtable.SavageRoar end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravage, 'Ravage')) and (( buff[classtable.StampedeCatBuff].up or buff[classtable.T134pcMeleeBuff].up ) and cooldown[classtable.TigersFury].remains == 0) and cooldown[classtable.Ravage].ready then
        if not setSpell then setSpell = classtable.Ravage end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (( ttd <= 4 and buff[classtable.ComboPointsBuff].count >= 5 ) or ttd <= 1) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (buff[classtable.ComboPointsBuff].count >= 5 and debuff[classtable.RipDeBuff].remains >= 14.0 and buff[classtable.SavageRoarBuff].remains >= 10.0) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.Ravage, 'Ravage')) and (( buff[classtable.StampedeCatBuff].up or buff[classtable.T134pcMeleeBuff].up ) and not buff[classtable.OmenofClarityBuff].up and buff[classtable.TigersFuryBuff].up and time_to_max_energy >1.0) and cooldown[classtable.Ravage].ready then
        if not setSpell then setSpell = classtable.Ravage end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (position_back and ( buff[classtable.TigersFuryBuff].up or buff[classtable.BerserkBuff].up )) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (position_back and ( ( buff[classtable.ComboPointsBuff].count <5 and debuff[classtable.RipDeBuff].remains <3.0 ) or ( buff[classtable.ComboPointsBuff].count == 0 and buff[classtable.SavageRoarBuff].remains <2 ) )) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (position_back and cooldown[classtable.TigersFury].remains <= 3.0) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (position_back and ttd <= 8.5) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (position_back and time_to_max_energy <= 1.0) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (position_front and ( buff[classtable.TigersFuryBuff].up or buff[classtable.BerserkBuff].up )) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (position_front and ( ( buff[classtable.ComboPointsBuff].count <5 and debuff[classtable.RipDeBuff].remains <3.0 ) or ( buff[classtable.ComboPointsBuff].count == 0 and buff[classtable.SavageRoarBuff].remains <2 ) )) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (position_front and cooldown[classtable.TigersFury].remains <= 3.0) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (position_front and ttd <= 8.5) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat')) and (position_front and time_to_max_energy <= 1.0) and cooldown[classtable.MangleCat].ready then
        if not setSpell then setSpell = classtable.MangleCat end
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
    classtable.Incarnation =  classtable.IncarnationAvatarofAshamane
    classtable.MoonfireCat =  classtable.Moonfire
    classtable.ThrashCat =  classtable.Thrash
    classtable.SwipeCat =  classtable.Swipe
    Energy = UnitPower('player', EnergyPT)
    EnergyMax = UnitPowerMax('player', EnergyPT)
    EnergyDeficit = EnergyMax - Energy
    EnergyRegen = GetPowerRegenForPowerType(Enum.PowerType.Energy)
    EnergyTimeToMax = EnergyDeficit / EnergyRegen
    EnergyPerc = (Energy / EnergyMax) * 100
    ComboPoints = UnitPower('player', ComboPointsPT)
    ComboPointsMax = UnitPowerMax('player', ComboPointsPT)
    ComboPointsDeficit = ComboPointsMax - ComboPoints
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.OmenofClarityBuff = 0
    classtable.TigersFuryBuff = 5217
    classtable.bloodlust = 0
    classtable.FaerieFireDeBuff = 0
    classtable.SunderArmorDeBuff = 0
    classtable.ExposeArmorDeBuff = 0
    classtable.MangleDeBuff = 0
    classtable.StampedeCatBuff = 0
    classtable.T134pcMeleeBuff = 0
    classtable.ComboPointsBuff = 0
    classtable.RipDeBuff = 1079
    classtable.BerserkBuff = 0
    classtable.SavageRoarBuff = 0
    classtable.RakeDeBuff = 155722
    setSpell = nil
    ClearCDs()

    Feral:callaction()
    if setSpell then return setSpell end
end
