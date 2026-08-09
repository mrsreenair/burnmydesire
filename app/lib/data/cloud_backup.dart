import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'backup.dart';

/// iCloud Drive backup.
///
/// The archive is encrypted with the user's passphrase *before* it leaves
/// the app, so iCloud stores ciphertext only — Apple can't read it, and
/// neither can anyone who gets into the iCloud account. That's what makes
/// syncing compatible with the promise the rest of the app makes.
enum CloudStatus {
  /// Ready to back up.
  available,

  /// No iCloud account on the device.
  signedOut,

  /// Build has no iCloud container (needs the paid developer account).
  noContainer,

  /// The native bridge isn't there at all.
  unsupported,
}

const _kPassphraseKey = 'cloud_backup_passphrase';

/// Stored so automatic backups don't prompt on every burn. Device-only,
/// never synced — restoring on a new phone asks for it again.
const _storage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

Future<void> saveCloudPassphrase(String passphrase) =>
    _storage.write(key: _kPassphraseKey, value: passphrase);

Future<String?> cloudPassphrase() => _storage.read(key: _kPassphraseKey);

Future<void> clearCloudPassphrase() => _storage.delete(key: _kPassphraseKey);

class CloudBackup {
  CloudBackup(this.backups, [MethodChannel? channel])
      : _channel =
            channel ?? const MethodChannel('burnmydesire/cloud_backup');

  final BackupService backups;
  final MethodChannel _channel;

  Future<CloudStatus> status() async {
    try {
      final raw = await _channel.invokeMethod<String>('status');
      return switch (raw) {
        'available' => CloudStatus.available,
        'signed_out' => CloudStatus.signedOut,
        'no_container' => CloudStatus.noContainer,
        _ => CloudStatus.unsupported,
      };
    } on PlatformException {
      return CloudStatus.unsupported;
    } on MissingPluginException {
      return CloudStatus.unsupported;
    }
  }

  /// When the stored archive was last written, or null if there is none.
  Future<DateTime?> lastBackup() async {
    try {
      final raw = await _channel.invokeMethod<String>('lastModified');
      return raw == null ? null : DateTime.tryParse(raw);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Builds an encrypted archive and hands it to iCloud. Returns false
  /// when iCloud isn't usable — the caller keeps the file-export path.
  Future<bool> backUp({String? passphrase}) async {
    final pass = passphrase ?? await cloudPassphrase();
    if (pass == null) {
      throw const BackupException('Set a backup passphrase first.');
    }
    if (await status() != CloudStatus.available) return false;

    final tmp = await getTemporaryDirectory();
    final staged = Directory('${tmp.path}/cloud_backup')
      ..createSync(recursive: true);
    final file = await backups.export(
      passphrase: pass,
      destinationDir: staged.path,
    );
    try {
      return await _channel
              .invokeMethod<bool>('upload', {'path': file.path}) ??
          false;
    } on PlatformException catch (e) {
      throw BackupException(e.message ?? 'iCloud upload failed.');
    }
  }

  /// Restores from the iCloud copy. Returns the number of desires
  /// restored, or null when no backup is stored there yet.
  Future<int?> restore({required String passphrase}) async {
    final String? path;
    try {
      path = await _channel.invokeMethod<String>('download');
    } on PlatformException catch (e) {
      throw BackupException(e.message ?? 'iCloud download failed.');
    }
    if (path == null) return null;
    return backups.import(path: path, passphrase: passphrase);
  }

  Future<bool> deleteCloudCopy() async {
    try {
      return await _channel.invokeMethod<bool>('delete') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
