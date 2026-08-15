import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import PageHero from "@/components/page-hero";
import Reveal from "@/components/reveal";

export const metadata: Metadata = {
  title: "How it works",
  description:
    "Name the desire, see what it costs in twenty-year money, then burn it. Every screen of Burn My Desire, in order.",
};

const CHAPTERS = [
  {
    n: "01",
    kicker: "Capture",
    title: "Name the desire",
    body: "Photograph the thing in a shop, paste a link, or just write the sentence. Add what it costs — and, if it's a habit, how often it repeats. A €429 one-off and €40 of drinks every Friday are both first-class citizens here.",
    points: [
      "Photo, link, or plain text",
      "One-off or recurring",
      "Emotional desires with no price tag are allowed too",
    ],
    src: "/screens/home.webp",
    alt: "The home screen listing logged desires and total wealth kept",
  },
  {
    n: "02",
    kicker: "Shock",
    title: "See what it actually costs",
    body: "The app answers with one number: what that money becomes if it stays invested until you're 65. It shows the rate and the horizon on the card, so the figure is auditable rather than a scare. Change the assumed return in Settings if 7% isn't your number.",
    points: [
      "Compound value at 10, 20 and 30 years",
      "Installment plans included, interest and all",
      "Recurring habits priced across the whole horizon",
    ],
    src: "/screens/shock.webp",
    alt: "The shock screen showing the compound cost of a purchase",
  },
  {
    n: "03",
    kicker: "Burn",
    title: "Give the craving an ending",
    body: "The room goes dark — the only dark screen in the app. Press and hold, and a GPU fire eats across the photo along a real burning front, glowing at the edge and curling the paper. Let go and it stops. Hold to the end and it's gone.",
    points: [
      "60fps fragment shader, no video, no canned animation",
      "Press-and-hold, so the ending is something you did",
      "Re-burn the same desire as often as it comes back",
    ],
    src: "/screens/burn.webp",
    alt: "The burn screen with a photo being consumed by fire",
  },
];

export default function HowItWorks() {
  return (
    <>
      <PageHero
        kicker="How it works"
        title={
          <>
            Forty seconds, <em>start to ash</em>.
          </>
        }
        lede="Two punches, in the order that works: one rational, one emotional. Neither of them asks you to be stronger than you were five minutes ago."
      />

      {CHAPTERS.map((c, i) => (
        <section className="section-tight" key={c.n}>
          <div
            className={`wrap grid items-center gap-14 lg:grid-cols-2 ${
              i % 2 === 1 ? "lg:[&>*:first-child]:order-2" : ""
            }`}
          >
            <Reveal>
              <p className="kicker">
                {c.n} — {c.kicker}
              </p>
              <h2 className="display mt-4 text-[clamp(32px,4vw,52px)]">
                {c.title}
              </h2>
              <p className="lede mt-5 max-w-[46ch]">{c.body}</p>
              <ul className="mt-7 flex flex-col gap-3">
                {c.points.map((p) => (
                  <li key={p} className="flex items-start gap-3">
                    <span
                      className="mt-[9px] block h-1.5 w-1.5 shrink-0 rounded-full"
                      style={{ background: "var(--accent)" }}
                    />
                    <span className="text-[15.5px]" style={{ color: "var(--ink-soft)" }}>
                      {p}
                    </span>
                  </li>
                ))}
              </ul>
            </Reveal>

            <Reveal variant={i % 2 === 1 ? "tilt-r" : "tilt-l"} delay={120}>
              <div className="flex justify-center">
                <div className="w-full max-w-[300px]">
                  <div className="phone" style={{ transform: "none" }}>
                    <Image
                      src={c.src}
                      alt={c.alt}
                      width={1206}
                      height={2622}
                      sizes="(max-width: 1024px) 70vw, 300px"
                    />
                  </div>
                </div>
              </div>
            </Reveal>
          </div>
        </section>
      ))}

      <section className="section">
        <div className="wrap">
          <Reveal>
            <div className="ritual px-8 py-16 text-center sm:px-12 sm:py-20">
              <div className="ritual-glow" aria-hidden />
              <div className="relative mx-auto max-w-[46ch]">
                <p className="kicker" style={{ color: "var(--spark)" }}>
                  And then the lights come back on
                </p>
                <h2 className="display mt-4" style={{ color: "#FFF6EE" }}>
                  Wake up with the money still in your <em>account</em>.
                </h2>
                <p
                  className="mt-6 text-[17px] leading-[1.65]"
                  style={{ color: "rgba(245,239,231,.68)" }}
                >
                  The fire is one screen. The rest of the app is daylight — what
                  you kept, what you resisted, and how much of it is quietly
                  compounding.
                </p>
                <div className="mt-9 flex justify-center gap-3">
                  <Link href="/#get" className="btn btn-fire">
                     Download on iPhone
                  </Link>
                  <Link
                    href="/faq"
                    className="btn btn-ghost !border-white/25 !bg-white/5 !text-white"
                  >
                    Read the FAQ
                  </Link>
                </div>
              </div>
            </div>
          </Reveal>
        </div>
      </section>
    </>
  );
}
