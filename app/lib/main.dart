import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'config.dart';
import 'data/currencies.dart';
import 'data/encrypted_db.dart';
import 'data/image_store.dart';
import 'data/user_prefs.dart';
import 'providers/db_providers.dart';
import 'screens/root_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'utils/format_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final docs = await getApplicationDocumentsDirectory();
  final imageStore = ImageStore(docs.path);
  await imageStore.protectAll();
  debugPrint('DB SECURITY: ${await databaseSecurityReport()}');
  debugPrint('IMAGE PROTECTION: ${await imageStore.protectionClass()}');
  // The saved currency, or the device locale's best guess until setup
  // confirms one. Must happen before any widget formats an amount.
  setActiveCurrency(
    currencyByCode(await savedCurrencyCode()) ?? detectCurrency(),
  );
  final setupDone = await hasCompletedSetup();
  final locked = setupDone && await hasPin();
  if (kRevenueCatIosApiKey.isNotEmpty) {
    await Purchases.configure(PurchasesConfiguration(kRevenueCatIosApiKey));
  }
  runApp(
    ProviderScope(
      overrides: [imageStoreProvider.overrideWithValue(imageStore)],
      child: BurnMyDesireApp(showOnboarding: !setupDone, locked: locked),
    ),
  );
}

class BurnMyDesireApp extends StatelessWidget {
  const BurnMyDesireApp({
    super.key,
    required this.showOnboarding,
    required this.locked,
  });

  final bool showOnboarding;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burn My Desire',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: showOnboarding
          ? const OnboardingScreen()
          : locked
          ? const LockScreen()
          : const RootShell(),
    );
  }
}
