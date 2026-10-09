extends SceneTree
## Godot 4.7.2 smoke test:
## godot --headless --path . --script res://tests/test_plugin_icon.gd
##
## This tests the direct SVG rasterization used by EditorPlugin, avoiding
## importer-dependent preload("icon.svg") at plugin initialization.

const ICON_PATH := "res://addons/jigsawg/icon.svg"

func _initialize() -> void:
	assert(FileAccess.file_exists(ICON_PATH), "JigsawG: bundled SVG icon is missing.")
	var svg := FileAccess.get_file_as_string(ICON_PATH)
	assert(not svg.is_empty(), "JigsawG: icon SVG is empty.")
	var image := Image.new()
	assert(image.load_svg_from_string(svg) == OK, "JigsawG: Godot cannot decode SVG icon.")
	assert(not image.is_empty(), "JigsawG: decoded SVG image is empty.")
	assert(ImageTexture.create_from_image(image) != null, "JigsawG: failed to create icon texture.")
	print("JigsawG icon smoke test: PASS (%dx%d)" % [image.get_width(), image.get_height()])
	quit()
