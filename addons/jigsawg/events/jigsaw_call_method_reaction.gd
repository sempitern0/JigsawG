@tool
class_name JigsawCallMethodReaction
extends JigsawReaction
## No-code integration: invoke an existing method on a node in the host scene.
## NodePath is resolved relative to the JigsawBoard. Methods should be
## no-argument or accept exactly one JigsawPuzzleEvent when pass_event=true.

@export_group("Target")
## Relative path from JigsawBoard (example: "../HUD").
@export var target_path: NodePath
## Existing method to invoke on the target node.
@export var method_name: StringName = &""
## Supply JigsawPuzzleEvent as the only method argument when true.
@export var pass_event := false

func react(board: Node2D, event: JigsawPuzzleEvent) -> void:
	if not is_instance_valid(board) or target_path.is_empty() or method_name.is_empty():
		return
	var target := board.get_node_or_null(target_path)
	if target == null:
		push_warning("JigsawG: Method reaction target not found at %s." % target_path)
		return
	if not target.has_method(method_name):
		push_warning("JigsawG: Target %s has no method '%s'." % [target_path, method_name])
		return
	if pass_event:
		target.call(method_name, event)
	else:
		target.call(method_name)
