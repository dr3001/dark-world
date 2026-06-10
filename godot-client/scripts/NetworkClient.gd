extends Node

# Dark World — Network Client
const SERVER_URL = "http://5.78.142.138:9000"

var http_request: HTTPRequest
var account_id: String = ""
var entity_id: String = ""

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

var _pending_callback: Callable

func get_worlds(callback: Callable):
	_pending_callback = callback
	http_request.request(SERVER_URL + "/worlds")

func create_account(display_name: String, callback: Callable):
	_pending_callback = callback
	var body = JSON.stringify({"display_name": display_name})
	var headers = ["Content-Type: application/json"]
	http_request.request(SERVER_URL + "/test/account", headers, HTTPClient.METHOD_POST, body)

func create_character(acc_id: String, char_name: String, callback: Callable):
	_pending_callback = callback
	var body = JSON.stringify({"account_id": acc_id, "character_name": char_name})
	var headers = ["Content-Type: application/json"]
	http_request.request(SERVER_URL + "/test/character", headers, HTTPClient.METHOD_POST, body)

func get_character(char_or_entity_id: String, callback: Callable):
	_pending_callback = callback
	http_request.request(SERVER_URL + "/characters/" + char_or_entity_id)

func get_entities(world_id: String, callback: Callable):
	_pending_callback = callback
	http_request.request(SERVER_URL + "/worlds/" + world_id + "/entities")

func trigger_death(entity_id: String, callback: Callable):
	_pending_callback = callback
	var body = JSON.stringify({"entity_id": entity_id})
	var headers = ["Content-Type: application/json"]
	http_request.request(SERVER_URL + "/events/character-died", headers, HTTPClient.METHOD_POST, body)

func trigger_return(entity_id: String, callback: Callable):
	_pending_callback = callback
	var body = JSON.stringify({"entity_id": entity_id})
	var headers = ["Content-Type: application/json"]
	http_request.request(SERVER_URL + "/events/afterlife-returned", headers, HTTPClient.METHOD_POST, body)

func get_recent_events(callback: Callable):
	_pending_callback = callback
	http_request.request(SERVER_URL + "/events/recent")

func get_dragons(callback: Callable):
	_pending_callback = callback
	http_request.request(SERVER_URL + "/dragons")

func _on_request_completed(_result, _response_code, _headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	if _pending_callback.is_valid():
		_pending_callback.call(data)
