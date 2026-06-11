extends Control

var network: Node
var current_account_id: String = ""
var current_entity_id: String = ""
var current_character_id: String = ""

const WORLD_SCENE = "res://scenes/World.tscn"
const LANDING_URL = "https://dark.zorionlabs.net"
const LOCAL_VERSION = "4.3.2"

@onready var status_label: Label = $"StatusLabel"
@onready var enter_btn: Button = $"EnterButton"
@onready var create_btn: Button = $"CreateAccountButton"
@onready var quit_btn: Button = $"QuitButton"
@onready var email_input: LineEdit = $"EmailInput"
@onready var password_input: LineEdit = $"PasswordInput"

func _ready():
	var NetScript = load("res://scripts/NetworkClient.gd")
	network = NetScript.new()
	network.name = "NetworkClient"
	add_child(network)
	enter_btn.pressed.connect(_on_enter_pressed)
	create_btn.pressed.connect(_on_create_account_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	enter_btn.disabled = true
	create_btn.disabled = true
	_check_version()

func _check_version():
	_set_status("Verificando atualizacao...")
	var http = HTTPRequest.new(); add_child(http)
	http.request_completed.connect(func(_r, code, _h, resp):
		if code != 200 or not resp:
			_set_status("Servidor indisponivel. Tente novamente.")
			return
		var data = JSON.parse_string(resp.get_string_from_utf8())
		if not data: return
		var remote = data.get("game_version", "0")
		var force = data.get("force_update", false)
		if remote != LOCAL_VERSION:
			_set_status("Atualizacao disponivel: v" + str(remote) + " (local: v" + LOCAL_VERSION + ")")
			if force:
				_set_status("ATUALIZACAO OBRIGATORIA! Baixe a versao mais recente.")
				enter_btn.text = "Atualizacao Necessaria"
				enter_btn.disabled = true
				create_btn.text = "Baixar v" + str(remote)
				create_btn.disabled = false
				return
		_set_status("v" + LOCAL_VERSION + " — Pronto.")
		enter_btn.disabled = false
		create_btn.disabled = false
		_register_device()
		http.queue_free()
	, CONNECT_ONE_SHOT)
	http.request("https://dark.zorionlabs.net/api/launcher/manifest")

func _register_device():
	var http = HTTPRequest.new(); add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free(), CONNECT_ONE_SHOT)
	var inst_id = OS.get_unique_id() if OS.has_feature("unique_id") else "DW-" + str(Time.get_unix_time_from_system())
	http.request("https://dark.zorionlabs.net/dw-api/launcher/register-device", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({
		"installation_id": inst_id,
		"device_id_hash": str(OS.get_unique_id()).sha256_text().substr(0, 16),
		"os": OS.get_name()
	}))

func _on_enter_pressed():
	var email = email_input.text.strip_edges() if email_input else ""
	var password = password_input.text if password_input else ""
	if email != "" and password != "":
		_set_status("Autenticando...")
		network.auth_login(email, password, _on_login_response)
	elif current_entity_id != "":
		_enter_world()
	else:
		_set_status("Digite seu email e senha, ou crie uma conta no portal.")

func _on_login_response(data):
	if not data:
		_set_status("Erro de conexao")
		return
	if data.has("error"):
		_set_status(str(data["error"]))
		return
	if data.has("token") and data.has("user"):
		current_account_id = data["user"]["id"]
		_set_status("Login OK! Buscando personagem...")
		get_tree().root.set_meta("account_id", current_account_id)
		get_tree().root.set_meta("auth_token", data["token"])
		get_tree().root.set_meta("user_role", data["user"].get("role", "player"))
		get_tree().root.set_meta("vip_level", data["user"].get("vip_level", 0))
		network.create_character(current_account_id, data["user"].get("display_name", "Hero"), _on_character_created)

func _on_create_account_pressed():
	OS.shell_open(LANDING_URL + "/register")
	_set_status("Abra o navegador para criar sua conta.")

func _on_account_created(data):
	if data and data.has("account"):
		current_account_id = data["account"]["id"]
		_set_status("Conta criada! Criando personagem...")
		network.create_character(current_account_id, "Hero", _on_character_created)
	else:
		_set_status("Erro ao criar conta")

func _on_character_created(data):
	if data and data.has("character"):
		current_entity_id = data["character"]["entity_id"]
		current_character_id = data["character"]["id"]
		get_tree().root.set_meta("character_id", current_character_id)
		get_tree().root.set_meta("account_id", current_account_id)
		get_tree().root.set_meta("entity_id", current_entity_id)
		_set_status("Entrando no Vale Cinzento...")
		await get_tree().create_timer(1.0).timeout
		_enter_world()
	else:
		_set_status("Erro ao criar personagem")

func _enter_world():
	get_tree().change_scene_to_file(WORLD_SCENE)

func _on_quit_pressed():
	get_tree().quit()

func _set_status(msg: String):
	if status_label: status_label.text = msg
	print("[Main] ", msg)
