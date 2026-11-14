# Relay Android Release & Branding Report

**Build Date:** November 14, 2026
**Application Name:** Relay
**Application ID:** `io.github.halloffame12.relay`
**Version:** `0.9.0` (versionCode `1`)
**Target Platform:** Android (minSdk `24`, targetSdk `36`, compileSdk `36`)

---

## 1. Executive Summary

A complete, production-grade Android branding, adaptive app icon, native splash screen, and release build system has been implemented directly in `C:\startup\Relay`.

All branding changes strictly preserve Relay's visual identity:
- **Near-black background:** `#0F0F11` (RGB 15, 15, 17)
- **Warm ivory/cream symbol:** `#F5EEE5`
- **Bright lime-green accent:** `#A7C645` / `#C2F050`

The official brand icon (`assets/brand/relay-icon.png`, SHA-256 `9bdd72a852a123f450e71cfe44b580a453a82762429e9f8954d5774d070e373f`) served as the sole source of truth for all derived assets.

---

## 2. Branding & Asset Changes

### 2.1 Brand Source Preservation
- Primary high-resolution source: `assets/brand/relay-icon.png` (1254 × 1254 px PNG).
- Synced mirror: `store/brand/relay-icon.png` (byte-identical, verified in automated tests).
- Manifest: `store/brand-assets.json` records dimensions, palette, and SHA-256 hash.

### 2.2 Android Launcher Icons
- **Adaptive Foreground (`ic_launcher_foreground.png`):**
  Extracted transparent Relay mark (ivory symbol + lime accent) with smooth anti-aliased alpha blending.
  - Positioned at **0.44 height fraction** of the 108dp canvas.
  - Maximum diagonal radius from center is **31.86 dp**, strictly contained within Android's **33.0 dp safe zone circle** (inner 66dp diameter).
  - Guaranteed zero clipping on circular (Pixel/Motorola), squircle (Samsung), teardrop, and rounded-rectangle launcher masks.
- **Adaptive Background (`ic_launcher_background`):**
  Pure `#0F0F11` XML color drawable that fills the full 108dp canvas out to every mask border.
- **Android 13+ Themed Monochrome (`ic_launcher_monochrome.png`):**
  Pure white (`#FFFFFF`) silhouette retaining the exact alpha channel and safe-zone geometry of the foreground. Seamlessly supports Material You wallpaper dynamic theming.
- **Legacy Standard & Round Icons:**
  - `mipmap-{density}/ic_launcher.png` (rounded corner radius 0.225)
  - `mipmap-{density}/ic_launcher_round.png` (circular mask)
  - Generated across all densities: `mdpi` (48px), `hdpi` (72px), `xhdpi` (96px), `xxhdpi` (144px), `xxxhdpi` (192px).

### 2.3 Native Android Splash Screen
- **Design:** Full-screen near-black background (`#0F0F11`) with centered Relay logo mark. Minimal, intentional, zero spinner, zero gradients, zero artificial delay.
- **Android 12+ (API 31+) Implementation:**
  - Configured in `android/app/src/main/res/values-v31/styles.xml` and `values-night-v31/styles.xml`.
  - `android:windowSplashScreenBackground`: `@color/relay_splash_background` (`#0F0F11`).
  - `android:windowSplashScreenAnimatedIcon`: `@drawable/splash_icon` (fitted mark on transparent canvas).
  - `android:windowSplashScreenIconBackgroundColor`: `@color/relay_splash_icon_background` (`#0F0F11`).
  - System bar icons: `windowLightStatusBar=false` and `windowLightNavigationBar=false` to ensure light system indicators on the dark window.
- **Android 11 and Older Implementation:**
  - Configured in `android/app/src/main/res/drawable/launch_background.xml` and `drawable-v21/launch_background.xml`.
  - Layer-list with solid `@color/relay_splash_background` (`#0F0F11`) and centered 160dp × 160dp `@drawable/splash_mark`.
  - `LaunchTheme` in `values/styles.xml` and `values-night/styles.xml` uses `@android:style/Theme.Black.NoTitleBar`.
- **First Frame Transition:**
  - Once the Flutter engine draws its first frame, `MainActivity` switches to `NormalTheme`.
  - The window backgrounds are configured to hand off without a white flash. This is a resource-level configuration; it was not visually re-verified on a physical device in this pass.

### 2.4 Flutter Application Branding Audit
- Application name displays as **Relay** in app title, Android manifest, and app tokens.
- `RelayBrandIcon` widget displays the official icon with configurable corner radius.
- `RelayWordmark` displays the official mark alongside the serif typography.
- Open-source licenses dialog (`showLicensePage` in `settings_screen.dart`) now renders the official `RelayBrandIcon`.
- Dialogs, empty states (`RelayEmptyState`), error states (`RelayErrorState`), and transfer screens consistently employ the Relay design system.

---

## 3. Asset Generation & Reproducibility

Asset generation is automated and deterministic via Python (using Pillow):

```powershell
# From the repository root C:\startup\Relay:
python tool/generate_brand_assets.py
```

Generated outputs include:
- `android/app/src/main/res/drawable-{density}/ic_launcher_foreground.png`
- `android/app/src/main/res/drawable-{density}/ic_launcher_monochrome.png`
- `android/app/src/main/res/drawable-{density}/splash_icon.png`
- `android/app/src/main/res/drawable-{density}/splash_mark.png`
- `android/app/src/main/res/drawable-night-{density}/splash_icon.png`
- `android/app/src/main/res/drawable-night-{density}/splash_mark.png`
- `android/app/src/main/res/mipmap-{density}/ic_launcher.png`
- `android/app/src/main/res/mipmap-{density}/ic_launcher_round.png`
- `store/icon-512.png` (512 × 512 px Play Store icon)
- `store/feature-graphic-1024x500.png` (1024 × 500 px Play Store feature graphic)
- `store/brand-assets.json` (Provenance manifest)
- Web, iOS, macOS, and Windows icons.

---

## 4. Build Commands & Artifact Verification

### 4.1 Build Commands
```powershell
# Analyze codebase
flutter analyze

# Run test suite
flutter test

# Build Release APK
flutter build apk --release

# Build Release Android App Bundle (AAB)
flutter build appbundle --release
```

### 4.2 Release Artifacts

| Artifact | File Path | File Size | SHA-256 Checksum |
| :--- | :--- | :--- | :--- |
| **Release APK** | `build/app/outputs/flutter-apk/app-release.apk` | 122,825,167 bytes (117.14 MB) | `3906dbbe0d986c3334071e6c94fe727e4729fff53eb49cae0b0092006abd253d` |
| **Release AAB** | `build/app/outputs/bundle/release/app-release.aab` | 82,497,107 bytes (78.68 MB) | `fab21ffe8f329815664fa8d55af9eb7a47a9c238f03d040640c6821491437242` |

---

## 5. Signing & Security Status

- **Signing Config:** Production upload release signing is active via `android/key.properties`.
- **Keystore Location:** `C:/Users/SUMIT CHAUHAN/RelayKeys/relay-upload.jks` (securely untracked by Git).
- **Key Alias:** `relay-upload`
- **Certificate DN:** `CN="sumit chauhan ", OU=Relay, O=halloffame12, L=Delhi, ST=Delhi, C=IN`
- **Certificate SHA-256 Digest:** `bb0a17521aca41b7ddec6e858b2cc83116518fc79872e1b18836fceab8745c95`
- **Verification Tool:** `apksigner verify --verbose`
  - `Verified using v2 scheme (APK Signature Scheme v2): true`
  - `Number of signers: 1`
  - **Verdict:** Valid production release signature. Not signed with a debug key.

---

## 6. Quality Assurance & Verification

### 6.1 Static Analysis (`flutter analyze`)
- Executed: `flutter analyze`
- Result: **No issues found!** (0 errors, 0 warnings, 0 lints)

### 6.2 Automated Test Suite (`flutter test`)
- Executed: `flutter test`
- Result: **All 202 tests passed!**
- Included verification from `test/brand_assets_test.dart`:
  - Verified byte-identical source match.
  - Verified presence and valid dimensions of legacy launcher icons across all densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
  - Verified presence and alpha channels of adaptive foreground and monochrome icons across all densities.
  - Verified light and dark splash mark resources.
  - Verified Play icon dimensions and corner pixel background color matching `#0F0F11`.

### 6.3 Device Testing Note
- Command `flutter devices` detected: Windows desktop, Chrome web, and Edge web.
- **No physical Android device or emulator was connected** during this build run. Therefore, direct on-device testing was not performed and is not falsely claimed. Visual layout and safe zones were verified programmatically via pixel-level mathematical calculations.

---

## 7. Remaining Release Blockers

There are **no build or signing blockers** for these artifacts. The APK/AAB are
signed with the production upload keystore, package metadata is valid, and both
files are ready to attach to a release or upload to Play Console.

The product is not fully production-verified:

- Cross-network sharing depends on a deployed signaling endpoint and TURN
  credentials. The published artifact was built without `RELAY_SIGNALING_URL`,
  so it is same-network only.
- No Play Console account access, Data Safety submission, or legal sign-off.
- No physical Android device was connected for this pass, so the new splash and
  launcher icon were not visually confirmed on hardware. Layout/safe-zone checks
  are geometric and test-backed only.
- Resume-after-drop is still not implemented.

Do not describe these artifacts as Play-published or as supporting cross-network
transfer until those items are completed and verified.
