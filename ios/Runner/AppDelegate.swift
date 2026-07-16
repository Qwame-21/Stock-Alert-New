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
    if let dartDefines = Bundle.main.object(forInfoDictionaryKey: "DART_DEFINES") as? String {
      for encodedDefine in dartDefines.split(separator: ",") {
        guard
          let defineData = Data(base64Encoded: String(encodedDefine)),
          let define = String(data: defineData, encoding: .utf8)
        else {
          continue
        }

        let keyValue = define.split(separator: "=", maxSplits: 1)
        if keyValue.count == 2,
           keyValue[0] == "MAPS_API_KEY_IOS",
           !keyValue[1].isEmpty {
          GMSServices.provideAPIKey(String(keyValue[1]))
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
