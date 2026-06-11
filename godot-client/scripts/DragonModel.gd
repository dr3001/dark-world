extends Node3D

func _ready():
	_create_dragon()

func _create_dragon():
	var body_color = Color(0.55, 0.12, 0.08)
	var belly_color = Color(0.7, 0.3, 0.15)
	var wing_color = Color(0.3, 0.06, 0.06)
	var spike_color = Color(0.15, 0.1, 0.08)
	var eye_color = Color(1, 0.8, 0)
	var dark = Color(0.2, 0.05, 0.05)

	# === MAIN BODY ===
	_make_box(Vector3(3.5, 2.5, 9), body_color, Vector3(0, 3, 0))
	_make_box(Vector3(3.8, 2.0, 5), belly_color, Vector3(0, 2.5, 0))
	
	# === NECK ===
	for i in range(4):
		var t = float(i) / 3.0
		var s = 1.0 - t * 0.5
		_make_box(Vector3(2.0*s, 1.8*s, 1.5), body_color, Vector3(0, 3.5 - t*1.5, -5 - i*1.5))
	
	# === HEAD ===
	_make_box(Vector3(2.8, 2.2, 3.5), body_color, Vector3(0, 3.2, -9))
	# Jaw
	_make_box(Vector3(2.4, 0.8, 2.5), dark, Vector3(0, 2.0, -9.5))
	# Snout
	_make_box(Vector3(1.8, 1.2, 2.0), body_color, Vector3(0, 3.0, -11))
	# Nostrils
	_make_box(Vector3(0.3, 0.3, 0.3), Color(0.1, 0.05, 0.05), Vector3(0.5, 3.3, -12))
	_make_box(Vector3(0.3, 0.3, 0.3), Color(0.1, 0.05, 0.05), Vector3(-0.5, 3.3, -12))
	
	# === EYES (glowing) ===
	var ley = _make_sphere(0.45, eye_color, Vector3(0.9, 4.0, -10.2))
	ley.material_override = _make_glow(eye_color)
	var rey = _make_sphere(0.45, eye_color, Vector3(-0.9, 4.0, -10.2))
	rey.material_override = _make_glow(eye_color)
	
	# === HORNS ===
	for i in range(3):
		var a = -20 + i*20
		var h = 1.5 - i*0.3
		_make_horn(Vector3(0.7, 4.5 - i*0.3, -9 + i*0.5), a, h)
		_make_horn(Vector3(-0.7, 4.5 - i*0.3, -9 + i*0.5), -a, h)
	
	# === SPIKES ALONG SPINE ===
	for i in range(10):
		var z = -3 + i * 1.0
		var spike_h = 1.5 - abs(z) * 0.05
		_make_spike(Vector3(0, 4.5, z), spike_h)
	
	# === WINGS ===
	# Left wing
	var lw = Node3D.new(); lw.position = Vector3(2.5, 4.5, -1); lw.rotation_degrees = Vector3(0, -10, 40)
	for i in range(5):
		var ws = 1.0 - i*0.2
		_make_box_for(lw, Vector3(0.2, 0.3, 7*ws), wing_color, Vector3(0, 0, -3.5 + i*1.8))
	add_child(lw)
	# Wing membrane
	_make_box_for(lw, Vector3(0.05, 0.5, 5), Color(0.3, 0.06, 0.06, 0.7), Vector3(0, -0.2, -1))
	
	# Right wing
	var rw = Node3D.new(); rw.position = Vector3(-2.5, 4.5, -1); rw.rotation_degrees = Vector3(0, 10, -40)
	for i in range(5):
		var ws = 1.0 - i*0.2
		_make_box_for(rw, Vector3(0.2, 0.3, 7*ws), wing_color, Vector3(0, 0, -3.5 + i*1.8))
	add_child(rw)
	_make_box_for(rw, Vector3(0.05, 0.5, 5), Color(0.3, 0.06, 0.06, 0.7), Vector3(0, -0.2, -1))
	
	# === FRONT LEGS ===
	_make_leg(Vector3(2, 2.5, -2), body_color, dark)
	_make_leg(Vector3(-2, 2.5, -2), body_color, dark)
	
	# === BACK LEGS ===
	_make_leg(Vector3(2, 2.5, 3), body_color, dark)
	_make_leg(Vector3(-2, 2.5, 3), body_color, dark)
	
	# === TAIL ===
	for i in range(8):
		var s = 1.0 - float(i) * 0.12
		_make_box(Vector3(1.5*s, 1.2*s, 2*s), body_color, Vector3(0, 2.5 - i*0.1, 5 + i*1.8))
	# Tail spikes
	for i in range(5):
		_make_spike(Vector3(0, 2.8, 6 + i*1.8), 1.0 - i*0.15)
	
	# === TEETH (upper jaw) ===
	for i in range(6):
		var x = -1.2 + i*0.5
		_make_tooth(Vector3(x, 2.6, -11.5))
	
	print("[DragonModel] Created with 60+ primitives")

func _make_box(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	return _make_box_for(self, size, color, pos)

func _make_box_for(parent: Node, size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new(); box.size = size
	mi.mesh = box
	var mat = StandardMaterial3D.new(); mat.albedo_color = color
	if color.a < 1.0: mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	parent.add_child(mi)
	return mi

func _make_sphere(r: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var s = SphereMesh.new(); s.radius = r; s.height = r*2
	mi.mesh = s
	var mat = StandardMaterial3D.new(); mat.albedo_color = color
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	add_child(mi)
	return mi

func _make_glow(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	return mat

func _make_horn(pos: Vector3, angle: float, h: float):
	var horn = Node3D.new()
	horn.position = pos
	horn.rotation_degrees = Vector3(0, 0, angle)
	_make_box_for(horn, Vector3(0.2, h, 0.2), Color(0.12, 0.1, 0.08), Vector3(0, h/2, 0))
	add_child(horn)

func _make_spike(pos: Vector3, h: float):
	var s = Node3D.new(); s.position = pos; s.rotation_degrees = Vector3(90, 0, 0)
	_make_box_for(s, Vector3(0.15, h, 0.3), Color(0.15, 0.1, 0.08), Vector3(0, h/2, 0))
	add_child(s)

func _make_tooth(pos: Vector3):
	_make_box(Vector3(0.12, 0.6, 0.12), Color(0.9, 0.9, 0.85), pos)

func _make_leg(pos: Vector3, upper_color: Color, lower_color: Color):
	var leg = Node3D.new(); leg.position = pos
	_make_box_for(leg, Vector3(0.8, 2.0, 0.8), upper_color, Vector3(0, -1, 0))
	_make_box_for(leg, Vector3(0.6, 2.0, 0.6), lower_color, Vector3(0, -3, 0))
	# Foot/claws
	_make_box_for(leg, Vector3(0.8, 0.3, 1.0), dark_color(), Vector3(0, -4.2, 0.3))
	add_child(leg)

func dark_color() -> Color: return Color(0.15, 0.05, 0.05)
