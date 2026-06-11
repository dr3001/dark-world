extends Node

var cached_tables: Dictionary = {}

func cache_table(source_type: String, source_id: String, table_data: Array):
	var key = source_type + ":" + source_id
	cached_tables[key] = table_data

func get_cached(source_type: String, source_id: String) -> Array:
	var key = source_type + ":" + source_id
	return cached_tables.get(key, [])

func roll_local(source_type: String, source_id: String) -> Array:
	var table = get_cached(source_type, source_id)
	var drops: Array = []
	for entry in table:
		var chance = float(entry.get("drop_chance", 1.0))
		if randf() <= chance:
			var min_q = int(entry.get("min_qty", 1))
			var max_q = int(entry.get("max_qty", 1))
			var qty = min_q + randi() % max(1, max_q - min_q + 1)
			drops.append({
				"item_id": entry.get("item_id", ""),
				"item_name": entry.get("item_name", "?"),
				"rarity": entry.get("rarity", "common"),
				"quantity": qty
			})
	return drops
