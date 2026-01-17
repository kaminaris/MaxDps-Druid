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

local Balance = {}

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.ForceOfNature, false)
end

function Balance:AoE()
    if (MaxDps:CheckSpellUsable(classtable.Hurricane, 'Hurricane')) and cooldown[classtable.Hurricane].ready then
        if not setSpell then setSpell = classtable.Hurricane end
    end
end

function Balance:Single()
    --Keep Faerie Fire Faerie Fire on the target if raiding, for the Improved Faerie Fire Improved Faerie Fire debuff.
    if MaxDps:CheckSpellUsable(classtable.FaerieFire, 'Faerie Fire') and MaxDps:GetPartyState() == "raid" and not debuff[classtable.FaerieFireDeBuff].up and cooldown[classtable.FaerieFire].ready then
        if not setSpell then setSpell = classtable.FaerieFire end
    end
    --Keep Moonfire Moonfire active on the target, but always let it fully finish its current duration before refreshing.
    if MaxDps:CheckSpellUsable(classtable.Moonfire, 'Moonfire') and not debuff[classtable.MoonfireDeBuff].up and cooldown[classtable.Moonfire].ready then
        if not setSpell then setSpell = classtable.Moonfire end
    end
    --Use Force of Nature Force of Nature if the trees will stay alive for most of their duration.
    if MaxDps:CheckSpellUsable(classtable.ForceOfNature, 'Force of Nature') and ttd >= 20 and cooldown[classtable.ForceOfNature].ready then
        MaxDps:GlowCooldown(classtable.ForceOfNature, true)
        --if not setSpell then setSpell = classtable.ForceOfNature end
    end
    --Spam Starfire Starfire until the target dies or you need to refresh your debuffs. If Mana is an issue, you will drop the damage over time applications and just spam Starfire.
    if MaxDps:CheckSpellUsable(classtable.Starfire, 'Starfire') and cooldown[classtable.Starfire].ready then
        if not setSpell then setSpell = classtable.Starfire end
    end
    --Use and refresh Insect Swarm Insect Swarm only when moving, in order to minimize DPS downtime!
end

function Druid:Balance()
classtable = MaxDps.SpellTable
local fd = MaxDps.FrameData
local ttd = (fd.timeToDie and fd.timeToDie) or 500
local gcd = fd.gcd
local cooldown = fd.cooldown
local buff = fd.buff
local debuff = fd.debuff
local talents = fd.talents
local targets = MaxDps:SmartAoe()

classtable.FaerieFireDeBuff = 91565
classtable.InsectSwarmDeBuff = 5570
classtable.MoonfireDeBuff = 8921
classtable.MarkoftheWildBuff = 79061
classtable.MoonkinFormBuff = 24858
classtable.ThornsBuff = 467
classtable.MarkoftheWild = 9884
classtable.MoonkinForm = 24858
classtable.InsectSwarm = 5570
classtable.FaerieFire = 770
classtable.ForceOfNature = 33831
classtable.Moonfire = 9835
classtable.Starfire = 25298
classtable.Hurricane = 16914
classtable.Thorns = 467

ClearCDs()

--AoE Rotation
--Channel Hurricane Hurricane if it will hit 3 targets or more for its whole duration.
if targets >= 3 then
    Balance:AoE()
end
--Use the single target rotation.

--Single Target Rotation
Balance:Single()

if setSpell then return setSpell end
end
