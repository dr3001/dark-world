extends Node3D

enum State { IDLE, PATROL, CHASE, ATTACK }
var current_state: State = State.IDLE
var hp: float = 100.0
var max_hp: float = 100.0
var move_speed: float = 3.0
var chase_speed: float = 6.0
var attack_range: float = 3.0
var detection_range: float = 20.0
var patrol_target: Vector3
var idle_timer: float = 0.0
var attack_timer: float = 0.0
var attack_cooldown: float = 1.5
var attack_damage: float = 10.0
var player: CharacterBody3D
var hp_label: Label3D
var name_tag: String = "Vorak, o Antigo"

func _ready():
	# Find player in the scene
	player = get_tree().get_first_node_in_group("player_group")
	
	# Create HP label floating above
	_create_hp_label()
	
	# Set initial patrol target
	patrol_target = global_position + Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))
	
	# Add to player group for attack detection
	add_to_group("enemy_group")

func _create_hp_label():
	hp_label = Label3D.new()
	hp_label.position = Vector3(0, 10, 0)
	hp_label.text = name_tag + "\nHP: 100"
	hp_label.modulate = Color(1, 0, 0)
	hp_label.font_size = 32
	hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(hp_label)

func _process(delta):
	if not player: return
	
	_update_hp_label()
	
	var dist_to_player = global_position.distance_to(player.global_position)
	
	match current_state:
		State.IDLE:
			_idle(delta, dist_to_player)
		State.PATROL:
			_patrol(delta, dist_to_player)
		State.CHASE:
			_chase(delta, dist_to_player)
		State.ATTACK:
			_attack(delta, dist_to_player)

func _idle(delta, dist):
	idle_timer -= delta
	# Slow rotation for ambiance
	rotation.y += delta * 0.2
	if dist < detection_range:
		_set_state(State.CHASE)
	elif idle_timer <= 0:
		_set_state(State.PATROL)

func _patrol(delta, dist):
	var dir = (patrol_target - global_position).normalized()
	global_position += dir * move_speed * delta
	look_at(patrol_target, Vector3.UP)
	
	if global_position.distance_to(patrol_target) < 2.0:
		patrol_target = global_position + Vector3(randf_range(-30, 30), 0, randf_range(-30, 30))
	
	if dist < detection_range:
		_set_state(State.CHASE)
	elif randf() < 0.002:
		_set_state(State.IDLE)
		idle_timer = randf_range(2.0, 5.0)

func _chase(delta, dist):
	var dir = (player.global_position - global_position).normalized()
	global_position += dir * chase_speed * delta
	look_at(player.global_position, Vector3.UP)
	
	if dist < attack_range:
		_set_state(State.ATTACK)
	elif dist > detection_range * 2:
		_set_state(State.IDLE)
		idle_timer = randf_range(2.0, 5.0)

func _attack(delta, dist):
	attack_timer -= delta
	look_at(player.global_position, Vector3.UP)
	
	if dist > attack_range:
		_set_state(State.CHASE)
	elif attack_timer <= 0:
		# Deal damage to player
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
			print("[AI] Dragon attacked player for ", attack_damage)
		attack_timer = attack_cooldown

func take_damage(amount: float):
	hp = max(hp - amount, 0)
	print("[AI] Dragon took ", amount, " damage. HP: ", hp, "/", max_hp)
	
	# Flash red
	# Flash handled via material
var model = get_node_or_null("DragonModel")
	if model:
		for c in model.get_children():
			if c is MeshInstance3D:
				var mat = c.get_surface_override_material(0)
				if mat: mat.albedo_color = Color(1, 0.2, 0.2)
	await get_tree().create_timer(0.2).timeout
	# Flash reset
var model2 = get_node_or_null("DragonModel")
	if model2:
		for c in model2.get_children():
			if c is MeshInstance3D:
				var mat = c.get_surface_override_material(0)
				if mat: mat.albedo_color = Color(0.6, 0.1, 0.1)
	
	if hp <= 0:
		_die()
	else:
		_set_state(State.CHASE)

func _die():
	print("[AI] Dragon ", name, " defeated!")
	if hp_label: hp_label.text = "DERROTADO!"
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _set_state(new_state: State):
	current_state = new_state
	if new_state == State.IDLE:
		idle_timer = randf_range(2.0, 5.0)

func _update_hp_label():
	if hp_label:
		hp_label.text = name_tag + "\nHP: " + str(int(hp)) + "/" + str(int(max_hp))
		var hp_ratio = hp / max_hp
		hp_label.modulate = Color(1, hp_ratio, hp_ratio)
