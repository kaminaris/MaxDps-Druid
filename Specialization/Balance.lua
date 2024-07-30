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

local no_cd_talent
local on_use_trinket
local is_aoe
local passive_asp
local cd_condition_aoe
local starfall_condition1
local enter_solar
local starfall_condition2
local cd_condition_st
local solar_eclipse_st
local enter_eclipse
local convoke_condition
local starsurge_condition1
local starsurge_condition2

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' or spellstring == 'KillShot' then
        if targethealthPerc < 15 then
            return true
        else
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if ( (classtable.AvengingWrathBuff and buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and buff[classtable.FinalVerdictBuff].up) ) then
            return true
        end
        if targethealthPerc < 20 then
            return true
        else
            return false
        end
    end
    if spellstring == 'Execute' then
        if (classtable.SuddenDeathBuff and buff[classtable.SuddenDeathBuff].up) then
            return true
        end
        if targethealthPerc < 35 then
            return true
        else
            return false
        end
    end
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
end



local function CheckEquipped(checkName)
    for i=1,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = itemID and C_Item.GetItemInfo(itemID) or ''
        if checkName == itemName then
            return true
        end
    end
    return false
end




local function CheckTrinketNames(checkName)
    --if slot == 1 then
    --    slot = 13
    --end
    --if slot == 2 then
    --    slot = 14
    --end
    for i=13,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = C_Item.GetItemInfo(itemID)
        if checkName == itemName then
            return true
        end
    end
    return false
end


local function CheckTrinketCooldown(slot)
    if slot == 1 then
        slot = 13
    end
    if slot == 2 then
        slot = 14
    end
    if slot == 13 or slot == 14 then
        local itemID = GetInventoryItemID('player', slot)
        local _, duration, _ = C_Item.GetItemCooldown(itemID)
        if duration == 0 then return true else return false end
    else
        local tOneitemID = GetInventoryItemID('player', 13)
        local tTwoitemID = GetInventoryItemID('player', 14)
        local tOneitemName = C_Item.GetItemInfo(tOneitemID)
        local tTwoitemName = C_Item.GetItemInfo(tTwoitemID)
        if tOneitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tOneitemID)
            if duration == 0 then return true else return false end
        end
        if tTwoitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tTwoitemID)
            if duration == 0 then return true else return false end
        end
    end
end




local function CheckPrevSpell(spell)
    if MaxDps and MaxDps.spellHistory then
        if MaxDps.spellHistory[1] then
            if MaxDps.spellHistory[1] == spell then
                return true
            end
            if MaxDps.spellHistory[1] ~= spell then
                return false
            end
        end
    end
    return true
end


function Balance:precombat()
    if (MaxDps:FindSpell(classtable.Flask) and CheckSpellCosts(classtable.Flask, 'Flask')) and cooldown[classtable.Flask].ready then
        return classtable.Flask
    end
    if (MaxDps:FindSpell(classtable.Food) and CheckSpellCosts(classtable.Food, 'Food')) and cooldown[classtable.Food].ready then
        return classtable.Food
    end
    if (MaxDps:FindSpell(classtable.Augmentation) and CheckSpellCosts(classtable.Augmentation, 'Augmentation')) and cooldown[classtable.Augmentation].ready then
        return classtable.Augmentation
    end
    if (MaxDps:FindSpell(classtable.SnapshotStats) and CheckSpellCosts(classtable.SnapshotStats, 'SnapshotStats')) and cooldown[classtable.SnapshotStats].ready then
        return classtable.SnapshotStats
    end
    no_cd_talent = not talents[classtable.CelestialAlignment] and not talents[classtable.IncarnationChosenofElune] or (not cooldown[classtable.IncarnationChosenofElune].ready and not cooldown[classtable.CelestialAlignment].ready and not cooldown[classtable.AstralCommunion].ready and not cooldown[classtable.ConvoketheSpirits].ready)
    --on_use_trinket = 0
    --on_use_trinket = trinket.1.has_proc.any and trinket.1.cooldown.duration or CheckTrinketNames('SpoilsofNeltharus') or CheckTrinketNames('MirrorofFracturedTomorrows')
    --on_use_trinket = ( trinket.2.has_proc.any and trinket.2.cooldown.duration or CheckTrinketNames('SpoilsofNeltharus') or CheckTrinketNames('MirrorofFracturedTomorrows') ) * 2
	if (MaxDps:FindSpell(classtable.MoonkinForm) and CheckSpellCosts(classtable.MoonkinForm, 'MoonkinForm')) and not buff[classtable.MoonkinForm].up and cooldown[classtable.MoonkinForm].ready then
        return classtable.MoonkinForm
    end
    --if (MaxDps:FindSpell(classtable.Wrath) and CheckSpellCosts(classtable.Wrath, 'Wrath')) and cooldown[classtable.Wrath].ready then
    --    return classtable.Wrath
    --end
    --if (MaxDps:FindSpell(classtable.Wrath) and CheckSpellCosts(classtable.Wrath, 'Wrath')) and cooldown[classtable.Wrath].ready then
    --    return classtable.Wrath
    --end
    --if (MaxDps:FindSpell(classtable.StellarFlare) and CheckSpellCosts(classtable.StellarFlare, 'StellarFlare')) and cooldown[classtable.StellarFlare].ready then
    --    return classtable.StellarFlare
    --end
    --if (MaxDps:FindSpell(classtable.Starfire) and CheckSpellCosts(classtable.Starfire, 'Starfire')) and (not talents[classtable.StellarFlare]) and cooldown[classtable.Starfire].ready then
    --    return classtable.Starfire
    --end
end
function Balance:aoe()
    if (MaxDps:FindSpell(classtable.Moonfire) and CheckSpellCosts(classtable.Moonfire, 'Moonfire')) and ((select(2,IsInInstance()) == 'party')) and cooldown[classtable.Moonfire].ready then
        return classtable.Moonfire
    end
    cd_condition_aoe = not (not cooldown[classtable.IncarnationChosenofElune].ready and not cooldown[classtable.CelestialAlignment].ready and not cooldown[classtable.AstralCommunion].ready and not cooldown[classtable.ConvoketheSpirits].ready) and ( cooldown[classtable.CaInc].remains <5 and not buff[classtable.CaIncBuff].up and ( ttd <25 + 10 * talents[classtable.IncarnationChosenofElune] ) )
    if (MaxDps:FindSpell(classtable.Sunfire) and CheckSpellCosts(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].refreshable and ( ttd - debuff[classtable.SunfireDeBuff].remains ) >6 - ( targets % 2 ) and LunarPowerDeficit >passive_asp + 3) and cooldown[classtable.Sunfire].ready then
        return classtable.Sunfire
    end
    if (MaxDps:FindSpell(classtable.Moonfire) and CheckSpellCosts(classtable.Moonfire, 'Moonfire')) and (not (select(2,IsInInstance()) == 'party')) and cooldown[classtable.Moonfire].ready then
        return classtable.Moonfire
    end
    if (MaxDps:FindSpell(classtable.StellarFlare) and CheckSpellCosts(classtable.StellarFlare, 'StellarFlare')) and (LunarPowerDeficit >passive_asp + 8 and targets <( 11 - (talents[classtable.UmbralIntensity] and 1 or 0) - (talents[classtable.AstralSmolder] and 1 or 0)  ) and cd_condition_aoe) and cooldown[classtable.StellarFlare].ready then
        return classtable.StellarFlare
    end
    starfall_condition1 = cd_condition_aoe and ( talents[classtable.OrbitalStrike] and LunarPowerDeficit <passive_asp + 8 * targets or buff[classtable.TouchtheCosmosBuff].up ) or LunarPowerDeficit <( passive_asp + 8 + 12 * ( buff[classtable.EclipseLunarBuff].remains <4 or buff[classtable.EclipseSolarBuff].remains <4 ) )
    --if (MaxDps:FindSpell(classtable.CancelBuff) and CheckSpellCosts(classtable.CancelBuff, 'CancelBuff')) and (buff[classtable.StarlordBuff].remains <2 and starfall_condition1) and cooldown[classtable.CancelBuff].ready then
    --    return classtable.CancelBuff
    --end
    if (MaxDps:FindSpell(classtable.Starfall) and CheckSpellCosts(classtable.Starfall, 'Starfall')) and (starfall_condition1) and cooldown[classtable.Starfall].ready then
        return classtable.Starfall
    end
    if (MaxDps:FindSpell(classtable.Starfire) and CheckSpellCosts(classtable.Starfire, 'Starfire')) and (buff[classtable.DreamstateBuff].up and cd_condition_aoe and buff[classtable.EclipseLunarBuff].up) and cooldown[classtable.Starfire].ready then
        return classtable.Starfire
    end
    if (MaxDps:FindSpell(classtable.CelestialAlignment) and CheckSpellCosts(classtable.CelestialAlignment, 'CelestialAlignment')) and (cd_condition_aoe) and cooldown[classtable.CelestialAlignment].ready then
        return classtable.CelestialAlignment
    end
    if (MaxDps:FindSpell(classtable.Incarnation) and CheckSpellCosts(classtable.Incarnation, 'Incarnation')) and (cd_condition_aoe) and cooldown[classtable.Incarnation].ready then
        return classtable.Incarnation
    end
    if (MaxDps:FindSpell(classtable.WarriorofElune) and CheckSpellCosts(classtable.WarriorofElune, 'WarriorofElune')) and cooldown[classtable.WarriorofElune].ready then
        return classtable.WarriorofElune
    end
    enter_solar = targets <3
    if (MaxDps:FindSpell(classtable.Starfire) and CheckSpellCosts(classtable.Starfire, 'Starfire')) and (enter_solar and ( fd.eclipseAnyNext or buff[classtable.EclipseSolarBuff].remains <( classtable and classtable.Starfire and GetSpellInfo(classtable.Starfire).castTime / 1000 ) )) and cooldown[classtable.Starfire].ready then
        return classtable.Starfire
    end
    if (MaxDps:FindSpell(classtable.Wrath) and CheckSpellCosts(classtable.Wrath, 'Wrath')) and (not enter_solar and ( fd.eclipseAnyNext or buff[classtable.EclipseLunarBuff].remains <( classtable and classtable.Wrath and GetSpellInfo(classtable.Wrath).castTime / 1000 ) )) and cooldown[classtable.Wrath].ready then
        return classtable.Wrath
    end
    if (MaxDps:FindSpell(classtable.WildMushroom) and CheckSpellCosts(classtable.WildMushroom, 'WildMushroom')) and (LunarPowerDeficit >passive_asp + 20 and ( not talents[classtable.WaningTwilight] or debuff[classtable.FungalGrowthDeBuff].remains <2 and ttd >7 and not (MaxDps.spellHistory[1] == classtable.WildMushroom) )) and cooldown[classtable.WildMushroom].ready then
        return classtable.WildMushroom
    end
    if (MaxDps:FindSpell(classtable.FuryofElune) and CheckSpellCosts(classtable.FuryofElune, 'FuryofElune')) and (ttd >2 and ( buff[classtable.CaIncBuff].remains >3 ) or ttd <10) and cooldown[classtable.FuryofElune].ready then
        return classtable.FuryofElune
    end
    starfall_condition2 = ttd >4 and ( buff[classtable.StarweaversWarpBuff].up or talents[classtable.Starlord] and buff[classtable.StarlordBuff].count <3 )
    --if (MaxDps:FindSpell(classtable.CancelBuff) and CheckSpellCosts(classtable.CancelBuff, 'CancelBuff')) and (buff[classtable.StarlordBuff].remains <2 and starfall_condition2) and cooldown[classtable.CancelBuff].ready then
    --    return classtable.CancelBuff
    --end
    if (MaxDps:FindSpell(classtable.Starfall) and CheckSpellCosts(classtable.Starfall, 'Starfall')) and (starfall_condition2) and cooldown[classtable.Starfall].ready then
        return classtable.Starfall
    end
    if (MaxDps:FindSpell(classtable.FullMoon) and CheckSpellCosts(classtable.FullMoon, 'FullMoon')) and (LunarPowerDeficit >passive_asp + 40 and ( buff[classtable.EclipseLunarBuff].remains >timeShift or buff[classtable.EclipseSolarBuff].remains >timeShift ) and ( buff[classtable.CaIncBuff].up or ttd <10 )) and cooldown[classtable.FullMoon].ready then
        return classtable.FullMoon
    end
    if (MaxDps:FindSpell(classtable.Starsurge) and CheckSpellCosts(classtable.Starsurge, 'Starsurge')) and (buff[classtable.StarweaversWeftBuff].up and targets <3) and cooldown[classtable.Starsurge].ready then
        return classtable.Starsurge
    end
    if (MaxDps:FindSpell(classtable.StellarFlare) and CheckSpellCosts(classtable.StellarFlare, 'StellarFlare')) and (LunarPowerDeficit >passive_asp + 8 and targets <( 11 - (talents[classtable.UmbralIntensity] and 1 or 0)  - (talents[classtable.AstralSmolder] and 1 or 0)  )) and cooldown[classtable.StellarFlare].ready then
        return classtable.StellarFlare
    end
    if (MaxDps:FindSpell(classtable.AstralCommunion) and CheckSpellCosts(classtable.AstralCommunion, 'AstralCommunion')) and (LunarPowerDeficit >passive_asp + 50) and cooldown[classtable.AstralCommunion].ready then
        return classtable.AstralCommunion
    end
    if (MaxDps:FindSpell(classtable.ConvoketheSpirits) and CheckSpellCosts(classtable.ConvoketheSpirits, 'ConvoketheSpirits')) and (LunarPower <50 and targets <3 + (talents[classtable.ElunesGuidance] and 1 or 0) and ( buff[classtable.EclipseLunarBuff].remains >4 or buff[classtable.EclipseSolarBuff].remains >4 )) and cooldown[classtable.ConvoketheSpirits].ready then
        return classtable.ConvoketheSpirits
    end
    if (MaxDps:FindSpell(classtable.NewMoon) and CheckSpellCosts(classtable.NewMoon, 'NewMoon')) and (LunarPowerDeficit >passive_asp + 10) and cooldown[classtable.NewMoon].ready then
        return classtable.NewMoon
    end
    if (MaxDps:FindSpell(classtable.HalfMoon) and CheckSpellCosts(classtable.HalfMoon, 'HalfMoon')) and (LunarPowerDeficit >passive_asp + 20 and ( buff[classtable.EclipseLunarBuff].remains >timeShift or buff[classtable.EclipseSolarBuff].remains >timeShift )) and cooldown[classtable.HalfMoon].ready then
        return classtable.HalfMoon
    end
    if (MaxDps:FindSpell(classtable.ForceofNature) and CheckSpellCosts(classtable.ForceofNature, 'ForceofNature')) and (LunarPowerDeficit >passive_asp + 20) and cooldown[classtable.ForceofNature].ready then
        return classtable.ForceofNature
    end
    if (MaxDps:FindSpell(classtable.Starsurge) and CheckSpellCosts(classtable.Starsurge, 'Starsurge')) and (buff[classtable.StarweaversWeftBuff].up and targets <17) and cooldown[classtable.Starsurge].ready then
        return classtable.Starsurge
    end
    if (MaxDps:FindSpell(classtable.Starfire) and CheckSpellCosts(classtable.Starfire, 'Starfire')) and (targets >( 3 - ( buff[classtable.DreamstateBuff].up or buff[classtable.BalanceT314pcBuffLunarBuff].count >buff[classtable.BalanceT314pcBuffSolarBuff].count ) ) and buff[classtable.EclipseLunarBuff].up or fd.eclipseInLunar) and cooldown[classtable.Starfire].ready then
        return classtable.Starfire
    end
    if (MaxDps:FindSpell(classtable.Wrath) and CheckSpellCosts(classtable.Wrath, 'Wrath')) and cooldown[classtable.Wrath].ready then
        return classtable.Wrath
    end
    --if (MaxDps:FindSpell(classtable.RunActionList) and CheckSpellCosts(classtable.RunActionList, 'RunActionList')) and cooldown[classtable.RunActionList].ready then
    --    return classtable.RunActionList
    --end
end
function Balance:fallthru()
    if (MaxDps:FindSpell(classtable.Starfall) and CheckSpellCosts(classtable.Starfall, 'Starfall')) and (is_aoe) and cooldown[classtable.Starfall].ready then
        return classtable.Starfall
    end
    if (MaxDps:FindSpell(classtable.Starsurge) and CheckSpellCosts(classtable.Starsurge, 'Starsurge')) and cooldown[classtable.Starsurge].ready then
        return classtable.Starsurge
    end
    if (MaxDps:FindSpell(classtable.Sunfire) and CheckSpellCosts(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.MoonfireDeBuff].remains >debuff[classtable.SunfireDeBuff].remains * 22 % 18) and cooldown[classtable.Sunfire].ready then
        return classtable.Sunfire
    end
    if (MaxDps:FindSpell(classtable.Moonfire) and CheckSpellCosts(classtable.Moonfire, 'Moonfire')) and cooldown[classtable.Moonfire].ready then
        return classtable.Moonfire
    end
end
function Balance:st()
    if (MaxDps:FindSpell(classtable.Sunfire) and CheckSpellCosts(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].refreshable and debuff[classtable.SunfireDeBuff].remains <2 and ( ttd - debuff[classtable.SunfireDeBuff].remains ) >6) and cooldown[classtable.Sunfire].ready then
        return classtable.Sunfire
    end
    cd_condition_st = not (not cooldown[classtable.IncarnationChosenofElune].ready and not cooldown[classtable.CelestialAlignment].ready and not cooldown[classtable.AstralCommunion].ready and not cooldown[classtable.ConvoketheSpirits].ready) and ( cooldown[classtable.CaInc].remains <5 and not buff[classtable.CaIncBuff].up and ( ttd <25 + 10 * (talents[classtable.IncarnationChosenofElune] and 1 or 0) ) )
    if (MaxDps:FindSpell(classtable.Moonfire) and CheckSpellCosts(classtable.Moonfire, 'Moonfire')) and (debuff[classtable.MoonfireDeBuff].refreshable and debuff[classtable.MoonfireDeBuff].remains <2 and ( ttd - debuff[classtable.MoonfireDeBuff].remains ) >6) and cooldown[classtable.Moonfire].ready then
        return classtable.Moonfire
    end
    if (MaxDps:FindSpell(classtable.StellarFlare) and CheckSpellCosts(classtable.StellarFlare, 'StellarFlare')) and (debuff[classtable.StellarFlare].refreshable and LunarPowerDeficit >passive_asp + 8 and debuff[classtable.StellarFlare].remains <2 and ( ttd - debuff[classtable.StellarFlare].remains ) >8) and cooldown[classtable.StellarFlare].ready then
        return classtable.StellarFlare
    end
    --if (MaxDps:FindSpell(classtable.CancelBuff) and CheckSpellCosts(classtable.CancelBuff, 'CancelBuff')) and (buff[classtable.StarlordBuff].remains <2 and ( buff[classtable.PrimordialArcanicPulsarBuff].value >= 550 and not buff[classtable.CaIncBuff].up and buff[classtable.StarweaversWarpBuff].up or buff[classtable.PrimordialArcanicPulsarBuff].value >= 560 and buff[classtable.StarweaversWeftBuff].up )) and cooldown[classtable.CancelBuff].ready then
    --    return classtable.CancelBuff
    --end
    if (MaxDps:FindSpell(classtable.Starfall) and CheckSpellCosts(classtable.Starfall, 'Starfall')) and cooldown[classtable.Starfall].ready then
        return classtable.Starfall
    end
    if (MaxDps:FindSpell(classtable.Starsurge) and CheckSpellCosts(classtable.Starsurge, 'Starsurge')) and cooldown[classtable.Starsurge].ready then
        return classtable.Starsurge
    end
    if (MaxDps:FindSpell(classtable.Starfire) and CheckSpellCosts(classtable.Starfire, 'Starfire')) and (buff[classtable.DreamstateBuff].up and cd_condition_st and fd.eclipseInLunar) and cooldown[classtable.Starfire].ready then
        return classtable.Starfire
    end
    if (MaxDps:FindSpell(classtable.Wrath) and CheckSpellCosts(classtable.Wrath, 'Wrath')) and (buff[classtable.DreamstateBuff].up and cd_condition_st and buff[classtable.EclipseSolarBuff].up) and cooldown[classtable.Wrath].ready then
        return classtable.Wrath
    end
    if (MaxDps:FindSpell(classtable.CelestialAlignment) and CheckSpellCosts(classtable.CelestialAlignment, 'CelestialAlignment')) and (cd_condition_st) and cooldown[classtable.CelestialAlignment].ready then
        return classtable.CelestialAlignment
    end
    if (MaxDps:FindSpell(classtable.Incarnation) and CheckSpellCosts(classtable.Incarnation, 'Incarnation')) and (cd_condition_st) and cooldown[classtable.Incarnation].ready then
        return classtable.Incarnation
    end
    solar_eclipse_st = true --buff[classtable.PrimordialArcanicPulsarBuff].value <520 and cooldown[classtable.CaInc].remains >5 and targets <3 or (MaxDps.tier and MaxDps.tier[31].count >= 2)
    enter_eclipse = fd.eclipseAnyNext or solar_eclipse_st and buff[classtable.EclipseSolarBuff].up and ( buff[classtable.EclipseSolarBuff].remains <( classtable and classtable.Starfire and GetSpellInfo(classtable.Starfire).castTime / 1000 ) ) or not solar_eclipse_st and buff[classtable.EclipseLunarBuff].up and ( buff[classtable.EclipseLunarBuff].remains <( classtable and classtable.Wrath and GetSpellInfo(classtable.Wrath).castTime / 1000 ) )
    if (MaxDps:FindSpell(classtable.WarriorofElune) and CheckSpellCosts(classtable.WarriorofElune, 'WarriorofElune')) and (solar_eclipse_st and ( enter_eclipse or buff[classtable.EclipseSolarBuff].remains <7 )) and cooldown[classtable.WarriorofElune].ready then
        return classtable.WarriorofElune
    end
    if (MaxDps:FindSpell(classtable.Starfire) and CheckSpellCosts(classtable.Starfire, 'Starfire')) and (enter_eclipse and ( solar_eclipse_st or buff[classtable.WarriorofEluneBuff].up )) and cooldown[classtable.Starfire].ready then
        return classtable.Starfire
    end
    if (MaxDps:FindSpell(classtable.Wrath) and CheckSpellCosts(classtable.Wrath, 'Wrath')) and (enter_eclipse) and cooldown[classtable.Wrath].ready then
        return classtable.Wrath
    end
    convoke_condition = buff[classtable.CaIncBuff].remains >4 or ( cooldown[classtable.CaInc].remains >30 or no_cd_talent ) and ( buff[classtable.EclipseLunarBuff].remains >4 or buff[classtable.EclipseSolarBuff].remains >4 )
    if (MaxDps:FindSpell(classtable.Starsurge) and CheckSpellCosts(classtable.Starsurge, 'Starsurge')) and (talents[classtable.ConvoketheSpirits] and cooldown[classtable.ConvoketheSpirits].ready and convoke_condition) and cooldown[classtable.Starsurge].ready then
        return classtable.Starsurge
    end
    if (MaxDps:FindSpell(classtable.ConvoketheSpirits) and CheckSpellCosts(classtable.ConvoketheSpirits, 'ConvoketheSpirits')) and (convoke_condition) and cooldown[classtable.ConvoketheSpirits].ready then
        return classtable.ConvoketheSpirits
    end
    if (MaxDps:FindSpell(classtable.AstralCommunion) and CheckSpellCosts(classtable.AstralCommunion, 'AstralCommunion')) and (LunarPowerDeficit >passive_asp + 55) and cooldown[classtable.AstralCommunion].ready then
        return classtable.AstralCommunion
    end
    if (MaxDps:FindSpell(classtable.ForceofNature) and CheckSpellCosts(classtable.ForceofNature, 'ForceofNature')) and (LunarPowerDeficit >passive_asp + 20) and cooldown[classtable.ForceofNature].ready then
        return classtable.ForceofNature
    end
    if (MaxDps:FindSpell(classtable.FuryofElune) and CheckSpellCosts(classtable.FuryofElune, 'FuryofElune')) and (ttd >2 and ( buff[classtable.CaIncBuff].remains >3 ) or ttd <10) and cooldown[classtable.FuryofElune].ready then
        return classtable.FuryofElune
    end
    if (MaxDps:FindSpell(classtable.Starfall) and CheckSpellCosts(classtable.Starfall, 'Starfall')) and (buff[classtable.StarweaversWarpBuff].up) and cooldown[classtable.Starfall].ready then
        return classtable.Starfall
    end
    starsurge_condition1 = talents[classtable.Starlord] and buff[classtable.StarlordBuff].count <3 or ( buff[classtable.BalanceofAllThingsArcaneBuff].count + buff[classtable.BalanceofAllThingsNatureBuff].count ) >2 and buff[classtable.StarlordBuff].remains >4
    --if (MaxDps:FindSpell(classtable.CancelBuff) and CheckSpellCosts(classtable.CancelBuff, 'CancelBuff')) and (buff[classtable.StarlordBuff].remains <2 and starsurge_condition1) and cooldown[classtable.CancelBuff].ready then
    --    return classtable.CancelBuff
    --end
    if (MaxDps:FindSpell(classtable.Starsurge) and CheckSpellCosts(classtable.Starsurge, 'Starsurge')) and (starsurge_condition1) and cooldown[classtable.Starsurge].ready then
        return classtable.Starsurge
    end
    if (MaxDps:FindSpell(classtable.Sunfire) and CheckSpellCosts(classtable.Sunfire, 'Sunfire')) and (debuff[classtable.SunfireDeBuff].refreshable and LunarPowerDeficit >passive_asp + 3) and cooldown[classtable.Sunfire].ready then
        return classtable.Sunfire
    end
    if (MaxDps:FindSpell(classtable.Moonfire) and CheckSpellCosts(classtable.Moonfire, 'Moonfire')) and (debuff[classtable.MoonfireDeBuff].refreshable and LunarPowerDeficit >passive_asp + 3) and cooldown[classtable.Moonfire].ready then
        return classtable.Moonfire
    end
    if (MaxDps:FindSpell(classtable.StellarFlare) and CheckSpellCosts(classtable.StellarFlare, 'StellarFlare')) and (debuff[classtable.StellarFlare].refreshable and LunarPowerDeficit >passive_asp + 8) and cooldown[classtable.StellarFlare].ready then
        return classtable.StellarFlare
    end
    if (MaxDps:FindSpell(classtable.NewMoon) and CheckSpellCosts(classtable.NewMoon, 'NewMoon')) and (LunarPowerDeficit >passive_asp + 10 and ( buff[classtable.CaIncBuff].up or ttd <10 )) and cooldown[classtable.NewMoon].ready then
        return classtable.NewMoon
    end
    if (MaxDps:FindSpell(classtable.HalfMoon) and CheckSpellCosts(classtable.HalfMoon, 'HalfMoon')) and (LunarPowerDeficit >passive_asp + 20 and ( buff[classtable.EclipseLunarBuff].remains >timeShift or buff[classtable.EclipseSolarBuff].remains >timeShift ) and ( buff[classtable.CaIncBuff].up or ttd <10 )) and cooldown[classtable.HalfMoon].ready then
        return classtable.HalfMoon
    end
    if (MaxDps:FindSpell(classtable.FullMoon) and CheckSpellCosts(classtable.FullMoon, 'FullMoon')) and (LunarPowerDeficit >passive_asp + 40 and ( buff[classtable.EclipseLunarBuff].remains >timeShift or buff[classtable.EclipseSolarBuff].remains >timeShift ) and ( buff[classtable.CaIncBuff].up or ttd <10 )) and cooldown[classtable.FullMoon].ready then
        return classtable.FullMoon
    end
    starsurge_condition2 = buff[classtable.StarweaversWeftBuff].up or LunarPowerDeficit <passive_asp + 0 + ( 0 + passive_asp ) * ( (buff[classtable.EclipseSolarBuff].remains <( gcd * 3 ) and 1 or 0)) or talents[classtable.AstralCommunion] and cooldown[classtable.AstralCommunion].remains <3 or ttd <5
    --if (MaxDps:FindSpell(classtable.CancelBuff) and CheckSpellCosts(classtable.CancelBuff, 'CancelBuff')) and (buff[classtable.StarlordBuff].remains <2 and starsurge_condition2) and cooldown[classtable.CancelBuff].ready then
    --    return classtable.CancelBuff
    --end
    if (MaxDps:FindSpell(classtable.Starsurge) and CheckSpellCosts(classtable.Starsurge, 'Starsurge')) and (starsurge_condition2) and cooldown[classtable.Starsurge].ready then
        return classtable.Starsurge
    end
    if (MaxDps:FindSpell(classtable.Wrath) and CheckSpellCosts(classtable.Wrath, 'Wrath')) and cooldown[classtable.Wrath].ready then
        return classtable.Wrath
    end
    --if (MaxDps:FindSpell(classtable.RunActionList) and CheckSpellCosts(classtable.RunActionList, 'RunActionList')) and cooldown[classtable.RunActionList].ready then
    --    return classtable.RunActionList
    --end
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
    classtable.CaIncBuff = 383410
    classtable.PrimordialArcanicPulsarBuff = 393961
    classtable.TouchtheCosmosBuff = 393633
    classtable.EclipseLunarBuff = 48518
    classtable.EclipseSolarBuff = 48517
    classtable.StarlordBuff = 279709
    classtable.DreamstateBuff = 424248
    classtable.FungalGrowthDeBuff = 81281
    classtable.StarweaversWarpBuff = 393942
    classtable.StarweaversWeftBuff = 393944
    classtable.BalanceT314pcBuffLunarBuff = 0
    classtable.BalanceT314pcBuffSolarBuff = 0
    classtable.MoonfireDeBuff = 164812
	classtable.SunfireDeBuff = 164815
    classtable.WarriorofEluneBuff = 202425
    classtable.BalanceofAllThingsArcaneBuff = 394049
    classtable.BalanceofAllThingsNatureBuff = 394050

    Balance:precombat()

    is_aoe = targets >( 1 + ( (not talents[classtable.AetherialKindling] and 0 or 1) and (not talents[classtable.Starweaver] and 0 or 1) ) ) and talents[classtable.Starfall]
	passive_asp = 6 % SpellHaste + (talents[classtable.NaturesBalance] and 1 or 0) + (talents[classtable.OrbitBreaker] and 1 or 0) * debuff[classtable.MoonfireDeBuff].duration * ( (buff[classtable.OrbitBreakerBuff].count >( 27 - 2 * buff[classtable.SolsticeBuff].duration ) and 1 or 0) ) * 40
    if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (not (not cooldown[classtable.IncarnationChosenofElune].ready and not cooldown[classtable.CelestialAlignment].ready and not cooldown[classtable.AstralCommunion].ready and not cooldown[classtable.ConvoketheSpirits].ready) and ( buff[classtable.CaIncBuff].remains >= 20 or no_cd_talent or ttd <30 )) and cooldown[classtable.Potion].ready then
        return classtable.Potion
    end
    if (MaxDps:FindSpell(classtable.NaturesVigil) and CheckSpellCosts(classtable.NaturesVigil, 'NaturesVigil')) and cooldown[classtable.NaturesVigil].ready then
        return classtable.NaturesVigil
    end
    if (is_aoe) then
        local aoeCheck = Balance:aoe()
        if aoeCheck then
            return Balance:aoe()
        end
    end
    local stCheck = Balance:st()
    if stCheck then
        return stCheck
    end
    local fallthruCheck = Balance:fallthru()
    if fallthruCheck then
        return fallthruCheck
    end
    local fallthruCheck = Balance:fallthru()
    if fallthruCheck then
        return fallthruCheck
    end

end
