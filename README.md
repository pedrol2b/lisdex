<p align="center">
  <img src="assets/app-icon/export/app-pill-1024.png" width="128" alt="Lisdex app icon: a two-tone gold capsule pill on graphite">
</p>

<h1 align="center">Lisdex</h1>

<p align="center">
  A tiny, open-source macOS menu bar app that keeps your Mac awake.<br>
  Indefinitely, for a duration, or on a schedule.
</p>

<p align="center">
  <a href="https://github.com/sponsors/pedrol2b"><img src="https://img.shields.io/badge/Sponsor-%E2%9D%A4-ea4aaa?logo=githubsponsors&logoColor=white" alt="Sponsor on GitHub"></a>
  <a href="https://github.com/pedrol2b/lisdex/releases/latest"><img src="https://img.shields.io/github/v/release/pedrol2b/lisdex?color=F4C85B" alt="Latest release"></a>
  <a href="https://github.com/pedrol2b/homebrew-tap"><img src="https://img.shields.io/badge/brew-pedrol2b%2Ftap%2Flisdex-FBB040?logo=homebrew&logoColor=white" alt="brew install pedrol2b/tap/lisdex"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-202228" alt="macOS 14+">
  <img src="https://img.shields.io/badge/license-MIT-F4C85B" alt="MIT license">
</p>

## Why does this exist?

My company laptop blocks [Amphetamine](https://apps.apple.com/app/amphetamine/id937984704) from the App Store, so I built my own.

Lisdex does one thing: stop your Mac from going to sleep. It's small enough to read in an afternoon, so you can check exactly what you're running.

### Why "Lisdex"?

**Lisdex** is short for **lisdexamfetamine** ([PubChem CID 11597698](https://pubchem.ncbi.nlm.nih.gov/compound/Lisdexamfetamine)), hence the capsule pill icon. Amphetamine is named after a drug, so this one is too. Lisdexamfetamine is the active ingredient of Vyvanse/Elvanse, which are trademarks of their owners. Lisdex isn't affiliated with them and has nothing to do with medicine.

## Features

| | |
| --- | --- |
| <img src="assets/menubar/pill-inactive@3x.png" height="18" alt=""> → <img src="assets/menubar/pill-active@3x.png" height="18" alt=""> | **Menu bar only.** No Dock icon. A capsule pill, outlined when inactive and filled when active. Prefer a coffee mug or a light bulb? It's one setting away. |
| ∞ | **Indefinitely.** Stay awake until you turn it off. |
| ◷ | **For a duration.** 15 min, 30 min, 1 h, 2 h or a custom time. |
| ▦ | **On a schedule.** Choose days and hours, e.g. weekdays 09:00–18:00 with a short Friday. |
| ⧉ | **While an app is open.** Pick apps like Xcode or VS Code; your Mac stays awake while one is open. |
| ◐ | **Focus modes and Shortcuts.** Links like `lisdex://on` work from any Shortcuts automation; native actions and a Focus filter when you build with a signing certificate ([details](#shortcuts-and-focus)). |
| 🖱 | **Left-click** opens the menu. **Right-click** toggles Keep Awake and keeps your selected mode. |
| 🔔 | **A little pop** when you switch it on or off (like Amphetamine). Pick a different sound, or turn it off. |
| ⚙︎ | Start on login, keep the display awake, a battery cutoff, accent colours and two icon variants. |

## Screenshots

<p align="center">
  <img src="assets/screenshots/popover-inactive.png" width="31%" alt="Lisdex menu, inactive, mode Indefinitely">
  <img src="assets/screenshots/popover-duration.png" width="31%" alt="Lisdex menu, active for a duration of 1 hour with progress">
  <img src="assets/screenshots/popover-schedule.png" width="31%" alt="Lisdex menu, schedule mode Monday to Friday 9:00 to 18:00">
</p>
<p align="center">
  <img src="assets/screenshots/settings-power.png" width="48%" alt="Settings, Power tab: display, battery cutoff and keep-awake engine">
  <img src="assets/screenshots/settings-appearance.png" width="48%" alt="Settings, Appearance tab: pill or coffee mug menu bar icon and accent colours">
</p>

### How it keeps your Mac awake

By default Lisdex uses macOS **power assertions** (IOKit), the same mechanism `caffeinate` uses. They show up as `Lisdex` in `pmset -g assertions`, and macOS clears them automatically if the app quits or crashes. If you prefer the system command, you can switch to `/usr/bin/caffeinate` in **Settings → Power**.

## Install

Lisdex is **built on your Mac from source**. There is no prebuilt download (see [why](#why-build-from-source)).

### Requirements

- macOS 14 Sonoma or later (Apple silicon or Intel)
- Xcode Command Line Tools with Swift 6: `xcode-select --install`
- [Homebrew](https://brew.sh) (only for option 1)

### Option 1 — Homebrew (recommended)

```sh
brew install pedrol2b/tap/lisdex
ln -sf "$(brew --prefix)/opt/lisdex/Lisdex.app" ~/Applications/Lisdex.app
open ~/Applications/Lisdex.app
```

Homebrew downloads the source from the [tap](https://github.com/pedrol2b/homebrew-tap), compiles it (takes about a minute) and installs `Lisdex.app`. The link puts it in `~/Applications` so Spotlight and Login Items can find it. Update with `brew upgrade lisdex`.

### Option 2 — Build it yourself

```sh
git clone https://github.com/pedrol2b/lisdex.git
cd lisdex
make install   # builds, signs locally and copies Lisdex.app to ~/Applications
```

### Why build from source?

macOS only opens downloaded apps if they're **signed and notarized with a paid Apple Developer account** (US$99/year). This project doesn't have one. Without it:

- a prebuilt `Lisdex.app` from GitHub Releases would be blocked by Gatekeeper as "damaged" or "from an unidentified developer";
- Homebrew's official cask repository no longer accepts unsigned apps, and Homebrew removed the `--no-quarantine` workaround.

An app **compiled on your own Mac** is never quarantined, so Gatekeeper lets it run with no warnings and no security settings to disable. The Homebrew tap uses a *formula* that builds from source for this reason, rather than a *cask* that downloads a binary.

On a company-managed Mac, device-management policy may still block locally built apps. Please respect your organisation's rules.

> 💛 **Want one-click installs?** Signed, notarized releases (and an official Homebrew cask) need an Apple Developer membership. If you'd like to help make that happen, by [sponsoring](https://github.com/sponsors/pedrol2b) or by contributing signing/notarization CI for a future maintainer account, contributions are very welcome. Open an issue to discuss.

## Shortcuts and Focus

**Links (every build).** Use Shortcuts' *Open URL* action, e.g. in an automation for when a Focus turns on or off:

| Link | Does |
| --- | --- |
| `lisdex://on` | Turns Keep Awake on in the current mode |
| `lisdex://on?minutes=90` | On for 90 minutes (1–1440) |
| `lisdex://on?until=stopped` | On until you turn it off |
| `lisdex://off` | Turns it off |
| `lisdex://toggle` | Flips it |

**Native actions and a Focus filter (builds signed with a certificate).** macOS only runs an app's Shortcuts actions when the app is signed with a team identity, so the default ad-hoc build leaves them out. A free Apple ID gives you an *Apple Development* certificate in Xcode → Settings → Accounts; then build with it:

```sh
CODESIGN_IDENTITY="Apple Development: Your Name (TEAMID)" make install
```

You then get *Turn Keep Awake On*, *Turn Keep Awake Off* and *Is Keep Awake On?* in Shortcuts, and in System Settings → Focus → (a Focus) → Focus Filters → Lisdex a **Keep Mac awake** switch: Lisdex turns on while that Focus is on and off when it ends. Turning it off yourself wins until the Focus starts again. Needs Xcode (not just the Command Line Tools).

## Uninstall

```sh
brew uninstall lisdex && rm ~/Applications/Lisdex.app   # Homebrew
rm -rf ~/Applications/Lisdex.app                          # built yourself
defaults delete io.github.pedrol2b.lisdex                  # optional: remove settings
```

## Contributing

Issues and PRs are welcome! Read the [contributing guide](CONTRIBUTING.md) and the [code of conduct](CODE_OF_CONDUCT.md) first. Found a vulnerability? Please follow the [security policy](SECURITY.md) instead of opening an issue.

The project is a SwiftPM package (no Xcode project): `make test` runs the unit tests, `make run` builds and launches the app. Design notes, decisions (ADRs) and the roadmap are in [`.context/`](.context/README.md). Start with [`AGENTS.md`](AGENTS.md).

## Sponsor

If Lisdex keeps your Mac (and you) awake, consider supporting it. Sponsorships go towards an Apple Developer membership for signed releases.

- [GitHub Sponsors](https://github.com/sponsors/pedrol2b)
- [Patreon](https://www.patreon.com/pedrol2b)
- [Buy Me a Coffee](https://buymeacoffee.com/pedrol2b)

## License

[MIT](LICENSE) © 2026 Pedro Bueno
