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
