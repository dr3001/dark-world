extends Node
func _ready():
	print("=== LOADING World.tscn ===")
	var ws = load("res://scenes/World.tscn")
	print("World.tscn load: ", ws, " valid=", ws != null)
	if ws:
		var w = ws.instantiate()
		print("instantiated: ", w, " class=", w.get_class(), " script=", w.get_script() != null)
		add_child(w)
		await get_tree().process_frame
		
		# Try loading dragon
		print("=== LOADING Dragon.tscn ===")
		var ds = load("res://scenes/models/Dragon.tscn")
		print("Dragon.tscn load: ", ds, " valid=", ds != null)
		if ds:
			var d = ds.instantiate()
			d.position = Vector3(10, 0, 10)
			add_child(d)
			await get_tree().process_frame
			
			# Count ALL meshes
			var count = _count_all_meshes(get_tree().root)
			print("TOTAL MeshInstance3D in tree: ", count)
		else:
			print("DRAGON LOAD FAILED!")
	else:
		print("WORLD LOAD FAILED!")
	
	print("=== TEST DONE ===")
	get_tree().quit()

func _count_all_meshes(n):
	var c = 0
	if n is MeshInstance3D: c += 1
	for child in n.get_children(): c += _count_all_meshes(child)
	return c
