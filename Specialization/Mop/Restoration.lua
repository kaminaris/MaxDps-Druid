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

local Mana
local ManaMax
local ManaDeficit
local ManaPerc

local Restoration = {}

function Restoration:precombat()
end

local function ClearCDs()
end

function Restoration:callaction()
    if targets >= 3 then
        if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and debuff[classtable.Sunfire].refreshable then
            if not setSpell then setSpell = classtable.Sunfire end
        end
        if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and debuff[classtable.Moonfire].refreshable then
            if not setSpell then setSpell = classtable.Moonfire end
        end
    else
        if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and debuff[classtable.Moonfire].refreshable then
            if not setSpell then setSpell = classtable.Moonfire end
        end
        if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and debuff[classtable.Sunfire].refreshable then
            if not setSpell then setSpell = classtable.Sunfire end
        end
    end

    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
end

function Druid:Restoration()
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
    targethealthPerc = (targetHP > 0 and targetmaxHP > 0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    ManaPerc = (Mana / ManaMax) * 100

    classtable.Moonfire = 8921
    classtable.Sunfire = 93402

    setSpell = nil
    ClearCDs()

    Restoration:precombat()
    Restoration:callaction()

    if setSpell then return setSpell end
end