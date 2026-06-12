extends Node3D

const SERVER_URL = "https://dark.zorionlabs.net/dw-api"

var player: CharacterBody3D
var cam: Camera3D
var hp_bar: ColorRect; var hp_text: Label; var fps_label: Label
var quest_text: Label; var pos_label: Label; var obj_label: Label
var tree_count: int = 0; var house_count: int = 0; var npc_count: int = 0; var dragon_count: int = 0
var dialog_panel: ColorRect; var dialog_name_label: Label; var dialog_text_label: Label
var interact_hint: Label; var dialog_open: bool = false; var nearest_npc: Node3D = null
var quest_stage: int = 0
var inventory_panel: ColorRect; var level_label: Label; var zorium_label: Label
var char_profile = null; var equip_panel_ui = null; var journal = null
var tooltip_node = null; var inv_system = null; var combat_sys = null
var loot_sys = null; var save_indicator: Label = null
var equipment_panel_node: ColorRect; var journal_panel_node: ColorRect
var character_id: String = ""; var auto_save_timer: float = 0.0
var net = null; var chat_display = null; var chat_panel_node: ColorRect
var speech_bubble = null; var mp_sync = null; var online_label: Label
var world_sim = null; var time_label: Label; var weather_label_node: Label
var class_label: Label; var server_label: Label
var blood_fx = null; var impact_fx = null; var decal_fx = null
var reaction_fx = null; var camera_fx = null; var audio_fx = null
var vfx_event_system = null; var hit_ui = null; var shield_vfx = null
var wind_vfx = null; var ground_vfx = null
var climate_combat = null; var vfx_budget = null
var npc_dialogs: Dictionary = {
	"Guardiao_do_Vale": "Mantenha-se atento aos perigos da regiao.",
	"Ferreiro_Thorin": "Posso forjar armas para aventureiros.",
	"Mercador_Ivan": "Tenho mercadorias para viajantes.",
	"Curandeira_Lyra": "Vorak ameaca o Vale Cinzento.\nDerrote-o antes que seja tarde.",
	"Campones_Finn": "A vida era mais tranquila antes de Vorak.",
	"Escriba_do_Vale": "Sou o cronista do Vale Cinzento.\nRegistro feitos, guerras e historias.\n[P] para ver seu perfil.",
	"Arauto_do_Vale": "Sou o mensageiro do Vale.\nAnuncio eventos, temporadas e noticias.\nFique atento aos avisos no chat do sistema.",
	"Mestre_de_Armas": "Sou o Mestre de Armas do Vale.\nTreine sua postura e golpes aqui,\nlonge dos olhos de Vorak."
}

func _ready():
	GameLogger.write_log("[WORLD] START")
	hp_bar = get_node_or_null("HUD/HPBar"); hp_text = get_node_or_null("HUD/HPText")
	fps_label = get_node_or_null("HUD/FPS"); quest_text = get_node_or_null("HUD/QuestText")
	pos_label = get_node_or_null("HUD/Position"); obj_label = get_node_or_null("HUD/ObjectCount")
	_hide_debug_hud()
	dialog_panel = get_node_or_null("HUD/DialogPanel")
	dialog_name_label = get_node_or_null("HUD/DialogPanel/DialogName")
	dialog_text_label = get_node_or_null("HUD/DialogPanel/DialogText")
	interact_hint = get_node_or_null("HUD/InteractHint")
	inventory_panel = get_node_or_null("HUD/InventoryPanel")
	level_label = get_node_or_null("HUD/LevelLabel")
	zorium_label = get_node_or_null("HUD/ZoriumLabel")
	cam = $Camera3D
	
	# BUILD WORLD FIRST — before any script loading
	# This ensures Windows gets the same world as Mac
	GameLogger.write_log("[WORLD] Building world...")
	_build_plaza()
	_spawn_player()
	_build_village()
	_build_walls()
	_build_rocks()
	_spawn_npcs()
	_build_castle()
	_spawn_dragon()
	_build_trees()
	_build_road_torches()
	GameLogger.write_log("[WORLD] DONE - Trees:" + str(tree_count) + " Houses:" + str(house_count) + " NPCs:" + str(npc_count) + " Dragons:" + str(dragon_count))
	GameLogger.write_log("[WORLD] Vale Cinzento — " + str(get_child_count()) + " objetos carregados")
	var env = get_node_or_null("WorldEnvironment")
	if env and env.environment:
		env.environment.fog_density = 0.00015
	if obj_label and not OS.is_debug_build():
		obj_label.visible = false
	if inventory_panel: inventory_panel.visible = false
	equipment_panel_node = get_node_or_null("HUD/EquipmentPanel")
	journal_panel_node = get_node_or_null("HUD/JournalPanel")
	save_indicator = get_node_or_null("HUD/SaveIndicator")
	var tp = get_node_or_null("HUD/TooltipPanel")
	if tp: tp.queue_free()
	var TipScript = load("res://scripts/ItemTooltip.gd")
	if TipScript:
		tooltip_node = TipScript.new(); tooltip_node.name = "TooltipPanel"
		get_node("HUD").add_child(tooltip_node)
	character_id = get_tree().root.get_meta("character_id", "")
	var CharProfileScript = load("res://scripts/CharacterProfile.gd")
	if CharProfileScript:
		char_profile = CharProfileScript.new(); add_child(char_profile)
		char_profile.set_character_id(character_id)
	var InvScript = load("res://scripts/InventorySystem.gd")
	if InvScript:
		inv_system = InvScript.new(); add_child(inv_system)
		inv_system.setup(inventory_panel, tooltip_node)
		inv_system.item_selected.connect(_on_inventory_item_selected)
	var EquipScript = load("res://scripts/EquipmentPanel.gd")
	if EquipScript:
		equip_panel_ui = EquipScript.new(); add_child(equip_panel_ui)
		equip_panel_ui.setup(equipment_panel_node)
		equip_panel_ui.on_unequip_callback = func(slot_type):
			if net and character_id != "":
				net.unequip_item(character_id, slot_type, func(_d): pass)
	var JournalScript = load("res://scripts/QuestJournal.gd")
	if JournalScript:
		journal = JournalScript.new(); add_child(journal)
		journal.setup(journal_panel_node)
	var CombatScript = load("res://scripts/CombatSystem.gd")
	if CombatScript:
		combat_sys = CombatScript.new(); add_child(combat_sys)
		combat_sys.hit_dealt.connect(_on_hit_dealt)
		combat_sys.critical_hit.connect(_on_critical_hit)
		combat_sys.target_died.connect(_on_target_died)
		combat_sys.target_blocked.connect(_on_target_blocked)
	var LootScript = load("res://scripts/LootTable.gd")
	if LootScript:
		loot_sys = LootScript.new(); add_child(loot_sys)
	var NetScript = load("res://scripts/NetworkClient.gd")
	if NetScript:
		net = NetScript.new(); net.name = "NetClient"; add_child(net)
	chat_panel_node = get_node_or_null("HUD/ChatPanel")
	var BubbleScript = load("res://scripts/SpeechBubble.gd")
	if BubbleScript:
		speech_bubble = BubbleScript.new(); speech_bubble.name = "SpeechBubble"; add_child(speech_bubble)
	var ChatScript = load("res://scripts/ChatDisplay.gd")
	if ChatScript:
		chat_display = ChatScript.new(); add_child(chat_display)
		chat_display.setup(chat_panel_node)
	
	if quest_text: quest_text.text = "Explore o Vale Cinzento"
	online_label = get_node_or_null("HUD/OnlineCount")
	class_label = get_node_or_null("HUD/ClassLabel")
	server_label = get_node_or_null("HUD/ServerLabel")
	time_label = get_node_or_null("HUD/TimeLabel")
	weather_label_node = get_node_or_null("HUD/WeatherLabel")
	if time_label:
		time_label.text = ""
	if weather_label_node:
		weather_label_node.text = ""
	var WSScript = load("res://scripts/WorldSimulation.gd")
	if WSScript:
		world_sim = WSScript.new(); world_sim.name = "WorldSim"; add_child(world_sim)
		world_sim.setup($SunLight, $WorldEnvironment, time_label, weather_label_node)
	var BloodScript = load("res://scripts/BloodEffectSystem.gd")
	if BloodScript: blood_fx = BloodScript.new(); blood_fx.name = "BloodFX"; add_child(blood_fx)
	var ImpactScript = load("res://scripts/ImpactParticleSystem.gd")
	if ImpactScript: impact_fx = ImpactScript.new(); impact_fx.name = "ImpactFX"; add_child(impact_fx)
	var DecalScript = load("res://scripts/CombatDecalSystem.gd")
	if DecalScript: decal_fx = DecalScript.new(); decal_fx.name = "DecalFX"; add_child(decal_fx)
	var ReactionScript = load("res://scripts/HitReactionSystem.gd")
	if ReactionScript: reaction_fx = ReactionScript.new(); reaction_fx.name = "ReactionFX"; add_child(reaction_fx)
	var CameraFxScript = load("res://scripts/CombatCameraFeedback.gd")
	if CameraFxScript: camera_fx = CameraFxScript.new(); camera_fx.name = "CameraFX"; add_child(camera_fx); camera_fx.setup(cam)
	var AudioFxScript = load("res://scripts/CombatAudioSystem.gd")
	if AudioFxScript: audio_fx = AudioFxScript.new(); audio_fx.name = "AudioFX"; add_child(audio_fx)
	var VFSEventScript = load("res://scripts/CombatVisualEventSystem.gd")
	if VFSEventScript:
		vfx_event_system = VFSEventScript.new(); vfx_event_system.name = "VFXEvents"; add_child(vfx_event_system)
		vfx_event_system.setup(blood_fx, impact_fx, decal_fx, reaction_fx, camera_fx, audio_fx)
	var HitUIScript = load("res://scripts/HitFeedbackUI.gd")
	if HitUIScript: hit_ui = HitUIScript.new(); hit_ui.name = "HitUI"; add_child(hit_ui)
	var ShieldVFSScript = load("res://scripts/ShieldImpactVisualSystem.gd")
	if ShieldVFSScript: shield_vfx = ShieldVFSScript.new(); shield_vfx.name = "ShieldVFX"; add_child(shield_vfx); shield_vfx.setup(impact_fx, audio_fx, camera_fx)
	var WindVFSScript = load("res://scripts/ProjectileWindInfluenceVisual.gd")
	if WindVFSScript: wind_vfx = WindVFSScript.new(); wind_vfx.name = "WindVFX"; add_child(wind_vfx)
	var GroundVFSScript = load("res://scripts/GroundImpactSystem.gd")
	if GroundVFSScript: ground_vfx = GroundVFSScript.new(); ground_vfx.name = "GroundVFX"; add_child(ground_vfx); ground_vfx.setup(impact_fx, decal_fx)
	var ClimateScript = load("res://scripts/CombatClimateIntegration.gd")
	if ClimateScript: climate_combat = ClimateScript.new(); climate_combat.name = "ClimateCombat"; add_child(climate_combat)
	var BudgetScript = load("res://scripts/CombatVFXPerformanceBudget.gd")
	if BudgetScript: vfx_budget = BudgetScript.new(); vfx_budget.name = "VFXBudget"; add_child(vfx_budget)
	var MPScript = load("res://scripts/MultiplayerSync.gd")
	if MPScript and net and player:
		mp_sync = MPScript.new(); mp_sync.name = "MultiplayerSync"; add_child(mp_sync)
		mp_sync.setup(net, character_id, player, online_label)
	_load_character_data()
	if blood_fx and character_id != "":
		var cfg_http = HTTPRequest.new(); add_child(cfg_http)
		cfg_http.request_completed.connect(func(_r, code, _h, resp):
			if code == 200 and resp and blood_fx:
				var d = JSON.parse_string(resp.get_string_from_utf8())
				if d and d.has("config") and d["config"]:
					var level = str(d["config"].get("brutality_level", "dark"))
					blood_fx.brutality = level
			cfg_http.queue_free()
		, CONNECT_ONE_SHOT)
		cfg_http.request(SERVER_URL + "/combat-vfx/config?user_id=" + character_id)
	call_deferred("_finalize_spawn")

func _finalize_spawn():
	await get_tree().process_frame
	if cam and cam.has_method("snap_validate"):
		cam.snap_validate()
	if player and cam and "--validation" in OS.get_cmdline_args():
		var vr_script = load("res://scripts/ValidationRunner.gd")
		if vr_script:
			var vr = vr_script.new()
			add_child(vr)
			vr.setup(player, cam)

# ===== PLAZA =====
func _build_plaza():
	# Stone plaza floor
	_plane(Vector3(0, 0.01, 0), Vector2(35, 35), Color(0.50, 0.46, 0.40, 1))
	# Inner circle
	_plane(Vector3(0, 0.02, 0), Vector2(18, 18), Color(0.55, 0.50, 0.43, 1))
	# Fountain center
	_fountain(Vector3(0, 0, 0))
	# 4 torches around fountain
	for i in range(4):
		var a = float(i) * PI / 2.0 + PI / 4.0
		_torch(Vector3(cos(a) * 5, 0, sin(a) * 5))
	# 8 trees around plaza
	for i in range(8):
		var a = float(i) * PI * 2.0 / 8.0
		_tree(Vector3(cos(a) * 15, 0, sin(a) * 15), 1.3)
	# 4 benches
	for i in range(4):
		var a = float(i) * PI / 2.0
		_bench(Vector3(cos(a) * 8, 0, sin(a) * 8), a + PI / 2.0)

func _fountain(pos: Vector3):
	var f = Node3D.new(); f.position = pos
	_cyl(f, 3.5, 0.4, Color(0.55, 0.52, 0.48, 1), Vector3(0, 0.2, 0))
	var sb = StaticBody3D.new(); sb.position = Vector3(0, 0.2, 0)
	var col = CollisionShape3D.new(); var cs = CylinderShape3D.new(); cs.radius = 3.5; cs.height = 0.8
	col.shape = cs; sb.add_child(col); f.add_child(sb)
	var w = MeshInstance3D.new(); var ds = CylinderMesh.new(); ds.top_radius = 3.0; ds.bottom_radius = 3.0; ds.height = 0.1; w.mesh = ds
	var wm = StandardMaterial3D.new(); wm.albedo_color = Color(0.20, 0.40, 0.70, 0.7); wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	w.set_surface_override_material(0, wm); w.position = Vector3(0, 0.35, 0); f.add_child(w)
	_cyl(f, 0.6, 3.0, Color(0.60, 0.58, 0.55, 1), Vector3(0, 1.7, 0))
	_cyl(f, 1.5, 0.3, Color(0.60, 0.58, 0.55, 1), Vector3(0, 3.2, 0))
	var light = OmniLight3D.new(); light.position = Vector3(0, 3.5, 0)
	light.light_color = Color(0.3, 0.5, 0.9); light.light_energy = 2.0; light.omni_range = 8.0
	f.add_child(light)
	add_child(f)

func _bench(pos: Vector3, angle: float):
	var b = Node3D.new(); b.position = pos; b.rotation.y = angle
	_box_on(b, Vector3(3, 0.3, 0.8), Color(0.35, 0.22, 0.12, 1), Vector3(0, 0.8, 0))
	_box_on(b, Vector3(0.2, 0.6, 0.2), Color(0.30, 0.18, 0.10, 1), Vector3(1.2, 0.4, 0))
	_box_on(b, Vector3(0.2, 0.6, 0.2), Color(0.30, 0.18, 0.10, 1), Vector3(-1.2, 0.4, 0))
	_static_box(b, Vector3(3, 1.0, 0.8), Vector3(0, 0.5, 0))
	add_child(b)

# ===== PLAYER =====
func _spawn_player():
	player = CharacterBody3D.new(); player.name = "Hero"; player.add_to_group("player_group")
	# Body
	_capsule2(player, 0.45, 1.3, Color(0.15, 0.25, 0.65, 1), Vector3(0, 1.5, 0))
	# Head
	_sphere2(player, 0.35, Color(0.85, 0.70, 0.55, 1), Vector3(0, 2.3, 0))
	# Arms
	_capsule2(player, 0.12, 0.85, Color(0.15, 0.25, 0.65, 1), Vector3(0.55, 1.6, 0))
	_capsule2(player, 0.12, 0.85, Color(0.15, 0.25, 0.65, 1), Vector3(-0.55, 1.6, 0))
	# Legs
	_capsule2(player, 0.14, 0.85, Color(0.12, 0.08, 0.04, 1), Vector3(0.2, 0.45, 0))
	_capsule2(player, 0.14, 0.85, Color(0.12, 0.08, 0.04, 1), Vector3(-0.2, 0.45, 0))
	# Collision
	var c = CollisionShape3D.new(); var cs = CapsuleShape3D.new(); cs.radius = 0.5; cs.height = 2.2
	c.shape = cs; c.position = Vector3(0, 1.1, 0); player.add_child(c)
	player.position = Vector3(0, 0, 0)
	var ps = load("res://scripts/PlayerController.gd")
	if ps: player.set_script(ps)
	add_child(player)
	if cam: cam.target = player

# ===== VILLAGE =====
func _build_village():
	# Main road (north-south)
	_plane(Vector3(0, 0.015, -30), Vector2(6, 80), Color(0.45, 0.40, 0.35, 1))
	_plane(Vector3(0, 0.015, 30), Vector2(6, 80), Color(0.45, 0.40, 0.35, 1))
	
	# 12 houses along roads
	for i in range(12):
		var side = 1 if i % 2 == 0 else -1
		var z = 15 + float(i / 2) * 15
		var x = side * (10 + randf() * 5)
		_house(Vector3(x, 0, z))
		house_count += 1
	
	# 4 houses near plaza
	var plaza_houses = [Vector3(20, 0, 10), Vector3(-20, 0, 10), Vector3(15, 0, -18), Vector3(-15, 0, -18)]
	for hp in plaza_houses:
		_house(hp)
		house_count += 1
	
	# Well
	_well(Vector3(8, 0, -8))
	# Carts
	_cart(Vector3(12, 0, -25))
	_cart(Vector3(-10, 0, 30))

func _house(pos: Vector3):
	var h = Node3D.new(); h.position = pos
	# Walls
	_box_on(h, Vector3(7, 5, 6), Color(0.50 + randf() * 0.1, 0.32 + randf() * 0.1, 0.18 + randf() * 0.1, 1), Vector3(0, 2.5, 0))
	# Collision for walls
	var sb = StaticBody3D.new(); sb.position = Vector3(0, 2.5, 0)
	var col = CollisionShape3D.new(); var bs = BoxShape3D.new(); bs.size = Vector3(7, 5, 6)
	col.shape = bs; sb.add_child(col); h.add_child(sb)
	# Roof
	var roof = MeshInstance3D.new(); var pr = PrismMesh.new(); pr.size = Vector3(8, 2.5, 7)
	roof.mesh = pr
	var rm = StandardMaterial3D.new(); rm.albedo_color = Color(0.40, 0.15, 0.08, 1)
	roof.set_surface_override_material(0, rm); roof.position = Vector3(0, 5.2, 0.5); h.add_child(roof)
	# Door + windows
	_box_on(h, Vector3(1.8, 3.5, 0.2), Color(0.25, 0.12, 0.06, 1), Vector3(0, 1.8, 3.1))
	# Chimney
	_box_on(h, Vector3(0.6, 3, 0.6), Color(0.35, 0.25, 0.18, 1), Vector3(2.5, 4.0, -2))
	_smoke(h, Vector3(2.5, 5.8, -2))
	add_child(h)

func _smoke(parent, pos):
	var s = MeshInstance3D.new()
	var sp = SphereMesh.new(); sp.radius = 0.3; sp.height = 0.6; s.mesh = sp
	var sm = StandardMaterial3D.new(); sm.albedo_color = Color(0.80, 0.80, 0.80, 0.4)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	s.set_surface_override_material(0, sm); s.position = pos
	parent.add_child(s)

func _well(pos: Vector3):
	var w = Node3D.new(); w.position = pos
	_cyl(w, 1.5, 3, Color(0.40, 0.35, 0.30, 1), Vector3(0, 1.5, 0))
	var sb = StaticBody3D.new(); sb.position = Vector3(0, 1.5, 0)
	var col = CollisionShape3D.new(); var cs = CylinderShape3D.new(); cs.radius = 1.5; cs.height = 3.0
	col.shape = cs; sb.add_child(col); w.add_child(sb)
	_box_on(w, Vector3(3, 0.3, 1), Color(0.35, 0.22, 0.12, 1), Vector3(0, 3.2, 0))
	var roof = MeshInstance3D.new(); var pr = PrismMesh.new(); pr.size = Vector3(3.5, 1.5, 2)
	roof.mesh = pr
	roof.set_surface_override_material(0, _mat(Color(0.35, 0.14, 0.08, 1)))
	roof.position = Vector3(0, 4.0, 0); w.add_child(roof)
	_box_on(w, Vector3(0.2, 3, 0.2), Color(0.30, 0.18, 0.10, 1), Vector3(0.8, 2.0, 0.5))
	_box_on(w, Vector3(0.2, 3, 0.2), Color(0.30, 0.18, 0.10, 1), Vector3(-0.8, 2.0, 0.5))
	add_child(w)

func _cart(pos: Vector3):
	var c = Node3D.new(); c.position = pos; c.rotation.y = randf() * PI
	_box_on(c, Vector3(2.5, 1, 3), Color(0.35, 0.22, 0.12, 1), Vector3(0, 1.0, 0))
	# Wheels
	for wx in [-1.2, 1.2]:
		for wz in [-1.0, 1.0]:
			var wheel = MeshInstance3D.new(); var cyl = CylinderMesh.new()
			cyl.top_radius = 0.5; cyl.bottom_radius = 0.5; cyl.height = 0.2; wheel.mesh = cyl
			wheel.set_surface_override_material(0, _mat(Color(0.25, 0.18, 0.12, 1)))
			wheel.rotation_degrees = Vector3(90, 0, 0); wheel.position = Vector3(wx, 0.5, wz); c.add_child(wheel)
	_box_on(c, Vector3(0.2, 0.2, 2.5), Color(0.30, 0.20, 0.12, 1), Vector3(0, 1.5, -2.5))
	_static_box(c, Vector3(2.5, 1.5, 3), Vector3(0, 0.75, 0))
	add_child(c)

# ===== CASTLE =====
func _build_castle():
	var c = Node3D.new(); c.name = "Castelo"; c.position = Vector3(-60, 0, 40)
	var stone = Color(0.52, 0.50, 0.46, 1); var dark = Color(0.44, 0.42, 0.38, 1)
	_box_on(c, Vector3(14, 18, 14), stone, Vector3(0, 9, 0))
	_static_box(c, Vector3(14, 18, 14), Vector3(0, 9, 0))
	for cx in [-9, 9]:
		for cz in [-9, 9]:
			_box_on(c, Vector3(5, 22, 5), dark, Vector3(cx, 11, cz))
			_static_box(c, Vector3(5, 22, 5), Vector3(cx, 11, cz))
			_cone(c, Vector3(cx, 22.5, cz), 3, 5, Color(0.38, 0.14, 0.08, 1))
	_box_on(c, Vector3(7, 10, 4), stone, Vector3(0, 5, 9))
	_static_box(c, Vector3(7, 10, 4), Vector3(0, 5, 9))
	_box_on(c, Vector3(4, 7, 1), Color(0.25, 0.18, 0.08, 1), Vector3(0, 3.5, 10.5))
	for i in range(30):
		var a = float(i) * PI * 2.0 / 30.0
		var r = 20.0
		var wpos = Vector3(cos(a) * r, 3.5, sin(a) * r)
		var w = _box_on(c, Vector3(1, 7, 3), dark, wpos)
		w.rotation.y = a + PI / 2.0
		var wsb = StaticBody3D.new(); wsb.position = wpos; wsb.rotation.y = a + PI / 2.0
		var wcol = CollisionShape3D.new(); var wbs = BoxShape3D.new(); wbs.size = Vector3(1, 7, 3)
		wcol.shape = wbs; wsb.add_child(wcol); c.add_child(wsb)
	var banner = MeshInstance3D.new(); var bp = BoxMesh.new(); bp.size = Vector3(0.1, 5, 2); banner.mesh = bp
	var bm = StandardMaterial3D.new(); bm.albedo_color = Color(0.80, 0.10, 0.10, 1)
	banner.set_surface_override_material(0, bm); banner.position = Vector3(0, 20, 0); c.add_child(banner)
	var castle_light = OmniLight3D.new(); castle_light.position = Vector3(0, 15, 10)
	castle_light.light_color = Color(1, 0.85, 0.6); castle_light.light_energy = 3.0; castle_light.omni_range = 25.0
	c.add_child(castle_light)
	add_child(c)

# ===== DRAGON =====
func _spawn_dragon():
	var pos = Vector3(30, 0, 0)
	var ds = load("res://assets/quaternius/creatures/Ultimate Monsters/Big/glTF/BlueDemon.gltf")
	if ds:
		var d = ds.instantiate(); d.name = "Vorak_o_Antigo"
		d.position = pos; d.scale = Vector3(6, 6, 6); d.rotation_degrees = Vector3(0, 90, 0)
		add_child(d); dragon_count += 1
		var sb = StaticBody3D.new(); sb.position = Vector3(0, 1.5, 0)
		var col = CollisionShape3D.new(); var bs = BoxShape3D.new(); bs.size = Vector3(4, 3, 6)
		col.shape = bs; sb.add_child(col); d.add_child(sb)
		var lbl = Label3D.new(); lbl.text = "VORAK, O ANTIGO\nHP: 100/100"
		lbl.position = Vector3(0, 8, 0); lbl.font_size = 44
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lbl.modulate = Color(1, 0.15, 0.15, 1)
		d.add_child(lbl)
		var circle = MeshInstance3D.new(); var cyl = CylinderMesh.new()
		cyl.top_radius = 3.0; cyl.bottom_radius = 3.0; cyl.height = 0.05; circle.mesh = cyl
		var cm = StandardMaterial3D.new(); cm.albedo_color = Color(0.90, 0.10, 0.10, 0.5)
		cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		circle.set_surface_override_material(0, cm); circle.position = Vector3(0, 0.03, 0)
		d.add_child(circle)
	else:
		_fallback_dragon(pos)

func _fallback_dragon(pos: Vector3):
	var d = Node3D.new(); d.name = "Vorak"; d.position = pos; d.scale = Vector3(6, 6, 6); d.rotation_degrees = Vector3(0, 90, 0)
	var sb = StaticBody3D.new(); sb.position = Vector3(0, 2.5, 0)
	var col = CollisionShape3D.new(); var fcs = CapsuleShape3D.new(); fcs.radius = 2.0; fcs.height = 7.0
	col.shape = fcs; sb.add_child(col); d.add_child(sb)
	var c = Color(0.55, 0.08, 0.08, 1)
	_capsule2(d, 1.6, 7, c, Vector3(0, 2.5, 0))
	_sphere2(d, 1.4, c, Vector3(0, 3.0, -4.5))
	_capsule2(d, 0.8, 3, c, Vector3(0, 3.5, -2.5))
	for side in [3, -3]:
		var wing = MeshInstance3D.new(); var pr = PrismMesh.new(); pr.size = Vector3(0.3, 5, 7)
		wing.mesh = pr; wing.set_surface_override_material(0, _mat(Color(0.30, 0.05, 0.05, 1)))
		wing.position = Vector3(side, 4.5, -1); wing.rotation_degrees = Vector3(0, 0, 45 if side > 0 else -45)
		d.add_child(wing)
	for i in range(6):
		var s = 1.0 - i * 0.14
		_capsule2(d, 0.7 * s, 2, c, Vector3(0, 2.5, 4 + i * 1.5))
	for lx in [1.5, -1.5]:
		for lz in [-2, 2]:
			_capsule2(d, 0.4, 2.5, c, Vector3(lx, 1.2, lz))
	_sphere2(d, 0.4, Color(1, 0.8, 0, 1), Vector3(0.7, 3.8, -5.5))
	_sphere2(d, 0.4, Color(1, 0.8, 0, 1), Vector3(-0.7, 3.8, -5.5))
	add_child(d); dragon_count += 1

# ===== NPCS =====
func _spawn_npcs():
	var npcs = [
		["Guardiao do Vale", "Guardiao", Vector3(5, 0, 5), Color(0.40, 0.35, 0.30, 1)],
		["Ferreiro Thorin", "Ferreiro", Vector3(-6, 0, 8), Color(0.45, 0.30, 0.20, 1)],
		["Mercador Ivan", "Mercador", Vector3(8, 0, -5), Color(0.55, 0.28, 0.12, 1)],
		["Curandeira Lyra", "Curandeira", Vector3(-7, 0, -6), Color(0.50, 0.45, 0.40, 1)],
		["Campones Finn", "Campones", Vector3(3, 0, -10), Color(0.55, 0.45, 0.30, 1)],
		["Escriba do Vale", "Cronista", Vector3(-10, 0, 0), Color(0.60, 0.50, 0.40, 1)],
		["Arauto do Vale", "Mensageiro", Vector3(10, 0, 0), Color(0.45, 0.40, 0.55, 1)],
		["Mestre de Armas", "Treinador", Vector3(0, 0, 15), Color(0.55, 0.35, 0.20, 1)],
	]
	for nd in npcs:
		_npc(nd[2], nd[0], nd[1], nd[3])
		npc_count += 1

func _npc(pos: Vector3, npc_name: String, title: String, body_color: Color):
	var n = StaticBody3D.new(); n.name = npc_name.replace(" ", "_"); n.position = pos
	n.add_to_group("npc")
	var col = CollisionShape3D.new(); var cs = CapsuleShape3D.new(); cs.radius = 0.5; cs.height = 2.0
	col.shape = cs; col.position = Vector3(0, 1.0, 0); n.add_child(col)
	_capsule2(n, 0.45, 1.3, body_color, Vector3(0, 1.5, 0))
	_sphere2(n, 0.37, Color(0.85, 0.70, 0.55, 1), Vector3(0, 2.4, 0))
	_capsule2(n, 0.13, 0.85, body_color, Vector3(0.58, 1.6, 0))
	_capsule2(n, 0.13, 0.85, body_color, Vector3(-0.58, 1.6, 0))
	_capsule2(n, 0.15, 0.85, Color(0.18, 0.12, 0.06, 1), Vector3(0.22, 0.45, 0))
	_capsule2(n, 0.15, 0.85, Color(0.18, 0.12, 0.06, 1), Vector3(-0.22, 0.45, 0))
	var lbl = Label3D.new(); lbl.text = npc_name + "\n" + title
	lbl.position = Vector3(0, 3.2, 0); lbl.font_size = 26
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lbl.modulate = Color(1, 0.9, 0.5, 1)
	n.add_child(lbl)
	add_child(n)

# ===== TREES =====
func _build_trees():
	for i in range(80):
		var a = float(i) * PI * 2.0 / 10.0 + randf_range(-0.5, 0.5)
		var r = randf_range(25, 250)
		_tree(Vector3(cos(a) * r, 0, sin(a) * r), 1.0)
		tree_count += 1

func _tree(pos: Vector3, sc: float):
	var t = Node3D.new(); t.position = pos; t.scale = Vector3(sc, sc, sc)
	var h = randf_range(5, 10)
	_cyl(t, 0.3, h, Color(0.38, 0.22, 0.10, 1), Vector3(0, h/2, 0))
	var sb = StaticBody3D.new(); sb.position = Vector3(0, h / 2, 0)
	var col = CollisionShape3D.new(); var cs = CylinderShape3D.new(); cs.radius = 0.5; cs.height = h
	col.shape = cs; sb.add_child(col); t.add_child(sb)
	for j in range(4):
		var s = 3.5 - float(j) * 0.7
		_sphere2(t, s * 0.5, Color(0.06, 0.35 + randf() * 0.30, 0.06, 1), Vector3(randf_range(-0.5, 0.5), h + float(j) * 1.5, randf_range(-0.5, 0.5)))
	add_child(t)

# ===== WALLS =====
func _build_walls():
	var wall_color = Color(0.42, 0.38, 0.32, 1)
	var segments = 40
	var radius = 120.0
	var wall_h = 6.0
	for i in range(segments):
		var a = float(i) * PI * 2.0 / float(segments)
		var x = cos(a) * radius
		var z = sin(a) * radius
		var w = Node3D.new(); w.position = Vector3(x, 0, z)
		_box_on(w, Vector3(2, wall_h, 20), wall_color, Vector3(0, wall_h / 2.0, 0))
		w.rotation.y = a + PI / 2.0
		var sb = StaticBody3D.new(); sb.position = Vector3(0, wall_h / 2.0, 0)
		var col = CollisionShape3D.new(); var bs = BoxShape3D.new(); bs.size = Vector3(2, wall_h, 20)
		col.shape = bs; sb.add_child(col); w.add_child(sb)
		add_child(w)
	for i in range(segments):
		var a = float(i) * PI * 2.0 / float(segments)
		if i % 5 == 0:
			var tx = cos(a) * (radius + 1)
			var tz = sin(a) * (radius + 1)
			_torch(Vector3(tx, 0, tz))

# ===== ROCKS =====
func _build_rocks():
	for i in range(40):
		var a = randf() * PI * 2.0
		var r = randf_range(20, 200)
		var pos = Vector3(cos(a) * r, 0, sin(a) * r)
		if pos.length() < 15: continue
		var sz = randf_range(0.5, 3.0)
		var rock = Node3D.new(); rock.position = pos
		_sphere2(rock, sz, Color(0.45 + randf() * 0.15, 0.42 + randf() * 0.1, 0.38 + randf() * 0.1, 1), Vector3(0, sz * 0.4, 0))
		var sb = StaticBody3D.new(); sb.position = Vector3(0, sz * 0.4, 0)
		var col = CollisionShape3D.new(); var ss = SphereShape3D.new(); ss.radius = sz * 0.5
		col.shape = ss; sb.add_child(col); rock.add_child(sb)
		rock.rotation.y = randf() * PI * 2.0
		add_child(rock)

# ===== ROAD TORCHES =====
func _build_road_torches():
	for z in range(-60, 80, 15):
		_torch(Vector3(4, 0, z))
		_torch(Vector3(-4, 0, z))

# ===== HELPERS =====
func _mat(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_color = color; return m

func _static_box(parent, size: Vector3, pos: Vector3):
	var sb = StaticBody3D.new(); sb.position = pos
	var col = CollisionShape3D.new(); var bs = BoxShape3D.new(); bs.size = size
	col.shape = bs; sb.add_child(col); parent.add_child(sb)

func _sphere2(parent, r, color, pos):
	var mi = MeshInstance3D.new(); var s = SphereMesh.new(); s.radius = r; s.height = r*2; mi.mesh = s
	mi.set_surface_override_material(0, _mat(color)); mi.position = pos; parent.add_child(mi)

func _capsule2(parent, r, h, color, pos):
	var mi = MeshInstance3D.new(); var c = CapsuleMesh.new(); c.radius = r; c.height = h; mi.mesh = c
	mi.set_surface_override_material(0, _mat(color)); mi.position = pos; parent.add_child(mi)

func _box_on(parent, size, color, pos):
	var mi = MeshInstance3D.new(); var b = BoxMesh.new(); b.size = size; mi.mesh = b
	mi.set_surface_override_material(0, _mat(color)); mi.position = pos; parent.add_child(mi); return mi

func _cyl(parent, r, h, color, pos):
	var mi = MeshInstance3D.new(); var c = CylinderMesh.new(); c.top_radius = r; c.bottom_radius = r; c.height = h; mi.mesh = c
	mi.set_surface_override_material(0, _mat(color)); mi.position = pos; parent.add_child(mi)

func _plane(pos: Vector3, size: Vector2, color: Color):
	var mi = MeshInstance3D.new(); var p = PlaneMesh.new(); p.size = size; mi.mesh = p
	mi.set_surface_override_material(0, _mat(color)); mi.position = pos; add_child(mi)

func _cone(parent, pos: Vector3, r: float, h: float, color: Color):
	var mi = MeshInstance3D.new(); var c = CylinderMesh.new(); c.top_radius = 0.05; c.bottom_radius = r; c.height = h; mi.mesh = c
	mi.set_surface_override_material(0, _mat(color)); mi.position = pos; parent.add_child(mi)

func _torch(pos: Vector3):
	var t = Node3D.new(); t.position = pos
	_cyl(t, 0.15, 4, Color(0.28, 0.20, 0.12, 1), Vector3(0, 2, 0))
	var flame = MeshInstance3D.new(); var fs = SphereMesh.new(); fs.radius = 0.5; fs.height = 1.0; flame.mesh = fs
	var fm = StandardMaterial3D.new(); fm.albedo_color = Color(1, 0.6, 0.1, 1)
	fm.emission_enabled = true; fm.emission = Color(1, 0.5, 0); fm.emission_energy_multiplier = 2.0
	flame.set_surface_override_material(0, fm); flame.position = Vector3(0, 4.5, 0); t.add_child(flame)
	var light = OmniLight3D.new(); light.position = Vector3(0, 4.5, 0)
	light.light_color = Color(1, 0.6, 0.2); light.light_energy = 1.5; light.omni_range = 10.0
	light.shadow_enabled = false
	t.add_child(light)
	add_child(t)

func _hide_debug_hud():
	if OS.is_debug_build():
		return
	if fps_label:
		fps_label.visible = false
	if pos_label:
		pos_label.visible = false
	if obj_label:
		obj_label.visible = false

func _log(msg: String):
	if quest_text: quest_text.text = msg
	GameLogger.write_log("[WORLD] " + msg)

func _process(delta):
	if OS.is_debug_build():
		if fps_label: fps_label.text = "FPS: " + str(Engine.get_frames_per_second())
		if obj_label: obj_label.text = "Obj: " + str(get_child_count())
	if player and hp_text:
		var hp = player.get("hp") if player.get("hp") != null else 100.0
		var mhp = player.get("max_hp") if player.get("max_hp") != null else 100.0
		hp_text.text = "HP: " + str(int(hp)) + "/" + str(int(mhp))
		if hp_bar and mhp > 0: hp_bar.size.x = 220 * (hp / mhp)
	if player and pos_label and OS.is_debug_build():
		pos_label.text = str(int(player.global_position.x)) + ", " + str(int(player.global_position.y)) + ", " + str(int(player.global_position.z))
	if char_profile:
		if level_label: level_label.text = char_profile.get_level_text()
		if zorium_label: zorium_label.text = char_profile.get_zorium_text()
	auto_save_timer += delta
	if auto_save_timer >= 60.0:
		auto_save_timer = 0.0
		_auto_save()
	if climate_combat and world_sim:
		climate_combat.update_weather(world_sim.weather_state, world_sim.temperature, world_sim.wind_speed)
	if player and not dialog_open:
		nearest_npc = null
		var min_dist = 4.0
		for npc in get_tree().get_nodes_in_group("npc"):
			var d = player.global_position.distance_to(npc.global_position)
			if d < min_dist:
				min_dist = d
				nearest_npc = npc
		if interact_hint:
			interact_hint.text = "[E] Conversar" if nearest_npc else ""

func _unhandled_input(event):
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if dialog_open and event.keycode != KEY_E:
		_handle_dialog_key(event.keycode)
		return
	if event.keycode == KEY_E:
		if dialog_open:
			_close_dialog()
		elif nearest_npc:
			_open_dialog(nearest_npc)
	elif event.keycode == KEY_I:
		if inv_system: inv_system.toggle()
		if equip_panel_ui: equip_panel_ui.toggle()
	elif event.keycode == KEY_J:
		if journal: journal.toggle()
	elif event.keycode == KEY_P:
		_show_profile()
	elif OS.is_debug_build() and event.keycode >= KEY_0 and event.keycode <= KEY_9:
		_debug_vfx(event.keycode)
	elif event.keycode == KEY_F5:
		_manual_save()

var dialog_npc_id: String = ""

func _open_dialog(npc: Node3D):
	dialog_open = true
	dialog_npc_id = npc.name
	if dialog_panel: dialog_panel.visible = true
	var npc_display = npc.name.replace("_", " ")
	if dialog_name_label: dialog_name_label.text = npc_display
	var base_text = npc_dialogs.get(npc.name, "...")
	if npc.name == "Curandeira_Lyra":
		base_text += "\n\n[C] Curar (5 Zorium)"
		if quest_stage == 0:
			base_text += "   [Q] Aceitar missao"
	elif npc.name == "Ferreiro_Thorin":
		base_text += "\n\n[F] Forjar Espada de Ferro (30 Z)"
	if dialog_text_label: dialog_text_label.text = base_text
	if interact_hint: interact_hint.text = ""
	if net and character_id != "":
		net.record_npc_memory(npc.name, character_id, "interaction", {"action": "dialog_opened"}, func(_d): pass)
	if speech_bubble and npc:
		speech_bubble.global_position = npc.global_position
		var short_text = str(npc_dialogs.get(npc.name, "...")).substr(0, 40)
		speech_bubble.show_message(short_text, 0, "player", 5.0)
	_advance_quest(npc.name)

func _close_dialog():
	dialog_open = false
	dialog_npc_id = ""
	if dialog_panel: dialog_panel.visible = false

func _advance_quest(npc_id: String):
	if npc_id == "Curandeira_Lyra" and quest_stage == 0:
		pass

func _handle_dialog_key(keycode: int):
	if dialog_npc_id == "Curandeira_Lyra":
		if keycode == KEY_C:
			_heal_player()
		elif keycode == KEY_Q and quest_stage == 0:
			quest_stage = 1
			if quest_text: quest_text.text = "MISSAO: Derrote Vorak, o Antigo"
			if dialog_text_label: dialog_text_label.text = "Missao aceita! Derrote Vorak."
			if net and character_id != "":
				net.accept_quest(character_id, "d0000000-0000-0000-0000-000000000001", func(_d): pass)
	elif dialog_npc_id == "Ferreiro_Thorin":
		if keycode == KEY_F:
			_forge_item()

func _load_character_data():
	if not net or character_id == "":
		GameLogger.write_log("[WORLD] No character_id — skipping server load")
		return
	GameLogger.write_log("[WORLD] Loading character data: " + character_id)
	net.get_stats(character_id, func(data):
		if data and data.has("stats") and char_profile:
			char_profile.load_from_server(data["stats"])
			GameLogger.write_log("[WORLD] Stats loaded — Level:" + str(char_profile.get_stat("level")) + " Zorium:" + str(char_profile.get_stat("zorium")))
	)
	net.get_inventory(character_id, func(data):
		if data and data.has("inventory") and inv_system:
			inv_system.load_from_server(data["inventory"])
			GameLogger.write_log("[WORLD] Inventory loaded — " + str(data["inventory"].size()) + " items")
	)
	net.get_equipment(character_id, func(data):
		if data and data.has("equipment") and equip_panel_ui:
			equip_panel_ui.load_from_server(data["equipment"])
			GameLogger.write_log("[WORLD] Equipment loaded")
	)
	net.get_quests(character_id, func(data):
		if data and data.has("quests") and journal:
			journal.load_from_server(data["quests"])
			GameLogger.write_log("[WORLD] Quests loaded — " + str(data["quests"].size()) + " quests")
	)
	var alleg_http = HTTPRequest.new(); add_child(alleg_http)
	alleg_http.request_completed.connect(func(_r, code, _h, resp):
		if code == 200 and resp:
			var d = JSON.parse_string(resp.get_string_from_utf8())
			if d and d.has("origin") and d["origin"] and class_label:
				var cn = d["origin"].get("class_name", "")
				var on2 = d["origin"].get("origin_name", "Viajante")
				class_label.text = (str(cn) + " — " if cn else "") + str(on2)
		alleg_http.queue_free()
	, CONNECT_ONE_SHOT)
	alleg_http.request(SERVER_URL + "/characters/" + character_id + "/allegiance")
	net.load_save(character_id, func(data):
		if data and data.has("save") and data["save"] and player:
			var pos = data["save"].get("position", {})
			if pos and pos.has("x"):
				player.global_position = Vector3(float(pos["x"]), float(pos["y"]), float(pos["z"]))
				GameLogger.write_log("[WORLD] Position loaded from save: " + str(player.global_position))
	)

func _heal_player():
	if not net or character_id == "":
		if dialog_text_label: dialog_text_label.text = "Erro: sem conexao."
		return
	if dialog_text_label: dialog_text_label.text = "Curando..."
	net.heal_character(character_id, func(data):
		if data and data.has("healed"):
			if char_profile:
				char_profile.heal_full()
				if data.has("stats"):
					char_profile.set_stat("zorium", float(data["stats"].get("zorium", 0)))
			if dialog_text_label: dialog_text_label.text = "Curada! HP restaurado. (-5 Z)"
		elif data and data.has("error"):
			if dialog_text_label: dialog_text_label.text = str(data["error"])
	)

func _forge_item():
	if not net or character_id == "": return
	if dialog_text_label: dialog_text_label.text = "Forjando..."
	net.spend_zorium(character_id, 30.0, "forge_iron_sword", func(data):
		if data and data.has("error"):
			if dialog_text_label: dialog_text_label.text = str(data["error"])
			return
		if char_profile: char_profile.set_stat("zorium", float(data.get("balance", 0)))
		var iron_sword_id = "c0000000-0000-0000-0000-000000000009"
		net.add_to_inventory(character_id, iron_sword_id, 1, func(inv_data):
			if inv_data and inv_data.has("added"):
				if dialog_text_label: dialog_text_label.text = "Espada de Ferro forjada! (-30 Z)"
				if inv_system:
					inv_system.add_item(int(inv_data["added"].get("slot_index", 0)), {
						"item_name": "Espada de Ferro", "item_type": "weapon",
						"rarity": "uncommon", "slot_type": "weapon",
						"base_stats": {"attack": 8, "speed": 0.9, "critical": 0.03},
						"quantity": 1, "item_id": iron_sword_id
					})
		)
	)

func _manual_save():
	if not net or character_id == "" or not player: return
	if save_indicator: save_indicator.text = "Salvando..."
	if save_indicator: save_indicator.visible = true
	net.save_game(character_id, player.global_position, func(data):
		GameLogger.write_log("[WORLD] Save result: " + str(data))
	)
	_hide_save_indicator(1.5)

func _auto_save():
	if not net or character_id == "" or not player: return
	if save_indicator: save_indicator.text = "Auto-save..."
	if save_indicator: save_indicator.visible = true
	net.save_game(character_id, player.global_position, func(_data): pass)
	_hide_save_indicator(1.0)

func _on_hit_dealt(target: Node3D, damage: float, impact_type: String):
	if vfx_event_system:
		vfx_event_system.trigger_event("HIT_MEDIUM", {"position": target.global_position + Vector3(0, 1, 0), "direction": Vector3.RIGHT})
	if hit_ui: hit_ui.show_floating_text(target.global_position, "-" + str(int(damage)), Color(1, 0.8, 0.3))

func _on_critical_hit(target: Node3D, damage: float):
	if vfx_event_system:
		vfx_event_system.trigger_event("CRITICAL_HIT", {"position": target.global_position + Vector3(0, 1, 0)})
	if hit_ui: hit_ui.show_critical(target.global_position, damage)

func _on_target_died(target: Node3D, killer: Node3D):
	if vfx_event_system:
		vfx_event_system.trigger_event("DEATH_PREVIEW", {"position": target.global_position})
	if ground_vfx: ground_vfx.ground_impact(target.global_position, "earth")

func _on_target_blocked(target: Node3D):
	if shield_vfx: shield_vfx.block_light(target.global_position)
	if hit_ui: hit_ui.show_blocked(target.global_position)

func _show_profile():
	if character_id == "" or not dialog_panel: return
	var http = HTTPRequest.new(); add_child(http)
	http.request_completed.connect(func(_r, code, _h, resp):
		if code == 200 and resp and dialog_panel:
			var d = JSON.parse_string(resp.get_string_from_utf8())
			if d and d.has("bio") and d["bio"]:
				var b = d["bio"]
				var txt = "=== PERFIL ===\n"
				txt += "Origem: " + str(b.get("origin_name", "?")) + "\n"
				txt += "Classe: " + str(b.get("class_path", "Nenhuma")) + "\n"
				txt += "Territorio: " + str(b.get("birth_homeland", "?")) + "\n"
				if d.has("titles") and d["titles"].size() > 0:
					txt += "Titulos: " + str(d["titles"][0].get("title", "")) + "\n"
				dialog_open = true; dialog_name_label.text = "Perfil do Heroi"
				dialog_text_label.text = txt; dialog_panel.visible = true
		http.queue_free()
	, CONNECT_ONE_SHOT)
	http.request(SERVER_URL + "/lore/character/" + character_id)

func _hide_save_indicator(delay: float):
	await get_tree().create_timer(delay).timeout
	if save_indicator: save_indicator.visible = false

func _debug_vfx(keycode: int):
	if not player: return
	var ppos = player.global_position + Vector3(0, 1, 0)
	if keycode == KEY_0:
		if blood_fx: blood_fx.clear_all()
		if decal_fx: decal_fx.clear_all()
		if camera_fx: camera_fx.reset_camera()
		GameLogger.write_log("[VFX] Cleared all effects")
	elif keycode == KEY_1:
		if blood_fx: blood_fx.splash_small(ppos)
		if impact_fx: impact_fx.spawn_impact("metal", ppos, Vector3.RIGHT)
		if reaction_fx: reaction_fx.setup(player); reaction_fx.hit_light(Vector3.RIGHT)
		if audio_fx: audio_fx.play_hit("light")
	elif keycode == KEY_2:
		if blood_fx: blood_fx.splash_medium(ppos)
		if impact_fx: impact_fx.spawn_impact("metal", ppos, Vector3.RIGHT)
		if decal_fx: decal_fx.spawn_decal("blood", ppos - Vector3(0,0.9,0))
		if reaction_fx: reaction_fx.setup(player); reaction_fx.hit_medium(Vector3.RIGHT)
		if camera_fx: camera_fx.shake_light()
		if audio_fx: audio_fx.play_hit("medium")
	elif keycode == KEY_3:
		if blood_fx: blood_fx.splash_heavy(ppos)
		if impact_fx: impact_fx.spawn_impact("metal", ppos, Vector3.RIGHT)
		if decal_fx: decal_fx.spawn_decal("blood", ppos)
		if reaction_fx: reaction_fx.setup(player); reaction_fx.hit_heavy(Vector3.RIGHT)
		if camera_fx: camera_fx.shake_medium()
		if audio_fx: audio_fx.play_hit("heavy")
	elif keycode == KEY_4:
		if impact_fx: impact_fx.spawn_impact("shield", ppos, Vector3.RIGHT)
		if reaction_fx: reaction_fx.setup(player); reaction_fx.shield_recoil(Vector3.LEFT)
		if camera_fx: camera_fx.block_flash()
		if audio_fx: audio_fx.play_block()
	elif keycode == KEY_5:
		if blood_fx: blood_fx.burst(ppos)
		if impact_fx: impact_fx.spawn_impact("metal", ppos, Vector3.UP)
		if decal_fx: decal_fx.spawn_decal("blood", ppos)
		if reaction_fx: reaction_fx.setup(player); reaction_fx.hit_heavy(Vector3.RIGHT)
		if camera_fx: camera_fx.critical_flash()
		if audio_fx: audio_fx.play_critical()
	elif keycode == KEY_6:
		if blood_fx: blood_fx.splash_heavy(ppos)
		if decal_fx: decal_fx.spawn_decal("blood", ppos)
		for i in range(4): decal_fx.spawn_decal("blood", ppos + Vector3(randf()*2-1,0,randf()*2-1))
	elif keycode == KEY_7:
		if impact_fx: impact_fx.spawn_impact("fire", ppos, Vector3.UP)
		if decal_fx: decal_fx.spawn_decal("fire", ppos)
		if camera_fx: camera_fx.damage_flash()
	elif keycode == KEY_8:
		if impact_fx: impact_fx.spawn_impact("ice", ppos, Vector3.UP)
		if decal_fx: decal_fx.spawn_decal("ice", ppos)
	elif keycode == KEY_9:
		if impact_fx: impact_fx.spawn_impact("wind", ppos, Vector3.RIGHT)
		if audio_fx: audio_fx.play_arrow()

func _on_inventory_item_selected(slot_index: int, item_data: Dictionary):
	var slot_type = item_data.get("slot_type", "")
	if slot_type == "" or slot_type == null: return
	var item_id = item_data.get("item_id", "")
	if item_id == "" or not net or character_id == "": return
	net.equip_item(character_id, item_id, slot_type, func(data):
		if data and data.has("equipped"):
			if equip_panel_ui: equip_panel_ui.equip_item(slot_type, item_data)
			GameLogger.write_log("[WORLD] Equipped " + str(item_data.get("item_name", "?")) + " in " + slot_type)
	)
