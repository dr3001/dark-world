extends Node

enum CombatState { IDLE, TARGETING, ATTACKING, COOLDOWN, DEFENDING }

var state: CombatState = CombatState.IDLE
var target: Node3D = null
var weapon_item: Dictionary = {}
var attack_cooldown: float = 0.5
var cooldown_timer: float = 0.0
var attack_range: float = 4.0
var base_damage: float = 5.0

func set_weapon(item_data: Dictionary):
	weapon_item = item_data
	var stats = item_data.get("base_stats", {})
	if stats is String: stats = JSON.parse_string(stats)
	if not stats: stats = {}
	base_damage = 5.0 + float(stats.get("attack", 0))
	attack_range = 4.0 + float(stats.get("range", 0))
	cooldown_timer = max(0.3, 0.5 - float(stats.get("speed", 0)) * 0.1)

func set_target(node: Node3D):
	target = node
	if target:
		state = CombatState.TARGETING
	else:
		state = CombatState.IDLE

func can_attack() -> bool:
	return state != CombatState.COOLDOWN and target != null

func calculate_damage(attacker_stats: Dictionary, defender_stats: Dictionary) -> Dictionary:
	var atk = float(attacker_stats.get("strength", 5)) + base_damage
	var def = float(defender_stats.get("vitality", 5)) + float(defender_stats.get("defense", 0))
	var raw = atk
	var mitigated = max(0, floor(def * 0.5))
	var crit_chance = float(attacker_stats.get("luck", 1)) * 0.02 + float(attacker_stats.get("critical", 0))
	var critical = randf() < crit_chance
	var mult = 1.5 if critical else 1.0
	var final_dmg = max(1, floor((raw - mitigated) * mult))
	return {
		"raw": raw,
		"mitigated": mitigated,
		"final": final_dmg,
		"critical": critical
	}

func process_cooldown(delta: float):
	if state == CombatState.COOLDOWN:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			cooldown_timer = attack_cooldown
			state = CombatState.IDLE if target == null else CombatState.TARGETING

func start_attack():
	if state == CombatState.COOLDOWN: return
	state = CombatState.ATTACKING

func finish_attack():
	state = CombatState.COOLDOWN
	cooldown_timer = attack_cooldown
