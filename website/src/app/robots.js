import { siteUrl as base } from "@/lib/site";

export const dynamic = "force-static";

export default function robots() {
  return {
    rules: [{ userAgent: "*", allow: "/" }],
    sitemap: `${base}/sitemap.xml`,
    host: base,
  };
}
