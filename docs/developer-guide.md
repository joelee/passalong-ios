# Developer guide

## Toolchain

- macOS with Xcode 16 or later (Swift 6, `swift format`, the iOS 17+
  SDK and Simulators). The app is built, tested in the Simulator, and
  signed there; Linux can run the Rust recipes only.
- Homebrew packages from the `Brewfile`: `just`, `xcodegen`, `swiftlint`,
  `pre-commit`.
- Rust stable (1.98 or later) with the targets `aarch64-apple-ios` and
  `aarch64-apple-ios-sim`. `uniffi-bindgen` is a binary of the bridge
  crate itself, so nothing else is installed.

One-time setup:

```sh
just setup        # brew bundle, rustup targets
pre-commit install
```

To run on a phone, put your development team in a git-ignored
`Local.xcconfig` (`DEVELOPMENT_TEAM = ABCDE12345`); `project.yml` includes
it when present.

## Repository layout

```text
PassalongKit/         Swift package: platform-free logic, `swift test`, the coverage gate
  Sources/PassalongKit/
    Domain/           Item, Picker (the TUI's state machine), Formats, Failures
    Core/             Core and StoreHandle protocols, CoreError
    Data/             AppFiles, ItemActions, the pasteboard and files sink protocols
    Choose/, Setup/   the controllers, @Observable each
  Tests/PassalongKitTests/   Swift Testing tests with fakes (Support/Fakes.swift)
App/                  The iOS app target: FfiCore, the sinks, AppContainer, SwiftUI views
AppTests/             Simulator tests: the bridge's TLS and the setup-then-choose flow
project.yml           XcodeGen spec; `just gen` writes the git-ignored Passalong.xcodeproj
rust/                 passalong-ffi: the UniFFI bridge over passalong-core, -ssh, -https
scripts/              rust-ios.sh, coverage.sh, sim-run.sh
docs/                 user and developer documentation; ideas, plans, reviews contracts
.agents/skills/       the report-number allocation skill the contracts use
```

Only `docs/`, `.agents/`, and the tooling configs exist until PLAN-00001
is built; the recipes below that need the rest fail until then.

## Recipes

| Recipe | Runs |
|---|---|
| `just fmt` / `just fmt-check` | swift-format and rustfmt, format or check |
| `just lint` | SwiftLint (`--strict`) and clippy (`-D warnings`) |
| `just test` | `swift test` in `PassalongKit`, then `cargo test` in `rust/` |
| `just coverage` | prints PassalongKit's Swift line coverage and fails under 80 % |
| `just test-https` | the bridge against a real passalong-server, from the binary `PASSALONG_SERVER_BIN` names |
| `just rust` | the Rust libraries, the Swift bindings, and `PassalongFFI.xcframework` alone |
| `just gen` | `xcodegen generate` |
| `just build` | the debug app for the Simulator, building the Rust library first |
| `just run` | installs and launches it in the Simulator (`just sim="iPhone 16 Pro" run`) |
| `just test-ios` | the Simulator tests; with a test server (`just test-ios <url> <pin> <key> <text>`), also the whole setup-then-choose flow |
| `just check` | fmt-check, lint, test, coverage, build |

`.pre-commit-config.yaml` runs `just check` before every commit once
`pre-commit install` has been run.

## Test-driven workflow

1. Write a failing test for the next behaviour; confirm it fails for the
   right reason.
2. Write the smallest code that passes it.
3. Refactor with the test green.
4. Run `just check` before committing.

Swift unit tests use Swift Testing (`@Test`, `#expect`) with fakes for
every external interface, ported from passalong-android's
`support/Fakes.kt`. The Rust bridge is tested on the host with `cargo
test` over the core's `local` backend, as on Android.

## Process

Ideas, plans, and reviews are numbered reports under `docs/ideas/`,
`docs/plans/`, and `docs/reviews/`, each governed by its `AGENTS.md`;
allocate numbers with
`.agents/skills/allocating-report-numbers/allocate-report.sh`. Plans are
written only on a clean worktree and approved by the user before any code
changes. CodeGraph indexes this repo (`codegraph init` once per machine);
the Android twin is indexed too, so `codegraph explore --path
../passalong-android "<symbol>"` finds the counterpart of a feature.

## The passalong-server to test against

Follow passalong-android's
[developer guide](https://github.com/joelee/passalong-android/blob/main/docs/developer-guide.md#a-passalong-server-to-try-against),
with two differences: from the iOS Simulator this Mac is `127.0.0.1`
(no `10.0.2.2`), and the self-signed certificate needs only `--host
localhost --ip 127.0.0.1` plus the Mac's LAN address for a phone. Always
give the server and the CLI a home of their own (`HOME=$(mktemp -d)`,
and unset `XDG_CONFIG_HOME` and `XDG_DATA_HOME`), so they never touch a
server you run for real.
