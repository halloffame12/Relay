"use client";

import { useState } from "react";

export default function CopyButton({ value, label = "Hash" }) {
  const [state, setState] = useState("idle");

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(value);
      setState("copied");
      window.setTimeout(() => setState("idle"), 1800);
    } catch (error) {
      setState("failed");
      window.setTimeout(() => setState("idle"), 2400);
    }
  };

  return (
    <button
      type="button"
      className="copy-btn"
      onClick={copy}
      aria-label={`Copy ${label}`}
    >
      {state === "copied" ? "Copied" : state === "failed" ? "Select text" : "Copy"}
    </button>
  );
}
