extends Node3D

func _ready():
	_create_dragon()

func _create_dragon():
	# Body - large elongated box
	var body = _make_box(Vector3(4, 2, 10), Color(0.5, 0.1, 0.1), Vector3(0, 3, 0))
	
	# Head
	var head = _make_box(Vector3(2.5, 2, 3), Color(0.55, 0.12, 0.12), Vector3(0, 3.5, -6))
	
	# Snout
	var snout = _make_box(Vector3(1.5, 1, 2), Color(0.3, 0.06, 0.06), Vector3(0, 3, -8))
	
	# Eyes (glowing yellow)
	var left_eye = _make_sphere(0.4, Color(1, 0.8, 0, 1), Vector3(0.7, 4.2, -7))
	left_eye.material_override = _make_glow_material(Color(1, 0.8, 0))
	var right_eye = _make_sphere(0.4, Color(1, 0.8, 0, 1), Vector3(-0.7, 4.2, -7))
	right_eye.material_override = _make_glow_material(Color(1, 0.8, 0))
	
	# Horns
	var left_horn = _make_box(Vector3(0.3, 1.5, 0.3), Color(0.15, 0.15, 0.15), Vector3(0.8, 5, -5.5))
	left_horn.rotation_degrees = Vector3(0, 0, -20)
	var right_horn = _make_box(Vector3(0.3, 1.5, 0.3), Color(0.15, 0.15, 0.15), Vector3(-0.8, 5, -5.5))
	right_horn.rotation_degrees = Vector3(0, 0, 20)
	
	# Wings (large flat boxes)
	var left_wing = _make_box(Vector3(8, 0.3, 3), Color(0.35, 0.07, 0.07), Vector3(4, 5, -1))
	left_wing.rotation_degrees = Vector3(0, 0, 30)
	var right_wing = _make_box(Vector3(8, 0.3, 3), Color(0.35, 0.07, 0.07), Vector3(-4, 5, -1))
	right_wing.rotation_degrees = Vector3(0, 0, -30)
	
	# Tail (series of boxes getting smaller)
	for i in range(6):
		var s = 1.0 - float(i) * 0.15
		var tail_seg = _make_box(Vector3(1.5 * s, 1 * s, 2), Color(0.5, 0.1, 0.1), Vector3(0, 2.5, 5 + i * 1.5))
	
	# Legs
	_make_leg(Vector3(1.5, 3.5, -2))
	_make_leg(Vector3(-1.5, 3.5, -2))
	_make_leg(Vector3(1.5, 3.5, 2))
	_make_leg(Vector3(-1.5, 3.5, 2))

func _make_box(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	add_child(mi)
	return mi

func _make_sphere(radius: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	mi.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	add_child(mi)
	return mi

func _make_glow_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	return mat

func _make_leg(pos: Vector3):
	var upper = _make_box(Vector3(0.6, 2.5, 0.6), Color(0.45, 0.09, 0.09), Vector3(pos.x, pos.y - 1.25, pos.z))
	var lower = _make_box(Vector3(0.4, 2.5, 0.4), Color(0.35, 0.07, 0.07), Vector3(pos.x, pos.y - 3.5, pos.z))
