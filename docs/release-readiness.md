# Release readiness audit

**Audit date:** 1 November 2026

**Decision:** **PRODUCTION AAB SIGNED, VERIFIED, AND TWO-DEVICE TESTED; NOT YET
READY TO PUBLISH.** The permanent application ID, upload signing, branded assets,
privacy policy and a final release-build two-physical-device transfer check are
in place. The remaining work is Play Console account access, declarations and
legal review, owner approval, a direct camera-to-screen QR test, and an authorized
Play-installed build. This is not a claim that the app is ready for production
release.

No Play Console submission, upload or production publish was performed.

## Scope and constraints

- Repository: `C:\startup\Relay`. Public source:
  <https://github.com/halloffame12/Relay>. Build output, `android/key.properties`,
  keystores and `local.properties` remain ignored.
- The product remains local-first. No analytics SDK, ads, accounts, cloud
  storage, discovery service or developer-operated server was added.
- Direct TCP, NDJSON protocol v2, QR invitation v1, receiver approval, checksum
  verification, duplicate rejection, managed imports and the manual fallback
  were preserved. NSD/mDNS discovery remains deferred.
- The owner-supplied upload keystore is outside the repository. It was not
  copied into the project, build output or bundle, and was not regenerated. No
  password, private key or secret value was printed.
- Final release candidate: `io.github.halloffame12.relay`, version `0.9.0`
  (`versionCode 1`), min SDK 24, target SDK 36. Version was not bumped for this
  candidate.

## Readiness summary

| Area | Status | Notes |
| --- | --- | --- |
| Target API | Pass | `targetSdk 36`, `minSdk 24`. Current Play requirement is Android 16 / API 36. |
| Build and tests | Pass | Format clean (117 files), analyze clean, 129 tests pass, release AAB and APK build. |
| App Bundle structure | Pass | `bundletool validate` exits 0; signed AAB validates; native libraries present. |
| Application ID | Pass | `io.github.halloffame12.relay`; namespace and `MainActivity` package match. Permanent after the first Play upload. |
| Release signing | Pass | AAB signed by alias `relay-upload`, not the debug key. Upload certificate SHA-256 recorded below. |
| Signing secrets | Pass | No `key.properties`, keystore, `local.properties`, debug keystore, or password/property strings found in the AAB. |
| QA/debug isolation | Pass | Debug signing with the production ID is rejected; QA builds require a `.qa` or `com.example.*` ID and receive a `-qa` version suffix. |
| Permissions | Pass | `INTERNET`, optional `CAMERA`, and transitive normal `ACCESS_NETWORK_STATE`; no broad storage. Camera hardware optional. |
| Exported components | Pass | Launcher activity plus a `ProfileInstallReceiver` protected by `android.permission.DUMP`; no deep-link import bypass found. |
| Backup controls | Pass | `allowBackup=false`, full-backup disabled, and all app data excluded from Android 12+ cloud backup and device transfer. |
| Branding and splash | Pass | Adaptive, legacy, monochrome and round resources packaged; launcher appearance visually checked in App info on Android 17 and Android 11. Android 12+ day/night splash and Android 11 legacy splash verified. Themed-icon appearance was not separately exercised. |
| Privacy policy | Published; URL action | Effective 27 October 2026. Public HTTPS page is the GitHub-rendered Markdown URL. Contact: public GitHub Issues plus the Play listing email. Enter the working URL in Play Console. |
| Data safety | Draft only | Conservative draft prepared; peer-to-peer and ML Kit answers need owner/legal confirmation. |
| Play Console account/track | **Blocker / unknown** | Account type and creation date are unknown; the required testing path cannot be confirmed. |
| Store listing assets | **Available; owner review pending** | Play icon, feature graphic, seven recommended phone screenshots and four tablet screenshots are prepared. Content rating and target audience are not submitted. |
| Release-device verification | **Pass, with open gaps** | Final upload-signed APK installed on two physical Android 16 devices. Manual pairing produced a 24.6 MB PDF import after the blocking approval, the receiver verified the checksum before import, a repeat send was recognized as a duplicate without overwrite, and an explicit rejection left no library entry. Direct camera-to-screen QR scanning and a Play-installed build remain unverified. |
| Policy audit | Pass with human items | Technical review found no concrete code-level Play violation. Owner/legal/account actions remain. |

## Changes made in this audit

1. **Release signing and identity guards**
   - `android/app/build.gradle.kts` reads a local, ignored
     `android/key.properties`.
   - Release tasks fail if the application ID still starts with `com.example.`
     or no release signing is configured.
   - `-Prelay.applicationId=<id>`, `-Prelay.allowExampleApplicationId=true` and
     `-Prelay.allowDebugReleaseSigning=true` are explicit Gradle properties. The
     last two are only for non-uploadable local QA.
   - `.gitignore` ignores `android/key.properties`, `*.jks` and `*.keystore`.
2. **Backup protections**
   - Added `android:fullBackupContent="false"` and
     `android:dataExtractionRules="@xml/data_extraction_rules"`.
   - Added `android/app/src/main/res/xml/data_extraction_rules.xml`, excluding
     app data from cloud backup and device transfer.
3. **Privacy and store copy**
   - Added the in-app policy in
     `lib/features/settings/presentation/privacy_policy.dart`.
   - Settings and About disclose direct/insecure-adjacent transfer behavior and
     the Google ML Kit scanner.
   - Added `docs/privacy-policy.md`, `docs/data-safety.md`,
     `docs/play-listing.md` and `docs/play-policy-audit.md`.
4. **Transfer destination visibility**
   - The connected send panel displays the resolved receiver address and port;
     the final confirmation repeats them.
   - Widget tests assert the displayed endpoint.
5. **Public source repository**
   - Initialized Git on `main`, committed source without build output or signing
     secrets, and pushed to <https://github.com/halloffame12/Relay>.
   - Added `docs/index.html`, `docs/privacy-policy.html` and `docs/.nojekyll` for
     a future Pages deployment. The account-level custom domain currently
     intercepts the project path, so Pages is disabled. The GitHub-rendered
     Markdown page is the current public policy URL.
6. **Branding, splash and store assets (Phase 8)**
   - Replaced the default Flutter icon across Android, iOS, macOS, Windows, web
     and PWA.
   - Added adaptive, monochrome, round and legacy Android icons, the Play 512
     icon, the 1024 x 500 feature graphic, and light/dark splash marks.
   - Added Android 12+ `windowSplashScreen*` styles, night colors, legacy
     `launch_background.xml`, and the `android:roundIcon` manifest entry.
   - Rebuilt store screenshots with the original
     `store/sample/the-quiet-orchard.epub`; moved live QR and policy-dialog
     captures to the local-only, gitignored `store/screenshots/internal/`
     directory; converted upload screenshots to RGB.
   - Added `tool/generate_brand_assets.py` and `store/brand-assets.json` for
     reproducible artwork.
7. **Policy and polish**
   - Updated the in-app and published policy to effective 27 October 2026 with a
     concrete public contact channel and a warning not to post documents or
     invitation codes.
   - Cleared stale manual address/port/pairing-code fields when a new share
     starts, so a spent single-use code is not reused.
   - Added a button label and accessibility tap action to the icon-only
     "Share locally" control.
8. **Final artifact**
   - Rebuilt the upload-signed AAB and local test APK after the branding,
     policy and accessibility changes.
   - Verified the final artifact and repeated a release-build manual transfer and
     duplicate check.
9. **Reliability and security hardening (31 October–1 November 2026)**
   - **Settings resilience:** corrupt, mistyped or unreadable preference values
     are treated as missing/default instead of crashing startup. Reader text
     scale is clamped to 0.85–1.45; a failed preference write is reported but
     does not escape `SettingsController`.
   - **Import cancellation:** a mid-copy `DocumentFileErrorCode.cancelled` now
     maps to `ImportCancelledException`, so an intentional cancellation is not
     reported as a generic import failure.
   - **Streaming SHA-256:** replaced the completer/error-rethrow wrapper in
     `LocalDocumentFileStore._sha256` with a single
     `sha256.bind(file.openRead()).first` pipeline. This removes an unhandled
     asynchronous error path while preserving size and checksum checks.
   - **Untrusted display text:** new `lib/core/utils/untrusted_text.dart` strips
     control, bidi and BOM characters, collapses whitespace, and caps
     title/author/description/language/block lengths. It is applied to imported
     metadata and EPUB parsing output.
   - **JSON nesting guard:** transfer control JSON is rejected at more than 32
     nesting levels before `jsonDecode`; brackets inside strings are not counted.
   - **EPUB images:** EPUB blocks can now carry bounded raster images. Only
     chapter-relative PNG, JPEG and GIF files with matching magic bytes are
     accepted, with 8 MiB per image, 24 MiB per book and 40-image limits. SVG,
     remote URLs, mismatches and over-budget images are skipped. The reader
     renders the bounded bytes with `Image.memory`; word counts ignore images.
   - **Pairing brute-force cap:** the receiver counts failed manual pairing
     attempts and rotates the invitation and six-digit code after five failures.
     The sender maps `pairing_locked` to a clear “too many incorrect attempts”
     message.
   - **Tests:** added or extended coverage for each change, including a
     self-contained ZIP EPUB fixture (PNG, SVG, GIF-mismatch and remote images),
     hostile metadata, corrupt settings, mid-copy cancellation, over-nested JSON
     and a five-failure pairing lockout integration test.

The hardening pass did not change the invitation envelope, checksum algorithm,
receiver-approval requirement, managed-file boundary or transfer state machine.
It did change transfer-frame validation and pairing-attempt behavior.

## Verification performed

Commands were run from `C:\startup\Relay` on 1 November 2026. The local signing
configuration was read by Gradle and `keytool`; no password, private key or
secret value was printed.

| Check | Result |
| --- | --- |
| `dart format lib test` | 117 files checked, 0 changed. |
| `flutter analyze --no-pub` | No issues found. |
| `flutter test --no-pub --reporter compact` | 129 tests passed. |
| `flutter build appbundle --release --no-pub` | Succeeded with no QA override or debug-signing flag. |
| `flutter build apk --release --no-pub` | Succeeded; local sideload/test artifact only. |
| `bundletool validate --bundle app-release.aab` | Exit 0; base module and native libraries present. |
| Manifest inspection | Package, version, SDK, permissions and exported components checked. |
| `keytool -printcert -jarfile app-release.aab` | Upload certificate; no Android Debug certificate. |
| `jarsigner -verify -certs app-release.aab` | Exit 0. Warnings about JarInputStream entry handling and the self-signed upload certificate are expected. |
| APK `apksigner verify --print-certs` | APK Signature Scheme v2 verifies; same upload certificate. |
| Embedded-file check | No `key.properties`, `.jks`, `.keystore`, `local.properties`, `debug.keystore`, or password/property strings found. |
| Policy screen | Earlier release APK showed the effective 27 October 2026 policy, the GitHub Issues URL and Play-email contact wording; policy content was not changed in the hardening pass. |
| Camera denial / manual fallback | Earlier release APK on emulator showed denial guidance and usable manual address/port/code entry; not re-exercised in the two-device run. |
| Two-device successful transfer | A009P sender to V2575 receiver, both Android 16 / API 36, manual TCP pairing. Receiver showed blocking approval, imported the 24.6 MB PDF after verifying size/SHA-256, and library/details showed the document. |
| Two-device duplicate check | Repeat send reported “Verified … already in your library” on the receiver and “already had this document” on the sender, with no overwrite. |
| Two-device rejection check | Receiver reported “You declined …”; sender recorded a cancelled transfer; no library entry was added. |
| Share accessibility | "Share locally" exposes a clickable labeled action; a new share clears prior manual connection fields. |
| Launcher icon | Branded icon visible in Android 17 and Android 11 App info. |
| Screenshot set | Phone captures 1080 x 1920 and tablet captures 1340 x 800, RGB; original sample content; no live token in upload assets. |

### Final production artifact

- **AAB path:** `build/app/outputs/bundle/release/app-release.aab`
- **AAB size:** 63,001,502 bytes (60.08 MiB)
- **AAB SHA-256:**
  `B2ADE2B061F50491EFFEA2C5962A4FA3417AF1027B93CD0FA0CDB9B72A3EAC96`
- **Local test APK:** `build/app/outputs/flutter-apk/app-release.apk`
- **APK size:** 84,360,067 bytes (80.45 MiB)
- **APK SHA-256:**
  `6621DD08129ADE857A2B33028700689465BEE0A1C7B0444F9A1B073E446F2BF2`
- **Package:** `io.github.halloffame12.relay`
- **Version:** `0.9.0` (`versionCode 1`)
- **SDK levels:** min 24, target 36
- **Native ABIs:** `arm64-v8a`, `armeabi-v7a`, `x86_64`
- **Key alias:** `relay-upload`
- **Signing certificate:** owner-supplied upload certificate, not
  `CN=Android Debug`
- **Certificate SHA-256:**
  `BB:0A:17:52:1A:CA:41:B7:DD:EC:6E:85:8B:2C:C8:31:16:51:8F:C7:98:72:E1:B1:88:36:FC:EA:B8:74:5C:95`
- **Certificate key/signature:** 4096-bit RSA, SHA384withRSA
- **Local signing location:** `%USERPROFILE%\RelayKeys\relay-upload.jks`,
  outside the repository. `android/key.properties` is ignored and was not
  committed.
- **Play App Signing:** not enrolled or recorded. The certificate above is the
  upload certificate, not the Play-distributed app-signing certificate.

The AAB is upload-signed and structurally valid. This verifies the local bundle
only; it does not verify a Play-installed build.

### Release-build device verification (1 November 2026)

- **Sender:** A009P, Android 16 / API 36, 1080 x 2344. Upload-signed APK installed
  over the existing app. Wi-Fi was initially disabled and the device was on
  mobile data.
- **Receiver:** V2575, Android 16 / API 36, 720 x 1600. Upload-signed APK installed
  fresh. Connected to `Airtel_kris_3077` with address `192.168.1.6/24`.
- **Network correction:** the first send from the mobile-data sender failed with
  the expected “could not reach the receiving device” message and created a
  failed sender record. Wi-Fi was enabled; the sender obtained
  `192.168.1.2/24`, and the manual path was retried with a fresh single-use code.
- **Successful transfer:** the sender entered the receiver address
  (`192.168.1.6`), TCP port (`33219`) and a fresh six-digit code, selected the
  24.6 MB PDF `machine learning`, and confirmed the destination. The receiver
  showed the blocking “Receive this document?” prompt before accepting bytes.
  After approval it imported the file, verified every byte and the SHA-256, and
  the library reported 1 document and 24.6 MB stored. Document details showed 14
  pages and “Received from Relay device 1687 over Wi-Fi”. The sender recorded a
  completed transfer to Relay device C5DB.
- **Duplicate handling:** repeating the send made the receiver report
  `Verified “machine learning”. It was already in your library.` The sender
  recorded “The receiving device already had this document.” The existing
  document was not overwritten.
- **Explicit rejection:** a further send was declined on the receiver. The
  receiver reported `You declined “machine learning”.` The sender recorded a
  cancelled transfer with “The receiving device declined this transfer.” No
  library entry was added.
- **What was not tested:** this run used manual pairing. A direct
  camera-to-screen QR scan was not performed; automated tests inject a scanner
  view. The APK was sideloaded, not installed from Play.
- **Screenshots:** store captures remain from the 27 October pass (1080 x 1920
  phone, 1340 x 800 tablet, RGB). The hardening changes were behavioral and did
  not redesign the captured screens.

### Earlier two-device physical tests

The Phase 4 and Phase 3 records in `README.md` describe earlier builds tested on
two physical devices. Those runs verified QR/manual transfers, rejection,
duplicate handling, invitation rotation, cleanup and camera-denial recovery.
They remain useful protocol history, but they are **not** tests of the final
upload-signed artifact.

One hardware caveat remains from those runs: the camera scanned a QR image on a
monitor, not the receiver's own screen. A direct camera-to-phone-screen
line-of-sight scan has not been demonstrated. Automated tests inject a scanner
view, not a real camera. Do not infer physical camera aiming or NSD discovery
from the existing results.

## Security and privacy findings

### Passed or fixed

- **No debug logging or secrets:** No `print`, `debugPrint`, developer logging or
  cloud API usage was found in app code. Invitation tokens are redacted from
  `TransferInvitation.toString()`, history and logs.
- **QR input is data:** The scanner never opens scanned text as a URL. Hostname
  and path fields are not accepted; the parser validates the envelope and IPv4
  addresses.
- **Invitation lifecycle:** Single-use token consumption, replay rejection,
  expiry, rotation and stopped-session rejection are covered by tests and prior
  physical runs.
- **Approval and integrity:** The receiver must approve before file bytes are
  accepted. Size and SHA-256 are verified; duplicates are rejected; temporary
  files are cleaned up. The final two-device run repeated approval, duplicate
  handling and explicit rejection.
- **Managed-file boundary:** The receiver imports into app-managed storage with a
  generated internal filename. User-supplied filenames are not used as paths.
- **Exported surface:** `MainActivity` is exported only as the launcher activity
  and has no permission. `ProfileInstallReceiver` is exported but protected by
  `android.permission.DUMP`. ML Kit, CameraX, AndroidX Startup and
  data-transport components are not exported.
- **Permissions:** No storage, location, contacts, microphone, SMS, call-log or
  photos permission. Camera denial has a manual fallback.
- **Backup:** Cloud backup and Android 12+ device transfer are disabled and
  excluded by rules.
- **Release flags:** `android:debuggable` and `android:testOnly` are absent.
- **No release secrets in the bundle:** Confirmed by entry and string checks; the
  only `META-INF` entries are the public signature block and manifest.
- **Accessibility:** The icon-only share control now has a labeled accessibility
  action.
- **Single-use form state:** A new share clears the prior manual connection
  values instead of presenting an expired code as if it were reusable.
- **Settings cannot crash startup:** Corrupt or mistyped preference entries fall
  back to defaults, non-finite/out-of-range text scale is clamped, and a failed
  preference write is contained by the settings controller.
- **Untrusted metadata is bounded:** Imported and EPUB-derived display text is
  stripped of control/bidi/BOM characters and length-capped before persistence
  or rendering.
- **Parser resource guards:** Transfer JSON deeper than 32 levels is rejected
  before decode. EPUB images are limited to verified chapter-relative raster
  files with per-image, per-book and count budgets; SVG and remote images are not
  loaded.
- **Pairing attempt cap:** Five failed manual codes invalidate the current
  invitation and rotate the code. This is a per-invitation cap, not a global
  network rate limit.
- **Async hashing path:** The managed-file SHA-256 pipeline now uses a single
  stream binding instead of a completer with a rethrow path, removing an
  unhandled asynchronous error. Mid-copy import cancellation maps to a dedicated
  cancellation result.

### Accepted risks or disclosures

- **No transport encryption:** Nearby uses direct TCP without Relay-specific
  encryption. A network observer may see document bytes. This is disclosed in
  the in-app policy, privacy policy, Data safety draft and store copy. The send
  screen shows the destination address and port.
- **No cleartext-traffic shortcut:** Android's cleartext-traffic policy applies to
  HTTP stacks, not Relay's raw TCP socket, so adding a false setting would not
  secure or block the transfer. ML Kit uses its own HTTPS transport. The direct
  transfer remains unencrypted and is described as such.
- **Public unicast IPv4 is allowed:** The QR invitation can specify a globally
  routable address because some local networks use one. Scanning is therefore a
  trust action; Relay does not claim that every invitation is a private LAN
  address.
- **No app-level encryption at rest:** Documents and the Drift database rely on
  Android's app sandbox and device storage encryption, not a Relay-specific
  encrypted container. This is not hidden, but it is not separately disclosed in
  the store listing.
- **No `FLAG_SECURE`:** The Android recents thumbnail may show the last document
  page. Adding `FLAG_SECURE` would block screenshots and was not requested; this
  is a product/privacy decision.
- **ML Kit telemetry:** `mobile_scanner 7.4.2` bundles Google ML Kit barcode
  scanning, which may send diagnostics, usage data, device information and
  per-installation identifiers to Google. Relay itself has no developer
  analytics, but the app must not claim "no analytics" without the ML Kit
  qualification. This is disclosed in the in-app policy and
  `docs/data-safety.md`.
- **Data safety ambiguity:** The conservative draft treats the user-initiated
  peer-to-peer file transfer as **Files and docs: collected, optional, app
  functionality, not shared, not encrypted in transit**. It treats ML Kit data as
  collected and, conservatively, **shared with Google**. The Play Console owner
  or legal adviser must confirm both before submission.
- **Direct camera-to-screen scan still open:** Prior physical tests scanned a QR
  image displayed on a monitor. The final two-device run used manual entry. A
  line-of-sight scan from the sender's camera to the receiver's own screen has
  not been demonstrated.
- **Play-installed build still open:** The final two-device run used a sideloaded
  upload-signed APK. No build has been installed from Play, and the
  Play-distributed signing certificate is not yet known.
- **EPUB resource limits:** The EPUB container is still read fully into memory.
  Extracted raster images are bounded (8 MiB each, 24 MiB per book, 40 images)
  and are not lazily decoded; SVG and remote image sources are skipped. Text
  blocks are capped at 50,000 characters, so pathological markup is truncated
  rather than rendered in full. Very large or image-heavy EPUBs may be slower.
- **Text-sanitization trade-off:** Bidi override/isolate controls in imported
  text are stripped to prevent UI spoofing. Normal Arabic/Hebrew text is
  preserved (ZWNJ/ZWJ are retained), but unusually crafted mixed-direction
  formatting may render differently.
- **Themed-icon appearance not exercised:** Round/monochrome resources are
  packaged, but the themed-icon launcher appearance was not separately visually
  verified.
- **Dependency maintenance:** Direct dependencies are current enough to build and
  test, but newer versions are available. No blind upgrade was performed.
  `drift_flutter 0.3.1` still pulls EOL `sqlite3_flutter_libs` compatibility
  shims; the bundle includes `libsqlite3.so` and no SQLCipher native library.
- **License review:** Direct dependencies use MIT or BSD-3-Clause-style licenses
  in their bundled `LICENSE` files. This was not a full transitive license scan.
  Native PDFium and ML Kit are subject to their own terms; the in-app open-source
  licenses page and `docs/privacy-policy.md` mention them. Run a full license
  scanner if the owner requires a formal audit.

## Google Play requirements

- **Target API:** The bundle targets Android 16 / API 36, satisfying the current
  requirement for new apps and updates. An Android 17 / target SDK 37 build would
  need the `ACCESS_LOCAL_NETWORK` runtime permission and a new permission flow;
  that was not added because the app targets 36.
- **Application ID and signing:** The permanent package is
  `io.github.halloffame12.relay`. The local AAB is signed with the owner's upload
  key. Play App Signing enrollment and the Play-distributed certificate are still
  Play Console actions.
- **Privacy policy:** The policy is published at
  <https://github.com/halloffame12/Relay/blob/main/docs/privacy-policy.md>,
  effective 27 October 2026, with public GitHub Issues plus the Play listing email
  as contact. Enter that URL in Play Console. A dedicated domain is preferable;
  the account-level GitHub Pages custom domain currently intercepts the project
  path, so the Pages deployment is disabled rather than exposing a wrong page.
- **Data safety:** A draft is ready; the final declaration must match the build
  and policy and be signed off by the account owner/legal adviser.
- **Testing path:** Personal developer accounts created after 13 November 2023
  currently need closed testing with at least 12 testers opted in continuously
  for 14 days before production access. Organization accounts differ. The account
  type and creation date are unknown, so this path is not confirmed.
- **Store listing:** Branded icon, feature graphic, phone/tablet screenshots and
  copy are available. Category, ads/IAP declarations, content rating, target
  audience, app access instructions, contact email and final listing approval
  are not submitted.
- **No unsupported claims:** The listing draft does not claim Wi-Fi Direct,
  Bluetooth, automatic discovery, cloud sync, transport encryption, background
  transfer, direct camera QR, or a Play-installed final build. The completed
  two-device manual PDF test is recorded in this audit.

## Blockers and human actions

### Hard blockers before any Play upload

1. **Enter the published privacy-policy URL in Play Console.** The working public
   HTTPS page is
   <https://github.com/halloffame12/Relay/blob/main/docs/privacy-policy.md>. A
   dedicated domain can replace it later, only after the URL is verified.
2. **Provide the Play developer contact email and developer identity.** The policy
   points to the Play listing email as one contact option; no address, company
   name or phone number was invented.
3. **Complete Data safety and content rating.** Confirm the peer-to-peer Files and
   docs treatment and the ML Kit shared/collected answers. Do not submit a "no
   data collected" declaration while ML Kit is bundled.
4. **Review the unencrypted-transfer and ML Kit diagnostic disclosures.** Confirm
   the final wording against the build, privacy policy and Data safety answers.
5. **Confirm the Play Console account type and testing path.** Determine whether
   the 12-tester/14-day closed-testing requirement applies before production.
6. **Review and approve the store assets and copy.** Play icon, feature graphic,
   seven recommended phone screenshots, four tablet screenshots, title and
   descriptions are available in `store/` and this document set.
7. **Authorize submission.** Do not upload or publish until the owner explicitly
   authorizes the account, track and build.

### Verification gaps before calling the release fully tested

1. Repeat an **EPUB** transfer on two physical devices. The final hardware run
   used a PDF; EPUB is covered by loopback integration tests and the reader test
   suite, but the final two-device hardware path was not repeated with EPUB.
2. Perform a direct **camera-to-phone-screen** QR scan with the sender's camera
   aimed at the receiver's screen. The earlier scan used a monitor image and the
   final two-device run used manual entry. Treat this as outstanding, not
   verified.
3. Verify the **Play-installed internal-testing build**, not only a sideloaded
   APK, and record the Play App Signing certificate after an authorized upload.
4. Optionally check the round/monochrome/themed launcher icon appearance on a
   launcher that enables themed icons.

## Real release procedure

The local production-upload-signed AAB is built and verified. Remaining steps:

1. Enter the published policy URL
   <https://github.com/halloffame12/Relay/blob/main/docs/privacy-policy.md> in
   Play Console and supply the monitored developer contact.
2. Complete Data safety, content rating, target audience, ads/IAP and app-access
   declarations.
3. Review the available feature graphic, phone screenshots, tablet screenshots
   and final listing copy.
4. Confirm the Play Console account type and required testing path.
5. The current AAB already contains the 1 November hardening code. Rebuild only
   if code or version changes:
   ```powershell
   flutter build appbundle --release --no-pub
   ```
6. Revalidate the bundle before any authorized upload:
   ```powershell
   java -jar bundletool.jar validate --bundle build/app/outputs/bundle/release/app-release.aab
   java -jar bundletool.jar dump manifest --bundle build/app/outputs/bundle/release/app-release.aab
   jarsigner -verify -certs build/app/outputs/bundle/release/app-release.aab
   keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
   ```
7. After explicit owner authorization, upload to **Internal testing** first.
   Install from Play on two physical devices and repeat the transfer checks.
8. Move to closed testing only after the internal build passes. Apply the
   12-tester/14-day path if the account type requires it.
9. Enroll or confirm Play App Signing and record the Play app-signing certificate.
   The local AAB is signed with the upload key, not the final Play app-signing
   key.
10. Submit production only after the owner reviews the privacy policy, Data
    safety, content rating, listing and testing evidence.

Do not delete or regenerate an existing production key without explicit owner
authorization. If a production key exists outside this repository, use it and
keep its backup; a lost upload key may require a Play upload-key reset.

## Related documents

- `docs/play-policy-audit.md`
- `docs/privacy-policy.md`
- `docs/data-safety.md`
- `docs/play-listing.md`
- `docs/transfer-protocol.md`
- `README.md`
