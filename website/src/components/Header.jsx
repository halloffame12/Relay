"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { asset } from "@/lib/asset";

const NAV_LINKS = [
  { href: "/", label: "Overview", index: "00" },
  { href: "/how-it-works", label: "How it works", index: "01" },
  { href: "/features", label: "Features", index: "02" },
  { href: "/about", label: "About", index: "03" },
  { href: "/download", label: "Download", index: "04" },
];

export default function Header() {
  const pathname = usePathname();
  const [theme, setTheme] = useState("light");
  const [mounted, setMounted] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    setMounted(true);
    const current =
      document.documentElement.getAttribute("data-theme") === "dark"
        ? "dark"
        : "light";
    setTheme(current);
  }, []);

  useEffect(() => {
    setMenuOpen(false);
  }, [pathname]);

  useEffect(() => {
    if (!menuOpen) return;
    const onKey = (event) => {
      if (event.key === "Escape") setMenuOpen(false);
    };
    document.addEventListener("keydown", onKey);
    const previous = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = previous;
    };
  }, [menuOpen]);

  const toggleTheme = () => {
    const next = theme === "dark" ? "light" : "dark";
    setTheme(next);
    document.documentElement.setAttribute("data-theme", next);
    try {
      localStorage.setItem("relay-theme", next);
    } catch (error) {
      // Storage can be unavailable in private browsing; the theme still applies.
    }
  };

  const isActive = (href) =>
    href === "/" ? pathname === "/" : pathname.startsWith(href);

  return (
    <>
      <header className="site-header">
        <div className="wrap header-inner">
          <Link className="brand" href="/" aria-label="Relay home">
            <span className="brand__mark">
              <Image
                src={asset("/assets/brand/icon-128.png")}
                alt=""
                width={32}
                height={32}
                priority
              />
            </span>
            <span className="brand__name">Relay</span>
            <span className="brand__ver mono">0.9.0</span>
          </Link>

          <nav className="nav" aria-label="Main">
            {NAV_LINKS.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={`nav__link ${isActive(link.href) ? "is-active" : ""}`}
                aria-current={isActive(link.href) ? "page" : undefined}
              >
                {link.label}
              </Link>
            ))}
          </nav>

          <div className="header-actions">
            <button
              className="icon-btn"
              type="button"
              onClick={toggleTheme}
              aria-label={`Switch to ${theme === "dark" ? "light" : "dark"} theme`}
              title={`Switch to ${theme === "dark" ? "light" : "dark"} theme`}
            >
              {mounted && theme === "dark" ? (
                <svg
                  width="17"
                  height="17"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.7"
                  strokeLinecap="round"
                  aria-hidden="true"
                >
                  <circle cx="12" cy="12" r="4.2" />
                  <path d="M12 2v2.2M12 19.8V22M2 12h2.2M19.8 12H22M4.9 4.9l1.6 1.6M17.5 17.5l1.6 1.6M4.9 19.1l1.6-1.6M17.5 6.5l1.6-1.6" />
                </svg>
              ) : (
                <svg
                  width="17"
                  height="17"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.7"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  <path d="M21 12.8A8.5 8.5 0 1 1 11.2 3a6.6 6.6 0 0 0 9.8 9.8Z" />
                </svg>
              )}
            </button>

            <Link className="btn btn--primary btn--small header-cta" href="/download">
              Get Relay <span className="arrow" aria-hidden="true">→</span>
            </Link>

            <button
              className="icon-btn menu-toggle"
              type="button"
              onClick={() => setMenuOpen((open) => !open)}
              aria-expanded={menuOpen}
              aria-controls="site-menu"
              aria-label={menuOpen ? "Close menu" : "Open menu"}
            >
              {menuOpen ? (
                <svg
                  width="18"
                  height="18"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.7"
                  strokeLinecap="round"
                  aria-hidden="true"
                >
                  <path d="M18 6 6 18M6 6l12 12" />
                </svg>
              ) : (
                <svg
                  width="18"
                  height="18"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.7"
                  strokeLinecap="round"
                  aria-hidden="true"
                >
                  <path d="M3 7h18M3 12h18M3 17h18" />
                </svg>
              )}
            </button>
          </div>
        </div>
      </header>

      {menuOpen && (
        <div className="drawer" id="site-menu">
          <div className="wrap">
            <nav className="drawer__nav" aria-label="Mobile">
              {NAV_LINKS.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`drawer__link ${isActive(link.href) ? "is-active" : ""}`}
                  aria-current={isActive(link.href) ? "page" : undefined}
                  onClick={() => setMenuOpen(false)}
                >
                  <span>{link.label}</span>
                  <span>{link.index}</span>
                </Link>
              ))}
              <a
                className="drawer__link"
                href="https://github.com/halloffame12/Relay"
                target="_blank"
                rel="noopener noreferrer"
              >
                <span>GitHub</span>
                <span>↗</span>
              </a>
            </nav>
            <div className="drawer__foot">
              <Link
                className="btn btn--primary btn--wide"
                href="/download"
                onClick={() => setMenuOpen(false)}
              >
                Get Relay 0.9.0 <span className="arrow" aria-hidden="true">→</span>
              </Link>
              <p className="drawer__meta">
                Android 7.0+ / offline PDF &amp; EPUB / no account
              </p>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
