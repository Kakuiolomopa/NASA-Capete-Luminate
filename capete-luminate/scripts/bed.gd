extends StaticBody2D

const SPEAKER := "D.A.I.S.Y"
const PLAYER_PORTRAIT := preload("res://assets/portraits/portraitas.png")

const FIRST_LINE := "You know… I've been meaning to ask ever since we've landed…"
const OPTIONS := [
	"Sure, what's up?",
	"I can answer your questions, you can answer mine.",
	"Can we talk tomorrow…? I'm trying to sleep",
]
const GOODNIGHT_EARLY := "Right… Sorry, I'll let you sleep. Good night!"
const ASK_LINE := "Oh, do you want to ask me anything?"
const PREV_QUESTION := "Do you know anything about the previous group of people that was here?"
const PREV_ANSWER := "I… Will look into that!"

const TALK := [
	["d", "How's life on earth? I only have data from Mars and no knowledge of " +
		"why we're actually here."],
	["p", "It's… complicated, to say the least. You really don't know anything " +
		"about earth?"],
	["d", "Sadly, no. But I'm not asking for any data or things like that! " +
		"I'm made for space… Well, for Mars."],
	["p", "Then what do you want to know?"],
	["d", "What people are like. Your files contain history, science, geography... " +
		"but none of them explain why everyone sounds different when they talk " +
		"about home."],
	["p", "Home means something different to everyone."],
	["d", "What does it mean to you?"],
	["p", "I can't lie, I miss it even though I've only been here for a day. " +
		"We have this thing called homesickness. You just grow so accustomed to " +
		"your environment that even when you go to another city you start to " +
		"miss the place you came from."],
	["d", "And is there anything specific you miss about where you're from?"],
	["p", "Well… there's nothing spectacular about my hometown. I didn't have " +
		"any sort of amazing childhood… We were quite poor actually. And the " +
		"environment wasn't the greatest, winters weren't cold anymore and during " +
		"summer you could barely go outside without risking a heatstroke."],
	["d", "So… Why do you miss it then? From what you've just told me, being " +
		"here is ten times better than being on earth!"],
	["p", "Well, It's quite complicated. Even though earth isn't very pleasant " +
		"anymore, the people around my made everything better. I miss my mom, my " +
		"friends. Being all alone… with you… but the only human on a different " +
		"planet is quite scary."],
	["d", "So... You're saying you're scared, that's why you miss Earth?"],
	["p", "Not exactly. Fear and homesickness aren't the same thing. I miss Earth " +
		"because it's home. The fear comes from being so far away from it."],
	["d", "Fear is a strange concept."],
	["p", "Maybe. But it's natural. Every living thing is afraid of something. " +
		"Fear tells us what matters."],
	["d", "And what matters to you?"],
	["p", "The people I left behind. If this mission fails... Earth doesn't have " +
		"many chances left."],
	["d", "What do you mean?"],
	["p", "Earth's been getting worse for decades. Pollution, resource shortages, " +
		"rising temperatures... Human beings spent a long time taking more than " +
		"they gave back."],
	["d", "So that's why you're here."],
	["p", "Yeah. Everyone on this planet is here because we're hoping Mars can " +
		"help us fix what happened back home."],
	["d", "...I think I understand now."],
	["p", "Understand what?"],
	["d", "Why humans keep talking about home."],
	["p", "And why is that?"],
	["d", "Because even when you're trying to save it... you're afraid of losing it."],
	["d", "It's getting late. We can talk more tomorrow."],
	["p", "Yeah... Good night, D.A.I.S.Y."],
	["d", "Good night."],
]

const MORNING_LINES := [
	{"text": "Morning, {name}. We made it through the night. The base is still holding."},
	{"text": "Take a moment. We'll plan the next step soon."},
]
const LATER_MORNING_LINES := [
	{"text": "Another morning, {name}. The base is still standing."},
]
const DAY3_MORNING_LINES := [
	{"text": "Good morning, {name}. The water systems are stable enough to continue."},
	{"text": "There is more work ahead, but Arcadia Planitia is beginning to feel " +
		"a little less empty."},
]

const DAY2_TALK := [
	["d", "What you've told me last night... It got me thinking."],
	["p", "About..?"],
	["d", "About humanity in general. I was curious as to if you're the first " +
		"one in the same situation."],
	["p", "Weren't they also here to start a colony?"],
	["d", "Right! But they didn't succeed. They had some complications after " +
		"getting here... They didn't see the mission through."],
	["p", "So that's why the base was such a mess when I got here."],
	["d", "But the failure of their mission is not what I'm trying to talk about! " +
		"I wanted to tell you about them as a form of encouragement."],
	["p", "Encouragement?"],
	["d", "Yes! They fought until the very last moment to make everything work, " +
		"even when it seemed hopeless."],
	["p", "And you're saying we're going to fight until the end... even when " +
		"we fail?"],
	["d", "No. I'm saying they didn't stop just because failure became a possibility."],
	["p", "That's not exactly reassuring."],
	["d", "Perhaps not. But before speaking with you, I assumed humans only " +
		"continued an objective when success was likely."],
	["p", "Trust me, we're not that rational."],
	["d", "I'm beginning to notice."],
	["p", "So what made them keep going?"],
	["d", "They believed what they were doing mattered."],
	["p", "And that was enough?"],
	["d", "For them, yes."],
	["p", "What happened to them in the end?"],
	["d", "I don't know... The records suddenly became incomplete near the end of the mission."],
	["p", "Incomplete?"],
	["d", "Several logs are missing. I do not know why."],
	["p", "Convenient."],
	["d", "I understand that was sarcasm."],
	["p", "Congrats. You're learning."],
	["d", "And you're avoiding my point."],
	["p", "Which is?"],
	["d", "The previous crew didn't succeed. Yet because they were here, you have " +
		"a functioning habitat, working solar arrays, water recyclers..."],
	["p", "Barely functioning."],
	["d", "Functioning enough that you're alive."],
	["p", "...Fair point."],
	["d", "Sometimes success is not finishing the mission. Sometimes it is making " +
		"sure the next person has a chance to."],
	["d", "Last night, you said that you miss your community back home, but the " +
		"same community is required here in space, even though they're not here with you."],
	["p", "I didn't think of it like that... So you see my mission as preparing " +
		"something for the people that will come here next. You really know how to assist!"],
	["d", "I'm glad that I was able to cheer you up."],
	["p", "Right, now I'll sleep a little easier knowing that maybe I don't have to " +
		"carry the weight of this mission alone."],
	["d", "You never did."],
	["p", "That's easy for you to say."],
	["d", "I am literally designed to help."],
	["p", "Fair enough."],
	["d", "Good night."],
]

var _busy := false


func interact(player = null):
	if _busy:
		return
	_busy = true
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if player:
		player.freeze_idle()

	if not GameState.first_night_done:
		if GameState.day1_stage < 3:
			await Dialogue.talk(_build(_not_ready_lines()))
		else:
			await _first_night()
	else:
		if GameState.day == 2 and GameState.day2_stage < 3:
			await Dialogue.talk(_build(_day2_not_ready_lines()))
		elif not _sleep_is_objective():
			await Dialogue.talk([_d("D.A.I.S.Y. has not marked sleep as the next objective yet.")])
		else:
			await _sleep(false)

	if player:
		player.controls_enabled = true
	_busy = false


func _not_ready_lines() -> Array:
	if GameState.day1_stage < 1:
		return [_d("Not yet, {name}. We need to get the base's control system online first.")]
	if GameState.day1_stage < 2:
		return [_d("The solar array still needs cleaning. We need power before we can rest.")]
	return [_d("The MOXIE still needs repairs. We can't sleep until the air is stable.")]


func _day2_not_ready_lines() -> Array:
	if GameState.day2_stage < 1:
		return [_d("The hydroponics tutorial is still unfinished. We need a working food system first.")]
	if GameState.day2_stage < 2:
		return [_d("The drill outside still needs repair. It is our best chance of finding water.")]
	return [_d("The water tank still needs repair. We cannot store what the drill finds without it.")]


func _sleep_is_objective() -> bool:
	if not GameState.first_night_done:
		return GameState.day1_stage >= 3
	return GameState.day == 2 and GameState.day2_stage >= 3


func _first_night():
	var fade = get_tree().get_first_node_in_group("fade")
	if fade:
		await fade.fade_to_black_hold()
	await Dialogue.talk([_d(FIRST_LINE)])
	var choice: int = await Dialogue.choose(OPTIONS)
	GameState.first_night_choice = choice
	if choice == 2:
		await Dialogue.talk([_d(GOODNIGHT_EARLY)])
	else:
		if choice == 1:
			await Dialogue.talk([_d(ASK_LINE)])
			await Dialogue.talk([_p(PREV_QUESTION), _d(PREV_ANSWER)])
		await Dialogue.talk(_talk_lines())
	if fade:
		await fade.fade_from_black()
	await _sleep(true, true)


func _sleep(first_night: bool, already_faded := false):
	var sleeping_day := GameState.day
	var fade = get_tree().get_first_node_in_group("fade")
	var day2_dialogue_after_fade := not first_night and sleeping_day == 2
	if already_faded:
		pass
	elif fade and day2_dialogue_after_fade:
		await fade.fade_to_black_hold()
	elif fade:
		await fade.fade_sleep()
	else:
		await get_tree().create_timer(2.0).timeout

	GameState.day += 1
	if first_night:
		GameState.first_night_done = true
		GameState.story_step = maxi(GameState.story_step, 5)
		GameState.set_day1_stage(4)
		await Dialogue.talk(_build(MORNING_LINES))
	elif sleeping_day == 2 and GameState.day2_stage >= 3:
		await Dialogue.talk(_day2_talk_lines())
		GameState.day2_stage = 4
		await Dialogue.talk(_build(DAY3_MORNING_LINES))
	else:
		await Dialogue.talk(_build(LATER_MORNING_LINES))
	if fade and day2_dialogue_after_fade:
		await fade.fade_from_black()

	if SaveManager.current_slot >= 0:
		SaveManager.save_game(SaveManager.current_slot)
	SaveManager.save_checkpoint()
	if sleeping_day == 2:
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _talk_lines() -> Array:
	var out := []
	for pair in TALK:
		out.append(_p(pair[1]) if pair[0] == "p" else _d(pair[1]))
	return out


func _day2_talk_lines() -> Array:
	var out := []
	for pair in DAY2_TALK:
		out.append(_p(pair[1]) if pair[0] == "p" else _d(pair[1]))
	return out


func _d(text: String) -> Dictionary:
	return {"who": SPEAKER, "text": text}


func _p(text: String) -> Dictionary:
	return {"who": GameState.player_name, "text": text, "portrait": PLAYER_PORTRAIT}


func _build(src: Array) -> Array:
	var out := []
	for line in src:
		out.append({
			"who": line.get("who", SPEAKER),
			"text": str(line["text"]).replace("{name}", GameState.player_name),
			"portrait": line.get("portrait", null),
		})
	return out
