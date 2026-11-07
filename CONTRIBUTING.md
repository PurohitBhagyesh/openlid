# Contributing to OpenLid 👁️

Thank you for your interest in contributing to **OpenLid**! We welcome bug reports, feature suggestions, documentation updates, and pull requests.

## 🛠 Local Development Setup

### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 15+ / 16+ or Swift 5.9+ / 6.0+ toolchain
- Git

### Building from Source

```bash
# Clone the repository
git clone https://github.com/openlid/openlid.git
cd openlid

# Run the test suite
swift test

# Build debug binaries
swift build

# Build the release .app bundle and CLI
./scripts/bundle.sh
```

## 📐 Project Structure

- `Sources/OpenLidCore/`: Core engine managing IOKit clamshell sensors, power assertions, battery thresholds, and thermal guards.
- `Sources/OpenLid/`: Native SwiftUI Menu Bar application (represented by the vigilant Eye symbol).
- `Sources/OpenLidCLI/`: Command-line interface (`openlid`).
- `Tests/OpenLidCoreTests/`: XCTest unit tests for core power management.
- `website/`: Aesthetic product landing page with interactive web simulator and remote awake portal.

## 📝 Commit Conventions

We follow Conventional Commits:
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation improvements
- `style:` Formatting / styling changes
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Build scripts, repo configuration

## ⚖️ License
By contributing to OpenLid, you agree that your contributions will be licensed under the MIT License.

