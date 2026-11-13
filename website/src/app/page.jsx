import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";
import DeviceFrame from "@/components/DeviceFrame";
import TransferDemo from "@/components/TransferDemo";
import Image from "next/image";
import Link from "next/link";

export const metadata = {
  title: "Relay — Your library. Your files. Your way.",
  description:
    "Read PDFs and EPUBs offline. Send files between devices with a simple QR scan. No complicated network setup. Just Relay.",
};

export default function Home() {
  return (
    <>
      <Header />
      <main id="main-content">
        {/* ====================================================================
            HERO SECTION
            ==================================================================== */}
        <section className="hero">
          <div className="container">
            <div className="hero-editorial-grid hero-grid">
              {/* Left Column: Headline, Subtitle, and Actions */}
              <div className="hero-narrative">
                <Reveal>
                  <div className="hero-meta-bar">
                    <span className="hero-index mono">[ RELAY FOR ANDROID ]</span>
                    <span className="hero-badge-tag">
                      <span className="hero-badge-dot"></span>
                      <span>Offline-First Engine</span>
                    </span>
                  </div>
                </Reveal>

                <Reveal>
                  <h1 className="display display-1">
                    Your library.
                    <br />
                    Your files.
                    <br />
                    Your way.
                  </h1>
                </Reveal>

                <Reveal>
                  <p className="lede hero-lede">
                    Read PDFs and EPUBs offline. Send files between devices with a simple
                    QR scan. No complicated network setup. Just Relay.
                  </p>
                </Reveal>

                <Reveal>
                  <div className="hero-ctas">
                    <Link className="btn btn-primary" href="/download">
                      <span>Download Relay</span>
                      <span className="arrow">→</span>
                    </Link>
                    <Link className="btn btn-secondary" href="/how-it-works">
                      <span>Explore how it works</span>
                    </Link>
                  </div>

                  <div className="hero-footnote">
                    <span>Android 7.0+</span>
                    <span className="footnote-bullet"></span>
                    <span>Offline-first</span>
                    <span className="footnote-bullet"></span>
                    <span>No account required</span>
                  </div>
                </Reveal>
              </div>

              {/* Right Column: Sophisticated Product Composition */}
              <div className="hero-composition composition">
                <Reveal as="div">
                  <div className="composition-stage">
                    {/* Primary Phone: Library */}
                    <div className="composition-phone-primary phone phone-main">
                      <div className="device-outer">
                        <div className="device-speaker"></div>
                        <div className="device-screen">
                          <Image
                            src="/assets/screenshots/02-library-imported.png"
                            alt="Relay offline document library interface"
                            width={280}
                            height={600}
                            priority
                            className="device-img"
                          />
                        </div>
                        <span className="device-badge">Device A • Library</span>
                      </div>
                    </div>

                    {/* Secondary Phone: QR Receive */}
                    <div className="composition-phone-secondary phone phone-secondary">
                      <div className="device-outer">
                        <div className="device-speaker"></div>
                        <div className="device-screen">
                          <Image
                            src="/assets/screenshots/06-receive-qr.png"
                            alt="Relay QR receive invitation"
                            width={260}
                            height={560}
                            priority
                            className="device-img"
                          />
                        </div>
                        <span className="device-badge">Device B • QR Handshake</span>
                      </div>
                    </div>

                    {/* Floating Architectural Badge */}
                    <div className="composition-floating-tag floating-badge">
                      <span className="live-dot"></span>
                      <span className="mono" style={{ fontSize: 11, fontWeight: 600 }}>
                        SHA-256 VERIFIED
                      </span>
                    </div>

                    {/* Small QR Card Overlay */}
                    <div className="qr-card">
                      <div className="qr-scan" role="img" aria-label="Illustrative QR code">
                        <svg viewBox="0 0 21 21" width="100%" height="100%" shapeRendering="crispEdges" aria-hidden="true">
                          <rect width="21" height="21" fill="var(--bg-surface)" />
                          <g fill="var(--ink)">
                            <rect x="1" y="1" width="7" height="7" /><rect x="2" y="2" width="5" height="5" fill="var(--bg-surface)" /><rect x="3" y="3" width="3" height="3" />
                            <rect x="13" y="1" width="7" height="7" /><rect x="14" y="2" width="5" height="5" fill="var(--bg-surface)" /><rect x="15" y="3" width="3" height="3" />
                            <rect x="1" y="13" width="7" height="7" /><rect x="2" y="14" width="5" height="5" fill="var(--bg-surface)" /><rect x="3" y="15" width="3" height="3" />
                            <rect x="9" y="9" width="1" height="1" /><rect x="11" y="9" width="1" height="1" /><rect x="9" y="11" width="1" height="1" /><rect x="12" y="12" width="1" height="1" /><rect x="10" y="13" width="2" height="1" /><rect x="14" y="10" width="1" height="1" /><rect x="16" y="12" width="1" height="1" /><rect x="18" y="14" width="1" height="1" /><rect x="10" y="16" width="1" height="1" /><rect x="12" y="18" width="2" height="1" />
                          </g>
                        </svg>
                      </div>
                      <div className="qr-label mono">Scan to receive</div>
                    </div>
                  </div>

                  <div className="composition-caption mono">
                    <span>Actual Android screens • Relay v0.9.0</span>
                    <span>Local Wi-Fi / WebRTC</span>
                  </div>
                </Reveal>
              </div>
            </div>
          </div>
        </section>

        {/* ====================================================================
            PRODUCT INTRODUCTION
            ==================================================================== */}
        <section className="section">
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">[ PRODUCT INTRODUCTION ]</div>
                <h2 className="display display-2">
                  Everything you need to keep your documents close.
                </h2>
                <p className="lede">
                  Relay combines a focused, offline reading library with direct peer-to-peer file sharing.
                  No cloud account to create, no third-party servers storing your books, and no manual
                  IP addresses or port numbers in the normal flow.
                </p>
              </div>
            </Reveal>

            {/* Architecture Principles Bar */}
            <div className="principles-grid">
              <div className="principle-item">
                <div className="principle-idx">01</div>
                <div>
                  <h4>Offline-First Storage</h4>
                  <p>
                    Your books and papers reside in local app storage managed by Drift SQL.
                    Reading never touches a network.
                  </p>
                </div>
              </div>
              <div className="principle-item">
                <div className="principle-idx">02</div>
                <div>
                  <h4>Zero-Setup QR Pairing</h4>
                  <p>
                    A single QR code carries ephemeral handshake tokens. Both devices establish
                    a direct socket without typed hostnames.
                  </p>
                </div>
              </div>
              <div className="principle-item">
                <div className="principle-idx">03</div>
                <div>
                  <h4>Explicit Receiver Consent</h4>
                  <p>
                    No file bytes are accepted until the receiver explicitly reviews the document
                    name, size, and SHA-256 hash.
                  </p>
                </div>
              </div>
              <div className="principle-item">
                <div className="principle-idx">04</div>
                <div>
                  <h4>Bounded Streaming Memory</h4>
                  <p>
                    Files stream in bounded 64 KiB buffers with on-the-fly checksum calculation.
                    RAM usage remains minimal regardless of file size.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ====================================================================
            CORE CAPABILITIES WITH DEDICATED VISUAL TREATMENTS
            ==================================================================== */}
        <section className="section" style={{ backgroundColor: "var(--bg-soft)", borderTop: "1px solid var(--line)" }}>
          <div className="container">
            <div className="section-head">
              <div className="eyebrow">[ CORE CAPABILITIES ]</div>
              <h2 className="display display-2">Engineered for clarity and independence.</h2>
              <p className="lede">
                Four pillars designed to make reading and sharing as direct and trustworthy as handing a physical book to a friend.
              </p>
            </div>

            {/* Feature 1: Read Anywhere */}
            <div className="feature-block">
              <div className="feature-editorial-row feature-row">
                <div className="feature-narrative feature-text">
                  <div className="eyebrow">[ 01 / READING ]</div>
                  <h3 className="display">Read anywhere. Offline by default.</h3>
                  <p>
                    Import documents once through the system picker. Read on a plane, subway, or in the woods.
                    Relay saves your exact scroll location and bookmarks directly in on-device storage.
                  </p>
                  <ul className="feature-spec-list feature-list">
                    <li className="feature-spec-item">
                      <span className="spec-bullet">/</span>
                      <span><strong>PDF Reader:</strong> Continuous rendering, instant page jump, and position persistence.</span>
                    </li>
                    <li className="feature-spec-item">
                      <span className="spec-bullet">/</span>
                      <span><strong>EPUB Engine:</strong> Chapter navigation with bounded inline PNG, JPEG, and GIF rendering.</span>
                    </li>
                    <li className="feature-spec-item">
                      <span className="spec-bullet">/</span>
                      <span><strong>Safety Guard:</strong> SVG and remote network images are strictly skipped to prevent remote tracking.</span>
                    </li>
                  </ul>
                  <div className="feature-honest-note mono">
                    Verified: Never contacts remote font servers or analytics during reading.
                  </div>
                </div>

                <div className="feature-stage-box feature-visual">
                  <DeviceFrame
                    src="/assets/screenshots/04-reader.png"
                    alt="Relay document reader interface"
                    width={300}
                    height={620}
                    caption="Actual app screenshot • PDF reader interface"
                  />
                </div>
              </div>
            </div>

            {/* Feature 2: Share With a Scan */}
            <div className="feature-block">
              <div className="feature-editorial-row flip feature-row flip">
                <div className="feature-narrative feature-text">
                  <div className="eyebrow">[ 02 / SHARING ]</div>
                  <h3 className="display">Share with a scan. No manual pairing codes.</h3>
                  <p>
                    Show an ephemeral QR code on the receiving device and scan it with the sender.
                    Relay validates the payload strictly as Relay binary data—never as a web URL.
                  </p>
                  <ul className="feature-spec-list feature-list">
                    <li className="feature-spec-item">
                      <span className="spec-bullet">/</span>
                      <span><strong>Single-Use Tokens:</strong> QR invitations expire in 10 minutes and rotate immediately after transfer.</span>
                    </li>
                    <li className="feature-spec-item">
                      <span className="spec-bullet">/</span>
                      <span><strong>Camera Security:</strong> Camera permission is requested only while the QR viewfinder is active.</span>
                    </li>
                    <li className="feature-spec-item">
                      <span className="spec-bullet">/</span>
                      <span><strong>Manual Fallback:</strong> Local IPv4 and port details remain accessible when camera hardware is unavailable.</span>
                    </li>
                  </ul>
                  <div className="feature-honest-note mono">
                    Verified: 5 failed manual code attempts invalidate and rotate the session token.
                  </div>
                </div>

                <div className="feature-stage-box feature-visual">
                  <DeviceFrame
                    src="/assets/screenshots/receiver-approve.png"
                    alt="Relay receiver approval dialog"
                    width={300}
                    height={620}
                    caption="Actual app screenshot • Explicit approval dialog"
                  />
                </div>
              </div>
            </div>

            {/* Feature 3: Across Networks */}
            <div className="feature-block">
              <div className="feature-editorial-row feature-row">
                <div className="feature-narrative feature-text">
                  <div className="eyebrow">[ 03 / CONNECTIVITY ]</div>
                  <h3 className="display">Across networks. Designed for the real world.</h3>
                  <p>
                    Designed to work whether both devices share the same Wi-Fi router or operate across different networks.
                    Relay prefers a direct LAN socket and can fall back to WebRTC data channels when direct paths are blocked.
                  </p>
                  <ul className="feature-spec-list feature-list">
                    <li className="feature-spec-item">
                      <span className="spec-bullet">/</span>
                      <span><strong>Direct First:</strong> Fast local socket transfer over LAN whenever available.</span>
                    </li>
                    <li className="feature-spec-item">
                      <span className="spec-bullet">/</span>
                      <span><strong>WebRTC Fallback:</strong> Encrypted data channel fallback for complex NAT topologies.</span>
                    </li>
                    <li className="feature-spec-item">
                      <span className="spec-bullet">/</span>
                      <span><strong>Transparent Status:</strong> Clear in-app indicators displaying whether the transfer is LAN-direct or relayed.</span>
                    </li>
                  </ul>
                  <div className="feature-honest-note mono">
                    Honest status: Cross-network relay requires an active signaling service (`infra/signaling`). Without it, transfers run local LAN.
                  </div>
                </div>

                <div className="feature-stage-box feature-visual">
                  <DeviceFrame
                    src="/assets/screenshots/phone-nearby.png"
                    alt="Relay Nearby transfer hub"
                    width={300}
                    height={620}
                    caption="Actual app screenshot • Nearby transfer screen"
                  />
                </div>
              </div>
            </div>

            {/* Feature 4: Built Around Your Files */}
            <div className="feature-block">
              <div className="feature-editorial-row flip feature-row flip">
                <div className="feature-narrative feature-text">
                  <div className="eyebrow">[ 04 / INTEGRITY ]</div>
                  <h3 className="display">Built around your files. Local-first & verified.</h3>
                  <p>
                    Relay manages its own storage copy so removing a book from Relay never damages your original file.
                    Every incoming document is validated byte-by-byte before it touches your library.
                  </p>
                  <ul className="feature-spec-list feature-list">
                    <li className="feature-spec-item">
                      <span className="spec-bullet">/</span>
                      <span><strong>SHA-256 Checksum:</strong> Receiving device verifies matching hash before committing to storage.</span>
                    </li>
                    <li className="feature-spec-item">
                      <span className="spec-bullet">/</span>
                      <span><strong>Duplicate Detection:</strong> Identical files are flagged to prevent duplicate storage consumption.</span>
                    </li>
                    <li className="feature-spec-item">
                      <span className="spec-bullet">/</span>
                      <span><strong>Zero Partial Mess:</strong> Any dropped or interrupted transfer purges temporary `.part` files immediately.</span>
                    </li>
                  </ul>
                  <div className="feature-honest-note mono">
                    Verified: Interrupted transfers leave zero orphaned files and zero broken database rows.
                  </div>
                </div>

                <div className="feature-stage-box feature-visual">
                  <DeviceFrame
                    src="/assets/screenshots/03-document-details.png"
                    alt="Relay document details and storage breakdown"
                    width={300}
                    height={620}
                    caption="Actual app screenshot • Document metadata & SHA-256"
                  />
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ====================================================================
            INTERACTIVE PROTOCOL SIMULATOR
            ==================================================================== */}
        <section className="section">
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">[ INTERACTIVE PROTOCOL EXPLORER ]</div>
                <h2 className="display display-2">Experience the transfer lifecycle.</h2>
                <p className="lede">
                  Test the actual 5-stage state machine that governs every Relay transfer: selection, QR handshake,
                  receiver approval, bounded streaming, and SHA-256 verification.
                </p>
              </div>
            </Reveal>

            <TransferDemo />
          </div>
        </section>

        {/* ====================================================================
            THREE-STEP HOW IT WORKS
            ==================================================================== */}
        <section className="section" style={{ backgroundColor: "var(--bg-soft)", borderTop: "1px solid var(--line)" }}>
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">[ WORKFLOW ]</div>
                <h2 className="display display-2">Understand it in three steps.</h2>
                <p className="lede">
                  No accounts to authenticate. No router ports to forward. Just three clear steps.
                </p>
              </div>
            </Reveal>

            <div className="how-steps-grid steps">
              <div className="how-step-card step">
                <div className="how-step-num step-num">01</div>
                <h3>Select</h3>
                <p>
                  Choose PDFs or EPUBs from your offline Relay library. Relay creates a manifest
                  with file sizes and cryptographic checksums.
                </p>
                <div className="how-step-visual mono" style={{ fontSize: 13, color: "var(--ink-muted)" }}>
                  Payload cap: 20 files / 200 MiB batch
                </div>
              </div>

              <div className="how-step-card step">
                <div className="how-step-num step-num">02</div>
                <h3>Scan</h3>
                <p>
                  The receiver taps "Offer to receive" to display a short-lived QR code.
                  The sender scans it to establish an authenticated direct socket.
                </p>
                <div className="how-step-visual mono" style={{ fontSize: 13, color: "var(--ink-muted)" }}>
                  Token expires: 10 min • Auto-invalidates
                </div>
              </div>

              <div className="how-step-card step">
                <div className="how-step-num step-num">03</div>
                <h3>Transfer</h3>
                <p>
                  The receiver reviews the document details, confirms approval, and accepts the streamed bytes.
                  The file is verified and added to the library.
                </p>
                <div className="how-step-visual mono" style={{ fontSize: 13, color: "var(--ink-muted)" }}>
                  Integrity: SHA-256 match required
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ====================================================================
            PERFORMANCE & RELIABILITY
            ==================================================================== */}
        <section className="section">
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">[ ENGINEERING PRINCIPLES ]</div>
                <h2 className="display display-2">Built on simple, rigorous rules.</h2>
                <p className="lede">
                  Software that respects your device, battery, and cognitive load.
                </p>
              </div>
            </Reveal>

            <div className="principles-grid principles">
              <div className="principle-item principle">
                <div className="principle-idx idx">01</div>
                <div>
                  <h4>Simple Connections</h4>
                  <p>
                    Pairing is a QR scan. No pairing PINs, discovery broadcasting delays, or manual IP entry in the standard path.
                  </p>
                </div>
              </div>

              <div className="principle-item principle">
                <div className="principle-idx idx">02</div>
                <div>
                  <h4>Efficient Transfers</h4>
                  <p>
                    Files stream with bounded memory buffers. Only small control frames and manifests are kept in RAM.
                  </p>
                </div>
              </div>

              <div className="principle-item principle">
                <div className="principle-idx idx">03</div>
                <div>
                  <h4>Reliable File Handling</h4>
                  <p>
                    An interrupted transfer leaves zero partial files in your library. Temporary `.part` files are immediately purged.
                  </p>
                </div>
              </div>

              <div className="principle-item principle">
                <div className="principle-idx idx">04</div>
                <div>
                  <h4>Offline Reading</h4>
                  <p>
                    Your library and reading progress are stored in Drift SQLite. The app opens and functions without an internet connection.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* ====================================================================
            PRIVACY SECTION
            ==================================================================== */}
        <section className="privacy-banner">
          <div className="container">
            <Reveal>
              <div className="privacy-grid">
                <div>
                  <div className="eyebrow-accent">[ PRIVACY BY DESIGN ]</div>
                  <h2 className="display display-2" style={{ margin: "14px 0 20px" }}>
                    Your documents should stay yours.
                  </h2>
                  <div className="privacy-quote">
                    "We believe software should never treat your reading list or personal documents as marketing telemetry."
                  </div>
                </div>

                <div>
                  <p className="lede">
                    Relay keeps your documents on your device. Direct transfers travel device-to-device over your local Wi-Fi.
                    No documents are ever uploaded to cloud storage or scanned for advertising.
                  </p>
                  <p style={{ marginTop: 16, color: "var(--ink-secondary)", fontSize: 15 }}>
                    We do not claim end-to-end encryption for plain local LAN sockets (which run raw TCP).
                    When cross-network WebRTC data channels are utilized, packets are DTLS-encrypted in transit.
                  </p>

                  <div className="privacy-matrix">
                    <div className="matrix-cell">
                      <div className="matrix-cell-title">No Cloud Storage</div>
                      <p className="matrix-cell-desc">Files never transit through or rest in AWS S3, Google Cloud, or third-party buckets.</p>
                    </div>
                    <div className="matrix-cell">
                      <div className="matrix-cell-title">Explicit Approval</div>
                      <p className="matrix-cell-desc">Receivers must explicitly approve each file. No silent transfers or auto-downloads.</p>
                    </div>
                    <div className="matrix-cell">
                      <div className="matrix-cell-title">Ephemeral Handshake</div>
                      <p className="matrix-cell-desc">QR invitations expire in 10 minutes and cannot be reused or replayed.</p>
                    </div>
                    <div className="matrix-cell">
                      <div className="matrix-cell-title">Zero Analytics</div>
                      <p className="matrix-cell-desc">No tracking SDKs, no behavioral cookies, no user telemetry.</p>
                    </div>
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
