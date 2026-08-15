import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../data/ai_coach.dart';
import '../data/backup.dart';
import '../data/cloud_backup.dart';
import '../data/database.dart';
import '../data/image_store.dart';
import '../data/notification_prefs.dart';
import '../data/reflection.dart';
import '../data/user_prefs.dart';
import '../data/world_counter.dart';
import '../models/burn_target.dart';
import '../providers/db_providers.dart';
import '../providers/financial_goal_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/pro_provider.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import '../utils/milestone_card.dart';
import '../utils/motivation.dart';
import '../widgets/confetti.dart';
import '../widgets/ember_ui.dart';
import '../widgets/goal_progress.dart';
import '../widgets/share_milestone.dart';
import '../widgets/paper_backdrop.dart';

/// The payoff. Structured like a proper achievement screen: hero, earned
/// badge, one big headline, supporting line, pinned CTA — with a confetti
/// pop on arrival so the win registers before you read a word.
class VictoryScreen extends ConsumerStatefulWidget {
  const VictoryScreen({super.key, required this.target});

  final BurnTarget target;

  @override
  ConsumerState<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends ConsumerState<VictoryScreen> {
  /// AI-personalized encouragement, faded in over the curated one when
  /// the on-device model responds in time.
  String? _aiMessage;

  /// Whether this burn ends the desire forever: the user asked for it, or
  /// the streak reached the final-burn count.
  bool get _isFinal =>
      widget.target.letGoForever || widget.target.burnNumber >= kFinalBurnCount;

  /// Whether to show the one-time notification ask on this victory.
  bool _offerNotifications = false;

  /// Whether to show the one-time world-counter ask on this victory.
  bool _offerCounter = false;

  @override
  void initState() {
    super.initState();
    _persistBurn();
    _celebrate();
    if (widget.target.isEmotion && !_isFinal) _loadAiMessage();
    _checkAsks();
  }

  /// At most one ask per victory, notifications first.
  ///
  /// Two cards stacked under a win turns a celebration into a consent
  /// form; the counter simply waits for the next burn.
  Future<void> _checkAsks() async {
    if (!await notificationAskShown()) {
      if (mounted) setState(() => _offerNotifications = true);
      return;
    }
    await _checkCounterAsk();
  }

  /// The counter ask, put at the only moment it makes sense: just after
  /// someone protected money, when the number they'd be adding is real
  /// and in front of them. Never at launch, never in a settings list
  /// nobody scrolls to. Money burns only — a thought burned contributes
  /// nothing to a euro total, so asking would be noise.
  Future<void> _checkCounterAsk() async {
    if (!WorldCounter().configured) return;
    if (widget.target.isEmotion || widget.target.priceCents <= 0) return;
    if (await worldCounterOptIn()) return;
    if (await worldCounterAskShown()) return;
    if (mounted) setState(() => _offerCounter = true);
  }

  Future<void> _answerCounterAsk(bool wantsIn) async {
    await markWorldCounterAskShown();
    if (mounted) setState(() => _offerCounter = false);
    if (!wantsIn) return;
    await setWorldCounterOptIn(true);
    await WorldCounter()
        .contribute(ref.read(protectedCentsProvider))
        .catchError((Object _) => null);
  }

  /// The permission ask happens here — right after a win, never at
  /// launch (NOTIFICATIONS.md §5). Shown once, ever.
  Future<void> _answerNotificationAsk(bool wantsThem) async {
    await markNotificationAskShown();
    if (mounted) setState(() => _offerNotifications = false);
    if (!wantsThem) return;
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    if (!granted) return;
    final prefs = await loadNotificationPrefs();
    await saveNotificationPrefs(prefs.copyWith(enabled: true));
    if (mounted) await replanNotifications(ref);
  }

  /// Fire-and-forget: the curated message shows instantly; if Apple's
  /// on-device model answers, its personal line takes over. Silence on
  /// any failure — the celebration never waits for AI.
  Future<void> _loadAiMessage() async {
    if (!await aiCoachEnabled()) return;
    final goalIds = await savedBurnGoals();
    final labels = [
      for (final (id, label, _) in burnGoals)
        if (goalIds.contains(id)) label,
    ];
    final message = await AiCoach().encouragement(
      isEmotion: true,
      burnNumber: widget.target.burnNumber,
      goalLabels: labels,
      thought: widget.target.thoughtText,
    );
    if (mounted && message != null) setState(() => _aiMessage = message);
  }

  /// A double beat under the confetti — the physical half of the reward.
  Future<void> _celebrate() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 110));
    await HapticFeedback.lightImpact();
  }

  Future<void> _persistBurn() async {
    final db = ref.read(databaseProvider);
    final store = ref.read(imageStoreProvider);
    final target = widget.target;
    final int id;
    if (target.itemId != null) {
      await db.recordReBurn(target.itemId!);
      id = target.itemId!;
    } else {
      final file = await store.save(target.imageBytes);
      id = await db.insertBurnedItem(
        imageFile: file,
        priceCents: target.priceCents,
        monthlyCents: target.plan?.monthlyCents,
        months: target.plan?.months,
        category: target.category,
        reflectionJson: target.reflection.isEmpty
            ? null
            : encodeReflection(target.reflection),
      );
    }
    if (_isFinal) {
      // The final burn: delete the photo (the craving trigger), then
      // tombstone the row so the savings ledger survives.
      final item = await db.getItem(id);
      if (item.imageFile.isNotEmpty) await store.delete(item.imageFile);
      await db.markDestroyed(id);
    }
    _syncToCloud(db, store);
    // Opt-in only, and it checks that itself.
    WorldCounter()
        .contribute(ref.read(protectedCentsProvider))
        .catchError((Object _) => null);
    // Streaks and totals just changed; the pending schedule follows.
    if (mounted) await replanNotifications(ref);
  }

  /// Fire-and-forget iCloud backup once the burn is recorded. Silent by
  /// design: a failed sync must never intrude on the celebration, and the
  /// data is already safe on the device.
  void _syncToCloud(AppDatabase db, ImageStore store) {
    if (!ref.read(proProvider)) return;
    CloudBackup(
      BackupService(db, store),
    ).backUp().catchError((Object _) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = widget.target;
    final price = target.priceCents;
    final fund = ref.watch(defaultFundProvider);
    final future =
        fund?.projectedValueCents(price, kDefaultHorizonYears) ??
        futureValueCents(price, years: kDefaultHorizonYears);
    final again = target.burnNumber > 1;
    final goal = ref.watch(financialGoalProvider).value;
    final protected = ref.watch(protectedCentsProvider);

    final String badge;
    if (_isFinal) {
      badge = 'Destroyed forever';
    } else if (again) {
      badge = 'Resisted ${target.burnNumber}×';
    } else {
      badge = target.isEmotion ? 'Thought burned' : 'Desire destroyed';
    }

    return Scaffold(
      body: PaperBackdrop(
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),
                          const PopIn(child: _HeroMark()),
                          const SizedBox(height: 28),
                          PopIn(
                            delay: const Duration(milliseconds: 260),
                            from: 0.8,
                            child: BadgePill(
                              badge,
                              color: _isFinal
                                  ? AppColors.gold
                                  : target.isEmotion
                                  ? AppColors.accent
                                  : AppColors.money,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Reveal(
                            delay: const Duration(milliseconds: 340),
                            child: _isFinal
                                ? _FinalResult(target: target, price: price)
                                : target.isEmotion
                                ? _ThoughtResult(
                                    target: target,
                                    aiMessage: _aiMessage,
                                  )
                                : _MoneyResult(
                                    target: target,
                                    price: price,
                                    future: future,
                                  ),
                          ),
                          // The destination. Money burns only — telling
                          // someone their breakup burn brought a MacBook
                          // closer would be exactly the wrong note.
                          if (!target.isEmotion &&
                              price > 0 &&
                              goal != null) ...[
                            const SizedBox(height: 24),
                            Reveal(
                              delay: const Duration(milliseconds: 480),
                              child: GoalProgress(
                                goal: goal,
                                protectedCents: protected,
                              ),
                            ),
                          ],
                          // The share sits with the celebration, above
                          // the asks: this is the win, the rest is
                          // housekeeping. Free as well as Pro — the card
                          // is the advertisement.
                          if (protected > 0) ...[
                            const SizedBox(height: 24),
                            Reveal(
                              delay: const Duration(milliseconds: 500),
                              child: ShareMilestone(
                                protectedCents: protected,
                                burns:
                                    ref.watch(itemsProvider).value?.length ?? 1,
                                format: CardFormat.story,
                                label: 'Share this win',
                              ),
                            ),
                          ],
                          if (_offerNotifications) ...[
                            const SizedBox(height: 24),
                            Reveal(
                              delay: const Duration(milliseconds: 520),
                              child: _NotificationAsk(
                                onAnswer: _answerNotificationAsk,
                              ),
                            ),
                          ],
                          if (_offerCounter) ...[
                            const SizedBox(height: 24),
                            Reveal(
                              delay: const Duration(milliseconds: 520),
                              child: _CounterAsk(
                                protectedCents: protected,
                                onAnswer: _answerCounterAsk,
                              ),
                            ),
                          ],
                          // Only after a money burn, and only once the
                          // craving has passed — never mid-urge.
                          if (!target.isEmotion &&
                              price > 0 &&
                              kMoveMoneyUrl.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Reveal(
                              delay: const Duration(milliseconds: 560),
                              child: _MoveTheMoney(cents: price),
                            ),
                          ],
                          if (!target.isEmotion && !again && !_isFinal) ...[
                            const SizedBox(height: 20),
                            Reveal(
                              delay: const Duration(milliseconds: 520),
                              child: Text(
                                'Put it to work: a low-cost ETF at your '
                                'broker beats a gadget in a drawer.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textLow,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Withings-style pinned footer: hairline, then the pill.
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.hairline),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Reveal(
                      delay: const Duration(milliseconds: 600),
                      offset: 12,
                      child: EmberButton(
                        label: 'Back to home',
                        onPressed: () =>
                            Navigator.of(context).popUntil((r) => r.isFirst),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const ConfettiBurst(),
          ],
        ),
      ),
    );
  }
}

/// The illustration slot: the flame resting in a soft disc, the way an
/// achievement mark sits on these screens.
class _HeroMark extends StatelessWidget {
  const _HeroMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.washPeach.withValues(alpha: 0.9),
            AppColors.washPeach.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: const Text('🔥', style: TextStyle(fontSize: 60)),
    );
  }
}

/// The money payoff: the protected amount is the headline, counting up.
class _MoneyResult extends StatelessWidget {
  const _MoneyResult({
    required this.target,
    required this.price,
    required this.future,
  });

  final BurnTarget target;
  final int price;
  final int future;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final again = target.burnNumber > 1;
    return Column(
      children: [
        Text(
          again ? 'Still protected' : 'You just protected',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        ShaderMask(
          shaderCallback: (b) => AppColors.wealthGradient.createShader(b),
          blendMode: BlendMode.srcIn,
          child: CountUpText(
            price,
            formatter: formatMoney,
            duration: const Duration(milliseconds: 1400),
            style: theme.textTheme.displayMedium,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          again
              ? 'This one keeps trying. You keep winning.'
              : 'Invested, that\'s ${formatMoney(future)} '
                    'in $kDefaultHorizonYears years.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textMid,
          ),
        ),
      ],
    );
  }
}

/// The Final Burn: the desire is dead, the trigger is deleted, the money
/// stays counted forever.
class _FinalResult extends StatelessWidget {
  const _FinalResult({required this.target, required this.price});

  final BurnTarget target;
  final int price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'This desire is dead',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        if (!target.isEmotion) ...[
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (b) => AppColors.wealthGradient.createShader(b),
            blendMode: BlendMode.srcIn,
            child: CountUpText(
              price,
              formatter: formatMoney,
              duration: const Duration(milliseconds: 1400),
              style: theme.textTheme.displayMedium,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          target.isEmotion
              ? 'The page is gone for good — deleted, not stored. '
                    'What you burn stops owning you.'
              : 'The photo is deleted. It can\'t tempt you again — '
                    'and your ${formatMoney(price)} stays protected forever.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textMid,
          ),
        ),
      ],
    );
  }
}

/// Thoughts have no price — the headline is the closure, the body is the
/// encouragement. The curated line shows instantly; when the on-device
/// AI answers, its personal line cross-fades in.
class _ThoughtResult extends StatelessWidget {
  const _ThoughtResult({required this.target, this.aiMessage});

  final BurnTarget target;
  final String? aiMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message =
        aiMessage ??
        motivationMessage(
          resistanceCount: target.burnNumber,
          seed: target.itemId ?? target.imageBytes.length,
        );
    return Column(
      children: [
        Text(
          target.burnNumber > 1 ? 'Burned it again' : 'It\'s ash now',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: Text(
            message,
            key: ValueKey(message),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textMid,
            ),
          ),
        ),
      ],
    );
  }
}

/// The one-time notification ask, placed right after a win. Both answers
/// are final: declining is remembered, and Settings remains the way in.
class _NotificationAsk extends StatelessWidget {
  const _NotificationAsk({required this.onAnswer});

  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.washPeach.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Want a nudge when your streak is at risk?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A quiet reminder now and then. It never names what you\'re '
            'resisting — nothing anyone could read into over your shoulder.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onAnswer(false),
                  child: const Text('No thanks'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => onAnswer(true),
                  child: const Text('Remind me'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The world-counter ask.
///
/// Opt-in, asked once, and phrased so the answer is informed: it names
/// the exact number that would leave the phone and what does not go with
/// it. A default-on counter would collect more and mean less — the
/// figure is worth something precisely because everyone in it chose to
/// be there.
class _CounterAsk extends StatelessWidget {
  const _CounterAsk({required this.protectedCents, required this.onAnswer});

  final int protectedCents;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.washPeach.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Add your ${formatMoney(protectedCents)} to the world total?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'One number joins a public figure of what people have burned '
            'instead of bought. No name, no items, nothing that points '
            'back to you. You can turn it off in Settings.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onAnswer(false),
                  child: const Text('Keep it private'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => onAnswer(true),
                  child: const Text('Count mine'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The missing half of the loop: the app says "you protected €800", but
/// the money only really counts once it moves somewhere it grows. Shown
/// after the burn — never during the craving, when the user is in no
/// state to be sold anything.
class _MoveTheMoney extends StatelessWidget {
  const _MoveTheMoney({required this.cents});

  final int cents;

  Future<void> _open() async {
    final uri = Uri.parse(kMoveMoneyUrl).replace(
      queryParameters: {
        ...Uri.parse(kMoveMoneyUrl).queryParameters,
        'amount': (cents / 100).toStringAsFixed(2),
      },
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.money.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.money.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            'Move the ${formatMoney(cents)} somewhere it grows',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Resisting only counts if the money actually moves. '
            'Opens your provider — we never see your account.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textLow,
            ),
          ),
          const SizedBox(height: 14),
          EmberButton(label: 'Move it now', glow: false, onPressed: _open),
          const SizedBox(height: 8),
          Text(
            'We may earn a commission. It costs you nothing, and it never '
            'changes what the app tells you.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textLow,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
