import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_colors.dart';
import '../utils/format_utils.dart';
import '../utils/milestone_card.dart';

/// The viral loop: the effect is the ad, so make the win trivially
/// shareable — without ever revealing what was resisted.
///
/// Free as well as Pro. Gating this behind the paywall put the
/// advertisement in front of the only people who had already bought.
class ShareMilestone extends StatefulWidget {
  const ShareMilestone({
    super.key,
    required this.protectedCents,
    required this.burns,
    this.thoughts = 0,
    this.goal,
    this.format = CardFormat.square,
    this.label = 'Share this win',
  });

  final int protectedCents;
  final int burns;

  /// Thoughts let go of — the headline when there's no money to show.
  final int thoughts;

  /// The destination, drawn as a goal line on money cards (M3).
  final MilestoneGoal? goal;

  /// Story from the victory screen, where people go straight to Instagram
  /// or TikTok; square from the dashboard, which is a review surface and
  /// more often shared into a message.
  final CardFormat format;
  final String label;

  @override
  State<ShareMilestone> createState() => _ShareMilestoneState();
}

class _ShareMilestoneState extends State<ShareMilestone> {
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await renderMilestoneCard(
        protectedCents: widget.protectedCents,
        burns: widget.burns,
        thoughts: widget.thoughts,
        goal: widget.goal,
        format: widget.format,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/burn-my-desire-${widget.format.name}.png');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: widget.protectedCents <= 0
              ? 'I let go of ${widget.thoughts} '
                    '${widget.thoughts == 1 ? 'thought' : 'thoughts'} by '
                    'burning ${widget.thoughts == 1 ? 'it' : 'them'}.'
              : widget.goal == null
              ? 'I protected ${formatMoney(widget.protectedCents)} by '
                    'burning what I wanted instead of buying it.'
              : 'I protected ${formatMoney(widget.protectedCents)} — '
                    '${widget.goal!.percent}% of the way to '
                    '${widget.goal!.emoji} ${widget.goal!.name} — by '
                    'burning what I wanted instead of buying it.',
        ),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t create the card.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _share,
        icon: Icon(_busy ? Icons.hourglass_empty : Icons.ios_share, size: 20),
        label: Text(_busy ? 'Preparing…' : widget.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
