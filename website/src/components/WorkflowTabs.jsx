"use client";

import { useRef, useState } from "react";
import Image from "next/image";
import Phone from "./Phone";
import ShareScreen from "./ShareScreen";
import { asset } from "@/lib/asset";

const TABS = [
  { id: "reading", label: "Reading", index: "01" },
  { id: "sharing", label: "Sharing", index: "02" },
];

const READING_STEPS = [
  {
    n: "01",
    title: "Import a PDF or EPUB",
    body: "Choose a file through the Android system picker. Relay copies it into app-managed storage, computes SHA-256 and rejects a duplicate instead of replacing an existing document.",
  },
  {
    n: "02",
    title: "Open it in Relay",
    body: "The reader restores your last position and keeps bookmarks with the document. PDF pages and EPUB chapters are rendered locally.",
  },
  {
    n: "03",
    title: "Read offline",
    body: "No account, no server and no connection is required. Reading progress lives in the on-device library.",
  },
  {
    n: "04",
    title: "Come back and continue",
    body: "Close the app whenever you need to. The next time you open the document, it starts where you stopped.",
  },
];

const SHARING_STEPS = [
  {
    n: "01",
    title: "Select a document",
    body: "The sender picks one document or a batch from the Relay library. Up to 20 files or 200 MiB per batch, with a 100 MiB cap per file.",
  },
  {
    n: "02",
    title: "Show a QR code",
    body: "Relay opens a short-lived session and renders a single-use code. It expires in minutes and contains no long-lived secret.",
  },
  {
    n: "03",
    title: "Scan from the other device",
    body: "The receiver scans the code in Relay. The code is validated as Relay data and is never opened as a URL.",
  },
  {
    n: "04",
    title: "Review and approve",
    body: "The receiver sees the sender name, file names, formats and sizes before approving. Nothing is written before that moment.",
  },
  {
    n: "05",
    title: "Transfer and verify",
    body: "Files stream with bounded memory. SHA-256 and the declared byte count are checked before import; an interrupted transfer leaves no library entry.",
  },
];

export default function WorkflowTabs() {
  const [active, setActive] = useState("reading");
  const tabRefs = useRef({});

  const onKeyDown = (event) => {
    const keys = ["ArrowRight", "ArrowLeft", "Home", "End"];
    if (!keys.includes(event.key)) return;
    event.preventDefault();
    const index = TABS.findIndex((tab) => tab.id === active);
    let next = index;
    if (event.key === "ArrowRight") next = (index + 1) % TABS.length;
    if (event.key === "ArrowLeft") next = (index - 1 + TABS.length) % TABS.length;
    if (event.key === "Home") next = 0;
    if (event.key === "End") next = TABS.length - 1;
    const id = TABS[next].id;
    setActive(id);
    tabRefs.current[id]?.focus();
  };

  return (
    <div className="workflow">
      <div
        className="workflow__tabs"
        role="tablist"
        aria-label="Relay workflows"
        onKeyDown={onKeyDown}
      >
        {TABS.map((tab) => (
          <button
            key={tab.id}
            ref={(node) => {
              tabRefs.current[tab.id] = node;
            }}
            type="button"
            role="tab"
            id={`tab-${tab.id}`}
            aria-selected={active === tab.id}
            aria-controls={`panel-${tab.id}`}
            tabIndex={active === tab.id ? 0 : -1}
            className="workflow__tab"
            onClick={() => setActive(tab.id)}
          >
            <span>{tab.index}</span>
            {tab.label}
          </button>
        ))}
      </div>

      {TABS.map((tab) => (
        <div
          key={tab.id}
          role="tabpanel"
          id={`panel-${tab.id}`}
          aria-labelledby={`tab-${tab.id}`}
          hidden={active !== tab.id}
          className="workflow__panel"
        >
          {tab.id === "reading" ? (
            <>
              <div className="workflow__steps">
                {READING_STEPS.map((step) => (
                  <div className="workflow__step" key={step.n}>
                    <span className="workflow__step-num">{step.n}</span>
                    <div>
                      <h3>{step.title}</h3>
                      <p>{step.body}</p>
                    </div>
                  </div>
                ))}
              </div>
              <div className="workflow__aside">
                <div className="read-stack">
                  <Phone caption="Library" device="A /">
                    <Image
                      src={asset("/assets/screenshots/02-library-imported.png")}
                      alt="Relay library with one imported EPUB, search, sort and filters"
                      width={1080}
                      height={1920}
                      sizes="(max-width: 980px) 30vw, 200px"
                    />
                  </Phone>
                  <Phone caption="Reader" device="B /">
                    <Image
                      src={asset("/assets/screenshots/04-reader.png")}
                      alt="Relay EPUB reader showing chapter one, progress and bookmark controls"
                      width={1080}
                      height={1920}
                      sizes="(max-width: 980px) 30vw, 200px"
                    />
                  </Phone>
                  <Phone caption="Document details" device="C /">
                    <Image
                      src={asset("/assets/screenshots/03-document-details.png")}
                      alt="Relay document details with reading position and file information"
                      width={1080}
                      height={1920}
                      sizes="(max-width: 980px) 40vw, 200px"
                    />
                  </Phone>
                </div>
                <p className="workflow__caption">
                  Captured from Relay 0.9.0 on Android. Illustrative of the shipped
                  interface.
                </p>
              </div>
            </>
          ) : (
            <>
              <div className="workflow__steps">
                {SHARING_STEPS.map((step) => (
                  <div className="workflow__step" key={step.n}>
                    <span className="workflow__step-num">{step.n}</span>
                    <div>
                      <h3>{step.title}</h3>
                      <p>{step.body}</p>
                    </div>
                  </div>
                ))}
              </div>
              <div className="workflow__aside">
                <div className="workflow__phones">
                  <Phone>
                    <ShareScreen screen="qr" />
                  </Phone>
                  <Phone>
                    <ShareScreen screen="approval" />
                  </Phone>
                </div>
                <p className="workflow__caption">
                  Illustrative interface built from the shipped screens: sender
                  shows a code, receiver approves before anything is saved.
                </p>
              </div>
            </>
          )}
        </div>
      ))}
    </div>
  );
}
