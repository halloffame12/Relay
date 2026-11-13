import Link from "next/link";
import Header from "@/components/Header";
import Footer from "@/components/Footer";

export default function NotFound() {
  return (
    <>
      <Header />
      <main id="main-content" className="section" style={{ minHeight: "60vh", display: "grid", placeItems: "center" }}>
        <div className="container" style={{ textAlign: "center", maxWidth: 600 }}>
          <div className="eyebrow-accent">[ 404 / NOT FOUND ]</div>
          <h1 className="display display-2" style={{ margin: "16px 0" }}>Page not found.</h1>
          <p className="lede" style={{ marginBottom: 32 }}>
            The requested document or page does not exist in the Relay catalog.
          </p>
          <Link href="/" className="btn btn-primary">
            Return to Library Home →
          </Link>
        </div>
      </main>
      <Footer />
    </>
  );
}

