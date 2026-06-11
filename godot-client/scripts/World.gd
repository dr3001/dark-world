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
	
	_spawn_player()
	_spawn_world_objects()
	_spawn_npcs()
	_spawn_torches()
	_spawn_dragon()
	_build_castle()
	
	print("[WORLD] DONE - Trees:", tree_count, " Rocks:", rock_count, " Houses:", house_count, " NPCs:", npc_count, " Dragons:", dragon_count)

func _spawn_player():
	player = CharacterBody3D.new()
	player.name = "Hero"
	player.add_to_group("player_group")
	
	# Body - blue tunic
	var body = MeshInstance3D.new()
	var cap = CapsuleMesh.new(); cap.radius = 0.45; cap.height = 1.2
	body.mesh = cap
	var bm = StandardMaterial3D.new(); bm.albedo_color = Color(0.15, 0.25, 0.65, 1)
	body.set_surface_override_material(0, bm); body.position = Vector3(0, 1.4, 0)
	player.add_child(body)
	# Head - skin color
	_sphere_on(player, 0.35, Color(0.85, 0.70, 0.55, 1), Vector3(0, 2.2, 0))
	# Arms - same blue
	var arm = CapsuleMesh.new(); arm.radius = 0.12; arm.height = 0.8
	var la = MeshInstance3D.new(); la.mesh = arm; la.set_surface_override_material(0, bm.duplicate()); la.position = Vector3(0.55, 1.5, 0)
	player.add_child(la)
	var ra = MeshInstance3D.new(); ra.mesh = arm.duplicate(); ra.set_surface_override_material(0, bm.duplicate()); ra.position = Vector3(-0.55, 1.5, 0)
	player.add_child(ra)
	# Legs - brown pants
	var leg = CapsuleMesh.new(); leg.radius = 0.14; leg.height = 0.8
	var lm = StandardMaterial3D.new(); lm.albedo_color = Color(0.15, 0.10, 0.05, 1)
	var ll = MeshInstance3D.new(); ll.mesh = leg; ll.set_surface_override_material(0, lm); ll.position = Vector3(0.2, 0.4, 0)
	player.add_child(ll)
	var rl = MeshInstance3D.new(); rl.mesh = leg.duplicate(); rl.set_surface_override_material(0, lm); rl.position = Vector3(-0.2, 0.4, 0)
	player.add_child(rl)
	# Collision
	var coll = CollisionShape3D.new()
	var cs = CapsuleShape3D.new(); cs.radius = 0.5; cs.height = 2.2
	coll.shape = cs; player.add_child(coll)
	player.position = Vector3(0, 2, 0)
	
	var ps = load("res://scripts/PlayerController.gd")
	if ps: player.set_script(ps)
	add_child(player)
	if cam: cam.target = player
	print("[WORLD] Player spawned")

func _spawn_world_objects():
	# 100 trees - distributed in a 600m radius around spawn, denser near center
	for i in range(100):
		var angle = float(i) * PI * 2.0 / 20.0 + randf_range(-0.5, 0.5)
		var r = randf_range(15, 300)
		var pos = Vector3(cos(angle) * r, 0, sin(angle) * r)
		if pos.length() < 12: continue
		_spawn_tree(pos)
		tree_count += 1
	
	# 50 rocks
	for i in range(50):
		var pos = Vector3(randf_range(-300, 300), 0, randf_range(-300, 300))
		if pos.length() < 8: continue
		_spawn_rock(pos)
		rock_count += 1
	
	# 20 houses in a wider ring
	for i in range(20):
		var angle = float(i) * PI * 2.0 / 20.0 + randf_range(-0.2, 0.2)
		var r = randf_range(40, 280)
		var pos = Vector3(cos(angle) * r, 0, sin(angle) * r)
		if pos.length() < 25: continue
		_spawn_house(pos)
		house_count += 1
	
	# Central plaza - large flat area at origin
	var plaza = MeshInstance3D.new()
	var pm = PlaneMesh.new(); pm.size = Vector2(40, 40)
	plaza.mesh = pm
	var pmat = StandardMaterial3D.new(); pmat.albedo_color = Color(0.50, 0.45, 0.38, 1)
	plaza.set_surface_override_material(0, pmat); plaza.position = Vector3(0, 0.02, 0)
	add_child(plaza)

func _spawn_tree(pos: Vector3):
	var t = Node3D.new(); t.position = pos
	# Trunk - thicker, taller
	var trunk = MeshInstance3D.new()
	var cyl = CylinderMesh.new(); cyl.top_radius = 0.22; cyl.bottom_radius = 0.4; cyl.height = randf_range(5, 10)
	trunk.mesh = cyl
	var tm = StandardMaterial3D.new(); tm.albedo_color = Color(0.35, 0.20, 0.10, 1)
	trunk.set_surface_override_material(0, tm); trunk.position = Vector3(0, 3, 0)
	t.add_child(trunk)
	# Canopy - bigger spheres
	for j in range(4):
		var s = 4.0 - float(j) * 0.8
		_sphere_on(t, s * 0.55, Color(0.06, 0.35 + randf() * 0.30, 0.06, 1), Vector3(randf_range(-0.5, 0.5), 5.5 + float(j) * 1.8, randf_range(-0.5, 0.5)))
	add_child(t)

func _spawn_rock(pos: Vector3):
	var r = MeshInstance3D.new()
	var sp = SphereMesh.new(); sp.radius = 1.0; sp.height = 2.0; r.mesh = sp
	var s = Vector3(randf_range(1.5, 6), randf_range(0.8, 3), randf_range(1.5, 6))
	r.scale = s
	var rm = StandardMaterial3D.new(); rm.albedo_color = Color(0.30 + randf() * 0.18, 0.30 + randf() * 0.18, 0.28 + randf() * 0.18, 1)
	r.set_surface_override_material(0, rm)
	r.position = pos + Vector3(0, s.y * 0.4, 0)
	add_child(r)

func _spawn_house(pos: Vector3):
	var h = Node3D.new(); h.position = pos
	# Walls
	var w = MeshInstance3D.new(); var wb = BoxMesh.new(); wb.size = Vector3(7, 5, 6); w.mesh = wb
	var wm = StandardMaterial3D.new(); wm.albedo_color = Color(0.45, 0.30, 0.18, 1)
	w.set_surface_override_material(0, wm); w.position = Vector3(0, 2.5, 0); h.add_child(w)
	# Roof
	var roof = MeshInstance3D.new()
	var prism = PrismMesh.new(); prism.size = Vector3(8, 3, 7)
	roof.mesh = prism
	var rm = StandardMaterial3D.new(); rm.albedo_color = Color(0.38, 0.14, 0.08, 1)
	roof.set_surface_override_material(0, rm); roof.position = Vector3(0, 5.5, 0.5); h.add_child(roof)
	# Door
	var d = MeshInstance3D.new(); var db = BoxMesh.new(); db.size = Vector3(1.8, 3.5, 0.2); d.mesh = db
	var dm = StandardMaterial3D.new(); dm.albedo_color = Color(0.25, 0.12, 0.06, 1)
	d.set_surface_override_material(0, dm); d.position = Vector3(0, 1.8, 3.1); h.add_child(d)
	add_child(h)

func _spawn_torches():
	# 10 torches around the plaza
	for i in range(10):
		var angle = float(i) * PI * 2.0 / 10.0
		var r = 16.0
		var pos = Vector3(cos(angle) * r, 0, sin(angle) * r)
		var torch = Node3D.new(); torch.position = pos
		# Pole
		_capsule(torch, 0.15, 4, Color(0.25, 0.18, 0.10, 1), Vector3(0, 2, 0))
		# Flame glow
		var flame = MeshInstance3D.new()
		var fs = SphereMesh.new(); fs.radius = 0.5; fs.height = 1.0; flame.mesh = fs
		var fm = StandardMaterial3D.new(); fm.albedo_color = Color(1, 0.6, 0.1, 1)
		fm.emission_enabled = true; fm.emission = Color(1, 0.5, 0)
		fm.emission_energy_multiplier = 2.0
		flame.set_surface_override_material(0, fm)
		flame.position = Vector3(0, 4.5, 0)
		torch.add_child(flame)
		add_child(torch)

func _spawn_npcs():
	var names = ["Capitao Aldric", "Sentinela Bjorn", "Sentinela Cedric", "Guarda Dorian", "Guarda Elric", "Aldeao Finn", "Aldeao Greta", "Aldeao Hugo", "Mercador Ivan"]
	var types = ["Guardiao", "Guardiao", "Guardiao", "Guardiao", "Guardiao", "Aldeao", "Aldeao", "Aldeao", "Mercador"]
	var colors = [Color(0.40, 0.35, 0.30, 1), Color(0.38, 0.33, 0.28, 1), Color(0.42, 0.37, 0.32, 1), Color(0.35, 0.30, 0.25, 1), Color(0.40, 0.35, 0.30, 1), Color(0.55, 0.45, 0.30, 1), Color(0.50, 0.40, 0.30, 1), Color(0.55, 0.45, 0.30, 1), Color(0.60, 0.28, 0.12, 1)]
	for i in range(9):
		var pos = Vector3(cos(float(i) * 0.7) * (8 + randf() * 5), 0, sin(float(i) * 0.7) * (8 + randf() * 5)) if i < 5 else Vector3(randf_range(-250, 250), 0, randf_range(-250, 250))
		if i >= 5 and pos.length() < 15: pos = Vector3(randf_range(20, 250), 0, randf_range(20, 250))
		_spawn_npc(pos, names[i], colors[i], types[i])
		npc_count += 1

func _spawn_npc(pos: Vector3, npc_name: String, body_color: Color, npc_type: String):
	var npc = Node3D.new(); npc.name = npc_name.replace(" ", "_"); npc.position = pos
	# Body
	var body = MeshInstance3D.new()
	var cap = CapsuleMesh.new(); cap.radius = 0.45; cap.height = 1.3
	body.mesh = cap
	var bm = StandardMaterial3D.new(); bm.albedo_color = body_color
	body.set_surface_override_material(0, bm); body.position = Vector3(0, 1.5, 0)
	npc.add_child(body)
	# Head
	_sphere_on(npc, 0.37, Color(0.85, 0.70, 0.55, 1), Vector3(0, 2.4, 0))
	# Arms
	var arm = CapsuleMesh.new(); arm.radius = 0.13; arm.height = 0.85
	var la = MeshInstance3D.new(); la.mesh = arm; la.set_surface_override_material(0, bm.duplicate()); la.position = Vector3(0.58, 1.6, 0)
	npc.add_child(la)
	var ra = MeshInstance3D.new(); ra.mesh = arm.duplicate(); ra.set_surface_override_material(0, bm.duplicate()); ra.position = Vector3(-0.58, 1.6, 0)
	npc.add_child(ra)
	# Legs
	var leg = CapsuleMesh.new(); leg.radius = 0.15; leg.height = 0.85
	var lm = StandardMaterial3D.new(); lm.albedo_color = Color(0.20, 0.15, 0.10, 1)
	var ll = MeshInstance3D.new(); ll.mesh = leg; ll.set_surface_override_material(0, lm); ll.position = Vector3(0.22, 0.45, 0)
	npc.add_child(ll)
	var rl = MeshInstance3D.new(); rl.mesh = leg.duplicate(); rl.set_surface_override_material(0, lm); rl.position = Vector3(-0.22, 0.45, 0)
	npc.add_child(rl)
	# Label
	var lbl = Label3D.new()
	lbl.text = npc_name + "\n" + npc_type + " | HP: 50"
	lbl.position = Vector3(0, 3.2, 0)
	lbl.font_size = 26
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = Color(1, 0.9, 0.5, 1)
	npc.add_child(lbl)
	add_child(npc)

func _spawn_dragon():
	var pos = Vector3(20, 0, 0)
	var dragon_path = "res://assets/quaternius/creatures/Ultimate Monsters/Big/glTF/BlueDemon.gltf"
	var ds = load(dragon_path)
	if ds:
		var d = ds.instantiate()
		d.name = "Vorak_o_Antigo"
		d.position = pos
		d.scale = Vector3(6, 6, 6)
		# Rotate to face player
		d.rotation_degrees = Vector3(0, 90, 0)
		add_child(d)
		dragon_count += 1
		# HP Label
		var lbl = Label3D.new()
		lbl.text = "VORAK, O ANTIGO\nHP: 100"
		lbl.position = Vector3(0, 8, 0)
		lbl.font_size = 40
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.modulate = Color(1, 0.2, 0.2, 1)
		d.add_child(lbl)
		print("[WORLD] Dragon: BlueDemon.gltf")
	else:
		print("[WORLD] GLTF failed, fallback...")
		_build_fallback_dragon(pos)
		dragon_count += 1

func _build_castle():
	var c = Node3D.new(); c.name = "Castelo"; c.position = Vector3(-50, 0, 50)
	var stone = Color(0.50, 0.48, 0.45, 1)
	# Main keep
	_box_on(c, Vector3(12, 15, 12), stone, Vector3(0, 7.5, 0))
	# Towers
	for cx in [-8, 8]:
		for cz in [-8, 8]:
			_box_on(c, Vector3(4, 18, 4), Color(0.45, 0.43, 0.40, 1), Vector3(cx, 9, cz))
			# Roof cone
			var roof = MeshInstance3D.new()
			var pr = PrismMesh.new(); pr.size = Vector3(4.5, 4, 4.5)
			roof.mesh = pr
			var rm = StandardMaterial3D.new(); rm.albedo_color = Color(0.35, 0.12, 0.08, 1)
			roof.set_surface_override_material(0, rm)
			roof.position = Vector3(cx, 18.5, cz)
			c.add_child(roof)
	# Gate
	_box_on(c, Vector3(5, 8, 1), Color(0.35, 0.30, 0.25, 1), Vector3(0, 4, 6.5))
	# Walls
	for i in range(20):
		var angle = float(i) * PI * 2.0 / 20.0
		var r = 16.0
		var w = _box_on(c, Vector3(1, 6, 3), stone, Vector3(cos(angle) * r, 3, sin(angle) * r))
		w.rotation.y = angle
	add_child(c)

func _build_fallback_dragon(pos: Vector3):
	var d = Node3D.new(); d.name = "Vorak_Fallback"; d.position = pos; d.scale = Vector3(6, 6, 6); d.rotation_degrees = Vector3(0, 90, 0)
	var c = Color(0.55, 0.08, 0.08, 1)
	_capsule(d, 1.6, 7, c, Vector3(0, 2.5, 0))
	_sphere_on(d, 1.4, c, Vector3(0, 3.0, -4.5))
	_capsule(d, 0.8, 3, c, Vector3(0, 3.5, -2.5))
	for side in [3, -3]:
		var wing = MeshInstance3D.new(); var pr = PrismMesh.new(); pr.size = Vector3(0.3, 5, 7)
		wing.mesh = pr; wing.set_surface_override_material(0, _mat(Color(0.30, 0.05, 0.05, 1)))
		wing.position = Vector3(side, 4.5, -1); wing.rotation_degrees = Vector3(0, 0, 45 if side > 0 else -45)
		d.add_child(wing)
	for i in range(6):
		var s = 1.0 - i * 0.14
		_capsule(d, 0.7 * s, 2, c, Vector3(0, 2.5, 4 + i * 1.5))
	for lx in [1.5, -1.5]:
		for lz in [-2, 2]:
			_capsule(d, 0.4, 2.5, c, Vector3(lx, 1.2, lz))
	_sphere_on(d, 0.4, Color(1, 0.8, 0, 1), Vector3(0.7, 3.8, -5.5))
	_sphere_on(d, 0.4, Color(1, 0.8, 0, 1), Vector3(-0.7, 3.8, -5.5))
	var lbl = Label3D.new()
	lbl.text = "VORAK, O ANTIGO\nHP: 100"
	lbl.position = Vector3(0, 12, 0); lbl.font_size = 40
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lbl.modulate = Color(1, 0.2, 0.2, 1)
	d.add_child(lbl)
	add_child(d)

# Helpers
func _mat(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_color = color; return m

func _sphere_on(parent, radius, color, pos):
	var mi = MeshInstance3D.new(); var s = SphereMesh.new(); s.radius = radius; s.height = radius * 2
	mi.mesh = s
	mi.set_surface_override_material(0, _mat(color))
	mi.position = pos; parent.add_child(mi)

func _capsule(parent, radius, height, color, pos):
	var mi = MeshInstance3D.new(); var c = CapsuleMesh.new(); c.radius = radius; c.height = height
	mi.mesh = c
	mi.set_surface_override_material(0, _mat(color))
	mi.position = pos; parent.add_child(mi)

func _box_on(parent, size, color, pos):
	var mi = MeshInstance3D.new(); var b = BoxMesh.new(); b.size = size; mi.mesh = b
	mi.set_surface_override_material(0, _mat(color))
	mi.position = pos; parent.add_child(mi); return mi

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
