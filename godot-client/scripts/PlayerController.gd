extends CharacterBody3D

# Dark World — Player Controller
# Movimentação WASD + câmera terceira pessoa

@export var speed: float = 5.0
@export var rotation_speed: float = 3.0

func _physics_process(delta):
	var input_dir = Vector3.ZERO
	
	if Input.is_key_pressed(KEY_W): input_dir.z -= 1
	if Input.is_key_pressed(KEY_S): input_dir.z += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	
	input_dir = input_dir.normalized()
	
	if input_dir != Vector3.ZERO:
		velocity = input_dir * speed
	else:
		velocity = Vector3.ZERO
	
	move_and_slide()
