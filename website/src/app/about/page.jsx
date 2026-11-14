import Link from "next/link";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";

export const metadata = {
  title: "About",
  description:
    "Why Relay exists: one app for reading without losing your place, and sharing a document without network setup.",
  alternates: { canonical: "/about" },
  openGraph: {
    title: "About Relay",
    description:
      "Two frustrations, one app: reading that remembers you, sharing that takes a scan.",
    url: "/about",
  },
};

export default function About() {
  return (
    <>
      <Header />
      <main id="main-content">
        <section className="page-head">
          <div className="wrap">
            <div className="page-head__meta">
              <span>About</span>
              <span>Independent / public source</span>
            </div>
            <div className="page-head__grid">
              <div>
                <h1 className="display display-1">
                  Two frustrations. One app.
                </h1>
                <p className="lede">
                  Relay began with a lost page and a needlessly complicated
                  transfer. It is an attempt to make both experiences boring in
                  the best way.
                </p>
              </div>
              <div className="page-head__aside">
                <p className="small muted">
                  An independent Android project, built in the open. No company
                  behind it, no growth metrics in the copy, and no pretend
                  testimonials.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className="section">
          <div className="wrap">
            <div className="about-story">
              <aside className="about-story__aside">
                <p className="eyebrow">The story</p>
                <p className="kicker" style={{ marginTop: 16 }}>
                  Read offline.<br />
                  Continue where you stopped.<br />
                  Share with a scan.
                </p>
                <div className="hero-actions" style={{ marginTop: 26 }}>
                  <a
                    className="btn btn--ghost btn--small"
                    href="https://github.com/halloffame12/Relay"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    GitHub <span className="arrow" aria-hidden="true">↗</span>
                  </a>
                </div>
              </aside>

              <Reveal className="about-story__body">
                <p className="lead">
                  Relay started with two frustrations: losing your place while
                  reading, and dealing with unnecessary steps when sharing
                  files.
                </p>
                <p>
                  The first is small but constant. You close a PDF to answer
                  something, come back, and the page is gone. The library knows
                  the file exists, but not where you were in it. The second is
                  louder. You want to send one document to the phone in front of
                  you, and suddenly you are reading out an IP address, hunting
                  for a port, or typing a six-digit code that expires while you
                  find it.
                </p>
                <p>
                  The idea was to build one application that makes both
                  experiences simpler. A library that keeps your position. A
                  transfer that starts with a scan and asks the receiver before
                  it writes anything.
                </p>

                <blockquote className="pull">
                  Read offline. Continue where you stopped. Share with a scan.
                </blockquote>

                <p>
                  That sentence set the constraints. The library had to work
                  without a connection, so reading could not depend on a server.
                  Sharing had to work without an account, so the handshake could
                  not rely on a cloud identity. And the receiver had to stay in
                  control, so the file list is shown and approved before the
                  first byte is written.
                </p>
                <p>
                  The rest is engineering discipline. Stream files in bounded
                  chunks instead of loading them into memory. Hash the bytes and
                  compare them. Refuse to overwrite a document that already
                  exists. Clean up after a cancelled transfer. Say which network
                  path was used, rather than implying every network behaves the
                  same.
                </p>
                <p>
                  Relay is still evolving. The published build handles
                  same-network transfers; the cross-network path is written but
                  needs a signaling endpoint. Features are added only when they
                  work end to end, and the website is meant to describe the app
                  that exists, not the one that might.
                </p>
              </Reveal>
            </div>
          </div>
        </section>

        <section className="section section--soft">
          <div className="wrap">
            <Reveal>
              <div className="section-head section-head--stack">
                <div>
                  <p className="eyebrow">Principles</p>
                  <h2 className="display display-2">
                    Rules the product is held to.
                  </h2>
                </div>
              </div>
            </Reveal>

            <div className="principle-grid">
              <div className="principle">
                <span className="principle__num">01</span>
                <h3>Local by default</h3>
                <p>
                  The library, reading position and bookmarks live on the
                  device. Reading is not a network feature.
                </p>
              </div>
              <div className="principle">
                <span className="principle__num">02</span>
                <h3>Consent before bytes</h3>
                <p>
                  The receiver sees the manifest and approves it. No file is
                  written automatically, and nothing is auto-accepted.
                </p>
              </div>
              <div className="principle">
                <span className="principle__num">03</span>
                <h3>Proof over promises</h3>
                <p>
                  SHA-256 and byte counts are checked before import. The code is
                  public, so the claim can be audited.
                </p>
              </div>
              <div className="principle">
                <span className="principle__num">04</span>
                <h3>Honest limits</h3>
                <p>
                  When a capability needs configuration or a network that
                  permits it, the interface says so instead of pretending.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className="section">
          <div className="wrap">
            <div className="split split--start">
              <Reveal>
                <p className="eyebrow">What Relay is not</p>
                <h2 className="display display-2" style={{ marginTop: 16 }}>
                  A small tool, on purpose.
                </h2>
                <p className="lede" style={{ marginTop: 20 }}>
                  Not a cloud drive. Not a social reading network. Not a
                  subscription. The scope is deliberately narrow, because the
                  two core experiences are the point.
                </p>
              </Reveal>
              <Reveal delay={80}>
                <div className="ledger">
                  <div className="ledger__row" style={{ gridTemplateColumns: "40px 1fr" }}>
                    <span className="ledger__num">—</span>
                    <span className="ledger__v">No document uploads to cloud storage.</span>
                  </div>
                  <div className="ledger__row" style={{ gridTemplateColumns: "40px 1fr" }}>
                    <span className="ledger__num">—</span>
                    <span className="ledger__v">No accounts, profiles or reading social graph.</span>
                  </div>
                  <div className="ledger__row" style={{ gridTemplateColumns: "40px 1fr" }}>
                    <span className="ledger__num">—</span>
                    <span className="ledger__v">No ads, trackers or behavioral analytics.</span>
                  </div>
                  <div className="ledger__row" style={{ gridTemplateColumns: "40px 1fr" }}>
                    <span className="ledger__num">—</span>
                    <span className="ledger__v">No claim that every network supports a direct connection.</span>
                  </div>
                </div>
                <p className="small muted" style={{ marginTop: 18 }}>
                  Found something that does not match these statements?{" "}
                  <a
                    className="text-link"
                    href="https://github.com/halloffame12/Relay/issues"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    Open an issue
                  </a>
                  .
                </p>
              </Reveal>
            </div>
          </div>
        </section>

        <section className="section section--ink">
          <div className="wrap">
            <Reveal>
              <div className="final__grid">
                <div>
                  <p className="eyebrow">Continue</p>
                  <h2 className="display display-2" style={{ marginTop: 16 }}>
                    Read the flow, then try it.
                  </h2>
                  <p className="final__copy">
                    The implementation is public, the release is downloadable,
                    and the limitations are written down.
                  </p>
                  <div className="final__actions">
                    <Link className="btn btn--primary" href="/download">
                      Get Relay <span className="arrow" aria-hidden="true">→</span>
                    </Link>
                    <Link className="btn btn--ghost" href="/how-it-works">
                      How it works
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
