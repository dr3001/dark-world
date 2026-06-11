extends Node3D

func _ready():
	_create_terrain()
	_create_trees()
	_create_rocks()
	_create_ruins()
	_create_lake()

func _create_terrain():
	var ground = $Ground
	if not ground: return
	
	# Keep the main ground plane - it already exists in World.tscn
	# Add some raised areas (hills)
	for i in range(15):
		var hill = _make_box(
			Vector3(randf_range(20, 40), randf_range(1, 4), randf_range(20, 40)),
			Color(0.25 + randf() * 0.1, 0.22 + randf() * 0.1, 0.15 + randf() * 0.1),
			Vector3(randf_range(-200, 200), randf_range(-0.5, 1), randf_range(-200, 200))
		)
		add_child(hill)

func _create_trees():
	for i in range(30):
		var pos = Vector3(randf_range(-200, 200), 0, randf_range(-200, 200))
		if pos.length() < 15: continue  # Skip center
		
		var tree = Node3D.new()
		tree.name = "Tree" + str(i)
		tree.position = pos
		
		# Trunk
		var trunk = _make_box(Vector3(0.3, randf_range(3, 6), 0.3), Color(0.3, 0.2, 0.1), Vector3(0, 2.5, 0))
		tree.add_child(trunk)
		
		# Canopy (2-3 layers of leaves)
		for j in range(randi() % 2 + 2):
			var leaf = _make_box(Vector3(randf_range(2, 4), 1.5, randf_range(2, 4)), Color(0.1, 0.3 + randf() * 0.2, 0.1), Vector3(0, 3.5 + j * 1.5, 0))
			tree.add_child(leaf)
		
		add_child(tree)

func _create_rocks():
	for i in range(50):
		var pos = Vector3(randf_range(-200, 200), 0, randf_range(-200, 200))
		if pos.length() < 10: continue
		var size = Vector3(randf_range(1, 5), randf_range(0.5, 3), randf_range(1, 5))
		var rock = _make_box(size, Color(0.3 + randf() * 0.2, 0.3 + randf() * 0.2, 0.3 + randf() * 0.2), pos + Vector3(0, size.y / 2, 0))
		rock.rotation_degrees = Vector3(randf_range(-10, 10), randf_range(0, 360), randf_range(-10, 10))
		add_child(rock)

func _create_ruins():
	for i in range(4):
		var pos = Vector3(randf_range(-180, 180), 0, randf_range(-180, 180))
		if pos.length() < 30: pos = Vector3(50 + i * 30, 0, 50 + i * 20)
		
		var ruin = Node3D.new()
		ruin.name = "Ruin" + str(i)
		ruin.position = pos
		
		# Pillars
		for j in range(4):
			var px = [ -4, 4, -4, 4 ][j]
			var pz = [ -3, -3, 3, 3 ][j]
			var pillar = _make_box(Vector3(0.8, randf_range(3, 6), 0.8), Color(0.4, 0.35, 0.3), Vector3(px, 2.5, pz))
			ruin.add_child(pillar)
		
		# Broken wall segments
		for j in range(3):
			var wall = _make_box(Vector3(3, 1.5, 0.4), Color(0.35, 0.3, 0.25), Vector3(j * 2 - 2, 1, -4 + j))
			ruin.add_child(wall)
		
		add_child(ruin)

func _create_lake():
	var lake = _make_box(Vector3(40, 0.1, 30), Color(0.1, 0.2, 0.4, 0.6), Vector3(60, 0.05, -40))
	lake.material_override = _make_water_material()
	add_child(lake)

func _make_box(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new(); box.size = size
	mi.mesh = box
	var mat = StandardMaterial3D.new(); mat.albedo_color = color
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	return mi

func _make_water_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.2, 0.4, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	mat.metallic = 0.5
	return mat
