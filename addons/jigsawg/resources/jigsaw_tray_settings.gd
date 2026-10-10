@tool
class_name JigsawTraySettings
extends Resource
## Optional world-space holding areas for connected puzzle groups.
## Existing projects keep trays disabled. Names are display labels only.

@export var enabled := false
## Up to four trays; the number/order of names determines tray indices.
@export var tray_names: PackedStringArray = PackedStringArray(["Corners", "Borders", "Other"])
## Enable releasing a dragged group over a tray to store it there.
@export var allow_drop := true
## Allow the host to draw its own tray zones using the Board's tray rect API.
@export var show_background := true
