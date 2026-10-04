# Architecture

> [!note] Planned
> The layers PLAN-00001 builds, mirroring passalong-android's
> [architecture](https://github.com/joelee/passalong-android/blob/main/docs/architecture.md).

## Layers

```text
App/UI/SetupView, App/UI/ChooseView             SwiftUI; draws state, sends events
        │
Setup/SetupController, Choose/ChooseController  @Observable @MainActor; the TUI's run_picker and init   ┐
        │                                                                                               │
Domain/Picker                                   pure state machine: modes, filter, selection, status    │ PassalongKit
Data/ItemActions, Data/AppFiles                 load/cat over the store; where files live               │ (swift test,
Core/Core, Core/StoreHandle                     Swift protocols; tests use fakes                        ┘  coverage)
        │
App/Core/FfiCore                                the only file that imports the UniFFI bindings
        │ C ABI, PassalongFFI.xcframework (static library + module map)
rust/ passalong-ffi                             UniFFI exports; tokio; unified-log writer
        │
passalong-core, -ssh, -https (v0.3.0, git)      → SSH/SFTP server, or a passalong-server over HTTPS
```

Every call that reads or changes the store is a Swift `async` function
backed by an async Rust function (`#[uniffi::export(async_runtime =
"tokio")]`), so nothing blocks the main actor. The few blocking calls the
app makes itself (reading the config and the list cache, making a key,
moving a download into Documents) run off the main actor.

## Differences from Android

| Android | iOS | Why |
|---|---|---|
| `cdylib` per ABI in `jniLibs/`, loaded by JNA | `staticlib` per target packed into `PassalongFFI.xcframework` | iOS apps may not load arbitrary dynamic libraries; the XCFramework is the standard vehicle |
| Kotlin bindings | Swift bindings, the same exports | UniFFI generates both from the same crate |
| `rustls-platform-verifier` needs its Kotlin component and a JNI `init_hosted` call | Works through `Security.framework` with no initialisation | No JNI entry point and no extra component in `NOTICE` |
| logcat via `android_log-sys` (one `unsafe` call) | The unified log via `os_log` | Console.app and `log stream` read it |
| `filesDir` | Application Support, excluded from backup | The sandbox's private, non-user-visible directory |
| Downloads via MediaStore | The app's Documents folder, shown in the Files app | iOS has no shared Downloads folder an app can write to |
| `Build.MODEL` device name | `utsname` machine identifier mapped to a model name, or `iPhone` | `UIDevice.name` is generic since iOS 16 |
| *Quit* menu item, Back key | No quit; swipe back and *Done* | iOS conventions |
