/**
 * Prefix a public asset path with the optional deployment base path.
 *
 * Next.js prefixes `/_next/*` automatically, but files in `public/` keep the
 * path written in source. Without this helper a GitHub Pages build at
 * `/Relay` would request images from the domain root.
 */
const basePath = process.env.NEXT_PUBLIC_BASE_PATH || "";

export function asset(path) {
  if (!path || /^[a-z]+:|^\/\//i.test(path)) return path;
  return `${basePath}${path.startsWith("/") ? path : `/${path}`}`;
}
