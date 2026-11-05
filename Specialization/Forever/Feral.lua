local _, addonTable = ...
local Druid = addonTable.Druid
local MaxDps = _G.MaxDps
if not MaxDps then return end

local GetItemCooldown = C_Item.GetItemCooldown
local usedTrinkets = {}
local aurasSetup = true

local Feral = {}

function Druid:Feral()
    --st cat
    if MaxDps.IsTrackedAuraActive(768) then
        if (not MaxDps.IsTrackedAuraActive(1822)) and not MaxDps.IsSpellOnCooldown(1822, true) then return 1822 end --  Rake
        if (MaxDps.Spells[1322605] and (MaxDps.Power("energy", false) <= 60)) and not MaxDps.IsSpellOnCooldown(1322605, true) then return 1322605 end --  Shifting Power
        if (MaxDps.IsTrackedAuraActive(5215)) and not MaxDps.IsSpellOnCooldown(6785, true) then return 6785 end --  Ravage
        if (not MaxDps.IsTrackedAuraActive(770)) and not MaxDps.IsSpellOnCooldown(770, true) then return 770 end --  Faerie Fire
        if ((MaxDps.Power("combo_points", false) >= 5) and not MaxDps.IsTrackedAuraActive(1079)) and not MaxDps.IsSpellOnCooldown(1079, true) then return 1079 end --  Rip
        if (MaxDps.Power("combo_points", false) == 5 and not MaxDps.IsTrackedAuraActive(16870)) and not MaxDps.IsSpellOnCooldown(22568, true) then return 22568 end --  Ferocious Bite
        if not MaxDps.IsSpellOnCooldown(5221, true) then return 5221 end --  Shred
        if not MaxDps.IsSpellOnCooldown(1082, true) then return 1082 end --  Claw
        if (not MaxDps.IsTrackedAuraActive(768)) and not MaxDps.IsSpellOnCooldown(768, true) then return 768 end --  Cat Form
    end

    --st bear
    if (MaxDps.IsTrackedAuraActive(5487) or MaxDps.IsTrackedAuraActive(9634)) and MaxDps:SmartAoe() <= 1 then
        if (not MaxDps.IsTrackedAuraActive(770)) and not MaxDps.IsSpellOnCooldown(770, true) then return 770 end --  Faerie Fire
        if (not MaxDps.IsTrackedAuraActive(99)) and not MaxDps.IsSpellOnCooldown(99, true) then return 99 end --  Demoralizing Roar
        if not MaxDps.IsSpellOnCooldown(407995, true) then return 407995 end --  Primal Bite
        if (MaxDps.Stacks("target", 414644, "HARMFUL") < 5 or not MaxDps.IsTrackedAuraActive(414644)) and not MaxDps.IsSpellOnCooldown(414644, true) then return 414644 end --  Lacerate
        if ((MaxDps.Power("rage", false) >= 25)) and not MaxDps.IsSpellOnCooldown(6807, true) then return 6807 end --  Maul
        if not MaxDps.IsSpellOnCooldown(414644, true) then return 414644 end --  Lacerate
    end

    --aoe bear
    if (MaxDps.IsTrackedAuraActive(5487) or MaxDps.IsTrackedAuraActive(9634)) and MaxDps:SmartAoe() > 1 then
        if not MaxDps.IsSpellOnCooldown(779, true) then return 779 end --  Swipe
        if (not MaxDps.IsTrackedAuraActive(770)) and not MaxDps.IsSpellOnCooldown(770, true) then return 770 end --  Faerie Fire
        if (not MaxDps.IsTrackedAuraActive(99)) and not MaxDps.IsSpellOnCooldown(99, true) then return 99 end --  Demoralizing Roar
        if not MaxDps.IsSpellOnCooldown(407995, true) then return 407995 end --  Primal Bite
        if (MaxDps.Stacks("target", 414644, "HARMFUL") < 5 or not MaxDps.IsTrackedAuraActive(414644)) and not MaxDps.IsSpellOnCooldown(414644, true) then return 414644 end --  Lacerate
        if ((MaxDps.Power("rage", false) >= 25)) and not MaxDps.IsSpellOnCooldown(6807, true) then return 6807 end --  Maul
        if not MaxDps.IsSpellOnCooldown(414644, true) then return 414644 end --  Lacerate
    end
end
