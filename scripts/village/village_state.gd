extends RefCounted
class_name VillageState

const GrowthEventScript = preload("res://scripts/village/growth_event.gd")

var village_level: int = 1
var flowers: int = 3
var lanterns: int = 1
var repaired_paths: int = 0
var bridge_state: String = "worn"
var library_level: int = 1
var workshop_level: int = 1
var branch_tree_level: int = 1
var release_bell_rings: int = 0
var diary_entries: Array = []
var resident_messages: Array = []
var last_updated_at: String = ""

func _init() -> void:
	last_updated_at = Time.get_datetime_string_from_system(true)
	resident_messages = [{
		"occurred_at": last_updated_at,
		"message": "何も変わらない日も、村はここにあります。",
	}]
	diary_entries = [{
		"occurred_at": last_updated_at,
		"title": "村のはじまり",
		"description": "小さな工房と図書館に灯りが入りました。",
		"growth_event_id": "",
	}]

func load_from_dict(data: Dictionary):
	if data.is_empty():
		return self

	village_level = int(data.get("village_level", 1))
	flowers = int(data.get("flowers", 3))
	lanterns = int(data.get("lanterns", 1))
	repaired_paths = int(data.get("repaired_paths", 0))
	bridge_state = String(data.get("bridge_state", "worn"))
	library_level = int(data.get("library_level", 1))
	workshop_level = int(data.get("workshop_level", 1))
	branch_tree_level = int(data.get("branch_tree_level", 1))
	release_bell_rings = int(data.get("release_bell_rings", 0))
	diary_entries = Array(data.get("diary_entries", [])).duplicate(true)
	resident_messages = Array(data.get("resident_messages", [])).duplicate(true)
	last_updated_at = String(data.get("last_updated_at", Time.get_datetime_string_from_system(true)))
	return self

func to_dict() -> Dictionary:
	return {
		"village_level": village_level,
		"flowers": flowers,
		"lanterns": lanterns,
		"repaired_paths": repaired_paths,
		"bridge_state": bridge_state,
		"library_level": library_level,
		"workshop_level": workshop_level,
		"branch_tree_level": branch_tree_level,
		"release_bell_rings": release_bell_rings,
		"diary_entries": diary_entries.duplicate(true),
		"resident_messages": resident_messages.duplicate(true),
		"last_updated_at": last_updated_at,
	}

func apply_growth_event(event, resident_message: String = "") -> void:
	match event.type:
		GrowthEventScript.TYPE_FLOWER_BLOOMED:
			flowers += event.intensity
		GrowthEventScript.TYPE_LANTERN_LIT:
			lanterns += event.intensity
		GrowthEventScript.TYPE_PATH_REPAIRED:
			repaired_paths += event.intensity
		GrowthEventScript.TYPE_BRIDGE_REPAIRED:
			bridge_state = "repaired"
		GrowthEventScript.TYPE_LIBRARY_EXPANDED:
			library_level += event.intensity
		GrowthEventScript.TYPE_WORKSHOP_UPGRADED:
			workshop_level += event.intensity
		GrowthEventScript.TYPE_BRANCH_TREE_GREW:
			branch_tree_level += event.intensity
		GrowthEventScript.TYPE_BELL_RANG:
			release_bell_rings += event.intensity
			workshop_level += 1
		GrowthEventScript.TYPE_PLAZA_DECORATED:
			flowers += 1
		_:
			pass

	village_level = _calculate_level()
	last_updated_at = Time.get_datetime_string_from_system(true)
	_add_diary_entry(event)
	if resident_message != "":
		add_resident_message(resident_message, event.id)

func add_resident_message(message: String, growth_event_id: String = "") -> void:
	resident_messages.push_front({
		"occurred_at": Time.get_datetime_string_from_system(true),
		"message": message,
		"growth_event_id": growth_event_id,
	})
	_trim_array(resident_messages, 40)

func get_latest_resident_message() -> String:
	if resident_messages.is_empty():
		return "何も変わらない日も、村はここにあります。"
	return String(Dictionary(resident_messages[0]).get("message", ""))

func get_recent_growth(limit: int = 5) -> Array:
	return diary_entries.slice(0, mini(limit, diary_entries.size()))

func get_today_entries() -> Array:
	var today_local := Time.get_date_string_from_system(false)
	var today_utc := Time.get_date_string_from_system(true)
	var entries: Array = []
	for entry in diary_entries:
		var occurred_at := String(Dictionary(entry).get("occurred_at", ""))
		if occurred_at.begins_with(today_local) or occurred_at.begins_with(today_utc):
			entries.append(entry)
	return entries

func _add_diary_entry(event) -> void:
	diary_entries.push_front({
		"occurred_at": event.occurred_at,
		"title": event.title,
		"description": event.description,
		"growth_event_id": event.id,
		"growth_event_type": event.type,
	})
	_trim_array(diary_entries, 80)

func _calculate_level() -> int:
	var growth_points := flowers + lanterns + repaired_paths + library_level + workshop_level + branch_tree_level + release_bell_rings
	if bridge_state == "repaired":
		growth_points += 3
	return maxi(1, int(floor(float(growth_points) / 6.0)) + 1)

func _trim_array(target: Array, max_size: int) -> void:
	while target.size() > max_size:
		target.pop_back()
