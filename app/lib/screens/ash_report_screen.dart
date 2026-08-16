import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/weekly_report.dart';
import '../providers/currency_provider.dart';
import '../providers/db_providers.dart';
import '../providers/financial_goal_provider.dart';
import '../theme/app_colors.dart';
import '../utils/format_utils.dart';
import '../utils/milestone_card.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/share_milestone.dart';

/// The weekly Ash Report (GROWTH.md M4).
///
/// One screen, one number, three tiles, one line, one share. It exists to
/// be opened on a Sunday evening when nothing is pulling at the user —
/// the only kind of visit an interruption app doesn't get by default.
/// Everything on it is a count or an amount; nothing on it says what was
/// burned.
class AshReportScreen extends ConsumerWidget {
  const AshReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final report = ref.watch(weeklyReportProvider);
    final goal = ref.watch(financialGoalProvider).value;
    final protectedTotal = ref.watch(protectedCentsProvider);
    final thoughtsTotal = ref.watch(thoughtsBurnedProvider);
    final burnsTotal = ref.watch(itemsProvider).value?.length ?? 0;
    // Rebuild on a currency change: amounts on this screen come from a
    // pure summary that doesn't watch it.
    ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: PaperBackdrop(
        child: SafeArea(
          child: report == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  children: [
                    Reveal(
                      child: Text(
                        report.window.label,
                        style: theme.textTheme.displaySmall,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Reveal(
                      delay: const Duration(milliseconds: 40),
                      child: Text(
                        _range(report.window),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textMid,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Reveal(
                      delay: const Duration(milliseconds: 80),
                      child: _Headline(report: report),
                    ),
                    const SizedBox(height: 18),
                    Reveal(
                      delay: const Duration(milliseconds: 120),
                      child: Text(
                        weeklyReportLine(report),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textMid,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Reveal(
                      delay: const Duration(milliseconds: 160),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Tile(
                              value: '${report.burns}',
                              label: report.burns == 1 ? 'burn' : 'burns',
                              icon: Icons.local_fire_department,
                              tint: AppColors.ember,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Tile(
                              value: '${report.reBurns}',
                              label: 'came back',
                              icon: Icons.replay,
                              tint: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: goal != null && report.protectedCents > 0
                                ? _Tile(
                                    value: '+${report.goalGain}%',
                                    label: goal.name,
                                    icon: Icons.flag_outlined,
                                    tint: AppColors.money,
                                  )
                                : _Tile(
                                    value: '${report.thoughts}',
                                    label: report.thoughts == 1
                                        ? 'thought'
                                        : 'thoughts',
                                    icon: Icons.cloud_outlined,
                                    tint: AppColors.textMid,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // The share is the running total, not the week: a
                    // "€40 this week" card is a small brag; "€1,240
                    // protected, 31 % of the way to Japan" is the post.
                    if (protectedTotal > 0 || thoughtsTotal > 0)
                      Reveal(
                        delay: const Duration(milliseconds: 200),
                        child: ShareMilestone(
                          protectedCents: protectedTotal,
                          burns: burnsTotal,
                          thoughts: thoughtsTotal,
                          goal: goal == null || protectedTotal <= 0
                              ? null
                              : MilestoneGoal(
                                  name: goal.name,
                                  emoji: goal.emoji,
                                  percent: goal.percentOf(protectedTotal),
                                ),
                          format: CardFormat.story,
                          label: 'Share the week',
                        ),
                      ),
                    const SizedBox(height: 16),
                    Reveal(
                      delay: const Duration(milliseconds: 240),
                      child: Text(
                        'Counts and amounts only. What you burned stays '
                        'between you and the fire.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textLow,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  static String _range(ReportWindow w) {
    final last = w.end.subtract(const Duration(minutes: 1));
    final f = DateFormat('d MMM');
    return '${f.format(w.start)} – ${f.format(last)}';
  }
}

/// The one number. Money when there is money; burns when there isn't.
class _Headline extends StatelessWidget {
  const _Headline({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = report.protectedCents > 0;
    return Column(
      children: [
        Text(
          money ? 'Kept, not spent' : 'Let go of',
          style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textMid),
        ),
        const SizedBox(height: 6),
        if (money)
          ShaderMask(
            shaderCallback: (b) => AppColors.wealthGradient.createShader(b),
            blendMode: BlendMode.srcIn,
            child: CountUpText(
              report.protectedCents,
              formatter: formatMoney,
              style: theme.textTheme.displayLarge,
            ),
          )
        else
          GradientText(
            '${report.burns}',
            style: theme.textTheme.displayLarge,
          ),
        if (!money)
          Text(
            report.burns == 1 ? 'thing this week' : 'things this week',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textMid,
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.value,
    required this.label,
    required this.icon,
    required this.tint,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.paperHigh,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow(opacity: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tint),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMid,
            ),
          ),
        ],
      ),
    );
  }
}
