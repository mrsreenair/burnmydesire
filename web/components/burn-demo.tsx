"use client";

import Image from "next/image";
import { useCallback, useEffect, useRef, useState } from "react";
import type { CSSProperties } from "react";

const HOLD_MS = 2200; // how long a full burn takes
const COOL_MS = 900; // how fast it retreats when you let go

const EMBERS = [
  { left: "12%", delay: "0s", drift: "34px", size: 3, dur: "3.6s" },
  { left: "27%", delay: "0.7s", drift: "-22px", size: 4, dur: "4.4s" },
  { left: "41%", delay: "1.5s", drift: "18px", size: 2, dur: "3.1s" },
  { left: "56%", delay: "0.3s", drift: "-30px", size: 3, dur: "4.9s" },
  { left: "68%", delay: "2.1s", drift: "26px", size: 4, dur: "3.8s" },
  { left: "83%", delay: "1.1s", drift: "-16px", size: 2, dur: "4.2s" },
];

/**
 * Press and hold to burn the screenshot away. This is the one piece of the app
 * that can't be explained in a paragraph, so the site lets you do it.
 */
export default function BurnDemo() {
  const [burn, setBurn] = useState(0);
  const [holding, setHolding] = useState(false);
  const [done, setDone] = useState(false);

  const frame = useRef(0);
  const last = useRef<number | null>(null);
  const holdingRef = useRef(false);
  const burnRef = useRef(0);

  const tick = useCallback((now: number) => {
    if (last.current === null) last.current = now;
    const dt = now - last.current;
    last.current = now;

    const rate = holdingRef.current ? dt / HOLD_MS : -dt / COOL_MS;
    const next = Math.max(0, Math.min(100, burnRef.current + rate * 100));
    burnRef.current = next;
    setBurn(next);

    if (next >= 100) {
      setDone(true);
      holdingRef.current = false;
      setHolding(false);
      return;
    }
    if (next <= 0 && !holdingRef.current) {
      last.current = null;
      return;
    }
    frame.current = requestAnimationFrame(tick);
  }, []);

  const start = useCallback(() => {
    if (done) return;
    holdingRef.current = true;
    setHolding(true);
    last.current = null;
    cancelAnimationFrame(frame.current);
    frame.current = requestAnimationFrame(tick);
  }, [done, tick]);

  const stop = useCallback(() => {
    if (!holdingRef.current) return;
    holdingRef.current = false;
    setHolding(false);
    cancelAnimationFrame(frame.current);
    last.current = null;
    frame.current = requestAnimationFrame(tick);
  }, [tick]);

  const reset = useCallback(() => {
    cancelAnimationFrame(frame.current);
    burnRef.current = 0;
    last.current = null;
    holdingRef.current = false;
    setBurn(0);
    setHolding(false);
    setDone(false);
  }, []);

  // Holding a key down is a poor gesture, so keyboard users get the whole burn
  // in one press instead of having to keep the key pressed.
  const onKeyDown = (e: React.KeyboardEvent) => {
    if (e.key !== "Enter" && e.key !== " ") return;
    e.preventDefault();
    if (done) return;
    const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduced) {
      burnRef.current = 100;
      setBurn(100);
      setDone(true);
      return;
    }
    start();
    window.setTimeout(stop, HOLD_MS + 120);
  };

  useEffect(() => () => cancelAnimationFrame(frame.current), []);

  const stageStyle = {
    "--burn": burn,
    "--edge-on": burn > 0.5 ? 1 : 0,
  } as CSSProperties;

  return (
    <div className="burn-stage w-full" style={stageStyle}>
      <div className="relative w-full max-w-[290px]">
        <div className="burn-halo" aria-hidden />

        {/* embers only drift once something is actually alight */}
        <div
          className="pointer-events-none absolute inset-x-0 bottom-0 h-full"
          style={{ opacity: burn > 4 ? 1 : 0, transition: "opacity .4s ease" }}
          aria-hidden
        >
          {EMBERS.map((e, i) => (
            <span
              key={i}
              className="ember"
              style={
                {
                  left: e.left,
                  bottom: `${Math.min(burn, 90)}%`,
                  width: e.size,
                  height: e.size,
                  animationDelay: e.delay,
                  animationDuration: e.dur,
                  "--drift": e.drift,
                } as CSSProperties
              }
            />
          ))}
        </div>

        <div className="phone phone-dark">
          <div className="burn-paper">
            <Image
              src="/screens/burn.png"
              alt="The burn screen: a photographed purchase, ready to be set on fire"
              width={1206}
              height={2622}
              className="h-auto w-full"
              priority={false}
            />
            <div className="burn-char" aria-hidden />
          </div>
          <div className="burn-edge" aria-hidden />
        </div>

        {/* what's left once the paper is gone */}
        <div
          className="burn-done pointer-events-none absolute inset-0 flex flex-col items-center justify-center px-6"
          style={{
            opacity: done ? 1 : 0,
            transform: done ? "scale(1)" : "scale(.92)",
            transition: "opacity .5s ease .15s, transform .6s cubic-bezier(.2,.9,.3,1.2) .15s",
          }}
          aria-hidden={!done}
        >
          <p className="kicker" style={{ color: "var(--spark)" }}>
            Gone
          </p>
          <p
            className="display money-text mt-3"
            style={{ fontSize: 54, lineHeight: 1 }}
          >
            €4,180
          </p>
          <p className="mt-3 text-[14px] text-white/60">kept, and compounding</p>
        </div>
      </div>

      <div className="mt-9 flex flex-col items-center gap-4">
        {done ? (
          <button className="btn btn-ghost !border-white/25 !bg-white/5 !text-white" onClick={reset}>
            Burn another
          </button>
        ) : (
          <button
            className="burn-hold"
            onPointerDown={start}
            onPointerUp={stop}
            onPointerLeave={stop}
            onPointerCancel={stop}
            onKeyDown={onKeyDown}
            aria-label="Press and hold to burn the screenshot"
          >
            <span>{holding ? "Keep holding…" : "Hold to burn"}</span>
          </button>
        )}
        <p className="text-[13px] text-white/40">
          {done
            ? "That's the whole product."
            : "Press and hold, the way you would in the app."}
        </p>
      </div>
    </div>
  );
}
