# Notifications — Design & Implementation

*Decided 2026-08-11. Status: shipped with the code this document sits beside.*

## 1. The architecture decision: local, never remote

This app has no server and no accounts, and its App Store privacy label
says **Data Not Collected**. Remote push (APNs/Firebase) requires device
tokens in someone's database — infrastructure to run, a privacy label to
lose, and nothing to gain: everything worth telling the user (streaks,
milestones, goal progress) is already **on the device**.

So: **scheduled local notifications only** (`UNUserNotificationCenter`
via `flutter_local_notifications`). Zero servers, zero cost, works with
the free Apple team. Remote push earns a place only for community
moments ("the world counter crossed €1M") — deliberately not built.

## 2. The design principle everything hangs on

**A notification must never re-trigger the craving it exists to fight.**
"Remember those sneakers?" is an advertisement for the sneakers.

And notifications appear on the lock screen, where anyone can read them.
For someone burning porn, gambling, or alcohol urges, a notification
that names the category could out them to whoever glances at their
phone.

Therefore — the same rule as milestone cards:

> **Amounts and streaks, never the object of desire.**
> No item references, no photos, no goal categories, no written thoughts.

Structurally enforced: the copy bank contains only fixed strings plus
formatted *amounts*. The planner never receives goal labels or thought
text as input, so a future edit cannot accidentally leak them.

Also banned: guilt, FOMO, "we miss you", streak-shaming. Every category
speaks in wins.

## 3. What fires, and when

| Category | Schedule | Example |
|---|---|---|
| **Check-in** | Daily, 3×/week (default), weekends (Fri–Sun) or around payday (the day + two after), at a user-chosen hour (default 21:00 — the impulse-shopping hour). Skips today if the user already burned today. | "Anything pulling at you tonight? One minute here is cheaper than one tap of Buy Now." |
| **Streak guard** | Per live item, +3 and +7 days after its last burn, at 09:30. The +3 invites the re-burn ("Still want it? Burn it again — it's free"); the +7 admires the streak. | "One of your desires hits a one-week streak tomorrow. Come claim it." |
| **Monthly proof** | Monthly on the first-burn anniversary day, 09:30. Needs a positive protected total. | "₹12,400 is still yours. Two months of winning." |
| **Final-burn invitation** | The morning after an item becomes one burn away from the final-burn threshold. | "One desire is ready to be ended forever. You've already beaten it three times." |
| **Backup nudge** (Pro) | When the last encrypted backup is over 30 days old. 09:30. | "Your wins deserve a backup. Thirty seconds, encrypted, yours." |
| **Weekly Ash Report** | Sunday 18:00, only for a week with at least one burn in it. Never for an empty week. (GROWTH.md M4) | "3 burns this week. Your Ash Report is ready." |
| **Renewal reminder** (Pro, subscription plans) | Three mornings before the next charge; if that's already passed, tomorrow morning — never after the charge. Only the master switch can silence it. (GROWTH.md M1) | "Pro renews in 3 days for €14.99. Keep it, or cancel in one tap — either is fine." |

### Global rules

- **Hard cap: one notification per day.** Priority when two collide:
  renewal > final-burn > streak > weekly report > monthly proof > backup > check-in.
  Renewal is first because it's the one the paywall *promises*.
- **Quiet hours:** nothing before 09:00 or after 22:30. The user's
  chosen check-in hour is clamped into that window.
- **Horizon:** the next 30 days, at most 20 scheduled (iOS caps pending
  local notifications at 64; staying far under leaves room and keeps
  re-planning cheap).
- Every category is individually toggleable; the master switch kills
  all. **"Erase everything" cancels everything.**

## 4. Scheduling model: plan, don't drip

There is no background daemon. Instead the entire future schedule is a
**pure function** of current state:

```
NotificationPlanner.plan(items, protectedCents, prefs, isPro, lastBackupAt, now)
    → [ (id, when, title, body), … ]
```

After anything relevant changes, the app cancels all pending
notifications and schedules the planner's fresh output. Re-plan happens:

- after every burn is persisted (victory screen),
- after any notification setting changes,
- on app launch and on foreground resume.

This is stateless and idempotent — there is nothing to migrate, nothing
to get out of sync, and the whole scheduling brain is unit-testable
without a device.

Notifications are scheduled as **absolute one-shot instants** (UTC), not
repeating calendar rules. A DST change while the app stays unopened can
drift a far-future check-in by an hour; the next open corrects it. In
exchange we avoid a native timezone plugin entirely.

## 5. Permission UX

- **Never ask at launch.** The ask appears once, on the victory screen
  after a burn — the moment the user just felt the win: *"Want a nudge
  when your streak is at risk?"* Contextual asks convert roughly twice
  as well as cold ones.
- Decline is remembered and never re-asked; the Settings master switch
  remains the way back in (it re-requests iOS permission if needed).
- If iOS permission is denied at the system level, the Settings switch
  points to the iOS Settings app rather than silently failing.

## 6. Code map

| File | Role |
|---|---|
| `app/lib/data/notification_planner.dart` | Pure scheduling brain + copy bank. No plugin imports, fully unit-tested. |
| `app/lib/data/notification_prefs.dart` | Toggles, frequency, check-in hour, ask-shown flag (SharedPreferences). |
| `app/lib/data/notification_service.dart` | Thin `flutter_local_notifications` wrapper: init, permission, sync(plan), cancelAll. |
| `app/lib/providers/notification_provider.dart` | `replanNotifications(ref)` — gathers state, runs planner, syncs. |
| Settings → Notifications group | Master + per-category switches, frequency, hour picker. |
| Victory screen | One-time contextual permission card. |
| `app/test/notification_planner_test.dart` | Cap, quiet hours, frequencies, streaks, horizon, copy rules. |

## 7. Explicitly not built (and why)

- **Remote push / FCM** — needs a token server; costs the privacy label.
- **Item-specific copy** ("your sneakers…") — re-triggers cravings,
  leaks on the lock screen.
- **Streak-loss shaming** ("you're about to lose your streak 😱") — the
  app never manufactures anxiety; it sells calm.
- **Badges** — a permanent red dot is a tiny anxiety machine.
- **AI-personalized notification copy** — possible later (on-device,
  same "let go, not burn" prompt rules as the coach), but curated copy
  ships first; notification text must be predictable enough to audit.
