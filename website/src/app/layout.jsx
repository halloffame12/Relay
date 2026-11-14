import "./globals.css";
import { asset } from "@/lib/asset";

const siteUrl = (
  process.env.NEXT_PUBLIC_SITE_URL || "https://sumitchauhan.me/Relay"
).replace(/\/$/, "");

export const metadata = {
  metadataBase: new URL(`${siteUrl}/`),
  title: {
    default: "Relay — Read without losing your place. Share with a scan.",
    template: "%s — Relay",
  },
  description:
    "Relay is an offline-first PDF and EPUB reader for Android that remembers where you stopped, and shares documents between devices with a single QR scan.",
  applicationName: "Relay",
  keywords: [
    "PDF reader",
    "EPUB reader",
    "offline reading",
    "QR file sharing",
    "Android file transfer",
    "local-first",
    "peer-to-peer",
    "document reader",
  ],
  authors: [{ name: "Relay" }],
  creator: "Relay",
  publisher: "Relay",
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    locale: "en_US",
    url: "/",
    siteName: "Relay",
    title: "Relay — Read without losing your place. Share with a scan.",
    description:
      "An offline-first PDF and EPUB reader with QR-based document sharing between devices. No account. No manual network setup.",
    images: [
      {
        url: "/assets/brand/og.png",
        width: 1200,
        height: 630,
        alt: "Relay — read offline, share by QR code",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Relay — Read without losing your place. Share with a scan.",
    description:
      "Offline PDF and EPUB reading, with QR-based document sharing between devices.",
    images: ["/assets/brand/og.png"],
  },
  icons: {
    icon: [
      { url: asset("/favicon.ico"), sizes: "any" },
      {
        url: asset("/assets/brand/icon-128.png"),
        sizes: "128x128",
        type: "image/png",
      },
      {
        url: asset("/assets/brand/icon-512.png"),
        sizes: "512x512",
        type: "image/png",
      },
    ],
    apple: [
      { url: asset("/assets/brand/icon-512.png"), sizes: "512x512" },
    ],
  },
  robots: {
    index: true,
    follow: true,
  },
};

const softwareJsonLd = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  name: "Relay",
  applicationCategory: "UtilitiesApplication",
  operatingSystem: "Android 7.0+",
  softwareVersion: "0.9.0",
  description:
    "Offline-first PDF and EPUB reader with QR-based document sharing between Android devices.",
  url: siteUrl,
  downloadUrl:
    "https://github.com/halloffame12/Relay/releases/tag/v0.9.0",
  offers: {
    "@type": "Offer",
    price: "0",
    priceCurrency: "USD",
  },
  isAccessibleForFree: true,
};

const themeScript = `(function(){try{var d=document.documentElement;var s=localStorage.getItem("relay-theme");var m=window.matchMedia("(prefers-color-scheme: dark)").matches;d.setAttribute("data-theme",s==="dark"||s==="light"?s:(m?"dark":"light"));d.classList.add("js");}catch(e){document.documentElement.classList.add("js");}})();`;

export default function RootLayout({ children }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeScript }} />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,300..700;1,9..144,300..700&family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap"
        />
        <meta name="theme-color" content="#F4F0E6" media="(prefers-color-scheme: light)" />
        <meta name="theme-color" content="#0E0E10" media="(prefers-color-scheme: dark)" />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(softwareJsonLd) }}
        />
      </head>
      <body>
        <a href="#main-content" className="skip-link">
          Skip to main content
        </a>
        {children}
      </body>
    </html>
  );
}
