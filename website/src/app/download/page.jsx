import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";
import Link from "next/link";

export const metadata = { title: "Download", description: "Download Relay for Android." };

export default function Download() {
  return (
    <>
      <Header />
      <main>
        <section className="section">
          <div className="container">
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">Download</div>
                <h1 className="display display-2">Get Relay.</h1>
                <p className="lede">Android. No account required to start reading.</p>
              </div>
            </Reveal>
            <div className="download-card reveal">
              <div>
                <h2 className="display display-3" style={{ margin: "0 0 8px" }}>Relay for Android</h2>
                <p className="body" style={{ margin: 0 }}>Install the release build directly, or get it from Google Play when the listing is published.</p>
              </div>
              <div className="row">
                <a className="btn btn-primary" href="https://github.com/halloffame12/Relay">View source on GitHub <span className="arrow">→</span></a>
                <span className="coming-soon" style={{ flex: 1, minWidth: 240 }}>Google Play listing is not published yet. Release APKs are attached to GitHub releases when available.</span>
              </div>
              <div className="download-meta">
                <div className="meta-item"><div className="label">Version</div><div className="value">0.9.0</div></div>
                <div className="meta-item"><div className="label">Platform</div><div className="value">Android 7.0+</div></div>
                <div className="meta-item"><div className="label">Min SDK</div><div className="value">24</div></div>
                <div className="meta-item"><div className="label">Size</div><div className="value">~120 MB</div></div>
              </div>
              <div className="coming-soon">
                <strong>Build from source:</strong> <code className="mono">flutter build apk --release --no-tree-shake-icons</code>. Requires Flutter 3.41.x and the Android SDK. <strong>Installation:</strong> enable installs from your browser in Android settings, then open the downloaded APK. Relay requests camera access only when you open the scanner.
              </div>
            </div>
            <div className="section-head reveal" style={{ marginTop: 64 }}>
              <div className="eyebrow">Release notes</div>
              <h2 className="display display-3">What's in this build.</h2>
              <ul className="feature-list" style={{ maxWidth: 640 }}>
                <li>Offline PDF and EPUB reading with position restore and bookmarks</li>
                <li>QR-based file sharing between devices</li>
                <li>Receiver approval and SHA-256 verification</li>
                <li>Direct and relayed connections with honest path labeling</li>
                <li>Local-first library with duplicate detection</li>
              </ul>
            </div>
          </div>
        </section>
        <section className="cta-band">
          <div className="container">
            <h2 className="display display-2" style={{ margin: "0 0 18px" }}>Not ready to install?</h2>
            <p>Read how Relay works first.</p>
            <div className="row" style={{ marginTop: 32 }}>
              <Link className="btn btn-secondary" href="/how-it-works">How it works <span className="arrow">→</span></Link>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
