import Flutter
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Bridge to Apple's on-device Foundation Models (Apple Intelligence).
/// Everything runs on the phone: no prompt, thought, or goal ever leaves
/// the device — which is the whole point (PROJECT.md §4.4 AI roadmap).
class FoundationModelsChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "burnmydesire/ai", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isAvailable":
        isAvailable(result: result)
      case "status":
        status(result: result)
      case "generate":
        guard let args = call.arguments as? [String: Any],
              let instructions = args["instructions"] as? String,
              let prompt = args["prompt"] as? String
        else {
          result(FlutterError(
            code: "bad_args",
            message: "instructions and prompt are required",
            details: nil))
          return
        }
        generate(instructions: instructions, prompt: prompt, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Human-readable reason the model is or isn't usable — the only way to
  /// tell "Apple Intelligence is off" from "this build can't see the
  /// framework" from the Flutter side.
  private static func status(result: @escaping FlutterResult) {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      switch SystemLanguageModel.default.availability {
      case .available:
        result("available")
      case .unavailable(let reason):
        switch reason {
        case .deviceNotEligible:
          result("device_not_eligible")
        case .appleIntelligenceNotEnabled:
          result("apple_intelligence_off")
        case .modelNotReady:
          result("model_downloading")
        @unknown default:
          result("unavailable_other")
        }
      @unknown default:
        result("unavailable_other")
      }
      return
    }
    result("ios_too_old")
    #else
    result("framework_missing")
    #endif
  }

  private static func isAvailable(result: @escaping FlutterResult) {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      switch SystemLanguageModel.default.availability {
      case .available:
        result(true)
      default:
        result(false)
      }
      return
    }
    #endif
    result(false)
  }

  private static func generate(
    instructions: String, prompt: String, result: @escaping FlutterResult
  ) {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      Task {
        do {
          let session = LanguageModelSession(instructions: instructions)
          let response = try await session.respond(to: prompt)
          await MainActor.run { result(response.content) }
        } catch {
          await MainActor.run {
            result(FlutterError(
              code: "generation_failed",
              message: error.localizedDescription,
              details: nil))
          }
        }
      }
      return
    }
    #endif
    result(FlutterError(
      code: "unavailable",
      message: "Foundation Models is not available on this device",
      details: nil))
  }
}
