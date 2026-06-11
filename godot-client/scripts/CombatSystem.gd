extends Node

signal hit_dealt(target, damage, impact_type)
signal critical_hit(target, damage)
signal target_blocked(target)
signal target_died(target, killer)
signal damage_received(source, damage)

enum CombatState { IDLE, TARGETING, ATTACKING, COOLDOWN, DEFENDING }
var state: CombatState = CombatState.IDLE
var target: Node3D = null
var weapon_stats: Dictionary = {}
var base_damage: float = 5.0
var attack_range: float = 4.0
var cooldown_timer: float = 0.0
var cooldown_time: float = 0.5
var is_blocking: bool = false

func set_weapon(item_data: Dictionary):
	weapon_stats = item_data
	var stats = item_data.get("base_stats", {})
	if stats is String: stats = JSON.parse_string(stats)
	if not stats: stats = {}
	base_damage = 5.0 + float(stats.get("attack", 0))
	attack_range = 4.0 + float(stats.get("range", 0))
	cooldown_time = max(0.3, 0.5 - float(stats.get("speed", 0)) * 0.1)

func try_attack() -> bool:
	if state == CombatState.COOLDOWN: return false
	if state == CombatState.ATTACKING: return false
	state = CombatState.ATTACKING
	return true

func resolve_hit(tgt: Node3D, attacker_node: Node3D, attacker_stats: Dictionary = {}) -> Dictionary:
	if state != CombatState.ATTACKING: return {"hit": false}
	var attacker_pos = attacker_node.global_position
	var target_pos = tgt.global_position
	var dist = attacker_pos.distance_to(target_pos)
	if dist > attack_range:
		state = CombatState.IDLE
		return {"hit": false, "reason": "out_of_range"}
	var direction = (target_pos - attacker_pos).normalized()
	var atk = float(attacker_stats.get("strength", 5)) + base_damage
	var crit_chance = float(attacker_stats.get("luck", 1)) * 0.02 + float(weapon_stats.get("critical", 0))
	var is_crit = randf() < crit_chance
	var dmg = atk
	if is_crit: dmg *= 1.5
	dmg = max(1, floor(dmg))
	var impact_type = "metal"
	if base_damage > 10: impact_type = "fire" if is_crit else "metal"
	elif base_damage > 7: impact_type = "metal"
	else: impact_type = "flesh"
	state = CombatState.COOLDOWN
	cooldown_timer = cooldown_time
	return {"hit": true, "damage": dmg, "critical": is_crit, "direction": direction, "impact_type": impact_type, "position": target_pos}

func apply_damage(tgt: Node3D, dmg_data: Dictionary, killer_node: Node3D = null):
	if not tgt.has_method("take_damage"): return
	tgt.take_damage(dmg_data["damage"])
	if dmg_data.get("critical"):
		critical_hit.emit(tgt, dmg_data["damage"])
	else:
		hit_dealt.emit(tgt, dmg_data["damage"], dmg_data.get("impact_type", "metal"))
	var hp = tgt.get("hp") if tgt.get("hp") != null else 100.0
	if hp <= 0 and tgt.has_method("die"):
		target_died.emit(tgt, killer_node)
		tgt.die()

func try_block() -> bool:
	if state == CombatState.ATTACKING: return false
	state = CombatState.DEFENDING
	is_blocking = true
	return true

func release_block():
	state = CombatState.IDLE
	is_blocking = false

func _process(delta):
	if state == CombatState.COOLDOWN:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			cooldown_timer = 0
			state = CombatState.IDLE
