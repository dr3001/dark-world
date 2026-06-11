extends Node

var character_id: String = ""
var stats: Dictionary = {
	"hp": 100, "max_hp": 100,
	"mana": 50, "max_mana": 50,
	"level": 1, "xp": 0, "zorium": 0,
	"strength": 5, "dexterity": 5, "intelligence": 5,
	"vitality": 5, "charisma": 3, "luck": 1
}

func set_character_id(id: String):
	character_id = id

func get_stat(key: String) -> int:
	return stats.get(key, 0)

func set_stat(key: String, value: int):
	stats[key] = value

func load_from_server(data: Dictionary):
	if not data: return
	for key in stats.keys():
		if data.has(key):
			stats[key] = data[key]

func get_level_text() -> String:
	return "Nv. " + str(stats.get("level", 1))

func get_zorium_text() -> String:
	return str(int(stats.get("zorium", 0))) + " Z"
