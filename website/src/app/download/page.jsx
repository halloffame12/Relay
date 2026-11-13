import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";
import CopySnippet from "@/components/CopySnippet";
import Link from "next/link";

export const metadata = {
  title: "Download Relay for Android — v0.9.0 Release",
  description:
    "Download Relay v0.9.0 for Android. Offline-first PDF & EPUB reader with peer-to-peer QR file sharing.",
};

export default function Download() {
  return (
    <>
      <Header />
      <main id="main-content">
        <section className="section" style={{ paddingBottom: 40 }}>
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">[ OFFICIAL RELEASE ]</div>
                <h1 className="display display-1">Download Relay for Android.</h1>
                <p className="lede">
                  Offline-first reader and peer-to-peer document transfer. No account required.
                </p>
              </div>
            </Reveal>

            {/* Main Release Card */}
            <div className="download-release-card download-card">
              <div className="release-grid">
                <div>
                  <div className="release-badge-row">
                    <span className="release-version">Relay v0.9.0</span>
                    <span className="verified-badge">STABLE PREVIEW</span>
                  </div>
                  <p style={{ color: "var(--ink-secondary)", fontSize: 16, margin: "0 0 20px" }}>
                    Install the verified release APK directly, or compile from source using Flutter.
                  </p>

                  <div className="row" style={{ gap: 14 }}>
                    <a
                      className="btn btn-primary"
                      href="https://github.com/halloffame12/Relay/releases"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      <span>Get APK on GitHub Releases</span>
                      <span className="arrow">↗</span>
                    </a>
                    <a
                      className="btn btn-secondary"
                      href="https://github.com/halloffame12/Relay"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      <span>View Source Code ↗</span>
                    </a>
                  </div>

                  <div className="honest-banner coming-soon">
                    <div style={{ fontWeight: 600, marginBottom: 4 }}>Google Play Store Status:</div>
                    <span>
                      The Google Play Store listing is currently in preparation and will be published following Data Safety review. We do not link to unverified or placeholder store entries.
                    </span>
                  </div>

                  <div className="specs-table download-meta">
                    <div className="specs-row meta-item">
                      <span className="specs-key label">Application ID</span>
                      <span className="specs-val value mono">io.github.halloffame12.relay</span>
                    </div>
                    <div className="specs-row meta-item">
                      <span className="specs-key label">Platform</span>
                      <span className="specs-val value">Android 7.0+ (Nougat and newer)</span>
                    </div>
                    <div className="specs-row meta-item">
                      <span className="specs-key label">Minimum SDK / Target SDK</span>
                      <span className="specs-val value mono">Min SDK 24 / Target SDK 36</span>
                    </div>
                    <div className="specs-row meta-item">
                      <span className="specs-key label">Signature Scheme</span>
                      <span className="specs-val value mono">v2 APK signature, single signer</span>
                    </div>
                    <div className="specs-row meta-item">
                      <span className="specs-key label">Package Size</span>
                      <span className="specs-val value mono">~45 MB (Universal APK)</span>
                    </div>
                  </div>
                </div>

                {/* Checksums & Verification */}
                <div>
                  <div className="build-card">
                    <h4>Cryptographic Checksums (v0.9.0)</h4>
                    <p>Verify that your downloaded release artifact matches the official build SHA-256 before sideloading.</p>

                    <div style={{ marginBottom: 16 }}>
                      <div className="eyebrow" style={{ fontSize: 11, marginBottom: 6 }}>
                        Release APK SHA-256
                      </div>
                      <CopySnippet text="A2D3FED1F2F612A16AE9B28EE6C58C21FDC35A11AE326F32A70776492FEE5AF2" />
                    </div>

                    <div style={{ marginBottom: 16 }}>
                      <div className="eyebrow" style={{ fontSize: 11, marginBottom: 6 }}>
                        Android App Bundle (.aab) SHA-256
                      </div>
                      <CopySnippet text="121D39677EB42DB5100049BA4D53A82BE70382552FD17E0D86961041D63A2D50" />
                    </div>

                    <div>
                      <div className="eyebrow" style={{ fontSize: 11, marginBottom: 6 }}>
                        Upload Certificate SHA-256
                      </div>
                      <CopySnippet text="BB:0A:17:52:1A:CA:41:B7:DD:EC:6E:85:8B:2C:C8:31:16:51:8F:C7:98:72:E1:B1:88:36:FC:EA:B8:74:5C:95" />
                    </div>
                  </div>

                  <div className="build-card" style={{ marginTop: 20 }}>
                    <h4>Compile From Source</h4>
                    <p>Relay is open source. You can compile the release binary directly from the terminal:</p>
                    <CopySnippet text="flutter build apk --release --no-tree-shake-icons" />
                    <div style={{ fontSize: 12, color: "var(--ink-muted)", marginTop: 10 }}>
                      Requires Flutter 3.41+ and Android SDK 34+.
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Sideloading Installation Guide */}
            <div className="section-head" style={{ marginTop: 40 }}>
              <div className="eyebrow">[ INSTALLATION GUIDE ]</div>
              <h2 className="display display-3">How to install the APK on Android.</h2>
            </div>

            <div className="principles-grid principles">
              <div className="principle-item principle">
                <div className="principle-idx idx">01</div>
                <div>
                  <h4>Download the Release APK</h4>
                  <p>
                    Download `app-release.apk` directly from GitHub Releases to your Android device using Chrome, Firefox, or any mobile browser.
                  </p>
                </div>
              </div>
              <div className="principle-item principle">
                <div className="principle-idx idx">02</div>
                <div>
                  <h4>Enable Unknown Sources</h4>
                  <p>
                    When opening the APK, Android may ask permission to "Install unknown apps" from your browser. Allow this once in Android Settings.
                  </p>
                </div>
              </div>
              <div className="principle-item principle">
                <div className="principle-idx idx">03</div>
                <div>
                  <h4>Verify Cryptographic Hash</h4>
                  <p>
                    Optionally verify that the SHA-256 hash matches the string published on this page using any file-hash utility.
                  </p>
                </div>
              </div>
              <div className="principle-item principle">
                <div className="principle-idx idx">04</div>
                <div>
                  <h4>Open & Import</h4>
                  <p>
                    Launch Relay. Tap the `+` button in your library to import your first PDF or EPUB document from device storage.
                  </p>
                </div>
              </div>
            </div>

            {/* Release Notes */}
            <div className="section-head" style={{ marginTop: 64 }}>
              <div className="eyebrow">[ RELEASE NOTES ]</div>
              <h2 className="display display-3">What's new in v0.9.0.</h2>
            </div>

            <div className="spec-box" style={{ padding: 32 }}>
              <ul style={{ paddingLeft: 20, color: "var(--ink-secondary)", fontSize: 15, lineHeight: 1.8 }}>
                <li><strong>Cross-network share subsystem:</strong> Introduced sender-owned session orchestration with single-use QR envelopes and WebRTC signaling client architecture.</li>
                <li><strong>Drift SQLite storage engine:</strong> Persists reading positions, page bookmarks, format filters, and verified transfer histories.</li>
                <li><strong>Bounded memory streaming:</strong> Streams file data in 64 KiB segments with on-the-fly SHA-256 verification and automatic `.part` file cleanup on interruption.</li>
                <li><strong>Sanitized EPUB rendering:</strong> Restricts inline media to bounded raster images (PNG, JPEG, GIF); excludes SVG and external URLs for security.</li>
                <li><strong>Hardened boundaries:</strong> JSON frames reject nesting beyond 32 levels; metadata strips control and bidi characters; manual PIN entry rotates after 5 failed guesses.</li>
              </ul>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
