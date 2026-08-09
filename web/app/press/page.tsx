import type { Metadata } from "next";
import Image from "next/image";
import PageHero from "@/components/page-hero";
import Reveal from "@/components/reveal";

export const metadata: Metadata = {
  title: "Press kit",
  description:
    "Boilerplate, facts, screenshots and colours for writing about Burn My Desire.",
};

const FACTS = [
  ["Name", "Burn My Desire"],
  ["Category", "Health & fitness / Finance"],
  ["Platform", "iPhone, iOS 17+ (Android later)"],
  ["Price", "Free to start, paid tier at launch"],
  ["Accounts", "None — no login, no server, no sync"],
  ["Positioning", "Other apps make you wait. We give you closure."],
];

const SWATCHES = [
  ["Paper", "#F7F4EE"],
  ["Ink", "#161513"],
  ["Ember", "#FF7A18"],
  ["Flame", "#FF3B2F"],
  ["Spark", "#FFC46B"],
  ["Money", "#17A567"],
  ["Night", "#0A0709"],
];

const SHOTS = [
  { src: "/screens/home.png", label: "Home — wealth kept" },
  { src: "/screens/shock.png", label: "Shock — the compound cost" },
  { src: "/screens/burn.png", label: "Burn — the ritual" },
];

export default function Press() {
  return (
    <>
      <PageHero
        kicker="Press kit"
        title={
          <>
            Everything you need to <em>write about us</em>.
          </>
        }
        lede="Take any of it without asking. If you need something that isn't here — a founder quote, a specific screen, a build to test — mail press@burnmydesire.com and you'll get it the same day."
      />

      <section className="pb-4">
        <div className="wrap grid gap-14 lg:grid-cols-[1fr_1fr]">
          <Reveal>
            <h2 className="display text-[28px]">The one-paragraph version</h2>
            <div className="prose-serif mt-5">
              <p>
                Burn My Desire is an iPhone app that breaks the impulse loop in
                two punches. It prices a temptation in twenty-year money — what
                €429 becomes if it stays invested until you are 65 — and then
                lets you photograph the thing and set it on fire with your thumb,
                using a GPU shader that burns along a real front at 60fps. It
                has no accounts, no cloud and no backend: everything stays
                encrypted on the device.
              </p>
            </div>
          </Reveal>

          <Reveal delay={120}>
            <h2 className="display text-[28px]">Fast facts</h2>
            <dl className="mt-5" style={{ borderTop: "1px solid var(--hair)" }}>
              {FACTS.map(([k, v]) => (
                <div
                  key={k}
                  className="flex flex-wrap gap-4 py-4"
                  style={{ borderBottom: "1px solid var(--hair-soft)" }}
                >
                  <dt className="kicker kicker-mid w-[110px] shrink-0 pt-1">{k}</dt>
                  <dd className="flex-1 text-[15.5px]" style={{ color: "var(--ink-soft)" }}>
                    {v}
                  </dd>
                </div>
              ))}
            </dl>
          </Reveal>
        </div>
      </section>

      <section className="section">
        <div className="wrap">
          <Reveal>
            <h2 className="display text-[28px]">Screenshots</h2>
            <p className="lede mt-3 text-[15.5px]">
              Right-click to save. Usable at any size, unedited or cropped.
            </p>
          </Reveal>
          <div className="mt-10 grid gap-8 sm:grid-cols-3">
            {SHOTS.map((s, i) => (
              <Reveal key={s.src} delay={i * 110} variant={i === 1 ? "tilt-r" : "tilt-l"}>
                <div>
                  <div className="phone" style={{ transform: "none" }}>
                    <Image
                      src={s.src}
                      alt={s.label}
                      width={1206}
                      height={2622}
                      sizes="(max-width: 640px) 80vw, 300px"
                    />
                  </div>
                  <p className="fine mt-4">{s.label}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      <section className="section-tight pb-28">
        <div className="wrap">
          <Reveal>
            <h2 className="display text-[28px]">Colours</h2>
            <p className="lede mt-3 max-w-[54ch] text-[15.5px]">
              Orange is fire and primary action only. Green means money you
              kept, and is never a button. The night colour appears on exactly
              one screen.
            </p>
          </Reveal>
          <div className="mt-10 grid grid-cols-2 gap-5 sm:grid-cols-4 lg:grid-cols-7">
            {SWATCHES.map(([name, hex], i) => (
              <Reveal key={hex} delay={i * 60} variant="pop">
                <div>
                  <div
                    className="h-24 rounded-[18px]"
                    style={{
                      background: hex,
                      boxShadow: "inset 0 0 0 1px rgba(22,21,19,.09)",
                    }}
                  />
                  <p className="mt-3 text-[14px] font-[650]">{name}</p>
                  <p className="fine font-mono">{hex}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>
    </>
  );
}
