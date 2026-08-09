import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSetupDoneKey = 'onboarding_seen';
const _kNameKey = 'profile_name';
const _kCategoriesKey = 'spend_categories';
const _kPinHashKey = 'pin_hash';
const _kPinSaltKey = 'pin_salt';

const _storage = FlutterSecureStorage();

/// What the user wants to burn: (id, label, emoji). Impulse buying is the
/// money wedge; everything else is a habit/emotion goal (PROJECT.md §4.4).
const burnGoals = <(String, String, String)>[
  ('impulse_buying', 'Impulse buying', '🛍️'),
  ('breakup', 'Breakup & heartbreak', '💔'),
  ('alcohol', 'Alcohol', '🍺'),
  ('smoking', 'Smoking & vaping', '🚬'),
  ('junk_food', 'Junk food', '🍔'),
  ('social_media', 'Social media', '📱'),
  ('porn', 'Porn & sex urges', '🔞'),
  ('gambling', 'Gambling', '🎰'),
  ('doomscrolling', 'Doomscrolling', '🌀'),
  ('thoughts', 'Unwanted thoughts', '💭'),
];

const _kGoalsKey = 'burn_goals';
const _kAiCoachKey = 'ai_coach_enabled';
const _kCurrencyKey = 'currency_code';

/// The chosen display currency (ISO code), null before setup picks one.
/// Changing it later never converts stored amounts — numbers are numbers;
/// the currency only decides how they're written.
Future<String?> savedCurrencyCode() async =>
    (await SharedPreferences.getInstance()).getString(_kCurrencyKey);

Future<void> saveCurrencyCode(String code) async =>
    (await SharedPreferences.getInstance()).setString(_kCurrencyKey, code);

Future<void> saveBurnGoals(List<String> ids) async =>
    (await SharedPreferences.getInstance()).setStringList(_kGoalsKey, ids);

Future<List<String>> savedBurnGoals() async =>
    (await SharedPreferences.getInstance()).getStringList(_kGoalsKey) ??
    const [];

/// On-device AI encouragement (Apple Intelligence). On by default; the
/// model runs entirely on the phone either way.
Future<bool> aiCoachEnabled() async =>
    (await SharedPreferences.getInstance()).getBool(_kAiCoachKey) ?? true;

Future<void> setAiCoachEnabled(bool on) async =>
    (await SharedPreferences.getInstance()).setBool(_kAiCoachKey, on);

const _kBurnSoundKey = 'burn_sound_enabled';

/// The crackle (or the shredder motor) under a hold. On by default, and
/// deliberately loud enough to hear — but it plays through the ring
/// switch, so anyone who burns in public needs a way to shut it off.
Future<bool> burnSoundEnabled() async =>
    (await SharedPreferences.getInstance()).getBool(_kBurnSoundKey) ?? true;

Future<void> setBurnSoundEnabled(bool on) async =>
    (await SharedPreferences.getInstance()).setBool(_kBurnSoundKey, on);

/// Spending temptations offered during setup: (label, emoji).
const spendCategories = <(String, String)>[
  ('Clothes', '👗'),
  ('Gadgets', '📱'),
  ('Sneakers & shoes', '👟'),
  ('Food delivery', '🍔'),
  ('Subscriptions', '📺'),
  ('Gaming', '🎮'),
  ('Beauty & skincare', '💄'),
  ('Watches & jewelry', '⌚'),
  ('Home & decor', '🛋️'),
  ('Hobby gear', '🎸'),
  ('Coffee & takeout', '☕'),
  ('Something else', '✨'),
];

// ---- Setup flag (same key as the old onboarding flag, now set only after
// the whole setup flow — onboarding, PIN, categories — completes) ----

Future<bool> hasCompletedSetup() async =>
    (await SharedPreferences.getInstance()).getBool(_kSetupDoneKey) ?? false;

Future<void> markSetupComplete() async =>
    (await SharedPreferences.getInstance()).setBool(_kSetupDoneKey, true);

// ---- Profile ----

Future<void> saveProfileName(String name) async =>
    (await SharedPreferences.getInstance()).setString(_kNameKey, name.trim());

Future<String> profileName() async =>
    (await SharedPreferences.getInstance()).getString(_kNameKey) ?? '';

// ---- Spending categories ----

Future<void> saveSpendCategories(List<String> labels) async =>
    (await SharedPreferences.getInstance()).setStringList(
      _kCategoriesKey,
      labels,
    );

Future<List<String>> savedSpendCategories() async =>
    (await SharedPreferences.getInstance()).getStringList(_kCategoriesKey) ??
    const [];

// ---- PIN (salted SHA-256, stored in the iOS Keychain — the PIN itself is
// never persisted anywhere) ----

String hashPin(String pin, String salt) =>
    sha256.convert(utf8.encode('$salt:$pin')).toString();

String generateSalt([Random? random]) {
  final rng = random ?? Random.secure();
  return base64Encode(List<int>.generate(16, (_) => rng.nextInt(256)));
}

Future<bool> hasPin() async => await _storage.read(key: _kPinHashKey) != null;

Future<void> savePin(String pin) async {
  final salt = generateSalt();
  await _storage.write(key: _kPinSaltKey, value: salt);
  await _storage.write(key: _kPinHashKey, value: hashPin(pin, salt));
}

/// "Erase everything": drop the profile, setup flags and the PIN. Leaves
/// the device with a clean install — onboarding runs again.
Future<void> clearAllPrefs() async {
  await (await SharedPreferences.getInstance()).clear();
  await _storage.delete(key: _kPinHashKey);
  await _storage.delete(key: _kPinSaltKey);
}

Future<bool> verifyPin(String pin) async {
  final salt = await _storage.read(key: _kPinSaltKey);
  final hash = await _storage.read(key: _kPinHashKey);
  if (salt == null || hash == null) return false;
  return hashPin(pin, salt) == hash;
}
