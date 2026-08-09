import Flutter
import Foundation

/// iCloud Drive storage for the encrypted backup archive.
///
/// The archive is already SQLCipher-encrypted with the user's passphrase
/// before it gets here, so iCloud — and Apple — only ever hold ciphertext.
/// This class just moves that opaque file in and out of the app's
/// ubiquity container and reports sync state.
class CloudBackupChannel {
  /// Must match the container in Runner.entitlements.
  private static let containerId = "iCloud.com.burnmydesire.burnMyDesire"
  private static let backupName = "burn-my-desire-backup.bmd"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "burnmydesire/cloud_backup", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isAvailable":
        result(containerURL() != nil)
      case "status":
        status(result: result)
      case "upload":
        guard let path = (call.arguments as? [String: Any])?["path"] as? String
        else {
          result(argError()); return
        }
        upload(localPath: path, result: result)
      case "download":
        download(result: result)
      case "lastModified":
        result(lastModified())
      case "delete":
        result(deleteBackup())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func argError() -> FlutterError {
    FlutterError(code: "bad_args", message: "path is required", details: nil)
  }

  /// nil when the entitlement is missing or the user isn't signed in to
  /// iCloud — both are normal, and the app falls back to file export.
  private static func containerURL() -> URL? {
    FileManager.default.url(forUbiquityContainerIdentifier: containerId)?
      .appendingPathComponent("Documents")
  }

  private static func backupURL() -> URL? {
    containerURL()?.appendingPathComponent(backupName)
  }

  /// Distinguishes "no entitlement/build" from "not signed in" so the UI
  /// can tell the user something actionable.
  private static func status(result: @escaping FlutterResult) {
    if FileManager.default.ubiquityIdentityToken == nil {
      result("signed_out")
      return
    }
    guard containerURL() != nil else {
      result("no_container")
      return
    }
    result("available")
  }

  private static func upload(
    localPath: String, result: @escaping FlutterResult
  ) {
    guard let destination = backupURL() else {
      result(FlutterError(
        code: "unavailable", message: "iCloud is not available",
        details: nil))
      return
    }
    let fm = FileManager.default
    do {
      try fm.createDirectory(
        at: destination.deletingLastPathComponent(),
        withIntermediateDirectories: true)
      if fm.fileExists(atPath: destination.path) {
        try fm.removeItem(at: destination)
      }
      // setUbiquitous moves the file into the container and hands syncing
      // to iOS; it uploads in the background on its own schedule.
      try fm.setUbiquitous(
        true, itemAt: URL(fileURLWithPath: localPath), destinationURL: destination)
      result(true)
    } catch {
      result(FlutterError(
        code: "upload_failed", message: error.localizedDescription,
        details: nil))
    }
  }

  /// Pulls the archive down (it may only exist as a placeholder) and
  /// returns a local copy's path.
  private static func download(result: @escaping FlutterResult) {
    guard let remote = backupURL() else {
      result(FlutterError(
        code: "unavailable", message: "iCloud is not available",
        details: nil))
      return
    }
    let fm = FileManager.default
    guard fm.fileExists(atPath: remote.path) else {
      // A placeholder exists but the content hasn't been fetched yet.
      try? fm.startDownloadingUbiquitousItem(at: remote)
      result(nil)
      return
    }
    do {
      try fm.startDownloadingUbiquitousItem(at: remote)
      let local = fm.temporaryDirectory.appendingPathComponent(backupName)
      if fm.fileExists(atPath: local.path) {
        try fm.removeItem(at: local)
      }
      try fm.copyItem(at: remote, to: local)
      result(local.path)
    } catch {
      result(FlutterError(
        code: "download_failed", message: error.localizedDescription,
        details: nil))
    }
  }

  /// ISO-8601 timestamp of the stored backup, or nil when there is none.
  private static func lastModified() -> String? {
    guard let url = backupURL(),
          let values = try? url.resourceValues(
            forKeys: [.contentModificationDateKey]),
          let date = values.contentModificationDate
    else { return nil }
    let formatter = ISO8601DateFormatter()
    return formatter.string(from: date)
  }

  private static func deleteBackup() -> Bool {
    guard let url = backupURL() else { return false }
    do {
      try FileManager.default.removeItem(at: url)
      return true
    } catch {
      return false
    }
  }
}
