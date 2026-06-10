extends Node3D

# Dark World — Afterlife Scene (Mundo Congelado)

var network: NetworkClient

const WORLD_SCENE = "res://scenes/World.tscn"

func _ready():
	var label = $HUD/AfterlifeLabel
	if label:
		label.text = "Voce despertou no Mundo Congelado.\nAguarde o retorno ou pressione R."
	
	var return_btn = $HUD/ReturnButton
	if return_btn:
		return_btn.pressed.connect(_on_return_pressed)

func _on_return_pressed():
	get_tree().change_scene_to_file(WORLD_SCENE)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			get_tree().change_scene_to_file(WORLD_SCENE)
		if event.keycode == KEY_K:
			# Also allow death from here (for testing)
			pass
