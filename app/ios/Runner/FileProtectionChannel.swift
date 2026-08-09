import Flutter
import Foundation

/// Applies iOS Data Protection to the app's files.
///
/// The database is encrypted by SQLCipher, but photos and rendered thought
/// pages are images on disk — a burned page literally contains the user's
/// words as pixels. `.complete` makes them unreadable whenever the phone is
/// locked, instead of the iOS default that only protects until first unlock.
class FileProtectionChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "burnmydesire/file_protection", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "protect":
        guard let path = (call.arguments as? [String: Any])?["path"] as? String
        else {
          result(FlutterError(
            code: "bad_args", message: "path is required", details: nil))
          return
        }
        result(protect(path: path))
      case "isSimulator":
        #if targetEnvironment(simulator)
          result(true)
        #else
          result(false)
        #endif
      case "protectionOf":
        guard let path = (call.arguments as? [String: Any])?["path"] as? String
        else {
          result(FlutterError(
            code: "bad_args", message: "path is required", details: nil))
          return
        }
        result(protectionOf(path: path))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Sets `.complete` on the path, and on every file inside it when it is a
  /// directory. Returns true only if everything succeeded.
  private static func protect(path: String) -> Bool {
    let fm = FileManager.default
    var ok = apply(path: path, fm: fm)
    var isDir: ObjCBool = false
    if fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
      let children = (try? fm.contentsOfDirectory(atPath: path)) ?? []
      for child in children {
        ok = apply(path: (path as NSString).appendingPathComponent(child),
                   fm: fm) && ok
      }
    }
    return ok
  }

  private static func apply(path: String, fm: FileManager) -> Bool {
    do {
      try fm.setAttributes(
        [.protectionKey: FileProtectionType.complete], ofItemAtPath: path)
      return true
    } catch {
      return false
    }
  }

  /// The current protection class, so the app can report the truth rather
  /// than assume it.
  private static func protectionOf(path: String) -> String {
    let attrs = try? FileManager.default.attributesOfItem(atPath: path)
    guard let value = attrs?[.protectionKey] as? FileProtectionType else {
      return "none"
    }
    switch value {
    case .complete: return "complete"
    case .completeUnlessOpen: return "complete_unless_open"
    case .completeUntilFirstUserAuthentication:
      return "until_first_unlock"
    default: return "other"
    }
  }
}
