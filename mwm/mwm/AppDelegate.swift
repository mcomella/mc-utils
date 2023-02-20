import Cocoa
import OSLog

let log = Logger(subsystem: "com.mcomella.mwm", category: "default")

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    // Must keep a reference or status bar item will be removed.
    private let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Remove from dock
        let isActivityPolicySuccess = NSApp.setActivationPolicy(.accessory)
        assert(isActivityPolicySuccess)

        alertAndExitIfAccessibilityIsDisabled()

        // Add to status bar
        self.statusBarItem.button!.title = "WM"
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(onQuitClick), keyEquivalent: "")
        let menu = NSMenu()
        menu.addItem(quitMenuItem)
        self.statusBarItem.menu = menu

        Input.initMonitoring()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @objc private func onQuitClick() {
        log.debug("Quit clicked: exiting…")
        exit(0)
    }
}

/// A class that contains Selector definitions. Since `#selector(…)` can only be used on concrete members or functions of classes (and some other type), we create this class exclusively to hold function references to selectors.
class SelectorFuncs {
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
