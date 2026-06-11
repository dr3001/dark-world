extends Node

func _ready():
	print("=== TESTLOADER: _ready() ===")
	
	# Load World scene resource
	print("Loading World.tscn...")
	var world_res = load("res://scenes/World.tscn")
	print("  Resource: ", world_res, " valid=", world_res != null)
	
	if world_res:
		var world = world_res.instantiate()
		print("  Instantiated: ", world, " class=", world.get_class())
		print("  Script: ", world.get_script())
		print("  Children: ", world.get_child_count())
		
		for i in range(world.get_child_count()):
			var c = world.get_child(i)
			print("    [", i, "] ", c.name, " (", c.get_class(), ")")
		
		var cam = world.get_node_or_null("Camera3D")
		print("  Camera3D: ", cam != null, " current=", cam.current if cam else "?")
		
		add_child(world)
		print("  Added to tree - World._ready() should execute NOW")
	
	await get_tree().create_timer(1.0).timeout
	print("=== TESTLOADER: DONE ===")
	get_tree().quit()
