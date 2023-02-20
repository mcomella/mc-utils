import AVFoundation
import Cocoa
import os

private let logger = Logger(subsystem: "com.mcomella.remind", category: "default")

struct Configuration : Codable {
    let text: String
    let min: Int
    let max: Int
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    // Must keep a reference to the status bar item for it to remain
    private let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let pauseResumeMenuItem = NSMenuItem(title: "Pause", action: #selector(onPauseResumeClick), keyEquivalent: "")

    private var timer: Timer? = nil
    private var userConfiguration: Configuration? = nil

    private var isPaused = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let isActivationPolicySuccess = NSApp.setActivationPolicy(.accessory)
        assert(isActivationPolicySuccess)

        // Load user's configuration; file loading via https://stackoverflow.com/a/24098149
        // Needed to disable app sandbox to access user home directory.
        let path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".remind", conformingTo: .text)
        logger.debug("Loading user configuration from path, \(path)")
        if let data = (try? String(contentsOf: path))?.data(using: .utf8) {
            logger.debug("Read configuration file successfully")
            userConfiguration = try? JSONDecoder().decode(Configuration.self, from: data)
        }

        if let conf = userConfiguration {
            logger.debug("Announcing \"\(conf.text)\" every \(conf.min) to \(conf.max) minutes")
        } else {
            logger.error("Failed to load user configuration: displaying alert and exiting")
            let alert = NSAlert()
            alert.messageText = "Failed to load user configuration"
            alert.informativeText = "Create a ~/.remind file with JSON contents: {text: String, min: Int, max: Int}"
            alert.addButton(withTitle: "Exit")
            alert.runModal()
            exit(1)
        }

        // Configure the status bar icon
        self.statusBarItem.button!.title = "R"
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(onQuitClick), keyEquivalent: "")
        let menu = NSMenu()
        menu.addItem(self.pauseResumeMenuItem)
        menu.addItem(quitMenuItem)
        self.statusBarItem.menu = menu

        // Add notifications to stop timer
        let notificationCenter = NSWorkspace.shared.notificationCenter
        for notificationName in [
            NSWorkspace.sessionDidResignActiveNotification,
            NSWorkspace.screensDidSleepNotification,
        ] {
            notificationCenter.addObserver(forName: notificationName, object: nil, queue: nil, using: stopReminder(_:))
        }

        // Add notifications to restart timer
        for notificationName in [
            NSWorkspace.sessionDidBecomeActiveNotification,
            NSWorkspace.screensDidWakeNotification,
        ] {
            notificationCenter.addObserver(forName: notificationName, object: nil, queue: nil, using: startReminder(_:))
        }

        // If we start in a different state, remember to update pause menu item title.
        startReminder()
    }

    @objc private func onPauseResumeClick() {
        if isPaused {
            isPaused = false
            logger.debug("onPauseResume clicked: resuming reminders")
            self.pauseResumeMenuItem.title = "Pause"
            startReminder()
        } else {
            isPaused = true
            logger.debug("onPauseResume clicked: pausing reminders")
            self.pauseResumeMenuItem.title = "Resume"
            stopReminder()
        }
    }

    @objc private func onQuitClick() {
        logger.debug("Quit clicked: exiting")
        exit(0)
    }

    private func stopReminder(_ notification: Notification) {
        logger.debug("Received \(notification.name.rawValue)")
        stopReminder()
    }

    private func stopReminder() {
        if let timer = timer {
            logger.debug("Stopping reminder")
            timer.invalidate()
            self.timer = nil
        } else {
            logger.debug("stopReminder called but timer not active")
        }
    }

    private func startReminder(_ notification: Notification) {
        logger.debug("Received \(notification.name.rawValue)")
        startReminder()
    }

    private func startReminder() {
        if isPaused {
            logger.debug("startReminder called but is paused")
            return
        }

        if timer != nil {
            logger.debug("startReminder called but timer already active")
            return
        }

        logger.debug("Starting reminder")
        scheduleTimer()
    }

    private func scheduleTimer() {
        // We verify userConfiguration is non-null earlier
        let text = userConfiguration!.text
        let min = userConfiguration!.min
        let max = userConfiguration!.max

        func tick(_ elapsedTimer: Timer) {
            logger.debug("tick")
            let utterance = AVSpeechUtterance(string: text)
            AVSpeechSynthesizer().speak(utterance)

            elapsedTimer.invalidate() // just in case, not sure if necessary
            scheduleTimer()
        }

        let durationMinutes = Int.random(in: min...max)
        logger.debug("Reminding in \(durationMinutes) minutes")
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(durationMinutes * 60), repeats: false, block: tick(_:))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
