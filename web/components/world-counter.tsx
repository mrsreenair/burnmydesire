import WorldCounterLive, { type Stats } from "@/components/world-counter-live";

/**
 * The build-time half of the counter.
 *
 * Fetched here so the page ships with the number already in it. The
 * browser half, in WorldCounterLive, brings it up to date on load —
 * necessary because a static export bakes this in whenever the site last
 * built, which may be a while ago.
 */
async function fetchStats(base: string): Promise<Stats | null> {
  try {
    const res = await fetch(`${base}/api/stats`, {
      next: { revalidate: 300 },
    });
    if (!res.ok) return null;
    const json = (await res.json()) as Partial<Stats>;
    if (typeof json.totalCents !== "number") return null;
    return {
      totalCents: json.totalCents,
      thoughts: json.thoughts ?? 0,
      contributors: json.contributors ?? 0,
      updatedAt: json.updatedAt ?? null,
    };
  } catch {
    return null;
  }
}

export default async function WorldCounter({
  standalone = false,
}: {
  standalone?: boolean;
}) {
  const base = process.env.COUNTER_URL ?? null;
  const stats = base ? await fetchStats(base) : null;

  return (
    <WorldCounterLive
      initial={stats}
      endpoint={base}
      standalone={standalone}
    />
  );
}
