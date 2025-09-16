import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Force camera permission request at app startup to ensure iOS registers it
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      AVCaptureDevice.requestAccess(for: .video) { granted in
        print("Camera permission \(granted ? "granted" : "denied")")
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
