extends CharacterBody3D

@export var speed: float = 5.0
@export var run_speed: float = 10.0
@export var jump_velocity: float = 8.0
@export var gravity: float = 20.0
@export var attack_range: float = 4.0
@export var attack_damage: float = 15.0
@export var attack_cooldown: float = 0.5

var hp: float = 100.0
var max_hp: float = 100.0
var mana: float = 50.0
var max_mana: float = 50.0
var last_attack_time: float = 0.0
var is_moving: bool = false
var player_model: Node3D

func _ready():
	# Find the PlayerModel child for animations
	for c in get_children():
		if c is Node3D and c.name != "CollisionShape3D":
			player_model = c
			break

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	# Sprint
	var current_speed = run_speed if Input.is_key_pressed(KEY_SHIFT) else speed
	
	# Movement
	var input_dir = Vector3.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.z -= 1
	if Input.is_key_pressed(KEY_S): input_dir.z += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	
	input_dir = input_dir.normalized()
	is_moving = input_dir != Vector3.ZERO
	
	if input_dir != Vector3.ZERO:
		velocity.x = input_dir.x * current_speed
		velocity.z = input_dir.z * current_speed
		# Face movement direction
		look_at(global_position + input_dir, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()
	
	if global_position.y < -10:
		global_position = Vector3(0, 5, 0)
		velocity = Vector3.ZERO
	
	if player_model and player_model.has_method("animate_walk"):
		player_model.animate_walk(delta, is_moving)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_attack()

func _attack():
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_attack_time < attack_cooldown:
		return
	last_attack_time = now
	
	# Find nearest dragon within range
	var space = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = attack_range
	query.shape = sphere
	query.transform = Transform3D(Basis(), global_position)
	
	var results = space.intersect_shape(query)
	for result in results:
		var collider = result.get("collider")
		if collider and collider.has_method("take_damage"):
			print("[COMBAT] Hit ", collider.name, " for ", attack_damage)
			collider.take_damage(attack_damage)
			return

func take_damage(amount: float):
	hp = max(hp - amount, 0)
	print("[COMBAT] Player took ", amount, " damage. HP: ", hp)
	if hp <= 0:
		print("[COMBAT] Player died!")
