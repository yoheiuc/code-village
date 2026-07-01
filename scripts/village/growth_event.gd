extends RefCounted
class_name GrowthEvent

const TYPE_FLOWER_BLOOMED := "flower_bloomed"
const TYPE_PATH_REPAIRED := "path_repaired"
const TYPE_LANTERN_LIT := "lantern_lit"
const TYPE_BRIDGE_REPAIRED := "bridge_repaired"
const TYPE_LIBRARY_EXPANDED := "library_expanded"
const TYPE_WORKSHOP_UPGRADED := "workshop_upgraded"
const TYPE_BRANCH_TREE_GREW := "branch_tree_grew"
const TYPE_ISSUE_BOARD_UPDATED := "issue_board_updated"
const TYPE_RESIDENT_MESSAGE_ADDED := "resident_message_added"
const TYPE_DIARY_ENTRY_CREATED := "diary_entry_created"
const TYPE_PLAZA_DECORATED := "plaza_decorated"
const TYPE_BELL_RANG := "bell_rang"

var id: String = ""
var type: String = ""
var occurred_at: String = ""
var activity_event_id: String = ""
var title: String = ""
var description: String = ""
var visual_target: String = ""
var intensity: int = 1

func setup(
		growth_type: String,
		source_activity_event_id: String,
		growth_title: String,
		growth_description: String,
		growth_visual_target: String,
		growth_intensity: int = 1
	):
	id = _make_id(growth_type)
	type = growth_type
	occurred_at = Time.get_datetime_string_from_system(true)
	activity_event_id = source_activity_event_id
	title = growth_title
	description = growth_description
	visual_target = growth_visual_target
	intensity = clampi(growth_intensity, 1, 3)
	return self

func load_from_dict(data: Dictionary):
	id = String(data.get("id", ""))
	type = String(data.get("type", ""))
	occurred_at = String(data.get("occurred_at", ""))
	activity_event_id = String(data.get("activity_event_id", ""))
	title = String(data.get("title", ""))
	description = String(data.get("description", ""))
	visual_target = String(data.get("visual_target", ""))
	intensity = int(data.get("intensity", 1))
	return self

func to_dict() -> Dictionary:
	return {
		"id": id,
		"type": type,
		"occurred_at": occurred_at,
		"activity_event_id": activity_event_id,
		"title": title,
		"description": description,
		"visual_target": visual_target,
		"intensity": intensity,
	}

func _make_id(prefix: String) -> String:
	var timestamp := Time.get_datetime_string_from_system(true).replace(":", "").replace("-", "")
	return "%s-%s-%d" % [prefix, timestamp, randi()]
