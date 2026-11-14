import Link from "next/link";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export const metadata = {
  title: "Page not found",
  robots: { index: false, follow: false },
};

export default function NotFound() {
  return (
    <>
      <Header />
      <main id="main-content" className="nf">
        <div className="wrap">
          <div className="nf__grid">
            <div>
              <p className="nf__code">404</p>
            </div>
            <div>
              <p className="eyebrow">Page not found</p>
              <h1 className="display display-2" style={{ marginTop: 14 }}>
                This page didn&apos;t arrive.
              </h1>
              <p className="lede">
                Nothing was lost. Your library is still where you left it. The
                address may have moved or never existed.
              </p>
              <div className="hero-actions">
                <Link className="btn btn--primary" href="/">
                  Back to Relay <span className="arrow" aria-hidden="true">→</span>
                </Link>
                <Link className="btn btn--ghost" href="/download">
                  Download
                </Link>
              </div>
            </div>
          </div>
        </div>
      </main>
      <Footer />
    </>
  );
}
