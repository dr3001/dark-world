extends Node

var blood_pool: Array[Node3D] = []
var max_splashes: int = 20
var max_decals: int = 15
var brutality: String = "dark"

func setup(level: String = "dark"):
	brutality = level

func splash_small(pos: Vector3, dir: Vector3 = Vector3.UP):
	_spawn_blood(pos, dir, 0.3, Color(0.65, 0.05, 0.05), 3)

func splash_medium(pos: Vector3, dir: Vector3 = Vector3.UP):
	_spawn_blood(pos, dir, 0.5, Color(0.7, 0.03, 0.03), 5)

func splash_heavy(pos: Vector3, dir: Vector3 = Vector3.UP):
	_spawn_blood(pos, dir, 0.8, Color(0.55, 0.02, 0.02), 8)
	for i in range(3):
		var off = Vector3(randf_range(-0.5,0.5), randf_range(0,0.3), randf_range(-0.5,0.5))
		_spawn_blood(pos+off, dir+Vector3(randf_range(-1,1),0,randf_range(-1,1)), 0.2, Color(0.6,0.04,0.04), 2)

func burst(pos: Vector3):
	for i in range(6):
		var dir = Vector3(randf_range(-1,1), randf_range(0,2), randf_range(-1,1)).normalized()
		_spawn_blood(pos, dir, randf_range(0.1,0.4), Color(0.6, 0.03, 0.03), 4)

func decal_ground(pos: Vector3, size: float = 0.6):
	var d = _make_decal(pos, size, Color(0.35, 0.02, 0.02, 0.7))
	get_parent().add_child(d)
	blood_pool.append(d)

func clear_all():
	for b in blood_pool:
		if is_instance_valid(b): b.queue_free()
	blood_pool.clear()

func _spawn_blood(pos: Vector3, dir: Vector3, size: float, col: Color, count: int):
	if brutality == "clean": return
	if brutality == "dark" and count > 4: count = 4
	for i in range(count):
		var s = MeshInstance3D.new()
		var sp = SphereMesh.new(); sp.radius = size * randf_range(0.3, 1.0); sp.height = sp.radius * 2
		s.mesh = sp
		var m = StandardMaterial3D.new(); m.albedo_color = col; m.roughness = 1.0
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		s.set_surface_override_material(0, m)
		s.position = pos + Vector3(randf_range(-0.2,0.2), randf_range(-0.1,0.3), randf_range(-0.2,0.2))
		get_parent().add_child(s)
		blood_pool.append(s)
	var t = get_tree().create_timer(2.0)
	t.timeout.connect(_cleanup_pool)

func _make_decal(pos: Vector3, size: float, col: Color) -> MeshInstance3D:
	var d = MeshInstance3D.new()
	var p = PlaneMesh.new(); p.size = Vector2(size, size)
	d.mesh = p; d.position = Vector3(pos.x, 0.02, pos.z)
	var m = StandardMaterial3D.new(); m.albedo_color = col; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	d.set_surface_override_material(0, m)
	return d

func _cleanup_pool():
	var to_remove: Array = []
	for i in range(blood_pool.size()):
		if not is_instance_valid(blood_pool[i]):
			to_remove.append(i)
			continue
		blood_pool[i].modulate.a -= 0.3
		if blood_pool[i].modulate.a <= 0:
			blood_pool[i].queue_free()
			to_remove.append(i)
	for idx in to_remove: blood_pool.remove_at(idx)
	while blood_pool.size() > max_splashes:
		if is_instance_valid(blood_pool[0]): blood_pool[0].queue_free()
		blood_pool.pop_front()
