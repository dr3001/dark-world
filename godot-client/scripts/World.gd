extends Node3D

var player: CharacterBody3D
var hp_bar: ColorRect
var hp_text: Label
var fps_label: Label
var quest_text: Label
var pos_label: Label
var obj_label: Label
var cam: Camera3D
var tree_count: int = 0
var rock_count: int = 0
var house_count: int = 0
var npc_count: int = 0
var dragon_count: int = 0

func _ready():
	print("[WORLD] START")
	hp_bar = get_node_or_null("HUD/HPBar")
	hp_text = get_node_or_null("HUD/HPText")
	fps_label = get_node_or_null("HUD/FPS")
	quest_text = get_node_or_null("HUD/QuestText")
	pos_label = get_node_or_null("HUD/Position")
	obj_label = get_node_or_null("HUD/ObjectCount")
	cam = $Camera3D
	
	_build_terrain()
	_spawn_player()
	_spawn_world_objects()
	_spawn_npcs()
	_spawn_dragon()
	
	print("[WORLD] DONE - Trees:", tree_count, " Rocks:", rock_count, " Houses:", house_count, " NPCs:", npc_count, " Dragons:", dragon_count)

func _build_terrain():
	pass  # Ground plane from World.tscn handles terrain

func _spawn_player():
	player = CharacterBody3D.new()
	player.name = "Hero"
	player.add_to_group("player_group")
	
	# Body
	var body = MeshInstance3D.new()
	var cap = CapsuleMesh.new(); cap.radius = 0.4; cap.height = 1.1
	body.mesh = cap
	var bm = StandardMaterial3D.new(); bm.albedo_color = Color(0.15, 0.25, 0.60, 1)
	body.set_surface_override_material(0, bm); body.position = Vector3(0, 1.3, 0)
	player.add_child(body)
	# Head
	_sphere_on(player, 0.33, Color(0.85, 0.70, 0.55, 1), Vector3(0, 2.1, 0))
	# Arms
	var arm = CapsuleMesh.new(); arm.radius = 0.11; arm.height = 0.75
	var la = MeshInstance3D.new(); la.mesh = arm; la.set_surface_override_material(0, bm.duplicate()); la.position = Vector3(0.52, 1.4, 0)
	player.add_child(la)
	var ra = MeshInstance3D.new(); ra.mesh = arm.duplicate(); ra.set_surface_override_material(0, bm.duplicate()); ra.position = Vector3(-0.52, 1.4, 0)
	player.add_child(ra)
	# Legs
	var leg = CapsuleMesh.new(); leg.radius = 0.13; leg.height = 0.75
	var lm = StandardMaterial3D.new(); lm.albedo_color = Color(0.12, 0.08, 0.04, 1)
	var ll = MeshInstance3D.new(); ll.mesh = leg; ll.set_surface_override_material(0, lm); ll.position = Vector3(0.18, 0.35, 0)
	player.add_child(ll)
	var rl = MeshInstance3D.new(); rl.mesh = leg.duplicate(); rl.set_surface_override_material(0, lm); rl.position = Vector3(-0.18, 0.35, 0)
	player.add_child(rl)
	# Collision
	var coll = CollisionShape3D.new()
	var cs = CapsuleShape3D.new(); cs.radius = 0.5; cs.height = 2.0
	coll.shape = cs; player.add_child(coll)
	player.position = Vector3(0, 2, 0)
	
	var ps = load("res://scripts/PlayerController.gd")
	if ps: player.set_script(ps)
	add_child(player)
	if cam: cam.target = player
	print("[WORLD] Player spawned")

func _spawn_world_objects():
	# 100 trees
	for i in range(100):
		var pos = Vector3(randf_range(-400, 400), 0, randf_range(-400, 400))
		if pos.length() < 10: continue
		_spawn_tree(pos)
		tree_count += 1
	# 50 rocks
	for i in range(50):
		var pos = Vector3(randf_range(-400, 400), 0, randf_range(-400, 400))
		if pos.length() < 8: continue
		_spawn_rock(pos)
		rock_count += 1
	# 20 houses
	for i in range(20):
		var angle = float(i) * PI * 2.0 / 20.0
		var r = randf_range(30, 350)
		var pos = Vector3(cos(angle) * r, 0, sin(angle) * r)
		if pos.length() < 20: continue
		_spawn_house(pos)
		house_count += 1
	# Central plaza (flat area at origin)
	var plaza = MeshInstance3D.new()
	var plaza_mesh = PlaneMesh.new(); plaza_mesh.size = Vector2(30, 30)
	plaza.mesh = plaza_mesh
	var plaza_mat = StandardMaterial3D.new(); plaza_mat.albedo_color = Color(0.45, 0.40, 0.35, 1)
	plaza.set_surface_override_material(0, plaza_mat); plaza.position = Vector3(0, 0.01, 0)
	add_child(plaza)

func _spawn_tree(pos: Vector3):
	var t = Node3D.new(); t.position = pos
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new(); cyl.top_radius = 0.18; cyl.bottom_radius = 0.3; cyl.height = randf_range(4, 8)
	trunk.mesh = cyl
	var tm = StandardMaterial3D.new(); tm.albedo_color = Color(0.35, 0.20, 0.10, 1)
	trunk.set_surface_override_material(0, tm); trunk.position = Vector3(0, 2.5, 0)
	t.add_child(trunk)
	for j in range(3):
		var s = 3.0 - float(j) * 0.7
		_sphere_on(t, s * 0.55, Color(0.08, 0.35 + randf() * 0.25, 0.08, 1), Vector3(0, 4.5 + float(j) * 1.5, 0))
	add_child(t)

func _spawn_rock(pos: Vector3):
	var r = MeshInstance3D.new()
	var sp = SphereMesh.new(); sp.radius = 1.0; sp.height = 2.0; r.mesh = sp
	var s = Vector3(randf_range(1, 5), randf_range(0.5, 2.5), randf_range(1, 5))
	r.scale = s
	var rm = StandardMaterial3D.new(); rm.albedo_color = Color(0.30 + randf() * 0.15, 0.30 + randf() * 0.15, 0.28 + randf() * 0.15, 1)
	r.set_surface_override_material(0, rm)
	r.position = pos + Vector3(0, s.y * 0.4, 0)
	add_child(r)

func _spawn_house(pos: Vector3):
	var h = Node3D.new(); h.position = pos
	# Walls
	var w = MeshInstance3D.new(); var wb = BoxMesh.new(); wb.size = Vector3(6, 4, 5); w.mesh = wb
	var wm = StandardMaterial3D.new(); wm.albedo_color = Color(0.45, 0.30, 0.18, 1)
	w.set_surface_override_material(0, wm); w.position = Vector3(0, 2, 0); h.add_child(w)
	# Roof
	var roof = MeshInstance3D.new()
	var prism = PrismMesh.new(); prism.size = Vector3(7, 2.5, 6)
	roof.mesh = prism
	var rm = StandardMaterial3D.new(); rm.albedo_color = Color(0.35, 0.12, 0.08, 1)
	roof.set_surface_override_material(0, rm); roof.position = Vector3(0, 4.7, 0.5); h.add_child(roof)
	# Door
	var d = MeshInstance3D.new(); var db = BoxMesh.new(); db.size = Vector3(1.5, 3, 0.2); d.mesh = db
	var dm = StandardMaterial3D.new(); dm.albedo_color = Color(0.25, 0.12, 0.06, 1)
	d.set_surface_override_material(0, dm); d.position = Vector3(0, 1.5, 2.6); h.add_child(d)
	add_child(h)

func _spawn_npcs():
	# 5 guards
	var guard_names = ["Capitão Aldric", "Sentinela Bjorn", "Sentinela Cedric", "Guarda Dorian", "Guarda Elric"]
	for i in range(5):
		var angle = float(i) * PI * 2.0 / 5.0 + randf() * 0.3
		var pos = Vector3(cos(angle) * 12, 0, sin(angle) * 12)
		_spawn_npc(pos, guard_names[i], Color(0.40, 0.35, 0.30, 1), "Guardiao")
		npc_count += 1
	# 3 villagers
	var villager_names = ["Aldeao Finn", "Aldeao Greta", "Aldeao Hugo"]
	for i in range(3):
		var pos = Vector3(randf_range(-350, 350), 0, randf_range(-350, 350))
		if pos.length() < 15: continue
		_spawn_npc(pos, villager_names[i], Color(0.60, 0.50, 0.35, 1), "Aldeao")
		npc_count += 1
	# 1 merchant
	_spawn_npc(Vector3(5, 0, -10), "Mercador Ivan", Color(0.65, 0.30, 0.15, 1), "Mercador")
	npc_count += 1

func _spawn_npc(pos: Vector3, npc_name: String, body_color: Color, npc_type: String):
	var npc = Node3D.new(); npc.name = npc_name.replace(" ", "_"); npc.position = pos
	# Body
	var body = MeshInstance3D.new()
	var cap = CapsuleMesh.new(); cap.radius = 0.42; cap.height = 1.2
	body.mesh = cap
	var bm = StandardMaterial3D.new(); bm.albedo_color = body_color
	body.set_surface_override_material(0, bm); body.position = Vector3(0, 1.4, 0)
	npc.add_child(body)
	# Head
	_sphere_on(npc, 0.35, Color(0.85, 0.70, 0.55, 1), Vector3(0, 2.3, 0))
	# Arms
	var arm = CapsuleMesh.new(); arm.radius = 0.12; arm.height = 0.8
	var la = MeshInstance3D.new(); la.mesh = arm; la.set_surface_override_material(0, bm.duplicate()); la.position = Vector3(0.55, 1.5, 0)
	npc.add_child(la)
	var ra = MeshInstance3D.new(); ra.mesh = arm.duplicate(); ra.set_surface_override_material(0, bm.duplicate()); ra.position = Vector3(-0.55, 1.5, 0)
	npc.add_child(ra)
	# Legs
	var leg = CapsuleMesh.new(); leg.radius = 0.14; leg.height = 0.8
	var lm = StandardMaterial3D.new(); lm.albedo_color = Color(0.20, 0.15, 0.10, 1)
	var ll = MeshInstance3D.new(); ll.mesh = leg; ll.set_surface_override_material(0, lm); ll.position = Vector3(0.2, 0.4, 0)
	npc.add_child(ll)
	var rl = MeshInstance3D.new(); rl.mesh = leg.duplicate(); rl.set_surface_override_material(0, lm); rl.position = Vector3(-0.2, 0.4, 0)
	npc.add_child(rl)
	# Name + HP label
	var lbl = Label3D.new()
	lbl.text = npc_name + "\n" + npc_type + " | HP: 50"
	lbl.position = Vector3(0, 3.0, 0)
	lbl.font_size = 22
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(1, 0.9, 0.5, 1)
	npc.add_child(lbl)
	add_child(npc)

func _spawn_dragon():
	var pos = Vector3(20, 0, 20)
	var ds = load("res://assets/quaternius/creatures/Ultimate Monsters/Big/glTF/BlueDemon.gltf")
	if ds:
		var d = ds.instantiate()
		d.name = "Vorak_o_Antigo"
		d.position = pos
		d.scale = Vector3(5, 5, 5)
		add_child(d)
		dragon_count += 1
		# Add name label
		var lbl = Label3D.new()
		lbl.text = "VORAK, O ANTIGO\nHP: 100"
		lbl.position = Vector3(0, 15, 0)
		lbl.font_size = 36
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.modulate = Color(1, 0.2, 0.2, 1)
		d.add_child(lbl)
	else:
		_build_fallback_dragon(pos)
		dragon_count += 1

func _build_fallback_dragon(pos: Vector3):
	var d = Node3D.new(); d.name = "Vorak_Fallback"; d.position = pos; d.scale = Vector3(5, 5, 5)
	var c = Color(0.55, 0.08, 0.08, 1)
	# Body
	var body = MeshInstance3D.new(); var bc = CapsuleMesh.new(); bc.radius = 1.6; bc.height = 7
	body.mesh = bc; body.set_surface_override_material(0, _mat(c)); body.position = Vector3(0, 2.5, 0)
	d.add_child(body)
	# Head
	_sphere_on(d, 1.4, c, Vector3(0, 3.0, -4.5))
	# Neck
	var neck = MeshInstance3D.new(); var nc = CapsuleMesh.new(); nc.radius = 0.8; nc.height = 3
	neck.mesh = nc; neck.set_surface_override_material(0, _mat(c)); neck.position = Vector3(0, 3.5, -2.5); neck.rotation_degrees = Vector3(30, 0, 0)
	d.add_child(neck)
	# Wings
	for side in [3, -3]:
		var wing = MeshInstance3D.new(); var pr = PrismMesh.new(); pr.size = Vector3(0.3, 5, 7)
		wing.mesh = pr; wing.set_surface_override_material(0, _mat(Color(0.30, 0.05, 0.05, 1)))
		wing.position = Vector3(side, 4.5, -1); wing.rotation_degrees = Vector3(0, 0, 45 if side > 0 else -45)
		d.add_child(wing)
	# Tail
	for i in range(6):
		var s = 1.0 - i * 0.14
		var t = MeshInstance3D.new(); var tc = CapsuleMesh.new(); tc.radius = 0.7 * s; tc.height = 2
		t.mesh = tc; t.set_surface_override_material(0, _mat(c)); t.position = Vector3(0, 2.5 - i * 0.1, 4 + i * 1.5)
		d.add_child(t)
	# Legs
	for lx in [1.5, -1.5]:
		for lz in [-2, 2]:
			var leg = MeshInstance3D.new(); var lc = CapsuleMesh.new(); lc.radius = 0.4; lc.height = 2.5
			leg.mesh = lc; leg.set_surface_override_material(0, _mat(c)); leg.position = Vector3(lx, 1.2, lz)
			d.add_child(leg)
	# Eyes
	_sphere_on(d, 0.4, Color(1, 0.8, 0, 1), Vector3(0.7, 3.8, -5.5))
	_sphere_on(d, 0.4, Color(1, 0.8, 0, 1), Vector3(-0.7, 3.8, -5.5))
	# Name label
	var lbl = Label3D.new()
	lbl.text = "VORAK, O ANTIGO\nHP: 100"
	lbl.position = Vector3(0, 12, 0)
	lbl.font_size = 36
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(1, 0.2, 0.2, 1)
	d.add_child(lbl)
	add_child(d)

func _mat(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_color = color; return m

func _sphere_on(parent, radius, color, pos):
	var mi = MeshInstance3D.new(); var s = SphereMesh.new(); s.radius = radius; s.height = radius * 2
	mi.mesh = s
	var m = StandardMaterial3D.new(); m.albedo_color = color
	mi.set_surface_override_material(0, m); mi.position = pos; parent.add_child(mi)

func _process(delta):
	if fps_label: fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	if obj_label: obj_label.text = "Obj: " + str(get_child_count())
	if player and hp_text:
		var pc = player.get_script()
		var hp = pc.get("hp") if pc and pc.get("hp") != null else 100.0
		var mhp = pc.get("max_hp") if pc and pc.get("max_hp") != null else 100.0
		hp_text.text = "HP: " + str(int(hp)) + "/" + str(int(mhp))
		if hp_bar: hp_bar.size.x = 220 * (hp / mhp)
	if player and pos_label:
		pos_label.text = str(int(player.global_position.x)) + ", " + str(int(player.global_position.y)) + ", " + str(int(player.global_position.z))
