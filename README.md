# LocalSend AirGap

A modification of [LocalSend](https://github.com/localsend/localsend) that enables file transfers without Wi-Fi, Bluetooth, or an internet connection, using animated QR codes.

## How It Works

1. Files are split into chunks, encoded using Base64 and JSON, and displayed as animated QR codes.
2. The receiver scans and collects frames, ignoring duplicates and recovering missed frames on subsequent cycles.
3. The original file is reconstructed, verified using SHA-256, and saved.

## Features

- Offline file transfer from desktop to Android
- Support for arbitrary file types
- Missing-frame recovery and integrity verification
- Transfer progress and performance statistics

## Building and Running

**Prerequisites**
- Flutter 3.41.9 ([FVM](https://fvm.app/) recommended)
- [Rust](https://rustup.rs/)
- Android SDK and Java 17 for Android builds
- Required Flutter and Linux development dependencies

**Clone and install dependencies**

```bash
git clone https://github.com/AbrasiveSquid/localsend_airgap_qr.git
cd localsend_airgap_qr
fvm install
cd app
fvm flutter pub get
```

**Linux (sender)**

```bash
fvm flutter run -d linux
```

Or build a release version:

```bash
fvm flutter build linux
```

**Android (receiver)**

Connect an Android device with USB debugging enabled, then run:

```bash
fvm flutter devices
fvm flutter run
```

Alternatively, build an APK:

```bash
fvm flutter build apk
```

The APK will be generated at `app/build/app/outputs/flutter-apk/app-release.apk`.

**Current limitations**

- AirGap transfers have been tested from Linux to Android.
- Only one file can be transferred at a time.
- Transfers are one-way and require the modified application on both devices.
- Transfer speeds are limited by QR display and camera scanning performance.

## How to Use

1. Launch LocalSend AirGap on Linux and Android.
2. On Linux, select a file and click **Send via AirGap**.
3. On Android, select **Receive via AirGap** and point your camera at the animated QR codes.
4. Keep scanning until all frames have been received.
5. Once SHA-256 verification succeeds, choose where to save the file.

No Wi-Fi, Bluetooth, or internet connection is required.

## Performance

Using 1,000-byte chunks and 300 ms frame intervals, AirGap achieved an average measured throughput of **2.83 KB/s**.

See [BENCHMARKS.md](BENCHMARKS.md) for results and methodology.

## Implementation

| File | Purpose |
|---|---|
| [airgap_gen.dart](app/lib/util/airgap/airgap_gen.dart) | File chunking, Base64, JSON, SHA-256 |
| [airgap_send_page.dart](app/lib/pages/airgap/airgap_send_page.dart) | QR generation and animation |
| [airgap_receive_page.dart](app/lib/pages/airgap/airgap_receive_page.dart) | Camera scanning, reconstruction, verification, saving |
| [send_tab.dart](app/lib/pages/tabs/send_tab.dart) | AirGap sender integration |
| [receive_tab.dart](app/lib/pages/tabs/receive_tab.dart) | AirGap receiver integration |

## Attribution

Based on the open-source [LocalSend](https://github.com/localsend/localsend) project. 
