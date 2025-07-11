﻿local addonName, addonTable = ...
_G[addonName] = addonTable

--- @type MaxDps
if not MaxDps then return end
local MaxDps = MaxDps
local UnitPower = UnitPower

local Druid = MaxDps:NewModule('Druid', 'AceEvent-3.0')
addonTable.Druid = Druid

Druid.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!')
	end
}

function Druid:Enable()
	if MaxDps:IsClassicWow() or MaxDps:IsCataWow() then
		if MaxDps.Spec == 1 then
			MaxDps.NextSpell = Druid.Balance
			MaxDps:Print(MaxDps.Colors.Info .. 'Druid Balance', "info")
		elseif MaxDps.Spec == 2 or MaxDps.Spec == 3 then
			MaxDps.NextSpell = Druid.Feral
			MaxDps:Print(MaxDps.Colors.Info .. 'Druid Feral', "info")
		elseif MaxDps.Spec == 4 then
			MaxDps.NextSpell = Druid.Restoration
			MaxDps:Print(MaxDps.Colors.Info .. 'Druid Restoration', "info")
		end

		return true
	else
		if MaxDps.Spec == 1 then
			MaxDps.NextSpell = Druid.Balance
			MaxDps:Print(MaxDps.Colors.Info .. 'Druid Balance', "info")
		elseif MaxDps.Spec == 2 then
			MaxDps.NextSpell = Druid.Feral
			MaxDps:Print(MaxDps.Colors.Info .. 'Druid Feral', "info")
		elseif MaxDps.Spec == 3 then
			MaxDps.NextSpell = Druid.Guardian
			MaxDps:Print(MaxDps.Colors.Info .. 'Druid Guardian', "info")
		elseif MaxDps.Spec == 4 then
			MaxDps.NextSpell = Druid.Restoration
			MaxDps:Print(MaxDps.Colors.Info .. 'Druid Restoration', "info")
		end

		return true
	end

end