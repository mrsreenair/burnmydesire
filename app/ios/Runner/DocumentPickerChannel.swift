import Flutter
import UIKit
import UniformTypeIdentifiers

/// Lets the user pick a backup file to restore.
///
/// Written as a small native channel rather than pulling in a plugin: the
/// project is Swift-Package-Manager only, and adding CocoaPods for one
/// file picker isn't worth the build complexity.
class DocumentPickerChannel: NSObject, UIDocumentPickerDelegate {
  private static var retained: DocumentPickerChannel?
  private var pending: FlutterResult?

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "burnmydesire/document_picker", binaryMessenger: messenger)
    let handler = DocumentPickerChannel()
    retained = handler
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "pickFile":
        handler.present(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func present(result: @escaping FlutterResult) {
    guard let root = Self.topViewController() else {
      result(FlutterError(
        code: "no_window", message: "No view controller", details: nil))
      return
    }
    pending = result
    // Backups have no registered UTI, so accept any file and let the
    // passphrase step reject anything that isn't ours.
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(
        forOpeningContentTypes: [UTType.data], asCopy: true)
    } else {
      picker = UIDocumentPickerViewController(
        documentTypes: ["public.data"], in: .import)
    }
    picker.delegate = self
    picker.allowsMultipleSelection = false
    root.present(picker, animated: true)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    pending?(urls.first?.path)
    pending = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController)
  {
    pending?(nil)
    pending = nil
  }

  private static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}
