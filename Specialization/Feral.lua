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

local Feral = {}

local trinket_one_buffs
local trinket_two_buffs
local trinket_one_sync
local trinket_two_sync
local trinket_priority
local effective_energy
local time_to_pool
local need_bt
local lastconvoke
local lastzerk
local lastpotion
local zerk_biteweave
local regrowth
local easy_swipe
local proccing_bt

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
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




local function active_bt_triggers()
    return 2
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


local function boss()
    if UnitExists('boss1')
    or UnitExists('boss2')
    or UnitExists('boss3')
    or UnitExists('boss4')
    or UnitExists('boss5')
    or UnitExists('boss6')
    or UnitExists('boss7')
    or UnitExists('boss8')
    or UnitExists('boss9')
    or UnitExists('boss10') then
        return true
    end
    return false
end


function Feral:precombat()
    --if (MaxDps:FindSpell(classtable.Prowl) and CheckSpellCosts(classtable.Prowl, 'Prowl')) and (not buff[classtable.ProwlBuff].up) and cooldown[classtable.Prowl].ready then
    --    return classtable.Prowl
    --end
    if (MaxDps:FindSpell(classtable.CatForm) and CheckSpellCosts(classtable.CatForm, 'CatForm')) and (not buff[classtable.CatFormBuff].up) and cooldown[classtable.CatForm].ready then
        return classtable.CatForm
    end
end
function Feral:aoe_builder()
    if (MaxDps:FindSpell(classtable.Rake) and CheckSpellCosts(classtable.Rake, 'Rake')) and (not debuff[classtable.RakeDeBuff].up and buff[classtable.SuddenAmbushBuff].up and not ( need_bt and buff[classtable.BtRakeBuff].up )) and cooldown[classtable.Rake].ready then
        return classtable.Rake
    end
    if (MaxDps:FindSpell(classtable.BrutalSlash) and CheckSpellCosts(classtable.BrutalSlash, 'BrutalSlash')) and (not ( need_bt and buff[classtable.BtSwipeBuff].up ) and ( cooldown[classtable.BrutalSlash].fullRecharge <4 or ttd <4 or targets <4 )) and cooldown[classtable.BrutalSlash].ready then
        return classtable.BrutalSlash
    end
    if (MaxDps:FindSpell(classtable.ThrashCat) and CheckSpellCosts(classtable.ThrashCat, 'ThrashCat')) and (debuff[classtable.ThrashCatDeBuff].refreshable and not talents[classtable.ThrashingClaws]) and cooldown[classtable.ThrashCat].ready then
        return classtable.ThrashCat
    end
    --if (MaxDps:FindSpell(classtable.Prowl) and CheckSpellCosts(classtable.Prowl, 'Prowl')) and (not ( buff[classtable.BtRakeBuff].up and active_bt_triggers == 2 ) and cooldown[classtable.Rake].ready and gcd == 0 and not buff[classtable.SuddenAmbushBuff].up and ( debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4 )) and cooldown[classtable.Prowl].ready then
    --    return classtable.Prowl
    --end
    if (MaxDps:FindSpell(classtable.Shadowmeld) and CheckSpellCosts(classtable.Shadowmeld, 'Shadowmeld')) and (not ( buff[classtable.BtRakeBuff].up and active_bt_triggers == 2 ) and cooldown[classtable.Rake].ready and gcd == 0 and not buff[classtable.SuddenAmbushBuff].up and ( debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4 )) and cooldown[classtable.Shadowmeld].ready then
        return classtable.Shadowmeld
    end
    if (MaxDps:FindSpell(classtable.Rake) and CheckSpellCosts(classtable.Rake, 'Rake')) and (( debuff[classtable.RakeDeBuff].refreshable or ( debuff[classtable.RakeDeBuff].remains <1 ) ) and not ( buff[classtable.BtRakeBuff].up and active_bt_triggers == 2 )) and cooldown[classtable.Rake].ready then
        return classtable.Rake
    end
    if (MaxDps:FindSpell(classtable.BrutalSlash) and CheckSpellCosts(classtable.BrutalSlash, 'BrutalSlash')) and (not ( buff[classtable.BtSwipeBuff].up and active_bt_triggers == 2 )) and cooldown[classtable.BrutalSlash].ready then
        return classtable.BrutalSlash
    end
    if (MaxDps:FindSpell(classtable.MoonfireCat) and CheckSpellCosts(classtable.MoonfireCat, 'MoonfireCat')) and (debuff[classtable.MoonfireCatDeBuff].refreshable and ( targets <4 or talents[classtable.BrutalSlash] ) and not ( buff[classtable.BtMoonfireBuff].up and active_bt_triggers == 2 )) and cooldown[classtable.MoonfireCat].ready then
        return classtable.MoonfireCat
    end
    if (MaxDps:FindSpell(classtable.SwipeCat) and CheckSpellCosts(classtable.SwipeCat, 'SwipeCat')) and (not ( buff[classtable.BtSwipeBuff].up and active_bt_triggers == 2 )) and cooldown[classtable.SwipeCat].ready then
        return classtable.SwipeCat
    end
    if (MaxDps:FindSpell(classtable.MoonfireCat) and CheckSpellCosts(classtable.MoonfireCat, 'MoonfireCat')) and (debuff[classtable.MoonfireCatDeBuff].refreshable and not ( buff[classtable.BtMoonfireBuff].up and active_bt_triggers == 2 )) and cooldown[classtable.MoonfireCat].ready then
        return classtable.MoonfireCat
    end
    if (MaxDps:FindSpell(classtable.Rake) and CheckSpellCosts(classtable.Rake, 'Rake')) and (( debuff[classtable.RakeDeBuff].refreshable or ( debuff[classtable.RakeDeBuff].remains <1 ) ) and not ( buff[classtable.BtRakeBuff].up and active_bt_triggers == 2 )) and cooldown[classtable.Rake].ready then
        return classtable.Rake
    end
    if (MaxDps:FindSpell(classtable.Shred) and CheckSpellCosts(classtable.Shred, 'Shred')) and (not ( buff[classtable.BtShredBuff].up and active_bt_triggers == 2 ) and not easy_swipe and not buff[classtable.SuddenAmbushBuff].up) and cooldown[classtable.Shred].ready then
        return classtable.Shred
    end
    if (MaxDps:FindSpell(classtable.ThrashCat) and CheckSpellCosts(classtable.ThrashCat, 'ThrashCat')) and (not ( buff[classtable.BtThrashBuff].up and active_bt_triggers == 2 ) and not talents[classtable.ThrashingClaws]) and cooldown[classtable.ThrashCat].ready then
        return classtable.ThrashCat
    end
    if (MaxDps:FindSpell(classtable.MoonfireCat) and CheckSpellCosts(classtable.MoonfireCat, 'MoonfireCat')) and (need_bt and not buff[classtable.BtMoonfireBuff].up) and cooldown[classtable.MoonfireCat].ready then
        return classtable.MoonfireCat
    end
    if (MaxDps:FindSpell(classtable.Shred) and CheckSpellCosts(classtable.Shred, 'Shred')) and (need_bt and not buff[classtable.BtShredBuff].up and not easy_swipe) and cooldown[classtable.Shred].ready then
        return classtable.Shred
    end
    if (MaxDps:FindSpell(classtable.Rake) and CheckSpellCosts(classtable.Rake, 'Rake')) and (debuff[classtable.RakeDeBuff].remains <1.6 and need_bt and not buff[classtable.BtRakeBuff].up) and cooldown[classtable.Rake].ready then
        return classtable.Rake
    end
end
function Feral:berserk()
    if (ComboPoints == 5) then
        local finisherCheck = Feral:finisher()
        if finisherCheck then
            return Feral:finisher()
        end
    end
    if (targets >= 2) then
        local aoe_builderCheck = Feral:aoe_builder()
        if aoe_builderCheck then
            return Feral:aoe_builder()
        end
    end
    --if (MaxDps:FindSpell(classtable.Prowl) and CheckSpellCosts(classtable.Prowl, 'Prowl')) and (not ( buff[classtable.BtRakeBuff].up and active_bt_triggers == 2 ) and cooldown[classtable.Rake].ready and gcd == 0 and not buff[classtable.SuddenAmbushBuff].up and ( debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4 ) and not buff[classtable.ShadowmeldBuff].up) and cooldown[classtable.Prowl].ready then
    --    return classtable.Prowl
    --end
    if (MaxDps:FindSpell(classtable.Shadowmeld) and CheckSpellCosts(classtable.Shadowmeld, 'Shadowmeld')) and (not ( buff[classtable.BtRakeBuff].up and active_bt_triggers == 2 ) and cooldown[classtable.Rake].ready and not buff[classtable.SuddenAmbushBuff].up and ( debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4 ) and not buff[classtable.ProwlBuff].up) and cooldown[classtable.Shadowmeld].ready then
        return classtable.Shadowmeld
    end
    if (MaxDps:FindSpell(classtable.Rake) and CheckSpellCosts(classtable.Rake, 'Rake')) and (not ( buff[classtable.BtRakeBuff].up and active_bt_triggers == 2 ) and ( debuff[classtable.RakeDeBuff].remains <3 or buff[classtable.SuddenAmbushBuff].up and 1 >debuff[classtable.RakeDeBuff].remains )) and cooldown[classtable.Rake].ready then
        return classtable.Rake
    end
    if (MaxDps:FindSpell(classtable.MoonfireCat) and CheckSpellCosts(classtable.MoonfireCat, 'MoonfireCat')) and (debuff[classtable.MoonfireCatDeBuff].refreshable) and cooldown[classtable.MoonfireCat].ready then
        return classtable.MoonfireCat
    end
    if (MaxDps:FindSpell(classtable.ThrashCat) and CheckSpellCosts(classtable.ThrashCat, 'ThrashCat')) and (not talents[classtable.ThrashingClaws] and debuff[classtable.ThrashCatDeBuff].refreshable) and cooldown[classtable.ThrashCat].ready then
        return classtable.ThrashCat
    end
    if (MaxDps:FindSpell(classtable.Shred) and CheckSpellCosts(classtable.Shred, 'Shred')) and (active_bt_triggers == 2 and not buff[classtable.BtShredBuff].up) and cooldown[classtable.Shred].ready then
        return classtable.Shred
    end
    if (MaxDps:FindSpell(classtable.BrutalSlash) and CheckSpellCosts(classtable.BrutalSlash, 'BrutalSlash')) and (active_bt_triggers == 2 and not buff[classtable.BtSwipeBuff].up) and cooldown[classtable.BrutalSlash].ready then
        return classtable.BrutalSlash
    end
    if (MaxDps:FindSpell(classtable.SwipeCat) and CheckSpellCosts(classtable.SwipeCat, 'SwipeCat')) and (active_bt_triggers == 2 and not buff[classtable.BtSwipeBuff].up and talents[classtable.WildSlashes]) and cooldown[classtable.SwipeCat].ready then
        return classtable.SwipeCat
    end
    if (MaxDps:FindSpell(classtable.BrutalSlash) and CheckSpellCosts(classtable.BrutalSlash, 'BrutalSlash')) and (cooldown[classtable.BrutalSlash].charges >1 and not buff[classtable.BtSwipeBuff].up) and cooldown[classtable.BrutalSlash].ready then
        return classtable.BrutalSlash
    end
    if (MaxDps:FindSpell(classtable.Shred) and CheckSpellCosts(classtable.Shred, 'Shred')) and (not buff[classtable.BtShredBuff].up) and cooldown[classtable.Shred].ready then
        return classtable.Shred
    end
    if (MaxDps:FindSpell(classtable.BrutalSlash) and CheckSpellCosts(classtable.BrutalSlash, 'BrutalSlash')) and (cooldown[classtable.BrutalSlash].charges >1) and cooldown[classtable.BrutalSlash].ready then
        return classtable.BrutalSlash
    end
    if (MaxDps:FindSpell(classtable.SwipeCat) and CheckSpellCosts(classtable.SwipeCat, 'SwipeCat')) and (not buff[classtable.BtSwipeBuff].up and talents[classtable.WildSlashes]) and cooldown[classtable.SwipeCat].ready then
        return classtable.SwipeCat
    end
    if (MaxDps:FindSpell(classtable.Shred) and CheckSpellCosts(classtable.Shred, 'Shred')) and cooldown[classtable.Shred].ready then
        return classtable.Shred
    end
end
function Feral:builder()
    if (MaxDps:FindSpell(classtable.Shadowmeld) and CheckSpellCosts(classtable.Shadowmeld, 'Shadowmeld')) and (gcd == 0 and Energy >= 35 and not buff[classtable.SuddenAmbushBuff].up and ( debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4 ) * not ( need_bt and buff[classtable.BtRakeBuff].up ) and buff[classtable.TigersFuryBuff].up) and cooldown[classtable.Shadowmeld].ready then
        return classtable.Shadowmeld
    end
    if (MaxDps:FindSpell(classtable.Rake) and CheckSpellCosts(classtable.Rake, 'Rake')) and (( ( debuff[classtable.RakeDeBuff].refreshable and 1 >= debuff[classtable.RakeDeBuff].remains or debuff[classtable.RakeDeBuff].remains <3 ) or buff[classtable.SuddenAmbushBuff].up and 1 >debuff[classtable.RakeDeBuff].remains ) and not ( need_bt and buff[classtable.BtRakeBuff].up )) and cooldown[classtable.Rake].ready then
        return classtable.Rake
    end
    if (MaxDps:FindSpell(classtable.BrutalSlash) and CheckSpellCosts(classtable.BrutalSlash, 'BrutalSlash')) and (cooldown[classtable.BrutalSlash].fullRecharge <4 and not ( need_bt and buff[classtable.BtSwipeBuff].up )) and cooldown[classtable.BrutalSlash].ready then
        return classtable.BrutalSlash
    end
    if (MaxDps:FindSpell(classtable.ThrashCat) and CheckSpellCosts(classtable.ThrashCat, 'ThrashCat')) and (debuff[classtable.ThrashCatDeBuff].refreshable) and cooldown[classtable.ThrashCat].ready then
        return classtable.ThrashCat
    end
    if (MaxDps:FindSpell(classtable.Shred) and CheckSpellCosts(classtable.Shred, 'Shred')) and (buff[classtable.ClearcastingBuff].up) and cooldown[classtable.Shred].ready then
        return classtable.Shred
    end
    if (MaxDps:FindSpell(classtable.MoonfireCat) and CheckSpellCosts(classtable.MoonfireCat, 'MoonfireCat')) and (debuff[classtable.MoonfireCatDeBuff].refreshable) and cooldown[classtable.MoonfireCat].ready then
        return classtable.MoonfireCat
    end
    if (MaxDps:FindSpell(classtable.BrutalSlash) and CheckSpellCosts(classtable.BrutalSlash, 'BrutalSlash')) and (not ( need_bt and buff[classtable.BtSwipeBuff].up )) and cooldown[classtable.BrutalSlash].ready then
        return classtable.BrutalSlash
    end
    if (MaxDps:FindSpell(classtable.SwipeCat) and CheckSpellCosts(classtable.SwipeCat, 'SwipeCat')) and (talents[classtable.WildSlashes] and not ( need_bt and buff[classtable.BtSwipeBuff].up )) and cooldown[classtable.SwipeCat].ready then
        return classtable.SwipeCat
    end
    if (MaxDps:FindSpell(classtable.Shred) and CheckSpellCosts(classtable.Shred, 'Shred')) and (not ( need_bt and buff[classtable.BtShredBuff].up )) and cooldown[classtable.Shred].ready then
        return classtable.Shred
    end
    if (MaxDps:FindSpell(classtable.SwipeCat) and CheckSpellCosts(classtable.SwipeCat, 'SwipeCat')) and (need_bt and not buff[classtable.BtSwipeBuff].up) and cooldown[classtable.SwipeCat].ready then
        return classtable.SwipeCat
    end
    if (MaxDps:FindSpell(classtable.Rake) and CheckSpellCosts(classtable.Rake, 'Rake')) and (need_bt and not buff[classtable.BtRakeBuff].up and 1 >= debuff[classtable.RakeDeBuff].remains) and cooldown[classtable.Rake].ready then
        return classtable.Rake
    end
    if (MaxDps:FindSpell(classtable.MoonfireCat) and CheckSpellCosts(classtable.MoonfireCat, 'MoonfireCat')) and (need_bt and not buff[classtable.BtMoonfireBuff].up) and cooldown[classtable.MoonfireCat].ready then
        return classtable.MoonfireCat
    end
    if (MaxDps:FindSpell(classtable.ThrashCat) and CheckSpellCosts(classtable.ThrashCat, 'ThrashCat')) and (need_bt and not buff[classtable.BtThrashBuff].up) and cooldown[classtable.ThrashCat].ready then
        return classtable.ThrashCat
    end
end
function Feral:cooldown()
    if (MaxDps:FindSpell(classtable.Incarnation) and CheckSpellCosts(classtable.Incarnation, 'Incarnation')) and cooldown[classtable.Incarnation].ready then
        MaxDps:GlowCooldown(classtable.Incarnation, cooldown[classtable.Incarnation].ready)
    end
    if (MaxDps:FindSpell(classtable.Berserk) and CheckSpellCosts(classtable.Berserk, 'Berserk')) and cooldown[classtable.Berserk].ready then
        return classtable.Berserk
    end
    if (MaxDps:FindSpell(classtable.FeralFrenzy) and CheckSpellCosts(classtable.FeralFrenzy, 'FeralFrenzy')) and (ComboPoints <= 1 or buff[classtable.BsIncBuff].up and ComboPoints <= 2) and cooldown[classtable.FeralFrenzy].ready then
        return classtable.FeralFrenzy
    end
    if (MaxDps:FindSpell(classtable.ConvoketheSpirits) and CheckSpellCosts(classtable.ConvoketheSpirits, 'ConvoketheSpirits')) and (boss and ttd <5 or ( buff[classtable.TigersFuryBuff].up and ( ComboPoints <= 2 or buff[classtable.BsIncBuff].up and ComboPoints <= 3 ) and ( ttd >5 - (talents[classtable.AshamanesGuidance] and talents[classtable.AshamanesGuidance] or 0) or ttd == ttd ) )) and cooldown[classtable.ConvoketheSpirits].ready then
        MaxDps:GlowCooldown(classtable.ConvoketheSpirits, cooldown[classtable.ConvoketheSpirits].ready)
    end
end
function Feral:finisher()
    if (MaxDps:FindSpell(classtable.PrimalWrath) and CheckSpellCosts(classtable.PrimalWrath, 'PrimalWrath')) and (targets >1 and ( ( debuff[classtable.PrimalWrathDeBuff].remains <6.5 and not buff[classtable.BsIncBuff].up or debuff[classtable.PrimalWrathDeBuff].refreshable ) or ( not talents[classtable.RampantFerocity] and ( targets >1 and not debuff[classtable.BloodseekerVinesDeBuff].up and not buff[classtable.RavageBuff].up or targets >6 + (talents[classtable.Ravage] and talents[classtable.Ravage] or 0) ) ) or debuff[classtable.PrimalWrathDeBuff].remains <1 )) and cooldown[classtable.PrimalWrath].ready then
        return classtable.PrimalWrath
    end
    if (MaxDps:FindSpell(classtable.Rip) and CheckSpellCosts(classtable.Rip, 'Rip')) and (debuff[classtable.RipDeBuff].refreshable and ( not talents[classtable.PrimalWrath] or targets == 1 ) and ( buff[classtable.BloodtalonsBuff].up or not talents[classtable.Bloodtalons] ) and ( buff[classtable.TigersFuryBuff].up or debuff[classtable.RipDeBuff].remains <cooldown[classtable.TigersFury].remains )) and cooldown[classtable.Rip].ready then
        return classtable.Rip
    end
    if (MaxDps:FindSpell(classtable.PoolResource) and CheckSpellCosts(classtable.PoolResource, 'PoolResource')) and cooldown[classtable.PoolResource].ready then
        return classtable.PoolResource
    end
    if (MaxDps:FindSpell(classtable.FerociousBite) and CheckSpellCosts(classtable.FerociousBite, 'FerociousBite')) and (not buff[classtable.BsIncBuff].up or not talents[classtable.SouloftheForest]) and cooldown[classtable.FerociousBite].ready then
        return classtable.FerociousBite
    end
    if (MaxDps:FindSpell(classtable.FerociousBite) and CheckSpellCosts(classtable.FerociousBite, 'FerociousBite')) and (debuff[classtable.BloodseekerVinesDeBuff].up) and cooldown[classtable.FerociousBite].ready then
        return classtable.FerociousBite
    end
end
function Feral:variable()
    effective_energy = Energy + ( 40 * buff[classtable.ClearcastingBuff].count ) + ( 3 * EnergyRegen ) + ( 50 * cooldown[classtable.TigersFury].remains <3.5 and 1 or 0)
    time_to_pool = ( ( 115 - effective_energy - ( 23 * buff[classtable.IncarnationBuff].duration ) ) % EnergyRegen )
    need_bt = talents[classtable.Bloodtalons] and buff[classtable.BloodtalonsBuff].count <= 1
    lastconvoke = ( cooldown[classtable.ConvoketheSpirits].remains + cooldown[classtable.ConvoketheSpirits].duration ) >ttd and cooldown[classtable.ConvoketheSpirits].remains <ttd
    lastzerk = ( cooldown[classtable.BsInc].remains + cooldown[classtable.BsInc].duration + 5 ) >ttd and cooldown[classtable.ConvoketheSpirits].remains <ttd
    lastpotion = ( 300 - ( ( timeInCombat + 300 ) % 300 ) + 300 + 15 ) >ttd and 300 - ( ( timeInCombat + 300 ) % 300 ) + 15 <ttd
    proccing_bt = need_bt
end

function Feral:callaction()
    --if (MaxDps:FindSpell(classtable.Prowl) and CheckSpellCosts(classtable.Prowl, 'Prowl')) and (not buff[classtable.BsIncBuff].up and not buff[classtable.ProwlBuff].up) and cooldown[classtable.Prowl].ready then
    --    return classtable.Prowl
    --end
    if (MaxDps:FindSpell(classtable.CatForm) and CheckSpellCosts(classtable.CatForm, 'CatForm')) and (not buff[classtable.CatFormBuff].up and not talents[classtable.FluidForm]) and cooldown[classtable.CatForm].ready then
        return classtable.CatForm
    end
    if (MaxDps:FindSpell(classtable.SkullBash) and CheckSpellCosts(classtable.SkullBash, 'SkullBash')) and cooldown[classtable.SkullBash].ready then
        MaxDps:GlowCooldown(classtable.SkullBash, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    local variableCheck = Feral:variable()
    if variableCheck then
        return variableCheck
    end
    if (MaxDps:FindSpell(classtable.TigersFury) and CheckSpellCosts(classtable.TigersFury, 'TigersFury')) and (EnergyDeficit >35 or ComboPoints == 5) and cooldown[classtable.TigersFury].ready then
        MaxDps:GlowCooldown(classtable.TigersFury, cooldown[classtable.TigersFury].ready)
    end
    if (MaxDps:FindSpell(classtable.Rake) and CheckSpellCosts(classtable.Rake, 'Rake')) and (buff[classtable.ShadowmeldBuff].up or buff[classtable.ProwlBuff].up) and cooldown[classtable.Rake].ready then
        return classtable.Rake
    end
    if (MaxDps:FindSpell(classtable.NaturesVigil) and CheckSpellCosts(classtable.NaturesVigil, 'NaturesVigil')) and (targets >0) and cooldown[classtable.NaturesVigil].ready then
        return classtable.NaturesVigil
    end
    if (MaxDps:FindSpell(classtable.Renewal) and CheckSpellCosts(classtable.Renewal, 'Renewal')) and (curentHP <60 and regrowth) and cooldown[classtable.Renewal].ready then
        return classtable.Renewal
    end
    if (MaxDps:FindSpell(classtable.FerociousBite) and CheckSpellCosts(classtable.FerociousBite, 'FerociousBite')) and (buff[classtable.ApexPredatorsCravingBuff].up and not ( need_bt and active_bt_triggers == 2 )) and cooldown[classtable.FerociousBite].ready then
        return classtable.FerociousBite
    end
    if (MaxDps:FindSpell(classtable.AdaptiveSwarm) and CheckSpellCosts(classtable.AdaptiveSwarm, 'AdaptiveSwarm')) and (( not debuff[classtable.AdaptiveSwarmDamageDeBuff].up or debuff[classtable.AdaptiveSwarmDamageDeBuff].remains <2 ) and debuff[classtable.AdaptiveSwarmDamageDeBuff].count <3 and not (classtable and classtable.AdaptiveSwarmDamage and GetSpellCooldown(classtable.AdaptiveSwarmDamage).duration >=5 ) and not (classtable and classtable.AdaptiveSwarm and GetSpellCooldown(classtable.AdaptiveSwarm).duration >=5 ) and ttd >5 and ( buff[classtable.CatFormBuff].up and not talents[classtable.UnbridledSwarm] or targets == 1 )) and cooldown[classtable.AdaptiveSwarm].ready then
        return classtable.AdaptiveSwarm
    end
    if (MaxDps:FindSpell(classtable.AdaptiveSwarm) and CheckSpellCosts(classtable.AdaptiveSwarm, 'AdaptiveSwarm')) and (buff[classtable.CatFormBuff].up and debuff[classtable.AdaptiveSwarmDamageDeBuff].count <3 and talents[classtable.UnbridledSwarm] and targets >1) and cooldown[classtable.AdaptiveSwarm].ready then
        return classtable.AdaptiveSwarm
    end
    if (debuff[classtable.RipDeBuff].up) then
        local cooldownCheck = Feral:cooldown()
        if cooldownCheck then
            return Feral:cooldown()
        end
    end
    if (buff[classtable.BsIncBuff].up) then
        local berserkCheck = Feral:berserk()
        if berserkCheck then
            return Feral:berserk()
        end
    end
    if (ComboPoints == 5) then
        local finisherCheck = Feral:finisher()
        if finisherCheck then
            return Feral:finisher()
        end
    end
    if (targets == 1 and ComboPoints <5 and ( time_to_pool <= 0 or not need_bt or proccing_bt )) then
        local builderCheck = Feral:builder()
        if builderCheck then
            return Feral:builder()
        end
    end
    if (targets >= 2 and ComboPoints <5 and ( time_to_pool <= 0 or not need_bt or proccing_bt )) then
        local aoe_builderCheck = Feral:aoe_builder()
        if aoe_builderCheck then
            return Feral:aoe_builder()
        end
    end
    if (MaxDps:FindSpell(classtable.Regrowth) and CheckSpellCosts(classtable.Regrowth, 'Regrowth')) and (buff[classtable.PredatorySwiftnessBuff].up and regrowth) and cooldown[classtable.Regrowth].ready then
        return classtable.Regrowth
    end
    if (ComboPoints == 5) then
        local finisherCheck = Feral:finisher()
        if finisherCheck then
            return Feral:finisher()
        end
    end
    if (targets >= 2) then
        local aoe_builderCheck = Feral:aoe_builder()
        if aoe_builderCheck then
            return Feral:aoe_builder()
        end
    end
end
function Druid:Feral()
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
    classtable.ProwlBuff = 5215
    classtable.CatFormBuff = 768
    classtable.RakeDeBuff = 155722
    classtable.SuddenAmbushBuff = 0
    classtable.BtRakeBuff = 0
    classtable.BtSwipeBuff = 0
    classtable.ThrashCatDeBuff = 405233
    classtable.MoonfireCatDeBuff = 0
    classtable.BtMoonfireBuff = 0
    classtable.BtShredBuff = 0
    classtable.BtThrashBuff = 0
    classtable.ShadowmeldBuff = 58984
    classtable.TigersFuryBuff = 0
    classtable.ClearcastingBuff = 135700
    classtable.BsIncBuff = 0
    classtable.PrimalWrathDeBuff = 0
    classtable.BloodseekerVinesDeBuff = 0
    classtable.RavageBuff = 0
    classtable.RipDeBuff = 1079
    classtable.BloodtalonsBuff = 0
    classtable.IncarnationBuff = 102543
    classtable.ApexPredatorsCravingBuff = 0
    classtable.AdaptiveSwarmDamageDeBuff = 0
    classtable.PredatorySwiftnessBuff = 69369

    local precombatCheck = Feral:precombat()
    if precombatCheck then
        return Feral:precombat()
    end

    local callactionCheck = Feral:callaction()
    if callactionCheck then
        return Feral:callaction()
    end
end
