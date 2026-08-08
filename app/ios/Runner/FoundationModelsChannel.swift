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
