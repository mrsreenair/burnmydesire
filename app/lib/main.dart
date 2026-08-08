import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'config.dart';
import 'data/image_store.dart';
import 'providers/db_providers.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final docs = await getApplicationDocumentsDirectory();
  final seenOnboarding = await hasSeenOnboarding();
  if (kRevenueCatIosApiKey.isNotEmpty) {
    await Purchases.configure(
      PurchasesConfiguration(kRevenueCatIosApiKey),
    );
  }
  runApp(
    ProviderScope(
      overrides: [
        imageStoreProvider.overrideWithValue(ImageStore(docs.path)),
      ],
      child: BurnMyDesireApp(showOnboarding: !seenOnboarding),
    ),
  );
}

class BurnMyDesireApp extends StatelessWidget {
  const BurnMyDesireApp({super.key, required this.showOnboarding});

  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Burn My Desire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepOrange,
        scaffoldBackgroundColor: const Color(0xFF141416),
      ),
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
