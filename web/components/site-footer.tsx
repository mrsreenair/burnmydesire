import Image from "next/image";
import Link from "next/link";

const COLUMNS = [
  {
    title: "Product",
    links: [
      { href: "/how-it-works", label: "How it works" },
      { href: "/#math", label: "The math" },
      { href: "/counter", label: "Burned so far" },
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
            <Image
              src="/brand/flame.png"
              alt=""
              width={26}
              height={26}
              className="block h-[26px] w-[26px] rounded-[8px]"
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
        <div className="flex flex-wrap items-center justify-between gap-4 pt-7">
          {/* The year of first publication, not the current one. A static
              export bakes whatever it renders, so a dynamic year would
              quietly go stale the moment the site stopped being rebuilt —
              and first publication is the date copyright actually runs
              from anyway. */}
          <p className="fine">© 2026 Burn My Desire. All rights reserved.</p>
          <p className="fine">No accounts · No tracking · No ads</p>
        </div>
        <div className="pb-8">
          {/* ™ rather than ®: the mark is claimed but not registered, and
              ® on an unregistered mark is itself an offence in several
              jurisdictions. It becomes ® once registration comes through. */}
          <p className="fine max-w-3xl">
            Burn My Desire™ and the flame mark are trademarks of Burn My
            Desire. The app, its source code, its visual design and the
            words on this site are protected by copyright and may not be
            reproduced without permission.
          </p>
        </div>
      </div>
    </footer>
  );
}
