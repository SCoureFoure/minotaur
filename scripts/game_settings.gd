extends Node
# Persistent settings store. Registered as autoload "GameSettings".
# No class_name — autoload name is the public handle.

const SAVE_PATH := "user://settings.cfg"
const DEFAULTS := {
	"match": {
		"player_count": 4,
		"auto_size_from_players": true,
		"cols": 12,
		"rows": 12,
		"layers": 3,
		"braid": 0.4,
		"level_height": 3.0,
		"links_per_pair": 3,
		"entrance_count": 3,
		"maze_seed": 0,
	},
	"debug": {
		"cave_calibration": false,
	},
}

# Injectable so tests can redirect writes to a temp path.
var save_path: String = SAVE_PATH
# Current section -> {key: value} map.
var data: Dictionary = {}

func _ready() -> void:
	load_from_disk()

func reset_to_defaults() -> void:
	# MUST deep-duplicate: const Dictionaries are still mutable shared refs in GDScript.
	# Assigning data = DEFAULTS would let mutations bleed into the const.
	data = DEFAULTS.duplicate(true)

func get_value(section: String, key: String) -> Variant:
	if data.has(section) and data[section].has(key):
		return data[section][key]
	# Fall back to DEFAULTS if the section or key is absent from data.
	return DEFAULTS[section][key]

func set_value(section: String, key: String, value) -> void:
	if not data.has(section):
		data[section] = {}
	data[section][key] = value
	save_to_disk()

func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	for section in data:
		for key in data[section]:
			cfg.set_value(section, key, data[section][key])
	cfg.save(save_path)

func load_from_disk() -> void:
	reset_to_defaults()
	var cfg := ConfigFile.new()
	var err := cfg.load(save_path)
	if err != OK:
		# File missing or unreadable — defaults already in place, silently continue.
		return
	for section in cfg.get_sections():
		for key in cfg.get_section_keys(section):
			if not data.has(section):
				data[section] = {}
			data[section][key] = cfg.get_value(section, key)
