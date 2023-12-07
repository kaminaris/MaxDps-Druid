local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then
	return
end

local MaxDps = MaxDps;
local UnitPower = UnitPower;
local GetSpellCount = GetSpellCount;
local LunarPower = Enum.PowerType.LunarPower;
local GetHaste = GetHaste;
local Druid = addonTable.Druid;

local BL = {
	MoonkinForm                = 24858,
	Wrath                      = 190984, -- ok
	Starfire                   = 194153, -- ok
	NaturesBalance             = 202430,
	Starsurge                  = 78674,  -- ok
	Starlord                   = 202345, -- ok
	StellarDrift               = 202354, -- ok
	Incarnation                = 102560, -- ok
	Starfall                   = 191034, -- ok
	EmpowerBond                = 338142,
	FuryOfElune                = 202770,
	Sunfire                    = 93402,
	SunfireAura                = 164815,
	Moonfire                   = 8921,
	MoonfireAura               = 164812,
	TwinMoons                  = 279620,
	SoulOfTheForest            = 114107,
	ForceOfNature              = 205636,
	CelestialAlignment         = 194223,
	StellarFlare               = 202347,
	NewMoon                    = 274281,
	HalfMoon                   = 274282,
	FullMoon                   = 274283,
	WarriorOfElune             = 202425,

	EclipseLunar               = 48518,
	EclipseSolar               = 48517,
};

setmetatable(BL, Druid.spellMeta);

function Druid:Balance()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local talents = fd.talents;
	local targets = MaxDps:SmartAoe();
	local currentSpell = fd.currentSpell;
	local buff = fd.buff;
	local lunarPower = UnitPower('player', LunarPower);

	local wrathCount = GetSpellCount(BL.Wrath);
	local starfireCount = GetSpellCount(BL.Starfire);
	local origWrathCount = wrathCount;
	local origStarfireCount = starfireCount;

	local castingMoonSpell = false;
	if currentSpell == BL.Wrath then
		lunarPower = lunarPower + 6;
		wrathCount = wrathCount - 1;
	elseif currentSpell == BL.Starfire then
		lunarPower = lunarPower + 8;
		starfireCount = starfireCount - 1;
	elseif currentSpell == BL.FuryOfElune then
		lunarPower = lunarPower + 40;
	elseif currentSpell == BL.ForceOfNature then
		lunarPower = lunarPower + 20;
	elseif currentSpell == BL.StellarFlare then
		lunarPower = lunarPower + 8;
	elseif currentSpell == BL.NewMoon then
		lunarPower = lunarPower + 10;
		castingMoonSpell = true;
	elseif currentSpell == BL.HalfMoon then
		lunarPower = lunarPower + 20;
		castingMoonSpell = true;
	elseif currentSpell == BL.FullMoon then
		lunarPower = lunarPower + 40;
		castingMoonSpell = true;
	end

	local MoonPhase = MaxDps:FindSpell(BL.NewMoon) and BL.NewMoon or
		(MaxDps:FindSpell(BL.HalfMoon) and BL.HalfMoon or BL.FullMoon);
	local CaInc = talents[BL.Incarnation] and BL.Incarnation or BL.CelestialAlignment;

	-- variable,name=is_aoe,value=spell_targets.starfall>1&(!talent.starlord.enabled|talent.stellar_drift.enabled)|spell_targets.starfall>2;
	local isAoe = targets > 1 and (not talents[BL.Starlord] or talents[BL.StellarDrift]) or targets > 2;

	-- variable,name=is_cleave,value=spell_targets.starfire>1;
	local isCleave = targets > 1;

	-- variable,name=convoke_desync,value=floor((interpolated_fight_remains-20-cooldown.convoke_the_spirits.remains)%120)>floor((interpolated_fight_remains-25-(10*talent.incarnation.enabled)-(conduit.precise_alignment.time_value)-cooldown.ca_inc.remains)%180)|cooldown.ca_inc.remains>interpolated_fight_remains|cooldown.convoke_the_spirits.remains>interpolated_fight_remains|!covenant.night_fae;
	fd.eclipseInLunar = buff[BL.EclipseLunar].up or (origStarfireCount == 1 and currentSpell == BL.Starfire);
	fd.eclipseInSolar = buff[BL.EclipseSolar].up or (origWrathCount == 1 and currentSpell == BL.Wrath);
	fd.eclipseInAny = fd.eclipseInSolar or fd.eclipseInLunar;
	fd.eclipseInBoth = fd.eclipseInSolar and fd.eclipseInLunar;

	fd.eclipseSolarNext = wrathCount > 0 and starfireCount <= 0;
	fd.eclipseLunarNext = wrathCount <= 0 and starfireCount > 0;
	fd.eclipseAnyNext = wrathCount > 0 and starfireCount > 0;

	fd.lunarPower = lunarPower;
	fd.wrathCount = wrathCount;
	fd.starfireCount = starfireCount;
	fd.CaInc = CaInc;
	fd.targets = targets;
	fd.isAoe = isAoe;
	fd.isCleave = isCleave;
	fd.castingMoonSpell = castingMoonSpell;
	fd.MoonPhase = MoonPhase;

	MaxDps:GlowCooldown(CaInc, cooldown[CaInc].ready);
	if talents[BL.ForceOfNature] then
		MaxDps:GlowCooldown(BL.ForceOfNature, cooldown[BL.ForceOfNature].ready);
	end

	-- run_action_list,name=aoe,if=variable.is_aoe;
	if isAoe then
		return Druid:BalanceAoe();
	end

	-- run_action_list,name=st;
	return Druid:BalanceSt();
end

function Druid:BalanceAoe()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local targets = fd.targets;
	local gcd = fd.gcd;
	local spellHaste = GetHaste();
	local lunarPower = fd.lunarPower;
	local CaInc = fd.CaInc;
	local isCleave = fd.isCleave;
	local eclipseInAny = fd.eclipseInAny;
	local eclipseInLunar = fd.eclipseInLunar;
	local eclipseInSolar = fd.eclipseInSolar;
	local eclipseInBoth = fd.eclipseInBoth;
	local eclipseSolarNext = fd.eclipseSolarNext;
	local eclipseLunarNext = fd.eclipseLunarNext;
	local eclipseAnyNext = fd.eclipseAnyNext;
	local castingMoonSpell = fd.castingMoonSpell;
	local MoonPhase = fd.MoonPhase;

	local canStarfall = lunarPower >= 50;
	local canStarsurge = lunarPower >= 30;

	-- starfall,if=buff.starfall.refreshable&(spell_targets.starfall<3|!runeforge.timeworn_dreambinder.equipped)&(!runeforge.lycaras_fleeting_glimpse.equipped|time%%45>buff.starfall.remains+2);
	if canStarfall and
		buff[BL.Starfall].refreshable and
		(targets < 3 )
	then
		return BL.Starfall;
	end

	-- starfall,if=runeforge.timeworn_dreambinder.equipped&spell_targets.starfall>=3&(!buff.timeworn_dreambinder.up&buff.starfall.refreshable|(variable.dream_will_fall_off&(buff.starfall.remains<3|spell_targets.starfall>2&talent.stellar_drift.enabled&buff.starfall.remains<5)));
	if canStarfall and
		targets >= 3 and
		(
			not  buff[BL.Starfall].refreshable
		)
	then
		return BL.Starfall;
	end

	local furyOfEluneRemains = talents[BL.FuryOfElune] and cooldown[BL.FuryOfElune].remains - 52 or 0;
	if furyOfEluneRemains < 0 then furyOfEluneRemains = 0 end

	-- variable,name=starfall_wont_fall_off,value=astral_power>80-(10*buff.timeworn_dreambinder.stack)-(buff.starfall.remains*3%spell_haste)-(dot.fury_of_elune.remains*5)&buff.starfall.up;
	local starfallWontFallOff = lunarPower >
		80 -
			(buff[BL.Starfall].remains * 3 / spellHaste) -
			(furyOfEluneRemains * 5)
		and buff[BL.Starfall].up;

	-- sunfire,target_if=refreshable&target.time_to_die>14-spell_targets+remains,if=ap_check&eclipse.in_any;
	if debuff[BL.SunfireAura].refreshable and eclipseInAny then
		return BL.Sunfire;
	end

	-- stellar_flare,target_if=refreshable&time_to_die>15,if=spell_targets.starfire<4&ap_check&(buff.ca_inc.remains>10|!buff.ca_inc.up);
	if talents[BL.StellarFlare] and
		debuff[BL.StellarFlare].refreshable and
		currentSpell ~= BL.StellarFlare and
		targets < 4 and
		(buff[CaInc].remains > 10 or not buff[CaInc].up)
	then
		return BL.StellarFlare;
	end

	-- fury_of_elune,if=eclipse.in_any&ap_check&buff.primordial_arcanic_pulsar.value<250&(dot.adaptive_swarm_damage.ticking|!covenant.necrolord|spell_targets>2);
	if talents[BL.FuryOfElune] and
		cooldown[BL.FuryOfElune].ready and
		eclipseInAny
	then
		return BL.FuryOfElune;
	end

	-- starfall,if=buff.oneths_perception.up&(buff.starfall.refreshable|astral_power>90);
	if canStarfall and (buff[BL.Starfall].refreshable or lunarPower > 90) then
		return BL.Starfall;
	end

	-- starfall,if=covenant.night_fae&(variable.convoke_desync|cooldown.ca_inc.up|buff.ca_inc.up)&cooldown.convoke_the_spirits.remains<gcd.max*ceil(astral_power%50)&buff.starfall.remains<4;
	if canStarfall and
		( cooldown[CaInc].up or buff[CaInc].up) and
		buff[BL.Starfall].remains < 4
	then
		return BL.Starfall;
	end

	-- starsurge,if=covenant.night_fae&(variable.convoke_desync|cooldown.ca_inc.up|buff.ca_inc.up)&cooldown.convoke_the_spirits.remains<6&buff.starfall.up&eclipse.in_any;
	if canStarsurge and
		(buff[CaInc].up) and
		cooldown[BL.ConvokeTheSpirits].remains < 6 and
		buff[BL.Starfall].up and
		eclipseInAny
	then
		return BL.Starsurge;
	end

	-- starsurge,if=buff.oneths_clear_vision.up|(!starfire.ap_check|(buff.ca_inc.remains<5&buff.ca_inc.up|(buff.ravenous_frenzy.remains<gcd.max*ceil(astral_power%30)&buff.ravenous_frenzy.up))&variable.starfall_wont_fall_off&spell_targets.starfall<3)&(!runeforge.timeworn_dreambinder.equipped|spell_targets.starfall<3);
	if canStarsurge and
		(
			(
				buff[CaInc].remains < 5 and buff[CaInc].up or
				(buff[BL.RavenousFrenzy].remains < gcd * math.ceil(lunarPower / 30) and buff[BL.RavenousFrenzy].up)
			) and
				starfallWontFallOff and targets < 3
		) and (not targets < 3)
	then
		return BL.Starsurge;
	end

	-- new_moon,if=(eclipse.in_any&cooldown.ca_inc.remains>50|(charges=2&recharge_time<5)|charges=3)&ap_check;
	-- half_moon,if=(eclipse.in_any&cooldown.ca_inc.remains>50|(charges=2&recharge_time<5)|charges=3)&ap_check;
	-- full_moon,if=(eclipse.in_any&cooldown.ca_inc.remains>50|(charges=2&recharge_time<5)|charges=3)&ap_check;
	if talents[BL.NewMoon] then
		local newMoonCharges = cooldown[BL.NewMoon].charges;
		if castingMoonSpell then newMoonCharges = newMoonCharges - 1; end

		if newMoonCharges >= 1 and eclipseInAny or
			(newMoonCharges >= 2 and cooldown[BL.NewMoon].partialRecharge < 5) or
			newMoonCharges >= 3
		then
			return MoonPhase;
		end
	end

	-- warrior_of_elune;
	if talents[BL.WarriorOfElune] and cooldown[BL.WarriorOfElune].ready then
		return BL.WarriorOfElune;
	end

	local masteryValue = GetMasteryEffect();
	-- variable,name=starfire_in_solar,value=spell_targets.starfire>4+floor(mastery_value%20)+floor(buff.starsurge_empowerment_solar.stack%4);
	local starfireInSolar = targets >
		4
			+ math.floor(masteryValue / 20)
			--+ math.floor(buff[BL.StarsurgeEmpowermentSolar].count / 4)
	;

	-- wrath,if=eclipse.lunar_next|eclipse.any_next&variable.is_cleave|buff.eclipse_solar.remains<action.starfire.execute_time&buff.eclipse_solar.up|eclipse.in_solar&!variable.starfire_in_solar|buff.ca_inc.remains<action.starfire.execute_time&!variable.is_cleave&buff.ca_inc.remains<execute_time&buff.ca_inc.up|buff.ravenous_frenzy.up&spell_haste>0.6&(spell_targets<=3|!talent.soul_of_the_forest.enabled)|!variable.is_cleave&buff.ca_inc.remains>execute_time;
	if ( -- currentSpell ~= BL.Wrath and
		--eclipseLunarNext or
			eclipseInSolar or
			eclipseSolarNext or
			eclipseAnyNext and isCleave or
			buff[BL.EclipseSolar].remains < 2 and buff[BL.EclipseSolar].up or
			--eclipseInSolar and not starfireInSolar or
			--buff[CaInc].remains < 2 and not isCleave and buff[CaInc].remains < 2 and buff[CaInc].up or
			buff[BL.RavenousFrenzy].up and spellHaste > 0.6 and (targets <= 3 or not talents[BL.SoulOfTheForest]) --or
			--not isCleave and buff[CaInc].remains > 2
	) then
		return BL.Wrath;
	end

	-- starfire;
	return BL.Starfire;
	--if currentSpell ~= BL.Starfire then
	--	return BL.Starfire;
	--end
	--
	---- run_action_list,name=fallthru;
	--return Druid:BalanceFallthru();
end

function Druid:BalanceBoat()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local gcd = fd.gcd;
	local spellHaste = GetHaste();
	local covenantId = fd.covenant.covenantId;
	local lunarPower = fd.lunarPower;
	local CaInc = fd.CaInc;
	local isAoe = fd.isAoe;
	local castingMoonSpell = fd.castingMoonSpell;
	local MoonPhase = fd.MoonPhase;

	local eclipseInAny = fd.eclipseInAny;
	local eclipseInLunar = fd.eclipseInLunar;
	local eclipseLunarNext = fd.eclipseLunarNext;
	local eclipseSolarNext = fd.eclipseSolarNext;
	local eclipseAnyNext = fd.eclipseAnyNext;
	local convokeDesync = fd.convokeDesync;
	local starfireCount = fd.starfireCount;

	-- ravenous_frenzy,if=buff.ca_inc.up;
	--if buff[CaInc].up then
	--	return BL.RavenousFrenzy;
	--end

	local canStarfall = lunarPower >= 50;
	local canStarsurge = lunarPower >= 30 ;

	-- starsurge,if=(cooldown.convoke_the_spirits.remains<5&(variable.convoke_desync|cooldown.ca_inc.remains<5))&astral_power>40&covenant.night_fae;
	if canStarsurge and
		(cooldown[CaInc].remains < 5)
	then
		return BL.Starsurge;
	end

	-- sunfire,target_if=refreshable&target.time_to_die>16,if=ap_check&(variable.critnotup|(astral_power<30&!buff.ca_inc.up)|cooldown.ca_inc.ready);
	if debuff[BL.SunfireAura].refreshable and
		((lunarPower < 30 and not buff[CaInc].up) or cooldown[CaInc].ready)
	then
		return BL.Sunfire;
	end

	-- moonfire,target_if=refreshable&target.time_to_die>13.5,if=ap_check&(variable.critnotup|(astral_power<30&!buff.ca_inc.up)|cooldown.ca_inc.ready)&!buff.kindred_empowerment_energize.up;
	if debuff[BL.MoonfireAura].refreshable and
		((lunarPower < 30 and not buff[CaInc].up) or cooldown[CaInc].ready)
	then
		return BL.Moonfire;
	end

	-- stellar_flare,target_if=refreshable&target.time_to_die>16+remains,if=ap_check&(variable.critnotup|astral_power<30|cooldown.ca_inc.ready);
	if talents[BL.StellarFlare] and
		debuff[BL.StellarFlare].refreshable and
		currentSpell ~= BL.StellarFlare and
		(lunarPower < 30 or cooldown[CaInc].ready)
	then
		return BL.StellarFlare;
	end

	-- force_of_nature,if=ap_check;
	--if cooldown[BL.ForceOfNature].ready then
	--	return BL.ForceOfNature;
	--end

	-- fury_of_elune,if=(eclipse.in_any|eclipse.solar_in_1|eclipse.lunar_in_1)&(!covenant.night_fae|(astral_power<95&(variable.critnotup|astral_power<30|variable.is_aoe)&(variable.convoke_desync&!cooldown.convoke_the_spirits.up|!variable.convoke_desync&!cooldown.ca_inc.up)))&(cooldown.ca_inc.remains>30|astral_power>90&cooldown.ca_inc.up&(cooldown.empower_bond.remains<action.starfire.execute_time|!covenant.kyrian)|interpolated_fight_remains<10)&(dot.adaptive_swarm_damage.remains>4|!covenant.necrolord);
	if talents[BL.FuryOfElune] and
		cooldown[BL.FuryOfElune].ready and
		(eclipseInAny)
	then
		return BL.FuryOfElune;
	end

	-- variable,name=aspPerSec,value=eclipse.in_lunar*8%action.starfire.execute_time+!eclipse.in_lunar*6%action.wrath.execute_time+0.2%spell_haste;
	local aspPerSec = (eclipseInLunar and 1 or 0) * 8 / 2 +
		(eclipseInLunar and 0 or 1) * 6 / 1.3 +
		0.2 / spellHaste;

	-- starsurge,if=(interpolated_fight_remains<4|(buff.ravenous_frenzy.remains<gcd.max*ceil(astral_power%30)&buff.ravenous_frenzy.up))|(astral_power+variable.aspPerSec*buff.eclipse_solar.remains+dot.fury_of_elune.ticks_remain*2.5>120|astral_power+variable.aspPerSec*buff.eclipse_lunar.remains+dot.fury_of_elune.ticks_remain*2.5>120)&eclipse.in_any&((!cooldown.ca_inc.up|covenant.kyrian&!cooldown.empower_bond.up)|covenant.night_fae)&(!covenant.venthyr|!buff.ca_inc.up|astral_power>90)|buff.ca_inc.remains>8&!buff.ravenous_frenzy.up;
	if lunarPower >= 40 and (
			eclipseInAny --and
	) then
		return BL.Starsurge;
	end

	-- new_moon,if=(buff.eclipse_lunar.up|(charges=2&recharge_time<5)|charges=3)&ap_check;
	-- half_moon,if=(buff.eclipse_lunar.up|(charges=2&recharge_time<5)|charges=3)&ap_check;
	-- full_moon,if=(buff.eclipse_lunar.up|(charges=2&recharge_time<5)|charges=3)&ap_check;
	if talents[BL.NewMoon] then
		local newMoonCharges = cooldown[BL.NewMoon].charges;
		if castingMoonSpell then newMoonCharges = newMoonCharges - 1; end

		if newMoonCharges >= 1 and buff[BL.EclipseLunar].up or
			(newMoonCharges >= 2 and cooldown[BL.NewMoon].partialRecharge < 5) or
			newMoonCharges >= 3
		then
			return MoonPhase;
		end
	end

	-- warrior_of_elune;
	if talents[BL.WarriorOfElune] and cooldown[BL.WarriorOfElune].ready then
		return BL.WarriorOfElune;
	end

	-- starfire,if=eclipse.in_lunar|eclipse.solar_next|eclipse.any_next|buff.warrior_of_elune.up&buff.eclipse_lunar.up|(buff.ca_inc.remains<action.wrath.execute_time&buff.ca_inc.up);
	if --currentSpell ~= BL.Starfire and
	(
			eclipseInLunar or
			--eclipseSolarNext or
			--eclipseAnyNext or
			starfireCount > 0 or
			buff[BL.WarriorOfElune].up and buff[BL.EclipseLunar].up or
			(buff[CaInc].remains < timeShift and buff[CaInc].up)
	)
	then
		return BL.Starfire;
	end

	-- wrath;
	return BL.Wrath;
	--if currentSpell ~= BL.Wrath then
	--	return BL.Wrath;
	--end
	--
	---- run_action_list,name=fallthru;
	--return Druid:BalanceFallthru();
end

function Druid:BalanceFallthru()
	local fd = MaxDps.FrameData;
	local lunarPower = fd.lunarPower;
	local debuff = fd.debuff;

	-- starsurge,if=!runeforge.balance_of_all_things.equipped;
	if lunarPower >= 40 then
		return BL.Starsurge;
	end

	-- sunfire,target_if=dot.moonfire.remains>remains;
	if debuff[BL.SunfireAura].refreshable then
		return BL.Sunfire;
	end

	-- moonfire;
	return BL.Moonfire;
end

function Druid:BalanceSt()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local timeShift = fd.timeShift;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local lunarPower = fd.lunarPower;
	local CaInc = fd.CaInc;
	local isAoe = fd.isAoe;
	local MoonPhase = fd.MoonPhase;
	local castingMoonSpell = fd.castingMoonSpell;

	local eclipseInLunar = fd.eclipseInLunar;
	local eclipseInSolar = fd.eclipseInSolar;
	local eclipseSolarNext = fd.eclipseSolarNext;
	local eclipseAnyNext = fd.eclipseAnyNext;
	local eclipseInAny = fd.eclipseInAny;
	local starfireCount = fd.starfireCount;

	local canStarfall = lunarPower >= 50;
	local canStarsurge = lunarPower >= 30;

	-- variable,name=dot_requirements,value=(buff.ca_inc.remains>5&(buff.ravenous_frenzy.remains>5|!buff.ravenous_frenzy.up)|!buff.ca_inc.up|astral_power<30)&(!buff.kindred_empowerment_energize.up|astral_power<30)&(buff.eclipse_solar.remains>gcd.max|buff.eclipse_lunar.remains>gcd.max);
	local dotRequirements =
		(buff[BL.EclipseSolar].remains > 2 or buff[BL.EclipseLunar].remains > 2)
	;

	-- moonfire,target_if=refreshable&target.time_to_die>12,if=ap_check&variable.dot_requirements;
	if debuff[BL.MoonfireAura].refreshable and dotRequirements then
		return BL.Moonfire;
	end

	-- sunfire,target_if=refreshable&target.time_to_die>12,if=ap_check&variable.dot_requirements;
	if debuff[BL.SunfireAura].refreshable and dotRequirements then
		return BL.Sunfire;
	end

	-- stellar_flare,target_if=refreshable&target.time_to_die>16,if=ap_check&variable.dot_requirements;
	if talents[BL.StellarFlare] and
		debuff[BL.StellarFlare].refreshable and
		currentSpell ~= BL.StellarFlare and
		dotRequirements
	then
		return BL.StellarFlare;
	end

	-- variable,name=save_for_ca_inc,value=(!cooldown.ca_inc.ready|!variable.convoke_desync&covenant.night_fae);
	local saveForCaInc = (not cooldown[CaInc].ready);

	-- fury_of_elune,if=eclipse.in_any&ap_check&buff.primordial_arcanic_pulsar.value<240&(dot.adaptive_swarm_damage.ticking|!covenant.necrolord)&variable.save_for_ca_inc;
	if talents[BL.FuryOfElune] and cooldown[BL.FuryOfElune].ready and
		eclipseInAny
	then
		return BL.FuryOfElune;
	end

	-- starfall,if=buff.oneths_perception.up&buff.starfall.refreshable;
	if  buff[BL.Starfall].refreshable then
		return BL.Starfall;
	end

	-- cancel_buff,name=starlord,if=buff.starlord.remains<5&(buff.eclipse_solar.remains>5|buff.eclipse_lunar.remains>5)&astral_power>90;
	--if buff[BL.Starlord].remains < 5 and (buff[BL.EclipseSolar].remains > 5 or buff[BL.EclipseLunar].remains > 5) and lunarPower > 90 then
	--	return starlord;
	--end

	-- starsurge,if=covenant.night_fae&variable.convoke_desync&cooldown.convoke_the_spirits.remains<5;
	if canStarsurge
	then
		return BL.Starsurge;
	end

	-- starfall,if=talent.stellar_drift.enabled&!talent.starlord.enabled&buff.starfall.refreshable&(buff.eclipse_lunar.remains>6&eclipse.in_lunar&buff.primordial_arcanic_pulsar.value<250|buff.primordial_arcanic_pulsar.value>=250&astral_power>90|dot.adaptive_swarm_damage.remains>8|action.adaptive_swarm_damage.in_flight)&!cooldown.ca_inc.ready;
	if canStarfall and (
		talents[BL.StellarDrift] and
		not talents[BL.Starlord] and
		buff[BL.Starfall].refreshable and
		(
			buff[BL.EclipseLunar].remains > 6 and eclipseInLunar < 250 or
		    lunarPower > 90
		)
	) then
		return BL.Starfall;
	end

	-- starsurge,if=talent.starlord.enabled&(buff.starlord.up|astral_power>90)&buff.starlord.stack<3&(buff.eclipse_solar.up|buff.eclipse_lunar.up)&buff.primordial_arcanic_pulsar.value<270&(cooldown.ca_inc.remains>10|!variable.convoke_desync&covenant.night_fae);
	if canStarsurge and
		talents[BL.Starlord] and
		(buff[BL.Starlord].up or lunarPower > 80) and
		buff[BL.Starlord].count < 3 and
		(buff[BL.EclipseSolar].up or buff[BL.EclipseLunar].up) and
		(cooldown[CaInc].remains > 10 )
	then
		return BL.Starsurge;
	end

	-- starsurge,if=(buff.primordial_arcanic_pulsar.value<270|buff.primordial_arcanic_pulsar.value<250&talent.stellar_drift.enabled)&buff.eclipse_solar.remains>7&eclipse.in_solar&!buff.oneths_perception.up&!talent.starlord.enabled&cooldown.ca_inc.remains>7&(cooldown.kindred_spirits.remains>7|!covenant.kyrian);
	if canStarsurge and
		buff[BL.EclipseSolar].remains > 7 and
		eclipseInSolar and
		not talents[BL.Starlord] --and
	then
		return BL.Starsurge;
	end

	-- new_moon,if=(buff.eclipse_lunar.up|(charges=2&recharge_time<5)|charges=3)&ap_check&variable.save_for_ca_inc;
	-- half_moon,if=(buff.eclipse_lunar.up&!covenant.kyrian|(buff.kindred_empowerment_energize.up&covenant.kyrian)|(charges=2&recharge_time<5)|charges=3|buff.ca_inc.up)&ap_check&variable.save_for_ca_inc;
	-- full_moon,if=(buff.eclipse_lunar.up&!covenant.kyrian|(buff.kindred_empowerment_energize.up&covenant.kyrian)|(charges=2&recharge_time<5)|charges=3|buff.ca_inc.up)&ap_check&variable.save_for_ca_inc;
	if talents[BL.NewMoon] then
		local newMoonCharges = cooldown[BL.NewMoon].charges;
		if castingMoonSpell then newMoonCharges = newMoonCharges - 1; end

		if newMoonCharges >= 1 and buff[BL.EclipseLunar].up or
			(newMoonCharges >= 2 and cooldown[BL.NewMoon].partialRecharge < 5) or
			newMoonCharges >= 3
		then
			return MoonPhase;
		end
	end

	-- warrior_of_elune;
	if talents[BL.WarriorOfElune] and cooldown[BL.WarriorOfElune].ready then
		return BL.WarriorOfElune;
	end

	-- starfire,if=eclipse.in_lunar|eclipse.solar_next|eclipse.any_next|buff.warrior_of_elune.up&buff.eclipse_lunar.up|(buff.ca_inc.remains<action.wrath.execute_time&buff.ca_inc.up);
	if --currentSpell ~= BL.Starfire and
		(
			eclipseInLunar or
			--eclipseSolarNext or
			--eclipseAnyNext or
			starfireCount > 0 or
			buff[BL.WarriorOfElune].up and buff[BL.EclipseLunar].up or
			(buff[CaInc].remains < timeShift and buff[CaInc].up)
		)
	then
		return BL.Starfire;
	end

	-- wrath;
	return BL.Wrath;
	--if currentSpell ~= BL.Wrath then
	--	return BL.Wrath;
	--end
	--
	---- run_action_list,name=fallthru;
	--return Druid:BalanceFallthru();
end