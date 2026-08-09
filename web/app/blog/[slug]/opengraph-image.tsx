import { ImageResponse } from "next/og";
import { newsreaderFonts, OG } from "@/lib/og";
import { getPost, posts } from "@/lib/posts";

export const alt = "Burn My Desire";
export const size = OG.size;
export const contentType = OG.contentType;

export function generateStaticParams() {
  return posts.map((p) => ({ slug: p.slug }));
}

export default async function Image({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const post = getPost(slug);
  const title = post?.title ?? "Burn My Desire";
  const meta = post
    ? `${post.category} · ${post.readingMinutes} min read`
    : "burnmydesire.com";

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
          justifyContent: "space-between",
          padding: 88,
          background: OG.paper,
          position: "relative",
        }}
      >
        <div
          style={{
            position: "absolute",
            top: -280,
            right: -200,
            width: 760,
            height: 760,
            borderRadius: 760,
            background: `radial-gradient(circle, ${OG.peach} 0%, rgba(249,228,216,0) 68%)`,
          }}
        />

        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <div
            style={{
              width: 24,
              height: 24,
              borderRadius: 8,
              background: `linear-gradient(135deg, ${OG.ember}, #FF3B2F)`,
            }}
          />
          <div
            style={{
              fontSize: 23,
              letterSpacing: 3,
              textTransform: "uppercase",
              color: OG.mid,
              fontWeight: 700,
            }}
          >
            Burn My Desire
          </div>
        </div>

        <div
          style={{
            fontFamily: serif,
            fontSize: title.length > 34 ? 82 : 100,
            lineHeight: 1.06,
            letterSpacing: -3,
            color: OG.ink,
            maxWidth: 940,
            display: "flex",
          }}
        >
          {title}
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
          <div style={{ width: 46, height: 4, background: OG.accent, borderRadius: 3 }} />
          <div style={{ fontSize: 25, color: OG.mid, textTransform: "uppercase", letterSpacing: 2 }}>
            {meta}
          </div>
        </div>
      </div>
    ),
    { ...size, fonts },
  );
}
