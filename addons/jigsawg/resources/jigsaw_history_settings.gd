@tool
class_name JigsawHistorySettings
extends Resource
## Opt-in, bounded per-action snapshots. Never stored in puzzle save files.

@export_group("Undo / Redo")
@export var enabled := false
## 20 actions usually cost only a few MB even for ~2000 pieces.
@export_range(1, 64, 1) var maximum_actions := 20
## When history is enabled: Ctrl+Z undo, Ctrl+Y or Ctrl+Shift+Z redo.
@export var standard_keyboard_shortcuts := true

@export_group("Optional InputMap Shortcuts")
## Host games register these actions; no default global key bindings.
@export var undo_action: StringName = &""
@export var redo_action: StringName = &""
## Optional keys; defaults disabled to avoid intercepting host shortcuts.
@export var undo_key: Key = KEY_NONE
@export var redo_key: Key = KEY_NONE
