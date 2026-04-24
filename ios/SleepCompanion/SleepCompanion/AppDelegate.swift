import AVFoundation
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .landscape
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        application.isIdleTimerDisabled = true
        configureAudioSession()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        application.isIdleTimerDisabled = false
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            assertionFailure("Unable to configure playback audio session: \(error)")
        }
    }
}
