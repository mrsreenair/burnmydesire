import CountUp from "@/components/count-up";
import Reveal from "@/components/reveal";

type Stats = {
  totalCents: number;
  contributors: number;
};

/**
 * The public total, fetched server-side so the page ships with the number
 * already in it. Renders nothing when the counter isn't configured or is
 * unreachable — a broken stat block is worse than no stat block.
 */
async function fetchStats(): Promise<Stats | null> {
  const base = process.env.COUNTER_URL;
  if (!base) return null;
  try {
    const res = await fetch(`${base}/api/stats`, {
      // Fresh enough to feel alive, cached enough to survive a front page.
      next: { revalidate: 300 },
    });
    if (!res.ok) return null;
    const json = (await res.json()) as Partial<Stats>;
    if (typeof json.totalCents !== "number") return null;
    return {
      totalCents: json.totalCents,
      contributors: json.contributors ?? 0,
    };
  } catch {
    return null;
  }
}

export default async function WorldCounter() {
  const stats = await fetchStats();
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
              {stats.contributors === 1 ? "person" : "people"} who burned
              what they wanted instead of buying it.
            </p>
            <p className="fine mx-auto mt-6 max-w-xl">
              Self-reported by people who chose to add their total. The app
              sends one number and nothing else — no account, no
              identifiers, nothing that could point back to anyone.
            </p>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
