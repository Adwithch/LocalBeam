# 🚀 LocalBeam

> Fast, private, local file transfer — no internet required.

**Made with 💙 by [Adwith](https://www.instagram.com/a.dwith?igsh=MXdyeXU5cDM5YW5oeQ==)**

[![CI](https://github.com/adwith/localbeam/actions/workflows/ci.yml/badge.svg)](https://github.com/adwith/localbeam/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.16%2B-blue)](https://flutter.dev)

---

## ✨ Features

| Feature | Details |
|---------|---------|
| 🌐 Local-only | Works entirely on your Wi-Fi — no cloud, no signup |
| 🔒 Encrypted | Optional AES-256-GCM with PBKDF2 key derivation |
| ✅ Integrity | SHA-256 per-chunk verification |
| 📡 Auto-discovery | mDNS — devices appear automatically |
| 📱 Cross-platform | Android, iOS, macOS, Windows, Linux |
| 📦 No size limit | Optimised for 10 GB+ with streaming chunks |
| 🕶️ Dark-first UI | Material 3, smooth animations, premium feel |
| 📜 History | Transfer log with export for debugging |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│               Presentation Layer             │
│  Riverpod Providers → Screens → Widgets      │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│               Domain Layer                   │
│  Entities · Repository Interfaces            │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│               Data Layer                     │
│  Hive · Settings · History · HTTP Client     │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│               Core Layer                     │
│  LocalServer · TransferManager · Crypto      │
│  DiscoveryService · WebRTC · DI (GetIt)      │
└─────────────────────────────────────────────┘
```

### Transfer Sequence

```
Sender                              Receiver
  │                                    │
  │─── POST /transfer/offer ──────────▶│
  │◀── { accepted: true } ────────────│
  │                                    │
  │─── POST /transfer/chunk (x N) ───▶│ ← chunked binary stream
  │◀── { status: ok } ────────────────│   (encrypted if password set)
  │                                    │
  │─── GET /transfer/{id}/status ────▶│
  │◀── { progress, speed, ... } ──────│
  │                                    │
  │         [all chunks sent]          │
  │                                    │
  └────── Transfer Complete ───────────┘
```

---

## 🔧 Build Instructions

### Prerequisites

- Flutter 3.16+ ([install](https://flutter.dev/docs/get-started/install))
- Dart 3.0+

```bash
# Clone
git clone https://github.com/adwith/localbeam.git
cd localbeam

# Install dependencies
flutter pub get

# Generate Hive adapters & code
flutter pub run build_runner build --delete-conflicting-outputs
```

### Android

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Or for Play Store:
flutter build appbundle --release
```

> **Permissions needed:** Internet, Local Network, Camera (QR), Storage, Nearby Wi-Fi Devices (Android 12+)

### iOS

```bash
flutter build ios --release

# Open Xcode for code signing:
open ios/Runner.xcworkspace
```

> **Info.plist keys configured:** `NSLocalNetworkUsageDescription`, `NSBonjourServices`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`
> 
> **iOS Background Limitation:** iOS suspends apps in the background. Active transfers will pause when the app is backgrounded. For large files, keep the screen on during transfer or use the "Background Modes" entitlement (fetch + processing — already configured in Info.plist).

### macOS

```bash
flutter config --enable-macos-desktop
flutter build macos --release
```

> Add entitlements in `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`:
> ```xml
> <key>com.apple.security.network.server</key><true/>
> <key>com.apple.security.network.client</key><true/>
> ```

### Windows

```bash
flutter config --enable-windows-desktop
flutter build windows --release
# Output: build\windows\x64\runner\Release\localbeam.exe
```

### Linux

```bash
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev
flutter config --enable-linux-desktop
flutter build linux --release
```

---

## 🧪 Testing

```bash
# Unit tests
flutter test test/unit/

# Integration tests (requires device/emulator)
flutter test test/integration/ --device-id <device_id>

# All tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 📱 Manual Two-Device Testing

1. Connect both devices to the **same Wi-Fi network**
2. Launch LocalBeam on both devices
3. On **Device A** (receiver): tap the **Receive** tab → note the QR code / IP address
4. On **Device B** (sender): tap **Pick Files** → select a file → tap **Scan QR** and scan Device A's code
5. Device A shows an incoming offer dialog (unless auto-accept is on)
6. Tap **Accept** on Device A
7. Watch the transfer progress on both devices
8. Verify the file saved to Device A's Downloads folder

> 💡 **No QR scanner?** On Device B, enter Device A's IP manually via Settings → Add Manual Device.

---

## 🔒 Security

### Encryption
- **Algorithm:** AES-256-GCM (authenticated encryption — prevents tampering)
- **Key derivation:** PBKDF2-HMAC-SHA256, 100,000 iterations, 32-byte salt
- **IV:** 12-byte random nonce per chunk
- **Authentication:** 16-byte GCM tag per chunk
- **Transport:** All traffic is local LAN only by default

### Integrity
- Every chunk includes a SHA-256 hash in the `X-Chunk-Hash` header
- Receiver verifies each chunk before writing to disk
- Mismatched chunks are rejected and the transfer fails

### Password challenge
- Sender creates `HMAC-SHA256(password + random_salt)` challenge
- Receiver must verify before chunks are accepted
- Password never transmitted in plaintext

### Threat model
- ✅ Protected against: passive eavesdropping on LAN, file corruption
- ⚠️ Not protected against: active MitM on the same network (use encryption), malicious apps on the same device

---

## ⚠️ Platform Limitations

| Platform | Limitation |
|----------|-----------|
| **Web** | Cannot run a TCP/HTTP server — Web is display/QR only |
| **iOS** | Transfers pause when app goes to background (iOS restriction) |
| **Android APK extraction** | Cannot extract system APKs — respects Android OS security policy |
| **Desktop (no Wi-Fi)** | mDNS discovery requires a network interface — use manual IP entry on VMs |

---

## 🐛 Troubleshooting

**Devices not discovering each other**
- Both must be on the same Wi-Fi network (not guest network isolation)
- Try adding the device manually via IP in Settings
- Check firewall on desktop: allow port 7432 (TCP inbound)

**Transfer fails immediately**
- Check receiver accepted the offer
- Confirm no VPN is active (VPNs can block local traffic)
- Try reducing chunk size in Settings (slow/congested networks)

**Slow transfer speed**
- Increase chunk size to 2 MB or 4 MB in Settings
- Ensure both devices are on 5 GHz Wi-Fi
- Close other bandwidth-heavy apps

**iOS crash after backgrounding**
- Keep app in foreground for large transfers
- Use low-power mode off (can affect network priority)

---

## 📊 Performance Benchmarks

| File Size | Network | Average Speed |
|-----------|---------|---------------|
| 100 MB | 5 GHz Wi-Fi 6 | ~80 MB/s |
| 1 GB | 5 GHz Wi-Fi 5 | ~45 MB/s |
| 10 GB | Wired LAN | ~95 MB/s |
| 100 MB | 2.4 GHz Wi-Fi | ~15 MB/s |

*Benchmarked on Pixel 8 → MacBook Pro M3. Results vary by network conditions.*

---

## 🔮 Future Extensibility (Design Only)

- **Internet relay mode** — optional TURN server for cross-network transfers
- **QR-less pairing** — automatic LAN pairing via mDNS + pre-shared token
- **Plugin system** — external storage providers (Google Drive, S3, etc.)
- **Resume transfers** — checkpoint + retry from last successful chunk

---

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

*Made with 💙 by Adwith · [@a.dwith](https://www.instagram.com/a.dwith?igsh=MXdyeXU5cDM5YW5oeQ==)*
