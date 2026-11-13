import "./globals.css";

export const metadata = {
  title: {
    default: "Relay — Read offline. Share with a scan.",
    template: "%s — Relay",
  },
  description:
    "An offline-first document library and reader for PDF and EPUB, with QR-based cross-network file sharing between devices. No cloud account required.",
  metadataBase: new URL("https://sumitchauhan.me/Relay/"),
  keywords: [
    "PDF reader",
    "EPUB reader",
    "offline library",
    "file transfer",
    "QR file sharing",
    "peer-to-peer",
    "Android reader",
    "local-first",
  ],
  authors: [{ name: "Relay Team" }],
  creator: "Relay",
  openGraph: {
    title: "Relay — Your library. Your files. Your way.",
    description:
      "Read PDFs and EPUBs offline. Send files between devices with a simple QR scan. No manual network setup. Just Relay.",
    type: "website",
    locale: "en_US",
    url: "https://relay.example.com",
    siteName: "Relay",
    images: [
      {
        url: "/assets/brand/icon-512.png",
        width: 512,
        height: 512,
        alt: "Relay Application Icon",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Relay — Read offline. Share with a scan.",
    description:
      "An offline-first document library and reader for PDF and EPUB, with QR-based file sharing between devices.",
    images: ["/assets/brand/icon-512.png"],
  },
  icons: {
    icon: [
      { url: "/assets/brand/relay-icon.png", sizes: "32x32", type: "image/png" },
      { url: "/assets/brand/icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: "/assets/brand/icon-512.png",
  },
};

export default function RootLayout({ children }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,300..700;1,9..144,300..700&family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap"
          rel="stylesheet"
        />
        <meta name="theme-color" content="#F4F0E6" media="(prefers-color-scheme: light)" />
        <meta name="theme-color" content="#0F0F11" media="(prefers-color-scheme: dark)" />
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
