import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../data/user_prefs.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/ember_ui.dart';
import '../widgets/pin_pad.dart';
import 'root_shell.dart';

/// PIN gate shown on launch. Face ID / Touch ID unlocks too; the PIN is
/// always available as fallback.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _auth = LocalAuthentication();
  var _entry = '';
  var _error = false;
  var _biometricsAvailable = false;
  String _name = '';

  @override
  void initState() {
    super.initState();
    profileName().then((n) {
      if (mounted) setState(() => _name = n);
    });
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!mounted) return;
      setState(() => _biometricsAvailable = supported && canCheck);
      if (_biometricsAvailable) await _tryBiometrics();
    } on LocalAuthException {
      // No biometrics (e.g. simulator without enrollment) — PIN still works.
    }
  }

  Future<void> _tryBiometrics() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Burn My Desire',
        biometricOnly: true,
      );
      if (ok) _unlock();
    } on LocalAuthException {
      // Fall through to PIN.
    }
  }

  void _unlock() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      emberRoute(const RootShell()),
    );
  }

  Future<void> _onDigit(String d) async {
    if (_entry.length >= kPinLength) return;
    setState(() {
      _entry += d;
      _error = false;
    });
    if (_entry.length < kPinLength) return;
    if (await verifyPin(_entry)) {
      _unlock();
    } else {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _entry = '';
          _error = true;
        });
      }
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
      body: PaperBackdrop(
        child: SafeArea(
          child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Reveal(
                child: Breathe(
                  child: Text('🔥',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 64)),
                ),
              ),
              const SizedBox(height: 24),
              Reveal(
                delay: const Duration(milliseconds: 80),
                child: Text(
                    _name.isEmpty ? 'Welcome back' : 'Welcome back, $_name',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: 8),
              Text(_error ? 'Wrong PIN — try again' : 'Enter your PIN',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: _error
                          ? theme.colorScheme.error
                          : AppColors.textMid)),
              const SizedBox(height: 32),
              PinDots(filled: _entry.length, error: _error),
              const Spacer(),
              PinPad(
                onDigit: _onDigit,
                onDelete: _onDelete,
                trailing: _biometricsAvailable
                    ? IconButton(
                        tooltip: 'Unlock with Face ID',
                        iconSize: 32,
                        icon: const Icon(Icons.face_retouching_natural),
                        onPressed: _tryBiometrics,
                      )
                    : null,
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
