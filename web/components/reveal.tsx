"use client";

import {
  createElement,
  useEffect,
  useRef,
  type CSSProperties,
  type ElementType,
  type ReactNode,
} from "react";

type Variant = "up" | "tilt-l" | "tilt-r" | "pop";

type RevealProps = {
  children: ReactNode;
  /** ms to hold before the element animates — used to stagger siblings */
  delay?: number;
  variant?: Variant;
  as?: ElementType;
  className?: string;
  /** how far into the viewport before it fires, as a bottom margin */
  rootMargin?: string;
};

/**
 * Releases its children when they scroll into view. The animation itself lives
 * in globals.css (`.reveal[data-shown]`), so all this costs is one observer.
 */
export default function Reveal({
  children,
  delay = 0,
  variant = "up",
  as = "div",
  className = "",
  rootMargin = "0px 0px -12% 0px",
}: RevealProps) {
  const ref = useRef<HTMLElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            entry.target.setAttribute("data-shown", "true");
            observer.unobserve(entry.target);
          }
        }
      },
      { rootMargin, threshold: 0.05 },
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [rootMargin]);

  return createElement(
    as,
    {
      ref,
      className: `reveal ${className}`,
      "data-variant": variant,
      style: { "--delay": `${delay}ms` } as CSSProperties,
    },
    children,
  );
}
