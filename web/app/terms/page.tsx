import type { Metadata } from "next";
import PageHero from "@/components/page-hero";
import Reveal from "@/components/reveal";

export const metadata: Metadata = {
  title: "Terms of use",
  description:
    "The plain-language terms for using the Burn My Desire app and website.",
};

const SECTIONS = [
  {
    h: "What you're agreeing to",
    p: [
      "By installing or using Burn My Desire you accept these terms. They are deliberately short, because the app collects nothing from you and holds no account on your behalf.",
    ],
  },
  {
    h: "The app is not financial advice",
    p: [
      "Burn My Desire performs a compound growth calculation on figures you enter yourself, using an assumed annual rate you can change. It does not know your circumstances, does not recommend or sell any financial product, and is not a substitute for advice from a licensed adviser.",
      "Projected values are illustrations of opportunity cost, not forecasts, and no outcome is promised.",
    ],
  },
  {
    h: "The app is not treatment",
    p: [
      "The app is a self-directed tool for interrupting impulses. It is not a medical device and does not diagnose or treat addiction, compulsive spending, or any other condition. If a craving is affecting your health, safety or finances seriously, please speak to a professional — the app is not a replacement for that.",
    ],
  },
  {
    h: "Your data is yours, and only yours",
    p: [
      "Everything you create stays on your device. We cannot access it, restore it, migrate it or recover it — including if you lose or reset the phone without a backup. That is the trade for having no server, and it is the design we intend to keep.",
    ],
  },
  {
    h: "What Pro costs",
    p: [
      "Pro is sold three ways: Burn My Desire Pro Monthly at €2.99 a month, Burn My Desire Pro Yearly at €19.99 a year with the first week free, or a one-time Lifetime unlock at €29.99. The App Store shows the price in your own currency, and that figure — not this page — is the one you pay.",
      "All three unlock exactly the same app. The only difference is how long you pay for and how often.",
    ],
  },
  {
    h: "How the subscriptions renew, and how to stop them",
    p: [
      "The monthly and yearly plans renew automatically for the same length of time until you stop them. Apple charges your Apple ID within the 24 hours before the current period ends. The Lifetime unlock never renews, because there is nothing to renew.",
      "You cancel on your own phone, not here: Settings, then your name, then Subscriptions, then turn off renewal at least 24 hours before the period ends. Pro stays on for the time you have already paid for. We cannot cancel it for you, and we would rather not have the ability.",
      "If you start the free week and then buy a subscription before it is up, the rest of the trial is forfeited. That is Apple's rule everywhere, not ours.",
    ],
  },
  {
    h: "Payments and refunds",
    p: [
      "Everything is sold through the App Store and governed by Apple's terms; we never see a card number and hold no billing record of yours. Refunds are Apple's to give, but if something has gone wrong, write to support@burnmydesire.com and we will help you get it sorted.",
    ],
  },
  {
    h: "Acceptable use",
    p: [
      "Don't decompile, resell or redistribute the app, and don't use it to harm anyone. That is the whole list.",
    ],
  },
  {
    h: "Changes and contact",
    p: [
      "If these terms change materially, the app will say so before you next use it rather than quietly updating a page. Questions go to hello@burnmydesire.com.",
    ],
  },
];

export default function Terms() {
  return (
    <>
      <PageHero
        kicker="Terms of use"
        title={
          <>
            Short terms, because there is <em>little to govern</em>.
          </>
        }
        lede="No account, no data of yours in our hands, and a subscription you can end from your own phone in fifteen seconds. What's left is mostly telling you honestly what this app is and isn't."
      >
        <p className="fine mt-8">Last updated: 15 August 2026</p>
      </PageHero>

      <section className="section-tight pb-28">
        <div className="wrap wrap-narrow">
          {SECTIONS.map((s, i) => (
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
        </div>
      </section>
    </>
  );
}
