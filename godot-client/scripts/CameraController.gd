extends Camera3D

@export var target: Node3D
@export var distance: float = 12.0
@export var height: float = 7.0
@export var smooth_speed: float = 6.0
@export var min_distance: float = 4.0
@export var max_distance: float = 22.0
@export var collision_margin: float = 0.45

var _yaw: float = 0.0

func _ready():
	current = true
	if target:
		_yaw = target.rotation.y

func _process(delta):
	if not target:
		return

	if Input.is_action_just_pressed("zoom_in"):
		distance = clamp(distance - 2.0, min_distance, max_distance)
	if Input.is_action_just_pressed("zoom_out"):
		distance = clamp(distance + 2.0, min_distance, max_distance)

	var sf := 1.0 - exp(-smooth_speed * delta)
	var target_pos := target.global_position
	var offset := Vector3(sin(_yaw), 0, cos(_yaw)) * distance
	var desired := target_pos + Vector3(0, height, 0) + offset
	var safe_pos := _collision_adjust(target_pos + Vector3(0, 1.5, 0), desired)

	global_position = global_position.lerp(safe_pos, sf)
	var look_target := target_pos + Vector3(0, 1.5, 0)
	if global_position.distance_to(look_target) > 0.1:
		var target_xform := global_transform.looking_at(look_target, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_xform.basis, sf)

	if Engine.get_frames_drawn() % 60 == 0:
		PlayerDebug.log_event("CAMERA_UPDATED", "dist=%.1f pos=%s" % [distance, str(global_position.round())])

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - 2.0, min_distance, max_distance)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + 2.0, min_distance, max_distance)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_yaw -= event.relative.x * 0.005

func snap_validate():
	if not target:
		return
	for i in range(6):
		var target_pos := target.global_position
		var offset := Vector3(sin(_yaw), 0, cos(_yaw)) * distance
		var desired := target_pos + Vector3(0, height, 0) + offset
		var safe := _collision_adjust(target_pos + Vector3(0, 1.5, 0), desired)
		if safe.distance_to(desired) < 0.2:
			break
		distance = clamp(distance + 2.5, min_distance, max_distance)
	global_position = _collision_adjust(
		target.global_position + Vector3(0, 1.5, 0),
		target.global_position + Vector3(0, height, 0) + Vector3(sin(_yaw), 0, cos(_yaw)) * distance
	)
	PlayerDebug.log_event("CAMERA_UPDATED", "snap_validate dist=%.1f" % distance)

func _collision_adjust(from: Vector3, to: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	if not space:
		return to
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collision_mask = 0xFFFFFFFF
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return to
	var dir := (to - from).normalized()
	return hit.position - dir * collision_margin
