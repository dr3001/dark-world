extends Node3D
func _ready():
	print("=== DRAGON LOAD TEST ===")
	var dragon_scene = load("res://scenes/models/Dragon.tscn")
	print("load result: ", dragon_scene, " valid: ", dragon_scene != null)
	if dragon_scene:
		var dragon = dragon_scene.instantiate()
		print("instantiated: ", dragon, " class: ", dragon.get_class())
		print("script: ", dragon.get_script())
		dragon.position = Vector3(0, 0, 5)
		add_child(dragon)
		print("added to tree")
		await get_tree().process_frame
		# Count meshes
		var count = 0
		for c in dragon.get_children():
			count += _count_meshes(c)
		print("Total MeshInstance3D in dragon: ", count)
	else:
		print("FAILED TO LOAD Dragon.tscn!")
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

func _count_meshes(n):
	var c = 0
	if n is MeshInstance3D: c += 1
	for child in n.get_children(): c += _count_meshes(child)
	return c
