import SwiftUI

fileprivate var lastKeyCommitted: CommittedKey? = nil

fileprivate typealias CommittedKey = (key: RecognizedKey, date: Date)

/// The positions we can move windows into.
fileprivate enum WindowPosition {
    case leftThird, leftHalf, leftTwoThirds
    case rightThird, rightHalf, rightTwoThirds
    case fullscreen
}

/// A key that the window manager recognizes.
fileprivate enum RecognizedKey {
    case arrowLeft, arrowRight, arrowUp, arrowDown
    case returnKey // "return" is a keyword

    static func from(keyCode: Int64) -> RecognizedKey? {
        switch keyCode {
        case 36: return .returnKey
        case 123: return .arrowLeft
        case 124: return .arrowRight
        case 125: return .arrowDown
        case 126: return .arrowUp
        default: return nil
        }
    }
}

/// A namespace for public functions related to input handling.
class Input {
    static func initMonitoring() {
        // Mask creation via https://stackoverflow.com/a/31898592
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: eventMask, callback: onKeyEvent, userInfo: nil) else {
            fatalError("unable to create event tap. Is accessibility permission granted?")
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(nil, eventTap, 0)

        // The two readily-available run loops are main and current: they both refer to the
        // same value so we pick one arbitrarily.
        //
        // The two readily-available run loop modes are default and common: the docs suggest
        // default will only run the loop when the app is idle and common is a pseudo-mode that
        // can contain several modes that we can customize. We pick common since it can run at
        // more opportunities than default possibly making the key observing more responsive
        // (though when I print them out, they both contain many modes and look similar).
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    }
}

fileprivate func onKeyEvent(_ proxy: CGEventTapProxy, _ type: CGEventType, _ event: CGEvent, _ refcon: Optional<UnsafeMutableRawPointer>) -> Unmanaged<CGEvent>? {
    func moveWindow(to windowPosition: WindowPosition) {
        print("move window? \(windowPosition)")
        guard let frontmostAppPid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            print("error: unable to fetch frontmost app pid")
            return
        }

        // To access accessibility attributes of other applications, we had to remove the
        // App Sandbox Capability, which was enabled by default. See:
        // https://stackoverflow.com/a/71655529
        let axApp = AXUIElementCreateApplication(frontmostAppPid)
        let (focusedWindowObj, err) = axApp.copyAttributeValue(kAXFocusedWindowAttribute)
        if err != AXError.success {
            print("error: unable to get focused window of frontmost application")
            return
        }

        // We assume result should never be null if err is success.
        let focusedWindow = focusedWindowObj! as! AXUIElement

        // This won't work correctly for macs with cameras in the bezels:
        // see auxiliaryTopLeftArea to address.
        guard let screenSize = NSScreen.main?.visibleFrame.size else {
            print("error: unable to get the screen size")
            return
        }

        let position: CGPoint
        switch windowPosition {
        case .leftThird, .leftHalf, .leftTwoThirds, .fullscreen:
            position = CGPoint(x: 0, y: 0)
        case .rightThird:
            position = CGPoint(x: screenSize.width - screenSize.width / 3, y: 0)
        case .rightHalf:
            position = CGPoint(x: screenSize.width - screenSize.width / 2, y: 0)
        case .rightTwoThirds:
            position = CGPoint(x: screenSize.width - screenSize.width / 3 * 2, y: 0)
        }

        let size: CGSize
        switch windowPosition {
        case .leftThird, .rightThird:
            size = CGSize(width: screenSize.width / 3, height: screenSize.height)
        case .leftHalf, .rightHalf:
            size = CGSize(width: screenSize.width / 2, height: screenSize.height)
        case .leftTwoThirds, .rightTwoThirds:
            size = CGSize(width: screenSize.width / 3 * 2, height: screenSize.height)
        case .fullscreen:
            size = CGSize(width: screenSize.width, height: screenSize.height)
        }

        let positionResult = focusedWindow.setPosition(position)
        let sizeResult = focusedWindow.setSize(size)

        if positionResult != AXError.success {
            print("error: set position failed \(positionResult)")
        }
        if sizeResult != AXError.success {
            print("error: set size failed \(sizeResult)")
        }

        if positionResult == AXError.success &&
            sizeResult == AXError.success {
            print("move window: success")
        }
    }

    if type == .tapDisabledByUserInput || type == .tapDisabledByTimeout {
        fatalError("event tap disabled \(type): window manager unable to function")
    }

    let flags = event.flags
    if flags.contains(.maskAlternate) && flags.contains(.maskControl) &&
        !flags.contains(.maskCommand) && !flags.contains(.maskShift),
       let key = RecognizedKey.from(keyCode: event.keyCode) {
        if event.isARepeat {
            return nil
        }

        let newWindowPosition: WindowPosition
        let commitUpdate: CommittedKey?
        if let lastCommit = lastKeyCommitted,
           lastCommit.key == key &&
            lastCommit.date.timeIntervalSinceNow <= 2 /* seconds */ {
            // If the user presesd a recognized key twice...
            switch key {
            case .arrowLeft: newWindowPosition = .leftHalf
            case .arrowRight: newWindowPosition = .rightHalf
            case .arrowDown: newWindowPosition = .leftTwoThirds
            case .arrowUp: newWindowPosition = .rightTwoThirds
            case .returnKey: newWindowPosition = .fullscreen
            }

            // Reset state as if we hadn't pressed a key.
            commitUpdate = nil
        } else {
            switch key {
            case .arrowLeft: newWindowPosition = .leftThird
            case .arrowRight: newWindowPosition = .rightThird
            case .arrowDown: newWindowPosition = .leftTwoThirds
            case .arrowUp: newWindowPosition = .rightTwoThirds
            case .returnKey: newWindowPosition = .fullscreen
            }

            commitUpdate = (key, Date())
        }

        moveWindow(to: newWindowPosition)
        lastKeyCommitted = commitUpdate
        return nil
    }

    return Unmanaged.passUnretained(event)
}
