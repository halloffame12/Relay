import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";

export const metadata = {
  title: "Terms",
  description:
    "Terms for using the Relay Android app and this website, including source availability, transfer responsibilities and warranty terms.",
  alternates: { canonical: "/terms" },
};

export default function Terms() {
  return (
    <>
      <Header />
      <main id="main-content">
        <section className="page-head">
          <div className="wrap">
            <div className="page-head__meta">
              <span>Terms</span>
              <span>Updated November 2026</span>
            </div>
            <div className="page-head__grid">
              <div>
                <h1 className="display display-1">Terms of use.</h1>
                <p className="lede">
                  Plain terms for a small tool: use it lawfully, understand the
                  transfer path, and do not rely on it as a backup service.
                </p>
              </div>
              <div className="page-head__aside">
                <p className="small muted">
                  By installing or using Relay you agree to these terms. If you
                  do not agree, do not use the app.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className="section">
          <div className="wrap wrap--prose">
            <Reveal className="prose">
              <h2>1. What Relay is</h2>
              <p>
                Relay is an Android application for reading PDF and EPUB
                documents stored on the device, and for transferring documents
                between Relay devices using a QR-initiated connection. It is
                provided as a release candidate and may change.
              </p>

              <h2>2. Your documents and your responsibilities</h2>
              <p>
                You are responsible for the documents you import, send and
                receive. Only transfer material you have the right to share.
                Relay does not scan documents for malware and does not verify
                that a sender owns the rights to a file.
              </p>
              <p>
                Keep your own backups. Relay is not a backup service. Removing a
                document, clearing app data or uninstalling the app can remove
                Relay&apos;s managed copy.
              </p>

              <h2>3. Network paths and security</h2>
              <p>
                Local network transfers use Relay&apos;s own TCP path and are not
                encrypted at the transport level. WebRTC paths are
                DTLS-encrypted. Use trusted networks for sensitive files, and
                verify the sender and file list before approving a transfer.
              </p>
              <p>
                Cross-network transfer requires a signaling service that you or
                an operator configure. Relay does not guarantee that a direct
                connection is available on every network, and does not promise
                that a relay will always be reachable.
              </p>

              <h2>4. Source code and licensing</h2>
              <p>
                The Relay source repository is publicly viewable for inspection
                and audit. The repository does not currently include a license
                file. Public visibility does not by itself grant permission to
                copy, modify, redistribute or publish builds; absent a license,
                default copyright rules apply. If a license is added to the
                repository, its terms govern use of the source.
              </p>
              <p>
                Release binaries are provided for installation and personal use.
                Do not redistribute modified builds as official Relay releases.
              </p>

              <h2>5. No warranty</h2>
              <p>
                THE SOFTWARE IS PROVIDED &ldquo;AS IS&rdquo;, WITHOUT WARRANTY OF
                ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
                WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
                AND NONINFRINGEMENT. NO WARRANTY IS MADE THAT TRANSFERS WILL BE
                UNINTERRUPTED, ERROR-FREE OR AVAILABLE ON EVERY NETWORK.
              </p>

              <h2>6. Limitation of liability</h2>
              <p>
                TO THE MAXIMUM EXTENT PERMITTED BY LAW, THE AUTHORS AND
                CONTRIBUTORS ARE NOT LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                LIABILITY ARISING FROM THE USE OF THE SOFTWARE, INCLUDING LOST
                DATA, LOST DOCUMENTS OR FAILED TRANSFERS.
              </p>

              <h2>7. Website</h2>
              <p>
                This website is informational. Download links point to the
                public GitHub release. Availability of third-party hosting and
                download infrastructure is outside Relay&apos;s control.
              </p>

              <h2>8. Changes to these terms</h2>
              <p>
                These terms may be updated alongside a new release. The date at
                the top of this page records the latest revision. Continued use
                after a change means you accept the revised terms.
              </p>

              <h2>9. Contact</h2>
              <p>
                Questions can be raised at{" "}
                <a
                  href="https://github.com/halloffame12/Relay/issues"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  github.com/halloffame12/Relay/issues
                </a>
                .
              </p>
            </Reveal>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
