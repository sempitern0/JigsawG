@tool
class_name JigsawAudioReaction
extends JigsawReaction
## No-code one-shot audio reaction for selected puzzle events.

@export_group("Audio")
## Sound played when this reaction accepts an event.
@export var stream: AudioStream
## Use AudioStreamPlayer2D at event.world_position; otherwise play globally.
@export var spatial := true
## Audio bus name in the host project.
@export var bus: StringName = &"Master"
## Playback volume.
@export_range(-60.0, 12.0, 0.5) var volume_db := 0.0
## Minimum random pitch for subtle variation.
@export_range(0.25, 4.0, 0.01) var pitch_min := 1.0
## Maximum random pitch for subtle variation.
@export_range(0.25, 4.0, 0.01) var pitch_max := 1.0

func react(board: Node2D, event: JigsawPuzzleEvent) -> void:
	if stream == null or not is_instance_valid(board):
		return
	var parent: Node = board.get_tree().current_scene
	if parent == null:
		parent = board
	var low := minf(pitch_min, pitch_max)
	var high := maxf(pitch_min, pitch_max)
	var pitch := randf_range(low, high)

	if spatial:
		var player_2d := AudioStreamPlayer2D.new()
		parent.add_child(player_2d)
		player_2d.global_position = event.world_position
		player_2d.stream = stream
		player_2d.bus = bus
		player_2d.volume_db = volume_db
		player_2d.pitch_scale = pitch
		player_2d.finished.connect(player_2d.queue_free)
		player_2d.play()
	else:
		var player_global := AudioStreamPlayer.new()
		parent.add_child(player_global)
		player_global.stream = stream
		player_global.bus = bus
		player_global.volume_db = volume_db
		player_global.pitch_scale = pitch
		player_global.finished.connect(player_global.queue_free)
		player_global.play()
