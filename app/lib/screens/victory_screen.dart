import 'package:flutter/foundation.dart';
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
import '../data/plan_offer.dart';
import '../data/pro_moment.dart';
import '../data/reflection.dart';
import '../data/user_prefs.dart';
import '../data/world_counter.dart';
import '../models/burn_target.dart';
import '../providers/db_providers.dart';
import '../providers/financial_goal_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/pro_provider.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import '../utils/milestone_card.dart';
import '../utils/motivation.dart';
import '../widgets/confetti.dart';
import '../widgets/ember_ui.dart';
import '../widgets/goal_progress.dart';
import '../widgets/share_milestone.dart';
import '../widgets/paper_backdrop.dart';
import 'paywall_screen.dart';

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

  /// Whether to offer Pro on this victory (GROWTH.md M2). Lowest priority
  /// of the three cards, and only after a burn worth more than Pro.
  bool _offerPro = false;

  /// The row this burn wrote, so "I moved it" has something to mark.
  int? _itemId;

  /// Whether the user has confirmed the money actually went somewhere.
  bool _moved = false;

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
    // Read before bumping: "never on the first burn" means the first
    // victory this install has ever shown.
    final victoriesBefore = await victoriesSeen();
    await bumpVictoriesSeen();
    if (!await notificationAskShown()) {
      if (mounted) setState(() => _offerNotifications = true);
      return;
    }
    if (await _checkCounterNotice()) return;
    await _checkProMoment(victoriesBefore);
  }

  /// The Pro moment. Everything that decides it is a pure rule in
  /// pro_moment.dart; this just gathers the inputs and remembers the
  /// showing — on show, not on tap, so a "not now" is honoured.
  Future<void> _checkProMoment(int victoriesBefore) async {
    final now = DateTime.now();
    final due = ProMoment.eligible(
      burnCents: widget.target.priceCents,
      eurosPerUnit: activeCurrency.eurosPerUnit,
      isEmotion: widget.target.isEmotion,
      isPro: ref.read(proProvider),
      // Debug builds have the preview paywall; release needs a real store.
      storeAvailable: ref.read(purchasesConfiguredProvider) || kDebugMode,
      anotherAskShowing: _offerNotifications || _offerCounter,
      victoriesBefore: victoriesBefore,
      lastShownAt: await proMomentLastShown(),
      now: now,
    );
    if (!due) return;
    await markProMomentShown(now);
    if (mounted) setState(() => _offerPro = true);
  }

  /// The counter notice, put at the only moment it makes sense: just
  /// after a burn, when the number being counted is real and in front of
  /// them. Never at launch, never buried in a settings list.
  ///
  /// The counter is on by default now, so this is a disclosure rather
  /// than a request — but it is shown before anything is sent, and it
  /// carries the switch to stop it. Shown once, ever.
  Future<bool> _checkCounterNotice() async {
    if (!WorldCounter().configured) return false;
    final hasSomethingToAdd =
        widget.target.priceCents > 0 || widget.target.isEmotion;
    if (!hasSomethingToAdd) return false;
    if (await worldCounterAskShown()) return false;
    if (mounted) setState(() => _offerCounter = true);
    return true;
  }

  Future<void> _answerCounterAsk(bool stayIn) async {
    await markWorldCounterAskShown();
    if (mounted) setState(() => _offerCounter = false);
    await setWorldCounterOptIn(stayIn);
    if (!stayIn) return;
    await WorldCounter()
        .contribute(
          ref.read(protectedCentsProvider),
          ref.read(thoughtsBurnedProvider),
        )
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

  /// Records that the money really moved. Silent if the row hasn't
  /// landed yet — the toggle appears with the screen, the insert is a
  /// frame or two behind it.
  Future<void> _setMoved(bool moved) async {
    setState(() => _moved = moved);
    final id = _itemId;
    if (id == null) return;
    await ref.read(databaseProvider).setMoved(id, moved: moved);
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
    if (mounted) setState(() => _itemId = id);
    if (_isFinal) {
      // The final burn: delete the photo (the craving trigger), then
      // tombstone the row so the savings ledger survives.
      final item = await db.getItem(id);
      if (item.imageFile.isNotEmpty) await store.delete(item.imageFile);
      await db.markDestroyed(id);
    }
    _syncToCloud(db, store);
    // Nothing goes anywhere before the notice has been put in front of
    // them. On the very first burn the notice card does the sending
    // itself, once they have seen what it says.
    if (await worldCounterAskShown()) {
      WorldCounter()
          .contribute(
            ref.read(protectedCentsProvider),
            ref.read(thoughtsBurnedProvider),
          )
          .catchError((Object _) => null);
    }
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
                          if (protected > 0 ||
                              ref.watch(thoughtsBurnedProvider) > 0) ...[
                            const SizedBox(height: 24),
                            Reveal(
                              delay: const Duration(milliseconds: 500),
                              child: ShareMilestone(
                                protectedCents: protected,
                                burns:
                                    ref.watch(itemsProvider).value?.length ?? 1,
                                thoughts: ref.watch(thoughtsBurnedProvider),
                                // The goal line rides along on money burns
                                // only — same rule as the GoalProgress card
                                // above it.
                                goal:
                                    !target.isEmotion &&
                                        price > 0 &&
                                        goal != null
                                    ? MilestoneGoal(
                                        name: goal.name,
                                        emoji: goal.emoji,
                                        percent: goal.percentOf(protected),
                                      )
                                    : null,
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
                                thoughts: ref.watch(thoughtsBurnedProvider),
                                onAnswer: _answerCounterAsk,
                              ),
                            ),
                          ],
                          // The Pro moment: after the win, anchored to
                          // its number, dismissable, and rare (M2).
                          if (_offerPro) ...[
                            const SizedBox(height: 24),
                            Reveal(
                              delay: const Duration(milliseconds: 520),
                              child: _ProMomentCard(
                                cents: price,
                                onDismiss: () =>
                                    setState(() => _offerPro = false),
                                onSee: () {
                                  setState(() => _offerPro = false);
                                  Navigator.of(context).push(
                                    emberRoute(
                                      PaywallScreen(
                                        source: PaywallSource.moment,
                                        anchorCents: price,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          // A thought burn ends and the screen just…
                          // stops. Someone who has just let go of a
                          // craving or a person needs somewhere for the
                          // next ten minutes to go — that's the whole
                          // difference between a ritual and a tool.
                          if (target.isEmotion) ...[
                            const SizedBox(height: 24),
                            Reveal(
                              delay: const Duration(milliseconds: 540),
                              child: _Aftercare(seed: target.imageBytes.length),
                            ),
                          ],
                          // The claim the whole app rests on, checked.
                          // "Protected €150" is a story the user's bank
                          // balance doesn't tell unless the money really
                          // went somewhere it can't be spent.
                          if (!target.isEmotion && price > 0) ...[
                            const SizedBox(height: 24),
                            Reveal(
                              delay: const Duration(milliseconds: 540),
                              child: _MovedItCard(
                                cents: price,
                                moved: _moved,
                                onChanged: _setMoved,
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

/// The Pro offer, in the user's own number. No feature list — the
/// paywall has that. One sentence that's true, one that's honest about
/// what the plan is, two buttons of equal weight.
class _ProMomentCard extends StatelessWidget {
  const _ProMomentCard({
    required this.cents,
    required this.onDismiss,
    required this.onSee,
  });

  final int cents;
  final VoidCallback onDismiss;
  final VoidCallback onSee;

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
            'That one burn pays for Pro',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You just protected ${formatMoney(cents)}. Pro forever costs '
            'less than that — once, no renewal, and the burn stays free '
            'either way.',
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
                  onPressed: onDismiss,
                  child: const Text('Not now'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onSee,
                  child: const Text('See Pro'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The world-counter notice.
///
/// The counter is on by default, so this tells rather than asks — but it
/// tells before anything is sent, it names the exact numbers that will
/// leave the phone and what does not go with them, and the way out is a
/// button rather than a settings expedition.
class _CounterAsk extends StatelessWidget {
  const _CounterAsk({
    required this.protectedCents,
    required this.thoughts,
    required this.onAnswer,
  });

  final int protectedCents;
  final int thoughts;
  final ValueChanged<bool> onAnswer;

  /// Names whichever of the two totals the person actually has, so the
  /// notice never reports a figure that is zero.
  String get _headline {
    final money = formatMoney(protectedCents);
    final count = thoughts == 1 ? '1 thought' : '$thoughts thoughts';
    if (protectedCents > 0 && thoughts > 0) {
      return 'Your $money and $count join the world total';
    }
    if (thoughts > 0) return 'Your $count joins the world total';
    return 'Your $money joins the world total';
  }

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
            _headline,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'It joins a public tally of what people have burned instead of '
            'bought. No name, no items, nothing that points back to you. '
            'You can turn it off in Settings.',
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
                  child: const Text('Leave me out'),
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

/// "Did the money actually go somewhere?"
///
/// The app's headline claim is that resisting protects money. That's only
/// true if the money moves — otherwise it sits in the current account and
/// leaves on something else by Friday, and the total quietly becomes
/// fiction. Asking costs one tap and makes the number real.
///
/// Deliberately not a nag: unanswered means "resisted", which is still
/// worth counting. It just isn't the same fact as "saved".
class _MovedItCard extends StatelessWidget {
  const _MovedItCard({
    required this.cents,
    required this.moved,
    required this.onChanged,
  });

  final int cents;
  final bool moved;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(!moved),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: moved
              ? AppColors.money.withValues(alpha: 0.10)
              : AppColors.paperHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: moved
                ? AppColors.money.withValues(alpha: 0.5)
                : AppColors.hairline,
          ),
          boxShadow: moved ? null : AppColors.cardShadow(opacity: 0.05),
        ),
        child: Row(
          children: [
            Icon(
              moved ? Icons.check_circle_rounded : Icons.savings_outlined,
              color: moved ? AppColors.moneyDeep : AppColors.textLow,
              size: 26,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moved
                        ? 'Moved for real'
                        : 'Did you move the ${formatMoney(cents)}?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    moved
                        ? 'Counted as saved, not just resisted.'
                        : 'Tap if it went to savings or investments. '
                              'Money left in the account tends to leave.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMid,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What to do with the next ten minutes.
///
/// A burn ends and the screen stops, which is fine for a €200 gadget and
/// wrong for grief. The urge that brought someone here doesn't end with
/// the animation; it ends when something else fills the gap. These are
/// the three things every craving protocol agrees on — move, call
/// someone, breathe — and they're offered, never prescribed.
///
/// No links, no timers, no tracking whether it was done. The moment a
/// suggestion becomes a task the app is one more thing to fail at.
class _Aftercare extends StatelessWidget {
  const _Aftercare({required this.seed});

  /// Varies the opener between burns so it doesn't read as a form letter.
  final int seed;

  static const _openers = [
    'The urge passes faster with something in its place.',
    'Cravings peak and fade. Give this one somewhere to go.',
    'The next ten minutes are the ones that matter.',
  ];

  static const _ideas = [
    (Icons.directions_walk_rounded, 'Move', 'Ten minutes outside. Anywhere.'),
    (
      Icons.chat_bubble_outline_rounded,
      'Say it out loud',
      'Text one person what just happened.',
    ),
    (
      Icons.air_rounded,
      'Breathe',
      'Slow count of four, in and out, ten times.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.washMint.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What now?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _openers[seed.abs() % _openers.length],
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMid,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          for (final (icon, title, body) in _ideas)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.paperHigh,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 18, color: AppColors.moneyDeep),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          body,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
