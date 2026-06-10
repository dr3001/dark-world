extends Node

# Dark World — World State Manager
# Mantém estado local do mundo sincronizado com o servidor

var network: Node
var current_world: String = ""
var characters: Dictionary = {}
var entities: Array = []
var dragons: Array = []
var events: Array = []

func init(net: Node):
	network = net

func load_world(world_id: String):
	current_world = world_id
	network.get_entities(world_id, _on_entities_loaded)
	network.get_dragons(_on_dragons_loaded)
	network.get_recent_events(_on_events_loaded)

func _on_entities_loaded(data: Dictionary):
	if data.has("entities"):
		entities = data["entities"]
		print("[WorldState] Entities loaded: ", entities.size())

func _on_dragons_loaded(data: Dictionary):
	if data.has("dragons"):
		dragons = data["dragons"]

func _on_events_loaded(data: Dictionary):
	if data.has("events"):
		events = data["events"]

func get_entity_by_name(name: String) -> Dictionary:
	for e in entities:
		if e.get("name") == name:
			return e
	return {}
