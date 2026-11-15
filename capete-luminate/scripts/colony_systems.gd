class_name ColonySystems
extends RefCounted

const DAISY := "D.A.I.S.Y"
const CREW := "MC"

const RADIATION_POWER := {
	"channels": ["shelter", "lab", "greenhouse", "comms"],
	"needs": {"shelter": 40, "lab": 20, "greenhouse": 15, "comms": 10},
	"budget": 85.0,
}


static func begin_day(day_number: int) -> void:
	GameState.greenhouse_fed_today = false
	GameState.colony_day_settled = 0
	GameState.hours_left = GameState.MAX_HOURS
	if day_number == 3:
		GameState.solar_efficiency = 1.0
		GameState.total_oxygen_lost = maxi(
			GameState.total_oxygen_lost, 100 - GameState.oxygen)
	if day_number == 5:
		await Dialogue.talk(_lines([
			[DAISY, "Water, power, food and air are linked. One weak system can affect the whole colony."],
			[DAISY, "This is the final systems check for the colony."],
		]))


static func choose_action(options: Array, costs: Array) -> int:
	var available := []
	var option_indices := []
	for i in options.size():
		if int(costs[i]) <= GameState.hours_left:
			available.append("%s (%dh)" % [str(options[i]), int(costs[i])])
			option_indices.append(i)
	if available.is_empty():
		return -1
	var selected := await Dialogue.choose(available)
	var chosen := int(option_indices[selected])
	GameState.hours_left -= int(costs[chosen])
	return chosen


static func consume_hours(amount: int) -> bool:
	if amount > GameState.hours_left:
		return false
	GameState.hours_left -= amount
	return true


static func play_minigame(owner: Node, kind: String, context: Dictionary = {}) -> Array:
	var game := ColonyMinigame.new()
	owner.add_child(game)
	game.start(kind, context)
	var result: Array = await game.finished
	game.queue_free()
	return result


static func handle_dust_storm(owner: Node, cleaned: bool) -> void:
	if not cleaned:
		GameState.solar_efficiency = 0.4
		GameState.panels_dirty = true
		await Dialogue.talk(_lines([
			[DAISY, "Dust is settling on the panels. Solar output will stay very low for the rest of the day."],
		]))
		return

	var result := await play_minigame(owner, "scrub")
	var score := float(result[0])
	if score >= 0.85:
		GameState.solar_efficiency = 1.15
		GameState.panels_dirty = false
		GameState.change_resource("energy", 10)
		await Dialogue.talk(_lines([
			[DAISY, "Solar efficiency is back to 96%. That should cover the greenhouse cycle tonight."],
		]))
	elif score >= 0.5:
		GameState.solar_efficiency = 0.8
		GameState.panels_dirty = false
		await Dialogue.talk(_lines([
			[DAISY, "Most of the panels are clear. A little dust will still reduce tonight's output."],
		]))
	else:
		GameState.solar_efficiency = 0.6
		GameState.panels_dirty = true
		await Dialogue.talk(_lines([
			[DAISY, "Several panels remain blocked. Expected energy production is reduced by 18%."],
		]))


static func support_greenhouse(owner: Node, option: int) -> void:
	if GameState.greenhouse_heated:
		GameState.greenhouse_health = mini(100, GameState.greenhouse_health + 8)
	match option:
		0:
			GameState.change_resource("energy", -8)
			GameState.greenhouse_health = mini(100, GameState.greenhouse_health + 8)
			GameState.greenhouse_fed_today = true
			var power_result := await play_minigame(owner, "greenhouse_controls")
			_resolve_greenhouse_controls(float(power_result[0]))
			await Dialogue.talk(_lines([
				[DAISY, "Extra grow-light power helped the crops, but left less energy for tonight."],
			]))
		1:
			GameState.change_resource("water", -8)
			GameState.greenhouse_health = mini(100, GameState.greenhouse_health + 8)
			GameState.greenhouse_fed_today = true
			var water_result := await play_minigame(owner, "greenhouse_controls")
			_resolve_greenhouse_controls(float(water_result[0]))
			await Dialogue.talk(_lines([
				[DAISY, "Greenhouse moisture is restored. Water reserves are lower, but crop growth should recover."],
			]))
		_:
			GameState.greenhouse_health = maxi(0, GameState.greenhouse_health - 12)
			GameState.greenhouse_fed_today = false
			await Dialogue.talk(_lines([
				[DAISY, "The greenhouse is running without extra support. The plants will produce less food."],
			]))


static func investigate_ice(owner: Node, investigate: bool) -> void:
	if not investigate:
		return
	GameState.change_resource("energy", -12)
	var result := await play_minigame(owner, "hold_zone", {"duration": 15.0})
	var score := float(result[0])
	if score >= 0.85:
		GameState.research_score += 5
		GameState.ice_samples = true
		GameState.water_efficiency = mini(100, GameState.water_efficiency + 5)
		await Dialogue.talk(_lines([
			[DAISY, "The sample contains water ice. It adds research data and will help recalibrate the purifier."],
		]))
	elif score >= 0.5:
		GameState.research_score += 2
		await Dialogue.talk(_lines([
			[DAISY, "We recovered a partial sample. Research data saved, but the drill needs maintenance."],
		]))
	else:
		GameState.change_resource("energy", -5)
		GameState.drill_repaired = false
		await Dialogue.talk(_lines([
			[DAISY, "The sample was contaminated and the drill was damaged. We lost extra power."],
		]))


static func handle_leak(owner: Node, choice: int) -> void:
	if choice == 2:
		GameState.leak_active = true
		await Dialogue.talk(_lines([
			[DAISY, "The leak is still active. It will keep venting oxygen through the day."],
		]))
		return

	var score := 0.0
	if choice == 0:
		var quick_result := await play_minigame(owner, "hold_zone", {"duration": 12.0})
		score = float(quick_result[0])
	else:
		var valve_result := await play_minigame(owner, "valves")
		var weld_result := await play_minigame(owner, "hold_zone", {"duration": 15.0})
		score = (float(valve_result[0]) + float(weld_result[0])) / 2.0

	if score >= 0.5:
		GameState.leak_repaired = true
		GameState.leak_active = false
		if choice == 1:
			GameState.flags["infrastructure_saved"] = true
			await Dialogue.talk(_lines([
				[DAISY, "The exact cause is fixed. The corridor seals are reinforced."],
			]))
		else:
			await Dialogue.talk(_lines([
				[DAISY, "The quick patch is holding for now."],
			]))
	else:
		GameState.leak_active = true
		GameState.change_resource("oxygen", -5)
		await Dialogue.talk(_lines([
			[DAISY, "The repair did not hold. Oxygen will continue to escape until the leak is sealed."],
		]))


static func record_crew_log(found: bool) -> void:
	if found:
		GameState.antenna_hint = true
		GameState.research_score += 5


static func handle_radiation(owner: Node, choice: int) -> void:
	if choice == 0:
		GameState.change_resource("radiation_exposure", -3)
		return
	if choice == 1:
		GameState.radiation_exposure += 5
		if not GameState.flags.get("infrastructure_saved", false):
			GameState.solar_efficiency = minf(GameState.solar_efficiency, 0.8)
		await Dialogue.talk(_lines([
			[DAISY, "You made progress, but the radiation exposure was not harmless."],
		]))
		return

	var result := await play_minigame(owner, "power", RADIATION_POWER)
	var allocation: Dictionary = result[1]
	var shelter := float(allocation.get("shelter", 0.0))
	var lab := float(allocation.get("lab", 0.0))
	var greenhouse := float(allocation.get("greenhouse", 0.0))
	var comms := float(allocation.get("comms", 0.0))
	var total := shelter + lab + greenhouse + comms
	GameState.change_resource("energy", -int(round(total * 0.25)))
	GameState.radiation_exposure += int(round(clampf(30.0 - shelter * 0.4, 3.0, 30.0)))
	if lab >= 20.0:
		GameState.research_score += 5
	if greenhouse >= 15.0:
		GameState.greenhouse_health = mini(100, GameState.greenhouse_health + 5)
	await Dialogue.talk(_lines([
		[DAISY, "Power allocated: shelter %d, lab %d, greenhouse %d, communications %d." % [
			int(shelter), int(lab), int(greenhouse), int(comms)]],
		[DAISY, "Radiation shielding was reinforced where the power allocation allowed."],
	]))


static func repair_day_four_water(owner: Node, choice: int) -> void:
	if choice == 0:
		var result := await play_minigame(owner, "valves")
		var gain := int(round(8.0 + float(result[0]) * 20.0))
		GameState.water_efficiency = mini(100, GameState.water_efficiency + gain)
		if float(result[0]) < 0.5:
			GameState.water_efficiency = maxi(50, GameState.water_efficiency - 5)
			GameState.water_fixed = false
		else:
			GameState.water_fixed = true
		await Dialogue.talk(_lines([
			[DAISY, "The water extraction filters are now running at %d%% efficiency." % GameState.water_efficiency],
		]))
	else:
		GameState.water_efficiency = maxi(45, GameState.water_efficiency - 8)
		await Dialogue.talk(_lines([
			[DAISY, "Rationing preserves power today, but weak filters reduce water and oxygen production."],
		]))


static func handle_day_four_power(owner: Node) -> void:
	if not consume_hours(1):
		await Dialogue.talk(_lines([
			[DAISY, "There is no work time left for a power reallocation. The current system settings remain in place."],
		]))
		return
	var context := {
		"channels": ["life_support", "greenhouse", "lab", "comms"],
		"needs": {"life_support": 30, "greenhouse": 15, "lab": 15, "comms": 10},
		"budget": clampf(float(GameState.energy) * 0.55, 25.0, 65.0),
	}
	var result := await play_minigame(owner, "power", context)
	var allocation: Dictionary = result[1]
	var life_support := float(allocation.get("life_support", 0.0))
	var greenhouse := float(allocation.get("greenhouse", 0.0))
	var lab := float(allocation.get("lab", 0.0))
	var total := 0.0
	for amount in allocation.values():
		total += float(amount)
	GameState.change_resource("energy", -int(round(total * 0.2)))
	if life_support < 30.0:
		GameState.change_resource("oxygen", -int(round((30.0 - life_support) * 0.4)))
	if greenhouse >= 15.0 and GameState.greenhouse_on:
		GameState.greenhouse_fed_today = true
	else:
		GameState.greenhouse_health = maxi(0, GameState.greenhouse_health - 8)
	if lab >= 15.0:
		GameState.research_score += 3
	await Dialogue.talk(_lines([
		[DAISY, "Night power set: life support %d, greenhouse %d, lab %d, communications %d." % [
			int(life_support), int(greenhouse), int(lab), int(allocation.get("comms", 0.0))]],
		[DAISY, "Power sent to one system was unavailable to the others."],
	]))


static func run_day_five_events(owner: Node) -> void:
	await _repair_purifier(owner)
	await _repair_greenhouse(owner)
	await _martian_night(owner)


static func _repair_purifier(owner: Node) -> void:
	GameState.water_efficiency = mini(GameState.water_efficiency, 62)
	await Dialogue.talk(_lines([
		[DAISY, "Water recycling efficiency has fallen to %d%%." % GameState.water_efficiency],
		[CREW, "Can anything in this base survive one day without breaking?"],
		[DAISY, "Statistically, no."],
		[DAISY, "Water supports the MOXIE, the greenhouse and the crew. This affects the whole colony."],
	]))
	var choice := await choose_action([
		"Full purifier repair (2 hours, uses power)",
		"Quick filter fix (1 hour)",
		"Postpone and keep the remaining supplies",
	], [2, 1, 0])
	if choice == 2:
		GameState.water_efficiency = maxi(45, GameState.water_efficiency - 8)
		GameState.water_fixed = false
		await Dialogue.talk(_lines([
			[DAISY, "The clogged filters remain. Water, crop growth and oxygen production will all fall."],
		]))
		return

	if choice == 0:
		GameState.change_resource("energy", -6)
	var result := await play_minigame(owner, "valves")
	var score := float(result[0])
	var gain := 30 if choice == 0 else 18
	if score < 0.5:
		gain = 8 if choice == 0 else 4
	elif score < 0.85:
		gain = 20 if choice == 0 else 12
	if GameState.ice_samples:
		gain += 8
		GameState.ice_samples = false
	GameState.water_efficiency = mini(100, GameState.water_efficiency + gain)
	GameState.water_fixed = score >= 0.5
	await Dialogue.talk(_lines([
		[DAISY, "Water production increased. Better recycling also supports oxygen generation and crop growth."],
		[DAISY, "Water recycling efficiency is now %d%%." % GameState.water_efficiency],
	]))


static func _repair_greenhouse(owner: Node) -> void:
	await Dialogue.talk(_lines([
		[DAISY, "Greenhouse controls are out of balance. Crop growth is slowing."],
	]))
	var choice := await choose_action([
		"Use water to restore greenhouse moisture",
		"Use extra power for grow lights",
		"Accept a lower crop yield",
	], [1, 1, 0])
	if choice == 0 or choice == 1:
		if choice == 0:
			GameState.change_resource("water", -10)
		else:
			GameState.change_resource("energy", -10)
		GameState.greenhouse_fed_today = true
		var result := await play_minigame(owner, "greenhouse_controls")
		var score := float(result[0])
		if score >= 0.85:
			GameState.greenhouse_health = mini(100, GameState.greenhouse_health + 15)
			await Dialogue.talk(_lines([
				[DAISY, "The greenhouse settings are balanced. Crop health is recovering."],
			]))
		elif score >= 0.5:
			GameState.greenhouse_health = mini(100, GameState.greenhouse_health + 6)
			await Dialogue.talk(_lines([
				[DAISY, "The crops should survive, but the yield will be lower."],
			]))
		else:
			GameState.greenhouse_health = maxi(0, GameState.greenhouse_health - 5)
			await Dialogue.talk(_lines([
				[DAISY, "The settings were off. Crop production will remain low."],
			]))
	else:
		GameState.greenhouse_health = maxi(0, GameState.greenhouse_health - 15)
		if GameState.greenhouse_neglect >= 2:
			GameState.change_resource("food", -15)
			await Dialogue.talk(_lines([
				[DAISY, "Two days of neglect cost a third of the crop."],
			]))
		else:
			await Dialogue.talk(_lines([
				[DAISY, "The lower yield will leave less food for the crew."],
			]))


static func _martian_night(owner: Node) -> void:
	await Dialogue.talk(_lines([
		[DAISY, "The batteries are nearly empty. Available power is insufficient."],
		[CREW, "For what?"],
		[DAISY, "Everything."],
	]))
	var context := {
		"channels": ["life_support", "greenhouse", "lab", "comms"],
		"needs": {"life_support": 35, "greenhouse": 20, "lab": 20, "comms": 25},
		"budget": clampf(float(GameState.energy) + 10.0, 25.0, 70.0),
	}
	if not consume_hours(1):
		GameState.antenna_charged = false
		await Dialogue.talk(_lines([
			[DAISY, "The crew has no work time left to reallocate night power. The current settings remain in place."],
		]))
		return
	var result := await play_minigame(owner, "power", context)
	var allocation: Dictionary = result[1]
	var life_support := float(allocation.get("life_support", 0.0))
	var greenhouse := float(allocation.get("greenhouse", 0.0))
	var lab := float(allocation.get("lab", 0.0))
	var comms := float(allocation.get("comms", 0.0))
	var total := life_support + greenhouse + lab + comms
	GameState.change_resource("energy", -int(round(total * 0.25)))
	if life_support < 35.0:
		var shortage := 1.0 - life_support / 35.0
		GameState.change_resource("oxygen", -int(round(20.0 * shortage)))
		GameState.health = maxi(0, GameState.health - int(round(15.0 * shortage)))
	if greenhouse < 20.0:
		GameState.greenhouse_health = maxi(0, GameState.greenhouse_health - 15)
	else:
		GameState.greenhouse_fed_today = true
	if lab >= 20.0:
		GameState.research_score += 5
	GameState.antenna_charged = comms >= 25.0

	await Dialogue.talk(_lines([
		[DAISY, "Night allocation set. Life support %d, greenhouse %d, lab %d, communications %d." % [
			int(life_support), int(greenhouse), int(lab), int(comms)]],
	]))
	if GameState.antenna_charged:
		var confirm := await choose_action([
			"Send the confirmation to Earth",
			"Go to sleep",
		], [1, 0])
		if confirm == 0:
			GameState.confirmation_sent = true
			GameState.sent_signal = true
			await Dialogue.talk(_lines([
				[CREW, "Message sent."],
				[DAISY, "Transmission acknowledged. Earth will answer in about twenty minutes. Light takes its time."],
			]))
		else:
			await Dialogue.talk(_lines([
				[DAISY, "Good night."],
			]))


static func end_day(_owner: Node, day_number: int) -> void:
	if GameState.colony_day_settled == day_number:
		return
	GameState.colony_day_settled = day_number

	var before := {
		"energy": GameState.energy,
		"oxygen": GameState.oxygen,
		"water": GameState.water,
		"food": GameState.food,
	}
	var solar_change := int(round(12.0 * GameState.solar_efficiency)) - (20 if day_number == 5 else 12)
	GameState.change_resource("energy", solar_change)

	if GameState.leak_active:
		var leak_loss := 12 + int(GameState.total_oxygen_lost * 0.1)
		GameState.change_resource("oxygen", -leak_loss)
		GameState.total_oxygen_lost += leak_loss

	var oxygen_output := int(round(GameState.water_efficiency * 0.1))
	if GameState.energy < 20:
		oxygen_output = int(round(oxygen_output * 0.5))
	if GameState.moxie_broken:
		oxygen_output = 0
	var oxygen_change := oxygen_output - 10
	if GameState.water < 20:
		oxygen_change -= 3
	GameState.change_resource("oxygen", oxygen_change)

	var water_change := int(round(GameState.water_efficiency * 0.08)) - 8
	GameState.change_resource("water", water_change)

	if GameState.greenhouse_fed_today:
		GameState.greenhouse_neglect = 0
		GameState.greenhouse_health = mini(100, GameState.greenhouse_health + 2)
	else:
		GameState.greenhouse_neglect += 1
		GameState.greenhouse_health = maxi(
			0, GameState.greenhouse_health - 6 * GameState.greenhouse_neglect)
	if GameState.energy < 15:
		GameState.greenhouse_health = maxi(0, GameState.greenhouse_health - 5)
	var harvest := int(round(GameState.greenhouse_health * 0.1))
	if GameState.water < 20:
		harvest = int(round(harvest * 0.5))
	GameState.change_resource("food", harvest - 8)
	if GameState.greenhouse_neglect >= 2 and GameState.day != 5:
		GameState.change_resource("food", -5)

	if GameState.oxygen < 25:
		GameState.health = maxi(0, GameState.health - 10)
	if GameState.food < 15:
		GameState.health = maxi(0, GameState.health - 8)
	GameState.health = maxi(0, GameState.health - int(round(GameState.radiation_exposure * 0.08)))
	if GameState.oxygen > 50 and GameState.food > 30:
		GameState.health = mini(100, GameState.health + 3)
	GameState.radiation_exposure = maxi(0, GameState.radiation_exposure - 5)

	var lines := [
		[DAISY, "Solar output changed energy by %d%%. Clean panels preserve more power for life support." % (
			GameState.energy - before["energy"])],
		[DAISY, "At %d%% recycling efficiency, water changed by %d%% and oxygen by %d%%. Water supports MOXIE production." % [
			GameState.water_efficiency, GameState.water - before["water"], GameState.oxygen - before["oxygen"]]],
		[DAISY, "Greenhouse health is %d%%. The plants changed food reserves by %d%%." % [
			GameState.greenhouse_health, GameState.food - before["food"]]],
		[DAISY, "Status tonight: Energy %d%%, Oxygen %d%%, Water %d%%, Food %d%%." % [
			GameState.energy, GameState.oxygen, GameState.water, GameState.food]],
		[DAISY, _health_comment()],
	]
	await Dialogue.talk(_lines(lines))


static func _resolve_greenhouse_controls(score: float) -> void:
	if score >= 0.85:
		GameState.greenhouse_health = mini(100, GameState.greenhouse_health + 8)
	elif score >= 0.5:
		GameState.greenhouse_health = mini(100, GameState.greenhouse_health + 3)
	else:
		GameState.greenhouse_health = maxi(0, GameState.greenhouse_health - 5)


static func _health_comment() -> String:
	if GameState.health < 35:
		return "You look pale. Please rest."
	if GameState.health < 65 or GameState.radiation_exposure > 50:
		return "You look tired."
	return "Radiation exposure remains acceptable."


static func _lines(texts: Array) -> Array:
	var lines := []
	for line in texts:
		lines.append({"who": line[0], "text": str(line[1])})
	return lines
