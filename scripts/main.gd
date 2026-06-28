extends Node3D
# Orchestrates a match: apply persisted settings, build the maze, drop the player.

@onready var maze: MazeRenderer = $MazeRenderer
@onready var player: CharacterBody3D = $Player

func _ready() -> void:
	# Pull tunables from the GameSettings autoload and apply before building.
	maze.player_count = GameSettings.get_value("match", "player_count")
	maze.auto_size_from_players = GameSettings.get_value("match", "auto_size_from_players")
	maze.cols = GameSettings.get_value("match", "cols")
	maze.rows = GameSettings.get_value("match", "rows")
	maze.layers = GameSettings.get_value("match", "layers")
	maze.braid = GameSettings.get_value("match", "braid")
	maze.level_height = GameSettings.get_value("match", "level_height")
	maze.links_per_pair = GameSettings.get_value("match", "links_per_pair")
	maze.entrance_count = GameSettings.get_value("match", "entrance_count")
	maze.maze_seed = GameSettings.get_value("match", "maze_seed")
	maze.cave_calibration = GameSettings.get_value("debug", "cave_calibration")
	maze.build()
	player.global_position = maze.get_spawn_position()
	_write_build_log()

func _write_build_log() -> void:
	if not maze.has_method("debug_state"):
		return
	var s: Dictionary = maze.debug_state()
	var ts := Time.get_datetime_dict_from_system()
	var ts_str := "%04d-%02d-%02d_%02d-%02d-%02d" % [ts.year, ts.month, ts.day, ts.hour, ts.minute, ts.second]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots/"))
	var log_path := "res://screenshots/run.log"
	var lf: FileAccess
	if FileAccess.file_exists(log_path):
		lf = FileAccess.open(log_path, FileAccess.READ_WRITE)
		if lf:
			lf.seek_end()
	else:
		lf = FileAccess.open(log_path, FileAccess.WRITE)
	if lf == null:
		return
	lf.store_line("")
	lf.store_line("[build] %s  seed=%s dims=%sx%sx%s grid=%sx%s cell=%s level_h=%s water=%s" % [
		ts_str, str(s.get("seed")), str(s.get("cols")), str(s.get("rows")), str(s.get("layers")),
		str(s.get("grid_w")), str(s.get("grid_h")), str(s.get("cell_size")),
		str(s.get("level_height")), str(s.get("water_level"))])
	lf.store_line("[build]   entrances=%s spawn=%s" % [str(s.get("entrance_cells")), str(s.get("spawn"))])
	lf.close()
