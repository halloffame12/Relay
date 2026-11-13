import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";
import DeviceFrame from "@/components/DeviceFrame";
import Image from "next/image";
import Link from "next/link";

export const metadata = {
  title: "Features & Specifications — Relay",
  description:
    "Complete breakdown of Relay capabilities: PDF & EPUB reading, offline Drift library, QR pairing protocol, cross-network transfers, and integrity verification.",
};

const FEATURE_MODULES = [
  {
    id: "pdf-reading",
    category: "DOCUMENT ENGINE",
    title: "PDF Reading Engine",
    description:
      "A fast, distraction-free document viewer designed for reading papers, articles, and long-form manuals completely offline.",
    screenshot: "/assets/screenshots/04-reader.png",
    screenshotCaption: "PDF reader showing document pages",
    specs: [
      {
        name: "Continuous Rendering",
        desc: "Smooth vertical scrolling with page boundary indicators and immediate page jump navigation.",
      },
      {
        name: "Position Persistence",
        desc: "Relay remembers your exact scroll coordinate and page index, restoring your reading position on reopen.",
      },
      {
        name: "Custom Bookmarks",
        desc: "Add named bookmarks to critical references and retrieve them from the document drawer.",
      },
      {
        name: "Zero Network Leaks",
        desc: "Never fetches remote fonts, telemetry, or external web assets while opening or viewing documents.",
      },
    ],
  },
  {
    id: "epub-reading",
    category: "DOCUMENT ENGINE",
    title: "EPUB Reader with Bounded Media",
    description:
      "A sanitized EPUB reading experience that protects device memory and preserves battery life.",
    screenshot: "/assets/screenshots/tablet-reader.png",
    screenshotCaption: "Relay EPUB reading interface",
    specs: [
      {
        name: "Sanitized HTML Flow",
        desc: "Strips control characters, bidi overrides, and unsupported HTML tags before rendering chapters.",
      },
      {
        name: "Bounded Inline Images",
        desc: "Renders chapter-relative PNG, JPEG, and GIF images within strict budgets (8 MiB per image, 24 MiB per book).",
      },
      {
        name: "Safety Safeguards",
        desc: "SVG files and remote web URLs are deliberately skipped to prevent tracking pixels and script execution.",
      },
      {
        name: "Chapter Indexing",
        desc: "Fast table-of-contents navigation with progress tracking per chapter.",
      },
    ],
  },
  {
    id: "offline-library",
    category: "STORAGE ARCHITECTURE",
    title: "Local-First Offline Library",
    description:
      "Your documents are managed locally through an embedded SQLite database powered by Drift, completely detached from cloud services.",
    screenshot: "/assets/screenshots/02-library-imported.png",
    screenshotCaption: "Relay offline document library",
    specs: [
      {
        name: "System Picker Import",
        desc: "Import any PDF or EPUB using Android's system storage framework. Relay copies the file to app-managed storage.",
      },
      {
        name: "Original File Protection",
        desc: "Removing a managed document inside Relay never alters or deletes the original file in your Downloads folder.",
      },
      {
        name: "SHA-256 Deduplication",
        desc: "Computes checksum on import; duplicate files are detected and rejected to save storage space.",
      },
      {
        name: "Storage Transparency",
        desc: "Inspect exact byte counts and disk space consumed by individual documents and the entire library.",
      },
    ],
  },
  {
    id: "qr-pairing",
    category: "NETWORKING PROTOCOL",
    title: "QR Pairing Protocol v2",
    description:
      "Camera-assisted peer pairing that eliminates typed IP addresses, port numbers, and network setup menus.",
    screenshot: "/assets/screenshots/06-receive-qr.png",
    screenshotCaption: "Ephemeral QR code receive screen",
    specs: [
      {
        name: "Ephemeral QR Invitations",
        desc: "Payloads contain short-lived cryptographic tokens with a hard 10-minute expiry cap.",
      },
      {
        name: "Binary Protocol Verification",
        desc: "Scanned text is parsed strictly through Relay's frame decoder and never opened in a web browser.",
      },
      {
        name: "Hardware Camera Boundary",
        desc: "Camera permission is requested exclusively when activating the QR viewfinder and closed immediately after.",
      },
      {
        name: "Manual IPv4 Fallback",
        desc: "Expandable drawer displays manual IP, port, and one-time 6-digit PIN if camera hardware is unavailable.",
      },
    ],
  },
  {
    id: "cross-network",
    category: "NETWORKING PROTOCOL",
    title: "Cross-Network Peer Transfer",
    description:
      "Engineered to negotiate connections across disparate Wi-Fi routers, guest networks, and mobile data.",
    screenshot: "/assets/screenshots/phone-nearby.png",
    screenshotCaption: "Nearby transfer options and status",
    specs: [
      {
        name: "LAN-First Negotiation",
        desc: "Attempts direct high-speed local TCP connection first to minimize latency and bypass external servers.",
      },
      {
        name: "WebRTC Data Channels",
        desc: "Falls back to WebRTC peer-to-peer data channels when devices are separated by restrictive NATs.",
      },
      {
        name: "Signaling Reference Client",
        desc: "Connects to a lightweight WebSocket signaling service to exchange session SDPs and ICE candidates.",
      },
      {
        name: "Honest Availability State",
        desc: "Clearly indicates in UI whether cross-network relaying is available or restricted to local LAN.",
      },
    ],
  },
  {
    id: "integrity-verification",
    category: "SECURITY & SAFETY",
    title: "Integrity Verification & Consent",
    description:
      "Every transferred document undergoes cryptographic checksum validation and explicit receiver approval.",
    screenshot: "/assets/screenshots/receiver-approve.png",
    screenshotCaption: "Receiver approval screen with SHA-256",
    specs: [
      {
        name: "Blocking Approval Dialog",
        desc: "Receiving device must explicitly confirm file acceptance. No auto-downloading or unsolicited delivery.",
      },
      {
        name: "On-the-Fly SHA-256 Check",
        desc: "Calculates digest incrementally as bytes arrive. Files with mismatched checksums are deleted instantly.",
      },
      {
        name: "Bounded Memory Streaming",
        desc: "Streams in 64 KiB buffers to keep memory footprint flat regardless of whether the file is 2 MB or 100 MB.",
      },
      {
        name: "Duplicate Integrity Gate",
        desc: "If the receiver already possesses an identical file, Relay alerts the user without duplicating data.",
      },
    ],
  },
  {
    id: "file-organization",
    category: "LIBRARY MANAGEMENT",
    title: "Organization & Search",
    description:
      "Fast filtering, search, and sorting tools to navigate large offline book and document collections.",
    screenshot: "/assets/screenshots/03-document-details.png",
    screenshotCaption: "Document details and metadata inspector",
    specs: [
      {
        name: "Full Title & Author Search",
        desc: "Search instantly across document titles, authors, and metadata stored in Drift SQLite.",
      },
      {
        name: "Format Filtering",
        desc: "Filter library views between PDF, EPUB, or all formats with one tap.",
      },
      {
        name: "Reading Status Badges",
        desc: "Track which documents are unread, in-progress, or finished with clear visual badges.",
      },
      {
        name: "Sort Controls",
        desc: "Sort your collection by title, import date, file size, or recent reading activity.",
      },
    ],
  },
];

export default function Features() {
  return (
    <>
      <Header />
      <main id="main-content">
        <section className="section" style={{ paddingBottom: 40 }}>
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">[ SYSTEM SPECIFICATIONS ]</div>
                <h1 className="display display-1">What Relay actually does.</h1>
                <p className="lede">
                  A verified, exhaustive account of all features genuinely implemented in Relay v0.9.0.
                  No exaggerated claims, no unverified marketing promises.
                </p>
              </div>
            </Reveal>
          </div>
        </section>

        <section className="section" style={{ paddingTop: 0 }}>
          <div className="container">
            <div className="feature-spec-grid">
              {FEATURE_MODULES.map((module) => (
                <div key={module.id} className="spec-category-row" id={module.id}>
                  <div className="spec-category-title">
                    <div className="eyebrow-accent">[{module.category}]</div>
                    <h3 className="display">{module.title}</h3>
                    <p style={{ color: "var(--ink-secondary)", fontSize: 15, margin: "12px 0 20px" }}>
                      {module.description}
                    </p>
                    <div style={{ maxWidth: 280, marginTop: 24 }}>
                      <DeviceFrame
                        src={module.screenshot}
                        alt={module.title}
                        width={260}
                        height={540}
                        caption={module.screenshotCaption}
                      />
                    </div>
                  </div>

                  <div className="spec-details-list">
                    {module.specs.map((spec) => (
                      <div key={spec.name} className="spec-box">
                        <h4>{spec.name}</h4>
                        <p>{spec.desc}</p>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
