extends Node

var decals: Array[MeshInstance3D] = []
var max_decals: int = 15

func spawn_decal(decal_type: String, pos: Vector3, dir: Vector3 = Vector3.UP):
	var cfg = _decal_config(decal_type)
	var d = MeshInstance3D.new()
	var p = PlaneMesh.new(); p.size = Vector2(cfg.size, cfg.size)
	d.mesh = p
	d.position = Vector3(pos.x, 0.03, pos.z)
	d.rotation_degrees = Vector3(-90, randf_range(0, 360), 0)
	var m = StandardMaterial3D.new(); m.albedo_color = cfg.color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	d.set_surface_override_material(0, m)
	get_parent().add_child(d)
	decals.append(d)
	_fade_decal(d, cfg.lifetime)
	_cleanup()

func clear_all():
	for d in decals:
		if is_instance_valid(d): d.queue_free()
	decals.clear()

func _decal_config(type: String) -> Dictionary:
	match type:
		"blood": return {size=0.5, color=Color(0.4,0.02,0.02,0.6), lifetime=20.0}
		"sword": return {size=0.3, color=Color(0.3,0.3,0.3,0.5), lifetime=15.0}
		"arrow": return {size=0.2, color=Color(0.25,0.2,0.15,0.5), lifetime=15.0}
		"fire": return {size=0.4, color=Color(0.6,0.2,0.05,0.4), lifetime=10.0}
		"ice": return {size=0.3, color=Color(0.3,0.6,1,0.4), lifetime=10.0}
		"poison": return {size=0.35, color=Color(0.2,0.7,0.2,0.4), lifetime=12.0}
		"dust": return {size=0.5, color=Color(0.5,0.4,0.3,0.3), lifetime=8.0}
		_: return {size=0.3, color=Color(0.5,0.5,0.5,0.4), lifetime=10.0}

func _fade_decal(d: MeshInstance3D, lifetime: float):
	var elapsed = 0.0
	while elapsed < lifetime and is_instance_valid(d):
		elapsed += 0.5
		if elapsed > lifetime - 3.0:
			d.modulate.a = 1.0 - (elapsed - (lifetime - 3.0)) / 3.0
		await get_tree().create_timer(0.5).timeout
	if is_instance_valid(d): d.queue_free()

func _cleanup():
	while decals.size() > max_decals:
		if is_instance_valid(decals[0]): decals[0].queue_free()
		decals.pop_front()
