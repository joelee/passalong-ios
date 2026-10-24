# Backlog

Future work not covered by an active plan. Completed items are removed.

## Next milestones

- **Parity with passalong-android v0.2.0** (PLAN-00001, draft): the
  Rust bridge for iOS, setup for an SSH server or a passalong-server, and
  the choose screen. Waiting on the user's choices for D-01 (copy the
  bridge or share one crate) and D-02 (Files-app folder or a share sheet
  for loaded files), then approval. No iOS code exists yet; STEP-01 and
  STEP-03 to STEP-06 need no Simulator, the rest need macOS.
- The Android app's own next milestones, as they land there: joining an
  encrypted store, sending (a Share extension for text and files, and a
  pasteboard push), API key import from a QR code or link and *Replace
  the key*, and a `check` screen.

## Later

- **Simulator UI tests for the SwiftUI screens** (XCUITest), and for the
  SSH flow against passalong's Docker OpenSSH server.
- **Keychain** for the API key and the identity key, if file protection
  in Application Support proves not enough; the core reads both from
  files today.
- **iPad layout and hardware-keyboard shortcuts**: the TUI's keys as they
  are.
- **App icon and branding.**
- **Release pipeline**: signing, `CURRENT_PROJECT_VERSION` scheme,
  TestFlight or ad hoc distribution.

## Housekeeping

- **One bridge crate for both apps.** `rust/` will start as a copy of
  passalong-android's `passalong-ffi` with iOS `cfg`s; once both apps
  build it, move it to one place (the passalong repository or a shared
  crate) so the exports cannot drift.

## Agent suggested next steps

- **x86_64 Simulator slice** for Intel Macs, if one is ever used; the
  XCFramework carries `aarch64-apple-ios-sim` only.
