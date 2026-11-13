import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";
import Link from "next/link";

export const metadata = { title: "How it works", description: "How Relay sends a document between two devices with a QR scan." };

const steps = [
  { n: "01", t: "Offer to receive", d: "On the receiving device, Relay opens a session and shows a single-use QR code. It never exposes other files on that device." },
  { n: "02", t: "Scan", d: "The sender scans the code. Relay validates it as Relay data, never as a URL, and connects automatically." },
  { n: "03", t: "Choose", d: "The sender picks a document from the Relay library and confirms. The receiver sees its name, format and size." },
  { n: "04", t: "Approve", d: "The receiver explicitly approves. Nothing is written before that moment." },
  { n: "05", t: "Transfer and verify", d: "Bytes stream with bounded memory. Both sides compute SHA-256. The receiver requires the declared size and hash to match." },
  { n: "06", t: "Import", d: "The verified file is imported into the receiver's library. A duplicate is reported, never overwriting the existing copy." },
];

export default function HowItWorks() {
  return (
    <>
      <Header />
      <main>
        <section className="section">
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">How it works</div>
                <h1 className="display display-2">A transfer in six beats.</h1>
                <p className="lede">From picking a file to opening it on the other device, with approval and verification in between.</p>
              </div>
            </Reveal>
            <div className="flow reveal">
              {steps.map((s) => (
                <div key={s.n} className="flow-step">
                  <div className="num">{s.n}</div>
                  <h4>{s.t}</h4>
                  <p>{s.d}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="section" style={{ background: "var(--bg-soft)" }}>
          <div className="container">
            <Reveal>
              <div className="grid-2 asym">
                <div>
                  <div className="eyebrow">Connections</div>
                  <h2 className="display display-3">Direct first. Relayed when needed.</h2>
                </div>
                <div>
                  <p className="lede">Relay tries a direct device-to-device connection first. When a direct path is unavailable, it can use a relay. You never choose between them and you never type an address.</p>
                  <p className="body" style={{ marginTop: 16 }}>When a relay is used, it carries encrypted packets, not file contents, and sees source and destination addresses plus transfer volume.</p>
                  <p className="body" style={{ marginTop: 16 }}>Cross-network transfer needs a deployed signaling service. When it is not configured, the app runs the local network path only and says so.</p>
                </div>
              </div>
            </Reveal>
          </div>
        </section>

        <section className="section">
          <div className="container">
            <Reveal>
              <div className="grid-2">
                <div>
                  <div className="eyebrow">When things fail</div>
                  <h2 className="display display-3">No partial mess.</h2>
                  <p className="body">An interrupted transfer leaves no library entry and removes its temporary file. A mismatched checksum or size is rejected before import. Cancelling closes the connection and records an interrupted transfer rather than a success.</p>
                </div>
                <div className="feature-visual">
                  <div className="progress-mock">
                    <div className="eyebrow">Result</div>
                    <div style={{ fontSize: 15, marginTop: 6 }}>Verified and imported</div>
                    <div className="progress-bar"><span></span></div>
                    <div className="row" style={{ justifyContent: "space-between", fontSize: 12, color: "var(--muted)" }}>
                      <span>24.6 MB</span><span>Done</span>
                    </div>
                  </div>
                </div>
              </div>
            </Reveal>
          </div>
        </section>

        <section className="cta-band">
          <div className="container">
            <h2 className="display display-2" style={{ margin: "0 0 18px" }}>See it on your devices.</h2>
            <p>Download Relay and try a transfer on your own network.</p>
            <div className="row" style={{ marginTop: 32 }}>
              <Link className="btn btn-primary" href="/download">Download Relay <span className="arrow">→</span></Link>
              <Link className="btn btn-secondary" href="/features">All features</Link>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
