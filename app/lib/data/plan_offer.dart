/// Turning store products into the numbers a paywall actually shows.
///
/// Kept free of RevenueCat types on purpose: the arithmetic here decides
/// what people are told they'll be charged, so it has to be testable
/// without a store, a network, or a device.
library;

/// How a plan recurs. Lifetime is a one-off purchase, not a subscription.
enum PlanPeriod { weekly, monthly, annual, lifetime, other }

/// Parses an ISO 8601 subscription period ("P1M", "P1Y", "P1W") into the
/// shape the paywall reasons about. Anything unexpected is [other] rather
/// than a guess — a mislabelled plan is worse than an unlabelled one.
PlanPeriod planPeriodFrom(String? iso) {
  switch (iso) {
    case 'P1W':
    case 'P7D':
      return PlanPeriod.weekly;
    case 'P1M':
      return PlanPeriod.monthly;
    case 'P1Y':
    case 'P12M':
      return PlanPeriod.annual;
    case null:
      return PlanPeriod.lifetime;
    default:
      return PlanPeriod.other;
  }
}

/// Whole days of free trial in an ISO 8601 intro period, or null when the
/// plan has no trial. Months are 30 days and years 365 — close enough for
/// "7 days free", and the exact wording always comes from the store.
int? trialDaysFrom(String? iso) {
  if (iso == null || iso.length < 3 || !iso.startsWith('P')) return null;
  final unit = iso[iso.length - 1];
  final count = int.tryParse(iso.substring(1, iso.length - 1));
  if (count == null || count <= 0) return null;
  return switch (unit) {
    'D' => count,
    'W' => count * 7,
    'M' => count * 30,
    'Y' => count * 365,
    _ => null,
  };
}

/// What the annual plan saves against paying monthly for a year, as whole
/// percent. Null when there's nothing to compare, when the maths would be
/// meaningless, or when annual isn't actually cheaper — a "Save -4%" badge
/// is the kind of thing that gets an app called a scam.
int? annualSavingsPercent({
  required double monthlyPrice,
  required double annualPrice,
}) {
  if (monthlyPrice <= 0 || annualPrice <= 0) return null;
  final yearOfMonthly = monthlyPrice * 12;
  if (annualPrice >= yearOfMonthly) return null;
  final percent = ((1 - annualPrice / yearOfMonthly) * 100).round();
  return percent <= 0 ? null : percent;
}

/// The per-month equivalent of an annual price, for the "€1.67/mo" line
/// every subscription app shows under a yearly plan.
double perMonthFromAnnual(double annualPrice) => annualPrice / 12;

/// Whether a plan is offered on the paywall at all.
///
/// Weekly is not. It's the plan that bills before anyone notices, the
/// exact mechanic this app teaches people to burn — and a store can add
/// one to the offering without an app update, so the app decides, not
/// the dashboard. Anything unparseable is hidden too: a plan the paywall
/// can't describe is a plan it shouldn't sell.
bool offeredOnPaywall(PlanPeriod period) => switch (period) {
  PlanPeriod.lifetime || PlanPeriod.annual || PlanPeriod.monthly => true,
  PlanPeriod.weekly || PlanPeriod.other => false,
};

/// Display order (lower first). Lifetime is the hero: for an app whose
/// pitch is "stop paying for things forever", the honest sale is the one
/// that ends. Annual is the cheap way in; monthly exists to make annual
/// look cheap.
int paywallRank(PlanPeriod period) => switch (period) {
  PlanPeriod.lifetime => 0,
  PlanPeriod.annual => 1,
  PlanPeriod.monthly => 2,
  PlanPeriod.weekly => 3,
  PlanPeriod.other => 4,
};

/// The plan preselected on arrival — the hero, when it exists.
int heroIndex(List<PlanPeriod> periods) {
  final i = periods.indexOf(PlanPeriod.lifetime);
  if (i >= 0) return i;
  final a = periods.indexOf(PlanPeriod.annual);
  return a >= 0 ? a : 0;
}

/// Roughly how many times over a single resisted purchase pays for the
/// lifetime plan, or null when there's nothing meaningful to say. Used
/// for the "one burn pays for it" line — only when it's actually true.
int? burnsCoveringLifetime({
  required int burnCents,
  required double lifetimePrice,
}) {
  if (burnCents <= 0 || lifetimePrice <= 0) return null;
  final times = (burnCents / 100) / lifetimePrice;
  return times >= 1 ? times.floor() : null;
}

/// Where the paywall was opened from. Decides the opening line so the
/// screen speaks to the moment rather than reciting features.
enum PaywallSource {
  /// Settings, dashboard, the tab — no particular moment.
  general,

  /// The free capture limit was hit.
  limit,

  /// A locked burn effect was tapped.
  effect,

  /// A second financial goal was attempted.
  goal,

  /// Offered on the victory screen right after a sizeable burn.
  moment,
}

/// The headline for each source. [burnLabel] is the formatted amount of
/// the burn that led here (moment only); [limitLine] is the caller's own
/// limit copy, kept because it already acknowledges the win.
String paywallHeadline(
  PaywallSource source, {
  String? burnLabel,
  String? limitLine,
}) => switch (source) {
  PaywallSource.general => 'Burn without limits',
  PaywallSource.limit => limitLine ?? 'Burn without limits',
  PaywallSource.effect => 'Unlock every way to let go',
  PaywallSource.goal => 'Chase more than one thing',
  PaywallSource.moment =>
    burnLabel == null
        ? 'Keep this going'
        : 'You just protected $burnLabel',
};
