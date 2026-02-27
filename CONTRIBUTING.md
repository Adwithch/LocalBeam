# Contributing to LocalBeam

Thank you for considering contributing! Here's how to get started.

## Getting Started

1. **Fork** the repo and clone your fork
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Run `flutter pub get` and `flutter pub run build_runner build`
4. Make your changes, write tests
5. Open a Pull Request against `main`

## Development Setup

```bash
# Install Flutter 3.16+
flutter doctor

# Get dependencies
flutter pub get

# Generate Hive adapters & Riverpod providers
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Analyze
flutter analyze
```

## Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Max line length: 100 characters
- Use `final` wherever possible
- Document all public APIs with `///` doc comments
- Every new feature needs at least one test

## Architecture

LocalBeam uses Clean Architecture:

```
lib/
  core/          — platform-agnostic utilities, DI, network engine
  data/          — data sources, Hive models, repository implementations  
  domain/        — entities, repository interfaces, use cases
  presentation/  — Riverpod providers, screens, widgets, theme
```

- Business logic lives in `core/` and `domain/` — no Flutter imports there
- Presentation only talks to `domain/` via providers
- No direct Hive/HTTP calls from screens

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add bandwidth limiting
fix: chunk retry on network timeout
docs: update iOS setup instructions
test: add crypto roundtrip tests
refactor: extract speed tracker to own class
```

## Platform Notes

- **Web**: Local HTTP server cannot run in browser. Web support is limited to QR display.
- **iOS**: Background transfers are limited by iOS app lifecycle — document this clearly.
- **Android**: `NEARBY_WIFI_DEVICES` permission required on API 33+ for mDNS.

## Reporting Bugs

Use the GitHub issue template. Include:
- Device + OS version
- Flutter version (`flutter --version`)
- Steps to reproduce
- Expected vs actual behavior
- Logs if possible (export from Settings > Export Logs)

## Security Issues

Please do **not** file public issues for security vulnerabilities.  
Email the maintainer directly or use GitHub private security advisories.
