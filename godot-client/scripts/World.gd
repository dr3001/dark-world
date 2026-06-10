extends Node3D

var network: Node
var current_entity_id: String = ""
var current_world_id: String = "a0000000-0000-0000-0000-000000000001"
var player_node: CharacterBody3D
var entities_cache: Array = []
var event_log: RichTextLabel
var after_death: bool = false

func _ready():
	event_log = $"HUD/EventLog"
	
	# Create NetworkClient via load
	var ns = load("res://scripts/NetworkClient.gd")
	network = ns.new()
	add_child(network)
	
	# Connect buttons
	var kb = $"HUD/DebugPanel/KillButton"
	var rb = $"HUD/DebugPanel/ReturnButton"
	if kb: kb.pressed.connect(func(): _on_kill())
	if rb: rb.pressed.connect(func(): _on_return())
	
	_spawn_player()
	_load_world()

func _spawn_player():
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
	player_node.set_script(ps)
	add_child(player_node)

func _load_world():
	if not network: return
	_log("Carregando mundo...")
	network.get_entities(current_world_id, _on_entities)
	network.get_dragons(_on_dragons)

func _on_entities(data: Dictionary):
	if not data.has("entities"): return
	entities_cache = data["entities"]
	_log("Entidades: " + str(entities_cache.size()))
	for entity in entities_cache:
		_spawn_entity(entity)

func _on_dragons(data: Dictionary):
	if data.has("dragons"):
		for d in data["dragons"]:
			_log("Dragao: " + d.get("dragon_name", "???"))

func _spawn_entity(entity: Dictionary):
	var et = entity.get("entity_type", "")
	var px = float(entity.get("position_x", 0)) / 10.0
	var pz = float(entity.get("position_y", 0)) / 10.0
	var mi = MeshInstance3D.new()
	
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
		add_child(mi)

func _on_kill():
	if network and current_entity_id != "":
		_log("Enviando morte...")
		network.trigger_death(current_entity_id, func(d): _log("Morte enviada"))

func _on_return():
	if network and current_entity_id != "":
		_log("Enviando retorno...")
		network.trigger_return(current_entity_id, func(d): _log("Retorno enviado"))

func _log(msg: String):
	print(msg)
	if event_log:
		event_log.text = msg + "\n" + event_log.text
