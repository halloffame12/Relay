import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";
import Image from "next/image";
import Link from "next/link";

export const metadata = {
  title: "Relay - Read offline. Share with a scan.",
  description: "Relay is an offline-first PDF and EPUB reader with QR-based file sharing between devices. No manual network setup.",
};

export default function Home() {
  return (
    <>
      <Header />
      <main>
        <section className="hero">
          <div className="container">
            <div className="hero-grid">
              <div>
                <Reveal>
                  <div className="hero-eyebrow eyebrow">Relay for Android</div>
                </Reveal>
                <Reveal>
                  <h1 className="display display-1">Your library. Your files. Your way.</h1>
                </Reveal>
                <Reveal>
                  <p className="lede hero-sub">
                    Read PDFs and EPUBs offline. Send files between devices with a simple QR scan. No manual network setup. Just Relay.
                  </p>
                </Reveal>
                <Reveal>
                  <div className="hero-ctas">
                    <Link className="btn btn-primary" href="/download">
                      Download Relay <span className="arrow">→</span>
                    </Link>
                    <Link className="btn btn-secondary" href="/how-it-works">
                      Explore how it works
                    </Link>
                  </div>
                  <p className="hero-note">Android. Offline-first. No account required.</p>
                </Reveal>
              </div>
              <Reveal className="composition">
                <span className="floating-badge">v0.9</span>
                <div className="phone phone-main">
                  <Image src="/assets/screenshots/02-library-imported.png" alt="Relay library showing imported documents" width={280} height={600} />
                </div>
                <div className="phone phone-secondary">
                  <Image src="/assets/screenshots/05-nearby.png" alt="Relay nearby sharing screen" width={240} height={520} />
                </div>
                <div className="qr-card">
                  <div className="qr-scan" role="img" aria-label="Illustrative QR code">
                    <svg viewBox="0 0 21 21" width="100%" height="100%" shapeRendering="crispEdges" aria-hidden="true">
                      <rect width="21" height="21" fill="#fff" />
                      <g fill="#0F0F11">
                        <rect x="1" y="1" width="7" height="7" />
                        <rect x="2" y="2" width="5" height="5" fill="#fff" />
                        <rect x="3" y="3" width="3" height="3" />
                        <rect x="13" y="1" width="7" height="7" />
                        <rect x="14" y="2" width="5" height="5" fill="#fff" />
                        <rect x="15" y="3" width="3" height="3" />
                        <rect x="1" y="13" width="7" height="7" />
                        <rect x="2" y="14" width="5" height="5" fill="#fff" />
                        <rect x="3" y="15" width="3" height="3" />
                      </g>
                    </svg>
                  </div>
                  <div className="qr-label">Scan to receive (illustrative)</div>
                </div>
              </Reveal>
            </div>
          </div>
        </section>

        <hr className="rule" />

        <section className="section">
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">Product</div>
                <h2 className="display display-2">Everything you need to keep your documents close.</h2>
                <p className="lede">Relay combines a calm, offline reading library with file sharing that starts with a scan. No cloud account, no manual IP addresses, no port numbers in the normal flow.</p>
              </div>
            </Reveal>
          </div>
        </section>

        <section className="section-tight">
          <div className="container">
            <div className="feature-row reveal">
              <div className="feature-text">
                <div className="eyebrow">Read anywhere</div>
                <h3>PDF and EPUB, offline.</h3>
                <p>Import once. Read on the train, in a plane, or anywhere without a connection. Relay remembers where you stopped.</p>
                <ul className="feature-list">
                  <li>PDF and EPUB support</li>
                  <li>Remembers your last position</li>
                  <li>Bookmarks and search</li>
                  <li>No network required to read</li>
                </ul>
              </div>
              <div className="feature-visual">
                <Image className="screenshot" src="/assets/screenshots/04-reader.png" alt="Relay reader showing a document" width={320} height={560} />
              </div>
            </div>

            <div className="feature-row flip reveal">
              <div className="feature-text">
                <div className="eyebrow">Share with a scan</div>
                <h3>A QR code is the whole handshake.</h3>
                <p>Show a code on one device, scan it with the other. Approve the incoming files before a single byte is written.</p>
                <ul className="feature-list">
                  <li>Single-use, short-lived codes</li>
                  <li>Receiver approval required</li>
                  <li>Integrity verified per file</li>
                  <li>No manual pairing codes in the normal flow</li>
                </ul>
              </div>
              <div className="feature-visual">
                <div className="qr-scan" role="img" aria-label="Illustrative QR code">
                  <svg viewBox="0 0 21 21" width="100%" height="100%" shapeRendering="crispEdges" aria-hidden="true">
                    <rect width="21" height="21" fill="#fff" />
                    <g fill="#0F0F11">
                      <rect x="1" y="1" width="7" height="7" />
                      <rect x="2" y="2" width="5" height="5" fill="#fff" />
                      <rect x="3" y="3" width="3" height="3" />
                      <rect x="13" y="1" width="7" height="7" />
                      <rect x="14" y="2" width="5" height="5" fill="#fff" />
                      <rect x="15" y="3" width="3" height="3" />
                      <rect x="1" y="13" width="7" height="7" />
                      <rect x="2" y="14" width="5" height="5" fill="#fff" />
                      <rect x="3" y="15" width="3" height="3" />
                    </g>
                  </svg>
                </div>
              </div>
            </div>

            <div className="feature-row reveal">
              <div className="feature-text">
                <div className="eyebrow">Across networks</div>
                <h3>Designed for the messy real world.</h3>
                <p>Relay prefers a direct connection and falls back to a relay only when it has to. You never type an IP address or a port.</p>
                <ul className="feature-list">
                  <li>Direct device-to-device when possible</li>
                  <li>Relayed connection as fallback</li>
                  <li>Automatic connection selection</li>
                  <li>Clear status of which path is used</li>
                </ul>
                <p className="muted" style={{ fontSize: 13, marginTop: 12 }}>
                  Cross-network transfer requires a deployed signaling service and is labeled honestly in the app when unavailable.
                </p>
              </div>
              <div className="feature-visual">
                <div className="progress-mock">
                  <div className="eyebrow">Transfer</div>
                  <div style={{ fontSize: 15, marginTop: 6 }}>machine-learning.pdf</div>
                  <div className="progress-bar"><span></span></div>
                  <div className="row" style={{ justifyContent: "space-between", fontSize: 12, color: "var(--muted)" }}>
                    <span>24.6 MB</span><span>62%</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="feature-row flip reveal">
              <div className="feature-text">
                <div className="eyebrow">Built around your files</div>
                <h3>Local-first. Verified. Transparent.</h3>
                <p>Your library lives on the device. Transfers are checksum-verified before import, and nothing is auto-accepted.</p>
                <ul className="feature-list">
                  <li>App-managed storage</li>
                  <li>SHA-256 verification</li>
                  <li>Duplicate detection</li>
                  <li>Storage usage visibility</li>
                </ul>
              </div>
              <div className="feature-visual">
                <Image className="screenshot" src="/assets/screenshots/03-document-details.png" alt="Relay document details screen" width={320} height={560} />
              </div>
            </div>
          </div>
        </section>

        <section className="section" style={{ background: "var(--bg-soft)" }}>
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">How it works</div>
                <h2 className="display display-2">Understand it in three steps.</h2>
                <p className="lede">No network configuration. No accounts. Just a scan.</p>
              </div>
            </Reveal>
            <div className="steps reveal">
              <div className="step">
                <div className="step-num">01</div>
                <h3>Select</h3>
                <p>Choose PDFs or EPUBs from your Relay library.</p>
              </div>
              <div className="step">
                <div className="step-num">02</div>
                <h3>Scan</h3>
                <p>Show the QR code on one device and scan it with the other.</p>
              </div>
              <div className="step">
                <div className="step-num">03</div>
                <h3>Transfer</h3>
                <p>Approve the incoming files and watch them arrive, verified.</p>
              </div>
            </div>
          </div>
        </section>

        <section className="section">
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">Reliability</div>
                <h2 className="display display-2">Built on simple rules.</h2>
              </div>
            </Reveal>
            <div className="principles reveal">
              <div className="principle">
                <div className="idx">01</div>
                <div>
                  <h4>Simple connections</h4>
                  <p>Pairing is a scan. No typed addresses, ports or codes in the normal flow.</p>
                </div>
              </div>
              <div className="principle">
                <div className="idx">02</div>
                <div>
                  <h4>Efficient transfers</h4>
                  <p>Files stream with bounded memory. Only manifests stay in RAM.</p>
                </div>
              </div>
              <div className="principle">
                <div className="idx">03</div>
                <div>
                  <h4>Reliable handling</h4>
                  <p>Interrupted transfers leave no library entry and no leftover files.</p>
                </div>
              </div>
              <div className="principle">
                <div className="idx">04</div>
                <div>
                  <h4>Offline reading</h4>
                  <p>Your library works without a connection. Reading never depends on a server.</p>
                </div>
              </div>
            </div>
          </div>
        </section>

        <section className="section" style={{ background: "var(--bg-soft)" }}>
          <div className="container">
            <Reveal>
              <div className="grid-2 asym">
                <div>
                  <div className="eyebrow">Privacy</div>
                  <h2 className="display display-2">Your documents should stay yours.</h2>
                </div>
                <div>
                  <p className="lede">
                    Relay keeps your library on the device and never auto-accepts a file. Direct transfers move between devices without a cloud relay. Cross-network transfers may use a relay only when a direct path is unavailable, and that relay sees encrypted packets, not file contents.
                  </p>
                  <p className="body" style={{ marginTop: 16 }}>
                    Relay does not claim end-to-end encryption for the local network path, and it does not upload your documents to cloud storage.
                  </p>
                </div>
              </div>
            </Reveal>
          </div>
        </section>

        <section className="cta-band">
          <div className="container">
            <div className="eyebrow" style={{ color: "color-mix(in srgb, var(--bg) 60%, transparent)" }}>Get started</div>
            <h2 className="display display-2" style={{ margin: "18px 0 18px" }}>A simpler way to read and share.</h2>
            <p>Download Relay and keep your documents close.</p>
            <div className="row" style={{ marginTop: 32 }}>
              <Link className="btn btn-primary" href="/download">
                Download Relay <span className="arrow">→</span>
              </Link>
              <Link className="btn btn-secondary" href="/features">
                Discover Relay
              </Link>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
