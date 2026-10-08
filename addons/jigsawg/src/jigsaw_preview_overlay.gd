extends CanvasLayer
## Camera-independent, non-interactive full-image reference (P by default).

var _root: Control
var _backdrop: ColorRect
var _image: TextureRect
var _hint: Label

func _ready() -> void:
	layer = 50
	_root = Control.new()
	_root.name = "PreviewFullscreen"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_backdrop = ColorRect.new()
	_backdrop.name = "DimBackground"
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.82)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_backdrop)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_image = TextureRect.new()
	_image.name = "FullPuzzleImage"
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_image)
	_image.anchor_left = 0.06
	_image.anchor_top = 0.06
	_image.anchor_right = 0.94
	_image.anchor_bottom = 0.90

	_hint = Label.new()
	_hint.name = "CloseHint"
	_hint.text = "P · Close preview"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hint)
	_hint.anchor_left = 0.0
	_hint.anchor_right = 1.0
	_hint.anchor_top = 0.93
	_hint.anchor_bottom = 0.98

	_root.visible = false

func configure(texture: Texture2D, backdrop_opacity: float, hint_text: String) -> void:
	if not is_node_ready():
		await ready
	_image.texture = texture
	_backdrop.color.a = clampf(backdrop_opacity, 0.0, 1.0)
	_hint.text = hint_text

func set_preview_visible(enabled: bool) -> void:
	if not is_node_ready():
		await ready
	_root.visible = enabled

func is_preview_visible() -> bool:
	return is_instance_valid(_root) and _root.visible
