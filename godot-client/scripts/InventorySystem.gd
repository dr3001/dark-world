extends Node

signal inventory_toggled(is_open)
signal item_selected(slot_index, item_data)

var is_open: bool = false
var slots: Array = []
var max_slots: int = 20
var panel: ColorRect
var grid: GridContainer
var title_label: Label
var hint_label: Label
var tooltip: Node
var selected_slot: int = -1

func setup(inventory_panel: ColorRect, tooltip_node: Node = null):
	panel = inventory_panel
	tooltip = tooltip_node
	if panel:
		panel.visible = false
		title_label = panel.get_node_or_null("InventoryTitle")
		grid = panel.get_node_or_null("InventoryGrid")
		hint_label = panel.get_node_or_null("InventoryHint")
	slots.resize(max_slots)
	for i in range(max_slots):
		slots[i] = null

func toggle():
	is_open = !is_open
	if panel: panel.visible = is_open
	if not is_open and tooltip and tooltip.has_method("hide_tooltip"):
		tooltip.hide_tooltip()
	selected_slot = -1
	inventory_toggled.emit(is_open)

func close():
	is_open = false
	if panel: panel.visible = false
	if tooltip and tooltip.has_method("hide_tooltip"):
		tooltip.hide_tooltip()
	selected_slot = -1

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

func get_used_count() -> int:
	var count = 0
	for s in slots:
		if s != null: count += 1
	return count

func _update_grid():
	if not grid: return
	for child in grid.get_children():
		child.queue_free()
	for i in range(max_slots):
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(110, 60)
		slot_btn.flat = true
		if slots[i]:
			var item = slots[i]
			var rarity = item.get("rarity", "common")
			slot_btn.modulate = _rarity_color(rarity)
			var name_short = str(item.get("item_name", "?")).substr(0, 12)
			var qty = item.get("quantity", 1)
			slot_btn.text = name_short + ("\n x" + str(qty) if qty > 1 else "")
			slot_btn.tooltip_text = str(item.get("item_name", "?"))
			var idx = i
			slot_btn.pressed.connect(func(): _on_slot_clicked(idx))
			slot_btn.mouse_entered.connect(func(): _on_slot_hover(idx))
			slot_btn.mouse_exited.connect(func(): _on_slot_unhover())
		else:
			slot_btn.modulate = Color(0.3, 0.3, 0.35, 0.6)
			slot_btn.text = ""
		grid.add_child(slot_btn)
	if hint_label:
		hint_label.text = str(get_used_count()) + "/" + str(max_slots) + " slots"

func _on_slot_clicked(idx: int):
	selected_slot = idx
	if slots[idx]:
		item_selected.emit(idx, slots[idx])

func _on_slot_hover(idx: int):
	if slots[idx] and tooltip and tooltip.has_method("show_item"):
		tooltip.show_item(slots[idx], Vector2(580, 200))

func _on_slot_unhover():
	if tooltip and tooltip.has_method("hide_tooltip"):
		tooltip.hide_tooltip()

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.6, 0.6, 0.6, 0.9)
		"uncommon": return Color(0.3, 0.8, 0.3, 0.9)
		"rare": return Color(0.3, 0.5, 1.0, 0.9)
		"epic": return Color(0.7, 0.3, 0.9, 0.9)
		"legendary": return Color(1.0, 0.7, 0.2, 0.9)
		"mythic": return Color(1.0, 0.3, 0.3, 0.9)
		_: return Color(0.5, 0.5, 0.5, 0.9)
