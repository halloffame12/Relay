import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";

export const metadata = { title: "Features", description: "Relay features: PDF and EPUB reading, offline library, QR pairing, cross-network transfer, integrity verification." };

const details = [
  { k: "Reading", t: "PDF reader", b: "Open PDFs from your library, restore your last position, add bookmarks, and read without a connection.", items: ["Page navigation and last-position restore", "Bookmarks", "Works fully offline"] },
  { k: "Reading", t: "EPUB reader", b: "Read EPUBs with chapter navigation, inline images, and position restore.", items: ["Chapter navigation", "Bounded inline images (PNG, JPEG, GIF)", "SVG and remote images are skipped for safety"] },
  { k: "Library", t: "Offline library", b: "Import PDFs and EPUBs through the system picker. Relay copies them into app-managed storage, computes SHA-256, and rejects duplicates.", items: ["Search and filter by format and reading status", "Storage usage visibility", "Remove Relay's copy without touching the original file"] },
  { k: "Sharing", t: "QR pairing", b: "One device shows a QR code, the other scans it. Codes are single-use and short-lived. Manual address, port and code entry remain as a fallback.", items: ["Single-use, expiring codes", "Camera permission requested only when scanning", "Scanned text is never opened as a URL"] },
  { k: "Sharing", t: "Cross-network transfer", b: "Designed to work without both devices sharing the same Wi-Fi. Direct connection first, relay fallback when needed. No manual network configuration.", items: ["Automatic connection selection", "Clear indication of which path is used", "Requires a deployed signaling service to be enabled"] },
  { k: "Integrity", t: "Verification and duplicates", b: "Every incoming file is checked against its declared size and SHA-256 before import. A duplicate is reported without overwriting the existing document.", items: ["SHA-256 verification", "Declared byte count checked", "Interrupted transfers leave no entry"] },
  { k: "Organization", t: "File organization", b: "Search, filter and sort your library. See how much storage Relay uses. Open documents where you left off.", items: ["Title, author and source search", "Format and reading-status filters", "Sort by title or size"] },
];

export default function Features() {
  return (
    <>
      <Header />
      <main>
        <section className="section">
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">Features</div>
                <h1 className="display display-2">What Relay actually does.</h1>
                <p className="lede">A short, honest list. No promised capabilities that are not in the app.</p>
              </div>
            </Reveal>
            {details.map((d) => (
              <div key={d.t} className="feature-detail reveal">
                <div>
                  <div className="eyebrow">{d.k}</div>
                  <h3>{d.t}</h3>
                </div>
                <div>
                  <p>{d.b}</p>
                  <ul>{d.items.map((i) => <li key={i}>{i}</li>)}</ul>
                </div>
              </div>
            ))}
          </div>
        </section>
        <section className="cta-band">
          <div className="container">
            <h2 className="display display-2" style={{ margin: "0 0 18px" }}>Ready to try it?</h2>
            <p>Download Relay and start a transfer on your own network.</p>
            <div className="row" style={{ marginTop: 32 }}>
              <a className="btn btn-primary" href="/download">Download Relay <span className="arrow">→</span></a>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
