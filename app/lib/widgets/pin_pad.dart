import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const kPinLength = 4;

/// Row of dots showing how many PIN digits have been entered.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.filled, this.error = false});

  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < kPinLength; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: error
                  ? scheme.error
                  : i < filled
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
            ),
          ),
      ],
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
            : InkResponse(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap();
                },
                child: Center(child: child),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .headlineSmall
        ?.copyWith(fontWeight: FontWeight.w600);
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
            _key(context, trailing ?? const SizedBox.shrink(), null),
            _key(context, Text('0', style: style), () => onDigit('0')),
            _key(context, const Icon(Icons.backspace_outlined), onDelete),
          ],
        ),
      ],
    );
  }
}
