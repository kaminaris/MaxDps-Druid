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

local Guardian = {}


function Guardian:precombat()

end

function Guardian:priorityList()
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


local function ClearCDs()
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

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Guardian:precombat()
    Guardian:priorityList()
    if setSpell then return setSpell end
end
