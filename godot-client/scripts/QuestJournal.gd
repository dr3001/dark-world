extends Node

var panel: ColorRect
var quest_list: VBoxContainer
var quests: Array = []
var is_open: bool = false

func setup(journal_panel: ColorRect):
	panel = journal_panel
	if not panel: return
	panel.visible = false
	quest_list = panel.get_node_or_null("QuestList")
	if not quest_list:
		quest_list = VBoxContainer.new()
		quest_list.name = "QuestList"
		quest_list.position = Vector2(20, 45)
		quest_list.size = Vector2(360, 300)
		panel.add_child(quest_list)

func toggle():
	is_open = !is_open
	if panel: panel.visible = is_open

func load_from_server(quest_data: Array):
	quests = quest_data
	_update_display()

func _update_display():
	if not quest_list: return
	for child in quest_list.get_children():
		child.queue_free()
	if quests.size() == 0:
		var lbl = Label.new()
		lbl.text = "Nenhuma missao ativa."
		lbl.modulate = Color(0.6, 0.6, 0.6)
		quest_list.add_child(lbl)
		return
	for q in quests:
		var entry = Label.new()
		var state = q.get("state", "available")
		var name = q.get("quest_name", q.get("name", "?"))
		entry.text = _state_icon(state) + " " + str(name)
		entry.modulate = _state_color(state)
		entry.autowrap_mode = 2
		quest_list.add_child(entry)
		if q.has("description"):
			var desc = Label.new()
			desc.text = "  " + str(q["description"]).substr(0, 60)
			desc.modulate = Color(0.6, 0.6, 0.6)
			desc.add_theme_font_size_override("font_size", 12)
			quest_list.add_child(desc)

func _state_icon(state: String) -> String:
	match state:
		"active": return ">"
		"completed": return "+"
		"failed": return "X"
		"turned_in": return "*"
		_: return "-"

func _state_color(state: String) -> Color:
	match state:
		"active": return Color(1, 0.9, 0.4)
		"completed": return Color(0.3, 0.9, 0.3)
		"failed": return Color(0.9, 0.3, 0.3)
		"turned_in": return Color(0.5, 0.5, 0.5)
		_: return Color(0.7, 0.7, 0.7)
