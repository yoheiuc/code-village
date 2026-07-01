extends Node
class_name SaveManager

const UserSettingsScript = preload("res://scripts/config/user_settings.gd")
const VillageStateScript = preload("res://scripts/village/village_state.gd")

const SAVE_PATH := "user://code_village_save.json"
const SAVE_PATH_ENV := "CODE_VILLAGE_SAVE_PATH"
const SCHEMA_VERSION := 1

var save_path: String = SAVE_PATH
var last_load_warning: String = ""

func _init() -> void:
	var override_path := OS.get_environment(SAVE_PATH_ENV).strip_edges()
	if override_path != "":
		save_path = override_path

func load_game() -> Dictionary:
	last_load_warning = ""
	var defaults := get_default_save()
	if not FileAccess.file_exists(save_path):
		return defaults

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		last_load_warning = "Save file could not be opened."
		return defaults

	var text := file.get_as_text()
	if text.strip_edges() == "":
		last_load_warning = "Save file is empty."
		return defaults

	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		last_load_warning = "Save file JSON parse failed: %s" % json.get_error_message()
		return defaults

	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		last_load_warning = "Save file root is not an object."
		return defaults

	return _merge_defaults(defaults, parsed)

func save_game(data: Dictionary) -> bool:
	var safe_data := _merge_defaults(get_default_save(), data)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(safe_data, "\t"))
	return true

func get_default_save() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"settings": UserSettingsScript.new().to_dict(),
		"repositories": [],
		"onboarding_guide_dismissed": false,
		"imported_activity_event_ids": [],
		"village_state": VillageStateScript.new().to_dict(),
		"activity_events": [],
		"growth_events": [],
	}

func get_save_path() -> String:
	return save_path

func delete_save() -> bool:
	if not FileAccess.file_exists(save_path):
		return true
	return DirAccess.remove_absolute(save_path) == OK

func _merge_defaults(defaults: Dictionary, data: Dictionary) -> Dictionary:
	var merged := defaults.duplicate(true)
	for key in data.keys():
		if merged.has(key) and typeof(merged[key]) == TYPE_DICTIONARY and typeof(data[key]) == TYPE_DICTIONARY:
			merged[key] = _merge_defaults(merged[key], data[key])
		else:
			merged[key] = data[key]
	return merged
