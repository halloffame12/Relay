# Release readiness audit

**Audit date:** 27 October 2026

**Decision:** **PRODUCTION AAB SIGNED AND VERIFIED; NOT YET READY TO PUBLISH.**
The permanent application ID and production upload signing are in place, and
the local AAB passes structural, identity, certificate and secret checks. The
remaining work is Play Console, privacy/legal, store-asset and physical-device
verification. This is not a claim that the app is ready for production release.

No Play Console submission or production publish was performed.

## Scope and constraints

- Repository: `C:\startup\Relay`. The audit began before Git was initialized.
  Git and the public `origin` remote were added afterward; build output and
  signing files remain ignored. The public repository is
  <https://github.com/halloffame12/Relay>.
- The product remains local-first. No analytics SDK, ads, accounts, cloud
  storage, discovery service or developer-operated server was added.
- Direct TCP, NDJSON, protocol v2, QR invitation v1, receiver approval, checksum
  verification, duplicate rejection, managed imports and the manual fallback
  were preserved. NSD/mDNS discovery remains deferred.
- Flutter, Gradle, Kotlin, AGP and dependencies were not upgraded. The existing
  toolchain builds successfully.
- The production upload keystore was supplied by the owner outside the
  repository. It was not copied into the project, build output, or bundle, and
  it was not created, deleted or regenerated during this audit. No password,
  private key, or secret value was printed or logged.

## Readiness summary

| Area | Status | Notes |
| --- | --- | --- |
| Target API | Pass | `targetSdk 36`, `minSdk 24`. Current Play requirement is Android 16 / API 36. |
| Build and tests | Pass | Format clean, analyze clean, 120 tests pass, production release bundle builds. |
| App Bundle structure | Pass | `bundletool validate` exits 0; signed AAB validates; 64-bit ABIs present. |
| Application ID | Pass | `io.github.halloffame12.relay`; namespace and `MainActivity` package match. Permanent after the first Play upload. |
| Release signing | Pass | Production upload key configured outside the repo; AAB is signed by alias `relay-upload`, not the debug key. |
| Signing secrets | Pass | No `key.properties`, keystore, `local.properties`, debug keystore, or password/property strings found in the AAB. |
| QA/debug isolation | Pass | Debug signing with the production ID is rejected; QA builds require a `.qa` or `com.example.*` ID and receive a `-qa` version suffix. |
| Permissions | Pass | `INTERNET`, `CAMERA`, and transitive `ACCESS_NETWORK_STATE` only; camera hardware optional; no broad storage. |
| Exported components | Pass | Launcher activity plus a `ProfileInstallReceiver` protected by `android.permission.DUMP`; other components are not exported. |
| Backup controls | Pass | `allowBackup=false`, `fullBackupContent=false`, and all app data excluded from Android 12+ cloud backup and device transfer. |
| Privacy policy | Published | In-app and Markdown policy written. Public HTTPS page: `https://github.com/halloffame12/Relay/blob/main/docs/privacy-policy.md`. Enter it in Play Console. |
| Data safety | Draft only | Conservative draft prepared; peer-to-peer and ML Kit answers need owner/legal confirmation. |
| Play Console account/track | **Blocker / unknown** | Account type and creation date are unknown; the required testing path cannot be confirmed. |
| Store listing assets | **Incomplete** | Icon available; feature graphic and screenshots are missing; content rating and target audience are not submitted. |
| Physical release verification | Outstanding | The production AAB has not been installed on physical devices; prior transfer tests used debug builds. |

## Changes made in this audit

1. **Release signing and identity guards**
   - `android/app/build.gradle.kts` now reads a local, ignored
     `android/key.properties`.
   - Release tasks fail with a clear error if the application ID still starts
     with `com.example.` or if no release signing is configured.
   - `-Prelay.applicationId=<id>`, `-Prelay.allowExampleApplicationId=true` and
     `-Prelay.allowDebugReleaseSigning=true` are explicit Gradle properties. The
     last two are only for non-uploadable local QA.
   - `android/key.properties.example` was added.
   - Root `.gitignore` now ignores `android/key.properties`, `*.jks` and
     `*.keystore` (the existing `android/.gitignore` already did).
2. **Backup protections**
   - Added `android:fullBackupContent="false"` and
     `android:dataExtractionRules="@xml/data_extraction_rules"`.
   - Added `android/app/src/main/res/xml/data_extraction_rules.xml`, excluding
     root, file, database, shared-preference and external domains from cloud
     backup and device transfer.
3. **Privacy and store copy**
   - Added an in-app privacy policy in
     `lib/features/settings/presentation/privacy_policy.dart`, reachable from
     Settings.
   - Updated the Settings privacy section and About text to state that Nearby is
     direct, not end-to-end encrypted, and that the QR scanner uses Google ML Kit.
   - Added `docs/privacy-policy.md`, `docs/data-safety.md` and
     `docs/play-listing.md`.
4. **Transfer destination visibility**
   - The connected send panel now displays the resolved receiver address and
     port. The final confirmation repeats them.
   - Added widget-test assertions for the displayed endpoint.
   - Documented the trust implications in `docs/transfer-protocol.md`.
5. **Documentation**
   - Updated `README.md` with release configuration, backup and ML Kit notes.
   - This file records the remaining human actions and verification gaps.
6. **Production identity and signing (Phase 7)**
   - Set the permanent application ID and namespace to
     `io.github.halloffame12.relay`.
   - Moved `MainActivity` to the matching Kotlin package and removed the old
     `com.example.relay` Android package.
   - Hardened the QA override: a debug-signed release bundle must use a
     `com.example.*` or `.qa` application ID and receives a `-qa` version
     suffix; combining the override with a real upload key is rejected.
   - Corrected the non-secret `storeFile` entry in `android/key.properties` so
     it points at the owner-supplied keystore outside the repository. No
     password or private key was displayed.
   - Built and verified the production-upload-signed AAB described below.
7. **Public source repository and policy page**
   - Initialized Git on `main`, committed the source without build output or
     signing secrets, and pushed it to
     <https://github.com/halloffame12/Relay>.
   - The AAB, `android/key.properties`, keystore files, `local.properties` and
     build directories are ignored and are not in the public repository.
   - Added `docs/index.html`, `docs/privacy-policy.html` and `docs/.nojekyll`
     for a future GitHub Pages deployment. The account-level custom domain
     currently intercepts the project path, so Pages was disabled rather than
     exposing a wrong page. The GitHub-rendered Markdown page is the current
     public URL.

No transfer protocol, invitation format, storage algorithm, receiver-approval
logic or checksum implementation was changed.

## Verification performed

Commands were run from `C:\startup\Relay` on 27 October 2026. The local signing
configuration was read by Gradle and `keytool`; no password, private key, or
secret value was printed.

| Check | Result |
| --- | --- |
| Keystore alias | `relay-upload`, `PrivateKeyEntry` |
| Keystore certificate | 4096-bit RSA, SHA384withRSA; fingerprint below |
| `dart format lib test` | 114 files checked, 0 changed. |
| `flutter analyze --no-pub` | No issues found. |
| `flutter test --no-pub` | 120 tests passed. |
| `flutter build appbundle --release --no-pub` | Succeeded with no QA override or debug-signing flag. |
| `bundletool validate --bundle app-release.aab` | Exit 0; base module and native libraries present. |
| Manifest inspection | Package, version, SDK, permissions, debuggable and testOnly checks below. |
| `keytool -printcert -jarfile app-release.aab` | Upload certificate; no Android Debug certificate. |
| `jarsigner -verify -verbose -certs app-release.aab` | Exit 0; reported `jar verified.` |
| Embedded-file check | No `key.properties`, `.jks`, `.keystore`, `local.properties`, `debug.keystore`, or password/property strings found. |
| Debug-signing guard | With the production key present, the debug override failed and left the AAB unchanged. |

The missing-credential guard remains in `android/app/build.gradle.kts` and was
exercised during the earlier QA audit. It was not re-run by temporarily moving
the now-configured key. The debug-signing guard was re-run with the key present:
the build failed at the "both a release keystore and the debug-signing QA
override" check, and the production AAB's SHA-256 was unchanged.

### Production artifact

- **Path:** `build/app/outputs/bundle/release/app-release.aab`
- **Size:** 62,183,331 bytes (59.30 MiB)
- **SHA-256:**
  `3A36EE9BD3A8F3D6BEB027F56C2F025C1F32171F9158B2D6919A8EA3293DCE3F`
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
- **Bundle validation:** `bundletool validate` exit 0; `jarsigner -verify`
  exit 0 with `jar verified.`
- **Debuggable/testOnly:** absent
- **Signing material:** no `key.properties`, `.jks`, `.keystore`,
  `local.properties`, debug keystore, or password/property strings in the
  bundle. The only `META-INF` entries are the public signature block
  (`RELAY-UP.SF`, `RELAY-UP.RSA`) and `MANIFEST.MF`.
- **Local signing location:** `%USERPROFILE%\RelayKeys\relay-upload.jks`,
  outside the repository. `android/key.properties` is ignored by `.gitignore`
  and was not committed. The public repository contains no keystore,
  `key.properties`, `local.properties` or build output.

The certificate SHA-256 matches the `relay-upload` certificate read from the
configured keystore. This AAB is signed with the upload key. If Play App Signing
is enrolled, Google re-signs the distributed APK with the app-signing key; that
Play certificate must be recorded after the first upload.

### Previous QA artifact (replaced)

The artifact at this path was inspected before replacement. Its immediate
predecessor was built with the explicit QA override:

- **Package:** `io.github.halloffame12.relay.qa`
- **Version:** `0.9.0-qa`
- **Certificate:** `C=US, O=Android, CN=Android Debug`
- **SHA-256:**
  `264485A28D36134D63BEFA53B02D98A86B6711A6BA2EFEE91D71B854CB823122`

The older `com.example.relay` QA bundle from the previous audit was also
debug-signed and non-uploadable. Neither QA artifact is present at the
production path now.

## Security and privacy findings

### Passed or fixed

- **No debug logging or secrets:** No `print`, `debugPrint`, developer logging or
  cloud API usage was found in app code. Invitation tokens are redacted from
  `TransferInvitation.toString()`, history and logs.
- **QR input is data:** The scanner never opens scanned text as a URL. Hostname
  and path fields are not accepted; the parser validates the envelope and IPv4
  addresses.
- **Invitation lifecycle:** Single-use token consumption, replay rejection,
  expiry, rotation and stopped-session rejection are covered by tests and the
  prior physical run.
- **Approval and integrity:** The receiver must approve before file bytes are
  accepted. Size and SHA-256 are verified; duplicates are rejected; temporary
  files are cleaned up.
- **Managed-file boundary:** The receiver imports into app-managed storage with a
  generated internal filename. User-supplied filenames are not used as paths.
- **Exported surface:** `MainActivity` is exported only as the launcher activity
  and has no permission. `ProfileInstallReceiver` is exported but protected by
  `android.permission.DUMP` (a signature/privileged permission). ML Kit, CameraX,
  AndroidX Startup and data-transport components are not exported.
- **Permissions:** No storage, location, contacts, microphone, SMS, call-log or
  photos permission. Camera denial has a manual fallback.
- **Backup:** Cloud backup and Android 12+ device transfer are disabled and
  excluded by rules.
- **Release flags:** `android:debuggable` and `android:testOnly` are absent.
- **No release secrets in the bundle:** Confirmed by entry and string checks;
  the only `META-INF` entries are the public signature block and manifest.

### Accepted risks or disclosures

- **No transport encryption:** Nearby uses direct TCP without Relay-specific
  encryption. A network observer may see document bytes. This is disclosed in
  the in-app policy, privacy policy, Data safety draft and store copy. The send
  screen shows the destination address and port.
- **No `usesCleartextTraffic` or network-security-config shortcut:** Android's
  cleartext-traffic policy applies to HTTP stacks, not Relay's raw TCP socket, so
  adding a false setting would not secure or block the transfer. ML Kit uses its
  own HTTPS transport. The direct transfer remains unencrypted and is described
  as such.
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
  per-installation identifiers to Google. Relay itself has no developer analytics,
  but the app must not claim "no analytics" without the ML Kit qualification.
  This is disclosed in the in-app policy and `docs/data-safety.md`.
- **Data safety ambiguity:** The conservative draft treats the user-initiated
  peer-to-peer file transfer as **Files and docs: collected, optional, app
  functionality, not shared, not encrypted in transit**. It treats ML Kit data as
  collected and, conservatively, **shared with Google**. The Play Console owner
  or legal adviser must confirm both before submission.
- **No direct phone-screen QR scan:** Prior physical tests scanned a QR image on a
  monitor, not the receiver's own screen. Automated tests inject a scanner view.
  Do not claim physical camera aiming or discovery support.
- **No production-build physical transfer:** The production AAB was inspected
  locally but was not installed on a device. A QA APK was smoke-tested on an
  emulator, and prior transfer tests used debug builds.
- **Dependency maintenance:** Direct dependencies are current enough to build and
  test, but newer versions are available. No blind upgrade was performed.
  `drift_flutter 0.3.1` still pulls the EOL `sqlite3_flutter_libs` compatibility
  shims; the bundle includes `libsqlite3.so` and no SQLCipher native library.
- **License review:** Direct dependencies use MIT or BSD-3-Clause-style licenses
  in their bundled `LICENSE` files. This was not a full transitive license scan.
  Native PDFium and ML Kit are subject to their own terms; the in-app open-source
  licenses page and `docs/privacy-policy.md` mention them. Run a full license
  scanner if the owner requires a formal audit.

## Google Play requirements

- **Target API:** The bundle targets Android 16 / API 36, satisfying the current
  requirement for new apps and updates (effective 31 August 2026). An Android 17
  / target SDK 37 build would need the `ACCESS_LOCAL_NETWORK` runtime permission
  and a new permission flow; that was not added because the app targets 36.
- **Application ID and signing:** The permanent package is
  `io.github.halloffame12.relay`. The local AAB is signed with the owner's
  upload key. Play App Signing enrollment and the Play-distributed certificate
  are still Play Console actions.
- **Privacy policy:** Play requires a privacy-policy URL for apps that request
  sensitive permissions or handle personal/sensitive data. The policy is
  published at
  <https://github.com/halloffame12/Relay/blob/main/docs/privacy-policy.md>.
  Enter that URL in Play Console. A dedicated domain is preferable; the
  account-level GitHub Pages custom domain currently intercepts the project
  path, so the Pages deployment was disabled rather than exposing a wrong page.
- **Data safety:** A draft is ready; the final declaration must match the build
  and policy and must be signed off by the account owner/legal adviser.
- **Testing path:** Personal developer accounts created after 13 November 2023
  currently need closed testing with at least 12 testers opted in continuously
  for 14 days before production access. Organization accounts differ. The account
  type and creation date are unknown, so this path is not confirmed.
- **Store listing:** Category, ads/IAP declarations, content rating, target
  audience, app access instructions, feature graphic, screenshots, contact email
  and final app name are not submitted.
- **No unsupported claims:** The listing draft does not claim Wi-Fi Direct,
  Bluetooth, automatic discovery, cloud sync, transport encryption or background
  transfer.

## Blockers and human actions

### Hard blockers before any Play upload

Application ID and release signing are no longer blockers. The AAB is signed
with the owner's upload key and the certificate matches the configured keystore.

1. **Enter the published privacy-policy URL in Play Console.** The working
   public HTTPS page is
   <https://github.com/halloffame12/Relay/blob/main/docs/privacy-policy.md>.
   A dedicated domain can replace it later, but only after the URL is verified.
2. **Provide the Play developer contact email and developer identity.** The
   policy points to the Play listing email; no address, company name or phone
   number was invented.
3. **Complete Data safety and content rating.** Confirm the peer-to-peer Files
   and docs treatment and the ML Kit shared/collected answers. Do not submit a
   "no data collected" declaration while ML Kit is bundled.
4. **Review the unencrypted-transfer and ML Kit diagnostic disclosures.** Confirm
   the final wording against the build, privacy policy and Data safety answers.
5. **Confirm the Play Console account type and testing path.** Determine whether
   the 12-tester/14-day closed-testing requirement applies before production.
6. **Prepare the remaining store assets.** A 512 x 512 icon exists at
   `web/icons/Icon-512.png` (verified 512 x 512, 24 bpp, no alpha). A 1024 x 500
   feature graphic, phone screenshots (2-8), optional tablet screenshots, and
   final app title/short/full description approval are still needed.
7. **Authorize submission.** Do not upload or publish until the owner explicitly
   authorizes the account, track and build.

### Verification gaps before calling the release fully tested

1. Install the production-signed release build on two physical devices on the
   same Wi-Fi network and repeat EPUB and PDF transfers, rejection, duplicate
   handling, expiry/rotation and cleanup.
2. Perform a direct **camera-to-phone-screen** QR scan with the sender's camera
   aimed at the receiver's screen. The earlier scan used a monitor image. Treat
   this as outstanding, not verified.
3. Recheck camera-permission denial and settings recovery in the release build.
4. Verify the Play-installed internal-testing build, not only a sideloaded APK,
   and record the Play App Signing certificate after an authorized upload.

## Real release procedure

The local production-upload-signed AAB is built and verified. Remaining steps:

1. Enter the published policy URL
   <https://github.com/halloffame12/Relay/blob/main/docs/privacy-policy.md>
   in Play Console and supply the monitored developer contact.
2. Complete Data safety, content rating, target audience, ads/IAP and app-access
   declarations.
3. Prepare the feature graphic, phone screenshots, optional tablet screenshots,
   and final listing copy.
4. Confirm the Play Console account type and required testing path.
5. Rebuild only if code or version changes:
   ```powershell
   flutter build appbundle --release --no-pub
   ```
6. Revalidate the bundle before any authorized upload:
   ```powershell
   java -jar bundletool.jar validate --bundle build/app/outputs/bundle/release/app-release.aab
   java -jar bundletool.jar dump manifest --bundle build/app/outputs/bundle/release/app-release.aab
   jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
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

- `docs/privacy-policy.md`
- `docs/data-safety.md`
- `docs/play-listing.md`
- `docs/transfer-protocol.md`
- `README.md`
