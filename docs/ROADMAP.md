# JigsawG — development roadmap

> **Status:** planning document, not a record of validated performance.  
> **Target:** an accessible, pleasant-to-play, reusable 2D jigsaw **runtime** for Godot 4.7.  
> **Scope:** the addon under `addons/jigsawg/`. Individual games own menus, story, scoring, art, save-slot UI and monetization.

[README](../README.md) · [Resource API](RESOURCE_API.md) · [Events & Reactions](EVENTS_AND_REACTIONS.md) · [Testing](TESTING.md) · [Agent working guide](../AGENTS.md)

## Product principles

1. **Enjoyable first:** players should understand how to select, arrange, rotate and join pieces without fighting the camera or UI.
2. **Accessible by design:** optional assistance, legible silhouettes, remappable input and useful feedback; no assistance should be mandatory.
3. **Scales honestly:** test 200, 500 and 2000 pieces with **real Godot nodes and artwork**. Never treat geometric planner benchmarks as runtime FPS measurements.
4. **A plugin, not a game:** keep the host game's HUD, save-slot architecture and audiovisual identity independent. Prefer configurable Resources, public Board signals and reactions.
5. **Compatibility matters:** preserve saved-state schema, deterministic seeds, matching shared seams, established configuration names and event-mask numeric values wherever possible.
6. **Measured changes:** optimize after recording baselines; compare like-for-like scenarios on named hardware and renderer.

## Current baseline (implemented; release validation still pending)

- Godot 4.7 GDScript addon with one public `JigsawBoard.puzzle_config` entry.
- Free group-assembly and Mosaic placement modes, 90° rotation and Ctrl multi-selection with compact arrangement.
- Classic, Rounded, Angular, Compact, Mixed and Organic complementary procedural connector families.
- Manual grid and approximate piece-count Auto grid (up to 4000 requested; dependent on source resolution).
- Board/overview camera framing, smooth navigation, seeded scatter with a spatial hash in Chaotic mode.
- Optional frame-batched puzzle generation, generation progress, cancellation and image-detail diagnostics. **The early complete-mosaic camera fit is implemented, with in-engine testing pending.**
- State capture/restore; typed gameplay events, reusable reactions and pluggable presentation-only motion adapters.
- Headless scripts and a separate heavy benchmark in `tests/`. Their **existence is not evidence that they all pass**; the Godot engine and target hardware are required to verify them.

### Top known risks

| Risk | Why it matters | How to establish the baseline |
| --- | --- | --- |
| `jigsaw_board.gd` still coordinates many systems | Regression risk and harder focused tests | Trace generation, input, camera, render and state responsibilities |
| Generation batches count nodes, not milliseconds | A single busy frame may still cause noticeable stalls | Capture frame-time distribution during 200/500/2000 builds |
| New spatial hit-testing needs actual Godot validation | Index rebuild cost and ordering must be verified on-device | Run the pure/Board regressions and benchmark 200/500/2000 indexed versus linear lookup |
| Per-piece canvas draw and dense Bézier contours | GPU/CPU costs at far zoom | Measure frame time, draw calls, memory and silhouette readability |
| Camera overview shows widely scattered pieces | Tiny pieces and difficult wayfinding | Test screen sizes, working view, overview and return-to-work workflows |
| Mouse and keyboard dominate input | Touch, motor, visual and keyboard-only access are not certified | Usability tasks with alternative inputs and high contrast |
| Example photograph provenance is unverified | Publication/redistribution risk | Replace with licensed artwork before distributable public demos |
| Plugin is in preview | Runtime regressions can exist despite static review | Clean-install + parser/import + gameplay regression matrix |

## Delivery sequence

Phases are **ordered by dependencies**, not promised calendar dates. Every phase should deliver a playable, testable vertical slice. A phase is complete only when its acceptance criteria are observed and recorded.

### P0 — Confidence and measurable baseline (first)

**Goal:** make development repeatable and know what the current plugin actually costs.

**Deliverables**
- Set up a reliable Godot **4.7.x** headless import/parse and fast regression runner (local and, if possible, CI). Pin the exact tested engine version. **Runner and workflow scaffold published; successful Godot execution and CI status remain to be verified.**
- Review existing tests for false assumptions, brittle assertions, render-dependent behavior and incomplete event/state coverage; fix failures before feature expansion.
- Add a reproducible performance harness for **200, 500 and 2000** pieces, both Free and Mosaic where applicable, using known image dimensions, seeds, viewport and renderer.
- Collect *first-generation time*, peak and steady memory, frame-time p50/p95/p99, input-to-motion latency, visible/drawn piece counts and pan/zoom responsiveness. Record GPU/CPU, OS, resolution and texture source.
- Separate automated checks from manual checks; document failures and environment limitations without labeling them PASS.

**Acceptance**
- A new contributor can run the documented fast tests with one short command.
- Clean-project install of `addons/jigsawg/`, demo startup, save/restore and multi-selection have recorded PASS/FAIL results.
- Benchmark outputs can be reproduced with the same seeds and hardware profile, and expose regressions without guessing acceptable FPS.

### P1 — Comfortable 2000-piece manipulation (after P0)

**Goal:** smooth interaction and useful orientation when pieces outnumber the screen's readable area.

**Candidates, selected by profiling**
- Spatial index for piece hit-testing (**implemented**, with lazy invalidation; engine execution and real performance measurements remain pending). Keep draw order, selected-group priority and animated hit shapes correct.
- Adaptive rendering detail / visibility strategy for out-of-view or far-zoom pieces; verify complementary geometry remains the single source of truth.
- Time-budgeted or adaptive generation batches, with safe cancellation and monotonic progress signals.
- Improve shuffle footprint and grouping distribution for large/portrait images; keep deterministic behavior and avoid overlaps.
- Working-area and overview navigation: clear camera framing, easy return to the current selected group (**F / `focus_selection()` implemented, in-engine check pending**) and host-configurable camera keys.
- Preserve image clarity: texture resolution guidance, reasonable filtering defaults and honest warnings when source pixels cannot support deep zoom.

**Acceptance**
- Complete side-by-side runs at 200/500/2000 on a *defined reference device*, showing before/after frame-time, generation time and memory.
- No input/selection regressions: small click vs drag, Ctrl highlight, disconnected group arrangement, connection matching and quarter-turn rotations.
- No visible holes, unexpected geometry changes, missing pieces or jumps while switching zoom or dragging near an edge.
- Proposed experience budget (subject to baseline/hardware review): target **60 FPS for 500 pieces** and **at least 30 FPS for 2000 pieces** on explicitly named reference hardware, with no long main-thread stalls during batched loading. These are **targets, not current results or platform guarantees**.

### P2 — Player accessibility and ergonomic interaction

**Goal:** a puzzle is playable without relying on tiny visual details or precise mouse gestures.

**Deliverables**
- Input action layer for remappable select, add/remove selection, rotate, zoom, focus board and overview; evaluate full keyboard play separately from mouse behavior. **Optional host InputMap aliases for rotate/preview/zoom/focus added; keyboard-only piece manipulation remains pending.**
- Touch and gesture prototype (tap/drag, two-finger pan/zoom), with conflicts tested against current drag/rotate behavior. **Initial touch, virtual cursor and standard gamepad button paths implemented; Godot import and physical hardware acceptance pending.**
- Accessible presentation options: adjustable selection/hover contrast, minimum visible contour width at zoom, color-blind-safe status cues, reduced motion and independent feedback volume. **Reduced-motion Feedback setting and live toggle added; Godot/manual verification pending.**
- Configurable snap assistance and larger interactive hit regions, clearly separated from the exact geometry needed for joins. **Initial opt-in implementation committed** (`snap_assist_extra_fraction`, `selection_assist_radius_px`); focused regressions written, but Godot runtime and manual usability checks still pending.
- A short documented usability scenario with controls, error prevention and discoverable camera shortcuts. **Touch/controller mapping documented; device usability trials pending.**

**Acceptance**
- Optional assists can be turned off, preserve deterministic puzzle state and do not change serialized group membership.
- Player feedback does not depend on color alone; reduced-motion operation remains functional.
- Test matrix covers mouse, keyboard-only and at least one touch device where supported; unsupported inputs remain explicitly documented until validated.

### P3 — Optional puzzle-organizing aids

**Goal:** help players manage hundreds of loose pieces without making the challenge trivial.

**Deliverables**
- Edge/corner/interior classification derived from grid topology, independent of current rotation or appearance. **Implemented as a pure catalog, with Board ID queries and optional C/E/I category camera browsing. Godot runtime confirmation pending.**
- Optional **trays** or named holding areas for loose pieces, with safe group movement and drag/drop. **First world-space named trays implemented**, with complete-group placement, drag/drop, safe retrieval and optional schema-1 membership persistence. Godot/runtime/device validation pending.
- Sort actions (border, corner, similarity only if backed by reliable information); avoid automatically solving the puzzle. **P3.2 exposes `put_selection_in_tray()` to let host UIs sort chosen connected groups; automatic color/image sorting is not implemented.**
- Progressive, opt-in hints with explicit difficulty levels: locate a region, highlight candidate groups, then stronger assistance only if requested. **First non-solving finding aid implemented: cycle camera focus among corners/edges/interior connected groups. Region/color hints remain future work.**
- Undo/redo feasibility study (bounded actions or snapshots, memory and event semantics), followed by implementation if justified.

**Acceptance**
- Sorting/tray operations are reversible or clearly disclosed, never silently disassemble connected groups or mutate original puzzle IDs.
- Hints cannot alter saved geometry or report false joins; available in both gameplay modes where sensible.
- 500/2000-piece manual tasks (finding corners, managing trays, returning to a group) are demonstrably faster or less frustrating than baseline.

### P4 — Maintainability and extensibility

**Goal:** lower the cost and risk of every next iteration.

**Deliverables**
- Continue extracting camera, input orchestration and generation workloads from `JigsawBoard` behind narrow interfaces, guided by tests—not a broad rewrite.
- Isolate presentation-related APIs from authoritative physics/snap transforms, leaving motion adapter and event contracts intact.
- Formalize versioning and migration rules for `JigsawPuzzleState`, event masks and serialized Resource presets.
- Add diagnostics hooks for progress, errors, profile samples and optional debug overlays without shipping them enabled.
- Evaluate batching/streaming scene creation and texture/mesh reuse only when concrete profiles justify their complexity.

**Acceptance**
- Public API and stored states remain compatible, or an explicit migration path and breaking-change release are documented.
- Fast tests and targeted scene tests cover every extracted subsystem.
- Code size or abstraction count is **not** itself a success metric; fewer regressions and simpler change paths are.

### P5 — Preview-to-stable release readiness

**Goal:** confidently install `addons/jigsawg/` in unrelated Godot projects.

**Deliverables**
- Clean-project packaging test with only `addons/jigsawg/`; no root `examples/`, `tests/` or `docs/` required for runtime.
- Confirm correct script UID/icon registration, import paths, engine compatibility and resource serialization.
- Verify provenance and permission of sample artwork; replace any uncertain files before distributing demos.
- A compact quick-start project, changelog, versioned documentation, known limitations and examples for both Free/Mosaic.
- Runtime smoke tests on chosen OS/renderers and explicit accessibility/performance support statement.

**Acceptance**
- Documented release checklist is completed with evidence; critical gameplay, parsing or save regressions block tagging.
- License/asset checks complete; release claims distinguish measured support from experimental scenarios.

## Proposed first three implementation iterations

| Iteration | Scope | Output | Tests/evidence |
| --- | --- | --- | --- |
| **1 — Baseline and safety** | Godot parser, fast-test runner, CI where viable; fix regressions | Repeatable PASS/FAIL report and hardware benchmark protocol | `tests/test_*.gd`, clean addon install, 200/500/2000 harness |
| **2 — Input at scale** | Measure and optimize piece lookup and visual priority | Controlled spatial hit-testing with fallback and no visible selection regressions | Selection/group/camera tests, latency before/after |
| **3 — First accessibility slice** | Remappable actions, reduced-motion option and contrast assessment | Small opt-in Resource/Input API, tested with mouse and keyboard | Public integration tests, manual keyboard-only scenario |

**Decision gate after iteration 1:** adjust P1 priorities to the actual bottleneck. Do not introduce a costly LOD or rendering rewrite if the measurements show another subsystem dominates.

## How to maintain this plan

- Mark completed work only after tests/observations; link commits, benchmarks and reproduction scenes in the relevant issue or PR.
- For each item record: user problem, public API impact, performance cost, compatibility risk, acceptance scenario and rollback strategy.
- Update this roadmap when the *priority or scope* changes, not as a replacement for `CHANGELOG.md` (which records completed changes).
- Keep optional gameplay aids behind Resources or host-accessible methods; do not turn JigsawG into a mandatory HUD or save framework.
