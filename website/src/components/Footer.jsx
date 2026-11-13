import Link from "next/link";
import Image from "next/image";

export default function Footer() {
  return (
    <footer className="site-footer">
      <div className="container">
        <div className="footer-top-cta">
          <div className="cta-statement">
            <span className="eyebrow-accent">[ GET STARTED ]</span>
            <h3 className="display display-3">A simpler way to read and share.</h3>
            <p>Download Relay for Android. No cloud account required to keep your documents close.</p>
          </div>
          <div className="cta-actions">
            <Link className="btn btn-primary" href="/download">
              Download Relay v0.9.0 <span className="arrow">→</span>
            </Link>
            <Link className="btn btn-secondary" href="/features">
              Explore All Features
            </Link>
          </div>
        </div>

        <div className="footer-grid">
          <div className="footer-brand-col">
            <Link className="brand" href="/" aria-label="Relay Home">
              <span className="brand-mark">
                <Image
                  src="/assets/brand/relay-icon.png"
                  alt="Relay Logo"
                  width={32}
                  height={32}
                />
              </span>
              <span className="brand-name">Relay</span>
            </Link>
            <p className="footer-desc">
              Offline-first document reader and local peer-to-peer file transfer application.
              Engineered with an emphasis on calm typography, explicit receiver consent, and honest architecture.
            </p>
            <div className="footer-status-pill">
              <span className="status-indicator"></span>
              <span>Architecture: Offline-First • Drift SQL Core</span>
            </div>
          </div>

          <div className="footer-col">
            <div className="footer-heading">Product</div>
            <ul className="footer-links">
              <li><Link href="/">Home & Overview</Link></li>
              <li><Link href="/how-it-works">How It Works</Link></li>
              <li><Link href="/features">Features & Specs</Link></li>
              <li><Link href="/download">Download & Releases</Link></li>
            </ul>
          </div>

          <div className="footer-col">
            <div className="footer-heading">Open Technology</div>
            <ul className="footer-links">
              <li><Link href="/about">About & Philosophy</Link></li>
              <li>
                <a
                  href="https://github.com/halloffame12/Relay"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  GitHub Repository ↗
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/halloffame12/Relay/releases"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Source Releases ↗
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/halloffame12/Relay/issues"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Issue Tracker ↗
                </a>
              </li>
            </ul>
          </div>

          <div className="footer-col">
            <div className="footer-heading">Governance & Privacy</div>
            <ul className="footer-links">
              <li><Link href="/privacy">Privacy Policy</Link></li>
              <li><Link href="/terms">Terms of Use</Link></li>
              <li>
                <a href="mailto:support@relay-reader.org">
                  Developer Contact
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div className="footer-bottom">
          <div className="footer-copy mono">
            © 2026 Relay. Local by default. Zero tracking.
          </div>
          <div className="footer-tech-specs mono">
            <span>SHA-256 Verified Transfers</span>
            <span>•</span>
            <span>Android Min SDK 24</span>
            <span>•</span>
            <span>Flutter & Drift</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
