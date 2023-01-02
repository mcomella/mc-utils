import OSLog
import SwiftUI

let log = Logger(subsystem: "xyz.mcomella.mwm", category: "default")

@main
struct mwmApp: App {

    init() {
        alertAndExitIfAccessibilityIsDisabled()
        Input.initMonitoring()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

fileprivate func alertAndExitIfAccessibilityIsDisabled() {
    if !AXIsProcessTrusted() {
        log.error("mwm must be trusted by accessibility. Will display alert and exit.")

        // This is mixing UI paradigms: SwiftUI and the legacy stuff. However, it's simple so we use it.
        let alert = NSAlert()
        alert.messageText = "Unable to start mwm"
        alert.informativeText = "mwm must be trusted by accessibility to observe key presses and change window sizes. Go to System Preferences -> Security & Privacy -> Privacy -> Accessibility and add \"mwm.app\"."
        alert.runModal()

        exit(1)
    }
}
