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

local Guardian = {}


local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnown(spell) then return false end
    if not C_Spell.IsSpellUsable(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'KillShot' then
        if (classtable.SicEmBuff and not buff[classtable.SicEmBuff].up) or (classtable.HuntersPreyBuff and not buff[classtable.HuntersPreyBuff].up) and targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if ( (classtable.AvengingWrathBuff and not buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and not buff[classtable.FinalVerdictBuff].up) ) and targethealthPerc > 20 then
            return false
        end
    end
    if spellstring == 'Execute' then
        if (classtable.SuddenDeathBuff and not buff[classtable.SuddenDeathBuff].up) and targethealthPerc > 35 then
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


function Guardian:precombat()
    --if (CheckSpellCosts(classtable.MarkoftheWild, 'MarkoftheWild')) and cooldown[classtable.MarkoftheWild].ready then
    --    return classtable.MarkoftheWild
    --end
    --if (CheckSpellCosts(classtable.BearForm, 'BearForm')) and cooldown[classtable.BearForm].ready then
    --    return classtable.BearForm
    --end
end

function Guardian:callaction()
    if (CheckSpellCosts(classtable.SkullBash, 'SkullBash')) and cooldown[classtable.SkullBash].ready then
        MaxDps:GlowCooldown(classtable.SkullBash, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (CheckSpellCosts(classtable.Incarnation, 'Incarnation')) and cooldown[classtable.Incarnation].ready then
        MaxDps:GlowCooldown(classtable.Incarnation, cooldown[classtable.Incarnation].ready)
    end
    if (CheckSpellCosts(classtable.Berserk, 'Berserk')) and cooldown[classtable.Berserk].ready then
        return classtable.Berserk
    end
    if (CheckSpellCosts(classtable.HeartoftheWild, 'HeartoftheWild')) and cooldown[classtable.HeartoftheWild].ready then
        return classtable.HeartoftheWild
    end
    if (CheckSpellCosts(classtable.NaturesVigil, 'NaturesVigil')) and cooldown[classtable.NaturesVigil].ready then
        return classtable.NaturesVigil
    end
    if (CheckSpellCosts(classtable.ConvoketheSpirits, 'ConvoketheSpirits')) and cooldown[classtable.ConvoketheSpirits].ready then
        MaxDps:GlowCooldown(classtable.ConvoketheSpirits, cooldown[classtable.ConvoketheSpirits].ready)
    end
    if (CheckSpellCosts(classtable.Renewal, 'Renewal')) and (curentHP <70) and cooldown[classtable.Renewal].ready then
        return classtable.Renewal
    end
    if (CheckSpellCosts(classtable.FrenziedRegeneration, 'FrenziedRegeneration')) and (curentHP <70 and ( not buff[classtable.FrenziedRegenerationBuff].up or RageDeficit <20 ) and (UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3)) and cooldown[classtable.FrenziedRegeneration].ready then
        return classtable.FrenziedRegeneration
    end
    if (CheckSpellCosts(classtable.SurvivalInstincts, 'SurvivalInstincts')) and (down and curentHP <70 and (UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3)) and cooldown[classtable.SurvivalInstincts].ready then
        return classtable.SurvivalInstincts
    end
    if (CheckSpellCosts(classtable.Barkskin, 'Barkskin')) and (down and curentHP <70 and (UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3)) and cooldown[classtable.Barkskin].ready then
        return classtable.Barkskin
    end
    if (CheckSpellCosts(classtable.Pulverize, 'Pulverize')) and cooldown[classtable.Pulverize].ready then
        return classtable.Pulverize
    end
    if (CheckSpellCosts(classtable.RageoftheSleeper, 'RageoftheSleeper')) and cooldown[classtable.RageoftheSleeper].ready then
        return classtable.RageoftheSleeper
    end
    if (CheckSpellCosts(classtable.LunarBeam, 'LunarBeam')) and cooldown[classtable.LunarBeam].ready then
        return classtable.LunarBeam
    end
    if (CheckSpellCosts(classtable.BristlingFur, 'BristlingFur')) and cooldown[classtable.BristlingFur].ready then
        return classtable.BristlingFur
    end
    if (CheckSpellCosts(classtable.Ironfur, 'Ironfur')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and ( not buff[classtable.IronfurBuff].up or RageDeficit <20 )) and cooldown[classtable.Ironfur].ready then
        return classtable.Ironfur
    end
    if (CheckSpellCosts(classtable.ThrashBear, 'ThrashBear')) and (not debuff[classtable.ThrashBearDeBuff].up) and cooldown[classtable.ThrashBear].ready then
        return classtable.ThrashBear
    end
    if (CheckSpellCosts(classtable.Moonfire, 'Moonfire')) and (debuff[classtable.MoonfireDeBuff].refreshable) and cooldown[classtable.Moonfire].ready then
        return classtable.Moonfire
    end
    if (CheckSpellCosts(classtable.Raze, 'Raze')) and (targets >1) and cooldown[classtable.Raze].ready then
        return classtable.Raze
    end
    if (CheckSpellCosts(classtable.Maul, 'Maul')) and cooldown[classtable.Maul].ready then
        return classtable.Maul
    end
    if (CheckSpellCosts(classtable.Mangle, 'Mangle')) and cooldown[classtable.Mangle].ready then
        return classtable.Mangle
    end
    if (CheckSpellCosts(classtable.ThrashBear, 'ThrashBear')) and cooldown[classtable.ThrashBear].ready then
        return classtable.ThrashBear
    end
    if (CheckSpellCosts(classtable.SwipeBear, 'SwipeBear')) and cooldown[classtable.SwipeBear].ready then
        return classtable.SwipeBear
    end
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
    Rage = UnitPower('player', RagePT)
    RageMax = UnitPowerMax('player', RagePT)
    RageDeficit = RageMax - Rage
    classtable.Incarnation =  classtable.IncarnationGuardianofUrsoc
    classtable.ThrashBear =  classtable.Thrash
    classtable.SwipeBear =  classtable.Swipe
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
    classtable.FrenziedRegenerationBuff = 22842
    classtable.IronfurBuff = 192081
    classtable.ThrashBearDeBuff = 77758
    classtable.MoonfireDeBuff = 164812

    local precombatCheck = Guardian:precombat()
    if precombatCheck then
        return Guardian:precombat()
    end

    local callactionCheck = Guardian:callaction()
    if callactionCheck then
        return Guardian:callaction()
    end
end
