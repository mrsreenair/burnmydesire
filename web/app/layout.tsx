import type { Metadata } from "next";
import { Inter, Newsreader } from "next/font/google";
import "./globals.css";
import SiteNav from "@/components/site-nav";
import SiteFooter from "@/components/site-footer";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

// Newsreader stands in for Iowan Old Style: an old-style serif with a real
// italic, which the headline treatment ("Burn it instead.") leans on.
const newsreader = Newsreader({
  variable: "--font-newsreader",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600"],
  style: ["normal", "italic"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://burnmydesire.com"),
  title: {
    default: "Burn My Desire — other apps make you wait, we give you closure",
    template: "%s · Burn My Desire",
  },
  description:
    "Impulse buying is a dopamine loop, not a maths problem. See what the money becomes in twenty years, then burn the thing to ash. No account, no cloud, nothing leaves your phone.",
  openGraph: {
    title: "Burn My Desire",
    description:
      "Other apps make you wait. We give you closure. An iPhone app that prices the craving in twenty-year money, then lets you burn it.",
    url: "https://burnmydesire.com",
    siteName: "Burn My Desire",
    type: "website",
  },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${inter.variable} ${newsreader.variable} h-full`}
    >
      <head>
        {/* Without JS the scroll-reveal never fires, so pin everything visible. */}
        <noscript>
          <style>{`.reveal,.enter,.enter-pop{opacity:1!important;animation:none!important}`}</style>
        </noscript>
      </head>
      <body className="min-h-full flex flex-col">
        <SiteNav />
        <main className="flex-1">{children}</main>
        <SiteFooter />
      </body>
    </html>
  );
}
