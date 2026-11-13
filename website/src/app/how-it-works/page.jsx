import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";
import DeviceFrame from "@/components/DeviceFrame";
import Image from "next/image";
import Link from "next/link";

export const metadata = {
  title: "How It Works — Relay File Transfer Protocol",
  description:
    "How Relay sends documents between devices with a simple QR scan, explicit receiver approval, and SHA-256 verification.",
};

const WORKFLOW_STEPS = [
  {
    step: "01",
    phase: "OFFER INITIALIZATION",
    title: "Generate Ephemeral QR Invitation",
    lead: "The receiving device starts a temporary listening session and displays a single-use QR invitation.",
    body: "The QR code carries an ephemeral session token, local network IPv4 candidates, port numbers, and protocol version v2. It expires after 10 minutes and strictly rejects any replayed connection.",
    badge: "Receiver Mode",
    screenshot: "/assets/screenshots/06-receive-qr.png",
    screenshotCaption: "Receiver generates single-use QR invitation",
    techPoints: [
      "Strict payload validation (Relay binary format, never a web URL)",
      "Maximum 10-minute token lifetime",
      "Manual IPv4 & 6-digit code fallback for camera-restricted environments",
    ],
  },
  {
    step: "02",
    phase: "HANDSHAKE & SELECTION",
    title: "Scan & Direct Handshake",
    lead: "The sender scans the code to establish an immediate, authenticated peer link.",
    body: "Relay parses the QR payload, tests local network reachability, and completes a versioned hello/welcome handshake. The sender selects up to 20 documents (max 200 MiB batch) from its local library.",
    badge: "Sender Mode",
    screenshot: "/assets/screenshots/sender-selected.png",
    screenshotCaption: "Sender selects Relay-managed documents",
    techPoints: [
      "Zero manual IP or port configuration required",
      "Framed control protocol: [type:1][len:4 BE][payload]",
      "Only Relay-managed library items are exposed",
    ],
  },
  {
    step: "03",
    phase: "CONSENT GATE",
    title: "Explicit Receiver Approval",
    lead: "No file bytes are accepted or written to disk until the recipient explicitly reviews and approves.",
    body: "Before streaming begins, the sender submits a transfer offer containing the exact document title, format, byte size, and declared SHA-256 hash. The receiver presents a blocking dialog requiring conscious user consent.",
    badge: "Receiver Approval",
    screenshot: "/assets/screenshots/receiver-approve.png",
    screenshotCaption: "Blocking approval dialog with file metadata",
    techPoints: [
      "Protects against unsolicited files and spam",
      "User sees exact file name, format, and size in megabytes",
      "Rejection cleanly closes the session with zero disk writes",
    ],
  },
  {
    step: "04",
    phase: "BOUNDED STREAMING",
    title: "Streaming Bytes & SHA-256 Calculation",
    lead: "Bytes stream through bounded memory buffers while both sides compute cryptographic hashes.",
    body: "Upon approval, the sender streams file chunks in bounded 64 KiB segments. Both devices compute the SHA-256 digest on the fly. Streaming never buffers whole files in RAM, ensuring smooth performance even on low-memory devices.",
    badge: "Streaming Engine",
    screenshot: "/assets/screenshots/receiver-incoming.png",
    screenshotCaption: "Receiver streaming bytes with real-time ETA",
    techPoints: [
      "Bounded memory streaming prevents out-of-memory crashes",
      "Real-time speed, bytes received, and percentage calculation",
      "Interrupted connections immediately trigger cleanup of temporary .part files",
    ],
  },
  {
    step: "05",
    phase: "INTEGRITY & COMMIT",
    title: "Verification & Library Import",
    lead: "The receiving device verifies the declared size and SHA-256 hash before committing the file.",
    body: "Once all bytes arrive, Relay checks that the received hash matches the sender's declared manifest. The verified temporary file is then imported into the local Drift SQLite database, and the single-use invitation token is destroyed.",
    badge: "Drift SQL Import",
    screenshot: "/assets/screenshots/receiver-done.png",
    screenshotCaption: "Transfer verified and added to library",
    techPoints: [
      "Bit-for-bit integrity validation via SHA-256",
      "Duplicate file detection prevents redundant disk usage",
      "Tokens automatically rotated; old codes cannot be reused",
    ],
  },
];

export default function HowItWorks() {
  return (
    <>
      <Header />
      <main id="main-content">
        <section className="section" style={{ paddingBottom: 40 }}>
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">[ WORKFLOW ARCHITECTURE ]</div>
                <h1 className="display display-1">A transfer in five deliberate beats.</h1>
                <p className="lede">
                  From initiating a session to opening verified pages on another device, Relay prioritizes
                  transparency, explicit user approval, and cryptographic verification at every step.
                </p>
              </div>
            </Reveal>
          </div>
        </section>

        <section className="section" style={{ paddingTop: 0 }}>
          <div className="container">
            {WORKFLOW_STEPS.map((item, index) => (
              <div key={item.step} className="feature-block">
                <div className={`feature-editorial-row feature-row ${index % 2 === 1 ? "flip" : ""}`}>
                  <div className="feature-narrative feature-text">
                    <div className="eyebrow">
                      <span>[{item.step} / {item.phase}]</span>
                    </div>
                    <h2 className="display display-3" style={{ margin: "10px 0 16px" }}>
                      {item.title}
                    </h2>
                    <p style={{ fontWeight: 500, color: "var(--ink)" }}>{item.lead}</p>
                    <p>{item.body}</p>

                    <div className="spec-box" style={{ marginTop: 12 }}>
                      <h4 className="mono" style={{ fontSize: 13, textTransform: "uppercase", color: "var(--accent)" }}>
                        Technical Specifications
                      </h4>
                      <ul>
                        {item.techPoints.map((point) => (
                          <li key={point}>{point}</li>
                        ))}
                      </ul>
                    </div>
                  </div>

                  <div className="feature-stage-box feature-visual">
                    <DeviceFrame
                      src={item.screenshot}
                      alt={item.title}
                      width={290}
                      height={600}
                      caption={item.screenshotCaption}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>

        <section className="section" style={{ backgroundColor: "var(--bg-soft)", borderTop: "1px solid var(--line)" }}>
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">[ NETWORK TOPOLOGY ]</div>
                <h2 className="display display-2">Direct first. Relayed when needed.</h2>
                <p className="lede">
                  How Relay navigates different network environments without requiring you to understand IP tables or port forwards.
                </p>
              </div>
            </Reveal>

            <div className="privacy-grid" style={{ marginTop: 36 }}>
              <div className="spec-box" style={{ background: "var(--bg-surface)", padding: 28 }}>
                <div className="eyebrow-accent">[ PRIMARY PATH ]</div>
                <h3 className="display display-3" style={{ margin: "12px 0 14px" }}>
                  Direct LAN Socket
                </h3>
                <p>
                  When both devices share the same Wi-Fi router or mobile hotspot, Relay establishes a direct,
                  high-speed TCP socket over the local network.
                </p>
                <ul style={{ paddingLeft: 18, color: "var(--ink-secondary)", fontSize: 14.5 }}>
                  <li><strong>Speed:</strong> Full local Wi-Fi bandwidth (often 15–40+ MB/s).</li>
                  <li><strong>Privacy:</strong> Data packets never leave your local physical router.</li>
                  <li><strong>Zero Internet:</strong> Operates even during complete internet outages.</li>
                </ul>
              </div>

              <div className="spec-box" style={{ background: "var(--bg-surface)", padding: 28 }}>
                <div className="eyebrow-accent">[ FALLBACK PATH ]</div>
                <h3 className="display display-3" style={{ margin: "12px 0 14px" }}>
                  Cross-Network WebRTC Relay
                </h3>
                <p>
                  When devices are on different networks (e.g. mobile cellular vs home broadband, or strict AP isolation),
                  Relay falls back to WebRTC data channels via an authenticated signaling server.
                </p>
                <ul style={{ paddingLeft: 18, color: "var(--ink-secondary)", fontSize: 14.5 }}>
                  <li><strong>Encryption:</strong> WebRTC data channels are strictly DTLS-encrypted end-to-end.</li>
                  <li><strong>Ephemeral Sessions:</strong> TURN credentials are minted per-session and expire quickly.</li>
                  <li><strong>Honest State:</strong> Requires deployed signaling service; app reports status clearly.</li>
                </ul>
              </div>
            </div>
          </div>
        </section>

        <section className="section">
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">[ RESILIENCE & INTEGRITY ]</div>
                <h2 className="display display-2">What happens when a transfer is interrupted?</h2>
                <p className="lede">
                  Zero orphan files, zero broken database records, and zero ambiguous states.
                </p>
              </div>
            </Reveal>

            <div className="principles-grid principles">
              <div className="principle-item principle">
                <div className="principle-idx idx">01</div>
                <div>
                  <h4>Immediate Clean-Up of Partial Files</h4>
                  <p>
                    If the Wi-Fi drops, battery dies, or the user cancels midway, Relay immediately purges the temporary
                    `.part` file from disk. No phantom files occupy your phone storage.
                  </p>
                </div>
              </div>

              <div className="principle-item principle">
                <div className="principle-idx idx">02</div>
                <div>
                  <h4>Atomic SQLite State Updates</h4>
                  <p>
                    Drift SQLite transactions only record a transfer as "completed" after full SHA-256 validation passes.
                    An interrupted transfer is marked failed and never presented as readable.
                  </p>
                </div>
              </div>

              <div className="principle-item principle">
                <div className="principle-idx idx">03</div>
                <div>
                  <h4>Brute-Force Guard on Manual Codes</h4>
                  <p>
                    If manual 6-digit pairing is used and 5 consecutive incorrect attempts occur, the receiver immediately
                    rotates the session token, invalidating previous guesses.
                  </p>
                </div>
              </div>

              <div className="principle-item principle">
                <div className="principle-idx idx">04</div>
                <div>
                  <h4>Malformed Data Rejection</h4>
                  <p>
                    JSON control frames nested deeper than 32 levels or containing unescaped bidi/control characters
                    are rejected before parsing to prevent parser exploitation.
                  </p>
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
