# Burn My Desire — Master Project Document

**Version:** 1.1 · **Date:** 2026-08-08
**Working title:** Burn My Desire (formerly BurnRate)
**Platforms:** iOS first (Flutter), Android later, Next.js web, browser extensions later
**Purpose:** Single source of truth for all product, technical, and business decisions. Every development phase references this document.

---

## 1. Vision & Problem

Impulse buying is a dopamine-driven psychological behavior, not a lack of mathematical awareness. People buy gadgets, clothes, and tools on impulse or installments without seeing the long-term wealth destruction. Traditional budgeting apps fail because they answer an emotional urge with static charts. Existing "pause before you buy" apps ask users to *wait* — but waiting requires the discipline the impulse buyer doesn't have.

**Burn My Desire** breaks the impulse loop with a two-punch mechanic:

1. **The Rational Shock** — instantly shows the compound-interest opportunity cost: what this money becomes in 10/20/30 years if invested instead.
2. **The Emotional Burn** — the user interactively burns the photo of the item with a 60fps GPU shader, giving psychological *closure now* instead of asking for patience.

**Positioning line:** *Other apps make you wait. We give you closure.*

### The bigger vision: burn ANY desire, not only purchases

Impulse buying is the wedge, not the ceiling. The same craving→shock→burn ritual applies to **any temptation**: the urge to drink, smoke, order junk food, or any recurring habit the user wants to break. The app is ultimately about **burning emotions and cravings**, with impulse purchases as the first, most monetizable category.

Crucially, the money mechanic survives the broadening — habits are *recurring* costs, which compound even harder than one-time purchases: *"€40 of drinks every weekend = €2,080/yr → ~€95,000 of 20-year wealth."* Emotional desires with no price tag still get the burn ritual and resistance tracking, just without the shock card.

**Scope discipline:** v1 ships purchase-focused (Phases 0–3). The broader temptation system is designed into the data model from day one (see §4.4 and §6) and ships as v2 — it must not delay v1.

---

## 2. Market Research (as of Aug 2026)

### Existing competitors

| App | Mechanic | Gap vs. us |
|---|---|---|
| Euna | Guided reflection, 24h pause, streaks | No emotional payoff, no investment framing |
| CartPause | Share item → wait 72h → decide (claims 3/4 skipped) | Proves share-sheet entry works; still a waiting app |
| CoolDown / Wait Before You Buy / paus / PauseBuy | Cooldown timers, reminders | Same waiting pattern |
| Onus: True Cost | Real cost incl. debt interest | Rational only, no ritual |
| Skip or Buy | Cost-per-use calculator | Rational only |
| Compound calculators (many) | Generic future-value math | Not tied to a purchase moment |

### Conclusions

- **Demand validated**: the niche is real and people pay for these apps. Most launched within the last ~18 months → the space is heating up; **speed matters**.
- **Differentiation confirmed**: no app combines invested-value shock with a destruction ritual. Burn/dissolve shaders exist only in game-dev tooling. The burn is ours.
- **CartPause validates the share-extension entry point** for the post-v1 roadmap.

---

## 3. Brand & Domains

- **Name:** Burn My Desire. Avoids the "burn rate" (startup finance) SEO collision. Memorable, self-describing — and deliberately broader than shopping: "desire" covers drinking, smoking, junk food, and every future temptation category, which shopping-bound alternatives (WishBurn, BurnMyCart) would not. This is why the name was chosen despite its mild romantic connotation.
- **Domains verified available (2026-08-08):** burnmydesire.com / .app / .io / .co / .net / .org
- **To register (user action):**
  - `burnmydesire.com` — primary brand, landing page
  - `burnmydesire.app` — app deep links / mobile landing (.app enforces HTTPS)
  - Skip the rest; renew-cost squatting insurance isn't worth it pre-revenue.
- **Registrar:** Cloudflare Registrar (at-cost, ~$10/yr .com) or Porkbun (near-cost, includes WHOIS privacy). Avoid GoDaddy (cheap year 1, expensive renewals).
- **App Store:** create the app record in App Store Connect early to reserve the name "Burn My Desire".

---

## 4. Product Specification

### 4.1 Core loop

```
Urge hits → open app (or share item into it)
  → photo of item (camera / gallery / shared image)
  → enter price (+ optional installment terms)
  → SHOCK CARD: one bold number (future value lost)
  → press-and-hold / drag to BURN the image (GPU shader)
  → VICTORY: "€800 protected" + running wealth-protected total
  → item saved with resistance count; burn again when the urge returns
```

### 4.2 Features

**F1 — Frictionless capture**
- `image_picker` for camera/gallery. Image cached locally only. Zero uploads, ever.

**F2 — Opportunity-cost calculator (reworked 2026-08-08: real market data)**
- **Founder decision:** no made-up rates. Forward projection from real history — *"invested today instead, this €800 could be €6,301 by 2046 in the S&P 500 — real 33-year average: 10.9%/yr."* Target year shown explicitly; horizon is a 1–30 year slider (default 20).
- Nine assets at launch (founder decision 2026-08-08): index ETFs S&P 500 (SPY), NASDAQ-100 (QQQ), MSCI World (IWDA.AS) first/default, plus single stocks Apple, Microsoft, Google, Amazon, Nvidia, Tesla. Rate used = each asset's full-history realized CAGR (dividends included), disclosed in the card ("real 22-year average: 23.8%/yr"). Known caveat: hyper-growth single stocks produce heroic 30-year numbers (survivorship bias) — kept per founder preference, revisit after user feedback.
- Data: monthly adjusted closes bundled as an asset (~23 KB), refreshed silently from Yahoo Finance's chart endpoint when >30 days old; offline always works.
- Fallback when data can't load: `A = P(1 + r)^t` with r = 8%.
- **Installment mode:** given monthly payment, term, and (optional) interest rate, show total paid + foregone growth: *"€70/mo × 12 = €840 paid for an €800 printer, plus €3,728 foregone — this printer really costs you €4,500."*
- **Shock card rule: ONE bold number.** The user is mid-craving; no lectures. Educational detail lives behind a tap.
- Disclaimer on every projection: *"Based on historical market averages. Not a guarantee or investment advice."*

**F3 — Interactive GLSL burn**
- Custom fragment shader (simplex noise dissolve, glowing orange/red edges → ash).
- Press-and-hold or drag drives the burn progress uniform 0.0 → 1.0.
- **Destruction effect library (shipped, Pro up-sell):** three effects behind one contract — every shader takes the same uniforms (size, progress, time, paper rect, texture) and `BurnableImage` just swaps the asset, so the ritual (hold, haptics, sound, completion) never changes. Free: **Fire**. Pro: **Ash** (no flame — the page cools, greys and crumbles into drifting motes) and **Cold flame** (gas-blue; bleaches the page instead of charring it). Each effect also carries the colour of the light it throws into the room, because an orange glow over a grey crumble would defeat the point of a flameless option. Chosen in Settings → Pro → Burn effect; a locked row opens the paywall rather than doing nothing, and losing Pro silently falls back to Fire instead of breaking the burn.
  - *Why these three, not shredder/dissolve:* the effect has to match the feeling. Fire suits a €400 impulse; it is the wrong register for grief. Ash gives the emotional burns a quiet, dignified ending, and Cold flame gives a clinical one. Mechanical effects (shredder, dust) are novelty — they read as a screensaver, not a ritual.
- Haptics on burn progress; satisfying full-burn moment. This is the product — it must feel visceral at 60fps or the thesis fails (hence Phase 0).
- Note: Flutter/Impeller shaders have no `discard` — output transparent pixels instead.

**F4 — Resistance system (retention layer)**
- Each temptation = a persistent **item record**: photo, price, dates, **resistance count**.
- Cravings recur → user re-burns the same item; count increments ("3D Printer — resisted 4×").
- **Savings counted once per item**, never per burn. The "wealth protected" total must stay credible.

**F5 — Victory & routing**
- Post-burn celebration + updated totals: "€4,200 protected this year → €19,600 by 2046."
- CTA links to low-cost brokers (region-aware: DEGIRO, Interactive Brokers). Plain outbound affiliate links. **No eToro** (CFD model conflicts with our message).

**F6 — Wealth-protected dashboard (Pro)** ✅ *built 2026-08-08*
- Total protected + real-market projection ("could be €9.451 by 2046 at the S&P 500's real 33-year average"), stat tiles (temptations / burns / best streak), weak-spot category chips from setup, per-item burn history with thumbnails.
- Pro-gated with a Go Pro lock screen; dev builds without a RevenueCat key keep it open for demos.

**F7 — Privacy lock & local profile (founder decision 2026-08-08)**
- **No accounts, no login — ever.** Registration/login was considered and rejected: with no backend there is nothing an account unlocks, and it would break the "your temptations never leave your phone" pillar.
- Instead: a **local privacy lock** — 4-digit PIN (stored as salted SHA-256 in the iOS Keychain, never the raw PIN) with **Face ID / Touch ID** unlock (`local_auth`), PIN always available as fallback.
- Setup flow after onboarding: name (greetings only) → create/confirm PIN → **spending-category selection** ("Where does your money leak?" — clothes, gadgets, sneakers, food delivery, subscriptions, gaming, …). Categories are stored on-device and will personalize the dashboard.

### 4.4 Temptation categories (v1.5 — pulled forward, founder decision 2026-08-08)

**The founder chose to ship the broader temptation system now** rather than waiting for v2: the app targets every kind of unwanted desire — impulse buying, breakup/heartbreak, alcohol, smoking, junk food, social media, porn/sex urges, gambling, doomscrolling, intrusive thoughts. Consequences of this decision:

- **Accounts were reconsidered and rejected again.** Addiction data is health-grade sensitive (GDPR special category). Everything stays on-device behind the PIN/Face ID lock; there is nothing to breach. *"Your addictions never leave your phone."*
- **Goal picker in onboarding** (F8): "What do you want to burn?" multi-select of the goals above; drives dashboard personalization and message tone. If impulse buying is picked, the spending-weakness picker follows.
- **Supportive disclaimer** (F8) closes onboarding: the app is a ritual, not treatment — seeing a doctor/therapist for a harmful addiction is strength, not defeat. Never claim to treat addiction (App Store + ethics).
- **Write-and-burn** (F9): write the thought/craving on on-screen paper, rendered to an image, burned with the same shader. Emotion burns skip the shock card (no price), keep resistance counts ("resisted texting them 7×").
- **Reflection step** (F10, expanded 2026-08-09 into the purchase interview): before the shock card, three questions max, one at a time — curated bank as the floor, the on-device model generating follow-ups from the user's actual answers when Apple Intelligence is available. Ends with the **mirror**: the user's own answers reflected back (AI paraphrase, or their words verbatim without AI), then the same growth-or-impulse choice as always. **The AI is the interviewer, never the judge** — a verdict would turn the ritual into a permission machine, and permission machines get gamed. "Just burn it" is visible at every step; reflection never stands between the user and the fire. Answers persist with the item (schema v3 `reflectionJson`), so a re-burn's shock screen opens with *"Last time, asked 'When would you use it?', you said: 'once, maybe'"* — nobody argues with their own words. A growth answer still softens the framing; the app never tells people to buy.
- **Motivation messages** (F11): curated per-category encouragement after emotional burns instead of money math.
- **AI roadmap:** curated content (shipped) → **Apple on-device Foundation Models (shipped 2026-08-08)** → optional opt-in cloud AI coach much later. No emotional content leaves the device without explicit consent.
  - Implementation: `FoundationModelsChannel.swift` (MethodChannel `burnmydesire/ai`, guarded by `#available(iOS 26)` + `canImport`) + `lib/data/ai_coach.dart`. After an emotional burn, the written thought + goals + streak go to the on-device model, which writes a personal encouragement; the curated line shows instantly and the AI line cross-fades in when ready. Guardrailed instructions (≤2 sentences, no clinical/financial advice, no AI self-reference, no shaming); output sanity-checked (non-empty, ≤240 chars) with silent fallback to curated messages on any failure, older iOS, or non-Apple-Intelligence devices. Settings → Privacy has an "AI encouragement" toggle (default on).

Every item record carries a `category` from day one:

| Category | Examples | Cost model | Shock card |
|---|---|---|---|
| `purchase` (v1) | Gadget, clothes, 3D printer | One-time price (± installments) | FV of price |
| `habit` (v2) | Drinking, smoking, junk food, gambling | **Recurring cost** (amount × frequency) | FV of annualized spend — *"€40/weekend on drinks = €2,080/yr → ~€95,000 in 20 years"* |
| `emotion` (v2) | Texting an ex, doomscroll urge, revenge impulse | No price | No shock card — straight to the burn ritual + resistance count |

- The burn ritual and resistance system are **identical across categories** — photograph the bottle, the pack, the screenshot; burn it; count the resistance.
- `habit` items are inherently repeat-burn: every resisted urge increments the count, and "wealth protected" accrues from the *avoided recurring spend* (counted per resisted occurrence, unlike one-time purchases).
- v2 marketing expansion: "quit drinking" / "quit smoking" App Store keywords are far larger markets than impulse shopping, with proven willingness to pay (Reframe, Smoke Free, etc. are top-grossing). The burn ritual differentiates there too.
- **Not in v1.** No category picker, no habit math in the first release — only the DB column and the vision.

### 4.5 Freemium gating

| | Free | Pro |
|---|---|---|
| Active temptation items | 3 | Unlimited |
| New desires per month (photos + thoughts) | 5 | Unlimited |
| Burns / re-burns per item | Unlimited | Unlimited |
| Burn effects | Fire, Shredder | All six (+ Ash, Cold flame, Dissolve, Static) |
| Return rate / horizon | Fixed 8% / 20y | Adjustable |
| Dashboard & analytics | — | ✓ |
| Price | — | **€29.99 lifetime (hero)** · €14.99/yr (7-day trial) · €2.99/mo — no weekly plan, ever |

Rationale: gating *capture* (not burns) puts the paywall where usage pressure actually is while never holding the ritual hostage — re-burning an existing struggle is free forever, because "pay €2.99 to resist your urge" is the one-star review that writes itself. The monthly count includes tombstones, so a final burn can't be farmed to refill the allowance. The paywall moment acknowledges the win ("You let go of 5 desires this month"), never scolds.

**Lifetime is the hero (2026-08-16, GROWTH.md M1).** An app that teaches people to burn the subscription they forgot to cancel cannot lead with an auto-renewing one — the irony is real and Gen Z screenshots it. So the one-time plan sits first and preselected ("One burn pays for it. No renewal, ever."), the subscriptions sit under it as the alternative, weekly is filtered out even if the store offers one, and every plan carries three promises: the burn stays free, no countdown timers or fake discounts, cancel in one tap (a real link to Apple's page) with a local reminder three days before each renewal. LTV maths: yearly at €19.99 × ~45 % renewal ≈ €32 over three years; lifetime at €29.99 is the same money with zero churn and it matches what the app preaches.

**Ads: rejected (2026-08-11).** An ad SDK would end the "Data Not Collected" label, put trackers inside an app holding addiction data, serve shopping ads to people mid-craving (the product's exact antithesis), and earn pocket change (~€2 blended eCPM on a low-session utility) while suppressing Pro conversion and affiliate revenue — both larger. The only ad-shaped thing ever worth considering: a self-served static "sponsored by" card from one aligned brand, no SDK, no tracking. Not before v3.

### 4.6 Going global (founder decision 2026-08-09) ✅ *built*

Launch markets: **US, India, Europe**, teens-and-up. Three pieces:

- **Currency is a display setting, nothing more.** Amounts are stored as plain integer minor units with no currency attached; nothing is ever converted (no FX problem exists — everything lives on one device). Setup asks one question with the device locale's answer pre-filled; Settings can change it later and says stored numbers stay as they are. India groups by lakh (₹1,00,000); everywhere else keeps en_US grouping (the "1.689 reads as one euro" lesson). The opt-in world counter converts contributions to euro cents with rough static rates so the public total keeps one unit.
- **Financial goal.** One goal — name, emoji, target amount — because a single destination keeps every burn pointed at the same picture. Skippable at setup; presets carry no prices (a car costs a different number in Mumbai and Munich). Progress shows after **money burns only** — an emotion burn is never told it brought a MacBook closer. Dashboard card + Settings edit. This is the retention spine: "you're 4% closer to your car" beats "you protected money".
- **Country-matched funds.** Bundled dataset grew to 14 series: Nifty 50 + Reliance + TCS (INR), FTSE 100 (GBP), DAX (EUR), alongside the existing US/world set (`tool/fetch_market_data.py` regenerates it). `fundsFor(currency)` orders: local indices → world → US indices → local stocks → US household names; foreign local indices never appear (no DAX in Delhi, no Nifty in Ohio). **The default selection is always an index in the user's own market** — showing a teen what NVDA "would have made" as the opening number is survivorship bias with a chart on it; single stocks stay one deliberate tap away. Growth math is a ratio, so a fund's quote currency never touches the user's amounts.

---

## 5. Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| App framework | **Flutter** (Dart), iOS-first | One codebase; Impeller renders custom shaders at 60fps |
| State | **Riverpod** | Typed, compile-safe |
| Burn effect | **GLSL fragment shader** (`.frag`) via `FragmentProgram` + `CustomPainter` | Direct GPU pixel control |
| Local DB | **Drift** (SQLite) | Actively maintained. **Not Isar** — unmaintained (v3 stale, v4 never stabilized) |
| Images | App documents directory | Private, included in iCloud device backup |
| Camera/gallery | `image_picker` | Standard |
| Payments | **StoreKit 2 / Play Billing via RevenueCat SDK** | Subscriptions with zero backend; free tier to $2.5k MRR |
| Analytics (optional) | TelemetryDeck | Privacy-first, fits brand; or ship v1 with none |
| Web | **Next.js** on Vercel | Landing + web calculator + WebGL burn demo |
| Extensions (later) | WebExtension (JS + WebGL burn) | Chrome/desktop interception |

### Backend: **none.**
All data on-device. No accounts, no servers, no cloud.

**Encryption (2026-08-09).** The database is SQLCipher-encrypted with a 256-bit key held in the Keychain (`first_unlock_this_device`, never synced); photos and rendered thought pages carry `NSFileProtectionComplete`. Pre-encryption databases migrate via `sqlcipher_export` and the plaintext file is deleted. The app refuses to open rather than fall back to plaintext, and Settings reports the live status so the claim is checkable. Proven by on-device integration tests: no plaintext header, user content absent from the raw file, unreadable without the key or with a wrong key.

**Backup (Pro) — iCloud first (founder decision 2026-08-09).** The encrypted archive is written into the app's iCloud Drive container and syncs automatically (after every burn, plus a manual "Back up now"), so restoring on a new phone needs no file shuffling. Crucially the archive is passphrase-encrypted *before* it leaves the device, so iCloud — and Apple — hold ciphertext only; the passphrase lives in the Keychain (device-only, never synced) so automatic backups don't prompt. "Erase everything" deletes the iCloud copy and the stored passphrase too.

**Blocked on the paid Apple Developer Program:** iCloud containers cannot be enabled on a free personal team. `ios/Runner/Runner.entitlements` is written and ready but deliberately *not* wired into the build, so current free-team installs keep working; the file documents the two steps to switch it on. Until then the app reports iCloud as unavailable and the share-sheet file backup below is the working path.

**Backup (Pro) — file export.** An encrypted archive — itself a SQLCipher database keyed by a user-chosen passphrase (PBKDF2-HMAC-SHA512) — exported through the share sheet and restored via a native document picker. No server touches it; a lost passphrase means a lost backup, stated plainly in the UI. iCloud device backup already covers same-device restore for free users, so this is the portable, cross-device option. Restore-on-new-phone comes free via iCloud/Google device backup. Running cost until revenue: ~€99/yr Apple Developer + ~€20/yr domains.

**Privacy is a feature:** a list of things someone craves but can't afford is intimate data. *"Your temptations never leave your phone"* is a core marketing line.

---

## 6. App Architecture (Flutter)

```
lib/
├── main.dart
├── models/
│   └── item_record.dart        # Drift table: photo path, category (purchase|habit|emotion),
│                               # price / recurring amount+frequency, installment terms,
│                               # created/last-burned dates, resistance_count
├── providers/
│   ├── calculator_provider.dart
│   ├── items_provider.dart
│   └── purchase_provider.dart  # RevenueCat entitlements
├── data/
│   └── user_prefs.dart         # Local profile, spend categories, PIN hash (Keychain)
├── screens/
│   ├── profile_setup_screen.dart   # Name + create/confirm PIN (F7)
│   ├── category_selection_screen.dart  # Spending-weakness picker (F7)
│   ├── lock_screen.dart        # PIN + Face ID gate on launch (F7)
│   ├── home_screen.dart        # Item list + "New temptation" CTA
│   ├── capture_screen.dart     # Photo + price + installment entry
│   ├── shock_screen.dart       # One-number shock card
│   ├── burn_screen.dart        # Shader canvas + hold/drag interaction
│   ├── victory_screen.dart     # Celebration + totals + broker CTA
│   └── dashboard_screen.dart   # Pro analytics
├── widgets/
│   ├── burnable_image.dart     # CustomPainter wrapping FragmentProgram
│   └── shock_card.dart
├── utils/
│   └── math_utils.dart         # FV, installment true-cost; unit-tested
└── assets/shaders/
    └── burn.frag
```

### Math spec (`math_utils.dart`)

- Future value: `A = P(1 + r)^t`, annual compounding, r default 0.08, t ∈ {10, 20, 30}.
- Installment true cost: `totalPaid = monthly × months`; overpayment = totalPaid − price; realCost = totalPaid + FV(price) − price framing per F2.
- All money math in cents (int), formatted per locale. 100% unit-test coverage on this file.

---

## 7. Monetization Summary

### 7.0 Analytics & growth decisions (2026-08-09)

**Installs and regular use come from App Store Connect, not from us.** Apple already reports units, active devices, sessions and retention, aggregated and privacy-safe. Building our own would be strictly worse and would cost the "Data Not Collected" privacy label, which is itself a marketing asset for this product. TelemetryDeck stays the option if funnel detail is ever needed.

**"Money saved" is an opt-in feature, not tracking.** `counter/` is a self-hosted service (Docker, for Coolify/Dokploy on Hetzner) storing exactly two integers: a running total and a contributor count. The app sends the *delta* since it last contributed, so the server never needs an identifier — no user table, no install id, no IP log, no per-contribution timestamp. Off by default, one tap to revoke. Rate limited and capped so one absurd submission can't distort a public figure. The website labels the figure as self-reported; inflating it would undo the thing the product sells.

**"Move the money" is the missing half of the loop.** The app said "you protected €800" while the money stayed in a current account until next week. The victory screen now offers to move that exact amount to a savings or broker partner, commission disclosed. **Shown only after the burn — never on the shock card**, where the user is mid-craving and in no state to be sold anything. This contextual placement is also why the affiliate economics work at all: a generic "check out DEGIRO" link converts far worse.

**Partner order:** neobanks / high-yield savings first (lowest friction for someone who won't open a brokerage), then brokers and ETF platforms, then meditation apps for the v1.5 addiction goals. **Therapy platforms are excluded** despite the highest payouts — BetterHelp's FTC settlement over health-data sharing makes it a reputational landmine inside an addiction app, and it would make the "see a real professional" disclaimer look monetized rather than sincere.

**Growth loop:** shareable milestone cards ("€X protected") and burn videos. The card deliberately says nothing about *what* was resisted, so sharing a win can never leak that someone is fighting an addiction.



1. **Pro tier** (RevenueCat, no backend): €29.99 lifetime (hero) · €14.99/yr · €2.99/mo. See §4.5 and GROWTH.md.
2. **Broker affiliate links** (IBKR, DEGIRO referral): outbound URLs only; treated as bonus revenue, never the pillar. No CFD platforms.
3. **No ads, ever** — conflicts with privacy positioning and the premium calm of the ritual.

### Compliance notes
- Projections are generic calculators, not advice. Adjustable rate, visible assumptions, "historical averages, not guaranteed" disclaimer. Never "you should invest in X."
- EU financial-promotion rules: keep broker links as plain referrals with neutral copy.
- App Store: finance-adjacent apps pass review fine with disclaimers; no crypto, no real trading in-app.

---

## 8. Web Presence (Phase 4)

**burnmydesire.com** — Next.js on Vercel. **Founder decision (2026-08-08): the website is a marketing funnel to the mobile app only — no interactive demos.** The burn ritual and calculator live exclusively in the app so the website never substitutes for installing it.
1. **Hero:** impulse-buying pain + compound-loss hook + App Store button (placeholder until launch).
2. **Real app screenshots** (home / shock / burn) as the centerpiece.
3. **How it works, About, Contact** (hello@burnmydesire.com — set up email forwarding at the registrar), **Privacy policy page** (also required by App Store Connect).
4. **Content hub (post-revenue):** ETF-education articles with vetted affiliate links.

**Marketing motion:** short-form video (TikTok/Reels/Shorts) of real items burning + the shock number. The effect *is* the ad.

---

## 9. Extensions Roadmap

### iOS Share Extension (Phase 5 — highest-leverage post-v1 feature)
- Share from Amazon/Zalando/etc. → Burn My Desire pre-filled with product image + detected price.
- Puts us *inside* the shopping flow at the exact impulse moment. CartPause proves the flow converts.

### Chrome Extension (Phase 7)
- Activates on retailer product/cart pages; overlays: *"This €800 is €3,728 of your future wealth. Burn it instead?"* → WebGL burn in-page → logs to nothing (stateless) or deep-links to app.
- Separate codebase (WebExtension JS + WebGL port of the shader — reuse the landing-page port).
- Price detection per retailer is a maintenance burden → start with Amazon only.
- Role: acquisition funnel for the app, not a standalone product.

---

## 10. Phased Roadmap

| Phase | Scope | Exit criteria | Est. |
|---|---|---|---|
| **0 — Shader spike** ✅ *done 2026-08-08* | Throwaway Flutter app (`shader_spike/`): press-and-hold burn via `burn.frag`, haptics, gallery picker | **PASSED** — full loop verified on iPhone 17 Pro simulator; founder approved the feel. Real-device haptics/fps check still pending | 2–3 days |
| **1 — Scaffold + core loop** ✅ *done 2026-08-08* | Real app in `app/`: Riverpod, `image_picker`, math_utils (9 unit tests, money in cents), installment true-cost, capture → shock → burn → victory, session totals + resistance counts (in-memory) | **PASSED** — full happy path verified on simulator with a real photo | 1–2 wks |
| **2 — Persistence + resistance** ✅ *done 2026-08-08* | Drift DB (`Items` table with `category` column ready for v2), photos in app documents dir, re-burn from home list, 4 DB unit tests | **PASSED** — item survived full app kill+relaunch; re-burn showed "resisted 2×" with total unchanged at €1.200 | 1 wk |
| **3 — Paywall + ship** 🔶 *code done 2026-08-08* | RevenueCat SDK behind `--dart-define=RC_IOS_KEY` (free-only fallback), 3-item gate (3 unit tests), paywall screen, 3-screen onboarding (shown once), flame app icon + display name | Code-side **PASSED** on simulator. **Blocked on founder accounts:** Apple Developer Program, App Store Connect app record + IAP products, RevenueCat project. Then: wire key, archive, TestFlight | 1 wk |
| **4 — Landing page** 🔶 *code done 2026-08-08* | Next.js site in `web/`: hero, real app screenshots, how-it-works, about, contact, privacy-policy page, compliance footer. App-marketing only per founder decision — no web demos. Fully static build | Code **PASSED** locally in browser. **Founder action:** deploy to Vercel + point burnmydesire.com DNS + set up hello@ email forwarding | 1 wk |
| **5 — iOS Share Extension** | Share-sheet target, image + price extraction | Amazon share → pre-filled capture screen | 1 wk |
| **6 — Android release** | Play Billing via RevenueCat, device QA | Play Store live | 1 wk |
| **7 — Chrome extension** | WebExtension, Amazon-only price detection, in-page WebGL burn | Chrome Web Store live | 1–2 wks |
| **8 — Content hub** | ETF-education articles + affiliate links (post-revenue) | Ongoing | — |
| **9 — Temptation categories (v2)** | Habit mode (recurring-cost math, per-occurrence savings) + emotion mode (ritual-only); category picker; "quit drinking/smoking" ASO keywords | Habit + emotion items shippable end-to-end | 2 wks |

**v1 = Phases 0–3.** Everything else waits until the core mechanic is validated by real users.

---

## 11. Success Metrics

- **Activation:** % of installs completing first burn (target > 60%).
- **Retention:** % returning to burn again within 14 days (the resistance system's job).
- **Honesty metric:** wealth-protected total = sum of unique items only.
- **Conversion:** free → Pro after hitting the 3-item gate (target 3–5%).
- **Virality:** shares of burn videos / victory cards.

## 12. Risks

| Risk | Mitigation |
|---|---|
| Burn feels gimmicky, not cathartic | Phase 0 kill-switch before further investment |
| Crowded niche moves fast | v1 in ~4–5 weeks; burn mechanic is the moat |
| Broader-vision scope creep delays v1 | Categories are a DB column + a doc section until v1 ships; no habit/emotion UI before Phase 9 |
| Episodic usage, weak retention | Resistance system + share extension put us at the impulse moment |
| Projection framing reads as advice | Disclaimers, adjustable assumptions, neutral broker copy |
| Isar-style dependency rot | Mainstream deps only (Drift, Riverpod, RevenueCat) |

---

*Next action: register burnmydesire.com + .app, reserve the App Store name, then begin Phase 0.*
