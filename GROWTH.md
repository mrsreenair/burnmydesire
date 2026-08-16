# Growth Build Plan — conversion, retention, and the honest paywall

**Started:** 2026-08-16 · **Owner:** founder + Claude · **Status:** 🔶 in progress
**Companion docs:** [PROJECT.md](PROJECT.md) (product truth), [PAYMENTS.md](app/PAYMENTS.md) (RevenueCat chain), [NOTIFICATIONS.md](NOTIFICATIONS.md) (what may fire, and what never will)

This is the working document for the growth pass. Every milestone has a
scope, the files it touches, an exit criterion, and a checkbox. Ticked
boxes are done and committed; nothing here is ticked on intent. When a
milestone changes a product truth, PROJECT.md is updated in the same
commit so the two never disagree.

---

## 0. The diagnosis this plan answers

Rated honestly on 2026-08-16, before any of this was built:

| Question | Answer | Why |
|---|---|---|
| Conversion design (Gen Z) | **4 / 10** | The paywall never fires (free limits are generous by design), the best feature is free forever, and Pro sells a dashboard nobody wants. The paywall *screen* itself is competent. |
| The irony | **Real, and sharp** | The subscription screen says *"forever, until you cancel"* — then Pro is an auto-renewing subscription. Gen Z will screenshot that into a review. |
| Retention | **Structurally hard** | An interruption app is opened when tempted; if it works you need it less. Retention must come from reasons to open when *not* tempted. |

Two corrections to the first-pass verdict, found while auditing the code:

- **A share card already exists** ([share_milestone.dart](app/lib/widgets/share_milestone.dart), on victory + dashboard). It says "€X protected by burning N desires" and deliberately never says *what*. So M3 is an upgrade, not a build.
- **Risk-window reminders already exist** as the check-in (user-chosen hour, default 21:00, NOTIFICATIONS.md §3). The delta is small and folded into M5.

Benchmarks used throughout (RevenueCat State of Subscription Apps; Adjust/AppsFlyer retention reports — verify the year's numbers before quoting externally):
download→paid median ≈ 2 % / top quartile ≥ 5 %; consumer D1 ≈ 25 %, D7 ≈ 11 %, D30 ≈ 5 %.
**Targets:** download→paid ≥ 3 %, D7 ≥ 20 %, D30 ≥ 10 %, activation (first burn) ≥ 60 %.

---

## 1. Milestones, in build order

Ordered by value ÷ effort. Native milestones (M8–M10) come last because
each adds an Xcode target and can leave the project unbuildable
mid-flight; everything before them is pure Dart and ships independently.

| # | Milestone | Effort | Status |
|---|---|---|---|
| M1 | Pricing + the honest paywall | ½ day | ✅ 2026-08-16 |
| M2 | Give Pro a reason to exist, and a moment to be offered | 1 day | ✅ 2026-08-16 |
| M3 | Share card 2.0 — goal-anchored | ½ day | ⬜ |
| M4 | Weekly Ash Report | 1½ days | ⬜ |
| M5 | Follow-up cadence + re-burn loop | ½ day | ⬜ |
| M6 | Cosmetics as Pro — two new burn effects | 1 day | ⬜ |
| M7 | Analytics decision (no code unless the decision flips) | — | ⏳ founder |
| M8 | Home-screen widget (native) | 2 days | ⬜ |
| M9 | Share extension (native) | 2–3 days | ⬜ |
| M10 | Live Activity for parked desires (native, shares M8's target) | 1½ days | ⬜ |

≈ 11–12 working days of build. M1–M6 are one release; M8–M10 are a second.

---

## M1 — Pricing + the honest paywall

**Why.** Resolve the irony by congruence, not by being free. Make the
one-time purchase the hero, kill weekly, and say the quiet part out loud.

**Prices** (replace placeholders everywhere — code, PROJECT.md §4.5, PAYMENTS.md, App Store Connect):

| Plan | Price | Role |
|---|---|---|
| **Lifetime** | **€29.99** | Hero. *"One burn pays for it. No renewal, ever."* |
| Yearly | €14.99, 7-day trial | Budget entry, ≈ €1.25/mo |
| Monthly | €2.99 | Exists to make yearly look good; expected < 15 % of buyers |
| ~~Weekly~~ | — | **Removed.** Weekly is the dark pattern the app is against. |

Comps (from memory, verify before locking): Opal $99/yr · Finch Plus $70/yr · Cleo $6/mo · one sec ≈ €20/yr · Forest/Streaks one-time $4–6 · YNAB $109/yr.
LTV maths: yearly €19.99 × ~45 % renewal ≈ €32 over three years; lifetime €29.99 is the same money with zero churn and it matches what the app preaches.

**Scope**
- [x] Mobbin pass on lifetime-hero / one-time-purchase paywalls before touching layout (memory rule)
- [x] `_ordered` ranks lifetime → annual → monthly; `_bestValueIndex` picks lifetime; weekly filtered out entirely
- [x] Badge copy: lifetime "One burn pays for it", yearly "Cheapest way in"
- [x] "No renewal, ever" line under lifetime; "Cancel in one tap" row (deep link `itms-apps://apps.apple.com/account/subscriptions`) for the subscriptions
- [x] Renewal reminder: local notification 3 days before a yearly renewal (`CustomerInfo.entitlements.active['pro'].expirationDate`), amounts-only copy, obeys the one-per-day cap and quiet hours (NOTIFICATIONS.md §3). New `_Kind.renewal`, priority just below finalBurn.
- [x] Sub-headline: "Less than one month of the thing you just burned" when arriving from a victory with a known price
- [x] `_preview` (debug) offerings updated to the new three
- [x] Docs: PROJECT.md §4.5 + §7, PAYMENTS.md product table
- [x] Tests: `plan_offer_test` for ordering + savings with lifetime hero; planner test for renewal reminder

**Exit.** Paywall shows three plans, lifetime preselected and badged; tapping "Cancel in one tap" opens Apple's subscription page; a Pro user with a yearly plan has a pending local notification 3 days before expiry. `flutter analyze` clean, tests green.

---

## M2 — Give Pro a reason to exist, and a moment to be offered

**Why.** The paywall is only reachable from Settings and a limit nobody
hits. Two fixes: make Pro contain things a Gen Z user actually wants,
and offer it once, at the one moment it's welcome — **after** a burn,
never on the shock card (same rule as "move the money", PROJECT.md §7.0).

**Pro contains (after M2 + M6):** unlimited capture · all burn effects (2 free, 4 Pro) · dashboard · reminders · encrypted backup · adjustable rate/horizon.

**Scope**
- [x] Victory-screen "Pro moment": one dismissible card, shown only when the burn is worth ≥ ~€30 (about the lifetime price, via the currency's rough EUR rate — so "one burn pays for it" is true), at most once per 14 days, never on the first victory, never on emotion burns, never alongside a permission ask. Copy anchors to the burn: *"You just protected €200. Pro forever costs less than that — once, no renewal."*
- [x] Frequency cap persisted (`pro_moment.dart`), marked on show not on tap
- [x] Effect picker: locked Pro effects open the paywall with `source: effect`
- [x] ~~Multiple financial goals~~ — **dropped.** `financial_goal.dart` says "one goal, by design: a single destination keeps every burn pointed at the same picture", and that's right; selling a second goal would sell a worse product. Recorded in §2.
- [x] Paywall `source` + `anchorCents` (landed in M1): `effect` → "Unlock every way to let go", `limit` → existing "You let go of 5 desires…", `moment` → "You just protected €200" + "That one burn pays for Pro 6 times over — forever"
- [x] Tests: `pro_moment_test` (7), headline mapping in `plan_offer_test`

**Exit.** ✅ Verified on the simulator 2026-08-16: second €200 burn showed the notification ask (Pro moment waited); third showed the Pro moment; "See Pro" opened the paywall with the anchored headline.

---

## M3 — Share card 2.0 — goal-anchored

**Why.** The existing card says "€X protected". The line Gen Z will
actually post is *"12 % closer to 🗾 Japan"* — it's theirs. Still never
says what was resisted (a goal is aspirational, a temptation is private).

**Scope**
- [ ] `milestone_card.dart`: optional goal line (emoji + name + "% closer" or "€X of €Y"), story + square
- [ ] Victory screen passes the goal + slice; dashboard passes cumulative
- [ ] Emotion/thought burns: card falls back to burns-only ("I let go of 3 things this week")
- [ ] Wordmark + a subtle "burnmydesire.app" — the card is the ad
- [ ] Golden-ish test: render both formats headless, assert non-empty PNG and dimensions

**Exit.** Sharing from a purchase victory produces a card with the goal line; from a thought burn, without.

---

## M4 — Weekly Ash Report

**Why.** The one ritual that opens the app when the user isn't tempted.
Sunday, one push, one screen, one share.

**Data.** There is no per-burn event log — only `lastBurnedAt` and
`resistanceCount`. Add a `Burns` table (itemId, at, priceCents snapshot,
category) — schema **v5**, back-filled from `lastBurnedAt` on migrate so
existing users get one row per item.

**Scope**
- [ ] `Burns` table + migration + `recordBurn` called from the victory path
- [ ] `weeklyReportProvider`: burns, protected, goal movement, follow-ups resisted, for the ISO week
- [ ] `AshReportScreen`: headline number, three tiles, one line of copy (rotating bank), ShareMilestone(story)
- [ ] Notification: Sunday 18:00 local, kind `weekly`, priority below streak, obeys cap + quiet hours; skipped if zero burns that week (never a "you did nothing" push)
- [ ] Home entry: small "This week" chip on the ledger from Saturday until it's opened
- [ ] Free for everyone. Reports are the ad, not the product.
- [ ] Tests: week bucketing (Monday start, local tz), planner skips empty weeks

**Exit.** After two burns in a week, Sunday's notification opens a report showing both; a week with none schedules nothing.

---

## M5 — Follow-up cadence + re-burn loop

**Why.** Questions get opened; nags get dismissed. And desires come back
— the app already needs 3 burns to destroy one, so invite the second.

**Scope**
- [ ] Follow-up window 14 d → **3 d + 14 d** (two questions per item; the second only if the first was "not yet"). `needsFollowUpProvider` grows a stage.
- [ ] Check-in gets a **days** choice: every day · a few times a week · weekends · payday (day-of-month picker). Copy unchanged, planner filters by weekday.
- [ ] Streak-guard +3 push copy adds the invitation to re-burn ("Still want it? Burn it again — it's free.")
- [ ] Tests: stage transitions; weekday filtering

**Exit.** A purchase burned on Monday asks on Thursday; "not yet" asks again two Mondays later; a "weekends" check-in never fires on a Tuesday.

---

## M6 — Cosmetics as Pro — two new burn effects

**Why.** Gen Z pays for cosmetics (Duolingo, Finch, every game). A fire
skin never contradicts "we help you save"; a capture limit arguably does.

**Scope**
- [ ] Two new fragment shaders, same conventions as `burn.frag` (Impeller: no `discard`, premultiplied output, `uProgress` 0→1, front sweep `mix(-0.34, 1.08, uProgress)`): **Dissolve** (ink-in-water, `pro`) and **Static** (CRT glitch/pixel-out, `pro`)
- [ ] Sounds: procedural WAV, 12 s seamless (audioplayers' iOS loop isn't gapless — see `burn_sound.dart`), water for Dissolve, hiss/tick for Static
- [ ] `burn_effects.dart` entries with icon, verb, glow, `pro: true`; Fire + Shred stay free, Ash + Cold move to Pro (this is the value gap M2 relies on)
- [ ] Picker preview: 1-s auto-loop thumbnail per effect (cheap: run the shader on a small quad)
- [ ] Tests: effect table invariants (unique ids, sound asset exists, exactly 2 free)

**Exit.** Six effects, two free; each new effect completes at hold-end with no dead time; sound loops seamlessly for a 3-s hold.

---

## M7 — Analytics decision

**Founder decision, no code by default.** PROJECT.md §7.0 (2026-08-09)
chose App Store Connect over any SDK to keep the "Data Not Collected"
label. That still holds — and it covers more than the first-pass
diagnosis credited: ASC gives D1/D7/D30 retention and sessions;
RevenueCat gives trial starts, conversion, churn, and LTV. **The only
gap is the in-app funnel** (capture → shock → burn), i.e. activation.

Options:
1. **Defer** (recommended). Launch with ASC + RevenueCat. If activation is unclear after 4 weeks of TestFlight/launch data, revisit.
2. **TelemetryDeck**, event-only, no identifiers. Costs the privacy label (Apple requires disclosing "Product Interaction — not linked to you"). Half a day.

- [ ] Founder picks. If (2), the events are: `onboarding_done`, `capture_started`, `shock_seen`, `burn_done`, `paywall_seen(source)`, `purchase(plan)` — nothing carrying an amount, a category, or a goal.

---

## M8 — Home-screen widget (native)

**Why.** Passive retention: the goal bar on the home screen. Also
bootstraps the native tooling M9/M10 reuse (App Group, extension target).

**How.** WidgetKit target added to `ios/Runner.xcodeproj` via the
`xcodeproj` gem (ships with CocoaPods — scriptable, no Xcode GUI);
App Group `group.com.burnmydesire.shared`; Flutter writes a JSON snapshot
(protected, goal name/emoji/percent, streak weeks) through the
`home_widget` package after every burn; Swift renders small + medium.

**Scope**
- [ ] `tool/add_widget_target.rb` — idempotent script adding the target + App Group entitlement to both targets
- [ ] `ios/BurnWidget/` — Swift: timeline provider reading the App Group JSON, small (goal ring) + medium (goal bar + protected), Paper & Fire palette
- [ ] Flutter: `widget_snapshot.dart` writes after burn / goal change / erase; `home_widget` dependency
- [ ] Never shows a temptation — goal + money only (same rule as notifications)
- [ ] `WIDGET.md` — the target/entitlement steps a human would repeat in Xcode, for when the script can't
- [ ] Exit: widget on the simulator home screen updates within seconds of a burn; archive builds with both targets signed

---

## M9 — Share extension (native)

**Why.** Highest-value item on the whole list: capture from *inside*
Amazon/Zalando/etc. It's the difference between remembering the app
exists and tapping Share (PROJECT.md §9, CartPause validation).

**How.** Share extension target (same gem script pattern as M8), accepts
image + URL + text; writes into the App Group container; opens the app
via `burnmydesire://capture`; Flutter picks up the pending payload on
launch/resume and lands on the capture screen pre-filled (image, and
price if a `€12,34`-shaped token is in the text/URL title).

**Scope**
- [ ] `tool/add_share_target.rb`, `ios/BurnShare/` (Swift, minimal UI: "Burn it" — no editing in the extension)
- [ ] URL scheme + `receive_sharing_intent`-style handoff (own implementation preferred: less surface, we only need one direction)
- [ ] Price extraction: currency-symbol/ISO-code + number regex, conservative; unknown → capture screen asks
- [ ] Free-tier gate still applies (`addBlockProvider`) — the extension never bypasses the paywall, and never shows it either: it hands off and the app decides
- [ ] `SHARE_EXTENSION.md`
- [ ] Exit: Safari → Amazon product → Share → Burn My Desire → capture screen shows the product image with the price filled

---

## M10 — Live Activity for parked desires (native)

**Why.** "Not now — remind me tomorrow" is a promise; the lock screen is
where the promise stays visible. *"🕯 19 h left"* — never the item.

**Scope**
- [ ] ActivityKit attributes in the M8 widget target; start on `_park`, end on unpark/burn/expiry
- [ ] Flutter bridge: one MethodChannel (start / end), no third-party dep
- [ ] Exit: parking a desire shows the countdown on the lock screen; burning it removes it

---

## 2. Decisions taken in this plan (so they aren't relitigated)

| Decision | Choice | Date |
|---|---|---|
| Hero plan | Lifetime €29.99 | 2026-08-16 |
| Weekly plan | Removed | 2026-08-16 |
| Free effects | Fire + Shred; the rest Pro | 2026-08-16 |
| Goals | One, for everyone — multiple goals dropped from M2 (conflicts with the one-picture design in `financial_goal.dart`) | 2026-08-16 |
| Weekly report | Free for everyone | 2026-08-16 |
| Analytics SDK | Deferred (M7) | 2026-08-16 |
| Burn video export | **Not now** — recording the shader is a day of work for a share format we can't measure yet; revisit after M3 share numbers | 2026-08-16 |

## 3. Still blocked on the founder (unchanged)

- Privacy policy URL (`PRIVACY_URL` — the paywall's Privacy link is inert without it; a rejection risk)
- App Store Connect products at the **new** prices + RevenueCat offering + sandbox tester + `appl_` key
- `git push` so the market-data workflow schedules; Settings → Actions → Workflow permissions → Read and write
- M7 decision
