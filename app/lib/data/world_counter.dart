import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../utils/format_utils.dart';

/// The opt-in global counter.
///
/// This is the only thing the app ever sends anywhere, and it sends one
/// number: how much the user's protected total has grown since they last
/// contributed. No install id, no categories, no goals, no timestamps —
/// nothing that could identify them or what they burned. Off by default.
const _kOptInKey = 'world_counter_opt_in';
const _kContributedKey = 'world_counter_contributed_cents';

class WorldStats {
  const WorldStats({required this.totalCents, required this.contributors});

  final int totalCents;
  final int contributors;

  factory WorldStats.fromJson(Map<String, dynamic> json) => WorldStats(
    totalCents: (json['totalCents'] as num?)?.toInt() ?? 0,
    contributors: (json['contributors'] as num?)?.toInt() ?? 0,
  );
}

Future<bool> worldCounterOptIn() async =>
    (await SharedPreferences.getInstance()).getBool(_kOptInKey) ?? false;

Future<void> setWorldCounterOptIn(bool on) async =>
    (await SharedPreferences.getInstance()).setBool(_kOptInKey, on);

/// How much of the user's total has already been counted, so we only ever
/// send the difference.
Future<int> contributedCents() async =>
    (await SharedPreferences.getInstance()).getInt(_kContributedKey) ?? 0;

Future<void> setContributedCents(int cents) async =>
    (await SharedPreferences.getInstance()).setInt(_kContributedKey, cents);

class WorldCounter {
  WorldCounter({HttpClient? client, String? baseUrl})
    : _client = client ?? HttpClient(),
      _baseUrl = baseUrl ?? kWorldCounterBaseUrl;

  final HttpClient _client;
  final String _baseUrl;

  bool get configured => _baseUrl.isNotEmpty;

  /// Sends the growth since the last contribution. Returns the updated
  /// world stats, or null when nothing needed sending or the network
  /// failed — this is never worth an error in the user's face.
  Future<WorldStats?> contribute(int protectedCents) async {
    if (!configured || !await worldCounterOptIn()) return null;
    final already = await contributedCents();
    final delta = protectedCents - already;
    if (delta <= 0) return null;

    // The public total is one number, so it needs one unit: euros. The
    // conversion is a rough static rate — fine for a figure the site
    // already labels self-reported — but without it, one ¥100,000 user
    // would inflate a euro counter a hundredfold. Too small to round to
    // a cent yet? Don't mark it contributed; it accumulates until it
    // does.
    final euroDelta = (delta * activeCurrency.eurosPerUnit).round();
    if (euroDelta <= 0) return null;

    try {
      final request = await _client.postUrl(
        Uri.parse('$_baseUrl/api/contributions'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({'deltaCents': euroDelta, 'firstTime': already == 0}),
      );
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      await setContributedCents(protectedCents);
      return WorldStats.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } on IOException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Public totals for display. Null when unreachable.
  Future<WorldStats?> stats() async {
    if (!configured) return null;
    try {
      final request = await _client.getUrl(Uri.parse('$_baseUrl/api/stats'));
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      return WorldStats.fromJson(jsonDecode(body) as Map<String, dynamic>);
    } on IOException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
