# AGENTS.md — Lisdex

Open-source macOS menu bar app (Swift 6, SwiftPM, AppKit + SwiftUI) that keeps the Mac awake — indefinitely, for a duration, or on a schedule. No Dock icon; a capsule-pill status icon, or a coffee mug (outlined = inactive, filled = active).

## Read first

- `.context/README.md` — how the knowledge base is organised.
- `.context/status/current.md` — roadmap, where things stand, open questions.
- `.context/specs/lisdex-v1.md` — product spec, menu layout, interactions, acceptance criteria.
- `.context/decisions/` — ADRs. Don't contradict one silently; supersede it with a new ADR.

## Commands

- `make test` — unit tests (must pass before you finish).
- `make app` / `make run` — build and launch `build/Lisdex.app`.
- `make lint` / `make format` — swift-format check / fix. `make icons` — regenerate icon exports from SVG.

## Rules

- Decision logic (session state, schedule evaluation, timers) goes in `Sources/LisdexCore` (Foundation only) **with tests**. `Sources/Lisdex` is I/O, power assertions, timing, UI.
- Value types and new values over mutation; `@MainActor` for app-layer state; no `print` — use `Log` (`os.Logger`).
- Never leave a power assertion / `caffeinate` child alive after quit or crash (see ADR 0002).
- Icon assets: edit SVG sources in `assets/`, regenerate exports — never hand-edit PNGs (ADR 0003).
- No secrets in the repo or `.context/`.
- After a non-trivial task: update `.context/status/current.md`; add an ADR for significant decisions; put verification notes in `.context/evidence/<date>-<topic>/`.
