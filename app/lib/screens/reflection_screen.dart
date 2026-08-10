import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/ai_coach.dart';
import '../data/reflection.dart';
import '../data/user_prefs.dart';
import '../models/burn_target.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';
import 'shock_screen.dart';

/// The purchase interview: three questions, then the mirror.
///
/// The AI (when the phone has one) asks; the user answers; at the end
/// their own words are reflected back and *they* choose — the same
/// growth-or-impulse choice the app has always had, now made informed.
/// "Just burn it" stays visible the whole way: reflection must never
/// stand between the user and the fire.
class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key, required this.target});

  /// A fresh capture — [BurnTarget.itemId] is null here by construction.
  final BurnTarget target;

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

enum _Stage { asking, thinking, mirror }

class _ReflectionScreenState extends State<ReflectionScreen> {
  final _answer = TextEditingController();
  final _qa = <ReflectionQA>[];

  var _stage = _Stage.asking;
  late String _question;
  String? _mirror;
  bool _aiOn = false;
  List<String> _weakSpots = const [];

  @override
  void initState() {
    super.initState();
    // The opener is always curated — it must appear instantly.
    _question = curatedQuestion(0, const []);
    aiCoachEnabled().then((on) async {
      final available = on && await AiCoach().isAvailable();
      if (mounted) setState(() => _aiOn = available);
    });
    savedSpendCategories().then((c) {
      if (mounted) _weakSpots = c;
    });
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  List<String> get _asked => [for (final qa in _qa) qa.question, _question];

  /// Submit the current answer (or skip with an empty one) and move on:
  /// next question, or the mirror after the last.
  Future<void> _next() async {
    final answer = _answer.text.trim();
    if (answer.isNotEmpty) {
      _qa.add(ReflectionQA(question: _question, answer: answer));
    }
    _answer.clear();

    final answered = _qa.length;
    final askedCount = _asked.length - (answer.isEmpty ? 1 : 0);
    if (answered >= kInterviewLength || askedCount >= kInterviewLength + 1) {
      await _finish();
      return;
    }

    // Curated next question is the guaranteed floor; the model may
    // replace it with one that builds on the actual answers. A short
    // timeout keeps the pause reflective, not annoying.
    final fallback = curatedQuestion(answered, _asked);
    setState(() {
      _stage = _Stage.thinking;
      _question = fallback;
    });
    if (_aiOn && _qa.isNotEmpty) {
      final generated = await AiCoach().generate(
        instructions: kInterviewInstructions,
        prompt: buildQuestionPrompt(
          priceLabel: formatMoney(widget.target.priceCents),
          soFar: _qa,
          weakSpots: _weakSpots,
        ),
        timeout: const Duration(seconds: 4),
        maxLength: 120,
      );
      if (!mounted) return;
      if (generated != null && !_asked.contains(generated)) {
        _question = generated;
      }
    }
    if (mounted) setState(() => _stage = _Stage.asking);
  }

  Future<void> _finish() async {
    if (_qa.isEmpty) {
      _go(growth: false);
      return;
    }
    setState(() => _stage = _Stage.thinking);
    String? mirror;
    if (_aiOn) {
      mirror = await AiCoach().generate(
        instructions: kMirrorInstructions,
        prompt: buildMirrorPrompt(
          priceLabel: formatMoney(widget.target.priceCents),
          answered: _qa,
        ),
        timeout: const Duration(seconds: 5),
        maxLength: 260,
      );
    }
    if (!mounted) return;
    setState(() {
      _mirror = mirror;
      _stage = _Stage.mirror;
    });
  }

  /// On to the shock card, carrying the interview so the item keeps it.
  void _go({required bool growth}) {
    final t = widget.target;
    Navigator.of(context).pushReplacement(
      emberRoute(
        ShockScreen(
          target: BurnTarget(
            image: t.image,
            imageBytes: t.imageBytes,
            priceCents: t.priceCents,
            plan: t.plan,
            category: t.category,
            reflection: List.unmodifiable(_qa),
          ),
          forGrowth: growth,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = (_qa.length + 1).clamp(1, kInterviewLength);
    return Scaffold(
      appBar: AppBar(title: const Text('Before you decide')),
      body: PaperBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ItemStrip(
                  image: widget.target.image,
                  priceLabel: formatMoney(widget.target.priceCents),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: Motion.base,
                    child: switch (_stage) {
                      _Stage.thinking => const Center(
                          key: ValueKey('thinking'),
                          child: CircularProgressIndicator(),
                        ),
                      _Stage.asking => _QuestionView(
                          key: ValueKey('q$step-$_question'),
                          step: step,
                          question: _question,
                          controller: _answer,
                          onSubmit: _next,
                        ),
                      _Stage.mirror => _MirrorView(
                          key: const ValueKey('mirror'),
                          qa: _qa,
                          aiMirror: _mirror,
                        ),
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (_stage == _Stage.mirror) ...[
                  EmberButton(
                    label: 'It\'s an impulse — burn it',
                    onPressed: () => _go(growth: false),
                  ),
                  TextButton(
                    onPressed: () => _go(growth: true),
                    child: const Text('It builds my future'),
                  ),
                ] else ...[
                  EmberButton(
                    label: 'Next',
                    onPressed: _stage == _Stage.asking ? _next : null,
                  ),
                  // The escape hatch. Always present, never punished.
                  TextButton(
                    onPressed: () => _go(growth: false),
                    child: Text(
                      'Just burn it',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The thing on trial: thumbnail and price, small and factual.
class _ItemStrip extends StatelessWidget {
  const _ItemStrip({required this.image, required this.priceLabel});

  final ui.Image image;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: RawImage(image: image, width: 56, height: 56, fit: BoxFit.cover),
        ),
        const SizedBox(width: 14),
        Text(
          priceLabel,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    super.key,
    required this.step,
    required this.question,
    required this.controller,
    required this.onSubmit,
  });

  final int step;
  final String question;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Question $step of $kInterviewLength',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMid,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        Text(question, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
          minLines: 1,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: const InputDecoration(
            hintText: 'Answer in your own words — or leave it blank',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

/// The user's answers, shown back. With AI: one warm paraphrase. Without:
/// their words verbatim — which is nearly as strong, because nobody
/// argues with their own words.
class _MirrorView extends StatelessWidget {
  const _MirrorView({super.key, required this.qa, this.aiMirror});

  final List<ReflectionQA> qa;
  final String? aiMirror;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('In your own words', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (aiMirror != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.washPeach.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(aiMirror!, style: theme.textTheme.titleMedium),
            )
          else
            for (final e in qa)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.question,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"${e.answer}"',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 12),
          Text(
            'Your call. It always was.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMid,
            ),
          ),
        ],
      ),
    );
  }
}
