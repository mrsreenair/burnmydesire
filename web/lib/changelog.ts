export type ChangeKind = "New" | "Improved" | "Security" | "Fixed";

export type Release = {
  version: string;
  date: string; // ISO
  headline: string;
  changes: { kind: ChangeKind; text: string }[];
};

export const releases: Release[] = [
  {
    version: "0.9.0",
    date: "2026-08-08",
    headline: "The paper runs edge to edge, and the fire has a voice",
    changes: [
      {
        kind: "Improved",
        text: "Every screen now runs the paper to the edges of the display, so cards float on the full sheet instead of inside a margin.",
      },
      {
        kind: "New",
        text: "The burn has sound. A low catch as it takes, a rise as the front crosses the photo, and a settle as it turns to ash — mutable in Settings, and silent when your phone is.",
      },
      {
        kind: "Improved",
        text: "Reveal and pop-in timings retuned across the app so entrances stagger rather than arriving all at once.",
      },
    ],
  },
  {
    version: "0.8.0",
    date: "2026-08-06",
    headline: "Backups that we still can't read",
    changes: [
      {
        kind: "New",
        text: "iCloud backup, on by default. Your history rides along in the encrypted device backup — Apple holds the file, and the key never leaves your Keychain, so nobody at Apple or here can open it.",
      },
      {
        kind: "New",
        text: "Pro encrypted export: write your whole history to a single passphrase-locked file, and restore it on a new phone. Lose the passphrase and the file is genuinely gone — there is no reset link, by design.",
      },
    ],
  },
  {
    version: "0.7.0",
    date: "2026-08-04",
    headline: "Everything sealed at rest",
    changes: [
      {
        kind: "Security",
        text: "The database is now encrypted with SQLCipher, using a key generated on first launch and stored in the iOS Keychain rather than shipped in the app.",
      },
      {
        kind: "Security",
        text: "Photos and written thought pages are written with complete data protection, which makes them unreadable while the phone is locked.",
      },
      {
        kind: "Improved",
        text: "\"Erase everything\" now destroys the encryption key alongside the data, so nothing is recoverable even from a stale backup.",
      },
    ],
  },
  {
    version: "0.6.0",
    date: "2026-07-30",
    headline: "The fire burns along a real front",
    changes: [
      {
        kind: "New",
        text: "The burn ritual moved to a fragment shader: a travelling noise threshold produces a ragged front with a glowing edge, char just ahead of it, and a curl where the sheet buckles into the heat.",
      },
      {
        kind: "Improved",
        text: "Holds at 60fps on hardware several generations back — one full-screen pass, no render targets, and the noise is computed rather than sampled from a texture.",
      },
      {
        kind: "Fixed",
        text: "Letting go mid-burn now cools the front back down smoothly instead of snapping the photo back to full opacity.",
      },
    ],
  },
];

export function formatReleaseDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-GB", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}
