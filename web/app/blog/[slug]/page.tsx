import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import Reveal from "@/components/reveal";
import { formatDate, getPost, posts, type Block } from "@/lib/posts";

type Params = { params: Promise<{ slug: string }> };

export function generateStaticParams() {
  return posts.map((p) => ({ slug: p.slug }));
}

// The posts are a fixed list in the repo; anything else is a 404 at build time
// rather than a page nobody can render on a static host.
export const dynamicParams = false;

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { slug } = await params;
  const post = getPost(slug);
  if (!post) return {};
  return {
    title: post.title,
    description: post.dek,
    openGraph: {
      title: post.title,
      description: post.dek,
      type: "article",
      publishedTime: post.date,
      images: [post.cover],
    },
  };
}

function renderBlock(block: Block, i: number) {
  switch (block.type) {
    case "h2":
      return (
        <h2 key={i} className="display mt-14 mb-5 text-[clamp(26px,3vw,36px)]">
          {block.text}
        </h2>
      );
    case "quote":
      return (
        <figure key={i} className="my-12">
          <blockquote
            className="display pl-7 text-[clamp(22px,2.6vw,30px)] leading-[1.28]"
            style={{ borderLeft: "3px solid var(--accent)" }}
          >
            <em>{block.text}</em>
          </blockquote>
          {block.cite ? (
            <figcaption className="fine mt-4 pl-7">— {block.cite}</figcaption>
          ) : null}
        </figure>
      );
    case "ul":
      return (
        <ul key={i} className="my-8 flex flex-col gap-4">
          {block.items.map((item) => (
            <li key={item} className="flex items-start gap-4">
              <span
                className="mt-[13px] block h-1.5 w-1.5 shrink-0 rounded-full"
                style={{ background: "var(--accent)" }}
              />
              <span
                className="text-[17.5px] leading-[1.62]"
                style={{ color: "var(--ink-soft)" }}
              >
                {item}
              </span>
            </li>
          ))}
        </ul>
      );
    case "note":
      return (
        <aside
          key={i}
          className="my-10 rounded-[20px] p-7"
          style={{ background: "var(--sticky)", color: "var(--sticky-ink)" }}
        >
          <p className="text-[16px] leading-[1.6] font-[550]">{block.text}</p>
        </aside>
      );
    default:
      return (
        <p
          key={i}
          className="my-6 text-[19px] leading-[1.68]"
          style={{ color: "var(--ink-soft)", fontFamily: "var(--font-newsreader), Georgia, serif" }}
        >
          {block.text}
        </p>
      );
  }
}

export default async function PostPage({ params }: Params) {
  const { slug } = await params;
  const post = getPost(slug);
  if (!post) notFound();

  const more = posts.filter((p) => p.slug !== post.slug).slice(0, 2);

  return (
    <>
      <article>
        <header className="relative overflow-hidden pb-10 pt-14">
          <div
            className="wash wash-peach"
            style={{ width: 520, height: 520, top: -260, right: -200 }}
          />
          <div className="wrap wrap-narrow relative">
            <Reveal>
              <Link href="/blog" className="fine hover:text-[var(--accent)]">
                ← All posts
              </Link>
              <p className="kicker mt-8">
                {post.category} · {post.readingMinutes} min read
              </p>
              <h1 className="display mt-5 text-[clamp(38px,5.4vw,68px)]">
                {post.title}
              </h1>
              <p className="lede mt-6 max-w-[54ch]">{post.dek}</p>
              <p className="fine mt-8">
                {formatDate(post.date)} · {post.author}
              </p>
            </Reveal>
          </div>
        </header>

        <div className="wrap">
          <Reveal variant="tilt-l">
            <Image
              src={post.cover}
              alt=""
              width={1200}
              height={750}
              priority
              className="card w-full object-cover"
              style={{ transform: "none" }}
            />
          </Reveal>
        </div>

        <div className="wrap wrap-narrow pb-8 pt-16">
          <Reveal>{post.body.map(renderBlock)}</Reveal>
        </div>
      </article>

      <section className="section">
        <div className="wrap wrap-narrow">
          <Reveal>
            <div className="ritual px-8 py-14 text-center sm:px-12">
              <div className="ritual-glow" aria-hidden />
              <div className="relative">
                <h2 className="display text-[clamp(26px,3vw,38px)]" style={{ color: "#FFF6EE" }}>
                  Other apps make you wait.
                  <br />
                  <em>We give you closure.</em>
                </h2>
                <div className="mt-8 flex justify-center">
                  <Link href="/#get" className="btn btn-fire">
                     Download on iPhone
                  </Link>
                </div>
              </div>
            </div>
          </Reveal>
        </div>
      </section>

      <section className="section-tight pb-28">
        <div className="wrap">
          <Reveal>
            <p className="kicker kicker-mid">Keep reading</p>
          </Reveal>
          <div className="mt-8 grid gap-7 md:grid-cols-2">
            {more.map((p, i) => (
              <Reveal key={p.slug} delay={i * 110}>
                <Link href={`/blog/${p.slug}`} className="block h-full">
                  <article className="card hover-lift flex h-full gap-5 overflow-hidden p-5">
                    <Image
                      src={p.cover}
                      alt=""
                      width={1200}
                      height={750}
                      className="h-[92px] w-[136px] shrink-0 rounded-[14px] object-cover"
                    />
                    <div>
                      <p className="kicker kicker-mid text-[11px]">{p.category}</p>
                      <h3 className="display mt-2 text-[21px]">{p.title}</h3>
                    </div>
                  </article>
                </Link>
              </Reveal>
            ))}
          </div>
        </div>
      </section>
    </>
  );
}
