import 'package:flutter/material.dart';

import '../data/user_prefs.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/pin_pad.dart';
import 'goal_selection_screen.dart';

enum _Stage { name, createPin, confirmPin }

/// Local profile setup: a name and a PIN. No account, no server —
/// everything stays on the device.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  var _stage = _Stage.name;
  var _entry = '';
  String? _firstPin;
  String? _pinError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onDigit(String d) async {
    if (_entry.length >= kPinLength) return;
    setState(() {
      _entry += d;
      _pinError = null;
    });
    if (_entry.length < kPinLength) return;

    if (_stage == _Stage.createPin) {
      _firstPin = _entry;
      setState(() {
        _stage = _Stage.confirmPin;
        _entry = '';
      });
      return;
    }

    // Confirm stage.
    if (_entry == _firstPin) {
      await saveProfileName(_nameController.text);
      await savePin(_entry);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        emberRoute(const GoalSelectionScreen()),
      );
    } else {
      setState(() {
        _stage = _Stage.createPin;
        _entry = '';
        _firstPin = null;
        _pinError = 'PINs didn\'t match — try again';
      });
    }
  }

  void _onDelete() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: PaperBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedSwitcher(
              duration: Motion.base,
              switchInCurve: Motion.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.02),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_stage == _Stage.name),
                child: _stage == _Stage.name
                    ? _buildName(theme)
                    : _buildPin(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Canopi-style form: the question sits low, right above the field and
  /// the keyboard — one thought, one thumb-reach.
  Widget _buildName(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Reveal(
          child: Text('What should\nwe call you?',
              style: theme.textTheme.headlineMedium),
        ),
        const SizedBox(height: 8),
        Reveal(
          delay: const Duration(milliseconds: 80),
          child: Text('Just for greetings. Nothing leaves your phone.',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: AppColors.textMid)),
        ),
        const SizedBox(height: 20),
        Reveal(
          delay: const Duration(milliseconds: 140),
          child: TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: AppColors.ink),
            decoration: const InputDecoration(hintText: 'Your name'),
            onSubmitted: (_) => setState(() => _stage = _Stage.createPin),
          ),
        ),
        const SizedBox(height: 16),
        Reveal(
          delay: const Duration(milliseconds: 200),
          child: EmberButton(
            label: 'Continue',
            onPressed: () => setState(() => _stage = _Stage.createPin),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPin(ThemeData theme) {
    final creating = _stage == _Stage.createPin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        const Text('🔒',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 56)),
        const SizedBox(height: 24),
        Text(creating ? 'Create your PIN' : 'Confirm your PIN',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
            _pinError ??
                'Your desires are private. This PIN keeps them that way.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
                color: _pinError != null
                    ? theme.colorScheme.error
                    : AppColors.textMid)),
        const SizedBox(height: 32),
        PinDots(filled: _entry.length, error: _pinError != null),
        const Spacer(),
        PinPad(onDigit: _onDigit, onDelete: _onDelete),
      ],
    );
  }
}
