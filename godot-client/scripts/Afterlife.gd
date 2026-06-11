extends Node3D

func _ready():
	print("[AFTERLIFE] _ready() — Mundo Congelado carregado")
	
	var return_btn = get_node_or_null("HUD/ReturnButton")
	if return_btn:
		print("[AFTERLIFE] ReturnButton found, connecting...")
		return_btn.pressed.connect(_on_return)
	else:
		print("[AFTERLIFE] ReturnButton NOT found!")

func _on_return():
	print("[AFTERLIFE] Return requested — voltando ao Mundo dos Vivos")
	get_tree().change_scene_to_file("res://scenes/World.tscn")
