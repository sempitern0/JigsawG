extends SceneTree
## Godot 4.7.2 smoke test:
## godot --headless --path . --script res://tests/test_plugin_icon.gd
##
## The plugin uses Godot's native UID/import system for the SVG Texture2D.

const ICON_UID := "uid://bawbrqv2h8r4v"

func _initialize() -> void:
	assert(ResourceLoader.exists(ICON_UID), "JigsawG: icon UID is not registered.")
	var icon := ResourceLoader.load(ICON_UID)
	assert(icon is Texture2D, "JigsawG: icon UID must resolve to Texture2D.")
	assert(icon.get_width() > 0 and icon.get_height() > 0, "JigsawG: imported icon has invalid dimensions.")
	print("JigsawG icon UID smoke test: PASS (%dx%d)" % [icon.get_width(), icon.get_height()])
	quit()
