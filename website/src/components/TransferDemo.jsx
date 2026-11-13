"use client";

import { useState, useEffect } from "react";

const SAMPLE_DOCS = [
  {
    id: "orchard",
    title: "The Quiet Orchard",
    filename: "the-quiet-orchard.epub",
    format: "EPUB",
    size: "2.4 MB",
    pages: "142 pages",
    sha256: "7e9a2b84f3c018a4d6e9102c890abf12c4481098b1e4c7601289cf301bb2e940",
  },
  {
    id: "dist-sys",
    title: "Distributed Systems Architecture",
    filename: "distributed-systems.pdf",
    format: "PDF",
    size: "18.6 MB",
    pages: "384 pages",
    sha256: "121d39677eb42db5100049ba4d53a82be70382552fd17e0d86961041d63a2d50",
  },
];

export default function TransferDemo() {
  const [selectedDoc, setSelectedDoc] = useState(SAMPLE_DOCS[0]);
  const [step, setStep] = useState(1);
  const [progress, setProgress] = useState(0);
  const [transferredBytes, setTransferredBytes] = useState(0);
  const [statusText, setStatusText] = useState("Idle");

  useEffect(() => {
    let timer;
    if (step === 4) {
      setProgress(0);
      setTransferredBytes(0);
      setStatusText("Streaming bytes over local link...");
      const interval = setInterval(() => {
        setProgress((prev) => {
          if (prev >= 100) {
            clearInterval(interval);
            setStatusText("Verifying SHA-256 checksum...");
            timer = setTimeout(() => {
              setStep(5);
              setStatusText("Import verified. Added to local library.");
            }, 600);
            return 100;
          }
          const next = prev + 5;
          setTransferredBytes(((next / 100) * parseFloat(selectedDoc.size)).toFixed(1));
          return next;
        });
      }, 70);
      return () => {
        clearInterval(interval);
        clearTimeout(timer);
      };
    }
  }, [step, selectedDoc]);

  const reset = () => {
    setStep(1);
    setProgress(0);
    setTransferredBytes(0);
    setStatusText("Idle");
  };

  return (
    <div className="transfer-simulator" aria-label="Interactive Relay transfer simulator">
      {/* Simulation Header */}
      <div className="sim-header">
        <div className="sim-badge">
          <span className="live-dot"></span>
          <span>Interactive Protocol Simulator</span>
        </div>
        <div className="sim-controls">
          <span className="sim-step-indicator">
            Step {step} of 5 — {step === 1 ? "Select Document" : step === 2 ? "QR Handshake" : step === 3 ? "Receiver Approval" : step === 4 ? "Streaming & Checksum" : "Library Import"}
          </span>
          {step > 1 && (
            <button type="button" className="sim-reset-btn" onClick={reset}>
              Reset Demo ↺
            </button>
          )}
        </div>
      </div>

      <div className="sim-body">
        {/* Step 1: Select Document */}
        {step === 1 && (
          <div className="sim-view sim-select">
            <div className="sim-lead">
              <span className="mono-idx">[01 / SELECT]</span>
              <h4>Choose a document from your local Relay library</h4>
              <p>Relay never touches external files. Only items already in your offline library are eligible to send.</p>
            </div>

            <div className="sim-doc-grid">
              {SAMPLE_DOCS.map((doc) => (
                <button
                  type="button"
                  key={doc.id}
                  className={`sim-doc-card ${selectedDoc.id === doc.id ? "selected" : ""}`}
                  onClick={() => setSelectedDoc(doc)}
                >
                  <div className="doc-icon-badge">{doc.format}</div>
                  <div className="doc-info">
                    <div className="doc-title">{doc.title}</div>
                    <div className="doc-meta">
                      <span>{doc.size}</span>
                      <span>•</span>
                      <span>{doc.pages}</span>
                    </div>
                    <div className="doc-hash mono">{doc.sha256.slice(0, 16)}...</div>
                  </div>
                  <div className="doc-check">
                    {selectedDoc.id === doc.id ? "✓" : "+"}
                  </div>
                </button>
              ))}
            </div>

            <div className="sim-actions">
              <button
                type="button"
                className="btn btn-primary"
                onClick={() => setStep(2)}
              >
                Create Transfer Offer & Generate QR →
              </button>
            </div>
          </div>
        )}

        {/* Step 2: QR Handshake */}
        {step === 2 && (
          <div className="sim-view sim-qr">
            <div className="sim-lead">
              <span className="mono-idx">[02 / SCAN]</span>
              <h4>Scan the single-use QR invitation</h4>
              <p>The code encapsulates an ephemeral session token and local network endpoints. It expires in 10 minutes and is never opened as a web URL.</p>
            </div>

            <div className="sim-qr-layout">
              <div className="qr-box-editorial">
                <div className="qr-matrix-sim">
                  <svg viewBox="0 0 25 25" width="160" height="160" shapeRendering="crispEdges">
                    <rect width="25" height="25" fill="var(--bg-surface)" />
                    <g fill="var(--ink)">
                      <rect x="2" y="2" width="7" height="7" /><rect x="3" y="3" width="5" height="5" fill="var(--bg-surface)" /><rect x="4" y="4" width="3" height="3" />
                      <rect x="16" y="2" width="7" height="7" /><rect x="17" y="3" width="5" height="5" fill="var(--bg-surface)" /><rect x="18" y="4" width="3" height="3" />
                      <rect x="2" y="16" width="7" height="7" /><rect x="3" y="17" width="5" height="5" fill="var(--bg-surface)" /><rect x="4" y="18" width="3" height="3" />
                      <rect x="10" y="3" width="1" height="2" /><rect x="12" y="2" width="2" height="1" /><rect x="11" y="6" width="1" height="1" />
                      <rect x="10" y="10" width="2" height="2" /><rect x="13" y="11" width="1" height="3" /><rect x="10" y="14" width="2" height="1" />
                      <rect x="16" y="10" width="1" height="2" /><rect x="19" y="11" width="2" height="1" /><rect x="17" y="14" width="2" height="2" />
                      <rect x="10" y="18" width="3" height="1" /><rect x="14" y="19" width="1" height="2" /><rect x="11" y="21" width="2" height="1" />
                      <rect x="18" y="18" width="2" height="2" /><rect x="21" y="20" width="1" height="2" /><rect x="17" y="22" width="3" height="1" />
                    </g>
                  </svg>
                  <div className="qr-laser-line"></div>
                </div>
                <div className="qr-status-pill">
                  <span className="pulse-dot"></span>
                  <span>Awaiting peer scan...</span>
                </div>
              </div>

              <div className="qr-tech-spec">
                <div className="spec-item">
                  <span className="spec-label">Session ID</span>
                  <span className="spec-val mono">sess_9a8f21bc</span>
                </div>
                <div className="spec-item">
                  <span className="spec-label">Transport</span>
                  <span className="spec-val">LAN Direct (TCP:9001) / WebRTC Fallback</span>
                </div>
                <div className="spec-item">
                  <span className="spec-label">Payload</span>
                  <span className="spec-val">{selectedDoc.filename} ({selectedDoc.size})</span>
                </div>
                <div className="spec-item">
                  <span className="spec-label">Token Expiry</span>
                  <span className="spec-val mono">09:59 (single-use)</span>
                </div>
              </div>
            </div>

            <div className="sim-actions">
              <button
                type="button"
                className="btn btn-secondary"
                onClick={() => setStep(1)}
              >
                ← Back
              </button>
              <button
                type="button"
                className="btn btn-primary"
                onClick={() => setStep(3)}
              >
                Receiver Scans Code →
              </button>
            </div>
          </div>
        )}

        {/* Step 3: Explicit Receiver Approval */}
        {step === 3 && (
          <div className="sim-view sim-approve">
            <div className="sim-lead">
              <span className="mono-idx">[03 / APPROVE]</span>
              <h4>Explicit Receiver Approval</h4>
              <p>Relay strictly blocks all incoming bytes until the recipient explicitly inspects and approves the manifest.</p>
            </div>

            <div className="approval-modal-mock">
              <div className="modal-top">
                <div className="modal-title">Incoming Document Offer</div>
                <div className="modal-sub">Peer wants to send 1 document over local Wi-Fi</div>
              </div>

              <div className="modal-card">
                <div className="modal-file-icon">{selectedDoc.format}</div>
                <div className="modal-details">
                  <div className="modal-doc-name">{selectedDoc.filename}</div>
                  <div className="modal-doc-meta">
                    <span>Size: <strong>{selectedDoc.size}</strong></span>
                    <span>•</span>
                    <span>Format: <strong>{selectedDoc.format}</strong></span>
                  </div>
                  <div className="modal-checksum">
                    <span className="hash-label">Expected SHA-256:</span>
                    <span className="mono hash-val">{selectedDoc.sha256}</span>
                  </div>
                </div>
              </div>

              <div className="modal-notice">
                <span>🛡 Zero bytes will be accepted into storage unless approved.</span>
              </div>

              <div className="modal-buttons">
                <button
                  type="button"
                  className="btn btn-secondary btn-sm"
                  onClick={() => {
                    alert("Transfer rejected by receiver. No files written.");
                    reset();
                  }}
                >
                  Reject Transfer
                </button>
                <button
                  type="button"
                  className="btn btn-accent btn-sm"
                  onClick={() => setStep(4)}
                >
                  Approve & Receive File
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Step 4: Streaming & SHA-256 Checksum */}
        {step === 4 && (
          <div className="sim-view sim-streaming">
            <div className="sim-lead">
              <span className="mono-idx">[04 / TRANSFER]</span>
              <h4>Bounded Byte Streaming & Verification</h4>
              <p>Streaming 64 KiB chunks through memory buffers. The receiving socket computes SHA-256 in real time.</p>
            </div>

            <div className="transfer-card-live">
              <div className="live-head">
                <span className="file-name">{selectedDoc.filename}</span>
                <span className="mono pct">{progress}%</span>
              </div>

              <div className="live-meter">
                <div className="live-meter-bar" style={{ width: `${progress}%` }}></div>
              </div>

              <div className="live-stats">
                <span>Transferred: <strong>{transferredBytes} / {selectedDoc.size}</strong></span>
                <span>Speed: <strong>14.2 MB/s</strong></span>
                <span>Buffer: <strong>Bounded 64 KiB</strong></span>
              </div>

              <div className="checksum-indicator">
                <span className="calc-dot"></span>
                <span className="mono status-line">{statusText}</span>
              </div>
            </div>
          </div>
        )}

        {/* Step 5: Transfer Complete */}
        {step === 5 && (
          <div className="sim-view sim-complete">
            <div className="sim-lead">
              <span className="mono-idx">[05 / VERIFIED]</span>
              <h4>Document Verified & Imported</h4>
              <p>Declared byte count and SHA-256 match perfectly. The temporary file is cleanly committed to the Drift library.</p>
            </div>

            <div className="success-banner">
              <div className="success-icon">✓</div>
              <div className="success-info">
                <h5>{selectedDoc.title}</h5>
                <p>Successfully added to offline library. Duplicate guard confirmed clean record.</p>
                <div className="verified-hash mono">
                  SHA-256 MATCH: {selectedDoc.sha256}
                </div>
              </div>
            </div>

            <div className="sim-actions">
              <button
                type="button"
                className="btn btn-primary"
                onClick={reset}
              >
                Run Another Simulated Transfer ↺
              </button>
            </div>
          </div>
        )}
      </div>

      <div className="sim-footer">
        <span className="tech-tag">Offline-First Engine</span>
        <span className="tech-tag">Zero Cloud Relay Required</span>
        <span className="tech-tag">Hardware Camera Only for QR</span>
      </div>
    </div>
  );
}

