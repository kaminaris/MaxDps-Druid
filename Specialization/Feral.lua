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

local Feral = {}

local rip_duration = 0
local rip_max_pandemic_duration = 0
local dot_refresh_soon = false
local need_bt = false
local regrowth = false
local easy_swipe = false

local function FormatItemorSpell(str)
    if not str then print("format got not str ", str) return "" end
    if type(str) ~= "string" then return end
    str = str:gsub("%s+", ""):gsub("%'", ""):gsub("%,", ""):gsub("%-", ""):gsub("%:", "") or str
    return str
end

--Check if spell was cast within 4 seconds to count for Bloodtalens
local function need_bt_trigger(spell)
    if Feral.bloodTalons and Feral.bloodTalons[spell] then
        if GetTime() - Feral.bloodTalons[spell].last_used <= 4 then
            return false
        else
            return true
        end
    else
        return true
    end
end


function Feral:precombat()
    if (MaxDps:CheckSpellUsable(classtable.MarkoftheWild, 'MarkoftheWild')) and not buff[classtable.MarkoftheWild].up and cooldown[classtable.MarkoftheWild].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MarkoftheWild end
    end
    if (MaxDps:CheckSpellUsable(classtable.Prowl, 'Prowl')) and (not buff[classtable.ProwlBuff].up) and cooldown[classtable.Prowl].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Prowl end
    end
    if (MaxDps:CheckSpellUsable(classtable.CatForm, 'CatForm')) and (not buff[classtable.CatFormBuff].up) and cooldown[classtable.CatForm].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.CatForm end
    end
end
function Feral:aoe_builder()
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (debuff[classtable.ThrashCatDeBuff].refreshable and not talents[classtable.ThrashingClaws] and not (need_bt and not need_bt_trigger('Thrash'))) and cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.BrutalSlash, 'BrutalSlash')) and (talents[classtable.BrutalSlash] and (cooldown[classtable.BrutalSlash].fullRecharge <4 or ttd <4 or targets <4 or (buff[classtable.BsIncBuff].up and targets >= 3-(MaxDps.ActiveHeroTree == 'druidoftheclaw' and 1 or 0))) and not (need_bt and not need_bt_trigger('Swipe') and (not buff[classtable.BsIncBuff].up or targets <3-(MaxDps.ActiveHeroTree == 'druidoftheclaw' and 1 or 0)))) and cooldown[classtable.BrutalSlash].ready then
        if not setSpell then setSpell = classtable.BrutalSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (not talents[classtable.BrutalSlash] and talents[classtable.WildSlashes] and (ttd <4 or targets <4 or buff[classtable.BsIncBuff].up and targets >= 3-(MaxDps.ActiveHeroTree == 'druidoftheclaw' and 1 or 0)) and not (need_bt and not need_bt_trigger('Swipe') and (not buff[classtable.BsIncBuff].up or targets <3-(MaxDps.ActiveHeroTree == 'druidoftheclaw' and 1 or 0)))) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (not talents[classtable.BrutalSlash] and ttd <4 or (talents[classtable.WildSlashes] and targets >4 and not (need_bt and not need_bt_trigger('Swipe')))) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Prowl, 'Prowl')) and ((debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4) and not (need_bt and not need_bt_trigger('Rake')) and cooldown[classtable.Rake].ready and MaxDps:CooldownConsolidated(61304).remains == 0 and not buff[classtable.SuddenAmbushBuff].up and not (buff[classtable.ClearcastingBuff].count == 1)) and cooldown[classtable.Prowl].ready then
        if not setSpell then setSpell = classtable.Prowl end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowmeld, 'Shadowmeld')) and ((debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4) and not (need_bt and not need_bt_trigger('Rake')) and cooldown[classtable.Rake].ready and not buff[classtable.SuddenAmbushBuff].up and not buff[classtable.ProwlBuff].up and not (buff[classtable.ClearcastingBuff].count == 1)) and cooldown[classtable.Shadowmeld].ready then
        MaxDps:GlowCooldown(classtable.Shadowmeld, cooldown[classtable.Shadowmeld].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (debuff[classtable.RakeDeBuff].refreshable and talents[classtable.DoubleclawedRake] and not (need_bt and not need_bt_trigger('Rake')) and not (buff[classtable.ClearcastingBuff].count == 1)) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (not talents[classtable.BrutalSlash] and talents[classtable.WildSlashes] and targets >2 and not (need_bt and not need_bt_trigger('Swipe'))) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (not debuff[classtable.RakeDeBuff].up and (MaxDps.ActiveHeroTree == 'wildstalker')) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonfireCat, 'MoonfireCat')) and (talents[classtable.LunarInspiration] and debuff[classtable.MoonfireCatDeBuff].refreshable and not (need_bt and not need_bt_trigger('Moonfire')) and not (buff[classtable.ClearcastingBuff].count == 1)) and cooldown[classtable.MoonfireCat].ready then
        if not setSpell then setSpell = classtable.MoonfireCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (debuff[classtable.RakeDeBuff].refreshable and not (need_bt and not need_bt_trigger('Rake')) and not (buff[classtable.ClearcastingBuff].count == 1)) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.BrutalSlash, 'BrutalSlash')) and (talents[classtable.BrutalSlash] and not (need_bt and not need_bt_trigger('Swipe'))) and cooldown[classtable.BrutalSlash].ready then
        if not setSpell then setSpell = classtable.BrutalSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (not talents[classtable.BrutalSlash] and not (need_bt and not need_bt_trigger('Swipe'))) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (not buff[classtable.SuddenAmbushBuff].up and not easy_swipe and not (need_bt and not need_bt_trigger('Shred'))) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (not talents[classtable.ThrashingClaws] and not (need_bt and not need_bt_trigger('Thrash'))) and cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (talents[classtable.DoubleclawedRake] and buff[classtable.SuddenAmbushBuff].up and need_bt and need_bt_trigger('Rake')) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonfireCat, 'MoonfireCat')) and (talents[classtable.LunarInspiration] and need_bt and need_bt_trigger('Moonfire')) and cooldown[classtable.MoonfireCat].ready then
        if not setSpell then setSpell = classtable.MoonfireCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (buff[classtable.SuddenAmbushBuff].up and need_bt and need_bt_trigger('Rake')) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (need_bt and need_bt_trigger('Shred') and not easy_swipe) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (debuff[classtable.RakeDeBuff].remains <1.6 and need_bt and need_bt_trigger('Rake')) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (need_bt and need_bt_trigger('Thrash')) and cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end
end
function Feral:builder()
    if (MaxDps:CheckSpellUsable(classtable.Prowl, 'Prowl')) and (MaxDps:CooldownConsolidated(61304).remains == 0 and Energy >= 35 and not buff[classtable.SuddenAmbushBuff].up and (debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4) and not (need_bt and not need_bt_trigger('Rake')) and buff[classtable.TigersFuryBuff].up and not buff[classtable.ShadowmeldBuff].up) and cooldown[classtable.Prowl].ready then
        if not setSpell then setSpell = classtable.Prowl end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowmeld, 'Shadowmeld')) and (MaxDps:CooldownConsolidated(61304).remains == 0 and Energy >= 35 and not buff[classtable.SuddenAmbushBuff].up and (debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4) and not (need_bt and not need_bt_trigger('Rake')) and buff[classtable.TigersFuryBuff].up and not buff[classtable.ProwlBuff].up) and cooldown[classtable.Shadowmeld].ready then
        MaxDps:GlowCooldown(classtable.Shadowmeld, cooldown[classtable.Shadowmeld].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (((debuff[classtable.RakeDeBuff].refreshable and 1 >= debuff[classtable.RakeDeBuff].remains or debuff[classtable.RakeDeBuff].remains <3.5) or buff[classtable.SuddenAmbushBuff].up and 1 >debuff[classtable.RakeDeBuff].remains) and not (need_bt and not need_bt_trigger('Rake')) and ((MaxDps.ActiveHeroTree == 'wildstalker') or not buff[classtable.BsIncBuff].up)) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (buff[classtable.SuddenAmbushBuff].up and buff[classtable.BsIncBuff].up and not (need_bt and not need_bt_trigger('Shred') and buff[classtable.BloodtalonsBuff].count == 2)) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.BrutalSlash, 'BrutalSlash')) and (talents[classtable.BrutalSlash] and cooldown[classtable.BrutalSlash].fullRecharge <4 and not (need_bt and not need_bt_trigger('Swipe'))) and cooldown[classtable.BrutalSlash].ready then
        if not setSpell then setSpell = classtable.BrutalSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonfireCat, 'MoonfireCat')) and (talents[classtable.LunarInspiration] and debuff[classtable.MoonfireCatDeBuff].refreshable) and cooldown[classtable.MoonfireCat].ready then
        if not setSpell then setSpell = classtable.MoonfireCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (debuff[classtable.ThrashCatDeBuff].refreshable and not talents[classtable.ThrashingClaws] and not buff[classtable.BsIncBuff].up) and cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (buff[classtable.ClearcastingBuff].up and not (need_bt and not need_bt_trigger('Shred'))) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.BrutalSlash, 'BrutalSlash')) and (talents[classtable.BrutalSlash] and not (need_bt and not need_bt_trigger('Swipe'))) and cooldown[classtable.BrutalSlash].ready then
        if not setSpell then setSpell = classtable.BrutalSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (not (need_bt and not need_bt_trigger('Shred'))) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (debuff[classtable.RakeDeBuff].refreshable) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (debuff[classtable.ThrashCatDeBuff].refreshable and not talents[classtable.ThrashingClaws]) and cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (not talents[classtable.BrutalSlash] and need_bt and need_bt_trigger('Swipe')) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (need_bt and need_bt_trigger('Rake') and 1 >= debuff[classtable.RakeDeBuff].remains) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonfireCat, 'MoonfireCat')) and (talents[classtable.LunarInspiration] and need_bt and need_bt_trigger('Moonfire')) and cooldown[classtable.MoonfireCat].ready then
        if not setSpell then setSpell = classtable.MoonfireCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (need_bt and need_bt_trigger('Thrash')) and cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end
end
function Feral:cooldown()
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (MaxDps:HasOnUseEffect('13') and (MaxDps:CheckTrinketCooldown('14') >20 or not MaxDps:HasOnUseEffect('14')) or MaxDps:HasOnUseEffect('13') and (buff[classtable.BsIncBuff].up or cooldown[classtable.BsInc].remains <5 or cooldown[classtable.BsInc].remains <20 and cooldown[classtable.ConvoketheSpirits].remains >30) or MaxDps:boss() and ttd <20) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (MaxDps:HasOnUseEffect('14') and (MaxDps:CheckTrinketCooldown('13') >20 or not MaxDps:HasOnUseEffect('13')) or MaxDps:HasOnUseEffect('14') and (buff[classtable.BsIncBuff].up or MaxDps:CheckTrinketCooldownDuration('14') <= cooldown[classtable.BsInc].remains) and (not MaxDps:HasOnUseEffect('13') or MaxDps:CheckTrinketCooldown('13') >20) or MaxDps:boss() and ttd <20) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Incarnation, 'Incarnation')) and cooldown[classtable.Incarnation].ready then
        MaxDps:GlowCooldown(classtable.Incarnation, cooldown[classtable.Incarnation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and cooldown[classtable.Berserk].ready then
        MaxDps:GlowCooldown(classtable.Berserk, cooldown[classtable.Berserk].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralFrenzy, 'FeralFrenzy')) and (ComboPoints <= 1+buff[classtable.BsIncBuff].upMath and buff[classtable.FeralFrenzyBuff].up and cooldown[classtable.Berserk].ready) and cooldown[classtable.FeralFrenzy].ready then
        MaxDps:GlowCooldown(classtable.FeralFrenzy, cooldown[classtable.FeralFrenzy].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ConvoketheSpirits, 'ConvoketheSpirits')) and (MaxDps:boss() and ttd <5 or buff[classtable.BsIncBuff].up and buff[classtable.BsIncBuff].remains <5-(talents[classtable.AshamanesGuidance] and talents[classtable.AshamanesGuidance] or 0) or buff[classtable.TigersFuryBuff].up and not (ttd <cooldown[classtable.ConvoketheSpirits].duration and ttd>(20 + cooldown[classtable.BsInc].remains) and cooldown[classtable.BsInc].remains <60) and (ComboPoints <= 4 or buff[classtable.BsIncBuff].up and ComboPoints <= 3)) and cooldown[classtable.ConvoketheSpirits].ready then
        MaxDps:GlowCooldown(classtable.ConvoketheSpirits, cooldown[classtable.ConvoketheSpirits].ready)
    end
end
function Feral:finisher()
    if (MaxDps:CheckSpellUsable(classtable.PrimalWrath, 'PrimalWrath') and talents[classtable.PrimalWrath]) and (targets >1 and ((debuff[classtable.PrimalWrathDeBuff].remains <6.5 and not buff[classtable.BsIncBuff].up or debuff[classtable.PrimalWrathDeBuff].refreshable) or (not (talents[classtable.RampantFerocity] and true or false) and (targets >1 and not debuff[classtable.BloodseekerVinesDeBuff].up and not buff[classtable.RavageBuff].up or targets >6+(talents[classtable.Ravage] and talents[classtable.Ravage] or 0))))) and cooldown[classtable.PrimalWrath].ready then
        if not setSpell then setSpell = classtable.PrimalWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rip, 'Rip')) and (debuff[classtable.RipDeBuff].refreshable and (not talents[classtable.PrimalWrath] or targets == 1) and (buff[classtable.BloodtalonsBuff].up or not talents[classtable.Bloodtalons]) and (buff[classtable.TigersFuryBuff].up or debuff[classtable.RipDeBuff].remains <cooldown[classtable.TigersFury].remains) and (debuff[classtable.RipDeBuff].remains <ttd or debuff[classtable.RipDeBuff].remains <4 and buff[classtable.RavageBuff].up)) and cooldown[classtable.Rip].ready then
        if not setSpell then setSpell = classtable.Rip end
    end
    if ((MaxDps.ActiveHeroTree == 'druidoftheclaw') and buff[classtable.BsIncBuff].up and not buff[classtable.RavageBuff].up and targets >= 2) then
        Feral:aoe_builder()
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (not buff[classtable.BsIncBuff].up and (not debuff[classtable.SabertoothDeBuff].up or EnergyDeficit <40)) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (buff[classtable.BsIncBuff].up and (not debuff[classtable.SabertoothDeBuff].up or EnergyDeficit <40)) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
end
function Feral:variable()
    rip_duration = ((4+(4 * ComboPoints))*(1-(0.2 * (talents[classtable.CircleofLifeandDeath] and talents[classtable.CircleofLifeandDeath] or 0)))*(1+(0.25 * (talents[classtable.Veinripper] and talents[classtable.Veinripper] or 0))))+(math.max(rip_max_pandemic_duration , debuff[classtable.RipDeBuff].remains))
    rip_max_pandemic_duration = ((4+(4 * ComboPoints))*(1-(0.2 * (talents[classtable.CircleofLifeandDeath] and talents[classtable.CircleofLifeandDeath] or 0)))*(1+(0.25 * (talents[classtable.Veinripper] and talents[classtable.Veinripper] or 0))))*0.3
    dot_refresh_soon = (not talents[classtable.ThrashingClaws] and (debuff[classtable.ThrashCatDeBuff].remains - debuff[classtable.ThrashCatDeBuff].duration*0.3 <= 2)) or (talents[classtable.LunarInspiration] and (debuff[classtable.MoonfireCatDeBuff].remains - debuff[classtable.MoonfireCatDeBuff].duration*0.3 <= 2)) or ((debuff[classtable.RakeDeBuff].remains <1.6 or buff[classtable.SuddenAmbushBuff].up) and (debuff[classtable.RakeDeBuff].remains - debuff[classtable.RakeDeBuff].duration*0.3 <= 2))
    need_bt = talents[classtable.Bloodtalons] and buff[classtable.BloodtalonsBuff].count <= 1
    regrowth = false
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.SkullBash, false)
    MaxDps:GlowCooldown(classtable.TigersFury, false)
    MaxDps:GlowCooldown(classtable.Renewal, false)
    MaxDps:GlowCooldown(classtable.Regrowth, false)
    MaxDps:GlowCooldown(classtable.Shadowmeld, false)
    MaxDps:GlowCooldown(classtable.trinket1, false)
    MaxDps:GlowCooldown(classtable.trinket2, false)
    MaxDps:GlowCooldown(classtable.Incarnation, false)
    MaxDps:GlowCooldown(classtable.Berserk, false)
    MaxDps:GlowCooldown(classtable.FeralFrenzy, false)
    MaxDps:GlowCooldown(classtable.ConvoketheSpirits, false)
end

function Feral:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Prowl, 'Prowl')) and (not buff[classtable.BsIncBuff].up and not buff[classtable.ProwlBuff].up) and cooldown[classtable.Prowl].ready then
        if not setSpell then setSpell = classtable.Prowl end
    end
    if (MaxDps:CheckSpellUsable(classtable.CatForm, 'CatForm')) and (not buff[classtable.CatFormBuff].up and not talents[classtable.FluidForm]) and cooldown[classtable.CatForm].ready then
        if not setSpell then setSpell = classtable.CatForm end
    end
    if (MaxDps:CheckSpellUsable(classtable.SkullBash, 'SkullBash')) and cooldown[classtable.SkullBash].ready then
        MaxDps:GlowCooldown(classtable.SkullBash, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    --if (MaxDps:CheckSpellUsable(classtable.Soothe, 'Soothe')) and cooldown[classtable.Soothe].ready then
    --    if not setSpell then setSpell = classtable.Soothe end
    --end
    Feral:variable()
    if (MaxDps:CheckSpellUsable(classtable.TigersFury, 'TigersFury')) and ((EnergyDeficit >35 or ComboPoints == 5 or ComboPoints >= 3 and debuff[classtable.RipDeBuff].refreshable and buff[classtable.BloodtalonsBuff].up and (MaxDps.ActiveHeroTree == 'wildstalker')) and (MaxDps:boss() and ttd <= 15 or (cooldown[classtable.BsInc].remains >20 and ttd >5) or (cooldown[classtable.BsInc].ready and ttd >12 or MaxDps:boss()))) and cooldown[classtable.TigersFury].ready then
        MaxDps:GlowCooldown(classtable.TigersFury, cooldown[classtable.TigersFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (buff[classtable.ShadowmeldBuff].up or buff[classtable.ProwlBuff].up) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.NaturesVigil, 'NaturesVigil')) and (regrowth and curentHP <70 and (buff[classtable.BsIncBuff].up or buff[classtable.TigersFuryBuff].up)) and cooldown[classtable.NaturesVigil].ready then
        if not setSpell then setSpell = classtable.NaturesVigil end
    end
    if (MaxDps:CheckSpellUsable(classtable.Renewal, 'Renewal')) and (regrowth and curentHP <70) and cooldown[classtable.Renewal].ready then
        MaxDps:GlowCooldown(classtable.Renewal, cooldown[classtable.Renewal].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AdaptiveSwarm, 'AdaptiveSwarm')) and (debuff[classtable.AdaptiveSwarmDamageDeBuff].count <3 and (not debuff[classtable.AdaptiveSwarmDamageDeBuff].up or debuff[classtable.AdaptiveSwarmDamageDeBuff].remains <2) and not (MaxDps.spellHistory[1] == classtable.AdaptiveSwarm) and (targets == 1 or not talents[classtable.UnbridledSwarm]) and (debuff[classtable.RipDeBuff].up or (MaxDps.ActiveHeroTree == 'druidoftheclaw'))) and cooldown[classtable.AdaptiveSwarm].ready then
        if not setSpell then setSpell = classtable.AdaptiveSwarm end
    end
    if (MaxDps:CheckSpellUsable(classtable.AdaptiveSwarm, 'AdaptiveSwarm')) and (buff[classtable.CatFormBuff].up and debuff[classtable.AdaptiveSwarmDamageDeBuff].count <3 and (talents[classtable.UnbridledSwarm] and true or false) and targets >1 and debuff[classtable.RipDeBuff].up) and cooldown[classtable.AdaptiveSwarm].ready then
        if not setSpell then setSpell = classtable.AdaptiveSwarm end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (buff[classtable.ApexPredatorsCravingBuff].up and not (need_bt and buff[classtable.BloodtalonsBuff].count == 2)) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (debuff[classtable.RipDeBuff].up) then
        Feral:cooldown()
    end
    if (MaxDps:CheckSpellUsable(classtable.Rip, 'Rip')) and (talents[classtable.RipandTear] and targets == 1 and (MaxDps.ActiveHeroTree == 'wildstalker') and buff[classtable.TigersFuryBuff].up and not buff[classtable.BsIncBuff].up and (buff[classtable.BloodtalonsBuff].up or not talents[classtable.Bloodtalons]) and (ComboPoints >= 3 and debuff[classtable.RipDeBuff].refreshable and cooldown[classtable.TigersFury].remains >25 or buff[classtable.TigersFuryBuff].remains <5 and rip_duration >cooldown[classtable.TigersFury].remains and cooldown[classtable.TigersFury].remains >= debuff[classtable.RipDeBuff].remains)) and cooldown[classtable.Rip].ready then
        if not setSpell then setSpell = classtable.Rip end
    end
    if ((buff[classtable.BsIncBuff].up and not buff[classtable.RavageBuff].up and not buff[classtable.CoiledToSpringBuff].up and (MaxDps.ActiveHeroTree == 'druidoftheclaw') and talents[classtable.CoiledToSpring] and targets <= 2) or buff[classtable.BloodtalonsBuff].count == 0 and buff[classtable.BloodtalonsBuff].count == 2) then
        Feral:builder()
    end
    if (ComboPoints == 5) then
        Feral:finisher()
    end
    if (targets == 1 and ComboPoints <5) then
        Feral:builder()
    end
    if (targets >= 2 and ComboPoints <5) then
        Feral:aoe_builder()
    end
    if (MaxDps:CheckSpellUsable(classtable.TigersFury, 'TigersFury')) and cooldown[classtable.TigersFury].ready then
        MaxDps:GlowCooldown(classtable.TigersFury, cooldown[classtable.TigersFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Regrowth, 'Regrowth')) and (buff[classtable.PredatorySwiftnessBuff].up and regrowth) and cooldown[classtable.Regrowth].ready then
        MaxDps:GlowCooldown(classtable.Regrowth, cooldown[classtable.Regrowth].ready)
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
    Rage = UnitPower('player', RagePT)
    RageMax = UnitPowerMax('player', RagePT)
    RageDeficit = RageMax - Rage
    RagePerc = (Rage / RageMax) * 100
    RageRegen = GetPowerRegenForPowerType(RagePT)
    RageTimeToMax = RageDeficit / RageRegen
    ComboPoints = UnitPower('player', ComboPointsPT)
    ComboPointsMax = UnitPowerMax('player', ComboPointsPT)
    ComboPointsDeficit = ComboPointsMax - ComboPoints
    ComboPointsPerc = (ComboPoints / ComboPointsMax) * 100
    ComboPointsRegen = GetPowerRegenForPowerType(ComboPointsPT)
    ComboPointsTimeToMax = ComboPointsDeficit / ComboPointsRegen
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    classtable.Incarnation =  classtable.IncarnationAvatarofAshamane
    classtable.MoonfireCat =  classtable.Moonfire
    classtable.ThrashCat =  classtable.Thrash
    classtable.SwipeCat =  classtable.Swipe
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.ProwlBuff = 5215
    classtable.CatFormBuff = 768
    classtable.BsIncBuff = talents[102543] and 102543 or 106951
    classtable.BloodtalonsBuff = 145152
    classtable.ShadowmeldBuff = 58984
    classtable.TigersFuryBuff = 5217
    classtable.ApexPredatorsCravingBuff = 391882
    classtable.RavageBuff = 441585
    classtable.CoiledToSpringBuff = 449538
    classtable.PredatorySwiftnessBuff = 69369
    classtable.BtThrashBuff = 0
    classtable.BtSwipeBuff = 0
    classtable.BtRakeBuff = 0
    classtable.SuddenAmbushBuff = 391974
    classtable.ClearcastingBuff = 135700
    classtable.BtMoonfireBuff = 0
    classtable.BtShredBuff = 0
    classtable.PreparingToStrikeBuff = 0
    classtable.RipDeBuff = 1079
    classtable.AdaptiveSwarmDamageDeBuff = 391889
    classtable.RakeDeBuff = 155722
    classtable.PrimalWrathDeBuff = 1079
    classtable.BloodseekerVinesDeBuff = 439531
    classtable.SabertoothDeBuff = 391722
    classtable.ThrashCatDeBuff = 405233
    classtable.MoonfireCatDeBuff = 155625
    classtable.ThrashCat = 106830
    classtable.SwipeCat = 106785
    classtable.Shadowmeld = 58984
    classtable.BsInc = 106951
    classtable.Incarnation = 102560

    local function debugg()
        talents[classtable.FluidForm] = 1
        talents[classtable.UnbridledSwarm] = 1
        talents[classtable.RipandTear] = 1
        talents[classtable.Bloodtalons] = 1
        talents[classtable.CoiledToSpring] = 1
        talents[classtable.ThrashingClaws] = 1
        talents[classtable.WildSlashes] = 1
        talents[classtable.DoubleclawedRake] = 1
        talents[classtable.RampantFerocity] = 1
        talents[classtable.PrimalWrath] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Feral:precombat()

    Feral:callaction()
    if setSpell then return setSpell end
end

local BTBuffInfo = {}
Feral.bloodTalonsTrackingFrame = CreateFrame('Frame')
Feral.bloodTalonsTrackingFrame:RegisterUnitEvent('UNIT_SPELLCAST_SUCCEEDED', 'player')
Feral.bloodTalonsTrackingFrame:RegisterUnitEvent('UNIT_AURA', 'player')
Feral.bloodTalonsTrackingFrame:SetScript('OnEvent', function(_, event, unitTarget, updateInfo, spellId)
    if not Feral.bloodTalons then
        Feral.bloodTalons = {}
    end
    if event == 'UNIT_SPELLCAST_SUCCEEDED' then
        -- event, unit, lineId
        if C_Spell.GetSpellName(spellId) == "Brutal Slash" then
            spellId = 106785
        end
        if not Feral.bloodTalons[FormatItemorSpell(C_Spell.GetSpellName(spellId))] then
            Feral.bloodTalons[FormatItemorSpell(C_Spell.GetSpellName(spellId))] = {}
        end
        Feral.bloodTalons[FormatItemorSpell(C_Spell.GetSpellName(spellId))].last_used = GetTime()
        --print("Adding: ", FormatItemorSpell(C_Spell.GetSpellName(spellId)))
        --if C_Spell.GetSpellName(spellId) == "Brutal Slash" then
        --    --print("formated spell: ", FormatItemorSpell(C_Spell.GetSpellName(spellId)) )
        --    --print(Feral.bloodTalons[FormatItemorSpell(C_Spell.GetSpellName(spellId))].last_used)
        --    print(need_bt_trigger('BrutalSlash'))
        --    print( GetTime() - Feral.bloodTalons[FormatItemorSpell(C_Spell.GetSpellName(spellId))].last_used )
        --end
        --if C_Spell.GetSpellName(spellId) == "Thrash" then
        --    print(need_bt_trigger('Thrash'))
        --    print(Feral.bloodTalons[FormatItemorSpell(C_Spell.GetSpellName(spellId))].last_used)
        --end
        --if C_Spell.GetSpellName(spellId) == "Shred" then
        --    print(need_bt_trigger('Shred'))
        --    print(Feral.bloodTalons[FormatItemorSpell(C_Spell.GetSpellName(spellId))].last_used)
        --end
        --if C_Spell.GetSpellName(spellId) == "Rake" then
        --    print("need rake: ", need_bt_trigger('Rake'))
        --    print(Feral.bloodTalons[FormatItemorSpell(C_Spell.GetSpellName(spellId))].last_used)
        --    print( GetTime() - Feral.bloodTalons[FormatItemorSpell(C_Spell.GetSpellName(spellId))].last_used )
        --end
        --if C_Spell.GetSpellName(spellId) == "Swipe" then
        --    print(need_bt_trigger('Swipe'))
        --    print(Feral.bloodTalons[FormatItemorSpell(C_Spell.GetSpellName(spellId))].last_used)
        --end
        --if C_Spell.GetSpellName(spellId) == "Moonfire" then
        --    print(need_bt_trigger('Moonfire'))
        --    print(Feral.bloodTalons[FormatItemorSpell(C_Spell.GetSpellName(spellId))].last_used)
        --end
    end
    if event == "UNIT_AURA" then
        local guid = UnitGUID(unitTarget)
        local targetGUID = UnitGUID("target")
        local playerGUID = UnitGUID("player")
        if (updateInfo and updateInfo.isFullUpdate) then
            if (AuraUtil.ForEachAura) then
                if guid == playerGUID then
                    AuraUtil.ForEachAura(unitTarget, "HELPFUL", nil,
                        function(aura)
                            if aura and aura.spellId and aura.spellId == 145152 then
                                wipe(Feral.bloodTalons)
                                BTBuffInfo.count = aura.applications
                                BTBuffInfo.auraInstanceID = aura.auraInstanceID
                            end
                        end,
                    true)
                end
            end
        end

        if updateInfo and updateInfo.addedAuras then
            for _, aura in pairs(updateInfo.addedAuras) do
                if guid == playerGUID and aura.isHelpful then
                    if aura.spellId and aura.spellId == 145152 then
                        wipe(Feral.bloodTalons)
                        BTBuffInfo.count = aura.applications
                        BTBuffInfo.auraInstanceID = aura.auraInstanceID
                    end
                end
            end
        end

        if updateInfo and updateInfo.updatedAuraInstanceIDs then
            for _, auraInstanceID in ipairs(updateInfo.updatedAuraInstanceIDs) do
                local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unitTarget, auraInstanceID)
                if aura then
                    if guid == playerGUID and aura.isHelpful then
                        if (aura.spellId and aura.spellId == 145152) and (not BTBuffInfo.count or BTBuffInfo.count ~= aura.applications) then
                            wipe(Feral.bloodTalons)
                            BTBuffInfo.count = aura.applications
                            BTBuffInfo.auraInstanceID = aura.auraInstanceID
                        end
                    end
                end
            end
        end

        if updateInfo and updateInfo.removedAuraInstanceIDs then
            for _, auraInstanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
                if guid == playerGUID and BTBuffInfo.auraInstanceID == auraInstanceID then
                    wipe(Feral.bloodTalons)
                    BTBuffInfo = {}
                end
            end
        end

    end
end)
