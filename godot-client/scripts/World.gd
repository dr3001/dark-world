extends Node3D

var player: CharacterBody3D
var quest_system: Node
var hp_bar: ColorRect
var mana_bar: ColorRect
var hp_text: Label
var fps_label: Label
var quest_text: Label
var pos_label: Label
var cam: Camera3D

func _ready():
	print("[WORLD] _ready() START")
	
	# Get HUD references
	hp_bar = get_node_or_null("HUD/HPBar")
	mana_bar = get_node_or_null("HUD/ManaBar")
	hp_text = get_node_or_null("HUD/HPText")
	fps_label = get_node_or_null("HUD/FPS")
	quest_text = get_node_or_null("HUD/QuestText")
	pos_label = get_node_or_null("HUD/Position")
	cam = $Camera3D
	
	# Create quest system
	quest_system = Node.new()
	quest_system.name = "QuestSystem"
	quest_system.set_script(load("res://scripts/QuestSystem.gd"))
	add_child(quest_system)
	
	# Build terrain
	var tb = get_node_or_null("TerrainBuilder")
	if tb:
		tb.set_script(load("res://scripts/TerrainBuilder.gd"))
	
	# Spawn player
	_spawn_player()
	
	# Load network client and fetch entities
	var ns = load("res://scripts/NetworkClient.gd")
	if ns:
		var net = ns.new()
		net.name = "Network"
		add_child(net)
		net.get_entities("a0000000-0000-0000-0000-000000000001", _on_entities)
		net.get_dragons(_on_dragons)
		print("[WORLD] HTTP requests sent")
	
	print("[WORLD] _ready() DONE")

func _spawn_player():
	player = CharacterBody3D.new()
	player.name = "Player"
	player.add_to_group("player_group")
	
	# Load procedural player model
	var player_scene = load("res://scenes/models/Player.tscn")
	if player_scene:
		var model = player_scene.instantiate()
		model.name = "PlayerModel"
		player.add_child(model)
	
	var coll = CollisionShape3D.new()
	var cshape = CapsuleShape3D.new()
	cshape.radius = 0.5
	cshape.height = 2.0
	coll.shape = cshape
	player.add_child(coll)
	
	player.position = Vector3(0, 2, 0)
	
	var ps = load("res://scripts/PlayerController.gd")
	if ps: player.set_script(ps)
	
	add_child(player)
	
	# Set camera target
	if cam: cam.target = player
	
	print("[WORLD] Player spawned at ", player.global_position)
	
	# Spawn a dragon RIGHT HERE for testing
	var dragon_scene = load("res://scenes/models/Dragon.tscn")
	if dragon_scene:
		var test_dragon = dragon_scene.instantiate()
		test_dragon.name = "Vorak_Test"
		test_dragon.position = Vector3(10, 0, 10)
		add_child(test_dragon)
		print("[WORLD] Test dragon spawned at (10,0,10)")

func _on_entities(data):
	if data == null or not data is Dictionary or not data.has("entities"):
		return
	for e in data["entities"]:
		var et = e.get("entity_type", "")
		var px = float(e.get("position_x", 0)) / 10.0
		var pz = float(e.get("position_y", 0)) / 10.0
		var nm = e.get("name", "")
		var eid = e.get("id", "")
		
		if et == "dragon":
			var dragon_scene = load("res://scenes/models/Dragon.tscn")
			if dragon_scene:
				var dragon = dragon_scene.instantiate()
				dragon.name = nm
				dragon.position = Vector3(px, 0, pz)
				if dragon.has_method("_ready"): pass  # ensure name_tag is set
				add_child(dragon)
				print("[WORLD] Dragon spawned: ", nm, " at ", dragon.position)
		elif et == "player_character":
			if nm != "Heroi Mac" and nm.find("Auditor") == -1:
				# Spawn other players as simple figures
				var npc = _make_colored_box(Vector3(0.8, 1.8, 0.8), Color(0.3, 0.5, 0.8), Vector3(px, 1, pz))
				add_child(npc)
		elif et == "territory":
			var t = _make_colored_box(Vector3(20, 0.1, 20), Color(0.3, 0.3, 0.3, 0.4), Vector3(px, 0, pz))
			t.name = nm
			add_child(t)

func _on_dragons(data):
	if data != null and data.has("dragons"):
		for d in data["dragons"]:
			print("[WORLD] Dragon data: ", d.get("dragon_name", "?"))
			
			# Check if the dragon already exists in the scene (spawned via entities)
			var existing = get_node_or_null(d.get("dragon_name", ""))
			if existing:
				# Set name on existing dragon
				var dragon = get_node_or_null(d.get("dragon_name", ""))
				pass

func _make_colored_box(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new(); box.size = size
	mi.mesh = box
	var mat = StandardMaterial3D.new(); mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	return mi

func _process(delta):
	if fps_label:
		fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
	
	if player:
		var pc = player.get_script()
		if pc:
			var hp_val = pc.get("hp") if pc.get("hp") != null else 100.0
			var max_hp_val = pc.get("max_hp") if pc.get("max_hp") != null else 100.0
			var mana_val = pc.get("mana") if pc.get("mana") != null else 50.0
			var max_mana_val = pc.get("max_mana") if pc.get("max_mana") != null else 50.0
			
			if hp_bar:
				hp_bar.size.x = 200 * (hp_val / max_hp_val)
				hp_bar.color = Color(0.8, hp_val / max_hp_val * 0.8, hp_val / max_hp_val * 0.8)
			if mana_bar:
				mana_bar.size.x = 200 * (mana_val / max_mana_val)
			if hp_text:
				hp_text.text = "HP: " + str(int(hp_val)) + "/" + str(int(max_hp_val))
			if pos_label:
				pos_label.text = str(int(player.global_position.x)) + ", " + str(int(player.global_position.y)) + ", " + str(int(player.global_position.z))
	
	if quest_system and quest_text:
		quest_text.text = quest_system.get_quest_text()
