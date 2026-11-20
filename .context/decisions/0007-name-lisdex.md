# 0007 — Product name: Lisdex

- **Status:** Accepted (owner, 2026-11-19)
- **Date:** 2026-11-19

## Context

The project's working name was "Vyvanse", the brand of lisdexamfetamine dimesylate, chosen as a nod to Amphetamine (Mac App Store). "Vyvanse" and "Elvanse" are Takeda trademarks. Non-commercial MIT use lowers but doesn't remove trademark risk, and GitHub acts on trademark complaints. Amphetamine itself uses a generic drug name.

## Decision

- Public name **Lisdex**, short for **lisdexamfetamine** (the generic name, and the molecule drawn in the icon).
- Identifiers: app `Lisdex.app`, targets `Lisdex` / `LisdexCore` / `LisdexCoreTests`, bundle id `io.github.pedrol2b.lisdex`, log subsystem = bundle id, IOKit assertion name `"Lisdex: <mode>"`. Repository: <https://github.com/pedrol2b/lisdex> (not created yet).
- README must explain the name: "Lisdex is short for lisdexamfetamine". It may mention Lisdex descriptively ("the molecule in Lisdex") but never as the product name or in the logo.
- All `.context` docs and assets were renamed in place. ADR 0004 (superseded) and the first-mock source note keep the old name as history.

## Consequences

- The molecule identity, the colours and the "Amphetamine-style" naming still fit together.
- The local folder `~/Developer/public/vyvanse` can be renamed to `lisdex` by the owner whenever convenient. Nothing references the absolute path.

## Alternatives considered

- Lisdex — trademark risk.
- Prodrug, Dexy, Lysine — less recognisable or more generic.
