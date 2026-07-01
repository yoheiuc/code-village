extends RefCounted
class_name RepositoryConfig

const PRIVACY_MODE_METADATA_ONLY := "metadata_only"

var id: String = ""
var display_name: String = ""
var local_path: String = ""
var enabled: bool = true
var created_at: String = ""
var last_scanned_at: String = ""
var privacy_mode: String = PRIVACY_MODE_METADATA_ONLY
var last_scan_metadata: Dictionary = {}

func setup_from_path(path: String):
	var normalized_path := path.simplify_path()
	id = "repo-%d" % absi(hash(normalized_path))
	display_name = normalized_path.get_file()
	if display_name == "":
		display_name = normalized_path
	local_path = normalized_path
	enabled = true
	created_at = Time.get_datetime_string_from_system(true)
	last_scanned_at = ""
	privacy_mode = PRIVACY_MODE_METADATA_ONLY
	return self

func load_from_dict(data: Dictionary):
	id = String(data.get("id", ""))
	display_name = String(data.get("display_name", ""))
	local_path = String(data.get("local_path", ""))
	enabled = bool(data.get("enabled", true))
	created_at = String(data.get("created_at", ""))
	last_scanned_at = String(data.get("last_scanned_at", ""))
	privacy_mode = String(data.get("privacy_mode", PRIVACY_MODE_METADATA_ONLY))
	last_scan_metadata = Dictionary(data.get("last_scan_metadata", {})).duplicate(true)
	return self

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"local_path": local_path,
		"enabled": enabled,
		"created_at": created_at,
		"last_scanned_at": last_scanned_at,
		"privacy_mode": privacy_mode,
		"last_scan_metadata": last_scan_metadata.duplicate(true),
	}
