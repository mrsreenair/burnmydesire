import Link from "next/link";

export default function NotFound() {
  return (
    <section className="relative overflow-hidden py-32 text-center">
      <div
        className="wash wash-peach"
        style={{ width: 560, height: 560, top: -180, left: "50%", marginLeft: -280 }}
      />
      <div className="wrap relative">
        <p className="kicker">404</p>
        <h1 className="display mx-auto mt-5 max-w-[16ch] text-[clamp(40px,6vw,78px)]">
          This page has already <em>burned</em>.
        </h1>
        <p className="lede mx-auto mt-6 max-w-[42ch]">
          Nothing left of it, which is at least on brand. Everything else is
          still standing.
        </p>
        <div className="mt-10 flex flex-wrap justify-center gap-3">
          <Link href="/" className="btn btn-dark">
            Back to the start
          </Link>
          <Link href="/blog" className="btn btn-ghost">
            Read something instead
          </Link>
        </div>
      </div>
    </section>
  );
}
