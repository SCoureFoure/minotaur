extends Node3D
# Screenshot fly-through bot. Builds a maze, then drives a free camera through the
# poses from MazeCapture.waypoints(), saving a PNG + sidecar per pose via the shared
# Screenshotter.capture_view(). Run NON-headless as its own main scene:
#   godot --path . res://scenes/capture.tscn
# It self-quits after the last shot. Headless produces blank images (dummy renderer),
# so this must run with a real rendering driver.

@onready var maze: MazeRenderer = $MazeRenderer
@onready var cam: Camera3D = $BotCam
@onready var shot: Node = $Screenshotter

# Fixed, small, deterministic maze so the bot is fast and repeatable.
@export var bot_seed: int = 1337

func _ready() -> void:
	get_window().title = "Minotaur — Capture Bot"
	maze.use_volume = true
	maze.auto_size_from_players = false
	maze.cols = 6
	maze.rows = 6
	maze.layers = 3
	maze.maze_seed = bot_seed
	maze.build()
	cam.current = true
	await _run()

func _run() -> void:
	var ws: Dictionary = maze.debug_state()
	var wps: Array = MazeCapture.waypoints(ws)

	# Warm a few frames so geometry is built and rendered before the first grab.
	for i in 6:
		await RenderingServer.frame_post_draw

	for wp in wps:
		cam.global_position = wp["pos"]
		_look_at(cam, wp["target"])
		# Two post-draw waits: one to render the new pose, one margin.
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		shot.capture_view(cam, maze, wp["label"])
		await RenderingServer.frame_post_draw

	print("[capture_bot] done: ", wps.size(), " shots")
	get_tree().quit()

# look_at with a safe up-vector: if the view direction is near-vertical (overhead),
# UP is degenerate, so fall back to a horizontal up.
func _look_at(c: Camera3D, target: Vector3) -> void:
	var dir := (target - c.global_position).normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3(0, 0, -1)
	c.look_at(target, up)
