import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";

export const metadata = {
  title: "Privacy Policy — Relay",
  description: "Relay data handling architecture and privacy principles.",
};

export default function Privacy() {
  return (
    <>
      <Header />
      <main id="main-content">
        <section className="section">
          <div className="container" style={{ maxWidth: 840 }}>
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">[ LEGAL & ARCHITECTURE ]</div>
                <h1 className="display display-2">Privacy Policy</h1>
                <p className="lede">
                  Last updated: November 2026. How Relay handles documents, network sockets, and device permissions.
                </p>
              </div>
            </Reveal>

            <div className="prose-editorial">
              <h3 className="display display-4">1. Local Storage Architecture</h3>
              <p>
                Relay is an offline-first application. All imported PDF and EPUB documents, reading positions, bookmarks, and transfer logs are stored strictly on your local device in an embedded SQLite database (Drift). Relay operates no cloud storage servers, user accounts, or remote document synchronizers.
              </p>

              <h3 className="display display-4" style={{ marginTop: 32 }}>2. Document Transfer & Network Data</h3>
              <p>
                Relay facilitates peer-to-peer file transfer between devices using local TCP sockets or WebRTC data channels:
              </p>
              <ul>
                <li><strong>Local Wi-Fi Transfers:</strong> Transmit directly between the two local IP addresses on your Wi-Fi network. File bytes travel directly between the two devices and never exit your local network router. Note that raw local TCP transmissions are unencrypted at the transport level; do not transfer sensitive documents across untrusted or public Wi-Fi networks without an isolated guest boundary.</li>
                <li><strong>Cross-Network / WebRTC Transfers:</strong> When devices reside on disparate networks, Relay negotiates a peer-to-peer connection via a lightweight WebSocket signaling service. Session SDPs and ICE candidates are exchanged to coordinate NAT traversal. WebRTC data channels are encrypted using DTLS. Relay does not store or log file contents on signaling servers.</li>
              </ul>

              <h3 className="display display-4" style={{ marginTop: 32 }}>3. Device Permissions</h3>
              <p>Relay requests minimal Android operating system permissions:</p>
              <ul>
                <li><strong>Camera:</strong> Requested strictly and exclusively while the QR code scanner is active to scan the peer's invitation token. Camera frames are parsed in memory and never recorded, saved, or uploaded.</li>
                <li><strong>Storage / Media:</strong> Utilizes the standard Android system file picker (Storage Access Framework) to import documents. Relay only reads files you explicitly select and writes to its own sandboxed application directory.</li>
                <li><strong>Network:</strong> Required to establish local Wi-Fi TCP sockets and connect to the signaling coordinator when performing cross-network transfers.</li>
              </ul>

              <h3 className="display display-4" style={{ marginTop: 32 }}>4. Analytics & Tracking</h3>
              <p>
                Relay contains zero advertising SDKs, zero behavioral trackers, and zero third-party analytics libraries. We do not track what you read, how long you read, or with whom you share documents.
              </p>

              <h3 className="display display-4" style={{ marginTop: 32 }}>5. Contact</h3>
              <p>
                For questions regarding Relay's privacy practices or security architecture, you may inspect the open source code on <a href="https://github.com/halloffame12/Relay" target="_blank" rel="noopener noreferrer" style={{ textDecoration: "underline", color: "var(--accent)" }}>GitHub</a> or contact the development team at <code className="mono">support@relay-reader.org</code>.
              </p>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
