local _, addonTable = ...
local Druid = addonTable.Druid
local MaxDps = _G.MaxDps
if not MaxDps then return end

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
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
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

local Restoration = {}

function Restoration:precombat()
    if (MaxDps:CheckSpellUsable(classtable.HeartoftheWild, 'HeartoftheWild')) and cooldown[classtable.HeartoftheWild].ready then
        return classtable.HeartoftheWild
    end
    if (MaxDps:CheckSpellUsable(classtable.CatForm, 'CatForm')) and (talents[classtable.Rake]) and cooldown[classtable.CatForm].ready and not buff[classtable.CatForm].up then
        return classtable.CatForm
    end
    --if (MaxDps:CheckSpellUsable(classtable.Prowl, 'Prowl')) and (talents[classtable.Rake]) and cooldown[classtable.Prowl].ready then
    --    return classtable.Prowl
    --end
end
function Restoration:cat()
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (buff[classtable.ShadowmeldBuff].up or buff[classtable.ProwlBuff].up or buff[classtable.SuddenAmbushBuff].up) and cooldown[classtable.Rake].ready then
        return classtable.Rake
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartoftheWild, 'HeartoftheWild')) and (( cooldown[classtable.ConvoketheSpirits].remains <40 or not talents[classtable.ConvoketheSpirits] ) or ttd <46) and cooldown[classtable.HeartoftheWild].ready then
        return classtable.HeartoftheWild
    end
    if (MaxDps:CheckSpellUsable(classtable.Rip, 'Rip')) and (( ( debuff[classtable.RipDeBuff].refreshable or Energy >90 and debuff[classtable.RipDeBuff].remains <= 10 ) and ( ComboPoints == 5 and ttd >debuff[classtable.RipDeBuff].remains + 24 or ( debuff[classtable.RipDeBuff].remains + ComboPoints * 4 <ttd and debuff[classtable.RipDeBuff].remains + 4 + ComboPoints * 4 >ttd ) ) or not debuff[classtable.RipDeBuff].up and ComboPoints >2 + targets * 2 )) and cooldown[classtable.Rip].ready then
        return classtable.Rip
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (debuff[classtable.ThrashCatDeBuff].refreshable and ttd >7 and targets >2) and cooldown[classtable.ThrashCat].ready then
        return classtable.ThrashCat
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (( debuff[classtable.SunfireDeBuff].refreshable and ttd >5 ) and not (MaxDps.spellHistory[1] == classtable.CatForm) and ( targets == 1 or talents[classtable.ImprovedSunfire] )) and cooldown[classtable.Sunfire].ready then
        return classtable.Sunfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (debuff[classtable.RakeDeBuff].refreshable and ttd >10 and targets <10) and cooldown[classtable.Rake].ready then
        return classtable.Rake
    end
    if (MaxDps:CheckSpellUsable(classtable.CatForm, 'CatForm')) and (not buff[classtable.CatFormBuff].up and Energy >50 and ( debuff[classtable.RakeDeBuff].refreshable and targets >3 and targets <7 and talents[classtable.Thrash] )) and cooldown[classtable.CatForm].ready and not buff[classtable.CatForm].up then
        return classtable.CatForm
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (( debuff[classtable.MoonfireDeBuff].refreshable and ttd >12 and not debuff[classtable.MoonfireDeBuff].up or ( (MaxDps.spellHistory[1] == classtable.Sunfire) and debuff[classtable.MoonfireDeBuff].remains <( classtable and classtable.Moonfire and GetSpellInfo(classtable.Moonfire).castTime /1000 ) * 0.8 and targets == 1 ) ) and not (MaxDps.spellHistory[1] == classtable.CatForm) and targets <6) and cooldown[classtable.Moonfire].ready then
        return classtable.Moonfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and ((MaxDps.spellHistory[1] == classtable.Moonfire) and debuff[classtable.SunfireDeBuff].remains <( classtable and classtable.Sunfire and GetSpellInfo(classtable.Sunfire).castTime /1000 ) * 0.8) and cooldown[classtable.Sunfire].ready then
        return classtable.Sunfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (targets == 1 or ( targets <8 and not buff[classtable.CatFormBuff].up )) and cooldown[classtable.Starsurge].ready then
        return classtable.Starsurge
    end
    if (MaxDps:CheckSpellUsable(classtable.CatForm, 'CatForm')) and (not buff[classtable.CatFormBuff].up and Energy >50) and cooldown[classtable.CatForm].ready then
        return classtable.CatForm
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (( ComboPoints >3 and ttd <3 ) or ( ComboPoints == 5 and Energy >= 50 and debuff[classtable.RipDeBuff].remains >10 ) and targets <4) and cooldown[classtable.FerociousBite].ready then
        return classtable.FerociousBite
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (debuff[classtable.ThrashCatDeBuff].refreshable and ttd >6 and ( targets >1 or talents[classtable.Liveliness] )) and cooldown[classtable.ThrashCat].ready then
        return classtable.ThrashCat
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (targets >3 and ComboPoints <5 and talents[classtable.ImprovedSwipe]) and cooldown[classtable.SwipeCat].ready then
        return classtable.SwipeCat
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].refreshable and ttd >5 and targets <7 and not talents[classtable.ImprovedSunfire]) and cooldown[classtable.Sunfire].ready then
        return classtable.Sunfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (Energy >60 and ComboPoints <5) and cooldown[classtable.Shred].ready then
        return classtable.Shred
    end
end

function Restoration:callaction()
    if (MaxDps:CheckSpellUsable(classtable.SkullBash, 'SkullBash')) and cooldown[classtable.SkullBash].ready then
        MaxDps:GlowCooldown(classtable.SkullBash, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.NaturesVigil, 'NaturesVigil')) and (not buff[classtable.ProwlBuff].up and not buff[classtable.ShadowmeldBuff].up) and cooldown[classtable.NaturesVigil].ready then
        return classtable.NaturesVigil
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartoftheWild, 'HeartoftheWild')) and (not buff[classtable.ProwlBuff].up and not buff[classtable.ShadowmeldBuff].up) and cooldown[classtable.HeartoftheWild].ready then
        return classtable.HeartoftheWild
    end
    if (talents[classtable.Rake]) then
        local catCheck = Restoration:cat()
        if catCheck then
            return Restoration:cat()
        end
    end
    if (MaxDps:CheckSpellUsable(classtable.CatForm, 'CatForm')) and (talents[classtable.Rake]) and cooldown[classtable.CatForm].ready and not buff[classtable.CatForm].up then
        return classtable.CatForm
    end
    if (MaxDps:CheckSpellUsable(classtable.ConvoketheSpirits, 'ConvoketheSpirits')) and (( buff[classtable.HeartoftheWildBuff].up or cooldown[classtable.HeartoftheWild].remains >60 - 30 * (talents[classtable.CenariusGuidance] and talents[classtable.CenariusGuidance] or 0) or not talents[classtable.HeartoftheWild] )) and cooldown[classtable.ConvoketheSpirits].ready then
        MaxDps:GlowCooldown(classtable.ConvoketheSpirits, cooldown[classtable.ConvoketheSpirits].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].refreshable and ttd >5 and talents[classtable.ImprovedSunfire]) and cooldown[classtable.Sunfire].ready then
        return classtable.Sunfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (debuff[classtable.MoonfireDeBuff].refreshable and ttd >12) and cooldown[classtable.Moonfire].ready then
        return classtable.Moonfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (targets <8) and cooldown[classtable.Starsurge].ready then
        return classtable.Starsurge
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].refreshable and ttd >7 and targets <7) and cooldown[classtable.Sunfire].ready then
        return classtable.Sunfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (targets >1 or buff[classtable.HeartoftheWildBuff].up) and cooldown[classtable.Starfire].ready then
        return classtable.Starfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and cooldown[classtable.Wrath].ready and not buff[classtable.CatForm].up then
        return classtable.Wrath
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
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    LunarPower = UnitPower('player', LunarPowerPT)
    LunarPowerMax = UnitPowerMax('player', LunarPowerPT)
    LunarPowerDeficit = LunarPowerMax - LunarPower
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
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.ShadowmeldBuff = 58984
    classtable.ProwlBuff = 5215
    classtable.SuddenAmbushBuff = 0
    classtable.RipDeBuff = 1079
    classtable.ThrashCatDeBuff = 405233
    classtable.SunfireDeBuff = 164815
    classtable.RakeDeBuff = 155722
    classtable.CatFormBuff = 768
    classtable.MoonfireDeBuff = 164812
    classtable.HeartoftheWildBuff = 0

    local precombatCheck = Restoration:precombat()
    if precombatCheck then
        return Restoration:precombat()
    end

    local callactionCheck = Restoration:callaction()
    if callactionCheck then
        return Restoration:callaction()
    end
end
