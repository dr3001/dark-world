extends Node

var camera: Camera3D
var shake_intensity: float = 0.0
var shake_decay: float = 5.0
var original_pos: Vector3
var vignette_timer: float = 0.0
var vignette_color: Color = Color.TRANSPARENT

func setup(cam: Camera3D):
	camera = cam
	original_pos = camera.global_position

func _process(delta):
	if shake_intensity > 0.001:
		camera.global_position = original_pos + Vector3(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity/3, shake_intensity/3),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = lerpf(shake_intensity, 0.0, shake_decay * delta)
	else:
		camera.global_position = original_pos
	if vignette_timer > 0:
		vignette_timer -= delta

func shake_light():
	shake_intensity = max(shake_intensity, 0.05)
	vignette_timer = max(vignette_timer, 0.2)
	vignette_color = Color(1, 0.5, 0.5, 0.08)

func shake_medium():
	shake_intensity = max(shake_intensity, 0.12)
	vignette_timer = max(vignette_timer, 0.4)
	vignette_color = Color(1, 0.3, 0.3, 0.12)

func shake_heavy():
	shake_intensity = max(shake_intensity, 0.25)
	vignette_timer = max(vignette_timer, 0.6)
	vignette_color = Color(1, 0.1, 0.1, 0.18)

func damage_flash():
	vignette_timer = max(vignette_timer, 0.3)
	vignette_color = Color(1, 0.2, 0.2, 0.15)

func critical_flash():
	vignette_timer = max(vignette_timer, 0.5)
	vignette_color = Color(1, 0.05, 0.05, 0.25)
	shake_intensity = max(shake_intensity, 0.3)

func block_flash():
	vignette_timer = max(vignette_timer, 0.2)
	vignette_color = Color(0.3, 0.5, 1, 0.1)

func reset_camera():
	camera.global_position = original_pos
	shake_intensity = 0.0
	vignette_timer = 0.0
