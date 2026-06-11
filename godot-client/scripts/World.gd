extends Node3D

var network: Node
var current_entity_id: String = ""
var current_world_id: String = "a0000000-0000-0000-0000-000000000001"
var player_node: CharacterBody3D
var entities_cache: Array = []
var event_log: RichTextLabel

func _ready():
	print("[World] _ready() START")
	
	event_log = $"HUD/EventLog"
	print("[World] event_log=", event_log != null)
	
	var ns = load("res://scripts/NetworkClient.gd")
	network = ns.new()
	network.name = "NetworkClient"
	add_child(network)
	print("[World] network added, calling _load_world()")
	
	var kb = $"HUD/DebugPanel/KillButton"
	var rb = $"HUD/DebugPanel/ReturnButton"
	print("[World] kill_btn=", kb != null, " return_btn=", rb != null)
	if kb: kb.pressed.connect(func(): _on_kill())
	if rb: rb.pressed.connect(func(): _on_return())
	
	print("[World] spawning player...")
	_spawn_player()
	print("[World] player spawned, loading world...")
	_load_world()
	print("[World] _ready() DONE")

func _spawn_player():
	print("[World] _spawn_player() START")
	player_node = CharacterBody3D.new()
	var mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.height = 2.0; cyl.radius = 0.5
	mesh.mesh = cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.3, 0.8)
	mesh.set_surface_override_material(0, mat)
	var coll = CollisionShape3D.new()
	var cshape = CylinderShape3D.new()
	cshape.height = 2.0; cshape.radius = 0.5
	coll.shape = cshape
	player_node.add_child(mesh)
	player_node.add_child(coll)
	player_node.position = Vector3(0, 1, 0)
	var ps = load("res://scripts/PlayerController.gd")
	print("[World] PlayerController script loaded=", ps != null)
	if ps:
		player_node.set_script(ps)
	add_child(player_node)
	print("[World] _spawn_player() DONE, player at ", player_node.position)

func _load_world():
	print("[World] _load_world() network exists=", network != null)
	if not network:
		print("[World] ERROR: network is null!")
		return
	_log("Carregando mundo...")
	print("[World] calling get_entities for world_id=", current_world_id)
	network.get_entities(current_world_id, _on_entities)
	print("[World] calling get_dragons")
	network.get_dragons(_on_dragons)
	print("[World] _load_world() DONE, waiting for callbacks...")

func _on_entities(data):
	print("[World] _on_entities() called, data type=", typeof(data), " data=", data)
	if data == null:
		_log("ERRO: resposta nula do servidor!")
		return
	if not data is Dictionary:
		_log("ERRO: resposta nao e Dictionary: " + str(typeof(data)))
		return
	if not data.has("entities"):
		_log("ERRO: sem campo entities na resposta: " + str(data.keys()))
		return
	entities_cache = data["entities"]
	_log("Entidades carregadas: " + str(entities_cache.size()))
	print("[World] entities_cache size=", entities_cache.size())
	for entity in entities_cache:
		print("[World] spawning entity: ", entity.get("entity_type"), entity.get("name"))
		_spawn_entity(entity)
	print("[World] _on_entities DONE")

func _on_dragons(data):
	print("[World] _on_dragons() called, data=", data)
	if data == null: return
	if data.has("dragons"):
		for d in data["dragons"]:
			_log("Dragao: " + d.get("dragon_name", "???"))

func _spawn_entity(entity: Dictionary):
	var et = entity.get("entity_type", "")
	var px = float(entity.get("position_x", 0)) / 10.0
	var pz = float(entity.get("position_y", 0)) / 10.0
	var mi = MeshInstance3D.new()
	print("[World] spawn_entity type=", et, " at (", px, ",", pz, ")")
	
	if et == "dragon":
		var box = BoxMesh.new(); box.size = Vector3(10, 5, 10)
		mi.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.1, 0.1)
		mi.set_surface_override_material(0, mat)
		mi.position = Vector3(px, 2.5, pz)
		var lbl = Label3D.new()
		lbl.text = entity.get("name", "Vorak") + " [AMEACA]"
		lbl.position = Vector3(0, 6, 0)
		mi.add_child(lbl)
	elif et == "territory":
		var box = BoxMesh.new(); box.size = Vector3(20, 0.2, 20)
		mi.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.3, 0.3)
		mi.set_surface_override_material(0, mat)
		mi.position = Vector3(px, -0.1, pz)
	elif et == "faction":
		var box = BoxMesh.new(); box.size = Vector3(3, 3, 3)
		mi.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.7, 0.2)
		mi.set_surface_override_material(0, mat)
		mi.position = Vector3(px, 1.5, pz)
	else:
		var cyl = CylinderMesh.new(); cyl.height = 2.0; cyl.radius = 0.5
		mi.mesh = cyl
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.7, 0.3)
		mi.set_surface_override_material(0, mat)
		mi.position = Vector3(px, 1.0, pz)
	add_child(mi)
	print("[World] spawn_entity DONE")

func _on_kill():
	if network and current_entity_id != "":
		_log("Enviando morte...")
		network.trigger_death(current_entity_id, func(d): _log("Morte enviada"))

func _on_return():
	if network and current_entity_id != "":
		_log("Enviando retorno...")
		network.trigger_return(current_entity_id, func(d): _log("Retorno enviado"))

func _log(msg: String):
	print("[World] ", msg)
	if event_log:
		event_log.text = msg + "\n" + event_log.text
