import type { Metadata } from "next";
import Link from "next/link";
import Accordion, { type QA } from "@/components/accordion";
import PageHero from "@/components/page-hero";
import Reveal from "@/components/reveal";

export const metadata: Metadata = {
  title: "FAQ",
  description:
    "How the burn works, where the compound number comes from, what happens to your data, and what it costs.",
};

const GROUPS: { title: string; items: QA[] }[] = [
  {
    title: "The app",
    items: [
      {
        q: "What actually happens when I burn something?",
        a: (
          <>
            You press and hold, and a fire shader consumes the photo along a
            real burning front — glowing at the edge, charring just ahead of it,
            curling the paper as it goes. Let go and it stops where it is. Hold
            to the end and the desire is marked burned, its compound value is
            added to your kept total, and the photo is destroyed on the device.
          </>
        ),
      },
      {
        q: "The urge came back. Did I fail?",
        a: (
          <>
            No — and re-burning is a supported action, not an error state. In
            the beta, most resisted desires were logged more than once. A
            craving showing up a fourth time and being burned a fourth time is
            the system working, not you failing.
          </>
        ),
      },
      {
        q: "Can I use it for things that aren't purchases?",
        a: (
          <>
            Yes. Drinking, smoking, junk food, the 1am scroll, a person you keep
            looking up — anything you want an ending for. Habits with a price
            get the compound number as well, because recurring costs compound
            hardest. Desires with no price tag skip the shock card and go
            straight to the burn.
          </>
        ),
      },
      {
        q: "Which devices does it run on?",
        a: (
          <>
            iPhone, iOS 17 and later. The fire needs a GPU shader, which is why
            iOS came first. Android is on the roadmap; there is no web version
            of the app itself, and there won&apos;t be, because that would mean
            putting your data on a server.
          </>
        ),
      },
    ],
  },
  {
    title: "The money",
    items: [
      {
        q: "Where does the big number come from?",
        a: (
          <>
            It is a compound growth calculation on the amount you entered, run
            to your retirement age at an assumed 7% annual return — roughly the
            long-run real return of a broad global equity index after inflation.
            The rate and the horizon are printed on the card so you can check
            the arithmetic, and you can change the rate in Settings.
          </>
        ),
      },
      {
        q: "Isn't 7% optimistic?",
        a: (
          <>
            It is an assumption, not a promise. Set it to 4% if you would rather
            be conservative — the app will use your number everywhere, including
            in past entries. What matters for the mechanic is that the figure is
            honest and auditable, not that it is large.
          </>
        ),
      },
      {
        q: "Is this financial advice?",
        a: (
          <>
            No. Burn My Desire does not sell, recommend, or connect to any
            financial product, and it has no idea what you actually invest in.
            It does arithmetic on a number you typed in, to make an
            opportunity cost visible at the moment you are deciding.
          </>
        ),
      },
      {
        q: "What does it cost?",
        a: (
          <>
            Free to start, with a paid tier for unlimited history and the
            broader habit categories. Pricing is set at launch — no subscription
            traps, and the free tier stays genuinely usable rather than being a
            timed demo.
          </>
        ),
      },
    ],
  },
  {
    title: "Your data",
    items: [
      {
        q: "Do I need an account?",
        a: (
          <>
            There isn&apos;t one. No email, no password, no social login, and
            nothing to delete later. There is no backend, so an account would
            have nothing to unlock. A local PIN or Face ID is the only gate.
          </>
        ),
      },
      {
        q: "Where are my photos stored?",
        a: (
          <>
            In the app&apos;s own container on your phone, written with complete
            data protection — unreadable while the device is locked. The
            database around them is encrypted with a key held in the iOS
            Keychain rather than shipped in the app.
          </>
        ),
      },
      {
        q: "What happens if I lose my phone?",
        a: (
          <>
            Your history goes with it, unless it was inside an encrypted device
            backup. That is the honest trade for having no server: nobody else
            can read it, and that includes us, so nobody else can restore it
            either.
          </>
        ),
      },
      {
        q: "Is there any tracking or analytics?",
        a: (
          <>
            No analytics SDK, no advertising identifier, no crash reporter that
            ships your content. &quot;Erase everything&quot; genuinely destroys
            the database, the images, the preferences and the key — there is no
            copy elsewhere, because there was never a copy elsewhere.
          </>
        ),
      },
    ],
  },
];

export default function Faq() {
  return (
    <>
      <PageHero
        kicker="FAQ"
        title={
          <>
            Questions people actually <em>ask</em>.
          </>
        }
        lede="The burn, the maths behind the number, and what happens to your data. If something isn't here, write to us — we answer everything."
      >
        <div className="mt-8">
          <Link href="/contact" className="btn btn-dark">
            Ask us something
          </Link>
        </div>
      </PageHero>

      <section className="pb-8">
        <div className="wrap wrap-narrow">
          {GROUPS.map((group, i) => (
            <Reveal key={group.title} delay={i * 60}>
              <div className="mb-16">
                <p className="kicker kicker-mid mb-6">{group.title}</p>
                <Accordion items={group.items} defaultOpen={i === 0 ? 0 : null} />
              </div>
            </Reveal>
          ))}
        </div>
      </section>

      <section className="section-tight">
        <div className="wrap wrap-narrow">
          <Reveal>
            <div className="card p-10 text-center" style={{ transform: "none" }}>
              <h2 className="display text-[30px]">Still have questions?</h2>
              <p className="lede mx-auto mt-3 max-w-[40ch] text-[16px]">
                There&apos;s no support ticket system and no bot. Mail lands with
                the people who built it.
              </p>
              <div className="mt-7 flex flex-wrap justify-center gap-3">
                <Link href="/contact" className="btn btn-dark">
                  Contact us
                </Link>
                <Link href="/privacy" className="btn btn-ghost">
                  Privacy policy
                </Link>
              </div>
            </div>
          </Reveal>
        </div>
      </section>
    </>
  );
}
