export type Block =
  | { type: "p"; text: string }
  | { type: "h2"; text: string }
  | { type: "quote"; text: string; cite?: string }
  | { type: "ul"; items: string[] }
  | { type: "note"; text: string };

export type Post = {
  slug: string;
  title: string;
  dek: string;
  category: "Psychology" | "Money" | "Craft" | "Privacy";
  date: string; // ISO
  readingMinutes: number;
  cover: string; // /art/*.svg
  author: string;
  body: Block[];
};

export const posts: Post[] = [
  {
    slug: "waiting-is-not-a-feature",
    title: "Waiting is not a feature",
    dek: "Every pause-before-you-buy app asks for the exact discipline the craving just took from you. Here's what we built instead.",
    category: "Psychology",
    date: "2026-07-28",
    readingMinutes: 6,
    cover: "/art/cover-waiting.svg",
    author: "The Burn My Desire team",
    body: [
      {
        type: "p",
        text: "Open the App Store and search for impulse spending. You will find a dozen apps with the same shape: you add the thing you want, a timer starts, and in twenty-four or seventy-two hours the app asks whether you still want it. The pitch is always some version of sleep on it.",
      },
      {
        type: "p",
        text: "It is good advice. It is also, for the person actually in the grip of an urge, close to useless — because the whole problem is that the part of you making the decision does not want to wait, and the timer has no way to make it.",
      },
      { type: "h2", text: "The urge is not asking a question" },
      {
        type: "p",
        text: "Impulse buying is a dopamine loop, not a maths error. The spike arrives before the purchase, on the anticipation, and it wants to be resolved. A cooldown timer does not resolve it. It parks it. And a parked urge does not sit still for three days — it comes back at eleven at night with a browser tab already open.",
      },
      {
        type: "quote",
        text: "I closed the tab. Then I opened it again eleven minutes later.",
        cite: "the sentence we heard, in some form, in nearly every beta interview",
      },
      {
        type: "p",
        text: "This is the thing every waiting app quietly relies on you to do by yourself: sit with an unresolved craving and outlast it. If you could reliably do that, you would not have downloaded the app.",
      },
      { type: "h2", text: "Two punches instead of one pause" },
      {
        type: "p",
        text: "Burn My Desire answers the urge twice, in the order that actually works.",
      },
      {
        type: "ul",
        items: [
          "The rational shock. Not the €429 on the price tag — the €4,180 that €429 becomes if it stays invested until you are 65. The number is uncomfortable in a way the sticker price never is, because it is denominated in something you actually care about.",
          "The emotional burn. You photograph the thing and set it on fire with your thumb. It curls, it glows at the edge, and then it is gone. The craving gets an ending rather than a deferral.",
        ],
      },
      {
        type: "p",
        text: "Destruction as closure is not a novelty we invented. People tear up photographs, delete the number, throw out the box. The ritual finishes something that the reasoning could not. We just gave the ritual sixty frames a second and attached it to your money.",
      },
      { type: "h2", text: "What we saw in the closed beta" },
      {
        type: "p",
        text: "This is a small, self-selected group and not a study, so treat it as a signal rather than a finding: most logged desires were never bought, and the ones that were had usually been logged more than once first.",
      },
      {
        type: "p",
        text: "That second half is the part that surprised us. Resistance was rarely a single heroic act of willpower. It was the same craving showing up four times and being burned four times.",
      },
      {
        type: "note",
        text: "That is why re-burning the same desire is a supported action rather than a failure state. Coming back means the loop is still live, and the app should be there when it is.",
      },
      {
        type: "p",
        text: "Waiting asks you to be a different person for three days. Burning asks you for forty seconds, tonight, as the person you already are.",
      },
    ],
  },
  {
    slug: "what-friday-drinks-actually-cost",
    title: "What €40 of Friday drinks actually costs",
    dek: "One-off purchases compound. Habits compound harder — and almost nobody prices them that way.",
    category: "Money",
    date: "2026-07-14",
    readingMinutes: 5,
    cover: "/art/cover-compound.svg",
    author: "The Burn My Desire team",
    body: [
      {
        type: "p",
        text: "Ask someone what their Friday night costs and they will say forty euros. It is the correct answer to the wrong question, and it is the reason habit spending survives every budget anyone has ever written.",
      },
      { type: "h2", text: "The arithmetic nobody runs" },
      {
        type: "p",
        text: "€40 a week is €2,080 a year. Invested at a 7% real return and left alone for twenty years, those contributions become roughly €95,000. Not because any single Friday was expensive, but because you did it a thousand times and the compounding did the rest.",
      },
      {
        type: "ul",
        items: [
          "€429 headphones, once, 24 years to retirement: about €4,180.",
          "€6 lunchtime coffee, five days a week, 20 years: about €71,000.",
          "€40 of drinks every weekend, 20 years: about €95,000.",
          "€90 a month of subscriptions you forgot about, 20 years: about €49,000.",
        ],
      },
      {
        type: "p",
        text: "Look at that list again. The single most expensive line is the cheapest individual purchase. That inversion is the entire argument for pricing habits rather than items.",
      },
      { type: "h2", text: "Why the big number works" },
      {
        type: "p",
        text: "There is a reasonable objection here: doesn't a €95,000 figure just produce guilt, and isn't guilt a famously bad motivator? It would be, if the number arrived as a verdict at the end of the month. Ours arrives at the exact moment of temptation, attached to one specific decision you are about to make, and it comes with something to do about it.",
      },
      {
        type: "quote",
        text: "The number is not there to shame you about last year. It is there to price the next forty seconds.",
      },
      { type: "h2", text: "The assumptions, stated plainly" },
      {
        type: "p",
        text: "Every figure in the app uses a 7% annual return, which is roughly the long-run real return of a broad global equity index after inflation. It is an assumption, not a promise, and you can change it in Settings — set it to 4% if you would rather be conservative. We show you the rate we used on the card itself, because a shock number you cannot audit is just a scare.",
      },
      {
        type: "note",
        text: "Burn My Desire is not investment advice and does not sell, recommend, or connect to any financial product. It does arithmetic on a number you typed in.",
      },
    ],
  },
  {
    slug: "burning-along-a-real-front",
    title: "Burning paper along a real front",
    dek: "How the fire got its glowing edge, and why we threw away three easier versions first.",
    category: "Craft",
    date: "2026-06-30",
    readingMinutes: 7,
    cover: "/art/cover-fire.svg",
    author: "The Burn My Desire team",
    body: [
      {
        type: "p",
        text: "The burn is the product. If it looks like a dissolve transition, the whole emotional argument collapses — you have not destroyed anything, you have faded a photo out. So we spent an unreasonable amount of time on about two seconds of animation.",
      },
      { type: "h2", text: "Three versions that did not work" },
      {
        type: "ul",
        items: [
          "A cross-fade to black. Reads as a loading state. Nobody felt anything.",
          "A particle burst. Looks like a game reward, which is exactly the wrong emotional register for a decision about drinking.",
          "A noise-threshold dissolve. Closer, but the paper vanished uniformly across the whole image at once, and real fire does not do that.",
        ],
      },
      {
        type: "p",
        text: "What all three missed is that fire has a front. It starts somewhere, it travels, and everything interesting happens in the few millimetres at the leading edge — the glow, the char, the curl. Burning is a moving boundary, not a global fade.",
      },
      { type: "h2", text: "The shader" },
      {
        type: "p",
        text: "The final version runs as a fragment shader. A fractal noise field is sampled per pixel and compared against a travelling threshold; where the noise falls below the threshold the pixel is gone. Because the threshold sweeps across the image rather than lifting everywhere at once, the boundary is a ragged line that moves — the front.",
      },
      {
        type: "p",
        text: "Then the interesting part: the same distance-to-threshold value drives three more effects layered on the boundary. Just past it, the paper darkens to char. On it, the pixel is pushed into the ember gradient and lit well past white. Just behind it, a subtle displacement curls the edge as if the sheet is buckling into the heat.",
      },
      {
        type: "quote",
        text: "One value — how far this pixel is from being consumed — draws the glow, the char and the curl. Everything else is tuning.",
      },
      { type: "h2", text: "Holding sixty frames a second" },
      {
        type: "p",
        text: "It runs on the GPU with a single full-screen pass and no render targets, which is what keeps it at 60fps on hardware going back several generations. The noise is computed rather than sampled from a texture, so there is nothing to load and nothing to ship in the bundle.",
      },
      {
        type: "note",
        text: "The burn screen is the only dark screen in the entire app. The room goes out, the fire is the only light source, and when it is over you come back to daylight. That contrast is doing as much work as the shader.",
      },
    ],
  },
  {
    slug: "an-app-with-no-login",
    title: "An app about shame should not have a login",
    dek: "No accounts, no cloud, no backend. Not as a feature — as the only defensible way to build this.",
    category: "Privacy",
    date: "2026-06-12",
    readingMinutes: 4,
    cover: "/art/cover-privacy.svg",
    author: "The Burn My Desire team",
    body: [
      {
        type: "p",
        text: "Burn My Desire has no sign-up screen. There is no email field, no password, no social login, no sync, and no account to delete. This was decided early and it is not going to change.",
      },
      { type: "h2", text: "What people actually log" },
      {
        type: "p",
        text: "The wedge is impulse purchases, so the obvious mental image is a pair of headphones. But once you give people a place to put a craving, they put the real ones there: the drinking, the smoking, the 1am scroll, the ex whose profile they keep opening.",
      },
      {
        type: "p",
        text: "A database of that, tied to an email address, is a liability no amount of encryption-in-transit makes acceptable. The safest possible version of that database is the one that never leaves the phone.",
      },
      { type: "h2", text: "What that means concretely" },
      {
        type: "ul",
        items: [
          "The database is SQLCipher-encrypted, with the key stored in the iOS Keychain rather than in the app bundle.",
          "Photos and written thoughts are written with complete data protection, so they are unreadable while the phone is locked.",
          "There is no analytics SDK, no crash reporter that ships content, and no network call that carries anything you typed.",
          "Erase everything genuinely destroys the database, the images, the preferences and the key. There is no copy elsewhere, because there was never a copy elsewhere.",
        ],
      },
      {
        type: "quote",
        text: "There is nothing an account could unlock, because there is no server for it to unlock.",
      },
      { type: "h2", text: "The trade we are making" },
      {
        type: "p",
        text: "This costs us things. No cross-device sync. No web dashboard. No recovering your history if you lose the phone without a backup. Growth loops that depend on knowing who you are do not exist for us.",
      },
      {
        type: "p",
        text: "We think that is the correct trade for an app people use at their least composed moments. If the promise is that your temptations never leave your phone, it has to be architecturally true, not a paragraph in a policy.",
      },
    ],
  },
];

export function getPost(slug: string) {
  return posts.find((p) => p.slug === slug);
}

export function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-GB", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}
