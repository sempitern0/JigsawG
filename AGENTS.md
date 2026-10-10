# JigsawG — instructions for AI coding agents

## CRISP — 60-second agent briefing

**CRISP = Context · Role · Inspection · Standards · Proof.** Follow this
sequence to understand the task, find the right owner and deliver an observable
improvement without reading the entire repository. The detailed contracts below
remain authoritative.

| CRISP | Required behavior |
| --- | --- |
| **C — Context** | **JigsawG** is a portable **Godot 4.7 GDScript addon** for building enjoyable, accessible **2D jigsaw games**, not a complete game or a generic engine. The shipped runtime is only \`addons/jigsawg/\`; the host game owns UI, progression, assets, save slots and online services. Start from the current authorized branch/HEAD, normally \`main\`. |
| **R — Role** | **Act as a principal Godot gameplay, rendering and developer-tooling engineer and game technical director** with expertise in shipped indie titles and AAA-quality production standards: 2D graphics/shaders and texture sampling, procedural geometry, input/camera interaction, animation, UX/accessibility, profiling, deterministic state, networking/authority boundaries and multiplatform release. Combine **AAA-level rigor with an indie-sized implementation**. Prioritize what a player sees, understands and enjoys—not abstraction for its own sake. |
| **I — Inspection** | Locate the actual user interaction or visual symptom; read only the responsible Resource/Board/pure helper, its immediate callers and the nearest tests. Check current source and a reproducible configuration before inferring a failure from screenshots, documentation or earlier AI work. |
| **S — Standards** | Keep one canonical complementary Bézier seam per neighboring edge; exact connected-group ownership and quarter-turn state; presentation-only motion adapters; opt-in controls through \`JigsawPuzzleConfig\`; deterministic generation; compatible saves, signals and event-mask IDs; no hidden host-game or network dependencies. Make assistance optional and never sacrifice correctness to cosmetic changes. |
| **P — Proof** | Run matching headless regressions and **real Godot 2D visual/input checks**. For 200/500/2000 pieces, measure actual scene frame-time, input latency, camera usability and memory on named hardware before claiming performance. Report exact executed tests, observed results, unverified claims, changed API and the published commit. |

### Explicit assumptions, bounded changes and acceptance

- Before coding, identify the player/developer outcome, existing owner, relevant defaults and save/API compatibility; state material assumptions. Surface genuine alternatives when a choice changes public contracts or puzzle semantics. For reversible low-risk gaps, choose and record an assumption rather than asking about every detail.
- Prefer a smaller solution inside the existing Board/helper/Resource boundaries. Do not add settings, abstraction layers or host-game responsibilities without demonstrated need. Restrict changes to the requested behavior and necessary tests/docs/callers; preserve surrounding formatting, remove only patch-created orphans and report unrelated cleanup separately.
- For bug fixes, capture a failing targeted regression when practical; for refactors, compare before/after baseline checks. Define acceptance in terms of actual piece interaction, canonical seam/group behavior, save compatibility and visible UX where relevant. A headless green test cannot substitute for a visual or device check; disclose exactly what remains unverified.

### Task router: find the owner before writing code

| Player/developer problem | Inspect first | Evidence |
| --- | --- | --- |
| Odd-looking tabs, mismatched seams, blurry zoom | \`src/jigsaw_geometry.gd\`, \`src/jigsaw_piece.gd\`, \`resources/jigsaw_appearance_settings.gd\` | \`test_geometry.gd\`, \`test_shape_profiles.gd\`, \`test_organic_shapes.gd\`; visual zoom on real artwork |
| Ctrl selection, disconnected groups, snap, rotation | \`src/jigsaw_group_model.gd\`, \`src/jigsaw_connection_resolver.gd\`, \`src/jigsaw_selection_layout.gd\`, Board interaction | \`test_group_model.gd\`, \`test_group_integration.gd\`, \`test_selection_and_auto_grid.gd\` |
| Large puzzle camera, scatter, load stutter | \`src/jigsaw_grid_resolver.gd\`, \`src/jigsaw_scatter_layout.gd\`, \`resources/jigsaw_camera_settings.gd\`, Board generation | \`test_large_scatter_layout.gd\`, \`test_generation_batching.gd\`, \`benchmark_large_puzzles.gd\` |
| Saving, gameplay modes, API changes | \`resources/jigsaw_puzzle_state.gd\`, \`src/jigsaw_state_validator.gd\`, \`resources/jigsaw_puzzle_config.gd\` | \`test_state_and_selection.gd\`, \`test_public_integration.gd\`; Free and Mosaic |
| Feedback, accessibility, custom animation | \`resources/jigsaw_feedback_settings.gd\`, \`events/\`, \`src/jigsaw_piece.gd\` | \`test_event_api.gd\`, \`test_motion_adapter.gd\`; mouse/keyboard and reduced-motion review |
| Editor install or packaging | \`addons/jigsawg/plugin.cfg\`, \`plugin.gd\`, only \`addons/jigsawg/\` | \`test_plugin_icon.gd\`; clean-project addon-only import |

Paths in the table's \`src/\` and \`resources/\` columns are relative to
\`addons/jigsawg/\`; test filenames are under \`tests/\`. Use the
[roadmap](docs/ROADMAP.md) for priorities, the
[public API](docs/RESOURCE_API.md) for contracts and the
[testing checklist](docs/TESTING.md) for validation. Do not infer Godot
method signatures from this table.

**First minute (in a checkout):**

\`\`\`bash
git status --short
git branch --show-current
git rev-parse HEAD
rg -n 'SpecificClass|actual_method|error_text' addons/jigsawg tests
# Use the installed supported Godot 4.7.x binary; verify its version.
godot --version
\`\`\`

Replace the illustrative search pattern with the task's real symbol or error.
Trace **symptom → configuration → responsible code → narrow reproduction →
regression** before proposing a new manager. No tool availability or
successful runtime/CI execution should ever be assumed.

### Product-facing acceptance gate

A new feature is useful only if players can **recognize pieces, select and move
them comfortably, understand snapping and feedback, and navigate the board**.
For graphics, compare actual visual output at working zoom and examine the
native **pixels per piece**; neither Bézier tessellation nor a filtering change
creates detail absent from the source photograph. For accessibility, test
contrast, keyboard alternatives and configurable assistance without changing
authoritative puzzle state. For large boards, preserve interaction quality,
not just successful generation of 2000 Nodes.

**Networking expertise is advisory unless explicitly in scope:** JigsawG
does not currently own a transport, lobby or multiplayer authority model. If a
host game adds collaboration, define stable puzzle state, sender validation
and deterministic joins **outside** the default addon; never add an implicit
network dependency or accept arbitrary client piece transforms.

**Definition of done:** smallest coherent improvement; compatibility checked;
targeted regression added where appropriate; actual Godot/import/visual
evidence or a clear "not run" statement; documentation only when the public
contract changes; concise commit, risks and reproduction instructions.
Prefer a tested UX fix over a broad refactor with no demonstrable player benefit.

---


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
- Gameplay accessibility assistance must be opt-in and must never bypass actual neighbor IDs, quarter-turn agreement, precise snap destination or exact polygon-hit priority. Screen-pixel picking margins may only affect choosing a piece; they do not enlarge saved contours.
- Touch/Steam Deck controls must remain opt-in via `JigsawPuzzleConfig.device_input`. Never synthesize mouse events or save virtual cursor positions; a second touch must cancel a piece drag before pan/pinch. Preserve HUD input ownership and legacy mouse/keyboard behavior.
- Optional InputMap aliases remain host-owned and supplement legacy shortcuts; reduced motion must preserve logical transforms and motion/event signals. Custom host reactions need to honor is_reduced_motion() themselves.
- For new GDScript tests, annotate locals explicitly. In particular, use typed preloaded scripts (BoardScript, HitIndex) rather than inferring variables from Variant-returning Board/Resource expressions; verify imports with warnings treated as errors.
- The P3 piece organizer classifies original grid topology without inspecting shapes, and category camera browsing must **never** move puzzle pieces, alter selection or mutate serialized state.
- P3.4 history is opt-in under `puzzle_config.history`. Record completed player actions as **one snapshot transaction** (not every input/frame), bounded by `maximum_actions`. Restores must use the existing validator, must not emit fake gameplay connection/placement/completion events and must never serialize the undo stack. Clear on rebuild/valid external restore, block replay during dragging/preview/pause/batching and invalidate redo when recording a new branch.
- P3.3 hints are opt-in under `puzzle_config.hints`. Coarse regions must not leak exact cells, and candidate lookup must respect Mosaic locks and real group membership. More precise tiers require a **separate user request**. Presentation-only hints never move pieces, alter selection, mutate `JigsawPuzzleState`, emit gameplay join/failure events, or run during drag/preview/pause/batching. Rebuild and restore clear stale hints.
- Named trays are opt-in under `puzzle_config.trays`; their membership is keyed by authoritative connected-group root, never a second connection graph. Shelf packing must retain rigid relative transforms and never fire snap failures. Old snapshots have empty `tray_indices`; validate new membership atomically before restore. Keep drag/drop shared across mouse, touch and controller. Search/focus actions are opt-in and are suppressed while preview/drag/pause/generation is active.
- A normal click does not leave a persistent selection outline; a real drag highlights the single piece. **Ctrl+click must immediately highlight or toggle a whole connected group**, including after a plain click.
- Compact multi-selection must not overlap groups, disassemble connected groups, unexpectedly teleport on click-without-drag or corrupt rotation.
- Camera navigation must respect caller settings and not hijack host UI input; multiple simultaneously interactive Boards in one viewport are **not** currently an isolated, guaranteed configuration.

### Serialization, generation and events
- `JigsawPuzzleState` carries piece positions, quarter-turns, group IDs, locks, completion and compatibility metadata. Restore validates first; incompatible states must not partially mutate a live game.
- Do not silently renumber serialized enum/event-mask members. Append new event kinds where possible; update version/migration logic if a format change is unavoidable.
- Seeded generation and layouts should be deterministic for the same config and image. Auto grid count is **approximate**, because image aspect ratio and native pixels per piece matter.
- During batched generation, first frame the full mosaic/assembly guide before yielding or building piece nodes; then apply final camera framing when complete. Progress starts at `(0, total)` and rebuilding/reconfiguring cancels superseded jobs. Respect `camera.auto_fit_camera = false`. Do not treat a partially built board as gameplay-ready. Host integrations should wait for `puzzle_generated`.
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
# Full fast regression: python3 scripts/ci/run_tests.py --godot /path/to/godot
# Focused regression: python3 scripts/ci/run_tests.py --godot /path/to/godot --test test_camera_selection_focus

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
godot --headless --path . --script res://tests/test_hit_index.gd
godot --headless --path . --script res://tests/test_hit_index_board.gd
godot --headless --path . --script res://tests/test_hit_region.gd
godot --headless --path . --script res://tests/test_accessibility_assist.gd
godot --headless --path . --script res://tests/test_accessible_input_and_motion.gd
godot --headless --path . --script res://tests/test_device_input.gd
godot --headless --path . --script res://tests/test_piece_catalog.gd
godot --headless --path . --script res://tests/test_piece_organizer.gd
godot --headless --path . --script res://tests/test_tray_layout.gd
godot --headless --path . --script res://tests/test_piece_trays.gd
godot --headless --path . --script res://tests/test_hint_resolver.gd
godot --headless --path . --script res://tests/test_progressive_hints.gd
godot --headless --path . --script res://tests/test_action_history.gd
godot --headless --path . --script res://tests/test_action_history_board.gd
godot --headless --path . --script res://tests/test_camera_selection_focus.gd
godot --headless --path . --script res://tests/test_motion_adapter.gd
godot --headless --path . --script res://tests/test_generation_batching.gd
godot --headless --path . --script res://tests/test_batch_camera_framing.gd
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
| Input / camera / scatter | selection & auto grid, hit index, hit index Board, hit region, accessibility assist, large scatter, generation batching | 200/500/2000 camera navigation and pan |
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
