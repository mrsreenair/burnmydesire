import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import Reveal from "@/components/reveal";

export const metadata: Metadata = {
  title: "Get the app",
  description:
    "Burn My Desire for iPhone. Price the craving in twenty-year money, then burn it. No account, nothing leaves your phone.",
  alternates: { canonical: "/app" },
};

const POINTS = [
  {
    title: "Nothing to sign up for",
    body: "No email, no password, no account. Open it and start.",
  },
  {
    title: "Works the first time you need it",
    body: "Photograph the thing, see the twenty-year price, hold to burn. Forty seconds.",
  },
  {
    title: "Stays on your phone",
    body: "Encrypted on the device, with no server for it to travel to.",
  },
];

/**
 * The landing page burnmydesire.app points at — reached almost entirely from a
 * phone, so it is one screen of decision and nothing else.
 */
export default function GetTheApp() {
  return (
    <section className="relative overflow-hidden pb-24 pt-12 sm:pt-16">
      <div
        className="wash wash-peach"
        style={{ width: 560, height: 560, top: -260, right: -200 }}
      />
      <div
        className="wash wash-mint wash-delay"
        style={{ width: 480, height: 480, bottom: -280, left: -180 }}
      />

      <div className="wrap relative">
        <div className="mx-auto max-w-[560px] text-center">
          <Reveal variant="pop">
            <div
              className="mx-auto grid h-[86px] w-[86px] place-items-center rounded-[24px] text-[40px]"
              style={{
                background: "linear-gradient(135deg,var(--ember),var(--flame))",
                boxShadow: "0 18px 44px rgba(255,90,25,.42)",
              }}
              aria-hidden
            >
              🔥
            </div>
          </Reveal>

          <Reveal delay={90}>
            <h1 className="display mt-8 text-[clamp(38px,9vw,58px)]">
              Burn My Desire, <em>for iPhone</em>.
            </h1>
            <p className="lede mx-auto mt-5 max-w-[38ch]">
              See what the money becomes in twenty years. Then hold your thumb
              down and watch the thing burn.
            </p>
          </Reveal>

          <Reveal delay={180}>
            <div className="mt-9 flex flex-col items-center gap-3">
              <a href="#" className="btn btn-fire w-full justify-center sm:w-auto">
                 Download on the App Store
              </a>
              <p className="fine">Free to start · iOS 17+ · No account</p>
            </div>
          </Reveal>
        </div>

        <Reveal delay={240} variant="tilt-l">
          <div className="mx-auto mt-16 w-full max-w-[290px]">
            <div className="phone" style={{ transform: "none" }}>
              <Image
                src="/screens/shock.png"
                alt="The shock screen, showing what a purchase costs over twenty years"
                width={1206}
                height={2622}
                priority
                sizes="(max-width: 640px) 80vw, 290px"
              />
            </div>
          </div>
        </Reveal>

        <div className="mx-auto mt-20 grid max-w-[900px] gap-10 sm:grid-cols-3">
          {POINTS.map((p, i) => (
            <Reveal key={p.title} delay={i * 110}>
              <div className="pt-5" style={{ borderTop: "2px solid var(--accent)" }}>
                <h2 className="display text-[21px]">{p.title}</h2>
                <p className="lede mt-2.5 text-[15px]">{p.body}</p>
              </div>
            </Reveal>
          ))}
        </div>

        <Reveal delay={200}>
          <p className="fine mt-16 text-center">
            Want the longer version?{" "}
            <Link href="/" className="underline hover:text-[var(--accent)]">
              Read how it works
            </Link>{" "}
            or{" "}
            <Link href="/privacy" className="underline hover:text-[var(--accent)]">
              what happens to your data
            </Link>
            .
          </p>
        </Reveal>
      </div>
    </section>
  );
}
