extends Node

var player_name := "AGENT"
var quests := {}   
var items := {}   


func done_count() -> int:
	var n := 0
	for id in quests:
		if quests[id] == "done":
			n += 1
	return n
