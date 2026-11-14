"use client";

import { useState } from "react";
import Phone from "./Phone";
import ShareScreen from "./ShareScreen";

const STEPS = [
  {
    n: "01",
    title: "Select a document",
    body: "The sender chooses PDFs or EPUBs from the Relay library. A batch can hold up to 20 files or 200 MiB, and each file is capped at 100 MiB.",
    meta: ["PDF · EPUB", "20 files / 200 MiB"],
    screen: "library",
    device: "Sender · choose documents",
  },
  {
    n: "02",
    title: "Generate a QR code",
    body: "Relay opens a short-lived session on the device and renders it as a single-use code. The code carries a session reference and an ephemeral token, not an account or a long-lived secret.",
    meta: ["5-minute expiry", "Single use", "No long-lived secret"],
    screen: "qr",
    device: "Sender · show this code",
  },
  {
    n: "03",
    title: "Scan from another device",
    body: "The receiver scans the code inside Relay. It is validated as a Relay envelope and never opened as a web link or an arbitrary URL.",
    meta: ["Camera only while scanning", "Never opened as a link"],
    screen: "scanner",
    device: "Receiver · scan the code",
  },
  {
    n: "04",
    title: "Review and approve",
    body: "The receiver sees the sender name, file names, formats and sizes, then approves or declines. Nothing is written to storage before that approval.",
    meta: ["Receiver consent", "Nothing saved yet"],
    screen: "approval",
    device: "Receiver · approve or decline",
  },
  {
    n: "05",
    title: "Transfer, then verify",
    body: "Files stream in chunks with bounded memory. The receiver requires the declared byte count and SHA-256 to match before anything is imported. A duplicate is reported, never overwritten.",
    meta: ["Bounded memory", "SHA-256", "No silent overwrite"],
    screen: "progress",
    device: "Sender · transfer progress",
  },
];

export default function FlowSteps() {
  const [active, setActive] = useState(0);
  const step = STEPS[active];

  return (
    <div className="flow">
      <div className="flow-steps">
        {STEPS.map((item, index) => {
          const isActive = index === active;
          return (
            <div
              key={item.n}
              className={`flow-step ${isActive ? "is-active" : ""}`}
            >
              <button
                type="button"
                className="flow-step__btn"
                onClick={() => setActive(index)}
                aria-expanded={isActive}
                aria-controls={`flow-panel-${item.n}`}
              >
                <span className="flow-step__num">{item.n}</span>
                <span className="flow-step__title">{item.title}</span>
                <span className="flow-step__plus" aria-hidden="true" />
              </button>
              <div className="flow-step__body" id={`flow-panel-${item.n}`}>
                <div>
                  <p>{item.body}</p>
                  <div className="flow-step__meta">
                    {item.meta.map((chip) => (
                      <span className="chip" key={chip}>{chip}</span>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="flow-preview">
        <div className="flow-preview__device">{step.device}</div>
        <div className="flow-preview__phone" aria-hidden="true">
          <Phone>
            <div className="mock-swap" key={step.screen}>
              <ShareScreen screen={step.screen} />
            </div>
          </Phone>
        </div>
        <p className="flow-preview__caption">Illustrative interface · not a live code</p>
      </div>
    </div>
  );
}
