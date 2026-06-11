extends Node
# FASE 19 — Centralized combat VFX performance budget

var total_particles: int = 0
var total_decals: int = 0
var total_splashes: int = 0
var max_total_particles: int = 50
var max_total_decals: int = 15
var max_total_splashes: int = 20
var max_sounds_simultaneous: int = 8
var low_end_mode: bool = false

func set_quality(level: String):
	match level:
		"low":
			max_total_particles = 20; max_total_decals = 8; max_total_splashes = 10
			low_end_mode = true
		"medium":
			max_total_particles = 50; max_total_decals = 15; max_total_splashes = 20
			low_end_mode = false
		"high":
			max_total_particles = 100; max_total_decals = 30; max_total_splashes = 40
			low_end_mode = false

func can_spawn_particle(count: int = 1) -> bool:
	return total_particles + count <= max_total_particles

func can_spawn_decal(count: int = 1) -> bool:
	return total_decals + count <= max_total_decals

func can_spawn_splash(count: int = 1) -> bool:
	return total_splashes + count <= max_total_splashes

func within_budget() -> bool:
	return can_spawn_particle() and can_spawn_decal() and can_spawn_splash()

func register_particles(count: int): total_particles += count
func remove_particles(count: int): total_particles = max(0, total_particles - count)
func register_decals(count: int): total_decals += count
func remove_decals(count: int): total_decals = max(0, total_decals - count)
