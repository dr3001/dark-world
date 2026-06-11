extends Node
# FASE 13 — Projectile Wind Influence Visual

var wind_direction: float = 0.0
var wind_speed: float = 0.0

func update_wind(dir: float, speed: float):
	wind_direction = dir
	wind_speed = speed

func apply_wind_to_particles(particle_pos: Vector3, lifetime: float = 1.0):
	var deviation = Vector3(cos(wind_direction), 0, sin(wind_direction)) * wind_speed * 0.02
	return deviation

func get_arrow_deviation():
	var base = Vector3(cos(wind_direction), wind_speed * 0.005, sin(wind_direction))
	return base * 3.0

func get_visual_deviation(weight: float = 1.0, speed: float = 10.0):
	var wind_factor = wind_speed / 20.0
	var weight_factor = 1.0 / max(weight, 0.1)
	return Vector3(cos(wind_direction), 0, sin(wind_direction)) * wind_factor * weight_factor * 2.0
