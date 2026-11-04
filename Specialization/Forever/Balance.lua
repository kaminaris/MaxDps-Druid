local _, addonTable = ...
local Druid = addonTable.Druid
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Balance = {}

function Druid:Balance()
    if MaxDps.Power("mana") <= 30 or MaxDps.Starved() then return 29166 end --  Innervate
    if not MaxDps.IsTrackedAuraActive(8921) then return 8921 end --  Moonfire
    if not MaxDps.IsTrackedAuraActive(5570) then return 5570 end --  Insect Swarm
    if not MaxDps.IsSpellOnCooldown(2912, true) then return 2912 end --  Starfire
end
