public protocol HeapPropertyValue {
    var heapValue: String { get }
}

extension Bool: HeapPropertyValue {
    public var heapValue: String { description }
}

extension Int: HeapPropertyValue {
    public var heapValue: String { description }
}

extension Int64: HeapPropertyValue {
    public var heapValue: String { description }
}

extension Int32: HeapPropertyValue {
    public var heapValue: String { description }
}

extension Int16: HeapPropertyValue {
    public var heapValue: String { description }
}

extension Int8: HeapPropertyValue {
    public var heapValue: String { description }
}

extension Double: HeapPropertyValue {
    public var heapValue: String { description }
}

extension Float: HeapPropertyValue {
    public var heapValue: String { description }
}

extension String: HeapPropertyValue {
    public var heapValue: String { self }
}

extension Substring: HeapPropertyValue {
    public var heapValue: String { String(self) }
}
