extends RefCounted
class_name UserSettings

var local_only: bool = true
var store_commit_messages: bool = false
var store_file_names: bool = false
var enable_external_network: bool = false
var show_rest_day_messages: bool = true
var auto_import_claude_events: bool = true

func load_from_dict(data: Dictionary):
	local_only = bool(data.get("local_only", true))
	store_commit_messages = bool(data.get("store_commit_messages", false))
	store_file_names = bool(data.get("store_file_names", false))
	enable_external_network = bool(data.get("enable_external_network", false))
	show_rest_day_messages = bool(data.get("show_rest_day_messages", true))
	auto_import_claude_events = bool(data.get("auto_import_claude_events", true))
	return self

func to_dict() -> Dictionary:
	return {
		"local_only": local_only,
		"store_commit_messages": false,
		"store_file_names": false,
		"enable_external_network": false,
		"show_rest_day_messages": show_rest_day_messages,
		"auto_import_claude_events": auto_import_claude_events,
	}

func is_mvp_privacy_safe() -> bool:
	return local_only and not store_commit_messages and not store_file_names and not enable_external_network
