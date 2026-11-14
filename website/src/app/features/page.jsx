import Link from "next/link";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";

export const metadata = {
  title: "Features",
  description:
    "Relay features: offline PDF and EPUB reading, position restore, bookmarks, QR pairing, receiver approval, SHA-256 verification and duplicate detection.",
  alternates: { canonical: "/features" },
  openGraph: {
    title: "Relay features",
    description:
      "What Relay actually does, grouped by reading and sharing, with the limits stated plainly.",
    url: "/features",
  },
};

const GROUPS = [
  {
    id: "reading",
    index: "01",
    title: "Reading",
    intro:
      "A quiet library and a reader that holds your place. Every claim below is in the 0.9.0 build.",
    rows: [
      {
        title: "PDF reader",
        body: "Page navigation, last-position restore and bookmarks. PDF pages are rendered on the device with no network access.",
      },
      {
        title: "EPUB reader",
        body: "Chapter navigation, last-position restore and inline images. PNG, JPEG and GIF images are supported with a bounded memory budget; SVG and remote references are intentionally skipped.",
      },
      {
        title: "Offline library",
        body: "Import through the Android system picker. Relay copies the file into app-managed storage, records its SHA-256 and keeps a local library. Reading never requires a connection.",
      },
      {
        title: "Reading position",
        body: "Progress is stored per document. Close the app, open a different file, then come back — the reader returns to where you stopped.",
      },
      {
        title: "Bookmarks",
        body: "Mark a page or chapter and return to it later. Bookmarks stay with the document in the local database.",
      },
      {
        title: "Search, filters and sort",
        body: "Search by title, author or source. Filter by format and reading status. Sort the collection or inspect how much storage Relay uses.",
      },
      {
        title: "Duplicates rejected on import",
        body: "A file whose SHA-256 already exists in the library is reported as a duplicate. Relay does not replace the existing document.",
      },
      {
        title: "Remove without losing the original",
        body: "Deleting a document removes Relay's managed copy. The file you imported from elsewhere is untouched.",
      },
    ],
  },
  {
    id: "sharing",
    index: "02",
    title: "Sharing",
    intro:
      "One device shows a code, the other scans it. Consent and verification sit between the scan and the library.",
    rows: [
      {
        title: "QR pairing",
        body: "The sender shows a single-use QR code; the receiver scans it inside Relay. The code is validated as a Relay envelope and never opened as a web link.",
      },
      {
        title: "No manual address or port entry",
        body: "The normal sharing flow has no IP, hostname, port or pairing-code fields. The devices negotiate the route themselves.",
      },
      {
        title: "Receiver approval",
        body: "The receiver sees the sender name, file names, formats and sizes, then approves or declines. Nothing is written to storage before approval.",
      },
      {
        title: "SHA-256 and byte-count verification",
        body: "Files stream in chunks. The receiver requires the declared byte count and SHA-256 digest to match before importing.",
      },
      {
        title: "Duplicate and overwrite protection",
        body: "An incoming document that already exists is reported as a duplicate. Relay never silently overwrites an existing document.",
      },
      {
        title: "Direct first, relay fallback",
        body: "Relay prefers a local network route, then a direct WebRTC connection, and finally an encrypted TURN relay when a restrictive network blocks both. The app labels the path used.",
        badge: "Requires signaling",
      },
      {
        title: "Batch limits",
        body: "Up to 20 files or 200 MiB per transfer, with a 100 MiB cap per file. The sender's selection screen enforces the same limits the receiver validates.",
      },
      {
        title: "Cancellation and cleanup",
        body: "Cancelling closes the connection and removes temporary files. An interrupted transfer leaves no library entry and no half-written document.",
      },
      {
        title: "Short-lived codes",
        body: "A sharing code is single-use and expires within minutes. It contains a session reference and an ephemeral token, not an account or long-lived secret.",
      },
    ],
  },
];

export default function Features() {
  return (
    <>
      <Header />
      <main id="main-content">
        <section className="page-head">
          <div className="wrap">
            <div className="page-head__meta">
              <span>Features</span>
              <span>0.9.0 / Android</span>
            </div>
            <div className="page-head__grid">
              <div>
                <h1 className="display display-1">What Relay actually does.</h1>
                <p className="lede">
                  A short, honest list, organised around the two things the app
                  is for: keeping your place while reading, and moving a
                  document with a scan.
                </p>
              </div>
              <div className="page-head__aside">
                <p className="small muted">
                  No benchmark numbers and no speculative security claims. The
                  public source is the authority for every item here.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className="section section--tight">
          <div className="wrap">
            {GROUPS.map((group) => (
              <Reveal key={group.id}>
                <div className="feature-group" id={group.id}>
                  <div className="feature-group__head">
                    <p className="eyebrow">{group.index} / {group.title}</p>
                    <h2 className="display display-2">{group.title}</h2>
                    <p>{group.intro}</p>
                  </div>
                  <div className="feature-rows">
                    {group.rows.map((row) => (
                      <div className="feature-row" key={row.title}>
                        <h3>
                          {row.title}
                          {row.badge && (
                            <span className="feature-row__badge">{row.badge}</span>
                          )}
                        </h3>
                        <p>{row.body}</p>
                      </div>
                    ))}
                  </div>
                </div>
              </Reveal>
            ))}

            <div className="split split--start" style={{ marginTop: "clamp(40px, 6vw, 72px)" }}>
              <Reveal>
                <div className="limits">
                  <p className="eyebrow">Known limits</p>
                  <h3 style={{ marginTop: 12 }}>What this release does not do.</h3>
                  <ul>
                    <li>
                      The published 0.9.0 APK transfers on the same network. The
                      cross-network path is implemented but needs a configured
                      signaling endpoint; this build does not ship one.
                    </li>
                    <li>
                      An interrupted transfer is cancelled and cleaned up. It is
                      not resumed from a byte offset.
                    </li>
                    <li>
                      The local TCP path is not encrypted at the transport level.
                      WebRTC paths are DTLS-encrypted. Avoid sensitive transfers
                      on untrusted Wi-Fi.
                    </li>
                    <li>
                      Relay is Android-only today. There is no iOS build and no
                      Google Play listing yet.
                    </li>
                    <li>
                      There is no cloud sync, account, annotation or text-to-speech
                      layer. None is promised here.
                    </li>
                  </ul>
                </div>
              </Reveal>
              <Reveal delay={80}>
                <p className="eyebrow">Read the source</p>
                <h2 className="display display-3" style={{ marginTop: 14 }}>
                  Verification is code, not a badge.
                </h2>
                <p className="body" style={{ marginTop: 14 }}>
                  The transfer protocol, framing, checksum checks and duplicate
                  handling are all in the public repository. If a claim here
                  does not match the code, the code is right.
                </p>
                <div className="hero-actions" style={{ marginTop: 22 }}>
                  <a
                    className="btn btn--ghost"
                    href="https://github.com/halloffame12/Relay"
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    Open the repository <span className="arrow" aria-hidden="true">↗</span>
                  </a>
                  <Link className="btn btn--primary" href="/download">
                    Get Relay <span className="arrow" aria-hidden="true">→</span>
                  </Link>
                </div>
              </Reveal>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
