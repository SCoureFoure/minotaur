extends Control
# Debug main menu: reads/writes match and debug settings via the GameSettings autoload.

@onready var player_count_spin: SpinBox  = $VBox/PlayerCountRow/PlayerCount
@onready var auto_size_check: CheckBox   = $VBox/AutoSizeRow/AutoSize
@onready var cols_spin: SpinBox          = $VBox/ColsRow/Cols
@onready var rows_spin: SpinBox          = $VBox/RowsRow/Rows
@onready var layers_spin: SpinBox        = $VBox/LayersRow/Layers
@onready var braid_spin: SpinBox         = $VBox/BraidRow/Braid
@onready var level_height_spin: SpinBox  = $VBox/LevelHeightRow/LevelHeight
@onready var links_per_pair_spin: SpinBox = $VBox/LinksPerPairRow/LinksPerPair
@onready var entrance_count_spin: SpinBox = $VBox/EntranceCountRow/EntranceCount
@onready var maze_seed_spin: SpinBox     = $VBox/MazeSeedRow/MazeSeed
@onready var cave_calibration_check: CheckBox = $VBox/CaveCalibrationRow/CaveCalibration
@onready var play_button: Button         = $VBox/PlayButton
@onready var quit_button: Button         = $VBox/QuitButton

func _ready() -> void:
	# Populate controls from persisted settings first, then wire signals so
	# the initial population does not trigger redundant set_value calls.
	player_count_spin.value       = GameSettings.get_value("match", "player_count")
	auto_size_check.button_pressed = GameSettings.get_value("match", "auto_size_from_players")
	cols_spin.value               = GameSettings.get_value("match", "cols")
	rows_spin.value               = GameSettings.get_value("match", "rows")
	layers_spin.value             = GameSettings.get_value("match", "layers")
	braid_spin.value              = GameSettings.get_value("match", "braid")
	level_height_spin.value       = GameSettings.get_value("match", "level_height")
	links_per_pair_spin.value     = GameSettings.get_value("match", "links_per_pair")
	entrance_count_spin.value     = GameSettings.get_value("match", "entrance_count")
	maze_seed_spin.value          = GameSettings.get_value("match", "maze_seed")
	cave_calibration_check.button_pressed = GameSettings.get_value("debug", "cave_calibration")

	# Wire change signals — lambdas cast int fields explicitly.
	player_count_spin.value_changed.connect(
		func(v: float) -> void: GameSettings.set_value("match", "player_count", int(v)))
	auto_size_check.toggled.connect(
		func(v: bool) -> void: GameSettings.set_value("match", "auto_size_from_players", v))
	cols_spin.value_changed.connect(
		func(v: float) -> void: GameSettings.set_value("match", "cols", int(v)))
	rows_spin.value_changed.connect(
		func(v: float) -> void: GameSettings.set_value("match", "rows", int(v)))
	layers_spin.value_changed.connect(
		func(v: float) -> void: GameSettings.set_value("match", "layers", int(v)))
	braid_spin.value_changed.connect(
		func(v: float) -> void: GameSettings.set_value("match", "braid", v))
	level_height_spin.value_changed.connect(
		func(v: float) -> void: GameSettings.set_value("match", "level_height", v))
	links_per_pair_spin.value_changed.connect(
		func(v: float) -> void: GameSettings.set_value("match", "links_per_pair", int(v)))
	entrance_count_spin.value_changed.connect(
		func(v: float) -> void: GameSettings.set_value("match", "entrance_count", int(v)))
	maze_seed_spin.value_changed.connect(
		func(v: float) -> void: GameSettings.set_value("match", "maze_seed", int(v)))
	cave_calibration_check.toggled.connect(
		func(v: bool) -> void: GameSettings.set_value("debug", "cave_calibration", v))

	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
