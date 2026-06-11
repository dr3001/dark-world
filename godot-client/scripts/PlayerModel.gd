extends Node3D

var head: Node3D
var body: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var run_time: float = 0.0
var is_moving: bool = false

func _ready():
	_create_player()

func _create_player():
	var skin = Color(0.85, 0.7, 0.55)
	var cloth = Color(0.25, 0.2, 0.15)
	var dark = Color(0.15, 0.12, 0.1)

	# Head
	head = _make_sphere(0.35, skin, Vector3(0, 2.35, 0))
	
	# Body (torso)
	body = _make_box(Vector3(0.7, 0.9, 0.35), cloth, Vector3(0, 1.55, 0))
	
	# Arms
	left_arm = _make_box(Vector3(0.2, 0.8, 0.2), cloth, Vector3(0.55, 1.6, 0))
	right_arm = _make_box(Vector3(0.2, 0.8, 0.2), cloth, Vector3(-0.55, 1.6, 0))
	
	# Legs
	left_leg = _make_box(Vector3(0.22, 0.75, 0.22), dark, Vector3(0.2, 0.55, 0))
	right_leg = _make_box(Vector3(0.22, 0.75, 0.22), dark, Vector3(-0.2, 0.55, 0))
	
	# Sword on back
	var sword_blade = _make_box(Vector3(0.08, 1.2, 0.05), Color(0.7, 0.7, 0.75), Vector3(0, 2.2, -0.3))
	var sword_guard = _make_box(Vector3(0.3, 0.08, 0.08), Color(0.6, 0.4, 0.2), Vector3(0, 1.65, -0.3))

func _make_box(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new(); box.size = size
	mi.mesh = box
	var mat = StandardMaterial3D.new(); mat.albedo_color = color
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	add_child(mi)
	return mi

func _make_sphere(r: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var s = SphereMesh.new(); s.radius = r; s.height = r * 2
	mi.mesh = s
	var mat = StandardMaterial3D.new(); mat.albedo_color = color
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	add_child(mi)
	return mi

func animate_walk(delta: float, moving: bool):
	if moving:
		run_time += delta * 10.0
		if left_arm: left_arm.rotation.x = sin(run_time) * 0.5
		if right_arm: right_arm.rotation.x = -sin(run_time) * 0.5
		if left_leg: left_leg.rotation.x = -sin(run_time) * 0.5
		if right_leg: right_leg.rotation.x = sin(run_time) * 0.5
	else:
		if left_arm: left_arm.rotation.x = lerp(left_arm.rotation.x, 0.0, 0.1)
		if right_arm: right_arm.rotation.x = lerp(right_arm.rotation.x, 0.0, 0.1)
		if left_leg: left_leg.rotation.x = lerp(left_leg.rotation.x, 0.0, 0.1)
		if right_leg: right_leg.rotation.x = lerp(right_leg.rotation.x, 0.0, 0.1)
