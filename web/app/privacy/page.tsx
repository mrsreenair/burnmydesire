import type { Metadata } from "next";
import PageHero from "@/components/page-hero";
import Reveal from "@/components/reveal";

export const metadata: Metadata = {
  title: "Privacy policy",
  description:
    "Burn My Desire stores everything on your device. No accounts, no cloud, no tracking.",
};

const SECTIONS = [
  {
    h: "What the app stores, and where",
    p: [
      "Photos you capture or pick, item prices, installment details, written thoughts and your burn history are saved in the app's private storage on your phone.",
      "The database is encrypted at rest with SQLCipher, using a key generated on first launch and held in the iOS Keychain — not in the app bundle. Photos and thought pages are written with complete data protection, which means they are unreadable while the device is locked.",
      "This data is included in your device backup (iCloud or local) under Apple's standard mechanisms. As the app works today, none of it is sent to us or to any third party.",
    ],
  },
  {
    h: "No accounts, by design",
    p: [
      "There is no sign-up, no email address, no password and no sync. There is no backend, so there is nothing an account could unlock and nothing for us to hold.",
      "A local PIN or Face ID is the only gate on the app, and the PIN is stored as a salted SHA-256 hash in the iOS Keychain.",
    ],
  },
  {
    h: "Camera and photo access",
    p: [
      "The app asks for camera and photo-library permission solely so you can add a picture of the thing you crave. The images stay in the app's private storage; nothing uploads them.",
    ],
  },
  {
    h: "Erasing everything",
    p: [
      "\"Erase everything\" in Settings destroys the database, the stored images, your preferences and the encryption key. Because the app keeps no copy anywhere else, there is nothing left afterwards — including with us.",
      "The one exception is the world counter below, if you switched it on. That number is already part of a public total and cannot be picked back out of it, because nothing recorded which part of the total was yours.",
    ],
  },
  {
    h: "Purchases",
    p: [
      "Optional paid purchases are processed by Apple and, for receipt validation, RevenueCat. We receive no payment details. See Apple's and RevenueCat's privacy policies for how they handle purchase data.",
    ],
  },
  {
    h: "This website",
    p: [
      "burnmydesire.com sets no cookies and runs no analytics or trackers. The contact form composes a mail draft in your own mail client — it does not post anything to a server.",
    ],
  },
  {
    h: "The world counter, if you turn it on",
    p: [
      "One optional feature does send something: the world counter, which adds your protected total to the public figure on this site. It is off unless you switch it on, it sends a single number and nothing else, and the server it reaches stores only a running total and a count of contributors — no identifier, no timestamp, nothing that could be traced back to a person or a phone.",
      "Turning it off stops any further sending. What was already counted stays in the total, because nothing links it to you well enough to take it out again.",
    ],
  },
  {
    h: "If this changes",
    p: [
      "The description above is what the app does today, not a promise about every version of it forever. Features we are considering — richer AI, for instance — could need data to leave the device to work at all.",
      "If that day comes, we will update this page with a new date, say plainly what is sent and why, and tell you inside the app before it starts. Anything new of that kind will be opt-in, the way the world counter is. What we will not do is quietly widen what we collect and leave this page saying otherwise.",
    ],
  },
  {
    h: "Contact",
    p: [
      "Questions about privacy go to privacy@burnmydesire.com and are answered by a person.",
    ],
  },
];

export default function Privacy() {
  return (
    <>
      <PageHero
        kicker="Privacy policy"
        title={
          <>
            It stays on your phone, and we <em>can&rsquo;t</em> read it.
          </>
        }
        lede="Burn My Desire has no accounts, no analytics and nowhere to sign in. Everything you do in the app — photos, prices, thoughts, burn history — is stored on your device, encrypted, and we cannot read it. One optional feature sends a single number, and only if you ask it to."
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
