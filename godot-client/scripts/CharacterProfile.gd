extends Node

signal level_up(new_level)
signal stats_changed()
signal zorium_changed(amount)

var character_id: String = ""
var stats: Dictionary = {
	"hp": 100, "max_hp": 100,
	"mana": 50, "max_mana": 50,
	"level": 1, "xp": 0, "zorium": 0.0,
	"strength": 5, "dexterity": 5, "intelligence": 5,
	"vitality": 5, "charisma": 3, "luck": 1
}

var xp_table: Array = [0, 100, 250, 500, 800, 1200, 1700, 2300, 3000, 4000,
	5200, 6600, 8200, 10000, 12500, 15500, 19000, 23000, 28000, 34000]

func set_character_id(id: String):
	character_id = id

func get_stat(key: String):
	return stats.get(key, 0)

func set_stat(key: String, value):
	stats[key] = value
	stats_changed.emit()

func load_from_server(data: Dictionary):
	if not data: return
	for key in stats.keys():
		if data.has(key):
			stats[key] = data[key]
	stats_changed.emit()

func add_xp(amount: int):
	var old_level = stats.get("level", 1)
	stats["xp"] = stats.get("xp", 0) + amount
	var new_level = old_level
	while new_level < xp_table.size() and stats["xp"] >= xp_table[new_level]:
		new_level += 1
	if new_level > old_level:
		stats["level"] = new_level
		stats["max_hp"] = stats.get("max_hp", 100) + (new_level - old_level) * 10
		stats["hp"] = stats["max_hp"]
		stats["max_mana"] = stats.get("max_mana", 50) + (new_level - old_level) * 5
		stats["mana"] = stats["max_mana"]
		level_up.emit(new_level)
	stats_changed.emit()

func add_zorium(amount: float):
	stats["zorium"] = stats.get("zorium", 0.0) + amount
	zorium_changed.emit(amount)
	stats_changed.emit()

func spend_zorium(amount: float) -> bool:
	if float(stats.get("zorium", 0)) < amount: return false
	stats["zorium"] = float(stats.get("zorium", 0)) - amount
	zorium_changed.emit(-amount)
	stats_changed.emit()
	return true

func heal_full():
	stats["hp"] = stats.get("max_hp", 100)
	stats_changed.emit()

func get_level_text() -> String:
	return "Nv. " + str(stats.get("level", 1))

func get_zorium_text() -> String:
	return str(int(stats.get("zorium", 0))) + " Z"

func get_xp_progress() -> float:
	var lvl = stats.get("level", 1)
	var xp = stats.get("xp", 0)
	var current_req = xp_table[lvl - 1] if lvl - 1 < xp_table.size() else 0
	var next_req = xp_table[lvl] if lvl < xp_table.size() else current_req + 5000
	if next_req <= current_req: return 1.0
	return clamp(float(xp - current_req) / float(next_req - current_req), 0.0, 1.0)
