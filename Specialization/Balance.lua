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

local Balance = {}

function Balance:precombat()
    if (MaxDps:CheckSpellUsable(classtable.MoonkinForm, 'MoonkinForm')) and not buff[classtable.MoonkinForm].up and cooldown[classtable.MoonkinForm].ready then
        return classtable.MoonkinForm
    end
    --if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and cooldown[classtable.Wrath].ready then
    --    return classtable.Wrath
    --end
    --if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and cooldown[classtable.Wrath].ready then
    --    return classtable.Wrath
    --end
    --if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (not talents[classtable.StellarFlare]) and cooldown[classtable.Starfire].ready then
    --    return classtable.Starfire
    --end
    --if (MaxDps:CheckSpellUsable(classtable.StellarFlare, 'StellarFlare')) and cooldown[classtable.StellarFlare].ready then
    --    return classtable.StellarFlare
    --end
end

function Balance:callaction()
    if (MaxDps:CheckSpellUsable(classtable.SolarBeam, 'SolarBeam')) and cooldown[classtable.SolarBeam].ready then
        MaxDps:GlowCooldown(classtable.SolarBeam, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (debuff[classtable.MoonfireDeBuff].refreshable) and cooldown[classtable.Moonfire].ready then
        return classtable.Moonfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].refreshable) and cooldown[classtable.Sunfire].ready then
        return classtable.Sunfire
    end
    if (MaxDps:CheckSpellUsable(classtable.StellarFlare, 'StellarFlare')) and (debuff[classtable.StellarFlareDeBuff].refreshable) and cooldown[classtable.StellarFlare].ready then
        return classtable.StellarFlare
    end
    if (MaxDps:CheckSpellUsable(classtable.ForceofNature, 'ForceofNature')) and cooldown[classtable.ForceofNature].ready then
        return classtable.ForceofNature
    end
    if (MaxDps:CheckSpellUsable(classtable.FuryofElune, 'FuryofElune')) and cooldown[classtable.FuryofElune].ready then
        return classtable.FuryofElune
    end

    MaxDps:GlowCooldown(classtable.Incarnation, talents[classtable.Incarnation] and cooldown[classtable.Incarnation].ready)


    MaxDps:GlowCooldown(classtable.CelestialAlignment,not talents[classtable.Incarnation] and cooldown[classtable.CelestialAlignment].ready)

    if (MaxDps:CheckSpellUsable(classtable.WarriorofElune, 'WarriorofElune')) and (not talents[classtable.LunarCalling] and buff[classtable.EclipseSolarBuff].remains <7 or talents[classtable.LunarCalling]) and cooldown[classtable.WarriorofElune].ready then
        return classtable.WarriorofElune
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (( not talents[classtable.LunarCalling] and targets == 1 ) and ( buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains <( classtable and classtable.Starfire and GetSpellInfo(classtable.Starfire).castTime / 1000 ) )) and cooldown[classtable.Starfire].ready then
        return classtable.Starfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (( talents[classtable.LunarCalling] or targets >1 ) and ( buff[classtable.EclipseLunarBuff].up and ( buff[classtable.EclipseLunarBuff].remains <( classtable and classtable.Wrath and GetSpellInfo(classtable.Wrath).castTime / 1000 ) ) )) and cooldown[classtable.Wrath].ready then
        return classtable.Wrath
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfall, 'Starfall')) and (buff[classtable.StarweaversWarpBuff].up) and cooldown[classtable.Starfall].ready then
        return classtable.Starfall
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (targets <2) and cooldown[classtable.Starsurge].ready then
        return classtable.Starsurge
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfall, 'Starfall')) and (targets >1) and cooldown[classtable.Starfall].ready then
        return classtable.Starfall
    end
    if (MaxDps:CheckSpellUsable(classtable.ConvoketheSpirits, 'ConvoketheSpirits')) and cooldown[classtable.ConvoketheSpirits].ready then
        MaxDps:GlowCooldown(classtable.ConvoketheSpirits, cooldown[classtable.ConvoketheSpirits].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.NewMoon, 'NewMoon')) and cooldown[classtable.NewMoon].ready then
        return classtable.NewMoon
    end
    if (MaxDps:CheckSpellUsable(classtable.HalfMoon, 'HalfMoon')) and cooldown[classtable.HalfMoon].ready then
        return classtable.HalfMoon
    end
    if (MaxDps:CheckSpellUsable(classtable.FullMoon, 'FullMoon')) and cooldown[classtable.FullMoon].ready then
        return classtable.FullMoon
    end
    if (MaxDps:CheckSpellUsable(classtable.WarriorofElune, 'WarriorofElune')) and cooldown[classtable.WarriorofElune].ready then
        return classtable.WarriorofElune
    end
    if (MaxDps:CheckSpellUsable(classtable.WildMushroom, 'WildMushroom')) and cooldown[classtable.WildMushroom].ready then
        return classtable.WildMushroom
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (talents[classtable.LunarCalling] or buff[classtable.EclipseLunarBuff].up and targets >1) and cooldown[classtable.Starfire].ready then
        return classtable.Starfire
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and cooldown[classtable.Wrath].ready then
        return classtable.Wrath
    end
end
function Druid:Balance()
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
    local currentSpell = fd.currentSpell
    local wrathCount = GetSpellCount(classtable.Wrath)
    local starfireCount = GetSpellCount(classtable.Starfire)
    local origWrathCount = wrathCount
    local origStarfireCount = starfireCount
    classtable.Incarnation =  classtable.IncarnationChosenofElune
    local CaInc = talents[classtable.Incarnation] and classtable.Incarnation or classtable.CelestialAlignment
    local castingMoonSpell = false
    if currentSpell == classtable.Wrath then
    	LunarPower = LunarPower + 6
    	wrathCount = wrathCount - 1
    elseif currentSpell == classtable.Starfire then
    	LunarPower = LunarPower + 8
    	starfireCount = starfireCount - 1
    elseif currentSpell == classtable.FuryOfElune then
    	LunarPower = LunarPower + 40
    elseif currentSpell == classtable.ForceOfNature then
    	LunarPower = LunarPower + 20
    elseif currentSpell == classtable.StellarFlare then
    	LunarPower = LunarPower + 8
    elseif currentSpell == classtable.NewMoon then
    	LunarPower = LunarPower + 10
    	castingMoonSpell = true
    elseif currentSpell == classtable.HalfMoon then
    	LunarPower = LunarPower + 20
    	castingMoonSpell = true
    elseif currentSpell == classtable.FullMoon then
    	LunarPower = LunarPower + 40
    	castingMoonSpell = true
    end
    fd.eclipseInLunar = buff[classtable.EclipseLunar].up or (origStarfireCount == 1 and currentSpell == classtable.Starfire)
    fd.eclipseInSolar = buff[classtable.EclipseSolar].up or (origWrathCount == 1 and currentSpell == classtable.Wrath)
    fd.eclipseInAny = fd.eclipseInSolar or fd.eclipseInLunar
    fd.eclipseInBoth = fd.eclipseInSolar and fd.eclipseInLunar
    fd.eclipseSolarNext = wrathCount > 0 and starfireCount <= 0
    fd.eclipseLunarNext = wrathCount <= 0 and starfireCount > 0
    fd.eclipseAnyNext = wrathCount > 0 and starfireCount > 0
    fd.wrathCount = wrathCount
    fd.starfireCount = starfireCount
    Energy = UnitPower('player', EnergyPT)
    EnergyMax = UnitPowerMax('player', EnergyPT)
    EnergyDeficit = EnergyMax - Energy
    EnergyRegen = GetPowerRegenForPowerType(Enum.PowerType.Energy)
    EnergyTimeToMax = EnergyDeficit / EnergyRegen
    EnergyPerc = (Energy / EnergyMax) * 100
    ComboPoints = UnitPower('player', ComboPointsPT)
    ComboPointsMax = UnitPowerMax('player', ComboPointsPT)
    ComboPointsDeficit = ComboPointsMax - ComboPoints
    classtable.HalfMoon = 274282
    classtable.FullMoon = 274283
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.MoonfireDeBuff = 164812
    classtable.SunfireDeBuff = 164815
    classtable.StellarFlareDeBuff = 202347
    classtable.EclipseSolarBuff = 48517
    classtable.EclipseLunarBuff = 48518
    classtable.StarweaversWarpBuff = 393942

    local precombatCheck = Balance:precombat()
    if precombatCheck then
        return Balance:precombat()
    end

    local callactionCheck = Balance:callaction()
    if callactionCheck then
        return Balance:callaction()
    end
end
