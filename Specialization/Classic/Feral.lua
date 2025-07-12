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
    if MaxDps:FindBuffAuraData ( 768 ) .up then
        if (MaxDps:CheckSpellUsable(classtable.FaerieFire, 'FaerieFire')) and cooldown[classtable.FaerieFire].ready and not UnitAffectingCombat('player') then
            if not setSpell then setSpell = classtable.FaerieFire end
        end
        if (MaxDps:CheckSpellUsable(classtable.TigersFury, 'TigersFury')) and cooldown[classtable.TigersFury].ready and not UnitAffectingCombat('player') then
            MaxDps:GlowCooldown(classtable.TigersFury, cooldown[classtable.TigersFury].ready)
        end
    end
end
function Feral:priorityList()
    if MaxDps:FindBuffAuraData ( 768 ) .up then
        if (MaxDps:CheckSpellUsable(classtable.FaerieFire, 'FaerieFire')) and (MaxDps:FindBuffAuraData ( 17392 ) .remains <= 1.0 and MaxDps:FindBuffAuraData ( 9907 ) .remains <= 1.0) and cooldown[classtable.FaerieFire].ready then
            if not setSpell then setSpell = classtable.FaerieFire end
        end
        if (MaxDps:CheckSpellUsable(classtable.Haste, 'Haste')) and (MaxDps:FindBuffAuraData ( 768 ) .up and IsSpellKnownOrOverridesKnown ( 13494 ) and not MaxDps:FindBuffAuraData ( 13494 ) .up and timeInCombat <90.0) and cooldown[classtable.Haste].ready then
            if not setSpell then setSpell = classtable.Haste end
        end
        if (MaxDps:CheckSpellUsable(classtable.SavageRoar, 'SavageRoar')) and ( ComboPoints >= 1 and MaxDps:FindBuffAuraData ( 407988 ) .refreshable ) and cooldown[classtable.SavageRoar].ready then
            if not setSpell then setSpell = classtable.SavageRoar end
        end
        if (MaxDps:CheckSpellUsable(classtable.TigersFury, 'TigersFury')) and (EnergyDeficit >= 40) and cooldown[classtable.TigersFury].ready  then
            MaxDps:GlowCooldown(classtable.TigersFury, cooldown[classtable.TigersFury].ready)
        end
        if MaxDps:IsSoDWow() then
            if (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and (MaxDps:FindBuffAuraData ( 417045 ) .up) and cooldown[classtable.Berserk].ready  then
                MaxDps:GlowCooldown(classtable.Berserk, cooldown[classtable.Berserk].ready)
            end
            if (MaxDps:CheckSpellUsable(classtable.Mangle, 'Mangle')) and (not MaxDps:FindBuffAuraData ( 407993 ) .up) and cooldown[classtable.Mangle].ready  then
                if not setSpell then setSpell = classtable.Mangle end
            end
        end
        if MaxDps:IsSoDWow() then
            if (MaxDps:CheckSpellUsable(classtable.Rip, 'Rip')) and (ComboPoints >= 5 and not MaxDps:FindBuffAuraData ( 9896 ) .up and MaxDps:FindBuffAuraData ( 407988 ) .remains >= 8) and cooldown[classtable.Rip].ready  then
                if not setSpell then setSpell = classtable.Rip end
            end
        end
        if not MaxDps:IsSoDWow() then
            if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (ComboPoints == 5.0 and not MaxDps:FindBuffAuraData ( 16870 ) .up) and cooldown[classtable.FerociousBite].ready then
                if not setSpell then setSpell = classtable.FerociousBite end
            end
        end
        if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (not MaxDps:FindBuffAuraData ( 9904 ) .up) and cooldown[classtable.Rake].ready  then
            if not setSpell then setSpell = classtable.Rake end
        end
        if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (not UnitThreatSituation("player", "target") or UnitThreatSituation("player", "target") <= 1) and cooldown[classtable.Shred].ready then
            if not setSpell then setSpell = classtable.Shred end
        end
        if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (not UnitThreatSituation("player", "target") or UnitThreatSituation("player", "target") <= 1) and cooldown[classtable.Shred].ready then
            if not setSpell then setSpell = classtable.Shred end
        end
        if (MaxDps:CheckSpellUsable(classtable.Claw, 'Claw')) and (talents[17061] and MaxDps:CheckSpellUsable ( 768 , "cat_form" ) ) and cooldown[classtable.Claw].ready then
            if not setSpell then setSpell = classtable.Claw end
        end
        if (MaxDps:CheckSpellUsable(classtable.FaerieFire, 'FaerieFire')) and (MaxDps:FindBuffAuraData ( 17392 ) .remains <= 14.0 and MaxDps:FindBuffAuraData ( 9907 ) .remains <= 14.0) and cooldown[classtable.FaerieFire].ready then
            if not setSpell then setSpell = classtable.FaerieFire end
        end
        --if (MaxDps:CheckSpellUsable(classtable.GoblinSapperCharge, 'GoblinSapperCharge')) and (not MaxDps:FindBuffAuraData ( 768 ) .up) and cooldown[classtable.GoblinSapperCharge].ready then
        --    if not setSpell then setSpell = classtable.GoblinSapperCharge end
        --end
        --if (MaxDps:CheckSpellUsable(classtable.DemonicRune, 'DemonicRune')) and (not MaxDps:FindBuffAuraData ( 768 ) .up and Mana + 1500.0 <= Mana/ManaPerc) and cooldown[classtable.DemonicRune].ready then
        --    if not setSpell then setSpell = classtable.DemonicRune end
        --end
        --if (MaxDps:CheckSpellUsable(classtable.MetamorphosisRune, 'MetamorphosisRune')) and (not MaxDps:FindBuffAuraData ( 768 ) .up and ManaPerc <= 80 and not IsSpellKnownOrOverridesKnown ( 12662 ) ) and cooldown[classtable.MetamorphosisRune].ready then
        --    if not setSpell then setSpell = classtable.MetamorphosisRune end
        --end
        if (MaxDps:CheckSpellUsable(classtable.Innervate, 'Innervate')) and (not MaxDps:FindBuffAuraData ( 768 ) .up and ManaPerc <= 40 and ttd >= 20.0 and not IsSpellKnownOrOverridesKnown ( 12662 ) ) and cooldown[classtable.Innervate].ready then
            if not setSpell then setSpell = classtable.Innervate end
        end
        --if (MaxDps:CheckSpellUsable(classtable.CatForm, 'CatForm')) and (not MaxDps:FindBuffAuraData ( 768 ) .up) and cooldown[classtable.CatForm].ready then
        --    if not setSpell then setSpell = classtable.CatForm end
        --end
    end
    if MaxDps:FindBuffAuraData ( 5487 ) .up or MaxDps:FindBuffAuraData ( 9634 ) .up then
        if (MaxDps:CheckSpellUsable(classtable.Lacerate, 'Lacerate')) and (MaxDps:FindDeBuffAuraData ( classtable.Lacerate ) .refreshable or MaxDps:FindDeBuffAuraData ( classtable.Lacerate ) .count < 5) and cooldown[classtable.Lacerate].ready then
            if not setSpell then setSpell = classtable.Lacerate end
        end
        if (MaxDps:CheckSpellUsable(classtable.Mangle, 'Mangle')) and cooldown[classtable.Mangle].ready then
            if not setSpell then setSpell = classtable.Mangle end
        end
        if (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and (ttd >= 15) and cooldown[classtable.Berserk].ready then
            if not setSpell then setSpell = classtable.Berserk end
        end
        if (MaxDps:CheckSpellUsable(classtable.Swipe, 'Swipe')) and cooldown[classtable.Swipe].ready then
            if not setSpell then setSpell = classtable.Swipe end
        end
        if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and (Rage >= 30) and cooldown[classtable.Maul].ready then
            if not setSpell then setSpell = classtable.Maul end
        end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.TigersFury, false)
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
    ManaPerc = (Mana / ManaMax) * 100
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

    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    -- BearForm
    classtable.Lacerate=414644
    classtable.Mangle=407995
    classtable.Berserk=417141
    classtable.Swipe=9908
    classtable.Maul=9881

    -- CatForm
    classtable.FaerieFire=17392
    classtable.TigersFury=9846
    classtable.Haste=13494
    classtable.CatForm=768
    classtable.Shred=9830
    classtable.FerociousBite=22829
    classtable.Claw=9850
    classtable.GoblinSapperCharge=10646
    classtable.DemonicRune=12662
    classtable.MetamorphosisRune=23724
    classtable.Innervate=29166

    classtable.SavageRoar = 407988
    classtable.Rip = 9896
    classtable.Rake = 9904
    classtable.Shred = 9830


    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Feral:precombat()
    Feral:priorityList()
    if setSpell then return setSpell end
end
