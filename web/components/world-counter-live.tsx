"use client";

import { useEffect, useState } from "react";
import CountUp from "@/components/count-up";
import Reveal from "@/components/reveal";

export type Stats = {
  totalCents: number;
  contributors: number;
};

/**
 * The public total.
 *
 * The number is fetched once at build time so the page ships with it
 * already in the HTML — that part survives from the original design, and
 * it is what a crawler or a reader without JavaScript sees. But the site
 * is a static export now, so "build time" can be days ago. The browser
 * therefore asks the counter directly on mount and replaces the figure
 * if it has moved.
 *
 * The endpoint is handed down from the server component rather than read
 * from a NEXT_PUBLIC_ variable, so there is only ever one place the URL
 * is configured.
 */
export default function WorldCounterLive({
  initial,
  endpoint,
}: {
  initial: Stats | null;
  endpoint: string | null;
}) {
  const [stats, setStats] = useState<Stats | null>(initial);

  useEffect(() => {
    if (!endpoint) return;
    let cancelled = false;

    (async () => {
      try {
        const res = await fetch(`${endpoint}/api/stats`);
        if (!res.ok) return;
        const json = (await res.json()) as Partial<Stats>;
        if (cancelled || typeof json.totalCents !== "number") return;
        setStats({
          totalCents: json.totalCents,
          contributors: json.contributors ?? 0,
        });
      } catch {
        // A stale number beats a broken section; keep whatever we have.
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [endpoint]);

  // Nothing to boast about yet. Renders nothing rather than "€0", which
  // would read as a failure of the idea rather than an empty start.
  if (!stats || stats.totalCents <= 0) return null;

  const euros = Math.floor(stats.totalCents / 100);

  return (
    <section className="section-tight" id="counter">
      <div className="wrap">
        <Reveal>
          <div className="mx-auto max-w-3xl text-center">
            <p className="kicker">Burned so far</p>
            <p className="display mt-4 text-[56px] sm:text-[86px]">
              <CountUp to={euros} prefix="€" />
            </p>
            <p className="mt-4 text-lg">
              protected by {stats.contributors.toLocaleString("en-US")}{" "}
              {stats.contributors === 1 ? "person" : "people"} who burned what
              they wanted instead of buying it.
            </p>
            <p className="fine mx-auto mt-6 max-w-xl">
              Self-reported by people who chose to add their total. The app
              sends one number and nothing else — no account, no identifiers,
              nothing that could point back to anyone.
            </p>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
