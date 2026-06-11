extends Node3D

var target_pos: Vector3 = Vector3.ZERO
var display_name: String = ""
var vip_level: int = 0
var player_role: String = "player"
var char_id: String = ""

func setup(cid: String, dname: String, pos: Vector3, vip: int = 0, role: String = "player"):
	char_id = cid
	display_name = dname
	target_pos = pos
	position = pos
	vip_level = vip
	player_role = role
	_build_visual()

func _build_visual():
	var body_color = _role_color()
	var body = MeshInstance3D.new()
	var caps = CapsuleMesh.new(); caps.radius = 0.4; caps.height = 1.2
	body.mesh = caps; body.position = Vector3(0, 1.4, 0)
	var mat = StandardMaterial3D.new(); mat.albedo_color = body_color
	body.set_surface_override_material(0, mat)
	add_child(body)
	var head = MeshInstance3D.new()
	var sphere = SphereMesh.new(); sphere.radius = 0.3; sphere.height = 0.6
	head.mesh = sphere; head.position = Vector3(0, 2.2, 0)
	var hmat = StandardMaterial3D.new(); hmat.albedo_color = Color(0.85, 0.70, 0.55)
	head.set_surface_override_material(0, hmat)
	add_child(head)
	var lbl = Label3D.new()
	lbl.text = display_name
	lbl.position = Vector3(0, 2.8, 0)
	lbl.font_size = 22
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = body_color
	add_child(lbl)

func update_position(pos: Vector3):
	target_pos = pos

func _process(delta):
	position = position.lerp(target_pos, 5.0 * delta)

func _role_color() -> Color:
	if player_role == "admin" or player_role == "owner": return Color(1, 0.3, 0.3)
	if player_role == "staff" or player_role == "gm": return Color(0.3, 0.8, 1)
	if player_role == "moderator": return Color(0.3, 1, 0.5)
	if vip_level >= 7: return Color(1, 0.85, 0.3)
	if vip_level >= 1: return Color(0.8, 0.6, 0.3)
	return Color(0.3, 0.3, 0.7)
