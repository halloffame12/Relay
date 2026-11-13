export const dynamic = "force-static";

export default function robots() {
  return {
    rules: { userAgent: "*", allow: "/" },
    sitemap: "https://sumitchauhan.me/Relay/sitemap.xml",
  };
}
