# ADR 0028 — About panel: standard panel, better credits

- **Status:** Accepted (owner picked A and approved the build, 2026-11-25)
- **Date:** 2026-11-25

## Context

After the Settings (ADR 0026) and menu (ADR 0027) reworks the owner asked to review About too.
The panel showed four grey credit lines of equal weight with the repo link as the only action,
and lacked two things the spec asked for: "Inspired by Amphetamine" and a note that the name and
pill aren't medical content.

Options (browser mockups, `.superpowers/brainstorm/`, not committed):

- **A.** Keep `orderFrontStandardAboutPanel`; better credits (picked).
- **B.** A custom SwiftUI window in the menu's style: copyable version chip, three buttons,
  accent-coloured Sponsor.

## Decision

- Credits, one short fact per line and no break inside a sentence (owner: the first draft was
  too tall because a sentence wrapped): tagline "Keeps your Mac awake." · links GitHub · Report an
  issue (`issues/new/choose`) · Sponsor (GitHub Sponsors, first in `FUNDING.yml`) · "Inspired by
  Amphetamine." · "Named after lisdexamfetamine." · "Not medical content." · "MIT License" (own
  line, owner). Copyright stays in `NSHumanReadableCopyright`.
- The panel is narrow (~280 pt); new lines must fit without wrapping.
- `-LisdexScreenshot about` opens the panel for screenshots.
