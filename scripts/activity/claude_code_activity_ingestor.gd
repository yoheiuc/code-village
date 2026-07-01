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
const CHECKPOINT_SCHEMA_VERSION := 1
const MAX_INBOX_LINE_CHARS := 8192
const MAX_REPORTED_ERRORS := 5

var inbox_path: String = ""

func import_events(imported_event_ids: Array, checkpoint: Dictionary = {}) -> Dictionary:
	var path := get_inbox_path()
	var previous_checkpoint := _normalize_checkpoint(checkpoint)
	var result := {
		"ok": true,
		"events": [],
		"imported_ids": [],
		"errors": [],
		"inbox_path": path,
		"checkpoint": previous_checkpoint.duplicate(true),
		"checkpoint_changed": false,
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

	var file_length := file.get_length()
	if file_length == 0:
		var empty_checkpoint := _build_checkpoint(path, 0, 0)
		result["checkpoint"] = empty_checkpoint
		result["checkpoint_changed"] = _checkpoint_has_position(previous_checkpoint)
		return result

	var start_offset := _resume_offset(previous_checkpoint, path, file_length)
	if start_offset > 0:
		file.seek(start_offset)

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "":
			continue
		if line.length() > MAX_INBOX_LINE_CHARS:
			_append_error(result["errors"], "Ignored oversized Claude Code activity line.")
			continue
		var parsed = JSON.parse_string(line)
		if typeof(parsed) != TYPE_DICTIONARY:
			_append_error(result["errors"], "Ignored malformed Claude Code activity line.")
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

	var next_checkpoint := _build_checkpoint(path, file.get_position(), file.get_length())
	result["checkpoint"] = next_checkpoint
	result["checkpoint_changed"] = not _checkpoint_equal(previous_checkpoint, next_checkpoint)

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

func _normalize_checkpoint(checkpoint: Dictionary) -> Dictionary:
	return {
		"schema_version": int(checkpoint.get("schema_version", CHECKPOINT_SCHEMA_VERSION)),
		"path_hash": String(checkpoint.get("path_hash", "")),
		"offset": max(0, int(checkpoint.get("offset", 0))),
		"file_size": max(0, int(checkpoint.get("file_size", 0))),
		"modified_time": max(0, int(checkpoint.get("modified_time", 0))),
		"updated_at": String(checkpoint.get("updated_at", "")),
	}

func _resume_offset(checkpoint: Dictionary, path: String, file_size: int) -> int:
	if int(checkpoint.get("schema_version", 0)) != CHECKPOINT_SCHEMA_VERSION:
		return 0
	if String(checkpoint.get("path_hash", "")) != _path_hash(path):
		return 0
	var offset := int(checkpoint.get("offset", 0))
	if offset < 0 or offset > file_size:
		return 0
	return offset

func _build_checkpoint(path: String, offset: int, file_size: int) -> Dictionary:
	return {
		"schema_version": CHECKPOINT_SCHEMA_VERSION,
		"path_hash": _path_hash(path),
		"offset": max(0, offset),
		"file_size": max(0, file_size),
		"modified_time": max(0, int(FileAccess.get_modified_time(path))),
		"updated_at": Time.get_datetime_string_from_system(true),
	}

func _checkpoint_equal(left: Dictionary, right: Dictionary) -> bool:
	for key in ["schema_version", "path_hash", "offset", "file_size", "modified_time"]:
		if left.get(key) != right.get(key):
			return false
	return true

func _checkpoint_has_position(checkpoint: Dictionary) -> bool:
	return String(checkpoint.get("path_hash", "")) != "" or int(checkpoint.get("offset", 0)) > 0 or int(checkpoint.get("file_size", 0)) > 0

func _append_error(errors: Array, message: String) -> void:
	if errors.size() < MAX_REPORTED_ERRORS:
		errors.append(message)

func _path_hash(path: String) -> String:
	return path.sha256_text().substr(0, 16)
