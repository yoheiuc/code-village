extends RefCounted
class_name AssetCatalog

const MANIFEST_PATH := "res://assets/asset_manifest.json"
const MANIFEST_ENV := "CODE_VILLAGE_ASSET_MANIFEST"

var manifest_path: String = MANIFEST_PATH
var manifest: Dictionary = {}
var loaded: bool = false
var errors: Array[String] = []

func _init() -> void:
	var override_path := OS.get_environment(MANIFEST_ENV).strip_edges()
	if override_path != "":
		manifest_path = override_path

func load_manifest() -> bool:
	errors.clear()
	if not FileAccess.file_exists(manifest_path):
		errors.append("asset manifest not found: %s" % manifest_path)
		manifest = {}
		loaded = false
		return false

	var raw := FileAccess.get_file_as_string(manifest_path)
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("asset manifest is not a JSON object")
		manifest = {}
		loaded = false
		return false

	manifest = Dictionary(parsed)
	loaded = true
	return true

func ensure_loaded() -> void:
	if not loaded:
		load_manifest()

func mode() -> String:
	ensure_loaded()
	return String(manifest.get("mode", "placeholder"))

func tile_size() -> int:
	ensure_loaded()
	return int(manifest.get("tile_size", 16))

func reference_resolution() -> Vector2:
	ensure_loaded()
	var size := Array(manifest.get("reference_resolution", [1280, 720]))
	if size.size() < 2:
		return Vector2(1280, 720)
	return Vector2(float(size[0]), float(size[1]))

func asset_path(section: String, key: String) -> String:
	ensure_loaded()
	var section_data := Dictionary(manifest.get(section, {}))
	return String(section_data.get(key, ""))

func growth_visual_path(growth_type: String) -> String:
	ensure_loaded()
	var visuals := Dictionary(manifest.get("growth_visuals", {}))
	return String(visuals.get(growth_type, ""))

func sprite_layout() -> Array:
	ensure_loaded()
	return Array(manifest.get("sprite_layout", []))

func state_visual_rules() -> Array:
	ensure_loaded()
	return Array(manifest.get("state_visual_rules", []))

func growth_effect_anchor(key: String) -> Dictionary:
	ensure_loaded()
	var anchors := Dictionary(manifest.get("growth_effect_anchors", {}))
	if anchors.has(key):
		return Dictionary(anchors.get(key, {}))
	return Dictionary(anchors.get("default", {}))

func placeholder_color(key: String, fallback: String) -> Color:
	ensure_loaded()
	var colors := Dictionary(manifest.get("placeholder_colors", {}))
	var value := String(colors.get(key, fallback))
	return Color.from_string(value, Color.from_string(fallback, Color.WHITE))

func asset_exists(section: String, key: String) -> bool:
	var path := asset_path(section, key)
	return path != "" and FileAccess.file_exists(path)

func growth_visual_exists(growth_type: String) -> bool:
	var path := growth_visual_path(growth_type)
	return path != "" and FileAccess.file_exists(path)
