import Link from "next/link";
import Image from "next/image";
import { asset } from "@/lib/asset";

export default function Footer() {
  return (
    <footer className="site-footer">
      <div className="wrap">
        <div className="footer-grid">
          <div className="footer-brand">
            <Link className="brand" href="/" aria-label="Relay home">
              <span className="brand__mark">
                <Image
                  src={asset("/assets/brand/icon-128.png")}
                  alt=""
                  width={32}
                  height={32}
                />
              </span>
              <span className="brand__name">Relay</span>
            </Link>
            <p>
              An offline-first reader for PDF and EPUB, with QR-based file
              sharing between Relay devices. Documents stay on the device.
              Reading never needs a connection.
            </p>
            <p className="mono small" style={{ fontSize: 10, letterSpacing: "0.08em", textTransform: "uppercase" }}>
              Version 0.9.0 · Android 7.0+
            </p>
          </div>

          <div className="footer-col">
            <h3>Product</h3>
            <ul>
              <li><Link href="/">Overview</Link></li>
              <li><Link href="/how-it-works">How it works</Link></li>
              <li><Link href="/features">Features</Link></li>
              <li><Link href="/download">Download</Link></li>
            </ul>
          </div>

          <div className="footer-col">
            <h3>Project</h3>
            <ul>
              <li><Link href="/about">About</Link></li>
              <li>
                <a
                  href="https://github.com/halloffame12/Relay"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Source code ↗
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/halloffame12/Relay/releases"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Releases ↗
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/halloffame12/Relay/issues"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Issues ↗
                </a>
              </li>
            </ul>
          </div>

          <div className="footer-col">
            <h3>Legal</h3>
            <ul>
              <li><Link href="/privacy">Privacy</Link></li>
              <li><Link href="/terms">Terms</Link></li>
              <li>
                <a
                  href="https://github.com/halloffame12/Relay/issues/new"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Contact ↗
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div className="footer-bottom">
          <span>© 2026 Relay. Local by default.</span>
          <div className="footer-bottom__specs">
            <span>Flutter</span>
            <span>Android API 24+</span>
            <span>SHA-256 verified</span>
            <span>No analytics</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
