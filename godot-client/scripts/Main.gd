extends Control

# Dark World — Main Controller

var network: Node
var current_account_id: String = ""
var current_entity_id: String = ""
var current_life_state: String = "alive"

const WORLD_SCENE = "res://scenes/World.tscn"

@onready var status_label: Label = $"StatusLabel"
@onready var enter_btn: Button = $"EnterButton"
@onready var create_btn: Button = $"CreateAccountButton"
@onready var quit_btn: Button = $"QuitButton"

func _ready():
	var NetScript = load("res://scripts/NetworkClient.gd")
	network = NetScript.new()
	network.name = "NetworkClient"
	add_child(network)
	
	enter_btn.pressed.connect(_on_enter_pressed)
	create_btn.pressed.connect(_on_create_account_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _on_create_account_pressed():
	_set_status("Criando conta...")
	network.create_account("Heroi Mac " + str(randi() % 1000), _on_account_created)

func _on_account_created(data: Dictionary):
	if data.has("account"):
		current_account_id = data["account"]["id"]
		_set_status("Conta criada! Entrando...")
		network.create_character(current_account_id, "Heroi Mac", _on_character_created)
	else:
		_set_status("Erro ao criar conta")

func _on_character_created(data: Dictionary):
	if data.has("character"):
		current_entity_id = data["character"]["entity_id"]
		current_life_state = data["character"]["life_state"]
		get_tree().root.set_meta("character_id", data["character"]["id"])
		get_tree().root.set_meta("account_id", current_account_id)
		get_tree().root.set_meta("entity_id", current_entity_id)
		_set_status("Entrando no Vale Cinzento...")
		await get_tree().create_timer(1.0).timeout
		_enter_world()
	else:
		_set_status("Erro ao criar personagem")

func _on_enter_pressed():
	if current_entity_id != "":
		_enter_world()
	else:
		_set_status("Crie uma conta primeiro")

func _enter_world():
	_set_status("Entrando no Vale Cinzento...")
	get_tree().change_scene_to_file(WORLD_SCENE)

func _on_quit_pressed():
	get_tree().quit()

func _set_status(msg: String):
	if status_label: status_label.text = msg
	print("[Main] ", msg)
