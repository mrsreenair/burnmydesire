import type { Metadata } from "next";
import Link from "next/link";
import PageHero from "@/components/page-hero";
import Reveal from "@/components/reveal";
import { formatReleaseDate, releases, type ChangeKind } from "@/lib/changelog";

export const metadata: Metadata = {
  title: "Changelog",
  description:
    "What shipped, when, and what it changed — every release of Burn My Desire.",
};

const KIND_STYLE: Record<ChangeKind, { bg: string; fg: string }> = {
  New: { bg: "rgba(255,107,44,.12)", fg: "#C2450F" },
  Improved: { bg: "var(--field)", fg: "var(--ink-soft)" },
  Security: { bg: "rgba(23,165,103,.12)", fg: "var(--money-deep)" },
  Fixed: { bg: "rgba(184,134,11,.14)", fg: "#8A6508" },
};

export default function Changelog() {
  return (
    <>
      <PageHero
        kicker="Changelog"
        title={
          <>
            Everything that has <em>shipped</em>.
          </>
        }
        lede="Written for people, not for a release-notes field. Security work gets the same billing as features, because for this app it is a feature."
      />

      <section className="section-tight pb-28">
        <div className="wrap">
          {releases.map((release, i) => (
            <Reveal key={release.version} delay={Math.min(i, 3) * 80}>
              <article
                className="grid gap-8 py-12 md:grid-cols-[220px_1fr] md:gap-16"
                style={{ borderTop: "1px solid var(--hair)" }}
              >
                <header className="md:sticky md:top-24 md:self-start">
                  <p className="display text-[30px]">{release.version}</p>
                  <p className="fine mt-1">{formatReleaseDate(release.date)}</p>
                  {i === 0 ? (
                    <span
                      className="kicker mt-4 inline-block rounded-full px-3 py-1.5 text-[10.5px]"
                      style={{ background: "rgba(255,107,44,.12)", color: "#C2450F" }}
                    >
                      Latest
                    </span>
                  ) : null}
                </header>

                <div>
                  <h2 className="display text-[clamp(26px,3vw,36px)]">
                    {release.headline}
                  </h2>
                  <ul className="mt-8 flex flex-col gap-6">
                    {release.changes.map((change) => (
                      <li key={change.text} className="flex flex-col gap-2.5 sm:flex-row sm:gap-5">
                        <span
                          className="inline-flex h-[26px] shrink-0 items-center self-start rounded-full px-3 text-[11px] font-bold uppercase tracking-[.12em] sm:w-[96px] sm:justify-center"
                          style={{
                            background: KIND_STYLE[change.kind].bg,
                            color: KIND_STYLE[change.kind].fg,
                          }}
                        >
                          {change.kind}
                        </span>
                        <p
                          className="max-w-[62ch] text-[16.5px] leading-[1.62]"
                          style={{ color: "var(--ink-soft)" }}
                        >
                          {change.text}
                        </p>
                      </li>
                    ))}
                  </ul>
                </div>
              </article>
            </Reveal>
          ))}

          <Reveal>
            <div
              className="card mt-10 flex flex-wrap items-center justify-between gap-6 p-9"
              style={{ transform: "none" }}
            >
              <div>
                <h2 className="display text-[26px]">Want the next release?</h2>
                <p className="lede mt-2 text-[15.5px]">
                  The beta lands on TestFlight before the App Store does.
                </p>
              </div>
              <Link href="/contact" className="btn btn-dark">
                Ask for beta access
              </Link>
            </div>
          </Reveal>
        </div>
      </section>
    </>
  );
}
