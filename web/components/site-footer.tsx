import Link from "next/link";

const COLUMNS = [
  {
    title: "Product",
    links: [
      { href: "/how-it-works", label: "How it works" },
      { href: "/#math", label: "The math" },
      { href: "/faq", label: "FAQ" },
      { href: "/changelog", label: "Changelog" },
      { href: "/app", label: "Get the app" },
    ],
  },
  {
    title: "Company",
    links: [
      { href: "/manifesto", label: "Manifesto" },
      { href: "/blog", label: "Blog" },
      { href: "/press", label: "Press kit" },
      { href: "/contact", label: "Contact" },
    ],
  },
  {
    title: "Legal",
    links: [
      { href: "/privacy", label: "Privacy" },
      { href: "/terms", label: "Terms" },
    ],
  },
];

export default function SiteFooter() {
  return (
    <footer className="mt-auto" style={{ borderTop: "1px solid var(--hair-soft)" }}>
      <div className="wrap grid gap-12 py-16 md:grid-cols-[1.4fr_repeat(3,1fr)]">
        <div>
          <div className="flex items-center gap-2.5">
            <span
              className="block h-6 w-6 rounded-[9px]"
              style={{
                background: "linear-gradient(135deg,var(--ember),var(--flame))",
              }}
            />
            <span className="display text-[19px]">
              Burn <em>My</em> Desire
            </span>
          </div>
          <p className="lede mt-4 max-w-[300px] text-[15px]">
            Other apps make you wait. We give you closure.
          </p>
          <p className="fine mt-5">
            Built without a server, on purpose.
            <br />
            Made in Europe.
          </p>
        </div>

        {COLUMNS.map((col) => (
          <div key={col.title}>
            <p className="kicker kicker-mid">{col.title}</p>
            <ul className="mt-5 flex flex-col gap-3">
              {col.links.map((l) => (
                <li key={l.href + l.label}>
                  <Link
                    href={l.href}
                    className="text-[15px] transition-colors hover:text-[var(--accent)]"
                    style={{ color: "var(--ink-soft)" }}
                  >
                    {l.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <div className="wrap">
        <div className="hairline" />
        <div className="flex flex-wrap items-center justify-between gap-4 py-7">
          <p className="fine">© {new Date().getFullYear()} Burn My Desire</p>
          <p className="fine">No accounts · No tracking · No cloud</p>
        </div>
      </div>
    </footer>
  );
}
