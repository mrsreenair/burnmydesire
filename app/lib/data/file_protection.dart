import 'package:flutter/services.dart';

/// iOS Data Protection for the app's image files.
///
/// SQLCipher covers the database, but photos and rendered thought pages
/// are images on disk. `complete` protection keeps them encrypted by the
/// OS whenever the phone is locked — the iOS default only protects until
/// the first unlock after boot.
class FileProtection {
  FileProtection([MethodChannel? channel])
      : _channel =
            channel ?? const MethodChannel('burnmydesire/file_protection');

  final MethodChannel _channel;

  /// Applies complete protection to a file or a whole directory.
  /// Returns false when the platform refuses or isn't iOS.
  Future<bool> protect(String path) async {
    try {
      return await _channel.invokeMethod<bool>('protect', {'path': path}) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The simulator has no Secure Enclave, so it reports no protection
  /// class at all — data protection can only be confirmed on a device.
  Future<bool> isSimulator() async {
    try {
      return await _channel.invokeMethod<bool>('isSimulator') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The protection class actually applied: 'complete',
  /// 'until_first_unlock', 'none', … Used to report the truth in Settings
  /// rather than assume the call worked.
  Future<String> protectionOf(String path) async {
    try {
      return await _channel
              .invokeMethod<String>('protectionOf', {'path': path}) ??
          'unknown';
    } on PlatformException {
      return 'unknown';
    } on MissingPluginException {
      return 'unavailable';
    }
  }
}
