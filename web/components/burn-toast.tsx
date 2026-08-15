"use client";

import { useEffect, useRef, useState } from "react";

type Stats = { totalCents: number; contributors: number };

/** How often the total is checked. Matches the endpoint's cache window. */
const POLL_MS = 60_000;
const VISIBLE_MS = 7_000;

/**
 * A quiet note when the world total actually moves.
 *
 * The shop-style version of this ("someone in Berlin just bought…") is
 * usually invented. This one cannot be: the counter keeps two integers
 * and no event log, so the only thing there is to report is a real
 * increase between two reads. If nobody burns anything, nothing appears
 * — which is the honest behaviour and the whole point.
 *
 * The contributor count decides the wording. A total that rose along
 * with the count is one new person; a total that rose without it is
 * someone already counted, adding more.
 */
function describe(deltaCents: number, deltaPeople: number): string {
  const euros = Math.floor(deltaCents / 100).toLocaleString("en-US");
  if (deltaPeople === 1) return `Someone just burned €${euros}`;
  if (deltaPeople > 1) return `€${euros} burned by ${deltaPeople} people just now`;
  return `Another €${euros} burned just now`;
}

export default function BurnToast({ endpoint }: { endpoint: string | null }) {
  const [message, setMessage] = useState<string | null>(null);
  const previous = useRef<Stats | null>(null);
  const hideTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (!endpoint) return;
    let stopped = false;

    async function check() {
      try {
        const res = await fetch(`${endpoint}/api/stats`);
        if (!res.ok) return;
        const json = (await res.json()) as Partial<Stats>;
        if (stopped || typeof json.totalCents !== "number") return;

        const now: Stats = {
          totalCents: json.totalCents,
          contributors: json.contributors ?? 0,
        };
        const before = previous.current;
        previous.current = now;

        // The first read is only a baseline — there is nothing to
        // compare it against, so it never announces anything.
        if (!before) return;

        const deltaCents = now.totalCents - before.totalCents;
        if (deltaCents <= 0) return;

        setMessage(describe(deltaCents, now.contributors - before.contributors));
        if (hideTimer.current) clearTimeout(hideTimer.current);
        hideTimer.current = setTimeout(() => setMessage(null), VISIBLE_MS);
      } catch {
        // Offline or blocked: stay silent and try again next time.
      }
    }

    check();
    const poll = setInterval(check, POLL_MS);
    return () => {
      stopped = true;
      clearInterval(poll);
      clearTimeout(hideTimer.current ?? undefined);
    };
  }, [endpoint]);

  if (!message) return null;

  return (
    <div
      aria-live="polite"
      className="burn-toast fixed bottom-5 left-5 z-50 max-w-[calc(100vw-2.5rem)]"
    >
      <div
        className="flex items-center gap-3 rounded-full py-3 pl-4 pr-5 shadow-lg"
        style={{
          background: "var(--paper)",
          border: "1px solid var(--hair-soft)",
        }}
      >
        <span aria-hidden className="text-lg leading-none">
          🔥
        </span>
        <p className="text-[15px]" style={{ color: "var(--ink)" }}>
          {message}
        </p>
      </div>
    </div>
  );
}
