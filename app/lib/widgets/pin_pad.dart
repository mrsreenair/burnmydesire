import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';

const kPinLength = 4;

/// Row of dots showing how many PIN digits have been entered.
/// Shakes horizontally when [error] flips on — a physical "no".
class PinDots extends StatefulWidget {
  const PinDots({super.key, required this.filled, this.error = false});

  final int filled;
  final bool error;

  @override
  State<PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<PinDots> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );

  @override
  void didUpdateWidget(PinDots old) {
    super.didUpdateWidget(old);
    if (widget.error && !old.error) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        // Damped sine: three swings that die out.
        final t = _shake.value;
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < kPinLength; i++)
            AnimatedContainer(
              duration: Motion.instant,
              curve: Motion.spring,
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.error
                    ? scheme.error
                    : i < widget.filled
                    ? AppColors.ink
                    : AppColors.field,
              ),
            ),
        ],
      ),
    );
  }
}

/// Numeric keypad: digits 1–9, then [trailing | 0 | backspace].
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.trailing,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  /// Optional bottom-left slot (e.g. a Face ID button).
  final Widget? trailing;

  Widget _key(BuildContext context, Widget child, VoidCallback? onTap) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.4,
        child: onTap == null
            ? Center(child: child)
            : Padding(
                padding: const EdgeInsets.all(6),
                child: Container(
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: AppColors.paperHigh,
                    shadows: AppColors.cardShadow(opacity: 0.06),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onTap();
                      },
                      child: Center(child: child),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            children: [
              for (final d in row)
                _key(context, Text(d, style: style), () => onDigit(d)),
            ],
          ),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.4,
                child: Center(child: trailing ?? const SizedBox.shrink()),
              ),
            ),
            _key(context, Text('0', style: style), () => onDigit('0')),
            _key(context, const Icon(Icons.backspace_outlined), onDelete),
          ],
        ),
      ],
    );
  }
}
