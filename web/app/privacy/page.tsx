import type { Metadata } from 'next';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Privacy Policy — Burn My Desire',
  description:
    'Burn My Desire stores everything on your device. No accounts, no cloud, no tracking.',
};

export default function Privacy() {
  return (
    <main className="min-h-screen bg-[#0d0d0f] text-neutral-100">
      <div className="mx-auto max-w-3xl px-6 py-24">
        <Link href="/" className="text-sm text-orange-500 underline">
          ← burnmydesire.com
        </Link>
        <h1 className="mt-6 text-4xl font-black">Privacy Policy</h1>
        <p className="mt-2 text-sm text-neutral-500">
          Last updated: August 8, 2026
        </p>

        <div className="mt-10 space-y-8 leading-relaxed text-neutral-300">
          <section>
            <h2 className="text-xl font-bold text-neutral-100">
              The short version
            </h2>
            <p className="mt-2">
              Burn My Desire has no accounts, no servers, and no analytics.
              Everything you do in the app — photos, prices, burn history —
              is stored only on your device. We never see it.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-neutral-100">
              What the app stores, and where
            </h2>
            <p className="mt-2">
              Photos you capture or pick, item prices, installment details,
              and your burn history are saved in the app&apos;s private
              storage on your phone. This data is included in your device
              backup (iCloud or local) under Apple&apos;s standard mechanisms
              and never transmitted to us or to any third party by the app.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-neutral-100">
              Camera and photo access
            </h2>
            <p className="mt-2">
              The app asks for camera and photo-library permission solely so
              you can add a picture of the thing you crave. Images never leave
              your device.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-neutral-100">Purchases</h2>
            <p className="mt-2">
              Optional Pro purchases are processed by Apple and, for receipt
              validation, RevenueCat. We receive no payment details. See
              Apple&apos;s and RevenueCat&apos;s privacy policies for how they
              handle purchase data.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-neutral-100">
              This website
            </h2>
            <p className="mt-2">
              burnmydesire.com sets no cookies and runs no analytics or
              trackers.
            </p>
          </section>

          <section>
            <h2 className="text-xl font-bold text-neutral-100">Contact</h2>
            <p className="mt-2">
              Questions about privacy:{' '}
              <a
                href="mailto:hello@burnmydesire.com"
                className="text-orange-500 underline"
              >
                hello@burnmydesire.com
              </a>
            </p>
          </section>
        </div>
      </div>
    </main>
  );
}
