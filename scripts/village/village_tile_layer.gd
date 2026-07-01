extends TileMapLayer
class_name VillageTileLayer

const SOURCE_ID := 0
const MAP_COLUMNS := 80
const MAP_ROWS := 45

const TILE_ATLAS := {
	"grass": Vector2i(0, 0),
	"lower_grass": Vector2i(1, 0),
	"path": Vector2i(2, 0),
	"water": Vector2i(3, 0),
	"plaza": Vector2i(4, 0),
}

const TILE_COLOR_FALLBACKS := {
	"grass": "#7aa36f",
	"lower_grass": "#6f945f",
	"path": "#d8c58f",
	"water": "#4f8ca8",
	"plaza": "#b8aa82",
}

var asset_catalog
var built: bool = false

func setup(catalog) -> void:
	asset_catalog = catalog
	tile_set = _build_tile_set()
	_paint_map()
	built = true

func _build_tile_set() -> TileSet:
	var new_tile_set := TileSet.new()
	new_tile_set.tile_size = Vector2i(asset_catalog.tile_size(), asset_catalog.tile_size())

	var texture := _build_tile_texture(new_tile_set.tile_size)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = new_tile_set.tile_size
	for atlas_coords in TILE_ATLAS.values():
		source.create_tile(atlas_coords)
	new_tile_set.add_source(source, SOURCE_ID)
	return new_tile_set

func _build_tile_texture(tile_size: Vector2i) -> Texture2D:
	var image := Image.create(tile_size.x * TILE_ATLAS.size(), tile_size.y, false, Image.FORMAT_RGBA8)
	for key in TILE_ATLAS.keys():
		var atlas_coords: Vector2i = TILE_ATLAS[key]
		var color: Color = asset_catalog.placeholder_color(String(key), String(TILE_COLOR_FALLBACKS[key]))
		image.fill_rect(Rect2i(atlas_coords.x * tile_size.x, 0, tile_size.x, tile_size.y), color)
		_add_tile_marks(image, atlas_coords, tile_size, String(key))
	return ImageTexture.create_from_image(image)

func _add_tile_marks(image: Image, atlas_coords: Vector2i, tile_size: Vector2i, key: String) -> void:
	var origin := Vector2i(atlas_coords.x * tile_size.x, 0)
	var mark_color := Color(1, 1, 1, 0.045)
	if key == "path":
		mark_color = Color(0.25, 0.19, 0.12, 0.08)
	if key == "water":
		mark_color = Color(0.82, 0.95, 1.0, 0.12)
	for index in range(0, tile_size.x, 5):
		var px := origin.x + index
		var py := origin.y + ((index * 3) % tile_size.y)
		image.set_pixel(px, py, mark_color)

func _paint_map() -> void:
	clear()
	for y in range(MAP_ROWS):
		for x in range(MAP_COLUMNS):
			var key: String = "lower_grass" if y >= 33 else "grass"
			_set_tile(Vector2i(x, y), key)

	_paint_path(Vector2i(16, 28), Vector2i(40, 22), 2)
	_paint_path(Vector2i(40, 22), Vector2i(57, 25), 2)
	_paint_path(Vector2i(40, 22), Vector2i(26, 13), 2)
	_paint_path(Vector2i(40, 22), Vector2i(49, 14), 2)
	_paint_plaza(Vector2i(40, 22), 5)
	_paint_pond(Vector2i(57, 25), Vector2i(6, 5))

func _paint_path(start: Vector2i, end: Vector2i, radius: int) -> void:
	var current := start
	var delta := Vector2i(abs(end.x - start.x), abs(end.y - start.y))
	var step := Vector2i(1 if start.x < end.x else -1, 1 if start.y < end.y else -1)
	var error := delta.x - delta.y
	while true:
		_paint_square(current, radius, "path")
		if current == end:
			break
		var double_error := error * 2
		if double_error > -delta.y:
			error -= delta.y
			current.x += step.x
		if double_error < delta.x:
			error += delta.x
			current.y += step.y

func _paint_plaza(center: Vector2i, radius: int) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var delta := Vector2i(x, y) - center
			if delta.length() <= float(radius):
				_set_tile(Vector2i(x, y), "plaza")

func _paint_pond(center: Vector2i, radius: Vector2i) -> void:
	for y in range(center.y - radius.y, center.y + radius.y + 1):
		for x in range(center.x - radius.x, center.x + radius.x + 1):
			var normalized := Vector2(float(x - center.x) / float(radius.x), float(y - center.y) / float(radius.y))
			if normalized.length() <= 1.0:
				_set_tile(Vector2i(x, y), "water")

func _paint_square(center: Vector2i, radius: int, key: String) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			_set_tile(Vector2i(x, y), key)

func _set_tile(coords: Vector2i, key: String) -> void:
	if coords.x < 0 or coords.y < 0 or coords.x >= MAP_COLUMNS or coords.y >= MAP_ROWS:
		return
	set_cell(coords, SOURCE_ID, TILE_ATLAS[key])
