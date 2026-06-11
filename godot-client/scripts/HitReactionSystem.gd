extends Node

var target_body: Node3D
var original_pos: Vector3

func setup(body: Node3D):
	target_body = body

func hit_light(dir: Vector3):
	_recoil(dir, 0.2, 0.15)

func hit_medium(dir: Vector3):
	_recoil(dir, 0.4, 0.2)
	_body_flash(Color(1, 0.8, 0.8), 0.1)

func hit_heavy(dir: Vector3):
	_recoil(dir, 0.7, 0.3)
	_body_flash(Color(1, 0.5, 0.5), 0.2)
	_stagger(0.3)

func knockback(dir: Vector3, force: float = 1.0):
	if not target_body is CharacterBody3D: return
	target_body.velocity = dir.normalized() * force * 5.0

func shield_recoil(dir: Vector3):
	_recoil(dir, 0.15, 0.1)
	_body_flash(Color(0.9, 0.9, 1), 0.08)

func _recoil(dir: Vector3, dist: float, duration: float):
	if not target_body: return
	original_pos = target_body.global_position
	var start = target_body.global_position
	var target = start + dir.normalized() * dist
	var elapsed = 0.0
	while elapsed < duration and is_instance_valid(target_body):
		elapsed += 0.016
		var t = elapsed / duration
		target_body.global_position = start.lerp(target, t)
		await get_tree().process_frame
	if is_instance_valid(target_body): target_body.global_position = start

func _body_flash(col: Color, duration: float):
	if not target_body: return
	for child in target_body.get_children():
		if child is MeshInstance3D:
			var mat = child.get_surface_override_material(0)
			if mat and mat is StandardMaterial3D:
				var orig = mat.emission
				mat.emission_enabled = true
				mat.emission = col
				mat.emission_energy_multiplier = 3.0
				await get_tree().create_timer(duration).timeout
				if is_instance_valid(mat):
					mat.emission_enabled = false
					mat.emission = orig

func _stagger(duration: float):
	if not target_body: return
	if target_body is CharacterBody3D:
		target_body.velocity = Vector3.ZERO
	await get_tree().create_timer(duration).timeout
