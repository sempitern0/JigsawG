# Contributing to JigsawG

Thank you for helping improve a reusable Godot jigsaw plugin.

## Before you contribute
- Search [existing issues](https://github.com/sempitern0/JigsawG/issues).
- For feature proposals, describe a real user scenario and the Resource/API behavior you expect.
- Do not submit images or other assets without redistribution permission.

Read [AGENTS.md](AGENTS.md) for the repository map, invariants and test selection, and [Development roadmap](docs/ROADMAP.md) for current priorities. These documents supplement the contribution workflow below.

## Development setup
1. Fork/clone the repository and open it with **Godot 4.7**.
2. Enable the JigsawG plugin and run `examples/puzzle_lab.tscn`.
3. Modify only the relevant `addons/jigsawg` scripts; keep the public `JigsawBoard.puzzle_config` API backwards compatible where possible.
4. Follow `docs/TESTING.md`, especially Free/Mosaic, rotation, shuffle, preview and camera checks.
5. Open a pull request with rationale, before/after behavior, engine logs and test results.

## Engineering conventions
- Resource classes own persistent configuration; runtime code must not modify shared preset assets.
- Internal piece geometry, camera, controls and feedback should remain independently testable.
- Preserve canonical matching seams and deterministic generation when a seed is supplied.
- Document every public signal, exported Resource field and breaking change.
- Avoid introducing extra required plugins/dependencies or links to host-project root assets.
- Prefer small focused pull requests over API-breaking rewrites.

## Reporting issues
Use the [bug report template](https://github.com/sempitern0/JigsawG/issues/new/choose) with your Godot version, steps to reproduce, source image size, relevant .tres settings and logs.
