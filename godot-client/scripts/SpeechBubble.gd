extends Node3D

var label: Label3D
var timer: float = 0.0
var duration: float = 4.0
var active: bool = false

func _ready():
	label = Label3D.new()
	label.font_size = 20
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 3.5, 0)
	label.visible = false
	add_child(label)

func show_message(text: String, vip_level: int = 0, role: String = "player", dur: float = 4.0):
	label.text = text
	label.modulate = _bubble_color(vip_level, role)
	label.outline_modulate = Color(0, 0, 0, 0.8)
	label.outline_size = 4
	label.visible = true
	duration = dur
	timer = 0.0
	active = true

func _process(delta):
	if not active: return
	timer += delta
	if timer >= duration:
		label.visible = false
		active = false

func _bubble_color(vip: int, role: String) -> Color:
	if role == "admin": return Color(1, 0.4, 0.4)
	if role == "staff": return Color(0.4, 0.9, 1)
	if vip >= 13: return Color(0.7, 0.9, 1)
	if vip >= 7: return Color(1, 0.85, 0.3)
	if vip >= 1: return Color(0.8, 0.65, 0.35)
	return Color(1, 1, 1)
