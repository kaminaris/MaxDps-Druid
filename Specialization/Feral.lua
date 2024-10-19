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
local proccing_bt
local effective_energy
local time_to_pool
local dot_refresh_soon
local need_bt
local cc_capped
local lastconvoke
local lastzerk
local lastpotion
local regrowth
local easy_swipe
local moonfire_snapshotted


--Check if spell was cast within 4 seconds to count for Bloodtalens
local function need_bt_trigger(spell)
    local spellName = C_Spell.GetSpellInfo(spell)
    return GetTime - MaxDps.spellHistoryTime[spellName] <= 4
end


function Feral:precombat()
    if (MaxDps:CheckSpellUsable(classtable.MarkoftheWild, 'MarkoftheWild')) and (not buff[classtable.MarkoftheWild].up) and cooldown[classtable.MarkoftheWild].ready and not UnitAffectingCombat('player') then
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
    proccing_bt = need_bt
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (debuff[classtable.ThrashCatDeBuff].refreshable and not talents[classtable.ThrashingClaws] and not ( need_bt and need_bt_trigger('Thrash') )) and cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.BrutalSlash, 'BrutalSlash')) and talents[classtable.BrutalSlash] and (( cooldown[classtable.BrutalSlash].fullRecharge <4 or ttd <4 or targets <4 or ( buff[classtable.BsIncBuff].up and targets >= 3 - (MaxDps.ActiveHeroTree == 'druidoftheclaw') ) ) and not ( need_bt and need_bt_trigger('Swipe') and ( not buff[classtable.BsIncBuff].up or targets <3 - (MaxDps.ActiveHeroTree == 'druidoftheclaw') ) )) and cooldown[classtable.BrutalSlash].ready then
        if not setSpell then setSpell = classtable.BrutalSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (ttd <4 or ( talents[classtable.WildSlashes] and targets >4 and not ( need_bt and need_bt_trigger('Swipe') ) )) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Prowl, 'Prowl')) and (debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4 and not ( need_bt and need_bt_trigger('Rake') ) and cooldown[classtable.Rake].ready and gcd == 0 and not buff[classtable.SuddenAmbushBuff].up and not cc_capped) and cooldown[classtable.Prowl].ready then
        if not setSpell then setSpell = classtable.Prowl end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowmeld, 'Shadowmeld')) and (debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4 and not ( need_bt and need_bt_trigger('Rake') ) and cooldown[classtable.Rake].ready and not buff[classtable.SuddenAmbushBuff].up and not buff[classtable.ProwlBuff].up and not cc_capped) and cooldown[classtable.Shadowmeld].ready then
        MaxDps:GlowCooldown(classtable.Shadowmeld, cooldown[classtable.Shadowmeld].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (debuff[classtable.RakeDeBuff].refreshable and talents[classtable.DoubleclawedRake] and not ( need_bt and need_bt_trigger('Rake') ) and not cc_capped) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (talents[classtable.WildSlashes] and targets >3 and not ( need_bt and need_bt_trigger('Swipe') )) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonfireCat, 'MoonfireCat')) and talents[classtable.LunarInspiration] and (debuff[classtable.MoonfireCatDeBuff].refreshable and not ( need_bt and need_bt_trigger('Moonfire') ) and not cc_capped) and cooldown[classtable.MoonfireCat].ready then
        if not setSpell then setSpell = classtable.MoonfireCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (debuff[classtable.RakeDeBuff].refreshable and not ( need_bt and need_bt_trigger('Rake') ) and not cc_capped) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.BrutalSlash, 'BrutalSlash')) and talents[classtable.BrutalSlash] and (not ( need_bt and need_bt_trigger('Swipe') )) and cooldown[classtable.BrutalSlash].ready then
        if not setSpell then setSpell = classtable.BrutalSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (not ( need_bt and need_bt_trigger('Swipe') )) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (not buff[classtable.SuddenAmbushBuff].up and not easy_swipe and not ( need_bt and need_bt_trigger('Shred') )) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (not talents[classtable.ThrashingClaws] and not ( need_bt and need_bt_trigger('Thrash') )) and cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (talents[classtable.DoubleclawedRake] and buff[classtable.SuddenAmbushBuff].up and need_bt and need_bt_trigger('Rake')) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonfireCat, 'MoonfireCat')) and talents[classtable.LunarInspiration] and (need_bt and need_bt_trigger('Moonfire')) and cooldown[classtable.MoonfireCat].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (need_bt and need_bt_trigger('Shred')) and cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end
end
function Feral:builder()
    if (MaxDps:CheckSpellUsable(classtable.Prowl, 'Prowl')) and (gcd == 0 and Energy >= 35 and not buff[classtable.SuddenAmbushBuff].up and ( debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4 ) * not ( need_bt and need_bt_trigger('Rake') ) and buff[classtable.TigersFuryBuff].up and not buff[classtable.ShadowmeldBuff].up) and cooldown[classtable.Prowl].ready then
        if not setSpell then setSpell = classtable.Prowl end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowmeld, 'Shadowmeld')) and (gcd == 0 and Energy >= 35 and not buff[classtable.SuddenAmbushBuff].up and ( debuff[classtable.RakeDeBuff].refreshable or debuff[classtable.RakeDeBuff].remains <1.4 ) * not ( need_bt and need_bt_trigger('Rake') ) and buff[classtable.TigersFuryBuff].up and not buff[classtable.ProwlBuff].up) and cooldown[classtable.Shadowmeld].ready then
        MaxDps:GlowCooldown(classtable.Shadowmeld, cooldown[classtable.Shadowmeld].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (( ( debuff[classtable.RakeDeBuff].refreshable and 1 >= debuff[classtable.RakeDeBuff].remains or debuff[classtable.RakeDeBuff].remains <3.5 ) or buff[classtable.SuddenAmbushBuff].up and 1 >debuff[classtable.RakeDeBuff].remains ) and not ( need_bt and need_bt_trigger('Rake') )) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.BrutalSlash, 'BrutalSlash')) and talents[classtable.BrutalSlash] and (cooldown[classtable.BrutalSlash].fullRecharge <4 and not ( need_bt and need_bt_trigger('Swipe') )) and cooldown[classtable.BrutalSlash].ready then
        if not setSpell then setSpell = classtable.BrutalSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonfireCat, 'MoonfireCat')) and talents[classtable.LunarInspiration] and (debuff[classtable.MoonfireCatDeBuff].refreshable) and cooldown[classtable.MoonfireCat].ready then
        if not setSpell then setSpell = classtable.MoonfireCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (debuff[classtable.ThrashCatDeBuff].refreshable and not talents[classtable.ThrashingClaws]) and cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (buff[classtable.ClearcastingBuff].up and not ( need_bt and need_bt_trigger('Shred') )) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.BrutalSlash, 'BrutalSlash')) and talents[classtable.BrutalSlash] and (not ( need_bt and need_bt_trigger('Swipe') )) and cooldown[classtable.BrutalSlash].ready then
        if not setSpell then setSpell = classtable.BrutalSlash end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (talents[classtable.WildSlashes] and not ( need_bt and need_bt_trigger('Swipe') )) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonfireCat, 'MoonfireCat')) and talents[classtable.LunarInspiration] and (not ( need_bt and need_bt_trigger('Moonfire') ) and not ( moonfire_snapshotted and not buff[classtable.TigersFuryBuff].up )) and cooldown[classtable.MoonfireCat].ready then
        if not setSpell then setSpell = classtable.MoonfireCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shred, 'Shred')) and (not ( need_bt and need_bt_trigger('Shred') )) and cooldown[classtable.Shred].ready then
        if not setSpell then setSpell = classtable.Shred end
    end
    if (MaxDps:CheckSpellUsable(classtable.SwipeCat, 'SwipeCat')) and (need_bt and need_bt_trigger('Swipe')) and cooldown[classtable.SwipeCat].ready then
        if not setSpell then setSpell = classtable.SwipeCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (need_bt and need_bt_trigger('Rake') and 1 >= debuff[classtable.RakeDeBuff].remains) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.MoonfireCat, 'MoonfireCat')) and talents[classtable.LunarInspiration] and (need_bt and need_bt_trigger('Moonfire')) and cooldown[classtable.MoonfireCat].ready then
        if not setSpell then setSpell = classtable.MoonfireCat end
    end
    if (MaxDps:CheckSpellUsable(classtable.ThrashCat, 'ThrashCat')) and (need_bt and need_bt_trigger('Thrash')) and cooldown[classtable.ThrashCat].ready then
        if not setSpell then setSpell = classtable.ThrashCat end
    end
end
function Feral:cooldown()
    if (MaxDps:CheckSpellUsable(classtable.Incarnation, 'Incarnation')) and (ttd >17 or MaxDps:boss()) and cooldown[classtable.Incarnation].ready then
        MaxDps:GlowCooldown(classtable.Incarnation, cooldown[classtable.Incarnation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Berserk, 'Berserk')) and not talents[classtable.Incarnation] and (buff[classtable.TigersFuryBuff].up and ( ttd >12 or MaxDps:boss() )) and cooldown[classtable.Berserk].ready then
        MaxDps:GlowCooldown(classtable.Berserk, cooldown[classtable.Berserk].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FeralFrenzy, 'FeralFrenzy')) and (ComboPoints <= 1 or buff[classtable.BsIncBuff].up and ComboPoints <= 2) and cooldown[classtable.FeralFrenzy].ready then
        if not setSpell then setSpell = classtable.FeralFrenzy end
    end
    if (MaxDps:CheckSpellUsable(classtable.ConvoketheSpirits, 'ConvoketheSpirits')) and (MaxDps:boss() and ttd <5 or ( cooldown[classtable.BsInc].remains >45 or buff[classtable.BsIncBuff].up or not talents[classtable.BerserkHeartoftheLion] ) and ( buff[classtable.TigersFuryBuff].up and ( ComboPoints <= 4 or buff[classtable.BsIncBuff].up and ComboPoints <= 3 ) and ( ttd >5 - (talents[classtable.AshamanesGuidance] and talents[classtable.AshamanesGuidance] or 0) or MaxDps:boss() ) )) and cooldown[classtable.ConvoketheSpirits].ready then
        MaxDps:GlowCooldown(classtable.ConvoketheSpirits, cooldown[classtable.ConvoketheSpirits].ready)
    end
end
function Feral:finisher()
    if (MaxDps:CheckSpellUsable(classtable.PrimalWrath, 'PrimalWrath')) and (targets >1 and ( ( debuff[classtable.PrimalWrathDeBuff].remains <6.5 and not buff[classtable.BsIncBuff].up or debuff[classtable.PrimalWrathDeBuff].refreshable ) or ( not talents[classtable.RampantFerocity] and ( targets >1 and not debuff[classtable.BloodseekerVinesDeBuff].up and not buff[classtable.RavageBuff].up or targets >6 + (talents[classtable.Ravage] and talents[classtable.Ravage] or 0) ) ) )) and cooldown[classtable.PrimalWrath].ready then
        if not setSpell then setSpell = classtable.PrimalWrath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Rip, 'Rip')) and (debuff[classtable.RipDeBuff].refreshable and ( not talents[classtable.PrimalWrath] or targets == 1 ) and ( buff[classtable.BloodtalonsBuff].up or not talents[classtable.Bloodtalons] ) and ( buff[classtable.TigersFuryBuff].up or debuff[classtable.RipDeBuff].remains <cooldown[classtable.TigersFury].remains ) and ( debuff[classtable.RipDeBuff].remains <ttd or debuff[classtable.RipDeBuff].remains <4 and buff[classtable.RavageBuff].up )) and cooldown[classtable.Rip].ready then
        if not setSpell then setSpell = classtable.Rip end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (not buff[classtable.BsIncBuff].up) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (buff[classtable.BsIncBuff].up) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
end
function Feral:variable()
    effective_energy = Energy + ( 40 * buff[classtable.ClearcastingBuff].count ) + ( 3 * EnergyRegen ) + ( 50 * ( cooldown[classtable.TigersFury].remains <3.5 and 1 or 0 ) )
    time_to_pool = ( ( 115 - effective_energy - ( 23 * buff[classtable.IncarnationBuff].duration ) ) % EnergyRegen )
    dot_refresh_soon = ( not talents[classtable.ThrashingClaws] and ( debuff[classtable.ThrashCatDeBuff].remains - debuff[classtable.ThrashCatDeBuff].duration * 0.3 <= 2 ) ) or ( talents[classtable.LunarInspiration] and ( debuff[classtable.MoonfireCatDeBuff].remains - debuff[classtable.MoonfireCatDeBuff].duration * 0.3 <= 2 ) ) or ( ( debuff[classtable.RakeDeBuff].remains <1.6 or buff[classtable.SuddenAmbushBuff].up ) and ( debuff[classtable.RakeDeBuff].remains - debuff[classtable.RakeDeBuff].duration * 0.3 <= 2 ) )
    need_bt = talents[classtable.Bloodtalons] and buff[classtable.BloodtalonsBuff].count <= 1
    cc_capped = buff[classtable.ClearcastingBuff].count == ( 1 + (talents[classtable.MomentofClarity] and talents[classtable.MomentofClarity] or 0) )
    lastconvoke = ( cooldown[classtable.ConvoketheSpirits].remains + cooldown[classtable.ConvoketheSpirits].duration ) >ttd and cooldown[classtable.ConvoketheSpirits].remains <ttd
    lastzerk = ( cooldown[classtable.BsInc].remains + cooldown[classtable.BsInc].duration + 5 ) >ttd and cooldown[classtable.ConvoketheSpirits].remains <ttd
    lastpotion = ( cooldown[classtable.Potions].remains + cooldown[classtable.Potions].duration + 15 ) >ttd and cooldown[classtable.Potions].remains + 15 <ttd
    regrowth = false
    proccing_bt = need_bt
    if MaxDps:CheckPrevSpell(classtable.LunarInspiration) then
        moonfire_snapshotted = buff[classtable.TigersFuryBuff].up
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.SkullBash, false)
    MaxDps:GlowCooldown(classtable.TigersFury, false)
    MaxDps:GlowCooldown(classtable.Renewal, false)
    MaxDps:GlowCooldown(classtable.Regrowth, false)
    MaxDps:GlowCooldown(classtable.Shadowmeld, false)
    MaxDps:GlowCooldown(classtable.Incarnation, false)
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
    if (MaxDps:CheckSpellUsable(classtable.TigersFury, 'TigersFury')) and (( EnergyDeficit >35 or ComboPoints == 5 or ComboPoints >= 3 and debuff[classtable.RipDeBuff].refreshable and buff[classtable.BloodtalonsBuff].up ) and ( MaxDps:boss() and ttd <= 15 or ( cooldown[classtable.BsInc].remains >20 and ttd >5 ) or ( cooldown[classtable.BsInc].ready and ttd >12 or MaxDps:boss() ) )) and cooldown[classtable.TigersFury].ready then
        MaxDps:GlowCooldown(classtable.TigersFury, cooldown[classtable.TigersFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Rake, 'Rake')) and (buff[classtable.ShadowmeldBuff].up or buff[classtable.ProwlBuff].up) and cooldown[classtable.Rake].ready then
        if not setSpell then setSpell = classtable.Rake end
    end
    if (MaxDps:CheckSpellUsable(classtable.NaturesVigil, 'NaturesVigil')) and (regrowth and curentHP <70 and ( buff[classtable.BsIncBuff].up or buff[classtable.TigersFuryBuff].up )) and cooldown[classtable.NaturesVigil].ready then
        if not setSpell then setSpell = classtable.NaturesVigil end
    end
    if (MaxDps:CheckSpellUsable(classtable.Renewal, 'Renewal')) and (regrowth and curentHP <70) and cooldown[classtable.Renewal].ready then
        MaxDps:GlowCooldown(classtable.Renewal, cooldown[classtable.Renewal].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AdaptiveSwarm, 'AdaptiveSwarm')) and (debuff[classtable.AdaptiveSwarmDamageDeBuff].count <3 and ( not debuff[classtable.AdaptiveSwarmDamageDeBuff].up or debuff[classtable.AdaptiveSwarmDamageDeBuff].remains <2 ) and not (classtable and classtable.AdaptiveSwarm and GetSpellCooldown(classtable.AdaptiveSwarm).duration >=5 ) and ( targets == 1 or not talents[classtable.UnbridledSwarm] ) and ( debuff[classtable.RipDeBuff].up or (MaxDps.ActiveHeroTree == 'druidoftheclaw') )) and cooldown[classtable.AdaptiveSwarm].ready then
        if not setSpell then setSpell = classtable.AdaptiveSwarm end
    end
    if (MaxDps:CheckSpellUsable(classtable.AdaptiveSwarm, 'AdaptiveSwarm')) and (buff[classtable.CatFormBuff].up and debuff[classtable.AdaptiveSwarmDamageDeBuff].count <3 and talents[classtable.UnbridledSwarm] and targets >1 and debuff[classtable.RipDeBuff].up) and cooldown[classtable.AdaptiveSwarm].ready then
        if not setSpell then setSpell = classtable.AdaptiveSwarm end
    end
    if (MaxDps:CheckSpellUsable(classtable.FerociousBite, 'FerociousBite')) and (buff[classtable.ApexPredatorsCravingBuff].up and not ( need_bt and active_bt_triggers == 2 )) and cooldown[classtable.FerociousBite].ready then
        if not setSpell then setSpell = classtable.FerociousBite end
    end
    if (debuff[classtable.RipDeBuff].up) then
        Feral:cooldown()
    end
    if (MaxDps:CheckSpellUsable(classtable.Rip, 'Rip')) and (targets == 1 and (MaxDps.ActiveHeroTree == 'wildstalker') and not ( talents[classtable.RagingFury] and talents[classtable.Veinripper] ) and ( buff[classtable.BloodtalonsBuff].up or not talents[classtable.Bloodtalons] ) and ( debuff[classtable.RipDeBuff].remains <5 and buff[classtable.TigersFuryBuff].remains >10 and ComboPoints >= 3 or ( ( buff[classtable.TigersFuryBuff].remains <3 and ComboPoints == 5 ) or buff[classtable.TigersFuryBuff].remains <= 1 ) and buff[classtable.TigersFuryBuff].up and ComboPoints >= 3 and debuff[classtable.RipDeBuff].remains <cooldown[classtable.TigersFury].remains )) and cooldown[classtable.Rip].ready then
        if not setSpell then setSpell = classtable.Rip end
    end
    if (ComboPoints == 5) then
        Feral:finisher()
    end
    if (targets == 1 and ComboPoints <5 and ( time_to_pool <= 0 or not need_bt or proccing_bt )) then
        Feral:builder()
    end
    if (targets >= 2 and ComboPoints <5 and ( time_to_pool <= 0 or not need_bt or proccing_bt )) then
        Feral:aoe_builder()
    end
    --if (MaxDps:CheckSpellUsable(classtable.Regrowth, 'Regrowth')) and (buff[classtable.PredatorySwiftnessBuff].up and regrowth and selection_time >gcd) and cooldown[classtable.Regrowth].ready then
    --    MaxDps:GlowCooldown(classtable.Regrowth, cooldown[classtable.Regrowth].ready)
    --end
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
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
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
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.ProwlBuff = 5215
    classtable.CatFormBuff = 768
    classtable.ThrashCatDeBuff = 405233
    classtable.BsIncBuff = 0
    classtable.RakeDeBuff = 155722
    classtable.SuddenAmbushBuff = 0
    classtable.MoonfireCatDeBuff = 164812
    classtable.TigersFuryBuff = 5217
    classtable.ShadowmeldBuff = 58984
    classtable.ClearcastingBuff = 135700
    classtable.PrimalWrathDeBuff = 1079
    classtable.BloodseekerVinesDeBuff = 0
    classtable.RavageBuff = 441585
    classtable.RipDeBuff = 1079
    classtable.BloodtalonsBuff = 145152
    classtable.tigers_furyDeBuff = 0
    classtable.IncarnationBuff = 102543
    classtable.AdaptiveSwarmDamageDeBuff = 391889
    classtable.ApexPredatorsCravingBuff = 0
    classtable.PredatorySwiftnessBuff = 69369
    setSpell = nil
    ClearCDs()

    Feral:precombat()

    Feral:callaction()
    if setSpell then return setSpell end
end
