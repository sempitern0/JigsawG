@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("JigsawBoard", "Node2D", preload("src/jigsaw_board.gd"), preload("res://icon.svg"))

func _exit_tree() -> void:
	remove_custom_type("JigsawBoard")
