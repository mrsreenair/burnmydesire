import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../utils/format_utils.dart';

/// The opt-in global counter.
///
/// This is the only thing the app ever sends anywhere, and it sends two
/// numbers: how much the user's protected total has grown since they last
/// contributed, and how many thoughts they have burned. No install id, no
/// categories, no goals, no timestamps, no text of any thought — nothing
/// that could identify them or what they burned. Off by default.
const _kOptInKey = 'world_counter_opt_in';
const _kContributedKey = 'world_counter_contributed_cents';
const _kContributedThoughtsKey = 'world_counter_contributed_thoughts';
const _kAskShownKey = 'world_counter_ask_shown';

class WorldStats {
  const WorldStats({
    required this.totalCents,
    required this.contributors,
    this.thoughts = 0,
  });

  final int totalCents;
  final int contributors;
  final int thoughts;

  factory WorldStats.fromJson(Map<String, dynamic> json) => WorldStats(
    totalCents: (json['totalCents'] as num?)?.toInt() ?? 0,
    contributors: (json['contributors'] as num?)?.toInt() ?? 0,
    thoughts: (json['thoughts'] as num?)?.toInt() ?? 0,
  );
}

Future<bool> worldCounterOptIn() async =>
    (await SharedPreferences.getInstance()).getBool(_kOptInKey) ?? false;

Future<void> setWorldCounterOptIn(bool on) async =>
    (await SharedPreferences.getInstance()).setBool(_kOptInKey, on);

/// Whether the one-time ask has already been put to this person.
///
/// Asked once, after a burn, and never again either way — a second ask
/// after a "no" would be nagging for something they gain nothing from.
Future<bool> worldCounterAskShown() async =>
    (await SharedPreferences.getInstance()).getBool(_kAskShownKey) ?? false;

Future<void> markWorldCounterAskShown() async =>
    (await SharedPreferences.getInstance()).setBool(_kAskShownKey, true);

/// How much of the user's total has already been counted, so we only ever
/// send the difference.
Future<int> contributedCents() async =>
    (await SharedPreferences.getInstance()).getInt(_kContributedKey) ?? 0;

Future<void> setContributedCents(int cents) async =>
    (await SharedPreferences.getInstance()).setInt(_kContributedKey, cents);

/// How many burned thoughts have already been counted.
Future<int> contributedThoughts() async =>
    (await SharedPreferences.getInstance()).getInt(_kContributedThoughtsKey) ??
    0;

Future<void> setContributedThoughts(int count) async =>
    (await SharedPreferences.getInstance()).setInt(
      _kContributedThoughtsKey,
      count,
    );

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
  ///
  /// Two numbers now: money protected, and thoughts burned. A thought has
  /// no price and never joins the euro total, but it is the same act, and
  /// a counter that reports only money implies only money counted.
  Future<WorldStats?> contribute(int protectedCents, int thoughtsBurned) async {
    if (!configured || !await worldCounterOptIn()) return null;
    final alreadyCents = await contributedCents();
    final alreadyThoughts = await contributedThoughts();
    final centsDelta = protectedCents - alreadyCents;
    final thoughtsDelta = thoughtsBurned - alreadyThoughts;
    if (centsDelta <= 0 && thoughtsDelta <= 0) return null;

    // The public total is one number, so it needs one unit: euros. The
    // conversion is a rough static rate — fine for a figure the site
    // already labels self-reported — but without it, one ¥100,000 user
    // would inflate a euro counter a hundredfold. Too small to round to
    // a cent yet? Don't mark it contributed; it accumulates until it
    // does — while the thoughts alongside it still go.
    final euroDelta = centsDelta > 0
        ? (centsDelta * activeCurrency.eurosPerUnit).round()
        : 0;
    if (euroDelta <= 0 && thoughtsDelta <= 0) return null;

    final payload = <String, dynamic>{
      'firstTime': alreadyCents == 0 && alreadyThoughts == 0,
    };
    if (euroDelta > 0) payload['deltaCents'] = euroDelta;
    if (thoughtsDelta > 0) payload['deltaThoughts'] = thoughtsDelta;

    try {
      final request = await _client.postUrl(
        Uri.parse('$_baseUrl/api/contributions'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      // Only mark what actually went. A rounded-away cent delta stays
      // uncounted so it can accumulate into the next send.
      if (euroDelta > 0) await setContributedCents(protectedCents);
      if (thoughtsDelta > 0) await setContributedThoughts(thoughtsBurned);
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
