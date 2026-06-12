extends Node

var _results: Dictionary = {}
var _player: CharacterBody3D
var _cam: Camera3D
var _start_pos: Vector3
var _start_cam: Vector3

func setup(player: CharacterBody3D, cam: Camera3D) -> void:
	_player = player
	_cam = cam
	_start_pos = player.global_position
	_start_cam = cam.global_position
	PlayerDebug.log_event("VALIDATION_MODE", "started")
	call_deferred("_run")

func _run() -> void:
	await get_tree().create_timer(1.0).timeout
	_test_move(Vector3(0, 0, -1), "forward")
	await get_tree().create_timer(0.5).timeout
	_test_move(Vector3(0, 0, 1), "backward")
	await get_tree().create_timer(0.5).timeout
	_test_move(Vector3(-1, 0, 0), "left")
	await get_tree().create_timer(0.5).timeout
	_test_move(Vector3(1, 0, 0), "right")
	await get_tree().create_timer(0.5).timeout
	_test_camera()
	_finish()

func _test_move(dir: Vector3, label: String) -> void:
	if not _player:
		_results["MOVEMENT_" + label.to_upper()] = "FAIL"
		return
	var before := _player.global_position
	for i in range(30):
		_player.velocity.x = dir.x * 5.0
		_player.velocity.z = dir.z * 5.0
		_player.move_and_slide()
		await get_tree().process_frame
	var moved := _player.global_position.distance_to(before) > 0.25
	_results["MOVEMENT_" + label.to_upper()] = "OK" if moved else "FAIL"
	PlayerDebug.log_event("VALIDATION_MOVE", "%s=%s dist=%.2f" % [label, _results["MOVEMENT_" + label.to_upper()], _player.global_position.distance_to(before)])

func _test_camera() -> void:
	if not _cam:
		_results["CAMERA"] = "FAIL"
		return
	var ok := _cam.global_position.distance_to(_start_cam) > 0.01 or _cam.current
	_results["CAMERA"] = "OK" if ok else "FAIL"
	PlayerDebug.log_event("VALIDATION_CAMERA", _results["CAMERA"])

func _finish() -> void:
	var movement_ok := true
	for k in _results:
		if k.begins_with("MOVEMENT") and _results[k] == "FAIL":
			movement_ok = false
	var summary := "MOVEMENT_%s CAMERA_%s" % [
		"OK" if movement_ok else "FAIL",
		_results.get("CAMERA", "FAIL")
	]
	PlayerDebug.log_event("VALIDATION_RESULT", summary)
	GameLogger.write_log("[VALIDATION] " + summary + " " + str(_results))
