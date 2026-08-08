import 'package:flutter/material.dart';

import '../data/user_prefs.dart';
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
        MaterialPageRoute(builder: (_) => const GoalSelectionScreen()),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              _stage == _Stage.name ? _buildName(theme) : _buildPin(theme),
        ),
      ),
    );
  }

  Widget _buildName(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text('👋', textAlign: TextAlign.center, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 24),
        Text('What should we call you?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Just for greetings. Nothing leaves your phone.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Your name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => setState(() => _stage = _Stage.createPin),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              minimumSize: const Size.fromHeight(56)),
          onPressed: () => setState(() => _stage = _Stage.createPin),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildPin(ThemeData theme) {
    final creating = _stage == _Stage.createPin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        const Text('🔒', textAlign: TextAlign.center, style: TextStyle(fontSize: 64)),
        const SizedBox(height: 24),
        Text(creating ? 'Create your PIN' : 'Confirm your PIN',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
            _pinError ??
                'Your desires are private. This PIN keeps them that way.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
                color: _pinError != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 32),
        PinDots(filled: _entry.length, error: _pinError != null),
        const Spacer(),
        PinPad(onDigit: _onDigit, onDelete: _onDelete),
      ],
    );
  }
}
