import Image from "next/image";
import Link from "next/link";
import BurnDemo from "@/components/burn-demo";
import CountUp from "@/components/count-up";
import Reveal from "@/components/reveal";
import BurnToast from "@/components/burn-toast";
import WorldCounter from "@/components/world-counter";
import { formatDate, posts } from "@/lib/posts";

const STEPS = [
  {
    n: "01",
    title: "Name the desire",
    body: "A photo, a link, or a sentence. €429 headphones counts. So does €40 of drinks every Friday, and so does the thing you keep reopening at 1am.",
    src: "/screens/home.webp",
    alt: "The home screen, listing desires and the wealth kept so far",
  },
  {
    n: "02",
    title: "See the real price",
    body: "Not the sticker price — the twenty-year one. The app answers with what the money becomes if it stays invested until you're 65.",
    src: "/screens/shock.webp",
    alt: "The shock screen, showing a purchase's compound cost",
  },
  {
    n: "03",
    title: "Burn it",
    body: "Hold your thumb down. A real burning front eats across the photo at 60fps, curls the edge, and leaves ash. The craving ends with it.",
    src: "/screens/burn.webp",
    alt: "The burn screen, with a photo mid-burn",
  },
];

const BURNED = [
  "Sony WH-1000XM6 · €429",
  "Friday drinks · €40/wk",
  "Second monitor · €260",
  "The 1am scroll",
  "Ultralight tent · €199",
  "Lunchtime coffee · €6/day",
  "Vape refills · €22/wk",
  "Another mechanical keyboard · €180",
  "Ski jacket, in July · €340",
];

const PRIVACY = [
  {
    title: "No account, ever",
    body: "No sign-up, no email, no password. There's no server, so there is nothing an account could unlock.",
  },
  {
    title: "Encrypted where it lives",
    body: "The database is encrypted with a key held in the iOS Keychain. Photos and thoughts are sealed with complete data protection.",
  },
  {
    title: "Erase means erase",
    body: "One confirmed tap destroys the database, the images and the key. Nothing to recover, because nothing was copied.",
  },
];

export default function Home() {
  const latest = posts.slice(0, 3);

  return (
    <>
      {/* ---------------------------------------------------------------- hero */}
      <section className="relative overflow-hidden pb-20 pt-10 sm:pt-16">
        <div
          className="wash wash-mint"
          style={{ width: 560, height: 560, top: -220, left: -220 }}
        />
        <div
          className="wash wash-peach wash-delay"
          style={{ width: 620, height: 620, top: -160, right: -240 }}
        />
        <div
          className="wash wash-lilac wash-delay-2"
          style={{ width: 440, height: 440, bottom: -260, left: "38%" }}
        />

        <div className="wrap relative grid items-center gap-14 lg:grid-cols-[1.05fr_.95fr]">
          <div>
            <p
              className="enter kicker"
              style={{ "--delay": "60ms" } as React.CSSProperties}
            >
              iPhone · free to start
            </p>

            <h1 className="display mt-6">
              <span
                className="enter block"
                style={{ "--delay": "140ms" } as React.CSSProperties}
              >
                <span className="struck struck-draw">Sleep on it.</span>
              </span>
              <span
                className="enter block"
                style={{ "--delay": "320ms" } as React.CSSProperties}
              >
                <em>Burn it</em> instead.
              </span>
            </h1>

            <p
              className="enter lede mt-7 max-w-[440px]"
              style={{ "--delay": "500ms" } as React.CSSProperties}
            >
              Impulse isn&apos;t a maths problem, so a waiting timer never fixes
              it. Burn My Desire prices the craving in twenty-year money, then
              gives you an ending for it — tonight, not in three days.
            </p>

            <div
              className="enter mt-9 flex flex-wrap items-center gap-3"
              style={{ "--delay": "640ms" } as React.CSSProperties}
            >
              <Link href="#get" className="btn btn-dark">
                 Download on iPhone
              </Link>
              <Link href="#ritual" className="btn btn-fire">
                Try the burn
              </Link>
            </div>

            <p
              className="enter fine mt-5"
              style={{ "--delay": "760ms" } as React.CSSProperties}
            >
              No account. Encrypted on your phone. Your temptations stay there.
            </p>
          </div>

          <div className="relative flex justify-center">
            <div
              className="enter-pop sticky-note absolute z-10"
              style={
                {
                  top: 22,
                  left: -6,
                  transform: "rotate(-8deg)",
                  "--delay": "900ms",
                } as React.CSSProperties
              }
            >
              I don&apos;t need this.
            </div>
            <div
              className="enter-pop sticky-note absolute z-10"
              style={
                {
                  bottom: 74,
                  right: -18,
                  transform: "rotate(6deg)",
                  "--delay": "1040ms",
                } as React.CSSProperties
              }
            >
              Day 12 clean 🔥
            </div>

            <div
              className="enter w-full max-w-[310px]"
              style={
                {
                  "--delay": "380ms",
                } as React.CSSProperties
              }
            >
              <div className="phone" style={{ transform: "rotate(-2.5deg)" }}>
                <Image
                  src="/screens/home.webp"
                  alt="Burn My Desire home screen, showing the wealth kept so far"
                  width={1206}
                  height={2622}
                  priority
                  sizes="(max-width: 1024px) 80vw, 310px"
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ------------------------------------------------------------ marquee */}
      <div
        className="marquee-mask overflow-hidden py-5"
        style={{
          borderBlock: "1px solid var(--hair-soft)",
          background: "rgba(255,255,255,.45)",
        }}
        aria-hidden
      >
        <div className="marquee">
          {[0, 1].map((copy) => (
            <div key={copy} className="flex shrink-0">
              {BURNED.map((item) => (
                <span
                  key={`${copy}-${item}`}
                  className="flex items-center gap-3 whitespace-nowrap px-6 text-[15px]"
                  style={{ color: "var(--ink-soft)" }}
                >
                  <span
                    className="block h-1.5 w-1.5 rounded-full"
                    style={{ background: "var(--accent)" }}
                  />
                  {item}
                </span>
              ))}
            </div>
          ))}
        </div>
      </div>

      {/* ---------------------------------------------------- world counter */}
      <WorldCounter />

      {/* Announces a real increase in the world total, nothing else. */}
      <BurnToast endpoint={process.env.COUNTER_URL ?? null} />

      {/* -------------------------------------------------------- how it works */}
      <section className="section" id="how">
        <div className="wrap">
          <Reveal>
            <p className="kicker">The ritual</p>
            <h2 className="display mt-4 max-w-[16ch]">
              Three taps between the urge and the <em>ash</em>.
            </h2>
            <p className="lede mt-5 max-w-[52ch]">
              It takes about forty seconds. That&apos;s the whole product.
            </p>
          </Reveal>

          <div className="mt-14 grid gap-6 md:grid-cols-3">
            {STEPS.map((step, i) => (
              <Reveal
                key={step.n}
                delay={i * 120}
                variant={i === 1 ? "tilt-r" : "tilt-l"}
              >
                <article
                  className="card hover-lift flex h-full flex-col overflow-hidden p-7"
                  style={{ transform: "none" }}
                >
                  <span
                    className="grid h-8 w-8 place-items-center rounded-[11px] text-[12px] font-bold"
                    style={{ background: "var(--field)", color: "var(--ink-soft)" }}
                  >
                    {step.n}
                  </span>
                  <h3 className="display mt-5 text-[26px]">{step.title}</h3>
                  <p className="lede mt-3 text-[15.5px]">{step.body}</p>
                  <div className="-mx-7 -mb-7 mt-8 overflow-hidden px-10 pt-8">
                    <Image
                      src={step.src}
                      alt={step.alt}
                      width={1206}
                      height={2622}
                      sizes="(max-width: 768px) 70vw, 260px"
                      className="mx-auto block w-full rounded-t-[22px] shadow-[0_-2px_30px_-8px_rgba(58,52,42,.28)]"
                      style={{ maxHeight: 210, objectFit: "cover", objectPosition: "top" }}
                    />
                  </div>
                </article>
              </Reveal>
            ))}
          </div>

          <Reveal delay={200}>
            <div className="mt-12">
              <Link href="/how-it-works" className="link-arrow">
                See every screen
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <path
                    d="M3 8h10M9 4l4 4-4 4"
                    stroke="currentColor"
                    strokeWidth="1.6"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </Link>
            </div>
          </Reveal>
        </div>
      </section>

      {/* ------------------------------------------------------------ the math */}
      <section className="section" id="math">
        <div className="wrap grid items-center gap-16 lg:grid-cols-2">
          <Reveal>
            <p className="kicker kicker-money">The rational shock</p>
            <h2 className="display mt-4">
              €429 is not the price.
              <br />
              <em>This</em> is the price.
            </h2>
            <p
              className="display money-text mt-8"
              style={{ fontSize: "clamp(64px,9vw,124px)", lineHeight: 0.9 }}
            >
              <CountUp to={4180} prefix="€" />
            </p>
            <p className="lede mt-5 max-w-[44ch]">
              What those headphones become by the time you&apos;re 65, at 7% a
              year over 24 years. One-offs compound. Habits compound harder.
            </p>
            <div className="mt-8">
              <Link href="/blog/what-friday-drinks-actually-cost" className="link-arrow">
                How we work the number out
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <path
                    d="M3 8h10M9 4l4 4-4 4"
                    stroke="currentColor"
                    strokeWidth="1.6"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </Link>
            </div>
          </Reveal>

          <Reveal variant="tilt-l" delay={140}>
            <div className="card overflow-hidden" style={{ transform: "none" }}>
              {[
                { name: "Sony WH-1000XM6", meta: "Burned 3 Aug · 24 yrs @ 7%", amt: "+€4,180" },
                { name: "Friday drinks", meta: "Recurring · €40 a week", amt: "+€95,400" },
                { name: "Ultralight tent", meta: "Burned 28 Jul · 24 yrs @ 7%", amt: "+€2,610" },
              ].map((row) => (
                <div
                  key={row.name}
                  className="flex items-center justify-between gap-6 px-7 py-5"
                  style={{ borderBottom: "1px solid var(--hair-soft)" }}
                >
                  <div>
                    <p className="text-[15.5px] font-[650]">{row.name}</p>
                    <p className="fine mt-0.5">{row.meta}</p>
                  </div>
                  <p
                    className="text-[17px] font-extrabold tracking-tight"
                    style={{ color: "var(--money-deep)" }}
                  >
                    {row.amt}
                  </p>
                </div>
              ))}
              <div
                className="flex items-center justify-between gap-6 px-7 py-6"
                style={{ background: "rgba(23,165,103,.07)" }}
              >
                <div>
                  <p className="text-[15.5px] font-[650]">Kept, all in</p>
                  <p className="fine mt-0.5">Since you started</p>
                </div>
                <p
                  className="display text-[30px]"
                  style={{ color: "var(--money-deep)" }}
                >
                  €102,190
                </p>
              </div>
            </div>
          </Reveal>
        </div>
      </section>

      {/* -------------------------------------------------------- the ritual */}
      <section className="pb-4" id="ritual">
        <div className="wrap">
          <div className="ritual px-6 py-20 sm:px-10 sm:py-24">
            <div className="ritual-glow" aria-hidden />
            <div className="relative grid items-center gap-16 lg:grid-cols-2">
              <Reveal>
                <p className="kicker" style={{ color: "var(--spark)" }}>
                  The only dark room in the app
                </p>
                <h2 className="display mt-4" style={{ color: "#FFF6EE" }}>
                  Watching it burn is the part that <em>works</em>.
                </h2>
                <p
                  className="mt-6 max-w-[46ch] text-[17.5px] leading-[1.65]"
                  style={{ color: "rgba(245,239,231,.68)" }}
                >
                  A real fire shader — a burning front that eats across the
                  paper, curls the edge and leaves embers. Your brain gets the
                  ending it was demanding. Then the lights come back on.
                </p>
                <div className="ember-line mt-9 max-w-[380px]" />
                <p
                  className="mt-9 text-[14px]"
                  style={{ color: "rgba(245,239,231,.42)" }}
                >
                  Go on — hold the button.
                </p>
              </Reveal>

              <Reveal variant="pop" delay={120}>
                <BurnDemo />
              </Reveal>
            </div>
          </div>
        </div>
      </section>

      {/* ---------------------------------------------------------- privacy */}
      <section className="section">
        <div className="wrap">
          <Reveal>
            <div className="max-w-[24ch]">
              <p className="kicker">Privacy</p>
              <h2 className="display mt-4">
                The things you&apos;re ashamed of stay on your <em>phone</em>.
              </h2>
            </div>
          </Reveal>

          <div className="mt-14 grid gap-10 md:grid-cols-3">
            {PRIVACY.map((item, i) => (
              <Reveal key={item.title} delay={i * 110}>
                <div
                  className="h-full pt-6"
                  style={{ borderTop: "2px solid var(--accent)" }}
                >
                  <h3 className="display text-[24px]">{item.title}</h3>
                  <p className="lede mt-3 text-[15.5px]">{item.body}</p>
                </div>
              </Reveal>
            ))}
          </div>

          <Reveal delay={200}>
            <div className="mt-12">
              <Link href="/privacy" className="link-arrow">
                Read the full privacy policy
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <path
                    d="M3 8h10M9 4l4 4-4 4"
                    stroke="currentColor"
                    strokeWidth="1.6"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </Link>
            </div>
          </Reveal>
        </div>
      </section>

      {/* ------------------------------------------------------------- blog */}
      <section className="section-tight">
        <div className="wrap">
          <Reveal>
            <div className="flex flex-wrap items-end justify-between gap-6">
              <div>
                <p className="kicker">Writing</p>
                <h2 className="display mt-4 text-[38px] sm:text-[46px]">
                  Notes from the workshop
                </h2>
              </div>
              <Link href="/blog" className="link-arrow">
                All posts
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <path
                    d="M3 8h10M9 4l4 4-4 4"
                    stroke="currentColor"
                    strokeWidth="1.6"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </Link>
            </div>
          </Reveal>

          <div className="mt-12 grid gap-7 md:grid-cols-3">
            {latest.map((post, i) => (
              <Reveal key={post.slug} delay={i * 110}>
                <Link href={`/blog/${post.slug}`} className="group block h-full">
                  <div className="card hover-lift h-full overflow-hidden">
                    <Image
                      src={post.cover}
                      alt=""
                      width={1200}
                      height={750}
                      className="aspect-[8/5] w-full object-cover"
                    />
                    <div className="p-6">
                      <p className="kicker kicker-mid">
                        {post.category} · {post.readingMinutes} min
                      </p>
                      <h3 className="display mt-3 text-[23px]">{post.title}</h3>
                      <p className="fine mt-3">{formatDate(post.date)}</p>
                    </div>
                  </div>
                </Link>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      {/* -------------------------------------------------------- final CTA */}
      <section className="relative overflow-hidden py-28 text-center" id="get">
        <div
          className="wash wash-peach"
          style={{ width: 620, height: 620, bottom: -320, left: "50%", marginLeft: -310 }}
        />
        <div className="wrap relative">
          <Reveal>
            <h2 className="display mx-auto max-w-[15ch]">
              Stop waiting for the urge to pass. Give it an <em>ending</em>.
            </h2>
            <p className="lede mx-auto mt-6 max-w-[42ch]">
              Free to start. Nothing to sign up for. The first burn takes under
              a minute.
            </p>
            <div className="mt-10 flex flex-wrap justify-center gap-3">
              <a href="#" className="btn btn-fire">
                 Download on iPhone
              </a>
              <Link href="/faq" className="btn btn-ghost">
                Read the FAQ
              </Link>
            </div>
            <p className="fine mt-6">iOS 17+ · Android later · No account</p>
          </Reveal>
        </div>
      </section>
    </>
  );
}
