extends Node

var particles: Array[Node3D] = []
var max_particles: int = 50

func spawn_impact(impact_type: String, pos: Vector3, dir: Vector3 = Vector3.UP):
	var config = _type_config(impact_type)
	for i in range(config.count):
		var p = MeshInstance3D.new()
		var sp = SphereMesh.new(); sp.radius = config.size * randf_range(0.3, 1.2); sp.height = sp.radius * 2
		p.mesh = sp
		var m = StandardMaterial3D.new()
		m.albedo_color = config.color
		m.emission_enabled = config.emission
		if config.emission: m.emission = config.color; m.emission_energy_multiplier = 0.5
		if config.alpha: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		p.set_surface_override_material(0, m)
		p.position = pos + Vector3(randf_range(-0.3,0.3), randf_range(0,0.5), randf_range(-0.3,0.3))
		get_parent().add_child(p)
		particles.append(p)
		var vel = (dir + Vector3(randf_range(-1,1), randf_range(0.5,2), randf_range(-1,1))).normalized() * config.speed
		_animate_particle(p, vel, config.lifetime)
	_cleanup()

func _type_config(type: String) -> Dictionary:
	match type:
		"metal": return {count=8, size=0.08, color=Color(0.9,0.85,0.2), speed=3.0, lifetime=0.6, emission=true, alpha=false}
		"wood": return {count=6, size=0.1, color=Color(0.5,0.3,0.15), speed=2.0, lifetime=0.5, emission=false, alpha=false}
		"stone": return {count=10, size=0.12, color=Color(0.5,0.5,0.45), speed=2.5, lifetime=0.7, emission=false, alpha=false}
		"flesh": return {count=4, size=0.06, color=Color(0.6,0.15,0.1), speed=1.5, lifetime=0.5, emission=false, alpha=true}
		"shield": return {count=12, size=0.05, color=Color(1,0.9,0.3), speed=4.0, lifetime=0.3, emission=true, alpha=false}
		"magic": return {count=15, size=0.07, color=Color(0.3,0.3,1), speed=2.0, lifetime=0.8, emission=true, alpha=true}
		"fire": return {count=10, size=0.1, color=Color(1,0.4,0.1), speed=1.5, lifetime=1.0, emission=true, alpha=true}
		"ice": return {count=8, size=0.08, color=Color(0.5,0.8,1), speed=2.0, lifetime=0.8, emission=true, alpha=true}
		"wind": return {count=6, size=0.06, color=Color(0.7,0.75,0.8), speed=5.0, lifetime=0.4, emission=false, alpha=true}
		"earth": return {count=10, size=0.15, color=Color(0.4,0.3,0.2), speed=1.5, lifetime=0.7, emission=false, alpha=false}
		"darkness": return {count=8, size=0.08, color=Color(0.15,0.05,0.25), speed=1.0, lifetime=1.0, emission=true, alpha=true}
		_: return {count=5, size=0.1, color=Color(0.7,0.7,0.7), speed=2.0, lifetime=0.5, emission=false, alpha=false}

func _animate_particle(p: MeshInstance3D, velocity: Vector3, lifetime: float):
	var elapsed = 0.0
	while elapsed < lifetime and is_instance_valid(p):
		elapsed += 0.016
		p.position += velocity * 0.016
		velocity *= 0.9
		p.modulate.a = 1.0 - (elapsed / lifetime)
		p.scale = Vector3.ONE * (1.0 - elapsed / lifetime * 0.5)
		await get_tree().process_frame
	if is_instance_valid(p): p.queue_free()

func _cleanup():
	while particles.size() > max_particles:
		if is_instance_valid(particles[0]): particles[0].queue_free()
		particles.pop_front()
