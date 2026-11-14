import Link from "next/link";
import Image from "next/image";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";
import Phone from "@/components/Phone";
import ShareScreen from "@/components/ShareScreen";
import FlowSteps from "@/components/FlowSteps";
import NetworkDiagram from "@/components/NetworkDiagram";
import { asset } from "@/lib/asset";

export const metadata = {
  title: "Read without losing your place. Share with a scan.",
  description:
    "Relay is an offline-first PDF and EPUB reader for Android. Resume exactly where you stopped, and send documents to another device with a single QR scan.",
  alternates: { canonical: "/" },
};

export default function Home() {
  return (
    <>
      <Header />
      <main id="main-content">
        {/* Hero */}
        <section className="hero">
          <div className="wrap">
            <div className="hero-meta">
              <span className="hero-meta__left">
                <span className="hero-meta__dot" aria-hidden="true" />
                Relay / Android / 0.9.0
              </span>
              <span className="hero-meta__right">
                <span>Offline PDF + EPUB</span>
                <span>No account</span>
              </span>
            </div>

            <h1 className="display display-1 hero-title">
              <span className="line">
                Read without losing <em>your place.</em>
              </span>
              <span className="line line--shift">
                <em>Share</em> without the setup.
              </span>
            </h1>

            <div className="hero-body">
              <Reveal className="hero-copy">
                <p className="lede">
                  Relay keeps your PDFs and EPUBs close, remembers where you
                  stopped, and lets you send documents to another device with a
                  simple QR scan.
                </p>
                <div className="hero-actions">
                  <Link className="btn btn--primary" href="/download">
                    Get Relay <span className="arrow" aria-hidden="true">→</span>
                  </Link>
                  <a
                    className="btn btn--ghost"
                    href="https://github.com/halloffame12/Relay"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    Explore on GitHub <span className="arrow" aria-hidden="true">↗</span>
                  </a>
                </div>
                <p className="hero-note">
                  <span>Android 7.0+</span>
                  <span>Version 0.9.0</span>
                  <span>No account required</span>
                </p>
              </Reveal>

              <Reveal className="stage" delay={120}>
                <Phone
                  className="device--reader"
                  device="Reading"
                  caption="Offline · resumes"
                >
                  <Image
                    src={asset("/assets/screenshots/04-reader.png")}
                    alt="Relay reader showing an EPUB open at chapter one, with reading progress and a bookmark button"
                    width={1080}
                    height={1920}
                    sizes="(max-width: 560px) 50vw, (max-width: 860px) 27vw, 240px"
                    priority
                  />
                </Phone>
                <Phone
                  className="device--share"
                  device="Sharing"
                  caption="One scan · no setup"
                >
                  <ShareScreen screen="qr" />
                </Phone>
              </Reveal>
            </div>

            <div className="spec-strip">
              <div className="spec">
                <span className="spec__k">Read</span>
                <span className="spec__v">PDF and EPUB, fully offline</span>
              </div>
              <div className="spec">
                <span className="spec__k">Resume</span>
                <span className="spec__v">Last position restored</span>
              </div>
              <div className="spec">
                <span className="spec__k">Share</span>
                <span className="spec__v">One QR scan, no setup</span>
              </div>
              <div className="spec">
                <span className="spec__k">Verify</span>
                <span className="spec__v">SHA-256 before import</span>
              </div>
            </div>
          </div>
        </section>

        {/* Reading continuity */}
        <section className="section" id="reading">
          <div className="wrap">
            <div className="split split--start">
              <Reveal>
                <p className="eyebrow">01 / Reading continuity</p>
                <h2 className="display display-2" style={{ marginTop: 16 }}>
                  Close the app. Come back. Pick up exactly where you left off.
                </h2>
                <p className="lede" style={{ marginTop: 20 }}>
                  Your reading progress stays with your library. Open a PDF or
                  EPUB, leave whenever you need to, and return to the same place.
                </p>
                <div className="fact-list">
                  <div className="fact">
                    <span className="fact__num">01</span>
                    <div>
                      <h3>Recently opened</h3>
                      <p>The library sorts by what you touched last, so the current document is always one tap away.</p>
                    </div>
                  </div>
                  <div className="fact">
                    <span className="fact__num">02</span>
                    <div>
                      <h3>Bookmarks that stay put</h3>
                      <p>Mark a page or chapter in the reader and return to it without searching or scrolling.</p>
                    </div>
                  </div>
                  <div className="fact">
                    <span className="fact__num">03</span>
                    <div>
                      <h3>Search and filters</h3>
                      <p>Find a document by title, author or source, then narrow by format and reading status.</p>
                    </div>
                  </div>
                  <div className="fact">
                    <span className="fact__num">04</span>
                    <div>
                      <h3>Offline by default</h3>
                      <p>Reading never opens a network socket. The library is a local database on the device.</p>
                    </div>
                  </div>
                </div>
              </Reveal>

              <Reveal className="read-visual" delay={80}>
                <Phone device="Library" caption="Recently added">
                  <Image
                    src={asset("/assets/screenshots/02-library-imported.png")}
                    alt="Relay library showing an imported EPUB with search, sort, filters and a document card"
                    width={1080}
                    height={1920}
                    sizes="(max-width: 980px) 34vw, 220px"
                  />
                </Phone>
                <Phone device="Reader" caption="Chapter 1 of 2">
                  <Image
                    src={asset("/assets/screenshots/04-reader.png")}
                    alt="Relay reader with an EPUB open, showing chapter progress and the bookmark control"
                    width={1080}
                    height={1920}
                    sizes="(max-width: 980px) 34vw, 220px"
                  />
                </Phone>
                <div className="resume-strip">
                  <span>Resumes at your last position</span>
                  <span className="resume-strip__bar" aria-hidden="true">
                    <span />
                  </span>
                  <span>0%</span>
                </div>
              </Reveal>
            </div>
          </div>
        </section>

        {/* Sharing */}
        <section className="section section--ink" id="sharing">
          <div className="wrap">
            <Reveal>
              <div className="section-head">
                <div>
                  <p className="eyebrow">02 / Sharing with a scan</p>
                  <h2 className="display display-2">
                    The easiest way to explain file sharing: scan this.
                  </h2>
                </div>
                <p className="lede">
                  Select a document. Show a QR code. Let the other device scan
                  it. Review and approve. That&apos;s it.
                </p>
              </div>
            </Reveal>

            <Reveal delay={60}>
              <FlowSteps />
            </Reveal>

            <Reveal delay={80}>
              <p
                className="mono"
                style={{
                  marginTop: 36,
                  paddingTop: 18,
                  borderTop: "1px solid var(--line)",
                  fontSize: 10.5,
                  letterSpacing: "0.1em",
                  textTransform: "uppercase",
                  color: "var(--muted)",
                }}
              >
                No IP addresses. No ports. No pairing codes to type.
              </p>
            </Reveal>
          </div>
        </section>

        {/* Networks */}
        <section className="section" id="networks">
          <div className="wrap">
            <div className="split split--start">
              <Reveal>
                <p className="eyebrow">03 / Across networks</p>
                <h2 className="display display-2" style={{ marginTop: 16 }}>
                  Your devices don&apos;t have to share a Wi-Fi network.
                </h2>
                <p className="lede" style={{ marginTop: 20 }}>
                  Relay is designed to connect devices across different
                  networks. It prefers direct device-to-device connections and
                  uses relay infrastructure when a direct connection isn&apos;t
                  available.
                </p>
                <p className="body" style={{ marginTop: 16 }}>
                  There is no address to type and no route to choose. Relay
                  picks the path and labels the one it used.
                </p>
                <div className="fact-list" style={{ marginTop: 26 }}>
                  <div className="fact">
                    <span className="fact__num">→</span>
                    <div>
                      <h3>Direct peer-to-peer</h3>
                      <p>On the same network, the two devices connect to each other. Nothing sits in the middle.</p>
                    </div>
                  </div>
                  <div className="fact">
                    <span className="fact__num">→</span>
                    <div>
                      <h3>Signaling for the introduction</h3>
                      <p>A small WebSocket room exchanges session and connection metadata. It does not carry file bytes.</p>
                    </div>
                  </div>
                  <div className="fact">
                    <span className="fact__num">→</span>
                    <div>
                      <h3>Relay only as a fallback</h3>
                      <p>When a restrictive network blocks a direct path, TURN relays encrypted WebRTC packets.</p>
                    </div>
                  </div>
                </div>
                <p className="small muted" style={{ marginTop: 22, maxWidth: "46ch" }}>
                  The published 0.9.0 APK transfers between devices on the same
                  network. Cross-network support is implemented, but that build
                  needs a configured signaling endpoint; the app states which
                  mode it is in.{" "}
                  <Link className="text-link" href="/how-it-works">
                    How the connection is chosen
                  </Link>
                </p>
              </Reveal>

              <Reveal delay={80}>
                <NetworkDiagram />
                <div className="sees" style={{ marginTop: 18 }}>
                  <div className="sees__col sees__col--yes">
                    <p className="sees__head">Signaling / relay sees</p>
                    <ul>
                      <li>Session and room identifiers</li>
                      <li>IP addresses and connection metadata</li>
                      <li>Transfer volume, if TURN is used</li>
                    </ul>
                  </div>
                  <div className="sees__col sees__col--no">
                    <p className="sees__head">Never</p>
                    <ul>
                      <li>Your document contents</li>
                      <li>Your library or reading history</li>
                      <li>An account or profile</li>
                    </ul>
                  </div>
                </div>
              </Reveal>
            </div>
          </div>
        </section>

        {/* Built with care */}
        <section className="section section--soft" id="care">
          <div className="wrap">
            <Reveal>
              <div className="section-head">
                <div>
                  <p className="eyebrow">04 / Built with care</p>
                  <h2 className="display display-2">
                    A transfer should arrive exactly as it was sent.
                  </h2>
                </div>
                <p className="lede">
                  The receiver holds the last word, and the bytes have to prove
                  themselves before anything joins the library.
                </p>
              </div>
            </Reveal>

            <div className="ledger">
              <div className="ledger__row">
                <span className="ledger__num">01</span>
                <span className="ledger__k">Byte count</span>
                <span className="ledger__v">The declared size is checked against what actually arrived. A short or oversized file is rejected.</span>
                <span className="ledger__tag">Checked</span>
              </div>
              <div className="ledger__row">
                <span className="ledger__num">02</span>
                <span className="ledger__k">SHA-256</span>
                <span className="ledger__v">Both sides hash the stream. The receiver requires a matching digest before import.</span>
                <span className="ledger__tag">Verified</span>
              </div>
              <div className="ledger__row">
                <span className="ledger__num">03</span>
                <span className="ledger__k">Duplicate detection</span>
                <span className="ledger__v">A document already in the library is reported as a duplicate, never silently replaced.</span>
                <span className="ledger__tag">No overwrite</span>
              </div>
              <div className="ledger__row">
                <span className="ledger__num">04</span>
                <span className="ledger__k">Explicit approval</span>
                <span className="ledger__v">The receiver sees the file list and approves it. Nothing is written before that moment.</span>
                <span className="ledger__tag">Consent</span>
              </div>
              <div className="ledger__row">
                <span className="ledger__num">05</span>
                <span className="ledger__k">Interrupted transfers</span>
                <span className="ledger__v">Cancelling closes the connection and removes temporary data. No half-written entry is left behind.</span>
                <span className="ledger__tag">Clean</span>
              </div>
            </div>

            <p className="small muted" style={{ marginTop: 22, maxWidth: "62ch" }}>
              These are implementation checks, not marketing guarantees. You can
              read the protocol and verification code in the public repository.
            </p>
          </div>
        </section>

        {/* No accounts */}
        <section className="section" id="privacy">
          <div className="wrap">
            <div className="split split--start">
              <Reveal>
                <p className="eyebrow">05 / No accounts</p>
                <h2 className="display display-2" style={{ marginTop: 16 }}>
                  Your documents don&apos;t need another cloud account.
                </h2>
                <p className="lede" style={{ marginTop: 20 }}>
                  Relay has no sign-up, no profile and no document sync service.
                  The library is yours, on the device. Sharing happens between
                  two Relay devices, not through a cloud library.
                </p>
                <p className="body" style={{ marginTop: 16 }}>
                  Signaling is a connection helper, not storage. It introduces
                  two devices and then steps out of the file path. Relay never
                  uploads your documents to cloud storage.
                </p>
                <p style={{ marginTop: 22 }}>
                  <Link className="text-link" href="/privacy">
                    Read the privacy details <span className="arrow" aria-hidden="true">→</span>
                  </Link>
                </p>
              </Reveal>

              <Reveal delay={80}>
                <div className="sees">
                  <div className="sees__col sees__col--yes">
                    <p className="sees__head">What Relay has</p>
                    <ul>
                      <li>A local document library</li>
                      <li>On-device reading progress and bookmarks</li>
                      <li>Camera access only while scanning</li>
                      <li>A direct path that needs no account</li>
                    </ul>
                  </div>
                  <div className="sees__col sees__col--no">
                    <p className="sees__head">What it does not</p>
                    <ul>
                      <li>Registration or sign-in</li>
                      <li>Cloud document storage</li>
                      <li>Ads or behavioral analytics</li>
                      <li>Automatic file acceptance</li>
                    </ul>
                  </div>
                </div>
                <p className="small muted" style={{ marginTop: 16, maxWidth: "44ch" }}>
                  Local network transfers use Relay&apos;s own TCP path. WebRTC
                  paths are DTLS-encrypted. Relay does not claim end-to-end
                  encryption for the local TCP path.
                </p>
              </Reveal>
            </div>
          </div>
        </section>

        {/* Open source */}
        <section className="section band--lime">
          <div className="wrap">
            <Reveal>
              <div className="os-band">
                <div>
                  <p className="eyebrow" style={{ color: "#3f4a10" }}>
                    06 / Built in the open
                  </p>
                  <h2 className="display display-2" style={{ marginTop: 16 }}>
                    Built in the open. Improved with feedback.
                  </h2>
                </div>
                <div className="os-band__side">
                  <p className="body" style={{ color: "#20260c" }}>
                    Relay is an evolving project with a public source
                    repository. Explore the code, report bugs, suggest
                    improvements, or contribute. No testimonials, no invented
                    community numbers — just the repository.
                  </p>
                  <a
                    className="btn"
                    href="https://github.com/halloffame12/Relay"
                    target="_blank"
                    rel="noopener noreferrer"
                    style={{ "--btn-bg": "#0e0e10", "--btn-fg": "#c5e74d", "--btn-line": "#0e0e10" }}
                  >
                    Explore Relay on GitHub <span className="arrow" aria-hidden="true">↗</span>
                  </a>
                  <span className="os-handle">github.com/halloffame12/Relay</span>
                </div>
              </div>
            </Reveal>
          </div>
        </section>

        {/* Final CTA */}
        <section className="section section--ink final">
          <div className="wrap">
            <Reveal>
              <div className="final__grid">
                <div>
                  <p className="eyebrow">Get started</p>
                  <h2 className="display display-1" style={{ marginTop: 18 }}>
                    A better way to keep reading and sharing.
                  </h2>
                  <p className="final__copy">
                    Your library stays close. Your reading progress stays with
                    you. Sharing takes a scan.
                  </p>
                  <div className="final__actions">
                    <Link className="btn btn--primary" href="/download">
                      Get Relay <span className="arrow" aria-hidden="true">→</span>
                    </Link>
                    <a
                      className="btn btn--ghost"
                      href="https://github.com/halloffame12/Relay"
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      View source code <span className="arrow" aria-hidden="true">↗</span>
                    </a>
                  </div>
                </div>
                <Image
                  className="final__mark"
                  src={asset("/assets/brand/icon-512.png")}
                  alt=""
                  width={512}
                  height={512}
                />
              </div>
            </Reveal>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
