local _, addonTable = ...
local Druid = addonTable.Druid
local MaxDps = _G.MaxDps
if not MaxDps then return end

local Restoration = {}

function Druid:Restoration()
    --st
    if (not MaxDps.IsTrackedAuraActive(8921)) and not MaxDps.IsSpellOnCooldown(8921, true) then return 8921 end --  Moonfire
    if not MaxDps.IsSpellOnCooldown(5176, true) then return 5176 end --  Wrath
end
