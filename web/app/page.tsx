import Image from 'next/image';
import Link from 'next/link';

const features = [
  {
    emoji: '📸',
    title: 'Capture the craving',
    body: 'Photograph the thing you want but shouldn\'t buy — in a store or from any shopping app.',
  },
  {
    emoji: '💸',
    title: 'See the real damage',
    body: 'One number shows what the purchase steals from your future self over 10, 20 or 30 years — installments included.',
  },
  {
    emoji: '🔥',
    title: 'Burn it to ash',
    body: 'Press and hold. A GPU-rendered fire consumes it at 60fps. The craving goes with it.',
  },
  {
    emoji: '🛡️',
    title: 'Watch your wealth grow',
    body: 'Every resisted urge adds to your protected total. Cravings come back? Burn them again — resistance counts.',
  },
];

const screens = [
  { src: '/screens/home.png', alt: 'Home screen showing wealth protected' },
  { src: '/screens/shock.png', alt: 'Shock screen showing the true cost of a purchase' },
  { src: '/screens/burn.png', alt: 'Burn screen with a photo ready to burn' },
];

export default function Home() {
  return (
    <main className="min-h-screen bg-[#0d0d0f] text-neutral-100">
      {/* Hero */}
      <section className="mx-auto max-w-5xl px-6 pb-16 pt-24 text-center">
        <p className="mb-6 text-5xl">🔥</p>
        <h1 className="mx-auto max-w-3xl text-5xl font-black tracking-tight sm:text-6xl">
          Burn the urge.
          <br />
          <span className="text-orange-500">Keep the wealth.</span>
        </h1>
        <p className="mx-auto mt-6 max-w-2xl text-lg leading-relaxed text-neutral-400">
          Impulse buying isn&apos;t a math problem — it&apos;s a dopamine loop.
          Burn My Desire is an iPhone app that breaks it in two punches: see
          exactly what a purchase steals from your future, then burn it to ash
          with your own hands.
        </p>
        <div className="mt-10 flex flex-col items-center gap-3">
          <div className="inline-flex items-center gap-3 rounded-full bg-orange-600 px-8 py-4 text-base font-bold text-white">
             App Store — coming soon
          </div>
          <p className="text-sm text-neutral-500">
            Follow along: the beta lands on TestFlight first.
          </p>
        </div>
      </section>

      {/* App screenshots */}
      <section className="mx-auto max-w-5xl px-6 py-16">
        <div className="grid gap-8 sm:grid-cols-3">
          {screens.map((s) => (
            <div
              key={s.src}
              className="overflow-hidden rounded-[2rem] border border-neutral-800 shadow-2xl shadow-orange-950/20"
            >
              <Image
                src={s.src}
                alt={s.alt}
                width={1206}
                height={2622}
                className="h-auto w-full"
              />
            </div>
          ))}
        </div>
      </section>

      {/* Features */}
      <section id="about" className="mx-auto max-w-5xl px-6 py-16">
        <h2 className="mb-12 text-center text-3xl font-extrabold sm:text-4xl">
          How it works
        </h2>
        <div className="grid gap-8 sm:grid-cols-2">
          {features.map((f) => (
            <div
              key={f.title}
              className="rounded-3xl border border-neutral-800 bg-neutral-900/60 p-8"
            >
              <p className="text-4xl">{f.emoji}</p>
              <h3 className="mt-4 text-xl font-bold">{f.title}</h3>
              <p className="mt-2 leading-relaxed text-neutral-400">{f.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* About */}
      <section className="mx-auto max-w-3xl px-6 py-16 text-center">
        <h2 className="text-3xl font-extrabold sm:text-4xl">
          Why we built this
        </h2>
        <p className="mx-auto mt-6 leading-relaxed text-neutral-400">
          Budgeting apps answer an emotional urge with charts — and lose.
          Cooling-off apps ask you to wait — but waiting takes the discipline
          you don&apos;t have mid-craving. Burn My Desire gives you closure
          instead: a shocking number your rational brain can&apos;t unsee, and
          a ritual your emotional brain actually enjoys. Burn the desire, not
          your money.
        </p>
      </section>

      {/* Privacy */}
      <section className="mx-auto max-w-3xl px-6 py-16 text-center">
        <h2 className="text-2xl font-extrabold">
          Your temptations never leave your phone
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-neutral-400">
          No account. No cloud. No tracking. Every photo and every number stays
          on your device — a list of things you crave is nobody&apos;s business
          but yours.{' '}
          <Link href="/privacy" className="text-orange-500 underline">
            Read the privacy policy
          </Link>
          .
        </p>
      </section>

      {/* Contact */}
      <section id="contact" className="mx-auto max-w-3xl px-6 py-16 text-center">
        <h2 className="text-2xl font-extrabold">Contact</h2>
        <p className="mt-4 text-neutral-400">
          Questions, feedback, or press?{' '}
          <a
            href="mailto:hello@burnmydesire.com"
            className="text-orange-500 underline"
          >
            hello@burnmydesire.com
          </a>
        </p>
      </section>

      <footer className="border-t border-neutral-900 px-6 py-10 text-center text-sm text-neutral-600">
        <p>© 2026 Burn My Desire · burnmydesire.com</p>
        <div className="mt-3 flex justify-center gap-6">
          <Link href="/privacy" className="hover:text-neutral-400">
            Privacy
          </Link>
          <a href="mailto:hello@burnmydesire.com" className="hover:text-neutral-400">
            Contact
          </a>
        </div>
        <p className="mx-auto mt-4 max-w-2xl leading-relaxed">
          In-app projections assume an 8% average annual return (historical
          market average) and are for illustration only — not financial advice,
          and not a guarantee of future returns.
        </p>
      </footer>
    </main>
  );
}
