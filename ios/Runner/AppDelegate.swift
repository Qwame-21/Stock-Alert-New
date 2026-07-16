import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Provide the iOS Maps API key before the Flutter engine initialises.
    // The key is compiled in via --dart-define=MAPS_API_KEY_IOS=<key>.
    // Flutter's build system writes all dart-defines into Info.plist under
    // the key "DART_DEFINES". We read it back here so the native SDK is
    // initialised on the correct platform path.
    if let dartDefinesBase64 = Bundle.main.object(forInfoDictionaryKey: "DART_DEFINES") as? String,
       let dartDefinesData = Data(base64Encoded: dartDefinesBase64),
       let dartDefinesString = String(data: dartDefinesData, encoding: .utf8) {
      let pairs = dartDefinesString.split(separator: ",")
      for pair in pairs {
        let kv = pair.split(separator: "=", maxSplits: 1)
        if kv.count == 2, kv[0] == "MAPS_API_KEY_IOS" {
          let iosKey = String(kv[1])
          if !iosKey.isEmpty {
            GMSServices.provideAPIKey(iosKey)
          }
          break
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

