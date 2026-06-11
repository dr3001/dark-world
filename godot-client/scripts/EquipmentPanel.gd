extends Node

var panel: ColorRect
var slot_labels: Dictionary = {}
var equipped: Dictionary = {}
var on_unequip_callback: Callable
var slot_types: Array = ["weapon", "helmet", "chest", "gloves", "boots", "ring", "amulet"]
var slot_names: Dictionary = {
	"weapon": "Arma", "helmet": "Capacete", "chest": "Peitoral",
	"gloves": "Luvas", "boots": "Botas", "ring": "Anel", "amulet": "Amuleto"
}

func setup(equip_panel: ColorRect):
	panel = equip_panel
	if not panel: return
	panel.visible = false
	for child in panel.get_children():
		if child.name != "EquipTitle": child.queue_free()
	for i in range(slot_types.size()):
		var slot = slot_types[i]
		var btn = Button.new()
		btn.name = "Slot_" + slot
		btn.custom_minimum_size = Vector2(160, 32)
		btn.position = Vector2(10, 40 + i * 38)
		btn.flat = true
		btn.text = slot_names[slot] + ": ---"
		btn.modulate = Color(0.7, 0.7, 0.7)
		var s = slot
		btn.pressed.connect(func(): _on_slot_clicked(s))
		panel.add_child(btn)
		slot_labels[slot] = btn

func toggle():
	if panel: panel.visible = !panel.visible

func show():
	if panel: panel.visible = true

func hide():
	if panel: panel.visible = false

func load_from_server(equipment_data: Array):
	equipped.clear()
	for eq in equipment_data:
		var st = eq.get("slot_type", "")
		equipped[st] = eq
	_update_display()

func equip_item(slot_type: String, item_data: Dictionary):
	equipped[slot_type] = item_data
	_update_display()

func unequip_slot(slot_type: String) -> Dictionary:
	var item = equipped.get(slot_type, {})
	equipped.erase(slot_type)
	_update_display()
	return item

func get_stat_bonuses() -> Dictionary:
	var bonuses: Dictionary = {}
	for slot in equipped:
		var item = equipped[slot]
		var base = item.get("base_stats", {})
		if base is String: base = JSON.parse_string(base)
		if not base: continue
		for k in base:
			bonuses[k] = bonuses.get(k, 0) + base[k]
	return bonuses

func _update_display():
	for slot in slot_types:
		if not slot_labels.has(slot): continue
		var btn = slot_labels[slot]
		if equipped.has(slot):
			var item = equipped[slot]
			var name = item.get("item_name", item.get("name", "?"))
			btn.text = slot_names[slot] + ": " + str(name)
			btn.modulate = _rarity_color(item.get("rarity", "common"))
		else:
			btn.text = slot_names[slot] + ": ---"
			btn.modulate = Color(0.5, 0.5, 0.5)

func _on_slot_clicked(slot_type: String):
	if equipped.has(slot_type):
		if on_unequip_callback.is_valid():
			on_unequip_callback.call(slot_type)
		unequip_slot(slot_type)

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"uncommon": return Color(0.3, 0.9, 0.3)
		"rare": return Color(0.4, 0.6, 1.0)
		"epic": return Color(0.7, 0.3, 0.9)
		"legendary": return Color(1.0, 0.7, 0.2)
		"mythic": return Color(1.0, 0.3, 0.3)
		_: return Color(0.8, 0.8, 0.8)
