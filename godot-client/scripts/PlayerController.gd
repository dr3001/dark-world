extends CharacterBody3D

@export var speed: float = 5.0
@export var run_speed: float = 10.0
@export var jump_velocity: float = 8.0
@export var gravity: float = 20.0
@export var accel: float = 25.0
@export var decel: float = 18.0
@export var rot_speed: float = 10.0
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
var shield_active: bool = false
var shield_defense: float = 0.0
var skills_ready: Dictionary = {
	"slash": {"cooldown": 0.0, "ready": true, "mana": 5},
	"fireball": {"cooldown": 0.0, "ready": true, "mana": 15},
	"heal": {"cooldown": 0.0, "ready": true, "mana": 20}
}

func _ready():
	for c in get_children():
		if c is Node3D and c.name != "CollisionShape3D":
			player_model = c
			break
	# Check if we have shield equipment
	var eq_data = get_node_or_null("../World") if get_node_or_null("../World") else null
	pass

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	var current_speed = run_speed if Input.is_key_pressed(KEY_SHIFT) else speed
	var input_dir = Vector3.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.z -= 1
	if Input.is_key_pressed(KEY_S): input_dir.z += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	input_dir = input_dir.normalized()
	is_moving = input_dir != Vector3.ZERO
	if input_dir != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, input_dir.x * current_speed, accel * delta)
		velocity.z = move_toward(velocity.z, input_dir.z * current_speed, accel * delta)
		var target_angle = atan2(input_dir.x, -input_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rot_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decel * delta)
		velocity.z = move_toward(velocity.z, 0, decel * delta)
	move_and_slide()
	if global_position.y < -10:
		global_position = Vector3(0, 5, 0)
		velocity = Vector3.ZERO
	if player_model and player_model.has_method("animate_walk"):
		player_model.animate_walk(delta, is_moving)
	for sn in skills_ready:
		var sk = skills_ready[sn]
		if not sk.ready:
			sk.cooldown -= delta
			if sk.cooldown <= 0:
				sk.cooldown = 0
				sk.ready = true
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
		velocity.x = move_toward(velocity.x, input_dir.x * current_speed, accel * delta)
		velocity.z = move_toward(velocity.z, input_dir.z * current_speed, accel * delta)
		var target_angle = atan2(input_dir.x, -input_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rot_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decel * delta)
		velocity.z = move_toward(velocity.z, 0, decel * delta)
	
	move_and_slide()
	
	if global_position.y < -10:
		global_position = Vector3(0, 5, 0)
		velocity = Vector3.ZERO
	
	if player_model and player_model.has_method("animate_walk"):
		player_model.animate_walk(delta, is_moving)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_attack()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_toggle_shield()
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Q: _use_skill("slash")
			KEY_R: _use_skill("fireball")
			KEY_T: _use_skill("heal")

func _toggle_shield():
	shield_active = !shield_active
	shield_defense = 3.0
	print("[COMBAT] Shield: ", shield_active)

func _use_skill(skill_name: String):
	var sk = skills_ready.get(skill_name, {})
	if not sk.ready: return
	sk.ready = false
	sk.cooldown = 2.0
	match skill_name:
		"slash": _melee_skill(8.0, "metal")
		"fireball": _projectile_skill(12.0, "fire")
		"heal": _heal_self()
	print("[SKILL] ", skill_name, " used")

func _melee_skill(dmg: float, impact: String):
	var space = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new(); sphere.radius = 5.0
	query.shape = sphere; query.transform = Transform3D(Basis(), global_position)
	for result in space.intersect_shape(query):
		var c = result.get("collider")
		if c and c != self and c.has_method("take_damage"):
			c.take_damage(dmg)
			var cs = get_node_or_null("../CombatSystem")
			if cs and cs.has_signal("hit_dealt"): cs.hit_dealt.emit(c, dmg, impact)
			return

func _projectile_skill(dmg: float, impact: String):
	var space = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new(); sphere.radius = 8.0
	query.shape = sphere; query.transform = Transform3D(Basis(), global_position)
	for result in space.intersect_shape(query):
		var c = result.get("collider")
		if c and c != self and c.has_method("take_damage"):
			c.take_damage(dmg)
			var cs = get_node_or_null("../CombatSystem")
			if cs and cs.has_signal("critical_hit"): cs.critical_hit.emit(c, dmg)
			return

func _heal_self():
	hp = min(hp + 25, max_hp)
	var cs = get_node_or_null("../CombatSystem")
	if cs and cs.has_signal("hit_dealt"): pass # visual feedback via World.gd

func _attack():
	var cs = get_node_or_null("../CombatSystem")
	if not cs or not cs.has_method("try_attack"): return
	if not cs.try_attack(): return
	var space = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 4.0
	query.shape = sphere
	query.transform = Transform3D(Basis(), global_position)
	var results = space.intersect_shape(query)
	var best_target: Node3D = null
	var best_dist = 99.0
	for result in results:
		var collider = result.get("collider")
		if not collider: continue
		if collider == self: continue
		if collider is CharacterBody3D and collider != self: best_target = collider; break
		var parent = collider.get_parent()
		while parent:
			if parent.has_method("take_damage"):
				var d = global_position.distance_to(parent.global_position)
				if d < best_dist: best_dist = d; best_target = parent
				break
			parent = parent.get_parent()
	if not best_target: cs.state = 0; return
	var stats = {"strength": 5, "luck": 1}
	var result = cs.resolve_hit(best_target, self, stats)
	if not result.get("hit"): return
	cs.apply_damage(best_target, result, self)
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
	if shield_active:
		var mitigated = floor(amount * 0.5)
		amount = mitigated
		if amount < 1: amount = 1
	hp = max(hp - amount, 0)
	if shield_active:
		shield_defense = max(0, shield_defense - 1)
		if shield_defense <= 0: shield_active = false
	print("[COMBAT] Player took ", amount, " damage. HP: ", hp, " Shield: ", shield_active)
	if hp <= 0:
		die()

func die():
	print("[COMBAT] Player died!")
	hp = max_hp
	mana = max_mana
	global_position = Vector3(0, 5, 0)
	velocity = Vector3.ZERO
