extends Node3D
# Orchestrates a match: build the maze, drop the player on a valid floor cell.

@onready var maze: MazeRenderer = $MazeRenderer
@onready var player: CharacterBody3D = $Player

func _ready() -> void:
	# Child _ready() runs before parent, so the maze grid already exists here.
	player.global_position = maze.get_spawn_position()
