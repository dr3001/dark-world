extends Node

signal inventory_toggled(is_open)

var is_open: bool = false
var slots: Array = []
var max_slots: int = 20
var panel: ColorRect
var grid: GridContainer
var title_label: Label

func setup(inventory_panel: ColorRect):
	panel = inventory_panel
	if panel:
		panel.visible = false
		title_label = panel.get_node_or_null("InventoryTitle")
		grid = panel.get_node_or_null("InventoryGrid")
	slots.resize(max_slots)
	for i in range(max_slots):
		slots[i] = null

func toggle():
	is_open = !is_open
	if panel: panel.visible = is_open
	inventory_toggled.emit(is_open)

func close():
	is_open = false
	if panel: panel.visible = false

func add_item(slot_index: int, item_data: Dictionary):
	if slot_index < 0 or slot_index >= max_slots: return
	slots[slot_index] = item_data
	_update_grid()

func remove_item(slot_index: int):
	if slot_index < 0 or slot_index >= max_slots: return
	slots[slot_index] = null
	_update_grid()

func load_from_server(inventory_data: Array):
	for i in range(max_slots):
		slots[i] = null
	for item in inventory_data:
		var idx = item.get("slot_index", -1)
		if idx >= 0 and idx < max_slots:
			slots[idx] = item
	_update_grid()

func _update_grid():
	if not grid: return
	for child in grid.get_children():
		child.queue_free()
	for i in range(max_slots):
		var slot_rect = ColorRect.new()
		slot_rect.custom_minimum_size = Vector2(56, 56)
		if slots[i]:
			slot_rect.color = _rarity_color(slots[i].get("rarity", "common"))
			var lbl = Label.new()
			lbl.text = str(slots[i].get("item_name", "?")).substr(0, 6)
			lbl.add_theme_font_size_override("font_size", 10)
			slot_rect.add_child(lbl)
		else:
			slot_rect.color = Color(0.12, 0.12, 0.15, 0.8)
		grid.add_child(slot_rect)

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.3, 0.3, 0.3, 0.9)
		"uncommon": return Color(0.2, 0.5, 0.2, 0.9)
		"rare": return Color(0.2, 0.3, 0.7, 0.9)
		"epic": return Color(0.5, 0.2, 0.6, 0.9)
		"legendary": return Color(0.7, 0.5, 0.1, 0.9)
		"mythic": return Color(0.8, 0.2, 0.2, 0.9)
		_: return Color(0.2, 0.2, 0.2, 0.9)
