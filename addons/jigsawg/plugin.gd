@tool
extends EditorPlugin

## Keep the SVG as portable source art. Godot can import SVG as a Texture2D,
## but preload("*.svg") may fail while editor imports are not yet available.
## Rasterize it explicitly here so plugin.gd always parses at startup.
const ICON_PATH := "res://addons/jigsawg/icon.svg"
const BoardScript = preload("res://addons/jigsawg/src/jigsaw_board.gd")

var _board_icon: Texture2D

func _enter_tree() -> void:
	_board_icon = _load_board_icon()
	add_custom_type("JigsawBoard", "Node2D", BoardScript, _board_icon)

func _exit_tree() -> void:
	remove_custom_type("JigsawBoard")
	_board_icon = null

func _load_board_icon() -> Texture2D:
	var svg := FileAccess.get_file_as_string(ICON_PATH)
	if not svg.is_empty():
		var image := Image.new()
		var result := image.load_svg_from_string(svg, 1.0)
		if result == OK and not image.is_empty():
			return ImageTexture.create_from_image(image)
		push_warning("JigsawG: could not decode bundled SVG icon (error %d); using editor fallback." % result)
	else:
		push_warning("JigsawG: bundled icon.svg not found; using editor fallback.")

	return EditorInterface.get_editor_theme().get_icon("Node2D", "EditorIcons")
