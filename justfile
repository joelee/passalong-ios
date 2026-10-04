# passalong-ios task runner. Every quality gate here is a command
# AGENTS.md names; pre-commit runs `just check`.
#
# Needs macOS with Xcode (docs/developer-guide.md); the Rust recipes also
# run on Linux. The Xcode project is generated from project.yml by XcodeGen.

set shell := ["bash", "-euo", "pipefail", "-c"]

# The Simulator `run`, `build`, and `test-ios` use; override with
# `just sim="iPhone 16 Pro" run`
sim := "iPhone 16"
swift_dirs := "PassalongKit App AppTests"

# List available recipes
default:
    @just --list

# Install developer tooling: Homebrew packages (Brewfile) and the Rust iOS targets
setup:
    brew bundle --file Brewfile
    rustup target add aarch64-apple-ios aarch64-apple-ios-sim

# Generate Passalong.xcodeproj from project.yml
gen:
    xcodegen generate --quiet

# Format Swift and Rust in place
fmt:
    swift format --in-place --recursive --parallel {{swift_dirs}}
    cargo fmt --manifest-path rust/Cargo.toml --all

# Check formatting
fmt-check:
    swift format lint --strict --recursive --parallel {{swift_dirs}}
    cargo fmt --manifest-path rust/Cargo.toml --all -- --check

# Lint: SwiftLint for Swift, clippy for Rust
lint:
    swiftlint lint --strict --quiet
    cargo clippy --manifest-path rust/Cargo.toml --all-targets --all-features -- -D warnings

# Unit tests: PassalongKit's Swift tests and the Rust bridge's host tests
test:
    swift test --package-path PassalongKit
    cargo test --manifest-path rust/Cargo.toml --all-features

# The bridge against a real passalong-server: PASSALONG_SERVER_BIN names the
# binary (docs/developer-guide.md); each test starts its own server
test-https:
    #!/usr/bin/env bash
    set -euo pipefail
    : "${PASSALONG_SERVER_BIN:?set PASSALONG_SERVER_BIN to a passalong-server binary; see docs/developer-guide.md}"
    cargo test --manifest-path rust/Cargo.toml --all-features --test server -- --ignored

# Swift line coverage gate (>= 80 %, over PassalongKit) with the figure printed
coverage:
    ./scripts/coverage.sh 80

# Build the Rust library, the Swift bindings, and the XCFramework alone
rust:
    ./scripts/rust-ios.sh

# Build the debug app for the Simulator, which builds the Rust library first
build: gen
    xcodebuild -project Passalong.xcodeproj -scheme Passalong -configuration Debug \
        -destination 'generic/platform=iOS Simulator' -quiet build

# Install and launch the debug app in the Simulator
run: gen
    ./scripts/sim-run.sh "{{sim}}"

# Simulator tests (AppTests); `server` and `pin` name a self-signed
# passalong-server to probe, and with `key` and `text` (an API key, and the
# text of an item the CLI put there) the whole setup-then-choose flow runs
# against it (docs/developer-guide.md)
test-ios server="" pin="" key="" text="": gen
    PASSALONG_TEST_SERVER="{{server}}" PASSALONG_TEST_PIN="{{pin}}" \
    PASSALONG_TEST_KEY="{{key}}" PASSALONG_TEST_TEXT="{{text}}" \
    xcodebuild -project Passalong.xcodeproj -scheme Passalong \
        -destination 'platform=iOS Simulator,name={{sim}}' -quiet test

# Every mandated check: format, lint, tests, coverage, build
check: fmt-check lint test coverage build

# Remove build outputs
clean:
    rm -rf Passalong.xcodeproj build DerivedData PassalongKit/.build
    cargo clean --manifest-path rust/Cargo.toml
    rm -rf rust/generated
