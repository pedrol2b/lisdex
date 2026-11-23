# Click behavior (swap clicks) — Phase 7.1

_Approved by owner 2026-11-22._

## Intent

Let the user choose which status-item click toggles Keep Awake and which opens the popover, like Amphetamine's "Quick-Start a Session" setting.

## Goals / non-goals

- Goal: one setting, two values; default keeps v1.0 behaviour (right-click toggles).
- Non-goal: a "both clicks open the menu" option; Option-click behaviour (reserved for the v1.1 quick menu).
- Anti-goal: changing behaviour for existing users who never touch the setting.

## Approaches

1. **Two-value setting, decision in Core (picked).** Testable, minimal.
2. Three-value setting (adds "never quick-toggle") — no stated need.
3. Hard-code the swap — breaks existing users.

## Design

- `LisdexCore`: `StatusItemClickBehavior` (`rightClickToggles` default, `leftClickToggles`), `StatusItemClick` (`primary`, `secondary`), `StatusItemAction` (`toggle`, `openPopover`), and `StatusItemClickBehavior.action(for:)`. Control-click counts as `secondary` (app layer).
- `AppSettings.clickBehavior`, tolerant decoding (missing/unknown → default).
- `StatusItemController.handleClick` maps the event to a `StatusItemClick` and asks the setting.
- Settings → General: picker "Quick-Start a Session" — "Right click (left click shows menu)" / "Left click (right click shows menu)".
- Spec `lisdex-v1.md` interaction table updated.
