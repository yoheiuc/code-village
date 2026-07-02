extends RefCounted
class_name AssetTextureLoader

# import 済みリソースが無い場合（gitignore された外部素材の headless 実行など）でも
# 画像本体から直接テクスチャを生成できる共有ローダー。

static func load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var resource := ResourceLoader.load(path)
		if resource is Texture2D:
			return resource

	if not FileAccess.file_exists(path):
		return null

	var extension := path.get_extension().to_lower()
	if extension == "svg":
		return _load_svg(path)
	if extension in ["png", "webp", "jpg", "jpeg"]:
		return _load_raster(path, extension)
	return null

static func _load_svg(path: String) -> Texture2D:
	var raw_svg := FileAccess.get_file_as_string(path)
	if raw_svg == "":
		return null
	var image := Image.new()
	if image.load_svg_from_buffer(raw_svg.to_utf8_buffer()) != OK:
		return null
	return ImageTexture.create_from_image(image)

static func _load_raster(path: String, extension: String) -> Texture2D:
	var buffer := FileAccess.get_file_as_bytes(path)
	if buffer.is_empty():
		return null
	var image := Image.new()
	var error := ERR_UNAVAILABLE
	if extension == "png":
		error = image.load_png_from_buffer(buffer)
	elif extension == "webp":
		error = image.load_webp_from_buffer(buffer)
	else:
		error = image.load_jpg_from_buffer(buffer)
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)
