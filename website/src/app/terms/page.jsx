import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Reveal from "@/components/Reveal";

export const metadata = {
  title: "Terms of Use — Relay",
  description: "Terms of use and license details for Relay.",
};

export default function Terms() {
  return (
    <>
      <Header />
      <main id="main-content">
        <section className="section">
          <div className="container" style={{ maxWidth: 840 }}>
            <Reveal>
              <div className="section-head">
                <div className="eyebrow">[ LEGAL & LICENSING ]</div>
                <h1 className="display display-2">Terms of Use</h1>
                <p className="lede">
                  Last updated: November 2026. General terms governing use of Relay software.
                </p>
              </div>
            </Reveal>

            <div className="prose-editorial">
              <h3 className="display display-4">1. Open Source License</h3>
              <p>
                Relay is open source software provided under open licensing terms. You are free to inspect, modify, and build the source code in accordance with the repository license terms on GitHub.
              </p>

              <h3 className="display display-4" style={{ marginTop: 32 }}>2. Permitted Use</h3>
              <p>
                Relay is provided for reading and sharing user-authorized documents. You agree not to use Relay to transmit malware, malicious binaries, or materials that violate applicable copyright laws.
              </p>

              <h3 className="display display-4" style={{ marginTop: 32 }}>3. Warranty Disclaimer</h3>
              <p>
                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY.
              </p>

              <h3 className="display display-4" style={{ marginTop: 32 }}>4. Modifications & Updates</h3>
              <p>
                These terms may be updated alongside new major releases of the Relay software. Continued use of Relay following any changes constitutes acceptance of the revised terms.
              </p>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
