@tool
extends EditorPlugin


func _enter_tree() -> void:
		add_custom_type("JigsawBoard", 
		"Node2D", 
		preload("uid://dg252a3yj7sqv"), 
		preload("uid://bawbrqv2h8r4v")
	)

func _exit_tree() -> void:
	remove_custom_type("JigsawBoard")
