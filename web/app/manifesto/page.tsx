import type { Metadata } from "next";
import Link from "next/link";
import PageHero from "@/components/page-hero";
import Reveal from "@/components/reveal";

export const metadata: Metadata = {
  title: "Manifesto",
  description:
    "Why we built an app that destroys things instead of one that asks you to wait — and the rules we won't break to grow it.",
};

const BELIEFS = [
  {
    n: "01",
    title: "The urge is not asking a question",
    body: "It is not waiting for evidence, and it will not be argued out of existence. Anything that answers a craving with a spreadsheet is answering the wrong organ.",
  },
  {
    n: "02",
    title: "Closure beats patience",
    body: "People tear up photographs and delete the number because finishing something works. We gave that instinct sixty frames a second and attached it to your money.",
  },
  {
    n: "03",
    title: "Price the habit, not the item",
    body: "The cheapest thing on your list is usually the most expensive line in your life. A €6 coffee, five days a week, outruns almost any single purchase you will ever regret.",
  },
  {
    n: "04",
    title: "Shame is not a growth strategy",
    body: "No streak you can break, no red numbers, no push notification asking why you lapsed. Coming back four times is the system working, not you failing.",
  },
  {
    n: "05",
    title: "The data should be impossible to leak",
    body: "Not carefully guarded — absent. No account, no server, no analytics. If the promise is that your temptations never leave your phone, it has to be architecturally true.",
  },
  {
    n: "06",
    title: "The fire has to be real",
    body: "A cross-fade would have shipped a year earlier and destroyed the entire argument. Some things are the product, and you do not get to approximate them.",
  },
];

export default function Manifesto() {
  return (
    <>
      <PageHero
        kicker="Manifesto"
        title={
          <>
            We build for the worst <em>eleven minutes</em> of your day.
          </>
        }
        lede="Not the calm Sunday when you write a budget. The moment at 1am with the tab already open, when every sensible tool you installed has nothing to say."
      />

      <section className="pb-4">
        <div className="wrap wrap-narrow">
          <Reveal>
            <div className="prose-serif">
              <p>
                Every app in this category is built for the version of you that
                is already regulated. It asks you to log the thing, wait
                seventy-two hours, and then decide with a clear head. That is
                excellent advice for someone who does not need the app.
              </p>
              <p>
                We started from the opposite end: what does the person in the
                grip of it actually have? About forty seconds of attention, a
                phone in one hand, and a craving that wants to be resolved right
                now. Anything that does not fit in that window is decoration.
              </p>
            </div>
          </Reveal>
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <div className="grid gap-x-10 gap-y-12 md:grid-cols-2">
            {BELIEFS.map((b, i) => (
              <Reveal key={b.n} delay={(i % 2) * 100}>
                <div className="pt-6" style={{ borderTop: "1px solid var(--hair)" }}>
                  <p className="kicker">{b.n}</p>
                  <h2 className="display mt-4 text-[clamp(24px,2.6vw,32px)]">
                    {b.title}
                  </h2>
                  <p className="lede mt-3 text-[16px]">{b.body}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      <section className="pb-4">
        <div className="wrap">
          <Reveal>
            <div className="ritual px-8 py-20 text-center sm:px-12">
              <div className="ritual-glow" aria-hidden />
              <div className="relative mx-auto max-w-[24ch]">
                <h2 className="display" style={{ color: "#FFF6EE" }}>
                  Your brain wanted an ending. Give it <em>one</em>.
                </h2>
              </div>
              <div className="ember-line mx-auto mt-10 max-w-[420px]" />
            </div>
          </Reveal>
        </div>
      </section>

      <section className="section">
        <div className="wrap wrap-narrow">
          <Reveal>
            <div className="prose-serif">
              <p>
                Burning is the wedge, not the ceiling. Impulse purchases are the
                first category because they are the easiest to price, but the
                same craving-shock-burn loop is what people reach for with
                drinking, smoking, junk food, and the things that have no price
                tag at all.
              </p>
              <p>
                What will not change: no accounts, no cloud, no advertising, and
                no mechanic that works by making you feel worse. If we ever need
                to break one of those to grow, that will be the answer about
                whether we should.
              </p>
            </div>
            <div className="mt-10 flex flex-wrap gap-3">
              <Link href="/#get" className="btn btn-fire">
                 Download on iPhone
              </Link>
              <Link href="/blog" className="btn btn-ghost">
                Read the blog
              </Link>
            </div>
          </Reveal>
        </div>
      </section>
    </>
  );
}
