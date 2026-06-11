extends Node

var panel: ColorRect
var message_container: VBoxContainer
var messages: Array = []
var max_messages: int = 8
var poll_timer: float = 0.0
var poll_interval: float = 5.0

func setup(chat_panel: ColorRect):
	panel = chat_panel
	if not panel: return
	message_container = panel.get_node_or_null("ChatMessages")
	if not message_container:
		message_container = VBoxContainer.new()
		message_container.name = "ChatMessages"
		message_container.position = Vector2(10, 10)
		message_container.size = Vector2(380, 140)
		panel.add_child(message_container)

func add_message(display_name: String, text: String, vip_level: int = 0, role: String = "player"):
	var entry = {"name": display_name, "text": text, "vip": vip_level, "role": role}
	messages.append(entry)
	if messages.size() > max_messages:
		messages.pop_front()
	_update_display()

func load_from_server(server_messages: Array):
	messages.clear()
	for msg in server_messages:
		messages.append({
			"name": msg.get("display_name", "?"),
			"text": msg.get("message", ""),
			"vip": msg.get("vip_level", 0),
			"role": msg.get("role", "player")
		})
	if messages.size() > max_messages:
		messages = messages.slice(messages.size() - max_messages)
	_update_display()

func _update_display():
	if not message_container: return
	for child in message_container.get_children():
		child.queue_free()
	for msg in messages:
		var lbl = Label.new()
		var prefix = _role_prefix(msg.get("role", "player"), msg.get("vip", 0))
		lbl.text = prefix + str(msg.get("name", "?")) + ": " + str(msg.get("text", ""))
		lbl.modulate = _role_color(msg.get("role", "player"), msg.get("vip", 0))
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.autowrap_mode = 2
		message_container.add_child(lbl)

func _role_prefix(role: String, vip: int) -> String:
	if role == "admin": return "[ADMIN] "
	if role == "staff": return "[STAFF] "
	if role == "moderator": return "[MOD] "
	if vip > 0: return "[VIP" + str(vip) + "] "
	return ""

func _role_color(role: String, vip: int) -> Color:
	if role == "admin": return Color(1, 0.3, 0.3)
	if role == "staff": return Color(0.3, 0.8, 1)
	if role == "moderator": return Color(0.3, 1, 0.5)
	if vip >= 13: return Color(0.7, 0.9, 1)
	if vip >= 7: return Color(1, 0.85, 0.3)
	if vip >= 4: return Color(0.75, 0.75, 0.8)
	if vip >= 1: return Color(0.8, 0.6, 0.3)
	return Color(0.8, 0.8, 0.8)
