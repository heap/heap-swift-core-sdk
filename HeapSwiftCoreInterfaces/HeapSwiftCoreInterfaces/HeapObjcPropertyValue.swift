import Foundation

@objc
public protocol HeapObjcPropertyValue: NSObjectProtocol {
    var heapValue: String { get }
}

extension NSString: HeapObjcPropertyValue, HeapPropertyValue {
    public var heapValue: String { return self as String }
}

extension NSNumber: HeapObjcPropertyValue, HeapPropertyValue {
    public var heapValue: String {
        if CFGetTypeID(self) == CFBooleanGetTypeID() {
            return self.boolValue ? "true" : "false"
        }
        return self.stringValue
    }
}
