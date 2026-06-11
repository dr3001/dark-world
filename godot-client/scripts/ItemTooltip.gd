extends ColorRect

var name_label: Label
var type_label: Label
var stats_label: Label
var value_label: Label
var active_item: Dictionary = {}

func _ready():
	visible = false
	color = Color(0.08, 0.08, 0.12, 0.95)
	custom_minimum_size = Vector2(240, 160)
	name_label = Label.new(); name_label.position = Vector2(10, 8)
	add_child(name_label)
	type_label = Label.new(); type_label.position = Vector2(10, 30)
	type_label.modulate = Color(0.7, 0.7, 0.7)
	add_child(type_label)
	stats_label = Label.new(); stats_label.position = Vector2(10, 55)
	stats_label.size = Vector2(220, 70); stats_label.autowrap_mode = 2
	add_child(stats_label)
	value_label = Label.new(); value_label.position = Vector2(10, 130)
	value_label.modulate = Color(0.4, 0.8, 1)
	add_child(value_label)

func show_item(item: Dictionary, at_pos: Vector2):
	active_item = item
	name_label.text = item.get("item_name", item.get("name", "?"))
	name_label.modulate = _rarity_color(item.get("rarity", "common"))
	var slot = item.get("slot_type", item.get("item_slot_type", ""))
	type_label.text = str(item.get("item_type", "")).capitalize()
	if slot and slot != "": type_label.text += " (" + str(slot).capitalize() + ")"
	var base = item.get("base_stats", {})
	if base is String: base = JSON.parse_string(base)
	if not base: base = {}
	var st = ""
	for k in base:
		st += str(k).capitalize() + ": +" + str(base[k]) + "\n"
	stats_label.text = st if st != "" else "(Sem bonus)"
	var val = item.get("value_zorium", 0)
	value_label.text = str(int(val)) + " Zorium" if int(val) > 0 else ""
	position = at_pos
	visible = true

func hide_tooltip():
	visible = false
	active_item = {}

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.8, 0.8, 0.8)
		"uncommon": return Color(0.3, 0.9, 0.3)
		"rare": return Color(0.3, 0.5, 1.0)
		"epic": return Color(0.7, 0.3, 0.9)
		"legendary": return Color(1.0, 0.7, 0.2)
		"mythic": return Color(1.0, 0.3, 0.3)
		_: return Color(0.8, 0.8, 0.8)
