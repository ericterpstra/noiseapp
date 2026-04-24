import SwiftUI

@main
struct SleepCompanionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = SleepAppModel()

    var body: some Scene {
        WindowGroup {
            ClockScreen()
                .environmentObject(model)
        }
    }
}
