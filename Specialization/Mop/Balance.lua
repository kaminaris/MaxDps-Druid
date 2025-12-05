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
local eclipse = UnitPower("player", Enum.PowerType.Balance) or 0
local eclipse_dir = (GetEclipseDirection() == "sun" and 1 or GetEclipseDirection() == "moon" and -1 or 0)

local Balance = {}

local function GetTotemInfoByName(name)
    local info = {
        duration = 0,
        remains = 0,
        up = false,
        count = 0,
    }
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local remains = math.floor(startTime+duration-GetTime())
        if (totemName == name ) then
            info.duration = duration
            info.up = true
            info.remains = remains
            info.count = info.count + 1
        end
    end
    return info
end

function Balance:precombat()
    if (MaxDps:CheckSpellUsable(classtable.MarkoftheWild, 'MarkoftheWild')) and (not buff[classtable.MarkoftheWildBuff].up) and cooldown[classtable.MarkoftheWild].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MarkoftheWild end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonkinForm, 'MoonkinForm')) and (not buff[classtable.MoonkinFormBuff].up) and cooldown[classtable.MoonkinForm].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MoonkinForm end
    end
    --if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and cooldown[classtable.VolcanicPotion].ready and not UnitAffectingCombat('player') then
    --    if not setSpell then setSpell = classtable.VolcanicPotion end
    --end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.NaturesSwiftness, false)
    MaxDps:GlowCooldown(classtable.Incarnation, false)
    MaxDps:GlowCooldown(classtable.CelestialAlignment, false)
end

function Balance:single()
    if (MaxDps:CheckSpellUsable(classtable.Starfall, 'Starfall')) and (not buff[classtable.StarfallBuff].up) and cooldown[classtable.Starfall].ready then
        if not setSpell then setSpell = classtable.Starfall end
    end
    if (MaxDps:CheckSpellUsable(classtable.Treants, 'Treants')) and ((talents[classtable.ForceofNature] and true or false)) and cooldown[classtable.Treants].ready then
        if not setSpell then setSpell = classtable.Treants end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildMushroomDetonate, 'WildMushroomDetonate')) and (GetTotemInfoByName("Wild Mushroom").count >0 and buff[classtable.SolarEclipseBuff].up) and cooldown[classtable.WildMushroomDetonate].ready then
        if not setSpell then setSpell = classtable.WildMushroomDetonate end
    end
    if (MaxDps:CheckSpellUsable(classtable.NaturesSwiftness, 'NaturesSwiftness') and talents[classtable.NaturesSwiftness]) and ((talents[classtable.DreamofCenarius] and true or false) and (talents[classtable.NaturesSwiftness] and true or false)) and cooldown[classtable.NaturesSwiftness].ready then
        MaxDps:GlowCooldown(classtable.NaturesSwiftness, cooldown[classtable.NaturesSwiftness].ready)
    end
    --if (MaxDps:CheckSpellUsable(classtable.HealingTouch, 'HealingTouch')) and (not buff[classtable.DreamofCenariusDamageBuff].up and (talents[classtable.DreamofCenarius] and true or false)) and cooldown[classtable.HealingTouch].ready then
    --    if not setSpell then setSpell = classtable.HealingTouch end
    --end
    if (MaxDps:CheckSpellUsable(classtable.Incarnation, 'Incarnation') and talents[classtable.Incarnation]) and ((talents[classtable.Incarnation] and true or false) and ( buff[classtable.LunarEclipseBuff].up or buff[classtable.SolarEclipseBuff].up )) and cooldown[classtable.Incarnation].ready then
        MaxDps:GlowCooldown(classtable.Incarnation, cooldown[classtable.Incarnation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.CelestialAlignment, 'CelestialAlignment')) and (( ( eclipse_dir == - 1 and eclipse <= 0 ) or ( eclipse_dir == 1 and eclipse >= 0 ) ) and ( buff[classtable.ChosenofEluneBuff].up or not (talents[classtable.Incarnation] and true or false) )) and cooldown[classtable.CelestialAlignment].ready then
        MaxDps:GlowCooldown(classtable.CelestialAlignment, cooldown[classtable.CelestialAlignment].ready)
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
    --or MaxDps:DebuffCounter(classtable.MoonfireDeBuff) < targets
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (buff[classtable.LunarEclipseBuff].up and (debuff[classtable.MoonfireDeBuff].refreshable)) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    --or MaxDps:DebuffCounter(classtable.SunfireDeBuff) < targets
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (buff[classtable.SolarEclipseBuff].up and not buff[classtable.CelestialAlignmentBuff].up and (debuff[classtable.SunfireDeBuff].refreshable)) and cooldown[classtable.Sunfire].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.WildMushroom, 'WildMushroom')) and (GetTotemInfoByName("Wild Mushroom").count <5) and cooldown[classtable.WildMushroom].ready then
        if not setSpell then setSpell = classtable.WildMushroom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (buff[classtable.ShootingStarsBuff].up) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    --if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (buff[classtable.LunarEclipseBuff].up) and cooldown[classtable.Moonfire].ready then
    --    if not setSpell then setSpell = classtable.Moonfire end
    --end
    --if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and cooldown[classtable.Sunfire].ready then
    --    if not setSpell then setSpell = classtable.Sunfire end
    --end
    -- Cast Wrath if outside Eclipse and previous Eclipse was Solar
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and eclipse_dir == -1 and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end

    -- Cast Starfire if outside Eclipse and previous Eclipse was Lunar
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and eclipse_dir == 1 and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
end

function Balance:aoe()
    if targets >= 5 then
        -- Cast Celestial Alignment
        if (MaxDps:CheckSpellUsable(classtable.CelestialAlignment, 'CelestialAlignment')) and cooldown[classtable.CelestialAlignment].ready then
            MaxDps:GlowCooldown(classtable.CelestialAlignment, cooldown[classtable.CelestialAlignment].ready)
        end

        -- Cast Starsurge while having Shooting Stars buffs
        if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and buff[classtable.ShootingStarsBuff].up and cooldown[classtable.Starsurge].ready then
            if not setSpell then setSpell = classtable.Starsurge end
        end

        -- Cast Starfall
        if (MaxDps:CheckSpellUsable(classtable.Starfall, 'Starfall')) and (not buff[classtable.StarfallBuff].up) and cooldown[classtable.Starfall].ready then
            if not setSpell then setSpell = classtable.Starfall end
        end

        --or MaxDps:DebuffCounter(classtable.SunfireDeBuff) < targets
        -- Apply or Refresh Sunfire on all targets while in Solar Eclipse
        if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and buff[classtable.SolarEclipseBuff].up and (debuff[classtable.SunfireDeBuff].refreshable) and cooldown[classtable.Sunfire].ready then
            if not setSpell then setSpell = classtable.Sunfire end
        end

        --or MaxDps:DebuffCounter(classtable.MoonfireDeBuff) < targets
        -- Apply or Refresh Moonfire on all targets while in Lunar Eclipse
        if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and buff[classtable.LunarEclipseBuff].up and (debuff[classtable.MoonfireDeBuff].refreshable) and cooldown[classtable.Moonfire].ready then
            if not setSpell then setSpell = classtable.Moonfire end
        end

        --or MaxDps:DebuffCounter(classtable.SunfireDeBuff) < targets
        -- Apply or Refresh Sunfire on all targets
        if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].refreshable) and cooldown[classtable.Sunfire].ready then
            if not setSpell then setSpell = classtable.Sunfire end
        end

        --or MaxDps:DebuffCounter(classtable.MoonfireDeBuff) < targets
        -- Apply or Refresh Moonfire on all targets
        if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (debuff[classtable.MoonfireDeBuff].refreshable) and cooldown[classtable.Moonfire].ready then
            if not setSpell then setSpell = classtable.Moonfire end
        end

        -- Cast Starsurge
        if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and cooldown[classtable.Starsurge].ready then
            if not setSpell then setSpell = classtable.Starsurge end
        end

        -- Cast Wrath if outside Eclipse and previous Eclipse was Solar
        if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and eclipse_dir == -1 and cooldown[classtable.Wrath].ready then
            if not setSpell then setSpell = classtable.Wrath end
        end

        -- Cast Starfire if outside Eclipse and previous Eclipse was Lunar
        if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and eclipse_dir == 1 and cooldown[classtable.Starfire].ready then
            if not setSpell then setSpell = classtable.Starfire end
        end

        -- Channel Hurricane
        if (MaxDps:CheckSpellUsable(classtable.Hurricane, 'Hurricane')) and cooldown[classtable.Hurricane].ready then
            if not setSpell then setSpell = classtable.Hurricane end
        end
    else
        -- Cast Celestial Alignment
        if (MaxDps:CheckSpellUsable(classtable.CelestialAlignment, 'CelestialAlignment')) and cooldown[classtable.CelestialAlignment].ready then
            MaxDps:GlowCooldown(classtable.CelestialAlignment, cooldown[classtable.CelestialAlignment].ready)
        end

        -- Cast Starsurge while having Shooting Stars buffs
        if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and buff[classtable.ShootingStarsBuff].up and cooldown[classtable.Starsurge].ready then
            if not setSpell then setSpell = classtable.Starsurge end
        end

        -- Cast Starfall
        if (MaxDps:CheckSpellUsable(classtable.Starfall, 'Starfall')) and (not buff[classtable.StarfallBuff].up) and cooldown[classtable.Starfall].ready then
            if not setSpell then setSpell = classtable.Starfall end
        end

        --or MaxDps:DebuffCounter(classtable.SunfireDeBuff) < targets
        -- Apply or Refresh Sunfire on all targets while in Solar Eclipse
        if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and buff[classtable.SolarEclipseBuff].up and (debuff[classtable.SunfireDeBuff].refreshable) and cooldown[classtable.Sunfire].ready then
            if not setSpell then setSpell = classtable.Sunfire end
        end

        --or MaxDps:DebuffCounter(classtable.MoonfireDeBuff) < targets
        -- Apply or Refresh Moonfire on all targets while in Lunar Eclipse
        if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and buff[classtable.LunarEclipseBuff].up and (debuff[classtable.MoonfireDeBuff].refreshable) and cooldown[classtable.Moonfire].ready then
            if not setSpell then setSpell = classtable.Moonfire end
        end

        --or MaxDps:DebuffCounter(classtable.SunfireDeBuff) < targets
        -- Apply or Refresh Sunfire on all targets
        if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].refreshable) and cooldown[classtable.Sunfire].ready then
            if not setSpell then setSpell = classtable.Sunfire end
        end

        --or MaxDps:DebuffCounter(classtable.MoonfireDeBuff) < targets
        -- Apply or Refresh Moonfire on all targets
        if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (debuff[classtable.MoonfireDeBuff].refreshable) and cooldown[classtable.Moonfire].ready then
            if not setSpell then setSpell = classtable.Moonfire end
        end

        -- Cast Starsurge
        if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and cooldown[classtable.Starsurge].ready then
            if not setSpell then setSpell = classtable.Starsurge end
        end

        -- Cast Wrath while in Solar Eclipse
        if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and buff[classtable.SolarEclipseBuff].up and cooldown[classtable.Wrath].ready then
            if not setSpell then setSpell = classtable.Wrath end
        end

        -- Cast Starfire while in Lunar Eclipse
        if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and buff[classtable.LunarEclipseBuff].up and cooldown[classtable.Starfire].ready then
            if not setSpell then setSpell = classtable.Starfire end
        end

        -- Cast Wrath if outside Eclipse and previous Eclipse was Solar
        if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and eclipse_dir == -1 and cooldown[classtable.Wrath].ready then
            if not setSpell then setSpell = classtable.Wrath end
        end

        -- Cast Starfire if outside Eclipse and previous Eclipse was Lunar
        if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and eclipse_dir == 1 and cooldown[classtable.Starfire].ready then
            if not setSpell then setSpell = classtable.Starfire end
        end
    end
end

function Balance:callaction()
    if targets > 1 then
        Balance:aoe()
    end
    Balance:single()
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
    eclipse = UnitPower("player", Enum.PowerType.Balance) or 0

    eclipse_dir = (GetEclipseDirection() == "sun" and 1 or GetEclipseDirection() == "moon" and -1 or 0)
    fd.eclipseInLunar = buff[classtable.EclipseLunar].up
    fd.eclipseInSolar = buff[classtable.EclipseSolar].up
    fd.eclipseInAny = fd.eclipseInSolar or fd.eclipseInLunar
    fd.eclipseInBoth = fd.eclipseInSolar and fd.eclipseInLunar

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

    classtable.Treants = 1006737

    classtable.MarkoftheWildBuff = 1126
    classtable.MoonkinFormBuff = 24858

    classtable.StarfallBuff = 48505
    --classtable.WildMushroomBuff
    classtable.SolarEclipseBuff = 48517
    classtable.LunarEclipseBuff = 48518
    classtable.CelestialAlignmentBuff = 112071
    classtable.ChosenofEluneBuff = 102560
    classtable.NaturesGraceBuff = 16886
    classtable.DreamofCenariusDamageBuff = 155625
    classtable.ShootingStarsBuff = 93400

    classtable.MoonfireDeBuff = 8921
    classtable.SunfireDeBuff = 93402


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Balance:precombat()

    Balance:callaction()
    if setSpell then return setSpell end
end
