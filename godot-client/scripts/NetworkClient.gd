extends Node

const SERVER_URL = "http://5.78.142.138:9000"

var http_request: HTTPRequest
var account_id: String = ""
var entity_id: String = ""

func _ready():
	print("[NetClient] _ready() started")
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	print("[NetClient] _ready() done, http_request=", http_request)

var _pending_callback: Callable
var _pending_name: String = ""

func _request(url: String, cb: Callable, name: String, method := HTTPClient.METHOD_GET, body := ""):
	_pending_callback = cb
	_pending_name = name
	print("[NetClient] REQUEST ", name, " -> ", url)
	if method == HTTPClient.METHOD_POST:
		var headers = ["Content-Type: application/json"]
		var err = http_request.request(url, headers, method, body)
		print("[NetClient]   POST error=", err)
	else:
		var err = http_request.request(url)
		print("[NetClient]   GET error=", err)

func get_worlds(callback: Callable):
	_request(SERVER_URL + "/worlds", callback, "get_worlds")

func create_account(display_name: String, callback: Callable):
	var body = JSON.stringify({"display_name": display_name})
	_request(SERVER_URL + "/test/account", callback, "create_account", HTTPClient.METHOD_POST, body)

func create_character(acc_id: String, char_name: String, callback: Callable):
	var body = JSON.stringify({"account_id": acc_id, "character_name": char_name})
	_request(SERVER_URL + "/test/character", callback, "create_character", HTTPClient.METHOD_POST, body)

func get_entities(world_id: String, callback: Callable):
	_request(SERVER_URL + "/worlds/" + world_id + "/entities", callback, "get_entities")

func trigger_death(ent_id: String, callback: Callable):
	var body = JSON.stringify({"entity_id": ent_id})
	_request(SERVER_URL + "/events/character-died", callback, "trigger_death", HTTPClient.METHOD_POST, body)

func trigger_return(ent_id: String, callback: Callable):
	var body = JSON.stringify({"entity_id": ent_id})
	_request(SERVER_URL + "/events/afterlife-returned", callback, "trigger_return", HTTPClient.METHOD_POST, body)

func get_dragons(callback: Callable):
	_request(SERVER_URL + "/dragons", callback, "get_dragons")

func _on_request_completed(result, response_code, _headers, body):
	print("[NetClient] RESPONSE ", _pending_name, " result=", result, " code=", response_code)
	if body != null:
		var text = body.get_string_from_utf8()
		print("[NetClient]   body=", text.substr(0, 200))
		var data = JSON.parse_string(text)
		if _pending_callback.is_valid():
			_pending_callback.call(data)
		else:
			print("[NetClient]   WARNING: callback is INVALID!")
	else:
		print("[NetClient]   body is NULL!")
