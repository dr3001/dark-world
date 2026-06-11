extends Node

var net = null
var character_id: String = ""
var player_node: CharacterBody3D = null
var other_players: Dictionary = {}
var poll_timer: float = 0.0
var poll_interval: float = 2.0
var online_count: int = 0
var online_label: Label = null

func setup(network: Node, char_id: String, player: CharacterBody3D, label: Label = null):
	net = network
	character_id = char_id
	player_node = player
	online_label = label

func _process(delta):
	if not net or character_id == "" or not player_node: return
	poll_timer += delta
	if poll_timer >= poll_interval:
		poll_timer = 0.0
		_report_position()
		_fetch_nearby()

func _report_position():
	var pos = player_node.global_position
	var b = JSON.stringify({
		"character_id": character_id,
		"x": pos.x, "y": pos.y, "z": pos.z,
		"display_name": "Hero"
	})
	var http = HTTPRequest.new(); add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free(), CONNECT_ONE_SHOT)
	http.request("http://5.78.142.138:9000/players/position", ["Content-Type: application/json"], HTTPClient.METHOD_POST, b)

func _fetch_nearby():
	var http = HTTPRequest.new(); add_child(http)
	http.request_completed.connect(func(_r, code, _h, resp):
		if code == 200 and resp:
			var data = JSON.parse_string(resp.get_string_from_utf8())
			if data and data.has("players"):
				_update_other_players(data["players"])
		http.queue_free()
	, CONNECT_ONE_SHOT)
	http.request("http://5.78.142.138:9000/players/nearby")

func _update_other_players(players: Array):
	var seen: Dictionary = {}
	online_count = players.size()
	if online_label: online_label.text = "Online: " + str(online_count)
	for p in players:
		var cid = str(p.get("character_id", ""))
		if cid == character_id: continue
		seen[cid] = true
		var pos = Vector3(float(p.get("x", 0)), float(p.get("y", 3)), float(p.get("z", 0)))
		if other_players.has(cid):
			other_players[cid].update_position(pos)
		else:
			var OPScript = load("res://scripts/OtherPlayer.gd")
			if OPScript:
				var op = Node3D.new(); op.set_script(OPScript)
				op.name = "OP_" + cid.substr(0, 8)
				get_parent().add_child(op)
				op.setup(cid, str(p.get("display_name", "?")), pos, int(p.get("vip_level", 0)), str(p.get("role", "player")))
				other_players[cid] = op
	for cid in other_players.keys():
		if not seen.has(cid):
			other_players[cid].queue_free()
			other_players.erase(cid)
