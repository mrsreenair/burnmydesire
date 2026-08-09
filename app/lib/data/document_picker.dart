import 'package:flutter/services.dart';

/// Native document picker, used to choose a backup file to restore.
/// Returns the copied file's path, or null when the user cancels.
class DocumentPicker {
  DocumentPicker([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('burnmydesire/document_picker');

  final MethodChannel _channel;

  Future<String?> pickFile() async {
    try {
      return await _channel.invokeMethod<String>('pickFile');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
