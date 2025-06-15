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
local EclipsePowerPT = 26
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
local ManaPerc
local Rage
local RageMax
local RageDeficit

local eclipse_dir
local eclipse

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

local function ClearCDs()
end

function Balance:callaction()
    if (MaxDps:CheckSpellUsable(classtable.MarkoftheWild, 'MarkoftheWild')) and not buff[classtable.MarkoftheWildBuff].up and cooldown[classtable.MarkoftheWild].ready then
        if not setSpell then setSpell = classtable.MarkoftheWild end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonkinForm, 'MoonkinForm')) and not buff[classtable.MoonkinFormBuff].up and cooldown[classtable.MoonkinForm].ready then
        if not setSpell then setSpell = classtable.MoonkinForm end
    end
    --if (MaxDps:CheckSpellUsable(classtable.FaerieFire, 'FaerieFire')) and (debuff[classtable.FaerieFireDeBuff].count <3 and not ( debuff[classtable.SunderArmorDeBuff].up or debuff[classtable.ExposeArmorDeBuff].up )) and cooldown[classtable.FaerieFire].ready then
    --    if not setSpell then setSpell = classtable.FaerieFire end
    --end
    print(GetTotemInfoByName("Wild Mushroom").count)
    if (MaxDps:CheckSpellUsable(classtable.WildMushroomDetonate, 'WildMushroomDetonate')) and (GetTotemInfoByName("Wild Mushroom").count >= 3) and cooldown[classtable.WildMushroomDetonate].ready then
        if not setSpell then setSpell = classtable.WildMushroomDetonate end
    end
    if (MaxDps:CheckSpellUsable(classtable.InsectSwarm, 'InsectSwarm')) and (( debuff[classtable.InsectSwarmDeBuff].duration <2 or ( debuff[classtable.InsectSwarmDeBuff].remains <10 and buff[classtable.SolarEclipseBuff].up and eclipse <15 ) ) and ( buff[classtable.SolarEclipseBuff].up or buff[classtable.LunarEclipseBuff].up or timeInCombat <10 )) and cooldown[classtable.InsectSwarm].ready then
        if not setSpell then setSpell = classtable.InsectSwarm end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildMushroomDetonate, 'WildMushroomDetonate')) and (GetTotemInfoByName("Wild Mushroom").count >0 and buff[classtable.SolarEclipseBuff].up) and cooldown[classtable.WildMushroomDetonate].ready then
        if not setSpell then setSpell = classtable.WildMushroomDetonate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Typhoon, 'Typhoon')) and cooldown[classtable.Typhoon].ready then
        if not setSpell then setSpell = classtable.Typhoon end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfall, 'Starfall')) and (eclipse < -80) and cooldown[classtable.Starfall].ready then
        if not setSpell then setSpell = classtable.Starfall end
    end
    if (MaxDps:CheckSpellUsable(classtable.Sunfire, 'Sunfire')) and (( debuff[classtable.SunfireDeBuff].refreshable ) or ( eclipse <15 and debuff[classtable.SunfireDeBuff].remains <10 )) and cooldown[classtable.Sunfire].ready then
        if not setSpell then setSpell = classtable.Sunfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and (buff[classtable.LunarEclipseBuff].up and ( ( debuff[classtable.MoonfireDeBuff].refreshable ) or ( eclipse >- 20 and debuff[classtable.MoonfireDeBuff].remains <10 ) )) and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (buff[classtable.SolarEclipseBuff].up or buff[classtable.LunarEclipseBuff].up) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Innervate, 'Innervate')) and (ManaPerc <50) and cooldown[classtable.Innervate].ready then
        if not setSpell then setSpell = classtable.Innervate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Treants, 'Treants')) and cooldown[classtable.Treants].ready then
        if not setSpell then setSpell = classtable.Treants end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (eclipse_dir == 1 and eclipse <80) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (MaxDps:CheckPrevSpell(classtable.Wrath) == 1 and eclipse_dir == - 1 and eclipse <- 87) and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Wrath, 'Wrath')) and (eclipse_dir == "moon") and cooldown[classtable.Wrath].ready then
        if not setSpell then setSpell = classtable.Wrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire')) and (eclipse_dir == "sun") and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    if (MaxDps:CheckSpellUsable(classtable.WildMushroom, 'WildMushroom')) and (GetTotemInfoByName("Wild Mushroom").count <3) and cooldown[classtable.WildMushroom].ready then
        if not setSpell then setSpell = classtable.WildMushroom end
    end
    if (MaxDps:CheckSpellUsable(classtable.Starsurge, 'Starsurge')) and (buff[classtable.ShootingStarsBuff].up) and cooldown[classtable.Starsurge].ready then
        if not setSpell then setSpell = classtable.Starsurge end
    end
    if (MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire')) and cooldown[classtable.Moonfire].ready then
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
    eclipse = UnitPower('player', EclipsePowerPT)
    local currentSpell = fd.currentSpell
    eclipse_dir = GetEclipseDirection()

    fd.eclipseInLunar = buff[classtable.EclipseLunar].up
    fd.eclipseInSolar = buff[classtable.EclipseSolar].up
    fd.eclipseInAny = fd.eclipseInSolar or fd.eclipseInLunar
    fd.eclipseInBoth = fd.eclipseInSolar and fd.eclipseInLunar

    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    classtable.Treants = 33831

    classtable.bloodlust = 0
    classtable.FaerieFireDeBuff = 91565
    classtable.SunderArmorDeBuff = 16145
    classtable.ExposeArmorDeBuff = 60842
    classtable.WildMushroomBuff = 0
    classtable.InsectSwarmDeBuff = 5570
    classtable.SolarEclipseBuff = 48517
    classtable.LunarEclipseBuff = 48518
    classtable.MoonfireDeBuff = 8921
    classtable.SunfireDeBuff = 93402
    classtable.ShootingStarsBuff = 93400
    classtable.Starsurge = 78674
    classtable.Sunfire = 93402
    classtable.MarkoftheWildBuff = 79061
    classtable.MoonkinFormBuff = 24858

    local function debugg()
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Balance:callaction()
    if setSpell then return setSpell end
end
