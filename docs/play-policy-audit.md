# Google Play policy and store-readiness audit

**Audit date:** 27 October 2026

**Scope:** the final release candidate for `io.github.halloffame12.relay`
version `0.9.0` (`versionCode 1`): source, manifest, permissions, exported
components, privacy behavior, policy text, Data safety draft, store copy and
upload assets.

**Decision:** the technical review found no concrete policy violation that can be
resolved in code without owner input. Several declaration, legal, account and
verification items remain open. This is **not** a legal opinion, a Google Play
review, or a claim that the app is ready to publish.

No Play Console access, upload, submission, publishing or store-listing creation
was performed.

## Artifact reviewed

- **AAB:** `build/app/outputs/bundle/release/app-release.aab`,
  62,970,943 bytes, SHA-256
  `99D21AD66DF2207BD28CA07C68B741950F14DA32E4C9581BE264440E164FF774`.
- **Local test APK:** `build/app/outputs/flutter-apk/app-release.apk`,
  84,343,683 bytes, SHA-256
  `802E8C473B0B3FE02020E276314736E21CF0492D643B2C376655C37664CA6A8B`.
- **Package/version:** `io.github.halloffame12.relay`, `0.9.0`
  (`versionCode 1`), min SDK 24, target SDK 36.
- **Signing:** owner-supplied upload key, alias `relay-upload`; certificate
  SHA-256
  `BB:0A:17:52:1A:CA:41:B7:DD:EC:6E:85:8B:2C:C8:31:16:51:8F:C7:98:72:E1:B1:88:36:FC:EA:B8:74:5C:95`.
  The AAB is not debug-signed. Play App Signing is not yet enrolled or recorded.
- **Validation:** `bundletool validate` exits 0; the APK verifies with APK
  Signature Scheme v2 using the same upload certificate. No signing secrets were
  found in the bundle.

## Findings

| Area | Status | Finding |
| --- | --- | --- |
| Target API | Pass | Targets Android 16 / API 36, the current Play requirement. |
| App identity | Pass | Permanent package ID and namespace match. The upload AAB is signed with the owner's upload key. |
| Permissions | Pass | `INTERNET`, optional `CAMERA`, and transitive normal `ACCESS_NETWORK_STATE`; no broad storage, location, contacts, microphone, SMS, call-log or photos permission. Camera hardware is optional. |
| Camera denial fallback | Pass | Release-build emulator test: denial guidance appears and manual address/port/code entry remains usable. |
| Exported surface | Pass | Only `MainActivity` is exported for the launcher. `ProfileInstallReceiver` is exported but protected by the signature/privileged `android.permission.DUMP`. No deep-link import bypass was found. |
| Backup | Pass | `allowBackup=false`, full-backup disabled, and Android 12+ cloud/device-transfer rules exclude app data. |
| Local-first behavior | Pass | No accounts, ads, cloud library, developer analytics, discovery service, developer server or hidden upload path found. ML Kit is disclosed separately. |
| ML Kit telemetry | Needs owner/legal review | The QR scanner bundles Google ML Kit, which may send diagnostics/usage data to Google. The conservative Data safety answer is collected/shared. Do not claim "no analytics" without the qualification. |
| Direct TCP transfer | Pass, accepted risk | Transfer is user-initiated, receiver-approved, checksum-verified and imported through the managed-file pipeline. It is **not** encrypted by Relay; this is disclosed in-app, in the policy, listing draft and Data safety draft. |
| Managed-file boundary | Pass | Only Relay-managed documents can be sent. Incoming filenames are generated locally; traversal, unsupported formats and malformed manifests are rejected. |
| Privacy policy | Published, URL action | Effective 27 October 2026; contact is public GitHub Issues plus the Play listing email. The public HTTPS page is the GitHub-rendered Markdown URL. The owner must enter the working URL in Play Console. |
| Privacy-policy domain | Blocked | A dedicated GitHub Pages path is currently intercepted by the account-level custom domain. Pages was disabled rather than publishing a wrong policy. |
| Data safety | Draft only | The draft conservatively treats peer-to-peer Files and docs as collected, not shared, and ML Kit as collected/shared with Google. The account owner or legal adviser must confirm and submit. |
| Content rating | Owner action | Complete the questionnaire in Play Console. Do not guess the final rating. No violence, sexual content, gambling, controlled substances, UGC or ads are present. |
| Target audience | Owner action | General document readers; not child-directed. Confirm the age band and Families-policy answer in Play Console. |
| Ads and IAP | Pass as declared | No ads and no in-app purchases. |
| App access | Pass | No login or account. All features are available without credentials; reviewer instructions are in `docs/play-listing.md`. |
| UGC / social | Not applicable | The app has no public user-generated content, social feed, chat or public profiles. |
| News / health / financial / government | Not applicable | No relevant features or claims. |
| Store assets | Available, owner review pending | Play icon, feature graphic, seven recommended phone screenshots and four tablet screenshots are available. The brand, listing title, short/full copy and screenshot selection still need owner approval. |
| Screenshot integrity | Pass | Document-bearing store captures use the original `store/sample/the-quiet-orchard.epub`; upload screenshots are RGB and contain no live invitation token. Live QR and policy-dialog captures are kept under the local-only, gitignored `store/screenshots/internal/` directory and are not upload assets. |
| Accessibility polish | Fixed | The icon-only "Share locally" control now exposes a button label and accessibility tap action. The previous tooltip-only semantics did not expose a reliable clickable node. |
| Single-use form polish | Fixed | Starting a new share now clears the previous manual address, port and pairing code instead of reusing a stale, expired code. |
| Play Console testing path | Blocker / unknown | Account type and creation date are unknown; the 12-tester/14-day closed-testing path cannot be confirmed. |
| Two-physical-device release test | Pass for manual PDF | On 1 November 2026 the final upload-signed APK ran on two physical Android 16 devices. Manual pairing produced a 24.6 MB PDF import after the blocking approval, the receiver verified the checksum, a duplicate was recognized without overwrite, and an explicit rejection left no library entry. EPUB was not repeated on final two-device hardware. |
| Direct camera-to-screen QR scan | Outstanding | The earlier two-device physical test scanned a QR image on a monitor, not the receiver's own screen. Do not claim that physical camera aiming has been proved. |
| Play-installed build | Outstanding | No Play upload or internal-testing install was performed. The Play App Signing certificate remains unrecorded. |

## Concrete issues fixed in this pass

- Added branded Android adaptive, monochrome, round and legacy icons; web,
  iOS, macOS and Windows icons; Android 12+ light/dark splash; pre-12 launch
  background; Play icon and feature graphic.
- Captured final phone screenshots with the original store sample, removed stale
  test-content captures, moved live QR/policy-dialog captures to
  `store/screenshots/internal/`, and converted upload screenshots to RGB.
- Updated the in-app and published policy to effective 27 October 2026 with a
  concrete public contact channel and an explicit warning not to post documents
  or invitation codes.
- Cleared stale manual connection fields when a new share starts.
- Added an accessible button label/action to the share control.
- Hardened corrupt-settings recovery, mid-copy import cancellation, streaming
  SHA-256, untrusted metadata, JSON nesting, EPUB image extraction and the manual
  pairing-code attempt cap.
- Rebuilt and re-verified the upload-signed AAB and local test APK after the
  hardening pass.

## Remaining owner/legal/store actions

1. Provide a monitored Play developer contact email and the real developer
   identity/address.
2. Enter the working privacy-policy URL in Play Console. Replace it with a
   dedicated verified policy URL only after that URL is live.
3. Complete Data safety, content rating, target audience, ads/IAP and app-access
   declarations against the final build.
4. Review the unencrypted-transfer and ML Kit disclosures with the account owner
   or legal adviser.
5. Confirm the Play Console account type and required testing path.
6. Review and approve the app title, short/full description, icon, feature
   graphic, phone screenshots and tablet screenshot set.
7. Repeat an EPUB transfer on two physical devices with the final build; the
   1 November run covered PDF, duplicate handling and rejection.
8. Perform a direct camera-to-phone-screen QR scan and recheck camera-denial
   recovery on the release build.
9. After explicit authorization, upload to internal testing, verify the
   Play-installed build, and record the Play App Signing certificate.
10. Authorize any submission or production publish.

## Claims to avoid

Do not claim that Relay is "production-ready", "policy-perfect", "Play approved",
"direct-camera QR tested", "Play-installed", or "Play App Signing verified" until
the corresponding action above is complete. Do not claim that the final
two-device run covered EPUB or camera pairing: it covered a manual PDF transfer,
duplicate handling and rejection on two physical devices. Do not claim transport
encryption, automatic discovery, Bluetooth, Wi-Fi Direct, cloud sync or
background transfer: none are implemented.

## Related documents

- `docs/release-readiness.md`
- `docs/privacy-policy.md`
- `docs/data-safety.md`
- `docs/play-listing.md`
- `docs/transfer-protocol.md`
- `README.md`
