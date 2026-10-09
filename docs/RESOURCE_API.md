# JigsawG — API basada en Resources

## Configuración del tablero

El nodo `JigsawBoard` expone **una sola propiedad** en el Inspector: `puzzle_config: JigsawPuzzleConfig`. Configura cada puzle mediante un recurso raíz .tres que agrupa la imagen, las dimensiones y cuatro recursos especializados.

| Resource | Variables |
|---|---|
| `JigsawPuzzleConfig` | `puzzle_texture`, `columns`, `rows`, `silhouette_variants`, `gameplay`, `appearance`, `camera`, `feedback` |
| `JigsawGameplaySettings` | `game_mode`, `snap_tolerance`, `allow_piece_rotation`, `random_rotation_on_shuffle`, `shuffle_mode`, `distribution_mode`, `initial_scatter`, `shuffle_spacing`, `generation_seed`, `show_ghost_board`, `ghost_opacity`, `enable_preview`, `preview_key`, `preview_dim` |
| `JigsawAppearanceSettings` | `connector_depth`, `visual_style`, `texture_sampling`, `bezier_detail`, `piece_edge_opacity`, `piece_edge_width` |
| `JigsawCameraSettings` | `enable_camera_navigation`, `invert_background_pan`, `auto_fit_camera`, `restrict_camera`, `camera_outer_margin`, `smooth_zoom`, `zoom_smoothing`, `wheel_zoom_factor`, `min_zoom`, `max_zoom`, `drag_smoothing`, `edge_scroll_zone`, `edge_scroll_speed` |
| `JigsawFeedbackSettings` | `animation_style`, `connect_animation_duration`, `connect_tint`, `pickup_tint`, `enable_failure_feedback`, `failure_tint`, `failure_animation_duration` |

Los ajustes de animación se definen **únicamente** en `JigsawFeedbackSettings`, no en Appearance. `preview_dim` pertenece a Gameplay.

Crea un recurso `JigsawPuzzleConfig` desde el editor y asígnalo directamente al nodo, o utiliza el ejemplo `examples/configs/standard_puzzle.tres`. Los subrecursos se pueden reutilizar como recursos externos entre varios puzles.

## Uso por código

```gdscript
extends Node2D

@onready var board: Node2D = $JigsawBoard

func _ready() -> void:
    var config := JigsawPuzzleConfig.new()
    config.puzzle_texture = load("res://art/puzzle.png")
    config.columns = 10
    config.rows = 8
    config.gameplay.allow_piece_rotation = true
    config.gameplay.show_ghost_board = true
    config.appearance.connector_depth = 0.23
    config.feedback.connect_animation_duration = 0.25
    config.camera.smooth_zoom = true

    board.configure(config)
    board.puzzle_completed.connect(_on_finished)

func _on_finished() -> void:
    print("Completed!")
```

Para alternar entre niveles: `board.configure(load("res://puzzles/forest.tres"))`. Para aplicar cambios en el recurso actual: `board.apply_configuration()`. Ambos regeneran las piezas y reinician la partida; no llames a esas funciones cada fotograma.

`board.get_configuration()` devuelve el recurso asignado. `board.set_preview_visible(true)` abre la referencia y `board.rotate_piece(index)` gira una pieza cuando el modo permite rotación.

## Reglas de propiedad y migración

Los Resources son la única fuente de opciones. `JigsawBoard` conserva una copia de valores **no exportados** para el runtime; no se escriben cambios sobre los Resources. Un subrecurso nulo aplica valores predeterminados para su categoría. Si el Resource raíz no se asigna, el tablero genera el puzzle de demostración con valores predeterminados.

**Cambio incompatible en escenas antiguas:** propiedades como `puzzle_texture`, `columns`, `show_ghost_board` o `animation_style` ya no se exportan en el nodo. Crea un `JigsawPuzzleConfig` y traslada sus valores antes de actualizar. No deben persistir asignaciones antiguas en `.tscn`.

Las señales públicas permiten añadir HUD, efectos, sonido y puntuación: `puzzle_generated`, `piece_picked`, `piece_released`, `pieces_connected`, `piece_placed`, `group_rotated`, `preview_toggled`, `connection_failed`, `puzzle_completed`.
