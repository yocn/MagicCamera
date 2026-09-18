import SwiftUI
import UIKit

final class CameraAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .portrait
    }
}

@main
struct CuteStickerCameraApp: App {
    @UIApplicationDelegateAdaptor(CameraAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            CameraScreen()
        }
    }
}
