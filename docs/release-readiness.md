# Release readiness audit

**Audit date:** 27 October 2026

**Decision:** **PRODUCTION AAB SIGNED AND VERIFIED; NOT YET READY TO PUBLISH.**
The permanent application ID, upload signing, branded assets, privacy policy and
a final release-build transfer check are in place. The remaining work is Play
Console account access, declarations and legal review, owner approval, a
two-physical-device release test, a direct camera-to-screen QR test, and an
authorized Play-installed build. This is not a claim that the app is ready for
production release.

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
| Build and tests | Pass | Format clean, analyze clean, 120 tests pass, release AAB and APK build. |
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
| Release-device verification | **Partial** | Final APK installed on an Android 17 emulator and one physical Android 11 tablet. A final-build manual-fallback approval/checksum/duplicate check succeeded; the successful import occurred on the immediately preceding release-signed build, and the final APK reopened the preserved document in the reader. A two-physical-device release test is still outstanding. |
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

No transfer protocol, invitation format, storage algorithm, receiver-approval
logic or checksum implementation was changed in this pass.

## Verification performed

Commands were run from `C:\startup\Relay` on 27 October 2026. The local signing
configuration was read by Gradle and `keytool`; no password, private key or
secret value was printed.

| Check | Result |
| --- | --- |
| `dart format lib test` | 114 files checked, 0 changed. |
| `flutter analyze --no-pub` | No issues found. |
| `flutter test --no-pub` | 120 tests passed. |
| `flutter build appbundle --release --no-pub` | Succeeded with no QA override or debug-signing flag. |
| `flutter build apk --release --no-pub` | Succeeded; local sideload/test artifact only. |
| `bundletool validate --bundle app-release.aab` | Exit 0; base module and native libraries present. |
| Manifest inspection | Package, version, SDK, permissions and exported components checked. |
| `keytool -printcert -jarfile app-release.aab` | Upload certificate; no Android Debug certificate. |
| `jarsigner -verify -certs app-release.aab` | Exit 0. Warnings about JarInputStream entry handling and the self-signed upload certificate are expected. |
| APK `apksigner verify --print-certs` | APK Signature Scheme v2 verifies; same upload certificate. |
| Embedded-file check | No `key.properties`, `.jks`, `.keystore`, `local.properties`, `debug.keystore`, or password/property strings found. |
| Policy screen | Final APK shows effective 27 October 2026, the GitHub Issues URL and the Play-email contact wording. |
| Camera denial / manual fallback | Release APK on emulator: denial guidance appears; manual address/port/code entry remains usable. |
| Final-build transfer check | Emulator sender to physical tablet receiver over direct TCP using manual entry. The tablet already held the sample; it showed the blocking approval, verified size/SHA-256, and recognized a duplicate without overwrite. |
| Reader content | The final APK reopened the preserved EPUB and displayed its text in the tablet reader. The successful import occurred on the immediately preceding release-signed build. |
| Share accessibility | "Share locally" exposes a clickable labeled action; a new share clears prior manual connection fields. |
| Launcher icon | Branded icon visible in Android 17 and Android 11 App info. |
| Screenshot set | Phone captures 1080 x 1920 and tablet captures 1340 x 800, RGB; original sample content; no live token in upload assets. |

### Final production artifact

- **AAB path:** `build/app/outputs/bundle/release/app-release.aab`
- **AAB size:** 62,970,943 bytes (60.05 MiB)
- **AAB SHA-256:**
  `99D21AD66DF2207BD28CA07C68B741950F14DA32E4C9581BE264440E164FF774`
- **Local test APK:** `build/app/outputs/flutter-apk/app-release.apk`
- **APK size:** 84,343,683 bytes (80.44 MiB)
- **APK SHA-256:**
  `802E8C473B0B3FE02020E276314736E21CF0492D643B2C376655C37664CA6A8B`
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

### Release-build device verification

- **Emulator:** Android 17 / API 37, final release APK, 1080 x 1920 override
  during capture (reset afterward). Verified launch, policy, camera denial,
  manual fallback, share accessibility, stale-field clearing and the launcher
  icon in App info.
- **Physical tablet:** RMP2105, Android 11 / API 30, 1340 x 800 landscape,
  density 213, final release APK. Verified launch, branded app-info icon, receive
  mode, manual connection details, receiver approval, checksum verification, a
  send of a document already in the library that was recognized as a duplicate
  without overwriting the existing copy, and reader content.
- **Live transfer:** the emulator sender entered the tablet's IPv4 address, TCP
  port and six-digit code, selected `The Quiet Orchard` (EPUB), confirmed the
  destination, and waited for approval. The tablet showed the blocking approval
  dialog before bytes were accepted. After approval, the tablet verified the
  declared size and SHA-256 and recognized the document as already in the
  library, without overwriting it.
- **Screenshots:** the tablet reader capture was repeated on the final APK after
  the live transfer. The tablet library/details/transfers captures were made on
  the immediately preceding release-signed build; the only later code change was
  the share-accessibility semantics, which does not affect those screens. The
  final APK was installed on the same tablet and used for the live duplicate
  check and reader check.

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
  files are cleaned up. The final APK repeated approval and duplicate handling.
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
- **Two-physical-device release test still open:** The final build was verified
  with an emulator sender and one physical tablet receiver. A second physical
  device was not available.
- **Direct camera scan still open:** Prior physical tests scanned a QR image on a
  monitor. The final-build send used manual entry.
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
  transfer or a tested two-physical-device final build.

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

1. Install the final production-signed build on **two physical devices** on the
   same Wi-Fi network and repeat EPUB and PDF transfers, rejection, duplicate
   handling, expiry/rotation and cleanup.
2. Perform a direct **camera-to-phone-screen** QR scan with the sender's camera
   aimed at the receiver's screen. The earlier scan used a monitor image. Treat
   this as outstanding, not verified.
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
5. Rebuild only if code or version changes:
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
