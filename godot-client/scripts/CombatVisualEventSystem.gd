extends Node
# FASE 2 — Central Combat Visual Event System

signal vfx_event(event_type, data)

var blood_fx = null
var impact_fx = null
var decal_fx = null
var reaction_fx = null
var camera_fx = null
var audio_fx = null

func setup(blood, impact, decal, reaction, camera, audio_node):
	blood_fx = blood; impact_fx = impact; decal_fx = decal
	reaction_fx = reaction; camera_fx = camera; audio_fx = audio_node

func trigger_event(event_type: String, data: Dictionary):
	vfx_event.emit(event_type, data)
	_log_to_server(event_type, data)
	match event_type:
		"HIT_LIGHT": _hit_light(data)
		"HIT_MEDIUM": _hit_medium(data)
		"HIT_HEAVY": _hit_heavy(data)
		"BLOCK": _block(data)
		"CRITICAL_HIT": _critical(data)
		"SHIELD_IMPACT": _shield_impact(data)
		"MAGIC_IMPACT": _magic_impact(data)
		"PROJECTILE_IMPACT": _projectile_impact(data)
		"GROUND_IMPACT": _ground_impact(data)
		"DEATH_PREVIEW": _death_preview(data)

func _hit_light(d): var pos = _get_pos(d)
	if blood_fx: blood_fx.splash_small(pos, d.get("direction", Vector3.RIGHT))
	if impact_fx: impact_fx.spawn_impact("metal", pos)
	if audio_fx: audio_fx.play_hit("light")

func _hit_medium(d): var pos = _get_pos(d)
	if blood_fx: blood_fx.splash_medium(pos)
	if impact_fx: impact_fx.spawn_impact("metal", pos, d.get("direction", Vector3.RIGHT))
	if decal_fx: decal_fx.spawn_decal("blood", pos - Vector3(0,0.9,0))
	if camera_fx: camera_fx.shake_light()
	if audio_fx: audio_fx.play_hit("medium")

func _hit_heavy(d): var pos = _get_pos(d)
	if blood_fx: blood_fx.splash_heavy(pos)
	if impact_fx: impact_fx.spawn_impact("metal", pos, d.get("direction", Vector3.RIGHT))
	if decal_fx: decal_fx.spawn_decal("blood", pos)
	if camera_fx: camera_fx.shake_medium()
	if audio_fx: audio_fx.play_hit("heavy")

func _block(d): var pos = _get_pos(d)
	if impact_fx: impact_fx.spawn_impact("shield", pos)
	if camera_fx: camera_fx.block_flash()
	if audio_fx: audio_fx.play_block()

func _critical(d): var pos = _get_pos(d)
	if blood_fx: blood_fx.burst(pos)
	if impact_fx: impact_fx.spawn_impact("fire", pos, Vector3.UP)
	if decal_fx: decal_fx.spawn_decal("blood", pos)
	if camera_fx: camera_fx.critical_flash()
	if audio_fx: audio_fx.play_critical()

func _shield_impact(d): var pos = _get_pos(d)
	if impact_fx: impact_fx.spawn_impact("shield", pos)
	if camera_fx: camera_fx.block_flash()

func _magic_impact(d): var pos = _get_pos(d)
	var elem = d.get("element", "magic")
	if impact_fx: impact_fx.spawn_impact(elem, pos, Vector3.UP)
	if decal_fx: decal_fx.spawn_decal(elem, pos)

func _projectile_impact(d): var pos = _get_pos(d)
	if impact_fx: impact_fx.spawn_impact(d.get("element", "wind"), pos, d.get("direction", Vector3.RIGHT))
	if audio_fx: audio_fx.play_arrow()

func _ground_impact(d): var pos = _get_pos(d)
	if impact_fx: impact_fx.spawn_impact("earth", pos, Vector3.UP)
	if decal_fx: decal_fx.spawn_decal("dust", pos)

func _death_preview(d): var pos = _get_pos(d)
	if blood_fx: blood_fx.burst(pos)
	if camera_fx: camera_fx.shake_heavy()
	if audio_fx: audio_fx.play_death()

func _get_pos(d: Dictionary) -> Vector3:
	return d.get("position", Vector3.ZERO)

func _log_to_server(event_type: String, data: Dictionary):
	var important = ["CRITICAL_HIT", "DEATH_PREVIEW", "HIT_HEAVY"]
	if event_type not in important: return
	var http = HTTPRequest.new(); add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free(), CONNECT_ONE_SHOT)
	http.request("http://5.78.142.138:9000/combat-vfx/event/log", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({
		"event_type": event_type,
		"position": {"x": data.get("position", Vector3.ZERO).x, "y": data.get("position", Vector3.ZERO).y, "z": data.get("position", Vector3.ZERO).z}
	}))
