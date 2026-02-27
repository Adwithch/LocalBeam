# Changelog

All notable changes to LocalBeam will be documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [SemVer](https://semver.org/)

---

## [1.0.0] — 2025-01-01

### Added
- Initial release 🎉
- Local file transfer over Wi-Fi (HTTP chunked streaming)
- mDNS peer discovery (auto-detects devices on same network)
- QR code pairing (generate + scan)
- AES-256-GCM optional encryption with PBKDF2 key derivation
- SHA-256 per-chunk integrity verification
- Support for 10 GB+ files via memory-efficient streaming
- Transfer history with export to text log
- Dark-first Material 3 UI with smooth animations
- Onboarding flow (4 screens)
- Settings: device name, download path, auto-accept, chunk size, encryption, bandwidth limit, session timeout
- Platforms: Android, iOS, macOS, Windows, Linux
- WebRTC data channel fallback for cross-subnet scenarios
- Riverpod state management with clean architecture
- Hive local storage for history and settings
- Unit tests for CryptoService and TransferManager
- Integration tests for send/receive flow
- GitHub Actions CI (analyze, test, build all platforms)
- MIT License

---

## [Unreleased]

### Planned
- Optional internet relay mode (TURN server)
- End-to-end encrypted mode with key exchange
- QR-less automatic LAN pairing
- Plugin system for external storage providers
- Resume interrupted transfers
- Transfer speed graph in UI
- Dark/light mode toggle in quick settings
