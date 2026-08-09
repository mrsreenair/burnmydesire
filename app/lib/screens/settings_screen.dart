import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../data/ai_coach.dart';
import '../data/encrypted_db.dart';
import '../data/user_prefs.dart';
import '../providers/db_providers.dart';
import '../providers/pro_provider.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';
import 'lock_screen.dart';
import 'onboarding_screen.dart';

/// Settings. There is no account to manage — the app has no login by
/// design (PROJECT.md F7) — so the two session actions are "Lock now"
/// and the destructive "Erase everything".
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _name = '';
  bool _busy = false;
  bool _aiOn = true;

  /// null while we ask the platform whether Apple Intelligence is usable.
  bool? _aiReady;

  /// Raw platform status code behind [_aiStatusText].
  String? _aiStatus;

  /// Whether the database on disk is really encrypted.
  String? _dbSecurity;

  @override
  void initState() {
    super.initState();
    profileName().then((n) {
      if (mounted) setState(() => _name = n);
    });
    aiCoachEnabled().then((on) {
      if (mounted) setState(() => _aiOn = on);
    });
    AiCoach().isAvailable().then((ready) {
      if (mounted) setState(() => _aiReady = ready);
    });
    AiCoach().status().then((s) {
      if (mounted) setState(() => _aiStatus = s);
    });
    databaseSecurityReport().then((r) {
      if (mounted) setState(() => _dbSecurity = r);
    });
  }

  /// Plain-language explanation of the raw platform status code.
  String get _aiStatusText => switch (_aiStatus) {
        null => 'Checking…',
        'available' => 'Ready — your burns get personal messages',
        'apple_intelligence_off' =>
          'Apple Intelligence is off. Turn it on in iOS Settings → Apple '
              'Intelligence & Siri.',
        'model_downloading' =>
          'The model is still downloading. Try again once iOS finishes.',
        'device_not_eligible' =>
          'This iPhone doesn\'t support Apple Intelligence. You\'ll get '
              'the built-in encouragements instead.',
        'ios_too_old' => 'Needs iOS 26 or newer.',
        'framework_missing' =>
          'This build can\'t see Apple Intelligence (built with an older '
              'SDK).',
        'channel_missing' =>
          'The AI bridge didn\'t load — this is a bug, not a setting.',
        _ => 'Unavailable ($_aiStatus)',
      };

  Future<void> _toggleAi(bool on) async {
    setState(() => _aiOn = on);
    await setAiCoachEnabled(on);
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);
    final saved = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('What should we call you?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == null) return;
    await saveProfileName(saved);
    if (mounted) setState(() => _name = saved.trim());
  }

  void _lockNow() {
    Navigator.of(context).pushAndRemoveUntil(
      emberRoute(const LockScreen()),
      (route) => false,
    );
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await Purchases.restorePurchases();
    } on Exception {
      // Nothing to restore — silently fall through.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The real "delete my account" for a device-only app: everything goes.
  Future<void> _eraseEverything() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Erase everything?'),
        content: const Text(
          'This deletes every burned desire, every photo, your PIN and '
          'your setup — permanently. Your protected-wealth total goes '
          'back to zero. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Erase everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final store = ref.read(imageStoreProvider);
    await ref.read(databaseProvider).deleteAllItems();
    final dir = Directory('${store.documentsPath}/item_images');
    if (await dir.exists()) await dir.delete(recursive: true);
    await clearAllPrefs();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      emberRoute(const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPro = ref.watch(proProvider);
    final configured = ref.watch(purchasesConfiguredProvider);
    final goals = ref.watch(burnGoalsProvider).value ?? const [];

    return Scaffold(
      body: PaperBackdrop(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
            children: [
              Reveal(
                child: Text('Settings', style: theme.textTheme.displaySmall),
              ),
              const SizedBox(height: 24),
              Reveal(
                delay: const Duration(milliseconds: 60),
                child: _Group(
                  label: 'You',
                  children: [
                    _Row(
                      icon: Icons.person_outline,
                      title: 'Name',
                      trailing: _name.isEmpty ? 'Not set' : _name,
                      onTap: _editName,
                    ),
                    _Row(
                      icon: Icons.local_fire_department_outlined,
                      title: 'What you\'re burning',
                      trailing: '${goals.length} picked',
                      onTap: () => _showGoals(goals),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Reveal(
                delay: const Duration(milliseconds: 120),
                child: _Group(
                  label: 'Privacy',
                  children: [
                    _Row(
                      icon: Icons.lock_outline,
                      title: 'Lock now',
                      subtitle: 'Require your PIN or Face ID to get back in',
                      onTap: _lockNow,
                    ),
                    const _Row(
                      icon: Icons.phone_iphone,
                      title: 'Everything stays on this phone',
                      subtitle: 'No account, no server, no uploads — ever',
                    ),
                    _Row(
                      icon: Icons.shield_outlined,
                      title: 'Encrypted on this device',
                      subtitle: _dbSecurity == null
                          ? 'Checking…'
                          : '${_dbSecurity!}. Photos and written pages are '
                              'locked by iOS whenever your phone is locked. '
                              'The key lives in the Keychain and never '
                              'leaves this device.',
                    ),
                    _SwitchRow(
                      icon: Icons.auto_awesome_outlined,
                      title: 'AI encouragement',
                      subtitle: 'Personal messages from Apple\'s on-device '
                          'model. Runs on your phone — nothing is sent '
                          'anywhere.',
                      value: _aiOn,
                      onChanged: _toggleAi,
                    ),
                    _Row(
                      icon: _aiReady == true
                          ? Icons.check_circle_outline
                          : Icons.help_outline,
                      title: 'On-device model',
                      subtitle: AiCoach.lastError == null
                          ? _aiStatusText
                          : '$_aiStatusText\nLast burn: '
                              '${AiCoach.lastError}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Reveal(
                delay: const Duration(milliseconds: 180),
                child: _Group(
                  label: 'Pro',
                  children: [
                    _Row(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Subscription',
                      trailing: isPro ? 'Active' : 'Free',
                    ),
                    if (configured)
                      _Row(
                        icon: Icons.restore,
                        title: 'Restore purchases',
                        onTap: _busy ? null : _restore,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Reveal(
                delay: const Duration(milliseconds: 240),
                child: _Group(
                  label: 'About',
                  children: [
                    _Row(
                      icon: Icons.favorite_outline,
                      title: 'A ritual, not a treatment',
                      subtitle:
                          'If an addiction is hurting your health or your '
                          'life, talk to a doctor or therapist. Use this '
                          'app alongside real support, never instead of it.',
                    ),
                    const _Row(
                      icon: Icons.show_chart,
                      title: 'Projections are not advice',
                      subtitle:
                          'Based on historical market averages. Past '
                          'performance doesn\'t guarantee future results.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // The destructive action lives alone at the bottom, in red,
              // the way sign-out does on every settings screen.
              Reveal(
                delay: const Duration(milliseconds: 300),
                child: TextButton(
                  onPressed: _eraseEverything,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        theme.colorScheme.error.withValues(alpha: 0.07),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Erase everything',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Burn My Desire · v0.1.0',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textLow),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoals(List<String> ids) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What you\'re burning',
                  style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (id, label, emoji) in burnGoals)
                    if (ids.contains(id)) Chip(label: Text('$emoji  $label')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled card of rows — the standard iOS settings grouping.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textMid,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.paperHigh,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow(opacity: 0.06),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 56, color: AppColors.hairline),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A settings row with a trailing switch, matching _Row's layout.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: AppColors.textMid),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        theme.textTheme.titleSmall?.copyWith(fontSize: 15.5)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: AppColors.textMid),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontSize: 15.5)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                Text(trailing!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textMid)),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.textLow),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
