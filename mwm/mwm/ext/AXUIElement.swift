import SwiftUI

extension AXUIElement {
    func getSize() -> CGSize? {
        let (axValue, result) = self.copyAttributeValue(kAXSizeAttribute)
        if (result != AXError.success) {
            return nil
        }

        var size = CGSize()
        if (!AXValueGetValue(axValue as! AXValue, AXValueType.cgSize, &size)) {
            return nil
        }
        return size
    }

    func setSize(_ size: CGSize) -> AXError {
        var sizeCopy = size.applying(CGAffineTransformIdentity)
        let axValue = AXValueCreate(AXValueType.cgSize, &sizeCopy)!
        return self.setAttributeValue(kAXSizeAttribute, axValue)
    }

    func getPosition() -> CGPoint? {
        let (axValue, result) = self.copyAttributeValue(kAXPositionAttribute)
        if (result != AXError.success) {
            return nil
        }

        var point = CGPoint()
        if (!AXValueGetValue(axValue as! AXValue, AXValueType.cgPoint, &point)) {
            return nil
        }
        return point
    }

    func setPosition(_ position: CGPoint) -> AXError {
        var positionCopy = position.applying(CGAffineTransformIdentity)
        let axValue = AXValueCreate(AXValueType.cgPoint, &positionCopy)!
        return self.setAttributeValue(kAXPositionAttribute, axValue)
    }

    /// Swift convenience wrapper for `AXUIElementCopyAttributeValue`.
    func copyAttributeValue(_ attribute: String) -> (AnyObject?, AXError) {
        var value: AnyObject? = nil
        let result = AXUIElementCopyAttributeValue(self, attribute as CFString, &value)
        return (value, result)
    }

    /// Swift convenience wrapper for `AXUIElementSetAttributeValue`.
    func setAttributeValue(_ attribute: String, _ value: AnyObject) -> AXError {
        return AXUIElementSetAttributeValue(self, attribute as CFString, value)
    }

    func debugPrintAttributeNames() {
        // Tips on how to get types to work from: https://stackoverflow.com/a/34121525
        print("debugPrintAttributeNames:")
        var arr: CFArray? = nil
        let result = AXUIElementCopyAttributeNames(self, &arr)
        if result != AXError.success {
            print("  error: CopyAttributeNames failed \(result.rawValue)")
            return
        }

        // We assume arr is non-null if the call was successful.
        for e in arr! as NSArray {
            print("  \(e)")
        }
    }
}
