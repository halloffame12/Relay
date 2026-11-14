import Link from "next/link";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";
import WorkflowTabs from "@/components/WorkflowTabs";
import NetworkDiagram from "@/components/NetworkDiagram";

export const metadata = {
  title: "How it works",
  description:
    "How Relay restores your reading position, and how a document travels from one device to another with a QR scan, receiver approval and SHA-256 verification.",
  alternates: { canonical: "/how-it-works" },
  openGraph: {
    title: "How Relay works — read and share",
    description:
      "Two workflows: reading that resumes where you stopped, and sharing that starts with a scan.",
    url: "/how-it-works",
  },
};

export default function HowItWorks() {
  return (
    <>
      <Header />
      <main id="main-content">
        <section className="page-head">
          <div className="wrap">
            <div className="page-head__meta">
              <span>How it works</span>
              <span>Reading / Sharing</span>
            </div>
            <div className="page-head__grid">
              <div>
                <h1 className="display display-1">
                  Two experiences. One app.
                </h1>
                <p className="lede">
                  Reading that remembers you, and sharing that needs nothing
                  more than a scan. Here is the whole flow, without the
                  networking vocabulary.
                </p>
              </div>
              <div className="page-head__aside">
                <p className="small muted">
                  Everything below reflects the 0.9.0 implementation. Where a
                  capability depends on configuration, it says so.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className="section">
          <div className="wrap">
            <Reveal>
              <WorkflowTabs />
            </Reveal>
          </div>
        </section>

        <section className="section section--soft">
          <div className="wrap">
            <div className="split split--start">
              <Reveal>
                <p className="eyebrow">Connection paths</p>
                <h2 className="display display-2" style={{ marginTop: 16 }}>
                  Direct first. Relayed only when needed.
                </h2>
                <p className="lede" style={{ marginTop: 20 }}>
                  Relay tries the shortest path it can find. You do not choose a
                  route, type an address, or open a port.
                </p>
                <ol className="steps-list" style={{ marginTop: 26 }}>
                  <li>
                    <span>
                      <b>Same network.</b> The devices find each other on the
                      local network and transfer directly. Nothing in the path
                      stores the document.
                    </span>
                  </li>
                  <li>
                    <span>
                      <b>Different networks.</b> A small signaling room
                      exchanges session and connection metadata so the devices
                      can attempt a direct WebRTC connection. It never receives
                      file bytes.
                    </span>
                  </li>
                  <li>
                    <span>
                      <b>Restrictive network.</b> If no direct path works, TURN
                      relays encrypted WebRTC packets. The relay forwards
                      traffic; it does not keep a copy.
                    </span>
                  </li>
                </ol>
                <p className="small muted" style={{ marginTop: 20, maxWidth: "52ch" }}>
                  Not every network permits a direct connection, and Relay does
                  not pretend otherwise. The app labels the path it actually
                  used.
                </p>
              </Reveal>
              <Reveal delay={80}>
                <NetworkDiagram />
              </Reveal>
            </div>
          </div>
        </section>

        <section className="section">
          <div className="wrap">
            <Reveal>
              <div className="section-head section-head--stack">
                <div>
                  <p className="eyebrow">The normal flow</p>
                  <h2 className="display display-2">
                    What Relay will never ask you for.
                  </h2>
                </div>
              </div>
            </Reveal>

            <div className="ledger">
              <div className="ledger__row">
                <span className="ledger__num">01</span>
                <span className="ledger__k">An IP address</span>
                <span className="ledger__v">The devices work this out themselves, on the local network or through signaling.</span>
                <span className="ledger__tag">Not in the UI</span>
              </div>
              <div className="ledger__row">
                <span className="ledger__num">02</span>
                <span className="ledger__k">A port number</span>
                <span className="ledger__v">There is no field to fill. The transport opens what it needs and reports the result.</span>
                <span className="ledger__tag">Not in the UI</span>
              </div>
              <div className="ledger__row">
                <span className="ledger__num">03</span>
                <span className="ledger__k">A pairing code</span>
                <span className="ledger__v">The QR code is the whole handshake. It is single-use and expires in minutes.</span>
                <span className="ledger__tag">Not in the UI</span>
              </div>
              <div className="ledger__row">
                <span className="ledger__num">04</span>
                <span className="ledger__k">A cloud account</span>
                <span className="ledger__v">No registration is needed to read, import or share a document.</span>
                <span className="ledger__tag">None</span>
              </div>
            </div>

            <p className="small muted" style={{ marginTop: 20, maxWidth: "58ch" }}>
              A manual connection path exists in the codebase for older
              transfers, but the current sharing screens are QR-only. Nothing on
              this page asks you to configure a network.
            </p>
          </div>
        </section>

        <section className="section section--ink">
          <div className="wrap">
            <Reveal>
              <div className="final__grid">
                <div>
                  <p className="eyebrow">Try it</p>
                  <h2 className="display display-2" style={{ marginTop: 16 }}>
                    One device reads. Two devices scan.
                  </h2>
                  <p className="final__copy">
                    Download Relay, import a document, then start a transfer on
                    your own network.
                  </p>
                  <div className="final__actions">
                    <Link className="btn btn--primary" href="/download">
                      Get Relay <span className="arrow" aria-hidden="true">→</span>
                    </Link>
                    <Link className="btn btn--ghost" href="/features">
                      See every feature
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
