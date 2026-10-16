import AVFoundation
import CoreLocation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let compassHandler = CompassStreamHandler()
  private let speechHandler = SpeechHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CompassChannel") {
      FlutterEventChannel(
        name: CompassStreamHandler.channelName,
        binaryMessenger: registrar.messenger()
      ).setStreamHandler(compassHandler)
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SpeechChannel") {
      let channel = FlutterMethodChannel(
        name: SpeechHandler.channelName,
        binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler(speechHandler.handle)
    }
  }
}

/// Streams the device's compass heading to Dart: `{heading, accuracy}` maps, only
/// while Dart listens.
///
/// `heading` is degrees clockwise from true north when location services allow it
/// (magnetic north otherwise), relative to the way the screen is held. `accuracy`
/// is Core Location's own estimate in degrees (plus or minus), null while it is
/// invalid. Core Location's calibration prompt is allowed to show.
final class CompassStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  static let channelName = "com.hevanto_it.swayriderapp/compass"

  private let manager = CLLocationManager()
  private var sink: FlutterEventSink?

  override init() {
    super.init()
    manager.delegate = self
    manager.headingFilter = 1  // degrees; Dart smooths it further
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    guard CLLocationManager.headingAvailable() else {
      return FlutterError(
        code: "NO_SENSOR", message: "Heading is not available on this device", details: nil)
    }
    sink = events
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(orientationChanged),
      name: UIDevice.orientationDidChangeNotification,
      object: nil)
    orientationChanged()
    manager.startUpdatingHeading()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager.stopUpdatingHeading()
    NotificationCenter.default.removeObserver(
      self, name: UIDevice.orientationDidChangeNotification, object: nil)
    UIDevice.current.endGeneratingDeviceOrientationNotifications()
    sink = nil
    return nil
  }

  /// Tells Core Location which edge of the device counts as "up" for the heading.
  @objc private func orientationChanged() {
    switch UIDevice.current.orientation {
    case .portrait:
      manager.headingOrientation = .portrait
    case .portraitUpsideDown:
      manager.headingOrientation = .portraitUpsideDown
    case .landscapeLeft:
      manager.headingOrientation = .landscapeLeft
    case .landscapeRight:
      manager.headingOrientation = .landscapeRight
    default:
      break  // face up, face down or unknown: keep the last one
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    let accuracy: Any = newHeading.headingAccuracy >= 0 ? newHeading.headingAccuracy : NSNull()
    sink?(["heading": heading, "accuracy": accuracy])
  }

  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
    return true
  }
}

/// Speaks navigation prompts with `AVSpeechSynthesizer`.
///
/// Channel methods: `speak {text, language}` (cuts off whatever is being
/// spoken) and `stop`. The audio session ducks other audio (music) while a
/// prompt plays and hands it back afterwards.
final class SpeechHandler: NSObject, AVSpeechSynthesizerDelegate {
  static let channelName = "com.hevanto_it.swayriderapp/speech"

  private let synthesizer = AVSpeechSynthesizer()

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "speak":
      guard let args = call.arguments as? [String: Any],
        let text = args["text"] as? String, !text.isEmpty
      else {
        result(nil)
        return
      }
      speak(text, language: args["language"] as? String ?? "en-US")
      result(nil)
    case "stop":
      synthesizer.stopSpeaking(at: .immediate)
      deactivateSession()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func speak(_ text: String, language: String) {
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(
      .playback, mode: .voicePrompt,
      options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
    try? session.setActive(true)

    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: language)
    synthesizer.speak(utterance)
  }

  private func deactivateSession() {
    try? AVAudioSession.sharedInstance().setActive(
      false, options: .notifyOthersOnDeactivation)
  }

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance
  ) {
    deactivateSession()
  }

  func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance
  ) {
    // A new utterance usually follows straight away and reactivates the
    // session; only release it when nothing else is queued.
    if !synthesizer.isSpeaking {
      deactivateSession()
    }
  }
}
