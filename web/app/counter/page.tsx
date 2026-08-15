import type { Metadata } from "next";
import Link from "next/link";
import PageHero from "@/components/page-hero";
import Reveal from "@/components/reveal";
import WorldCounter from "@/components/world-counter";

export const metadata: Metadata = {
  title: "Burned so far",
  description:
    "The running total of what people chose not to buy, self-reported and anonymous.",
};

const NOTES = [
  {
    h: "What the number is",
    p: [
      "Every euro here is money someone decided not to spend, added by that person from inside the app. It is not revenue, not a valuation, and not a projection — it is a sum of individual refusals.",
    ],
  },
  {
    h: "What it is not",
    p: [
      "It is self-reported and unverifiable. We cannot check any of it, and we will not pretend otherwise. A number nobody can audit is worth something only for as long as it is honest, so it is never rounded up, seeded, or nudged along.",
    ],
  },
  {
    h: "How your total gets here",
    p: [
      "It doesn't, unless you ask. The app never sends anything by default. After a burn it offers once — \"add your total to the world counter?\" — and you can say no and never see it again, or turn it on later in Settings.",
      "When it is on, the app sends one number: how much your protected total has grown since last time. No name, no device id, no timestamp of your own, nothing that could be traced back to you. The server adds it to the running sum and forgets everything else, because there is nothing else to forget.",
    ],
  },
  {
    h: "Why it cannot be undone",
    p: [
      "Turning the counter off stops any further sending, but what was already counted stays in the total. Nothing recorded which part of the sum was yours, so there is nothing to pull back out. That is the cost of collecting no identifiers, and we would rather pay it than keep a record of who contributed what.",
    ],
  },
];

export default function Counter() {
  return (
    <>
      <PageHero
        kicker="Burned so far"
        title={
          <>
            Money that stayed <em>where it was</em>.
          </>
        }
        lede="A running total of what people chose not to buy. Added by hand, by people who opted in, and left exactly as reported."
      />

      <WorldCounter standalone />

      <section className="section-tight pb-28">
        <div className="wrap wrap-narrow">
          {NOTES.map((s, i) => (
            <Reveal key={s.h} delay={Math.min(i, 3) * 70}>
              <div
                className="py-9"
                style={{ borderTop: "1px solid var(--hair-soft)" }}
              >
                <h2 className="display text-[clamp(24px,2.6vw,30px)]">{s.h}</h2>
                {s.p.map((para) => (
                  <p
                    key={para}
                    className="mt-4 text-[17px] leading-[1.65]"
                    style={{ color: "var(--ink-soft)" }}
                  >
                    {para}
                  </p>
                ))}
              </div>
            </Reveal>
          ))}

          <Reveal>
            <p className="fine mt-10">
              The mechanics are spelled out in the{" "}
              <Link href="/privacy" className="underline">
                privacy policy
              </Link>
              .
            </p>
          </Reveal>
        </div>
      </section>
    </>
  );
}
