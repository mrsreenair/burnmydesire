"use client";

import { useEffect, useState } from "react";
import CountUp from "@/components/count-up";
import Reveal from "@/components/reveal";

export type Stats = {
  totalCents: number;
  thoughts: number;
  contributors: number;
  updatedAt?: string | null;
};

/**
 * How long ago the last burn landed, in words.
 *
 * Deliberately coarse. The counter knows the minute a total last moved
 * and nothing about who moved it, so anything more precise would imply
 * a resolution the data does not have.
 */
function timeAgo(iso: string, now: number): string | null {
  const then = Date.parse(iso);
  if (Number.isNaN(then)) return null;
  const seconds = Math.floor((now - then) / 1000);
  if (seconds < 0) return null;
  if (seconds < 90) return "just now";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes} minutes ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return hours === 1 ? "an hour ago" : `${hours} hours ago`;
  const days = Math.floor(hours / 24);
  return days === 1 ? "yesterday" : `${days} days ago`;
}

/**
 * The public total.
 *
 * The number is fetched once at build time so the page ships with it
 * already in the HTML — that part survives from the original design, and
 * it is what a crawler or a reader without JavaScript sees. But the site
 * is a static export now, so "build time" can be days ago. The browser
 * therefore asks the counter directly on mount and replaces the figure
 * if it has moved.
 */
export default function WorldCounterLive({
  initial,
  endpoint,
  standalone = false,
}: {
  initial: Stats | null;
  endpoint: string | null;
  /** On its own page, an empty counter explains itself instead of vanishing. */
  standalone?: boolean;
}) {
  const [stats, setStats] = useState<Stats | null>(initial);
  const [ago, setAgo] = useState<string | null>(null);

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
          thoughts: json.thoughts ?? 0,
          contributors: json.contributors ?? 0,
          updatedAt: json.updatedAt ?? null,
        });
      } catch {
        // A stale number beats a broken section; keep whatever we have.
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [endpoint]);

  // Computed after mount, never during render: "four minutes ago" is
  // true at the moment it is read, not at the moment the page was built,
  // and rendering it on the server would hydrate into a contradiction.
  useEffect(() => {
    const at = stats?.updatedAt;
    if (!at) {
      setAgo(null);
      return;
    }
    const tick = () => setAgo(timeAgo(at, Date.now()));
    tick();
    const timer = setInterval(tick, 30_000);
    return () => clearInterval(timer);
  }, [stats?.updatedAt]);

  if (!stats || (stats.totalCents <= 0 && stats.thoughts <= 0)) {
    if (!standalone) return null;
    return (
      <section className="section-tight" id="counter">
        <div className="wrap">
          <div className="mx-auto max-w-3xl text-center">
            <p className="kicker">Burned so far</p>
            <p className="display mt-4 text-[56px] sm:text-[86px]">€0</p>
            <p className="mt-4 text-lg">
              Nobody has added a total yet. The first number here will be
              real, which is the only kind worth putting up.
            </p>
          </div>
        </div>
      </section>
    );
  }

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
            {stats.thoughts > 0 && (
              <p className="mt-2 text-lg">
                and {stats.thoughts.toLocaleString("en-US")}{" "}
                {stats.thoughts === 1 ? "thought" : "thoughts"} let go, which
                had no price at all.
              </p>
            )}
            {ago && (
              <p className="kicker-mid mt-5" aria-live="polite">
                Last burn {ago}
              </p>
            )}
            <p className="fine mx-auto mt-6 max-w-xl">
              Self-reported by people who chose to add their totals. The app
              sends two numbers and nothing else — no account, no identifiers,
              not a word of any thought, nothing that could point back to
              anyone.
            </p>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
