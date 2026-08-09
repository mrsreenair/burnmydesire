import type { Metadata } from "next";
import Link from "next/link";
import ContactForm from "@/components/contact-form";
import PageHero from "@/components/page-hero";
import Reveal from "@/components/reveal";

export const metadata: Metadata = {
  title: "Contact",
  description:
    "Support, press, and beta access for Burn My Desire. Mail lands with the people who built it.",
};

const DIRECT = [
  {
    label: "Support",
    email: "support@burnmydesire.com",
    note: "Bugs, refunds, anything that isn't working. Usually answered within a day.",
  },
  {
    label: "Press",
    email: "press@burnmydesire.com",
    note: "Interviews, review copies, and the press kit. We'll send TestFlight access.",
  },
  {
    label: "Beta",
    email: "beta@burnmydesire.com",
    note: "The closed TestFlight round. Tell us what you'd be burning — it helps us pick.",
  },
];

export default function Contact() {
  return (
    <>
      <PageHero
        kicker="Contact"
        title={
          <>
            Write to us. A <em>person</em> reads it.
          </>
        }
        lede="No ticket queue, no chatbot, no account required to get help. Three addresses and a small team behind them."
      />

      <section className="pb-4">
        <div className="wrap grid gap-12 lg:grid-cols-[1.15fr_.85fr]">
          <Reveal>
            <ContactForm />
          </Reveal>

          <Reveal delay={140}>
            <div className="flex flex-col gap-8">
              {DIRECT.map((d) => (
                <div
                  key={d.email}
                  className="pt-6"
                  style={{ borderTop: "2px solid var(--accent)" }}
                >
                  <p className="kicker kicker-mid">{d.label}</p>
                  <a
                    href={`mailto:${d.email}`}
                    className="display mt-3 block text-[22px] hover:text-[var(--accent)]"
                  >
                    {d.email}
                  </a>
                  <p className="lede mt-2 text-[14.5px]">{d.note}</p>
                </div>
              ))}
            </div>
          </Reveal>
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <Reveal>
            <div
              className="card flex flex-wrap items-center justify-between gap-8 p-9 sm:p-12"
              style={{ transform: "none" }}
            >
              <div className="max-w-[46ch]">
                <h2 className="display text-[clamp(26px,3vw,36px)]">
                  Looking for an answer rather than a conversation?
                </h2>
                <p className="lede mt-3 text-[16px]">
                  Most of what people write in is already in the FAQ — including
                  where the compound number comes from and what happens to your
                  data.
                </p>
              </div>
              <div className="flex flex-wrap gap-3">
                <Link href="/faq" className="btn btn-dark">
                  Read the FAQ
                </Link>
                <Link href="/press" className="btn btn-ghost">
                  Press kit
                </Link>
              </div>
            </div>
          </Reveal>
        </div>
      </section>
    </>
  );
}
