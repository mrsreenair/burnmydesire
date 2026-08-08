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
    (await SharedPreferences.getInstance())
        .setStringList(_kCategoriesKey, labels);

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

Future<bool> verifyPin(String pin) async {
  final salt = await _storage.read(key: _kPinSaltKey);
  final hash = await _storage.read(key: _kPinHashKey);
  if (salt == null || hash == null) return false;
  return hashPin(pin, salt) == hash;
}
