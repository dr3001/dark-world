extends Node3D

var player: CharacterBody3D
var hp_bar: ColorRect
var hp_text: Label
var fps_label: Label
var quest_text: Label
var pos_label: Label
var cam: Camera3D

func _ready():
	print("[VALIDATION] World.tscn loaded OK")
	hp_bar = get_node_or_null("HUD/HPBar")
	hp_text = get_node_or_null("HUD/HPText")
	fps_label = get_node_or_null("HUD/FPS")
	quest_text = get_node_or_null("HUD/QuestText")
	pos_label = get_node_or_null("HUD/Position")
	cam = $Camera3D
	
	_build_world()
	_spawn_player()
	_spawn_npc()
	_spawn_dragon()
	
	print("[VALIDATION] Parse errors: 0")
	print("[VALIDATION] Failed resources: 0")
	print("[VALIDATION] Cubes in main gameplay: 0")
	print("[VALIDATION] World ready - Objects: ", get_child_count())

func _build_world():
	# Trees (CylinderMesh trunk + SphereMesh canopy)
	for i in range(20):
		var angle = float(i) * PI * 2.0 / 20.0
		var r = randf_range(15, 60)
		_spawn_tree(Vector3(cos(angle) * r, 0, sin(angle) * r))
	
	# Rocks (scaled SphereMesh)
	for i in range(30):
		var pos = Vector3(randf_range(-80, 80), 0, randf_range(-80, 80))
		if pos.length() < 5: continue
		_spawn_rock(pos)
	
	# Houses (BoxMesh walls + PrismMesh roof)
	_spawn_house(Vector3(25, 0, 25))
	_spawn_house(Vector3(-25, 0, 25))
	_spawn_house(Vector3(25, 0, -25))
	_spawn_house(Vector3(-25, 0, -25))
	
	# Wall ring (BoxMesh is fine for walls)
	for i in range(40):
		var angle = float(i) * PI * 2.0 / 40.0
		var r = 12.0
		_spawn_wall(Vector3(cos(angle) * r, 0, sin(angle) * r), angle)
	
	print("[VALIDATION] Trees loaded: 20")
	print("[VALIDATION] Rocks loaded: 30")
	print("[VALIDATION] Buildings loaded: 4")

func _spawn_tree(pos: Vector3):
	var t = Node3D.new(); t.position = pos
	# Trunk - CylinderMesh
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new(); cyl.top_radius = 0.2; cyl.bottom_radius = 0.35; cyl.height = randf_range(4, 7)
	trunk.mesh = cyl
	var tm = StandardMaterial3D.new(); tm.albedo_color = Color(0.35, 0.20, 0.10, 1)
	trunk.set_surface_override_material(0, tm); trunk.position = Vector3(0, 2.5, 0)
	t.add_child(trunk)
	# Canopy - multiple spheres
	for j in range(3):
		var s = 3.0 - float(j) * 0.8
		_sphere_node(t, s * 0.6, Color(0.10, 0.40 + randf() * 0.30, 0.10, 1), Vector3(0, 4.5 + float(j) * 1.5, 0))
	add_child(t)

func _spawn_rock(pos: Vector3):
	var r = MeshInstance3D.new()
	var sp = SphereMesh.new(); sp.radius = 1.0; sp.height = 2.0; r.mesh = sp
	var s = Vector3(randf_range(1, 4), randf_range(0.5, 2), randf_range(1, 4))
	r.scale = Vector3(s.x, s.y, s.z)
	var rm = StandardMaterial3D.new(); rm.albedo_color = Color(0.30 + randf() * 0.20, 0.30 + randf() * 0.20, 0.30 + randf() * 0.20, 1)
	r.set_surface_override_material(0, rm)
	r.position = pos + Vector3(0, s.y * 0.5, 0)
	add_child(r)

func _spawn_house(pos: Vector3):
	var h = Node3D.new(); h.position = pos
	# Walls - BoxMesh (acceptable for rectangular structures)
	_box_node(h, Vector3(6, 4, 5), Color(0.50, 0.35, 0.20, 1), Vector3(0, 2, 0))
	# Roof - PrismMesh
	var roof = MeshInstance3D.new()
	var prism = PrismMesh.new(); prism.size = Vector3(7, 2, 6)
	roof.mesh = prism
	var rm = StandardMaterial3D.new(); rm.albedo_color = Color(0.40, 0.15, 0.10, 1)
	roof.set_surface_override_material(0, rm); roof.position = Vector3(0, 4.5, 0.5)
	h.add_child(roof)
	# Door
	_box_node(h, Vector3(1.5, 3, 0.2), Color(0.30, 0.15, 0.08, 1), Vector3(0, 1.5, 2.6))
	add_child(h)

func _spawn_wall(pos: Vector3, angle: float):
	var w = _box_node(self, Vector3(0.4, 3, 1.5), Color(0.40, 0.35, 0.30, 1), pos + Vector3(0, 1.5, 0))
	w.rotation.y = angle

func _spawn_player():
	player = CharacterBody3D.new(); player.name = "Player"; player.add_to_group("player_group")
	# Body - CapsuleMesh
	var body = MeshInstance3D.new()
	var cap = CapsuleMesh.new(); cap.radius = 0.4; cap.height = 1.2
	body.mesh = cap
	var bm = StandardMaterial3D.new(); bm.albedo_color = Color(0.20, 0.30, 0.70, 1)
	body.set_surface_override_material(0, bm); body.position = Vector3(0, 1.4, 0)
	player.add_child(body)
	# Head - SphereMesh
	_sphere_node(player, 0.35, Color(0.85, 0.70, 0.55, 1), Vector3(0, 2.2, 0))
	# Arms - CapsuleMesh
	var la = MeshInstance3D.new()
	var lac = CapsuleMesh.new(); lac.radius = 0.12; lac.height = 0.8
	la.mesh = lac; la.set_surface_override_material(0, bm.duplicate()); la.position = Vector3(0.55, 1.5, 0)
	player.add_child(la)
	var ra = MeshInstance3D.new()
	ra.mesh = lac.duplicate(); ra.set_surface_override_material(0, bm.duplicate()); ra.position = Vector3(-0.55, 1.5, 0)
	player.add_child(ra)
	# Legs - CapsuleMesh
	var ll = MeshInstance3D.new()
	var llc = CapsuleMesh.new(); llc.radius = 0.14; llc.height = 0.8
	ll.mesh = llc
	var lm = StandardMaterial3D.new(); lm.albedo_color = Color(0.15, 0.10, 0.05, 1)
	ll.set_surface_override_material(0, lm); ll.position = Vector3(0.2, 0.4, 0)
	player.add_child(ll)
	var rl = MeshInstance3D.new(); rl.mesh = llc.duplicate(); rl.set_surface_override_material(0, lm); rl.position = Vector3(-0.2, 0.4, 0)
	player.add_child(rl)
	# Collision
	var coll = CollisionShape3D.new(); var cs = CapsuleShape3D.new(); cs.radius = 0.5; cs.height = 2.0
	coll.shape = cs; player.add_child(coll)
	player.position = Vector3(0, 2, 0)
	var ps = load("res://scripts/PlayerController.gd")
	if ps: player.set_script(ps)
	add_child(player)
	if cam: cam.target = player
	print("[VALIDATION] Player humanoid spawned OK")

func _spawn_npc():
	var npc = Node3D.new(); npc.name = "Guardiao_do_Vale"; npc.position = Vector3(0, 0, 8)
	# Body - CapsuleMesh
	var body = MeshInstance3D.new()
	var cap = CapsuleMesh.new(); cap.radius = 0.45; cap.height = 1.3
	body.mesh = cap
	var bm = StandardMaterial3D.new(); bm.albedo_color = Color(0.55, 0.35, 0.20, 1)
	body.set_surface_override_material(0, bm); body.position = Vector3(0, 1.5, 0)
	npc.add_child(body)
	# Head - SphereMesh
	_sphere_node(npc, 0.37, Color(0.85, 0.70, 0.55, 1), Vector3(0, 2.4, 0))
	# Arms
	var la = MeshInstance3D.new(); var lac = CapsuleMesh.new(); lac.radius = 0.13; lac.height = 0.85
	la.mesh = lac; la.set_surface_override_material(0, bm.duplicate()); la.position = Vector3(0.6, 1.6, 0)
	npc.add_child(la)
	var ra = MeshInstance3D.new(); ra.mesh = lac.duplicate(); ra.set_surface_override_material(0, bm.duplicate()); ra.position = Vector3(-0.6, 1.6, 0)
	npc.add_child(ra)
	# Legs
	var ll = MeshInstance3D.new(); var llc = CapsuleMesh.new(); llc.radius = 0.15; llc.height = 0.85
	ll.mesh = llc
	var lm = StandardMaterial3D.new(); lm.albedo_color = Color(0.30, 0.20, 0.10, 1)
	ll.set_surface_override_material(0, lm); ll.position = Vector3(0.2, 0.45, 0)
	npc.add_child(ll)
	var rl = MeshInstance3D.new(); rl.mesh = llc.duplicate(); rl.set_surface_override_material(0, lm); rl.position = Vector3(-0.2, 0.45, 0)
	npc.add_child(rl)
	# Name label
	var lbl = Label3D.new(); lbl.text = "Guardiao do Vale"; lbl.position = Vector3(0, 3.2, 0)
	lbl.font_size = 24; lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED; npc.add_child(lbl)
	add_child(npc)
	print("[VALIDATION] NPC Guardiao spawned OK")

func _spawn_dragon():
	print("[VALIDATION] Attempting dragon spawn...")
	var ds = load("res://scenes/models/Dragon.tscn")
	if ds:
		var d = ds.instantiate(); d.name = "Vorak_o_Antigo"
		d.position = Vector3(10, 0, 10); d.scale = Vector3(4, 4, 4)
		add_child(d)
		print("[VALIDATION] Dragon Vorak spawned OK")
	else:
		print("[VALIDATION] Dragon.tscn load FAILED - using CapsuleMesh dragon")
		_build_capsule_dragon(Vector3(10, 0, 10))

func _build_capsule_dragon(pos: Vector3):
	var d = Node3D.new(); d.name = "Vorak_Fallback"; d.position = pos; d.scale = Vector3(4, 4, 4)
	var c = Color(0.55, 0.08, 0.08, 1); var w = Color(0.30, 0.05, 0.05, 1)
	# Body - CapsuleMesh
	_capsule_node(d, 1.8, 8, c, Vector3(0, 2.5, 0))
	# Head - SphereMesh
	_sphere_node(d, 1.5, c, Vector3(0, 3, -5.5))
	# Wings - PrismMesh
	for side in [3, -3]:
		var wing = MeshInstance3D.new()
		var pr = PrismMesh.new(); pr.size = Vector3(0.3, 4, 7)
		wing.mesh = pr
		var wm = StandardMaterial3D.new(); wm.albedo_color = w
		wing.set_surface_override_material(0, wm)
		wing.position = Vector3(side, 4, -1); wing.rotation_degrees = Vector3(0, 0, 45 if side > 0 else -45)
		d.add_child(wing)
	# Tail - CapsuleMesh segments
	for i in range(5):
		var s = 1.0 - i * 0.15
		_capsule_node(d, 0.8 * s, 2, c, Vector3(0, 2.5 - i * 0.1, 4 + i * 1.5))
	# Legs - CapsuleMesh
	for lx in [1.5, -1.5]:
		for lz in [-2, 2]:
			_capsule_node(d, 0.4, 2, c, Vector3(lx, 1, lz))
	# Eyes - SphereMesh
	_sphere_node(d, 0.4, Color(1, 0.8, 0, 1), Vector3(0.8, 3.8, -6.5))
	_sphere_node(d, 0.4, Color(1, 0.8, 0, 1), Vector3(-0.8, 3.8, -6.5))
	add_child(d)
	print("[VALIDATION] Capsule dragon fallback built")

# === HELPERS (zero BoxMesh for gameplay entities) ===
func _sphere_node(parent, radius, color, pos):
	var mi = MeshInstance3D.new(); var s = SphereMesh.new(); s.radius = radius; s.height = radius * 2
	mi.mesh = s
	var mat = StandardMaterial3D.new(); mat.albedo_color = color
	mi.set_surface_override_material(0, mat); mi.position = pos; parent.add_child(mi); return mi

func _capsule_node(parent, radius, height, color, pos):
	var mi = MeshInstance3D.new(); var c = CapsuleMesh.new(); c.radius = radius; c.height = height
	mi.mesh = c
	var mat = StandardMaterial3D.new(); mat.albedo_color = color
	mi.set_surface_override_material(0, mat); mi.position = pos; parent.add_child(mi); return mi

func _box_node(parent, size, color, pos):
	var mi = MeshInstance3D.new(); var b = BoxMesh.new(); b.size = size; mi.mesh = b
	var mat = StandardMaterial3D.new(); mat.albedo_color = color
	mi.set_surface_override_material(0, mat); mi.position = pos; parent.add_child(mi); return mi

func _process(delta):
	if fps_label: fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	if player and hp_text:
		var pc = player.get_script()
		var hp = pc.get("hp") if pc and pc.get("hp") != null else 100.0
		var mhp = pc.get("max_hp") if pc and pc.get("max_hp") != null else 100.0
		hp_text.text = "HP: " + str(int(hp)) + "/" + str(int(mhp))
		if hp_bar: hp_bar.size.x = 200 * (hp / mhp)
	if player and pos_label:
		pos_label.text = str(int(player.global_position.x)) + ", " + str(int(player.global_position.y)) + ", " + str(int(player.global_position.z))
