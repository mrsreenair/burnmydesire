import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// Fades + floats a child into place. Give siblings increasing [delay]
/// for the staggered-entrance rhythm used across the app.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.slow,
    this.offset = 24,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.easeOut,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Scales a child in with an overshoot, for things that should feel like
/// they *landed* — celebration heroes, earned badges.
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.slow,
    this.from = 0.6,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double from;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween(
      begin: widget.from,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Motion.spring));
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: widget.child),
    );
  }
}

/// The earned-achievement pill: tinted capsule with a star, set in small
/// caps above the headline.
class BadgePill extends StatelessWidget {
  const BadgePill(this.label, {super.key, this.color = AppColors.money});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 16, color: color),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// How a pill CTA is dressed.
enum PillKind {
  /// Black pill — the default Canopi-style action.
  ink,

  /// Orange fire pill — only for actions that lead to the burn.
  fire,
}

/// The primary CTA: a full pill with a press-down scale so every tap
/// feels physical. [PillKind.fire] adds the ember gradient + glow and is
/// reserved for burn-path actions.
class EmberButton extends StatefulWidget {
  const EmberButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.kind = PillKind.ink,
    this.glow = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final PillKind kind;
  final bool glow;

  @override
  State<EmberButton> createState() => _EmberButtonState();
}

class _EmberButtonState extends State<EmberButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fire = widget.kind == PillKind.fire;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      // Without this the pill is a decorated box to VoiceOver: it reads
      // the label as plain text and never says "button", so there is
      // nothing to tell a blind user it can be pressed.
      onTap: enabled ? widget.onPressed : null,
      child: GestureDetector(
        // The default, deferToChild, only counts a hit that lands on a
        // descendant that hit-tests — here, the glyphs of the label. The
        // black around them looks like part of the button and behaves
        // like background. Opaque makes the whole pill the target.
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                HapticFeedback.mediumImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1.0,
          duration: Motion.instant,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            duration: Motion.fast,
            opacity: enabled ? 1 : 0.35,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: fire ? null : AppColors.ink,
                gradient: fire ? AppColors.emberGradient : null,
                borderRadius: BorderRadius.circular(28),
                boxShadow: fire && widget.glow && enabled
                    ? AppColors.emberGlow(opacity: _down ? 0.2 : 0.32, blur: 24)
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Big numbers that count up into place — the shock lands harder when
/// the value grows in front of you.
class CountUpText extends StatelessWidget {
  const CountUpText(
    this.value, {
    super.key,
    required this.formatter,
    this.style,
    this.duration = Motion.reveal,
    this.curve = Motion.easeOut,
  });

  final int value;
  final String Function(int) formatter;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, v, _) =>
          Text(formatter(v.round()), textAlign: TextAlign.center, style: style),
    );
  }
}

/// Text filled with the ember gradient (for the shock number).
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = AppColors.emberGradient,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}

/// Slow breathing scale, for idle flames and glows.
class Breathe extends StatefulWidget {
  const Breathe({
    super.key,
    required this.child,
    this.min = 0.97,
    this.max = 1.03,
    this.period = const Duration(milliseconds: 2400),
  });

  final Widget child;
  final double min;
  final double max;
  final Duration period;

  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(
        begin: widget.min,
        end: widget.max,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// Section label used above lists ("BURN HISTORY", "WEAK SPOTS").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: AppColors.textLow,
      ),
    );
  }
}
