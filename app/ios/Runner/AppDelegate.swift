import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar =
      engineBridge.pluginRegistry.registrar(forPlugin: "FoundationModelsChannel")
    {
      FoundationModelsChannel.register(with: registrar.messenger())
      FileProtectionChannel.register(with: registrar.messenger())
      DocumentPickerChannel.register(with: registrar.messenger())
      CloudBackupChannel.register(with: registrar.messenger())
    }
  }
}
