extends RefCounted
class_name ActivityEvent

const TYPE_COMMIT_CREATED := "commit_created"
const TYPE_CLAUDE_CODE_SESSION := "claude_code_session"
const TYPE_CLAUDE_CODE_TURN_COMPLETED := "claude_code_turn_completed"
const TYPE_TESTS_PASSED := "tests_passed"
const TYPE_DOCS_UPDATED := "docs_updated"
const TYPE_REFACTOR_DETECTED := "refactor_detected"
const TYPE_BUGFIX_DETECTED := "bugfix_detected"
const TYPE_RELEASE_TAG_CREATED := "release_tag_created"
const TYPE_BRANCH_CREATED := "branch_created"
const TYPE_PROJECT_ADDED := "project_added"
const TYPE_MANUAL_CODING_SESSION := "manual_coding_session"
const TYPE_MANUAL_REFLECTION_ADDED := "manual_reflection_added"

const PRIVACY_METADATA_ONLY := "metadata_only"
const PRIVACY_MANUAL_NOTE := "manual_note"

var id: String = ""
var type: String = ""
var occurred_at: String = ""
var source: String = ""
var repository_id: String = ""
var metadata: Dictionary = {}
var privacy_level: String = PRIVACY_METADATA_ONLY

func setup(
		event_type: String,
		event_source: String,
		event_repository_id: String = "",
		event_metadata: Dictionary = {},
		event_privacy_level: String = PRIVACY_METADATA_ONLY
	):
	id = _make_id(event_type)
	type = event_type
	occurred_at = Time.get_datetime_string_from_system(true)
	source = event_source
	repository_id = event_repository_id
	metadata = event_metadata.duplicate(true)
	privacy_level = event_privacy_level
	return self

func load_from_dict(data: Dictionary):
	id = String(data.get("id", ""))
	type = String(data.get("type", ""))
	occurred_at = String(data.get("occurred_at", ""))
	source = String(data.get("source", ""))
	repository_id = String(data.get("repository_id", ""))
	metadata = Dictionary(data.get("metadata", {})).duplicate(true)
	privacy_level = String(data.get("privacy_level", PRIVACY_METADATA_ONLY))
	return self

func to_dict() -> Dictionary:
	return {
		"id": id,
		"type": type,
		"occurred_at": occurred_at,
		"source": source,
		"repository_id": repository_id,
		"metadata": metadata.duplicate(true),
		"privacy_level": privacy_level,
	}

func _make_id(prefix: String) -> String:
	var timestamp := Time.get_datetime_string_from_system(true).replace(":", "").replace("-", "")
	return "%s-%s-%d" % [prefix, timestamp, randi()]
