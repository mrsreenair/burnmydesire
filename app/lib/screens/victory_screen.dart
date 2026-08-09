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
import '../data/user_prefs.dart';
import '../data/world_counter.dart';
import '../models/burn_target.dart';
import '../providers/db_providers.dart';
import '../providers/financial_goal_provider.dart';
import '../providers/pro_provider.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import '../utils/motivation.dart';
import '../widgets/confetti.dart';
import '../widgets/ember_ui.dart';
import '../widgets/goal_progress.dart';
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

  @override
  void initState() {
    super.initState();
    _persistBurn();
    _celebrate();
    if (widget.target.isEmotion && !_isFinal) _loadAiMessage();
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
                          if (!target.isEmotion && price > 0 && goal != null) ...[
                            const SizedBox(height: 24),
                            Reveal(
                              delay: const Duration(milliseconds: 480),
                              child: GoalProgress(
                                goal: goal,
                                protectedCents: protected,
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
