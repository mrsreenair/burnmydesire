import { ImageResponse } from "next/og";
import { newsreaderFonts, OG } from "@/lib/og";

export const alt = "Burn My Desire — other apps make you wait, we give you closure";
export const size = OG.size;
export const contentType = OG.contentType;

const STRUCK = "Sleep on it.";

export default async function Image() {
  const fonts = await newsreaderFonts();
  const serif = "Newsreader";

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          padding: "0 88px",
          background: OG.paper,
          position: "relative",
        }}
      >
        {/* the corner washes, flattened into plain radial gradients */}
        <div
          style={{
            position: "absolute",
            top: -260,
            right: -180,
            width: 760,
            height: 760,
            borderRadius: 760,
            background: `radial-gradient(circle, ${OG.peach} 0%, rgba(249,228,216,0) 68%)`,
          }}
        />
        <div
          style={{
            position: "absolute",
            bottom: -320,
            left: -220,
            width: 700,
            height: 700,
            borderRadius: 700,
            background: `radial-gradient(circle, ${OG.mint} 0%, rgba(220,239,226,0) 68%)`,
          }}
        />

        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <div
            style={{
              width: 26,
              height: 26,
              borderRadius: 9,
              background: `linear-gradient(135deg, ${OG.ember}, #FF3B2F)`,
            }}
          />
          <div
            style={{
              fontSize: 25,
              letterSpacing: 3,
              textTransform: "uppercase",
              color: OG.mid,
              fontWeight: 700,
            }}
          >
            Burn My Desire
          </div>
        </div>

        {/* the struck line, with the orange rule drawn over it */}
        <div style={{ display: "flex", position: "relative", marginTop: 44 }}>
          <div
            style={{
              fontFamily: serif,
              fontSize: 108,
              lineHeight: 1.05,
              letterSpacing: -3,
              color: OG.low,
            }}
          >
            {STRUCK}
          </div>
          <div
            style={{
              position: "absolute",
              left: -8,
              top: 54,
              width: 545,
              height: 7,
              borderRadius: 4,
              background: OG.accent,
              transform: "rotate(-1.1deg)",
            }}
          />
        </div>

        <div
          style={{
            fontFamily: serif,
            fontSize: 108,
            lineHeight: 1.05,
            letterSpacing: -3,
            color: OG.ink,
            display: "flex",
          }}
        >
          <span style={{ fontStyle: "italic" }}>Burn it</span>
          <span>&nbsp;instead.</span>
        </div>

        <div
          style={{
            marginTop: 56,
            fontSize: 27,
            color: OG.mid,
            display: "flex",
          }}
        >
          burnmydesire.com · No account. Nothing leaves your phone.
        </div>
      </div>
    ),
    { ...size, fonts },
  );
}
