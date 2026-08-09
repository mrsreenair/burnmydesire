import type { ReactNode } from "react";
import Reveal from "@/components/reveal";

export default function PageHero({
  kicker,
  title,
  lede,
  children,
}: {
  kicker: string;
  title: ReactNode;
  lede?: ReactNode;
  children?: ReactNode;
}) {
  return (
    <section className="relative overflow-hidden pb-14 pt-14 sm:pb-20 sm:pt-20">
      <div
        className="wash wash-mint"
        style={{ width: 480, height: 480, top: -260, left: -200 }}
      />
      <div
        className="wash wash-peach wash-delay"
        style={{ width: 520, height: 520, top: -220, right: -220 }}
      />
      <div className="wrap relative">
        <Reveal>
          <p className="kicker">{kicker}</p>
          <h1 className="display mt-5 max-w-[16ch] text-[clamp(40px,6vw,78px)]">
            {title}
          </h1>
          {lede ? <p className="lede mt-7 max-w-[56ch]">{lede}</p> : null}
          {children}
        </Reveal>
      </div>
    </section>
  );
}
