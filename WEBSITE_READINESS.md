# Relay Official Website — Production Readiness & Architecture Audit

**Status:** Production Ready  
**Date:** November 13, 2026  
**Repository:** `C:\startup\Relay`  
**Website Location:** `C:\startup\Relay\website`  
**Release Target:** Relay v0.9.0 (Android)  

---

## 1. Executive Summary

The official website for **Relay** has been completely designed, developed, and verified as an editorial, production-ready web platform. Moving far away from generic, interchangeable SaaS landing page templates, the site embraces an editorial, neo-brutalist aesthetic inspired by high-end independent software studios and literary publications.

The visual direction centers around the official Relay brand asset (`store/brand/relay-icon.png`), utilizing tactile paper tones (`#F5F1E8`), deep charcoal typography (`#0E0F12`), warm terracotta brand accents (`#D96543`), acid lime accents (`#C4F042`), and sage hues (`#D6E0CF`), paired with Fraunces serif display typography, crisp Inter body text, and monospaced JetBrains Mono for cryptographic and networking metadata.

All product claims are strictly anchored in the actual Flutter codebase (`lib/`), Drift database schemas, and the Node.js signaling reference service (`infra/signaling/`).

---

## 2. Pages Implemented & Validated

| Route | Title | Key Architectural Sections |
| :--- | :--- | :--- |
| `/` | **Relay — Your library. Your files. Your way.** | • Asymmetric editorial hero with dual device composition (`02-library-imported.png` & `06-receive-qr.png`).<br>• Product introduction manifesto block.<br>• 4 core capabilities: Read anywhere (PDF/EPUB), Share with a scan, Across networks (honest status), Built around your files.<br>• **Interactive Protocol Simulator** (5-state live demonstration).<br>• 3-step visual workflow (01 Select, 02 Scan, 03 Transfer).<br>• Engineering principles & Privacy manifesto. |
| `/how-it-works` | **How It Works — Relay File Transfer Protocol** | • 5-beat lifecycle with real screenshots: Offer Initialization (`06-receive-qr.png`), Handshake & Selection (`sender-selected.png`), Consent Gate (`receiver-approve.png`), Bounded Streaming (`receiver-incoming.png`), Verification & Commit (`receiver-done.png`).<br>• LAN Direct vs Cross-Network WebRTC comparative topology.<br>• Failure recovery & zero partial file guarantees. |
| `/features` | **Features & Specifications — Relay** | • Comprehensive feature matrix based strictly on implementation:<br>1. PDF Reading Engine (continuous rendering, position restore, bookmarks)<br>2. EPUB Reader with Bounded Media (sanitized HTML, 8 MiB image cap, no SVG/remote leaks)<br>3. Local-First Offline Library (Drift SQLite, deduplication, SAF system picker)<br>4. QR Pairing Protocol v2 (10-min ephemeral token, binary validation, camera boundary)<br>5. Cross-Network Peer Transfer (LAN socket, WebRTC data channels, signaling client)<br>6. Integrity Verification & Consent (blocking approval modal, streaming SHA-256)<br>7. Organization & Search (title/author search, format filtering, status badges) |
| `/download` | **Download Relay for Android — v0.9.0 Release** | • Official v0.9.0 Stable Preview release card.<br>• Direct links to GitHub Releases and open source repository.<br>• Honest Google Play Store status (in review / pending Data Safety approval, no fake badges).<br>• Platform specifications (Min SDK 24 / Android 7.0+, Target SDK 36, v2 signature).<br>• 1-click copyable cryptographic checksums (Release APK SHA-256, AAB SHA-256, Upload Certificate).<br>• Terminal build-from-source command (`flutter build apk --release --no-tree-shake-icons`).<br>• Sideloading installation guide & complete v0.9.0 release notes. |
| `/about` | **About — The Thinking Behind Relay** | • Founding manifesto: "Your documents should be easy to read, keep, and share."<br>• Critique of modern bloated document tools and cloud lock-in.<br>• 4 core tenets: Local First, Explicit Consent, Cryptographic Verification, Honest Communication.<br>• The Relay brand mark story & design philosophy. |
| `/privacy` | **Privacy Policy** | • Precise description of local storage architecture (Drift SQLite).<br>• Complete network socket transparency (LAN direct raw TCP vs WebRTC DTLS data channels).<br>• Strict camera and storage permission boundaries.<br>• Zero tracking SDKs, cookies, or remote analytics commitment. |
| `/terms` | **Terms of Use** | • Open source licensing, permitted use, warranty disclaimers, and version terms. |
| `/sitemap.xml` | Generated XML Sitemap | Dynamic static sitemap covering all canonical site routes. |
| `/robots.txt` | Generated Robots Directive | Clean search engine indexing configuration. |

---

## 3. Component Architecture

- `src/components/Header.jsx`: Sticky blur navigation with brand mark, responsive navigation links, theme toggle with persistent storage and system preference listener, and an animated mobile drawer.
- `src/components/Footer.jsx`: Editorial footer with top CTA band, product links, open source repository links, governance links, and technical specs summary.
- `src/components/DeviceFrame.jsx`: High-fidelity Android device mockup container with realistic bezels, speakers, display screens, and metadata captions for framing authentic screenshots.
- `src/components/TransferDemo.jsx`: Fully interactive 5-phase protocol simulator enabling users to test document selection, QR code generation, receiver approval modals, real-time streamed byte meters, and SHA-256 verification.
- `src/components/CopySnippet.jsx`: One-click clipboard copy component with visual feedback for terminal commands and cryptographic hashes.
- `src/components/Reveal.jsx`: Performant scroll entrance reveals with strict `prefers-reduced-motion` compliance.

---

## 4. Design System & Design Tokens

### Color Palette (Anchored in `store/brand/relay-icon.png`)
- **Light Theme (Tactile Editorial Paper):**
  - Base: `#F5F1E8`
  - Soft Background: `#EDE6D8`
  - Surface: `#FAF7F0`
  - Deep Ink: `#0E0F12`
  - Secondary Ink: `#2E302B`
  - Muted Ink: `#5C6057`
  - Hairlines: `#D5CEBE`
  - Brand Terracotta: `#D96543` (Hover: `#BF5333`)
  - Brand Lime: `#C4F042`
  - Brand Sage: `#D6E0CF`
- **Dark Theme (Obsidian & Mineral):**
  - Base: `#0D0E11`
  - Soft Background: `#15171B`
  - Surface: `#1B1E24`
  - Elevated: `#23272F`
  - High-Contrast Text: `#F5F1E8`
  - Secondary Text: `#D7D2C5`
  - Dark Hairlines: `#292D35`
  - Luminous Terracotta: `#E57351`
  - Acid Lime: `#C4F042`

### Typography Hierarchy
- **Headings & Editorial Quotes:** *Fraunces* (Optical size 9–144, weights 300–700).
- **Body & Interface:** *Inter* (Weights 300–700, OpenType feature settings `cv02`, `cv03`, `cv04`, `cv11`).
- **Cryptographic Hashes & System Metrics:** *JetBrains Mono* (Tabular numerals, zero-slash).

---

## 5. Responsive Verification Matrix

Tested and optimized for complete responsiveness across device viewports:

| Viewport | Device Class | Status | Layout Behavior |
| :--- | :--- | :--- | :--- |
| **320px** | iPhone SE (Compact) | Passed | Fluid typography clamps cleanly; zero horizontal overflow; full-width stacked cards. |
| **360px** | Small Android | Passed | Navigation collapses to clean mobile toggle; hero mockups scale proportionally. |
| **390px** | Standard Modern Smartphone | Passed | Ideal reading widths; mobile drawer functions smoothly; touch targets ≥ 44px. |
| **430px** | Large Smartphone (Pro Max) | Passed | Spacious editorial padding; simulator buttons wrap elegantly. |
| **768px** | iPad / Tablet Portrait | Passed | Grid switches to 2-column layout; device mockups display side-by-side with text. |
| **1024px** | iPad Pro / Small Laptop | Passed | Desktop navigation activates; asymmetric hero composition renders in full detail. |
| **1280px** | Desktop | Passed | Canonical container max-width (`1280px`) with balanced editorial margins. |
| **1440px** | Standard Desktop Display | Passed | High contrast hairlines and balanced whitespace. |
| **1920px** | Wide / Ultrawide Display | Passed | Centered layout; typography does not overscale; visual hierarchy remains disciplined. |

---

## 6. Accessibility (a11y) & SEO Compliance

- **Accessible Landmarks:** `<header>`, `<main id="main-content">`, `<nav>`, `<section>`, `<figure>`, `<figcaption>`, `<footer>`.
- **Skip Navigation:** Keyboard-accessible `.skip-link` anchored to `#main-content`.
- **Keyboard Navigation:** All interactive buttons, simulator steps, copy actions, and theme toggles are fully navigable via `Tab` and `Enter`/`Space` with high-visibility focus rings (`:focus-visible`).
- **Reduced Motion:** Comprehensive `@media (prefers-reduced-motion: reduce)` rules disable all CSS animations, transitions, laser sweeps, and scroll transforms.
- **Open Graph & Twitter Cards:** Full metadata tags configured in `src/app/layout.jsx` linking to `/assets/brand/icon-512.png`.
- **Favicons & App Icons:** Linked to official brand assets in `public/assets/brand/`.
- **Robots & Sitemap:** `robots.txt` and `sitemap.xml` are statically rendered during `next build`.

---

## 7. Verification Results

```bash
cd C:\startup\Relay\website
npm run build
```
- **Build Status:** Compiled successfully in 1.7s.
- **Static Export:** 12/12 static HTML pages rendered to `C:\startup\Relay\website\out`.
- **Local Server Test:** All canonical routes (`/`, `/how-it-works/`, `/features/`, `/download/`, `/about/`, `/privacy/`, `/terms/`, `/sitemap.xml`, `/robots.txt`) returned `200 OK`.
- **Asset Integrity:** All images linked to authentic application screenshots in `public/assets/screenshots/` and official icon in `public/assets/brand/relay-icon.png`.

---

## 8. Deployment Requirements

1. **Static Hosting:** The contents of `C:\startup\Relay\website\out` can be hosted directly on any static web host (Cloudflare Pages, Vercel, Netlify, GitHub Pages, AWS S3 / CloudFront, or NGINX).
2. **Canonical Domain:** Before public deployment, update the placeholder `https://relay.example.com` in `layout.jsx`, `sitemap.js`, and `robots.js` with Relay's production domain.
3. **Artifact Releases:** When official GitHub release binaries or Google Play Store links become available, verify that download URLs in `src/app/download/page.jsx` point directly to the published release.
