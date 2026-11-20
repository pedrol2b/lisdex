# Contributing

Contributions are always welcome, no matter how large or small!

We want this community to be friendly and respectful to each other. Please follow it in all your interactions with the project. Before contributing, please read the [code of conduct](./CODE_OF_CONDUCT.md).

## Development workflow

Lisdex is a plain [Swift Package](https://www.swift.org/documentation/package-manager/) with no Xcode project. You need:

- macOS 14 Sonoma or later
- Xcode 16+ or the Command Line Tools with Swift 6 (`xcode-select --install`)

```sh
git clone https://github.com/pedrol2b/lisdex.git
cd lisdex
make test   # unit tests
make run    # build build/Lisdex.app and launch it
```

You can open the folder in Xcode (`xed .`), VS Code with the Swift extension, or any editor you like.

### Project layout

- `Sources/LisdexCore` — pure decision logic (session planning, schedules, settings). Foundation only, **fully unit-tested**.
- `Sources/Lisdex` — the app: AppKit status item, SwiftUI popover and settings, power assertions, timers.
- `Tests/LisdexCoreTests` — [Swift Testing](https://developer.apple.com/documentation/testing) unit tests.
- `assets/` — SVG sources for the icons and the exports generated from them. Edit the SVGs, never the PNGs.
- `.context/` — design notes, specs, architecture decisions (ADRs) and the roadmap. Read [`AGENTS.md`](AGENTS.md) and `.context/status/current.md` before larger changes.

Logic that makes a decision belongs in `LisdexCore` with tests. The app target should only do I/O, timing and UI.

### Formatting

We use [swift-format](https://github.com/swiftlang/swift-format), which ships with the Swift 6 toolchain:

```sh
swift format lint --strict --recursive Sources Tests   # check
swift format --in-place --recursive Sources Tests      # fix
```

### Commit message convention

We follow the [conventional commits specification](https://www.conventionalcommits.org/en) for our commit messages:

- `fix`: bug fixes, e.g. release the power assertion when the timer ends.
- `feat`: new features, e.g. add per-day schedule windows.
- `refactor`: code refactor, e.g. extract the schedule evaluator.
- `docs`: changes into documentation, e.g. update the install guide.
- `test`: adding or updating tests, e.g. cover daylight-saving transitions.
- `chore`: tooling changes, e.g. update `.editorconfig`.
- `perf`: performance improvements, e.g. avoid waking the timer every second.
- `ci`: CI/CD pipeline changes, e.g. update a GitHub Actions workflow.
- `build`: build system changes, e.g. change `scripts/build-app.sh` or the Homebrew formula.

### Git hooks (optional)

If you use [lefthook](https://lefthook.dev) (`brew install lefthook && lefthook install`), the `pre-commit` hook lints staged Swift files with swift-format and the `commit-msg` hook checks the conventional-commit format. Tests aren't run automatically on commit, so run `make test` yourself before opening a pull request.

### Scripts

The `Makefile` contains the common tasks:

- `make build`: debug build.
- `make test`: run unit tests.
- `make coverage`: run tests with code coverage.
- `make app`: assemble `build/Lisdex.app` (ad-hoc signed).
- `make run`: build the app and launch it.
- `make install`: copy the app to `~/Applications` and launch it.
- `make clean`: remove build artifacts.

### Testing your change in the app

Check the menu bar behaviour by hand: left-click opens the menu, right-click toggles Keep Awake. To confirm Lisdex is really keeping the Mac awake, run:

```sh
pmset -g assertions | grep -i lisdex
```

### Sending a pull request

> **Working on your first pull request?** You can learn how from this _free_ series: [How to Contribute to an Open Source Project on GitHub](https://app.egghead.io/playlists/how-to-contribute-to-an-open-source-project-on-github).

When you're sending a pull request:

- Prefer small pull requests focused on one change.
- Verify that formatting and tests are passing.
- Include a screenshot or short recording for UI changes.
- Review the documentation to make sure it looks good.
- For pull requests that change behaviour or add features, discuss with maintainers first by opening an issue (see the [issue templates](.github/ISSUE_TEMPLATE) for bug reports, build errors, and feature requests).

### Signed releases

Lisdex is distributed as source (see the README for why). If you have experience with Developer ID signing and notarization in GitHub Actions and would like to help offer signed releases in the future, please open an issue.
