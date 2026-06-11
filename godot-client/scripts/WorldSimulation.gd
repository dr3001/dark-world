extends Node

const SERVER_URL = "http://5.78.142.138:9000"
var sun: DirectionalLight3D
var env_node: WorldEnvironment
var time_label: Label
var weather_label: Label
var poll_timer: float = 0.0
var poll_interval: float = 30.0
var world_hour: int = 12
var world_season: String = "summer"
var weather_state: String = "clear"
var temperature: float = 22.0
var target_sun_energy: float = 5.0
var target_sun_rotation: float = -0.9
var target_fog_density: float = 0.0003

func setup(sun_node: DirectionalLight3D, world_env: WorldEnvironment, t_label: Label, w_label: Label):
	sun = sun_node
	env_node = world_env
	time_label = t_label
	weather_label = w_label

func _process(delta):
	poll_timer += delta
	if poll_timer >= poll_interval:
		poll_timer = 0.0
		_fetch_world_state()
	if sun:
		sun.light_energy = lerp(sun.light_energy, target_sun_energy, 2.0 * delta)
		sun.rotation.x = lerp(sun.rotation.x, target_sun_rotation, 1.0 * delta)
	if env_node and env_node.environment:
		env_node.environment.fog_density = lerp(env_node.environment.fog_density, target_fog_density, 1.0 * delta)

func _fetch_world_state():
	var http = HTTPRequest.new(); add_child(http)
	http.request_completed.connect(func(_r, code, _h, resp):
		if code == 200 and resp:
			var data = JSON.parse_string(resp.get_string_from_utf8())
			if data: _apply_state(data)
		http.queue_free()
	, CONNECT_ONE_SHOT)
	http.request(SERVER_URL + "/world/state")

func _apply_state(data: Dictionary):
	if data.has("time") and data["time"]:
		var t = data["time"]
		world_hour = int(t.get("hour", 12))
		world_season = str(t.get("season", "summer"))
		_apply_day_night()
		if time_label:
			time_label.text = str(world_hour).pad_zeros(2) + ":00 " + _season_name()
	if data.has("weather") and data["weather"]:
		var w = data["weather"]
		weather_state = str(w.get("state", "clear"))
		temperature = float(w.get("temperature", 22))
		_apply_weather()
		if weather_label:
			weather_label.text = _weather_name() + " " + str(int(temperature)) + "°C"

func _apply_day_night():
	match world_hour:
		0, 1, 2, 3, 4:
			target_sun_energy = 0.3; target_sun_rotation = -0.2
		5, 6:
			target_sun_energy = 1.5; target_sun_rotation = -0.4
		7, 8, 9, 10, 11:
			target_sun_energy = 5.0; target_sun_rotation = -0.9
		12, 13, 14, 15, 16:
			target_sun_energy = 4.5; target_sun_rotation = -0.7
		17, 18:
			target_sun_energy = 2.0; target_sun_rotation = -0.3
		19, 20, 21, 22, 23:
			target_sun_energy = 0.5; target_sun_rotation = -0.15
	if sun:
		var night = world_hour < 6 or world_hour > 19
		sun.light_color = Color(0.3, 0.35, 0.6) if night else Color(1.0, 0.97, 0.85)

func _apply_weather():
	match weather_state:
		"clear": target_fog_density = 0.0002
		"cloudy": target_fog_density = 0.0008; target_sun_energy *= 0.7
		"light_rain": target_fog_density = 0.0015; target_sun_energy *= 0.5
		"heavy_rain": target_fog_density = 0.003; target_sun_energy *= 0.3
		"storm": target_fog_density = 0.005; target_sun_energy *= 0.2
		"fog": target_fog_density = 0.008; target_sun_energy *= 0.6
		_: target_fog_density = 0.0003

func _season_name() -> String:
	match world_season:
		"spring": return "Primavera"
		"summer": return "Verao"
		"autumn": return "Outono"
		"winter": return "Inverno"
		_: return world_season

func _weather_name() -> String:
	match weather_state:
		"clear": return "Ensolarado"
		"cloudy": return "Nublado"
		"light_rain": return "Chuva Leve"
		"heavy_rain": return "Chuva Forte"
		"storm": return "Tempestade"
		"fog": return "Neblina"
		_: return weather_state.capitalize()
