extends Node

const MAX_BYTES := 5 * 1024 * 1024

var _log_path: String = ""

func _ready() -> void:
	var dir := _logs_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	_log_path = dir.path_join("game.log")
	_rotate_if_needed(_log_path)
	write_log("Game logger initialized")

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
	var size := FileAccess.get_file_as_bytes(path).size()
	if size < MAX_BYTES:
		return
	var rotated := _logs_dir().path_join("game.%d.log" % Time.get_unix_time_from_system())
	DirAccess.rename_absolute(path, rotated)

func write_log(msg: String) -> void:
	var line := "[%d] %s\n" % [Time.get_unix_time_from_system(), msg]
	var f := FileAccess.open(_log_path, FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_string(line)
		f.close()
	if OS.is_debug_build():
		print(msg)

func warn(msg: String) -> void:
	write_log("WARN: " + msg)

func error(msg: String) -> void:
	write_log("ERROR: " + msg)
