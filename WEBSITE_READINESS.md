# Relay Official Website — Readiness & Design Record

**Status:** Deployed and smoke-tested on Vercel. GitHub Pages build published but shadowed by the portfolio domain.
**Last updated:** 14 November 2026
**Website:** `C:\startup\Relay\website` (Next.js 15 App Router, React 19)
**App release referenced:** Relay 0.9.0 (Android)
**Production URL:** `https://relay-three-red.vercel.app` (Vercel project `relay`, auto-deployed from `main`)

---

## 1. What the site is for

Relay does two things, and the site is built around exactly those two things:

1. **Reading continuity** — an offline PDF/EPUB library that reopens where you stopped.
2. **Sharing with a scan** — a sender shows a QR code, a receiver scans it, reviews the file list, approves, and receives a verified copy.

The homepage has to make both obvious within five seconds, without a generic SaaS hero, invented metrics, fake testimonials, or a Play Store badge for a listing that does not exist. The visual language is editorial and neo-brutalist: warm paper, deep charcoal, lime drawn from the official icon, asymmetric layouts, hairline rules, oversized Fraunces display type, and monospace for technical facts.

The site never asks the visitor to type an IP address, port, hostname, or pairing code. It does not claim cross-network transfer works in the published build. The published 0.9.0 APK was compiled without a signaling endpoint, so it transfers on the same network only; the site says so in the sharing section, on `/how-it-works`, and on `/features`.

---

## 2. Routes

All routes are statically exported: 7 public HTML routes, a 404 page, and generated `robots.txt` and `sitemap.xml`.

| Route | Purpose | Main content |
| --- | --- | --- |
| `/` | Overview | Editorial hero with a real reader screenshot and an illustrative QR phone; reading-continuity section; sharing section with an interactive five-step flow; cross-network explanation and route diagram; verification ledger; no-accounts section; public-source band; final CTA. |
| `/how-it-works` | Explain both workflows | Tabbed “Reading” / “Sharing” panels with phone mockups and captions; connection-path cards (LAN, direct WebRTC, TURN relay); “never asks for” ledger; limits and failure behavior. |
| `/features` | Capability inventory | Reading and sharing feature groups, each tied to what the app actually does; “Known limits” section; source link. |
| `/download` | Get the app | Version 0.9.0 card; direct GitHub Release links for APK and AAB; SHA-256 hashes with copy buttons; verification commands; compatibility; install and build notes; release notes; source links. |
| `/about` | Product thinking | Why Relay exists, its principles, what it deliberately is not, and how to continue. |
| `/privacy` | Privacy policy | Local storage, no account, camera scope, file access, transfer metadata, no analytics/ads, permission summary. |
| `/terms` | Terms of use | What Relay is, user responsibility, network paths, source licensing, warranty and liability, contact. |
| `not-found` | 404 | Editorial “page not found” page with links back into the site. |

There is no login, dashboard, cart, newsletter capture, live chat, or pricing page. Nothing on the site collects visitor data.

---

## 3. Page structure

### Homepage narrative

- **Hero** — “Read without losing your place. Share without the setup.” Two phones: a real reader screenshot and a clearly decorative QR mock labelled `Sharing`. A four-item spec strip states read/resume/share/verify.
- **01 / Reading continuity** — resumes, recent documents, bookmarks, search, offline library. Real screenshots of the library and reader sit in device frames; the resume strip is a static caption bar, not a fake notification.
- **02 / Sharing with a scan** — dark section. States the sender/receiver roles, the five-step flow, batch limits (20 files or 200 MiB), and the fact that nothing is written before approval. The phone screens here are explicitly illustrative app UI built in HTML/CSS.
- **03 / Across networks** — explains LAN first, direct WebRTC second, TURN relay as a fallback. States honestly that the published build is same-network only and why. The route diagram is labelled as illustrative, not a screenshot.
- **04 / Built with care** — a verification ledger: byte count, SHA-256, duplicate detection, explicit approval, interrupted-transfer cleanup.
- **05 / No accounts** — offline-first library, no profile, camera used only for scanning, known limits.
- **06 / Built in the open** — lime band linking to the public source repository. No invented contributor counts.
- **Final CTA** — download and source links over the official mark.

### Interior pages

- `/how-it-works` uses a real tab control (Reading / Sharing), then connection paths and a “never asks for” ledger. On mobile the tabs remain side by side and the panels stack.
- `/download` is a document, not a marketing page: release metadata, hash blocks, terminal verification commands, install caveats, and release notes.
- `/features` separates what ships from “Known limits,” including same-network-only behavior for this build and the absence of resume-after-drop.

---

## 4. Component architecture

| File | Role |
| --- | --- |
| `src/app/layout.jsx` | Metadata, canonical URL, Open Graph/Twitter, icons, theme-color, JSON-LD `SoftwareApplication`, pre-paint theme script. |
| `src/app/page.jsx` | Homepage sections and hero composition. |
| `src/components/Header.jsx` | Sticky header, active-route state, theme toggle (`localStorage` key `relay-theme`), mobile drawer with Escape-to-close and body scroll lock. |
| `src/components/Footer.jsx` | Sitemap-style footer, product/project/legal columns, build facts. |
| `src/components/Reveal.jsx` | IntersectionObserver entrance reveal; disabled under `prefers-reduced-motion`. |
| `src/components/Phone.jsx` | Device frame with caption slot and CSS bevel. |
| `src/components/ShareScreen.jsx` | Illustrative sender/receiver screens: library selection, QR display, scanner, approval, progress, completion. Marked `aria-hidden` so decorative mock headings stay out of the document outline. |
| `src/components/FlowSteps.jsx` | Interactive five-step sharing demo with selectable steps and live preview. |
| `src/components/NetworkDiagram.jsx` | Illustrative LAN / WebRTC / relay route diagram. |
| `src/components/WorkflowTabs.jsx` | Reading/Sharing tabs with `aria-selected`, `aria-controls`, and correct `hidden` panels. |
| `src/components/QrMark.jsx` | Decorative generated QR-style mark (explicitly not a scannable code). |
| `src/components/CopyButton.jsx` | Clipboard copy with visible confirmation for hashes and commands. |
| `src/lib/asset.js` | Prefixes public asset URLs with the optional `BASE_PATH` so subpath builds resolve images and icons correctly. |

Client components are limited to the header, tabs, flow, copy buttons, and reveal wrapper. Everything else is static HTML.

---

## 5. Design system

Tokens live at the top of `src/app/globals.css`; the theme is switched with `data-theme` on `<html>`.

**Light**

| Token | Value |
| --- | --- |
| `--bg` | `#f4f0e6` |
| `--bg-soft` | `#ece7d9` |
| `--surface` | `#faf7f0` |
| `--ink` | `#0e0e10` |
| `--ink-soft` | `#2c2b2e` |
| `--muted` | `#6b665b` |
| `--line` | `#d9d1c0` |
| `--cream` | `#f5eee5` |
| `--lime` | `#c5e74d` |
| `--accent-deep` | `#4b5a12` |
| `--accent-soft` | `#e8f3bd` |

**Dark**

| Token | Value |
| --- | --- |
| `--bg` | `#0e0e10` |
| `--bg-soft` | `#141416` |
| `--surface` | `#17171a` |
| `--ink` | `#f5eee5` |
| `--muted` | `#a39d90` |
| `--line` | `#2c2c30` |
| `--lime` | `#c5e74d` |
| `--accent-deep` | `#c5e74d` |

Typography:

- **Display:** Fraunces (variable optical size). Used for h1/h2 and editorial pull quotes.
- **Body/UI:** Inter.
- **Technical:** JetBrains Mono for hashes, batch sizes, route labels, and numbered captions.

Layout rules: a `1280px` max content width, asymmetric 12/7-ish splits, hairline rules, square corners, and no drop-shadow-heavy cards. The lime band and ink sections break the page rhythm instead of adding another white card.

Contrast: `--muted` on light paper is ≈5.0:1; the dark muted token on `#0e0e10` is ≈7.1:1. Focus outlines use `--focus` (`#4b5a12` light, lime dark) with `:focus-visible`.

---

## 6. Honest capability matrix

| Claim on the site | Reality in the published 0.9.0 APK | Where it is stated |
| --- | --- | --- |
| Offline PDF/EPUB reading, position restore, bookmarks, search | Implemented and shipped | Home, features |
| Sender shows a QR, receiver scans and approves | Implemented and shipped | Home, how-it-works |
| No IP/port/hostname/code entry in the normal flow | True | Home, how-it-works, features |
| Single-use QR, five-minute lifetime, no long-lived secret | Implemented (`shareInvitationTtl = 5 min`, invitation v2) | Home, how-it-works, features |
| 20 files / 200 MiB per batch | Implemented (`shareMaxFilesPerBatch`, `shareMaxBatchBytes`) | Sharing section, features |
| SHA-256 verification before import | Implemented | Home ledger, features, download |
| Same-network transfer in this build | True; APK compiled without `RELAY_SIGNALING_URL` | Sharing section, how-it-works, features |
| Cross-network via WebRTC/TURN | Implemented in source, not configured in the published APK | Explained as available when a signaling/TURN deployment is configured |
| Resume after a dropped connection | Not implemented | `/features` known limits |
| Google Play listing | Does not exist | `/download` links only to GitHub Releases |

No page claims end-to-end encryption for the local TCP path. The privacy page states that WebRTC paths are DTLS-encrypted while the LAN path uses Relay’s own TCP protocol.

---

## 7. Responsive verification

Automated overflow audit: Puppeteer + Chrome headless, every public route plus `/missing-page`, at **320, 360, 390, 430, 768, 1024, 1280, 1440, 1920 px**, in both light and dark themes, with reduced motion forced. The audit walks every element and flags any box whose right edge exceeds the viewport, plus any document wider than the viewport.

**Result: `[]` — no offenders at any tested width or theme.**

Manual inspection was also done on full-page captures at 1440 light/dark, 390 light/dark, 320, and 768, and on cropped sections for the hero, reading, sharing, networks, care, no-accounts, final CTA, `/how-it-works` (both tabs), `/features`, `/download`, `/about`, the 404 page, and the mobile drawer.

Specific responsive behavior:

- Below 860 px the hero drops the dashed baseline and stacks copy over phones.
- Phone widths use `clamp()` with a container query unit inside the mocks, so the illustrative UI keeps its proportions at 320 px without clipping.
- The sharing/reading panels become one column; the tabs stay usable.
- The header collapses to a drawer at the mobile breakpoint; the drawer closes on route change, Escape, and backdrop click, and locks body scroll while open.
- Download hash blocks wrap instead of overflowing; long SHA-256 strings break inside the block.
- No fixed-width element exceeds the viewport at 320 px.

---

## 8. Accessibility checks

Automated per-route checks returned:

- Exactly **one `<h1>`** on every route.
- One `<main id="main-content">` on every page.
- **Zero images without `alt`** (decorative images use `alt=""`).
- **Zero links without an accessible name.**

Other measures:

- A skip link targets `#main-content`.
- The mobile menu button exposes `aria-expanded` and `aria-controls`; the drawer is removed from the DOM when closed.
- Tabs use `role="tab"`, `aria-selected`, `aria-controls`, and real `hidden` panels; both the Reading and Sharing panels exist but only one is displayed.
- The flow steps are buttons with visible `aria-current`/active state and text labels.
- Decorative mock screens are `aria-hidden="true"`, so their internal headings do not pollute the outline.
- `prefers-reduced-motion: reduce` disables animation and smooth scrolling.
- Color is never the only state signal; active states also change weight, border, or text.
- Focus rings are visible against both themes.
- The theme toggle is a real button with an accessible label and persisted preference.

---

## 9. Interaction verification

Run against the exported build (`http://localhost:4173`):

| Check | Result |
| --- | --- |
| `/how-it-works` initial state | Reading panel visible, Sharing panel `display: none` |
| Click “Sharing” tab | Reading `none`, Sharing `grid`, `aria-selected="true"` |
| Click flow step 3 | Active step becomes “Scan from another device” and preview updates |
| Theme toggle | `dark → light`, persisted as `relay-theme = light` after reload |
| Mobile drawer open | `aria-expanded="true"`, `body.style.overflow = hidden` |
| Escape closes drawer | Drawer removed, `aria-expanded="false"`, body scroll restored |
| 404 page | `/404.html` renders “Page not found — Relay” at 1440 and 390 |

---

## 10. Assets and brand provenance

The only official brand source is `store/brand/relay-icon.png`. Nothing on the site invents a logo.

| Asset | Role |
| --- | --- |
| `public/assets/brand/relay-icon.png` | Source of truth, copied from `store/brand/relay-icon.png` |
| `icon-128.png` | Header/footer mark |
| `icon-512.png` | Apple icon, final CTA mark |
| `icon-1024.png` | High-resolution use |
| `og.png` | 1200×630 Open Graph card built from the official feature graphic |
| `favicon.ico` | 16/32/48 ICO generated from the official icon |
| `public/assets/screenshots/01-library-empty.png` | Real Android library screenshot |
| `02-library-imported.png` | Real library with documents |
| `03-document-details.png` | Real document details screen |
| `04-reader.png` | Real reader screen |

Derived assets are generated by:

- `tool/generate_brand_assets.py` — Android/iOS/web/store derivatives and `store/brand-assets.json` provenance.
- `tool/make_web_og.py` — Open Graph image.
- `tool/make_web_favicon.py` — ICO favicon.

Stale screenshots that showed the earlier receive-QR/manual-connection flow were deleted from `website/public/assets/screenshots`. They remain only under `store/screenshots/` as historical artifacts and are not referenced by the site.

Sharing visuals are HTML/CSS mockups, not screenshots, and are labelled as illustrative. They are used because the published build presents the same sender/receiver flow, but a fresh capture of the new share screens would require two connected devices, and no devices were available via adb during this pass.

---

## 11. Build and static export

```powershell
cd C:\startup\Relay\website
npm install
npm run build
```

- Next.js 15.5.x, React 19, JavaScript only.
- `output: "export"` with `images.unoptimized: true`.
- `trailingSlash: false`.
- Output: `website/out/`.
- Build result: **7 routes plus the 404 page, `robots.txt`, and `sitemap.xml` generated without errors or type/lint blockers.**
- `BASE_PATH` is optional. Leave it empty for a root deployment (Vercel); set `BASE_PATH=/Relay` only for the GitHub Pages project build. `next.config.js` exposes it as `NEXT_PUBLIC_BASE_PATH`, and `src/lib/asset.js` prefixes public image, icon, and favicon URLs so a subpath build does not request assets from the domain root.
- `NEXT_PUBLIC_SITE_URL` controls canonical URLs, Open Graph URLs, `robots.txt`, and `sitemap.xml`. When it is unset, `src/lib/site.js` falls back to Vercel's injected `VERCEL_PROJECT_PRODUCTION_URL`, then to `https://sumitchauhan.me/Relay`.

Local preview used during verification:

```powershell
npx serve out -l 4173
# or the small Node static server used for the audit
```

The export is plain HTML/CSS/JS; no server runtime is required.

---

## 12. Deployment

### Vercel (live)

Deployed as project `relay` under `sumits-projects-319df29b`, linked to `halloffame12/Relay` and built from `main`.

1. Project root: `website`.
2. Framework preset: Next.js. Build command `npm run build`. Output directory `out`.
3. `BASE_PATH` is not set.
4. `NEXT_PUBLIC_SITE_URL` is not set; canonical, Open Graph, sitemap, and robots derive from Vercel's production host through `src/lib/site.js`.
5. Production URL: `https://relay-three-red.vercel.app`.

Verified on 14 November 2026: `/`, `/about`, `/features`, `/how-it-works`, `/download`, `/privacy`, `/terms`, `/sitemap.xml`, and `/robots.txt` return 200; an unknown path returns 404; brand images, screenshots, and `favicon.ico` return 200 with correct content types.

Cost: the hobby/personal Vercel plan is free for this static site. A custom domain is the only likely cost; `sumitchauhan.me` is already owned. No paid signaling, TURN, database, or email service is required for the site itself.

### GitHub Pages (published but currently unreachable)

```powershell
$env:BASE_PATH="/Relay"
$env:NEXT_PUBLIC_SITE_URL="https://sumitchauhan.me/Relay"
npm run build
```

The subpath export is published to the `gh-pages` branch with `.nojekyll`, and GitHub Pages reports the build as successful. However, `sumitchauhan.me` is claimed as the custom domain of `halloffame12/halloffame12.github.io` and is served by a Cloudflare-fronted portfolio app that returns its own `index.html` for every path. As a result, `https://sumitchauhan.me/Relay/` and every `/Relay/*` asset currently return the portfolio page, not Relay. The Relay site is therefore served only from Vercel.

Fixing that requires either removing the catch-all behaviour from the portfolio deployment or proxying `/Relay/*` to GitHub Pages. That change belongs to the portfolio project, not this repository.

### Restrictive networks

The site itself is static and needs no TURN server. Cross-network sharing in the app needs a deployed WebSocket signaling endpoint and TURN credentials; those are not configured in the published APK. The site does not imply otherwise.

---

## 13. Verification commands and current results

| Check | Command | Result |
| --- | --- | --- |
| Website production build | `cd website; npm run build` | Pass; 7 routes + 404, `robots.txt`, `sitemap.xml` |
| Overflow audit | Puppeteer script, 8 routes × 9 widths × 2 themes | `[]` |
| Interaction audit | Tabs, flow, theme, drawer, 404 | Pass |
| Subpath asset check | `BASE_PATH=/Relay` build | Every image/icon/favicon URL prefixed with `/Relay` |
| Heading/alt/link audit | All public routes | 1 h1 each; 0 images without alt; 0 unnamed links |
| Live route smoke test | `curl` against `relay-three-red.vercel.app` | 9 routes 200, unknown path 404 |
| Live asset check | `curl` brand images, screenshot, favicon | 200 with correct content types |
| Live canonical/OG | `curl` homepage HTML | Canonical, `og:url`, and `og:image` all use `relay-three-red.vercel.app` |
| Live overflow audit | Puppeteer against production URL | `[]` |
| Release download reachability | `curl -L -r 0-0` release assets | APK 122,825,167 bytes; AAB 82,497,107 bytes |
| Dart format | `dart format --output=none --set-exit-if-changed lib test` | Clean |
| Flutter analyze | `flutter analyze --no-pub` | No issues found |
| Flutter tests | `flutter test --no-pub` | 202 passing |

Screenshots and audit JSON from this pass are in the session temp folder (`live-shots/`), not committed, because they are verification artifacts rather than site assets.

---

## 14. Known limitations and remaining issues

1. **Domain shadowing on GitHub Pages.** The `gh-pages` build is published and builds cleanly, but `sumitchauhan.me/Relay/*` is answered by the portfolio deployment's catch-all. The working production URL is `https://relay-three-red.vercel.app`. Do not advertise `sumitchauhan.me/Relay` until the portfolio routing is changed.
2. **No cross-network deployment.** Without `RELAY_SIGNALING_URL` and TURN credentials, the site can only describe cross-network support as available-when-configured. It does not claim the published APK can do it.
3. **No fresh share-flow screenshots.** The sharing visuals are illustrative HTML/CSS. Capturing the real screens needs two connected Android devices; none were available via adb.
4. **No Play Store presence.** No Play Console access, no Data Safety sign-off, and no listing. The site links to GitHub Releases only.
5. **Signaling/TURN costs if enabled.** A small signaling service can run on free or low-cost hosting, but TURN relays carry bandwidth costs. Nothing is purchased or deployed.
6. **Fonts are loaded from Google Fonts** at runtime. This is a third-party request; the site does not otherwise load analytics or tracking scripts. Self-hosting the three families would remove that dependency if desired.
7. **Animation and reveal behavior** is CSS/IntersectionObserver only; there is no JavaScript animation library to maintain.
8. **Visual QA is manual.** The automated audit catches overflow, heading structure, missing alt text, and unnamed links, but not every visual regression. Full-page captures were reviewed at 1440, 768, 390, and 320.

---

## 15. Definition of done for publishing

- [x] Both core experiences are visible in the first viewport and named in the h1.
- [x] Every route builds as static HTML.
- [x] No horizontal overflow at 320–1920 px in either theme.
- [x] Navigation, tabs, flow steps, theme toggle, drawer, and 404 work.
- [x] Download links point at the real `v0.9.0` GitHub Release.
- [x] Hashes on `/download` match the published artifacts.
- [x] Official icon used everywhere; no generated substitute logo.
- [x] Claims match the published APK, including same-network-only sharing.
- [x] Privacy and terms pages exist and are linked.
- [x] Canonical URL, Open Graph, favicon, sitemap, and robots are configured.
- [x] Deployed and committed.
- [x] Post-deploy smoke test on the production URL.
