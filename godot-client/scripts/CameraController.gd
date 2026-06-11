extends Camera3D

@export var target: Node3D
@export var distance: float = 15.0
@export var height: float = 8.0
@export var angle: float = 0.0
@export var smooth_speed: float = 5.0
@export var min_distance: float = 5.0
@export var max_distance: float = 30.0

func _ready():
	current = true

func _process(delta):
	if not target: return
	
	# Mouse scroll zoom
	if Input.is_action_just_pressed("zoom_in"):
		distance -= 2.0
	if Input.is_action_just_pressed("zoom_out"):
		distance += 2.0
	distance = clamp(distance, min_distance, max_distance)
	
	# Calculate target position behind and above player
	var target_pos = target.global_position
	var cam_target = target_pos + Vector3(0, height, distance)
	
	# Smooth follow
	global_position = global_position.lerp(cam_target, smooth_speed * delta)
	
	# Look at player
	look_at(target_pos + Vector3(0, 1.5, 0))

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - 2.0, min_distance, max_distance)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + 2.0, min_distance, max_distance)
