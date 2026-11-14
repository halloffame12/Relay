/**
 * Canonical origin for metadata, canonical links, sitemap, and robots.
 *
 * An explicit NEXT_PUBLIC_SITE_URL always wins, which is what the GitHub Pages
 * subpath build uses. On Vercel, fall back to the production URL Vercel injects
 * so canonical/OG tags never point at a domain that does not serve this site.
 */
const explicit = process.env.NEXT_PUBLIC_SITE_URL;
const vercelHost = process.env.VERCEL_PROJECT_PRODUCTION_URL;

export const siteUrl = (
  explicit ||
  (vercelHost ? `https://${vercelHost}` : "https://sumitchauhan.me/Relay")
).replace(/\/$/, "");
