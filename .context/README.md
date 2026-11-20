# .context

Project knowledge base for **Lisdex**, written for AI coding agents and humans alike. Agents are told (via `AGENTS.md` / `CLAUDE.md`) to read from and write to this folder. It is **not** app source code — nothing here is bundled into the `.app`.

## Layout

| Folder          | What goes in it                                                                                                                       | Naming                                  |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| `architecture/` | How the app is built: module map, data flow, state, power-assertion lifecycle, diagrams. Describes the _current_ system.              | `<topic>.md`                            |
| `decisions/`    | Architecture Decision Records (ADRs): one decision per file, never rewritten — supersede with a new ADR. Start from `0000-template.md`. | `NNNN-<kebab-title>.md`                 |
| `evidence/`     | Verification artifacts for changes (screenshots, test output, manual QA notes).                                                       | `<yyyy-mm-dd>-<topic>/`                 |
| `runbooks/`     | Step-by-step operational procedures: local setup, building the `.app`, signing, notarizing, releasing.                                | `<task>.md`                             |
| `sources/`      | External reference material pulled in for context: vendor docs excerpts, design exports, links. Note the origin and date.            | `<source>-<topic>.md`                   |
| `specs/`        | Feature specs, PRDs and acceptance criteria.                                                                                          | `<feature>.md` or `<feature>/`          |
| `status/`       | Where things stand: current status, roadmap, open questions, handoff notes between sessions.                                          | `current.md`, `<yyyy-mm-dd>-<topic>.md` |
| `tooling/`      | Dev tooling docs: build system, AI agent setup (skills, plugins, MCP), linters, CI, editor config.                                    | `<tool>.md`                             |

## Conventions

- **Markdown first**, short and factual. Link to code with repo-relative paths (`Sources/LisdexCore/SessionPlanner.swift:20`).
- **Date everything** that can go stale (ISO dates, `2026-11-19`).
- **One source of truth**: if something is enforced by code or config (`Package.swift`, `Support/Info.plist`, `Makefile`), reference it instead of copying it.
- **No secrets**: no signing identities' passwords, App Store Connect API keys or notarization credentials. Those live in the Keychain / CI secrets.
- Agents: before a non-trivial task, read the relevant `specs/`, `decisions/` and `status/current.md`; after it, update `status/current.md` and add an ADR if a significant decision was made.
