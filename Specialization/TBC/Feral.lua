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

local Feral = {}

local ComboPoints
local ComboPointsMax
local ComboPointsDeficit
local Energy
local EnergyMax
local EnergyDeficit
local EnergyRegen
local EnergyTimeToMax
local EnergyPerc

local base, posBuff, negBuff
local totalAP

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.CatForm, false)
    MaxDps:GlowCooldown(classtable.DemoralizingRoar, false)
end

function Feral:AoE()
    if MaxDps:FindBuffAuraData(5487).up or MaxDps:FindBuffAuraData(9634).up then
        if (MaxDps:CheckSpellUsable(classtable.DemoralizingRoar, 'DemoralizingRoar')) and (MaxDps:FindDeBuffAuraData(classtable.DemoralizingRoar).refreshable) and cooldown[classtable.DemoralizingRoar].ready then
            --if not setSpell then setSpell = classtable.DemoralizingRoar end
            MaxDps:GlowCooldown(classtable.DemoralizingRoar, true)
        end
        if (MaxDps:CheckSpellUsable(classtable.Swipe, 'Swipe')) and cooldown[classtable.Swipe].ready then
            if not setSpell then setSpell = classtable.Swipe end
        end
        if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and cooldown[classtable.Maul].ready then
            if not setSpell then setSpell = classtable.Maul end
        end
    end
end

function Feral:Single()
    if MaxDps:FindBuffAuraData(classtable.CatForm) .up then
        if MaxDps:CheckSpellUsable(classtable.Rip, 'Rip') and ComboPoints >= 4 and ttd >= 12 and cooldown[classtable.Rip].ready then
            if not setSpell then setSpell = classtable.Rip end
        end
        if MaxDps:CheckSpellUsable(classtable.FerociousBite, 'Ferocious Bite') and ComboPoints >= 4 and cooldown[classtable.FerociousBite].ready then
            if not setSpell then setSpell = classtable.FerociousBite end
        end
        if MaxDps:CheckSpellUsable(classtable.MangleCat, 'MangleCat') and MaxDps:FindDeBuffAuraData(classtable.MangleCat).refreshable and cooldown[classtable.MangleCat].ready then
            if not setSpell then setSpell = classtable.MangleCat end
        end
        if MaxDps:CheckSpellUsable(classtable.Shred, 'Shred') and cooldown[classtable.Shred].ready then
            if not setSpell then setSpell = classtable.Shred end
        end
        if MaxDps:CheckSpellUsable(classtable.CatForm, 'Cat Form') and Energy <= 10 and cooldown[classtable.CatForm].ready then
            --if not setSpell then setSpell = classtable.CatForm end
            MaxDps:GlowCooldown(classtable.CatForm, true)
        end
    end
    if MaxDps:FindBuffAuraData(5487).up or MaxDps:FindBuffAuraData(9634).up then
        if targets >=3 then
            Feral:AoE()
        else
            if (MaxDps:CheckSpellUsable(classtable.DemoralizingRoar, 'DemoralizingRoar')) and (MaxDps:FindDeBuffAuraData(classtable.DemoralizingRoar).refreshable) and cooldown[classtable.DemoralizingRoar].ready then
                --if not setSpell then setSpell = classtable.DemoralizingRoar end
                MaxDps:GlowCooldown(classtable.DemoralizingRoar, true)
            end
            if (MaxDps:CheckSpellUsable(classtable.MangleBear, 'MangleBear')) and cooldown[classtable.MangleBear].ready then
                if not setSpell then setSpell = classtable.MangleBear end
            end
            if (MaxDps:CheckSpellUsable(classtable.Lacerate, 'Lacerate')) and (MaxDps:FindDeBuffAuraData(classtable.Lacerate).refreshable or MaxDps:FindDeBuffAuraData(classtable.Lacerate).count < 5) and cooldown[classtable.Lacerate].ready then
                if not setSpell then setSpell = classtable.Lacerate end
            end
            if (MaxDps:CheckSpellUsable(classtable.Swipe, 'Swipe')) and totalAP >= 2700 and cooldown[classtable.Swipe].ready then
                if not setSpell then setSpell = classtable.Swipe end
            end
            if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and cooldown[classtable.Maul].ready then
                if not setSpell then setSpell = classtable.Maul end
            end
        end
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

    ComboPoints = UnitPower('player', ComboPointsPT)
    ComboPointsMax = UnitPowerMax('player', ComboPointsPT)
    ComboPointsDeficit = ComboPointsMax - ComboPoints
    Energy = UnitPower('player', EnergyPT)
    EnergyMax = UnitPowerMax('player', EnergyPT)
    EnergyDeficit = EnergyMax - Energy
    EnergyRegen = GetPowerRegenForPowerType(Enum.PowerType.Energy)
    EnergyTimeToMax = EnergyDeficit / EnergyRegen
    EnergyPerc = (Energy / EnergyMax) * 100

    base, posBuff, negBuff = UnitAttackPower("player")
    totalAP = base + posBuff + negBuff


    classtable.Lacerate=414644
    classtable.MangleBear=407995
    classtable.Berserk=417141
    classtable.Swipe=9908
    classtable.Maul=9881
    classtable.DemoralizingRoar=26998

    --classtable.FaerieFire=17392
    --classtable.TigersFury=9846
    --classtable.Haste=13494
    classtable.CatForm=768
    classtable.Rip = 9896
    classtable.Shred=9830
    classtable.FerociousBite=22829
    --classtable.Claw=9850
    --classtable.Innervate=29166
    classtable.MangleCat=33876

    ClearCDs()

    --AoE Rotation
    if targets >= 3 then
        Feral:AoE()
    end

    --Single Target Rotation
    Feral:Single()

    if setSpell then return setSpell end
end
