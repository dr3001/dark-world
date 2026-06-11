extends Node3D

var player: CharacterBody3D
var cam: Camera3D
var hp_bar: ColorRect; var hp_text: Label; var fps_label: Label
var quest_text: Label; var pos_label: Label; var obj_label: Label
var tree_count: int = 0; var house_count: int = 0; var npc_count: int = 0; var dragon_count: int = 0

func _ready():
	print("[WORLD] START")
	hp_bar = get_node_or_null("HUD/HPBar"); hp_text = get_node_or_null("HUD/HPText")
	fps_label = get_node_or_null("HUD/FPS"); quest_text = get_node_or_null("HUD/QuestText")
	pos_label = get_node_or_null("HUD/Position"); obj_label = get_node_or_null("HUD/ObjectCount")
	cam = $Camera3D
	
	_build_plaza()
	_spawn_player()
	_build_village()
	_build_walls()
	_build_rocks()
	_spawn_npcs()
	_build_castle()
	_spawn_dragon()
	_build_trees()
	_build_road_torches()
	
	print("[WORLD] DONE - Trees:", tree_count, " Houses:", house_count, " NPCs:", npc_count, " Dragons:", dragon_count)
	_log("Vale Cinzento — " + str(get_child_count()) + " objetos carregados")

# ===== PLAZA =====
func _build_plaza():
	# Stone plaza floor
	_plane(Vector3(0, 0.01, 0), Vector2(35, 35), Color(0.50, 0.46, 0.40, 1))
	# Inner circle
	_plane(Vector3(0, 0.02, 0), Vector2(18, 18), Color(0.55, 0.50, 0.43, 1))
	# Fountain center
	_fountain(Vector3(0, 0, 0))
	# 4 torches around fountain
	for i in range(4):
		var a = float(i) * PI / 2.0 + PI / 4.0
		_torch(Vector3(cos(a) * 5, 0, sin(a) * 5))
	# 8 trees around plaza
	for i in range(8):
		var a = float(i) * PI * 2.0 / 8.0
		_tree(Vector3(cos(a) * 15, 0, sin(a) * 15), 1.3)
	# 4 benches
	for i in range(4):
		var a = float(i) * PI / 2.0
		_bench(Vector3(cos(a) * 8, 0, sin(a) * 8), a + PI / 2.0)

func _fountain(pos: Vector3):
	var f = Node3D.new(); f.position = pos
	_cyl(f, 3.5, 0.4, Color(0.55, 0.52, 0.48, 1), Vector3(0, 0.2, 0))
	var sb = StaticBody3D.new(); sb.position = Vector3(0, 0.2, 0)
	var col = CollisionShape3D.new(); var cs = CylinderShape3D.new(); cs.radius = 3.5; cs.height = 0.8
	col.shape = cs; sb.add_child(col); f.add_child(sb)
	var w = MeshInstance3D.new(); var ds = CylinderMesh.new(); ds.top_radius = 3.0; ds.bottom_radius = 3.0; ds.height = 0.1; w.mesh = ds
	var wm = StandardMaterial3D.new(); wm.albedo_color = Color(0.20, 0.40, 0.70, 0.7); wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	w.set_surface_override_material(0, wm); w.position = Vector3(0, 0.35, 0); f.add_child(w)
	_cyl(f, 0.6, 3.0, Color(0.60, 0.58, 0.55, 1), Vector3(0, 1.7, 0))
	_cyl(f, 1.5, 0.3, Color(0.60, 0.58, 0.55, 1), Vector3(0, 3.2, 0))
	var light = OmniLight3D.new(); light.position = Vector3(0, 3.5, 0)
	light.light_color = Color(0.3, 0.5, 0.9); light.light_energy = 2.0; light.omni_range = 8.0
	f.add_child(light)
	add_child(f)

func _bench(pos: Vector3, angle: float):
	var b = Node3D.new(); b.position = pos; b.rotation.y = angle
	_box_on(b, Vector3(3, 0.3, 0.8), Color(0.35, 0.22, 0.12, 1), Vector3(0, 0.8, 0))
	_box_on(b, Vector3(0.2, 0.6, 0.2), Color(0.30, 0.18, 0.10, 1), Vector3(1.2, 0.4, 0))
	_box_on(b, Vector3(0.2, 0.6, 0.2), Color(0.30, 0.18, 0.10, 1), Vector3(-1.2, 0.4, 0))
	add_child(b)

# ===== PLAYER =====
func _spawn_player():
	player = CharacterBody3D.new(); player.name = "Hero"; player.add_to_group("player_group")
	# Body
	_capsule2(player, 0.45, 1.3, Color(0.15, 0.25, 0.65, 1), Vector3(0, 1.5, 0))
	# Head
	_sphere2(player, 0.35, Color(0.85, 0.70, 0.55, 1), Vector3(0, 2.3, 0))
	# Arms
	_capsule2(player, 0.12, 0.85, Color(0.15, 0.25, 0.65, 1), Vector3(0.55, 1.6, 0))
	_capsule2(player, 0.12, 0.85, Color(0.15, 0.25, 0.65, 1), Vector3(-0.55, 1.6, 0))
	# Legs
	_capsule2(player, 0.14, 0.85, Color(0.12, 0.08, 0.04, 1), Vector3(0.2, 0.45, 0))
	_capsule2(player, 0.14, 0.85, Color(0.12, 0.08, 0.04, 1), Vector3(-0.2, 0.45, 0))
	# Collision
	var c = CollisionShape3D.new(); var cs = CapsuleShape3D.new(); cs.radius = 0.5; cs.height = 2.2
	c.shape = cs; c.position = Vector3(0, 1.1, 0); player.add_child(c)
	player.position = Vector3(0, 3, 0)
	var ps = load("res://scripts/PlayerController.gd")
	if ps: player.set_script(ps)
	add_child(player)
	if cam: cam.target = player

# ===== VILLAGE =====
func _build_village():
	# Main road (north-south)
	_plane(Vector3(0, 0.015, -30), Vector2(6, 80), Color(0.45, 0.40, 0.35, 1))
	_plane(Vector3(0, 0.015, 30), Vector2(6, 80), Color(0.45, 0.40, 0.35, 1))
	
	# 12 houses along roads
	for i in range(12):
		var side = 1 if i % 2 == 0 else -1
		var z = 15 + float(i / 2) * 15
		var x = side * (10 + randf() * 5)
		_house(Vector3(x, 0, z))
		house_count += 1
	
	# 4 houses near plaza
	var plaza_houses = [Vector3(20, 0, 10), Vector3(-20, 0, 10), Vector3(15, 0, -18), Vector3(-15, 0, -18)]
	for hp in plaza_houses:
		_house(hp)
		house_count += 1
	
	# Well
	_well(Vector3(8, 0, -8))
	# Carts
	_cart(Vector3(12, 0, -25))
	_cart(Vector3(-10, 0, 30))

func _house(pos: Vector3):
	var h = Node3D.new(); h.position = pos
	# Walls
	_box_on(h, Vector3(7, 5, 6), Color(0.50 + randf() * 0.1, 0.32 + randf() * 0.1, 0.18 + randf() * 0.1, 1), Vector3(0, 2.5, 0))
	# Collision for walls
	var sb = StaticBody3D.new(); sb.position = Vector3(0, 2.5, 0)
	var col = CollisionShape3D.new(); var bs = BoxShape3D.new(); bs.size = Vector3(7, 5, 6)
	col.shape = bs; sb.add_child(col); h.add_child(sb)
	# Roof
	var roof = MeshInstance3D.new(); var pr = PrismMesh.new(); pr.size = Vector3(8, 2.5, 7)
	roof.mesh = pr
	var rm = StandardMaterial3D.new(); rm.albedo_color = Color(0.40, 0.15, 0.08, 1)
	roof.set_surface_override_material(0, rm); roof.position = Vector3(0, 5.2, 0.5); h.add_child(roof)
	# Door + windows
	_box_on(h, Vector3(1.8, 3.5, 0.2), Color(0.25, 0.12, 0.06, 1), Vector3(0, 1.8, 3.1))
	# Chimney
	_box_on(h, Vector3(0.6, 3, 0.6), Color(0.35, 0.25, 0.18, 1), Vector3(2.5, 4.0, -2))
	_smoke(h, Vector3(2.5, 5.8, -2))
	add_child(h)

func _smoke(parent, pos):
	var s = MeshInstance3D.new()
	var sp = SphereMesh.new(); sp.radius = 0.3; sp.height = 0.6; s.mesh = sp
	var sm = StandardMaterial3D.new(); sm.albedo_color = Color(0.80, 0.80, 0.80, 0.4)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s.set_surface_override_material(0, sm); s.position = pos
	parent.add_child(s)

func _well(pos: Vector3):
	var w = Node3D.new(); w.position = pos
	_cyl(w, 1.5, 3, Color(0.40, 0.35, 0.30, 1), Vector3(0, 1.5, 0))
	var sb = StaticBody3D.new(); sb.position = Vector3(0, 1.5, 0)
	var col = CollisionShape3D.new(); var cs = CylinderShape3D.new(); cs.radius = 1.5; cs.height = 3.0
	col.shape = cs; sb.add_child(col); w.add_child(sb)
	_box_on(w, Vector3(3, 0.3, 1), Color(0.35, 0.22, 0.12, 1), Vector3(0, 3.2, 0))
	var roof = MeshInstance3D.new(); var pr = PrismMesh.new(); pr.size = Vector3(3.5, 1.5, 2)
	roof.mesh = pr
	roof.set_surface_override_material(0, _mat(Color(0.35, 0.14, 0.08, 1)))
	roof.position = Vector3(0, 4.0, 0); w.add_child(roof)
	_box_on(w, Vector3(0.2, 3, 0.2), Color(0.30, 0.18, 0.10, 1), Vector3(0.8, 2.0, 0.5))
	_box_on(w, Vector3(0.2, 3, 0.2), Color(0.30, 0.18, 0.10, 1), Vector3(-0.8, 2.0, 0.5))
	add_child(w)

func _cart(pos: Vector3):
	var c = Node3D.new(); c.position = pos; c.rotation.y = randf() * PI
	_box_on(c, Vector3(2.5, 1, 3), Color(0.35, 0.22, 0.12, 1), Vector3(0, 1.0, 0))
	# Wheels
	for wx in [-1.2, 1.2]:
		for wz in [-1.0, 1.0]:
			var wheel = MeshInstance3D.new(); var cyl = CylinderMesh.new()
			cyl.top_radius = 0.5; cyl.bottom_radius = 0.5; cyl.height = 0.2; wheel.mesh = cyl
			wheel.set_surface_override_material(0, _mat(Color(0.25, 0.18, 0.12, 1)))
			wheel.rotation_degrees = Vector3(90, 0, 0); wheel.position = Vector3(wx, 0.5, wz); c.add_child(wheel)
	# Shafts
	_box_on(c, Vector3(0.2, 0.2, 2.5), Color(0.30, 0.20, 0.12, 1), Vector3(0, 1.5, -2.5))
	add_child(c)

# ===== CASTLE =====
func _build_castle():
	var c = Node3D.new(); c.name = "Castelo"; c.position = Vector3(-60, 0, 40)
	var stone = Color(0.52, 0.50, 0.46, 1); var dark = Color(0.44, 0.42, 0.38, 1)
	_box_on(c, Vector3(14, 18, 14), stone, Vector3(0, 9, 0))
	_static_box(c, Vector3(14, 18, 14), Vector3(0, 9, 0))
	for cx in [-9, 9]:
		for cz in [-9, 9]:
			_box_on(c, Vector3(5, 22, 5), dark, Vector3(cx, 11, cz))
			_static_box(c, Vector3(5, 22, 5), Vector3(cx, 11, cz))
			_cone(c, Vector3(cx, 22.5, cz), 3, 5, Color(0.38, 0.14, 0.08, 1))
	_box_on(c, Vector3(7, 10, 4), stone, Vector3(0, 5, 9))
	_static_box(c, Vector3(7, 10, 4), Vector3(0, 5, 9))
	_box_on(c, Vector3(4, 7, 1), Color(0.25, 0.18, 0.08, 1), Vector3(0, 3.5, 10.5))
	for i in range(30):
		var a = float(i) * PI * 2.0 / 30.0
		var r = 20.0
		var w = _box_on(c, Vector3(1, 7, 3), dark, Vector3(cos(a) * r, 3.5, sin(a) * r))
		w.rotation.y = a + PI / 2.0
	var banner = MeshInstance3D.new(); var bp = BoxMesh.new(); bp.size = Vector3(0.1, 5, 2); banner.mesh = bp
	var bm = StandardMaterial3D.new(); bm.albedo_color = Color(0.80, 0.10, 0.10, 1)
	banner.set_surface_override_material(0, bm); banner.position = Vector3(0, 20, 0); c.add_child(banner)
	var castle_light = OmniLight3D.new(); castle_light.position = Vector3(0, 15, 10)
	castle_light.light_color = Color(1, 0.85, 0.6); castle_light.light_energy = 3.0; castle_light.omni_range = 25.0
	c.add_child(castle_light)
	add_child(c)

# ===== DRAGON =====
func _spawn_dragon():
	var pos = Vector3(30, 0, 0)
	var ds = load("res://assets/quaternius/creatures/Ultimate Monsters/Big/glTF/BlueDemon.gltf")
	if ds:
		var d = ds.instantiate(); d.name = "Vorak_o_Antigo"
		d.position = pos; d.scale = Vector3(6, 6, 6); d.rotation_degrees = Vector3(0, 90, 0)
		add_child(d); dragon_count += 1
		# HP label
		var lbl = Label3D.new(); lbl.text = "VORAK, O ANTIGO\nHP: 100/100"
		lbl.position = Vector3(0, 8, 0); lbl.font_size = 44
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lbl.modulate = Color(1, 0.15, 0.15, 1)
		d.add_child(lbl)
		# Red circle below
		var circle = MeshInstance3D.new(); var cyl = CylinderMesh.new()
		cyl.top_radius = 3.0; cyl.bottom_radius = 3.0; cyl.height = 0.05; circle.mesh = cyl
		var cm = StandardMaterial3D.new(); cm.albedo_color = Color(0.90, 0.10, 0.10, 0.5)
		cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		circle.set_surface_override_material(0, cm); circle.position = Vector3(0, 0.03, 0)
		d.add_child(circle)
	else:
		_fallback_dragon(pos)

func _fallback_dragon(pos: Vector3):
	var d = Node3D.new(); d.name = "Vorak"; d.position = pos; d.scale = Vector3(6, 6, 6); d.rotation_degrees = Vector3(0, 90, 0)
	var c = Color(0.55, 0.08, 0.08, 1)
	_capsule2(d, 1.6, 7, c, Vector3(0, 2.5, 0))
	_sphere2(d, 1.4, c, Vector3(0, 3.0, -4.5))
	_capsule2(d, 0.8, 3, c, Vector3(0, 3.5, -2.5))
	for side in [3, -3]:
		var wing = MeshInstance3D.new(); var pr = PrismMesh.new(); pr.size = Vector3(0.3, 5, 7)
		wing.mesh = pr; wing.set_surface_override_material(0, _mat(Color(0.30, 0.05, 0.05, 1)))
		wing.position = Vector3(side, 4.5, -1); wing.rotation_degrees = Vector3(0, 0, 45 if side > 0 else -45)
		d.add_child(wing)
	for i in range(6):
		var s = 1.0 - i * 0.14
		_capsule2(d, 0.7 * s, 2, c, Vector3(0, 2.5, 4 + i * 1.5))
	for lx in [1.5, -1.5]:
		for lz in [-2, 2]:
			_capsule2(d, 0.4, 2.5, c, Vector3(lx, 1.2, lz))
	_sphere2(d, 0.4, Color(1, 0.8, 0, 1), Vector3(0.7, 3.8, -5.5))
	_sphere2(d, 0.4, Color(1, 0.8, 0, 1), Vector3(-0.7, 3.8, -5.5))
	add_child(d); dragon_count += 1

# ===== NPCS =====
func _spawn_npcs():
	var npcs = [
		["Guarda do Vale", "Guarda", Vector3(5, 0, 5), Color(0.40, 0.35, 0.30, 1)],
		["Ferreiro Thorin", "Ferreiro", Vector3(-6, 0, 8), Color(0.45, 0.30, 0.20, 1)],
		["Mercador Ivan", "Mercador", Vector3(8, 0, -5), Color(0.55, 0.28, 0.12, 1)],
		["Curandeira Lyra", "Curandeira", Vector3(-7, 0, -6), Color(0.50, 0.45, 0.40, 1)],
		["Campones Finn", "Campones", Vector3(3, 0, -10), Color(0.55, 0.45, 0.30, 1)],
	]
	for nd in npcs:
		_npc(nd[2], nd[0], nd[1], nd[3])
		npc_count += 1

func _npc(pos: Vector3, name: String, title: String, body_color: Color):
	var n = Node3D.new(); n.name = name.replace(" ", "_"); n.position = pos
	_capsule2(n, 0.45, 1.3, body_color, Vector3(0, 1.5, 0))
	_sphere2(n, 0.37, Color(0.85, 0.70, 0.55, 1), Vector3(0, 2.4, 0))
	_capsule2(n, 0.13, 0.85, body_color, Vector3(0.58, 1.6, 0))
	_capsule2(n, 0.13, 0.85, body_color, Vector3(-0.58, 1.6, 0))
	_capsule2(n, 0.15, 0.85, Color(0.18, 0.12, 0.06, 1), Vector3(0.22, 0.45, 0))
	_capsule2(n, 0.15, 0.85, Color(0.18, 0.12, 0.06, 1), Vector3(-0.22, 0.45, 0))
	var lbl = Label3D.new(); lbl.text = name + "\n" + title
	lbl.position = Vector3(0, 3.2, 0); lbl.font_size = 26
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lbl.modulate = Color(1, 0.9, 0.5, 1)
	n.add_child(lbl)
	add_child(n)

# ===== TREES =====
func _build_trees():
	for i in range(80):
		var a = float(i) * PI * 2.0 / 10.0 + randf_range(-0.5, 0.5)
		var r = randf_range(25, 250)
		_tree(Vector3(cos(a) * r, 0, sin(a) * r), 1.0)
		tree_count += 1

func _tree(pos: Vector3, scale: float):
	var t = Node3D.new(); t.position = pos; t.scale = Vector3(scale, scale, scale)
	var h = randf_range(5, 10)
	_cyl(t, 0.3, h, Color(0.38, 0.22, 0.10, 1), Vector3(0, h/2, 0))
	for j in range(4):
		var s = 3.5 - float(j) * 0.7
		_sphere2(t, s * 0.5, Color(0.06, 0.35 + randf() * 0.30, 0.06, 1), Vector3(randf_range(-0.5, 0.5), h + float(j) * 1.5, randf_range(-0.5, 0.5)))
	add_child(t)

# ===== WALLS =====
func _build_walls():
	var wall_color = Color(0.42, 0.38, 0.32, 1)
	var segments = 40
	var radius = 120.0
	var wall_h = 6.0
	for i in range(segments):
		var a = float(i) * PI * 2.0 / float(segments)
		var x = cos(a) * radius
		var z = sin(a) * radius
		var w = Node3D.new(); w.position = Vector3(x, 0, z)
		_box_on(w, Vector3(2, wall_h, 20), wall_color, Vector3(0, wall_h / 2.0, 0))
		w.rotation.y = a + PI / 2.0
		var sb = StaticBody3D.new(); sb.position = Vector3(0, wall_h / 2.0, 0)
		var col = CollisionShape3D.new(); var bs = BoxShape3D.new(); bs.size = Vector3(2, wall_h, 20)
		col.shape = bs; sb.add_child(col); w.add_child(sb)
		add_child(w)
	for i in range(segments):
		var a = float(i) * PI * 2.0 / float(segments)
		if i % 5 == 0:
			var tx = cos(a) * (radius + 1)
			var tz = sin(a) * (radius + 1)
			_torch(Vector3(tx, 0, tz))

# ===== ROCKS =====
func _build_rocks():
	for i in range(40):
		var a = randf() * PI * 2.0
		var r = randf_range(20, 200)
		var pos = Vector3(cos(a) * r, 0, sin(a) * r)
		if pos.length() < 15: continue
		var sz = randf_range(0.5, 3.0)
		var rock = Node3D.new(); rock.position = pos
		_sphere2(rock, sz, Color(0.45 + randf() * 0.15, 0.42 + randf() * 0.1, 0.38 + randf() * 0.1, 1), Vector3(0, sz * 0.4, 0))
		rock.rotation.y = randf() * PI * 2.0
		add_child(rock)

# ===== ROAD TORCHES =====
func _build_road_torches():
	for z in range(-60, 80, 15):
		_torch(Vector3(4, 0, z))
		_torch(Vector3(-4, 0, z))

# ===== HELPERS =====
func _mat(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_color = color; return m

func _static_box(parent, size: Vector3, pos: Vector3):
	var sb = StaticBody3D.new(); sb.position = pos
	var col = CollisionShape3D.new(); var bs = BoxShape3D.new(); bs.size = size
	col.shape = bs; sb.add_child(col); parent.add_child(sb)

func _sphere2(parent, r, color, pos):
	var mi = MeshInstance3D.new(); var s = SphereMesh.new(); s.radius = r; s.height = r*2; mi.mesh = s
	mi.set_surface_override_material(0, _mat(color)); mi.position = pos; parent.add_child(mi)

func _capsule2(parent, r, h, color, pos):
	var mi = MeshInstance3D.new(); var c = CapsuleMesh.new(); c.radius = r; c.height = h; mi.mesh = c
	mi.set_surface_override_material(0, _mat(color)); mi.position = pos; parent.add_child(mi)

func _box_on(parent, size, color, pos):
	var mi = MeshInstance3D.new(); var b = BoxMesh.new(); b.size = size; mi.mesh = b
	mi.set_surface_override_material(0, _mat(color)); mi.position = pos; parent.add_child(mi); return mi

func _cyl(parent, r, h, color, pos):
	var mi = MeshInstance3D.new(); var c = CylinderMesh.new(); c.top_radius = r; c.bottom_radius = r; c.height = h; mi.mesh = c
	mi.set_surface_override_material(0, _mat(color)); mi.position = pos; parent.add_child(mi)

func _plane(pos: Vector3, size: Vector2, color: Color):
	var mi = MeshInstance3D.new(); var p = PlaneMesh.new(); p.size = size; mi.mesh = p
	mi.set_surface_override_material(0, _mat(color)); mi.position = pos; add_child(mi)

func _cone(parent, pos: Vector3, r: float, h: float, color: Color):
	var mi = MeshInstance3D.new(); var c = CylinderMesh.new(); c.top_radius = 0.05; c.bottom_radius = r; c.height = h; mi.mesh = c
	mi.set_surface_override_material(0, _mat(color)); mi.position = pos; parent.add_child(mi)

func _torch(pos: Vector3):
	var t = Node3D.new(); t.position = pos
	_cyl(t, 0.15, 4, Color(0.28, 0.20, 0.12, 1), Vector3(0, 2, 0))
	var flame = MeshInstance3D.new(); var fs = SphereMesh.new(); fs.radius = 0.5; fs.height = 1.0; flame.mesh = fs
	var fm = StandardMaterial3D.new(); fm.albedo_color = Color(1, 0.6, 0.1, 1)
	fm.emission_enabled = true; fm.emission = Color(1, 0.5, 0); fm.emission_energy_multiplier = 2.0
	flame.set_surface_override_material(0, fm); flame.position = Vector3(0, 4.5, 0); t.add_child(flame)
	var light = OmniLight3D.new(); light.position = Vector3(0, 4.5, 0)
	light.light_color = Color(1, 0.6, 0.2); light.light_energy = 1.5; light.omni_range = 10.0
	light.shadow_enabled = false
	t.add_child(light)
	add_child(t)

func _log(msg: String):
	if quest_text: quest_text.text = msg
	print("[WORLD] ", msg)

func _process(delta):
	if fps_label: fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	if obj_label: obj_label.text = "Obj: " + str(get_child_count())
	if player and hp_text:
		var hp = player.get("hp") if player.get("hp") != null else 100.0
		var mhp = player.get("max_hp") if player.get("max_hp") != null else 100.0
		hp_text.text = "HP: " + str(int(hp)) + "/" + str(int(mhp))
		if hp_bar and mhp > 0: hp_bar.size.x = 220 * (hp / mhp)
	if player and pos_label:
		pos_label.text = str(int(player.global_position.x)) + ", " + str(int(player.global_position.y)) + ", " + str(int(player.global_position.z))
