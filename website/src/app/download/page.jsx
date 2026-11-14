import Link from "next/link";
import Image from "next/image";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";
import CopyButton from "@/components/CopyButton";
import { asset } from "@/lib/asset";

const RELEASE = "https://github.com/halloffame12/Relay/releases/tag/v0.9.0";
const APK =
  "https://github.com/halloffame12/Relay/releases/download/v0.9.0/app-release.apk";
const AAB =
  "https://github.com/halloffame12/Relay/releases/download/v0.9.0/app-release.aab";

const APK_SHA =
  "3906DBBE0D986C3334071E6C94FE727E4729FFF53EB49CAE0B0092006ABD253D";
const AAB_SHA =
  "FAB21FFE8F329815664FA8D55AF9EB7A47A9C238F03D040640C6821491437242";
const CERT_SHA =
  "BB:0A:17:52:1A:CA:41:B7:DD:EC:6E:85:8B:2C:C8:31:16:51:8F:C7:98:72:E1:B1:88:36:FC:EA:B8:74:5C:95";

export const metadata = {
  title: "Download",
  description:
    "Download Relay 0.9.0 for Android. Verified APK and App Bundle, checksums, install steps and release notes.",
  alternates: { canonical: "/download" },
  openGraph: {
    title: "Download Relay 0.9.0",
    description:
      "Relay for Android 7.0+. APK and AAB downloads with SHA-256 checksums.",
    url: "/download",
  },
};

export default function Download() {
  return (
    <>
      <Header />
      <main id="main-content">
        <section className="page-head">
          <div className="wrap">
            <div className="page-head__meta">
              <span>Download</span>
              <span>0.9.0 / Android</span>
            </div>
            <div className="page-head__grid">
              <div>
                <h1 className="display display-1">Get Relay.</h1>
                <p className="lede">
                  An Android release build, attached to the public GitHub
                  release. No account and no Play Store dependency.
                </p>
              </div>
              <div className="page-head__aside">
                <p className="small muted">
                  Google Play is not published yet, so there is no Play badge or
                  Play link here. The APK below is the current release artifact.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className="section">
          <div className="wrap">
            <div className="download-grid">
              <Reveal>
                <div className="release-card">
                  <div className="release-card__top">
                    <div className="release-card__title">
                      <span className="release-card__icon">
                        <Image
                          src={asset("/assets/brand/icon-128.png")}
                          alt=""
                          width={44}
                          height={44}
                        />
                      </span>
                      <div>
                        <div className="release-card__name">Relay for Android</div>
                        <div className="release-card__sub">Version 0.9.0 · build 1</div>
                      </div>
                    </div>
                    <span className="badge badge--lime">Release candidate</span>
                  </div>

                  <div className="release-card__body">
                    <div className="meta-grid">
                      <div>
                        <dt>Minimum Android</dt>
                        <dd>7.0 (API 24)</dd>
                      </div>
                      <div>
                        <dt>Target SDK</dt>
                        <dd>API 36</dd>
                      </div>
                      <div>
                        <dt>APK size</dt>
                        <dd>~117 MB</dd>
                      </div>
                      <div>
                        <dt>Package</dt>
                        <dd className="mono" style={{ fontSize: 11.5, wordBreak: "break-all" }}>
                          io.github.halloffame12.relay
                        </dd>
                      </div>
                    </div>

                    <div className="release-card__actions">
                      <a className="btn btn--primary" href={APK}>
                        Download APK <span className="arrow" aria-hidden="true">↓</span>
                      </a>
                      <a className="btn btn--ghost" href={AAB}>
                        Download AAB <span className="arrow" aria-hidden="true">↓</span>
                      </a>
                      <a
                        className="btn btn--ghost"
                        href={RELEASE}
                        target="_blank"
                        rel="noopener noreferrer"
                      >
                        Release notes <span className="arrow" aria-hidden="true">↗</span>
                      </a>
                    </div>

                    <p className="small muted">
                      The APK is signed with the Relay upload key. Enable
                      &ldquo;Install unknown apps&rdquo; for your browser or file
                      manager, open the downloaded file, and confirm the install.
                      Android may show a Play Protect prompt for apps installed
                      outside Play.
                    </p>

                    <details className="disclosure">
                      <summary>Build from source instead</summary>
                      <div>
                        <p className="small muted">
                          Requires Flutter 3.41.x and the Android SDK. Run these
                          from the repository root.
                        </p>
                        <pre className="code-block">
{`flutter pub get
flutter build apk --release --no-tree-shake-icons`}
                        </pre>
                        <p className="small muted">
                          For a cross-network build, point the app at your own
                          signaling service:
                        </p>
                        <pre className="code-block">
{`flutter build apk --release --no-tree-shake-icons \\
  --dart-define=RELAY_SIGNALING_URL=wss://your-host/v1/relay`}
                        </pre>
                      </div>
                    </details>
                  </div>
                </div>
              </Reveal>

              <Reveal delay={80}>
                <div className="checksums">
                  <h2>Verify the download</h2>
                  <p>
                    Compare the SHA-256 of the file you downloaded with the
                    value below. The certificate fingerprint identifies the
                    signing key.
                  </p>

                  <div className="check-row">
                    <div className="check-row__label">
                      <span>APK · SHA-256</span>
                      <CopyButton value={APK_SHA} label="APK SHA-256 checksum" />
                    </div>
                    <div className="check-row__value">
                      <code>{APK_SHA}</code>
                    </div>
                  </div>

                  <div className="check-row">
                    <div className="check-row__label">
                      <span>AAB · SHA-256</span>
                      <CopyButton value={AAB_SHA} label="AAB SHA-256 checksum" />
                    </div>
                    <div className="check-row__value">
                      <code>{AAB_SHA}</code>
                    </div>
                  </div>

                  <div className="check-row">
                    <div className="check-row__label">
                      <span>Signing certificate · SHA-256</span>
                      <CopyButton value={CERT_SHA} label="Signing certificate fingerprint" />
                    </div>
                    <div className="check-row__value">
                      <code>{CERT_SHA}</code>
                    </div>
                  </div>

                  <div style={{ marginTop: 18 }}>
                    <p className="kicker" style={{ marginBottom: 8 }}>Windows</p>
                    <pre className="code-block">Get-FileHash .\app-release.apk -Algorithm SHA256</pre>
                    <p className="kicker" style={{ margin: "14px 0 8px" }}>macOS / Linux</p>
                    <pre className="code-block">shasum -a 256 app-release.apk</pre>
                    <p className="kicker" style={{ margin: "14px 0 8px" }}>Signature</p>
                    <pre className="code-block">apksigner verify --print-certs app-release.apk</pre>
                  </div>
                </div>
              </Reveal>
            </div>
          </div>
        </section>

        <section className="section section--soft">
          <div className="wrap">
            <div className="split split--start">
              <Reveal>
                <p className="eyebrow">Release notes</p>
                <h2 className="display display-2" style={{ marginTop: 16 }}>
                  What&apos;s in 0.9.0.
                </h2>
                <ol className="steps-list" style={{ marginTop: 24 }}>
                  <li>
                    <span>
                      <b>Reader.</b> Offline PDF and EPUB reading with position
                      restore, chapters, bookmarks, search and filters.
                    </span>
                  </li>
                  <li>
                    <span>
                      <b>QR sharing.</b> Sender shows a single-use code; receiver
                      scans, reviews and approves the file list.
                    </span>
                  </li>
                  <li>
                    <span>
                      <b>Verification.</b> Per-file SHA-256 and byte-count checks
                      before import, with duplicate detection and no silent
                      overwrites.
                    </span>
                  </li>
                  <li>
                    <span>
                      <b>Cleanup.</b> Cancelling or losing a connection removes
                      temporary data and leaves no library entry.
                    </span>
                  </li>
                  <li>
                    <span>
                      <b>Branding.</b> The official Relay mark across the
                      launcher, splash, reader header and store assets.
                    </span>
                  </li>
                </ol>
              </Reveal>

              <Reveal delay={80}>
                <div className="limits">
                  <p className="eyebrow">Before you install</p>
                  <h3 style={{ marginTop: 12 }}>Three things to know.</h3>
                  <ul>
                    <li>
                      This build is the same-network transfer build. The
                      cross-network path needs a signaling endpoint and is not
                      configured in the published APK.
                    </li>
                    <li>
                      An interrupted transfer is cancelled and cleaned up, not
                      resumed.
                    </li>
                    <li>
                      Local TCP transfers are not transport-encrypted. Use
                      trusted networks for sensitive documents; WebRTC paths are
                      DTLS-encrypted.
                    </li>
                  </ul>
                  <div className="hero-actions" style={{ marginTop: 20 }}>
                    <Link className="btn btn--ghost btn--small" href="/how-it-works">
                      Read the flow
                    </Link>
                    <a
                      className="btn btn--ghost btn--small"
                      href="https://github.com/halloffame12/Relay/issues"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      Report an issue ↗
                    </a>
                  </div>
                </div>
              </Reveal>
            </div>
          </div>
        </section>

        <section className="section section--ink">
          <div className="wrap">
            <Reveal>
              <div className="final__grid">
                <div>
                  <p className="eyebrow">Source</p>
                  <h2 className="display display-2" style={{ marginTop: 16 }}>
                    Don&apos;t install a binary you can&apos;t inspect.
                  </h2>
                  <p className="final__copy">
                    Every screen, the framing protocol and the verification code
                    are in the public repository. Build it yourself if you would
                    rather.
                  </p>
                  <div className="final__actions">
                    <a
                      className="btn btn--primary"
                      href="https://github.com/halloffame12/Relay"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      View source <span className="arrow" aria-hidden="true">↗</span>
                    </a>
                    <Link className="btn btn--ghost" href="/features">
                      Feature list
                    </Link>
                  </div>
                </div>
              </div>
            </Reveal>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
