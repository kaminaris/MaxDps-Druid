local _, addonTable = ...
local Druid = addonTable.Druid
local MaxDps = _G.MaxDps
if not MaxDps then return end
local LibStub = LibStub
local setSpell

local ceil = ceil
local floor = floor
local fmod = fmod
local format = format
local max = max
local min = min
local pairs = pairs
local select = select
local strsplit = strsplit
local GetTime = GetTime

local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitSpellHaste = UnitSpellHaste
local UnitThreatSituation = UnitThreatSituation
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
local GetSpellCastCount = C_Spell.GetSpellCastCount
local GetUnitSpeed = GetUnitSpeed
local GetCritChance = GetCritChance
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = C_Item.GetItemInfo
local GetItemSpell = C_Item.GetItemSpell
local GetNamePlates = C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates or GetNamePlates
local GetPowerRegenForPowerType = GetPowerRegenForPowerType
local GetSpellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName or GetSpellInfo
local GetTotemInfo = GetTotemInfo
local IsStealthed = IsStealthed
local IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

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

local Mana
local ManaMax
local ManaDeficit
local ManaPerc
local ManaRegen
local ManaRegenCombined
local ManaTimeToMax
local Energy
local EnergyMax
local EnergyDeficit
local EnergyPerc
local EnergyRegen
local EnergyRegenCombined
local EnergyTimeToMax
local Rage
local RageMax
local RageDeficit
local RagePerc
local RageRegen
local RageRegenCombined
local RageTimeToMax
local LunarPower
local LunarPowerMax
local LunarPowerDeficit
local LunarPowerPerc
local LunarPowerRegen
local LunarPowerRegenCombined
local LunarPowerTimeToMax
local AstralPower
local AstralPowerMax
local AstralPowerDeficit
local AstralPowerPerc
local AstralPowerRegen
local AstralPowerRegenCombined
local AstralPowerTimeToMax
local ComboPoints
local ComboPointsMax
local ComboPointsDeficit
local ComboPointsPerc
local ComboPointsRegen
local ComboPointsRegenCombined
local ComboPointsTimeToMax

local Balance = {}

local no_cd_talent = false
local on_use_trinket = 0
local passive_asp = 0
local ca_effective_cd = 0
local pre_cd_condition = false
local cd_condition = false
local convoke_condition = false
local enter_lunar = false
local boat_stacks = 0
local kotg_ca_condition = false
local pool_for_cd = false
local pool_in_ca = false
local generic_trinket_condition = false
function Balance:precombat()
    if (MaxDps:CheckSpellUsable(classtable.MarkoftheWild, 'MarkoftheWild')) and (not buff[classtable.MarkoftheWild].up) and cooldown[classtable.MarkoftheWild].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MarkoftheWild end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonkinForm, 'MoonkinForm')) and (not buff[classtable.MoonkinForm].up) and cooldown[classtable.MoonkinForm].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MoonkinForm end
    end
    no_cd_talent = not talents[classtable.CelestialAlignment] and not talents[classtable.IncarnationChosenofElune] or (not cooldown[classtable.IncarnationChosenofElune].ready and not cooldown[classtable.CelestialAlignment].ready and not cooldown[classtable.AstralCommunion].ready and not cooldown[classtable.ConvoketheSpirits].ready)
    on_use_trinket = 0
    if MaxDps:HasOnUseEffect('13') and not MaxDps:CheckTrinketNames('OvinaxsMercurialEgg') and not MaxDps:CheckTrinketNames('SpymastersWeb') then
        on_use_trinket = on_use_trinket+1
    else
        on_use_trinket = on_use_trinket+0
    end
    if MaxDps:HasOnUseEffect('14') and not MaxDps:CheckTrinketNames('OvinaxsMercurialEgg') and not MaxDps:CheckTrinketNames('SpymastersWeb') then
        on_use_trinket = on_use_trinket+2
    else
        on_use_trinket = on_use_trinket+0
    end
    if (MaxDps:CheckSpellUsable(classtable.Regrowth, 'Regrowth')) and ((MaxDps.ActiveHeroTree == 'keeperofthegrove') and not talents[classtable.StellarFlare] and (MaxDps.spellHistoryTime and MaxDps.spellHistoryTime[classtable.Regrowth] and GetTime() - MaxDps.spellHistoryTime[classtable.Regrowth].last_used or 0) <10 and MaxDps:DebuffCounter(classtable.RegrowthDeBuff) == 0) and cooldown[classtable.Regrowth].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.Regrowth, cooldown[classtable.Regrowth].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (fd.eclipseInLunar) and cooldown[classtable.Wrath].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Wrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (not talents[classtable.StellarFlare] and (MaxDps.ActiveHeroTree == 'eluneschosen')) and cooldown[classtable.Starfire].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.StellarFlare, 'StellarFlare') and talents[classtable.StellarFlare]) and cooldown[classtable.StellarFlare].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.StellarFlare end
    end
end
function Balance:aoe()
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (buff[classtable.DryadsFavorBuff].up) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (enter_lunar and (fd.eclipseInLunar or fd.eclipseInSolar) and (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Wrath and GetSpellInfo(classtable.Wrath).castTime /1000 or 0)) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (not enter_lunar and (fd.eclipseInLunar or fd.eclipseInSolar) and (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Starfire and GetSpellInfo(classtable.Starfire).castTime /1000 or 0)) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfall, 'Starfall')) and (AstralPowerDeficit <= passive_asp+6) and cooldown[classtable.Starfall].ready then
        if not setSpell then setSpell = classtable.Starfall end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (debuff[classtable.MoonfireDeBuff].refreshable and (ttd - debuff[classtable.MoonfireDeBuff].remains)>6 and (not talents[classtable.TreantsoftheMoon] or targets - MaxDps:DebuffCounter(classtable.MoonfireDmgDeBuff)>6 or cooldown[classtable.ForceofNature].remains >3 and not buff[classtable.HarmonyoftheGroveBuff].up) and not MaxDps:boss()) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].refreshable and (ttd - debuff[classtable.SunfireDeBuff].remains)>6-(targets%2)) and cooldown[classtable.Sunfire].ready then
        if not setSpell then setSpell = classtable.Sunfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (debuff[classtable.MoonfireDeBuff].refreshable and (ttd - debuff[classtable.MoonfireDeBuff].remains)>6 and (not talents[classtable.TreantsoftheMoon] or targets - MaxDps:DebuffCounter(classtable.MoonfireDmgDeBuff)>6 or cooldown[classtable.ForceofNature].remains >3 and not buff[classtable.HarmonyoftheGroveBuff].up) and MaxDps:boss()) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (enter_lunar and ((not fd.eclipseInLunar and not fd.eclipseInSolar) or (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Wrath and GetSpellInfo(classtable.Wrath).castTime /1000 or 0)) and not pre_cd_condition) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (not enter_lunar and ((not fd.eclipseInLunar and not fd.eclipseInSolar) or (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Starfire and GetSpellInfo(classtable.Starfire).castTime /1000 or 0))) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.StellarFlare, 'StellarFlare') and talents[classtable.StellarFlare]) and (debuff[classtable.StellarFlareDeBuff].refreshable and (ttd - debuff[classtable.StellarFlareDeBuff].remains-target >7+targets) and targets<(11 - (talents[classtable.UmbralIntensity] and talents[classtable.UmbralIntensity] or 0)-(2 * (talents[classtable.AstralSmolder] and talents[classtable.AstralSmolder] or 0))-(talents[classtable.LunarCalling] and talents[classtable.LunarCalling] or 0))) and cooldown[classtable.StellarFlare].ready then
        if not setSpell then setSpell = classtable.StellarFlare end
    end
    if (MaxDps:CheckSpellUsable(classtable.ForceofNature, 'ForceofNature')) and (pre_cd_condition or cooldown[classtable.CaInc].fullRecharge + 5+15 * (talents[classtable.ControloftheDream] and talents[classtable.ControloftheDream] or 0)>cooldown[classtable.ForceofNature].remains and (not talents[classtable.ConvoketheSpirits] or cooldown[classtable.ConvoketheSpirits].remains + 10+15 * (talents[classtable.ControloftheDream] and talents[classtable.ControloftheDream] or 0)>cooldown[classtable.ForceofNature].remains or ttd <cooldown[classtable.ConvoketheSpirits].remains+cooldown[classtable.ConvoketheSpirits].duration + 5) and (on_use_trinket == 0 or (on_use_trinket == 1 or on_use_trinket == 3) and (MaxDps:CheckTrinketCooldown('13') >5+15 * (talents[classtable.ControloftheDream] and talents[classtable.ControloftheDream] or 0) or cooldown[classtable.CaInc].remains >20 or MaxDps:CheckTrinketReady('13')) or on_use_trinket == 2 and (MaxDps:CheckTrinketCooldown('14') >5+15 * (talents[classtable.ControloftheDream] and talents[classtable.ControloftheDream] or 0) or cooldown[classtable.CaInc].remains >20 or MaxDps:CheckTrinketReady('14'))) and (ttd >cooldown[classtable.ForceofNature].remains+5 or ttd <cooldown[classtable.CaInc].remains+7) or talents[classtable.WhirlingStars] and talents[classtable.ConvoketheSpirits] and cooldown[classtable.ConvoketheSpirits].remains >cooldown[classtable.ForceofNature].duration-10 and ttd >cooldown[classtable.ConvoketheSpirits].remains+6) and cooldown[classtable.ForceofNature].ready then
        if not setSpell then setSpell = classtable.ForceofNature end
    end
    if (MaxDps:CheckSpellUsable(classtable.FuryofElune, 'FuryofElune')) and ((fd.eclipseInLunar or fd.eclipseInSolar)) and cooldown[classtable.FuryofElune].ready then
        if not setSpell then setSpell = classtable.FuryofElune end
    end
    Balance:pre_cd()
    if (MaxDps:CheckSpellUsable(classtable.CelestialAlignment, 'CelestialAlignment')) and (not talents[classtable.Incarnationchosenofelune] and cd_condition) and cooldown[classtable.CelestialAlignment].ready then
        MaxDps:GlowCooldown(classtable.CelestialAlignment, cooldown[classtable.CelestialAlignment].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Incarnation, 'Incarnation')) and (cd_condition) and cooldown[classtable.Incarnation].ready then
        MaxDps:GlowCooldown(classtable.Incarnation, cooldown[classtable.Incarnation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.WarriorofElune, 'WarriorofElune')) and (not talents[classtable.LunarCalling] and buff[classtable.EclipseSolarBuff].remains <7 or talents[classtable.LunarCalling] and not buff[classtable.DreamstateBuff].up) and cooldown[classtable.WarriorofElune].ready then
        if not setSpell then setSpell = classtable.WarriorofElune end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and ((not talents[classtable.LunarCalling] and targets == 1) and (buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains <( classtable and classtable.Starfire and GetSpellInfo(classtable.Starfire).castTime / 1000 or 0) or (not fd.eclipseInLunar and not fd.eclipseInSolar))) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfall, 'Starfall')) and (buff[classtable.StarweaversWarpBuff].up or buff[classtable.TouchtheCosmosStarfallBuff].up) and cooldown[classtable.Starfall].ready then
        if not setSpell then setSpell = classtable.Starfall end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (buff[classtable.StarweaversWeftBuff].up) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfall, 'Starfall')) and cooldown[classtable.Starfall].ready then
        if not setSpell then setSpell = classtable.Starfall end
    end
    if (MaxDps:CheckSpellUsable(classtable.ConvoketheSpirits, 'ConvoketheSpirits') and talents[classtable.ConvoketheSpirits]) and ((not buff[classtable.DreamstateBuff].up and not buff[classtable.UmbralEmbraceBuff].up and targets <7 or targets == 1) and (MaxDps:boss() and ttd <5 or (buff[classtable.CaIncBuff].up or cooldown[classtable.CaInc].remains >40) and (not (MaxDps.ActiveHeroTree == 'keeperofthegrove') or buff[classtable.HarmonyoftheGroveBuff].up or cooldown[classtable.ForceofNature].remains >15))) and cooldown[classtable.ConvoketheSpirits].ready then
        MaxDps:GlowCooldown(classtable.ConvoketheSpirits, cooldown[classtable.ConvoketheSpirits].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.NewMoon, 'NewMoon')) and cooldown[classtable.NewMoon].ready then
        if not setSpell then setSpell = classtable.NewMoon end
    end
    if (MaxDps:CheckSpellUsable(classtable.HalfMoon, 'HalfMoon')) and cooldown[classtable.HalfMoon].ready then
        if not setSpell then setSpell = classtable.HalfMoon end
    end
    if (MaxDps:CheckSpellUsable(classtable.FullMoon, 'FullMoon')) and cooldown[classtable.FullMoon].ready then
        if not setSpell then setSpell = classtable.FullMoon end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildMushroom, 'WildMushroom')) and (not (MaxDps.spellHistory[1] == classtable.WildMushroom) and not debuff[classtable.FungalGrowthDeBuff].up) and cooldown[classtable.WildMushroom].ready then
        if not setSpell then setSpell = classtable.WildMushroom end
    end
    if (MaxDps:CheckSpellUsable(classtable.ForceofNature, 'ForceofNature')) and (not (MaxDps.ActiveHeroTree == 'keeperofthegrove')) and cooldown[classtable.ForceofNature].ready then
        if not setSpell then setSpell = classtable.ForceofNature end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (talents[classtable.LunarCalling] or buff[classtable.EclipseLunarBuff].up and targets>(3-(((talents[classtable.UmbralIntensity] and talents[classtable.UmbralIntensity] or 0) or talents[classtable.SouloftheForest]) and 1 or 0))) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
end
function Balance:kotg_pre_cd()
    if (MaxDps:CheckSpellUsable(classtable.FuryofElune, 'FuryofElune')) and (not buff[classtable.CaIncBuff].up and kotg_ca_condition or cooldown[classtable.ConvoketheSpirits].remains >cooldown[classtable.FuryofElune].duration) and cooldown[classtable.FuryofElune].ready then
        if not setSpell then setSpell = classtable.FuryofElune end
    end
end
function Balance:kotg_st()
    if (MaxDps:CheckSpellUsable(classtable.WarriorofElune, 'WarriorofElune')) and ((buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <= 7) and cooldown[classtable.WarriorofElune].ready then
        if not setSpell then setSpell = classtable.WarriorofElune end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (enter_lunar and (fd.eclipseInLunar or fd.eclipseInSolar) and (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Wrath and GetSpellInfo(classtable.Wrath).castTime /1000 or 0) or kotg_ca_condition and buff[classtable.PartingSkiesBuff].up and ((buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Wrath and GetSpellInfo(classtable.Wrath).castTime /1000 or 0) or (not fd.eclipseInLunar and not fd.eclipseInSolar))) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (not enter_lunar and (fd.eclipseInLunar or fd.eclipseInSolar) and (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Starfire and GetSpellInfo(classtable.Starfire).castTime /1000 or 0) and not buff[classtable.DryadsFavorBuff].up and not kotg_ca_condition) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and ((debuff[classtable.MoonfireDeBuff].remains <3 and (not talents[classtable.TreantsoftheMoon] or cooldown[classtable.ForceofNature].remains >3 and not buff[classtable.HarmonyoftheGroveBuff].up)) or not debuff[classtable.MoonfireDeBuff].up) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].remains <3 or debuff[classtable.SunfireDeBuff].remains<(math.max(12 , buff[classtable.CaIncBuff].duration)) and kotg_ca_condition and not buff[classtable.CaIncBuff].up) and cooldown[classtable.Sunfire].ready then
        if not setSpell then setSpell = classtable.Sunfire end
    end
    Balance:kotg_pre_cd()
    if (MaxDps:CheckSpellUsable(classtable.CelestialAlignment, 'CelestialAlignment')) and (not talents[102560] and kotg_ca_condition) and cooldown[classtable.CelestialAlignment].ready then
        MaxDps:GlowCooldown(classtable.CelestialAlignment, cooldown[classtable.CelestialAlignment].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Incarnation, 'Incarnation')) and (kotg_ca_condition) and cooldown[classtable.Incarnation].ready then
        MaxDps:GlowCooldown(classtable.Incarnation, cooldown[classtable.Incarnation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (buff[classtable.DryadsFavorBuff].up and buff[classtable.CaIncBuff].up) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (enter_lunar and ((not fd.eclipseInLunar and not fd.eclipseInSolar) or (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Wrath and GetSpellInfo(classtable.Wrath).castTime /1000 or 0))) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (not enter_lunar and ((not fd.eclipseInLunar and not fd.eclipseInSolar) or (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Starfire and GetSpellInfo(classtable.Starfire).castTime /1000 or 0))) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.StellarFlare, 'StellarFlare') and talents[classtable.StellarFlare]) and (debuff[classtable.StellarFlareDeBuff].remains <= buff[classtable.CaIncBuff].duration and pool_for_cd or debuff[classtable.StellarFlareDeBuff].remains <= buff[classtable.CaIncBuff].duration and not buff[classtable.DryadsFavorBuff].up) and cooldown[classtable.StellarFlare].ready then
        if not setSpell then setSpell = classtable.StellarFlare end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (pool_for_cd) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (buff[classtable.DryadBuff].remains >8 and buff[classtable.DryadBuff].up) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.ForceofNature, 'ForceofNature')) and (buff[classtable.DryadBuff].up and buff[classtable.HarmonyoftheGroveBuff].duration >buff[classtable.DryadBuff].remains+gcd * 2 or cooldown[classtable.ForceofNature].duration <cooldown[classtable.ConvoketheSpirits].remains+(15 * (talents[classtable.ControloftheDream] and talents[classtable.ControloftheDream] or 0)) or MaxDps:boss() and ttd <20) and cooldown[classtable.ForceofNature].ready then
        if not setSpell then setSpell = classtable.ForceofNature end
    end
    if (MaxDps:CheckSpellUsable(classtable.FuryofElune, 'FuryofElune')) and (5 + passive_asp<AstralPowerDeficit and (cooldown[classtable.ConvoketheSpirits].remains >buff[classtable.FuryofEluneBuff].duration or not talents[classtable.ConvoketheSpirits]) or ttd <8+gcd) and cooldown[classtable.FuryofElune].ready then
        if not setSpell then setSpell = classtable.FuryofElune end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfall, 'Starfall')) and (buff[classtable.StarweaversWarpBuff].up) and cooldown[classtable.Starfall].ready then
        if not setSpell then setSpell = classtable.Starfall end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (talents[classtable.Starlord] and buff[classtable.StarlordBuff].count <3 and not pool_in_ca) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].refreshable) and cooldown[classtable.Sunfire].ready then
        if not setSpell then setSpell = classtable.Sunfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (debuff[classtable.MoonfireDeBuff].refreshable and (not talents[classtable.TreantsoftheMoon] or cooldown[classtable.ForceofNature].remains >3 and not buff[classtable.HarmonyoftheGroveBuff].up)) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (cooldown[classtable.ConvoketheSpirits].remains <gcd*2 and convoke_condition and AstralPowerDeficit <50 and buff[classtable.DryadBuff].remains >8 and buff[classtable.DryadBuff].up) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.ConvoketheSpirits, 'ConvoketheSpirits') and talents[classtable.ConvoketheSpirits]) and (convoke_condition and buff[classtable.HarmonyoftheGroveBuff].up) and cooldown[classtable.ConvoketheSpirits].ready then
        MaxDps:GlowCooldown(classtable.ConvoketheSpirits, cooldown[classtable.ConvoketheSpirits].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.StellarFlare, 'StellarFlare') and talents[classtable.StellarFlare]) and (debuff[classtable.StellarFlareDeBuff].refreshable and (ttd - debuff[classtable.StellarFlareDeBuff].remains-target >7+targets) and not buff[classtable.CaIncBuff].up) and cooldown[classtable.StellarFlare].ready then
        if not setSpell then setSpell = classtable.StellarFlare end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and ((buff[classtable.StarlordBuff].remains >4 and boat_stacks >= 7 or ttd <4) and not pool_in_ca) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.NewMoon, 'NewMoon')) and (AstralPowerDeficit >passive_asp+0 and ((buff[classtable.HarmonyoftheGroveBuff].up and not buff[classtable.CaIncBuff].up or buff[classtable.CaIncBuff].up and not cooldown[classtable.CaInc].ready) or cooldown[classtable.NewMoon].fullRecharge <cooldown[classtable.ConvoketheSpirits].remains) or ttd <20) and cooldown[classtable.NewMoon].ready then
        if not setSpell then setSpell = classtable.NewMoon end
    end
    if (MaxDps:CheckSpellUsable(classtable.HalfMoon, 'HalfMoon')) and (AstralPowerDeficit >passive_asp+0 and ((buff[classtable.HarmonyoftheGroveBuff].up and not buff[classtable.CaIncBuff].up or buff[classtable.CaIncBuff].up and not cooldown[classtable.CaInc].ready) or cooldown[classtable.NewMoon].fullRecharge <cooldown[classtable.ConvoketheSpirits].remains) or ttd <20) and cooldown[classtable.HalfMoon].ready then
        if not setSpell then setSpell = classtable.HalfMoon end
    end
    if (MaxDps:CheckSpellUsable(classtable.FullMoon, 'FullMoon')) and (AstralPowerDeficit >passive_asp+0 and ((buff[classtable.HarmonyoftheGroveBuff].up and not buff[classtable.CaIncBuff].up or buff[classtable.CaIncBuff].up and not cooldown[classtable.CaInc].ready) or cooldown[classtable.NewMoon].fullRecharge <cooldown[classtable.ConvoketheSpirits].remains) or ttd <20) and cooldown[classtable.FullMoon].ready then
        if not setSpell then setSpell = classtable.FullMoon end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (buff[classtable.StarweaversWeftBuff].up or buff[classtable.TouchtheCosmosBuff].up) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and ((AstralPowerDeficit <passive_asp+0+(0 + passive_asp)*(buff[classtable.EclipseSolarBuff].remains<(gcd * 2) and 1 or 0)) and not pool_in_ca) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildMushroom, 'WildMushroom')) and (not (MaxDps.spellHistory[1] == classtable.WildMushroom) and debuff[classtable.FungalGrowthDeBuff].remains <2) and cooldown[classtable.WildMushroom].ready then
        if not setSpell then setSpell = classtable.WildMushroom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
end
function Balance:pre_cd()
    if (MaxDps:CheckSpellUsable(classtable.spymasters_web, 'spymasters_web')) and (cd_condition and (buff[classtable.SpymastersReportBuff].count >29 or MaxDps:boss() and ttd <cooldown[classtable.CaInc].duration)) and cooldown[classtable.spymasters_web].ready then
        MaxDps:GlowCooldown(classtable.spymasters_web, cooldown[classtable.spymasters_web].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (not MaxDps:CheckTrinketNames('SpymastersWeb') and not MaxDps:CheckTrinketNames('ImperfectAscendancySerum') and not MaxDps:CheckTrinketNames('TreacherousTransmitter') and (on_use_trinket == 1 or on_use_trinket == 3) and cd_condition) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (not MaxDps:CheckTrinketNames('SpymastersWeb') and not MaxDps:CheckTrinketNames('ImperfectAscendancySerum') and not MaxDps:CheckTrinketNames('TreacherousTransmitter') and on_use_trinket == 2 and cd_condition) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
end
function Balance:st()
    if (MaxDps:CheckSpellUsable(classtable.WarriorofElune, 'WarriorofElune')) and (talents[classtable.LunarCalling] or not talents[classtable.LunarCalling] and (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <= 7) and cooldown[classtable.WarriorofElune].ready then
        if not setSpell then setSpell = classtable.WarriorofElune end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (enter_lunar and (fd.eclipseInLunar or fd.eclipseInSolar) and (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Wrath and GetSpellInfo(classtable.Wrath).castTime /1000 or 0) and not cd_condition) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (not enter_lunar and (fd.eclipseInLunar or fd.eclipseInSolar) and (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Starfire and GetSpellInfo(classtable.Starfire).castTime /1000 or 0) and not cd_condition) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].remains <3 or debuff[classtable.SunfireDeBuff].refreshable and ((MaxDps.ActiveHeroTree == 'keeperofthegrove') and cooldown[classtable.ForceofNature].ready or not (MaxDps.ActiveHeroTree == 'keeperofthegrove') and cd_condition)) and cooldown[classtable.Sunfire].ready then
        if not setSpell then setSpell = classtable.Sunfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (debuff[classtable.MoonfireDeBuff].refreshable and debuff[classtable.MoonfireDeBuff].remains <3 and (not talents[classtable.TreantsoftheMoon] or cooldown[classtable.ForceofNature].remains >3 and not buff[classtable.HarmonyoftheGroveBuff].up)) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    Balance:pre_cd()
    if (MaxDps:CheckSpellUsable(classtable.CelestialAlignment, 'CelestialAlignment')) and (not talents[102560] and cd_condition) and cooldown[classtable.CelestialAlignment].ready then
        MaxDps:GlowCooldown(classtable.CelestialAlignment, cooldown[classtable.CelestialAlignment].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Incarnation, 'Incarnation')) and (cd_condition) and cooldown[classtable.Incarnation].ready then
        MaxDps:GlowCooldown(classtable.Incarnation, cooldown[classtable.Incarnation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (enter_lunar and ((not fd.eclipseInLunar and not fd.eclipseInSolar) or (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Wrath and GetSpellInfo(classtable.Wrath).castTime /1000 or 0))) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (not enter_lunar and ((not fd.eclipseInLunar and not fd.eclipseInSolar) or (buff[classtable.EclipseLunarBuff].up and buff[classtable.EclipseLunarBuff].remains or buff[classtable.EclipseSolarBuff].up and buff[classtable.EclipseSolarBuff].remains or 0) <( classtable and classtable.Starfire and GetSpellInfo(classtable.Starfire).castTime /1000 or 0))) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (cd_condition and AstralPowerDeficit >passive_asp+0) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.ForceofNature, 'ForceofNature')) and (pre_cd_condition or cooldown[classtable.CaInc].fullRecharge + 5+15 * (talents[classtable.ControloftheDream] and talents[classtable.ControloftheDream] or 0)>cooldown[classtable.ForceofNature].remains and (not talents[classtable.ConvoketheSpirits] or cooldown[classtable.ConvoketheSpirits].remains + 10+15 * (talents[classtable.ControloftheDream] and talents[classtable.ControloftheDream] or 0)>cooldown[classtable.ForceofNature].remains or MaxDps:boss() and ttd <cooldown[classtable.ConvoketheSpirits].remains+cooldown[classtable.ConvoketheSpirits].duration + 5) and (on_use_trinket == 0 or (on_use_trinket == 1 or on_use_trinket == 3) and (MaxDps:CheckTrinketCooldown('13') >5+15 * (talents[classtable.ControloftheDream] and talents[classtable.ControloftheDream] or 0) or cooldown[classtable.CaInc].remains >20 or MaxDps:CheckTrinketReady('13')) or on_use_trinket == 2 and (MaxDps:CheckTrinketCooldown('14') >5+15 * (talents[classtable.ControloftheDream] and talents[classtable.ControloftheDream] or 0) or cooldown[classtable.CaInc].remains >20 or MaxDps:CheckTrinketReady('14'))) and (ttd >cooldown[classtable.ForceofNature].remains+5 or ttd <cooldown[classtable.CaInc].remains+7) or talents[classtable.WhirlingStars] and talents[classtable.ConvoketheSpirits] and cooldown[classtable.ConvoketheSpirits].remains >cooldown[classtable.ForceofNature].duration-10 and ttd >cooldown[classtable.ConvoketheSpirits].remains+6) and cooldown[classtable.ForceofNature].ready then
        if not setSpell then setSpell = classtable.ForceofNature end
    end
    if (MaxDps:CheckSpellUsable(classtable.FuryofElune, 'FuryofElune')) and (5 + passive_asp<AstralPowerDeficit) and cooldown[classtable.FuryofElune].ready then
        if not setSpell then setSpell = classtable.FuryofElune end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfall, 'Starfall')) and (buff[classtable.StarweaversWarpBuff].up) and cooldown[classtable.Starfall].ready then
        if not setSpell then setSpell = classtable.Starfall end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (talents[classtable.Starlord] and buff[classtable.StarlordBuff].count <3) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].refreshable) and cooldown[classtable.Sunfire].ready then
        if not setSpell then setSpell = classtable.Sunfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (debuff[classtable.MoonfireDeBuff].refreshable and (not talents[classtable.TreantsoftheMoon] or cooldown[classtable.ForceofNature].remains >3 and not buff[classtable.HarmonyoftheGroveBuff].up)) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (cooldown[classtable.ConvoketheSpirits].remains <gcd*2 and convoke_condition) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.ConvoketheSpirits, 'ConvoketheSpirits') and talents[classtable.ConvoketheSpirits]) and (convoke_condition) and cooldown[classtable.ConvoketheSpirits].ready then
        MaxDps:GlowCooldown(classtable.ConvoketheSpirits, cooldown[classtable.ConvoketheSpirits].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (buff[classtable.StarlordBuff].remains >4 and boat_stacks >= 3 or ttd <4) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.NewMoon, 'NewMoon')) and (AstralPowerDeficit >passive_asp+0 or ttd <20 or cooldown[classtable.CaInc].remains >15) and cooldown[classtable.NewMoon].ready then
        if not setSpell then setSpell = classtable.NewMoon end
    end
    if (MaxDps:CheckSpellUsable(classtable.HalfMoon, 'HalfMoon')) and (AstralPowerDeficit >passive_asp+0 and (buff[classtable.EclipseLunarBuff].remains >timeShift or buff[classtable.EclipseSolarBuff].remains >timeShift) or ttd <20 or cooldown[classtable.CaInc].remains >15) and cooldown[classtable.HalfMoon].ready then
        if not setSpell then setSpell = classtable.HalfMoon end
    end
    if (MaxDps:CheckSpellUsable(classtable.FullMoon, 'FullMoon')) and (AstralPowerDeficit >passive_asp+0 and (buff[classtable.EclipseLunarBuff].remains >timeShift or buff[classtable.EclipseSolarBuff].remains >timeShift) or ttd <20 or cooldown[classtable.CaInc].remains >15) and cooldown[classtable.FullMoon].ready then
        if not setSpell then setSpell = classtable.FullMoon end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (buff[classtable.StarweaversWeftBuff].up or buff[classtable.TouchtheCosmosStarsurgeBuff].up) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (AstralPowerDeficit <passive_asp+0+(0 + passive_asp)*(buff[classtable.EclipseSolarBuff].remains<(gcd * 3) and 1 or 0)) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.ForceofNature, 'ForceofNature')) and (not (MaxDps.ActiveHeroTree == 'keeperofthegrove')) and cooldown[classtable.ForceofNature].ready then
        if not setSpell then setSpell = classtable.ForceofNature end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildMushroom, 'WildMushroom')) and (not (MaxDps.spellHistory[1] == classtable.WildMushroom) and debuff[classtable.FungalGrowthDeBuff].remains <2) and cooldown[classtable.WildMushroom].ready then
        if not setSpell then setSpell = classtable.WildMushroom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (talents[classtable.LunarCalling]) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Regrowth, false)
    MaxDps:GlowCooldown(classtable.SolarBeam, false)
    MaxDps:GlowCooldown(classtable.imperfect_ascendancy_serum, false)
    MaxDps:GlowCooldown(classtable.trinket1, false)
    MaxDps:GlowCooldown(classtable.trinket2, false)
    MaxDps:GlowCooldown(classtable.CelestialAlignment, false)
    MaxDps:GlowCooldown(classtable.Incarnation, false)
    MaxDps:GlowCooldown(classtable.ConvoketheSpirits, false)
    MaxDps:GlowCooldown(classtable.spymasters_web, false)
end

function Balance:callaction()
    if (MaxDps:CheckSpellUsable(classtable.SolarBeam, 'SolarBeam')) and cooldown[classtable.SolarBeam].ready then
        MaxDps:GlowCooldown(classtable.SolarBeam, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (timeInCombat <2 and fd.wrathCount == 1) and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
    passive_asp = 6 / SpellHaste + (talents[classtable.NaturesBalance] and talents[classtable.NaturesBalance] or 0) + (talents[classtable.OrbitBreaker] and talents[classtable.OrbitBreaker] or 0) * debuff[classtable.MoonfireDeBuff].remains * ( buff[classtable.OrbitBreakerBuff].count >( 27 - 2 * buff[classtable.SolsticeBuff].duration ) and 1 or 0) * 24
    ca_effective_cd = math.min ( cooldown[classtable.CaInc].fullRecharge , cooldown[classtable.ForceofNature].remains )
    last_ca_inc = MaxDps:boss() and ttd <cooldown[classtable.CaInc].duration + ca_effective_cd
    pre_cd_condition = ( not talents[classtable.WhirlingStars] or not talents[classtable.ConvoketheSpirits] or cooldown[classtable.ConvoketheSpirits].remains <gcd * 2 or ttd <cooldown[classtable.ConvoketheSpirits].remains + 3 or cooldown[classtable.ConvoketheSpirits].remains >cooldown[classtable.CaInc].fullRecharge + 15 * (talents[classtable.ControloftheDream] and talents[classtable.ControloftheDream] or 0) ) and cooldown[classtable.CaInc].remains <gcd and not buff[classtable.CaIncBuff].up
    cd_condition = pre_cd_condition and ( ttd <( 15 + 5 * (talents[classtable.IncarnationChosenofElune] and talents[classtable.IncarnationChosenofElune] or 0) ) * ( 1 - (talents[classtable.WhirlingStars] and talents[classtable.WhirlingStars] or 0) * 0.2 ) or ttd >10 and ( not (MaxDps.ActiveHeroTree == 'keeperofthegrove') or buff[classtable.HarmonyoftheGroveBuff].up ) )
    convoke_condition = MaxDps:boss() and ttd <5 or ( buff[classtable.CaIncBuff].up or cooldown[classtable.CaInc].remains >40 ) and ( not (MaxDps.ActiveHeroTree == 'keeperofthegrove') or buff[classtable.HarmonyoftheGroveBuff].up or cooldown[classtable.ForceofNature].remains >15 )
    enter_lunar = talents[classtable.LunarCalling] or targets >3-(((talents[classtable.UmbralIntensity] and talents[classtable.UmbralIntensity] or 0) or talents[classtable.SouloftheForest]) and 1 or 0)
    boat_stacks = buff[classtable.BalanceofAllThingsArcaneBuff].count + buff[classtable.BalanceofAllThingsNatureBuff].count
    kotg_ca_condition = (MaxDps and MaxDps.ActiveHeroTree == 'keeperofthegrove' and MaxDps.tier and MaxDps.tier[34].count >= 4 and 1 or 0) and AstralPowerDeficit <= 50 and (on_use_trinket == 1 and MaxDps:CheckTrinketReady('13') or on_use_trinket == 2 and MaxDps:CheckTrinketReady('14') or on_use_trinket == 0 or on_use_trinket == 3 and (MaxDps:CheckTrinketReady('13') or MaxDps:CheckTrinketReady('14'))) and cooldown[classtable.ForceofNature].remains <gcd*4 and (cooldown[classtable.CaInc].fullRecharge <buff[classtable.DryadBuff].duration or not buff[classtable.CaIncBuff].up and (cooldown[classtable.ConvoketheSpirits].remains <gcd*4 or not talents[classtable.ConvoketheSpirits])) or buff[classtable.HarmonyoftheGroveBuff].up and (buff[classtable.DryadBuff].remains <gcd and buff[classtable.DryadBuff].up or buff[classtable.DryadsFavorBuff].up) or MaxDps:boss() and ttd <20
    pool_for_cd = AstralPower <MaxDps:GetSpellCost(classtable.Starsurge, 'ENERGY')*3 and (on_use_trinket == 1 and MaxDps:CheckTrinketReady('13') or on_use_trinket == 2 and MaxDps:CheckTrinketReady('14') or on_use_trinket == 3 and (MaxDps:CheckTrinketReady('13') or MaxDps:CheckTrinketReady('14')) or on_use_trinket == 0) and (cooldown[classtable.ConvoketheSpirits].ready or not talents[classtable.ConvoketheSpirits]) and not buff[classtable.CaIncBuff].up
    pool_in_ca = buff[classtable.DryadBuff].up and ((AstralPower - MaxDps:GetSpellCost(classtable.Starsurge, 'ENERGY'))+((0 <min(buff[classtable.DryadBuff].remains - gcd))*(0%2))+passive_asp)<MaxDps:GetSpellCost(classtable.Starsurge, 'ENERGY') * 2
    if (MaxDps:CheckSpellUsable(classtable.imperfect_ascendancy_serum, 'imperfect_ascendancy_serum')) and (debuff[classtable.SunfireDeBuff].remains >4 and (debuff[classtable.MoonfireDeBuff].remains >4 or talents[classtable.TreantsoftheMoon] and (cooldown[classtable.ForceofNature].remains <3 or buff[classtable.HarmonyoftheGroveBuff].up) and ca_effective_cd <1 or ttd <20 or ttd <ca_effective_cd and (buff[classtable.HarmonyoftheGroveBuff].up or cooldown[classtable.ConvoketheSpirits].ready)) and buff[classtable.SpymastersReportBuff].count <= 29) and cooldown[classtable.imperfect_ascendancy_serum].ready then
        MaxDps:GlowCooldown(classtable.imperfect_ascendancy_serum, cooldown[classtable.imperfect_ascendancy_serum].ready)
    end
    generic_trinket_condition = buff[classtable.DryadBuff].up or no_cd_talent or MaxDps:boss() and ttd <ca_effective_cd and (buff[classtable.HarmonyoftheGroveBuff].up or cooldown[classtable.ConvoketheSpirits].ready) or (buff[classtable.SpymastersReportBuff].count + ca_effective_cd%6)>29 and ca_effective_cd >20 or on_use_trinket == 0
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (not MaxDps:CheckTrinketNames('SpymastersWeb') and not MaxDps:CheckTrinketNames('ImperfectAscendancySerum') and not MaxDps:CheckTrinketNames('TreacherousTransmitter') and not MaxDps:CheckTrinketNames('SoullettingRuby') and (on_use_trinket ~=1 and on_use_trinket ~=3 and MaxDps:CheckTrinketCooldown('14') >20 or ttd<(20 + 20*((MaxDps:HasOnUseEffect('14') and MaxDps:CheckTrinketCooldown('14') <25) and 1 or 0)) or generic_trinket_condition)) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (not MaxDps:CheckTrinketNames('SpymastersWeb') and not MaxDps:CheckTrinketNames('ImperfectAscendancySerum') and not MaxDps:CheckTrinketNames('TreacherousTransmitter') and not MaxDps:CheckTrinketNames('SoullettingRuby') and (on_use_trinket <2 and MaxDps:CheckTrinketCooldown('13') >20 or on_use_trinket == 3 and MaxDps:CheckTrinketCooldown('13') >20 and (not (MaxDps.ActiveHeroTree == 'keeperofthegrove') or buff[classtable.HarmonyoftheGroveBuff].up or ceil((ttd - 15)%MaxDps:CheckTrinketCooldownDuration('14'))>ceil((ttd - cooldown[classtable.ForceofNature].remains-15)%MaxDps:CheckTrinketCooldownDuration('14'))) or ttd<(20 + 20*((MaxDps:HasOnUseEffect('13') and MaxDps:CheckTrinketCooldown('13') <25) and 1 or 0)) or generic_trinket_condition)) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (targets >1) then
        Balance:aoe()
    end
    if (not (MaxDps and MaxDps.ActiveHeroTree == 'keeperofthegrove' and MaxDps.tier and MaxDps.tier[34].count >= 4) and targets == 1) then
        Balance:st()
    end
    if ((MaxDps and MaxDps.ActiveHeroTree == 'keeperofthegrove' and MaxDps.tier and MaxDps.tier[34].count >= 4) and targets == 1) then
        Balance:kotg_st()
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
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    local trinket1ID = GetInventoryItemID('player', 13)
    local trinket2ID = GetInventoryItemID('player', 14)
    local MHID = GetInventoryItemID('player', 16)
    classtable.trinket1 = (trinket1ID and select(2,GetItemSpell(trinket1ID)) ) or 0
    classtable.trinket2 = (trinket2ID and select(2,GetItemSpell(trinket2ID)) ) or 0
    classtable.main_hand = (MHID and select(2,GetItemSpell(MHID)) ) or 0
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    ManaPerc = (Mana / ManaMax) * 100
    ManaRegen = GetPowerRegenForPowerType(ManaPT)
    ManaTimeToMax = ManaDeficit / ManaRegen
    Energy = UnitPower('player', EnergyPT)
    EnergyMax = UnitPowerMax('player', EnergyPT)
    EnergyDeficit = EnergyMax - Energy
    EnergyPerc = (Energy / EnergyMax) * 100
    EnergyRegen = GetPowerRegenForPowerType(EnergyPT)
    EnergyTimeToMax = EnergyDeficit / EnergyRegen
    AstralPower = UnitPower('player', AstralPowerPT)
    AstralPowerMax = UnitPowerMax('player', AstralPowerPT)
    AstralPowerDeficit = AstralPowerMax - AstralPower
    AstralPowerPerc = (AstralPower / AstralPowerMax) * 100
    --AstralPowerRegen = GetPowerRegenForPowerType(AstralPowerPT)
    --AstralPowerTimeToMax = AstralPowerDeficit / AstralPowerRegen
    ComboPoints = UnitPower('player', ComboPointsPT)
    ComboPointsMax = UnitPowerMax('player', ComboPointsPT)
    ComboPointsDeficit = ComboPointsMax - ComboPoints
    ComboPointsPerc = (ComboPoints / ComboPointsMax) * 100
    ComboPointsRegen = GetPowerRegenForPowerType(ComboPointsPT)
    ComboPointsTimeToMax = ComboPointsDeficit / ComboPointsRegen
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    local currentSpell = fd.currentSpell
    local wrathCount = GetSpellCastCount(classtable.Wrath)
    local starfireCount = GetSpellCastCount(classtable.Starfire)
    local origWrathCount = wrathCount
    local origStarfireCount = starfireCount
    classtable.Incarnation =  talents[102560] and C_Spell.GetSpellInfo(C_Spell.GetSpellInfo(102560).name).spellID or 102560
    local CaInc = talents[102560] and classtable.Incarnation or classtable.CelestialAlignment
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
    fd.eclipseInLunar = buff[48518].up
    fd.eclipseInSolar = buff[48517].up
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
    classtable.BounteousBloomBuff = 429215
    classtable.OrbitBreakerBuff = 329970
    classtable.SolsticeBuff = 343648
    classtable.CaIncBuff = talents[102560] and classtable.Incarnation or classtable.CelestialAlignment
    classtable.HarmonyoftheGroveBuff = 428735
    classtable.EclipseLunarBuff = 48518
    classtable.EclipseSolarBuff = 48517
    classtable.BalanceofAllThingsArcaneBuff = 394050
    classtable.BalanceofAllThingsNatureBuff = 394049
    classtable.DryadBuff = 0
    classtable.DryadsFavorBuff = 0
    classtable.SpymastersReportBuff = 451199
    classtable.DreamstateBuff = 424248
    classtable.StarweaversWarpBuff = 393942
    classtable.TouchtheCosmosStarfallBuff = 450360
    classtable.StarweaversWeftBuff = 393944
    classtable.UmbralEmbraceBuff = 393763
    classtable.PartingSkiesBuff = 395110
    classtable.FuryofEluneBuff = 202770
    classtable.StarlordBuff = 279709
    classtable.TouchtheCosmosBuff = 450360
    classtable.TouchtheCosmosStarsurgeBuff = 450360
    classtable.MoonfireDeBuff = 164812
    classtable.SunfireDeBuff = 164815
    classtable.FungalGrowthDeBuff = 81281
    classtable.Incarnation = 102560
    classtable.HalfMoon = 274282
    classtable.FullMoon = 274283
    classtable.CaInc = talents[102560] and classtable.Incarnation or classtable.CelestialAlignment


    local function debugg()
        talents[classtable.StellarFlare] = 1
        talents[classtable.TreantsoftheMoon] = 1
        talents[classtable.ConvoketheSpirits] = 1
        talents[classtable.WhirlingStars] = 1
        talents[classtable.LunarCalling] = 1
        talents[classtable.SouloftheForest] = 1
        talents[classtable.Starlord] = 1
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
