extends RefCounted
class_name ClaudeCodeActivityIngestor

const ActivityEventScript = preload("res://scripts/activity/activity_event.gd")

const DEFAULT_INBOX_RELATIVE_PATH := "Library/Application Support/Code Village/activity_inbox/claude_code_events.jsonl"
const ALLOWED_TYPES := {
	"claude_code_session": true,
	"claude_code_turn_completed": true,
}
const ALLOWED_METADATA_KEYS := {
	"project_label": true,
	"hook_event": true,
	"session_hash": true,
	"source": true,
}

var inbox_path: String = ""

func import_events(imported_event_ids: Array) -> Dictionary:
	var path := get_inbox_path()
	var result := {
		"ok": true,
		"events": [],
		"imported_ids": [],
		"errors": [],
		"inbox_path": path,
	}

	if not FileAccess.file_exists(path):
		return result

	var imported_lookup := {}
	for id in imported_event_ids:
		imported_lookup[String(id)] = true

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result["ok"] = false
		result["errors"].append("Claude Code activity inbox could not be opened.")
		return result

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "":
			continue
		var parsed = JSON.parse_string(line)
		if typeof(parsed) != TYPE_DICTIONARY:
			result["errors"].append("Ignored malformed Claude Code activity line.")
			continue
		var event_dict := _sanitize_event_dict(Dictionary(parsed))
		if event_dict.is_empty():
			continue
		var event_id := String(event_dict.get("id", ""))
		if imported_lookup.has(event_id):
			continue
		var event = ActivityEventScript.new().load_from_dict(event_dict)
		result["events"].append(event)
		result["imported_ids"].append(event_id)
		imported_lookup[event_id] = true

	return result

func get_inbox_path() -> String:
	if inbox_path != "":
		return inbox_path
	var env_path := OS.get_environment("CODE_VILLAGE_ACTIVITY_INBOX")
	if env_path != "":
		return env_path
	return OS.get_environment("HOME").path_join(DEFAULT_INBOX_RELATIVE_PATH)

func _sanitize_event_dict(data: Dictionary) -> Dictionary:
	var event_id := String(data.get("id", "")).strip_edges()
	var event_type := String(data.get("type", "")).strip_edges()
	if event_id == "" or not ALLOWED_TYPES.has(event_type):
		return {}

	var metadata := {}
	var raw_metadata := Dictionary(data.get("metadata", {}))
	for key in raw_metadata.keys():
		var key_string := String(key)
		if ALLOWED_METADATA_KEYS.has(key_string):
			metadata[key_string] = _sanitize_metadata_value(key_string, raw_metadata[key])

	return {
		"id": event_id,
		"type": event_type,
		"occurred_at": String(data.get("occurred_at", Time.get_datetime_string_from_system(true))).substr(0, 40),
		"source": "claude_code_hook",
		"repository_id": "",
		"metadata": metadata,
		"privacy_level": ActivityEventScript.PRIVACY_METADATA_ONLY,
	}

func _sanitize_metadata_value(key: String, value) -> String:
	var raw := String(value).strip_edges()
	if key == "project_label":
		var normalized := raw.replace("\\", "/")
		if normalized.find("/") != -1:
			return normalized.get_file().substr(0, 80)
		return normalized.substr(0, 80)
	return raw.substr(0, 120)
