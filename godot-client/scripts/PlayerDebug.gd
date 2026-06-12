extends Node

const MAX_BYTES := 3 * 1024 * 1024
var _path: String = ""

func _ready() -> void:
	var dir := _logs_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	_path = dir.path_join("player_debug.log")
	_rotate_if_needed(_path)

func _logs_dir() -> String:
	if OS.get_name() == "Windows":
		var base := OS.get_environment("LOCALAPPDATA")
		if base.is_empty():
			base = OS.get_user_data_dir()
		return base.path_join("DarkWorld").path_join("logs").path_join("game")
	return OS.get_user_data_dir().path_join("logs").path_join("game")

func _rotate_if_needed(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	if FileAccess.get_file_as_bytes(path).size() >= MAX_BYTES:
		var rotated := _logs_dir().path_join("player_debug.%d.log" % Time.get_unix_time_from_system())
		DirAccess.rename_absolute(path, rotated)

func log_event(tag: String, detail: String = "") -> void:
	var line := "[%d] %s" % [Time.get_unix_time_from_system(), tag]
	if detail != "":
		line += " " + detail
	var f := FileAccess.open(_path, FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_line(line)
		f.close()
