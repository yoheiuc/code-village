extends Node2D
class_name VillageSpriteLayer

const AssetCatalogScript = preload("res://scripts/assets/asset_catalog.gd")

var asset_catalog = AssetCatalogScript.new()
var sprites: Dictionary = {}
var growth_sprites: Dictionary = {}
var state_sprites: Dictionary = {}
var effect_sprites: Dictionary = {}
var load_errors: Array[String] = []

const FLOWER_POSITIONS := [
	Vector2(222, 452),
	Vector2(282, 472),
	Vector2(368, 438),
	Vector2(474, 454),
	Vector2(542, 388),
	Vector2(606, 476),
	Vector2(744, 462),
	Vector2(832, 486),
	Vector2(962, 464),
	Vector2(1038, 486),
	Vector2(1118, 438),
	Vector2(1166, 468),
]

const LANTERN_POSITIONS := [
	Vector2(548, 314),
	Vector2(724, 308),
	Vector2(342, 408),
	Vector2(818, 382),
	Vector2(478, 248),
	Vector2(690, 454),
]

func setup(catalog) -> void:
	asset_catalog = catalog
	rebuild()

func rebuild() -> void:
	for child in get_children():
		child.queue_free()
	sprites.clear()
	growth_sprites.clear()
	state_sprites.clear()
	effect_sprites.clear()
	load_errors.clear()

	for item in asset_catalog.sprite_layout():
		if typeof(item) == TYPE_DICTIONARY:
			_add_sprite(Dictionary(item))

func sprite_count() -> int:
	return sprites.size()

func has_sprite(sprite_name: String) -> bool:
	return sprites.has(sprite_name)

func growth_sprite_count(kind: String = "") -> int:
	if kind == "":
		return growth_sprites.size()
	var count := 0
	for key in growth_sprites.keys():
		if String(key).begins_with(kind + "_"):
			count += 1
	return count

func state_sprite_count(kind: String = "") -> int:
	if kind == "":
		return state_sprites.size()
	var count := 0
	for key in state_sprites.keys():
		if String(key).begins_with(kind + "_"):
			count += 1
	return count

func effect_sprite_count() -> int:
	return effect_sprites.size()

func apply_village_state(state) -> void:
	_clear_growth_sprites()
	_clear_state_sprites()
	_add_growth_sprites(
		"flower",
		"flower_bloomed",
		FLOWER_POSITIONS,
		mini(int(state.flowers), 36),
		1.0,
		28,
	)
	_add_growth_sprites(
		"lantern",
		"lantern_lit",
		LANTERN_POSITIONS,
		mini(int(state.lanterns), LANTERN_POSITIONS.size()),
		0.5,
		29,
	)
	_add_state_visual_sprites(state)

func show_growth_events(growth_events: Array) -> void:
	_clear_effect_sprites()
	var count := mini(growth_events.size(), 3)
	for index in range(count):
		var growth_event = growth_events[index]
		if growth_event != null:
			_add_growth_event_effect(growth_event, index)

func _add_sprite(item: Dictionary) -> void:
	var section := String(item.get("section", ""))
	var key := String(item.get("key", ""))
	var sprite_name := String(item.get("name", key))
	var path: String = asset_catalog.asset_path(section, key)
	if path == "":
		load_errors.append("missing asset path for %s/%s" % [section, key])
		return
	if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
		load_errors.append("resource path does not exist: %s" % path)
		return

	var texture: Texture2D = _load_texture(path)
	if texture == null:
		load_errors.append("resource could not load: %s" % path)
		return

	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.position = _array_to_vector2(Array(item.get("position", [0, 0])), Vector2.ZERO)
	sprite.scale = _scale_to_vector2(item.get("scale", 1.0))
	sprite.z_index = int(item.get("z_index", 0))
	add_child(sprite)
	sprites[sprite_name] = sprite

func _add_growth_sprites(
		kind: String,
		growth_type: String,
		positions: Array,
		count: int,
		scale_value: float,
		z_index_value: int
	) -> void:
	var path: String = asset_catalog.growth_visual_path(growth_type)
	if path == "":
		load_errors.append("missing growth visual path for %s" % growth_type)
		return
	var texture: Texture2D = _load_texture(path)
	if texture == null:
		load_errors.append("growth visual could not load: %s" % path)
		return
	for index in range(count):
		var sprite := Sprite2D.new()
		var sprite_name: String = "%s_%02d" % [kind, index]
		sprite.name = sprite_name
		sprite.texture = texture
		sprite.centered = true
		sprite.position = positions[index % positions.size()] + Vector2((index / positions.size()) * 12, 0)
		sprite.scale = Vector2(scale_value, scale_value)
		sprite.z_index = z_index_value
		add_child(sprite)
		growth_sprites[sprite_name] = sprite

func _add_state_visual_sprites(state) -> void:
	for item in asset_catalog.state_visual_rules():
		if typeof(item) == TYPE_DICTIONARY:
			var rule := Dictionary(item)
			if _state_rule_matches(rule, state):
				_add_state_visual_sprite(rule)

func _add_state_visual_sprite(rule: Dictionary) -> void:
	var visual_name := String(rule.get("name", "state_visual"))
	var path := String(rule.get("path", ""))
	if path == "" and rule.has("growth_type"):
		path = asset_catalog.growth_visual_path(String(rule.get("growth_type", "")))
	if path == "" and rule.has("section") and rule.has("key"):
		path = asset_catalog.asset_path(String(rule.get("section", "")), String(rule.get("key", "")))
	if path == "":
		load_errors.append("missing state visual path for %s" % visual_name)
		return

	var texture: Texture2D = _load_texture(path)
	if texture == null:
		load_errors.append("state visual could not load: %s" % path)
		return

	var sprite := Sprite2D.new()
	sprite.name = visual_name
	sprite.texture = texture
	sprite.centered = true
	sprite.position = _array_to_vector2(Array(rule.get("position", [0, 0])), Vector2.ZERO)
	sprite.scale = _scale_to_vector2(rule.get("scale", 1.0))
	sprite.z_index = int(rule.get("z_index", 31))
	sprite.modulate = Color(1.0, 1.0, 1.0, float(rule.get("opacity", 1.0)))
	add_child(sprite)
	state_sprites[visual_name] = sprite

func _clear_growth_sprites() -> void:
	for sprite in growth_sprites.values():
		if is_instance_valid(sprite):
			sprite.queue_free()
	growth_sprites.clear()

func _clear_state_sprites() -> void:
	for sprite in state_sprites.values():
		if is_instance_valid(sprite):
			sprite.queue_free()
	state_sprites.clear()

func _clear_effect_sprites() -> void:
	for sprite in effect_sprites.values():
		if is_instance_valid(sprite):
			sprite.queue_free()
	effect_sprites.clear()

func _add_growth_event_effect(growth_event, index: int) -> void:
	var growth_type := String(growth_event.type)
	var visual_target := String(growth_event.visual_target)
	var anchor: Dictionary = asset_catalog.growth_effect_anchor(visual_target)
	if anchor.is_empty():
		anchor = asset_catalog.growth_effect_anchor(growth_type)
	var default_anchor: Dictionary = asset_catalog.growth_effect_anchor("default")
	var path := String(anchor.get("path", ""))
	if path == "":
		path = String(default_anchor.get("path", ""))
	if path == "":
		path = asset_catalog.growth_visual_path(growth_type)
	if path == "":
		return

	var texture: Texture2D = _load_texture(path)
	if texture == null:
		load_errors.append("growth effect could not load: %s" % path)
		return

	var base_position := _array_to_vector2(Array(anchor.get("position", [640, 360])), Vector2(640, 360))
	var offset := Vector2(index * 24, -index * 10)

	var sprite := Sprite2D.new()
	var sprite_name := "growth_effect_%02d" % index
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.position = base_position + offset
	sprite.scale = _scale_to_vector2(anchor.get("scale", 0.45))
	sprite.z_index = int(anchor.get("z_index", 42))
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.95)
	add_child(sprite)
	effect_sprites[sprite_name] = sprite

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "position", sprite.position + Vector2(0, -18), 2.0)
	tween.tween_property(sprite, "modulate:a", 0.0, 2.0).set_delay(0.35)
	tween.finished.connect(_finish_growth_effect.bind(sprite_name))

func _finish_growth_effect(sprite_name: String) -> void:
	var sprite = effect_sprites.get(sprite_name)
	effect_sprites.erase(sprite_name)
	if is_instance_valid(sprite):
		sprite.queue_free()

func _state_rule_matches(rule: Dictionary, state) -> bool:
	var state_key := String(rule.get("state_key", ""))
	if state_key == "" or state == null:
		return false
	var value = _state_value(state, state_key)
	if rule.has("equals"):
		return String(value) == String(rule.get("equals"))
	if rule.has("min_value"):
		return float(value) >= float(rule.get("min_value", 0))
	return bool(value)

func _state_value(state, key: String):
	if typeof(state) == TYPE_DICTIONARY:
		return Dictionary(state).get(key)
	if state is Object:
		return state.get(key)
	return null

func _array_to_vector2(values: Array, fallback: Vector2) -> Vector2:
	if values.size() < 2:
		return fallback
	return Vector2(float(values[0]), float(values[1]))

func _scale_to_vector2(value) -> Vector2:
	if typeof(value) == TYPE_ARRAY:
		return _array_to_vector2(Array(value), Vector2.ONE)
	var uniform := float(value)
	return Vector2(uniform, uniform)

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var resource := ResourceLoader.load(path)
		if resource is Texture2D:
			return resource

	if path.get_extension().to_lower() == "svg":
		var raw_svg := FileAccess.get_file_as_string(path)
		if raw_svg == "":
			return null
		var image := Image.new()
		var error := image.load_svg_from_buffer(raw_svg.to_utf8_buffer())
		if error != OK:
			load_errors.append("svg could not decode: %s" % path)
			return null
		return ImageTexture.create_from_image(image)

	return null
