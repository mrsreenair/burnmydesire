import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import '../data/plan_offer.dart';
import '../data/database.dart';
import '../data/user_prefs.dart';
import '../data/reflection.dart';
import '../models/burn_target.dart';
import '../providers/currency_provider.dart';
import '../providers/db_providers.dart';
import '../providers/pro_provider.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/tilt_card.dart';
import 'burn_screen.dart';
import 'capture_screen.dart';
import 'paywall_screen.dart';
import 'profile_setup_screen.dart';
import 'shock_screen.dart';
import 'subscription_screen.dart';
import 'write_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _reBurn(
    BuildContext context,
    WidgetRef ref,
    Item item, {
    bool forever = false,
  }) async {
    final store = ref.read(imageStoreProvider);
    final bytes = await store.read(item.imageFile);
    final image = await decodeImageFromList(bytes);
    if (!context.mounted) return;
    final plan = item.monthlyCents != null && item.months != null
        ? InstallmentPlan(
            monthlyCents: item.monthlyCents!,
            months: item.months!,
          )
        : null;
    final target = BurnTarget(
      itemId: item.id,
      image: image,
      imageBytes: bytes,
      priceCents: item.priceCents,
      plan: plan,
      category: item.category,
      burnNumber: item.resistanceCount + 1,
      letGoForever: forever,
      // Last time's interview answers: the shock screen shows the user
      // their own words back.
      reflection: decodeReflection(item.reflectionJson),
    );
    // Thoughts have no price and a forever-burn is a release, not a
    // decision: both skip the shock card and go straight to the fire.
    Navigator.of(context).push(
      target.isEmotion || forever
          ? fireRoute(BurnScreen(target: target))
          : emberRoute(ShockScreen(target: target)),
    );
  }

  /// The follow-up answer. "Yes, I bought it" pulls the money back out of
  /// the protected total; "no" just stops the asking by counting as the
  /// most recent word on it.
  Future<void> _answerFollowUp(WidgetRef ref, Item item, bool bought) async {
    final db = ref.read(databaseProvider);
    if (bought) {
      await db.markBought(item.id);
    } else {
      // Re-stamp the burn so the fourteen-day clock restarts rather than
      // asking again tomorrow.
      await db.recordFollowUpResisted(item.id);
    }
  }

  /// Long-press: end the desire now instead of waiting for burn three.
  Future<void> _confirmForever(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    final isThought = item.category == 'emotion';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Let it go forever?'),
        content: Text(
          isThought
              ? 'One last burn. The page is deleted for good and this '
                    'thought leaves your list.'
              : 'One last burn. The photo is deleted for good and this '
                    'desire leaves your list — the '
                    '${formatMoney(item.priceCents)} stays protected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Final burn'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await _reBurn(context, ref, item, forever: true);
    }
  }

  /// The capture gate. Blocked users land on the paywall with an opener
  /// that names their win, not their limit — capping never blocks
  /// re-burns, only NEW captures (PROJECT.md §4.5).
  Widget _gateOr(WidgetRef ref, Widget destination) {
    return switch (ref.read(addBlockProvider)) {
      AddBlock.none => destination,
      AddBlock.liveLimit => const PaywallScreen(
        source: PaywallSource.limit,
        headline: 'Three desires in the fight.\nGo unlimited?',
      ),
      AddBlock.monthlyLimit => PaywallScreen(
        source: PaywallSource.limit,
        headline:
            'You let go of $kFreeMonthlyNewItems desires '
            'this month.',
      ),
    };
  }

  void _chooseBurnType(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textLow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'What\'s pulling at you?',
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              _SheetChoice(
                emoji: '🛍️',
                title: 'Burn a purchase',
                subtitle: 'Photo + price — see the real damage',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(
                    context,
                  ).push(emberRoute(_gateOr(ref, const CaptureScreen())));
                },
              ),
              const SizedBox(height: 12),
              _SheetChoice(
                emoji: '🔁',
                title: 'Burn a subscription',
                subtitle: 'The one you meant to cancel — see the real total',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(
                    context,
                  ).push(emberRoute(_gateOr(ref, const SubscriptionScreen())));
                },
              ),
              const SizedBox(height: 12),
              _SheetChoice(
                emoji: '✍️',
                title: 'Burn a thought',
                subtitle: 'Write the craving or feeling — burn the paper',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(
                    context,
                  ).push(emberRoute(_gateOr(ref, const WriteScreen())));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(liveItemsProvider);
    final protected = ref.watch(protectedCentsProvider);
    // One at a time, oldest first: a stack of confessions to work through
    // would feel like an audit, not a check-in.
    final pending = ref.watch(needsFollowUpProvider);
    final followUp = pending.isEmpty
        ? null
        : (pending.toList()
                ..sort((a, b) => a.lastBurnedAt!.compareTo(b.lastBurnedAt!)))
              .first;
    // Rebuild when the currency changes — this screen sits in the tab
    // stack, so nothing else would repaint its amounts.
    ref.watch(currencyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: PaperBackdrop(
        child: SafeArea(
          // The tab bar floats over the body; content clears it itself.
          bottom: false,
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 190),
                children: [
                  // Canopi editorial header: quiet date, then the title.
                  Reveal(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEE d MMM').format(DateTime.now()),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Desires', style: theme.textTheme.displaySmall),
                      ],
                    ),
                  ),
                  // Setup, offered once there's something to protect —
                  // the PIN in particular means nothing before the first
                  // burn, because there's no data behind it yet.
                  if (items.isNotEmpty)
                    _DeferredSetupCard(
                      onStart: () => Navigator.of(
                        context,
                      ).push(emberRoute(const ProfileSetupScreen())),
                    ),
                  // The question nobody asks: did resisting actually
                  // stick? Two weeks on, one tap makes the total true.
                  if (followUp != null) ...[
                    const SizedBox(height: 20),
                    Reveal(
                      delay: const Duration(milliseconds: 40),
                      child: _FollowUpCard(
                        item: followUp,
                        onAnswer: (bought) =>
                            _answerFollowUp(ref, followUp, bought),
                      ),
                    ),
                  ],
                  if (protected > 0) ...[
                    const SizedBox(height: 20),
                    Reveal(
                      delay: const Duration(milliseconds: 60),
                      child: _WealthHero(protected: protected),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Reveal(
                        delay: Duration(milliseconds: 120),
                        child: _EmptyState(),
                      ),
                    )
                  else
                    for (final (i, item) in items.indexed)
                      Reveal(
                        delay: Duration(milliseconds: 120 + 60 * i),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: _ItemCollage(
                            item: item,
                            tiltSeed: i,
                            onTap: () => _reBurn(context, ref, item),
                            onLongPress: () =>
                                _confirmForever(context, ref, item),
                          ),
                        ),
                      ),
                ],
              ),
              // Orange fire FAB, Canopi-style circle — floats just above
              // the tab bar rather than on the screen edge.
              if (items.isNotEmpty)
                Positioned(
                  right: 24,
                  bottom: 124,
                  child: Reveal(
                    delay: const Duration(milliseconds: 200),
                    child: _FireFab(
                      onPressed: () => _chooseBurnType(context, ref),
                    ),
                  ),
                ),
              if (items.isEmpty)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 124,
                  child: Reveal(
                    delay: const Duration(milliseconds: 260),
                    child: EmberButton(
                      label: 'Burn something',
                      icon: Icons.local_fire_department,
                      kind: PillKind.fire,
                      onPressed: () => _chooseBurnType(context, ref),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Protected wealth as quiet editorial text — money is a state, not a
/// billboard. Green number, gray projection line.
class _WealthHero extends StatelessWidget {
  const _WealthHero({required this.protected});

  final int protected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ShaderMask(
          shaderCallback: (b) => AppColors.wealthGradient.createShader(b),
          blendMode: BlendMode.srcIn,
          child: CountUpText(
            protected,
            formatter: formatMoney,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            'protected · '
            '${formatMoney(futureValueCents(protected, years: kDefaultHorizonYears))} '
            'in ${kDefaultHorizonYears}y',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMid,
            ),
          ),
        ),
      ],
    );
  }
}

/// One temptation as a Canopi collection row: resistance label, then a
/// small collage — photo card + a note card, gently tilted.
class _ItemCollage extends ConsumerWidget {
  const _ItemCollage({
    required this.item,
    required this.tiltSeed,
    required this.onTap,
    required this.onLongPress,
  });

  final Item item;
  final int tiltSeed;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(imageStoreProvider);
    final theme = Theme.of(context);
    final isThought = item.category == 'emotion';
    // Alternate tilt direction row by row so the page feels hand-laid.
    final dir = tiltSeed.isEven ? 1.0 : -1.0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resisted ${item.resistanceCount}×',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isThought ? 'A thought you let go' : formatMoney(item.priceCents),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // The photo (or thought) as a tilted polaroid.
              TiltCard(
                tiltDegrees: -2.0 * dir,
                child: Image.file(
                  store.file(item.imageFile),
                  width: 96,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 96,
                    height: 110,
                    color: AppColors.field,
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppColors.textLow,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              // A sticky-note card carrying the re-burn nudge. One burn
              // from the final-burn threshold, it becomes a warning label.
              TiltCard(
                tiltDegrees: 1.6 * dir,
                color: isThought ? AppColors.sticky : AppColors.paperHigh,
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: 130,
                  height: 82,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 6),
                      Text(
                        item.resistanceCount >= kFinalBurnCount - 1
                            ? 'One more burn and\nit\'s gone forever.'
                            : 'Tap to burn again.\nHold to end it now.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isThought
                              ? AppColors.stickyInk
                              : AppColors.textMid,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const CardFan(
          cards: [
            Text('🛍️', style: TextStyle(fontSize: 26)),
            Text('🔥', style: TextStyle(fontSize: 26)),
            Text('✍️', style: TextStyle(fontSize: 26)),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Craving something you shouldn\'t?\nBring it here before it owns you.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textMid,
          ),
        ),
      ],
    );
  }
}

class _FireFab extends StatelessWidget {
  const _FireFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: AppColors.accent,
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppColors.emberGlow(opacity: 0.3, blur: 20),
          ),
          child: const Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _SheetChoice extends StatelessWidget {
  const _SheetChoice({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.paperHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow(opacity: 0.06),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLow),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Did you buy it in the end?"
///
/// The app otherwise assumes every burn is a permanent saving, which
/// users know isn't true — and a total that can only rise stops meaning
/// anything. Asking two weeks later costs one tap, makes the number
/// honest, and is a real reason to open the app again.
///
/// Framed without judgement on purpose. An app about self-compassion for
/// craving cannot punish the honest answer, or it only ever gets the
/// other one.
class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({required this.item, required this.onAnswer});

  final Item item;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeks = DateTime.now().difference(item.lastBurnedAt!).inDays ~/ 7;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.washPeach.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weeks < 1
                ? 'You burned this recently'
                : 'You burned this $weeks week${weeks == 1 ? '' : 's'} ago',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Did you end up buying it?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Honest either way — it just keeps your total true.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => onAnswer(true),
                  child: const Text('I bought it'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: () => onAnswer(false),
                  child: const Text('Still resisted'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Finish setting up" — the name, PIN, currency and goals that used to
/// stand between install and the first burn.
///
/// Appears only once something has been burned, which is also the first
/// moment any of it means anything: a PIN protects data, and until now
/// there wasn't any. Dismissible, and it never comes back — this is an
/// offer, not a chore list.
class _DeferredSetupCard extends StatefulWidget {
  const _DeferredSetupCard({required this.onStart});

  final VoidCallback onStart;

  @override
  State<_DeferredSetupCard> createState() => _DeferredSetupCardState();
}

class _DeferredSetupCardState extends State<_DeferredSetupCard> {
  /// null while we're still asking the prefs whether to show at all.
  bool? _show;

  @override
  void initState() {
    super.initState();
    deferredSetupDone().then((done) {
      if (mounted) setState(() => _show = !done);
    });
  }

  Future<void> _dismiss() async {
    setState(() => _show = false);
    await markDeferredSetupDone();
  }

  @override
  Widget build(BuildContext context) {
    if (_show != true) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.paperHigh,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.cardShadow(opacity: 0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.textMid),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lock this behind a PIN?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'You\'ve got something worth keeping private now. Takes a '
              'minute: a PIN, your currency, and what you\'re saving for.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMid,
                height: 1.35,
              ),
            ),
            Row(
              children: [
                TextButton(onPressed: _dismiss, child: const Text('Not now')),
                const Spacer(),
                FilledButton(
                  onPressed: widget.onStart,
                  child: const Text('Set it up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
