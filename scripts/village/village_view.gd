extends Node2D
class_name VillageView

const AssetCatalogScript = preload("res://scripts/assets/asset_catalog.gd")
const VillageSpriteLayerScript = preload("res://scripts/village/village_sprite_layer.gd")
const VillageTileLayerScript = preload("res://scripts/village/village_tile_layer.gd")
const VillageStateScript = preload("res://scripts/village/village_state.gd")

var asset_catalog = AssetCatalogScript.new()
var village_state = VillageStateScript.new()
var tile_layer = VillageTileLayerScript.new()
var sprite_layer = VillageSpriteLayerScript.new()
var elapsed: float = 0.0

func _ready() -> void:
	asset_catalog.load_manifest()
	tile_layer.name = "TileLayer"
	tile_layer.z_index = -100
	tile_layer.show_behind_parent = true
	add_child(tile_layer)
	tile_layer.setup(asset_catalog)
	sprite_layer.name = "SpriteLayer"
	add_child(sprite_layer)
	sprite_layer.setup(asset_catalog)
	sprite_layer.apply_village_state(village_state)
	_update_world_layer_transform()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func set_village_state(state) -> void:
	village_state = state
	if sprite_layer != null:
		sprite_layer.apply_village_state(village_state)
	queue_redraw()

func show_growth_events(growth_events: Array) -> void:
	if sprite_layer != null:
		sprite_layer.show_growth_events(growth_events)

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var reference_size := asset_catalog.reference_resolution()
	var scale_factor := minf(viewport_size.x / reference_size.x, viewport_size.y / reference_size.y)
	var offset := (viewport_size - reference_size * scale_factor) * 0.5
	_update_world_layer_transform()
	draw_set_transform(offset, 0.0, Vector2(scale_factor, scale_factor))

	if not _has_tile_layer():
		_draw_ground()
		_draw_water()
		_draw_paths()
	if not _has_sprite("plaza_core"):
		_draw_plaza()
	if not _has_sprite("debug_bridge"):
		_draw_bridge()
	if not _has_sprite("workshop") or not _has_sprite("library"):
		_draw_buildings()
	if not _has_sprite("tree_northwest"):
		_draw_trees()
	if not _has_sprite("branch_tree"):
		_draw_branch_tree()
	if not _has_growth_sprite("flower"):
		_draw_flowers()
	if not _has_growth_sprite("lantern"):
		_draw_lanterns()
	if not _has_sprite("issue_board") or not _has_sprite("release_bell"):
		_draw_board_and_bell()
	if not _has_sprite("resident_a") or not _has_sprite("resident_b"):
		_draw_residents()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_ground() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), _c("grass", "#7aa36f"))
	draw_rect(Rect2(0, 520, 1280, 200), _c("lower_grass", "#6f945f"))
	for x in range(0, 1280, 64):
		draw_line(Vector2(x, 0), Vector2(x - 120, 720), Color(1, 1, 1, 0.035), 2.0)

func _draw_water() -> void:
	var shimmer := sin(elapsed * 1.8) * 4.0
	draw_circle(Vector2(912, 408), 88, _c("water", "#4f8ca8"))
	draw_circle(Vector2(878, 384), 48, _c("water_highlight", "#69a9c3"))
	draw_arc(Vector2(912, 408), 62 + shimmer, 0.2, 2.7, 24, _c("water_line", "#b6dce5"), 3.0)

func _draw_paths() -> void:
	var path_color := _c("path", "#d8c58f")
	var repaired_color := _c("repaired_path", "#ead9a8")
	var width := 30.0 + float(village_state.repaired_paths) * 2.0
	draw_line(Vector2(260, 450), Vector2(640, 360), path_color, width)
	draw_line(Vector2(640, 360), Vector2(908, 408), path_color, width)
	draw_line(Vector2(640, 360), Vector2(420, 210), path_color, width)
	draw_line(Vector2(640, 360), Vector2(782, 224), path_color, width)
	if village_state.repaired_paths > 0:
		draw_line(Vector2(260, 450), Vector2(640, 360), repaired_color, 8.0)
		draw_line(Vector2(640, 360), Vector2(908, 408), repaired_color, 8.0)

func _draw_plaza() -> void:
	draw_circle(Vector2(640, 360), 82, _c("plaza", "#b8aa82"))
	draw_arc(Vector2(640, 360), 56, 0.0, TAU, 32, _c("plaza_line", "#ece2bd"), 4.0)
	draw_circle(Vector2(640, 360), 14, _c("stone", "#7f6f59"))

func _draw_bridge() -> void:
	var bridge_color := _c("bridge_worn", "#8a5f42") if village_state.bridge_state == "worn" else _c("bridge_repaired", "#b37a4f")
	draw_rect(Rect2(842, 386, 140, 42), bridge_color)
	for x in range(852, 974, 24):
		draw_line(Vector2(x, 388), Vector2(x, 426), _c("wood_dark", "#5d4335"), 2.0)
	draw_line(Vector2(838, 382), Vector2(986, 382), _c("wood_dark", "#5d4335"), 5.0)
	draw_line(Vector2(838, 432), Vector2(986, 432), _c("wood_dark", "#5d4335"), 5.0)

func _draw_buildings() -> void:
	_draw_workshop(Vector2(248, 214))
	_draw_library(Vector2(760, 174))

func _draw_workshop(pos: Vector2) -> void:
	var body := Rect2(pos.x, pos.y, 170, 120)
	draw_rect(body, _c("workshop_body", "#bd7c55"))
	draw_polygon([
		Vector2(pos.x - 12, pos.y),
		Vector2(pos.x + 85, pos.y - 62),
		Vector2(pos.x + 182, pos.y),
	], [_c("workshop_roof", "#6f4b43")])
	draw_rect(Rect2(pos.x + 66, pos.y + 58, 38, 62), _c("door", "#5d4639"))
	draw_rect(Rect2(pos.x + 20, pos.y + 34, 34, 30), _c("window_warm", "#f0c86b"))
	draw_rect(Rect2(pos.x + 116, pos.y + 34, 34, 30), _c("window_warm", "#f0c86b"))
	_draw_label_plaque(pos + Vector2(34, 104), "WORK")

func _draw_library(pos: Vector2) -> void:
	var level_bonus: int = min(village_state.library_level, 5) * 4
	draw_rect(Rect2(pos.x, pos.y - level_bonus, 180, 130 + level_bonus), _c("library_body", "#c8aa63"))
	draw_polygon([
		Vector2(pos.x - 10, pos.y - level_bonus),
		Vector2(pos.x + 90, pos.y - 66 - level_bonus),
		Vector2(pos.x + 190, pos.y - level_bonus),
	], [_c("library_roof", "#4b6f89")])
	for i in range(3):
		var x := pos.x + 30 + i * 48
		draw_rect(Rect2(x, pos.y + 28, 22, 72), _c("wood_dark", "#806d53"))
	draw_rect(Rect2(pos.x + 68, pos.y + 68, 44, 62), _c("door", "#5b513f"))
	_draw_label_plaque(pos + Vector2(40, 112), "DOCS")

func _draw_label_plaque(pos: Vector2, text: String) -> void:
	draw_rect(Rect2(pos.x, pos.y, 68, 20), _c("plaque", "#3e4b40"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(10, 15), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, _c("plaque_text", "#f5ecd0"))

func _draw_trees() -> void:
	var tree_positions := [
		Vector2(132, 134),
		Vector2(162, 472),
		Vector2(1090, 204),
		Vector2(1126, 496),
		Vector2(552, 128),
	]
	for pos in tree_positions:
		draw_rect(Rect2(pos.x - 8, pos.y + 16, 16, 36), _c("tree_trunk", "#7a5036"))
		draw_circle(pos, 38, _c("tree_leaf", "#3f7a55"))
		draw_circle(pos + Vector2(-20, 12), 26, _c("tree_leaf_light", "#4d8b5e"))
		draw_circle(pos + Vector2(20, 12), 26, _c("tree_leaf_dark", "#356947"))

func _draw_branch_tree() -> void:
	var pos := Vector2(1028, 118)
	draw_rect(Rect2(pos.x - 10, pos.y + 30, 20, 80), _c("tree_trunk", "#6d4b35"))
	draw_line(pos + Vector2(0, 50), pos + Vector2(-42, 8), _c("tree_trunk", "#6d4b35"), 7.0)
	draw_line(pos + Vector2(0, 52), pos + Vector2(42, 4), _c("tree_trunk", "#6d4b35"), 7.0)
	draw_circle(pos, 42 + village_state.branch_tree_level * 2, _c("branch_tree_leaf", "#4f8f61"))
	draw_circle(pos + Vector2(-44, 10), 24 + village_state.branch_tree_level, _c("branch_tree_leaf_light", "#6fa96d"))
	draw_circle(pos + Vector2(44, 4), 24 + village_state.branch_tree_level, _c("branch_tree_leaf_mid", "#5b9c68"))

func _draw_flowers() -> void:
	var count := mini(village_state.flowers, 36)
	for i in range(count):
		var x := 210 + (i * 43) % 820
		var y := 526 + ((i * 31) % 108)
		var color := _c("flower_red", "#f08a87") if i % 3 == 0 else (_c("flower_yellow", "#f0c85a") if i % 3 == 1 else _c("flower_pink", "#d8a2d2"))
		draw_circle(Vector2(x, y), 5, color)
		draw_circle(Vector2(x, y + 7), 2, _c("stem", "#2f6e4c"))

func _draw_lanterns() -> void:
	var lantern_positions := [
		Vector2(548, 314),
		Vector2(724, 308),
		Vector2(342, 408),
		Vector2(818, 382),
		Vector2(478, 248),
		Vector2(690, 454),
	]
	var count := mini(village_state.lanterns, lantern_positions.size())
	for i in range(count):
		var pos: Vector2 = lantern_positions[i]
		draw_line(pos + Vector2(0, 16), pos + Vector2(0, 48), _c("lantern_post", "#4f4038"), 4.0)
		draw_circle(pos, 13, _c("lantern_glow", "#f2d071"))
		draw_circle(pos, 20 + sin(elapsed * 2.0 + i) * 1.5, Color(1.0, 0.78, 0.32, 0.16))

func _draw_board_and_bell() -> void:
	var board_pos := Vector2(530, 198)
	draw_rect(Rect2(board_pos.x, board_pos.y, 100, 62), _c("board", "#8c6244"))
	draw_rect(Rect2(board_pos.x + 12, board_pos.y + 12, 76, 38), _c("paper", "#d8c58f"))
	draw_line(board_pos + Vector2(18, 22), board_pos + Vector2(80, 22), _c("board_line", "#6d5847"), 2.0)
	draw_line(board_pos + Vector2(18, 34), board_pos + Vector2(66, 34), _c("board_line", "#6d5847"), 2.0)
	draw_line(board_pos + Vector2(18, 46), board_pos + Vector2(72, 46), _c("board_line", "#6d5847"), 2.0)

	var bell_pos := Vector2(644, 260)
	draw_line(bell_pos + Vector2(0, -26), bell_pos + Vector2(0, 20), _c("bell_post", "#5c4a3b"), 4.0)
	draw_arc(bell_pos, 20, PI, TAU, 18, _c("bell", "#d6a33e"), 10.0)
	draw_circle(bell_pos + Vector2(0, 16), 5, _c("flower_yellow", "#f0c85a"))

func _draw_residents() -> void:
	_draw_resident(Vector2(604, 430), _c("resident_a", "#6b789f"))
	_draw_resident(Vector2(706, 414), _c("resident_b", "#8f6d8f"))

func _draw_resident(pos: Vector2, color: Color) -> void:
	draw_circle(pos + Vector2(0, -18), 12, _c("resident_skin", "#d9b18f"))
	draw_rect(Rect2(pos.x - 12, pos.y - 6, 24, 34), color)
	draw_line(pos + Vector2(-8, 28), pos + Vector2(-12, 44), _c("resident_leg", "#443a35"), 4.0)
	draw_line(pos + Vector2(8, 28), pos + Vector2(12, 44), _c("resident_leg", "#443a35"), 4.0)

func _c(key: String, fallback: String) -> Color:
	return asset_catalog.placeholder_color(key, fallback)

func _has_sprite(sprite_name: String) -> bool:
	return sprite_layer != null and sprite_layer.has_sprite(sprite_name)

func _has_growth_sprite(kind: String) -> bool:
	return sprite_layer != null and sprite_layer.growth_sprite_count(kind) > 0

func _update_world_layer_transform() -> void:
	var viewport_size := get_viewport_rect().size
	var reference_size := asset_catalog.reference_resolution()
	var scale_factor := minf(viewport_size.x / reference_size.x, viewport_size.y / reference_size.y)
	var offset := (viewport_size - reference_size * scale_factor) * 0.5
	if tile_layer != null:
		tile_layer.position = offset
		tile_layer.scale = Vector2(scale_factor, scale_factor)
	if sprite_layer != null:
		sprite_layer.position = offset
		sprite_layer.scale = Vector2(scale_factor, scale_factor)

func _has_tile_layer() -> bool:
	return tile_layer != null and tile_layer.built
