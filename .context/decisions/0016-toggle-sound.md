# ADR 0016 — Toggle sound feedback

- **Status:** Accepted
- **Date:** 2026-11-20

## Context

Amphetamine plays a short "pop" when a session starts. The owner wants the same audible
confirmation, with a setting to turn it off and a few sounds to choose from.

## Decision

- When the **user** switches Keep Awake on or off (popover switch, right-click, a duration
  chip that turns it on), play a short sound once the change actually took effect.
  A failed start plays nothing.
- Expiry, battery cutoff, engine give-up, mode restarts and activate-on-launch stay silent.
  Expiry already has its own notification.
- Sounds are the macOS system sounds (Pop, Tink, Glass, Bottle, Purr, Morse) played with
  `NSSound(named:)`. Nothing is bundled, so there is no licensing question and no added app size.
- `AppSettings.playsToggleSound` (default **on**) and `toggleSound` (default **Pop**) live in
  Settings → General → Sound. Choosing a sound previews it.
- The same sound is used for on and off. Separate on/off sounds can come later if asked for.
