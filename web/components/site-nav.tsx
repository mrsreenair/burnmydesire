"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

const LINKS = [
  { href: "/how-it-works", label: "How it works" },
  { href: "/manifesto", label: "Manifesto" },
  { href: "/blog", label: "Blog" },
  { href: "/faq", label: "FAQ" },
  { href: "/privacy", label: "Privacy" },
];

export default function SiteNav() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // Close the mobile sheet whenever the route changes under it.
  useEffect(() => setOpen(false), [pathname]);

  return (
    <header
      className="sticky top-0 z-50"
      style={{
        background: scrolled ? "rgba(247,244,238,.82)" : "transparent",
        backdropFilter: scrolled ? "blur(14px)" : "none",
        borderBottom: `1px solid ${scrolled ? "var(--hair-soft)" : "transparent"}`,
        transition: "background .3s ease, border-color .3s ease",
      }}
    >
      <div
        className="wrap flex items-center justify-between"
        style={{
          height: scrolled ? 64 : 76,
          transition: "height .3s cubic-bezier(.2,.8,.2,1)",
        }}
      >
        <Link href="/" className="flex items-center gap-2.5">
          <span
            className="block h-6 w-6 rounded-[9px]"
            style={{
              background: "linear-gradient(135deg,var(--ember),var(--flame))",
              boxShadow: "0 4px 14px rgba(255,107,44,.42)",
            }}
          />
          <span className="display text-[19px]">
            Burn <em>My</em> Desire
          </span>
        </Link>

        <nav className="hidden items-center gap-7 text-[14.5px] md:flex">
          {LINKS.map((l) => {
            const active = pathname === l.href || pathname.startsWith(`${l.href}/`);
            return (
              <Link
                key={l.href}
                href={l.href}
                className="transition-colors"
                style={{
                  color: active ? "var(--ink)" : "var(--ink-soft)",
                  fontWeight: active ? 650 : 500,
                }}
              >
                {l.label}
              </Link>
            );
          })}
        </nav>

        <div className="flex items-center gap-2">
          <Link href="/app" className="btn btn-dark btn-sm hidden sm:inline-flex">
            Get the app
          </Link>
          <button
            className="grid h-10 w-10 place-items-center rounded-full md:hidden"
            style={{ border: "1px solid var(--hair)" }}
            aria-label={open ? "Close menu" : "Open menu"}
            aria-expanded={open}
            onClick={() => setOpen((v) => !v)}
          >
            <span className="relative block h-[10px] w-[18px]">
              <span
                className="absolute left-0 block h-[1.8px] w-full rounded bg-[var(--ink)] transition-transform"
                style={{
                  top: 0,
                  transform: open ? "translateY(4px) rotate(45deg)" : "none",
                }}
              />
              <span
                className="absolute left-0 block h-[1.8px] w-full rounded bg-[var(--ink)] transition-transform"
                style={{
                  bottom: 0,
                  transform: open ? "translateY(-4px) rotate(-45deg)" : "none",
                }}
              />
            </span>
          </button>
        </div>
      </div>

      {/* mobile sheet */}
      <div
        className="overflow-hidden md:hidden"
        style={{
          maxHeight: open ? 420 : 0,
          transition: "max-height .42s cubic-bezier(.2,.85,.25,1)",
          background: "rgba(247,244,238,.96)",
          backdropFilter: "blur(14px)",
          borderBottom: open ? "1px solid var(--hair-soft)" : "none",
        }}
      >
        <div className="wrap flex flex-col gap-1 pb-6 pt-2">
          {LINKS.map((l) => (
            <Link
              key={l.href}
              href={l.href}
              className="display py-2.5 text-[26px]"
            >
              {l.label}
            </Link>
          ))}
          <Link href="/changelog" className="display py-2.5 text-[26px]">
            Changelog
          </Link>
          <Link href="/contact" className="display py-2.5 text-[26px]">
            Contact
          </Link>
          <Link href="/app" className="btn btn-dark mt-4 self-start">
            Get the app
          </Link>
        </div>
      </div>
    </header>
  );
}
