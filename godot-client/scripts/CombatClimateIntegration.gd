extends Node
# FASE 14 — Climate + Combat visual integration

var weather_state: String = "clear"
var temperature: float = 22.0
var wind_speed: float = 0.0

func update_weather(state: String, temp: float, wind: float):
	weather_state = state; temperature = temp; wind_speed = wind

func modify_blood_intensity(base_intensity: String) -> String:
	if weather_state in ["heavy_rain", "storm"]: return "small"
	if weather_state == "fog": return "medium"
	if temperature < 5: return "medium"
	return base_intensity

func modify_particle_lifetime(base_lifetime: float) -> float:
	if weather_state in ["heavy_rain", "storm"]: return base_lifetime * 0.4
	if weather_state in ["drought", "heat"]: return base_lifetime * 1.3
	return base_lifetime

func modify_fire_effects() -> bool:
	return weather_state not in ["heavy_rain", "storm"]

func modify_ice_effects() -> bool:
	return temperature < 15.0

func get_wind_effect() -> Dictionary:
	return {"direction": wind_speed, "intensity": wind_speed / 20.0}

func is_raining() -> bool:
	return weather_state in ["light_rain", "heavy_rain", "storm"]
