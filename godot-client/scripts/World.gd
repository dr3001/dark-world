extends Node3D

var player: CharacterBody3D
var hp_bar: ColorRect
var hp_text: Label
var fps_label: Label
var quest_text: Label
var pos_label: Label
var cam: Camera3D

func _ready():
	print("[WORLD] _ready() START")
	
	# Get HUD references
	hp_bar = get_node_or_null("HUD/HPBar")
	hp_text = get_node_or_null("HUD/HPText")
	fps_label = get_node_or_null("HUD/FPS")
	quest_text = get_node_or_null("HUD/QuestText")
	pos_label = get_node_or_null("HUD/Position")
	cam = $Camera3D
	
	# ===== BUILD WORLD (all fixed, no API) =====
	_build_world()
	
	# ===== SPAWN PLAYER =====
	_spawn_player()
	
	# ===== SPAWN NPC =====
	_spawn_npc()
	
	# ===== SPAWN DRAGON =====
	_spawn_dragon()
	
	# ===== LOAD NETWORK ENTITIES (secondary) =====
	var ns = load("res://scripts/NetworkClient.gd")
	if ns:
		var net = ns.new()
		add_child(net)
		net.get_entities("a0000000-0000-0000-0000-000000000001", _on_entities)
	
	print("[WORLD] _ready() DONE - Objects: ", get_child_count())

func _build_world():
	# 1. LARGE GROUND (500x500) - already in World.tscn
	
	# 2. BUILD 20 TREES around spawn
	for i in range(20):
		var angle = float(i) * PI * 2.0 / 20.0
		var radius = randf_range(15, 60)
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		_spawn_tree(Vector3(x, 0, z))
	
	# 3. BUILD 30 ROCKS
	for i in range(30):
		var pos = Vector3(randf_range(-80, 80), 0, randf_range(-80, 80))
		if pos.length() < 5: continue
		_spawn_rock(pos)
	
	# 4. BUILD 4 HOUSES
	_spawn_house(Vector3(25, 0, 25))
	_spawn_house(Vector3(-25, 0, 25))
	_spawn_house(Vector3(25, 0, -25))
	_spawn_house(Vector3(-25, 0, -25))
	
	# 5. BUILD WALLS around spawn
	for i in range(40):
		var angle = float(i) * PI * 2.0 / 40.0
		var r = 12.0
		var x = cos(angle) * r
		var z = sin(angle) * r
		_spawn_wall_segment(Vector3(x, 0, z), angle)
	
	print("[WORLD] World built: 20 trees, 30 rocks, 4 houses, wall ring")

func _spawn_tree(pos: Vector3):
	var tree = Node3D.new(); tree.position = pos
	# Trunk
	var trunk = _box(tree, Vector3(0.4, randf_range(4, 7), 0.4), Color(0.35, 0.2, 0.1), Vector3(0, 2.5, 0))
	# Canopy layers
	for i in range(3):
		var s = 3.0 - float(i) * 0.8
		_box(tree, Vector3(s, 1.5, s), Color(0.1, 0.4 + randf() * 0.3, 0.1), Vector3(0, 4.5 + float(i) * 1.5, 0))
	add_child(tree)

func _spawn_rock(pos: Vector3):
	var s = Vector3(randf_range(1, 4), randf_range(0.5, 2), randf_range(1, 4))
	var rock = _box(self, s, Color(0.3 + randf() * 0.2, 0.3 + randf() * 0.2, 0.3 + randf() * 0.2), pos + Vector3(0, s.y/2, 0))
	rock.rotation = Vector3(randf_range(-0.2, 0.2), randf_range(0, 6.28), randf_range(-0.2, 0.2))

func _spawn_house(pos: Vector3):
	var house = Node3D.new(); house.position = pos
	# Base
	_box(house, Vector3(6, 4, 5), Color(0.5, 0.35, 0.2), Vector3(0, 2, 0))
	# Roof
	var roof = _box(house, Vector3(7, 0.3, 6), Color(0.4, 0.15, 0.1), Vector3(0, 4.2, 0.5))
	roof.rotation_degrees = Vector3(30, 0, 0)
	# Door
	_box(house, Vector3(1.5, 3, 0.2), Color(0.3, 0.15, 0.08), Vector3(0, 1.5, 2.6))
	# Windows
	_box(house, Vector3(1, 1, 0.1), Color(0.6, 0.7, 0.9), Vector3(2, 2.5, 2.6))
	_box(house, Vector3(1, 1, 0.1), Color(0.6, 0.7, 0.9), Vector3(-2, 2.5, 2.6))
	add_child(house)

func _spawn_wall_segment(pos: Vector3, angle: float):
	var wall = _box(self, Vector3(0.4, 3, 1.5), Color(0.4, 0.35, 0.3), pos + Vector3(0, 1.5, 0))
	wall.rotation.y = angle

func _spawn_player():
	player = CharacterBody3D.new()
	player.name = "Player"
	player.add_to_group("player_group")
	# Body
	var body = _box(player, Vector3(0.8, 1.2, 0.4), Color(0.2, 0.3, 0.7), Vector3(0, 1.4, 0))
	# Head
	_sphere(player, 0.35, Color(0.85, 0.7, 0.55), Vector3(0, 2.2, 0))
	# Arms
	_box(player, Vector3(0.2, 0.9, 0.2), Color(0.2, 0.3, 0.7), Vector3(0.6, 1.5, 0))
	_box(player, Vector3(0.2, 0.9, 0.2), Color(0.2, 0.3, 0.7), Vector3(-0.6, 1.5, 0))
	# Legs
	_box(player, Vector3(0.25, 0.8, 0.25), Color(0.15, 0.1, 0.05), Vector3(0.2, 0.4, 0))
	_box(player, Vector3(0.25, 0.8, 0.25), Color(0.15, 0.1, 0.05), Vector3(-0.2, 0.4, 0))
	# Collision
	var coll = CollisionShape3D.new()
	var cshape = CapsuleShape3D.new(); cshape.radius = 0.5; cshape.height = 2.0
	coll.shape = cshape
	player.add_child(coll)
	player.position = Vector3(0, 2, 0)
	var ps = load("res://scripts/PlayerController.gd")
	if ps: player.set_script(ps)
	add_child(player)
	if cam: cam.target = player
	print("[WORLD] Player spawned")

func _spawn_npc():
	var npc = Node3D.new(); npc.name = "Guardiao_do_Vale"; npc.position = Vector3(0, 0, 8)
	_box(npc, Vector3(0.9, 1.3, 0.5), Color(0.6, 0.4, 0.2), Vector3(0, 1.5, 0))
	_sphere(npc, 0.37, Color(0.85, 0.7, 0.55), Vector3(0, 2.4, 0))
	_box(npc, Vector3(0.2, 0.9, 0.2), Color(0.5, 0.3, 0.15), Vector3(0.7, 1.6, 0))
	_box(npc, Vector3(0.2, 0.9, 0.2), Color(0.5, 0.3, 0.15), Vector3(-0.7, 1.6, 0))
	_box(npc, Vector3(0.25, 0.9, 0.25), Color(0.3, 0.2, 0.1), Vector3(0.2, 0.45, 0))
	_box(npc, Vector3(0.25, 0.9, 0.25), Color(0.3, 0.2, 0.1), Vector3(-0.2, 0.45, 0))
	# Name label
	var label = Label3D.new(); label.text = "Guardião do Vale"; label.position = Vector3(0, 3.2, 0)
	label.font_size = 24; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	npc.add_child(label)
	add_child(npc)
	print("[WORLD] NPC spawned")

func _spawn_dragon():
	print("[WORLD] DRAGON: Attempting load...")
	var ds = load("res://scenes/models/Dragon.tscn")
	print("[WORLD] DRAGON: load result=", ds, " valid=", ds != null)
	
	if ds:
		var dragon = ds.instantiate()
		dragon.name = "Vorak_o_Antigo"
		dragon.position = Vector3(10, 0, 10)
		dragon.scale = Vector3(4, 4, 4)  # 4x larger
		add_child(dragon)
		print("[WORLD] DRAGON: SPAWNED! Children=", dragon.get_child_count())
	else:
		# Fallback: build dragon manually RIGHT NOW
		print("[WORLD] DRAGON: load failed, building fallback...")
		_build_fallback_dragon(Vector3(10, 0, 10))
	
	print("[WORLD] DRAGON: done")

func _build_fallback_dragon(pos: Vector3):
	var d = Node3D.new(); d.name = "Vorak_Fallback"; d.position = pos; d.scale = Vector3(4, 4, 4)
	var c = Color(0.5, 0.08, 0.08)
	# Body
	_box(d, Vector3(3, 2, 8), c, Vector3(0, 2.5, 0))
	# Head
	_box(d, Vector3(2.5, 2, 3), c, Vector3(0, 3, -5.5))
	# Wings
	var lw = _box(d, Vector3(0.3, 0.3, 7), Color(0.3, 0.05, 0.05), Vector3(3, 4, -1)); lw.rotation_degrees = Vector3(0, 0, 45)
	var rw = _box(d, Vector3(0.3, 0.3, 7), Color(0.3, 0.05, 0.05), Vector3(-3, 4, -1)); rw.rotation_degrees = Vector3(0, 0, -45)
	# Tail
	for i in range(5):
		var s = 1.0 - i * 0.15
		_box(d, Vector3(1.5*s, 1*s, 2), c, Vector3(0, 2.5 - i*0.1, 4 + i*1.5))
	# Legs
	_box(d, Vector3(0.6, 2, 0.6), c, Vector3(1.5, 1, -2)); _box(d, Vector3(0.6, 2, 0.6), c, Vector3(-1.5, 1, -2))
	_box(d, Vector3(0.6, 2, 0.6), c, Vector3(1.5, 1, 2)); _box(d, Vector3(0.6, 2, 0.6), c, Vector3(-1.5, 1, 2))
	# Eyes
	_sphere(d, 0.4, Color(1, 0.8, 0), Vector3(0.8, 3.8, -6.5))
	_sphere(d, 0.4, Color(1, 0.8, 0), Vector3(-0.8, 3.8, -6.5))
	add_child(d)
	print("[WORLD] DRAGON: Fallback built")

func _on_entities(data):
	if data == null: return
	print("[WORLD] Entities loaded: ", data.get("entities", []).size())

func _box(parent, size, color, pos):
	var mi = MeshInstance3D.new(); var b = BoxMesh.new(); b.size = size; mi.mesh = b
	var mat = StandardMaterial3D.new(); mat.albedo_color = color; mi.set_surface_override_material(0, mat)
	mi.position = pos; parent.add_child(mi); return mi

func _sphere(parent, r, color, pos):
	var mi = MeshInstance3D.new(); var s = SphereMesh.new(); s.radius = r; s.height = r*2; mi.mesh = s
	var mat = StandardMaterial3D.new(); mat.albedo_color = color; mi.set_surface_override_material(0, mat)
	mi.position = pos; parent.add_child(mi); return mi

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
