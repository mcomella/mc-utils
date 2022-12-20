import CoreGraphics

extension CGEvent {
    /// Conversion to Bool for `CGEvent.getIntegerValueField(.keyboardEventAutorepeat)`.
    var isARepeat: Bool {
        get {
            return self.getIntegerValueField(.keyboardEventAutorepeat) != 0
        }
    }

    /// Alias for `CGEvent.getIntegerValueField(.keyboardEventKeycode)`.
    var keyCode: Int64 {
        get {
            return self.getIntegerValueField(.keyboardEventKeycode)
        }
    }
}
