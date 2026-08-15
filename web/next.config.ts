import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // The whole site is content we already hold in the repo, so it ships as a
  // folder of HTML. No server to run, no runtime to keep patched.
  output: "export",

  // Static hosting has no image optimizer behind it. Keep the source files
  // small instead — that is the trade, and it is the honest one here.
  images: { unoptimized: true },

  // /about and /about/ should be the same page on a static host rather than
  // one of them 404ing.
  trailingSlash: true,
};

export default nextConfig;
