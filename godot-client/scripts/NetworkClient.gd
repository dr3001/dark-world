extends Node

const SERVER_URL = "http://5.78.142.138:9000"

var account_id: String = ""
var entity_id: String = ""

func _ready():
	print("[NetClient] _ready()")

func _make_request(url: String, callback: Callable, name: String, method := HTTPClient.METHOD_GET, body := ""):
	print("[NetClient] REQUEST ", name, " -> ", url)
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, _h, resp_body):
		print("[NetClient] RESPONSE ", name, " result=", result, " code=", code)
		if resp_body != null:
			var text = resp_body.get_string_from_utf8()
			print("[NetClient]   body=", text.substr(0, 150))
			var data = JSON.parse_string(text)
			if callback.is_valid():
				callback.call(data)
		http.queue_free()
	, CONNECT_ONE_SHOT)
	
	if method == HTTPClient.METHOD_POST:
		var headers = ["Content-Type: application/json"]
		http.request(url, headers, method, body)
	else:
		http.request(url)

func create_account(display_name: String, callback: Callable):
	var body = JSON.stringify({"display_name": display_name})
	_make_request(SERVER_URL + "/test/account", callback, "create_account", HTTPClient.METHOD_POST, body)

func create_character(acc_id: String, char_name: String, callback: Callable):
	var body = JSON.stringify({"account_id": acc_id, "character_name": char_name})
	_make_request(SERVER_URL + "/test/character", callback, "create_character", HTTPClient.METHOD_POST, body)

func get_entities(world_id: String, callback: Callable):
	_make_request(SERVER_URL + "/worlds/" + world_id + "/entities", callback, "get_entities")

func get_dragons(callback: Callable):
	_make_request(SERVER_URL + "/dragons", callback, "get_dragons")

func trigger_death(ent_id: String, callback: Callable):
	var body = JSON.stringify({"entity_id": ent_id})
	_make_request(SERVER_URL + "/events/character-died", callback, "trigger_death", HTTPClient.METHOD_POST, body)

func trigger_return(ent_id: String, callback: Callable):
	var body = JSON.stringify({"entity_id": ent_id})
	_make_request(SERVER_URL + "/events/afterlife-returned", callback, "trigger_return", HTTPClient.METHOD_POST, body)

func get_stats(char_id: String, callback: Callable):
	_make_request(SERVER_URL + "/characters/" + char_id + "/stats", callback, "get_stats")

func get_inventory(char_id: String, callback: Callable):
	_make_request(SERVER_URL + "/characters/" + char_id + "/inventory", callback, "get_inventory")

func get_equipment(char_id: String, callback: Callable):
	_make_request(SERVER_URL + "/characters/" + char_id + "/equipment", callback, "get_equipment")

func get_wallet(char_id: String, callback: Callable):
	_make_request(SERVER_URL + "/characters/" + char_id + "/wallet", callback, "get_wallet")

func get_items(callback: Callable):
	_make_request(SERVER_URL + "/items", callback, "get_items")

func get_quests(char_id: String, callback: Callable):
	_make_request(SERVER_URL + "/characters/" + char_id + "/quests", callback, "get_quests")

func accept_quest(char_id: String, quest_id: String, callback: Callable):
	var b = JSON.stringify({"quest_id": quest_id})
	_make_request(SERVER_URL + "/characters/" + char_id + "/quests/accept", callback, "accept_quest", HTTPClient.METHOD_POST, b)

func save_game(char_id: String, pos: Vector3, callback: Callable):
	var b = JSON.stringify({"position": {"x": pos.x, "y": pos.y, "z": pos.z}})
	_make_request(SERVER_URL + "/characters/" + char_id + "/save", callback, "save_game", HTTPClient.METHOD_POST, b)
