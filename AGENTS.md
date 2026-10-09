# JigsawG — instructions for AI coding agents

> Applies to the repository root and all subdirectories. Read this file **before** editing code, Resources, tests or documentation. Follow the active user task and repository instructions first; this is a project working guide, not a license to make unrelated changes.

## Mission and non-negotiable constraints

JigsawG is a **self-contained Godot 4.7 GDScript addon** for procedural 2D jigsaw puzzles. It owns geometry, puzzle group/placement mechanics, selection, camera navigation, state and semantic events. A game using it owns HUD, sound design, achievements, artwork, narrative and save-slot policy.

- The distributable plugin is **`addons/jigsawg/` only**. It must import in a fresh Godot project without needing root `project.godot`, `examples/`, `tests/` or `docs/` assets.
- `JigsawBoard` has **one public Inspector configuration property**, `puzzle_config: JigsawPuzzleConfig`. Add new configurable behaviors under the appropriate Resource, not as duplicated Board exports.
- Preserve **Free** connected-group assembly and **Mosaic** per-piece placement.
- Preserve existing public signals, Resource fields, enum values, saved state compatibility and caller-visible behavior unless a breaking change is explicitly requested and migration/versioning is provided.
- Never alter or repurpose user-supplied images, copy artwork/masks from third-party reference projects, or claim unclear demo asset licenses are verified.
- Never describe tests, benchmark numbers, import checks or in-editor visuals as verified if you did not actually execute/observe them.

## Read these first

| Goal | Primary source |
| --- | --- |
| What users install / quick start | [README.md](README.md) |
| Current development priorities | [docs/ROADMAP.md](docs/ROADMAP.md) |
| Public Resource and Board API | [docs/RESOURCE_API.md](docs/RESOURCE_API.md) |
| Event contract, motion and reusable reactions | [docs/EVENTS_AND_REACTIONS.md](docs/EVENTS_AND_REACTIONS.md) |
| Regression and release matrix | [docs/TESTING.md](docs/TESTING.md) |
| Contribution and version history | [CONTRIBUTING.md](CONTRIBUTING.md), [CHANGELOG.md](CHANGELOG.md) |

Before proposing new machinery, check whether the behavior is already available as a Resource field, public Board method, `JigsawReaction` or `JigsawMotionAdapter`.

## Repository map

```text
addons/jigsawg/
  plugin.cfg, plugin.gd, icon.svg         # Editor registration; independent of root project
  resources/
    jigsaw_puzzle_config.gd               # Only public Board Inspector entry
    jigsaw_gameplay_settings.gd           # Modes, shuffle, rotation, generation batches
    jigsaw_appearance_settings.gd         # Profile families, tint, filtering
    jigsaw_camera_settings.gd             # Navigation, framing and shortcuts
    jigsaw_feedback_settings.gd           # Presentation and motion adapter
    jigsaw_puzzle_state.gd                # Serialized runtime snapshot
  src/
    jigsaw_board.gd                       # Scene controller / coordination
    jigsaw_piece.gd                       # Draw-only presentation and hit shapes
    jigsaw_geometry.gd                    # Canonical complementary Bézier seams
    jigsaw_group_model.gd                 # Node-free membership and merge model
    jigsaw_connection_resolver.gd         # Pure snap and adjacency calculations
    jigsaw_grid_resolver.gd               # Approximate count -> balanced grid
    jigsaw_scatter_layout.gd              # Seeded structured/chaotic layouts
    jigsaw_selection_layout.gd            # Compact multiple-group arrangement
    jigsaw_state_validator.gd             # Reject incompatible snapshots
    jigsaw_preview_overlay.gd             # Reference-image overlay
  events/
    jigsaw_puzzle_event.gd                # Typed semantic event and reason values
    jigsaw_reaction.gd                    # Resource-driven event subscription
    jigsaw_motion_adapter.gd              # Presentation-only transform interpolation
    jigsaw_motion_context.gd              # Snapshot for motion callbacks
    jigsaw_*_reaction.gd                  # Audio, spawn, animation, method effects

examples/                                  # Development/demo only
tests/                                     # Regression scripts and heavy benchmark
docs/                                      # User API, events, testing, roadmap
```

`JigsawBoard` is currently a large orchestrator. Prefer extracting **pure, independently testable helpers** over growing it indefinitely, while keeping the public façade intact. Avoid speculative refactors unrelated to the task.

## Invariants: do not break these

### Geometry and textures
- A seam is generated **once** as a shared canonical contour; the neighboring edge uses the exactly complementary/reversed contour. Never seed adjacent pieces independently or approximate one side with a new, unrelated curve.
- Organic variation is deterministic per shared seam token. Preserve older numeric `ConnectorFamily` values and the established appearance of Classic presets.
- `jigsaw_piece.gd` samples the shared source image via UVs. More Bézier samples improve shape smoothness **not** source-image detail; never claim pixel upscaling restores missing photograph detail.
- Do not add per-piece full-image bitmap copies, new required shaders or material dependencies without measured justification.

### Groups, motion and input
- `JigsawGroupModel` is the authoritative source of connected group roots/members. A union retains the **dragged/anchor group's root**. Do not mirror independent mutable parent/member arrays in the Board.
- Connected pieces remain rigid during dragging, packing and quarter-turn rotations. Position/rotation used for snap and save are exact, not tweened.
- Motion adapters operate on **presentation** (e.g. `JigsawPiece.display_transform`), not the Board's authoritative piece transforms.
- A normal click does not leave a persistent selection outline; a real drag highlights the single piece. **Ctrl+click must immediately highlight or toggle a whole connected group**, including after a plain click.
- Compact multi-selection must not overlap groups, disassemble connected groups, unexpectedly teleport on click-without-drag or corrupt rotation.
- Camera navigation must respect caller settings and not hijack host UI input; multiple simultaneously interactive Boards in one viewport are **not** currently an isolated, guaranteed configuration.

### Serialization, generation and events
- `JigsawPuzzleState` carries piece positions, quarter-turns, group IDs, locks, completion and compatibility metadata. Restore validates first; incompatible states must not partially mutate a live game.
- Do not silently renumber serialized enum/event-mask members. Append new event kinds where possible; update version/migration logic if a format change is unavoidable.
- Seeded generation and layouts should be deterministic for the same config and image. Auto grid count is **approximate**, because image aspect ratio and native pixels per piece matter.
- During batched generation, report progress accurately; rebuilding/reconfiguring cancels superseded jobs. Do not treat a partially built board as gameplay-ready. Host integrations should wait for `puzzle_generated`.
- Emit existing compact signals **and** rich typed `JigsawPuzzleEvent` equivalents as expected; reactions are reusable stateless Resources, not places to store per-session scores.
- The puzzle requires a sufficiently resolved source image (minimum ~14 original pixels per piece axis to generate; recommendation is higher). Do not bypass the limit to falsely claim blurry images become crisp.

## Efficient agent workflow

1. **Establish the working state.** Read current `main` HEAD / `git status` (or current branch), task constraints and nearest relevant tests. Inspect only relevant files and call sites first. Do not work from an earlier remembered commit.
2. **State the problem and expected behavior.** Distinguish a genuine bug, an unverified user-visible impression, an optimization and an architectural idea. Capture a minimal reproduction where possible.
3. **Make a narrow plan.** Record affected APIs, backward compatibility, likely edge cases, performance implications and which tests will demonstrate success.
4. **Implement the smallest coherent slice.** Prefer preserving existing exports and defaults. New settings belong to the relevant Resource. No unrelated formatting, file mass-renames or large speculative abstractions.
5. **Validate in increasing scope.** Import/parse in Godot; run focused tests; run the fast suite; then run manual graphics/input checks and the heavy benchmark if relevant. Report exactly which steps you ran.
6. **Review the diff.** Check addon-only file paths and resource UIDs, signal names, default settings, save behavior, RNG determinism, docs, license provenance and performance side effects.
7. **Publish carefully.** The current maintainer workflow uses **direct, small commits to `main` when explicitly authorized**; otherwise honor the user's branch/PR instructions. Check current HEAD before every push/update; do not force-push, rewrite history or discard other work. Prefer atomic commits with a concrete testable purpose.
8. **Report results precisely.** Link commits; summarize user-facing behavior, compatibility, tests that passed, tests not run and known risks. Don't confuse static review with in-engine validation.

If the Godot binary, GUI or reference hardware is unavailable, do static review and provide exact Godot commands. Mark engine-dependent behavior as **unverified**, not PASS. Never invent frame timings, FPS or screenshots.

## Commands to validate (from repository root)

Use the available Godot 4.7.x executable (`godot` or `godot4` on your machine):

```bash
# Import assets / resolve UID references before headless test scripts
godot --headless --path . --editor --quit

# Focused fast tests (choose those relevant to the change)
godot --headless --path . --script res://tests/test_geometry.gd
godot --headless --path . --script res://tests/test_shape_profiles.gd
godot --headless --path . --script res://tests/test_organic_shapes.gd
godot --headless --path . --script res://tests/test_group_model.gd
godot --headless --path . --script res://tests/test_group_integration.gd
godot --headless --path . --script res://tests/test_state_and_selection.gd
godot --headless --path . --script res://tests/test_selection_and_auto_grid.gd
godot --headless --path . --script res://tests/test_motion_adapter.gd
godot --headless --path . --script res://tests/test_generation_batching.gd
godot --headless --path . --script res://tests/test_event_api.gd
godot --headless --path . --script res://tests/test_board_events.gd
godot --headless --path . --script res://tests/test_public_integration.gd
godot --headless --path . --script res://tests/test_plugin_icon.gd
godot --headless --path . --script res://tests/test_large_scatter_layout.gd

# Heavy end-to-end profile: explicitly separate from the fast suite
godot --headless --path . --script res://tests/benchmark_large_puzzles.gd
```

**Suggested minimal regression by change area:**

| Changed area | Always run | Also inspect |
| --- | --- | --- |
| Geometry / Organic / UV sampling | geometry, shape profiles, organic shapes, state & selection | Neighbor seams, rotation, zoomed art |
| Groups / snapping / multi-select | group model, group integration, selection & auto grid, state & selection | Connected drag and save/restore |
| Input / camera / scatter | selection & auto grid, large scatter, generation batching | 200/500/2000 camera navigation and pan |
| Generation / save | generation batching, state & selection, public integration | Cancellation, immutable Resource presets |
| Events / reactions / motion | event API, board events, motion adapter, public integration | Event ordering and visual tween correctness |
| Plugin registration / distribution | plugin icon, public integration | Clean-project install using addon alone |

These scripts are smoke/regression checks, not proof of input accessibility or graphics quality. Manually test `examples/puzzle_lab.tscn` and use `docs/TESTING.md` for release validation. Do **not** infer passing results solely from exit-free parsing or from a test file existing.

## Change completion checklist

- [ ] Task objective and behavior specified; only relevant files changed.
- [ ] Public Resource defaults, saved schema, enum IDs and signals preserved or explicitly migrated.
- [ ] No root `res://examples` or host-only asset dependency entered `addons/jigsawg/`.
- [ ] Relevant tests **actually run** (or are openly recorded as not run).
- [ ] Manual visual/camera tests and 200/500/2000 benchmarks when relevant, with device information.
- [ ] `README.md` and/or the specialized docs updated only for public-facing changes.
- [ ] `CHANGELOG.md` updated for notable shipped behavior; `docs/ROADMAP.md` updated for priority/scope changes.
- [ ] No unlicensed imagery, needless generated files, engine caches or copied font/assets committed.
- [ ] Git HEAD verified, commits published only with authorization and clear summary.

## Common traps

- Editing the wrong branch or relying on an old main HEAD.
- Optimizing code based on theoretical complexity without profiling a Godot scene.
- Changing `JigsawBoard` exports instead of extending `JigsawPuzzleConfig` subresources.
- Breaking shared seam symmetry with per-piece randomness or one-sided geometry edits.
- Treating animated drawing transforms as logical coordinates during snapping or serialization.
- Losing event-mask backward compatibility by inserting enum members in the middle.
- Using a large JPEG and promising that filtering can create missing pixels.
- Adding features only in a README without code or verified test coverage.
- Stating an issue is fixed in Godot without running Godot.

A good agent change is **small, reproducible, reversible, documented and measurable**.
