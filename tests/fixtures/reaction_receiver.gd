extends Node
## Minimal host-game component for reaction routing tests.
var no_arg_calls := 0
var last_event: JigsawPuzzleEvent

func on_simple_event() -> void:
	no_arg_calls += 1

func on_puzzle_event(event: JigsawPuzzleEvent) -> void:
	last_event = event
