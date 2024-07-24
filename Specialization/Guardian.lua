local _, addonTable = ...
local Druid = addonTable.Druid
local MaxDps = _G.MaxDps
if not MaxDps then return end

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local GetSpellDescription = GetSpellDescription
local GetSpellPowerCost = C_Spell.GetSpellPowerCost
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit

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

local If_build
local catweave_bear
local owlweave_bear

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc < 15 then
            return true
        else
            return false
        end
    end
    local costs = GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end

function Guardian:precombat()
    if (MaxDps:FindSpell(classtable.Flask) and CheckSpellCosts(classtable.Flask, 'Flask')) and cooldown[classtable.Flask].ready then
        return classtable.Flask
    end
    if (MaxDps:FindSpell(classtable.Food) and CheckSpellCosts(classtable.Food, 'Food')) and cooldown[classtable.Food].ready then
        return classtable.Food
    end
    if (MaxDps:FindSpell(classtable.Augmentation) and CheckSpellCosts(classtable.Augmentation, 'Augmentation')) and cooldown[classtable.Augmentation].ready then
        return classtable.Augmentation
    end
    if (MaxDps:FindSpell(classtable.SnapshotStats) and CheckSpellCosts(classtable.SnapshotStats, 'SnapshotStats')) and cooldown[classtable.SnapshotStats].ready then
        return classtable.SnapshotStats
    end
    if talents[classtable.ThornsofIron] and talents[classtable.ReinforcedFur] then
        If_build = 1
    else
        If_build = 0
    end
    catweave_bear = false
    owlweave_bear = false
    if (MaxDps:FindSpell(classtable.CatForm) and CheckSpellCosts(classtable.CatForm, 'CatForm')) and (( catweave_bear and ( timeInCombat >30 ) )) and cooldown[classtable.CatForm].ready then
        return classtable.CatForm
    end
    if (MaxDps:FindSpell(classtable.MoonkinForm) and CheckSpellCosts(classtable.MoonkinForm, 'MoonkinForm')) and (( not catweave_bear ) and ( timeInCombat >30 )) and cooldown[classtable.MoonkinForm].ready then
        return classtable.MoonkinForm
    end
    if (MaxDps:FindSpell(classtable.HeartoftheWild) and CheckSpellCosts(classtable.HeartoftheWild, 'HeartoftheWild')) and (talents[classtable.HeartoftheWild]) and cooldown[classtable.HeartoftheWild].ready then
        return classtable.HeartoftheWild
    end
    if (MaxDps:FindSpell(classtable.Prowl) and CheckSpellCosts(classtable.Prowl, 'Prowl')) and (catweave_bear and ( timeInCombat >30 )) and cooldown[classtable.Prowl].ready then
        return classtable.Prowl
    end
    if (MaxDps:FindSpell(classtable.BearForm) and CheckSpellCosts(classtable.BearForm, 'BearForm')) and (( not buff[classtable.ProwlBuff].up )) and cooldown[classtable.BearForm].ready then
        return classtable.BearForm
    end
end
function Guardian:bear()
    if talents[classtable.ThornsofIron] and talents[classtable.ReinforcedFur] then
        If_build = 1
    else
        If_build = 0
    end
    if (MaxDps:FindSpell(classtable.BearForm) and CheckSpellCosts(classtable.BearForm, 'BearForm')) and (not buff[classtable.BearFormBuff].up) and cooldown[classtable.BearForm].ready then
        return classtable.BearForm
    end
    if (MaxDps:FindSpell(classtable.HeartoftheWild) and CheckSpellCosts(classtable.HeartoftheWild, 'HeartoftheWild')) and (talents[classtable.HeartoftheWild]) and cooldown[classtable.HeartoftheWild].ready then
        return classtable.HeartoftheWild
    end
    if (MaxDps:FindSpell(classtable.Moonfire) and CheckSpellCosts(classtable.Moonfire, 'Moonfire')) and (( ( ( not debuff[classtable.MoonfireDebuff].up and ttd >12 ) or ( debuff[classtable.MoonfireDebuff].refreshable and ttd >12 ) ) and targets <7 and talents[classtable.FuryofNature] ) or ( ( ( not debuff[classtable.MoonfireDebuff].up and ttd >12 ) or ( debuff[classtable.MoonfireDebuff].refreshable and ttd >12 ) ) and targets <4 and not talents[classtable.FuryofNature] )) and cooldown[classtable.Moonfire].ready then
        return classtable.Moonfire
    end
    if (MaxDps:FindSpell(classtable.Thrash) and CheckSpellCosts(classtable.Thrash, 'Thrash')) and (debuff[classtable.Thrash].refreshable or ( debuff[classtable.ThrashBearDeBuff].count <5 and talents[classtable.FlashingClaws] == 2 or debuff[classtable.ThrashBearDeBuff].count <4 and talents[classtable.FlashingClaws] == 1 or debuff[classtable.ThrashBearDeBuff].count <3 and not talents[classtable.FlashingClaws] )) and cooldown[classtable.Thrash].ready then
        return classtable.Thrash
    end
    if (MaxDps:FindSpell(classtable.BristlingFur) and CheckSpellCosts(classtable.BristlingFur, 'BristlingFur')) and ( cooldown[classtable.RageoftheSleeper].remains >8) and cooldown[classtable.BristlingFur].ready then
        return classtable.BristlingFur
    end
    if (MaxDps:FindSpell(classtable.Barkskin) and CheckSpellCosts(classtable.Barkskin, 'Barkskin')) and (buff[classtable.BearFormBuff].up) and cooldown[classtable.Barkskin].ready then
        return classtable.Barkskin
    end
    if (MaxDps:FindSpell(classtable.ConvoketheSpirits) and CheckSpellCosts(classtable.ConvoketheSpirits, 'ConvoketheSpirits')) and cooldown[classtable.ConvoketheSpirits].ready then
        return classtable.ConvoketheSpirits
    end
    if (MaxDps:FindSpell(classtable.Berserk) and CheckSpellCosts(classtable.Berserk, 'Berserk')) and cooldown[classtable.Berserk].ready then
        return classtable.Berserk
    end
    if (MaxDps:FindSpell(classtable.Incarnation) and CheckSpellCosts(classtable.Incarnation, 'Incarnation')) and cooldown[classtable.Incarnation].ready then
        return classtable.Incarnation
    end
    if (MaxDps:FindSpell(classtable.LunarBeam) and CheckSpellCosts(classtable.LunarBeam, 'LunarBeam')) and cooldown[classtable.LunarBeam].ready then
        return classtable.LunarBeam
    end
    if (MaxDps:FindSpell(classtable.RageoftheSleeper) and CheckSpellCosts(classtable.RageoftheSleeper, 'RageoftheSleeper')) and (( ( not buff[classtable.IncarnationGuardianofUrsocBuff].up and cooldown[classtable.IncarnationGuardianofUrsoc].remains >60 ) or not buff[classtable.BerserkBearBuff].up ) and Rage >75 and ( not talents[classtable.ConvoketheSpirits] ) or ( buff[classtable.IncarnationGuardianofUrsocBuff].up or buff[classtable.BerserkBearBuff].up ) and Rage >75 and ( not talents[classtable.ConvoketheSpirits] ) or ( talents[classtable.ConvoketheSpirits] ) and Rage >75) and cooldown[classtable.RageoftheSleeper].ready then
        return classtable.RageoftheSleeper
    end
    if (MaxDps:FindSpell(classtable.Maul) and CheckSpellCosts(classtable.Maul, 'Maul')) and (( buff[classtable.RageoftheSleeperBuff].up and buff[classtable.ToothandClawBuff].count >0 and targets <= 6 and not talents[classtable.Raze] and If_build == 0 ) or ( buff[classtable.RageoftheSleeperBuff].up and buff[classtable.ToothandClawBuff].count >0 and targets == 1 and talents[classtable.Raze] and If_build == 0 )) and cooldown[classtable.Maul].ready then
        return classtable.Maul
    end
    if (MaxDps:FindSpell(classtable.Raze) and CheckSpellCosts(classtable.Raze, 'Raze')) and (buff[classtable.RageoftheSleeperBuff].up and buff[classtable.ToothandClawBuff].count >0 and If_build == 0 and targets >1) and cooldown[classtable.Raze].ready then
        return classtable.Raze
    end
    if (MaxDps:FindSpell(classtable.Maul) and CheckSpellCosts(classtable.Maul, 'Maul')) and (( ( ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and targets <= 5 and not talents[classtable.Raze] and ( buff[classtable.ToothandClawBuff].count >= 1 ) ) and If_build == 0 ) and cooldown[classtable.RageoftheSleeper].remains >3 or ( ( ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and targets == 1 and talents[classtable.Raze] and ( buff[classtable.ToothandClawBuff].count >= 1 ) ) and If_build == 0 ) and cooldown[classtable.RageoftheSleeper].remains >3 or ( ( ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and targets <= 5 and not talents[classtable.Raze] and ( buff[classtable.ToothandClawBuff].count >= 1 ) ) and If_build == 0 ) and buff[classtable.RageoftheSleeperBuff].up or ( ( ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and targets == 1 and talents[classtable.Raze] and ( buff[classtable.ToothandClawBuff].count >= 1 ) ) and If_build == 0 ) and buff[classtable.RageoftheSleeperBuff].up) and cooldown[classtable.Maul].ready then
        return classtable.Maul
    end
    if (MaxDps:FindSpell(classtable.Raze) and CheckSpellCosts(classtable.Raze, 'Raze')) and (( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and ( If_build == 0 ) and targets >1 and cooldown[classtable.RageoftheSleeper].remains >3 or ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and ( If_build == 0 ) and targets >1 and buff[classtable.RageoftheSleeperBuff].up) and cooldown[classtable.Raze].ready then
        return classtable.Raze
    end
    --if (MaxDps:FindSpell(classtable.Ironfur) and CheckSpellCosts(classtable.Ironfur, 'Ironfur')) and (not buff[classtable.IronfurBuff].up and Rage >50 and If_build == 0 and not buff[classtable.RageoftheSleeperBuff].up and cooldown[classtable.RageoftheSleeper].remains >3 and not buff[classtable.BlazingThornsBuff].up or Rage >90 and If_build == 0 and not buff[classtable.RageoftheSleeperBuff].up and cooldown[classtable.RageoftheSleeper].remains >3 and not buff[classtable.BlazingThornsBuff].up or not debuff[classtable.ToothandClawDebuffDeBuff].up or ( not buff[classtable.IronfurBuff].up and Rage >50 and If_build == 0 and buff[classtable.RageoftheSleeperBuff].up and not buff[classtable.BlazingThornsBuff].up or Rage >90 and If_build == 0 and buff[classtable.RageoftheSleeperBuff].up and not buff[classtable.BlazingThornsBuff].up ) or ( not debuff[classtable.ToothandClawDebuffDeBuff].up )) and cooldown[classtable.Ironfur].ready then
    --    return classtable.Ironfur
    --end
    --if (MaxDps:FindSpell(classtable.Ironfur) and CheckSpellCosts(classtable.Ironfur, 'Ironfur')) and (Rage >90 and If_build == 1 and cooldown[classtable.RageoftheSleeper].remains >3 or ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and Rage >20 and If_build == 1 and cooldown[classtable.RageoftheSleeper].remains >3 or Rage >90 and If_build == 1 and buff[classtable.RageoftheSleeperBuff].up or ( buff[classtable.IncarnationBuff].up or buff[classtable.BerserkBearBuff].up ) and Rage >20 and If_build == 1 and buff[classtable.RageoftheSleeperBuff].up) and cooldown[classtable.Ironfur].ready then
    --    return classtable.Ironfur
    --end
    if (MaxDps:FindSpell(classtable.Raze) and CheckSpellCosts(classtable.Raze, 'Raze')) and (( buff[classtable.ToothandClawBuff].up ) and targets >1 and cooldown[classtable.RageoftheSleeper].remains >3 or ( buff[classtable.ToothandClawBuff].up ) and targets >1 and buff[classtable.RageoftheSleeperBuff].up) and cooldown[classtable.Raze].ready then
        return classtable.Raze
    end
    if (MaxDps:FindSpell(classtable.Raze) and CheckSpellCosts(classtable.Raze, 'Raze')) and (( If_build == 0 ) and targets >1 and cooldown[classtable.RageoftheSleeper].remains >3 or ( If_build == 0 ) and targets >1 and buff[classtable.RageoftheSleeperBuff].up) and cooldown[classtable.Raze].ready then
        return classtable.Raze
    end
    if (MaxDps:FindSpell(classtable.Mangle) and CheckSpellCosts(classtable.Mangle, 'Mangle')) and (buff[classtable.GoreBuff].up and targets <11 or buff[classtable.ViciousCycleMangleBuff].count == 3) and cooldown[classtable.Mangle].ready then
        return classtable.Mangle
    end
    if (MaxDps:FindSpell(classtable.Maul) and CheckSpellCosts(classtable.Maul, 'Maul')) and (( buff[classtable.ToothandClawBuff].up and targets <= 5 and not talents[classtable.Raze] ) and cooldown[classtable.RageoftheSleeper].remains >3 or ( buff[classtable.ToothandClawBuff].up and targets == 1 and talents[classtable.Raze] ) and cooldown[classtable.RageoftheSleeper].remains >3 or ( buff[classtable.ToothandClawBuff].up and targets <= 5 and not talents[classtable.Raze] ) and buff[classtable.RageoftheSleeperBuff].up or ( buff[classtable.ToothandClawBuff].up and targets == 1 and talents[classtable.Raze] ) and buff[classtable.RageoftheSleeperBuff].up) and cooldown[classtable.Maul].ready then
        return classtable.Maul
    end
    if (MaxDps:FindSpell(classtable.Maul) and CheckSpellCosts(classtable.Maul, 'Maul')) and (( targets <= 5 and not talents[classtable.Raze] and If_build == 0 ) and cooldown[classtable.RageoftheSleeper].remains >3 or ( targets == 1 and talents[classtable.Raze] and If_build == 0 ) and cooldown[classtable.RageoftheSleeper].remains >3 or ( targets <= 5 and not talents[classtable.Raze] and If_build == 0 ) and buff[classtable.RageoftheSleeperBuff].up or ( targets == 1 and talents[classtable.Raze] and If_build == 0 ) and buff[classtable.RageoftheSleeperBuff].up) and cooldown[classtable.Maul].ready then
        return classtable.Maul
    end
    if (MaxDps:FindSpell(classtable.Thrash) and CheckSpellCosts(classtable.Thrash, 'Thrash')) and (targets >= 5) and cooldown[classtable.Thrash].ready then
        return classtable.Thrash
    end
    if (MaxDps:FindSpell(classtable.Swipe) and CheckSpellCosts(classtable.Swipe, 'Swipe')) and (not buff[classtable.IncarnationGuardianofUrsocBuff].up and not buff[classtable.BerserkBearBuff].up and targets >= 11) and cooldown[classtable.Swipe].ready then
        return classtable.Swipe
    end
    if (MaxDps:FindSpell(classtable.Mangle) and CheckSpellCosts(classtable.Mangle, 'Mangle')) and (( buff[classtable.IncarnationBuff].up and targets <= 4 ) or ( buff[classtable.IncarnationBuff].up and talents[classtable.SouloftheForest] and targets <= 5 ) or ( ( Rage <90 ) and targets <11 ) or ( ( Rage <85 ) and targets <11 and talents[classtable.SouloftheForest] )) and cooldown[classtable.Mangle].ready then
        return classtable.Mangle
    end
    if (MaxDps:FindSpell(classtable.Thrash) and CheckSpellCosts(classtable.Thrash, 'Thrash')) and (targets >1) and cooldown[classtable.Thrash].ready then
        return classtable.Thrash
    end
    if (MaxDps:FindSpell(classtable.Pulverize) and CheckSpellCosts(classtable.Pulverize, 'Pulverize')) and (debuff[classtable.ThrashBearDeBuff].count >2) and cooldown[classtable.Pulverize].ready then
        return classtable.Pulverize
    end
    if (MaxDps:FindSpell(classtable.Thrash) and CheckSpellCosts(classtable.Thrash, 'Thrash')) and cooldown[classtable.Thrash].ready then
        return classtable.Thrash
    end
    if (MaxDps:FindSpell(classtable.Moonfire) and CheckSpellCosts(classtable.Moonfire, 'Moonfire')) and (buff[classtable.GalacticGuardianBuff].up) and cooldown[classtable.Moonfire].ready then
        return classtable.Moonfire
    end
    if (MaxDps:FindSpell(classtable.Swipe) and CheckSpellCosts(classtable.Swipe, 'SwipeBear')) and cooldown[classtable.Swipe].ready then
        return classtable.Swipe
    end
end
function Guardian:catweave()
    if (MaxDps:FindSpell(classtable.HeartoftheWild) and CheckSpellCosts(classtable.HeartoftheWild, 'HeartoftheWild')) and (talents[classtable.HeartoftheWild] and not buff[classtable.HeartoftheWildBuff].up and not buff[classtable.CatFormBuff].up) and cooldown[classtable.HeartoftheWild].ready then
        return classtable.HeartoftheWild
    end
    if (MaxDps:FindSpell(classtable.CatForm) and CheckSpellCosts(classtable.CatForm, 'CatForm')) and (not buff[classtable.CatFormBuff].up) and cooldown[classtable.CatForm].ready then
        return classtable.CatForm
    end
    if (MaxDps:FindSpell(classtable.Rake) and CheckSpellCosts(classtable.Rake, 'Rake')) and (buff[classtable.ProwlBuff].up) and cooldown[classtable.Rake].ready then
        return classtable.Rake
    end
    if (MaxDps:FindSpell(classtable.HeartoftheWild) and CheckSpellCosts(classtable.HeartoftheWild, 'HeartoftheWild')) and (talents[classtable.HeartoftheWild] and not buff[classtable.HeartoftheWildBuff].up) and cooldown[classtable.HeartoftheWild].ready then
        return classtable.HeartoftheWild
    end
    if (MaxDps:FindSpell(classtable.Rake) and CheckSpellCosts(classtable.Rake, 'Rake')) and (debuff[classtable.RakeDeBuff].refreshable or Energy <45) and cooldown[classtable.Rake].ready then
        return classtable.Rake
    end
    if (MaxDps:FindSpell(classtable.Rip) and CheckSpellCosts(classtable.Rip, 'Rip')) and (debuff[classtable.RipDeBuff].refreshable and ComboPoints >= 1) and cooldown[classtable.Rip].ready then
        return classtable.Rip
    end
    if (MaxDps:FindSpell(classtable.ConvoketheSpirits) and CheckSpellCosts(classtable.ConvoketheSpirits, 'ConvoketheSpirits')) and cooldown[classtable.ConvoketheSpirits].ready then
        return classtable.ConvoketheSpirits
    end
    if (MaxDps:FindSpell(classtable.FerociousBite) and CheckSpellCosts(classtable.FerociousBite, 'FerociousBite')) and (ComboPoints >= 4 and Energy >50) and cooldown[classtable.FerociousBite].ready then
        return classtable.FerociousBite
    end
    if (MaxDps:FindSpell(classtable.Shred) and CheckSpellCosts(classtable.Shred, 'Shred')) and (ComboPoints <= 5) and cooldown[classtable.Shred].ready then
        return classtable.Shred
    end
end

function Druid:Guardian()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = MaxDps.PlayerAuras
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('target')
    SpellCrit = GetCritChance()
    LunarPower = UnitPower('player', LunarPowerPT)
    LunarPowerMax = UnitPowerMax('player', LunarPowerPT)
    LunarPowerDeficit = LunarPowerMax - LunarPower
    Rage = UnitPower('player', RagePT)
    RageMax = UnitPowerMax('player', RagePT)
    RageDeficit = RageMax - Rage
    Energy = UnitPower('player', EnergyPT)
    EnergyMax = UnitPowerMax('player', EnergyPT)
    EnergyDeficit = EnergyMax - Energy
    EnergyRegen = GetPowerRegenForPowerType(Enum.PowerType.Energy)
    EnergyTimeToMax = EnergyDeficit / EnergyRegen
    EnergyPerc = (Energy / EnergyMax) * 100
    ComboPoints = UnitPower('player', ComboPointsPT)
    ComboPointsMax = UnitPowerMax('player', ComboPointsPT)
    ComboPointsDeficit = ComboPointsMax - ComboPoints
    classtable.ProwlBuff = 5215
    classtable.BearFormBuff = 5487
    classtable.ThrashBearDeBuff = 77758
    classtable.IncarnationGuardianofUrsocBuff = 102558
    classtable.BerserkBearBuff = 50334
    classtable.RageoftheSleeperBuff = 200851
    classtable.ToothandClawBuff = 135286
    classtable.IncarnationBuff = 102558
    classtable.IronfurBuff = 192081
    classtable.BlazingThornsBuff = 425441
    classtable.ToothandClawDebuffDeBuff = 135601
    classtable.GoreBuff = 93622
    classtable.ViciousCycleMangleBuff = 372015
    classtable.GalacticGuardianBuff = 213708
    classtable.HeartoftheWildBuff = 319454
    classtable.CatFormBuff = 768
    classtable.RakeDeBuff = 155722
    classtable.RipDeBuff = 1079
	classtable.MoonfireDebuff = 164812
	classtable.Berserk = 50334
	classtable.Incarnation = 102558

    --if (MaxDps:FindSpell(classtable.AutoAttack) and CheckSpellCosts(classtable.AutoAttack, 'AutoAttack')) and (not buff[classtable.ProwlBuff].up) and cooldown[classtable.AutoAttack].ready then
    --    return classtable.AutoAttack
    --end
    --if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (( ( talents[classtable.HeartoftheWild] and buff[classtable.HeartoftheWildBuff].up ) or ( ( buff[classtable.BerserkBearBuff].up or buff[classtable.IncarnationGuardianofUrsocBuff].up ) and ( not catweave_bear and not owlweave_bear ) ) )) and cooldown[classtable.Potion].ready then
    --    return classtable.Potion
    --end
    --if (( target.cooldown.pause_action.remains or timeInCombat >= 30 ) and catweave_bear and buff[classtable.ToothandClawBuff].remains >1.5 and ( not buff[classtable.IncarnationGuardianofUrsocBuff].up and not buff[classtable.BerserkBearBuff].up ) and ( cooldown[classtable.ThrashBear].remains >0 and cooldown[classtable.Mangle].remains >0 and debuff[classtable.MoonfireDeBuff].remains >= 2 ) or ( buff[classtable.CatFormBuff].up and Energy >25 and catweave_bear and buff[classtable.ToothandClawBuff].remains >1.5 ) or ( buff[classtable.HeartoftheWildBuff].up and Energy >90 and catweave_bear and buff[classtable.ToothandClawBuff].remains >1.5 )) then
    --    local catweaveCheck = Guardian:catweave()
    --    if catweaveCheck then
    --        return Guardian:catweave()
    --    end
    --end
    local bearCheck = Guardian:bear()
    if bearCheck then
        return bearCheck
    end

end
