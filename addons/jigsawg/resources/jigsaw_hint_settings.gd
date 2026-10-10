@tool
class_name JigsawHintSettings
extends Resource
## Opt-in staged assistance; affects only overlay/camera, never puzzle state.

enum MaximumLevel { REGION = 1, CANDIDATE = 2, PRECISE = 3 }

@export_group("Hints")
@export var enabled := false
## Region -> highlight loose group -> exact target cell; each step is explicit.
@export var maximum_level: MaximumLevel = MaximumLevel.CANDIDATE
## 2-5 coarse zones across each axis; no precise location at level 1.
@export_range(2, 5, 1) var region_divisions := 3
@export var show_overlay := true
## Only changes the Camera2D, without moving or selecting any pieces.
@export var focus_on_request := true

@export_group("Optional Input")
## No global InputMap actions are installed by the addon.
@export var advance_action: StringName = &""
@export var advance_key: Key = KEY_NONE
