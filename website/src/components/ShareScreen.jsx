import QrMark from "./QrMark";

function StatusBar({ dark = false }) {
  return (
    <div className="mock__status" aria-hidden="true">
      <span>9:41</span>
      <span className="mock__status-icons">
        <span style={{ width: 8 }} />
        <span style={{ width: 6 }} />
        <span style={{ width: 11 }} />
      </span>
    </div>
  );
}

function Brand({ label, dark = false }) {
  return (
    <div className="mock__brand">
      <span className="mock__brand-mark" aria-hidden="true">R</span>
      <span>{label}</span>
    </div>
  );
}

function DocRow({ format, title, meta, selected = false }) {
  return (
    <div className={`mock__row ${selected ? "is-selected" : ""}`}>
      <span className="mock__thumb" aria-hidden="true">{format}</span>
      <span className="mock__row-main">
        <span className="mock__row-title">{title}</span>
        <span className="mock__row-sub">{meta}</span>
      </span>
      {selected && <span className="mock__check" aria-hidden="true" />}
    </div>
  );
}

export default function ShareScreen({ screen = "qr" }) {
  if (screen === "library") {
    return (
      <div className="mock" aria-hidden="true">
        <StatusBar />
        <div className="mock__body">
          <Brand label="Relay · Send" />
          <p className="mock__eyebrow">Choose documents</p>
          <h3 className="mock__title mock__title--sm">Two files selected.</h3>
          <div className="mock__rows">
            <DocRow format="EPUB" title="The Quiet Orchard" meta="EPUB · 2.4 KB" selected />
            <DocRow format="PDF" title="Field Notes on Systems" meta="PDF · 18.2 MB" selected />
            <DocRow format="PDF" title="A Small Atlas" meta="PDF · 4.0 MB" />
          </div>
          <div className="mock__total">
            <span>2 files</span>
            <b>18.2 MB</b>
          </div>
          <div className="mock__capacity">
            <div className="mock__kv">
              <span>Batch capacity</span>
              <span>18.2 of 200 MiB</span>
            </div>
            <div className="mock__bar" aria-hidden="true">
              <span style={{ width: "9%" }} />
            </div>
          </div>
          <div className="mock__actions">
            <span className="mock__btn">Show QR code</span>
          </div>
          <p className="mock__note">Up to 20 files or 200 MiB per batch.</p>
        </div>
      </div>
    );
  }

  if (screen === "scanner") {
    return (
      <div className="mock mock--dark" aria-hidden="true">
        <StatusBar dark />
        <div className="mock__body">
          <Brand label="Relay · Receive" dark />
          <p className="mock__eyebrow">Open camera</p>
          <div className="mock__scanner">
            <div className="mock__viewfinder">
              <span className="mock__corner" />
              <span className="mock__beam" />
            </div>
            <p className="mock__scan-copy">
              <b>Point at the sender&apos;s code</b>
              The code is validated as Relay data. Scanned text is never opened
              as a link.
            </p>
          </div>
          <p className="mock__note">Camera access is requested only while the scanner is open.</p>
        </div>
      </div>
    );
  }

  if (screen === "approval") {
    return (
      <div className="mock" aria-hidden="true">
        <StatusBar />
        <div className="mock__body">
          <Brand label="Relay · Receive" />
          <p className="mock__eyebrow">Approve or decline</p>
          <h3 className="mock__title mock__title--sm">2 files from Relay device 2347</h3>
          <div className="mock__rows">
            <DocRow format="EPUB" title="The Quiet Orchard" meta="EPUB · 2.4 KB" />
            <DocRow format="PDF" title="Field Notes on Systems" meta="PDF · 18.2 MB" />
          </div>
          <div className="mock__total">
            <span>Total</span>
            <b>18.2 MB</b>
          </div>
          <div className="mock__kv">
            <span>Path</span>
            <span>Same network · direct</span>
          </div>
          <div className="mock__kv">
            <span>Verification</span>
            <span>SHA-256 after transfer</span>
          </div>
          <div className="mock__actions">
            <span className="mock__btn mock__btn--ghost">Decline</span>
            <span className="mock__btn">Approve &amp; receive</span>
          </div>
          <p className="mock__note">Nothing is written before you approve.</p>
        </div>
      </div>
    );
  }

  if (screen === "progress") {
    return (
      <div className="mock" aria-hidden="true">
        <StatusBar />
        <div className="mock__body">
          <Brand label="Relay · Send" />
          <p className="mock__eyebrow">Transferring to Relay device 2347</p>
          <div className="mock__progress-head">
            <span className="mock__pct">62%</span>
            <span className="mock__badge">SHA-256</span>
          </div>
          <div className="mock__bar" aria-hidden="true">
            <span style={{ width: "62%" }} />
          </div>
          <div className="mock__kv">
            <span>11.3 of 18.2 MB</span>
            <span>1.8 MB/s · 4s left</span>
          </div>
          <div className="mock__divider" />
          <div className="mock__file-row">
            <span className="mock__file-name">The Quiet Orchard</span>
            <span className="mock__file-state">Verified</span>
          </div>
          <div className="mock__file-row">
            <span className="mock__file-name">Field Notes on Systems</span>
            <span className="mock__file-state">Receiving</span>
          </div>
          <p className="mock__note">Each file is checked against its declared bytes and SHA-256 before it reaches the library.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="mock" aria-hidden="true">
      <StatusBar />
      <div className="mock__body">
        <Brand label="Relay · Send" />
        <p className="mock__eyebrow">Show this code</p>
        <h3 className="mock__title">Scan to receive</h3>
        <div className="mock__qr">
          <QrMark />
        </div>
        <div className="mock__code-meta">
          <span>Single use</span>
          <span>Expires in <b>04:52</b></span>
        </div>
        <div className="mock__actions">
          <span className="mock__btn mock__btn--ghost">New code</span>
          <span className="mock__btn mock__btn--ghost">Stop</span>
        </div>
        <p className="mock__note mock__note--center">No address, port or pairing code to type.</p>
      </div>
    </div>
  );
}
