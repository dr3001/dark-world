extends Node3D

func _ready():
	print("[WORLD] _ready() START")
	
	# Load NetworkClient
	var ns = load("res://scripts/NetworkClient.gd")
	if ns:
		var net = ns.new()
		net.name = "DiagNetwork"
		add_child(net)
		print("[WORLD] Network loaded")
		
		# Check camera
		var cam = $Camera3D
		print("[WORLD] Camera found: ", cam != null, " current: ", cam.current if cam else "N/A")
		print("[WORLD] Camera pos: ", cam.global_position if cam else "N/A")
		
		# Spawn player
		var player = CharacterBody3D.new()
		player.name = "Player"
		var mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(1, 2, 1)
		mesh.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.8, 0.2)
		mesh.set_surface_override_material(0, mat)
		player.add_child(mesh)
		var coll = CollisionShape3D.new()
		var cshape = BoxShape3D.new()
		cshape.size = Vector3(1, 2, 1)
		coll.shape = cshape
		player.add_child(coll)
		player.position = Vector3(0, 2, 0)
		var ps = load("res://scripts/PlayerController.gd")
		if ps: player.set_script(ps)
		add_child(player)
		print("[WORLD] Player spawned at: ", player.global_position)
		
		# Force camera to look at (0,0,0) where geometry is
		if cam:
			cam.look_at(Vector3(0, 0, 0))
			print("[WORLD] Camera looking at origin")
		
		# Connect HUD buttons
		var kb = get_node_or_null("HUD/DebugPanel/KillButton")
		var rb = get_node_or_null("HUD/DebugPanel/ReturnButton")
		if kb: kb.pressed.connect(func(): print("[WORLD] KILL"))
		if rb: rb.pressed.connect(func(): print("[WORLD] RETURN"))
		
		# Load world entities
		net.get_entities("a0000000-0000-0000-0000-000000000001", _on_entities)
		net.get_dragons(_on_dragons)
		print("[WORLD] HTTP requests sent")
	else:
		print("[WORLD] ERROR: NetworkClient script not found!")
	
	# Verify scene has visible geometry
	await get_tree().process_frame
	var meshes = []
	_find_meshes(self, meshes)
	print("[WORLD] Total MeshInstance3D in scene: ", meshes.size())
	for m in meshes:
		print("[WORLD]   ", m.get_path(), " mesh=", m.mesh, " visible=", m.visible)
	
	print("[WORLD] _ready() DONE")


func _on_entities(data):
	if data == null or not data is Dictionary or not data.has("entities"):
		return
	for e in data["entities"]:
		var et = e.get("entity_type", "?")
		var px = float(e.get("position_x", 0)) / 10.0
		var pz = float(e.get("position_y", 0)) / 10.0
		var mi = MeshInstance3D.new()
		var b = BoxMesh.new()
		if et == "dragon":
			b.size = Vector3(10, 5, 10)
			mi.mesh = b
			var m = StandardMaterial3D.new(); m.albedo_color = Color(1, 0, 0)
			mi.set_surface_override_material(0, m)
			mi.position = Vector3(px, 2.5, pz)
		elif et == "territory":
			b.size = Vector3(30, 0.2, 30)
			mi.mesh = b
			var m = StandardMaterial3D.new(); m.albedo_color = Color(0.5, 0.5, 0.5)
			mi.set_surface_override_material(0, m)
			mi.position = Vector3(px, -0.1, pz)
		else:
			b.size = Vector3(1, 2, 1)
			mi.mesh = b
			var m = StandardMaterial3D.new(); m.albedo_color = Color(0, 1, 0)
			mi.set_surface_override_material(0, m)
			mi.position = Vector3(px, 1, pz)
		add_child(mi)


func _on_dragons(data):
	pass


func _find_meshes(node, result):
	if node is MeshInstance3D:
		result.append(node)
	for c in node.get_children():
		_find_meshes(c, result)
