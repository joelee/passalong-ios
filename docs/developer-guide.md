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

Hold off on `pre-commit install` until `just check` passes (PLAN-00001
STEP-02): until the app exists, the hook would refuse every commit.

To run on a phone, put your development team in a git-ignored
`Local.xcconfig` (`DEVELOPMENT_TEAM = ABCDE12345`); `project.yml` includes
it when present.

## Setting up a new machine

The plans and the parity rule read sibling repositories, so clone them
side by side:

```sh
cd ~/Projects/GitHub      # any folder; the four must be siblings
git clone git@github.com:joelee/passalong-ios.git
git clone git@github.com:joelee/passalong-android.git
git clone git@github.com:joelee/passalong.git
git clone git@github.com:joelee/passalong-server.git
git -C passalong-android switch feature/00002-passalong-server
```

| Sibling | Why |
|---|---|
| `passalong-android` | The reference implementation; PLAN-00001 ports it. Its passalong-server work (PLAN-00002, commit `9c2bf59`) is on `feature/00002-passalong-server` until merged into its `main`, so check that branch out |
| `passalong` | The CLI 0.3.0, to seed a test server with items (`cargo build --release --locked`), and the core's source for a local path patch |
| `passalong-server` | The server binary `just test-https` and `just test-ios` run against (`cargo build --release --locked -p passalong-server`); AGPL, so read its docs but never copy its code here |

Then, in `passalong-ios`:

```sh
just setup
codegraph init .                   # the index is per machine and git-ignored
codegraph init ../passalong-android
```

`codegraph explore --path ../passalong-android "<symbol>"` then finds the
Android counterpart of anything being ported.

Nothing in this repository has been compiled for iOS yet: the `justfile`,
`.swift-format`, `.swiftlint.yml`, and the CI workflow were written on
Linux before any Swift existed. Expect STEP-02 of PLAN-00001 to correct
them on the first Mac run, and record what changed in its work log.

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

## Porting from Android

PLAN-00001 ports each Kotlin file test-first. Some Android choices exist
for reasons the code doesn't spell out; keep them:

- **Controllers start after construction.** `ChooseController.connect()`
  is called by its owner, not from `init`, so a test can watch every
  status from the first.
- **Tests record statuses at each fake call.** A `StateFlow` merges
  quick successive values, so Android's controller tests have the fake
  store record the status at the moment it is called, as the TUI's fake
  screen records frames. `@Observable` is no better at showing
  intermediate states; port the tests the same way.
- **The core gets an environment, not the process's.** The bridge's
  `AppEnv` (`rust/src/env.rs`) answers only `HOME` (the app's storage)
  and a hostname the app passes. The core needs `HOME` to expand `~`
  in the CLI-format config; pass both to every bridge call that parses
  config (`validate_config`, `open_store`), and never read `std::env`
  in the bridge.
- **Bindings are generated by the crate's own binary** (`cargo run
  --features cli --bin uniffi-bindgen`), so bindgen and library never
  disagree; don't use a separately installed `uniffi-bindgen`.
- **Strings are part of the contract.** Status lines and prompts are the
  TUI's and Android's word for word; a test that pins one is ported with
  the same text.

## The passalong-server to test against

Build the server and the CLI in their sibling clones (see above), then
give each a home of its own. This matters: with `XDG_CONFIG_HOME` or
`XDG_DATA_HOME` set, `HOME=<tmp>` alone does not isolate them, and a test
run has once written a workspace and a key into a real server's data.
Never point tests at a server you use for real.

```sh
export HOME=$(mktemp -d); unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME
P=../passalong-server/target/release/passalong-server
$P init
$P tls self-signed --host localhost --ip 127.0.0.1 --ip <this Mac's LAN address>  # prints the pin
$P workspace create home
$P key create --workspace home --label simulator              # prints the key, once
$P serve                                                      # https://0.0.0.0:8443
```

From the iOS Simulator this Mac is `127.0.0.1`; from a phone, its LAN
address. Put items there with the CLI, under the same isolated home:

```sh
C=../passalong/target/release/passalong
$C init --url https://127.0.0.1:8443 --tls-pin <pin> --api-key-file <a 600 file holding the key> --yes
printf 'hello' | $C clipboard --stdin
just test-ios https://127.0.0.1:8443 <pin> <key> hello
```

The bridge's own server tests start a server per test from the binary
and need only `PASSALONG_SERVER_BIN=$P just test-https`.
