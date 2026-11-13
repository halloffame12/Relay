# Relay

Relay is an offline-first Android document library and reader for PDF and EPUB
files. It keeps imported documents in app-managed storage, remembers reading
progress and bookmarks, and can stream a managed document directly to another
Relay device on the same local Wi-Fi network.

## What is implemented

- Import PDF and EPUB files through the Android system picker. Relay copies the
  file into its own storage, computes SHA-256, and rejects duplicates.
- Read PDF and EPUB documents, restore the last reading position, add bookmarks,
  search and filter the library, and view storage usage. EPUB reading renders
  bounded inline raster images (PNG, JPEG, GIF); SVG and remote images are
  skipped.
- Remove Relay's managed copy without modifying the original file the user
  imported.
- Offer receive mode on one device, show a single-use QR invitation, scan it
  with the other device, then choose a Relay-managed document to send.
- Keep manual IPv4 address, TCP port, and six-digit code entry as a secondary
  troubleshooting path when scanning is unavailable.
- Approve incoming documents explicitly before any file bytes are accepted.
- Verify the declared byte count and SHA-256 on the receiving device, then
  import the verified temporary file through the same import pipeline used for
  local files.
- Persist real transfer records and states in Drift. Interrupted transfers are
  marked failed on restart and never appear resumable or complete.
- Harden untrusted boundaries: imported and EPUB metadata is stripped of control
  and bidi characters and length-bounded, transfer JSON is nesting-limited
  before decode, and corrupt settings fall back to safe defaults instead of
  crashing. After five failed manual pairing attempts the receiver rotates the
  invitation and six-digit code.

## How direct transfer works

1. On the receiving device, open **Nearby** and choose **Offer to receive**.
   Relay opens a TCP server for this foreground session and shows a QR code
   containing the current Wi-Fi IPv4 address(es), port, wire protocol version,
   session ID, and a short-lived single-use invitation token.
2. On the sending device, open **Nearby** and choose **Scan receiver’s QR code**.
   Relay requests camera access only for this scan, validates the code as Relay
   data (never as a URL), connects to the advertised IPv4 address, and completes
   a versioned `hello`/`welcome` handshake.
3. After the receiver is verified, the sender chooses one document from the
   Relay library and confirms the send. The receiver shows a blocking approval
   dialog with the document name, format, and size.
4. Only after approval does the receiver accept exactly the declared number of
   bytes into a temporary file under app-managed storage.
5. Both sides compute SHA-256. The receiver requires the declared size and hash
   to match, then imports the verified file. A duplicate is reported without
   overwriting the existing library document.
6. Terminal state is written only after import succeeds. Any interruption,
   rejection, timeout, or mismatch removes the temporary file and creates no
   library entry. The receiver then rotates the QR token and manual code for the
   next session.

The receiver also exposes an expandable **Manual connection details** panel. It
contains the IPv4 address, port, and six-digit code for the case where the camera
cannot be used. The code is single-use and is invalidated by a successful QR
connection.

Both devices must be on the same Wi-Fi network. Guest networks, access-point
isolation, VPN routing, and network firewalls may block the connection.

### Explicitly not implemented

Relay does **not** provide automatic network discovery (NSD/mDNS), Wi-Fi Direct,
Bluetooth, internet or cloud relay, accounts, background transfer reliability,
resumable transfers, or transport encryption. QR scanning and manual details are
the only pairing paths in this build; discovery remains a possible follow-up,
not a claim. The protocol is intended for two devices on a trusted local
network. The single-use invitation prevents accidental connections and replay,
but it is not a substitute for TLS. Cancelling during raw byte streaming closes
the socket, so the other device records an interrupted transfer rather than a
cancel message.

## Storage and safety

- Relay only offers documents it already manages. It does not browse or expose
  other files on the device.
- Remote names and titles are validated. Path separators, traversal, control
  characters, unsupported formats, oversized documents, and malformed checksums
  are rejected before they reach a file path or database field.
- Incoming filenames are generated locally. A remote filename is never used as
  a filesystem path.
- File bytes are streamed with bounded buffers. Only the small manifest is kept
  in memory. Transfer control frames reject JSON nested deeper than 32 levels
  before decoding.
- The receive server handles one incoming connection at a time. Five failed
  manual pairing-code attempts invalidate the current invitation; the receiver
  rotates to a new code instead of allowing unlimited guesses against a
  short-lived six-digit secret.
- Imported and EPUB-derived title, author, description and language text is
  stripped of control, bidi and BOM characters, whitespace-collapsed, and
  length-bounded before display or persistence.
- EPUB images are restricted to chapter-relative PNG, JPEG or GIF files whose
  magic bytes match, with per-image (8 MiB), per-book (24 MiB) and count (40)
  budgets. SVG, remote URLs, and mismatched or oversized images are skipped
  rather than fetched or rendered.
- Corrupt or unreadable settings entries are treated as missing and rewritten;
  out-of-range reader text scale is clamped to 0.85–1.45. A failed settings write
  is surfaced but does not escape the controller.
- QR invitations are strictly bounded and parsed as Relay data. Relay rejects
  hostnames, URL paths, user-info, ports in the authority, duplicate or unknown
  fields, non-IPv4 and link-local/multicast addresses, expired codes, and
  overlong expiry windows. Scanned text is never opened as a URL.
- Invitation tokens and manual pairing codes are single-use and short-lived
  (5 minutes by default). They rotate after expiry, use, rejection, or a
  completed transfer, and reuse or replay is rejected. The six-digit code is a
  troubleshooting fallback, not strong authentication.
- Full invitation credentials are never logged or persisted. `toString()`
  redacts the token, and transfer history contains no token or session
  credential.
- Camera permission is requested only when the scanner screen opens. The
  scanner disposes its controller with the screen and accepts only one valid
  detection to avoid duplicate connection attempts.
- After connection, the send screen displays the resolved receiver address and
  port, and the final confirmation repeats them, so an unexpected destination is
  visible before any bytes are sent.
- Abandoned temporary files are removed at startup. Partial files are never
  imported.
- Transfer history stores only local IDs, display metadata, relative managed
  names, and temporary-file names. It never stores an absolute path.
- The existing library document is never overwritten. If the same SHA-256 is
  already present, the incoming transfer completes as a duplicate and points to
  the existing document.

Default bounds are defined in `lib/features/transfers/domain/transfer_limits.dart`:

| Limit | Default |
| --- | --- |
| Maximum document | 100 MiB |
| Maximum control message | 64 KiB |
| Maximum QR invitation payload | 1,024 bytes |
| Maximum addresses in an invitation | 4 |
| Invitation lifetime | 5 min |
| Maximum invitation future window | 15 min |
| Connect / handshake timeout | 12 s |
| QR offer timeout | 2 min |
| Receiver approval timeout | 2 min |
| Verification timeout | 2 min |
| Inactivity timeout | 20 s |
| Receive connections | 1 active |

## Protocol

The wire protocol and QR invitation are documented in
[`docs/transfer-protocol.md`](docs/transfer-protocol.md). The current wire
protocol is version 2: a versioned, newline-delimited JSON control channel
followed by exact-length raw file bytes on the same TCP connection. The QR
envelope is version 1 and includes the wire protocol version, active session ID,
single-use invitation token, IPv4 address(es), port, and expiry.

## Development

Requirements: Flutter 3.41.x / Dart 3.11.x.

```powershell
flutter pub get
flutter pub run build_runner build
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Android uses the normal `INTERNET` permission for direct TCP sockets and
requests `CAMERA` only when the QR scanner opens. Camera hardware is declared
optional, so the app still installs on devices that use manual entry. Relay does
not request broad storage permissions, sets `allowBackup="false"`, and excludes
all app data from Android 12+ cloud backup and device transfer through
`res/xml/data_extraction_rules.xml`. The QR scanner uses Google ML Kit through
`mobile_scanner`; its transitive Android library merges the normal
`ACCESS_NETWORK_STATE` permission. ML Kit may send limited diagnostics and usage
data to Google even though Relay's own transfer code never sends document bytes
or invitation credentials to a cloud service. The in-app and published privacy
policies disclose that SDK telemetry and the fact that nearby transfers are not
end-to-end encrypted. This build targets Android SDK 36, where `INTERNET` also
grants local-network access. An Android 17 / target SDK 37 build would need to
declare and request the `ACCESS_LOCAL_NETWORK` runtime permission before
listening or connecting. Automatic discovery is not implemented, so no NSD/mDNS
permission or service is used.

## Release configuration

The permanent Play identity is `io.github.halloffame12.relay`. The Android
namespace and `MainActivity` package match it. The application ID is permanent
after the first Play upload.

Release signing is supplied by ignored local files: `android/key.properties`
and the upload keystore outside the repository. Release builds fail if signing
is missing. Debug signing cannot be combined with a real upload key or used
with the production application ID.

```powershell
# Production upload build (requires android/key.properties and the keystore).
flutter build appbundle --release --no-pub

# Local QA only, and only when no production key.properties is present.
# The override is rejected when a real upload key is configured.
flutter build appbundle --release --no-pub `
  --android-project-arg=relay.applicationId=io.github.halloffame12.relay.qa `
  --android-project-arg=relay.allowDebugReleaseSigning=true
```

Never upload the QA variant. Do not commit the keystore, `key.properties`, or
their passwords. See [`docs/release-readiness.md`](docs/release-readiness.md),
[`docs/play-policy-audit.md`](docs/play-policy-audit.md),
[`docs/privacy-policy.md`](docs/privacy-policy.md),
[`docs/data-safety.md`](docs/data-safety.md), and
[`docs/play-listing.md`](docs/play-listing.md).

## Branding and store assets

Relay uses a forest-ink, warm-paper, terracotta and sage palette. The mark is a
pair of paper pages with a relay arrow. The reproducible generator is
`tool/generate_brand_assets.py`; its palette and paths are recorded in
`store/brand-assets.json`.

- Play icon: `store/icon-512.png` (512 x 512, RGB, no alpha).
- Feature graphic: `store/feature-graphic-1024x500.png` (1024 x 500, RGB).
- Phone screenshots: `store/screenshots/` at 1080 x 1920, RGB.
- Tablet screenshots: `store/screenshots/` at 1340 x 800, RGB.
- Original screenshot sample: `store/sample/the-quiet-orchard.epub`.
- Android adaptive, monochrome, round and legacy icons; Android 12+ day/night
  splash styles; legacy launch background; iOS/macOS/Windows/web icons.

The launcher icon was visually checked in App info on Android 17 and Android 11.
Live QR and policy-dialog verification captures are local-only and gitignored
under `store/screenshots/internal/`; do not upload them. See
[`docs/play-listing.md`](docs/play-listing.md) for the recommended upload set.

## Public repository and privacy policy

- Source: <https://github.com/halloffame12/Relay>
- Privacy policy (effective 27 October 2026):
  <https://github.com/halloffame12/Relay/blob/main/docs/privacy-policy.md>
- Policy contact: public GitHub Issues at
  <https://github.com/halloffame12/Relay/issues> or the developer email on the
  Play listing. Do not post documents or invitation codes in a public issue.

The repository intentionally excludes `android/key.properties`, keystores,
`local.properties`, build output and local-only verification captures. The static
HTML in `docs/` is prepared for a future dedicated GitHub Pages deployment. The
account-level Pages custom domain currently intercepts the project path, so that
deployment is disabled and is not the public policy URL.

## Verification status

Automated tests exercise protocol v2 validation, QR invitation parsing and
bounds, single-use/replay/expiry/rotation rejection, multi-address connection
attempts, scanner duplicate-detection, URL rejection, camera-denial retry,
connected-send widget selection, manual fallback, transfer persistence and
state transitions, the version-1-to-version-2 Drift migration, loopback
PDF/EPUB transfers, rejection, duplicate handling, large streaming, checksum
and size mismatches, interrupted streams, connection failure, timeout,
cancellation, startup cleanup, screen layouts, and existing reader
regressions. Hardening coverage includes corrupt settings and failed settings
writes, mid-copy import cancellation, hostile metadata, over-nested transfer
JSON, bounded EPUB images (including SVG/remote/GIF-mismatch rejection), and
pairing-code rotation after five failed manual attempts.

The final release candidate passes `dart format lib test` (117 files, 0
changed), `flutter analyze --no-pub` (no issues), and
`flutter test --no-pub` (129 tests). The production upload-signed AAB and a local
release APK build successfully with no QA override or debug-signing flag.
Automatic NSD/mDNS discovery was evaluated but deliberately deferred; the QR and
manual paths do not depend on it.

### Release bundle verification (1 November 2026)

The production upload-signed AAB and local test APK were rebuilt from the
hardened working tree with no QA override or debug-signing flag:

- AAB: `build/app/outputs/bundle/release/app-release.aab`, 63,001,502 bytes
  (60.08 MiB), SHA-256
  `B2ADE2B061F50491EFFEA2C5962A4FA3417AF1027B93CD0FA0CDB9B72A3EAC96`
- Local test APK: `build/app/outputs/flutter-apk/app-release.apk`, 84,360,067
  bytes (80.45 MiB), SHA-256
  `6621DD08129ADE857A2B33028700689465BEE0A1C7B0444F9A1B073E446F2BF2`
- `io.github.halloffame12.relay`, version `0.9.0` (`versionCode 1`), min SDK 24,
  target SDK 36, ABIs `arm64-v8a`, `armeabi-v7a`, `x86_64`
- `relay-upload` upload certificate, SHA-256
  `BB:0A:17:52:1A:CA:41:B7:DD:EC:6E:85:8B:2C:C8:31:16:51:8F:C7:98:72:E1:B1:88:36:FC:EA:B8:74:5C:95`

`bundletool validate` exits 0, `jarsigner -verify -certs` exits 0 (with the
expected JarInputStream entry warnings), and the APK verifies with APK Signature
Scheme v2 using the same upload certificate. Manifest inspection still shows
`INTERNET`, optional `CAMERA`, and transitive normal `ACCESS_NETWORK_STATE`, with
no storage, location or other broad permissions. The bundle contains no
`key.properties`, keystore, `local.properties`, debug keystore, or
password/property strings.

### Final two-physical-device release verification (1 November 2026)

The final upload-signed APK was installed on two physical devices on the same
Wi-Fi network (`Airtel_kris_3077`):

- sender: A009P, Android 16 / API 36, 1080 x 2344
- receiver: V2575, Android 16 / API 36, 720 x 1600

The sender initially had Wi-Fi disabled, so the first manual attempt failed with
the expected unreachable-receiver message. After enabling Wi-Fi, the sender
obtained `192.168.1.2/24` and the receiver was `192.168.1.6/24`. A fresh
single-use code was then used.

- **Successful transfer:** the sender streamed a 24.6 MB PDF (`machine
  learning`) over direct TCP via manual address/port/code entry. The receiver
  displayed the blocking approval dialog before accepting bytes. After approval
  it imported the file; the library then reported 1 document and 24.6 MB stored,
  and document details showed 14 pages and “Received from Relay device 1687 over
  Wi-Fi”. The sender recorded a completed transfer to Relay device C5DB.
- **Duplicate handling:** repeating the send made the receiver report
  `Verified “machine learning”. It was already in your library.`; the sender
  recorded “The receiving device already had this document.” No existing
  document was overwritten.
- **Explicit rejection:** another send was declined on the receiver. The receiver
  reported `You declined “machine learning”.`; the sender recorded a cancelled
  transfer with “The receiving device declined this transfer.” No library entry
  was added.

This is a real two-physical-device release-build test of approval, checksum
verification, duplicate detection and rejection. It used manual pairing, not the
camera. A direct camera-to-screen QR scan is still unverified, and the build was
sideloaded rather than installed from Play.

Store captures remain the 1080 x 1920 phone and 1340 x 800 tablet RGB images from
the 27 October pass; the hardening changes were behavioral and did not redesign
the captured screens. Live QR and policy-dialog captures remain local-only and
gitignored under `store/screenshots/internal/`.

This verifies the local artifact and the two-device manual path only. It was not
uploaded to Play, installed from Play, or published. See
[`docs/release-readiness.md`](docs/release-readiness.md) and
[`docs/play-policy-audit.md`](docs/play-policy-audit.md) for the remaining human
blockers and verification gaps.

### Earlier two-device physical result (pre-branding build)

This section records an earlier build on two physical devices on the same
router: an A009P sender (Android 16, SDK 36) and an RMP2105 receiver (Android 11,
SDK 30). It is protocol history, not a test of the final upload-signed artifact.

- **QR-initiated connection.** The sender scanned a valid Relay invitation,
  reached a verified connection, chose the 2,214-byte EPUB, and the receiver
  showed a blocking "Receive this document?" prompt with the title, format,
  and size. After approval the receiver imported the document. The managed
  copies matched at SHA-256
  `506fe6410202a4751ba4aebfbbe4a9139f5d3692b15272853b34c6d1413d3de3`,
  and the transfer history and temporary-file cleanup were checked.
- **Manual fallback.** The sender entered the receiver's address, port, and
  code, chose the 49,430-byte PDF, and the receiver showed the same blocking
  approval prompt. After approval the managed copies matched at SHA-256
  `b63cce79e0a819df68bed4995bd42c1971a7c7efd46bc4b053d1d546de878ed7`.
  History and cleanup were checked again.
- **Rejection and duplicate.** The receiver declined a third document; no
  bytes were imported and the sender recorded a cancelled entry. Sending the
  EPUB again was verified as already present and did not overwrite the
  existing library copy.
- **Invitation lifecycle.** A replaced manual code was rejected while the
  current invitation stayed valid. Stopping receive mode invalidated the
  session; a later attempt failed and was recorded. The receiver rotated its
  QR token and manual code after completion, rejection, and duplicate
  handling. Automated tests cover expiry, replay, and stopped-session
  rejection as well. Transfer history contains no token or session
  credential.
- **Camera denial.** With the receiver's camera permission revoked, the
  scanner showed the Settings guidance and manual fallback after the first
  denial. With the permission permanently denied (`USER_FIXED`), the same
  single panel remained after "Try camera again", and "Use manual connection"
  returned to Nearby.

One hardware caveat remains: the sender's camera was aimed at a monitor
showing the receiver's QR image, not at the receiver's own screen. The scanned
payload, connection, approval, transfer, and checksum were real, but a direct
camera-to-phone-screen line-of-sight scan has not been demonstrated.
Automated tests use an injected scanner view, not a real camera. Do not infer
physical camera aiming or NSD discovery from these results.

### Earlier Phase 3 result

The Phase 3 build was verified on two physical Android 16 phones on the same
Wi-Fi network: an A009P sender and a V2575 receiver. The sender's route to the
receiver used `wlan0`, and the receiver listened on `192.168.1.6`. Two real
manual-code transfers completed:

- A unique 2,214-byte EPUB. Both rows reached `completed` with 2,214 of 2,214
  bytes. The sender's managed file and the receiver's newly imported file had
  the same SHA-256
  (`506fe6410202a4751ba4aebfbbe4a9139f5d3692b15272853b34c6d1413d3de3`),
  and the receiver opened it in the EPUB reader.
- A 48.3 KB PDF. Both rows reached `completed` with 49,430 of 49,430 bytes.
  The two managed copies had the same SHA-256
  (`b63cce79e0a819df68bed4995bd42c1971a7c7efd46bc4b053d1d546de878ed7`),
  and the receiver opened it in the PDF reader.

The receiver ended with exactly two documents, one for each transfer. Both
histories survived a force-stop and restart, receive mode did not restart
automatically, and no transfer temporary file remained.

An earlier build was also exercised on an Android 17 (API 37) emulator through
`127.0.0.1`, where the 2,153-byte duplicate path was verified instead of
overwriting the existing document.

The physical tests verify one router and network configuration. Guest
networks, access-point isolation, VPN routing, and firewalls can still block
other client-to-client connections. When testing manually, keep both Relay
screens open, use the address shown on the receiver, and confirm the received
document opens in the reader.
