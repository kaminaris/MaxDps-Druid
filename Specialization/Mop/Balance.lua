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
    if (MaxDps:CheckSpellUsable(classtable.MarkoftheWild, 'MarkoftheWild')) and (not aura.str_agi_int.up) and cooldown[classtable.MarkoftheWild].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MarkoftheWild end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonkinForm, 'MoonkinForm')) and cooldown[classtable.MoonkinForm].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MoonkinForm end
    end
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and cooldown[classtable.VolcanicPotion].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.NaturesSwiftness, false)
    MaxDps:GlowCooldown(classtable.Incarnation, false)
end

function Balance:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Starfall, 'Starfall')) and (not buff[classtable.StarfallBuff].up) and cooldown[classtable.Starfall].ready then
        if not setSpell then setSpell = classtable.Starfall end
    end
    if (MaxDps:CheckSpellUsable(classtable.Treants, 'Treants')) and ((talents[classtable.ForceofNature] and true or false)) and cooldown[classtable.Treants].ready then
        if not setSpell then setSpell = classtable.Treants end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildMushroomDetonate, 'WildMushroomDetonate')) and (buff[classtable.WildMushroomBuff].count >0 and buff[classtable.SolarEclipseBuff].up) and cooldown[classtable.WildMushroomDetonate].ready then
        if not setSpell then setSpell = classtable.WildMushroomDetonate end
    end
    if (MaxDps:CheckSpellUsable(classtable.NaturesSwiftness, 'NaturesSwiftness') and talents[classtable.NaturesSwiftness]) and ((talents[classtable.DreamofCenarius] and true or false) and (talents[classtable.NaturesSwiftness] and true or false)) and cooldown[classtable.NaturesSwiftness].ready then
        MaxDps:GlowCooldown(classtable.NaturesSwiftness, cooldown[classtable.NaturesSwiftness].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.HealingTouch, 'HealingTouch')) and (not buff[classtable.DreamofCenariusDamageBuff].up and (talents[classtable.DreamofCenarius] and true or false)) and cooldown[classtable.HealingTouch].ready then
        if not setSpell then setSpell = classtable.HealingTouch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Incarnation, 'Incarnation') and talents[classtable.Incarnation]) and ((talents[classtable.Incarnation] and true or false) and ( buff[classtable.LunarEclipseBuff].up or buff[classtable.SolarEclipseBuff].up )) and cooldown[classtable.Incarnation].ready then
        MaxDps:GlowCooldown(classtable.Incarnation, cooldown[classtable.Incarnation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.CelestialAlignment, 'CelestialAlignment')) and (( ( eclipse_dir == - 1 and eclipse <= 0 ) or ( eclipse_dir == 1 and eclipse >= 0 ) ) and ( buff[classtable.ChosenofEluneBuff].up or not (talents[classtable.Incarnation] and true or false) )) and cooldown[classtable.CelestialAlignment].ready then
        if not setSpell then setSpell = classtable.CelestialAlignment end
    end
    if (MaxDps:CheckSpellUsable(classtable.NaturesVigil, 'NaturesVigil') and talents[classtable.NaturesVigil]) and (( ( (talents[classtable.Incarnation] and true or false) and buff[classtable.ChosenofEluneBuff].up ) or ( not (talents[classtable.Incarnation] and true or false) and buff[classtable.CelestialAlignmentBuff].up ) ) and (talents[classtable.NaturesVigil] and true or false)) and cooldown[classtable.NaturesVigil].ready then
        if not setSpell then setSpell = classtable.NaturesVigil end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (eclipse <= - 70 and eclipse_dir <= 0) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (eclipse >= 60 and eclipse_dir >= 0) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (buff[classtable.LunarEclipseBuff].up and ( debuff[classtable.MoonfireDeBuff].remains <( buff[classtable.NaturesGraceBuff].remains - 2 + 2 * (MaxDps.tier and MaxDps.tier[14].count >= 4 and 1 or 0) ) )) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (buff[classtable.SolarEclipseBuff].up and not buff[classtable.CelestialAlignmentBuff].up and ( debuff[classtable.SunfireDeBuff].remains <( buff[classtable.NaturesGraceBuff].remains - 2 + 2 * (MaxDps.tier and MaxDps.tier[14].count >= 4 and 1 or 0) ) )) and cooldown[classtable.Sunfire].ready then
        if not setSpell then setSpell = classtable.Sunfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (not debuff[classtable.MoonfireDeBuff].up and not buff[classtable.CelestialAlignmentBuff].up and ( buff[classtable.DreamofCenariusDamageBuff].up or not (talents[classtable.DreamofCenarius] and true or false) )) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (not debuff[classtable.SunfireDeBuff].up and not buff[classtable.CelestialAlignmentBuff].up and ( buff[classtable.DreamofCenariusDamageBuff].up or not (talents[classtable.DreamofCenarius] and true or false) )) and cooldown[classtable.Sunfire].ready then
        if not setSpell then setSpell = classtable.Sunfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (buff[classtable.CelestialAlignmentBuff].up and ( classtable and classtable.Starfire and GetSpellInfo(classtable.Starfire).castTime /1000 or 0) <buff[classtable.CelestialAlignmentBuff].remains) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (buff[classtable.CelestialAlignmentBuff].up and ( classtable and classtable.Wrath and GetSpellInfo(classtable.Wrath).castTime /1000 or 0) <buff[classtable.CelestialAlignmentBuff].remains) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (eclipse_dir == 1 or ( eclipse_dir == 0 and eclipse >0 )) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (eclipse_dir == - 1 or ( eclipse_dir == 0 and eclipse <= 0 )) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (not debuff[classtable.SunfireDeBuff].up) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (not debuff[classtable.MoonfireDeBuff].up) and cooldown[classtable.Sunfire].ready then
        if not setSpell then setSpell = classtable.Sunfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildMushroom, 'WildMushroom')) and (buff[classtable.WildMushroomBuff].count <5) and cooldown[classtable.WildMushroom].ready then
        if not setSpell then setSpell = classtable.WildMushroom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (buff[classtable.ShootingStarsBuff].up) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (buff[classtable.LunarEclipseBuff].up) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and cooldown[classtable.Sunfire].ready then
        if not setSpell then setSpell = classtable.Sunfire end
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
    AstralPower = UnitPower('player', LunarPowerPT)
    AstralPowerMax = UnitPowerMax('player', LunarPowerPT)
    AstralPowerDeficit = AstralPowerMax - AstralPower
    local currentSpell = fd.currentSpell
    local wrathCount = GetSpellCount(classtable.Wrath)
    local starfireCount = GetSpellCount(classtable.Starfire)
    local origWrathCount = wrathCount
    local origStarfireCount = starfireCount
    classtable.Incarnation =  classtable.IncarnationChosenofElune
    local CaInc = talents[classtable.Incarnation] and classtable.Incarnation or classtable.CelestialAlignment
    local castingMoonSpell = false
    if currentSpell == classtable.Wrath then
    	AstralPower = AstralPower + 6
    	wrathCount = wrathCount - 1
    elseif currentSpell == classtable.Starfire then
    	AstralPower = AstralPower + 8
    	starfireCount = starfireCount - 1
    elseif currentSpell == classtable.FuryOfElune then
    	AstralPower = AstralPower + 40
    elseif currentSpell == classtable.ForceOfNature then
    	AstralPower = AstralPower + 20
    elseif currentSpell == classtable.StellarFlare then
    	AstralPower = AstralPower + 8
    elseif currentSpell == classtable.NewMoon then
    	AstralPower = AstralPower + 10
    	castingMoonSpell = true
    elseif currentSpell == classtable.HalfMoon then
    	AstralPower = AstralPower + 20
    	castingMoonSpell = true
    elseif currentSpell == classtable.FullMoon then
    	AstralPower = AstralPower + 40
    	castingMoonSpell = true
    end
    fd.eclipseInLunar = buff[classtable.EclipseLunar].up
    fd.eclipseInSolar = buff[classtable.EclipseSolar].up
    fd.eclipseInAny = fd.eclipseInSolar or fd.eclipseInLunar
    fd.eclipseInBoth = fd.eclipseInSolar and fd.eclipseInLunar
    fd.eclipseSolarNext = wrathCount > 0 and starfireCount <= 0
    fd.eclipseLunarNext = wrathCount <= 0 and starfireCount > 0
    fd.eclipseAnyNext = wrathCount > 0 and starfireCount > 0
    fd.wrathCount = wrathCount
    fd.starfireCount = starfireCount
    classtable.HalfMoon = 274282
    classtable.FullMoon = 274283
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    local function debugg()
        talents[classtable.ForceofNature] = 1
        talents[classtable.DreamofCenarius] = 1
        talents[classtable.NaturesSwiftness] = 1
        talents[classtable.Incarnation] = 1
        talents[classtable.NaturesVigil] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Balance:precombat()

    Balance:callaction()
    if setSpell then return setSpell end
end
