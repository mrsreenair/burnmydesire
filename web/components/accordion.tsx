"use client";

import { useId, useState, type ReactNode } from "react";

export type QA = { q: string; a: ReactNode };

/**
 * FAQ accordion. The panel animates via `grid-template-rows: 0fr → 1fr`, so the
 * height transition works without measuring anything.
 */
export default function Accordion({
  items,
  defaultOpen = 0,
}: {
  items: QA[];
  defaultOpen?: number | null;
}) {
  const [open, setOpen] = useState<number | null>(defaultOpen);
  const baseId = useId();

  return (
    <div style={{ borderTop: "1px solid var(--hair-soft)" }}>
      {items.map((item, i) => {
        const isOpen = open === i;
        const panelId = `${baseId}-panel-${i}`;
        return (
          <div className="acc-item" key={item.q}>
            <button
              className="acc-trigger"
              aria-expanded={isOpen}
              aria-controls={panelId}
              onClick={() => setOpen(isOpen ? null : i)}
            >
              <span className="display pr-4 text-[21px] leading-[1.25] sm:text-[24px]">
                {item.q}
              </span>
              <span className="acc-sign" aria-hidden>
                <svg width="13" height="13" viewBox="0 0 13 13" fill="none">
                  <path
                    d="M6.5 1v11M1 6.5h11"
                    stroke="currentColor"
                    strokeWidth="1.6"
                    strokeLinecap="round"
                  />
                </svg>
              </span>
            </button>
            <div className="acc-panel" data-open={isOpen} id={panelId} role="region">
              <div>
                <div className="lede max-w-[62ch] pb-7 pr-10 text-[16px]">
                  {item.a}
                </div>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
