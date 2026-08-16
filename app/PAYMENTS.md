# Payments

How Pro is sold, and exactly what has to exist before a purchase can
happen. Written down because the failure mode here is silent: everything
compiles, the paywall renders, and no plans ever appear.

## The chain

    App Store Connect  →  RevenueCat  →  app
    (products, prices)    (offering)     (RC_IOS_KEY)

Three links. A break in any one of them shows up in the app as "no plans
came back from the store", so work through them in order.

## What the app expects

| Thing | Value |
| --- | --- |
| Bundle ID | `com.burnmydesire.burnMyDesire` |
| Entitlement | `pro` (`kProEntitlementId` in `lib/config.dart`) |
| Product IDs | `pro_monthly`, `pro_yearly`, `pro_lifetime` |
| Offering | RevenueCat's **current** offering |

The product IDs above are a convention, not a requirement — the app never
names a product. It renders whatever packages the current offering
contains, sorts them yearly → monthly → lifetime, and preselects the
yearly one. Prices, currency and trial length all come from the store, so
changing a price never needs an app update.

## 1. App Store Connect

1. **Agreements, Tax, and Banking** — the Paid Applications agreement must
   be *Active*. Nothing else works until it is, and this is the single
   most common reason products never appear.
2. Create the in-app purchases:
   - `pro_monthly` — Auto-Renewable Subscription, €2.99/month
   - `pro_yearly` — Auto-Renewable Subscription, €14.99/year, **1 week
     free trial** (Introductory Offer → Free Trial)
   - `pro_lifetime` — Non-Consumable, €29.99 — **the hero plan**
   - Do **not** create a weekly product. The paywall filters weekly out
     even if one exists (`offeredOnPaywall`), so it would only confuse
     the RevenueCat dashboard.
3. Put both subscriptions in **one subscription group** so people can move
   between them without double-paying.
4. Each product needs a display name, description, and a review
   screenshot, and must reach **Ready to Submit**. Products in "Missing
   Metadata" are invisible to the app.

## 2. RevenueCat

1. New project → add an App Store app with the bundle ID above.
2. Paste the **In-App Purchase Key** (App Store Connect → Users and
   Access → Integrations → In-App Purchase) so RevenueCat can verify
   transactions.
3. Create entitlement `pro`, attach all three products to it.
4. Create an offering, mark it **current**, and add one package per
   product.
5. Copy the **public** SDK key (`appl_…`). Public, not secret — it ships
   inside the app.

## 3. Build with the key

```bash
flutter build ios --release --dart-define=RC_IOS_KEY=appl_xxx
```

Without it the app runs in free-only mode with everything unlocked, and
the paywall says so. The key is never committed; it comes in at build
time (`kRevenueCatIosApiKey`).

Also set the legal links, which App Review requires on a paywall
(guideline 3.1.2):

```bash
--dart-define=TERMS_URL=https://… --dart-define=PRIVACY_URL=https://…
```

`TERMS_URL` defaults to Apple's standard EULA, which is acceptable.
**`PRIVACY_URL` has no default** — the Privacy link is inert until it's
set, and shipping it that way risks rejection.

## Testing

### The screen, with no store at all

Debug builds with no `RC_IOS_KEY` show sample plans (€29.99 lifetime,
€14.99/yr with a 7-day trial, €2.99/mo — plus a €0.99 weekly that must
*not* appear, to prove the filter) so the layout, the savings badge
and the trial timeline can be checked without any setup. The buy button
is deliberately dead and a banner says why. Release builds can't reach
this code — see `lib/data/paywall_preview.dart`.

### A real transaction

Needs a **physical device** and a **sandbox Apple ID**:

1. App Store Connect → Users and Access → **Sandbox Testers** → create
   one. Use an email you control that is *not* an existing Apple ID.
2. On the iPhone: Settings → Developer → **Sandbox Apple Account** → sign
   in as that tester. (Not the main App Store account — signing into the
   real store with a sandbox ID does not work.)
3. Install a build carrying `RC_IOS_KEY` and buy. Sandbox renewals are
   accelerated: a 1-year subscription renews every hour, a 1-month one
   every 5 minutes, so a trial expiring can be watched in minutes.
4. Confirm in RevenueCat → Customer History that the transaction landed
   and the `pro` entitlement went active.

**Xcode's StoreKit configuration files don't help here.** They fake
Apple's purchase sheet locally, but RevenueCat validates receipts on its
own servers, so the entitlement never activates and Pro never unlocks.
That's why the preview above fakes the *screen* instead of the
*transaction* — a fake purchase that appears to succeed while leaving the
app locked is worse than no test at all.

### What to check

- [ ] All three plans appear, **lifetime first and preselected**, then
      yearly, then monthly; the "or a subscription" heading sits between
- [ ] The savings badge matches the real prices (it's computed, not typed)
- [ ] "Cancel in one tap" opens the App Store's subscriptions page
- [ ] After buying yearly (sandbox), Settings → notifications shows a
      pending renewal reminder — sandbox years last ~1 h, so it lands
      "tomorrow morning" via the missed-lead path
- [ ] Buying unlocks Pro without restarting the app
- [ ] Cancelling the sheet leaves no error on screen
- [ ] Restore purchases works on a second device with the same Apple ID
- [ ] Restore with nothing to restore says so instead of doing nothing
- [ ] Terms and Privacy both open
