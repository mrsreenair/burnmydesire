import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../data/ai_coach.dart';
import '../data/backup.dart';
import '../data/burn_effects.dart';
import '../data/cloud_backup.dart';
import '../data/document_picker.dart';
import '../data/encrypted_db.dart';
import '../data/user_prefs.dart';
import '../data/world_counter.dart';
import '../utils/format_utils.dart';
import '../providers/burn_effect_provider.dart';
import '../providers/db_providers.dart';
import '../providers/pro_provider.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';
import 'lock_screen.dart';
import 'paywall_screen.dart';
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
  bool _soundOn = true;

  /// null while we ask the platform whether Apple Intelligence is usable.
  bool? _aiReady;

  /// Raw platform status code behind [_aiStatusText].
  String? _aiStatus;

  /// Whether the database on disk is really encrypted.
  String? _dbSecurity;

  /// iCloud availability and the time of the stored backup.
  CloudStatus? _cloudStatus;
  DateTime? _lastCloudBackup;

  /// Opt-in to the anonymous world counter, and the last totals seen.
  bool _counterOptIn = false;
  WorldStats? _worldStats;

  @override
  void initState() {
    super.initState();
    profileName().then((n) {
      if (mounted) setState(() => _name = n);
    });
    aiCoachEnabled().then((on) {
      if (mounted) setState(() => _aiOn = on);
    });
    burnSoundEnabled().then((on) {
      if (mounted) setState(() => _soundOn = on);
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
    _refreshCloud();
    worldCounterOptIn().then((on) {
      if (mounted) setState(() => _counterOptIn = on);
    });
    WorldCounter().stats().then((s) {
      if (mounted) setState(() => _worldStats = s);
    });
  }

  /// Turning this on sends one number: how much the protected total has
  /// grown since last time. Turning it off stops all sending; what was
  /// already counted stays counted, since it can't be traced back.
  Future<void> _toggleCounter(bool on) async {
    setState(() => _counterOptIn = on);
    await setWorldCounterOptIn(on);
    if (!on) return;
    final stats = await WorldCounter().contribute(
      ref.read(protectedCentsProvider),
    );
    if (mounted && stats != null) setState(() => _worldStats = stats);
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

  Future<void> _toggleSound(bool on) async {
    setState(() => _soundOn = on);
    await setBurnSoundEnabled(on);
  }

  /// Asks for a passphrase. The same sheet serves export and import, so
  /// the wording changes but the rules don't.
  Future<String?> _askPassphrase({required bool forExport}) async {
    final controller = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(forExport ? 'Protect your backup' : 'Unlock backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                forExport
                    ? 'Pick a passphrase. It encrypts the file — without it '
                          'nobody, including us, can open your backup. If you '
                          'lose it the backup is gone for good.'
                    : 'Enter the passphrase you used when you made this '
                          'backup.',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Passphrase',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text;
                final problem = forExport ? passphraseProblem(value) : null;
                if (problem != null || value.isEmpty) {
                  setDialogState(
                    () => error = problem ?? 'Enter your passphrase',
                  );
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: Text(forExport ? 'Create backup' : 'Restore'),
            ),
          ],
        ),
      ),
    );
  }

  CloudBackup _cloud() => CloudBackup(
    BackupService(ref.read(databaseProvider), ref.read(imageStoreProvider)),
  );

  Future<void> _refreshCloud() async {
    final cloud = _cloud();
    final status = await cloud.status();
    final last = await cloud.lastBackup();
    if (mounted) {
      setState(() {
        _cloudStatus = status;
        _lastCloudBackup = last;
      });
    }
  }

  /// What the iCloud row says, in the user's terms.
  String get _cloudSubtitle {
    switch (_cloudStatus) {
      case null:
        return 'Checking…';
      case CloudStatus.signedOut:
        return 'Sign in to iCloud in iOS Settings to back up automatically.';
      case CloudStatus.noContainer:
      case CloudStatus.unsupported:
        return 'iCloud backup isn\'t enabled in this build yet. Use the '
            'encrypted file backup below.';
      case CloudStatus.available:
        final when = _lastCloudBackup;
        return when == null
            ? 'Encrypted with your passphrase before it leaves the phone — '
                  'Apple can\'t read it either.'
            : 'Last backup ${DateFormat.yMMMd().add_jm().format(when)}. '
                  'Encrypted with your passphrase before it leaves the phone.';
    }
  }

  Future<void> _backUpToCloud() async {
    var pass = await cloudPassphrase();
    pass ??= await _askPassphrase(forExport: true);
    if (pass == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await saveCloudPassphrase(pass);
      final ok = await _cloud().backUp(passphrase: pass);
      _toast(
        ok ? 'Backed up to iCloud.' : 'iCloud isn\'t available right now.',
      );
      await _refreshCloud();
    } on BackupException catch (e) {
      _toast(e.message);
    } on Object catch (e) {
      _toast('iCloud backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromCloud() async {
    final confirmed = await _confirmReplace();
    if (confirmed != true || !mounted) return;
    final pass =
        await cloudPassphrase() ?? await _askPassphrase(forExport: false);
    if (pass == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final restored = await _cloud().restore(passphrase: pass);
      _toast(
        restored == null
            ? 'No iCloud backup found yet.'
            : 'Restored $restored ${restored == 1 ? 'desire' : 'desires'}.',
      );
    } on BackupException catch (e) {
      _toast(e.message);
    } on Object catch (e) {
      _toast('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmReplace() => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Restore from backup?'),
      content: const Text(
        'This replaces every desire currently on this phone with the '
        'ones in the backup. Your current data is deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Restore'),
        ),
      ],
    ),
  );

  Future<void> _exportBackup() async {
    final passphrase = await _askPassphrase(forExport: true);
    if (passphrase == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final store = ref.read(imageStoreProvider);
      final dir = await getTemporaryDirectory();
      final file = await BackupService(
        ref.read(databaseProvider),
        store,
      ).export(passphrase: passphrase, destinationDir: dir.path);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Burn My Desire backup (encrypted)',
        ),
      );
    } on Object catch (e) {
      _toast('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup() async {
    final confirmed = await _confirmReplace();
    if (confirmed != true || !mounted) return;

    final path = await DocumentPicker().pickFile();
    if (path == null || !mounted) return;

    final passphrase = await _askPassphrase(forExport: false);
    if (passphrase == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final restored = await BackupService(
        ref.read(databaseProvider),
        ref.read(imageStoreProvider),
      ).import(path: path, passphrase: passphrase);
      _toast('Restored $restored ${restored == 1 ? 'desire' : 'desires'}.');
    } on BackupException catch (e) {
      _toast(e.message);
    } on Object catch (e) {
      _toast('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    Navigator.of(
      context,
    ).pushAndRemoveUntil(emberRoute(const LockScreen()), (route) => false);
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
          'This deletes every burned desire, every photo, your PIN, your '
          'setup and your iCloud backup — permanently. Your '
          'protected-wealth total goes back to zero. This cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Erase everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final store = ref.read(imageStoreProvider);
    // Erasing must reach the iCloud copy too, or "erase everything" would
    // leave a full backup sitting in the cloud.
    await _cloud().deleteCloudCopy();
    await clearCloudPassphrase();
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
    final effect = ref.watch(burnEffectProvider);

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
                    _Row(
                      icon: Icons.currency_exchange_outlined,
                      title: 'Currency',
                      subtitle: 'Changes how amounts are written. Your '
                          'saved numbers stay as they are.',
                      trailing:
                          '${currency.flag} ${currency.code}',
                      onTap: _showCurrencies,
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
                    if (WorldCounter().configured)
                      _SwitchRow(
                        icon: Icons.public_outlined,
                        title: 'Add my total to the world counter',
                        subtitle: _counterOptIn
                            ? _worldStats == null
                                  ? 'Sends one number: how much your protected '
                                        'total grew. Nothing else — no name, no '
                                        'items, nothing traceable.'
                                  : '${formatMoney(_worldStats!.totalCents)} '
                                        'burned by '
                                        '${_worldStats!.contributors} people so '
                                        'far. Only a single number ever leaves '
                                        'your phone.'
                            : 'Off. Turn on to add your protected total to '
                                  'the public figure — one number, nothing '
                                  'that identifies you.',
                        value: _counterOptIn,
                        onChanged: _toggleCounter,
                      ),
                    _SwitchRow(
                      icon: Icons.auto_awesome_outlined,
                      title: 'AI encouragement',
                      subtitle:
                          'Personal messages from Apple\'s on-device '
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
              // Sound isn't a Pro feature, so it doesn't live in the Pro
              // group — but it belongs next to the effect, since the two
              // together are what the ritual feels like.
              Reveal(
                delay: const Duration(milliseconds: 150),
                child: _Group(
                  label: 'The ritual',
                  children: [
                    _SwitchRow(
                      icon: Icons.volume_up_outlined,
                      title: 'Burn sound',
                      subtitle: _soundOn
                          ? 'Plays even when your phone is on silent, so '
                                'turn it off if you burn in public.'
                          : 'Off. The burn stays silent.',
                      value: _soundOn,
                      onChanged: _toggleSound,
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
                    _Row(
                      icon: Icons.whatshot_outlined,
                      title: 'Burn effect',
                      subtitle: effect.blurb,
                      trailing: effect.name,
                      onTap: _showEffects,
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
                delay: const Duration(milliseconds: 210),
                child: _Group(
                  label: 'Backup',
                  children: [
                    _Row(
                      icon: Icons.cloud_outlined,
                      title: 'Back up to iCloud',
                      subtitle: isPro
                          ? _cloudSubtitle
                          : 'Pro: automatic encrypted backup to your iCloud',
                      trailing: isPro ? null : 'Pro',
                      onTap: _busy
                          ? null
                          : isPro
                          ? _backUpToCloud
                          : () => Navigator.of(
                              context,
                            ).push(emberRoute(const PaywallScreen())),
                    ),
                    if (isPro && _cloudStatus == CloudStatus.available)
                      _Row(
                        icon: Icons.cloud_download_outlined,
                        title: 'Restore from iCloud',
                        subtitle: 'Replaces what\'s on this phone',
                        onTap: _busy ? null : _restoreFromCloud,
                      ),
                    _Row(
                      icon: Icons.lock_outline,
                      title: 'Create encrypted backup',
                      subtitle: isPro
                          ? 'One file, locked with your own passphrase. '
                                'Save it to Files, iCloud Drive, anywhere — '
                                'it stays unreadable without the passphrase.'
                          : 'Pro: export your desires as one encrypted file',
                      trailing: isPro ? null : 'Pro',
                      onTap: _busy
                          ? null
                          : isPro
                          ? _exportBackup
                          : () => Navigator.of(
                              context,
                            ).push(emberRoute(const PaywallScreen())),
                    ),
                    _Row(
                      icon: Icons.restore_page_outlined,
                      title: 'Restore from backup',
                      subtitle: 'Replaces what\'s on this phone',
                      trailing: isPro ? null : 'Pro',
                      onTap: _busy
                          ? null
                          : isPro
                          ? _importBackup
                          : () => Navigator.of(
                              context,
                            ).push(emberRoute(const PaywallScreen())),
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
                    backgroundColor: theme.colorScheme.error.withValues(
                      alpha: 0.07,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Erase everything',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Burn My Desire · v0.1.0',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textLow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The burn effect picker. Locked options stay visible and tappable —
  /// tapping one goes to the paywall rather than doing nothing, since a
  /// dead row teaches the user the app is broken.
  void _showEffects() {
    final current = ref.read(burnEffectProvider);
    final unlocked = ref.read(proUnlockedProvider);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Burn effect',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'How a desire ends. The ritual is the same either way.',
                style: Theme.of(
                  sheetContext,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMid),
              ),
              const SizedBox(height: 8),
              for (final e in burnEffects)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: e.glow,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(e.name),
                  subtitle: Text(e.blurb),
                  trailing: e.pro && !unlocked
                      ? const Icon(Icons.lock_outline, size: 18)
                      : e.id == current.id
                      ? const Icon(Icons.check, color: AppColors.accent)
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    if (e.pro && !unlocked) {
                      Navigator.of(
                        context,
                      ).push(emberRoute(const PaywallScreen()));
                    } else {
                      _pickEffect(e);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickEffect(BurnEffect e) async {
    await saveBurnEffect(e.id);
    ref.invalidate(burnEffectIdProvider);
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
              Text(
                'What you\'re burning',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
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
                  const Divider(
                    height: 1,
                    indent: 56,
                    color: AppColors.hairline,
                  ),
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
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 15.5),
                ),
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
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 15.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                Text(
                  trailing!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMid,
                  ),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textLow,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
