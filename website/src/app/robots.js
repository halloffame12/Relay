export const dynamic = "force-static";

const base = (
  process.env.NEXT_PUBLIC_SITE_URL || "https://sumitchauhan.me/Relay"
).replace(/\/$/, "");

export default function robots() {
  return {
    rules: [{ userAgent: "*", allow: "/" }],
    sitemap: `${base}/sitemap.xml`,
    host: base,
  };
}
