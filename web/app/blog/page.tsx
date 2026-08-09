import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import PageHero from "@/components/page-hero";
import Reveal from "@/components/reveal";
import { formatDate, posts } from "@/lib/posts";

export const metadata: Metadata = {
  title: "Blog",
  description:
    "Notes on impulse psychology, compound arithmetic, fire shaders, and building an app with no server.",
};

export default function Blog() {
  const [featured, ...rest] = posts;

  return (
    <>
      <PageHero
        kicker="Writing"
        title={
          <>
            Notes from the <em>workshop</em>.
          </>
        }
        lede="Why waiting fails, what habits really cost, how the fire is drawn, and why there is no login. Roughly monthly, never a newsletter you have to escape."
      />

      {/* featured */}
      <section className="pb-6">
        <div className="wrap">
          <Reveal variant="tilt-l">
            <Link href={`/blog/${featured.slug}`} className="block">
              <article
                className="card hover-lift grid overflow-hidden md:grid-cols-2"
                style={{ transform: "none" }}
              >
                <Image
                  src={featured.cover}
                  alt=""
                  width={1200}
                  height={750}
                  priority
                  className="h-full w-full object-cover"
                  style={{ minHeight: 260 }}
                />
                <div className="flex flex-col justify-center p-9 sm:p-12">
                  <p className="kicker">
                    Latest · {featured.category} · {featured.readingMinutes} min
                  </p>
                  <h2 className="display mt-4 text-[clamp(28px,3.4vw,42px)]">
                    {featured.title}
                  </h2>
                  <p className="lede mt-4 text-[16.5px]">{featured.dek}</p>
                  <p className="fine mt-6">{formatDate(featured.date)}</p>
                </div>
              </article>
            </Link>
          </Reveal>
        </div>
      </section>

      {/* the rest */}
      <section className="section-tight">
        <div className="wrap">
          <div className="grid gap-7 md:grid-cols-3">
            {rest.map((post, i) => (
              <Reveal key={post.slug} delay={i * 110}>
                <Link href={`/blog/${post.slug}`} className="block h-full">
                  <article className="card hover-lift flex h-full flex-col overflow-hidden">
                    <Image
                      src={post.cover}
                      alt=""
                      width={1200}
                      height={750}
                      className="aspect-[8/5] w-full object-cover"
                    />
                    <div className="flex flex-1 flex-col p-6">
                      <p className="kicker kicker-mid">
                        {post.category} · {post.readingMinutes} min
                      </p>
                      <h3 className="display mt-3 text-[24px]">{post.title}</h3>
                      <p className="lede mt-3 text-[15px]">{post.dek}</p>
                      <p className="fine mt-auto pt-6">{formatDate(post.date)}</p>
                    </div>
                  </article>
                </Link>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      <section className="section-tight pb-28">
        <div className="wrap wrap-narrow">
          <Reveal>
            <div
              className="card flex flex-wrap items-center justify-between gap-6 p-9"
              style={{ transform: "none" }}
            >
              <div>
                <h2 className="display text-[26px]">Want the next one?</h2>
                <p className="lede mt-2 text-[15.5px]">
                  We&apos;ll mail you when something new goes up. Nothing else,
                  ever.
                </p>
              </div>
              <Link href="/contact" className="btn btn-dark">
                Get notified
              </Link>
            </div>
          </Reveal>
        </div>
      </section>
    </>
  );
}
