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

local Rage
local RageMax
local RageDeficit

local Guardian = {}

function Guardian:precombat()
    if (MaxDps:CheckSpellUsable(classtable.MarkoftheWild, 'MarkoftheWild')) and (not buff[classtable.MarkoftheWildBuff].up) and cooldown[classtable.MarkoftheWild].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MarkoftheWild end
    end
end

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Berserk, false)
end

function Guardian:aoe()
    if (MaxDps:CheckSpellUsable(classtable.Thrash, 'Thrash')) and (not debuff[classtable.ThrashDeBuff].up) and cooldown[classtable.Thrash].ready then
        if not setSpell then setSpell = classtable.Thrash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Mangle, 'Mangle')) and cooldown[classtable.Mangle].ready then
        if not setSpell then setSpell = classtable.Mangle end
    end
    if (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and cooldown[classtable.Berserk].ready then
        MaxDps:GlowCooldown(classtable.Berserk, cooldown[classtable.Berserk].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SavageDefense, 'SavageDefense')) and cooldown[classtable.SavageDefense].ready then
        MaxDps:GlowCooldown(classtable.SavageDefense, cooldown[classtable.SavageDefense].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrenziedRegeneration, 'FrenziedRegeneration')) and cooldown[classtable.FrenziedRegeneration].ready then
        MaxDps:GlowCooldown(classtable.FrenziedRegeneration, cooldown[classtable.FrenziedRegeneration].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and (buff[classtable.ToothandClawBuff].up or healthPerc > 80) and cooldown[classtable.Maul].ready then
        if not setSpell then setSpell = classtable.Maul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Thrash, 'Thrash')) and cooldown[classtable.Thrash].ready then
        if not setSpell then setSpell = classtable.Thrash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Swipe, 'Swipe')) and cooldown[classtable.Swipe].ready then
        if not setSpell then setSpell = classtable.Swipe end
    end
end

function Guardian:single()
    -- Single Target Priority
    if (MaxDps:CheckSpellUsable(classtable.Mangle, 'Mangle')) and cooldown[classtable.Mangle].ready then
        if not setSpell then setSpell = classtable.Mangle end
    end
    if (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and cooldown[classtable.Berserk].ready then
        MaxDps:GlowCooldown(classtable.Berserk, cooldown[classtable.Berserk].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SavageDefense, 'SavageDefense')) and cooldown[classtable.SavageDefense].ready then
        MaxDps:GlowCooldown(classtable.SavageDefense, cooldown[classtable.SavageDefense].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrenziedRegeneration, 'FrenziedRegeneration')) and cooldown[classtable.FrenziedRegeneration].ready then
        MaxDps:GlowCooldown(classtable.FrenziedRegeneration, cooldown[classtable.FrenziedRegeneration].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Maul, 'Maul')) and (buff[classtable.ToothandClawBuff].up or healthPerc > 80) and cooldown[classtable.Maul].ready then
        if not setSpell then setSpell = classtable.Maul end
    end
    if (MaxDps:CheckSpellUsable(classtable.Thrash, 'Thrash')) and (not debuff[classtable.ThrashDeBuff].up) and cooldown[classtable.Thrash].ready then
        if not setSpell then setSpell = classtable.Thrash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Lacerate, 'Lacerate')) and (debuff[classtable.LacerateDeBuff].count < 3) and cooldown[classtable.Lacerate].ready then
        if not setSpell then setSpell = classtable.Lacerate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Enrage, 'Enrage')) and cooldown[classtable.Enrage].ready then
        MaxDps:GlowCooldown(classtable.Enrage, cooldown[classtable.Enrage].ready)
    end
end

function Guardian:callaction()
    -- AoE Priority
    if targets > 1 then
        Guardian:aoe()
    end
    Guardian:single()
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
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    Rage = UnitPower('player', RagePT)
    RageMax = UnitPowerMax('player', RagePT)
    RageDeficit = RageMax - Rage
    classtable = MaxDps.SpellTable

    classtable.Mangle = 33917
    classtable.Berserk = 50334
    classtable.SavageDefense = 62606
    classtable.FrenziedRegeneration = 22842
    classtable.Maul = 6807
    classtable.Thrash = 77758
    classtable.Lacerate = 33745
    classtable.Enrage = 5229
    classtable.Swipe = 213771
    classtable.ToothandClawBuff = 135286
    classtable.MarkoftheWildBuff = 1126
    classtable.ThrashDeBuff = 77758
    classtable.LacerateDeBuff = 33745

    setSpell = nil
    ClearCDs()

    Guardian:precombat()
    Guardian:callaction()
    if setSpell then return setSpell end
end