import { siteUrl as base } from "@/lib/site";

export const dynamic = "force-static";

export default function sitemap() {
  const routes = [
    "",
    "/how-it-works",
    "/features",
    "/download",
    "/about",
    "/privacy",
    "/terms",
  ].map((path) => ({
    url: `${base}${path}`,
    lastModified: new Date(),
    changeFrequency: path === "" ? "monthly" : "yearly",
    priority: path === "" ? 1 : path === "/download" ? 0.9 : 0.7,
  }));

  return routes;
}
