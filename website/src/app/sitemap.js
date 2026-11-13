export const dynamic = "force-static";

export default function sitemap() {
  const base = "https://sumitchauhan.me/Relay";
  return [
    "", "/how-it-works", "/features", "/download", "/about", "/privacy", "/terms",
  ].map((p) => ({ url: `${base}${p}`, lastModified: new Date() }));
}
