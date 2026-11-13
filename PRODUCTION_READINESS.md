# Relay production readiness

Last updated: 2026-11-13

## Scope

Relay is a Flutter app that reads PDF/EPUB files offline and shares them
between two devices by QR code, with no typed addresses, ports, hostnames or
pairing codes. The new share subsystem lives in `lib/features/share/` and runs
alongside the older TCP `RelayTransferService`, which is still present and
still tested.

## Current release artifacts

| Artifact | Path | SHA-256 |
| --- | --- | --- |
| Android App Bundle | `build/app/outputs/bundle/release/app-release.aab` | `121D39677EB42DB5100049BA4D53A82BE70382552FD17E0D86961041D63A2D50` |
| Android APK | `build/app/outputs/flutter-apk/app-release.apk` | `A2D3FED1F2F612A16AE9B28EE6C58C21FDC35A11AE326F32A70776492FEE5AF2` |
| Play icon | `store/icon-512.png` | derived from `store/brand/relay-icon.png` |
| Feature graphic | `store/feature-graphic-1024x500.png` | derived from `store/brand/relay-icon.png` |

- App id: `io.github.halloffame12.relay`
- Version: `0.9.0+1`
- Min SDK 24, target SDK 36
- Upload certificate SHA-256: `BB:0A:17:52:1A:CA:41:B7:DD:EC:6E:85:8B:2C:C8:31:16:51:8F:C7:98:72:E1:B1:88:36:FC:EA:B8:74:5C:95`
- APK signature: v2 scheme, single signer.

## Verification performed

```text
dart format lib test          -> 0 files changed
flutter analyze --no-pub     -> No issues found!
flutter test --no-pub        -> +202, all passed
npm test (infra/signaling)   -> 6/6 passed
```

The 202 tests include the legacy library/import/reader/transfer suite plus
share domain, frame codec, offer, protocol, service and widget coverage. The
share service tests drive a full sender/receiver session through an in-memory
duplex link and a fake injectable `WebRtcConnector`, so the session protocol
runs without networking, WebRTC, or TURN.

## What is complete

### Cross-network share subsystem (`lib/features/share/`)
- Sender-owned sessions: the sender selects documents, creates a session, and
  shows a QR. The receiver scans and approves before any bytes are written.
- QR envelope v2 (`share_invitation.dart`): strict validation, ephemeral
  token, short expiry (max 10 minutes, capped even if the payload claims later),
  size limits, control-character rejection, duplicate-field rejection, LAN
  hints limited to three, no token in `toString()`.
- Shared framing (`share_frame.dart`): `[type:1][len:4 BE][payload]` over
  TCP and WebRTC data channels. The decoder is a `StreamController`-based
  implementation that forwards pause/resume/cancel to the source. This fixes a
  real production hang where cancelling an `async*` generator left the inner
  subscription open and made `ShareInbox.dispose()` and link close hang after
  the last frame.
- Shared protocol (`share_protocol.dart`): hello, welcome, offer, accept,
  reject, file start/end, per-file result, batch complete, cancel, error.
  Strict field validation and bounds on indexes, counters and message codes.
- Batch bounds (`share_offer.dart`): 20 files / 200 MiB total, per-file 100
  MiB inherited from `TransferLimits`.
- `ShareService` orchestration: LAN-first connection selection, WebRTC direct
  fallback, TURN-only-when-issued, SHA-256 verification per file, bounded
  memory streaming, progress/speed/ETA, cancellation, retry, duplicate
  handling, storage checks, cleanup of `.part` files, never auto-accepts.
- Signaling client (`signaling_client.dart`): WebSocket room client, `joined`
  carries the ICE list, validates every relayed frame, closes on malformed
  data.
- `WebRtcConnector` is injectable, so session logic is unit-testable without
  a TURN deployment.
- UI: `ShareHomeScreen`, `ShareSendScreen`, `ShareReceiveScreen`,
  `ShareScannerScreen`, plus brand and progress widgets. Routes repointed:
  `/nearby` -> `ShareHomeScreen`, `/nearby/send` -> `ShareSendScreen`,
  `/nearby/receive` -> `ShareReceiveScreen`, `/nearby/scan` ->
  `ShareScannerScreen`. Legacy files remain and are still tested.

### Branding
- `store/brand/relay-icon.png` is the single official source. All launcher,
  adaptive, monochrome, splash, web, iOS, macOS, Windows and store artwork is
  derived from it by `tool/generate_brand_assets.py`, which now records the
  source path and SHA-256 in `store/brand-assets.json`.
- `RelayBrandIcon` (`lib/core/widgets/relay_brand_icon.dart`) is used by
  headers, empty states, transfer panels, settings and About. `RelayWordmark`
  now shows the official mark instead of a hand-drawn one.
- Android adaptive background colour changed to the official icon background
  (`#0F0F11`); splash uses warm paper so the dark mark stays legible in both
  themes.

### Signaling reference service (`infra/signaling/`)
- Node WebSocket service with room auth, per-session ICE/TURN issuance,
  rate limits, room expiry, heartbeat, health endpoint, Dockerfile and tests.
- TURN credentials are minted per session using coturn's shared secret and
  expire quickly; none are embedded in the APK.
- README documents deployment, coturn setup, and cost model.

## Known limitations (not implemented, documented honestly)

- **Resume after drop is not implemented.** A failed transfer leaves no
  partial library record and removes `.part` files, but a dropped transfer
  must be restarted from the first byte.
- **LAN transport is plaintext.** WebRTC data channels are DTLS-encrypted;
  the legacy TCP path is not. The UI labels the path honestly and does not
  claim end-to-end encryption for LAN.
- **No deployed signaling or TURN server exists.** Cross-network, mobile-data,
  restrictive-NAT and TURN-fallback paths cannot be exercised in this
  environment. Only the LAN and injected-link paths are verified.
- **No real-device or hardware WebRTC run** has been performed. WebRTC
  behaviour is verified through the injectable connector and the in-memory
  link pair, not against a TURN deployment.
- **Data Safety:** `mobile_scanner` pulls ML Kit, so the app cannot claim
  "no data collected" unqualified. The dependency is declared and the Play
  listing must reflect it.
- **No Play Console access, legal/Data Safety sign-off, or publish
  authorisation.** Nothing has been published.

## Blockers for production release

1. Deploy and operate a signaling endpoint and a coturn TURN server, then
   rebuild with `--dart-define=RELAY_SIGNALING_URL=wss://...`.
2. Run the cross-network matrix (same Wi-Fi, different Wi-Fi, mobile data,
   symmetric NAT, corporate firewall) on at least two physical devices and
   record results.
3. Complete Play Console Data Safety, content rating, store listing and
   privacy policy review.
4. Decide on resume-after-drop scope (implement or document as out of scope).
5. Re-run `flutter test` and a release build after any signalling URL or
   infra change.

## Continuation instructions

- Work from `C:\startup\Relay`. Keep `flutter pub get` failures in mind: it
  prints a Developer Mode/symlink warning and exits 1 on Windows, but Android
  builds still succeed. Run analyze/test/build sequentially; concurrent
  `flutter` commands corrupt the engine stamp.
- Official brand source: `store/brand/relay-icon.png`. Regenerate all
  artwork with `python tool/generate_brand_assets.py`. Do not substitute a
  generated logo.
- Signalling service: `cd infra/signaling && npm install && npm start`,
  then `npm test`. Configure `TURN_*` before claiming relay fallback.
- Tests: `dart format lib test`, `flutter analyze --no-pub`,
  `flutter test --no-pub`, and `npm test` in `infra/signaling`.
- Builds: `flutter build appbundle --release --no-tree-shake-icons` and
  `flutter build apk --release --no-tree-shake-icons`.
- Do not print or commit `android/key.properties`, `*.jks` or `*.keystore`.
- Do not upload user files to cloud storage or publish without explicit
  permission.
