import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";

export const metadata = {
  title: "Privacy",
  description:
    "How Relay handles documents, camera access, local storage, signaling metadata and relay traffic. No accounts, no cloud document storage, no analytics.",
  alternates: { canonical: "/privacy" },
};

export default function Privacy() {
  return (
    <>
      <Header />
      <main id="main-content">
        <section className="page-head">
          <div className="wrap">
            <div className="page-head__meta">
              <span>Privacy</span>
              <span>Updated November 2026</span>
            </div>
            <div className="page-head__grid">
              <div>
                <h1 className="display display-1">Privacy, in plain terms.</h1>
                <p className="lede">
                  Relay is local-first. There is no account, no document cloud,
                  and no behavioral analytics. This page describes exactly what
                  leaves the device, and when.
                </p>
              </div>
              <div className="page-head__aside">
                <p className="small muted">
                  This policy covers the Android app and this static website.
                  The source is public, so every statement can be checked
                  against the implementation.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className="section">
          <div className="wrap wrap--prose">
            <Reveal className="prose">
              <h2>1. Your library stays on your device</h2>
              <p>
                Imported PDF and EPUB files, reading positions, bookmarks and
                library metadata are stored in Relay&apos;s private application
                storage on the device, backed by a local SQLite database
                (Drift). Relay operates no document storage service and does not
                synchronise your library to a server.
              </p>
              <p>
                Removing a document deletes Relay&apos;s managed copy. If you
                imported the file from another location, that original is not
                touched.
              </p>

              <h2>2. No account, no profile</h2>
              <p>
                Relay has no registration, sign-in, email address or user
                profile. Nothing in the app requires an identity to read, import
                or share a document.
              </p>

              <h2>3. Camera</h2>
              <p>
                Camera access is requested only when you open the QR scanner,
                and only to read a Relay invitation code. Frames are processed on
                the device by the scanner library and are not recorded, stored or
                uploaded by Relay. Relay does not treat scanned text as a web
                link; it validates the relay envelope and rejects anything else.
              </p>
              <p>
                You can deny or revoke camera permission in Android settings.
                The rest of the app, including reading and importing, continues
                to work.
              </p>

              <h2>4. Files and storage access</h2>
              <p>
                Imports use the Android system file picker (Storage Access
                Framework). Relay only reads the files you explicitly select,
                then copies them into its own app-managed directory.
              </p>

              <h2>5. Transfer metadata</h2>
              <p>
                Relay supports two connection paths. Which one is used depends on
                the build and the network:
              </p>
              <ul>
                <li>
                  <strong>Local network (TCP).</strong> The two devices connect
                  directly using local addresses. File bytes do not pass through
                  a Relay server. This path is not encrypted at the transport
                  level, so avoid sensitive transfers on untrusted or public
                  Wi-Fi.
                </li>
                <li>
                  <strong>WebRTC (direct or relayed).</strong> When a signaling
                  endpoint is configured, a WebSocket service introduces the two
                  devices and exchanges session and ICE metadata. WebRTC data
                  channels are encrypted with DTLS. If a direct path fails, TURN
                  relays encrypted packets; the relay can observe source and
                  destination addresses and transfer volume, but not the
                  decrypted document.
                </li>
              </ul>
              <p>
                The signaling service may process room identifiers, session
                identifiers, IP addresses, connection metadata and timestamps.
                The reference server does not log request contents and does not
                store documents. A hosting provider may still keep
                infrastructure-level network logs under its own policy.
              </p>

              <h2>6. Analytics, ads and tracking</h2>
              <p>
                Relay contains no advertising SDKs, no behavioral analytics and
                no third-party trackers. No reading activity, file name, search
                term or transfer history is sent to Relay.
              </p>
              <p>
                This website is a static site. It does not set analytics cookies.
                It stores only your light or dark theme preference in your
                browser&apos;s local storage. No account or contact form data is
                collected here.
              </p>

              <h2>7. Permissions summary</h2>
              <ul>
                <li><strong>Camera:</strong> QR scanning, while the scanner is open.</li>
                <li><strong>Network:</strong> local transfers and, if configured, signaling and WebRTC.</li>
                <li><strong>Files:</strong> through the system picker; Relay writes only to its own storage.</li>
              </ul>

              <h2>8. Children</h2>
              <p>
                Relay is a general-purpose document tool and is not directed at
                children. It does not knowingly collect personal information from
                anyone, because it does not collect accounts or profiles.
              </p>

              <h2>9. Changes</h2>
              <p>
                If data handling changes, this page will be updated with the
                release that introduces the change. The implementation remains
                the authoritative description.
              </p>

              <h2>10. Contact</h2>
              <p>
                Questions or corrections can be raised through the public issue
                tracker at{" "}
                <a
                  href="https://github.com/halloffame12/Relay/issues"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  github.com/halloffame12/Relay/issues
                </a>
                . Please do not include sensitive personal documents in a public
                issue.
              </p>
            </Reveal>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
