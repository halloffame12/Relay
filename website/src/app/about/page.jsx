import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";
import Image from "next/image";
import Link from "next/link";

export const metadata = {
  title: "About — The Thinking Behind Relay",
  description:
    "Why we built Relay: A calm, offline-first reading library and honest peer-to-peer file sharing without cloud intermediary accounts.",
};

export default function About() {
  return (
    <>
      <Header />
      <main id="main-content">
        <section className="section">
          <div className="container">
            <Reveal>
              <div className="philosophy-grid">
                <div>
                  <div className="eyebrow">[ MANIFESTO ]</div>
                  <h1 className="display display-2" style={{ margin: "14px 0 24px" }}>
                    Software built for calm reading and quiet transfers.
                  </h1>
                  <blockquote className="philosophy-quote-lg">
                    "Relay is built around a simple idea: your documents should be easy to read, keep, and share."
                  </blockquote>
                </div>

                <div className="prose-editorial">
                  <p>
                    Modern software has complicated two very simple human acts: reading a book and sharing a document with someone sitting across the table.
                  </p>
                  <p>
                    Today, reading an electronic paper often requires cloud accounts, online license checks, reading telemetry, and apps laden with social feeds. Meanwhile, sharing a 15 MB PDF often requires uploading it to a cloud drive, creating a shareable web link, emailing that link, and waiting for the other person to download it through a web browser.
                  </p>
                  <p>
                    Relay takes a different path. It is designed as an independent, local-first utility.
                    When you import a document into Relay, it stays on your phone. When you share a document,
                    bytes stream directly between the two physical devices. There is no cloud holding your files,
                    no third party inspecting your reading habits, and no subscription paywall.
                  </p>
                  <p>
                    We built Relay because tools that handle our reading lives should feel like physical paper:
                    calm, dependable, private, and durable.
                  </p>
                </div>
              </div>
            </Reveal>
          </div>
        </section>

        {/* Principles Section */}
        <section className="section" style={{ backgroundColor: "var(--bg-soft)", borderTop: "1px solid var(--line)" }}>
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">[ CORE TENETS ]</div>
                <h2 className="display display-2">Our design principles.</h2>
                <p className="lede">
                  The engineering boundaries that guide every line of code we write for Relay.
                </p>
              </div>
            </Reveal>

            <div className="principles-grid">
              <div className="principle-item">
                <div className="principle-idx">01</div>
                <div>
                  <h4>Local First</h4>
                  <p>
                    Your documents, annotations, reading progress, and transfer records belong exclusively to your device storage. Reading never depends on external servers or active internet connections.
                  </p>
                </div>
              </div>

              <div className="principle-item">
                <div className="principle-idx">02</div>
                <div>
                  <h4>Explicit Receiver Consent</h4>
                  <p>
                    No device should ever receive unsolicited files. Relay requires the receiver to consciously review the document name, format, and declared byte size before a single byte touches the disk.
                  </p>
                </div>
              </div>

              <div className="principle-item">
                <div className="principle-idx">03</div>
                <div>
                  <h4>Cryptographic Verification</h4>
                  <p>
                    Every transfer is validated against a SHA-256 digest. Corrupted streams or truncated files are rejected immediately and purged without leaving broken remnants in your library.
                  </p>
                </div>
              </div>

              <div className="principle-item">
                <div className="principle-idx">04</div>
                <div>
                  <h4>Honest Product Communication</h4>
                  <p>
                    We refuse to inflate capabilities. We do not claim end-to-end encryption for unencrypted LAN sockets. We clearly label cross-network relaying as requiring signaling infrastructure. We tell the truth about what the code does.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* The Brand Mark */}
        <section className="section">
          <div className="container">
            <div className="privacy-grid" style={{ alignItems: "center" }}>
              <div>
                <div className="eyebrow">[ BRAND IDENTITY ]</div>
                <h2 className="display display-3" style={{ margin: "12px 0 16px" }}>
                  The Relay Brand Mark
                </h2>
                <p style={{ color: "var(--ink-secondary)", fontSize: 16 }}>
                  The Relay icon represents the tactile intersection of open pages and directed signal transmission.
                  Rendered in deep charcoal, warm terracotta, and acid lime, it embodies the spirit of independent,
                  well-crafted digital tools that prioritize substance over superficiality.
                </p>
                <div className="row" style={{ marginTop: 24 }}>
                  <Link className="btn btn-primary" href="/download">
                    Download Relay <span className="arrow">→</span>
                  </Link>
                  <a
                    className="btn btn-secondary"
                    href="https://github.com/halloffame12/Relay"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    GitHub Source Code ↗
                  </a>
                </div>
              </div>

              <div style={{ display: "flex", justifyContent: "center" }}>
                <div
                  style={{
                    width: 220,
                    height: 220,
                    borderRadius: 36,
                    overflow: "hidden",
                    boxShadow: "var(--shadow-lg)",
                    border: "2px solid var(--line)",
                  }}
                >
                  <Image
                    src="/assets/brand/relay-icon.png"
                    alt="Official Relay Brand Icon"
                    width={220}
                    height={220}
                    priority
                  />
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
