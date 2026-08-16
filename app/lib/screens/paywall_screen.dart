import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../data/notification_planner.dart' show renewalReminderLeadDays;
import '../data/paywall_preview.dart';
import '../data/plan_offer.dart';
import '../providers/pro_provider.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/ember_ui.dart';
import '../widgets/trial_timeline.dart';

/// The paywall.
///
/// Built on what subscription apps that survive review actually do
/// (Monarch, Centr, Deezer, Deepstash, Wolt on Mobbin), then bent to fit
/// an app whose whole pitch is "stop paying for things forever":
///
///  * **Lifetime is the hero**, not the footnote (Peanut's structure, one
///    year's and timespent's tone). An app that teaches you to burn the
///    subscription you forgot to cancel can't lead with an auto-renewing
///    one — Gen Z would screenshot the irony into a review. So the
///    one-time plan sits on top, preselected, and says "no renewal, ever".
///  * Weekly plans are filtered out even if the store offers one.
///  * The subscriptions get an honesty block instead of a countdown:
///    the burn stays free, no fake discounts, cancel in one tap (a real
///    link to Apple's page), and a reminder before every renewal — which
///    the notification planner actually keeps.
///  * A trial timeline — today, the reminder, the charge — because the
///    only question between a person and a free trial is when they get
///    billed and whether they'll see it coming.
///  * The price is stated in a full sentence right above the button, and
///    the button says what will happen rather than "Continue".
///  * Terms and Privacy are linked. Guideline 3.1.2 requires it; leaving
///    them out is one of the most common rejections there is.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    super.key,
    this.embedded = false,
    this.headline,
    this.source = PaywallSource.general,
    this.anchorCents,
  });

  /// True when shown as a tab: no close button, and room for the tab bar.
  final bool embedded;

  /// Contextual opener ("You let go of 5 desires this month.") shown
  /// instead of the generic one when the paywall was reached by hitting
  /// a limit — the moment should acknowledge the win, not scold.
  final String? headline;

  /// Where the screen was opened from; picks the opening line.
  final PaywallSource source;

  /// The burn that led here (source == moment): lets the screen say
  /// "one burn already pays for it" with the user's own number.
  final int? anchorCents;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<Package> _packages = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  int _picked = 0;

  /// Showing sample plans because there's no store key. Debug only, and
  /// nothing here can be bought — see data/paywall_preview.dart.
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (kRevenueCatIosApiKey.isEmpty) {
      // No store, but the screen still has to be designable. In release
      // this branch is dead: kDebugMode is a compile-time constant.
      setState(() {
        if (kDebugMode) {
          _preview = true;
          _packages = _ordered(previewPackages());
          _picked = _bestValueIndex(_packages);
        }
        _loading = false;
      });
      return;
    }
    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? const [];
      if (!mounted) return;
      setState(() {
        _packages = _ordered(packages);
        // Land on the hero. Nobody arrives wanting to pay more, or longer.
        _picked = _bestValueIndex(_packages);
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Couldn\'t load plans. $e';
      });
    }
  }

  static PlanPeriod _period(Package p) =>
      planPeriodFrom(p.storeProduct.subscriptionPeriod);

  /// Lifetime, then annual, then monthly; weekly and anything unparseable
  /// dropped — regardless of how the dashboard lists them (plan_offer).
  static List<Package> _ordered(List<Package> packages) {
    final out = [
      for (final p in packages)
        if (offeredOnPaywall(_period(p))) p,
    ]..sort((a, b) => paywallRank(_period(a)).compareTo(paywallRank(_period(b))));
    return out;
  }

  static int _bestValueIndex(List<Package> packages) =>
      heroIndex([for (final p in packages) _period(p)]);

  Package? _first(PlanPeriod period) {
    for (final p in _packages) {
      if (_period(p) == period) return p;
    }
    return null;
  }

  /// The monthly plan's price, used to work out what annual saves.
  double? get _monthlyPrice => _first(PlanPeriod.monthly)?.storeProduct.price;

  /// The one line under the headline that ties Pro to the user's own
  /// number. Only says "one burn pays for it" when that's arithmetically
  /// true for the burn that brought them here.
  String? get _anchorLine {
    final cents = widget.anchorCents;
    final lifetime = _first(PlanPeriod.lifetime)?.storeProduct;
    if (cents == null || lifetime == null) return null;
    final times = burnsCoveringLifetime(
      burnCents: cents,
      lifetimePrice: lifetime.price,
    );
    if (times == null) return null;
    return times == 1
        ? 'That one burn already pays for Pro — forever.'
        : 'That one burn pays for Pro $times times over — forever.';
  }

  Future<void> _buy(Package package) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Trust the result's own customerInfo rather than reading the
      // provider straight after: the provider updates from a listener, so
      // checking it here is a race that silently swallows a real purchase.
      final result = await Purchases.purchase(PurchaseParams.package(package));
      if (!mounted) return;
      if (result.customerInfo.entitlements.active.containsKey(
        kProEntitlementId,
      )) {
        if (!widget.embedded) Navigator.of(context).pop();
        return;
      }
      setState(
        () => _error =
            'That went through, but Pro didn\'t unlock. Try '
            'Restore purchases.',
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final code = PurchasesErrorHelper.getErrorCode(e);
      // A cancel isn't an error; anything else deserves saying out loud.
      // Failing silently here means a tap that does nothing, which reads
      // as a broken app rather than a declined card.
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        setState(
          () => _error = e.message ?? 'The purchase didn\'t go through.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await Purchases.restorePurchases();
      if (!mounted) return;
      if (info.entitlements.active.containsKey(kProEntitlementId)) {
        if (!widget.embedded) Navigator.of(context).pop();
        return;
      }
      setState(() => _error = 'Nothing to restore on this Apple ID.');
    } on PlatformException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Restore failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configured = ref.watch(purchasesConfiguredProvider);
    final isPro = ref.watch(proProvider);

    final selected = _picked < _packages.length ? _packages[_picked] : null;
    final trialDays = selected == null
        ? null
        : trialDaysFrom(selected.storeProduct.introductoryPrice?.period);

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      extendBodyBehindAppBar: !widget.embedded,
      body: PaperBackdrop(
        child: SafeArea(
          bottom: !widget.embedded,
          child: ListView(
            padding: EdgeInsets.fromLTRB(24, 8, 24, widget.embedded ? 110 : 24),
            children: [
              const SizedBox(height: 8),
              const Reveal(
                child: Breathe(
                  child: Text(
                    '🔥',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 52),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Reveal(
                delay: const Duration(milliseconds: 80),
                child: GradientText(
                  isPro
                      ? 'You\'re Pro'
                      : paywallHeadline(
                          widget.source,
                          limitLine: widget.headline,
                          burnLabel: widget.anchorCents == null
                              ? null
                              : formatMoney(widget.anchorCents!),
                        ),
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              if (!isPro && _anchorLine != null) ...[
                const SizedBox(height: 8),
                Reveal(
                  delay: const Duration(milliseconds: 120),
                  child: Text(
                    _anchorLine!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              for (final (i, f) in const [
                ('♾️', 'Unlimited desires, every month'),
                ('🔥', 'Every burn effect, now and future'),
                ('📈', 'Custom return rates & horizons'),
                ('📊', 'Wealth-protected analytics & backup'),
              ].indexed)
                Reveal(
                  delay: Duration(milliseconds: 140 + 60 * i),
                  offset: 14,
                  child: _Feature(f.$1, f.$2),
                ),

              const SizedBox(height: 20),

              if (isPro)
                _Notice(
                  'Pro is active on this Apple ID. Thank you — the burn was '
                  'always free; you paid for the rest.',
                )
              else if (!configured && !_preview)
                const _SetupNotice()
              else if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_packages.isEmpty)
                _Notice(
                  _error ??
                      'No plans came back from the store. Check the offering '
                          'is live in RevenueCat and the products are '
                          '"Ready to Submit" in App Store Connect.',
                )
              else ...[
                for (final (i, p) in _packages.indexed) ...[
                  // The subscriptions sit under their own small heading,
                  // so the one-time plan above them reads as the offer
                  // and they read as the alternative — not the reverse.
                  if (i > 0 && _period(_packages[i - 1]) == PlanPeriod.lifetime)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
                      child: Text(
                        'or a subscription — cancel in one tap',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PlanCard(
                      package: p,
                      monthlyPrice: _monthlyPrice,
                      selected: i == _picked,
                      onTap: () => setState(() => _picked = i),
                    ),
                  ),
                ],

                const SizedBox(height: 4),
                _HonestyBlock(onManage: () => _open(kManageSubscriptionsUrl)),
                const SizedBox(height: 10),

                if (trialDays != null && selected != null) ...[
                  const SizedBox(height: 8),
                  TrialTimeline(
                    days: trialDays,
                    priceLine:
                        '${selected.storeProduct.priceString}'
                        '${_perLabel(selected)} starts. Cancel any time '
                        'before this.',
                  ),
                  const SizedBox(height: 14),
                ] else
                  const SizedBox(height: 6),

                if (selected != null)
                  Text(
                    _priceSentence(selected, trialDays),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMid,
                      height: 1.35,
                    ),
                  ),
                const SizedBox(height: 10),

                if (_preview) ...[
                  _Notice(
                    'Sample plans — this build has no store key, so nothing '
                    'here can be bought. Real prices come from App Store '
                    'Connect.',
                    tone: _Tone.warning,
                  ),
                  const SizedBox(height: 10),
                ],
                if (_error != null) ...[
                  _Notice(_error!, tone: _Tone.warning),
                  const SizedBox(height: 10),
                ],

                EmberButton(
                  label: _busy
                      ? 'One moment…'
                      : selected != null &&
                            _period(selected) == PlanPeriod.lifetime
                      ? 'Own Pro forever · ${selected.storeProduct.priceString}'
                      : trialDays != null
                      ? 'Start my $trialDays-day free trial'
                      : 'Unlock Pro',
                  kind: PillKind.fire,
                  onPressed: _busy || selected == null || _preview
                      ? null
                      : () => _buy(selected),
                ),
              ],

              if (configured && !isPro) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _busy ? null : _restore,
                  child: const Text('Restore purchases'),
                ),
              ],
              if (isPro) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => _open(kManageSubscriptionsUrl),
                  child: const Text('Manage or cancel'),
                ),
              ],

              // Required on any screen selling a subscription.
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _open(kTermsUrl),
                    child: const Text('Terms'),
                  ),
                  Text('·', style: TextStyle(color: AppColors.textLow)),
                  TextButton(
                    onPressed: kPrivacyUrl.isEmpty
                        ? null
                        : () => _open(kPrivacyUrl),
                    child: const Text('Privacy'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "/year", "/month" — the unit that follows a price.
  static String _perLabel(Package p) =>
      switch (planPeriodFrom(p.storeProduct.subscriptionPeriod)) {
        PlanPeriod.annual => '/year',
        PlanPeriod.monthly => '/month',
        PlanPeriod.weekly => '/week',
        PlanPeriod.lifetime => 'once',
        PlanPeriod.other => '',
      };

  /// The whole commitment in one sentence, directly above the button —
  /// what Deepstash puts at the top of its paywall. Everything here comes
  /// from the store's own localized strings, never a hardcoded price.
  static String _priceSentence(Package p, int? trialDays) {
    final price = '${p.storeProduct.priceString}${_perLabel(p)}';
    final period = planPeriodFrom(p.storeProduct.subscriptionPeriod);
    if (period == PlanPeriod.lifetime) {
      return '${p.storeProduct.priceString}, once. Yours forever — nothing '
          'renews, nothing to cancel.';
    }
    final renews =
        'Renews automatically until you cancel. We remind you '
        '$renewalReminderLeadDays days before each renewal (with '
        'notifications on), and cancelling is one tap on Apple\'s page.';
    return trialDays != null
        ? '$trialDays days free, then $price. $renews'
        : '$price. $renews';
  }
}

/// The three sentences that make the subscription honest — timespent's
/// "no dark patterns" letter, compressed. Shown for every plan, because
/// the person weighing lifetime against yearly is exactly who needs to
/// hear that the yearly one has an exit.
class _HonestyBlock extends StatelessWidget {
  const _HonestyBlock({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget line(String text, {VoidCallback? onTap}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.check, size: 16, color: AppColors.money),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onTap == null ? AppColors.textMid : AppColors.accent,
                  fontWeight: onTap == null ? null : FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.paperHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line('The burn stays free. Forever, for everyone.'),
          line('No countdown timers. No fake discounts.'),
          line('Cancel in one tap — Apple\'s page, no hoops.', onTap: onManage),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.emoji, this.label);

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.ember.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 19)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

enum _Tone { neutral, warning }

class _Notice extends StatelessWidget {
  const _Notice(this.text, {this.tone = _Tone.neutral});

  final String text;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final warn = tone == _Tone.warning;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warn
            ? AppColors.flame.withValues(alpha: 0.08)
            : AppColors.paperHigh,
        borderRadius: BorderRadius.circular(18),
        border: warn
            ? Border.all(color: AppColors.flame.withValues(alpha: 0.25))
            : null,
        boxShadow: warn ? null : AppColors.cardShadow(opacity: 0.05),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
      ),
    );
  }
}

/// What's still missing before purchases can work at all. Shown only in
/// builds without a RevenueCat key — which is every build until the key is
/// passed in — so the checklist lives where you'd look for it.
class _SetupNotice extends StatelessWidget {
  const _SetupNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paperHigh,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow(opacity: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Purchases aren\'t live in this build',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Everything Pro unlocks is open while there\'s no store key, so '
            'the app is fully usable — plans appear here once it\'s built '
            'with --dart-define=RC_IOS_KEY=appl_…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMid,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.package,
    required this.monthlyPrice,
    required this.selected,
    required this.onTap,
  });

  final Package package;

  /// The monthly plan's price, so annual can show what it saves.
  final double? monthlyPrice;

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = package.storeProduct;
    final period = planPeriodFrom(product.subscriptionPeriod);

    final hero = period == PlanPeriod.lifetime;

    final label = switch (period) {
      PlanPeriod.annual => 'Yearly',
      PlanPeriod.monthly => 'Monthly',
      PlanPeriod.weekly => 'Weekly',
      PlanPeriod.lifetime => 'Lifetime',
      PlanPeriod.other => product.title,
    };

    final savings = period == PlanPeriod.annual && monthlyPrice != null
        ? annualSavingsPercent(
            monthlyPrice: monthlyPrice!,
            annualPrice: product.price,
          )
        : null;

    // Per-month equivalent, formatted from the store's own currency
    // symbol rather than a guess at the user's locale.
    final symbol = product.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
    final subtitle = switch (period) {
      PlanPeriod.lifetime => 'One payment. No renewal, ever.',
      PlanPeriod.annual =>
        '$symbol${perMonthFromAnnual(product.price).toStringAsFixed(2)}'
            '/month, billed once a year',
      PlanPeriod.monthly => 'Billed monthly',
      _ => null,
    };

    final badge = hero
        ? 'ONE BURN PAYS FOR IT'
        : savings != null
        ? 'SAVE $savings%'
        : null;

    // The hero is drawn in fire so it reads as the offer; the
    // subscriptions in ink so they read as the alternative.
    final tint = hero ? AppColors.ember : AppColors.accent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(16, hero ? 18 : 14, 16, hero ? 18 : 14),
        decoration: BoxDecoration(
          color: selected ? tint.withValues(alpha: 0.10) : AppColors.paperHigh,
          borderRadius: BorderRadius.circular(hero ? 22 : 18),
          border: Border.all(
            color: selected ? tint : AppColors.ink.withValues(alpha: 0.06),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? null
              : AppColors.cardShadow(opacity: hero ? 0.09 : 0.05),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 22,
              color: selected ? tint : AppColors.textLow,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        label,
                        style:
                            (hero
                                    ? theme.textTheme.titleLarge
                                    : theme.textTheme.titleMedium)
                                ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (badge != null)
                        _PlanBadge(
                          badge,
                          color: hero ? AppColors.ember : AppColors.money,
                        ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              product.priceString,
              style:
                  (hero
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.titleMedium)
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: selected ? tint : AppColors.ink,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A plan's tag — compact enough to sit beside the plan name without
/// pushing the price off the card. The earned-achievement `BadgePill`
/// (star, generous padding) is right above a headline and wrong here.
class _PlanBadge extends StatelessWidget {
  const _PlanBadge(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}
